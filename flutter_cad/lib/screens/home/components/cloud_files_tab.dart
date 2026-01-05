/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-05 13:30:48
 */
import 'package:flutter/material.dart';

class CloudFilesTab extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CloudFilesTab({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云图'),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.cloud),
            title: Text('云图 ${index + 1}'),
            subtitle: const Text('更新时间: 2024-01-01'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show more options
              },
            ),
            onTap: () {
              // Open cloud diagram
            },
          );
        },
      ),
    );
  }
}
