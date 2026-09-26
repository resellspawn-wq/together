import 'package:flutter/material.dart';

import '../../core/backend_scope.dart';
import '../../core/models/message.dart';
import '../../theme/theme.dart';
import '../../widgets/app_text.dart';
import 'media_viewer_screen.dart';

/// All photos/videos exchanged in a conversation, opened by tapping the
/// other member's name/avatar in the chat's app bar — a grid with an
/// option to select and delete some or all of them.
class MediaGalleryScreen extends StatefulWidget {
  final String conversationId;
  final String otherDisplayName;

  const MediaGalleryScreen({super.key, required this.conversationId, required this.otherDisplayName});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  late Future<List<Message>> _future;
  List<Message> _items = [];
  bool _selecting = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Message>> _load() async {
    final items = await BackendScope.readOf(context).messages.fetchAttachments(widget.conversationId);
    if (mounted) setState(() => _items = items);
    return items;
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    await _delete(_selected.toList());
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Eliminare tutti i file?'),
        content: AppText('Tutte le foto e i video con ${widget.otherDisplayName} verranno eliminati per entrambi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const AppText('ANNULLA')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const AppText('ELIMINA TUTTI')),
        ],
      ),
    );
    if (ok != true) return;
    await _delete(_items.map((m) => m.id).toList());
  }

  Future<void> _delete(List<String> ids) async {
    try {
      await BackendScope.readOf(context).messages.deleteMessages(ids);
      if (mounted) {
        setState(() {
          _items = _items.where((m) => !ids.contains(m.id)).toList();
          _future = Future.value(_items);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: AppText('Non è stato possibile eliminare i file.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: AppText('File con ${widget.otherDisplayName}', style: AppTypography.titleCompact()),
          actions: [
            if (_selecting) ...[
              IconButton(
                icon: Icon(AppIcons.trash, color: AppColors.berry),
                onPressed: _selected.isEmpty ? null : _deleteSelected,
              ),
              TextButton(
                onPressed: () => setState(() {
                  _selecting = false;
                  _selected.clear();
                }),
                child: const AppText('ANNULLA'),
              ),
            ] else ...[
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'select') setState(() => _selecting = true);
                  if (value == 'deleteAll') _deleteAll();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'select', child: AppText('Seleziona')),
                  PopupMenuItem(value: 'deleteAll', child: AppText('Elimina tutti')),
                ],
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<Message>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.fuchsia));
              }
              if (_items.isEmpty) {
                return Center(
                  child: AppText(
                    'Nessuna foto o video ancora.',
                    style: AppTypography.body(color: AppColors.inkSoft),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisSpacing: AppSpacing.xs,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isSelected = _selected.contains(item.id);
                  return GestureDetector(
                    onTap: () {
                      if (_selecting) {
                        _toggleSelect(item.id);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MediaViewerScreen(url: item.attachmentUrl!, type: item.attachmentType!),
                          ),
                        );
                      }
                    },
                    onLongPress: () => setState(() {
                      _selecting = true;
                      _selected.add(item.id);
                    }),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: item.attachmentType == AttachmentType.image
                              ? Image.network(item.attachmentUrl!, fit: BoxFit.cover)
                              : ColoredBox(
                                  color: Colors.black87,
                                  child: Icon(AppIcons.playCircle, color: AppColors.white),
                                ),
                        ),
                        if (_selecting)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(
                              isSelected ? AppIcons.checkCircle : AppIcons.check,
                              color: isSelected ? AppColors.fuchsia : AppColors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
