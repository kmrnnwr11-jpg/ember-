import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'preview_controller.dart';

enum DevicePreset {
  phone('iPhone', Size(390, 844), Icons.smartphone),
  android('Android', Size(412, 915), Icons.phone_android),
  tablet('Tablet', Size(820, 1180), Icons.tablet_mac),
  desktop('Desktop', Size.infinite, Icons.desktop_windows);

  const DevicePreset(this.label, this.size, this.icon);
  final String label;
  final Size size;
  final IconData icon;

  /// The name shown in the menu: brand names stay, the rest is translated.
  String title(AppLocalizations l) => switch (this) {
    DevicePreset.tablet => l.deviceTablet,
    DevicePreset.desktop => l.deviceDesktop,
    _ => label,
  };
}

class PreviewPanel extends StatefulWidget {
  const PreviewPanel({super.key, required this.controller});

  final PreviewController controller;

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  DevicePreset _device = DevicePreset.phone;
  bool _showConsole = false;
  InAppWebViewController? _web;

  PreviewController get c => widget.controller;

  Future<void> _openExternal() async {
    final url = c.url;
    if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showQr() {
    final url = c.url;
    if (url == null) return;
    final l = AppLocalizations.of(context);
    final host = Uri.parse(url).host;
    final localOnly = host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.openOnOtherDevice),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                // A QR code is read on a light ground, whatever the theme.
                color: context.ember.onCodeSurface,
                padding: const EdgeInsets.all(Gap.md),
                child: QrImageView(data: url, size: 240),
              ),
              Gap.vMd,
              SelectableText(url, textAlign: TextAlign.center),
              if (localOnly) ...[
                Gap.vSm,
                Text(l.qrLocalhostWarning, style: TextStyle(color: context.scheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: url)),
            child: Text(l.copy),
          ),
          FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final building = c.phase == PreviewPhase.building;
        final url = c.url;
        return Column(
          children: [
            Material(
              color: context.scheme.surfaceContainer,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                      child: FilledButton.icon(
                        key: const Key('runWeb'),
                        onPressed: building ? null : () => c.run(),
                        icon: building
                            ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.play_arrow),
                        label: Text(building ? l.building : l.runWeb),
                      ),
                    ),
                    IconButton(
                      tooltip: l.reload,
                      icon: const Icon(Icons.refresh),
                      onPressed: url == null ? null : () => _web?.reload(),
                    ),
                    PopupMenuButton<DevicePreset>(
                      tooltip: l.device,
                      icon: Icon(_device.icon),
                      initialValue: _device,
                      onSelected: (d) => setState(() => _device = d),
                      itemBuilder: (_) => [
                        for (final d in DevicePreset.values)
                          PopupMenuItem(value: d, child: ListTile(leading: Icon(d.icon), title: Text(d.title(l)))),
                      ],
                    ),
                    IconButton(
                      key: const Key('runFullscreen'),
                      tooltip: l.runFullscreen,
                      icon: const Icon(Icons.fullscreen),
                      onPressed: url == null ? null : () => context.push(Uri(path: '/run', queryParameters: {'url': url}).toString()),
                    ),
                    IconButton(
                      tooltip: l.openInBrowser,
                      icon: const Icon(Icons.open_in_new),
                      onPressed: url == null ? null : _openExternal,
                    ),
                    IconButton(tooltip: l.openOnOtherDevice, icon: const Icon(Icons.qr_code), onPressed: url == null ? null : _showQr),
                    IconButton(
                      tooltip: l.console,
                      isSelected: _showConsole,
                      icon: Badge(
                        isLabelVisible: c.console.any((e) => e.level == 'error'),
                        child: const Icon(Icons.bug_report_outlined),
                      ),
                      onPressed: () => setState(() => _showConsole = !_showConsole),
                    ),
                    if (c.info?.autoRebuild ?? false)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                        child: InputChip(
                          label: Text(l.autoRebuild),
                          avatar: const Icon(Icons.bolt, size: 16),
                          onDeleted: c.stopAutoRebuild,
                          deleteButtonTooltipMessage: l.stopAutoRebuild,
                        ),
                      ),
                  ]),
                ),
              ),
            ),
            Expanded(child: _body(context, l, url)),
            if (_showConsole) SizedBox(height: 180, child: _ConsoleView(controller: c)),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, String? url) {
    if (c.phase == PreviewPhase.building && url == null || c.phase == PreviewPhase.failed) {
      return _BuildLog(controller: c, failed: c.phase == PreviewPhase.failed);
    }
    if (url == null) {
      // Scrolls when the console leaves it only a strip of the panel.
      return Center(child: SingleChildScrollView(child: EmptyState(icon: Icons.phone_iphone, text: l.previewEmpty, compact: true)));
    }
    final webview = InAppWebView(
      key: ValueKey('$url#${c.revision}'),
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        cacheEnabled: false,
        clearCache: true,
        isInspectable: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (w) => _web = w,
      onConsoleMessage: (_, m) => c.addConsole(m.messageLevel.toNativeValue() == 3 ? 'error' : 'log', m.message),
    );
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            if (_device == DevicePreset.desktop) return webview;
            final s = _device.size;
            final scale = [box.maxWidth / (s.width + 24), box.maxHeight / (s.height + 24), 1.0].reduce((a, b) => a < b ? a : b);
            return Center(
              child: SizedBox(
                width: (s.width + 24) * scale,
                height: (s.height + 24) * scale,
                child: FittedBox(
                  child: Container(
                    width: s.width + 24,
                    height: s.height + 24,
                    padding: const EdgeInsets.all(Gap.md),
                    decoration: BoxDecoration(color: context.ember.codeSurface, borderRadius: BorderRadius.circular(36)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(26), child: SizedBox.fromSize(size: s, child: webview)),
                  ),
                ),
              ),
            );
          },
        ),
        if (c.phase == PreviewPhase.building)
          const PositionedDirectional(top: 0, start: 0, end: 0, child: LinearProgressIndicator()),
      ],
    );
  }
}

class _BuildLog extends StatelessWidget {
  const _BuildLog({required this.controller, required this.failed});

  final PreviewController controller;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: LogSurface(
        padding: EdgeInsets.zero,
        radius: BorderRadius.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failed)
              Container(
                color: context.scheme.errorContainer,
                padding: const EdgeInsets.all(Gap.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 18, color: context.scheme.onErrorContainer),
                    Gap.hSm,
                    Expanded(
                      child: Text(
                        controller.error != null ? l.error(controller.error.toString()) : l.buildFailed,
                        style: context.text.bodyMedium?.copyWith(color: context.scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              )
            else
              const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                padding: const EdgeInsets.all(Gap.sm),
                child: SelectableText(controller.buildLog.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An error line on the dark console: the theme's error colour, lifted enough
/// to read on a surface that stays dark in the light theme too.
Color _errorOnCode(BuildContext context) => Color.lerp(context.scheme.error, context.ember.onCodeSurface, 0.4)!;

class _ConsoleView extends StatelessWidget {
  const _ConsoleView({required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ember = context.ember;
    final errorColor = _errorOnCode(context);
    return LogSurface(
      padding: EdgeInsets.zero,
      radius: BorderRadius.zero,
      child: Column(
        children: [
          Row(
            children: [
              Gap.hSm,
              Text(l.console, style: TextStyle(color: ember.codeMuted)),
              const Spacer(),
              IconButton(
                tooltip: l.clearConsole,
                iconSize: 16,
                color: ember.codeMuted,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.block),
                onPressed: controller.clearConsole,
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: controller.console.length,
              itemBuilder: (_, i) {
                final line = controller.console[controller.console.length - 1 - i];
                final error = line.level == 'error';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Errors are marked by an icon too, not by colour alone.
                      if (error) ...[Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.error_outline, size: 12, color: errorColor)), Gap.hXs],
                      Expanded(child: SelectableText(line.message, style: error ? TextStyle(color: errorColor) : null)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
