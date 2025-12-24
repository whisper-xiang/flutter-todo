// 导入Flutter Material Design组件库
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';

// 应用入口函数
void main() {
  // 启动应用，传入根Widget
  runApp(const MyApp());
}

// 应用根组件，继承自StatelessWidget（无状态组件）
class MyApp extends StatelessWidget {
  // 构造函数，使用const优化性能
  const MyApp({super.key});

  // 构建UI界面的方法
  @override
  Widget build(BuildContext context) {
    // 返回Material Design风格的应用
    return MaterialApp(
      // 应用标题
      title: 'Flutter Demo',
      // 应用主题配置
      theme: new ThemeData(primaryColor: Colors.white),
      // 应用首页
      home: new RandomWords(),
    );
  }
}

// 首页组件，继承自StatefulWidget（有状态组件）
class MyHomePage extends StatefulWidget {
  // 构造函数，接收一个必填的title参数
  const MyHomePage({super.key, required this.title});

  // 页面标题
  final String title;

  // 创建状态对象
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// 首页状态类
class _MyHomePageState extends State<MyHomePage> {
  // 计数器变量
  int _counter = 0;

  // 增加计数器的方法
  void _incrementCounter() {
    // 调用setState通知框架状态已改变
    setState(() {
      // 计数器加1
      _counter++;
    });
  }

  // 构建UI界面
  @override
  Widget build(BuildContext context) {
    // 返回一个Scaffold组件，提供基本的Material Design布局结构
    return Scaffold(
      // 顶部导航栏
      appBar: AppBar(
        // 设置背景色为主题的反色
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // 设置标题文本
        title: Text(widget.title),
      ),
      // 页面主体内容
      body: Center(
        // 垂直排列子组件的列布局
        child: Column(
          // 垂直居中子组件
          mainAxisAlignment: MainAxisAlignment.center,
          children: [new RandomWords()],
        ),
      ),
      // 悬浮操作按钮
      floatingActionButton: FloatingActionButton(
        // 点击事件
        onPressed: _incrementCounter,
        // 长按提示文本
        tooltip: 'Increment',
        // 按钮图标
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  createState() => new RandomWordsState();
}

class RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final _saved = new Set<WordPair>();

  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          final tiles = _saved.map((pair) {
            return new ListTile(
              title: new Text(pair.asPascalCase, style: _biggerFont),
            );
          });
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();
          return new Scaffold(
            appBar: new AppBar(title: new Text('Saved Suggestions')),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Startup Name Generator'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.list), onPressed: _pushSaved),
        ],
      ),

      body: _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return new ListView.builder(
      padding: const EdgeInsets.all(16.0),
      // 对于每个建议的单词对都会调用一次itemBuilder，然后将单词对添加到ListTile行中
      // 在偶数行，该函数会为单词对添加一个ListTile row.
      // 在奇数行，该函数会添加一个分割线widget，来分隔相邻的词对。
      // 注意，在小屏幕上，分割线看起来可能比较吃力。
      itemBuilder: (context, i) {
        // 在每一列之前，添加一个1像素高的分隔线widget
        if (i.isOdd) return new Divider();

        // 语法 "i ~/ 2" 表示i除以2，但返回值是整形（向下取整），比如i为：1, 2, 3, 4, 5
        // 时，结果为0, 1, 1, 2, 2， 这可以计算出ListView中减去分隔线后的实际单词对数量
        final index = i ~/ 2;
        // 如果是建议列表中最后一个单词对
        if (index >= _suggestions.length) {
          // ...接着再生成10个单词对，然后添加到建议列表
          _suggestions.addAll(generateWordPairs().take(10));
        }
        return _buildRow(_suggestions[index]);
      },
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return new ListTile(
      title: new Text(pair.asPascalCase, style: _biggerFont),
      trailing: new Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }
}
