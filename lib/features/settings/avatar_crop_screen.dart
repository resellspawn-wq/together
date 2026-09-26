import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/theme.dart';
import '../../widgets/app_text.dart';

/// Lets the user pinch/pan a picked image into position before it becomes
/// their profile photo, instead of uploading whatever they picked as-is.
/// Pops with the cropped square PNG bytes, or null if cancelled.
class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const AvatarCropScreen({super.key, required this.imageBytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  bool _saving = false;

  static const double _viewportSize = 320;
  static const double _exportPixelRatio = 2;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _exportPixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.of(context).pop(byteData?.buffer.asUint8List());
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: AppText('Non è stato possibile ritagliare la foto.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: AppText('Sistema la foto', style: AppTypography.titleCompact()),
          actions: [
            TextButton(
              onPressed: _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fuchsia),
                    )
                  : const AppText('FATTO'),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              AppText(
                'Trascina e pizzica per posizionare la foto',
                style: AppTypography.bodySmall(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: _viewportSize,
                    height: _viewportSize,
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          key: _boundaryKey,
                          child: ClipRect(
                            child: InteractiveViewer(
                              transformationController: _transformController,
                              minScale: 0.5,
                              maxScale: 4,
                              boundaryMargin: const EdgeInsets.all(double.infinity),
                              child: Image.memory(widget.imageBytes, fit: BoxFit.cover, width: _viewportSize, height: _viewportSize),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 3),
                              boxShadow: AppShadows.soft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
