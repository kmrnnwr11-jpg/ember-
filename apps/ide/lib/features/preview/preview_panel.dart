import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
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
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(data: url, size: 240),
              ),
              const SizedBox(height: 12),
              SelectableText(url, textAlign: TextAlign.center),
              if (localOnly) ...[
                const SizedBox(height: 8),
                Text(l.qrLocalhostWarning, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                          PopupMenuItem(value: d, child: ListTile(leading: Icon(d.icon), title: Text(d.label))),
                      ],
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
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: InputChip(
                          label: Text(l.autoRebuild),
                          avatar: const Icon(Icons.bolt, size: 16),
                          onDeleted: c.stopAutoRebuild,
                        ),
                      ),
                  ],
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
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(l.previewEmpty, textAlign: TextAlign.center)),
      );
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(36)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(26), child: SizedBox.fromSize(size: s, child: webview)),
                  ),
                ),
              ),
            );
          },
        ),
        if (c.phase == PreviewPhase.building)
          const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
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
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failed)
            Container(
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                controller.error != null ? l.error(controller.error.toString()) : l.buildFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            )
          else
            const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                controller.buildLog.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleView extends StatelessWidget {
  const _ConsoleView({required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Text(l.console, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              IconButton(iconSize: 16, color: Colors.white54, icon: const Icon(Icons.block), onPressed: controller.clearConsole),
            ],
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: controller.console.length,
              itemBuilder: (_, i) {
                final line = controller.console[controller.console.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  child: SelectableText(
                    line.message,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: line.level == 'error' ? Colors.redAccent : Colors.white70,
                    ),
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
