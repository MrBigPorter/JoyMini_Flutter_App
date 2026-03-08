import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/app/page/transaction_record_page.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/providers/wallet_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/form/deposit_form/deposit_form.dart';
import 'package:flutter_app/utils/format_helper.dart';
import '../../../core/models/balance.dart';
import '../../../core/store/wallet_store.dart';
import '../../../utils/form/validation/k_deposit_validation_messages.dart';
import '../../../utils/form/validators.dart';
import '../../../utils/jump_helper.dart';
import 'payment_webview_page.dart';

// Declare parts
part 'deposit_page_logic.dart';
part 'deposit_page_ui.dart';
part 'deposit_page_skeleton.dart';

class DepositPage extends ConsumerStatefulWidget {
  const DepositPage({super.key});

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

// Mixin logic via DepositPageLogic
class _DepositPageState extends ConsumerState<DepositPage> with DepositPageLogic {

  @override
  Widget build(BuildContext context) {
    // Watch channel configuration Provider
    final channelsAsync = ref.watch(clientPaymentChannelsRechargeProvider);

    // Bind listeners (Logic part)
    setupListeners();

    // Check if page is loading (and has no old data)
    final bool isPageLoading = channelsAsync.isLoading && !channelsAsync.hasValue;

    return ReactiveFormConfig(
      validationMessages: kDepositValidationMessages,
      child: ReactiveForm(
        formGroup: formGroup.form,
        child: BaseScaffold(
          title: 'Deposit',
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),

                  // 1. Amount input box (disabled during loading to prevent misoperation)
                  IgnorePointer(
                    ignoring: isPageLoading,
                    child: buildAmountInputCard(),
                  ),

                  SizedBox(height: 24.h),

                  // 2. Display content based on state: Skeleton OR Error Page OR Real Content
                  if (isPageLoading)
                    const DepositSkeletonLoader()
                  else if (channelsAsync.hasError)
                    buildErrorState()
                  else
                    buildMainContent(channelsAsync.value ?? []),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Bottom button
          bottomNavigationBar: buildBottomBar(isPageLoading),
        ),
      ),
    );
  }
}