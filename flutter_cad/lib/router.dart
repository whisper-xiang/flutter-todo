/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:38:42
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-05 11:14:32
 * @FilePath: /flutter_cad/lib/router.dart
 */
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'providers/auth_provider.dart';
import 'models/cad_file.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cloud_files_screen.dart';
import 'screens/local_files_screen.dart';
import 'screens/preview_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final isLoggingIn = state.uri.toString() == '/login';

    // 移除强制登录验证，允许游客访问大多数页面
    // 只有在特定需要认证的页面才进行重定向
    if (isLoggingIn && isLoggedIn) {
      return '/home'; // 已登录用户不应访问登录页
    }

    return null; // 允许所有其他访问
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          CupertinoPage(child: const LoginScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CupertinoPage(child: const HomeScreen()),
    ),
    GoRoute(
      path: '/local',
      pageBuilder: (context, state) =>
          CupertinoPage(child: const LocalFilesScreen()),
    ),
    GoRoute(
      path: '/cloud',
      pageBuilder: (context, state) =>
          CupertinoPage(child: const CloudFilesScreen()),
    ),
    GoRoute(
      path: '/preview/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        // 通过 extra 传递文件对象，简化 demo 实现
        final file = state.extra as CadFile;
        return CupertinoPage(
          child: PreviewScreen(id: id, file: file),
        );
      },
    ),
  ],
);
