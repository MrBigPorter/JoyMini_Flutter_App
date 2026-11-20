import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/ai_action_model.dart';

/// 确认卡片组件 — 显示操作详情 + [确认] [取消] 按钮
class AiConfirmCard extends StatelessWidget {
  final AiConfirmData data;
  final ConfirmCardStatus status;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? errorMessage;
  final ValueChanged<String>? onOtpSubmit; // 提现 OTP 验证码提交回调

  const AiConfirmCard({
    super.key,
    required this.data,
    required this.status,
    required this.onConfirm,
    required this.onCancel,
    this.errorMessage,
    this.onOtpSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              color: const Color(0xFFF5F5F5),
            ),
            child: Icon(
              Icons.support_agent,
              color: const Color(0xFF9E9E9E),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 8.w),
          // 卡片内容
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  SizedBox(height: 8.h),
                  _buildParams(),
                  SizedBox(height: 8.h),
                  _buildStatusBar(),
                  SizedBox(height: 8.h),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(_actionIcon, size: 18.sp),
        SizedBox(width: 4.w),
        Text(
          _actionTitle,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildParams() {
    final entries = _paramEntries;
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      children: entries
          .map(
            (e) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 64.w,
                    child: Text(
                      e.label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatusBar() {
    switch (status) {
      case ConfirmCardStatus.expired:
        return Text(
          '已过期，请让 AI 重新发起',
          style: TextStyle(fontSize: 11.sp, color: Colors.orange),
        );
      case ConfirmCardStatus.loading:
        return Row(
          children: [
            SizedBox(
              width: 12.w,
              height: 12.w,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 6.w),
            Text(
              '处理中...',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
            ),
          ],
        );
      case ConfirmCardStatus.failed:
        return Text(
          errorMessage ?? '操作失败',
          style: TextStyle(fontSize: 11.sp, color: Colors.red),
        );
      case ConfirmCardStatus.success:
      case ConfirmCardStatus.cancelled:
        return const SizedBox.shrink();
      case ConfirmCardStatus.pending:
        return Text(
          '请在 60 秒内确认',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
        );
      case ConfirmCardStatus.needOtp:
        return Text(
          'Please enter the OTP code sent to your registered mobile number to complete the withdrawal.Valid for 60 seconds.',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
        );
    }
  }

  Widget _buildButtons() {
    if (status == ConfirmCardStatus.needOtp) {
      return _OtpInput(onSubmit: (code) => onOtpSubmit?.call(code));
    }
    final disabled =
        status == ConfirmCardStatus.expired ||
        status == ConfirmCardStatus.loading;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36.h,
            child: OutlinedButton(
              onPressed: disabled ? null : onCancel,
              child: Text('取消', style: TextStyle(fontSize: 13.sp)),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: SizedBox(
            height: 36.h,
            child: ElevatedButton(
              onPressed: disabled ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF95EC69),
                foregroundColor: Colors.black87,
              ),
              child: Text('确认', style: TextStyle(fontSize: 13.sp)),
            ),
          ),
        ),
      ],
    );
  }

  IconData get _actionIcon {
    switch (data.action) {
      case 'withdraw':
        return Icons.account_balance;
      case 'claim_coupon':
        return Icons.card_giftcard;
      case 'redeem_code':
        return Icons.vpn_key;
      case 'draw':
        return Icons.casino;
      case 'delete_address':
        return Icons.delete;
      default:
        return Icons.description;
    }
  }

  String get _actionTitle {
    switch (data.action) {
      case 'withdraw':
        return '提现确认';
      case 'claim_coupon':
        return '领券确认';
      case 'redeem_code':
        return '兑换码确认';
      case 'draw':
        return '抽奖确认';
      case 'delete_address':
        return '删除地址确认';
      default:
        return '操作确认';
    }
  }

  List<_ParamEntry> get _paramEntries {
    switch (data.action) {
      case 'withdraw':
        return [
          _ParamEntry('金额', data.summary['amount']?.toString() ?? ''),
          _ParamEntry('渠道', data.summary['channelId']?.toString() ?? ''),
          _ParamEntry('账号', data.summary['account']?.toString() ?? ''),
          _ParamEntry('户主', data.summary['accountName']?.toString() ?? ''),
          _ParamEntry('手续费', data.summary['fee']?.toString() ?? ''),
          _ParamEntry('到账', data.summary['netAmount']?.toString() ?? ''),
        ];
      case 'claim_coupon':
        return [_ParamEntry('优惠券', data.summary['couponId']?.toString() ?? '')];
      case 'redeem_code':
        return [_ParamEntry('兑换码', data.summary['code']?.toString() ?? '')];
      case 'draw':
        return [_ParamEntry('抽奖券', data.summary['ticketId']?.toString() ?? '')];
      case 'delete_address':
        return [_ParamEntry('地址', data.summary['addressId']?.toString() ?? '')];
      default:
        return [];
    }
  }
}

class _ParamEntry {
  final String label;
  final String value;
  _ParamEntry(this.label, this.value);
}

/// 验证码输入框 — 自己管 controller，提交时把码回调出去
class _OtpInput extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  const _OtpInput({required this.onSubmit});

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'Please enter the OTP code',
              counterText: '',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        ElevatedButton(
          onPressed: () => widget.onSubmit(_controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF95EC69),
            foregroundColor: Colors.black87,
          ),
          child: Text('Submit', style: TextStyle(fontSize: 13.sp)),
        ),
      ],
    );
  }
}
