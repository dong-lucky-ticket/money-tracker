import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SettingsExportedFilesSheet extends StatefulWidget {
  final List<File> initialFiles;
  final Future<void> Function(BuildContext context, File file) onRestoreFile;
  final Future<void> Function(BuildContext context, File file) onShareFile;
  final Future<void> Function(BuildContext context, File file) onSaveToDevice;
  final Future<bool> Function(BuildContext context, File file) onDeleteFile;

  const SettingsExportedFilesSheet({
    super.key,
    required this.initialFiles,
    required this.onRestoreFile,
    required this.onShareFile,
    required this.onSaveToDevice,
    required this.onDeleteFile,
  });

  @override
  State<SettingsExportedFilesSheet> createState() =>
      _SettingsExportedFilesSheetState();
}

class _SettingsExportedFilesSheetState
    extends State<SettingsExportedFilesSheet> {
  late final List<File> _files = List<File>.from(widget.initialFiles);

  Future<void> _showActions(BuildContext context, File file) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(sheetContext);
                await widget.onRestoreFile(context, file);
              },
              child: const Text('恢复此备份'),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(sheetContext);
                await widget.onSaveToDevice(context, file);
              },
              child: const Text('保存到设备'),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(sheetContext);
                await widget.onShareFile(context, file);
              },
              child: const Text('分享文件'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(sheetContext);
                final deleted = await widget.onDeleteFile(context, file);
                if (!deleted || !mounted) {
                  return;
                }
                setState(() {
                  _files.remove(file);
                });
              },
              child: const Text('删除文件'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('取消'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '最近导出',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            '这里保存的是应用最近生成的临时备份，系统可能会自动清理。重要数据建议及时保存到设备或云盘。',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: _files.isEmpty
              ? const Center(
                  child: Text(
                    '暂无最近导出',
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
                          onTap: () => _showActions(itemContext, file),
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
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
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
