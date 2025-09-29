
// lib/config.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Config {
  // Static map to store all configuration values
  static final Map<String, dynamic> _config = {
    'apiBaseUrl': "http://127.0.0.1:8000",
    'showNsfw': true,
    'appName': "LoveOS",
    'version': "1.0.0",
    'loverName': "Eshal",
    'primaryColor': "#FF4081",
    'accentColor': "#03A9F4",
    'darkMode': false,
    'animationSpeed': 300,
    'defaultFontSize': 16.0,
    'enableNotifications': true,
    'autoSave': true,
    'language': "en"
  };

  // Dynamic getter for any configuration value
  static dynamic get(String key) {
    if (key == 'primaryColor' && _config[key] is String) {
      return _hexToColor(_config[key]);
    }
    if (key == 'accentColor' && _config[key] is String) {
      return _hexToColor(_config[key]);
    }
    return _config[key];
  }

  // Load configuration from config.json
  static Future<void> loadConfig() async {
    try {
      // Use rootBundle to load asset in Flutter web
      final jsonString = await rootBundle.loadString('assets/config.json');
      final Map<String, dynamic> loadedConfig = jsonDecode(jsonString);
      
      // Update the config map with loaded values
      _config.addAll(loadedConfig);
    } catch (e) {
      print('Error loading config.json: $e');
      // Use default values if config.json cannot be loaded
    }
  }
  
  // Helper method to convert hex color string to Color
  static Color _hexToColor(String hexString) {
    final hexColor = hexString.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  // Convenience getters for commonly used values
  static String get apiBaseUrl => _config['apiBaseUrl'];
  static bool get showNsfw => _config['showNsfw'];
  static String get appName => _config['appName'];
  static String get version => _config['version'];
  static String get loverName => _config['loverName'];
  static Color get primaryColor => get('primaryColor');
  static Color get accentColor => get('accentColor');
  static bool get darkMode => _config['darkMode'];
  
  // Command lists
  static const List<String> sfwCommands = [
    "waifu", "neko", "shinobu", "megumin", "bully", "cuddle", "cry", "hug", 
    "awoo", "kiss", "lick", "pat", "smug", "bonk", "yeet", "blush", "smile", 
    "wave", "highfive", "handhold", "nom", "bite", "glomp", "slap", "kill", 
    "kick", "happy", "wink", "poke", "dance", "cringe"
  ];

  static const List<String> nsfwCommands = ["nsfwwaifu", "nsfwneko", "trap", "blowjob"];
}
