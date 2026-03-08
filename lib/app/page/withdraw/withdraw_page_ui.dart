part of 'withdraw_page.dart';

/// Extension: Handles rendering of UI components to prevent main file bloat
extension WithdrawPageUI on _WithdrawPageState {

  TextStyle get headerStyle => TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: context.textSecondary700
  );

  Widget buildBalanceCard(double balance) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: context.bgBrandPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'withdraw.balance_label'.tr(),
              style: TextStyle(color: Colors.white70, fontSize: 13.sp)
          ),
          SizedBox(height: 8.h),
          Text(
              FormatHelper.formatCurrency(balance),
              style: TextStyle(color: Colors.white, fontSize: 30.sp, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget buildAmountInputSection(double currentBalance) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.borderSecondary),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('withdraw.amount_label'.tr(), style:  TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary900),),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final channelMax = selectedChannel?.maxAmount ?? double.infinity;
                  final smartMax = (currentBalance < channelMax) ? currentBalance : channelMax;
                  formGroup.amountControl.value = smartMax.toStringAsFixed(2);
                },
                child: Text(
                    'withdraw.withdraw_all'.tr(),
                    style: TextStyle(color: context.textBrandPrimary900, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ReactiveTextField<String>(
            formControlName: WithdrawFormModelForm.amountControlName,
            showErrors: (control) => control.invalid && control.touched,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary900,
            ),
            decoration: InputDecoration(
              prefixText: '₱ ',
              prefixStyle: TextStyle(
                fontSize: 24.sp,
                color: context.textPrimary900,
                fontWeight: FontWeight.bold,
              ),
              hintStyle: TextStyle(
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
                color: context.utilityGray300,
              ),
              hintText: '0.00',
              border: InputBorder.none,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
          ),
          const Divider(),
          SizedBox(height: 8.h),
          ReactiveValueListenableBuilder<String>(
            formControlName: WithdrawFormModelForm.amountControlName,
            builder: (context, control, child) {
              final amount = double.tryParse(control.value ?? '0') ?? 0.0;
              final feeRate = selectedChannel?.feeRate ?? 0.0;
              final fixedFee = selectedChannel?.feeFixed ?? 0.0;

              double fee = 0.0;
              if (amount > 0) {
                fee = (amount * feeRate) + fixedFee;
              }
              final actual = (amount - fee > 0) ? amount - fee : 0.0;

              return Column(
                children: [
                  buildDetailRow('withdraw.fee_label'.tr(), '- ${FormatHelper.formatCurrency(fee)}'),
                  SizedBox(height: 4.h),
                  buildDetailRow(
                    'withdraw.actual_received_label'.tr(),
                    FormatHelper.formatCurrency(actual),
                    isBold: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildChannelList(List<PaymentChannelConfigItem> channels) {
    if (channels.isEmpty) return Text("withdraw.no_methods".tr());

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = selectedChannel?.id == channel.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedChannel = channel;
              final currentBalance = ref.read(walletProvider).realBalance;
              updateValidators(currentBalance);
            });
          },
          child: AnimatedContainer(
            duration: 200.ms,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? context.textBrandPrimary900 : context.borderSecondary,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(color: context.bgSecondary, shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.network(
                      channel.icon ?? '',
                      errorBuilder: (_, __, ___) => Icon(Icons.account_balance_wallet, size: 20.w),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(channel.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: context.textBrandPrimary900),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildAccountForm() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.borderSecondary),
      ),
      child: Column(
        children: [
          ReactiveTextField(
            formControlName: WithdrawFormModelForm.accountNameControlName,
            textInputAction: TextInputAction.next,
            showErrors: (control) => control.invalid && control.touched,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
            ),
            decoration: InputDecoration(
              labelText: 'withdraw.label_account_name'.tr(),
              labelStyle: TextStyle(
                color: context.textTertiary600,
                fontSize: 14.sp,
              ),
              hintText: 'withdraw.hint_account_name'.tr(),
              hintStyle: TextStyle(color: context.utilityGray300),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: context.textTertiary600,
                size: 22.w,
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 40.w),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            validationMessages: {
              ValidationMessage.required: (_) => 'withdraw.error_account_name_required'.tr(),
            },
          ),
          Divider(height: 1, color: context.utilityGray200),
          ReactiveTextField(
            formControlName: WithdrawFormModelForm.accountNumberControlName,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            showErrors: (control) => control.invalid && control.touched,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
              fontFamily: 'Monospace',
            ),
            decoration: InputDecoration(
              labelText: 'withdraw.label_account_number'.tr(),
              labelStyle: TextStyle(
                color: context.textTertiary600,
                fontSize: 14.sp,
              ),
              hintText: 'withdraw.hint_account_number'.tr(),
              hintStyle: TextStyle(color: context.utilityGray300),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.credit_card_outlined,
                color: context.textTertiary600,
                size: 22.w,
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 40.w),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            validationMessages: {
              ValidationMessage.required: (_) => 'withdraw.error_account_number_required'.tr(),
            },
          ),
        ],
      ),
    );
  }

  Widget buildBottomAction(bool isPageLoading) {
    final createWithdrawState = ref.watch(createWithdrawProvider);
    final isSubmitting = createWithdrawState.isLoading;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final height = keyboardHeight > 0 ? keyboardHeight : MediaQuery.of(context).padding.bottom + 12.h;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, height),
      color: context.bgPrimary,
      child: ReactiveFormConsumer(
        builder: (context, form, child) {
          final isDisabled = isPageLoading || isSubmitting || selectedChannel == null;

          return Button(
            loading: isSubmitting,
            width: double.infinity,
            height: 52.h,
            onPressed: isDisabled ? null : handleWithdraw,
            child: Text('withdraw.btn_confirm_withdrawal'.tr()),
          );
        },
      ),
    );
  }

  Widget buildSafetyNotice() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: context.bgSecondary, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16.sp, color: context.textSecondary700),
          SizedBox(width: 8.w),
          Expanded(child: Text('withdraw.safety_notice'.tr(), style: TextStyle(fontSize: 11.sp, color: context.textSecondary700))),
        ],
      ),
    );
  }

  Widget buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: context.textTertiary600)),
        Text(
            value,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? context.utilitySuccess600 : context.textPrimary900
            )
        ),
      ],
    );
  }

  Widget buildErrorState() => SizedBox(
      height: 100.h,
      child: Center(child: Text("withdraw.error_load_methods".tr()))
  );
}