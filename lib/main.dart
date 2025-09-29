import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'config.dart';
import 'providers/files_provider.dart';
import 'screens/desktop_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register WebView plugin for web platform
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }
  
  // Load configuration from config.json
  Config.loadConfig();
  
  // Load quotes from quotes.json
  await loadQuotes();
  
  // Load cute responses
  await loadCuteResponses();
  
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

// Global cute responses list
List<String> cuteResponses = [];

Future<void> loadQuotes() async {
  try {
    final String jsonString = await rootBundle.loadString('assets/quotes.json');
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

Future<void> loadCuteResponses() async {
  try {
    final String jsonString = await rootBundle.loadString('assets/cute_responses.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    cuteResponses = List<String>.from(jsonData['cute_responses']);
  } catch (e) {
    print('Error loading cute responses: $e');
    // Fallback responses
    cuteResponses = [
      'kawaii magic from the cloud! ✨',
      'brought to you by fluffy servers! 🐱',
      'delivered with love and sparkles! 💖'
    ];
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoveOS',
      theme: AppTheme.darkTheme,
      home: const DesktopScreen(),
    );
  }
}