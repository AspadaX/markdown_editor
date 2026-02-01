import 'package:bit_markdown_editor/src/elements.dart';

class MarkdownEditorParser {
  final _numRegex = RegExp(r'^\d+\.\s+');
  final _imageRegex = RegExp(r'!\[(.*?)\]\((.*?)(?:\s+"(.*?)")?\)',);
  final _linkRegex = RegExp(r'\[(.*?)\]\((.*?)(?:\s+"(.*?)")?\)',);

  // Multiline parser
  List<MarkdownElement> parseDocument(String text) {
    final lines = _splitKeepingNewlines(text);
    final elements = <MarkdownElement>[];

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];

      if (line.isEmpty) {
        i++;
        continue;
      }

      // Code block
      if (line.startsWith('```')) {
        final language = line.substring(3).trim();
        final codeLines = <String>[];
        i++;

        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }

        elements.add(
          EditorCodeBlockElement(
            codeLines.join('\n'),
            language: language.isEmpty ? null : language,
          ),
        );
        i++;
        continue;
      }

      // Block Math $$...$$
      if (line.startsWith(r'$$')) {
        final mathLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith(r'$$')) {
          mathLines.add(lines[i]);
          i++;
        }

        elements.add(EditorMathBlockElement(mathLines.join('\n').trim()));
        i++;
        continue;
      }

      elements.add(parseLine(line));
      i++;
    }

    return elements;
  }

  // Line by line parser
  MarkdownElement parseLine(String line) {
    // Heading
    if (line.startsWith('#')) {
      final level = line.indexOf(' ');
      final text = line.substring(level + 1);
      return EditorHeadingElement(text, level);
    }

    // Unordered list
    if (line.startsWith('- ')) {
      return EditorListItemElement(line.substring(2));
    }

    // Ordered list
    final numMatch = _numRegex.firstMatch(line);
    if (numMatch != null) {
      return EditorListItemElement(line.substring(numMatch.end), ordered: true);
    }

    // Block quote
    if (line.startsWith('> ')) {
      return EditorBlockQuoteElement(line.substring(2));
    }

    // Table
    if (line.startsWith('|') && line.endsWith('|')) {
      final cells = line
          .substring(1, line.length - 1)
          .split('|')
          .map((c) => c.trim())
          .toList();
      return EditorTableRowElement(cells);
    }

    // Horizontal line
    if (line.startsWith('---') || line.startsWith('***')) {
      return EditorHorizontalLine();
    }

    // Image ![alt](url "title")
    final imageMatch = _imageRegex.firstMatch(line);
    if (imageMatch != null) {
      final alt = imageMatch.group(1) ?? '';
      final url = imageMatch.group(2) ?? '';
      final title = imageMatch.group(3);
      return EditorImageElement(alt, url, title: title);
    }

    // Link [text](url "title")
    final linkMatch = _linkRegex.firstMatch(line);
    if (linkMatch != null) {
      final text = linkMatch.group(1) ?? '';
      final url = linkMatch.group(2) ?? '';
      final title = linkMatch.group(3);
      return EditorLinkElement(text, url, title: title);
    }

    // Default text
    return EditorTextElement(line);
  }

  List<String> _splitKeepingNewlines(String text) {
    final lines = <String>[];
    int start = 0;
    while (true) {
      final index = text.indexOf('\n', start);
      if (index == -1) {
        if (start < text.length) {
          lines.add(text.substring(start));
        }
        break;
      }
      lines.add(text.substring(start, index + 1));
      start = index + 1;
    }
    return lines;
  }
}
