/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:38:42
 * @LastEditors: 轻语
 * @LastEditTime: 2025-12-25 16:42:00
 * @FilePath: /flutter_cad/lib/router.dart
 */
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'providers/auth_provider.dart';
import 'models/cad_file.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/file_list_screen.dart';
import 'screens/local_file_screen.dart';
import 'screens/preview_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final isLoggingIn = state.uri.toString() == '/login';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && isLoggingIn) return '/home';

    return null;
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
      path: '/files',
      pageBuilder: (context, state) =>
          CupertinoPage(child: const FileListScreen()),
    ),
    GoRoute(
      path: '/local',
      pageBuilder: (context, state) =>
          CupertinoPage(child: const LocalFileScreen()),
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
