import 'package:ai_connect/ai_connect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AiMessage serializes role name', () {
    expect(const AiMessage(AiRole.user, 'hi').toJson(), {'role': 'user', 'content': 'hi'});
  });
}
