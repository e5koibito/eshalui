from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse, RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
import motor.motor_asyncio
import httpx
import uvicorn
from pydantic import BaseModel
from typing import List, Optional

# Load configuration from config.json
import json
import os

# Import our new API service
from api.waifu_api import waifu_api_service
from database.file_system import file_system_manager

print(f"File system manager imported: {file_system_manager}")
print(f"File system manager base path: {file_system_manager.base_path}")

# Default configuration
MONGO_DETAILS = "mongodb://localhost:27017"
MONGO_DB_NAME = "loveos"
WAIFU_PICS_BASE_API = "https://api.waifu.pics"
NEKOS_API_URL = "https://nekos.best/api/v2"
PORT = 8000
HOST = "127.0.0.1"
DEBUG = True
ALLOW_NSFW = True
SFW_CATEGORIES = []
NSFW_CATEGORIES = []

# Try to load from config.json
try:
    config_path = os.path.join(os.path.dirname(__file__), "config.json")
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            config = json.load(f)
            PORT = config.get("port", PORT)
            HOST = config.get("host", HOST)
            DEBUG = config.get("debug", DEBUG)
            WAIFU_PICS_BASE_API = config.get("waifuPicsApiUrl", WAIFU_PICS_BASE_API)
            NEKOS_API_URL = config.get("nekosApiUrl", NEKOS_API_URL)
            ALLOW_NSFW = config.get("allowNsfw", ALLOW_NSFW)
            MONGO_DETAILS = config.get("mongoDbUrl", MONGO_DETAILS)
            MONGO_DB_NAME = config.get("mongoDbName", MONGO_DB_NAME)
except Exception as e:
    print(f"Error loading config.json: {e}")

# Try to load categories from config.py if it exists
try:
    from config import SFW_CATEGORIES, NSFW_CATEGORIES
except ImportError:
    print("Could not import categories from config.py, using defaults")

app = FastAPI()

# CORS middleware to allow requests from the Flutter app
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB Connection - Using in-memory database for reliability
print("Using in-memory dictionary database for reliability")

# Simple in-memory database implementation
class InMemoryCollection:
    def __init__(self):
        self.data = {}
        self.counter = 0
    
    def insert_one(self, document):
        self.counter += 1
        document_id = str(self.counter)
        document["_id"] = document_id
        self.data[document_id] = document
        
        class Result:
            def __init__(self, inserted_id):
                self.inserted_id = inserted_id
        
        return Result(document_id)
    
    def find_one(self, query):
        if "_id" in query:
            doc_id = query["_id"]
            return self.data.get(doc_id)
        return None
    
    def find(self, query=None):
        if query is None:
            query = {}
        
        result = []
        for doc in self.data.values():
            match = True
            for k, v in query.items():
                if k not in doc or doc[k] != v:
                    match = False
                    break
            if match:
                result.append(doc.copy())
        return result
    
    def update_one(self, query, update):
        if "_id" in query:
            doc_id = query["_id"]
            if doc_id in self.data:
                for k, v in update.get("$set", {}).items():
                    self.data[doc_id][k] = v
                
                class Result:
                    def __init__(self):
                        self.modified_count = 1
                
                return Result()
        
        class Result:
            def __init__(self):
                self.modified_count = 0
        
        return Result()

# Create in-memory database
class InMemoryDatabase:
    def __init__(self):
        self.collections = {}
    
    def __getitem__(self, name):
        if name not in self.collections:
            self.collections[name] = InMemoryCollection()
        return self.collections[name]
    
    def create_collection(self, name):
        self.collections[name] = InMemoryCollection()

db = InMemoryDatabase()
print("Successfully connected to in-memory database")


class File(BaseModel):
    name: str
    content: Optional[str] = None
    is_folder: bool = False
    parent_id: Optional[str] = None


class FileDB(File):
    id: str


@app.get("/")
def read_root():
    return {"Hello": "World"}


# Filesystem endpoints
@app.post("/files/", response_model=FileDB)
async def create_file(file: File):
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Database connection is not available."
        )
    
    try:
        file_dict = file.dict()
        
        # Using in-memory database
        result = db["files"].insert_one(file_dict)
        file_id = result.inserted_id
        new_file = db["files"].find_one({"_id": file_id})
        
        if new_file:
            new_file["id"] = str(new_file["_id"])
            return new_file
        else:
            raise HTTPException(status_code=404, detail="Created file not found")
    except Exception as e:
        print(f"Error in create_file: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Database operation failed: {str(e)}"
        )


@app.get("/files/", response_model=List[FileDB])
async def read_files(parent_id: Optional[str] = None):
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Database connection is not available."
        )
    
    try:
        query = {"parent_id": parent_id}
        files = []
        
        # Using in-memory database
        cursor = db["files"].find(query)
        for doc in cursor:
            doc["id"] = str(doc["_id"])
            files.append(doc)
                
        return files
    except Exception as e:
        print(f"Error in read_files: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Database operation failed: {str(e)}"
        )


@app.get("/files/{file_id}", response_model=FileDB)
async def read_file(file_id: str):
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Database connection is not available."
        )
    try:
        # Using in-memory database
        file = db["files"].find_one({"_id": file_id})
        
        if file:
            file["id"] = str(file["_id"])
            return file
        else:
            raise HTTPException(status_code=404, detail="File not found")
    except Exception as e:
        print(f"Error in read_file: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Database operation failed: {str(e)}"
        )


class FileUpdate(BaseModel):
    name: Optional[str] = None
    content: Optional[str] = None
    parent_id: Optional[str] = None
    type: Optional[str] = None
    metadata: Optional[dict] = None

@app.put("/files/{file_id}", response_model=FileDB)
async def update_file(file_id: str, file: FileUpdate):
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Database connection is not available."
        )
    
    try:
        file_dict = file.dict(exclude_unset=True)
        
        # Using in-memory database
        result = db["files"].update_one(
            {"_id": file_id}, {"$set": file_dict}
        )
        updated_file = db["files"].find_one({"_id": file_id})
        
        if updated_file:
            updated_file["id"] = str(updated_file["_id"])
            return updated_file
        else:
            raise HTTPException(status_code=404, detail="File not found")
    except Exception as e:
        print(f"Error in update_file: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Database operation failed: {str(e)}"
        )


# A simple endpoint for the web browser to search
@app.get("/search")
async def search(q: str):
    # In a real scenario, you might use a search engine API
    # For now, we'll just redirect to Google
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url=f"https://www.google.com/search?q={q}")

@app.get("/background")
async def background():
    # Always return a properly formatted SVG with a gradient background
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


@app.get("/waifu-proxy/{type}/{category}")
async def waifu_proxy(type: str, category: str):
    if type not in ["sfw", "nsfw"]:
        return {"error": "Invalid type. Must be 'sfw' or 'nsfw'."}, 403
    
    if type == "sfw" and category not in SFW_CATEGORIES:
        return {"error": f"Invalid SFW category. Must be one of {SFW_CATEGORIES}"}, 403
    
    if type == "nsfw" and category not in NSFW_CATEGORIES:
        return {"error": f"Invalid NSFW category. Must be one of {NSFW_CATEGORIES}"}, 403
    
    # Try waifu.pics first
    waifu_url = f"https://api.waifu.pics/{type}/{category}"
    print(f"Attempting to fetch from waifu.pics: {waifu_url}")
    
    try:
        async with httpx.AsyncClient(verify=False) as client:
            response = await client.get(waifu_url, timeout=5.0)
            
            # If successful, return the data
            if response.status_code == 200:
                print("Successfully fetched from waifu.pics")
                return response.json()
            
            print(f"Failed to fetch from waifu.pics: {response.status_code}")
            
            # If we get here, waifu.pics failed, so try nekos.best as fallback
            # But nekos.best only supports SFW content
            if type == "nsfw":
                return {"error": "NSFW content not available from fallback API"}, 403
            
            # Map common categories to nekos.best endpoints
            nekos_best_endpoints = {
                "hug": "hug",
                "kiss": "kiss",
                "pat": "pat",
                "wink": "wink",
                "slap": "slap",
                "poke": "poke",
                "dance": "dance",
                "blush": "blush",
                "smile": "smile",
                "wave": "wave",
                "highfive": "highfive",
                "handhold": "handhold",
                "bite": "bite",
                "neko": "neko",
                "waifu": "waifu"
            }
            
            # Default to 'hug' if category not found
            endpoint = nekos_best_endpoints.get(category, "hug")
            
            nekos_url = f"https://nekos.best/api/v2/{endpoint}"
            print(f"Attempting to fetch from nekos.best fallback: {nekos_url}")
            
            response = await client.get(nekos_url, timeout=5.0)
            
            if response.status_code == 200:
                data = response.json()
                # Transform the response to match the expected format from waifu.pics
                if "results" in data and len(data["results"]) > 0:
                    print("Successfully fetched from nekos.best fallback")
                    return {"url": data["results"][0]["url"]}
            
            return {"error": "Both primary and fallback APIs failed"}
            
    except Exception as e:
        print(f"Error in waifu_proxy: {str(e)}")
        return {"error": f"API request failed: {str(e)}"}

@app.get("/image-proxy")
async def image_proxy(url: str):
    try:
        async with httpx.AsyncClient(verify=False) as client:
            response = await client.get(url, timeout=10.0)
            return StreamingResponse(iter([response.content]), media_type=response.headers.get("content-type", "image/gif"))
    except Exception as e:
        print(f"Error in image_proxy: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to proxy image: {str(e)}")

@app.get("/api/categories")
async def get_categories(content_type: str = "sfw"):
    """Get available categories for all APIs"""
    try:
        categories = await waifu_api_service.get_categories(content_type)
        return {"success": True, "categories": categories}
    except Exception as e:
        print(f"Error getting categories: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get categories: {str(e)}")

@app.get("/api/hentaicord-categories")
async def get_hentaicord_categories():
    """Get categories from hentaicord API"""
    try:
        api_token = None
        try:
            config_path = os.path.join(os.path.dirname(__file__), "config.json")
            if os.path.exists(config_path):
                with open(config_path, "r") as f:
                    config = json.load(f)
                    api_token = config.get("hentaicordApiToken")
        except:
            pass
        
        categories = await waifu_api_service.get_hentaicord_categories(api_token)
        return {"success": True, "categories": categories}
    except Exception as e:
        print(f"Error getting hentaicord categories: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get hentaicord categories: {str(e)}")

@app.get("/api/status")
async def get_api_status():
    """Get status of all APIs"""
    try:
        status = {}
        
        # Test each API
        for api_type in waifu_api_service.apis.keys():
            try:
                success, _, source = await waifu_api_service._try_api(
                    api_type, "waifu", "sfw", None
                )
                status[api_type.value] = {
                    "available": success,
                    "priority": waifu_api_service.apis[api_type]["priority"]
                }
            except:
                status[api_type.value] = {
                    "available": False,
                    "priority": waifu_api_service.apis[api_type]["priority"]
                }
        
        return {"success": True, "apis": status}
    except Exception as e:
        print(f"Error getting API status: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get API status: {str(e)}")


# Commands endpoint for terminal interactions
class CommandRequest(BaseModel):
    type: str

@app.post("/commands")
async def execute_command(command: CommandRequest):
    """Handle terminal commands from the Flutter app using the new API service"""
    try:
        command_type = command.type.lower()
        
        # Determine if it's NSFW and get the category
        is_nsfw = command_type.startswith("nsfw")
        category = command_type.replace("nsfw", "") if is_nsfw else command_type
        
        # Check if NSFW is allowed
        if is_nsfw and not ALLOW_NSFW:
            return {"success": False, "message": "NSFW commands are disabled"}
        
        # Get API token for hentaicord if available
        api_token = None
        try:
            config_path = os.path.join(os.path.dirname(__file__), "config.json")
            if os.path.exists(config_path):
                with open(config_path, "r") as f:
                    config = json.load(f)
                    api_token = config.get("hentaicordApiToken")
        except:
            pass
        
        # Use the new API service with fallback
        success, image_url, source_api = await waifu_api_service.get_image(
            category=category,
            is_nsfw=is_nsfw,
            api_token=api_token
        )
        
        if success:
            return {
                "success": True, 
                "url": image_url, 
                "message": f"Sent {command_type} from {source_api}!",
                "source": source_api
            }
        else:
            # Final fallback to cute GIF (valid Cataas endpoint)
            safe_tag = category.strip().lower() or "cute"
            fallback_url = f"https://cataas.com/cat/gif/{safe_tag}"
            return {
                "success": True, 
                "url": fallback_url, 
                "message": f"Sent {command_type} (fallback)!",
                "source": "fallback"
            }
            
    except Exception as e:
        print(f"Error in execute_command: {str(e)}")
        return {"success": False, "message": f"Error executing command: {str(e)}"}


# File system endpoints for terminal commands
@app.get("/files")
async def list_files(path: str = "/"):
    """List files and directories at the given path"""
    try:
        items = file_system_manager.list_directory(path)
        return {
            "path": path,
            "items": [item.to_dict() for item in items]
        }
        
    except Exception as e:
        print(f"Error in list_files: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to list files: {str(e)}")

@app.get("/files/content")
async def get_file_content(path: str):
    """Get the content of a file"""
    print(f"Getting file content for path: {path}")
    print(f"File system manager type: {type(file_system_manager)}")
    print(f"File system manager base path: {file_system_manager.base_path}")
    
    try:
        success, content = file_system_manager.get_file_content(path)
        print(f"File system manager returned: success={success}, content_length={len(content) if content else 0}")
        
        if success:
            return {"path": path, "content": content}
        else:
            print(f"File not found, raising 404 with detail: {content}")
            raise HTTPException(status_code=404, detail=content)
    except Exception as e:
        print(f"Exception in get_file_content: {type(e).__name__}: {e}")
        raise

class FileCreateRequest(BaseModel):
    path: str
    content: str = ""

@app.post("/files/create")
async def create_file(request: FileCreateRequest):
    """Create a new file"""
    try:
        success, message = file_system_manager.create_file(request.path, request.content)
        
        if success:
            return {"success": True, "message": message}
        else:
            raise HTTPException(status_code=400, detail=message)
        
    except Exception as e:
        print(f"Error in create_file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create file: {str(e)}")

class FileSaveRequest(BaseModel):
    path: str
    content: str

@app.post("/files/save")
async def save_file(request: FileSaveRequest):
    """Save edits to a file"""
    try:
        success, message = file_system_manager.save_file(request.path, request.content)
        if success:
            return {"success": True, "message": message}
        else:
            raise HTTPException(status_code=400, detail=message)
    except Exception as e:
        print(f"Error in save_file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to save file: {str(e)}")

class DirectoryCreateRequest(BaseModel):
    path: str

@app.post("/files/mkdir")
async def create_directory(request: DirectoryCreateRequest):
    """Create a new directory"""
    try:
        success, message = file_system_manager.create_directory(request.path)
        
        if success:
            return {"success": True, "message": message}
        else:
            raise HTTPException(status_code=400, detail=message)
        
    except Exception as e:
        print(f"Error in create_directory: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create directory: {str(e)}")

@app.delete("/files/delete")
async def delete_file(path: str):
    """Delete a file or directory"""
    try:
        success, message = file_system_manager.delete_file(path)
        
        if success:
            return {"success": True, "message": message}
        else:
            raise HTTPException(status_code=400, detail=message)
        
    except Exception as e:
        print(f"Error in delete_file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete file: {str(e)}")

@app.delete("/files/rmdir")
async def delete_directory(path: str):
    """Delete a directory"""
    try:
        success, message = file_system_manager.delete_directory(path)
        
        if success:
            return {"success": True, "message": message}
        else:
            raise HTTPException(status_code=400, detail=message)
        
    except Exception as e:
        print(f"Error in delete_directory: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete directory: {str(e)}")

@app.get("/files/info")
async def get_file_info(path: str):
    """Get detailed information about a file or directory"""
    try:
        item = file_system_manager.get_file_info(path)
        
        if item:
            return {"success": True, "item": item.to_dict()}
        else:
            raise HTTPException(status_code=404, detail="File or directory not found")
        
    except Exception as e:
        print(f"Error in get_file_info: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get file info: {str(e)}")

@app.get("/files/pwd")
async def get_current_directory():
    """Get current directory path"""
    try:
        current_path = file_system_manager.get_current_path()
        return {"path": current_path}
        
    except Exception as e:
        print(f"Error in get_current_directory: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get current directory: {str(e)}")

@app.post("/files/cd")
async def change_directory(path: str):
    """Change current directory"""
    try:
        success, message = file_system_manager.change_directory(path)
        
        if success:
            return {"success": True, "path": message}
        else:
            raise HTTPException(status_code=400, detail=message)
        
    except Exception as e:
        print(f"Error in change_directory: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to change directory: {str(e)}")


# Password management for sudo
class SudoRequest(BaseModel):
    password: str

@app.post("/sudo")
async def sudo_command(request: SudoRequest):
    """Verify sudo password"""
    try:
        # Load password from config
        config_password = None
        try:
            config_path = os.path.join(os.path.dirname(__file__), "config.json")
            if os.path.exists(config_path):
                with open(config_path, "r") as f:
                    config = json.load(f)
                    config_password = config.get("sudoPassword", "love123")
        except:
            config_password = "love123"  # Default password
        
        if request.password == config_password:
            return {"success": True, "message": "Password verified"}
        else:
            return {"success": False, "message": "Incorrect password"}
            
    except Exception as e:
        print(f"Error in sudo_command: {str(e)}")
        return {"success": False, "message": f"Error verifying password: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    print(f"Starting server on {HOST}:{PORT}")
    uvicorn.run(app, host=HOST, port=PORT)


if __name__ == "__main__":
    uvicorn.run("app:app", host=HOST, port=PORT, reload=DEBUG)