library vcr;

import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

const dioHttpHeadersForResponseBody = {
  Headers.contentTypeHeader: [Headers.jsonContentType],
};

class VcrAdapter extends Mock implements HttpClientAdapter {
  String basePath = 'test/cassettes';

  useCassette(path) {
    File file = _loadFile(path);

    if (!file.existsSync()) return makeNormalRequestWithAdapter(file);

    return makeMockRequestWithAdapter(file);
  }

  File _loadFile(String path) {
    if (!path.contains('.json')) {
      path = "$path.json";
    }
    String finalPath = "$basePath/$path";

    if(Platform.environment.containsKey('TRAVIS_BUILD_DIR')){
      String travisBuildDir = Platform.environment["TRAVIS_BUILD_DIR"];
      finalPath ="$travisBuildDir/$finalPath";
    }
    print(finalPath);
    return new File(finalPath);
  }

  makeMockRequestWithAdapter(File file) {
    when(fetch(any, any, any)).thenAnswer((invocation) async {
      List arguments = invocation.positionalArguments;
      return makeMockRequest(file, arguments[0], arguments[1], arguments[2]);
    });
  }

  makeNormalRequestWithAdapter(File file) {
    when(fetch(any, any, any)).thenAnswer((invocation) async {
      List arguments = invocation.positionalArguments;
      if (file.existsSync())
        return makeMockRequest(file, arguments[0], arguments[1], arguments[2]);

      return makeNormalRequest(file, arguments[0], arguments[1], arguments[2]);
    });
  }

  Future<ResponseBody> makeNormalRequest(
    File file,
    RequestOptions options,
    Stream<List<int>> requestStream,
    Future cancelFuture,
  ) async {
    final adapter = DefaultHttpClientAdapter();

    ResponseBody responseBody =
        await adapter.fetch(options, requestStream, cancelFuture);

    int status = responseBody.statusCode;

    DefaultTransformer transformer = DefaultTransformer();

    var data = await transformer.transformResponse(options, responseBody);

    _storeRequest(file, options, data, responseBody);

    return ResponseBody.fromString(
      json.encode(data),
      status,
      headers: dioHttpHeadersForResponseBody,
    );
  }

  Future<ResponseBody> makeMockRequest(
    File file,
    RequestOptions options,
    Stream<List<int>> requestStream,
    Future cancelFuture,
  ) async {
    Map data = await _matchRequest(options.uri, file, orElse: () async {
      await makeNormalRequest(file, options, requestStream, cancelFuture);
      return _matchRequest(options.uri, file);
    });

    Map response = data['response'];

    final responsePayload = json.encode(response['body']);

    return ResponseBody.fromString(
      responsePayload,
      response["status"],
      headers: dioHttpHeadersForResponseBody,
    );
  }

  void _storeRequest(File file, RequestOptions requestOptions, dynamic data,
      ResponseBody responseBody) {
    List mock = [_buildCassette(data, responseBody, requestOptions)];

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    } else {
      List requests = _readFile(file);
      requests.addAll(mock);
      mock = requests;
    }

    file.writeAsStringSync(json.encode(mock));
  }

  List _readFile(File file) {
    String jsonString = file.readAsStringSync();
    return json.decode(jsonString);
  }

  Map _buildCassette(
      dynamic data, ResponseBody responseBody, RequestOptions requestOptions) {
    return {
      'request': {
        'url': requestOptions.uri.toString(),
        'payload': requestOptions.data,
        'headers': requestOptions.headers ?? {}
      },
      'response': {
        'status': responseBody.statusCode,
        'body': data,
        'headers': responseBody.headers ?? {}
      },
      'createdAt': DateTime.now().toString()
    };
  }

  Future<Map> _matchRequest(Uri uri, File file, {orElse}) async {
    String host = uri.host;
    String path = uri.path;
    List requests = _readFile(file);
    return requests.firstWhere(
      (request) {
        Uri uri2 = Uri.parse(request["request"]["url"]);
        return uri2.host == host && uri2.path == path;
      },
      orElse: () =>
          orElse != null ? orElse() : throw Exception('Cassette not found'),
    );
  }
}
