"""
File System Management Service
Handles file operations, directory navigation, and file system state
"""

import os
import json
import shutil
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from pathlib import Path

class FileSystemItem:
    def __init__(self, name: str, path: str, is_directory: bool = False, 
                 content: str = "", size: int = 0, last_modified: Optional[datetime] = None):
        self.name = name
        self.path = path
        self.is_directory = is_directory
        self.content = content
        self.size = size
        self.last_modified = last_modified or datetime.now()
    
    def to_dict(self):
        return {
            "name": self.name,
            "path": self.path,
            "type": "directory" if self.is_directory else "file",
            "is_directory": self.is_directory,
            "content": self.content,
            "size": self.size,
            "last_modified": self.last_modified.isoformat()
        }

class FileSystemManager:
    def __init__(self, base_path: str = "/tmp/loveos_filesystem"):
        self.base_path = Path(base_path)
        self.current_path = Path("/")
        self._ensure_base_directory()
        self._initialize_default_structure()
    
    def _ensure_base_directory(self):
        """Ensure the base directory exists"""
        self.base_path.mkdir(parents=True, exist_ok=True)
    
    def _initialize_default_structure(self):
        """Initialize default file system structure"""
        default_structure = {
            "documents": {
                "type": "directory",
                "contents": {
                    "todo.txt": {
                        "type": "file",
                        "content": "1. Learn Flutter\n2. Build awesome apps\n3. Share with the world\n4. Make Eshal happy <3"
                    },
                    "ideas.txt": {
                        "type": "file",
                        "content": "App ideas:\n- Dating app with AI\n- Virtual pet simulator\n- Productivity tracker\n- LoveOS improvements"
                    },
                    "love_notes.txt": {
                        "type": "file",
                        "content": "Dear Eshal,\n\nI love you so much! ❤️\n\nYou make my world brighter every day.\n\nYours forever,\nLovely"
                    }
                }
            },
            "pictures": {
                "type": "directory",
                "contents": {
                    "vacation.txt": {
                        "type": "file",
                        "content": "Beautiful beach sunset picture description"
                    },
                    "memories": {
                        "type": "directory",
                        "contents": {
                            "our_first_date.txt": {
                                "type": "file",
                                "content": "The day we first met - magical and unforgettable"
                            }
                        }
                    }
                }
            },
            "music": {
                "type": "directory",
                "contents": {
                    "our_song.txt": {
                        "type": "file",
                        "content": "Our special song that reminds us of each other"
                    }
                }
            },
            "projects": {
                "type": "directory",
                "contents": {
                    "flutter_app": {
                        "type": "directory",
                        "contents": {
                            "README.md": {
                                "type": "file",
                                "content": "# Flutter App\n\nThis is a sample Flutter application for LoveOS."
                            },
                            "main.dart": {
                                "type": "file",
                                "content": 'void main() {\n  print("Hello, Flutter!");\n  print("Made with love for Eshal ❤️");\n}'
                            }
                        }
                    },
                    "loveos": {
                        "type": "directory",
                        "contents": {
                            "README.md": {
                                "type": "file",
                                "content": "# LoveOS\n\nA beautiful operating system made with love for Eshal."
                            }
                        }
                    }
                }
            },
            "system": {
                "type": "directory",
                "contents": {
                    "config.txt": {
                        "type": "file",
                        "content": "LoveOS Configuration\nUser: Eshal\nTheme: Pink\nLanguage: English"
                    },
                    "logs": {
                        "type": "directory",
                        "contents": {
                            "system.log": {
                                "type": "file",
                                "content": "System startup successful\nAll services running\nLove level: Maximum ❤️"
                            }
                        }
                    }
                }
            },
            "readme.txt": {
                "type": "file",
                "content": "Welcome to LoveOS file system!\n\nThis is your personal space filled with love and memories.\n\nUse 'ls' to list files, 'cd' to navigate, and 'cat' to read files."
            }
        }
        
        self._create_structure_from_dict("/", default_structure)
    
    def _create_structure_from_dict(self, current_path: str, structure: Dict):
        """Create file system structure from dictionary"""
        for name, item in structure.items():
            item_path = f"{current_path}/{name}" if current_path != "/" else f"/{name}"
            
            if item["type"] == "directory":
                self._create_directory(item_path)
                if "contents" in item:
                    self._create_structure_from_dict(item_path, item["contents"])
            else:
                self._create_file(item_path, item.get("content", ""))
    
    def _get_real_path(self, virtual_path: str) -> Path:
        """Convert virtual path to real file system path"""
        if virtual_path == "/":
            return self.base_path
        
        # Remove leading slash and convert to real path
        relative_path = virtual_path.lstrip("/")
        return self.base_path / relative_path
    
    def _create_directory(self, virtual_path: str) -> bool:
        """Create a directory"""
        try:
            real_path = self._get_real_path(virtual_path)
            real_path.mkdir(parents=True, exist_ok=True)
            return True
        except Exception as e:
            print(f"Error creating directory {virtual_path}: {e}")
            return False
    
    def _create_file(self, virtual_path: str, content: str = "") -> bool:
        """Create a file with content"""
        try:
            real_path = self._get_real_path(virtual_path)
            real_path.parent.mkdir(parents=True, exist_ok=True)
            real_path.write_text(content, encoding='utf-8')
            return True
        except Exception as e:
            print(f"Error creating file {virtual_path}: {e}")
            return False
    
    def list_directory(self, virtual_path: str = None) -> List[FileSystemItem]:
        """List contents of a directory"""
        if virtual_path is None:
            virtual_path = str(self.current_path)
        
        try:
            real_path = self._get_real_path(virtual_path)
            
            if not real_path.exists():
                return []
            
            items = []
            
            if real_path.is_dir():
                for item_path in real_path.iterdir():
                    virtual_item_path = f"{virtual_path}/{item_path.name}" if virtual_path != "/" else f"/{item_path.name}"
                    
                    item = FileSystemItem(
                        name=item_path.name,
                        path=virtual_item_path,
                        is_directory=item_path.is_dir(),
                        size=item_path.stat().st_size if item_path.is_file() else 0,
                        last_modified=datetime.fromtimestamp(item_path.stat().st_mtime)
                    )
                    
                    if item_path.is_file():
                        try:
                            item.content = item_path.read_text(encoding='utf-8')
                        except:
                            item.content = "[Binary file]"
                    
                    items.append(item)
            
            return sorted(items, key=lambda x: (not x.is_directory, x.name.lower()))
        
        except Exception as e:
            print(f"Error listing directory {virtual_path}: {e}")
            return []
    
    def change_directory(self, virtual_path: str) -> Tuple[bool, str]:
        """Change current directory"""
        try:
            if virtual_path.startswith("/"):
                new_path = Path(virtual_path)
            else:
                new_path = self.current_path / virtual_path
            
            # Normalize path
            new_path = new_path.resolve()
            
            # Check if path exists and is directory
            real_path = self._get_real_path(str(new_path))
            if real_path.exists() and real_path.is_dir():
                self.current_path = new_path
                return True, str(new_path)
            else:
                return False, f"Directory not found: {virtual_path}"
        
        except Exception as e:
            return False, f"Error changing directory: {e}"
    
    def get_file_content(self, virtual_path: str) -> Tuple[bool, str]:
        """Get content of a file"""
        try:
            real_path = self._get_real_path(virtual_path)
            
            if not real_path.exists():
                return False, "File not found"
            
            if real_path.is_dir():
                return False, "Is a directory"
            
            content = real_path.read_text(encoding='utf-8')
            return True, content
        
        except Exception as e:
            return False, f"Error reading file: {e}"

    def save_file(self, virtual_path: str, content: str) -> Tuple[bool, str]:
        """Save content to a file, creating it if necessary"""
        try:
            real_path = self._get_real_path(virtual_path)
            real_path.parent.mkdir(parents=True, exist_ok=True)
            real_path.write_text(content, encoding='utf-8')
            return True, f"Saved file: {virtual_path}"
        except Exception as e:
            return False, f"Error saving file: {e}"
    
    def create_file(self, virtual_path: str, content: str = "") -> Tuple[bool, str]:
        """Create a new file"""
        try:
            if self._create_file(virtual_path, content):
                return True, f"Created file: {virtual_path}"
            else:
                return False, "Failed to create file"
        
        except Exception as e:
            return False, f"Error creating file: {e}"
    
    def create_directory(self, virtual_path: str) -> Tuple[bool, str]:
        """Create a new directory"""
        try:
            if self._create_directory(virtual_path):
                return True, f"Created directory: {virtual_path}"
            else:
                return False, "Failed to create directory"
        
        except Exception as e:
            return False, f"Error creating directory: {e}"
    
    def delete_file(self, virtual_path: str) -> Tuple[bool, str]:
        """Delete a file"""
        try:
            real_path = self._get_real_path(virtual_path)
            
            if not real_path.exists():
                return False, "File not found"
            
            if real_path.is_dir():
                return False, "Is a directory, use rmdir instead"
            
            real_path.unlink()
            return True, f"Deleted file: {virtual_path}"
        
        except Exception as e:
            return False, f"Error deleting file: {e}"
    
    def delete_directory(self, virtual_path: str) -> Tuple[bool, str]:
        """Delete a directory"""
        try:
            real_path = self._get_real_path(virtual_path)
            
            if not real_path.exists():
                return False, "Directory not found"
            
            if not real_path.is_dir():
                return False, "Is a file, use rm instead"
            
            # Check if directory is empty
            if any(real_path.iterdir()):
                return False, "Directory not empty"
            
            real_path.rmdir()
            return True, f"Deleted directory: {virtual_path}"
        
        except Exception as e:
            return False, f"Error deleting directory: {e}"
    
    def get_current_path(self) -> str:
        """Get current directory path"""
        return str(self.current_path)
    
    def get_file_info(self, virtual_path: str) -> Optional[FileSystemItem]:
        """Get detailed information about a file or directory"""
        try:
            real_path = self._get_real_path(virtual_path)
            
            if not real_path.exists():
                return None
            
            item = FileSystemItem(
                name=real_path.name,
                path=virtual_path,
                is_directory=real_path.is_dir(),
                size=real_path.stat().st_size if real_path.is_file() else 0,
                last_modified=datetime.fromtimestamp(real_path.stat().st_mtime)
            )
            
            if real_path.is_file():
                try:
                    item.content = real_path.read_text(encoding='utf-8')
                except:
                    item.content = "[Binary file]"
            
            return item
        
        except Exception as e:
            print(f"Error getting file info: {e}")
            return None

# Global file system manager instance
file_system_manager = FileSystemManager()
