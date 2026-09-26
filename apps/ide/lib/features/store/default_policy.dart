/// A privacy policy to fall back on when the model does not write one.
///
/// Google will not take an app without a policy at a public address, so the
/// listing step that produced everything else and left this one blank cost the
/// user the upload — with nothing on screen saying why. A written-in template
/// is not as good as one describing this app exactly, but it is true of it,
/// and it is publishable.
///
/// It claims only what the app can be seen to do: [ads] and [purchases] come
/// from what was actually built, not from a guess.
String defaultPrivacyPolicy({
  required String appName,
  required String email,
  bool ads = false,
  bool purchases = false,
  DateTime? today,
}) {
  final name = appName.trim().isEmpty ? 'This app' : appName.trim();
  final d = today ?? DateTime.now();
  final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final contact = email.trim().isEmpty ? '[EMAIL]' : email.trim();

  final collected = <String>[
    '- **What you type into the app** (for example the content you create). It is kept on your device and is not sent to us.',
    if (ads)
      '- **Advertising identifiers**, used by Google AdMob to show ads. In the European Union you are asked for consent before any ad loads, and you may refuse or change your mind at any time.',
    if (purchases)
      '- **Purchase records**, handled by Google Play Billing. We never see or store your payment details.',
    '- **Crash and error information**, when your device sends it to the platform, so faults can be fixed.',
  ];

  final third = <String>[
    if (ads) '- Google AdMob — advertising. https://policies.google.com/privacy',
    if (purchases) '- Google Play Billing — purchases. https://policies.google.com/privacy',
    if (!ads && !purchases) '- None. $name works without sending your data to any third party.',
  ];

  return '''
# Privacy Policy — $name

_Last updated: ${date}_

$name is made to be useful without collecting more than it needs. This policy
says plainly what it does with your information.

## What is collected

${collected.join('\n')}

## What is not collected

$name does not ask for your name, address or telephone number, does not track
you across other apps or websites, and does not sell or share your information
with anyone for advertising or any other purpose.

## Where your data is kept

What you create stays on your device. Removing the app removes it, so keep your
own copy of anything you want to keep — export it before uninstalling.

## Third-party services

${third.join('\n')}

## Your rights

If you are in the European Union, the GDPR gives you the right to see, correct,
export or delete the personal data held about you, and to withdraw a consent
you gave. Because $name keeps your content on your own device, you can exercise
most of these yourself at any time by deleting the content or the app. For
anything else, write to the address below and we will answer within 30 days.

## Children

$name is not directed at children under 13 and does not knowingly collect
anything from them.

## Changes to this policy

If this policy changes, the new version appears at this address with a new date
at the top.

## Contact

$contact
''';
}
