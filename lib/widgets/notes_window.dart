import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotesWindow extends StatefulWidget {
  @override
  _NotesWindowState createState() => _NotesWindowState();
}

class _NotesWindowState extends State<NotesWindow> {
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _notesController.text = "Dear Eshal,\n\nI love you so much! ❤️\n\nYou make my world brighter every day.\n\nYours forever,\nLovely";
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _notesController,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.primaryPink,
          fontFamily: 'monospace',
        ),
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Write your love notes here... 💕',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
