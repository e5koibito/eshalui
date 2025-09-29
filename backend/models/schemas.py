"""
Pydantic models for LoveOS API
"""
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class File(BaseModel):
    name: str
    content: Optional[str] = None
    is_folder: bool = False
    parent_id: Optional[str] = None

class FileDB(File):
    id: str

class FileUpdate(BaseModel):
    name: Optional[str] = None
    content: Optional[str] = None
    parent_id: Optional[str] = None
    type: Optional[str] = None
    metadata: Optional[dict] = None

class CommandRequest(BaseModel):
    type: str

class SudoRequest(BaseModel):
    password: str

class FileListResponse(BaseModel):
    path: str
    items: List[Dict[str, str]]

class FileContentResponse(BaseModel):
    path: str
    content: str

class CommandResponse(BaseModel):
    success: bool
    url: Optional[str] = None
    message: str

class SudoResponse(BaseModel):
    success: bool
    message: str

