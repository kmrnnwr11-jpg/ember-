import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

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

  /// Puts the preview back on the app and says why the Google button did nothing.
  ///
  /// Google refuses to run its sign-in inside a window like this one, and a
  /// session created in the real browser does not reach here either: they are
  /// separate browsers. The app's own email sign-in works, so say that instead
  /// of sending the user on a trip that ends where it started.
  Future<void> _signInElsewhere() async {
    final text = AppLocalizations.of(context).previewLoginInBrowser;
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
    if (mounted) showEmberSnack(context, text, error: true);
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
    final ember = context.ember;
    if (kIsWeb) return const Scaffold(body: LoadingState());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: ember.codeSurface,
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
                await _signInElsewhere();
                return NavigationActionPolicy.CANCEL;
              },
              // A popup window would open empty and stay black: the sign-in it
              // wants to show is the one Google refuses to run here.
              onCreateWindow: (_, request) async {
                final host = request.request.url?.host ?? '';
                if (!host.contains('accounts.google.com')) return false;
                await _signInElsewhere();
                return false;
              },
            ),
            if (_progress < 1)
              PositionedDirectional(top: 0, start: 0, end: 0, child: LinearProgressIndicator(value: _progress == 0 ? null : _progress)),
            // Always-visible way back to Ember (desktop has no back gesture).
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(Gap.sm),
                  child: OverlayButton(key: const Key('closeFullscreenApp'), icon: Icons.close, tooltip: l.backToEmber, onPressed: () => context.pop()),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _showHint ? 1 : 0,
              duration: Motion.of(context, Motion.slow),
              child: IgnorePointer(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(Gap.lg),
                      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
                      decoration: BoxDecoration(color: ember.scrim, borderRadius: Radii.lgAll),
                      child: Text(l.fullscreenExitHint, style: TextStyle(color: ember.onCodeSurface)),
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
