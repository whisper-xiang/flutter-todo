import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../models/cad_file.dart';

class PdfPreviewScreen extends StatefulWidget {
  final CadFile file;

  const PdfPreviewScreen({super.key, required this.file});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.file(
      File(widget.file.path!),
      key: _pdfViewerKey,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableTextSelection: true,
      onDocumentLoaded: (details) {
        // PDF加载完成
      },
      onDocumentLoadFailed: (details) {
        setState(() {
          _error = 'PDF加载失败: ${details.error}';
        });
      },
      onPageChanged: (details) {
        // 页面变化时的处理
      },
    );
  }
}
