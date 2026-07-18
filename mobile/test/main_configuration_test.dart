import 'package:minibanter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the local API by default for development', () {
    expect(apiBaseUrl, 'http://localhost:8000');
  });
}
