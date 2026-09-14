import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
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
    final sa = await ref.read(keyValueStoreProvider).read(_saKey);
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
    } on RunnerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(l.productsTitle, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.productsHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final p in widget.builder.products)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(p['type'] == 'subscription' ? Icons.autorenew : Icons.toll_outlined),
                title: Text('${p['title']}  ·  ${p['id']}'),
                subtitle: Text([
                  p['type'] == 'subscription' ? l.productPerPeriod('${p['price']} ${p['currency']}', _period(p['period'] as String?)) : '${p['price']} ${p['currency']}',
                  if ((p['freeTrialDays'] as num? ?? 0) > 0) l.productTrial((p['freeTrialDays'] as num).toInt()),
                  if (_results[p['id']]?['ok'] == true) l.productsActive,
                  if (_results[p['id']]?['ok'] == false) '⚠️ ${_results[p['id']]!['error']}',
                ].join('\n')),
              ),
            const SizedBox(height: 8),
            Text(l.productsBefore, style: theme.textTheme.bodySmall),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _activate,
                  icon: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.rocket_launch_outlined),
                  label: Text(l.productsActivate),
                ),
                OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse('https://play.google.com/console/u/0/developers/payments-profile'), mode: LaunchMode.externalApplication),
                  child: Text(l.productsOpenPayments),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/projects/${widget.projectId}/play', extra: widget.builder.prompt),
                  child: Text(l.productsUploadFirst),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
