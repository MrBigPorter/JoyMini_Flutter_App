import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/models/clickable_resource.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/jump_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';

import 'package:flutter_app/utils/media/remote_url_builder.dart';

/// 首页广告位 Home Ad
/// 包含单图广告、三图广告等模块 including single-image ad, three-image ad, etc.
class HomeAd extends StatelessWidget {
  final List<AdRes> list;

  const HomeAd({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final visible = list.where((e) => e.status == 1).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      children: visible.map((item) {

        /// sortType 1 单图广告 single-image ad
        if (item.sortType == 1) {
          return SingleAd(ad: item);
        } else {
          /// sortType 2 三图广告 three-image ad
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: GridAd(ad: item),
          );
        }
      }).toList(),
    );
  }
}

/// 广告位 Grid Ad - 三图广告 three-image ad
class GridAd extends StatelessWidget {
  final AdRes? ad;

  const GridAd({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final List<BannerItem> bannerArray = ad?.bannerArray ?? const [];
    if (bannerArray.isEmpty) return const SizedBox.shrink();

    if (bannerArray.length < 3) {
      // Degrade to a simple row when backend returns fewer than 3 banners.
      return Row(
        children: [
          for (var i = 0; i < bannerArray.length; i++) ...[
            Expanded(
              child: AdImage(
                src: bannerArray[i].img,
                width: double.infinity,
                height: 130,
                relatedTitleId: bannerArray[i].relatedTitleId,
                jumpCate: bannerArray[i].jumpCate,
                jumpUrl: bannerArray[i].jumpUrl,
                videoUrl: bannerArray[i].videoUrl,
              ),
            ),
            if (i < bannerArray.length - 1) SizedBox(width: 8.w),
          ]
        ],
      );
    }

    final BannerItem? first = bannerArray.isNotEmpty ? bannerArray[0] : null;
    final BannerItem? second = bannerArray.length > 1 ? bannerArray[1] : null;
    final BannerItem? third = bannerArray.length > 2 ? bannerArray[2] : null;


    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AdImage(
          src: first?.img ?? '',
          width: 205,
          height: 267,
          relatedTitleId: first?.relatedTitleId,
          jumpCate: first?.jumpCate,
          jumpUrl: first?.jumpUrl,
          videoUrl: first?.videoUrl,
        ),
        SizedBox(width: 8.w,),
        Column(
          children: [
            AdImage(
              src: second?.img ?? '',
              width: 130,
              height: 130,
              relatedTitleId: second?.relatedTitleId,
              jumpCate: second?.jumpCate,
              jumpUrl: second?.jumpUrl,
              videoUrl: second?.videoUrl,
            ),
            SizedBox(height: 8.h),
            AdImage(
              src: third?.img ?? '',
              width: 130,
              height: 130,
              relatedTitleId: third?.relatedTitleId,
              jumpCate: third?.jumpCate,
              jumpUrl: third?.jumpUrl,
              videoUrl: third?.videoUrl,
            ),

          ],
        )
      ],
    );
  }
}

/// 广告位 Single Ad - 单图广告 single-image ad
class SingleAd extends StatelessWidget {
  final AdRes? ad;

  const SingleAd({super.key, required this.ad});

  @override
  build(BuildContext context){
    final src = ad?.img ?? '';
    if (src.isEmpty) return const SizedBox.shrink();

    return AdImage(
      src: src,
      width: double.infinity,
      height: 114,
      relatedTitleId: ad?.relatedTitleId,
      jumpCate: ad?.jumpCate,
      jumpUrl: ad?.jumpUrl,
      videoUrl: ad?.videoUrl,
    );
  }
}

/// 广告图片 Ad Image
class AdImage extends StatelessWidget {
  final String src;
  final double width;
  final double height;
  final String? relatedTitleId;
  final int? jumpCate;
  final String? jumpUrl;
  final String? videoUrl;
  final String? alt;
  final BoxFit? fit;

  const AdImage({
    super.key,
    required this.src,
    required this.width,
    required this.height,
    this.relatedTitleId,
    this.jumpCate,
    this.jumpUrl,
    this.videoUrl,
    this.alt = '',
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width.isFinite ? width.w : null;
    final resolvedHeight = height.isFinite ? height.h : null;

    if (src.isEmpty) {
      return Container(
        width: resolvedWidth,
        height: resolvedHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(CupertinoIcons.photo, size: 18.w, color: Colors.grey.shade500),
      );
    }

    return GestureDetector(
      onTap: () {
        final defaultClickable = DefaultClickableResource(
          jumpCate: jumpCate,
          jumpUrl: jumpUrl,
          relatedTitleId: relatedTitleId,
          videoUrl: videoUrl,
        );
        JumHelper.handleTap(context, defaultClickable);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: AppCachedImage(
          RemoteUrlBuilder.fitAbsoluteUrl(src),
          width: resolvedWidth,
          height: resolvedHeight,
        ),
      ),
    );
  }
}
