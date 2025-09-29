import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
          decoration: AppTheme.windowDecoration,
          child: Column(
            children: [
              // Window title bar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      "LoveOS",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                      onPressed: () => widget.onClose(widget),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
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
