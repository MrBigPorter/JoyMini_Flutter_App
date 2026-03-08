part of 'deposit_page.dart';

class DepositSkeletonLoader extends StatelessWidget {
  const DepositSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mock "Quick Select" title
        buildSkeletonRect(context, width: 100.w, height: 20.h),
        SizedBox(height: 12.h),
        // Mock quick select grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 2.4,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Skeleton.react(
            width: double.infinity,
            height: 40.h,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        SizedBox(height: 24.h),
        // Mock "Payment Method" title
        buildSkeletonRect(context, width: 140.w, height: 20.h),
        SizedBox(height: 12.h),
        // Mock channel list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, __) => Container(
            height: 72.h,
            decoration: BoxDecoration(
              color: context.utilityGray200,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5));
  }

  /// Simple skeleton placeholder
  Widget buildSkeletonRect(BuildContext context, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.utilityGray200,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}