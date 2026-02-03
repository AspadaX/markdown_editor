import 'package:bit_markdown_controller/src/elements.dart';
import 'package:bit_markdown_controller/src/renderer.dart';
import 'package:bit_markdown_controller/src/style_sheet.dart';
import 'package:flutter/cupertino.dart';

import 'parser.dart';

class MarkdownTextEditingController extends TextEditingController {
  MarkdownStyleSheet styleSheet;
  MarkdownEditorParser parser;

  String lastText = '';
  List<MarkdownElement> elements = [];

  TextSpan lastProcessedTextSpan = TextSpan();
  List<InlineSpan> processedInlineTextSpans = [];
  List<InlineSpan> lastProcessedInlineTextSpans = [];
  List<TextRange> invisibleRanges = [];

  bool isRebuild = false;

  MarkdownTextEditingController({
    required this.parser,
    required this.styleSheet,
  });

  void _parseAndPrepareMarkdownForRendering() {
    elements = parser.parseDocument(text);
    final results = MarkdownEditorRenderer.buildRenderResults(
      elements,
      styleSheet,
    );
    processedInlineTextSpans = results.map((e) => e.span).toList();

    // Calculate absolute invisible ranges
    invisibleRanges.clear();
    int currentOffset = 0;
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];
      final result = results[i];

      for (final range in result.invisibleRanges) {
        invisibleRanges.add(TextRange(
          start: range.start + currentOffset,
          end: range.end + currentOffset,
        ));
      }

      currentOffset += element.sourceLength;
    }

    isRebuild = true;
  }

  void updateStyleSheet(MarkdownStyleSheet newStyleSheet) {
    styleSheet = newStyleSheet;
    _parseAndPrepareMarkdownForRendering();
    isRebuild = true;
    notifyListeners();
  }

  TextSpan _rebuild(TextStyle? style) {
    // Update the cache
    lastProcessedInlineTextSpans = processedInlineTextSpans;
    lastProcessedTextSpan = TextSpan(
      style: style ?? styleSheet.p,
      children: processedInlineTextSpans,
    );

    isRebuild = false;
    return lastProcessedTextSpan;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text != lastText) {
      _parseAndPrepareMarkdownForRendering();
      lastText = text;
    }

    if (isRebuild || lastProcessedTextSpan.style != (style ?? styleSheet.p)) {
      return _rebuild(style);
    }

    return lastProcessedTextSpan;
  }

  @override
  set selection(TextSelection newSelection) {
    super.selection = _adjustSelection(newSelection);
  }

  TextSelection _adjustSelection(TextSelection newSelection) {
    if (!newSelection.isValid) return newSelection;

    // Only adjust collapsed selection (cursor)
    if (newSelection.isCollapsed) {
      final offset = newSelection.baseOffset;
      final prevOffset = selection.baseOffset;
      
      for (final range in invisibleRanges) {
        // Check if cursor lands inside an invisible range (exclusive of start/end)
        // We allow landing AT start or AT end, but not in between.
        // Actually, with width 0, start and end are visually the same.
        // But logically, we want to prevent being "inside" the tag.
        if (range.start < offset && offset < range.end) {
          // Determine direction
          if (offset > prevOffset) {
            // Moving right: jump to end
            return TextSelection.collapsed(offset: range.end);
          } else if (offset < prevOffset) {
            // Moving left: jump to start
            return TextSelection.collapsed(offset: range.start);
          } else {
            // No movement (e.g. tap)? Jump to nearest or end.
            // Default to end to "enter" the content or "exit" the tag.
            return TextSelection.collapsed(offset: range.end);
          }
        }
      }
    }
    return newSelection;
  }
}
