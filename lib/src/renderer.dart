import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'elements.dart';
import 'parser.dart';
import 'style_sheet.dart';

class RenderResult {
  final InlineSpan span;
  final List<TextRange> invisibleRanges;

  RenderResult(this.span, this.invisibleRanges);
}

class MarkdownEditorRenderer {
  static void Function(String url)? onLinkTap;

  static const TextStyle invisibleText = TextStyle(
    color: Colors.transparent,
    fontSize: 0.1,
    letterSpacing: 0,
  );

  static RenderResult renderHeading(
    String text,
    String prefix,
    int level,
    MarkdownStyleSheet styleSheet,
  ) {
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
    return RenderResult(
      TextSpan(
        children: [
          TextSpan(text: prefix, style: invisibleText),
          TextSpan(text: text, style: style),
        ],
      ),
      [TextRange(start: 0, end: prefix.length)],
    );
  }

  static RenderResult renderListItem(
    String text,
    String prefix,
    bool ordered,
    MarkdownStyleSheet styleSheet,
  ) {
    final rendered = renderText(text, styleSheet, style: styleSheet.listBullet);

    // Render the prefix (bullet or number)
    final prefixSpan = TextSpan(
      text: prefix,
      style: styleSheet.listBullet.copyWith(fontWeight: FontWeight.bold),
    );

    // Shift invisible ranges from the content text by the length of the prefix
    final shiftedRanges = rendered.invisibleRanges.map((range) {
      return TextRange(
        start: range.start + prefix.length,
        end: range.end + prefix.length,
      );
    }).toList();

    return RenderResult(
      TextSpan(children: [prefixSpan, rendered.span]),
      shiftedRanges,
    );
  }

  static RenderResult renderHorizontalLine(MarkdownStyleSheet styleSheet) {
    return RenderResult(const TextSpan(text: '---'), []);
  }

  static RenderResult renderTableRow(
    List<String> cells,
    MarkdownStyleSheet styleSheet,
  ) {
    final spans = <InlineSpan>[];
    final invisibleRanges = <TextRange>[];
    int currentOffset = 0;

    for (var i = 0; i < cells.length; i++) {
      // Table rendering is complex because of separators.
      // This implementation constructs a span but doesn't track exact offsets for separators.
      // For simplicity, we process cell content but tracking ranges across table cells
      // requires precise knowledge of the separator characters (' | ').
      // Given the current implementation just concatenates, we will try to track.

      final rendered = renderText(
        cells[i],
        styleSheet,
        style: styleSheet.tableBody,
      );
      spans.add(rendered.span);

      // Add ranges from cell, shifted by currentOffset
      for (final range in rendered.invisibleRanges) {
        invisibleRanges.add(
          TextRange(
            start: range.start + currentOffset,
            end: range.end + currentOffset,
          ),
        );
      }

      currentOffset += cells[i].length;

      if (i != cells.length - 1) {
        spans.add(const TextSpan(text: ' | '));
        currentOffset += 3; // ' | ' length
      }
    }
    return RenderResult(TextSpan(children: spans), invisibleRanges);
  }

  static RenderResult renderBlockQuote(
    String text,
    String prefix,
    MarkdownStyleSheet styleSheet,
  ) {
    return RenderResult(
      TextSpan(
        children: [
          TextSpan(text: prefix, style: invisibleText),
          TextSpan(text: text, style: styleSheet.blockQuote),
        ],
      ),
      [TextRange(start: 0, end: prefix.length)],
    );
  }

  static RenderResult renderCodeBlock(
    String code,
    MarkdownStyleSheet styleSheet, {
    String? language,
  }) {
    final spans = <InlineSpan>[];
    
    // Opening backticks
    spans.add(
      TextSpan(
        text: '```',
        style: styleSheet.codeBlock.copyWith(
          color: Colors.grey,
        ),
      ),
    );

    if (language != null) {
      spans.add(
        TextSpan(
          text: language,
          style: styleSheet.codeBlock.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // Newline after opening
    spans.add(TextSpan(text: '\n', style: styleSheet.codeBlock));
    
    // Content
    spans.add(TextSpan(text: code, style: styleSheet.codeBlock));
    
    // Newline before closing (only if code doesn't end with one)
    if (code.isNotEmpty && !code.endsWith('\n')) {
      spans.add(TextSpan(text: '\n', style: styleSheet.codeBlock));
    }

    // Closing backticks
    spans.add(
      TextSpan(
        text: '```',
        style: styleSheet.codeBlock.copyWith(
          color: Colors.grey,
        ),
      ),
    );
    
    return RenderResult(TextSpan(children: spans), []);
  }

  static RenderResult renderMathBlock(
    String expression,
    MarkdownStyleSheet styleSheet,
  ) {
    return RenderResult(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          expression,
          textStyle: styleSheet.p.copyWith(fontSize: 20),
          mathStyle: MathStyle.display,
        ),
      ),
      [],
    );
  }

  static RenderResult renderMathInline(
    String expression,
    MarkdownStyleSheet styleSheet,
  ) {
    return RenderResult(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              expression,
              textStyle: styleSheet.p.copyWith(fontSize: 16),
              mathStyle: MathStyle.text,
            ),
          ),
        ],
      ),
      [],
    );
  }

  static RenderResult renderImage(
    String url,
    MarkdownStyleSheet styleSheet, {
    String? altText,
    String? title,
  }) {
    return RenderResult(
      TextSpan(
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
                    return altText != null
                        ? Text(altText)
                        : const Icon(Icons.broken_image, size: 48);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      [],
    );
  }

  static RenderResult renderLink(
    String text,
    String url,
    MarkdownStyleSheet styleSheet, {
    String? title,
    void Function(String url)? onTap,
  }) {
    return RenderResult(
      TextSpan(
        text: text,
        style: styleSheet.link,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) onTap(url);
          },
      ),
      [],
    );
  }

  static RenderResult renderText(
    String text,
    MarkdownStyleSheet styleSheet, {
    TextStyle? style,
  }) {
    final spans = <InlineSpan>[];
    final invisibleRanges = <TextRange>[];
    var i = 0;

    while (i < text.length) {
      // Bold (** or __)
      if (text.startsWith('**', i)) {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          spans.add(TextSpan(text: '**', style: invisibleText));
          invisibleRanges.add(TextRange(start: i, end: i + 2));

          spans.add(
            TextSpan(
              text: text.substring(i + 2, end),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
          spans.add(TextSpan(text: '**', style: invisibleText));
          invisibleRanges.add(TextRange(start: end, end: end + 2));

          i = end + 2;
          continue;
        }
      } else if (text.startsWith('__', i)) {
        final end = text.indexOf('__', i + 2);
        if (end != -1) {
          spans.add(TextSpan(text: '__', style: invisibleText));
          invisibleRanges.add(TextRange(start: i, end: i + 2));

          spans.add(
            TextSpan(
              text: text.substring(i + 2, end),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
          spans.add(TextSpan(text: '__', style: invisibleText));
          invisibleRanges.add(TextRange(start: end, end: end + 2));

          i = end + 2;
          continue;
        }
      }

      // Italic
      if (text.startsWith('*', i) && !text.startsWith('**', i)) {
        final end = text.indexOf('*', i + 1);
        if (end != -1) {
          spans.add(TextSpan(text: '*', style: invisibleText));
          invisibleRanges.add(TextRange(start: i, end: i + 1));

          spans.add(
            TextSpan(
              text: text.substring(i + 1, end),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          );
          spans.add(TextSpan(text: '*', style: invisibleText));
          invisibleRanges.add(TextRange(start: end, end: end + 1));

          i = end + 1;
          continue;
        }
      } else if (text.startsWith('_', i) && !text.startsWith('__', i)) {
        final end = text.indexOf('_', i + 1);
        if (end != -1) {
          spans.add(TextSpan(text: '_', style: invisibleText));
          invisibleRanges.add(TextRange(start: i, end: i + 1));

          spans.add(
            TextSpan(
              text: text.substring(i + 1, end),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          );
          spans.add(TextSpan(text: '_', style: invisibleText));
          invisibleRanges.add(TextRange(start: end, end: end + 1));

          i = end + 1;
          continue;
        }
      }

      //Strikethrough
      if (text.startsWith('~~', i)) {
        final end = text.indexOf('~~', i + 2);
        if (end != -1) {
          spans.add(TextSpan(text: '~~', style: invisibleText));
          invisibleRanges.add(TextRange(start: i, end: i + 2));

          spans.add(
            TextSpan(
              text: text.substring(i + 2, end),
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
          );
          spans.add(TextSpan(text: '~~', style: invisibleText));
          invisibleRanges.add(TextRange(start: end, end: end + 2));

          i = end + 2;
          continue;
        }
      }

      // Inline Code
      if (text.startsWith('`', i)) {
        final end = text.indexOf('`', i + 1);
        if (end != -1) {
          spans.add(TextSpan(text: '`', style: invisibleText));
          invisibleRanges.add(TextRange(start: i, end: i + 1));

          spans.add(
            TextSpan(text: text.substring(i + 1, end), style: styleSheet.code),
          );
          spans.add(TextSpan(text: '`', style: invisibleText));
          invisibleRanges.add(TextRange(start: end, end: end + 1));

          i = end + 1;
          continue;
        }
      }

      // Inline Math
      if (text.startsWith(r'$', i) && !text.startsWith(r'$$', i)) {
        final end = text.indexOf(r'$', i + 1); // Use raw string here too
        if (end != -1) {
          spans.add(TextSpan(text: r'$', style: invisibleText));
          invisibleRanges.add(TextRange(start: i, end: i + 1));

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Math.tex(
                text.substring(i + 1, end),
                mathStyle: MathStyle.text,
                textStyle: styleSheet.p.copyWith(fontSize: 16),
              ),
            ),
          );
          spans.add(TextSpan(text: r'$', style: invisibleText));
          invisibleRanges.add(TextRange(start: end, end: end + 1));

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

    return RenderResult(
      TextSpan(style: style ?? styleSheet.p, children: spans),
      invisibleRanges,
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

  static List<RenderResult> buildRenderResults(
    List<MarkdownElement> markdownElements,
    MarkdownStyleSheet styleSheet,
  ) {
    List<RenderResult> results = [];
    for (final MarkdownElement element in markdownElements) {
      results.add(element.buildWidget(styleSheet));
    }

    return results;
  }
}
