import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/draggable_window.dart';
import '../widgets/terminal_window.dart';
import '../widgets/browser_window.dart';
import '../widgets/finder_window.dart';
import '../widgets/media_player.dart';
import '../theme/app_theme.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  _DesktopScreenState createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  final List<Widget> openWindows = [];

  void _openWindow(Widget window) {
    setState(() {
      openWindows.add(window);
    });
  }

  void _openMediaWindow(String url, [String? title]) {
    _openWindow(
      DraggableWindow(
        onClose: (window) => _closeWindow(window),
        child: MediaWindow(url: url, title: title),
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
                // Finder Icon
                GestureDetector(
                  onTap: () => _openWindow(
                    DraggableWindow(
                      onClose: (window) => _closeWindow(window),
                      child: FinderWindow(),
                    ),
                  ),
                  child: _buildDesktopIcon(Icons.folder, "Finder"),
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
          width: 70,
          height: 70,
          decoration: AppTheme.desktopIconDecoration,
          child: Icon(
            icon,
            color: AppTheme.textPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                blurRadius: 3.0,
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
