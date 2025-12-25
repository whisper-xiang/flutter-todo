/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语 243267674@qq.com
 * @LastEditTime: 2025-12-25 11:39:57
 */
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _DashboardCard(
            icon: Icons.cloud_download,
            title: 'Cloud Files',
            onTap: () => context.push('/files'),
            color: Colors.blue.shade100,
          ),
          _DashboardCard(
            icon: Icons.folder_open,
            title: 'Local Files',
            onTap: () => context.push('/local'),
            color: Colors.green.shade100,
          ),
          _DashboardCard(
            icon: Icons.history,
            title: 'Recent',
            onTap: () {},
            color: Colors.orange.shade100,
          ),
          _DashboardCard(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {},
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.black54),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
