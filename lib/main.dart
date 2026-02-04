import 'package:flutter/material.dart';
import 'package:bit_markdown_controller/bit_markdown_controller.dart';

void main() {
  runApp(const DebugApp());
}

// --- Mocks for the User Snippet ---
class SearchHighlight {
  final String text;
  final String? chunkId;
  SearchHighlight({required this.text, this.chunkId});
}

class AppState {
  final Map<String, SearchHighlight> searchHighlights = {};
  final Map<String, Map<String, int>> documentChunkOffsets = {};
}

class AppStateScope extends InheritedWidget {
  final AppState appState;

  const AppStateScope({
    super.key,
    required this.appState,
    required super.child,
  });

  static AppState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppStateScope>()!
        .appState;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) => false;
}
// ----------------------------------

class DebugApp extends StatefulWidget {
  const DebugApp({super.key});

  @override
  State<DebugApp> createState() => _DebugAppState();
}

class _DebugAppState extends State<DebugApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final AppState _appState = AppState();

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: _appState,
      child: MaterialApp(
        title: 'Markdown Debugger',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: _themeMode,
        home: DebugPage(onThemeToggle: _toggleTheme),
      ),
    );
  }
}

class DebugPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final String documentId = 'demo_doc'; // Added mock ID

  const DebugPage({super.key, required this.onThemeToggle});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  late MarkdownTextEditingController _controller;
  final FocusNode _focusNode = FocusNode(); // Added FocusNode

  @override
  void initState() {
    super.initState();
    // Initialize with a default theme, it will be updated in didChangeDependencies
    _controller = MarkdownTextEditingController(
      parser: MarkdownEditorParser(),
      styleSheet: MarkdownStyleSheet.fromTheme(ThemeData.light()),
    );
    _controller.text = r'''# Welcome to Markdown Debugger

Try typing some markdown here!

## Features
- **Bold** text
- *Italic* text
- `Inline code`
- Lists
  - Item 1
  - Item 2

> Blockquotes work too!

```dart
void main() {
  print("Hello World");
}
```

$$
f(x) = x^2 + 2x + 1
$$
''';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update stylesheet when theme changes
    _controller.updateStyleSheet(
      MarkdownStyleSheet.fromTheme(Theme.of(context)),
    );

    // Check highlight whenever dependencies change (e.g. state update)
    _checkHighlight();
  }

  // --- User Snippet ---
  void _checkHighlight() {
    final appState = AppStateScope.of(context);
    final highlight = appState.searchHighlights[widget.documentId];

    // Access the raw markdown text from the controller
    final text = _controller.text;

    if (highlight != null && text.isNotEmpty) {
      final highlightText = highlight.text;
      int index = -1;
      int length = highlightText.length;

      // 1. Try chunk offset (Fastest if offsets are valid)
      if (highlight.chunkId != null) {
        final offsets = appState.documentChunkOffsets[widget.documentId];
        if (offsets != null && offsets.containsKey(highlight.chunkId)) {
          final offset = offsets[highlight.chunkId]!;
          // Simple validation to ensure offset is within bounds
          if (offset >= 0 && offset < text.length) {
            index = offset;
          }
        }
      }

      // 2. Exact Match (Standard)
      if (index == -1) {
        index = text.indexOf(highlightText);
      }

      // 3. Flexible Regex Match (Handles \r\n vs \n and multiple spaces)
      if (index == -1) {
        // Split search text by whitespace and rejoin with \s+ to match ANY whitespace sequence
        // This makes "Hello World" match "Hello\nWorld" or "Hello   World"
        final parts = highlightText.split(RegExp(r'\s+'));
        // Escape parts to treat symbols like *, [, ] as literals, not regex commands
        final pattern = parts.map(RegExp.escape).join(r'\s+');

        if (pattern.isNotEmpty) {
          final match = RegExp(pattern, multiLine: true).firstMatch(text);
          if (match != null) {
            index = match.start;
            // CRITICAL: Use the length of the *actual match* found in the document
            length = match.end - match.start;
          }
        }
      }

      // 4. Fallback: Prefix Match (Handle truncated text or tail differences)
      if (index == -1 && highlightText.length > 50) {
        final shortHighlight = highlightText.substring(0, 50);
        index = text.indexOf(shortHighlight);
        // If found, we keep the original 'length' (highlightText.length)
        // to attempt selecting the full text, rather than just the first 50 chars.
      }

      if (index != -1) {
        // Clear highlight from state
        appState.searchHighlights.remove(widget.documentId);

        final textLength = text.length;
        // Ensure indices are valid
        final baseOffset = index.clamp(0, textLength);
        final extentOffset = (index + length).clamp(0, textLength);

        final selection = TextSelection(
          baseOffset: baseOffset,
          extentOffset: extentOffset,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _controller.selection = selection;
          // Ensure the editor has focus so the selection is visible
          _focusNode.requestFocus();
        });
      }
    }
  }
  // -------------------

  void _triggerSearch() async {
    final searchText = await showDialog<String>(
      context: context,
      builder: (context) {
        String value = '';
        return AlertDialog(
          title: const Text('Search'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter text to find...',
            ),
            onChanged: (v) => value = v,
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(value),
              child: const Text('Find'),
            ),
          ],
        );
      },
    );

    if (searchText != null && searchText.isNotEmpty) {
      final appState = AppStateScope.of(context);
      appState.searchHighlights[widget.documentId] = SearchHighlight(text: searchText);

      // Trigger check
      setState(() {
        _checkHighlight();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Controller Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _triggerSearch,
            tooltip: 'Find "Hello World"',
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: widget.onThemeToggle,
            tooltip: 'Toggle Theme',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'links') {
                _controller.updateConfig(enableLinks: !_controller.enableLinks);
              } else if (value == 'images') {
                _controller.updateConfig(
                    enableImages: !_controller.enableImages);
              } else if (value == 'math') {
                _controller.updateConfig(enableMath: !_controller.enableMath);
              }
              setState(() {});
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'links',
                checked: _controller.enableLinks,
                child: const Text('Enable Links'),
              ),
              CheckedPopupMenuItem(
                value: 'images',
                checked: _controller.enableImages,
                child: const Text('Enable Images'),
              ),
              CheckedPopupMenuItem(
                value: 'math',
                checked: _controller.enableMath,
                child: const Text('Enable Math'),
              ),
            ],
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Type markdown here...',
          ),
        ),
      ),
    );
  }
}
