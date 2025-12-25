import '../models/cad_file.dart';

class MockService {
  Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<List<CadFile>> getFiles() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      CadFile(
        id: '1',
        name: 'FloorPlan_Level1.dwg',
        url: 'https://example.com/files/floorplan.dwg',
        type: FileType.cad2d,
        modifiedAt: DateTime.now().subtract(const Duration(days: 2)),
        size: 1024 * 1024 * 5, // 5MB
      ),
      CadFile(
        id: '2',
        name: 'Engine_Part.step',
        url: 'https://example.com/files/engine.step',
        type: FileType.cad3d,
        modifiedAt: DateTime.now().subtract(const Duration(days: 5)),
        size: 1024 * 1024 * 12, // 12MB
      ),
      CadFile(
        id: '3',
        name: 'Project_Specs.pdf',
        url: 'https://example.com/files/specs.pdf',
        type: FileType.pdf,
        modifiedAt: DateTime.now().subtract(const Duration(hours: 4)),
        size: 1024 * 500, // 500KB
      ),
    ];
  }

  Future<bool> uploadFile(String path) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}
