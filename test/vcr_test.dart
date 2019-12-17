import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcr/vcr.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  VcrAdapter adapter;
  Dio client;

  File getFile() {
    String path = 'github/user_repos.json';
    Directory current = Directory.current;
    String finalPath = current.path.endsWith('/test') ? current.path : current.path + '/test';

    finalPath = "$finalPath/cassettes/$path";
    return File(finalPath);
  }

  List _readFile(File file) {
    String jsonString = file.readAsStringSync();
    return json.decode(jsonString);
  }

  checkRequestSizeInFile(File file, int size) {
    List requests = _readFile(file);

    expect(requests.length, size);
  }

  setUp(() {
    adapter = VcrAdapter();
    client = Dio();
    client.httpClientAdapter = adapter;
  });

  tearDown(() {
    Directory current = Directory.current;
    String finalPath = current.path.endsWith('/test') ? current.path : current.path + '/test';
    var directory = Directory('$finalPath/cassettes');
    if (directory.existsSync()) directory.delete(recursive: true);
  });

  test('make request when there is no cassette', () async {
    File file = getFile();
    expect(file.existsSync(), isFalse);

    await adapter.useCassette('github/user_repos');

    Response response =
        await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);

    expect(file.existsSync(), isTrue);

    checkRequestSizeInFile(file, 1);
  });

  test('must not store a new request in same file when it already exists',
      () async {
    File file = getFile();
    expect(file.existsSync(), isFalse);
    await adapter.useCassette('github/user_repos');

    Response response =
        await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);
    expect(file.existsSync(), isTrue);
    checkRequestSizeInFile(file, 1);

    response =
        await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);
    checkRequestSizeInFile(file, 1);
  });

  test('must store a new request in same file when does not found', () async {
    File file = getFile();
    expect(file.existsSync(), isFalse);
    await adapter.useCassette('github/user_repos');

    Response response =
        await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);
    expect(file.existsSync(), isTrue);
    checkRequestSizeInFile(file, 1);

    response = await client.get('https://api.github.com/users/keviinlouis');
    expect(response.statusCode, 200);
    checkRequestSizeInFile(file, 2);
  });
}
