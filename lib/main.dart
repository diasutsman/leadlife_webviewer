import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leadlife_webviewer/pull_to_refresh.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_useragent/webview_useragent.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final _webviewUserAgentPlugin = WebviewUserAgent();
  bool canPop = false;

  late DragGesturePullToRefresh dragGesturePullToRefresh; // Here

  final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000));

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformUserAgent;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformUserAgent =
          await _webviewUserAgentPlugin.getPlatformUserAgent() ??
              'Unknown platform UserAgent';
    } on PlatformException {
      platformUserAgent = 'Failed to get platform UserAgent.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    print("platformUserAgent: $platformUserAgent");
    initController(platformUserAgent: "random");
  }

  @override
  void initState() {
    super.initState();
    dragGesturePullToRefresh = DragGesturePullToRefresh(); // Here
    addFileSelectionListener();
    initController();
  }

  void addFileSelectionListener() async {
    if (Platform.isAndroid) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      await androidController.setOnShowFileSelector(_androidFilePicker);
    }
  }

  Future<List<String>> _androidFilePicker(
      final FileSelectorParams params) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          params.acceptTypes.map((type) => type.split("/").last).toList(),
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      return [file.uri.toString()];
    }
    return [];
  }

  Future<bool> _willPopCallback() async {
    final canNavigate = await _controller.canGoBack();
    if (canNavigate) {
      _controller.goBack();
    }
    return !canNavigate;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        canPop = await _willPopCallback();
        print("onPopInvokedWithResult: canPop: $canPop");
        print("result: $result");
        setState(() {
          canPop = canPop;
        });
      },
      child: RefreshIndicator(
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        onRefresh: dragGesturePullToRefresh.refresh, // Here
        child: Scaffold(
          body: SafeArea(
            child: Builder(builder: (context) {
              // IMPORTANT: Use the RefreshIndicator context!
              dragGesturePullToRefresh.setContext(context); // Here
              return WebViewWidget(
                controller: _controller,
                gestureRecognizers: {
                  Factory(() => dragGesturePullToRefresh)
                }, // Here
              );
            }),
          ),
        ),
      ),
    );
  }

  void initController({String platformUserAgent = 'random'}) {
    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            dragGesturePullToRefresh.started(); // Here
          },
          onPageFinished: (String url) async {
            canPop = !(await _controller.canGoBack());
            print("onPageFinished: canPop: $canPop");
            setState(() {
              canPop = canPop;
            });
            dragGesturePullToRefresh.finished(); // Here
          },
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {
            dragGesturePullToRefresh.finished(); // Here
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
        platformUserAgent,
      )
      ..loadRequest(Uri.parse('https://leadlife.id'));
    dragGesturePullToRefresh // Here
        .setController(_controller)
        .setDragHeightEnd(200)
        .setDragStartYDiff(10)
        .setWaitToRestart(3000);
    WidgetsBinding.instance.addObserver(this);
  }
}
