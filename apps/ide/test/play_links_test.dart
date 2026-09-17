import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/store/play_links.dart';

void main() {
  test('reads the account and developer id from a Play Console link', () {
    final l = PlayConsoleLink.parse('https://play.google.com/console/u/0/developers/8174711554070464364/app-list')!;
    expect(l.developerId, '8174711554070464364');
    expect(l.userIndex, 0);
    expect(l.appList('com.demo.app'), contains('developers/8174711554070464364/app-list?search=com.demo.app'));
    expect(PlayConsoleLink.parse('https://play.google.com/console/u/3/developers/123456/app/1/tracks')!.userIndex, 3);
    expect(PlayConsoleLink.parse('https://play.google.com/store/apps/details?id=x'), isNull);
  });

  test('opens the app own pages once the app id is known', () {
    final withApp = PlayConsoleLink.parse('https://play.google.com/console/u/0/developers/817471155407046436/app/4975171550098515073/app-dashboard')!;
    expect(withApp.appId, '4975171550098515073');
    expect(withApp.appContent, contains('app/4975171550098515073/app-dashboard'));

    // A link without an app falls back to the app list, and never loses the app already known.
    final listOnly = PlayConsoleLink.parse('https://play.google.com/console/u/0/developers/817471155407046436/app-list')!;
    expect(listOnly.appContent, contains('app-list'));
    expect(listOnly.merge(withApp).appContent, contains('app/4975171550098515073'));
  });
}
