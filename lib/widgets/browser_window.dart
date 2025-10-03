import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

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
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          // Browser controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppTheme.textPrimary,
                  onPressed: () async {
                    if (!kIsWeb) {
                      if (await _controller.canGoBack()) {
                        await _controller.goBack();
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  color: AppTheme.textPrimary,
                  onPressed: () async {
                    if (!kIsWeb) {
                      if (await _controller.canGoForward()) {
                        await _controller.goForward();
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: AppTheme.textPrimary,
                  onPressed: () {
                    if (!kIsWeb) {
                      _controller.reload();
                    } else {
                      final url = _urlController.text;
                      if (url.isNotEmpty) {
                        _openExternal(url);
                      }
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter URL',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppTheme.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    onSubmitted: (value) {
                      String url = value;
                      if (!url.startsWith('http')) {
                        url = 'https://$url';
                      }
                      if (kIsWeb) {
                        _openExternal(url);
                      } else {
                        _controller.loadRequest(Uri.parse(url));
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.home),
                  color: AppTheme.textPrimary,
                  onPressed: () {
                    final url = 'https://www.google.com';
                    if (kIsWeb) {
                      _openExternal(url);
                    } else {
                      _controller.loadRequest(Uri.parse(url));
                    }
                  },
                ),
              ],
            ),
          ),
          // Browser content
          Expanded(
            child: kIsWeb
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.open_in_new, color: AppTheme.textPrimary),
                          const SizedBox(height: 12),
                          Text(
                            'WebView is not supported in Flutter Web here. Opened in a new tab.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (isLoading)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: AppTheme.primaryPink,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Loading...",
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
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

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
