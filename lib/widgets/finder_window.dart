import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../theme/app_theme.dart';
import 'media_player.dart';

class FinderWindow extends StatefulWidget {
  const FinderWindow({super.key});

  @override
  _FinderWindowState createState() => _FinderWindowState();
}

class _FinderWindowState extends State<FinderWindow> {
  String _currentPath = '/';
  List<FileSystemItem> _items = [];
  bool _isLoading = false;
  String _error = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/files?path=${Uri.encodeComponent(_currentPath)}';
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _items = (data['items'] as List)
              .map((item) => FileSystemItem.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load directory';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToDirectory(String path) async {
    setState(() {
      _currentPath = path;
    });
    await _loadDirectory();
  }

  Future<void> _createFile() async {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Create File', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter filename',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createNewFile(nameController.text);
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewFile(String filename) async {
    if (filename.isEmpty) return;
    
    final filePath = _currentPath == '/' ? '/$filename' : '$_currentPath/$filename';
    
    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/files/create';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': filePath, 'content': ''}),
      );
      
      if (response.statusCode == 200) {
        await _loadDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created file: $filename'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['detail']}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _createDirectory() async {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Create Directory', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter directory name',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createNewDirectory(nameController.text);
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewDirectory(String dirname) async {
    if (dirname.isEmpty) return;
    
    final dirPath = _currentPath == '/' ? '/$dirname' : '$_currentPath/$dirname';
    
    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/files/mkdir';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': dirPath}),
      );
      
      if (response.statusCode == 200) {
        await _loadDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created directory: $dirname'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['detail']}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteItem(FileSystemItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete ${item.isDirectory ? 'Directory' : 'File'}', 
               style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to delete "${item.name}"?',
                     style: const TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiUrl = item.isDirectory 
          ? '${Config.get('apiBaseUrl')}/files/rmdir?path=${Uri.encodeComponent(item.path)}'
          : '${Config.get('apiBaseUrl')}/files/delete?path=${Uri.encodeComponent(item.path)}';
      
      final response = await http.delete(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        await _loadDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${item.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['detail']}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _openItem(FileSystemItem item) async {
    if (item.isDirectory) {
      await _navigateToDirectory(item.path);
    } else {
      // Check if it's a media file
      final name = item.name.toLowerCase();
      final mediaExtensions = [
        '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', // Images
        '.mp4', '.avi', '.mov', '.mkv', '.webm', '.m4v', '.3gp', '.flv' // Videos
      ];
      
      if (mediaExtensions.any((ext) => name.endsWith(ext))) {
        // Open in media player
        showDialog(
          context: context,
          builder: (context) => MediaViewerDialog(
            url: item.content,
            title: item.name,
          ),
        );
      } else {
        // Show file content
        _showFileContent(item);
      }
    }
  }

  void _showFileContent(FileSystemItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(item.name, style: const TextStyle(color: AppTheme.textPrimary)),
        content: SizedBox(
          width: 400,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              item.content,
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _goUp() {
    if (_currentPath == '/') return;
    
    final parts = _currentPath.split('/')..removeLast();
    final newPath = parts.join('/');
    _navigateToDirectory(newPath.isEmpty ? '/' : newPath);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.mediaPlayerDecoration,
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _currentPath == '/' ? null : _goUp,
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                ),
                IconButton(
                  onPressed: _loadDirectory,
                  icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  onPressed: _createFile,
                  icon: const Icon(Icons.note_add, color: AppTheme.textPrimary),
                  tooltip: 'Create File',
                ),
                IconButton(
                  onPressed: _createDirectory,
                  icon: const Icon(Icons.create_new_folder, color: AppTheme.textPrimary),
                  tooltip: 'Create Directory',
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: AppTheme.errorColor, size: 48),
                            const SizedBox(height: 16),
                            Text(_error, style: const TextStyle(color: AppTheme.errorColor)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDirectory,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Text(
                              'Directory is empty',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _buildFileItem(item);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileSystemItem item) {
    return ListTile(
      leading: Icon(
        item.isDirectory ? Icons.folder : Icons.description,
        color: item.isDirectory ? AppTheme.primaryColor : AppTheme.textPrimary,
      ),
      title: Text(
        item.name,
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      subtitle: Text(
        item.isDirectory 
            ? 'Directory' 
            : '${item.size} bytes • ${_formatDate(item.lastModified)}',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'open':
              _openItem(item);
              break;
            case 'delete':
              _deleteItem(item);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'open',
            child: Text('Open', style: TextStyle(color: AppTheme.textPrimary)),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
        child: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
      ),
      onTap: () => _openItem(item),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class FileSystemItem {
  final String name;
  final String path;
  final bool isDirectory;
  final String content;
  final int size;
  final String lastModified;

  FileSystemItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.content,
    required this.size,
    required this.lastModified,
  });

  factory FileSystemItem.fromJson(Map<String, dynamic> json) {
    return FileSystemItem(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      isDirectory: json['is_directory'] ?? false,
      content: json['content'] ?? '',
      size: json['size'] ?? 0,
      lastModified: json['last_modified'] ?? '',
    );
  }
}

