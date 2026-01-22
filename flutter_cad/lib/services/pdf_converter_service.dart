import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDF转换服务
/// 将Word文档转换为PDF格式
class PdfConverterService {
  static const String _libreOfficePath = '/Applications/LibreOffice.app/Contents/MacOS/soffice';
  
  /// 检查LibreOffice是否可用
  static Future<bool> isLibreOfficeAvailable() async {
    try {
      final result = await Process.run(_libreOfficePath, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      print('LibreOffice不可用: $e');
      return false;
    }
  }
  
  /// 使用LibreOffice转换Word文档为PDF
  static Future<File?> convertWordToPdfWithLibreOffice(String wordFilePath) async {
    try {
      print('开始使用LibreOffice转换Word文档: $wordFilePath');
      
      // 检查LibreOffice是否可用
      if (!await isLibreOfficeAvailable()) {
        throw Exception('LibreOffice未安装或不可用');
      }
      
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final outputDir = '${tempDir.path}/pdf_conversion';
      await Directory(outputDir).create(recursive: true);
      
      // 执行转换命令
      final result = await Process.run(_libreOfficePath, [
        '--headless',
        '--convert-to', 'pdf',
        '--outdir', outputDir,
        wordFilePath,
      ]);
      
      if (result.exitCode != 0) {
        throw Exception('LibreOffice转换失败: ${result.stderr}');
      }
      
      // 查找生成的PDF文件
      final wordFile = File(wordFilePath);
      final pdfFileName = '${wordFile.path.split('/').last}.pdf';
      final pdfFile = File('$outputDir/$pdfFileName');
      
      if (await pdfFile.exists()) {
        print('PDF转换成功: ${pdfFile.path}');
        return pdfFile;
      } else {
        throw Exception('PDF文件未生成');
      }
    } catch (e) {
      print('Word转PDF失败: $e');
      return null;
    }
  }
  
  /// 清理不支持的字符
  static String _cleanUnsupportedCharacters(String text) {
    // 替换不支持的字符为问号或空格
    return text.replaceAllMapped(
      RegExp(r'[^\x20-\x7E\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]'),
      (match) => match.group(0)!.length > 0 ? '?' : ' ',
    );
  }

  /// 创建简单的PDF文档（作为备用方案）
  static Future<File?> createSimplePdf(String wordFilePath) async {
    try {
      print('创建简单PDF文档作为备用方案');
      
      final wordFile = File(wordFilePath);
      String wordContent;
      
      // 尝试不同方式读取Word文档内容
      try {
        // 首先尝试UTF-8解码
        wordContent = await wordFile.readAsString(encoding: utf8);
      } catch (e) {
        try {
          // 尝试Latin-1解码
          wordContent = await wordFile.readAsString(encoding: latin1);
        } catch (e2) {
          try {
            // 尝试GBK解码（中文文档）
            wordContent = await wordFile.readAsString(encoding: Encoding.getByName('gbk') ?? utf8);
          } catch (e3) {
            // 如果都失败，创建基本信息PDF
            wordContent = '无法读取Word文档内容\n\n文件路径: $wordFilePath\n文件大小: ${await wordFile.length()} bytes\n\n这是一个Word文档的PDF预览。\n由于格式限制，无法直接显示文档内容。\n建议使用专业的Word处理软件打开此文件。';
          }
        }
      }
      
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf');
      
      // 创建PDF文档
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      
      // 添加标题
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16);
      final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
      
      page.graphics.drawString(
        'Word文档预览',
        titleFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: const Rect.fromLTWH(0, 0, 500, 30),
      );
      
      // 添加文件信息
      page.graphics.drawString(
        '文件名: ${wordFile.path.split('/').last}',
        contentFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: const Rect.fromLTWH(0, 50, 500, 20),
      );
      
      page.graphics.drawString(
        '文件大小: ${await wordFile.length()} bytes',
        contentFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: const Rect.fromLTWH(0, 80, 500, 20),
      );
      
      page.graphics.drawString(
        '转换时间: ${DateTime.now().toString()}',
        contentFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: const Rect.fromLTWH(0, 110, 500, 20),
      );
      
      // 添加分隔线
      page.graphics.drawLine(
        PdfPen(PdfColor(0, 0, 0), width: 1),
        Offset(0, 140),
        Offset(500, 140),
      );
      
      // 添加内容预览（限制长度）
      String previewContent = wordContent.length > 1000 
          ? '${wordContent.substring(0, 1000)}...\n\n[内容过长，仅显示前1000字符]'
          : wordContent;
      
      // 清理不支持的字符
      previewContent = _cleanUnsupportedCharacters(previewContent);
      
      // 将长文本分行显示
      List<String> lines = previewContent.split('\n');
      double yPosition = 160;
      
      for (String line in lines) {
        if (yPosition > 700) break; // 防止超出页面
        
        // 处理超长行
        if (line.length > 80) {
          List<String> words = line.split(' ');
          String currentLine = '';
          
          for (String word in words) {
            if ((currentLine + ' ' + word).length > 80) {
              if (currentLine.isNotEmpty) {
                page.graphics.drawString(
                  currentLine,
                  contentFont,
                  brush: PdfSolidBrush(PdfColor(0, 0, 0)),
                  bounds: Rect.fromLTWH(0, yPosition, 500, 15),
                );
                yPosition += 18;
                currentLine = word;
              } else {
                // 单词太长，直接显示
                page.graphics.drawString(
                  word,
                  contentFont,
                  brush: PdfSolidBrush(PdfColor(0, 0, 0)),
                  bounds: Rect.fromLTWH(0, yPosition, 500, 15),
                );
                yPosition += 18;
              }
            } else {
              currentLine = currentLine.isEmpty ? word : '$currentLine $word';
            }
          }
          
          if (currentLine.isNotEmpty) {
            page.graphics.drawString(
              currentLine,
              contentFont,
              brush: PdfSolidBrush(PdfColor(0, 0, 0)),
              bounds: Rect.fromLTWH(0, yPosition, 500, 15),
            );
            yPosition += 18;
          }
        } else {
          page.graphics.drawString(
            line,
            contentFont,
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(0, yPosition, 500, 15),
          );
          yPosition += 18;
        }
      }
      
      // 添加说明
      if (yPosition < 700) {
        yPosition += 20;
        page.graphics.drawString(
          '说明: 这是Word文档的文本内容预览',
          contentFont,
          brush: PdfSolidBrush(PdfColor(128, 128, 128)),
          bounds: Rect.fromLTWH(0, yPosition, 500, 15),
        );
        
        yPosition += 18;
        page.graphics.drawString(
          '格式和图片可能无法完全保留',
          contentFont,
          brush: PdfSolidBrush(PdfColor(128, 128, 128)),
          bounds: Rect.fromLTWH(0, yPosition, 500, 15),
        );
      }
      
      // 保存PDF文件
      final List<int> bytes = await document.save();
      await pdfFile.writeAsBytes(bytes);
      document.dispose();
      
      print('简单PDF创建成功: ${pdfFile.path}');
      return pdfFile;
    } catch (e) {
      print('创建简单PDF失败: $e');
      return null;
    }
  }
  
  /// 智能转换：尝试LibreOffice，失败则使用简单PDF
  static Future<File?> convertWordToPdf(String wordFilePath) async {
    print('开始智能转换Word文档: $wordFilePath');
    
    // 首先尝试LibreOffice转换
    File? pdfFile = await convertWordToPdfWithLibreOffice(wordFilePath);
    
    if (pdfFile != null) {
      return pdfFile;
    }
    
    print('LibreOffice转换失败，使用备用方案');
    // 使用简单PDF作为备用方案
    return await createSimplePdf(wordFilePath);
  }
  
  /// 清理临时文件
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final conversionDir = Directory('${tempDir.path}/pdf_conversion');
      
      if (await conversionDir.exists()) {
        await conversionDir.delete(recursive: true);
        print('临时文件清理完成');
      }
    } catch (e) {
      print('清理临时文件失败: $e');
    }
  }
}
