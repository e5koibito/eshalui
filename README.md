# LoveOS 

A simple, lovey-dovey themed WebOS built with Flutter and FastAPI, created with love for Eshal.

## Features

*   **Themed Desktop Environment:** A beautiful, animated desktop background with a dock for applications.
*   **Draggable Windows:** All applications open in draggable windows that can be moved around the desktop.
*   **Terminal:** A command-line interface with a variety of fun commands.
    *   Fetches SFW and NSFW images and GIFs from the `waifu.pics` API.
    *   Includes commands like `kiss`, `hug`, `cuddle`, and many more.
    *   Explicit NSFW commands like `nsfwwaifu` for clarity.
    *   `help` command to list all available actions.
    *   Selectable text for easy copying.
*   **File Explorer:** A basic file system where you can create files and folders.
    *   Create, read, and update files through the API.
    *   Organize content in a hierarchical structure.
*   **Web Browser:** A simple web browser to search Google and navigate to websites.
*   **CORS Handling:** Backend proxy system to handle Cross-Origin Resource Sharing issues for API calls and image loading.

## Development Progress

### Completed
* Backend API for file operations (create, read, update)
* In-memory database implementation for reliable file storage
* CORS proxy for external API requests and image loading
* Basic UI with draggable windows
* Terminal with various commands
* File explorer interface

### Known Issues & Pending Improvements
* **Window Resizing:** Windows cannot be properly resized yet
* **Browser Functionality:** Web browser is not fully functional
  * `setBackgroundColor` implementation error in WebViewController
  * Font loading issues with Roboto font from Google Fonts
* **Loading Animation:** Need to implement proper loading animations
* **File System Sync:** File system can post files to API but has issues fetching them
* **UI Responsiveness:** Needs improvement for different screen sizes
* **API Integration Issues:**
  * Terminal commands return 404 errors when sent to backend
  * Commands like `kiss`, `hug`, and `cuddle` fetch from fixed sources instead of API
* **Flutter Run Commands:**
  * `d` - Detach (terminate "flutter run" but leave application running)
  * `c` - Clear the screen
  * `q` - Quit (terminate the application on the device)

## Tech Stack

*   **Frontend:** Flutter
*   **Backend:** FastAPI (Python)
*   **Database:** MongoDB
*   **HTTP Client (Backend):** HTTPlus
*   **Real-time API (for another AI):** Websockets

## Configuration

The application uses configuration files to manage settings:

### Frontend Configuration
A `config.json` file in the root directory controls frontend settings:
```json
{
  "apiBaseUrl": "http://127.0.0.1:8000",
  "showNsfw": true,
  "appName": "LoveOS",
  "version": "1.0.0"
}
```

### Backend Configuration
A `config.json` file in the backend directory controls server settings:
```json
{
  "port": 8000,
  "host": "0.0.0.0",
  "debug": true,
  "waifuPicsApiUrl": "https://api.waifu.pics",
  "nekosApiUrl": "https://nekos.best/api/v2",
  "allowNsfw": true
}
```

## Project Structure

```
eshalui/
├── backend/            # The Python FastAPI backend
│   ├── app.py          # Main backend application file
│   ├── config.py       # Backend configuration
│   └── requirements.txt
├── lib/                # The Flutter frontend application
│   ├── main.dart       # Main frontend application file
│   ├── config.dart     # Frontend configuration
│   └── providers/
│       └── files_provider.dart
├── android/
├── ios/
├── web/
└── ... (other Flutter project files)
```

## Prerequisites

*   **Flutter:** Make sure you have the Flutter SDK installed.
*   **Python:** Python 3.7+ is required for the backend.
*   **MongoDB:** A running MongoDB instance is required for the file system feature.

## Setup and Installation

### 1. Backend Setup

The backend server acts as a proxy to handle API requests and avoid CORS issues in the browser.

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```
2.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
3.  **Run the server:**
    ```bash
    python app.py
    ```
    The backend will be running at `http://127.0.0.1:8000`.

### 2. Frontend Setup

1.  **Navigate to the project root directory:**
    ```bash
    cd .. 
    ```
2.  **Get Flutter dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the application:**
    You can run the app on any platform, but it has been primarily tested on Chrome.
    ```bash
    flutter run -d chrome
    ```

## Configuration

You can easily configure parts of the application without digging into the code.

### Backend Configuration

File: `backend/config.py`

*   `MONGO_DETAILS`: Change the connection string for your MongoDB instance if it's not running on the default `localhost:27017`.

### Frontend Configuration

File: `lib/config.dart`

*   `apiBaseUrl`: If you change the port of the backend server, you must update it here.
*   `showNsfw`: Set this to `false` to disable all NSFW commands in the terminal.