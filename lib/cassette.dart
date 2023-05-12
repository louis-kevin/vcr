import 'dart:convert';

import 'package:dio/dio.dart';
import 'dart:io';

class Cassette {
  ResponseBody responseBody;
  File file;
  dynamic data;
  RequestOptions requestOptions;

  Cassette(this.file, this.responseBody, this.requestOptions);

  save() async {
    await _buildData();
    _storeRequest();
  }

  _buildData() async {
    final transformer = BackgroundTransformer();

    this.data =
        await transformer.transformResponse(requestOptions, responseBody);
  }

  void _storeRequest() {
    List mock = [_toMap()];

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    } else {
      List requests = _readFile(file)!;
      requests.addAll(mock);
      mock = requests;
    }

    file.writeAsStringSync(json.encode(mock));
  }

  List? _readFile(File file) {
    String jsonString = file.readAsStringSync();
    return json.decode(jsonString);
  }

  _toMap() {
    return {
      'request': {
        'url': requestOptions.uri.toString(),
        'method': requestOptions.method,
        'payload': requestOptions.data,
        'headers': requestOptions.headers
      },
      'response': {
        'status': responseBody.statusCode,
        'body': data,
        'headers': responseBody.headers
      },
      'createdAt': DateTime.now().toString()
    };
  }
}
