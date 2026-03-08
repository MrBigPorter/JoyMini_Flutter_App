part of 'deposit_page.dart';

/// Mixin: Handles core business logic for the deposit page
mixin DepositPageLogic on ConsumerState<DepositPage> {
  // Currently selected channel
  PaymentChannelConfigItem? selectedChannel;

  // Default quick amounts (shown when backend config is missing or fails to load)
  final List<num> defaultAmounts = [100, 200, 500, 1000, 2000, 5000];

  late final DepositFormModelForm formGroup = DepositFormModelForm(
    DepositFormModelForm.formElements(const DepositFormModel()),
    null,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(clientPaymentChannelsRechargeProvider);

      // Only invalidate if we have data and it's not currently loading, to avoid disrupting an in-progress fetch
      // First load will be triggered by the page build, so this is mainly for when user returns to this page and we want to refresh the channels
      if (state.hasValue && !state.isLoading) {
        ref.invalidate(clientPaymentChannelsRechargeProvider);
      }
    });
  }

  /// Setup Riverpod page-level listeners
  void setupListeners() {
    // Logic optimization: listen to data changes, set default selected item
    ref.listen<AsyncValue<List<PaymentChannelConfigItem>>>(
      clientPaymentChannelsRechargeProvider,
          (previous, next) {
        next.whenData((channels) {
          // If list is not empty and no item is selected, select the first one by default
          if (channels.isNotEmpty && selectedChannel == null) {
            setState(() {
              selectedChannel = channels.first;
              updateValidators();
            });
          }
        });
      },
    );
  }

  /// Update form validation rules (Min/Max)
  void updateValidators() {
    if (selectedChannel == null) return;

    final control = formGroup.form.control('amount');
    control.setValidators([
      DepositAmount(
        minAmount: selectedChannel!.minAmount,
        maxAmount: selectedChannel!.maxAmount,
      )
    ]);
    control.updateValueAndValidity();
  }

  Future<void> onSubmit() async {
    if (formGroup.form.valid && selectedChannel != null) {
      FocusScope.of(context).unfocus();
      final amount = formGroup.form.control('amount').value;
      try {
        // Call create order API
        final response = await ref.read(createRechargeProvider.notifier).create(
          CreateRechargeDto(
            amount: num.parse(amount),
            channelId: selectedChannel!.id,
            redirectUrl: JumHelper.getBaseRedirectUrl(),
          ),
        );

        if (response != null && response.payUrl.isNotEmpty) {
          if (!mounted) return;

          ref.read(transactionDirtyProvider(UiTransactionType.deposit).notifier).state = true;

          // Navigate to Webview payment
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentWebViewPage(
                url: response.payUrl,
                orderNo: response.rechargeNo,
              ),
            ),
          );
        } else {
          throw 'Payment URL is empty';
        }
      } catch (e) {
        if (!mounted) return;
        debugPrint('Deposit Error: $e');
        // Toast can be added here
      } finally {
        if (mounted) {
          ref.read(walletProvider.notifier).fetchBalance();
        }
      }
    }
  }
}