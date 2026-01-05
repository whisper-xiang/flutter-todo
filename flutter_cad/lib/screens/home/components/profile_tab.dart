/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-05 13:30:48
 */
import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ProfileTab({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100),
            SizedBox(height: 16),
            Text('用户信息'),
          ],
        ),
      ),
    );
  }
}
