import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../components/share_sheet.dart';
import '../../../ui/modal/sheet/radix_sheet.dart';
import '../models/share_content.dart';
import '../index.dart';
import '../../../core/store/config_store.dart';

class ShareManager {
  static void startShare(BuildContext context, ShareContent content) {
    // Get webBaseUrl from configuration
    final container = ProviderScope.containerOf(context);
    final config = container.read(configProvider);
    final webBaseUrl = config.webBaseUrl;
    
    // Build share bridge URL from configuration
    final bridgeHost = webBaseUrl.isNotEmpty ? '$webBaseUrl/share.html' : 'https://dev-api.joyminis.com/share.html';
    
    // 1. Use Uri to safely assemble parameters, ensuring pid and gid match the HTML script
    final uri = Uri.parse(bridgeHost).replace(queryParameters: {
      'pid': content.id,
      if (content.groupId != null) 'gid': content.groupId,
    });

    //  核心：清洗文字里的 HTML 标签，并在结尾加两个换行符 \n\n
    final cleanDesc = content.desc.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    final data = ShareData(
      title: content.title,
      text: "$cleanDesc\n\n", // 使用清洗后的文本，必须有 \n\n
      url: uri.toString(),     // Generated H5 intermediate link
      imageUrl: content.imageUrl,
    );

    // 2. Invoke the underlying share component
    ShareService.openSystemOrSheet(
      data,
          () => RadixSheet.show(
        headerBuilder: (context) => SharePost(data: data),
        builder: (context, close) => ShareSheet(data: data),
      ),
    );
  }
}
