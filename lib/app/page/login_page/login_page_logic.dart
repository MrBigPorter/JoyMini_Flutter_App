part of 'login_page.dart';

mixin LoginPageLogic on ConsumerState<LoginPage> {
  late final Countdown cd = Countdown();

  late final LoginEmailModelForm emailForm = LoginEmailModelForm(
    LoginEmailModelForm.formElements(const LoginEmailModel()),
    null,
  );

  bool _submitted = false;

  // 新增：专门追踪邮箱登录的完整生命周期
  bool _emailLoginInFlight = false;
  // 追踪社交登录的完整生命周期
  bool _socialOauthInFlight = false;
  // 新增：标记是否已经登录成功，正在等待路由跳转
  bool _isSuccessRedirecting = false;

  bool _googleWebReady = false;
  bool _googleWebUserInitiated = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleWebAuthSub;

  @override
  void initState() {
    super.initState();
    // keepAlive providers 可能因热重载中断或上次流程异常，残留 AsyncLoading 状态。
    // 用 Future(() {}) 延迟到 widget 树构建完毕后再 reset，
    // 避免 Riverpod "Tried to modify a provider while the widget tree was building" 断言。
    Future(() {
      if (!mounted) return;
      ref.read(authLoginGoogleCtrlProvider.notifier).reset();
      ref.read(authLoginFacebookCtrlProvider.notifier).reset();
      ref.read(authLoginAppleCtrlProvider.notifier).reset();
    });

    if (kIsWeb && OauthSignInService.canShowGoogleButton) {
      _initGoogleWebSignIn();
    }

    // 生产环境诊断：输出 OAuth 配置状态到控制台
    if (kIsWeb) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _logOauthDiagnostics();
        }
      });
    }
  }

  Future<void> _initGoogleWebSignIn() async {
    try {
      debugPrint('[LoginPage] Google web sign-in initialization start');
      await OauthSignInService.initializeForWeb(trigger: 'login_page.initState');
      debugPrint('[LoginPage] Google web sign-in initialization success');
      
      _googleWebAuthSub?.cancel();
      _googleWebAuthSub = GoogleSignIn.instance.authenticationEvents.listen(
            (event) {
          debugPrint('[LoginPage] Google web auth event received: ${event.runtimeType}');
          if (event is GoogleSignInAuthenticationEventSignIn) {
            debugPrint('[LoginPage] Google web SignIn event | email=${event.user.email}');
            _processGoogleWebCredential(event.user);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            debugPrint('[LoginPage] Google web SignOut event');
          } else {
            debugPrint('[LoginPage] Google web other event: ${event.runtimeType}');
          }
        },
        onError: (Object error) {
          debugPrint('[LoginPage] Google web auth stream error: $error');
          if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) {
            debugPrint('[LoginPage] Google web auth cancelled');
            return;
          }
          _handleOauthError(error);
        },
        cancelOnError: false,
      );
      debugPrint('[LoginPage] Google web auth listener established');
      
      if (mounted) {
        setState(() {
          _googleWebReady = true;
          debugPrint('[LoginPage] Google web ready flag set to true');
        });
      }
    } catch (e, s) {
      debugPrint('[LoginPage] Google web init error: $e');
      debugPrint('[LoginPage] Google web init stack trace: $s');
      if (mounted) {
        setState(() {
          _googleWebReady = false;
          debugPrint('[LoginPage] Google web ready flag set to false due to error');
        });
      }
    }
  }

  Future<void> _processGoogleWebCredential(GoogleSignInAccount account) async {
    // Ignore passive FedCM/OneTap events unless the user actually tapped the Google area.
    if (!_googleWebUserInitiated) {
      debugPrint('[LoginPage] Ignore Google web credential without user tap');
      return;
    }
    _googleWebUserInitiated = false;

    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _handleOauthError(StateError('Google idToken is empty'));
      return;
    }

    setState(() => _socialOauthInFlight = true);
    try {
      final result = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
      idToken: idToken,
      inviteCode: _currentInviteCode(),
      ));

      // 成功获取 Token 后，标记正在重定向，保持 Loading 状态
      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      // 只有在没成功的情况下，才取消 Loading；如果成功了，就让它一直转圈直到页面被卸载
      if (mounted && !_isSuccessRedirecting) setState(() => _socialOauthInFlight = false);
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
    if (ref.watch(authLoginEmailCtrlProvider).isLoading || _emailLoginInFlight || _isSuccessRedirecting) return;

    final model = emailForm.model;
    setState(() => _emailLoginInFlight = true); // 开启本地死锁 Loading

    try {
      final result = await ref.read(authLoginEmailCtrlProvider.notifier).run((
      email: model.email,
      code: model.code,
      ));

      if (result.isNotNullOrEmpty && result.tokens.isNotNullOrEmpty) {
        // 成功！标记重定向状态
        _isSuccessRedirecting = true;
        await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
      }
    } catch (e) {
      // 处理错误，API 的错误通常被 Controller 内部处理了，这里做个兜底
    } finally {
      // 如果登录失败，解除 Loading 状态；如果成功，保持 Loading 陪伴用户度过路由延迟
      if (mounted && !_isSuccessRedirecting) setState(() => _emailLoginInFlight = false);
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
    final auth = ref.read(authProvider.notifier);
    await auth.login(accessToken, refreshToken);
  }

  Future<void> _loginWithGoogleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    setState(() => _socialOauthInFlight = true);
    try {
      final oauthParams = await OauthSignInService.signInWithGoogle(inviteCode: _currentInviteCode());
      final result = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
      idToken: oauthParams.idToken,
      inviteCode: oauthParams.inviteCode,
      ));

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) setState(() => _socialOauthInFlight = false);
    }
  }

  void _markGoogleWebUserInitiated() {
    _googleWebUserInitiated = true;
  }

  Future<void> _loginWithFacebookOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    setState(() => _socialOauthInFlight = true);
    try {
      final oauthParams = await OauthSignInService.signInWithFacebook(inviteCode: _currentInviteCode());
      final result = await ref.read(authLoginFacebookCtrlProvider.notifier).run((
      accessToken: oauthParams.accessToken,
      userId: oauthParams.userId,
      inviteCode: oauthParams.inviteCode,
      ));

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) setState(() => _socialOauthInFlight = false);
    }
  }

  Future<void> _loginWithAppleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    setState(() => _socialOauthInFlight = true);
    try {
      final oauthParams = await OauthSignInService.signInWithApple(inviteCode: _currentInviteCode());
      final result = await ref.read(authLoginAppleCtrlProvider.notifier).run((
      idToken: oauthParams.idToken,
      code: oauthParams.code,
      inviteCode: oauthParams.inviteCode,
      ));

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) setState(() => _socialOauthInFlight = false);
    }
  }

  void _handleOauthError(Object error) {
    if (error is OauthCancelledException) return;
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
      RadixToast.success(
        'login.email_code_sent'.tr(namedArgs: {'email': emailValue}),
      );
      cd.start(60);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      RadixToast.error(message);
    }
  }

  void _logOauthDiagnostics() {
    if (!kDebugMode) return;
    
    try {
      final diagnostics = OauthSignInService.getOauthDiagnostics();
      
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║                 OAUTH 诊断报告 (生产环境)                ║');
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║ 平台: ${diagnostics['platform']}');
      debugPrint('║ 当前域名: ${diagnostics['origin']}');
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      
      final google = diagnostics['google'] as Map<String, dynamic>;
      debugPrint('║ GOOGLE 配置状态:');
      debugPrint('║   • Client ID 已配置: ${google['clientIdConfigured']}');
      debugPrint('║   • Client ID 长度: ${google['clientIdLength']}');
      debugPrint('║   • Client ID 预览: ${google['clientIdPreview']}');
      debugPrint('║   • 按钮可显示: ${google['canShowButton']}');
      debugPrint('║   • 已初始化: ${google['initialized']}');
      debugPrint('║   • 初始化 Key: ${google['initKey']}');
      
      final facebook = diagnostics['facebook'] as Map<String, dynamic>;
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║ FACEBOOK 配置状态:');
      debugPrint('║   • App ID 已配置: ${facebook['appIdConfigured']}');
      debugPrint('║   • App ID 长度: ${facebook['appIdLength']}');
      debugPrint('║   • App ID 预览: ${facebook['appIdPreview']}');
      debugPrint('║   • 按钮可显示: ${facebook['canShowButton']}');
      debugPrint('║   • 已初始化: ${facebook['initialized']}');
      debugPrint('║   • SDK 版本: ${facebook['sdkVersion']}');
      
      if (diagnostics['platform'] == 'web') {
        final web = diagnostics['webSpecific'] as Map<String, dynamic>;
        debugPrint('╠══════════════════════════════════════════════════════════╣');
        debugPrint('║ WEB 特定状态:');
        debugPrint('║   • 缓存账号: ${web['cachedAccount']}');
        debugPrint('║   • 全局监听器活跃: ${web['globalListenerActive']}');
        debugPrint('║   • 等待中请求: ${web['pendingWaiter']}');
      }
      
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║ 页面状态:');
      debugPrint('║   • Google Web Ready: $_googleWebReady');
      debugPrint('║   • 社交登录进行中: $_socialOauthInFlight');
      debugPrint('║   • 重定向中: $_isSuccessRedirecting');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      
      // 提供配置建议
      if (kIsWeb) {
        if (!google['clientIdConfigured']) {
          debugPrint('[诊断建议] Google Client ID 未配置，请检查 prod.json 中的 GOOGLE_WEB_CLIENT_ID');
        } else if (!google['initialized']) {
          debugPrint('[诊断建议] Google 初始化失败，可能原因:');
          debugPrint('  1. Google Cloud Console 未配置 Authorized JavaScript origins');
          debugPrint('  2. 当前域名 ${diagnostics['origin']} 不在允许列表中');
          debugPrint('  3. Client ID 无效或已被删除');
        }
        
        if (!facebook['appIdConfigured']) {
          debugPrint('[诊断建议] Facebook App ID 未配置，请检查 prod.json 中的 FACEBOOK_WEB_APP_ID');
        } else if (!facebook['initialized']) {
          debugPrint('[诊断建议] Facebook 初始化失败，可能原因:');
          debugPrint('  1. Facebook Developer Console 未配置 App Domains');
          debugPrint('  2. 当前域名未添加到 App Domains');
          debugPrint('  3. App ID 无效或已被删除');
        }
      }
    } catch (e) {
      debugPrint('[OAuth 诊断错误] $e');
    }
  }

  @override
  void dispose() {
    _googleWebAuthSub?.cancel();
    cd.dispose();
    super.dispose();
  }
}
