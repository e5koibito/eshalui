import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'config.dart';
import 'providers/files_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register WebView plugin for web platform
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }
  
  // Load configuration from config.json
  await Config.loadConfig();
  
  // Load quotes from quotes.json
  await loadQuotes();
  
  // Small delay to ensure config is loaded
  await Future.delayed(Duration(milliseconds: 100));
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FilesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Global quotes map
Map<String, List<String>> quotes = {
  'loading': ['Loading...'],
  'error': ['An error occurred.'],
  'welcome': ['Welcome!']
};

Future<void> loadQuotes() async {
  try {
    final String jsonString = await rootBundle.loadString('lib/quotes.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    quotes = {
      'loading': List<String>.from(jsonData['loading']),
      'error': List<String>.from(jsonData['error']),
      'welcome': List<String>.from(jsonData['welcome']),
    };
  } catch (e) {
    print('Error loading quotes: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoveOS',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        hintColor: Colors.white,
        brightness: Brightness.dark,
        fontFamily: 'monospace',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
          primary: Colors.pink[300],
          secondary: Colors.pinkAccent,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const LoveOSDesktop(),
    );
  }
}

class LoveOSDesktop extends StatefulWidget {
  const LoveOSDesktop({super.key});

  @override
  _LoveOSDesktopState createState() => _LoveOSDesktopState();
}

class _LoveOSDesktopState extends State<LoveOSDesktop> {
  final List<Widget> openWindows = [];

  void _openWindow(Widget window) {
    setState(() {
      openWindows.add(window);
    });
  }

  void _openMediaWindow(String url) {
    _openWindow(
      DraggableWindow(
        onClose: (window) => _closeWindow(window),
        child: MediaWindow(url: url),
      ),
    );
  }
  
  void _openBrowserWindow(String url) {
    _openWindow(
      DraggableWindow(
        onClose: (window) => _closeWindow(window),
        child: BrowserWindow(initialUrl: url),
      ),
    );
  }
  
  String _getRandomQuote(String type) {
    if (quotes.containsKey(type) && quotes[type]!.isNotEmpty) {
      final random = DateTime.now().millisecondsSinceEpoch % quotes[type]!.length;
      return quotes[type]![random];
    }
    return type == 'loading' ? "Loading..." : "Error occurred";
  }
  
  void _closeWindow(Widget window) {
    setState(() {
      openWindows.remove(window);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Desktop Background
          SvgPicture.asset(
            "assets/images/background.svg",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Open Windows
          ...openWindows,
          // Desktop Icons
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                // Terminal Icon
                GestureDetector(
                  onTap: () => _openWindow(
                    DraggableWindow(
                      onClose: (window) => _closeWindow(window),
                      child: TerminalWindow(openMediaWindow: _openMediaWindow),
                    ),
                  ),
                  child: _buildDesktopIcon(Icons.terminal, "Terminal"),
                ),
                const SizedBox(height: 20),
                // Browser Icon
                GestureDetector(
                  onTap: () => _openWindow(
                    DraggableWindow(
                      onClose: (window) => _closeWindow(window),
                      child: BrowserWindow(initialUrl: "https://www.google.com"),
                    ),
                  ),
                  child: _buildDesktopIcon(Icons.web, "Browser"),
                ),
                const SizedBox(height: 20),
                // Notes Icon
                GestureDetector(
                  onTap: () => _openWindow(
                    DraggableWindow(
                      onClose: (window) => _closeWindow(window),
                      child: NotesWindow(),
                    ),
                  ),
                  child: _buildDesktopIcon(Icons.note, "Notes"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.pink[300]!, width: 2),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DraggableWindow extends StatefulWidget {
  final Widget child;
  final Function(Widget) onClose;

  const DraggableWindow({
    super.key,
    required this.child,
    required this.onClose,
  });

  @override
  _DraggableWindowState createState() => _DraggableWindowState();
}

class _DraggableWindowState extends State<DraggableWindow> {
  double xPosition = 100;
  double yPosition = 100;
  double windowWidth = 800;
  double windowHeight = 600;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: xPosition,
      top: yPosition,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            xPosition += details.delta.dx;
            yPosition += details.delta.dy;
          });
        },
        child: Container(
          width: windowWidth,
          height: windowHeight,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.pink[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Window title bar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.pink[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Text(
                      "LoveOS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => widget.onClose(widget),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              // Window content
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrowserWindow extends StatefulWidget {
  final String initialUrl;
  const BrowserWindow({super.key, required this.initialUrl});

  @override
  _BrowserWindowState createState() => _BrowserWindowState();
}

class _BrowserWindowState extends State<BrowserWindow> {
  late WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  bool isLoading = true;
  String currentUrl = '';
  
  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl;
    currentUrl = widget.initialUrl;
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              currentUrl = url;
              _urlController.text = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 600,
      color: Colors.white,
      child: Column(
        children: [
          // Browser controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.grey[900],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      await _controller.goBack();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  color: Colors.white,
                  onPressed: () async {
                    if (await _controller.canGoForward()) {
                      await _controller.goForward();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: Colors.white,
                  onPressed: () {
                    _controller.reload();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter URL',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    onSubmitted: (value) {
                      String url = value;
                      if (!url.startsWith('http')) {
                        url = 'https://$url';
                      }
                      _controller.loadRequest(Uri.parse(url));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.home),
                  color: Colors.white,
                  onPressed: () {
                    _controller.loadRequest(Uri.parse('https://www.google.com'));
                  },
                ),
              ],
            ),
          ),
          // Browser content
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (isLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.pink,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Loading...",
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TerminalWindow extends StatefulWidget {
  final Function(String) openMediaWindow;

  const TerminalWindow({super.key, required this.openMediaWindow});

  @override
  _TerminalWindowState createState() => _TerminalWindowState();
}

class _TerminalWindowState extends State<TerminalWindow> {
  final TextEditingController _commandController = TextEditingController();
  final List<String> _commandHistory = [];
  final List<String> _outputHistory = [];
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _outputHistory.add(Config.get('terminalWelcomeMessage') ?? "Welcome to LoveOS Terminal");
  }

  void _executeCommand(String command) {
    setState(() {
      _commandHistory.add(command);
      _commandController.clear();
      
      // Process command
      if (command.toLowerCase() == 'help') {
        _outputHistory.add('Available commands:');
        _outputHistory.add('- help: Show this help message');
        _outputHistory.add('- clear: Clear the terminal');
        _outputHistory.add('- kiss: Send a kiss');
        _outputHistory.add('- hug: Send a hug');
        _outputHistory.add('- cuddle: Send a cuddle');
      } else if (command.toLowerCase() == 'clear') {
        _outputHistory.clear();
      } else if (command.toLowerCase() == 'kiss') {
        _outputHistory.add('Sending a kiss...');
        widget.openMediaWindow('https://media.giphy.com/media/l0HlGdXFWYbKv5rby/giphy.gif');
      } else if (command.toLowerCase() == 'hug') {
        _outputHistory.add('Sending a hug...');
        widget.openMediaWindow('https://media.giphy.com/media/3M4NpbLCTxBqU/giphy.gif');
      } else if (command.toLowerCase() == 'cuddle') {
        _outputHistory.add('Sending a cuddle...');
        widget.openMediaWindow('https://media.giphy.com/media/ZBQhoZC0nqknSviPqT/giphy.gif');
      } else {
        _outputHistory.add('Command not recognized: $command');
      }
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Terminal output
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _outputHistory.length,
              itemBuilder: (context, index) {
                return Text(
                  _outputHistory[index],
                  style: const TextStyle(color: Colors.green),
                );
              },
            ),
          ),
          // Command input
          Row(
            children: [
              const Text(
                '> ',
                style: TextStyle(color: Colors.green),
              ),
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: const TextStyle(color: Colors.green),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter command',
                    hintStyle: TextStyle(color: Colors.green),
                  ),
                  onSubmitted: _executeCommand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MediaWindow extends StatelessWidget {
  final String url;
  
  const MediaWindow({super.key, required this.url});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      color: Colors.black,
      child: Center(
        child: Image.network(
          url,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.pink,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Error loading image',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NotesWindow extends StatefulWidget {
  @override
  _NotesWindowState createState() => _NotesWindowState();
}

class _NotesWindowState extends State<NotesWindow> {
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _notesController.text = "Dear Eshal,\n\nI love you so much! ❤️\n\nYours forever,\nLovely";
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _notesController,
        style: const TextStyle(color: Colors.pink),
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Write your notes here...',
          hintStyle: TextStyle(color: Colors.pink),
        ),
      ),
    );
  }
}
