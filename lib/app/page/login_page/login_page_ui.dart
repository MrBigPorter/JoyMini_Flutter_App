part of 'login_page.dart';

extension LoginPageUI on _LoginPageState {
  Widget buildUI(BuildContext context) {
    final send = ref.watch(sendOtpCtrlProvider);
    final verify = ref.watch(verifyOtpCtrlProvider);
    final login = ref.watch(authLoginOtpCtrlProvider);
    final sendEmail = ref.watch(sendEmailCodeCtrlProvider);
    final emailLogin = ref.watch(authLoginEmailCtrlProvider);
    final googleOauth = ref.watch(authLoginGoogleCtrlProvider);
    final facebookOauth = ref.watch(authLoginFacebookCtrlProvider);
    final appleOauth = ref.watch(authLoginAppleCtrlProvider);

    final socialLoading =
        googleOauth.isLoading ||
            facebookOauth.isLoading ||
            appleOauth.isLoading ||
            _socialOauthInFlight;
    final emailLoading = sendEmail.isLoading || emailLogin.isLoading;
    final showGoogleButton = OauthSignInService.canShowGoogleButton || kIsWeb;
    final showFacebookButton =
        OauthSignInService.canShowFacebookButton || kIsWeb;

    return BaseScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 32.w, 16.w, 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      'sign-in'.tr(),
                      style: TextStyle(
                        fontSize: context.displayXs,
                        height: context.leadingXs,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary900,
                      ),
                    ),
                    SizedBox(height: 8.w),
                    Text(
                      'start-your-fortunate-journey'.tr(),
                      style: TextStyle(
                        fontSize: context.textMd,
                        height: context.leadingMd,
                        fontWeight: FontWeight.w400,
                        color: context.textTertiary600,
                      ),
                    ),
                    SizedBox(height: 20.w),

                    // 优化后的 Tab 切换区域
                    Container(
                      height: 48.h, // 增加明确的高度，让触摸区域更大更舒适
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F2F4), // 稍微加深底色，凸显白色滑块
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Stack(
                        children: [
                          // 移动的白色滑块
                          AnimatedAlign(
                            alignment: _modeHighlightAlignment,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: FractionallySizedBox(
                              widthFactor: 1 / 3,
                              child: Container(
                                height: double.infinity, // 填满外层高度
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 1,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 文字按钮层
                          Row(
                            children: [
                              // 🌟 修改点：第一顺位 - 邮箱
                              Expanded(
                                child: _buildModeTab(
                                  label: 'login.mode.email_code'.tr(),
                                  mode: LoginPageLogic._modeEmailCode,
                                ),
                              ),
                              // 🌟 修改点：第二顺位 - 密码
                              Expanded(
                                child: _buildModeTab(
                                  label: 'login.mode.password'.tr(),
                                  mode: LoginPageLogic._modePassword,
                                ),
                              ),
                              // 🌟 修改点：第三顺位 - 手机验证码
                              Expanded(
                                child: _buildModeTab(
                                  label: 'login.mode.phone_code'.tr(),
                                  mode: LoginPageLogic._modePhoneCode,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.w),

                    // 表单区域
                    ReactiveFormConfig(
                      validationMessages: kGlobalValidationMessages,
                      child: ReactiveForm(
                        formGroup: _usePasswordLogin
                            ? passwordForm.form
                            : (_useEmailCodeLogin
                            ? emailForm.form
                            : otpForm.form),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_useEmailCodeLogin) ...[
                              LfInput(
                                name: 'phone',
                                label: 'login.phone.label'.tr(),
                                hint: 'login.phone.hint'.tr(),
                                required: true,
                                keyboardType: TextInputType.phone,
                                showErrors: (c) =>
                                c.invalid && (c.dirty || _submitted),
                                prefixIcon: _buildPhPrefix(context),
                              ),
                              SizedBox(height: 16.w),
                            ],

                            if (_usePasswordLogin) ...[
                              LfInput(
                                name: 'password',
                                label: 'login.password.label'.tr(),
                                hint: 'login.password.hint'.tr(),
                                required: true,
                                obscureText: true,
                                showErrors: (c) =>
                                c.invalid && (c.dirty || _submitted),
                              ),
                              Button(
                                variant: ButtonVariant.text,
                                paddingX: 0,
                                onPressed: () =>
                                    appRouter.push('/reset-password'),
                                child: Text(
                                  'common.forgot.password'.tr(),
                                  style: TextStyle(
                                    fontSize: context.textSm,
                                    height: context.leadingSm,
                                    fontWeight: FontWeight.w800,
                                    color: context.buttonTertiaryColorFg,
                                  ),
                                ),
                              ),
                            ] else ...[
                              if (!_useEmailCodeLogin) ...[
                                LfInput(
                                  name: 'otp',
                                  label: 'login.phone_code.label'.tr(),
                                  hint: 'login.phone_code.hint'.tr(),
                                  required: true,
                                  keyboardType: TextInputType.number,
                                  showErrors: (c) =>
                                  c.invalid && (c.dirty || _submitted),
                                  suffixIcon: ValueListenableBuilder(
                                    valueListenable: cd.seconds,
                                    builder: (context, int seconds, _) {
                                      final running = cd.running;
                                      return Button(
                                        variant: ButtonVariant.text,
                                        loading: send.isLoading,
                                        onPressed: running || send.isLoading
                                            ? null
                                            : sendCode,
                                        child: Text(
                                          running
                                              ? 'login.resend_in'.tr(
                                            namedArgs: {
                                              'seconds': '$seconds',
                                            },
                                          )
                                              : 'login.send_code'.tr(),
                                          style: TextStyle(
                                            fontSize: context.textSm,
                                            height: context.leadingSm,
                                            fontWeight: FontWeight.w600,
                                            color: running
                                                ? context.textDisabled
                                                : context
                                                .buttonTertiaryColorFg,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ] else ...[
                                LfInput(
                                  name: 'email',
                                  label: 'login.email.label'.tr(),
                                  hint: 'login.email.hint'.tr(),
                                  required: true,
                                  keyboardType: TextInputType.emailAddress,
                                  showErrors: (c) =>
                                  c.invalid && (c.dirty || _submitted),
                                ),
                                SizedBox(height: 16.w),
                                LfInput(
                                  name: 'code',
                                  label: 'login.email_code.label'.tr(),
                                  hint: 'login.email_code.hint'.tr(),
                                  required: true,
                                  keyboardType: TextInputType.number,
                                  showErrors: (c) =>
                                  c.invalid && (c.dirty || _submitted),
                                  suffixIcon: ValueListenableBuilder(
                                    valueListenable: cd.seconds,
                                    builder: (context, int seconds, _) {
                                      final running = cd.running;
                                      return Button(
                                        variant: ButtonVariant.text,
                                        loading: sendEmail.isLoading,
                                        onPressed:
                                        running || sendEmail.isLoading
                                            ? null
                                            : sendCode,
                                        child: Text(
                                          running
                                              ? 'login.resend_in'.tr(
                                            namedArgs: {
                                              'seconds': '$seconds',
                                            },
                                          )
                                              : 'login.send_code'.tr(),
                                          style: TextStyle(
                                            fontSize: context.textSm,
                                            height: context.leadingSm,
                                            fontWeight: FontWeight.w600,
                                            color: running
                                                ? context.textDisabled
                                                : context
                                                .buttonTertiaryColorFg,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],

                            if (!_usePasswordLogin &&
                                !_useEmailCodeLogin) ...[
                              SizedBox(height: 16.w),
                              LfInput(
                                name: 'inviteCode',
                                label: 'login.invite_code.label'.tr(),
                                hint: 'login.invite_code.hint'.tr(),
                                keyboardType: TextInputType.text,
                                showErrors: (c) =>
                                c.invalid && (c.dirty || _submitted),
                              ),
                            ],

                            SizedBox(height: 24.w),

                            // 提交
                            Button(
                              loading:
                              verify.isLoading ||
                                  login.isLoading ||
                                  emailLoading,
                              width: double.infinity,
                              onPressed: submit,
                              child: Text('common.login'.tr()),
                            ),

                            SizedBox(height: 20.w),

                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                  ),
                                  child: Text(
                                    'login.or_continue_with'.tr(),
                                    style: TextStyle(
                                      fontSize: context.textSm,
                                      color: context.textTertiary600,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),

                            SizedBox(height: 12.w),

                            if (showGoogleButton) ...[
                              if (kIsWeb) ...[
                                // ─── Web: Google renderButton (bottom, clickable)
                                //          + custom visual (top, IgnorePointer) ──
                                if (_googleWebReady) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48.h,
                                    child: Stack(
                                      children: [
                                        // Bottom: real Google renderButton (receives clicks → popup)
                                        Positioned.fill(
                                          child: buildGoogleSignInWebButton(),
                                        ),
                                        // Top: our custom visual (pointer-transparent)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: socialLoading
                                                    ? Colors.grey.shade100
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                border: Border.all(
                                                  color: const Color(0xFFDADCE0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  if (_socialOauthInFlight) ...[
                                                    SizedBox(
                                                      width: 18.w,
                                                      height: 18.w,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: context
                                                            .textTertiary600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.w),
                                                  ] else
                                                    Icon(
                                                      Icons
                                                          .g_mobiledata_rounded,
                                                      size: 35.sp,
                                                    ),
                                                  Text(
                                                    'login.oauth.google'.tr(),
                                                    style: TextStyle(
                                                      fontSize: context.textSm,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Disable overlay when any OAuth is in flight
                                        if (socialLoading)
                                          Positioned.fill(
                                            child: AbsorbPointer(
                                              child: Container(
                                                color: Colors.white
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Still initializing
                                  Button(
                                    width: double.infinity,
                                    height: 48.h,
                                    variant: ButtonVariant.secondary,
                                    disabled: true,
                                    onPressed: null,
                                    leading: Icon(
                                      Icons.g_mobiledata_rounded,
                                      size: 35.sp,
                                    ),
                                    child: Text('login.oauth.google'.tr()),
                                  ),
                                ],
                              ] else ...[
                                // ─── Native: custom button ────────────────────
                                Button(
                                  width: double.infinity,
                                  height: 48.h,
                                  variant: ButtonVariant.secondary,
                                  loading: googleOauth.isLoading,
                                  disabled: socialLoading &&
                                      !googleOauth.isLoading,
                                  onPressed: socialLoading ||
                                          !OauthSignInService
                                              .canShowGoogleButton
                                      ? null
                                      : _loginWithGoogleOauth,
                                  leading: Icon(
                                    Icons.g_mobiledata_rounded,
                                    size: 35.sp,
                                  ),
                                  child: Text('login.oauth.google'.tr()),
                                ),
                              ],
                              SizedBox(height: 10.w),
                            ],

                            if (showFacebookButton) ...[
                              Button(
                                width: double.infinity,
                                height: 48.h,
                                variant: ButtonVariant.secondary,
                                loading: facebookOauth.isLoading,
                                disabled: socialLoading &&
                                    !facebookOauth.isLoading,
                                onPressed:
                                socialLoading ||
                                    !OauthSignInService
                                        .canShowFacebookButton
                                    ? null
                                    : _loginWithFacebookOauth,
                                leading: const Icon(Icons.facebook_rounded),
                                child: Text('login.oauth.facebook'.tr()),
                              ),
                              SizedBox(height: 10.w),
                            ],

                            if (OauthSignInService.canShowAppleButton) ...[
                              SizedBox(height: 10.w),
                              Button(
                                width: double.infinity,
                                height: 48.h,
                                variant: ButtonVariant.secondary,
                                loading: appleOauth.isLoading,
                                disabled: socialLoading &&
                                    !appleOauth.isLoading,
                                onPressed: socialLoading
                                    ? null
                                    : _loginWithAppleOauth,
                                leading: const Icon(Icons.apple_rounded),
                                child: Text('login.oauth.apple'.tr()),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                        .animate(key: ValueKey(_loginMode))
                        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                        .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    )
                        .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutQuart,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhPrefix(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ph.png',
            width: 24.w,
            height: 24.w,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 4.w),
          Text(
            '+63',
            style: TextStyle(
              fontSize: context.textMd,
              height: context.leadingMd,
              fontWeight: FontWeight.w400,
              color: context.textPrimary900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({required String label, required String mode}) {
    final selected = _loginMode == mode;

    return GestureDetector(
      onTap: () => _setLoginMode(mode),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: double.infinity, // 撑满父级，确保整个区域都能点击
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: 13.sp, // 字体稍微调大一点点，更清晰
              letterSpacing: 0.3, // 增加字间距，显得更现代
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? context.textPrimary900
                  : context.textTertiary600,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // 防止多语言文本过长导致换行破图
            ),
          ),
        ),
      ),
    );
  }
}