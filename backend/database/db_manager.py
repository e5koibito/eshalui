"""
In-memory database handler for LoveOS
"""
from typing import Dict, List, Optional, Any

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

class InMemoryDatabase:
    def __init__(self):
        self.collections = {}
    
    def __getitem__(self, name):
        if name not in self.collections:
            self.collections[name] = InMemoryCollection()
        return self.collections[name]
    
    def create_collection(self, name):
        self.collections[name] = InMemoryCollection()

class DatabaseManager:
    def __init__(self):
        self.db = InMemoryDatabase()
        print("Successfully connected to in-memory database")
    
    def get_collection(self, name: str):
        """Get a collection by name"""
        return self.db[name]
    
    def create_file(self, file_data: Dict) -> Dict:
        """Create a new file"""
        result = self.db["files"].insert_one(file_data)
        file_id = result.inserted_id
        new_file = self.db["files"].find_one({"_id": file_id})
        
        if new_file:
            new_file["id"] = str(new_file["_id"])
            return new_file
        else:
            raise Exception("Created file not found")
    
    def read_files(self, parent_id: Optional[str] = None) -> List[Dict]:
        """Read files with optional parent filter"""
        query = {"parent_id": parent_id}
        files = []
        
        cursor = self.db["files"].find(query)
        for doc in cursor:
            doc["id"] = str(doc["_id"])
            files.append(doc)
        
        return files
    
    def read_file(self, file_id: str) -> Dict:
        """Read a specific file by ID"""
        file = self.db["files"].find_one({"_id": file_id})
        
        if file:
            file["id"] = str(file["_id"])
            return file
        else:
            raise Exception("File not found")
    
    def update_file(self, file_id: str, file_data: Dict) -> Dict:
        """Update a file"""
        result = self.db["files"].update_one(
            {"_id": file_id}, {"$set": file_data}
        )
        updated_file = self.db["files"].find_one({"_id": file_id})
        
        if updated_file:
            updated_file["id"] = str(updated_file["_id"])
            return updated_file
        else:
            raise Exception("File not found")

# Global instance
db_manager = DatabaseManager()

