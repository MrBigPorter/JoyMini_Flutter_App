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

  @override
  void initState() {
    super.initState();

    // 移除老OAuth Provider重置逻辑，Deep Link OAuth不需要
    _checkForOAuthRecovery();
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
    cd.dispose();
    super.dispose();
  }
}