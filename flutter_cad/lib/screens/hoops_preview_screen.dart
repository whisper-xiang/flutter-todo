import 'package:flutter/material.dart';
import 'package:hoops_visualize/hoops_visualize.dart';
import '../models/cad_file.dart';

const String _hoopsLicense =
    '4AIK8CRp1EM2vRRc0CR39ANqDwmz0xizvUJ48QNp1xXEjr9EhjPMj79EjrBqCyVkCbDFxhaY4wQN7Rf\$Avnp1wEH3uQVxgmUEhML2vUGwRIL5zfs2FbqDDV10BYZ3y259RN22gBx0BZawTM_3fV05w2N2fYLBxi5AEyXCwm15Bb0BSU5CDZovUYN1iFcDiI3AS3b9Ri8zVmz2fna9EaU2eUK1CITwxYZ1Vn\$xb9EjrACj7DFrbDFj7DFj7DFj7DFIspFjIHGj7Eij7DFj7DFjGtPj7DFj7DFIspFjHmPIqR5DBmK3AUK5iVdvEuGDhf88Drk0ji7BhMSAin5wgNmCSuK0hjmximJ3Da7zSRk9xb3CvRv9xNn0UiI0uYzvUuz5sQYzyYgj7DFGrHFjDm5EhnzDvb15C72DuFr0SI5vVfzwzf0xgvpAgN9EgyIvEu14wu2xhjr2jnz5CQ52AQXADf8zQYPxiiVEff\$0Vi2CuRawCyHCi6X9TJm4Ez94fYRCyjq8QI6AQJmvUboAxrl1jj1DS6P0Dj1xVqGxgJ59DZ00Rm_1gru3UqZARM_ADJ33vbawgY_xy66Dy7r5iy63EQZxwMJ9yJu8TM32wrl0TQRAiQ4BDnn9EIGDQZlCyNw1Bnoxjq22uU5AgM1wyNs1CiZ2DnyCgNn1wFc5SJp0jj78hY2vEB32wZ45BJn2Szv7Tm3ACZa1eNsvUYYxSrl8ReN9SQP7TJtwhjuwuF38gU00TNuweFk5xXFj7DFIspFj7DFj7GhjNDFxfm4vRe4vQFowuQzxeJoweJnwhIz8DJn8fnpx7FmwBm2vQI58eM58AZnxva3wBfl8AJlxuFlwTVpwTNnwuM38AQ3xxRpwxM68xRm8ARn8QVk8xQ8vDY5xxQ6xTQ08hRk9hQ5xDRowRe2xfi4weU8whY78hU08fjmxfa28QY0vAI29eQ29fi18fbp8hJovQNmwuY6xBezweZoxRi5xuJo9eU58eU18uY4vARp8AY2xQRp7TU4wEbkwDY6wUa38Rm38va3weM0xDJl8TJl9fnmwDQ6xQFmvQQ1xRnk7QVl9eY59eFoxEa4vAQ0vUbnxvnl8eY7xTI5vAE08Ba58eYz8xJl8AU1wDNpxeY3wuRkxuE8wvi7vTRl8DQ1vANlxDJnwxNmxBnp7QU7xRm7wxU2vEa08BjlwDY8xhNm8AY27Ra7xAY2weFk7TVkxTVlxeU3wRe0wya2xhQ6xfe18uZnxUa7xeNn8yazwTJm9eM2xBa6xeY39eEzvAQ8wfbn8BboxTM1wRnpxTJn8Re48uQ48Re4wDI38hI1wuY88eFnwrEG2Bjo';

class HoopsPreviewScreen extends StatefulWidget {
  final String id;
  final CadFile file;

  const HoopsPreviewScreen({super.key, required this.id, required this.file});

  @override
  State<HoopsPreviewScreen> createState() => _HoopsPreviewScreenState();
}

class _HoopsPreviewScreenState extends State<HoopsPreviewScreen> {
  final GlobalKey<HoopsNativeViewState> _viewKey = GlobalKey();
  bool _isLoading = true;
  bool _fileLoaded = false;
  String? _errorMessage;

  void _onViewCreated() {
    debugPrint('HOOPS View created');
  }

  void _onFileLoaded(bool success) {
    setState(() {
      _isLoading = false;
      _fileLoaded = success;
      if (!success) {
        _errorMessage = 'CAD文件加载失败';
      }
    });
    if (success) {
      debugPrint('CAD文件加载成功: ${widget.file.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _viewKey.currentState?.resetView(),
            tooltip: '重置视图',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: () => _viewKey.currentState?.fitView(),
            tooltip: '适应视图',
          ),
        ],
      ),
      body: Stack(
        children: [
          HoopsNativeView(
            key: _viewKey,
            license: _hoopsLicense,
            filePath: widget.file.path,
            onViewCreated: _onViewCreated,
            onFileLoaded: _onFileLoaded,
          ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载CAD文件...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          if (_errorMessage != null && !_fileLoaded)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
