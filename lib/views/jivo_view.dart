import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jivochat_flutter/models/jivo_infos_model.dart';
import 'package:logger/logger.dart';

class JivoView extends StatefulWidget {
  final JivoInfos jivoInfos;
  final void Function(String url)? onLinkPressed;
  final void Function()? onClose;
  final Widget? loading;

  @override
  _JivoViewState createState() => _JivoViewState();

  const JivoView({
    Key? key,
    required this.jivoInfos,
    this.onLinkPressed,
    required this.onClose,
    this.loading,
  }) : super(key: key);
}

class _JivoViewState extends State<JivoView> {
  InAppWebViewController? _webViewController;
  late InAppWebViewGroupOptions _options;

  final Logger _logger = Logger();

  bool _isLoading = true;

  final ScreenUtil _screenUtil = ScreenUtil();

  Future<bool> _executeJivo() async {
    final html = '''
      var script = document.createElement('script');
      script.src = 'https://code.jivosite.com/widget/${widget.jivoInfos.websiteId}';
      script.async = true;
      document.head.appendChild(script);

      function jivo_onLoadCallback() {
        try {
          let openChat = jivo_api.open();
          if(openChat.result !== 'fail') {
            window.flutter_inappwebview.callHandler('JivoChatChannel', false);
          } 
        } catch(e) {
          console.log(e);
        }
      }

      function jivo_onClose() {
        window.flutter_inappwebview.callHandler('JivoChatChannelClose', true);
      }
    ''';

    _webViewController?.evaluateJavascript(
      source: html,
    );

    final Completer<bool> completer = Completer();

    _webViewController?.addJavaScriptHandler(
      handlerName: 'JivoChatChannel',
      callback: (args) {
        final bool val = args[0];
        completer.complete(val);
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'JivoChatChannelClose',
      callback: (args) {
        if (widget.onClose != null && args[0] == true) {
          widget.onClose!();
        }
      },
    );

    return completer.future;
  }

  @override
  void initState() {
    super.initState();

    _options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        cacheEnabled: true,
        useOnLoadResource: true,
        javaScriptEnabled: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Mobile Safari/537.36',
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        cacheMode: AndroidCacheMode.LOAD_CACHE_ELSE_NETWORK,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: _screenUtil.statusBarHeight,
              bottom: _screenUtil.bottomBarHeight),
          child: InAppWebView(
            gestureRecognizers: {}..add(
                Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer(),
                ),
              ),
            initialUrlRequest: URLRequest(
              url: Uri.parse(widget.jivoInfos.referenceUrl),
            ),
            initialOptions: _options,
            onWebViewCreated: (InAppWebViewController controller) {
              _webViewController = controller;
            },
            onLoadStop: (InAppWebViewController controller, Uri? url) async {
              if (_isLoading) {
                _executeJivo().then(
                  (value) => Future.delayed(
                    const Duration(milliseconds: 300),
                    () => setState(() => _isLoading = value),
                  ),
                );
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              _logger.e(consoleMessage.message);
            },
          ),
        ),
        if (_isLoading)
          if (widget.loading == null)
            Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        if (_isLoading)
          if (widget.loading != null) widget.loading!
      ],
    );
  }
}
