
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class FileSystemItem {
  final String id;
  final String name;
  final bool isFolder;
  final String? parentId;
  final String? content;

  FileSystemItem({
    required this.id,
    required this.name,
    required this.isFolder,
    this.parentId,
    this.content,
  });

  factory FileSystemItem.fromJson(Map<String, dynamic> json) {
    return FileSystemItem(
      id: json['id'],
      name: json['name'],
      isFolder: json['is_folder'],
      parentId: json['parent_id'],
      content: json['content'],
    );
  }
}

class FilesProvider with ChangeNotifier {
  List<FileSystemItem> _items = [];
  String? _currentFolderId;

  List<FileSystemItem> get items => _items;

  FilesProvider() {
    fetchFiles();
  }

  Future<void> fetchFiles({String? parentId}) async {
    _currentFolderId = parentId;
    final url = Uri.parse('${Config.apiBaseUrl}/files/?parent_id=${parentId ?? ''}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _items = data.map((item) => FileSystemItem.fromJson(item)).toList();
        notifyListeners();
      } else {
        // If API fails, provide mock data for testing
        _items = [
          FileSystemItem(id: 'root1', name: 'Documents', isFolder: true, parentId: null),
          FileSystemItem(id: 'root2', name: 'Pictures', isFolder: true, parentId: null),
          FileSystemItem(id: 'root3', name: 'readme.txt', isFolder: false, parentId: null, content: 'Welcome to LoveOS file system!'),
        ];
        notifyListeners();
      }
    } catch (e) {
      // Handle error with mock data
      _items = [
        FileSystemItem(id: 'root1', name: 'Documents', isFolder: true, parentId: null),
        FileSystemItem(id: 'root2', name: 'Pictures', isFolder: true, parentId: null),
        FileSystemItem(id: 'root3', name: 'readme.txt', isFolder: false, parentId: null, content: 'Welcome to LoveOS file system!'),
      ];
      notifyListeners();
      print(e);
    }
  }

  Future<void> createFile(String name, {bool isFolder = false, String? content}) async {
    final url = Uri.parse('${Config.apiBaseUrl}/files/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'is_folder': isFolder,
          'parent_id': _currentFolderId,
          'content': content,
        }),
      );
      if (response.statusCode == 200) {
        fetchFiles(parentId: _currentFolderId);
      }
    } catch (e) {
      // Handle error
      print(e);
    }
  }
  
  Future<FileSystemItem?> getFileContent(String fileId) async {
    final url = Uri.parse('${Config.apiBaseUrl}/files/$fileId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FileSystemItem.fromJson(data);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }
  
  Future<bool> updateFileContent(String fileId, String content) async {
    final url = Uri.parse('${Config.apiBaseUrl}/files/$fileId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': content,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
