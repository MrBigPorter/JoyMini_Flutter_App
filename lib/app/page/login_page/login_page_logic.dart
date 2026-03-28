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

  @override
  void initState() {
    super.initState();
    Future(() {
      if (!mounted) return;
      ref.read(authLoginGoogleCtrlProvider.notifier).reset();
      ref.read(authLoginFacebookCtrlProvider.notifier).reset();
      ref.read(authLoginAppleCtrlProvider.notifier).reset();
    });
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
    setState(() => _emailLoginInFlight = true);

    try {
      final result = await ref.read(authLoginEmailCtrlProvider.notifier).run((
      email: model.email,
      code: model.code,
      ));

      if (!mounted) return; //  关键防线：API 返回后，页面可能已销毁

      if (result.isNotNullOrEmpty && result.tokens.isNotNullOrEmpty) {
        _isSuccessRedirecting = true;
        await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
      }
    } catch (e) {
      // 兜底错误
    } finally {
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
    if (!mounted) return; //  关键防线：确保在用 ref.read 之前页面还在
    final auth = ref.read(authProvider.notifier);
    await auth.login(accessToken, refreshToken);
  }

  Future<void> _loginWithGoogleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;

    _oauthCancelled = false;
    setState(() => _socialOauthInFlight = true);

    try {
      final idToken = await FirebaseOauthSignInService.signInWithGoogle();


      if (!mounted) return; //  关键防线：Firebase 弹窗回来后检查

      if (idToken == null) {
        throw StateError('Google sign-in failed: no token returned');
      }

      final result = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
      idToken: idToken,
      inviteCode: _currentInviteCode(),
      ));

      if (!mounted) return; //  关键防线：NestJS 返回后检查

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
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
      final result = await FirebaseOauthSignInService.signInWithFacebook();

      if (!mounted) return; //  关键防线：Facebook 弹窗回来后检查

      if (result == null) {
        throw StateError('Facebook sign-in failed: no result returned');
      }

      if (result.containsKey('accessToken')) {
        final apiResult = await ref.read(authLoginFacebookCtrlProvider.notifier).run((
        idToken: null,
        accessToken: result['accessToken'],
        userId: result['userId'],
        inviteCode: _currentInviteCode(),
        ));

        if (!mounted) return; //  关键防线

        _isSuccessRedirecting = true;
        await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);
      } else {
        final apiResult = await ref.read(authLoginFacebookCtrlProvider.notifier).run((
        idToken: result['idToken'],
        accessToken: null,
        userId: null,
        inviteCode: _currentInviteCode(),
        ));

        if (!mounted) return; //  关键防线

        _isSuccessRedirecting = true;
        await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);
      }
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
      final idToken = await FirebaseOauthSignInService.signInWithApple();

      if (!mounted) return; //  关键防线

      if (idToken == null) {
        throw StateError('Apple sign-in failed: no token returned');
      }

      final result = await ref.read(authLoginAppleCtrlProvider.notifier).run((
      idToken: idToken,
      inviteCode: _currentInviteCode(),
      ));

      if (!mounted) return; //  关键防线

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
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

      if (!mounted) return; //  关键防线

      RadixToast.success(
        'login.email_code_sent'.tr(namedArgs: {'email': emailValue}),
      );
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