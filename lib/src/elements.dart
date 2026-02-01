import 'package:bit_markdown_editor/src/renderer.dart';
import 'package:flutter/material.dart';

abstract class MarkdownElement {
  InlineSpan buildWidget();
}

class EditorTextElement extends MarkdownElement {
  final String text;
  final TextStyle? style;

  EditorTextElement(this.text, {this.style});

  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderText(text, style);
}

class EditorHeadingElement extends MarkdownElement {
  final String text;
  final int level;

  EditorHeadingElement(this.text, this.level);

  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderHeading(text, level);
}

class EditorBlockQuoteElement extends MarkdownElement {
  final String text;

  EditorBlockQuoteElement(this.text);

  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderBlockQuote(text);
}

class EditorListItemElement extends MarkdownElement {
  final String text;
  final bool ordered;

  EditorListItemElement(this.text, {this.ordered = false});

  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderListItem(text, ordered);
}

class EditorHorizontalLine extends MarkdownElement {
  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderHorizontalLine();
}

class EditorTableRowElement extends MarkdownElement {
  final List<String> cells;
  EditorTableRowElement(this.cells);

  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderTableRow(cells);
}

class EditorCodeBlockElement extends MarkdownElement {
  final String code;
  final String? language;
  EditorCodeBlockElement(this.code, {this.language});

  @override
  InlineSpan buildWidget() =>
      MarkdownEditorRenderer.renderCodeBlock(code, language: language);
}

class EditorMathBlockElement extends MarkdownElement {
  final String expression;
  EditorMathBlockElement(this.expression);

  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderMathBlock(expression);
}

class EditorMathInlineElement extends MarkdownElement {
  final String expression;
  EditorMathInlineElement(this.expression);

  @override
  InlineSpan buildWidget() => MarkdownEditorRenderer.renderMathInline(expression);
}

class EditorImageElement extends MarkdownElement {
  final String alt;
  final String url;
  final String? title;

  EditorImageElement(this.alt, this.url, {this.title});
  @override
  InlineSpan buildWidget() =>
      MarkdownEditorRenderer.renderImage(url, altText: alt, title: title);
}

class EditorLinkElement extends MarkdownElement {
  final String text;
  final String url;
  final String? title;
  void Function(String url)? onTap;

  EditorLinkElement(this.text, this.url, {this.title, this.onTap});

  @override
  InlineSpan buildWidget() =>
      MarkdownEditorRenderer.renderLink(text, url, title: title, onTap: onTap);
}
