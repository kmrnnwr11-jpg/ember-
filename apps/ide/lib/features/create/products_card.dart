import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../store/play_links.dart';
import 'app_builder.dart';

/// Products the AI put in the app, with one button to create and activate them on Google Play.
class ProductsCard extends ConsumerStatefulWidget {
  const ProductsCard({super.key, required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  ConsumerState<ProductsCard> createState() => _ProductsCardState();
}

class _ProductsCardState extends ConsumerState<ProductsCard> {
  static const _saKey = 'play_service_account';
  bool _busy = false;
  String? _error;
  Map<String, Map<String, dynamic>> _results = {};

  /// Products Google Play already sells, read when the card opens.
  Set<String> _active = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  /// Asks Google Play which products are active. Quiet on failure: without a
  /// key or a connection the card simply looks as it always did.
  Future<void> _loadStatus() async {
    if (widget.builder.products.isEmpty) return;
    try {
      final sa = await ref.read(settingsStoreProvider).read(_saKey);
      if (sa == null || sa.trim().isEmpty) return;
      final api = await ref.read(runnerApiProvider.future);
      final res = await api.playProductStatuses(widget.projectId, sa, widget.builder.products);
      final list = (res['statuses'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _active = {for (final s in list) if (s['active'] == true) s['id'] as String});
    } catch (_) {}
  }

  bool _isActive(Map<String, dynamic> p) => _active.contains(p['id']) || _results[p['id']]?['ok'] == true;

  static String _period(String? p) => switch (p) {
    'P1W' => '1 w',
    'P1M' => '1 m',
    'P3M' => '3 m',
    'P6M' => '6 m',
    'P1Y' => '1 y',
    _ => p ?? '',
  };

  Future<void> _activate() async {
    final l = AppLocalizations.of(context);
    final sa = await ref.read(settingsStoreProvider).read(_saKey);
    if (!mounted) return;
    if (sa == null || sa.trim().isEmpty) {
      setState(() => _error = l.productsNeedKey);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      final res = await api.syncPlayProducts(widget.projectId, sa, widget.builder.products);
      final list = (res['results'] as List).cast<Map<String, dynamic>>();
      setState(() => _results = {for (final r in list) r['id'] as String: r});
      // What Google really has now, not only what this run managed.
      await _loadStatus();
    } on RunnerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      icon: Icons.shopping_bag_outlined,
      title: l.productsTitle,
      hint: l.productsHint,
      children: [
        Gap.vSm,
        for (final p in widget.builder.products)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: _isActive(p)
                ? Icon(Icons.check_circle, color: context.ember.success)
                : Icon(p['type'] == 'subscription' ? Icons.autorenew_outlined : Icons.toll_outlined),
            title: Text('${p['title']}  ·  ${p['id']}'),
            subtitle: Text([
              p['type'] == 'subscription' ? l.productPerPeriod('${p['price']} ${p['currency']}', _period(p['period'] as String?)) : '${p['price']} ${p['currency']}',
              if ((p['freeTrialDays'] as num? ?? 0) > 0) l.productTrial((p['freeTrialDays'] as num).toInt()),
              if (_isActive(p)) l.productsActive,
              if (!_isActive(p) && _results[p['id']]?['ok'] == false) l.error('${_results[p['id']]!['error']}'),
            ].join('\n')),
          ),
        Gap.vSm,
        DefaultTextStyle.merge(style: context.text.bodySmall, child: StepsList.parse(l.productsBefore)),
        if (_error != null) ...[
          Gap.vSm,
          InlineMessage(_error!, error: true),
        ],
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _activate,
              icon: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.rocket_launch_outlined),
              label: Text(l.productsActivate),
            ),
            OutlinedButton(
              onPressed: () async => launchUrl(Uri.parse((await PlayConsoleLink.load()).paymentsProfile), mode: LaunchMode.externalApplication),
              child: Text(l.productsOpenPayments),
            ),
            OutlinedButton(
              onPressed: () => context.push('/projects/${widget.projectId}/play', extra: widget.builder.prompt),
              child: Text(l.productsUploadFirst),
            ),
          ],
        ),
      ],
    );
  }
}
