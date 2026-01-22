import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import '../models/cad_file.dart';

class ExcelPreviewScreen extends StatefulWidget {
  final CadFile file;

  const ExcelPreviewScreen({super.key, required this.file});

  @override
  State<ExcelPreviewScreen> createState() => _ExcelPreviewScreenState();
}

class _ExcelPreviewScreenState extends State<ExcelPreviewScreen> {
  bool _isLoading = true;
  String? _error;
  List<List<String>> _sheetData = [];
  List<String> _sheetNames = [];
  int _currentSheetIndex = 0;
  String _fileName = '';
  int _rowCount = 0;
  int _columnCount = 0;
  bool _useWebView = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadExcelFile();
  }

  Future<void> _loadExcelFile() async {
    try {
      print('尝试加载Excel文件: ${widget.file.path}');
      
      if (widget.file.path != null) {
        final file = File(widget.file.path!);
        
        if (!await file.exists()) {
          throw Exception('文件不存在');
        }
        
        print('文件大小: ${await file.length()} bytes');
        
        // 检测文件格式
        final extension = widget.file.name.split('.').last.toLowerCase();
        print('Excel格式: $extension');
        
        if (!['xls', 'xlsx'].contains(extension)) {
          throw Exception('不支持的Excel格式: $extension');
        }
        
        _fileName = widget.file.name;
        
        // XLS格式使用WebView备用方案
        if (extension == 'xls') {
          print('检测到XLS格式，使用WebView备用方案');
          await _loadWebView();
          return;
        }
        
        // XLSX格式使用excel插件
        print('使用excel插件解析XLSX文件');
        await _loadExcelData();
      }
    } catch (e) {
      print('Excel文件加载失败: $e');
      if (mounted) {
        setState(() {
          _error = 'Excel文件加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWebView() async {
    try {
      // 使用Google Docs查看器
      final googleDocsUrl = 'https://docs.google.com/gview?embedded=1&url=https://r.jina.ai/http://localhost:8080/${widget.file.name}';
      
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              print('WebView导航到: ${request.url}');
              return NavigationDecision.navigate;
            },
            onPageFinished: (String url) {
              print('WebView页面加载完成: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _useWebView = true;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView错误: ${error.description}');
              if (mounted) {
                setState(() {
                  _error = 'WebView加载失败: ${error.description}';
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(googleDocsUrl));
    } catch (e) {
      print('WebView初始化失败: $e');
      if (mounted) {
        setState(() {
          _error = 'WebView初始化失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExcelData() async {
    try {
      final file = File(widget.file.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      print('Excel文件解析成功!');
      
      // 获取所有工作表名称
      _sheetNames = excel.tables.keys.toList();
      _currentSheetIndex = 0;
      
      if (_sheetNames.isEmpty) {
        throw Exception('Excel文件中没有工作表');
      }
      
      // 加载当前工作表数据
      await _loadSheetData(excel, _sheetNames[_currentSheetIndex]);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _useWebView = false;
        });
      }
    } catch (e) {
      print('Excel数据解析失败: $e');
      if (mounted) {
        setState(() {
          _error = 'Excel数据解析失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSheetData(Excel excel, String sheetName) async {
    try {
      final sheet = excel.tables[sheetName];
      if (sheet == null) {
        throw Exception('工作表 $sheetName 不存在');
      }
      
      final List<List<String>> data = [];
      
      // 简化处理：直接读取前100行和前26列
      final limitRows = 100;
      final limitCols = 26;
      
      for (int row = 0; row < limitRows; row++) {
        final List<String> rowData = [];
        bool hasData = false;
        
        for (int col = 0; col < limitCols; col++) {
          try {
            final cellValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))?.value;
            final formattedValue = _formatCellValue(cellValue);
            rowData.add(formattedValue);
            if (formattedValue.isNotEmpty) hasData = true;
          } catch (e) {
            rowData.add('');
          }
        }
        
        // 只添加有数据的行
        if (hasData || row == 0) {
          data.add(rowData);
        }
      }
      
      _rowCount = data.length;
      _columnCount = data.isNotEmpty ? data[0].length : 0;
      _sheetData = data;
      
      print('数据加载完成: ${data.length} 行 x ${data.isNotEmpty ? data[0].length : 0} 列');
    } catch (e) {
      print('加载工作表数据失败: $e');
      throw Exception('加载工作表数据失败: $e');
    }
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '';
    
    // 处理不同类型的值
    if (value is String) {
      return value;
    } else if (value is int) {
      return value.toString();
    } else if (value is double) {
      // 格式化数字，避免过长的小数
      if (value == value.toInt()) {
        return value.toInt().toString();
      } else {
        return value.toStringAsFixed(2);
      }
    } else if (value is DateTime) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    } else if (value is bool) {
      return value ? 'TRUE' : 'FALSE';
    } else {
      return value.toString();
    }
  }

  Future<void> _switchSheet(int index) async {
    if (index < 0 || index >= _sheetNames.length) return;
    
    setState(() {
      _isLoading = true;
      _currentSheetIndex = index;
    });
    
    try {
      final file = File(widget.file.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      await _loadSheetData(excel, _sheetNames[index]);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('切换工作表失败: $e');
      if (mounted) {
        setState(() {
          _error = '切换工作表失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          widget.file.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _shareFile,
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: '分享文件',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 20),
            Text(
              _useWebView ? '正在加载在线预览...' : '正在加载Excel文件...',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                'Excel文件预览失败',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadExcelFile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 如果使用WebView，显示WebView
    if (_useWebView) {
      return Column(
        children: [
          // 文件信息栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[50],
            child: Row(
              children: [
                Text('文件: $_fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('格式: XLS (在线预览)'),
                const SizedBox(width: 16),
                const Icon(Icons.cloud, color: Colors.blue),
              ],
            ),
          ),
          // WebView内容
          Expanded(
            child: WebViewWidget(controller: _webViewController!),
          ),
        ],
      );
    }

    // 否则显示本地解析的表格
    return Column(
      children: [
        // 工作表选择器
        if (_sheetNames.length > 1)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('工作表: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_sheetNames.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(_sheetNames[index]),
                            selected: index == _currentSheetIndex,
                            onSelected: (selected) {
                              if (selected) _switchSheet(index);
                            },
                            selectedColor: Colors.green,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // 文件信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Colors.grey[50],
          child: Row(
            children: [
              Text('文件: $_fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('工作表: ${_sheetNames[_currentSheetIndex]}'),
              const SizedBox(width: 16),
              Text('$_rowCount 行 x $_columnCount 列'),
            ],
          ),
        ),
        
        // 表格数据
        Expanded(
          child: _buildDataTable(),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (_sheetData.isEmpty) {
      return const Center(
        child: Text('工作表为空'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: List.generate(
            _sheetData.isNotEmpty ? _sheetData[0].length : 0,
            (index) => DataColumn(
              label: Container(
                width: 100,
                child: Text(
                  _getColumnName(index),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          rows: List.generate(
            _sheetData.length,
            (rowIndex) => DataRow(
              cells: List.generate(
                _sheetData[rowIndex].length,
                (colIndex) => DataCell(
                  Container(
                    width: 100,
                    constraints: const BoxConstraints(minWidth: 80),
                    child: Text(
                      _sheetData[rowIndex][colIndex],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => Colors.green.withOpacity(0.1),
          ),
          dataRowMaxHeight: double.infinity,
        ),
      ),
    );
  }

  String _getColumnName(int index) {
    // Excel列名: A, B, C, ..., Z, AA, AB, ...
    String columnName = '';
    int temp = index;
    while (temp >= 0) {
      columnName = String.fromCharCode(65 + (temp % 26)) + columnName;
      temp = (temp ~/ 26) - 1;
      if (temp < 0) break;
    }
    return columnName;
  }

  Future<void> _shareFile() async {
    // TODO: 实现文件分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
