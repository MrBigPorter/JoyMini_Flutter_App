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

    // Riverpod 不允许在构建期间直接改 provider，这里放到微任务中执行
    Future.microtask(() {
      if (!mounted) return;
      ref.read(authLoginGoogleCtrlProvider.notifier).reset();
      ref.read(authLoginFacebookCtrlProvider.notifier).reset();
      ref.read(authLoginAppleCtrlProvider.notifier).reset();
    });

    // 检查是否有中断的OAuth登录需要恢复（使用全局处理器）
    _checkForOAuthRecovery();
  }

  /// 检查并恢复中断的OAuth登录
  Future<void> _checkForOAuthRecovery() async {
    if (!mounted || _oauthRecoveryStarted) return;

    // dedicated OAuth processing 页面已接管 callback 恢复，登录页仅保留入口回退
    if (isAppRouterReady) {
      final currentPath = appRouter.routeInformationProvider.value.uri.path;
      if (currentPath == '/oauth/processing') {
        return;
      }
    }

    _oauthRecoveryStarted = true;

    // ── Web 优先：检查 Firebase 重定向结果 ──────────────────────────────────
    // 当 signInWithPopup 在移动浏览器 / PWA / 弹窗拦截场景下 fallback 为重定向
    // 模式时，页面会重新加载，signInWithPopup 的 Promise 已丢失。
    // 必须调用 getRedirectResult() 才能取回凭证，否则页面停在 login 啥也不做。
    if (kIsWeb) {
      final handled = await _checkWebRedirectResult();
      if (handled) return; // 已处理，不再执行下面的 native 恢复
    }

    // ── Native（iOS/Android）恢复：检查内存中缓存的 token ─────────────────
    // 只有存在可恢复 token 时才显示 busy，避免无 token 时页面闪一下 loading
    final hasRecoverableGoogleToken = OAuthStateManager.hasValidIdToken(
      'google',
    );

    // 立即显示过渡中的忙碌状态，避免出现"晚一拍"的视觉延迟
    if (mounted && hasRecoverableGoogleToken) {
      setState(() {
        _socialOauthInFlight = true;
      });
    }

    debugPrint('[LoginPageLogic] Checking for interrupted OAuth login...');

    // 使用全局处理器检查恢复
    // 全局处理器不依赖页面状态，即使页面销毁也能工作
    try {
      await GlobalOAuthHandler.checkAndRecoverInterruptedOAuth();
    } finally {
      if (mounted && !_isSuccessRedirecting && hasRecoverableGoogleToken) {
        setState(() {
          _socialOauthInFlight = false;
        });
      }
    }
  }

  /// Web 专用：检查 Firebase 重定向结果并完成登录流程。
  ///
  /// 适用场景：移动浏览器 / PWA / 弹窗被拦截，Firebase 内部将
  /// signInWithPopup 降级为 redirect 模式，页面重载后 signInWithPopup 的
  /// Promise 已丢失，必须调用此方法取回凭证。
  ///
  /// Returns true if a redirect result was found (processed or errored),
  /// false if no redirect result was pending.
  Future<bool> _checkWebRedirectResult() async {
    try {
      debugPrint('[LoginPageLogic] [Web] Checking Firebase redirect result...');

      final authResult =
          await FirebaseOauthSignInService.getWebRedirectAuthResult();

      if (!mounted) return false;

      if (authResult == null) {
        debugPrint('[LoginPageLogic] [Web] No redirect result pending');
        return false;
      }

      debugPrint(
        '[LoginPageLogic] [Web] Redirect result found! '
        'provider=${authResult.providerId}',
      );

      // 有重定向结果，立即进入加载态
      setState(() => _socialOauthInFlight = true);
      _isSuccessRedirecting = true;

      switch (authResult.providerId) {
        case 'facebook.com':
          // Facebook web redirect → Firebase ID Token 路径
          final apiResult = await ref
              .read(authLoginFacebookCtrlProvider.notifier)
              .run((
                idToken: authResult.idToken,
                accessToken: null,
                userId: null,
                inviteCode: _currentInviteCode(),
              ));
          if (mounted) {
            await _syncLoginTokens(
              apiResult.tokens.accessToken,
              apiResult.tokens.refreshToken,
            );
          }

        case 'apple.com':
          // Apple web redirect → Firebase ID Token 路径
          final apiResult = await ref
              .read(authLoginAppleCtrlProvider.notifier)
              .run((
                idToken: authResult.idToken,
                inviteCode: _currentInviteCode(),
              ));
          if (mounted) {
            await _syncLoginTokens(
              apiResult.tokens.accessToken,
              apiResult.tokens.refreshToken,
            );
          }

        default:
          // Google（或未知 provider，默认走 Google 处理器）
          // showGlobalLoading: false — 登录页自身 _socialOauthInFlight 已提供反馈
          await GlobalOAuthHandler.handleGoogleOAuthCallback(
            idToken: authResult.idToken,
            showGlobalLoading: false,
          );
      }

      debugPrint(
        '[LoginPageLogic] [Web] Redirect OAuth login completed successfully',
      );
      return true;
    } catch (e) {
      debugPrint('[LoginPageLogic] [Web] Redirect result processing failed: $e');
      _isSuccessRedirecting = false;
      if (mounted) {
        setState(() => _socialOauthInFlight = false);
        if (e is! OauthCancelledException) {
          _handleOauthError(e);
        }
      }
      // 返回 true：已检测到 redirect 结果（即使处理失败），阻止重复 native 恢复
      return true;
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
        _isSuccessRedirecting)
      return;

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
        await _syncLoginTokens(
          result.tokens.accessToken,
          result.tokens.refreshToken,
        );
      }
    } catch (e) {
      // 兜底错误
    } finally {
      if (mounted && !_isSuccessRedirecting)
        setState(() => _emailLoginInFlight = false);
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
      debugPrint(
        '[LoginPageLogic] Starting Google OAuth with global processor...',
      );

      // 使用新的全局处理器方法
      // 这个方法会处理整个流程：Firebase登录 → 后端API → Token同步 → 导航
      await FirebaseOauthSignInService.signInWithGoogleAndProcess();

      // 如果成功，设置重定向标志
      _isSuccessRedirecting = true;
      debugPrint(
        '[LoginPageLogic] Google OAuth completed successfully via global processor',
      );

      // 注意：这里不重置loading状态，让全局处理器处理跳转
      // 全局处理器会添加延迟确保用户看到loading状态
      // 页面跳转后会自动销毁，不需要手动重置
    } catch (e) {
      debugPrint('[LoginPageLogic] Google OAuth error: $e');
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        if (!_oauthCancelled && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted && !_isSuccessRedirecting) {
          debugPrint('[LoginPageLogic] Resetting social OAuth loading state');
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
        final apiResult = await ref
            .read(authLoginFacebookCtrlProvider.notifier)
            .run((
              idToken: null,
              accessToken: result['accessToken'],
              userId: result['userId'],
              inviteCode: _currentInviteCode(),
            ));

        if (!mounted) return; //  关键防线

        _isSuccessRedirecting = true;
        await _syncLoginTokens(
          apiResult.tokens.accessToken,
          apiResult.tokens.refreshToken,
        );
      } else {
        final apiResult = await ref
            .read(authLoginFacebookCtrlProvider.notifier)
            .run((
              idToken: result['idToken'],
              accessToken: null,
              userId: null,
              inviteCode: _currentInviteCode(),
            ));

        if (!mounted) return; //  关键防线

        _isSuccessRedirecting = true;
        await _syncLoginTokens(
          apiResult.tokens.accessToken,
          apiResult.tokens.refreshToken,
        );
      }

      // 成功登录后，立即重置loading状态（即使页面即将跳转）
      if (mounted) {
        setState(() => _socialOauthInFlight = false);
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
      await _syncLoginTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );

      // 成功登录后，立即重置loading状态（即使页面即将跳转）
      if (mounted) {
        setState(() => _socialOauthInFlight = false);
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
    if (cd.running ||
        _emailLoginInFlight ||
        _socialOauthInFlight ||
        _isSuccessRedirecting)
      return;

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
