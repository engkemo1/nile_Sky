import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';

/// Picks images, uploads them to the API (which stores the bytes in Postgres)
/// and shows what is attached so far.
///
/// [urls] holds stored paths such as `/upload/<id>`; [onChanged] fires with the
/// updated list. Rendering goes through [AdminApiService.mediaUrl] so a stored
/// path becomes a full URL.
class MediaManager extends StatefulWidget {
  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final String folder;
  final int maxFiles;

  const MediaManager({
    super.key,
    required this.urls,
    required this.onChanged,
    this.folder = 'flights',
    this.maxFiles = 8,
  });

  @override
  State<MediaManager> createState() => _MediaManagerState();
}

class _MediaManagerState extends State<MediaManager> {
  bool _uploading = false;
  String? _error;

  static const _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'mp4': 'video/mp4',
    'webm': 'video/webm',
  };

  Future<void> _pick() async {
    setState(() => _error = null);

    // file_picker 13 differs from 8.x in four ways: pickFiles is a STATIC
    // method (there is no .platform instance any more), it returns a
    // List<PlatformFile> directly rather than a nullable FilePickerResult,
    // allowMultiple/withData are gone, and the bytes come from readAsBytes()
    // rather than a bytes field.
    List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _mimeByExt.keys.toList(),
      );
    } catch (e) {
      setState(() => _error = 'Could not open the file picker: $e');
      return;
    }
    if (picked.isEmpty) return;

    setState(() => _uploading = true);
    final added = <String>[];
    String? failure;

    for (final file in picked) {
      if (widget.urls.length + added.length >= widget.maxFiles) {
        failure = 'Only ${widget.maxFiles} files allowed; the rest were skipped.';
        break;
      }
      final ext = file.extension?.toLowerCase() ?? '';
      final mime = _mimeByExt[ext];
      if (mime == null) {
        failure = '${file.name}: unsupported type.';
        continue;
      }
      try {
        final bytes = await file.readAsBytes();
        final res = await AdminApiService.uploadImage(
          filename: file.name,
          mimetype: mime,
          bytes: bytes,
          folder: widget.folder,
        );
        final url = res['url']?.toString();
        if (url != null) added.add(url);
      } catch (e) {
        failure = '${file.name}: ${e.toString().replaceFirst('ApiException: ', '')}';
      }
    }

    if (!mounted) return;
    setState(() {
      _uploading = false;
      _error = failure;
    });
    if (added.isNotEmpty) {
      widget.onChanged([...widget.urls, ...added]);
    }
  }

  void _remove(int index) {
    final next = [...widget.urls]..removeAt(index);
    widget.onChanged(next);
  }

  bool _isVideo(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.mp4') || u.endsWith('.webm') || u.contains('video');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos',
              style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '${widget.urls.length}/${widget.maxFiles}',
              style: const TextStyle(color: AdminColors.textMuted, fontSize: 11),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _uploading ? null : _pick,
              icon: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AdminColors.primary,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: Text(_uploading ? 'Uploading…' : 'Add'),
              style: TextButton.styleFrom(foregroundColor: AdminColors.primary),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: AdminColors.error, fontSize: 11),
            ),
          ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AdminColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AdminColors.border),
          ),
          child: widget.urls.isEmpty
              ? const Center(
                  child: Text(
                    'No photos yet — max 3 MB each\njpg, png, webp, gif, mp4, webm',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AdminColors.textMuted, fontSize: 11),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(widget.urls.length, (i) {
                    final url = AdminApiService.mediaUrl(widget.urls[i]);
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 84,
                            height: 84,
                            color: AdminColors.cardDark,
                            child: _isVideo(widget.urls[i])
                                ? const Icon(Icons.videocam,
                                    color: AdminColors.textMuted, size: 28)
                                : Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: AdminColors.textMuted,
                                      size: 24,
                                    ),
                                    loadingBuilder: (_, child, progress) =>
                                        progress == null
                                            ? child
                                            : const Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AdminColors.primary,
                                                  ),
                                                ),
                                              ),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            iconSize: 16,
                            icon: const Icon(Icons.cancel,
                                color: AdminColors.error),
                            tooltip: 'Remove',
                            onPressed: () => _remove(i),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
