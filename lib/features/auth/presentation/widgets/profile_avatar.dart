// lib/features/profile/presentation/widgets/profile_avatar.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/domain/models/user_model.dart';
import 'package:future_riverpod/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileAvatar extends ConsumerStatefulWidget {
  const ProfileAvatar({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  bool _uploading = false;

  // ── Pick → Crop → Upload ──────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;

    // ← Give iOS time to fully dismiss the sheet/picker before presenting
    // the cropper. Without this, image_cropper returns null silently on iOS.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final cs = Theme.of(context).colorScheme;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: cs.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: cs.primary,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: true,
          rotateClockwiseButtonHidden: true,
          hidesNavigationBar: true,
        ),
      ],
    );

    if (cropped == null || !mounted) return;

    setState(() => _uploading = true);
    await ref.read(profileProvider.notifier).uploadAvatar(File(cropped.path));
    if (mounted) setState(() => _uploading = false);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    setState(() => _uploading = true);
    await ref.read(profileProvider.notifier).deleteAvatar();
    if (mounted) setState(() => _uploading = false);
  }

  // ── Sheet routing ─────────────────────────────────────────────────────────

  void _showSourceSheet(BuildContext context) {
    if (Platform.isIOS) {
      _showCupertinoSheet(context);
    } else {
      _showMaterialSheet(context);
    }
  }

  // ── iOS Cupertino sheet ───────────────────────────────────────────────────

  void _showCupertinoSheet(BuildContext context) {
    final hasPhoto = widget.user.avatarUrl != null;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Profile Photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _pick(ImageSource.camera);
            },
            child: const Text('Take a Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _pick(ImageSource.gallery);
            },
            child: const Text('Choose from Gallery'),
          ),
          // Only show delete if the user already has a photo
          if (hasPhoto)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _delete();
              },
              child: const Text('Remove Photo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // ── Android Material sheet ────────────────────────────────────────────────

  void _showMaterialSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasPhoto = widget.user.avatarUrl != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Profile Photo',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              onTap: () {
                Navigator.of(context).pop();
                _pick(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.of(context).pop();
                _pick(ImageSource.gallery);
              },
            ),
            // Only show delete if the user already has a photo
            if (hasPhoto) ...[
              const SizedBox(height: 12),
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                onTap: () {
                  Navigator.of(context).pop();
                  _delete();
                },
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const photoRadius = 55.0;

    return GestureDetector(
      onTap: () => _showSourceSheet(context),
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // ── Primary ring → gap → photo ─────────────────────────────────
          Container(
            width: photoRadius * 2 + 10,
            height: photoRadius * 2 + 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary, width: 2.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 3,
                ),
                color: cs.primary.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: _uploading
                    ? _UploadingOverlay(cs: cs)
                    : widget.user.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.user.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            _InitialsView(user: widget.user, cs: cs),
                        errorWidget: (_, __, ___) =>
                            _InitialsView(user: widget.user, cs: cs),
                      )
                    : _InitialsView(user: widget.user, cs: cs),
              ),
            ),
          ),

          // ── Edit badge ─────────────────────────────────────────────────
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InitialsView extends StatelessWidget {
  const _InitialsView({required this.user, required this.cs});
  final UserModel user;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
    color: cs.primary.withValues(alpha: 0.1),
    child: Center(
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: cs.primary,
        ),
      ),
    ),
  );
}

class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
    color: cs.onSurface.withValues(alpha: 0.12),
    child: Center(
      child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
    ),
  );
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = isDestructive ? Colors.redAccent : cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.redAccent.withValues(alpha: 0.07)
              : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: isDestructive
              ? Border.all(color: Colors.redAccent.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
