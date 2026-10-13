import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'error_screen.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  static const String APP_URL = 'https://atc1.com.eg/login.php';
  static const String APP_DOMAIN = 'atc1.com.eg';

  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    // تفعيل وضع edgeToEdge عشان يدي مساحة أكبر للشاشة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return ErrorScreen(
        message: errorMessage,
        onRetry: () {
          setState(() {
            hasError = false;
            errorMessage = '';
            isLoading = true;
          });
          webViewController?.loadUrl(
            urlRequest: URLRequest(url: WebUri(APP_URL)),
          );
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (webViewController != null) {
          final canGoBack = await webViewController!.canGoBack();
          if (canGoBack) {
            webViewController!.goBack();
          } else {
            final shouldExit = await _showExitDialog();
            if (shouldExit == true && mounted) {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgMain,
        // ← تم التعديل: SafeArea top: true عشان العناصر اللي فوق تبان
        body: SafeArea(
          top: true, 
          bottom: true,
          child: Stack(
            children: [
              Column(
                children: [
                  if (isLoading)
                    SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentBlue,
                        ),
                      ),
                    ),
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest:
                          URLRequest(url: WebUri(APP_URL)),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        databaseEnabled: true,
                        useHybridComposition: true, // مهم جداً للأداء
                        allowsInlineMediaPlayback: true,
                        mediaPlaybackRequiresUserGesture: false,
                        cacheEnabled: true,
                        clearCache: false,
                        supportZoom: false,
                        verticalScrollBarEnabled: false, // يخلي الشكل أنضف
                        horizontalScrollBarEnabled: false,
                        disableHorizontalScroll: true,
                        useShouldOverrideUrlLoading: true,
                        useOnDownloadStart: true,
                        allowFileAccess: true,
                        allowContentAccess: true,
                        geolocationEnabled: false,
                        transparentBackground: false,
                        // ← إعدادات مهمة جداً عشان الموقع يظهر صح على الموبايل
                        useWideViewPort: true, 
                        loadWithOverviewMode: true,
                        // ← إعدادات إضافية لتحسين الأداء
                        hardwareAcceleration: true,
                        offscreenPreRaster: true,
                      ),
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      // ← لوج عشان نشوف أخطاء الموقع لو موجودة
                      onConsoleMessage: (controller, consoleMessage) {
                        debugPrint("WebView Console: ${consoleMessage.message}");
                      },
                      onLoadStart: (controller, url) {
                        if (!mounted) return;
                        setState(() {
                          isLoading = true;
                        });
                      },
                      onLoadStop: (controller, url) async {
                        if (!mounted) return;
                        setState(() {
                          isLoading = false;
                        });
                        // منع السكرول الزيادة
                        await controller.evaluateJavascript(source: """
                          document.body.style.overscrollBehavior = 'none';
                          document.documentElement.style.overscrollBehavior = 'none';
                        """);
                      },
                      onProgressChanged: (controller, prog) {
                        if (!mounted) return;
                        setState(() {
                          progress = prog / 100;
                          if (prog >= 100) isLoading = false;
                        });
                      },
                      onReceivedError: (controller, request, error) {
                        if (request.isForMainFrame ?? false) {
                          if (!mounted) return;
                          setState(() {
                            hasError = true;
                            errorMessage = error.description;
                          });
                        }
                      },
                      onReceivedHttpError: (controller, request, response) {
                        if ((request.isForMainFrame ?? false) &&
                            response.statusCode != null &&
                            response.statusCode! >= 500) {
                          if (!mounted) return;
                          setState(() {
                            hasError = true;
                            errorMessage =
                                'خطأ في السيرفر: ${response.statusCode}';
                          });
                        }
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        final uri = navigationAction.request.url;
                        if (uri == null) return NavigationActionPolicy.ALLOW;

                        final host = uri.host;

                        // الروابط الخارجية تفتح في المتصفح
                        if (!host.contains(APP_DOMAIN)) {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        // روابط الملفات
                        final path = uri.path.toLowerCase();
                        final fileExts = [
                          '.pdf', '.xlsx', '.xls', '.doc',
                          '.docx', '.zip', '.csv'
                        ];
                        for (final ext in fileExts) {
                          if (path.endsWith(ext)) {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        // tel: و whatsapp: و mailto:
                        final scheme = uri.scheme.toLowerCase();
                        if (scheme == 'tel' ||
                            scheme == 'mailto' ||
                            scheme == 'whatsapp' ||
                            scheme == 'sms') {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                          return NavigationActionPolicy.CANCEL;
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onDownloadStartRequest: (controller, request) async {
                        if (await canLaunchUrl(request.url)) {
                          await launchUrl(request.url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingButton(
                      icon: Icons.refresh_rounded,
                      onPressed: () => webViewController?.reload(),
                      tooltip: 'تحديث',
                    ),
                    const SizedBox(height: 12),
                    _buildFloatingButton(
                      icon: Icons.home_rounded,
                      onPressed: () {
                        webViewController?.loadUrl(
                          urlRequest: URLRequest(url: WebUri(APP_URL)),
                        );
                      },
                      tooltip: 'الرئيسية',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.bgSecondary.withOpacity(0.95),
        borderRadius: BorderRadius.circular(50),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onPressed,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppTheme.accentPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppTheme.accentBlue, size: 24),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'الخروج من التطبيق',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'هل تريد الخروج من التطبيق؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppTheme.accentBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'خروج',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );
  }
}