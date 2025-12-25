import 'dart:io';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/material.dart';
import '../models/cad_file.dart';
import '../services/mock_service.dart';

class FileProvider extends ChangeNotifier {
  final MockService _service;
  List<CadFile> _cloudFiles = [];
  final List<CadFile> _localFiles = [];
  bool _isLoading = false;

  FileProvider(this._service);

  List<CadFile> get cloudFiles => _cloudFiles;
  List<CadFile> get localFiles => _localFiles;
  bool get isLoading => _isLoading;

  Future<void> fetchCloudFiles() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cloudFiles = await _service.getFiles();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickLocalFile() async {
    final result = await picker.FilePicker.platform.pickFiles(
      type: picker.FileType.custom,
      allowedExtensions: ['dwg', 'dxf', 'pdf', 'png', 'jpg', 'step', 'obj'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final file = File(path);
      final stat = await file.stat();
      
      final newItem = CadFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result.files.single.name,
        path: path,
        type: _determineType(path),
        modifiedAt: stat.modified,
        size: stat.size,
      );
      
      _localFiles.add(newItem);
      notifyListeners();
    }
  }

  FileType _determineType(String path) {
    if (path.endsWith('.pdf')) return FileType.pdf;
    if (path.endsWith('.png') || path.endsWith('.jpg')) return FileType.image;
    if (path.endsWith('.dwg') || path.endsWith('.dxf')) return FileType.cad2d;
    if (path.endsWith('.step') || path.endsWith('.obj')) return FileType.cad3d;
    return FileType.unknown;
  }
}
