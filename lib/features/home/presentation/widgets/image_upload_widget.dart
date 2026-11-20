import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/seasons/season_palette.dart';

class ImageUploadWidget extends StatelessWidget {
  const ImageUploadWidget({
    super.key,
    required this.onImageSelected,
    required this.onImageRemoved,
    this.uploadedImage,
  });

  final Function(Uint8List) onImageSelected;
  final VoidCallback onImageRemoved;
  final Uint8List? uploadedImage;

  Future<bool> _ensurePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }
    // The gallery opens the system photo picker (Android Photo Picker, iOS
    // PHPicker), which needs no library permission.
    return true;
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    try {
      final granted = await _ensurePermission(source);
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission required to access camera/gallery.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        onImageSelected(bytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: SeasonPalette.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern handle bar
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SeasonPalette.mutedText.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 24),

                // Header with icon and title
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: SeasonPalette.accent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: SeasonPalette.accent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Image Source',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: SeasonPalette.text,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose how you want to add your image',
                            style: TextStyle(
                              fontSize: 14,
                              color: SeasonPalette.text.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action buttons with improved design
                Row(
                  children: [
                    Expanded(
                      child: _ImageSourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        subtitle: 'Take a photo',
                        color: SeasonPalette.accent,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera, context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ImageSourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        subtitle: 'Choose existing',
                        color: SeasonPalette.card,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery, context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: SeasonPalette.text.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uploadedImage != null) {
      return _buildImagePreview(context);
    }

    return _buildUploadArea(context);
  }

  Widget _buildUploadArea(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showImageSourceDialog(context),
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: SeasonPalette.accent.withOpacity(0.55),
            radius: 24,
          ),
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: SeasonPalette.accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: SeasonPalette.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: SeasonPalette.accent,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add a photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Camera or gallery · JPG, PNG',
                  style: TextStyle(
                    fontSize: 12,
                    color: SeasonPalette.text.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SeasonPalette.text.withOpacity(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(uploadedImage!, fit: BoxFit.cover),
            // Bottom scrim for legibility of the controls.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF4ADE80),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Photo ready',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  _PreviewAction(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Change',
                    onTap: () => _showImageSourceDialog(context),
                  ),
                  const SizedBox(width: 8),
                  _PreviewAction(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    onTap: onImageRemoved,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = SeasonPalette.onColor(color ?? SeasonPalette.card);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color ?? SeasonPalette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (color ?? SeasonPalette.card).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container with enhanced design
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: fg.withOpacity(0.2), width: 1),
                ),
                child: Icon(icon, color: fg, size: 28),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              // Subtitle if provided
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: fg.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
