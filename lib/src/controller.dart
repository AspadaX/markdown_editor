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

  bool isRebuild = false;

  MarkdownTextEditingController({
    required this.parser,
    required this.styleSheet,
  });

  void _parseAndPrepareMarkdownForRendering() {
    elements = parser.parseDocument(text);
    processedInlineTextSpans = MarkdownEditorRenderer.buildInlineTextSpans(
      elements,
      styleSheet,
    );
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
}
