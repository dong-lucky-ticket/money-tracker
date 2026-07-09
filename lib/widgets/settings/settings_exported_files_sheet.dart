import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SettingsExportedFilesSheet extends StatefulWidget {
  final List<File> initialFiles;
  final Future<void> Function(BuildContext context, File file) onShareFile;

  const SettingsExportedFilesSheet({
    super.key,
    required this.initialFiles,
    required this.onShareFile,
  });

  @override
  State<SettingsExportedFilesSheet> createState() =>
      _SettingsExportedFilesSheetState();
}

class _SettingsExportedFilesSheetState extends State<SettingsExportedFilesSheet> {
  late final List<File> _files = List<File>.from(widget.initialFiles);

  Future<void> _deleteFile(BuildContext context, File file) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('删除文件'),
              content: const Text('确定要删除这个导出的文件吗？此操作不可恢复。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    file.deleteSync();
    if (mounted) {
      setState(() {
        _files.remove(file);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '已导出的 CSV 文件',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _files.isEmpty
              ? const Center(
                  child: Text(
                    '暂无导出的文件',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final fileName =
                        file.path.split(Platform.pathSeparator).last;
                    final fileSize =
                        (file.lengthSync() / 1024).toStringAsFixed(2);
                    final modifiedTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(file.lastModifiedSync());

                    return Builder(
                      builder: (itemContext) {
                        return ListTile(
                          leading: Icon(
                            MdiIcons.fileDelimitedOutline,
                            color: const Color(0xFF4A90E2),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '$modifiedTime  |  $fileSize KB',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () async {
                                  await widget.onShareFile(itemContext, file);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteFile(itemContext, file),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
