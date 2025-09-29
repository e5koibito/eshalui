import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../theme/app_theme.dart';

class MediaPlayer extends StatefulWidget {
  final String url;
  final String? title;
  
  const MediaPlayer({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends State<MediaPlayer> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isLoading = true;
  String? _error;
  bool _isValidUrl = true;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    try {
      // First, validate the URL
      await _validateUrl();
      
      if (!_isValidUrl) {
        setState(() {
          _error = "Invalid or inaccessible URL";
          _isLoading = false;
        });
        return;
      }

      // Check if the URL is a video based on file extension
      final url = widget.url.toLowerCase();
      final videoExtensions = ['.mp4', '.avi', '.mov', '.mkv', '.webm', '.m4v', '.3gp', '.flv'];
      
      _isVideo = videoExtensions.any((ext) => url.contains(ext));
      
      if (_isVideo) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _validateUrl() async {
    try {
      final response = await http.head(Uri.parse(widget.url));
      if (response.statusCode >= 400) {
        _isValidUrl = false;
      }
    } catch (e) {
      _isValidUrl = false;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pink),
            SizedBox(height: 16),
            Text(
              'Loading media...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading media:',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _initializeMedia();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.textPrimary,
        title: Text(widget.title ?? 'Media Player'),
        actions: [
          if (_isVideo) ...[
            IconButton(
              icon: Icon(
                _videoController?.value.isPlaying == true
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  if (_videoController?.value.isPlaying == true) {
                    _videoController?.pause();
                  } else {
                    _videoController?.play();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () {
                // Toggle fullscreen
                if (_videoController?.value.isPlaying == true) {
                  _videoController?.pause();
                } else {
                  _videoController?.play();
                }
              },
            ),
          ],
        ],
      ),
      body: Container(
        decoration: AppTheme.mediaPlayerDecoration,
        child: _isVideo ? _buildVideoPlayer() : _buildImagePlayer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null) {
      return const Center(
        child: Text(
          'Video player not initialized',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildImagePlayer() {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(
        widget.url,
        errorListener: (exception, stackTrace) {
          print('Image loading error: $exception');
        },
      ),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2.0,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: widget.url),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: Colors.pink),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${widget.url}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MediaWindow extends StatelessWidget {
  final String url;
  final String? title;
  
  const MediaWindow({super.key, required this.url, this.title});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 500,
      decoration: AppTheme.mediaPlayerDecoration,
      child: MediaPlayer(
        url: url,
        title: title,
      ),
    );
  }
}

class MediaViewerDialog extends StatelessWidget {
  final String url;
  final String? title;

  const MediaViewerDialog({
    super.key,
    required this.url,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MediaPlayer(
          url: url,
          title: title,
        ),
      ),
    );
  }
}
