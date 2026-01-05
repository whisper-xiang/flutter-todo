import '../models/cad_file.dart';

class MockService {
  void _logNetwork(
    String method,
    String url, {
    Map<String, dynamic>? data,
    int? statusCode,
    String? response,
  }) {
    print('🌐 ──────────────────────────────────');
    print('📡 $method $url');
    if (data != null) {
      print('📦 Request Data: $data');
    }
    if (statusCode != null) {
      print('📊 Status: $statusCode');
    }
    if (response != null) {
      print('📄 Response: $response');
    }
    print('⏰ Time: ${DateTime.now()}');
    print('──────────────────────────────────');
  }

  Future<bool> login(String email, String password) async {
    final url = 'https://api.example.com/login';
    _logNetwork('POST', url, data: {'email': email, 'password': '***'});

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final result = email.isNotEmpty && password.isNotEmpty;
    _logNetwork(
      'POST',
      url,
      statusCode: result ? 200 : 401,
      response: result ? 'Login successful' : 'Login failed',
    );

    return result;
  }

  Future<List<CadFile>> getFiles() async {
    final url = 'https://api.example.com/files';
    _logNetwork('GET', url);

    await Future.delayed(const Duration(seconds: 1));

    final files = [
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

    _logNetwork(
      'GET',
      url,
      statusCode: 200,
      response: 'Found ${files.length} files',
    );

    return files;
  }

  Future<bool> uploadFile(String path) async {
    final url = 'https://api.example.com/upload';
    _logNetwork('POST', url, data: {'file': path});

    await Future.delayed(const Duration(seconds: 2));

    final result = true;
    _logNetwork('POST', url, statusCode: 200, response: 'Upload successful');

    return result;
  }
}
