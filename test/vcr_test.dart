import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcr/vcr.dart';

void main() {
  DioAdapterMock adapter;
  Dio client;

  List _readFile(File file) {
    String jsonString = file.readAsStringSync();
    return json.decode(jsonString);
  }

  checkRequestSizeInFile(File file, int size){
    List requests = _readFile(file);

    expect(requests.length, size);
  }

  setUp((){
    adapter = DioAdapterMock();
    client = Dio();
    client.httpClientAdapter = adapter;
  });

  tearDown(() {
    var directory = Directory('test/cassetes');
    if(directory.existsSync()) directory.delete(recursive: true);
  });

  test('make request when there is no cassette', () async {
    File file = File('test/cassetes/github/user_repos.json');
    expect(file.existsSync(), isFalse);

    adapter.useCassette('github/user_repos');

    Response response = await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);

    expect(file.existsSync(), isTrue);

    checkRequestSizeInFile(file, 1);
  });

  test('must not store a new request in same file when it already exists', () async {
    File file = File('test/cassetes/github/user_repos.json');
    expect(file.existsSync(), isFalse);
    adapter.useCassette('github/user_repos');

    Response response = await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);
    expect(file.existsSync(), isTrue);
    checkRequestSizeInFile(file, 1);

    response = await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);
    checkRequestSizeInFile(file, 1);
  });

  test('must store a new request in same file when does not found', () async {
    File file = File('test/cassetes/github/user_repos.json');
    expect(file.existsSync(), isFalse);
    adapter.useCassette('github/user_repos');

    Response response = await client.get('https://api.github.com/users/keviinlouis/repos');
    expect(response.statusCode, 200);
    expect(file.existsSync(), isTrue);
    checkRequestSizeInFile(file, 1);

    response = await client.get('https://api.github.com/users/keviinlouis');
    expect(response.statusCode, 200);
    checkRequestSizeInFile(file, 2);
  });
}


