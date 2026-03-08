import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/format_helper.dart';

import 'package:flutter_app/core/models/balance.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/wallet_provider.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/core/store/wallet_store.dart';

import 'package:flutter_app/utils/form/validators.dart';
import 'package:flutter_app/utils/form/withdraw_froms/withdraw_form.dart';
import '../../../utils/form/validation/k_withdraw_validation_messages.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/app/page/transaction_record_page.dart';
import 'package:flutter_app/app/page/withdraw/withdraw_success_modal.dart';

// Declare parts
part 'withdraw_page_logic.dart';
part 'withdraw_page_ui.dart';
part 'withdraw_page_skeleton.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

// Mixin logic via WithdrawPageLogic
class _WithdrawPageState extends ConsumerState<WithdrawPage> with WithdrawPageLogic {

  @override
  Widget build(BuildContext context) {
    // Watch data streams
    final wallet = ref.watch(walletProvider.select((s) => s));
    final withdrawable = wallet.realBalance;
    final channelsAsync = ref.watch(clientPaymentChannelsWithdrawProvider);

    // Bind listeners (Logic part)
    setupListeners(withdrawable);

    final isPageLoading = channelsAsync.isLoading && !channelsAsync.hasValue;

    return ReactiveFormConfig(
      validationMessages: kWithdrawValidationMessages,
      child: ReactiveForm(
        formGroup: formGroup.form,
        child: BaseScaffold(
          title: 'withdraw.title'.tr(),
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildBalanceCard(withdrawable),
                  SizedBox(height: 20.h),

                  if (isPageLoading)
                    const WithdrawSkeletonLoader() // Elegant standalone skeleton
                  else if (channelsAsync.hasError)
                    buildErrorState()
                  else ...[
                      buildAmountInputSection(withdrawable),
                      SizedBox(height: 20.h),

                      Text('withdraw.method_title'.tr(), style: headerStyle),
                      SizedBox(height: 12.h),
                      buildChannelList(channelsAsync.value ?? []),
                      SizedBox(height: 20.h),

                      Text('withdraw.account_details_title'.tr(), style: headerStyle),
                      SizedBox(height: 12.h),
                      buildAccountForm(),
                    ],

                  SizedBox(height: 20.h),
                  if (!isPageLoading) buildSafetyNotice(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          bottomNavigationBar: buildBottomAction(isPageLoading),
        ),
      ),
    );
  }
}