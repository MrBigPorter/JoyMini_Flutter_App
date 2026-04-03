import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// 商品富文本渲染组件（详情/规则/秒杀详情共用）
/// 处理 flex 布局、nowrap、table/pre 横向滚动、img 自适应等场景
class ProductHtmlContent extends StatelessWidget {
  final String html;

  /// 自定义文字样式，默认 13sp + textSecondary
  final TextStyle? textStyle;

  const ProductHtmlContent({
    super.key,
    required this.html,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: _HtmlWidget(
              html: html,
              maxWidth: constraints.maxWidth,
              allowBlockScroll: true,
              textStyle: textStyle,
            ),
          );
        },
      ),
    );
  }
}

class _HtmlWidget extends StatelessWidget {
  final String html;
  final double maxWidth;
  final bool allowBlockScroll;
  final TextStyle? textStyle;

  const _HtmlWidget({
    required this.html,
    required this.maxWidth,
    required this.allowBlockScroll,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      textStyle: textStyle ?? TextStyle(fontSize: 13.sp),
      buildAsync: true,
      customWidgetBuilder: allowBlockScroll
          ? (element) {
              final tag = element.localName;
              if (tag == 'table' || tag == 'pre') {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: maxWidth),
                    child: _HtmlWidget(
                      html: element.outerHtml,
                      maxWidth: maxWidth,
                      allowBlockScroll: false,
                      textStyle: textStyle,
                    ),
                  ),
                );
              }
              return null;
            }
          : null,
      customStylesBuilder: (element) {
        final tag = element.localName;
        final inlineStyle = (element.attributes['style'] ?? '').toLowerCase();

        if (inlineStyle.contains('display:flex')) {
          return {
            'display': 'block',
            'max-width': '100%',
            'width': '100%',
            'word-break': 'break-word',
            'overflow-wrap': 'anywhere',
          };
        }

        if (inlineStyle.contains('white-space:nowrap')) {
          return {
            'white-space': 'normal',
            'word-break': 'break-word',
            'overflow-wrap': 'anywhere',
          };
        }

        if (const {
          'p',
          'div',
          'span',
          'li',
          'a',
          'strong',
          'em',
          'td',
          'th',
        }.contains(tag)) {
          return {
            'white-space': 'normal',
            'word-break': 'break-word',
            'overflow-wrap': 'anywhere',
            'max-width': '100%',
          };
        }

        if (tag == 'img') {
          return {
            'display': 'block',
            'max-width': '100%',
            'height': 'auto',
          };
        }

        if (tag == 'table') {
          return {
            'max-width': '100%',
            'width': '100%',
            'table-layout': 'fixed',
          };
        }

        if (tag == 'pre' || tag == 'code') {
          return {
            'white-space': 'pre-wrap',
            'word-break': 'break-word',
            'overflow-wrap': 'anywhere',
            'max-width': '100%',
          };
        }

        return null;
      },
    );
  }
}

