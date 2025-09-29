"""
Comprehensive Waifu API service with fallback support
Supports: waifu.pics, nekos.best, hentaicord.net, waifu.im
"""

import httpx
import asyncio
from typing import Dict, List, Optional, Tuple
from enum import Enum

class APIType(Enum):
    WAIFU_PICS = "waifu_pics"
    NEKOS_BEST = "nekos_best"
    HENTAICORD = "hentaicord"
    WAIFU_IM = "waifu_im"

class WaifuAPIService:
    def __init__(self):
        self.apis = {
            APIType.WAIFU_PICS: {
                "base_url": "https://api.waifu.pics",
                "timeout": 5.0,
                "priority": 1
            },
            APIType.NEKOS_BEST: {
                "base_url": "https://nekos.best/api/v2",
                "timeout": 5.0,
                "priority": 2
            },
            APIType.HENTAICORD: {
                "base_url": "https://api.hentaicord.net",
                "timeout": 5.0,
                "priority": 3
            },
            APIType.WAIFU_IM: {
                "base_url": "https://waifu.im/api",
                "timeout": 5.0,
                "priority": 4
            }
        }
        
        # Category mappings for different APIs
        self.category_mappings = {
            APIType.WAIFU_PICS: {
                "sfw": ["waifu", "neko", "shinobu", "megumin", "bully", "cuddle", "cry", "hug", 
                       "awoo", "kiss", "lick", "pat", "smug", "bonk", "yeet", "blush", "smile", 
                       "wave", "highfive", "handhold", "nom", "bite", "glomp", "slap", "kill", 
                       "kick", "happy", "wink", "poke", "dance", "cringe"],
                "nsfw": ["waifu", "neko", "trap", "blowjob", "ass", "bdsm", "cum", "creampie", 
                        "manga", "futanari", "hentai", "incest", "masturbation", "public", 
                        "ero", "orgy", "elves", "yuri", "pantsu", "glasses", "cuckold", 
                        "blowjob", "boobjob", "handjob", "footjob", "pussy", "ahegao", 
                        "uniform", "gangbang", "tentacles", "gif", "nsfwNeko", "nsfwWaifu"]
            },
            APIType.NEKOS_BEST: {
                "sfw": ["hug", "kiss", "pat", "wink", "slap", "poke", "dance", "blush", 
                       "smile", "wave", "highfive", "handhold", "bite", "neko", "waifu", 
                       "cuddle", "cry", "awoo", "lick", "smug", "bonk", "yeet", "nom", 
                       "glomp", "kill", "kick", "happy", "cringe"]
            },
            APIType.HENTAICORD: {
                "hentai": ["boobs", "ass", "thighs", "feet", "pussy", "blowjob", "handjob", 
                          "footjob", "tits", "milf", "teen", "mature", "big_boobs", "big_ass", 
                          "small_boobs", "small_ass", "redhead", "blonde", "brunette", "black_hair", 
                          "white_hair", "blue_hair", "pink_hair", "green_hair", "purple_hair", 
                          "brown_hair", "long_hair", "short_hair", "twin_tails", "ponytail", 
                          "bob_cut", "afro", "curly_hair", "straight_hair", "wavy_hair", 
                          "braided_hair", "bun", "pigtails", "side_ponytail", "space_buns", 
                          "french_braid", "dutch_braid", "fishtail_braid", "crown_braid", 
                          "waterfall_braid", "milkmaid_braid", "rope_braid", "ladder_braid", 
                          "herringbone_braid", "french_braid", "dutch_braid", "fishtail_braid", 
                          "crown_braid", "waterfall_braid", "milkmaid_braid", "rope_braid", 
                          "ladder_braid", "herringbone_braid"],
                "real_porn": ["boobs", "ass", "thighs", "feet", "pussy", "blowjob", "handjob", 
                             "footjob", "tits", "milf", "teen", "mature", "big_boobs", "big_ass", 
                             "small_boobs", "small_ass", "redhead", "blonde", "brunette", "black_hair", 
                             "white_hair", "blue_hair", "pink_hair", "green_hair", "purple_hair", 
                             "brown_hair", "long_hair", "short_hair", "twin_tails", "ponytail", 
                             "bob_cut", "afro", "curly_hair", "straight_hair", "wavy_hair", 
                             "braided_hair", "bun", "pigtails", "side_ponytail", "space_buns", 
                             "french_braid", "dutch_braid", "fishtail_braid", "crown_braid", 
                             "waterfall_braid", "milkmaid_braid", "rope_braid", "ladder_braid", 
                             "herringbone_braid", "french_braid", "dutch_braid", "fishtail_braid", 
                             "crown_braid", "waterfall_braid", "milkmaid_braid", "rope_braid", 
                             "ladder_braid", "herringbone_braid"],
                "roleplay": ["boobs", "ass", "thighs", "feet", "pussy", "blowjob", "handjob", 
                            "footjob", "tits", "milf", "teen", "mature", "big_boobs", "big_ass", 
                            "small_boobs", "small_ass", "redhead", "blonde", "brunette", "black_hair", 
                            "white_hair", "blue_hair", "pink_hair", "green_hair", "purple_hair", 
                            "brown_hair", "long_hair", "short_hair", "twin_tails", "ponytail", 
                            "bob_cut", "afro", "curly_hair", "straight_hair", "wavy_hair", 
                            "braided_hair", "bun", "pigtails", "side_ponytail", "space_buns", 
                            "french_braid", "dutch_braid", "fishtail_braid", "crown_braid", 
                            "waterfall_braid", "milkmaid_braid", "rope_braid", "ladder_braid", 
                            "herringbone_braid", "french_braid", "dutch_braid", "fishtail_braid", 
                            "crown_braid", "waterfall_braid", "milkmaid_braid", "rope_braid", 
                            "ladder_braid", "herringbone_braid"]
            },
            APIType.WAIFU_IM: {
                "sfw": ["waifu", "neko", "shinobu", "megumin", "bully", "cuddle", "cry", "hug", 
                       "awoo", "kiss", "lick", "pat", "smug", "bonk", "yeet", "blush", "smile", 
                       "wave", "highfive", "handhold", "nom", "bite", "glomp", "slap", "kill", 
                       "kick", "happy", "wink", "poke", "dance", "cringe"],
                "nsfw": ["waifu", "neko", "trap", "blowjob", "ass", "bdsm", "cum", "creampie", 
                        "manga", "futanari", "hentai", "incest", "masturbation", "public", 
                        "ero", "orgy", "elves", "yuri", "pantsu", "glasses", "cuckold", 
                        "blowjob", "boobjob", "handjob", "footjob", "pussy", "ahegao", 
                        "uniform", "gangbang", "tentacles", "gif", "nsfwNeko", "nsfwWaifu"]
            }
        }

    async def get_image(self, category: str, is_nsfw: bool = False, api_token: Optional[str] = None) -> Tuple[bool, str, str]:
        """
        Get image from APIs with fallback support
        Returns: (success, image_url, source_api)
        """
        content_type = "nsfw" if is_nsfw else "sfw"
        
        # Get available APIs sorted by priority
        available_apis = self._get_available_apis(content_type, category)
        
        for api_type in available_apis:
            try:
                success, url, source = await self._try_api(api_type, category, content_type, api_token)
                if success:
                    return True, url, source
            except Exception as e:
                print(f"API {api_type.value} failed: {e}")
                continue
        
        return False, "", "none"

    def _get_available_apis(self, content_type: str, category: str) -> List[APIType]:
        """Get available APIs for the given content type and category, sorted by priority"""
        available = []
        
        for api_type, config in self.apis.items():
            if content_type in self.category_mappings.get(api_type, {}):
                if category in self.category_mappings[api_type][content_type]:
                    available.append(api_type)
        
        # Sort by priority (lower number = higher priority)
        return sorted(available, key=lambda x: self.apis[x]["priority"])

    async def _try_api(self, api_type: APIType, category: str, content_type: str, api_token: Optional[str] = None) -> Tuple[bool, str, str]:
        """Try to get image from specific API"""
        config = self.apis[api_type]
        
        async with httpx.AsyncClient(verify=False, timeout=config["timeout"]) as client:
            if api_type == APIType.WAIFU_PICS:
                return await self._try_waifu_pics(client, category, content_type)
            elif api_type == APIType.NEKOS_BEST:
                return await self._try_nekos_best(client, category, content_type)
            elif api_type == APIType.HENTAICORD:
                return await self._try_hentaicord(client, category, content_type, api_token)
            elif api_type == APIType.WAIFU_IM:
                return await self._try_waifu_im(client, category, content_type)
        
        return False, "", api_type.value

    async def _try_waifu_pics(self, client: httpx.AsyncClient, category: str, content_type: str) -> Tuple[bool, str, str]:
        """Try waifu.pics API"""
        url = f"https://api.waifu.pics/{content_type}/{category}"
        response = await client.get(url)
        
        if response.status_code == 200:
            data = response.json()
            return True, data.get("url", ""), "waifu.pics"
        
        return False, "", "waifu.pics"

    async def _try_nekos_best(self, client: httpx.AsyncClient, category: str, content_type: str) -> Tuple[bool, str, str]:
        """Try nekos.best API (SFW only)"""
        if content_type == "nsfw":
            return False, "", "nekos.best"
        
        url = f"https://nekos.best/api/v2/{category}"
        response = await client.get(url)
        
        if response.status_code == 200:
            data = response.json()
            if "results" in data and len(data["results"]) > 0:
                return True, data["results"][0]["url"], "nekos.best"
        
        return False, "", "nekos.best"

    async def _try_hentaicord(self, client: httpx.AsyncClient, category: str, content_type: str, api_token: Optional[str] = None) -> Tuple[bool, str, str]:
        """Try hentaicord.net API"""
        if not api_token:
            return False, "", "hentaicord"
        
        # Map content type to hentaicord type
        hentaicord_type = "hentai" if content_type == "nsfw" else "hentai"  # hentaicord is primarily NSFW
        
        url = f"https://api.hentaicord.net/retrieve/{hentaicord_type}/{category}"
        headers = {"Authorization": api_token}
        response = await client.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            return True, data.get("image", ""), "hentaicord"
        
        return False, "", "hentaicord"

    async def _try_waifu_im(self, client: httpx.AsyncClient, category: str, content_type: str) -> Tuple[bool, str, str]:
        """Try waifu.im API"""
        url = f"https://waifu.im/api/{content_type}/{category}"
        response = await client.get(url)
        
        if response.status_code == 200:
            data = response.json()
            if "images" in data and len(data["images"]) > 0:
                return True, data["images"][0]["url"], "waifu.im"
        
        return False, "", "waifu.im"

    async def get_categories(self, content_type: str) -> Dict[str, List[str]]:
        """Get available categories for each API"""
        categories = {}
        
        for api_type, config in self.apis.items():
            if content_type in self.category_mappings.get(api_type, {}):
                categories[api_type.value] = self.category_mappings[api_type][content_type]
        
        return categories

    async def get_hentaicord_categories(self, api_token: Optional[str] = None) -> Dict[str, List[str]]:
        """Get categories from hentaicord API"""
        if not api_token:
            return {}
        
        try:
            async with httpx.AsyncClient(verify=False, timeout=5.0) as client:
                url = "https://api.hentaicord.net/types-categories"
                headers = {"Authorization": api_token}
                response = await client.get(url, headers=headers)
                
                if response.status_code == 200:
                    data = response.json()
                    return data.get("categories", {})
        except Exception as e:
            print(f"Error fetching hentaicord categories: {e}")
        
        return {}

# Global instance
waifu_api_service = WaifuAPIService()
