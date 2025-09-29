import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class TerminalWindow extends StatefulWidget {
  final Function(String, [String?]) openMediaWindow;

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

  // Current directory for file navigation
  String _currentDirectory = '/';

  Future<void> _sendCommand(String commandType) async {
    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/commands';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'type': commandType})
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['url'] != null) {
          // Get a random cute response
          String cuteResponse = _getRandomCuteResponse();
          
          // Add the cute response to output
          setState(() {
            _outputHistory.add(cuteResponse);
          });
          
          // Open the GIF in a media window with cute title
          widget.openMediaWindow(data['url'], cuteResponse);
        }
      } else {
        print("Error sending command: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception sending command: ${e.toString()}");
    }
  }

  String _getRandomCuteResponse() {
    if (cuteResponses.isEmpty) {
      return 'kawaii magic from the cloud! ✨';
    }
    final random = Random();
    return cuteResponses[random.nextInt(cuteResponses.length)];
  }

  void _executeCommand(String command) async {
    setState(() {
      _commandHistory.add(command);
      _commandController.clear();
    });
    
    // Split command into parts
    final parts = command.trim().split(' ');
    final cmd = parts.isNotEmpty ? parts[0].toLowerCase() : '';
    final args = parts.length > 1 ? parts.sublist(1) : [];
    
    // Process command
    switch (cmd) {
        case 'help':
          setState(() {
            _outputHistory.add('Available commands:');
            _outputHistory.add('help - Display this help message');
            _outputHistory.add('clear - Clear the terminal');
            _outputHistory.add('ls - List directory contents');
            _outputHistory.add('cd [dir] - Change directory');
            _outputHistory.add('pwd - Print working directory');
            _outputHistory.add('cat [file] - Display file contents');
            _outputHistory.add('touch [file] - Create a new file');
            _outputHistory.add('mkdir [dir] - Create a new directory');
            _outputHistory.add('rm [file] - Remove a file');
            _outputHistory.add('rmdir [dir] - Remove a directory');
            _outputHistory.add('chmod [mode] [file] - Change file permissions');
            _outputHistory.add('whoami - Show current user');
            _outputHistory.add('date - Show current date and time');
            _outputHistory.add('echo [text] - Display text');
            _outputHistory.add('sudo [command] - Execute command as superuser');
            _outputHistory.add('open [file] - Open file in media player');
            _outputHistory.add('SFW Commands:');
            _outputHistory.add('kiss, hug, cuddle, pat, handhold');
            _outputHistory.add('waifu, neko, shinobu, megumin, bully');
            _outputHistory.add('cry, awoo, lick, smug, bonk, yeet');
            _outputHistory.add('blush, smile, wave, highfive, nom');
            _outputHistory.add('bite, glomp, slap, kill, kick, happy');
            _outputHistory.add('wink, poke, dance, cringe');
            _outputHistory.add('NSFW Commands:');
            _outputHistory.add('nsfwwaifu, nsfwneko, nsfwspank, nsfwbite');
            _outputHistory.add('nsfwblowjob, nsfwtrap, nsfwthighs, nsfwass');
            _outputHistory.add('nsfwboobs, nsfwfeet, nsfwfuta, nsfwhentai');
            _outputHistory.add('nsfworgy, nsfwpaizuri, nsfwyaoi, nsfwyuri');
          });
          break;
          
        case 'clear':
          setState(() {
            _outputHistory.clear();
          });
          break;
          
        case 'ls':
          await _listDirectory();
          break;
          
        case 'cd':
          if (args.isEmpty) {
            setState(() {
              _currentDirectory = '/';
              _outputHistory.add('Changed to root directory');
            });
          } else {
            await _changeDirectory(args[0]);
          }
          break;
          
        case 'pwd':
          setState(() {
            _outputHistory.add(_currentDirectory);
          });
          break;
          
        case 'cat':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('Usage: cat [filename]');
            });
          } else {
            await _displayFile(args[0]);
          }
          break;
          
        case 'touch':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('Usage: touch [filename]');
            });
          } else {
            await _createFile(args[0]);
          }
          break;
          
        case 'mkdir':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('Usage: mkdir [dirname]');
            });
          } else {
            await _createDirectory(args[0]);
          }
          break;
          
        case 'rm':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('Usage: rm [filename]');
            });
          } else {
            await _removeFile(args[0]);
          }
          break;
          
        case 'rmdir':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('Usage: rmdir [dirname]');
            });
          } else {
            await _removeDirectory(args[0]);
          }
          break;
          
        case 'chmod':
          if (args.length < 2) {
            setState(() {
              _outputHistory.add('Usage: chmod [mode] [file]');
            });
          } else {
            _changePermissions(args[0], args[1]);
          }
          break;
          
        case 'whoami':
          setState(() {
            _outputHistory.add('eshal');
          });
          break;
          
        case 'date':
          setState(() {
            _outputHistory.add(DateTime.now().toString());
          });
          break;
          
        case 'echo':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('');
            });
          } else {
            setState(() {
              _outputHistory.add(args.join(' '));
            });
          }
          break;
          
        case 'sudo':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('Usage: sudo [command]');
            });
          } else {
            await _executeSudoCommand(args.join(' '));
          }
          break;
          
        case 'open':
          if (args.isEmpty) {
            setState(() {
              _outputHistory.add('Usage: open [filename]');
            });
          } else {
            await _openFile(args[0]);
          }
          break;
          
        // SFW Commands
        case 'kiss':
          setState(() {
            _outputHistory.add('kissweiees for chu! :D');
          });
          _sendCommand('kiss');
          break;
          
        case 'hug':
          setState(() {
            _outputHistory.add('warm hugs for eshal UwU');
          });
          _sendCommand('hug');
          break;
          
        case 'cuddle':
          setState(() {
            _outputHistory.add('cuddles with love <3');
          });
          _sendCommand('cuddle');
          break;
          
        case 'pat':
          setState(() {
            _outputHistory.add('gentle pats for you :3');
          });
          _sendCommand('pat');
          break;
          
        case 'handhold':
          setState(() {
            _outputHistory.add('holding hands with eshal ^w^');
          });
          _sendCommand('handhold');
          break;
          
        case 'waifu':
          setState(() {
            _outputHistory.add('cute waifu for eshal! :3');
          });
          _sendCommand('waifu');
          break;
          
        case 'neko':
          setState(() {
            _outputHistory.add('kawaii neko for chu! :D');
          });
          _sendCommand('neko');
          break;
          
        case 'shinobu':
          setState(() {
            _outputHistory.add('shinobu chan for eshal! UwU');
          });
          _sendCommand('shinobu');
          break;
          
        case 'megumin':
          setState(() {
            _outputHistory.add('EXPLOSION! megumin for chu! :3');
          });
          _sendCommand('megumin');
          break;
          
        case 'bully':
          setState(() {
            _outputHistory.add('playful bullying for eshal! >w<');
          });
          _sendCommand('bully');
          break;
          
        case 'cry':
          setState(() {
            _outputHistory.add('crying together with eshal! T_T');
          });
          _sendCommand('cry');
          break;
          
        case 'awoo':
          setState(() {
            _outputHistory.add('awoo awoo for eshal! :D');
          });
          _sendCommand('awoo');
          break;
          
        case 'lick':
          setState(() {
            _outputHistory.add('gentle licks for chu! :P');
          });
          _sendCommand('lick');
          break;
          
        case 'smug':
          setState(() {
            _outputHistory.add('smug face for eshal! >:3');
          });
          _sendCommand('smug');
          break;
          
        case 'bonk':
          setState(() {
            _outputHistory.add('bonk bonk for eshal! :D');
          });
          _sendCommand('bonk');
          break;
          
        case 'yeet':
          setState(() {
            _outputHistory.add('yeet yeet for chu! :3');
          });
          _sendCommand('yeet');
          break;
          
        case 'blush':
          setState(() {
            _outputHistory.add('blushing for eshal! >///<');
          });
          _sendCommand('blush');
          break;
          
        case 'smile':
          setState(() {
            _outputHistory.add('happy smile for chu! :D');
          });
          _sendCommand('smile');
          break;
          
        case 'wave':
          setState(() {
            _outputHistory.add('waving at eshal! ^w^');
          });
          _sendCommand('wave');
          break;
          
        case 'highfive':
          setState(() {
            _outputHistory.add('high five with eshal! :D');
          });
          _sendCommand('highfive');
          break;
          
        case 'nom':
          setState(() {
            _outputHistory.add('nom nom for chu! :3');
          });
          _sendCommand('nom');
          break;
          
        case 'bite':
          setState(() {
            _outputHistory.add('gentle bite for eshal! :P');
          });
          _sendCommand('bite');
          break;
          
        case 'glomp':
          setState(() {
            _outputHistory.add('glomp glomp for chu! UwU');
          });
          _sendCommand('glomp');
          break;
          
        case 'slap':
          setState(() {
            _outputHistory.add('playful slap for eshal! >w<');
          });
          _sendCommand('slap');
          break;
          
        case 'kill':
          setState(() {
            _outputHistory.add('murderous intent for chu! :3');
          });
          _sendCommand('kill');
          break;
          
        case 'kick':
          setState(() {
            _outputHistory.add('kick kick for eshal! :D');
          });
          _sendCommand('kick');
          break;
          
        case 'happy':
          setState(() {
            _outputHistory.add('happiness for chu! ^w^');
          });
          _sendCommand('happy');
          break;
          
        case 'wink':
          setState(() {
            _outputHistory.add('wink wink for eshal! ;3');
          });
          _sendCommand('wink');
          break;
          
        case 'poke':
          setState(() {
            _outputHistory.add('poke poke for chu! :3');
          });
          _sendCommand('poke');
          break;
          
        case 'dance':
          setState(() {
            _outputHistory.add('dancing with eshal! :D');
          });
          _sendCommand('dance');
          break;
          
        case 'cringe':
          setState(() {
            _outputHistory.add('cringe cringe for chu! >w<');
          });
          _sendCommand('cringe');
          break;
          
        // NSFW Commands
        case 'nsfwwaifu':
          setState(() {
            _outputHistory.add('spicy waifu for eshal! >w<');
          });
          _sendCommand('nsfwwaifu');
          break;
          
        case 'nsfwneko':
          setState(() {
            _outputHistory.add('naughty neko for chu! :3');
          });
          _sendCommand('nsfwneko');
          break;
          
        case 'nsfwspank':
          setState(() {
            _outputHistory.add('playful spanks for eshal! >w<');
          });
          _sendCommand('nsfwspank');
          break;
          
        case 'nsfwbite':
          setState(() {
            _outputHistory.add('gentle bites for chu! :P');
          });
          _sendCommand('nsfwbite');
          break;
          
        case 'nsfwblowjob':
          setState(() {
            _outputHistory.add('blowjob for eshal! >///<');
          });
          _sendCommand('nsfwblowjob');
          break;
          
        case 'nsfwtrap':
          setState(() {
            _outputHistory.add('trap for chu! :3');
          });
          _sendCommand('nsfwtrap');
          break;
          
        case 'nsfwthighs':
          setState(() {
            _outputHistory.add('thighs for eshal! >w<');
          });
          _sendCommand('nsfwthighs');
          break;
          
        case 'nsfwass':
          setState(() {
            _outputHistory.add('ass for chu! :3');
          });
          _sendCommand('nsfwass');
          break;
          
        case 'nsfwboobs':
          setState(() {
            _outputHistory.add('boobs for eshal! >w<');
          });
          _sendCommand('nsfwboobs');
          break;
          
        case 'nsfwfeet':
          setState(() {
            _outputHistory.add('feet for chu! :3');
          });
          _sendCommand('nsfwfeet');
          break;
          
        case 'nsfwfuta':
          setState(() {
            _outputHistory.add('futa for eshal! >w<');
          });
          _sendCommand('nsfwfuta');
          break;
          
        case 'nsfwhentai':
          setState(() {
            _outputHistory.add('hentai for chu! :3');
          });
          _sendCommand('nsfwhentai');
          break;
          
        case 'nsfworgy':
          setState(() {
            _outputHistory.add('orgy for eshal! >w<');
          });
          _sendCommand('nsfworgy');
          break;
          
        case 'nsfwpaizuri':
          setState(() {
            _outputHistory.add('paizuri for chu! :3');
          });
          _sendCommand('nsfwpaizuri');
          break;
          
        case 'nsfwyaoi':
          setState(() {
            _outputHistory.add('yaoi for eshal! >w<');
          });
          _sendCommand('nsfwyaoi');
          break;
          
        case 'nsfwyuri':
          setState(() {
            _outputHistory.add('yuri for chu! :3');
          });
          _sendCommand('nsfwyuri');
          break;
          
        default:
          setState(() {
            _outputHistory.add('Command not recognized: $command');
          });
      }
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // Helper methods for file system commands
  Future<void> _listDirectory() async {
    try {
      final apiUrl = '${Config.get('apiBaseUrl')}/files?path=${Uri.encodeComponent(_currentDirectory)}';
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null) {
          setState(() {
            if (data['items'].isEmpty) {
              _outputHistory.add('Directory is empty');
            } else {
              for (var item in data['items']) {
                final type = item['is_directory'] ? 'd' : '-';
                final size = item['size'] ?? 0;
                final modified = item['last_modified'] ?? '';
                _outputHistory.add('$type  ${item['name']} (${size} bytes)');
              }
            }
          });
          return;
        }
      }
      
      setState(() {
        _outputHistory.add('Error: Failed to list directory');
      });
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _changeDirectory(String path) async {
    try {
      String newPath;
      if (path.startsWith('/')) {
        newPath = path;
      } else if (path == '..') {
        if (_currentDirectory == '/') {
          newPath = '/';
        } else {
          final parts = _currentDirectory.split('/')..removeLast();
          newPath = parts.join('/');
          if (newPath.isEmpty) newPath = '/';
        }
      } else {
        newPath = _currentDirectory == '/' 
            ? '/$path' 
            : '$_currentDirectory/$path';
      }
      
      // Use API to change directory
      final apiUrl = '${Config.get('apiBaseUrl')}/files/cd?path=${Uri.encodeComponent(newPath)}';
      final response = await http.post(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _currentDirectory = data['path'];
            _outputHistory.add('Changed to $_currentDirectory');
          });
        } else {
          setState(() {
            _outputHistory.add('Error: ${data['detail']}');
          });
        }
      } else {
        setState(() {
          _outputHistory.add('Error: Failed to change directory');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _displayFile(String filename) async {
    try {
      String filePath = _currentDirectory == '/' 
          ? '/$filename' 
          : '$_currentDirectory/$filename';
      
      final apiUrl = '${Config.get('apiBaseUrl')}/files/content?path=${Uri.encodeComponent(filePath)}';
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add(data['content'] ?? '');
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add('Error: ${data['detail'] ?? 'File not found'}');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _createFile(String filename) async {
    try {
      String filePath = _currentDirectory == '/' 
          ? '/$filename' 
          : '$_currentDirectory/$filename';
      
      final apiUrl = '${Config.get('apiBaseUrl')}/files/create';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': filePath, 'content': ''})
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add(data['message']);
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add('Error: ${data['detail']}');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _createDirectory(String dirname) async {
    try {
      String dirPath = _currentDirectory == '/' 
          ? '/$dirname' 
          : '$_currentDirectory/$dirname';
      
      final apiUrl = '${Config.get('apiBaseUrl')}/files/mkdir';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': dirPath})
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add(data['message']);
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add('Error: ${data['detail']}');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _removeFile(String filename) async {
    try {
      String filePath = _currentDirectory == '/' 
          ? '/$filename' 
          : '$_currentDirectory/$filename';
      
      final apiUrl = '${Config.get('apiBaseUrl')}/files/delete?path=${Uri.encodeComponent(filePath)}';
      final response = await http.delete(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add(data['message']);
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add('Error: ${data['detail']}');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _removeDirectory(String dirname) async {
    try {
      String dirPath = _currentDirectory == '/' 
          ? '/$dirname' 
          : '$_currentDirectory/$dirname';
      
      final apiUrl = '${Config.get('apiBaseUrl')}/files/rmdir?path=${Uri.encodeComponent(dirPath)}';
      final response = await http.delete(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add(data['message']);
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          _outputHistory.add('Error: ${data['detail']}');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  void _changePermissions(String mode, String filename) {
    try {
      setState(() {
        _outputHistory.add('Changed permissions of $filename to $mode');
      });
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _executeSudoCommand(String command) async {
    try {
      // Show password prompt
      setState(() {
        _outputHistory.add('[sudo] password for eshal:');
        _outputHistory.add('Password: ***');
      });
      
      // Verify password with backend
      final apiUrl = '${Config.get('apiBaseUrl')}/sudo';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'password': 'love123'}) // Default password
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _outputHistory.add('Executing: $command');
            _outputHistory.add('Command executed with sudo privileges');
          });
        } else {
          setState(() {
            _outputHistory.add('Sorry, try again.');
          });
        }
      } else {
        setState(() {
          _outputHistory.add('Error verifying password');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  Future<void> _openFile(String filename) async {
    try {
      String filePath = _currentDirectory == '/' 
          ? '/$filename' 
          : '$_currentDirectory/$filename';
      
      // Get file info to check if it's a media file
      final apiUrl = '${Config.get('apiBaseUrl')}/files/info?path=${Uri.encodeComponent(filePath)}';
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = data['item'];
        
        // Check if it's a media file based on extension
        final name = item['name'].toLowerCase();
        final mediaExtensions = [
          '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', // Images
          '.mp4', '.avi', '.mov', '.mkv', '.webm', '.m4v', '.3gp', '.flv' // Videos
        ];
        
        if (mediaExtensions.any((ext) => name.endsWith(ext))) {
          // It's a media file, open in media player
          widget.openMediaWindow(item['content'] ?? '', item['name']);
          setState(() {
            _outputHistory.add('Opening ${item['name']} in media player...');
          });
        } else {
          // It's a text file, display content
          await _displayFile(filename);
        }
      } else {
        setState(() {
          _outputHistory.add('Error: File not found');
        });
      }
    } catch (e) {
      setState(() {
        _outputHistory.add('Error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.terminalDecoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Terminal output
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _outputHistory.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    _outputHistory[index],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.successColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
          // Command input
          Row(
            children: [
              Text(
                'eshal@loveos:~\\\$ ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.successColor,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter command',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
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
