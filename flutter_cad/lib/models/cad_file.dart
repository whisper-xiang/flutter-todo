enum FileType {
  image,
  pdf,
  cad2d,
  cad3d,
  video,
  audio,
  text,
  document,
  unknown
}

class CadFile {
  final String id;
  final String name;
  final String? path; // Local path
  final String? url;  // Remote URL
  final FileType type;
  final DateTime modifiedAt;
  final int size;

  CadFile({
    required this.id,
    required this.name,
    this.path,
    this.url,
    required this.type,
    required this.modifiedAt,
    required this.size,
  });

  bool get isLocal => path != null;
  bool get isRemote => url != null;
}
