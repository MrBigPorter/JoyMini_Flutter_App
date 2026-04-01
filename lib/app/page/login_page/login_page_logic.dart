part of 'login_page.dart';

mixin LoginPageLogic on ConsumerState<LoginPage> {
  late final Countdown cd = Countdown();

  late final LoginEmailModelForm emailForm = LoginEmailModelForm(
    LoginEmailModelForm.formElements(const LoginEmailModel()),
    null,
  );

  bool _submitted = false;
  bool _emailLoginInFlight = false;
  bool _socialOauthInFlight = false;
  bool _isSuccessRedirecting = false;
  bool _oauthCancelled = false;
  bool _oauthRecoveryStarted = false;

  /// 记录 App 是否在 OAuth 等待期间进入了后台（浏览器打开）
  bool _appWentToBackground = false;
  Timer? _cancelAfterResumeTimer;

  @override
  void initState() {
    super.initState();

    // 注意：WidgetsBinding.instance.addObserver 由 _LoginPageState 负责
    // 添加页面返回监听
    if (isAppRouterReady) {
      appRouter.routeInformationProvider.addListener(_onRouteChanged);
    }

    // 移除老OAuth Provider重置逻辑，Deep Link OAuth不需要
    _checkForOAuthRecovery();
  }

  /// 由 _LoginPageState.didChangeAppLifecycleState 调用
  /// 监听 App 生命周期变化
  /// - paused：App 进入后台（OAuth 浏览器打开时发生）
  /// - resumed：App 回到前台（用户关闭浏览器时发生）
  void handleLifecycleChange(AppLifecycleState state) {
    if (!_socialOauthInFlight || _isSuccessRedirecting) return;

    if (state == AppLifecycleState.paused) {
      // App 进入后台，记录标记（OAuth 浏览器已打开）
      _appWentToBackground = true;
      _cancelAfterResumeTimer?.cancel();
      debugPrint('[LoginPage] App went to background during OAuth, will check on resume');
    } else if (state == AppLifecycleState.resumed && _appWentToBackground) {
      // App 从后台恢复，用户可能关闭了浏览器/取消了授权
      _appWentToBackground = false;
      _cancelAfterResumeTimer?.cancel();
      // 给 3 秒 grace period 等待 deep link 回调
      // 如果 3 秒内收到 deep link → 登录成功，timer 会被取消
      // 如果 3 秒内没有 deep link → 用户取消了，自动清除 loading
      _cancelAfterResumeTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted || !_socialOauthInFlight || _isSuccessRedirecting) return;
        debugPrint('[LoginPage] No deep link after resume, user likely cancelled OAuth');
        DeepLinkOAuthService.cancelLogin();
        // cancelLogin 会触发 completeError → catch 块 → finally 块 setState
        // 这里加一道保险：直接重置（防止 completer 已释放的边缘情况）
        if (mounted && _socialOauthInFlight && !_isSuccessRedirecting) {
          setState(() {
            _socialOauthInFlight = false;
            _oauthCancelled = true;
          });
        }
      });
    }
  }

  /// 用户主动点击"取消"按钮
  void cancelOAuth() {
    _cancelAfterResumeTimer?.cancel();
    DeepLinkOAuthService.cancelLogin();
    if (mounted && _socialOauthInFlight && !_isSuccessRedirecting) {
      setState(() {
        _socialOauthInFlight = false;
        _oauthCancelled = true;
      });
    }
  }

  void _onRouteChanged() {
    if (!mounted) return;
    
    final currentPath = appRouter.routeInformationProvider.value.uri.path;
    if (currentPath != '/login' && _socialOauthInFlight) {
      // 如果离开登录页但OAuth仍在进行中，取消OAuth并重置状态
      debugPrint('[LoginPage] Route changed away from login, cancelling OAuth');
      DeepLinkOAuthService.cancelLogin();
      if (mounted) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }

  Future<void> _checkForOAuthRecovery() async {
    if (!mounted || _oauthRecoveryStarted) return;

    if (isAppRouterReady) {
      final currentPath = appRouter.routeInformationProvider.value.uri.path;
      if (currentPath == '/oauth/processing') return;
    }

    _oauthRecoveryStarted = true;

    // Deep Link OAuth 不需要 Web 重定向恢复逻辑
    // 所有 OAuth 状态由后端管理，前端只需等待 Deep Link 回调

    try {
      await GlobalOAuthHandler.checkAndRecoverInterruptedOAuth();
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }

  void submit() {
    setState(() {
      _submitted = true;
      emailForm.form.markAllAsTouched();
    });

    if (!emailForm.form.valid) return;
    loginWithEmailCode();
  }

  Future<void> loginWithEmailCode() async {
    if (ref.watch(authLoginEmailCtrlProvider).isLoading ||
        _emailLoginInFlight ||
        _isSuccessRedirecting) {
      return;
    }

    final model = emailForm.model;
    setState(() => _emailLoginInFlight = true);

    try {
      final result = await ref.read(authLoginEmailCtrlProvider.notifier).run((
      email: model.email,
      code: model.code,
      ));

      if (!mounted) return;

      if (result.isNotNullOrEmpty && result.tokens.isNotNullOrEmpty) {
        _isSuccessRedirecting = true;
        await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
      }
    } catch (e) {
      // 静默处理错误
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _emailLoginInFlight = false);
      }
    }
  }

  String? _currentInviteCode() {
    final AbstractControl<dynamic>? control;
    try {
      control = emailForm.form.control('inviteCode');
    } catch (_) {
      return null;
    }
    final value = control.value?.toString();
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  Future<void> _syncLoginTokens(String accessToken, String refreshToken) async {
    if (!mounted) {
      return;
    }
    final auth = ref.read(authProvider.notifier);
    await auth.login(accessToken, refreshToken);
  }

  Future<void> _loginWithGoogleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    _oauthCancelled = false;
    setState(() => _socialOauthInFlight = true);
    try {
      final result = await DeepLinkOAuthService.loginWithGoogle(
        apiBaseUrl: OAuthConfig.apiBaseUrl,
        inviteCode: _currentInviteCode(),
      );

      if (!mounted) return;

      // Deep Link OAuth 直接使用后端返回的 Luna Token，不调用 Firebase API
      _isSuccessRedirecting = true;
      _cancelAfterResumeTimer?.cancel(); // 成功时取消 grace timer
      await _syncLoginTokens(result['token']!, result['refreshToken'] ?? '');

      if (mounted) setState(() => _socialOauthInFlight = false);
    } on DeepLinkOAuthException catch (e) {
      if (e.message.contains('cancelled') || e.message.contains('timeout')) {
        _oauthCancelled = true;
        return;
      }
      _handleOauthError(e);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        if (!_oauthCancelled && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted && !_isSuccessRedirecting) {
          setState(() => _socialOauthInFlight = false);
        }
      }
    }
  }

  Future<void> _loginWithFacebookOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    _oauthCancelled = false;
    setState(() => _socialOauthInFlight = true);
    try {
      final result = await DeepLinkOAuthService.loginWithFacebook(
        apiBaseUrl: OAuthConfig.apiBaseUrl,
        inviteCode: _currentInviteCode(),
      );

      if (!mounted) return;

      // Deep Link OAuth 直接使用后端返回的 Luna Token，不调用 Firebase API
      _isSuccessRedirecting = true;
      _cancelAfterResumeTimer?.cancel(); // 成功时取消 grace timer
      await _syncLoginTokens(result['token']!, result['refreshToken'] ?? '');

      if (mounted) setState(() => _socialOauthInFlight = false);
    } on DeepLinkOAuthException catch (e) {
      if (e.message.contains('cancelled') || e.message.contains('timeout')) {
        _oauthCancelled = true;
        return;
      }
      _handleOauthError(e);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        if (!_oauthCancelled && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted && !_isSuccessRedirecting) {
          setState(() => _socialOauthInFlight = false);
        }
      }
    }
  }

  Future<void> _loginWithAppleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    _oauthCancelled = false;
    setState(() => _socialOauthInFlight = true);
    try {
      final result = await DeepLinkOAuthService.loginWithApple(
        apiBaseUrl: OAuthConfig.apiBaseUrl,
        inviteCode: _currentInviteCode(),
      );

      if (!mounted) return;

      // Deep Link OAuth 直接使用后端返回的 Luna Token，不调用 Firebase API
      _isSuccessRedirecting = true;
      _cancelAfterResumeTimer?.cancel(); // 成功时取消 grace timer
      await _syncLoginTokens(result['token']!, result['refreshToken'] ?? '');

      if (mounted) setState(() => _socialOauthInFlight = false);
    } on DeepLinkOAuthException catch (e) {
      if (e.message.contains('cancelled') || e.message.contains('timeout')) {
        _oauthCancelled = true;
        return;
      }
      _handleOauthError(e);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        if (!_oauthCancelled && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted && !_isSuccessRedirecting) {
          setState(() => _socialOauthInFlight = false);
        }
      }
    }
  }

  void _handleOauthError(Object error) {
    if (error is OauthCancelledException) {
      _oauthCancelled = true;
      return;
    }
    final raw = error.toString();
    if (raw.contains('origin_mismatch')) {
      RadixToast.error('Google login blocked: origin_mismatch.');
      return;
    }
    final message = raw.replaceFirst('Exception: ', '');
    RadixToast.error(message);
  }

  Future<void> sendCode() async {
    if (cd.running || _emailLoginInFlight || _socialOauthInFlight || _isSuccessRedirecting) return;

    final email = emailForm.form.control('email');
    email.markAsTouched();
    if (email.invalid) return;

    final emailValue = email.value.toString();
    try {
      await ref.read(sendEmailCodeCtrlProvider.notifier).run(emailValue);
      if (!mounted) return;
      RadixToast.success('login.email_code_sent'.tr(namedArgs: {'email': emailValue}));
      cd.start(60);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      RadixToast.error(message);
    }
  }

  @override
  void dispose() {
    // 注意：WidgetsBinding.instance.removeObserver 由 _LoginPageState 负责
    // 取消 resume 延迟取消计时器
    _cancelAfterResumeTimer?.cancel();
    // 取消所有进行中的 OAuth 登录
    DeepLinkOAuthService.cancelLogin();
    // 确保按钮 loading 状态被重置
    if (_socialOauthInFlight) {
      _socialOauthInFlight = false;
    }
    // 移除路由监听
    if (isAppRouterReady) {
      appRouter.routeInformationProvider.removeListener(_onRouteChanged);
    }
    cd.dispose();
    super.dispose();
  }
}