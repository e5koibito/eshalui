# Gemini Handover Document: LoveOS Project

This document provides a detailed technical overview of the LoveOS project, its architecture, and the key challenges encountered during its development. It is intended for another AI agent taking over the project.

## 1. Project Overview

LoveOS is a Flutter-based desktop-like web application with a "lovey-dovey" theme. It features a terminal, a file explorer, and a web browser, all running in draggable windows. The application is backed by a FastAPI server that provides data persistence for the file system and, crucially, acts as a proxy to circumvent browser CORS (Cross-Origin Resource Sharing) policies.

## 2. Architecture

The project is divided into two main parts: a Flutter frontend and a FastAPI backend.

### 2.1. Frontend Architecture (Flutter)

-   **Core File:** `lib/main.dart` contains the entire UI logic.
-   **State Management:** A simple approach is used via the `provider` package. `ChangeNotifierProvider` is used at the root of the application to provide a `FilesProvider` instance for managing the file system state.
-   **UI Paradigm:** The UI is built around a `Stack` widget in `LoveOSDesktop`. Applications are not separate pages but are widgets (`TerminalWindow`, `FilesWindow`, `Browser`) wrapped in a `DraggableWindow` widget, which are added to a list in the `_LoveOSDesktopState`. This gives the illusion of a multi-window desktop environment.
-   **Configuration:** Frontend settings are centralized in `lib/config.dart`. This includes the backend URL and a feature flag (`showNsfw`) to control the visibility of NSFW commands.

### 2.2. Backend Architecture (FastAPI)

-   **Core File:** `backend/app.py` contains the entire backend logic.
-   **Database:** MongoDB is used for storing the file system structure. The connection is managed by the `motor` asynchronous driver.
-   **API Endpoints:**
    -   `/files`: POST and GET methods to create and retrieve file/folder records from MongoDB.
    -   `/search`: A simple redirect to Google search, used by the browser.
    -   `/waifu-proxy/{type}/{category}`: Proxies API requests to `api.waifu.pics`. This is essential to bypass browser CORS restrictions that would block a direct call from the frontend.
    -   `/background`: Fetches the desktop background image and streams it to the client. This was changed from a redirect to a streaming response to solve a CORS issue.
    -   `/image-proxy`: A generic image proxy. It takes a URL as a query parameter, fetches the image on the server-side, and streams the image data back. This is the final and most critical piece of the CORS solution.

## 3. Key Technical Challenge: CORS

The most significant challenge in this project was Cross-Origin Resource Sharing (CORS). The Flutter web client, running on a specific origin (e.g., `http://localhost:12345`), is blocked by the browser from making requests to different origins (e.g., `api.waifu.pics` or `i.pinimg.com`).

**The solution involved a two-part proxy system:**

1.  **API Proxy (`/waifu-proxy`):** The frontend calls this endpoint on its own backend. The backend then makes the server-to-server request to `api.waifu.pics` and returns the JSON response. This works because server-to-server requests are not subject to browser CORS policies.

2.  **Image Proxy (`/image-proxy`):** The JSON from the API proxy contains a URL to an image on a third-party domain (e.g., `i.waifu.pics`). If the frontend tried to load this URL directly, it would again be blocked by CORS. To solve this, the frontend constructs a new URL pointing to the `/image-proxy` endpoint, passing the third-party image URL as a parameter. The backend then fetches the image and streams it to the frontend. The browser sees this as a simple request to the same origin, so it is not blocked.

This is the implementation of the image proxy in `backend/app.py`:

```python
@app.get("/image-proxy")
async def image_proxy(url: str):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url)
            response.raise_for_status()
            return StreamingResponse(response.iter_bytes(), media_type=response.headers.get("content-type"))
        except httpx.RequestError as e:
            raise HTTPException(status_code=400, detail=f"Failed to fetch image: {e}")
```

And this is how the frontend uses it in `lib/main.dart`:

```dart
// ... after getting the imageUrl from the API proxy
final proxiedUrl = '${Config.apiBaseUrl}/image-proxy?url=${Uri.encodeComponent(imageUrl)}';
widget.openMediaWindow(proxiedUrl);
```

## 4. Key Technical Challenge: Webview Initialization

The `webview_flutter` plugin failed to initialize on the web platform, throwing an `AssertionFailed` error: `A platform implementation for 'webview_flutter' has not been set.`

The standard fix, `WidgetsFlutterBinding.ensureInitialized()`, was not sufficient.

The definitive solution was to **manually register the web platform implementation** at the beginning of the `main()` function. This required adding the `webview_flutter_web` package and the following code:

```dart
// lib/main.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter_web/webview_flutter_web.dart';

void main() {
  if (kIsWeb) {
    WebView.platform = WebViewFlutterWebPlugin();
  }
  
  WidgetsFlutterBinding.ensureInitialized();
  runApp(...);
}
```

## 5. Handover Summary

The project is now in a stable state. The core features are implemented, and the major technical hurdles (CORS and Webview initialization) have been overcome. The next AI agent can proceed with adding new features.

**Immediate next steps could include:**

*   Implementing the saving and loading of file content in the `FilesWindow`.
*   Adding history, bookmarks, and back/forward buttons to the `Browser`.
*   Refactoring the `DraggableWindow` logic to be more robust.
*   Enhancing the UI with animations and transitions for a more polished experience.
*   Adding more applications to the dock, such as a notes app or a media player.
*   Implementing user authentication and personalization features.

## 6. Current Development Status

### 6.1 Recent Progress

The project has made significant progress in several areas:

- **Backend Stability:** Fixed critical issues with the backend server:
  - Resolved port conflicts by configuring proper host and port settings
  - Implemented reliable in-memory database for file operations
  - Fixed AsyncIOMotorCursor iteration issues in MongoDB operations
  - Streamlined file operation endpoints (create, read, update)

- **API Functionality:** All core API endpoints are now working:
  - `/files/` endpoint for listing files
  - `/files/{id}` endpoint for retrieving specific files
  - File creation and update operations

- **CORS Handling:** Successfully implemented image and API proxying to handle cross-origin requests.

### 6.2 Known Issues & Pending Improvements

Several challenges remain to be addressed:

1. **UI/UX Issues:**
   - Window resizing functionality is not properly implemented
   - Loading animations are missing or inadequate
   - UI responsiveness needs improvement for different screen sizes

2. **Browser Functionality:**
   - Web browser component is not fully functional
   - Navigation controls (back/forward) need implementation

3. **File System Integration:**
   - Frontend can post files to API but has issues fetching and displaying them
   - Need to implement proper synchronization between UI and backend

4. **Performance Optimization:**
   - Application performance could be improved, especially for image loading
   - Consider implementing caching mechanisms

The application is currently running with the core desktop environment, terminal, file explorer, and web browser functionalities. The CORS issues have been successfully addressed through the backend proxy system, allowing seamless API interactions and image loading.

The project is actively being developed with a focus on enhancing the user experience and adding more features to make it a comprehensive desktop-like environment.

This concludes the handover. The codebase is stable, extensible, and ready for further development.
