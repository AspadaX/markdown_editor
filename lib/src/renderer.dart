import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'elements.dart';
import 'parser.dart';
import 'style_sheet.dart';

class MarkdownEditorRenderer {
  static void Function(String url)? onLinkTap;

  static InlineSpan renderHeading(String text, String prefix, int level, MarkdownStyleSheet styleSheet) {
    TextStyle style;
    switch (level) {
      case 1:
        style = styleSheet.h1;
        break;
      case 2:
        style = styleSheet.h2;
        break;
      case 3:
        style = styleSheet.h3;
        break;
      case 4:
        style = styleSheet.h4;
        break;
      case 5:
        style = styleSheet.h5;
        break;
      case 6:
        style = styleSheet.h6;
        break;
      default:
        style = styleSheet.p;
        break;
    }
    return TextSpan(
      children: [
        TextSpan(text: prefix, style: const TextStyle(color: Colors.transparent, fontSize: 0.0, letterSpacing: 0)),
        TextSpan(
          text: text,
          style: style,
        ),
      ],
    );
  }

  static InlineSpan renderListItem(String text, String prefix, bool ordered, MarkdownStyleSheet styleSheet) {
    final rendered = renderText(text, styleSheet, style: styleSheet.listBullet);
    final textSpan = rendered is TextSpan ? rendered : TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: prefix, style: const TextStyle(color: Colors.transparent, fontSize: 0.0, letterSpacing: 0)),
        textSpan,
      ],
    );
  }

  static InlineSpan renderHorizontalLine(MarkdownStyleSheet styleSheet) {
    return const TextSpan(text: '---');
  }

  static InlineSpan renderTableRow(List<String> cells, MarkdownStyleSheet styleSheet) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < cells.length; i++) {
      final rendered = renderText(cells[i], styleSheet, style: styleSheet.tableBody);
      spans.add(rendered);
      if (i != cells.length - 1) {
        spans.add(const TextSpan(text: ' | '));
      }
    }
    return TextSpan(children: spans);
  }

  static InlineSpan renderBlockQuote(String text, String prefix, MarkdownStyleSheet styleSheet) {
    return TextSpan(
      children: [
        TextSpan(text: prefix, style: const TextStyle(color: Colors.transparent, fontSize: 0.0, letterSpacing: 0)),
        TextSpan(
          text: text,
          style: styleSheet.blockQuote,
        ),
      ],
    );
  }

  static InlineSpan renderCodeBlock(String code, MarkdownStyleSheet styleSheet, {String? language}) {
    final spans = <InlineSpan>[];
    if (language != null) {
      spans.add(
        TextSpan(
          text: '$language\n',
          style: styleSheet.codeBlock.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    spans.add(
      TextSpan(
        text: code,
        style: styleSheet.codeBlock,
      ),
    );
    return TextSpan(children: spans);
  }

  static InlineSpan renderMathBlock(String expression, MarkdownStyleSheet styleSheet) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Math.tex(expression, textStyle: styleSheet.p.copyWith(fontSize: 20), mathStyle: MathStyle.display),
    );
  }

  static InlineSpan renderMathInline(String expression, MarkdownStyleSheet styleSheet) {
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(expression, textStyle: styleSheet.p.copyWith(fontSize: 16), mathStyle: MathStyle.text),
        ),
      ],
    );
  }

  static InlineSpan renderImage(String url, MarkdownStyleSheet styleSheet, {String? altText, String? title}) {
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Tooltip(
              message: title ?? '',
              child: Image.network(
                url,
                errorBuilder: (context, error, stackTrace) {
                  return altText != null ? Text(altText) : const Icon(Icons.broken_image, size: 48);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  static InlineSpan renderLink(String text, String url, MarkdownStyleSheet styleSheet, {String? title, void Function(String url)? onTap}) {
    return TextSpan(
      text: text,
      style: styleSheet.link,
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          if (onTap != null) onTap(url);
        },
    );
  }

  static InlineSpan renderText(String text, MarkdownStyleSheet styleSheet, {TextStyle? style}) {
    final spans = <InlineSpan>[];
    var i = 0;

    while (i < text.length) {
      // Bold (** or __)
      if (text.startsWith('**', i)) {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: text.substring(i + 2, end),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
          i = end + 2;
          continue;
        }
      } else if (text.startsWith('__', i)) {
        final end = text.indexOf('__', i + 2);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: text.substring(i + 2, end),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
          i = end + 2;
          continue;
        }
      }

      // Italic
      if (text.startsWith('*', i) && !text.startsWith('**', i)) {
        final end = text.indexOf('*', i + 1);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: text.substring(i + 1, end),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          );
          i = end + 1;
          continue;
        }
      } else if (text.startsWith('_', i) && !text.startsWith('__', i)) {
        final end = text.indexOf('_', i + 1);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: text.substring(i + 1, end),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          );
          i = end + 1;
          continue;
        }
      }

      //Strikethrough
      if (text.startsWith('~~', i)) {
        if (text.startsWith('~~', i)) {
          final end = text.indexOf('~~', i + 2);
          if (end != -1) {
            spans.add(
              TextSpan(
                text: text.substring(i + 2, end),
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
            );
            i = end + 2;
            continue;
          }
        }
      }

      // Inline Code
      if (text.startsWith('`', i)) {
        final end = text.indexOf('`', i + 1);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: text.substring(i + 1, end),
              style: styleSheet.code,
            ),
          );
          i = end + 1;
          continue;
        }
      }

      // Inline Math
      if (text.startsWith(r'$', i) && !text.startsWith(r'$$', i)) {
        final end = text.indexOf(r'$', i + 1); // Use raw string here too
        if (end != -1) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Math.tex(text.substring(i + 1, end), mathStyle: MathStyle.text, textStyle: styleSheet.p.copyWith(fontSize: 16)),
            ),
          );
          i = end + 1;
          continue;
        }
      }

      // Regular
      var next = _findNext(text, i);

      if (next == i) {
        next = i + 1;
      }

      spans.add(TextSpan(text: text.substring(i, next)));
      i = next;
    }

    return TextSpan(
      style: style ?? styleSheet.p,
      children: spans,
    );
  }

  static int _findNext(String text, int start) {
    var pos = text.length;

    final bold = text.indexOf('**', start);
    if (bold != -1 && bold < pos) pos = bold;

    final italic = text.indexOf('*', start);
    if (italic != -1 && italic < pos) pos = italic;

    final inlineCode = text.indexOf('`', start);
    if (inlineCode != -1 && inlineCode < pos) pos = inlineCode;

    final strike = text.indexOf('~~', start);
    if (strike != -1 && strike < pos) pos = strike;

    final inlineMath = text.indexOf(r'$', start);
    if (inlineMath != -1 && inlineMath < pos) pos = inlineMath;

    return pos;
  }

  // static Future<List<InlineSpan>> buildInlineSpans(String text, MarkdownEditorParser parser, MarkdownStyleSheet styleSheet) async {
  //   final List<MarkdownElement> elements = await compute(parser.parseDocument, text);
  //   List<InlineSpan> newSpans = [];
  //   for (final MarkdownElement element in elements) {
  //     newSpans.add(element.buildWidget(styleSheet));
  //   }

  //   return newSpans;
  // }
  
  static List<InlineSpan> buildInlineTextSpans(List<MarkdownElement> markdownElements, MarkdownStyleSheet styleSheet) {
    List<InlineSpan> newSpans = [];
    for (final MarkdownElement element in markdownElements) {
      newSpans.add(element.buildWidget(styleSheet));
    }

    return newSpans;
  }
}
