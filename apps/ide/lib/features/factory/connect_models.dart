/// What the Runner says about the two store accounts (`GET /v1/connect`),
/// read leniently like everything else the Fabbrica gets from it.
library;

/// How an account stands: the store accepted its key just now, nothing is
/// saved, the store refused the key, or the store could not be asked.
enum StoreState {
  connected,
  missing,
  invalid,
  unreachable;

  static StoreState parse(Object? v) => StoreState.values.firstWhere((s) => s.name == v, orElse: () => StoreState.missing);
}

class StoreAccount {
  const StoreAccount({
    required this.provider,
    this.state = StoreState.missing,
    this.detail = '',
    this.account = '',
    this.message = '',
    this.teamId = '',
  });

  /// `google_play` or `apple`.
  final String provider;
  final StoreState state;

  /// A code: `ok`, `missing`, `bad_key`, `key_refused`, `no_permission`, `offline`.
  final String detail;

  /// The service account's email, or the Apple Key ID.
  final String account;

  /// What the store said, as a hint under the explanation.
  final String message;
  final String teamId;

  bool get connected => state == StoreState.connected;

  factory StoreAccount.fromJson(String provider, Object? json) {
    final j = json is Map ? json.cast<String, dynamic>() : const <String, dynamic>{};
    String s(Object? v) => v is String ? v : '';
    return StoreAccount(
      provider: provider,
      state: StoreState.parse(j['state']),
      detail: s(j['detail']),
      account: s(j['account']),
      message: s(j['message']),
      teamId: s(j['teamId']),
    );
  }
}

class StoreAccounts {
  const StoreAccounts({
    this.googlePlay = const StoreAccount(provider: 'google_play'),
    this.apple = const StoreAccount(provider: 'apple'),
    this.gcloudInstalled = false,
    this.developerId = '',
    this.links = const {},
  });

  final StoreAccount googlePlay;
  final StoreAccount apple;

  /// The Google Cloud tools are on this computer: the Google Play connection can be made hands-free.
  final bool gcloudInstalled;

  /// The Play Console developer account number saved with the key.
  final String developerId;

  /// Where each store makes its keys: `playConsole`, `googleCloudKeys`, `appStoreKeys`.
  final Map<String, String> links;

  bool get allConnected => googlePlay.connected && apple.connected;

  factory StoreAccounts.fromJson(Map<String, dynamic> j) {
    final gcloud = j['gcloud'];
    final links = j['links'];
    return StoreAccounts(
      googlePlay: StoreAccount.fromJson('google_play', j['googlePlay']),
      apple: StoreAccount.fromJson('apple', j['apple']),
      gcloudInstalled: gcloud is Map && gcloud['installed'] == true,
      developerId: j['developerId'] is String ? j['developerId'] as String : '',
      links: links is Map ? {for (final e in links.entries) '${e.key}': '${e.value}'} : const {},
    );
  }
}
