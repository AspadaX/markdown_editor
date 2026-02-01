import 'package:bit_markdown_editor/src/elements.dart';
import 'package:bit_markdown_editor/src/parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MarkdownEditorRenderer {
  static void Function(String url)? onLinkTap;

  static InlineSpan renderHeading(String text, int level) {
    final size = 24.0 - (level * 2);
    return TextSpan(
      text: text,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.bold),
    );
  }

  static InlineSpan renderListItem(String text, bool ordered) {
    final rendered = renderText(text, null);
    final textSpan = rendered is TextSpan ? rendered : TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: ordered ? '• ' : '• '),
        textSpan,
      ],
    );
  }

  static InlineSpan renderHorizontalLine() {
    return const TextSpan(text: '---');
  }

  static InlineSpan renderTableRow(List<String> cells) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < cells.length; i++) {
      final rendered = renderText(cells[i], null);
      spans.add(rendered);
      if (i != cells.length - 1) {
        spans.add(const TextSpan(text: ' | '));
      }
    }
    return TextSpan(children: spans);
  }

  static InlineSpan renderBlockQuote(String text) {
    return TextSpan(
      text: text,
      style: const TextStyle(fontStyle: FontStyle.italic),
    );
  }

  static InlineSpan renderCodeBlock(String code, {String? language}) {
    final spans = <InlineSpan>[];
    if (language != null) {
      spans.add(
        TextSpan(
          text: '$language\n',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    spans.add(
      TextSpan(
        text: code,
        style: const TextStyle(fontFamilyFallback: ['Courier', 'monospace'], fontSize: 14),
      ),
    );
    return TextSpan(children: spans);
  }

  static InlineSpan renderMathBlock(String expression) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Math.tex(expression, textStyle: const TextStyle(fontSize: 20), mathStyle: MathStyle.display),
    );
  }

  static InlineSpan renderMathInline(String expression) {
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(expression, textStyle: const TextStyle(fontSize: 16), mathStyle: MathStyle.text),
        ),
      ],
    );
  }

  static InlineSpan renderImage(String url, {String? altText, String? title}) {
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

  static InlineSpan renderLink(String text, String url, {String? title, void Function(String url)? onTap}) {
    return TextSpan(
      text: text,
      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          if (onTap != null) onTap(url);
        },
    );
  }

  static InlineSpan renderText(String text, TextStyle? style) {
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
              style: const TextStyle(fontFamilyFallback: ['Courier', 'monospace'], backgroundColor: Color.fromARGB(255, 230, 230, 230)),
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
              child: Math.tex(text.substring(i + 1, end), mathStyle: MathStyle.text, textStyle: const TextStyle(fontSize: 16)),
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
      style: style ?? const TextStyle(fontSize: 16, color: Colors.black),
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

  static Future<List<InlineSpan>> buildInlineSpans(String text, MarkdownEditorParser parser) async {
    final List<MarkdownElement> elements = await compute(parser.parseDocument, text);
    List<InlineSpan> newSpans = [];
    for (final MarkdownElement element in elements) {
      newSpans.add(element.buildWidget());
    }

    return newSpans;
  }
}
