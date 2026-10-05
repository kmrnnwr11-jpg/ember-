import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'publish_job.dart';

const _playConsoleSignup = 'https://play.google.com/console/signup';

const _cloudServiceAccounts = 'https://console.cloud.google.com/iam-admin/serviceaccounts';
const _enablePublisherApi = 'https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com';

/// A link that opens outside Ember (Play Console, Google Cloud).
class StoreLink extends StatelessWidget {
  const StoreLink(this.label, this.url, {super.key});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Text(label),
  );
}

/// A value to copy into a Google form, with the button that copies it.
class CopyRow extends StatelessWidget {
  const CopyRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: SelectableText('$label: $value', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconButton(
          tooltip: l.copy,
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            showEmberSnack(context, l.copied);
          },
        ),
      ],
    );
  }
}

/// Where the user pastes the address of their own Play Console, once.
class ConsoleLinkField extends StatelessWidget {
  const ConsoleLinkField({super.key, required this.controller, required this.developerId, required this.onSave});
  final TextEditingController controller;

  /// The developer account read from the saved address, when there is one.
  final String? developerId;
  final Future<void> Function(String url) onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Gap.sm),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.url,
        // An address is written left to right in every language.
        textDirection: TextDirection.ltr,
        onChanged: onSave,
        decoration: InputDecoration(
          labelText: l.consoleLinkLabel,
          hintText: 'https://play.google.com/console/u/0/developers/…',
          suffixIcon: IconButton(
            tooltip: l.paste,
            icon: const Icon(Icons.content_paste_outlined),
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final text = data?.text?.trim();
              if (text == null || text.isEmpty) return;
              controller.text = text;
              await onSave(text);
            },
          ),
          helperText: developerId == null ? l.consoleLinkHint : l.consoleLinkSaved(developerId!),
          helperMaxLines: 3,
          isDense: true,
        ),
      ),
    );
  }
}

/// Step 1: a Play Console account, which only the user can open.
class AccountStep extends StatelessWidget {
  const AccountStep({super.key, required this.hasAccount, required this.onHasAccount, required this.onNext});
  final bool hasAccount;
  final ValueChanged<bool> onHasAccount;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(icon: Icons.info_outline, title: l.plFeeTitle, hint: l.playFeeNotice, tone: Tone.attention, margin: EdgeInsets.zero),
        Gap.vSm,
        StoreLink(l.playOpenSignup, _playConsoleSignup),
        CheckboxListTile(value: hasAccount, onChanged: (v) => onHasAccount(v ?? false), title: Text(l.playHaveAccount), contentPadding: EdgeInsets.zero),
        Gap.vSm,
        FilledButton(onPressed: hasAccount ? onNext : null, child: Text(l.next)),
      ],
    );
  }
}

/// Step 2: the app created by hand in Play Console (Google allows no other way).
class CreateAppStep extends StatelessWidget {
  const CreateAppStep({
    super.key,
    required this.packageName,
    required this.consoleUrl,
    required this.consoleField,
    required this.appCreated,
    required this.onAppCreated,
    required this.onNext,
  });
  final String? packageName;
  final String consoleUrl;
  final Widget consoleField;
  final bool appCreated;
  final ValueChanged<bool> onAppCreated;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(data: l.playCreateAppGuide),
        Gap.vSm,
        if (packageName != null) CopyRow(l.playPackageName, packageName!),
        StoreLink(l.playOpenConsole, consoleUrl),
        consoleField,
        CheckboxListTile(value: appCreated, onChanged: (v) => onAppCreated(v ?? false), title: Text(l.playAppCreated), contentPadding: EdgeInsets.zero),
        Gap.vSm,
        FilledButton(onPressed: appCreated ? onNext : null, child: Text(l.next)),
      ],
    );
  }
}

/// Step 3: the key that lets Ember upload to Google Play.
class ConnectStep extends StatelessWidget {
  const ConnectStep({super.key, required this.serviceAccount, required this.valid, required this.consoleUrl, required this.onChanged, required this.onNext});
  final TextEditingController serviceAccount;

  /// The pasted text is a service-account key.
  final bool valid;
  final String consoleUrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(data: l.playConnectGuide),
        Gap.vSm,
        Wrap(
          spacing: Gap.sm,
          children: [
            StoreLink(l.playOpenApiLibrary, _enablePublisherApi),
            StoreLink(l.playOpenServiceAccounts, _cloudServiceAccounts),
            StoreLink(l.playOpenConsole, consoleUrl),
          ],
        ),
        Gap.vSm,
        SecretField(controller: serviceAccount, label: l.playServiceAccountJson, maxLines: 6, onChanged: onChanged),
        Gap.vMd,
        FilledButton(onPressed: valid ? onNext : null, child: Text(l.next)),
      ],
    );
  }
}

/// Step 5: what was uploaded, and what Google still wants done by hand.
class FinishStep extends StatelessWidget {
  const FinishStep({
    super.key,
    required this.result,
    required this.privacyUrl,
    required this.dataSafety,
    required this.contentRating,
    required this.otherDeclarations,
    required this.consoleUrl,
    required this.consoleField,
  });

  /// What the upload answered; null until there was one.
  final Map<String, dynamic>? result;
  final String privacyUrl;
  final String dataSafety;
  final String contentRating;
  final String otherDeclarations;
  final String consoleUrl;
  final Widget consoleField;

  Widget _answers(String title, String markdown) => ExpansionTile(
    title: Text(title),
    tilePadding: EdgeInsets.zero,
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    childrenPadding: const EdgeInsetsDirectional.only(bottom: Gap.md),
    children: [MarkdownBody(data: markdown, selectable: true)],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r != null) ...[
          SectionCard(
            icon: Icons.cloud_done_outlined,
            title: l.upTitle,
            tone: Tone.success,
            margin: EdgeInsets.zero,
            children: [
              Gap.vSm,
              SelectableText(
                '${l.playUploaded('${r['versionCode']}', '${r['track']}', r['downgradedToDraft'] == true ? l.playDraftNote : '')}\n${uploadSummary(l, r)}${r['reviewNotSent'] == true ? '\n\n${l.playReviewNotSent}' : ''}',
                style: TextStyle(color: context.scheme.onPrimaryContainer),
              ),
            ],
          ),
          Gap.vMd,
        ],
        MarkdownBody(data: l.playManualChecklist(privacyUrl.isEmpty ? '—' : privacyUrl)),
        if (dataSafety.isNotEmpty) _answers(l.playDataSafety, dataSafety),
        if (contentRating.isNotEmpty) _answers(l.playContentRating, contentRating),
        if (otherDeclarations.isNotEmpty) _answers(l.playOtherDeclarations, otherDeclarations),
        StoreLink(l.playOpenConsole, consoleUrl),
        consoleField,
      ],
    );
  }
}
