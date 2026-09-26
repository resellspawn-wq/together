import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/message.dart';
import '../../theme/theme.dart';

/// Full-screen photo/video viewer, opened by tapping an attachment
/// bubble in a chat.
class MediaViewerScreen extends StatefulWidget {
  final String url;
  final AttachmentType type;

  const MediaViewerScreen({super.key, required this.url, required this.type});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.type == AttachmentType.video) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = controller;
      controller
          .initialize()
          .then((_) {
            if (!mounted) return;
            setState(() => _ready = true);
            controller.play();
          })
          .catchError((Object _) {
            if (mounted) setState(() => _error = 'Non è stato possibile caricare il video.');
          });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          icon: const Icon(AppIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: widget.type == AttachmentType.image
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(widget.url, fit: BoxFit.contain),
              )
            : _buildVideo(),
      ),
    );
  }

  Widget _buildVideo() {
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: AppColors.white));
    }
    final controller = _controller;
    if (controller == null || !_ready) {
      return const CircularProgressIndicator(color: AppColors.white);
    }
    return GestureDetector(
      onTap: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              const Icon(AppIcons.playCircle, color: AppColors.white, size: 64),
          ],
        ),
      ),
    );
  }
}
