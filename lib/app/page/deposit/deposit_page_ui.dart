part of 'deposit_page.dart';

/// Extension: Handles rendering of UI components to prevent main file bloat
extension DepositPageUI on _DepositPageState {

  /// Error state
  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48.w, color: context.utilityGray400),
            SizedBox(height: 16.h),
            Text('Failed to load channels', style: TextStyle(color: context.textSecondary700)),
            SizedBox(height: 8.h),
            Button(
              variant: ButtonVariant.ghost,
              height: 36.h,
              onPressed: () => ref.refresh(clientPaymentChannelsRechargeProvider),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }

  /// Real content area
  Widget buildMainContent(List<PaymentChannelConfigItem> channels) {
    if (channels.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No payment channels available"),
      ));
    }

    final List<num> displayOptions =
    (selectedChannel?.fixedAmounts != null && selectedChannel!.fixedAmounts!.isNotEmpty)
        ? selectedChannel!.fixedAmounts!
        : defaultAmounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayOptions.isNotEmpty) ...[
          Text(
            'Quick Select',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.textSecondary700,
            ),
          ).animate().fadeIn(duration: 400.ms),
          SizedBox(height: 12.h),
          buildQuickGrid(displayOptions),
          SizedBox(height: 24.h),
        ],

        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: context.textSecondary700,
          ),
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: 12.h),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: channels.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) => buildChannelItem(channels[index]),
        ),
      ],
    );
  }

  Widget buildAmountInputCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter Amount',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary700,
                ),
              ),
              if (selectedChannel != null)
                Text(
                  'Min ₱${FormatHelper.formatCurrency(selectedChannel!.minAmount, decimalDigits: 0, symbol: '')}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textTertiary600,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₱',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary900,
                  height: 1.2,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ReactiveTextField<String>(
                  formControlName: 'amount',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  readOnly: !(selectedChannel?.isCustom ?? true),
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary900,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    contentPadding: EdgeInsets.zero,
                    errorStyle: const TextStyle(height: 0),
                    hintStyle: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: context.utilityGray300,
                    ),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 8.h),
            height: 1,
            color: context.utilityGray200,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget buildQuickGrid(List<num> options) {
    return Padding(
      padding: EdgeInsets.zero,
      child: ReactiveValueListenableBuilder<String>(
        formControlName: 'amount',
        builder: (context, control, child) {
          final currentValStr = control.value ?? '';

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 2.4,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final amount = options[index];
              final amountStr = amount.toStringAsFixed(0);
              final isSelected = currentValStr == amountStr;

              return QuickSelectChip(
                amount: amount.toInt(),
                isSelected: isSelected,
                index: index,
                onTap: () {
                  HapticFeedback.selectionClick();
                  control.value = amountStr;
                  FocusScope.of(context).unfocus();
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildChannelItem(PaymentChannelConfigItem channel) {
    final isSelected = selectedChannel?.id == channel.id;

    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() {
          selectedChannel = channel;
          formGroup.form.control('amount').value = '';
          updateValidators();
        });
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? context.utilityBrand500 : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: context.bgSecondary,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                // Icon fallback logic
                child: (channel.icon != null && channel.icon!.isNotEmpty)
                    ? Image.network(
                  channel.icon!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.account_balance_wallet,
                    size: 24.w,
                    color: context.utilityBrand500,
                  ),
                )
                    : Icon(
                  Icons.account_balance_wallet,
                  size: 24.w,
                  color: context.utilityBrand500,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Instant • Fee 0%",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.utilitySuccess500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 24.w, color: context.utilityBrand500)
            else
              Icon(Icons.circle_outlined, size: 24.w, color: context.utilityGray300),
          ],
        ),
      ),
    );
  }

  Widget buildBottomBar(bool isPageLoading) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final rechargeState = ref.watch(createRechargeProvider);

    // If fetching channel data or submitting order, consider it busy/loading
    final bool isBusy = isPageLoading || rechargeState.isLoading;

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: 12.h + bottom,
      ),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(top: BorderSide(color: context.utilityGray100)),
      ),
      child: ReactiveFormConsumer(
        builder: (context, form, child) {
          final isEnabled = !isPageLoading && form.valid && selectedChannel != null;

          return Button(
            loading: isBusy,
            disabled: !isEnabled,
            onPressed: isEnabled ? onSubmit : null,
            width: double.infinity,
            height: 52.h,
            child: Text(
              'Deposit Now',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// Standalone Component
// ==========================================

/// Standalone Chip component
class QuickSelectChip extends StatelessWidget {
  final int amount;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const QuickSelectChip({
    super.key,
    required this.amount,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? context.utilityBrand500 : context.bgPrimary,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? Colors.transparent : context.utilityGray200,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: context.utilityBrand500.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                FormatHelper.formatCurrency(amount, decimalDigits: 0),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : context.textPrimary900,
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                    duration: 1200.ms,
                    color: Colors.white.withOpacity(0.3),
                    angle: -0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutQuad);
  }
}