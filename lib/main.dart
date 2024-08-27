import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:leadlife_webviewer/colors.dart';
import 'package:leadlife_webviewer/env.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  await Permission.microphone.request(); // if you need microphone permission
  await Permission.location.request(); // if you need microphone permission
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(
    MaterialApp(
      home: const MyApp(),
      title: Env.isAdvisor
          ? "Leadlife.id Advisor"
          : Env.isUser
              ? "Leadlife.id"
              : "Leadlife.id",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: colorPrimary,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();

  static String get leadIdUrl => Env.isAdvisor
      ? "https://leadlife.id/login/advisor"
      : Env.isUser
          ? "https://leadlife.id"
          : "https://leadlife.id";

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    alwaysBounceHorizontal: false,
    alwaysBounceVertical: false,
    userAgent:
        "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36",
    supportMultipleWindows: true,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    disallowOverScroll: true,
  );

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: colorPrimary,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if ((await webViewController?.canGoBack()) == true) {
          webViewController?.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            // Status bar color
            statusBarColor: Colors.black,

            // Status bar brightness (optional)
            statusBarIconBrightness:
                Brightness.dark, // For Android (dark icons)
            statusBarBrightness: Brightness.light, // For iOS (dark icons)
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              progress < 1.0
                  ? LinearProgressIndicator(
                      value: progress,
                      color: colorPrimary,
                    )
                  : const LinearProgressIndicator(
                      value: 1,
                      color: Colors.black,
                    ),
              Expanded(
                child: InAppWebView(
                  onGeolocationPermissionsShowPrompt:
                      (webViewController, origin) async {
                    return GeolocationPermissionShowPromptResponse(
                        allow: true, origin: origin, retain: true);
                  },
                  key: webViewKey,
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      leadIdUrl,
                      // "https://google.com"
                    ),
                  ),
                  initialSettings: settings,
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT);
                  },
                  onCreateWindow: (controller, createWindowRequest) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          insetPadding: EdgeInsets.zero,
                          contentPadding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: InAppWebView(
                              onGeolocationPermissionsShowPrompt:
                                  (webViewController, origin) async {
                                return GeolocationPermissionShowPromptResponse(
                                  allow: true,
                                  origin: origin,
                                  retain: true,
                                );
                              },
                              // Setting the windowId property is important here!
                              windowId: createWindowRequest.windowId,
                              initialSettings: InAppWebViewSettings(
                                isInspectable: kDebugMode,
                                mediaPlaybackRequiresUserGesture: false,
                                alwaysBounceHorizontal: false,
                                alwaysBounceVertical: false,
                                userAgent: "random",
                                supportMultipleWindows: true,
                                allowsInlineMediaPlayback: true,
                                iframeAllow: "camera; microphone",
                                iframeAllowFullscreen: true,
                                disallowOverScroll: true,
                              ),
                              onWebViewCreated:
                                  (InAppWebViewController controller) {},
                              onLoadStart: (InAppWebViewController controller,
                                  WebUri? url) {
                                debugPrint("onLoadStart popup $url");
                              },
                              onLoadStop: (InAppWebViewController controller,
                                  WebUri? url) async {
                                debugPrint("onLoadStop popup $url");
                              },
                              onCloseWindow: (controller) {
                                // On Facebook Login, this event is called twice,
                                // so here we check if we already popped the alert dialog context
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );

                    return true;
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    var uri = navigationAction.request.url!;
                    debugPrint("shouldOverrideUrlLoading uri: $uri");
                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about"
                    ].contains(uri.scheme)) {
                      if (await canLaunchUrl(uri)) {
                        // Launch the App
                        await launchUrl(
                          uri,
                        );
                        // and cancel the request
                        return NavigationActionPolicy.CANCEL;
                      }
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController?.endRefreshing();
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onReceivedError: (controller, request, error) {
                    pullToRefreshController?.endRefreshing();
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController?.endRefreshing();
                    }
                    setState(() {
                      this.progress = progress / 100;
                      urlController.text = url;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    if (kDebugMode) {
                      debugPrint(consoleMessage.toString());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
