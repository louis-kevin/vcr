import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcr/cassette.dart';
import 'package:vcr/vcr.dart';

class VcrTestAdapter extends VcrAdapter {
  VcrTestAdapter({String basePath = 'test/cassettes', createIfNotExists = true})
      : super(basePath: basePath, createIfNotExists: createIfNotExists);

  fakeFetch(RequestOptions options,
      Stream<Uint8List>? _,
      Future? __,) {
    return ResponseBody.fromString(
      json.encode({"path": options.uri.path}),
      200,
    );
  }

  Future<Map?> makeNormalRequest(RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future? cancelFuture,) async {
    ResponseBody responseBody =
    await fakeFetch(options, requestStream, cancelFuture);

    var cassette = Cassette(file, responseBody, options);

    await cassette.save();

    return matchRequest(options.uri);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late VcrTestAdapter adapter;
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
    adapter =
        VcrTestAdapter(basePath: 'test/cassettes', createIfNotExists: false);
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
