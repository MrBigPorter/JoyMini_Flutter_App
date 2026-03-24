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
  }

  Future<void> _initGoogleWebSignIn() async {
    try {
      await OauthSignInService.initializeForWeb(trigger: 'login_page.initState');
      _googleWebAuthSub?.cancel();
      _googleWebAuthSub = GoogleSignIn.instance.authenticationEvents.listen(
            (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _processGoogleWebCredential(event.user);
          }
        },
        onError: (Object error) {
          if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) return;
          _handleOauthError(error);
        },
        cancelOnError: false,
      );
      if (mounted) setState(() => _googleWebReady = true);
    } catch (e) {
      debugPrint('[LoginPage] Google web init error: $e');
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

  @override
  void dispose() {
    _googleWebAuthSub?.cancel();
    cd.dispose();
    super.dispose();
  }
}