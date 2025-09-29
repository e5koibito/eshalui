"""
API routes for LoveOS
"""
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse, RedirectResponse
from typing import List, Optional
import json
import os

from models.schemas import (
    File, FileDB, FileUpdate, CommandRequest, SudoRequest,
    FileListResponse, FileContentResponse, CommandResponse, SudoResponse
)
from database.db_manager import db_manager
from api.waifu_api import waifu_api

# Create router
router = APIRouter()

# Commands endpoint
@router.post("/commands", response_model=CommandResponse)
async def execute_command(command: CommandRequest):
    """Handle terminal commands from the Flutter app"""
    try:
        command_type = command.type.lower()
        
        # SFW Commands
        if command_type in ["kiss", "hug", "cuddle", "pat", "handhold", "waifu", "neko", "shinobu", "megumin", "bully", "cry", "awoo", "lick", "smug", "bonk", "yeet", "blush", "smile", "wave", "highfive", "nom", "bite", "glomp", "slap", "kill", "kick", "happy", "wink", "poke", "dance", "cringe"]:
            return await waifu_api.get_sfw_image(command_type)
        
        # NSFW Commands
        elif command_type in ["nsfwwaifu", "nsfwneko", "nsfwspank", "nsfwbite", "nsfwblowjob", "nsfwtrap", "nsfwthighs", "nsfwass", "nsfwboobs", "nsfwfeet", "nsfwfuta", "nsfwhentai", "nsfworgy", "nsfwpaizuri", "nsfwyaoi", "nsfwyuri"]:
            # Check if NSFW is allowed
            try:
                config_path = os.path.join(os.path.dirname(__file__), "..", "config.json")
                if os.path.exists(config_path):
                    with open(config_path, "r") as f:
                        config = json.load(f)
                        if not config.get("allowNsfw", True):
                            return CommandResponse(success=False, message="NSFW commands are disabled")
            except:
                pass
            
            return await waifu_api.get_nsfw_image(command_type)
        
        else:
            return CommandResponse(success=False, message=f"Unknown command: {command_type}")
            
    except Exception as e:
        print(f"Error in execute_command: {str(e)}")
        return CommandResponse(success=False, message=f"Error executing command: {str(e)}")

# Filesystem endpoints
@router.post("/files/", response_model=FileDB)
async def create_file(file: File):
    try:
        file_dict = file.dict()
        new_file = db_manager.create_file(file_dict)
        return new_file
    except Exception as e:
        print(f"Error in create_file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database operation failed: {str(e)}")

@router.get("/files/", response_model=List[FileDB])
async def read_files(parent_id: Optional[str] = None):
    try:
        files = db_manager.read_files(parent_id)
        return files
    except Exception as e:
        print(f"Error in read_files: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database operation failed: {str(e)}")

@router.get("/files/{file_id}", response_model=FileDB)
async def read_file(file_id: str):
    try:
        file = db_manager.read_file(file_id)
        return file
    except Exception as e:
        print(f"Error in read_file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database operation failed: {str(e)}")

@router.put("/files/{file_id}", response_model=FileDB)
async def update_file(file_id: str, file: FileUpdate):
    try:
        file_dict = file.dict(exclude_unset=True)
        updated_file = db_manager.update_file(file_id, file_dict)
        return updated_file
    except Exception as e:
        print(f"Error in update_file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database operation failed: {str(e)}")

# File system endpoints for terminal commands
@router.get("/files", response_model=FileListResponse)
async def list_files(path: str = "/"):
    """List files and directories at the given path"""
    try:
        # For now, return mock data - in a real implementation, you'd use os.listdir()
        mock_files = {
            "/": [
                {"name": "documents", "type": "directory"},
                {"name": "pictures", "type": "directory"},
                {"name": "music", "type": "directory"},
                {"name": "projects", "type": "directory"},
                {"name": "readme.txt", "type": "file"}
            ],
            "/documents": [
                {"name": "todo.txt", "type": "file"},
                {"name": "ideas.txt", "type": "file"}
            ],
            "/pictures": [
                {"name": "vacation.txt", "type": "file"}
            ],
            "/projects": [
                {"name": "flutter_app", "type": "directory"}
            ],
            "/projects/flutter_app": [
                {"name": "README.md", "type": "file"},
                {"name": "main.dart", "type": "file"}
            ]
        }
        
        items = mock_files.get(path, [])
        return FileListResponse(path=path, items=items)
        
    except Exception as e:
        print(f"Error in list_files: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to list files: {str(e)}")

@router.get("/files/content", response_model=FileContentResponse)
async def get_file_content(path: str):
    """Get the content of a file"""
    try:
        # Mock file contents - in a real implementation, you'd read the actual file
        mock_contents = {
            "/readme.txt": "Welcome to LoveOS terminal!",
            "/documents/todo.txt": "1. Learn Flutter\n2. Build awesome apps\n3. Share with the world",
            "/documents/ideas.txt": "App ideas:\n- Dating app with AI\n- Virtual pet simulator\n- Productivity tracker",
            "/pictures/vacation.txt": "Beautiful beach sunset picture description",
            "/projects/flutter_app/README.md": "# Flutter App\n\nThis is a sample Flutter application.",
            "/projects/flutter_app/main.dart": 'void main() {\n  print("Hello, Flutter!");\n}'
        }
        
        content = mock_contents.get(path, "File not found")
        return FileContentResponse(path=path, content=content)
        
    except Exception as e:
        print(f"Error in get_file_content: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to read file: {str(e)}")

# Password management for sudo
@router.post("/sudo", response_model=SudoResponse)
async def sudo_command(request: SudoRequest):
    """Verify sudo password"""
    try:
        # Load password from config
        config_password = None
        try:
            config_path = os.path.join(os.path.dirname(__file__), "..", "config.json")
            if os.path.exists(config_path):
                with open(config_path, "r") as f:
                    config = json.load(f)
                    config_password = config.get("sudoPassword", "love123")
        except:
            config_password = "love123"  # Default password
        
        if request.password == config_password:
            return SudoResponse(success=True, message="Password verified")
        else:
            return SudoResponse(success=False, message="Incorrect password")
            
    except Exception as e:
        print(f"Error in sudo_command: {str(e)}")
        return SudoResponse(success=False, message=f"Error verifying password: {str(e)}")

# Additional endpoints
@router.get("/")
def read_root():
    return {"Hello": "World"}

@router.get("/search")
async def search(q: str):
    """Simple search endpoint"""
    return RedirectResponse(url=f"https://www.google.com/search?q={q}")

@router.get("/background")
async def background():
    """Background SVG endpoint"""
    svg_content = """<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
    <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#ff9a9e;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#fad0c4;stop-opacity:1" />
        </linearGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#grad)" />
    <text x="50%" y="50%" font-family="Arial" font-size="48" fill="#ffffff" text-anchor="middle" dominant-baseline="middle">LoveOS</text>
    <text x="50%" y="58%" font-family="Arial" font-size="24" fill="#ffffff" text-anchor="middle" dominant-baseline="middle">Your personal love companion</text>
</svg>"""
    return StreamingResponse(iter([svg_content.encode()]), media_type="image/svg+xml")

@router.get("/image-proxy")
async def image_proxy(url: str):
    """Proxy images to avoid CORS issues"""
    try:
        import httpx
        async with httpx.AsyncClient(verify=False) as client:
            response = await client.get(url, timeout=10.0)
            return StreamingResponse(iter([response.content]), media_type=response.headers.get("content-type", "image/gif"))
    except Exception as e:
        print(f"Error in image_proxy: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to proxy image: {str(e)}")

