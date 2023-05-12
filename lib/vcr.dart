import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/io.dart';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart';
import 'package:vcr/cassette.dart';

const dioHttpHeadersForResponseBody = {
  Headers.contentTypeHeader: [Headers.jsonContentType],
};

class VcrAdapter extends IOHttpClientAdapter {
  late String basePath;
  bool createIfNotExists;
  File? _file;

  File get file {
    if (_file == null)
      throw Exception(
          'File not loaded, use `useCassette` or enable creation if not exists with `createIfNotExists` options');

    return _file!;
  }

  VcrAdapter(
      {String basePath = 'test/cassettes', this.createIfNotExists = true}) {
    final current = p.current;
    this.basePath =
        p.joinAll([current, ...basePath.replaceAll("\\", "/").split('/')]);
  }

  useCassette(path) {
    _file = loadFile(path);
  }

  File loadFile(String path) {
    final filePath = loadPath(path);
    return File(filePath);
  }

  String loadPath(String path) {
    if (!path.endsWith('.json')) {
      path = "$path.json";
    }

    var paths = path.replaceAll("\\", "/").split('/');

    String cassettePath = p.joinAll(paths);

    return p.join(basePath, cassettePath);
  }

  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    if (_file == null && createIfNotExists) {
      useCassette(options.uri.path);
    }

    var data = await matchRequest(options);

    if (data == null) {
      data = await makeNormalRequest(options, requestStream, cancelFuture);
    }

    if (data == null) {
      throw Exception('Unable to create cassette');
    }

    Map response = data['response'];

    final responsePayload = json.encode(response['body']);

    return ResponseBody.fromString(
      responsePayload,
      response["status"],
      headers: dioHttpHeadersForResponseBody,
    );
  }

  Future<Map?> makeNormalRequest(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    ResponseBody responseBody =
        await super.fetch(options, requestStream, cancelFuture);

    var cassette = Cassette(file, responseBody, options);

    await cassette.save();

    return matchRequest(options);
  }

  List? _readFile() {
    String jsonString = file.readAsStringSync();
    return json.decode(jsonString);
  }

  Future<Map?> matchRequest(RequestOptions options) async {
    if (!file.existsSync()) return null;

    String host = options.uri.host;
    String path = options.uri.path;
    String method = options.method;
    List requests = _readFile()!;
    return requests.firstWhere((request) {
      Uri uri2 = Uri.parse(request["request"]["url"]);
      return uri2.host == host &&
          uri2.path == path &&
          request["request"]["method"] == method;
    }, orElse: () => null);
  }
}
