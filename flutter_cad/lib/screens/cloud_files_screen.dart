import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/file_provider.dart';
import '../models/cad_file.dart';

class CloudFilesScreen extends StatefulWidget {
  const CloudFilesScreen({super.key});

  @override
  State<CloudFilesScreen> createState() => _CloudFilesScreenState();
}

class _CloudFilesScreenState extends State<CloudFilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FileProvider>().fetchCloudFiles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Files')),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cloudFiles.isEmpty) {
            return const Center(child: Text('No files found'));
          }

          return ListView.builder(
            itemCount: provider.cloudFiles.length,
            itemBuilder: (context, index) {
              final file = provider.cloudFiles[index];
              return ListTile(
                leading: _buildIcon(file.type),
                title: Text(file.name),
                subtitle: Text(
                  'Size: ${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/preview/${file.id}', extra: file);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simulate upload
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload feature mocked')),
          );
        },
        child: const Icon(Icons.upload),
      ),
    );
  }

  Widget _buildIcon(FileType type) {
    switch (type) {
      case FileType.cad2d:
      case FileType.cad3d:
        return const Icon(Icons.architecture, color: Colors.blue);
      case FileType.pdf:
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case FileType.image:
        return const Icon(Icons.image, color: Colors.green);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }
}
