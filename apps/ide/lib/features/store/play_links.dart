import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Remembers which Play Console account (Google profile index + developer id) the
/// user works with, so every button opens their console instead of the account chooser.
class PlayConsoleLink {
  const PlayConsoleLink({this.userIndex = 0, this.developerId});

  final int userIndex;
  final String? developerId;

  static const _key = 'play_console_link';

  /// Reads the account and developer id out of any Play Console URL.
  static PlayConsoleLink? parse(String url) {
    final dev = RegExp(r'developers/(\d{5,25})').firstMatch(url)?.group(1);
    if (dev == null) return null;
    final u = RegExp(r'/console/u/(\d+)/').firstMatch(url)?.group(1);
    return PlayConsoleLink(userIndex: int.tryParse(u ?? '') ?? 0, developerId: dev);
  }

  static Future<PlayConsoleLink> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const PlayConsoleLink();
      final parts = raw.split(':');
      return PlayConsoleLink(userIndex: int.tryParse(parts.first) ?? 0, developerId: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null);
    } catch (_) {
      return const PlayConsoleLink();
    }
  }

  Future<void> save() async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, '$userIndex:${developerId ?? ''}');
    } catch (_) {}
  }

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
