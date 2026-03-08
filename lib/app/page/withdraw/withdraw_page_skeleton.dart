part of 'withdraw_page.dart';

class WithdrawSkeletonLoader extends StatelessWidget {
  const WithdrawSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //  1. 优化后的金额输入区域骨架屏 (告别大灰砖)
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部 Amount 和 Withdraw All 占位
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton.react(width: 80.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
                  Skeleton.react(width: 60.w, height: 14.h, borderRadius: BorderRadius.circular(4.r)),
                ],
              ),
              SizedBox(height: 24.h),
              // 中间的大额度输入 ₱ 0.00
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Skeleton.react(width: 24.w, height: 32.h, borderRadius: BorderRadius.circular(4.r)),
                  SizedBox(width: 12.w),
                  Skeleton.react(width: 140.w, height: 32.h, borderRadius: BorderRadius.circular(6.r)),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              SizedBox(height: 16.h),
              // 底部的 Fee / Actual Received 明细
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton.react(width: 60.w, height: 12.h, borderRadius: BorderRadius.circular(4.r)),
                  Skeleton.react(width: 40.w, height: 12.h, borderRadius: BorderRadius.circular(4.r)),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton.react(width: 100.w, height: 14.h, borderRadius: BorderRadius.circular(4.r)),
                  Skeleton.react(width: 70.w, height: 14.h, borderRadius: BorderRadius.circular(4.r)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // 2. 模拟渠道标题
        Skeleton.react(width: 120.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
        SizedBox(height: 12.h),

        // 3. 模拟渠道列表 (3个 item)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, __) => Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Skeleton.react(width: 32.w, height: 32.w, borderRadius: BorderRadius.circular(16.r)),
                SizedBox(width: 12.w),
                Skeleton.react(width: 150.w, height: 14.h, borderRadius: BorderRadius.circular(4.r)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}