import 'dart:async';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Assuming your ShareData is imported here
import 'package:flutter_app/features/share/models/share_data.dart';

class ShareService {

  // ==========================================
  // 1. Private Helpers
  // ==========================================

  /// Downloads the image as a preview thumbnail with a 3-second timeout to prevent freezing.
  static Future<XFile?> _ensurePreviewThumbnail(ShareData d) async {
    if (d.previewThumbnail != null) return d.previewThumbnail;
    if (d.imageUrl == null || d.imageUrl!.isEmpty) return null;

    try {
      // Optimization: Added timeout. If download exceeds 3 seconds, proceed without it
      // to ensure the share dialog pops up immediately for the user.
      final resp = await http.get(Uri.parse(d.imageUrl!))
          .timeout(const Duration(seconds: 3));

      if (resp.statusCode == 200) {
        return XFile.fromData(
          resp.bodyBytes,
          name: 'preview_thumbnail.jpg',
          mimeType: resp.headers['content-type'] ?? 'image/jpeg',
        );
      }
    } catch (e) {
      debugPrint('ShareService: Download thumbnail failed or timed out: $e');
    }
    return null;
  }

  /// Gets the anchor position for sharing on iPad.
  /// Optimization: Added null-safety check to prevent crashes.
  static Rect? _getShareOrigin(BuildContext ctx) {
    try {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (e) {
      debugPrint('ShareService: Cannot find render object for share origin: $e');
    }
    return null; // If failed, SharePlus will attempt to center or use a default position.
  }

  /// Optimization: Extracted common social app intent logic.
  static Future<void> _launchSocialIntent({
    required String urlScheme,
    required ShareData fallbackData,
  }) async {
    final uri = Uri.parse(urlScheme);

    // Attempt to open the specific app (WhatsApp, Telegram, etc.)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to system native share if app launch fails
      await SharePlus.instance.share(
        ShareParams(
            text: fallbackData.combined,
            downloadFallbackEnabled: true
        ),
      );
    }
  }

  // ==========================================
  // 2. Public APIs
  // ==========================================

  static Future<ShareResult> shareNative(BuildContext ctx, ShareData d) async {
    final origin = _getShareOrigin(ctx);

    return SharePlus.instance.share(
      ShareParams(
        //text: d.combined, // Ensure this is "Text + Space + Link"
        subject: d.title,
        sharePositionOrigin: origin,
        downloadFallbackEnabled: true,
      ),
    );
  }

  static Future<ShareResult> shareFiles(
      BuildContext ctx,
      List<XFile> files, {
        String? text,
        String? subject,
      }) {
    final origin = _getShareOrigin(ctx);

    return SharePlus.instance.share(
      ShareParams(
        files: files,
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
        downloadFallbackEnabled: true,
      ),
    );
  }

  /// WhatsApp: Requires parameter encoding
  static Future<void> shareWhatsApp(ShareData d) async {
    final text = Uri.encodeComponent("${d.text}\n\n${d.url}");
    await _launchSocialIntent(
      urlScheme: 'whatsapp://send?text=$text',
      fallbackData: d,
    );
  }

  /// Telegram: Supports url and text parameters
  static Future<void> shareTelegram(ShareData d) async {
    final url = Uri.encodeComponent(d.url);
    final text = Uri.encodeComponent(d.text ?? '');
    await _launchSocialIntent(
      urlScheme: 'tg://msg_url?url=$url&text=$text',
      fallbackData: d,
    );
  }

  /// Twitter/X: Recommends using intent URL
  static Future<void> shareTwitter(ShareData d) async {
    final text = Uri.encodeComponent(d.text ?? '');
    final url = Uri.encodeComponent(d.url);
    await _launchSocialIntent(
      urlScheme: 'https://twitter.com/intent/tweet?text=$text&url=$url',
      fallbackData: d,
    );
  }

  /// Facebook: Primarily uses the 'u' parameter
  static Future<void> shareFacebook(ShareData d) async {
    final url = Uri.encodeComponent(d.url);
    // FB often ignores text and crawls the OpenGraph info from the URL instead
    await _launchSocialIntent(
      urlScheme: 'https://www.facebook.com/sharer/sharer.php?u=$url',
      fallbackData: d,
    );
  }

  /// Smart Share Entry: Attempts native share, falls back to custom sheet if it fails
  static Future<void> openSystemOrSheet(
      ShareData d,
      Future<void> Function()? openSheet,
      ) async {
    // 1. Direct to custom sheet on Web (Native share experience is inconsistent)
    if (kIsWeb && openSheet != null) {
      await openSheet();
      return;
    }

    try {
      await Share.shareUri(Uri.parse(d.url));
    } catch (e) {
      debugPrint('ShareService: Native share failed ($e), falling back to custom sheet.');
      if (openSheet != null) {
        await openSheet();
      }
    }
  }
}