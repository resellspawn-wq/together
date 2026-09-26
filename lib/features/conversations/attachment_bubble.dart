import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../theme/theme.dart';
import 'media_viewer_screen.dart';

/// The photo/video shown inside a chat bubble that carries an
/// attachment — a thumbnail for a photo, a dark placeholder with a play
/// icon for a video (a real video thumbnail would mean initializing a
/// player just to grab one frame, for every bubble in the list — not
/// worth it). Tapping either opens the full-screen viewer.
class AttachmentBubble extends StatelessWidget {
  final String url;
  final AttachmentType type;

  const AttachmentBubble({super.key, required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MediaViewerScreen(url: url, type: type)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: SizedBox(
          width: 200,
          height: 200,
          child: type == AttachmentType.image
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.fuchsia));
                  },
                  errorBuilder: (context, error, stack) => const ColoredBox(
                    color: AppColors.chromeLight,
                    child: Icon(AppIcons.image, color: AppColors.inkSoft),
                  ),
                )
              : const ColoredBox(
                  color: Colors.black87,
                  child: Icon(AppIcons.playCircle, color: AppColors.white, size: 48),
                ),
        ),
      ),
    );
  }
}
