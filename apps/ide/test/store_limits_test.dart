import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/store/play_publish_screen.dart';

void main() {
  test('a translated page is cut to what Google accepts, at a word', () {
    final page = fitToStore(<String, String>{
      'title': 'Modificatore di PDF completo e gratuito',
      'shortDescription': 'x' * 100,
      'fullDescription': 'ok',
    });
    expect(page['title']!.length, lessThanOrEqualTo(30));
    // Cut where a word ends, not in the middle of one.
    expect(page['title'], 'Modificatore di PDF completo');
    expect(page['shortDescription']!.length, 80);
    expect(page['fullDescription'], 'ok');
  });

  test('a page already within the limits is left alone', () {
    final page = fitToStore(<String, String>{'title': 'PDF Toolkit', 'shortDescription': 'Breve', 'fullDescription': 'Lunga'});
    expect(page, <String, String>{'title': 'PDF Toolkit', 'shortDescription': 'Breve', 'fullDescription': 'Lunga'});
  });
}
