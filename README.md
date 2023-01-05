# vcr

A package to mock requests using Dio Client

[![Build Status](https://travis-ci.com/keviinlouis/vcr.svg?token=AnXqdLS5A2ztMfzjxSdg&branch=master)](https://travis-ci.com/keviinlouis/vcr)
<a href="https://codeclimate.com/github/keviinlouis/vcr/maintainability"><img src="https://api.codeclimate.com/v1/badges/2b4874898ddb47ca3c76/maintainability" /></a>
## Getting Started

To start using, just create a adapter and put inside your client<br>
This is a example with Dio client:
```
VcrAdapter adapter = VcrAdapter({basePath:'test/cassettes', createIfNotExists: true });
Dio client = Dio();
client.httpClientAdapter = adapter;
```

After config the adapter, you now can use a cassette

```
Response response = await client.get('https://api.github.com/users/louis-kevin/repos');
expect(response.statusCode, 200);
```

Now the request is stored in `test/cassette/users/louis-kevin/repos.json`<br>

If you have multiple requests for one test, they will be added in a list of requests
If the adapter can't find the right request, he will make a normal request and then store the request

This package is inspired by VCR gem

#### Options

| basePath | string | Path to store your cassettes, relative to root |
| createIfNotExists | boolean | If this is disabled, you need to call `useCassette` before call your api|

### Using useCassette
The only main difference is that you need to call `useCassette` before calling your API
```
adapter.useCassette('github/my_casssete')
Response response = await client.get('https://api.github.com/users/louis-kevin/repos');
expect(response.statusCode, 200);
```

You can choose passing `.json` format or not, it will store the cassette in json either way<br>
Now the request is stored in `test/cassette/github/my_casssete.json`<br>

#### Next Features
- [ ] Work with Http Package
- [ ] Work with YAML

