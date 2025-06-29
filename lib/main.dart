import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billing Selling',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate immediately to avoid unnecessary delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WebViewApp()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo with subtle animation
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/app_logo.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Billing Selling',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            // More subtle loading indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: false,
      mediaPlaybackRequiresUserGesture: false,
      useOnDownloadStart: true,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      supportZoom: false,
      cacheEnabled: true,
      clearCache: false,
      transparentBackground: true, // Prevents black screen
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
      mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      safeBrowsingEnabled: true,
      supportMultipleWindows: true,
      builtInZoomControls: false,
      geolocationEnabled: true,
      allowContentAccess: true,
      allowFileAccess: true,
      overScrollMode: AndroidOverScrollMode.OVER_SCROLL_NEVER,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
      allowsBackForwardNavigationGestures: true,
      allowsLinkPreview: true,
    ),
  );

  final String url = "https://www.billingselling.com";
  bool isLoading = true;
  bool isWebViewReady = false;
  double progress = 0;
  String? initialUrl;

  @override
  void initState() {
    super.initState();
    _initializeResources();
  }

  Future<void> _initializeResources() async {
    try {
      // Get the last visited URL to potentially start from there
      final lastUrl = await getLastVisitedUrl();
      if (mounted) {
        setState(() {
          initialUrl = lastUrl ?? url;
        });
      }
    } catch (e) {
      // Handle any potential errors
      print("Error initializing resources: $e");
      if (mounted) {
        setState(() {
          initialUrl = url;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (webViewController != null) {
      if (await webViewController!.canGoBack()) {
        webViewController!.goBack();
        return false;
      } else {
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ) ??
            false;
      }
    }
    return true;
  }

  Future<void> saveLastVisitedUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_url', url);
  }

  Future<String?> getLastVisitedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_url');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white, // Prevent black background
        body: SafeArea(
          child: Stack(
            children: [
              // Show loading screen until we have initial URL
              if (initialUrl == null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/app_logo.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ),
                )
              else
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(url: WebUri(initialUrl!)),
                  initialOptions: options,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                    setState(() {
                      isWebViewReady = true;
                    });
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      isLoading = true;
                    });
                    if (url != null) {
                      saveLastVisitedUrl(url.toString());
                    }
                  },
                  onLoadStop: (controller, url) {
                    setState(() {
                      isLoading = false;
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    if (url != null) {
                      saveLastVisitedUrl(url.toString());
                    }
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                        var uri = navigationAction.request.url;
                        if (uri != null) {
                          return NavigationActionPolicy.ALLOW;
                        }
                        return NavigationActionPolicy.CANCEL;
                      },
                  onConsoleMessage: (controller, consoleMessage) {
                    print("Console Message: ${consoleMessage.message}");
                  },
                  onReceivedServerTrustAuthRequest:
                      (controller, challenge) async {
                        return ServerTrustAuthResponse(
                          action: ServerTrustAuthResponseAction.PROCEED,
                        );
                      },
                ),
              // Show progress indicator only during web page loading
              if (isLoading && isWebViewReady && initialUrl != null)
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Loading page...',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ), // Refresh button commented out as requested
        // floatingActionButton: !isLoading
        //     ? FloatingActionButton(
        //         child: const Icon(Icons.refresh),
        //         onPressed: () {
        //           webViewController?.reload();
        //         },
        //       )
        //     : null,
      ),
    );
  }
}
