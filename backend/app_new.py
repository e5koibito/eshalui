"""
LoveOS Backend - Minimal main application
"""
import uvicorn
import json
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes.api_routes import router

# Load configuration
def load_config():
    config_path = os.path.join(os.path.dirname(__file__), "config.json")
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            return json.load(f)
    return {}

# Default configuration
config = load_config()
PORT = config.get("port", 8000)
HOST = config.get("host", "127.0.0.1")
DEBUG = config.get("debug", True)

# Create FastAPI app
app = FastAPI(title="LoveOS Backend", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(router)

if __name__ == "__main__":
    print(f"Starting LoveOS server on {HOST}:{PORT}")
    uvicorn.run(app, host=HOST, port=PORT, reload=DEBUG)

