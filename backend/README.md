# LoveOS API

This is the backend for the LoveOS Flutter application.

## Setup

1.  Install the dependencies:
    ```bash
    pip install -r requirements.txt
    ```

2.  Make sure you have a MongoDB instance running. You can configure the connection string in `config.py`.

## Running the API

```bash
python app.py
```

You can also run the server with auto-reloading for development:
```bash
uvicorn app:app --reload
```

The API will be available at `http://127.0.0.1:8000`.
