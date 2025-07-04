import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoMessageView extends StatefulWidget {
  const VideoMessageView({
    super.key,
    required this.url,
    this.highlightVideo = false,
    this.highlightScale = 1.2,
  });

  final String url;

  final bool highlightVideo;
  final double highlightScale;

  @override
  State<VideoMessageView> createState() => _VideoMessageViewState();
}

class _VideoMessageViewState extends State<VideoMessageView> {
  Uint8List? _thumbnailBytes;

  String get videoUrl => widget.url;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.PNG,
        quality: 75,
      );
      if (uint8list != null) {
        setState(() {
          _thumbnailBytes = uint8list;
        });
      }
    } catch (e) {
      // silently fail, fallback to placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 300,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenVideoPlayer(
                  videoUrl: videoUrl,
                  heroTag: widget.url,
                  fromMemory: false,
                ),
              ),
            ),
            child: SizedBox(
              child: _thumbnailBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _thumbnailBytes!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black26,
                        ),
                        Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white.withOpacity(0.8),
                            size: 64,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.black12,
                      child: Center(
                        child: Icon(
                          Icons.videocam,
                          size: 48,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool fromMemory;
  final String heroTag;

  const FullScreenVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.heroTag,
    this.fromMemory = false,
  }) : super(key: key);

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.fromMemory) {
      // decode base64 video string to bytes and create temp file
      final base64String =
          widget.videoUrl.substring(widget.videoUrl.indexOf('base64') + 7);
      final bytes = base64Decode(base64String);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/${widget.heroTag}_video.mp4');
      file.writeAsBytesSync(bytes);
      _controller = VideoPlayerController.file(file);
    } else if (widget.videoUrl.startsWith('http')) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    }

    _controller?.initialize().then((_) {
      setState(() {});
      _controller?.play();
      _controller?.setLooping(true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 1, 31),
      body: Center(
        child: Hero(
          tag: widget.heroTag,
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
          });
        },
        child: Icon(
          _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
