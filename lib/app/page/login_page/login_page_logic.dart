part of 'login_page.dart';

mixin LoginPageLogic on ConsumerState<LoginPage> {
  static const _modePhoneCode = 'phoneCode';
  static const _modeEmailCode = 'emailCode';
  static const _modePassword = 'password';

  late final Countdown cd = Countdown();

  // OTP 登录表单
  late final LoginOtpModelForm otpForm = LoginOtpModelForm(
    LoginOtpModelForm.formElements(const LoginOtpModel()),
    null,
  );

  // 密码登录表单
  late final LoginPasswordModelForm passwordForm = LoginPasswordModelForm(
    LoginPasswordModelForm.formElements(const LoginPasswordModel()),
    null,
  );

  // 邮箱验证码登录表单
  late final LoginEmailModelForm emailForm = LoginEmailModelForm(
    LoginEmailModelForm.formElements(const LoginEmailModel()),
    null,
  );

  //  修改点 1：默认显示为邮箱登录
  String _loginMode = _modeEmailCode;
  bool _submitted = false;

  bool get _usePasswordLogin => _loginMode == _modePassword;
  bool get _useEmailCodeLogin => _loginMode == _modeEmailCode;

  //  修改点 2：调整 Index，对应最新的 UI 顺序
  // 0: 邮箱 (左), 1: 密码 (中), 2: 手机 (右)
  int get _modeIndex => switch (_loginMode) {
    _modeEmailCode => 0,
    _modePassword => 1,
    _modePhoneCode => 2,
    _ => 0,
  };

  Alignment get _modeHighlightAlignment => switch (_modeIndex) {
    0 => Alignment.centerLeft,
    1 => Alignment.center,
    _ => Alignment.centerRight,
  };

  void _setLoginMode(String mode) {
    otpForm.form.reset();
    passwordForm.form.reset();
    emailForm.form.reset();
    cd.stop();
    setState(() {
      _loginMode = mode;
      _submitted = false;
    });
  }

  void submit() {
    final form = _usePasswordLogin
        ? passwordForm.form
        : (_useEmailCodeLogin ? emailForm.form : otpForm.form);
    setState(() {
      _submitted = true;
      form.markAllAsTouched();
    });

    if (!form.valid) return;

    if (_usePasswordLogin) {
      // TODO: 密码登录
    } else {
      if (_useEmailCodeLogin) {
        loginWithEmailCode();
      } else {
        loginWithOtp();
      }
    }
  }

  Future<void> loginWithOtp() async {
    final model = otpForm.model;
    if (ref.watch(verifyOtpCtrlProvider).isLoading) return;

    final verify = await ref
        .read(verifyOtpCtrlProvider.notifier)
        .run(model.phone, model.otp);
    if (!verify) return;

    final result = await ref.read(authLoginOtpCtrlProvider.notifier).run((
    phone: model.phone,
    ));

    if (result.isNotNullOrEmpty && result.tokens.isNotNullOrEmpty) {
      final auth = ref.read(authProvider.notifier);
      await auth.login(result.tokens.accessToken, result.tokens.refreshToken);
    }
  }

  Future<void> loginWithEmailCode() async {
    final model = emailForm.model;
    if (ref.watch(authLoginEmailCtrlProvider).isLoading) return;

    final result = await ref.read(authLoginEmailCtrlProvider.notifier).run((
    email: model.email,
    code: model.code,
    ));

    if (result.isNotNullOrEmpty && result.tokens.isNotNullOrEmpty) {
      await _syncLoginTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );
    }
  }

  String? _currentInviteCode() {
    final form = _usePasswordLogin
        ? passwordForm.form
        : (_useEmailCodeLogin ? emailForm.form : otpForm.form);
    final AbstractControl<dynamic>? control;
    try {
      control = form.control('inviteCode');
    } catch (_) {
      return null;
    }
    final value = control.value?.toString();
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  Future<void> _syncLoginTokens(String accessToken, String refreshToken) async {
    final auth = ref.read(authProvider.notifier);
    await auth.login(accessToken, refreshToken);
  }

  Future<void> _loginWithGoogleOauth() async {
    try {
      final oauthParams = await OauthSignInService.signInWithGoogle(
        inviteCode: _currentInviteCode(),
      );
      final result = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
      idToken: oauthParams.idToken,
      inviteCode: oauthParams.inviteCode,
      ));
      await _syncLoginTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );
    } catch (e) {
      _handleOauthError(e);
    }
  }

  Future<void> _loginWithFacebookOauth() async {
    try {
      final oauthParams = await OauthSignInService.signInWithFacebook(
        inviteCode: _currentInviteCode(),
      );
      final result = await ref
          .read(authLoginFacebookCtrlProvider.notifier)
          .run((
      accessToken: oauthParams.accessToken,
      userId: oauthParams.userId,
      inviteCode: oauthParams.inviteCode,
      ));
      await _syncLoginTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );
    } catch (e) {
      _handleOauthError(e);
    }
  }

  Future<void> _loginWithAppleOauth() async {
    try {
      final oauthParams = await OauthSignInService.signInWithApple(
        inviteCode: _currentInviteCode(),
      );
      final result = await ref.read(authLoginAppleCtrlProvider.notifier).run((
      idToken: oauthParams.idToken,
      code: oauthParams.code,
      inviteCode: oauthParams.inviteCode,
      ));
      await _syncLoginTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );
    } catch (e) {
      _handleOauthError(e);
    }
  }

  void _handleOauthError(Object error) {
    if (error is OauthCancelledException) return;
    final message = error.toString().replaceFirst('Exception: ', '');
    RadixToast.error(message);
  }

  Future<void> sendCode() async {
    if (cd.running) return;

    if (_useEmailCodeLogin) {
      final email = emailForm.form.control('email');
      email.markAsTouched();
      if (email.invalid) return;

      await ref
          .read(sendEmailCodeCtrlProvider.notifier)
          .run(email.value.toString());
      cd.start(60);
      return;
    }

    final phone = otpForm.form.control('phone');
    phone.markAsTouched();
    if (phone.invalid) return;

    final sendCtrl = ref.read(sendOtpCtrlProvider.notifier);
    await sendCtrl.run(phone.value);
    cd.start(60);
  }

  @override
  void dispose() {
    cd.dispose();
    super.dispose();
  }
}