import 'package:flutter/material.dart';
import 'package:bit_markdown_controller/bit_markdown_controller.dart';

void main() {
  runApp(const DebugApp());
}

class DebugApp extends StatefulWidget {
  const DebugApp({super.key});

  @override
  State<DebugApp> createState() => _DebugAppState();
}

class _DebugAppState extends State<DebugApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown Debugger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      ),
      themeMode: _themeMode,
      home: DebugPage(onThemeToggle: _toggleTheme),
    );
  }
}

class DebugPage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const DebugPage({super.key, required this.onThemeToggle});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  late MarkdownTextEditingController _controller;

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
    _controller.updateStyleSheet(MarkdownStyleSheet.fromTheme(Theme.of(context)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Controller Debug'),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: widget.onThemeToggle,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
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
