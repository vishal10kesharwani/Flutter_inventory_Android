import 'package:http/http.dart';
import 'dart:convert';

Future getData(url) async {
  Map<String, dynamic> requestPayload = {
    "url": url
  };
  String herokuURL = "http://fyp-app-2022.herokuapp.com/find";
  final response = await post(Uri.parse(herokuURL), body: jsonEncode(requestPayload), headers: {'Content-Type': 'application/json'},);
  print(response.body);
  return response.body;
}