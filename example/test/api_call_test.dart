// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dio/dio.dart';
import 'package:vcr/vcr.dart';
import '../lib/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late VcrAdapter adapter;
  late ApiCall apiCall;
  setUp(() {
    adapter = VcrAdapter();
    apiCall = ApiCall();
    apiCall.client.httpClientAdapter = adapter;
  });

  test('test call', () async {
    await adapter.useCassette('github/user_repos');
    Response response = await apiCall.call();
    expect(response.statusCode, 200);
  });
}
