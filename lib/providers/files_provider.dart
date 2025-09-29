
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../config.dart';

class FileSystemItem {
  final String id;
  final String name;
  final bool isFolder;
  final String? parentId;
  final String? content;
  final DateTime lastUpdated;

  FileSystemItem({
    required this.id,
    required this.name,
    required this.isFolder,
    this.parentId,
    this.content,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory FileSystemItem.fromJson(Map<String, dynamic> json) {
    return FileSystemItem(
      id: json['id'],
      name: json['name'],
      isFolder: json['is_folder'],
      parentId: json['parent_id'],
      content: json['content'],
      lastUpdated: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_folder': isFolder,
      'parent_id': parentId,
      'content': content,
    };
  }
}

enum SyncStatus {
  idle,
  syncing,
  error,
  success,
}

class FilesProvider extends ChangeNotifier {
  List<FileSystemItem> _items = [];
  SyncStatus _syncStatus = SyncStatus.idle;
  
  List<FileSystemItem> get items => _items;
  SyncStatus get syncStatus => _syncStatus;

  FilesProvider() {
    _initialize();
  }
  
  void _initialize() {
    _useMockData();
  }
  
  void _useMockData() {
    _items = [
      FileSystemItem(id: 'root1', name: 'Documents', isFolder: true, parentId: null),
      FileSystemItem(id: 'root2', name: 'Pictures', isFolder: true, parentId: null),
      FileSystemItem(id: 'root3', name: 'Music', isFolder: true, parentId: null),
      FileSystemItem(id: 'root4', name: 'readme.txt', isFolder: false, parentId: null, content: 'Welcome to LoveOS file system!'),
      FileSystemItem(id: 'root5', name: 'notes.txt', isFolder: false, parentId: null, content: 'Important notes for my love.'),
      FileSystemItem(id: 'root6', name: 'todo.txt', isFolder: false, parentId: null, content: '1. Fix API\n2. Add more features\n3. Make it beautiful'),
    ];
  }

  Future<void> fetchFiles({String? parentId}) async {
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
    
    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/files${parentId != null ? "?parent_id=$parentId" : ""}';
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _items = data.map((item) => FileSystemItem.fromJson(item)).toList();
        _syncStatus = SyncStatus.success;
      } else {
        print("Error fetching files: ${response.statusCode}");
        _syncStatus = SyncStatus.error;
        // Fallback to mock data if API fails
        _useMockData();
      }
    } catch (e) {
      print("Exception fetching files: ${e.toString()}");
      _syncStatus = SyncStatus.error;
      // Fallback to mock data if API fails
      _useMockData();
    }
    
    notifyListeners();
  }
  
  Future<bool> updateFile(String fileId, String newContent) async {
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
    
    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/files/$fileId';
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': newContent})
      );
      
      if (response.statusCode == 200) {
        final index = _items.indexWhere((item) => item.id == fileId);
        if (index >= 0) {
          final item = _items[index];
          _items[index] = FileSystemItem(
            id: item.id,
            name: item.name,
            isFolder: item.isFolder,
            parentId: item.parentId,
            content: newContent,
            lastUpdated: DateTime.now(),
          );
        }
        
        _syncStatus = SyncStatus.success;
        notifyListeners();
        return true;
      } else {
        print("Error updating file: ${response.statusCode}");
        _syncStatus = SyncStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _syncStatus = SyncStatus.error;
      print("Error updating file: ${e.toString()}");
      notifyListeners();
      return false;
    }
  }
  
  // Navigate to a folder
  Future<void> navigateToFolder(String? folderId) async {
    await fetchFiles(parentId: folderId);
  }
  
  // Force refresh the current folder
  Future<void> refreshCurrentFolder() async {
    await fetchFiles();
  }
  
  Future<void> syncWithBackend() async {
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
    
    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/sync';
      final response = await http.post(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        await fetchFiles();
        _syncStatus = SyncStatus.success;
      } else {
        print("Error syncing with backend: ${response.statusCode}");
        _syncStatus = SyncStatus.error;
      }
    } catch (e) {
      print("Exception syncing with backend: ${e.toString()}");
      _syncStatus = SyncStatus.error;
    }
    
    notifyListeners();
  }
}
