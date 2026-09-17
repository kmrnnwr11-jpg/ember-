import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Remembers which Play Console account (Google profile index + developer id) the
/// user works with, so every button opens their console instead of the account chooser.
class PlayConsoleLink {
  const PlayConsoleLink({this.userIndex = 0, this.developerId, this.appId});

  final int userIndex;
  final String? developerId;

  /// The app's own id inside Play Console, so buttons land on its pages.
  final String? appId;

  static const _key = 'play_console_link';

  /// Reads the account, developer id and app id out of any Play Console URL.
  static PlayConsoleLink? parse(String url) {
    final dev = RegExp(r'developers/(\d{5,25})').firstMatch(url)?.group(1);
    if (dev == null) return null;
    final u = RegExp(r'/console/u/(\d+)/').firstMatch(url)?.group(1);
    return PlayConsoleLink(
      userIndex: int.tryParse(u ?? '') ?? 0,
      developerId: dev,
      appId: RegExp(r'/app/(\d{5,25})').firstMatch(url)?.group(1),
    );
  }

  static Future<PlayConsoleLink> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const PlayConsoleLink();
      final parts = raw.split(':');
      String? at(int i) => parts.length > i && parts[i].isNotEmpty ? parts[i] : null;
      return PlayConsoleLink(userIndex: int.tryParse(parts.first) ?? 0, developerId: at(1), appId: at(2));
    } catch (_) {
      return const PlayConsoleLink();
    }
  }

  /// Keeps the app id already known when a link without one is pasted.
  PlayConsoleLink merge(PlayConsoleLink older) =>
      PlayConsoleLink(userIndex: userIndex, developerId: developerId ?? older.developerId, appId: appId ?? older.appId);

  Future<void> save() async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, '$userIndex:${developerId ?? ''}:${appId ?? ''}');
    } catch (_) {}
  }

  /// The app's own dashboard, which lists every App content question.
  String get appContent => appId == null || developerId == null ? appList() : '$_base/developers/$developerId/app/$appId/app-dashboard';

  String get _base => 'https://play.google.com/console/u/$userIndex';

  /// The user's app list, filtered on the package when known.
  String appList([String? packageName]) => developerId == null
      ? '$_base/developers'
      : '$_base/developers/$developerId/app-list${packageName == null ? '' : '?search=${Uri.encodeQueryComponent(packageName)}'}';

  String get createApp => developerId == null ? '$_base/developers/create-new-app' : '$_base/developers/$developerId/create-new-app';

  String get users => developerId == null ? '$_base/developers' : '$_base/developers/$developerId/users-and-permissions';

  String get paymentsProfile => developerId == null ? '$_base/developers' : '$_base/developers/$developerId/payments-profile';

  Future<void> open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
