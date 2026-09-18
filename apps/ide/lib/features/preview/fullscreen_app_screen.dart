import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Runs the generated app edge-to-edge, like an installed app: no IDE chrome,
/// system bars hidden (immersive). Back gesture/button returns to the IDE.
class FullscreenAppScreen extends StatefulWidget {
  const FullscreenAppScreen({super.key, required this.url});

  final String url;

  @override
  State<FullscreenAppScreen> createState() => _FullscreenAppScreenState();
}

class _FullscreenAppScreenState extends State<FullscreenAppScreen> {
  InAppWebViewController? _web;
  double _progress = 0;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // In a browser the "app" is simply a new tab.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await launchUrl(Uri.parse(widget.url), webOnlyWindowName: '_blank');
        if (mounted) context.pop();
      });
      return;
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    if (!kIsWeb) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _back() async {
    // Let the generated app handle back navigation first (its own routes).
    if (_web != null && await _web!.canGoBack()) {
      await _web!.goBack();
    } else if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (kIsWeb) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            InAppWebView(
              key: const Key('fullscreenWebView'),
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                cacheEnabled: false,
                clearCache: true,
                mediaPlaybackRequiresUserGesture: false,
                supportZoom: false,
                useHybridComposition: true,
              ),
              onWebViewCreated: (c) => _web = c,
              onProgressChanged: (_, p) => setState(() => _progress = p / 100),
              // Google refuses to sign anyone in inside a window like this one, and
              // the app is left on a black screen. Hand the whole thing to the real
              // browser instead, where the same app and the same login do work.
              shouldOverrideUrlLoading: (_, action) async {
                final host = action.request.url?.host ?? '';
                if (!host.contains('accounts.google.com')) return NavigationActionPolicy.ALLOW;
                final messenger = ScaffoldMessenger.of(context);
                final text = AppLocalizations.of(context).previewLoginInBrowser;
                await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
                messenger.showSnackBar(SnackBar(content: Text(text)));
                return NavigationActionPolicy.CANCEL;
              },
            ),
            if (_progress < 1)
              Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(value: _progress == 0 ? null : _progress)),
            // Always-visible way back to Ember (desktop has no back gesture).
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Material(
                    color: Colors.black54,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      key: const Key('closeFullscreenApp'),
                      customBorder: const StadiumBorder(),
                      onTap: () => context.pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.close, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(l.backToEmber, style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _showHint ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                      child: Text(l.fullscreenExitHint, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
