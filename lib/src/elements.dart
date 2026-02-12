import 'package:flutter/rendering.dart';

import 'renderer.dart';
import 'style_sheet.dart';

abstract class MarkdownElement {
  int sourceLength = 0;
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  });
}

class EditorTextElement extends MarkdownElement {
  final String text;
  final TextStyle? style;

  EditorTextElement(this.text, {this.style});

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) =>
      MarkdownEditorRenderer.renderText(
        text,
        styleSheet,
        style: style,
        enableMath: enableMath,
      );
}

class EditorHeadingElement extends MarkdownElement {
  final String text;
  final String prefix;
  final int level;

  EditorHeadingElement(this.text, this.prefix, this.level);

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) =>
      MarkdownEditorRenderer.renderHeading(text, prefix, level, styleSheet);
}

class EditorBlockQuoteElement extends MarkdownElement {
  final String text;
  final String prefix;

  EditorBlockQuoteElement(this.text, this.prefix);

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) =>
      MarkdownEditorRenderer.renderBlockQuote(text, prefix, styleSheet);
}

class EditorListItemElement extends MarkdownElement {
  final String text;
  final String prefix;
  final bool ordered;

  EditorListItemElement(this.text, this.prefix, {this.ordered = false});

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) =>
      MarkdownEditorRenderer.renderListItem(text, prefix, ordered, styleSheet);
}

class EditorHorizontalLine extends MarkdownElement {
  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) =>
      MarkdownEditorRenderer.renderHorizontalLine(styleSheet);
}

class EditorTableRowElement extends MarkdownElement {
  final List<String> cells;
  EditorTableRowElement(this.cells);

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) =>
      MarkdownEditorRenderer.renderTableRow(cells, styleSheet);
}

class EditorCodeBlockElement extends MarkdownElement {
  final String code;
  final String? language;
  EditorCodeBlockElement(this.code, {this.language});

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) =>
      MarkdownEditorRenderer.renderCodeBlock(
        code,
        styleSheet,
        language: language,
      );
}

class EditorMathBlockElement extends MarkdownElement {
  final String expression;
  EditorMathBlockElement(this.expression);

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) {
    if (!enableMath) {
      return MarkdownEditorRenderer.renderText(
        '\$\$$expression\$\$',
        styleSheet,
        enableMath: false,
      );
    }
    return MarkdownEditorRenderer.renderMathBlock(expression, styleSheet);
  }
}

class EditorMathInlineElement extends MarkdownElement {
  final String expression;
  EditorMathInlineElement(this.expression);

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) {
    if (!enableMath) {
      return MarkdownEditorRenderer.renderText(
        '\$$expression\$',
        styleSheet,
        enableMath: false,
      );
    }
    return MarkdownEditorRenderer.renderMathInline(expression, styleSheet);
  }
}

class EditorImageElement extends MarkdownElement {
  final String alt;
  final String url;
  final String? title;
  final String sourceText;

  EditorImageElement(this.alt, this.url, this.sourceText, {this.title});
  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) {
    if (!enableImages) {
      return MarkdownEditorRenderer.renderText(
        sourceText,
        styleSheet,
        enableMath: enableMath,
      );
    }
    return MarkdownEditorRenderer.renderImage(
      url,
      styleSheet,
      altText: alt,
      title: title,
    );
  }
}

class EditorLinkElement extends MarkdownElement {
  final String text;
  final String url;
  final String? title;
  final String sourceText;
  void Function(String url)? onTap;

  EditorLinkElement(this.text, this.url, this.sourceText,
      {this.title, this.onTap});

  @override
  RenderResult buildWidget(
    MarkdownStyleSheet styleSheet, {
    bool enableLinks = true,
    bool enableImages = true,
    bool enableMath = true,
  }) {
    if (!enableLinks) {
      return MarkdownEditorRenderer.renderText(
        sourceText,
        styleSheet,
        enableMath: enableMath,
      );
    }
    return MarkdownEditorRenderer.renderLink(
      text,
      url,
      styleSheet,
      title: title,
      onTap: onTap,
    );
  }
}
