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

  Future<void> _renderMarkdown() async {
    print("\tprocessing buildInlineSpans...");
    processedInlineTextSpans = await MarkdownEditorRenderer.buildInlineSpans(
      text,
      parser,
    );
    print("\tprocessed InlineSpans: $processedInlineTextSpans");
    print("\tfinished processing buildInlineSpans");
    isRebuild = true;
    notifyListeners();
  }

  TextSpan _rebuild(TextStyle? style) {
    print("Updating the text spans");
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
    print("\n");
    print("Comparing lastText and text");
    
    if (isRebuild) {
      return _rebuild(style);
    }

    // We need to determine whether the spans are processed before updating it
    if (currentText == lastText) {
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

    print("Processing the text");
    // Start processing the text
    _renderMarkdown();

    print("Swap the text into lastText");
    lastText = text;
    currentText = text;

    print("returned last processed text span");
    print("text: $text");
    print("InlineSpan: $lastProcessedInlineTextSpans");
    return lastProcessedTextSpan;
  }
}
