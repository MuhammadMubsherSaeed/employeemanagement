import 'dart:convert';

class CheckDataException {
  static String parseResponse(String response) {
    var decodedJson = jsonDecode(response);
    return decodedJson['message'];
  }
}
