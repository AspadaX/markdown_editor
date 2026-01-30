import 'package:editor/bit_markdown/editor_parser.dart';
import 'package:editor/bit_markdown/text_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FocusNode focus = FocusNode();
  FocusNode textFieldFocus = FocusNode();
  KeyEvent? key;
  final TextEditingController textController = MarkdownTextEditingController(
    MarkdownEditorParser(),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String?> getClipboardText() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  Widget buildOptimizedMarkdownEditor() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text("$key")),
        Expanded(
          child: TextField(
            maxLines: null,
            focusNode: textFieldFocus,
            controller: textController,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  // Widget buildHandRolledMarkdownEditor() {
  //   return KeyboardListener(
  //     autofocus: true,
  //     focusNode: focus,
  //     onKeyEvent: (KeyEvent keyEvent) async {
  //       if (keyEvent is! KeyDownEvent) return;

  //       final bool isPaste =
  //           (keyEvent.logicalKey == LogicalKeyboardKey.keyV) &&
  //           (HardwareKeyboard.instance.isControlPressed ||
  //               HardwareKeyboard.instance.isMetaPressed);

  //       if (isPaste) {
  //         String? clipboardText = await getClipboardText();
  //         if (clipboardText != null) {
  //           text += clipboardText;
  //         }
  //         return;
  //       }

  //       if (keyEvent.physicalKey == PhysicalKeyboardKey.enter) {
  //         text += '\n';
  //       }

  //       if (keyEvent.physicalKey == PhysicalKeyboardKey.backspace) {
  //         if (text.isNotEmpty) {
  //           text = text.substring(0, text.length - 1);
  //         }
  //       }

  //       if (keyEvent.character != null) {
  //         text += keyEvent.character!;
  //       }

  //       key = keyEvent;

  //       setState(() {});
  //     },
  //     child: Column(
  //       children: [
  //         Padding(padding: const EdgeInsets.all(12), child: Text("$key")),
  //         // ...MarkdownGenerator().buildWidgets(text),
  //         Expanded(child: BitMarkdown(text)),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: buildOptimizedMarkdownEditor(),
    );
  }
}
