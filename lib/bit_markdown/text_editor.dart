import 'package:editor/bit_markdown/editor_parser.dart';
import 'package:editor/bit_markdown/editor_renderer.dart';
import 'package:flutter/cupertino.dart';

class MarkdownTextEditingController extends TextEditingController {
  MarkdownEditorParser parser;
  List<InlineSpan> processedInlineTextSpans = [];
  String lastText = '';
  String currentText = '';
  TextSpan lastProcessedTextSpan = TextSpan();
  List<InlineSpan> lastProcessedInlineTextSpans = [];
  bool isRebuild = false;

  MarkdownTextEditingController(this.parser);

  Future<void> _parseAndPrepareMarkdownForRendering() async {
    processedInlineTextSpans = await MarkdownEditorRenderer.buildInlineSpans(
      text,
      parser,
    );
    isRebuild = true;
    notifyListeners();
  }

  TextSpan _rebuild(TextStyle? style) {
    // Update the cache
    lastProcessedInlineTextSpans = processedInlineTextSpans;
    lastProcessedTextSpan = TextSpan(
      style:
          style ??
          const TextStyle(
            fontSize: 16,
            color: CupertinoColors.darkBackgroundGray,
          ),
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
    if (isRebuild) {
      return _rebuild(style);
    }

    // We need to determine whether the spans are processed before updating it
    if (text == lastText) {
      return lastProcessedTextSpan;
    }

    // currentText
    // no edit > no update
    // edited > update
    // rebuilding > no update
    //
    // lastText
    // current no edit > no
    // current edited > yes
    // current rebuilding > no

    // Start processing the text
    _parseAndPrepareMarkdownForRendering();
    
    lastText = text;
    return lastProcessedTextSpan;
  }
}
