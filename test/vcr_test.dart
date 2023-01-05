import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcr/vcr.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late VcrAdapter adapter;
  late Dio client;
  String cassetteName = 'github/user_repos';
  String url = 'https://api.github.com/users/louis-kevin/repos';

  List _readFile(File file) {
    String jsonString = file.readAsStringSync();
    return json.decode(jsonString);
  }

  checkRequestSizeInFile(File file, int size) {
    List requests = _readFile(file);

    expect(requests.length, size);
  }

  setUp(() {
    adapter = VcrAdapter(basePath: 'test/cassettes', createIfNotExists: false);
    client = Dio();
    client.httpClientAdapter = adapter;
  });

  tearDown(() {
    File file = adapter.loadFile(cassetteName);
    if (file.existsSync()) file.parent.delete(recursive: true);
  });

  test('make request when there is no cassette', () async {
    File file = adapter.loadFile(cassetteName);
    expect(file.existsSync(), isFalse);

    await adapter.useCassette(cassetteName);

    Response response = await client.get(url);
    expect(response.statusCode, 200);

    expect(file.existsSync(), isTrue);

    checkRequestSizeInFile(file, 1);
  });

  test('must not store a new request in same file when it already exists',
      () async {
    File file = adapter.loadFile(cassetteName);
    expect(file.existsSync(), isFalse);
    await adapter.useCassette(cassetteName);

    Response response = await client.get(url);
    expect(response.statusCode, 200);
    expect(file.existsSync(), isTrue);
    checkRequestSizeInFile(file, 1);

    response = await client.get(url);
    expect(response.statusCode, 200);
    checkRequestSizeInFile(file, 1);
  });

  test('must store a new request in same file when does not found', () async {
    File file = adapter.loadFile(cassetteName);
    expect(file.existsSync(), isFalse);
    await adapter.useCassette(cassetteName);

    Response response = await client.get(url);
    expect(response.statusCode, 200);
    expect(file.existsSync(), isTrue);
    checkRequestSizeInFile(file, 1);

    response = await client.get('https://api.github.com/users/louis-kevin');
    expect(response.statusCode, 200);
    checkRequestSizeInFile(file, 2);
  });

  test('must create cassette when useCassette is not called', () async {
    var oldCreateIfNotExists = adapter.createIfNotExists;
    adapter.createIfNotExists = true;
    File file = adapter.loadFile('users/louis-kevin/repos.json');

    expect(file.existsSync(), isFalse);

    Response response = await client.get(url);
    expect(response.statusCode, 200);
    expect(file.existsSync(), isTrue);
    checkRequestSizeInFile(file, 1);

    response = await client.get(url);
    expect(response.statusCode, 200);
    checkRequestSizeInFile(file, 1);

    file.deleteSync();
    expect(file.existsSync(), isFalse);
    adapter.createIfNotExists = oldCreateIfNotExists;
  });

  test('must not create cassette when useCassette is not called', () async {
    var oldCreateIfNotExists = adapter.createIfNotExists;
    adapter.createIfNotExists = false;
    File file = adapter.loadFile('users/louis/kevin/repos.json');

    expect(file.existsSync(), isFalse);

    expect(() => client.get(url), throwsException);

    expect(file.existsSync(), isFalse);
    adapter.createIfNotExists = oldCreateIfNotExists;
  });
}
