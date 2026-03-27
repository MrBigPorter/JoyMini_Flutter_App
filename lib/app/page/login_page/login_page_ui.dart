part of 'login_page.dart';

extension LoginPageUI on _LoginPageState {
  Widget _buildDiagnosticRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.textTertiary600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: value.contains('✅') ? context.bgSuccessPrimary : context.bgWarningPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUI(BuildContext context) {
    final sendEmail = ref.watch(sendEmailCodeCtrlProvider);
    final emailLogin = ref.watch(authLoginEmailCtrlProvider);

    // 全局是否处于"忙碌"状态（包含了等待路由跳转的死区时间）
    final isPageBusy = _emailLoginInFlight ||
        _socialOauthInFlight ||
        _isSuccessRedirecting;

    // 独立控制不同按钮的 Loading，谁被点了谁就一直转圈
    final isEmailBtnLoading = emailLogin.isLoading || _emailLoginInFlight;
    // 社交登录 loading 只依赖本页面的局部标志，避免 keepAlive provider
    // 的历史 AsyncLoading 状态（热重载中断、上次登录残留）污染按钮状态
    final isSocialBtnLoading = _socialOauthInFlight;

    final showGoogleButton = OauthSignInService.canShowGoogleButton;
    final showFacebookButton = OauthSignInService.canShowFacebookButton;

    return BaseScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 30.h, 24.w, 48.h),
                    // 核心防御墙：整个表单和按钮区域在 Busy 状态下完全忽略触摸事件
                    child: AbsorbPointer(
                      absorbing: isPageBusy,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ─── 头部视觉组 ───
                          Image.asset(
                            'assets/images/logo.png',
                            width: 72.w,
                            height: 72.w,
                          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),


                          Text(
                            'sign-in'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30.sp,
                              height: 1.2,
                              letterSpacing: -0.5,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary900,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                          SizedBox(height: 8.h),

                          Text(
                            'login.welcome_subtitle'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: context.textMd,
                              height: context.leadingMd,
                              fontWeight: FontWeight.w400,
                              color: context.textTertiary600,
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                          SizedBox(height: 48.h),

                          // ─── 诊断信息（仅开发模式显示） ───
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: context.bgSuccessSolid,
                                borderRadius: BorderRadius.circular(12.w),
                                border: Border.all(color: context.borderSecondary, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bug_report_rounded, size: 20.sp, color: context.textTertiary600),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'OAuth 诊断信息 (仅开发模式)',
                                        style: TextStyle(
                                          fontSize: context.textSm,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimary900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Builder(
                                    builder: (context) {
                                      final diagnostics = OauthSignInService.getOauthDiagnostics();
                                      final google = diagnostics['google'] as Map<String, dynamic>;
                                      final facebook = diagnostics['facebook'] as Map<String, dynamic>;
                                      
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildDiagnosticRow('Google 状态', google['initialized'] ? '✅ 已初始化' : '❌ 未初始化'),
                                          _buildDiagnosticRow('Google Client ID', google['clientIdConfigured'] ? '✅ 已配置' : '❌ 未配置'),
                                          _buildDiagnosticRow('Facebook 状态', facebook['initialized'] ? '✅ 已初始化' : '❌ 未初始化'),
                                          _buildDiagnosticRow('Facebook App ID', facebook['appIdConfigured'] ? '✅ 已配置' : '❌ 未配置'),
                                          _buildDiagnosticRow('Google Web Ready', _googleWebReady ? '✅ 就绪' : '❌ 未就绪'),
                                          SizedBox(height: 8.h),
                                          if (!google['initialized'] || !facebook['initialized'])
                                            Text(
                                              '💡 提示：查看浏览器控制台获取详细诊断信息',
                                              style: TextStyle(
                                                fontSize: context.textXs,
                                                color: context.textTertiary600,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                          // ─── 表单区域 ───
                          ReactiveFormConfig(
                            validationMessages: kGlobalValidationMessages,
                            child: ReactiveForm(
                              formGroup: emailForm.form,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LfInput(
                                    name: 'email',
                                    label: 'login.email.label'.tr(),
                                    hint: 'login.email.hint'.tr(),
                                    required: true,
                                    keyboardType: TextInputType.emailAddress,
                                    showErrors: (c) => c.invalid && (c.dirty || _submitted),
                                  ),
                                  SizedBox(height: 20.h),
                                  LfInput(
                                    name: 'code',
                                    label: 'login.email_code.label'.tr(),
                                    hint: 'login.email_code.hint'.tr(),
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    showErrors: (c) => c.invalid && (c.dirty || _submitted),
                                    suffixIcon: ValueListenableBuilder(
                                      valueListenable: cd.seconds,
                                      builder: (context, int seconds, _) {
                                        final running = cd.running;
                                        return Button(
                                          variant: ButtonVariant.text,
                                          loading: sendEmail.isLoading,
                                          onPressed: running || sendEmail.isLoading ? null : sendCode,
                                          child: Text(
                                            running
                                                ? 'login.resend_in'.tr(namedArgs: {'seconds': '$seconds'})
                                                : 'login.send_code'.tr(),
                                            style: TextStyle(
                                              fontSize: context.textSm,
                                              fontWeight: FontWeight.w600,
                                              color: running ? context.textDisabled : context.buttonTertiaryColorFg,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 36.h),

                                  // 登录按钮 (使用专属的 Loading 状态)
                                  Button(
                                    loading: isEmailBtnLoading,
                                    width: double.infinity,
                                    height: 52.h,
                                    onPressed: submit,
                                    child: Text(
                                      'common.login'.tr(),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 32.h),

                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
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

                                  SizedBox(height: 24.h),

                                  // ─── 社交登录按钮区域 ───
                                  if (showGoogleButton) ...[
                                    if (kIsWeb) ...[
                                      if (_googleWebReady) ...[
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48.h,
                                          child: Listener(
                                            behavior: HitTestBehavior.translucent,
                                            onPointerDown: (_) => _markGoogleWebUserInitiated(),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Opacity(
                                                  opacity: 0.01,
                                                  child: buildGoogleSignInWebButton(),
                                                ),
                                                IgnorePointer(
                                                  child: Button(
                                                    width: double.infinity,
                                                    height: 48.h,
                                                    variant: ButtonVariant.secondary,
                                                    loading: isSocialBtnLoading,
                                                    leading: Icon(Icons.g_mobiledata_rounded, size: 35.sp),
                                                    child: Text('login.oauth.google'.tr()),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Button(
                                          width: double.infinity,
                                          height: 48.h,
                                          variant: ButtonVariant.secondary,
                                          disabled: true,
                                          loading: false,
                                          onPressed: null,
                                          leading: Icon(Icons.g_mobiledata_rounded, size: 35.sp),
                                          child: Text('login.oauth.google'.tr()),
                                        ),
                                      ],
                                    ] else ...[
                                      Button(
                                        width: double.infinity,
                                        height: 48.h,
                                        variant: ButtonVariant.secondary,
                                        loading: isSocialBtnLoading,
                                        onPressed: isPageBusy || !OauthSignInService.canShowGoogleButton ? null : _loginWithGoogleOauth,
                                        leading: Icon(Icons.g_mobiledata_rounded, size: 35.sp),
                                        child: Text('login.oauth.google'.tr()),
                                      ),
                                    ],
                                    SizedBox(height: 16.h),
                                  ],

                                  if (showFacebookButton) ...[
                                    Button(
                                      width: double.infinity,
                                      height: 48.h,
                                      variant: ButtonVariant.secondary,
                                      loading: isSocialBtnLoading,
                                      onPressed: isPageBusy || !OauthSignInService.canShowFacebookButton ? null : _loginWithFacebookOauth,
                                      leading: const Icon(Icons.facebook_rounded),
                                      child: Text('login.oauth.facebook'.tr()),
                                    ),
                                    SizedBox(height: 16.h),
                                  ],

                                  if (OauthSignInService.canShowAppleButton) ...[
                                    Button(
                                      width: double.infinity,
                                      height: 48.h,
                                      variant: ButtonVariant.secondary,
                                      loading: isSocialBtnLoading,
                                      onPressed: isPageBusy ? null : _loginWithAppleOauth,
                                      leading: const Icon(Icons.apple_rounded),
                                      child: Text('login.oauth.apple'.tr()),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.05, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}