import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/file_provider.dart';


class LocalFileScreen extends StatelessWidget {
  const LocalFileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Files')),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          if (provider.localFiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No local files selected'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.pickLocalFile(),
                    icon: const Icon(Icons.add),
                    label: const Text('Pick File'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.localFiles.length,
            itemBuilder: (context, index) {
              final file = provider.localFiles[index];
              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.orange),
                title: Text(file.name),
                subtitle: Text(file.path ?? ''),
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
        onPressed: () => context.read<FileProvider>().pickLocalFile(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
