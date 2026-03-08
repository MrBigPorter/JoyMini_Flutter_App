import 'package:flutter/material.dart';
import '../../../components/share_sheet.dart';
import '../../../ui/modal/sheet/radix_sheet.dart';
import '../models/share_content.dart';
import '../index.dart';

class ShareManager {
  // Must match the path hosted on the server
  static const String _bridgeHost = "https://dev-api.joyminis.com/share.html";

  static void startShare(BuildContext context, ShareContent content) {
    // 1. Use Uri to safely assemble parameters, ensuring pid and gid match the HTML script
    final uri = Uri.parse(_bridgeHost).replace(queryParameters: {
      'pid': content.id,
      if (content.groupId != null) 'gid': content.groupId,
    });

    final data = ShareData(
      title: content.title,
      text: content.desc,      // Use dynamic copy passed from the business layer
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