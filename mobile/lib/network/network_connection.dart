// import 'dart:convert';
//
// import 'package:dio/dio.dart';
// import 'package:paf_skyview/database/hive_functions.dart';
// import 'package:paf_skyview/network/environment_config.dart';
//
// class NetworkConnection {
//   static bool? networkAvailability;
//   static String timeoutError =
//       'TimeoutException after 0:00:10.000000: Future not completed';
//   static tokenGenerate() async {
//     var userCredentials = await HiveFunctions.getKeyValue('user_credentials');
//     if (userCredentials != null) {
//       final dio = Dio(BaseOptions(
//           baseUrl: EnvironmentConfig.getBaseUrl(),
//           headers: {
//             'Authorization': 'Bearer ${EnvironmentConfig.userToken}',
//             'Content-Type': 'application/json',
//             "Accept": "*/*",
//           },
//           connectTimeout: const Duration(seconds: 10),
//           receiveTimeout: const Duration(seconds: 10)));
//       var jsonBody = {
//         "user_name": userCredentials['user_name'],
//         "password": userCredentials['password'],
//       };
//       Response? response;
//       try {
//         response = await dio.post('user/login', data: jsonBody);
//         var decodeJson = jsonDecode(response.data.toString());
//         if (decodeJson['success'] == true) {
//           NetworkConnection.networkAvailability = true;
//           await HiveFunctions.putWithSingleValue(
//               'token', decodeJson['data']['token']);
//         }
//         NetworkConnection.networkAvailability = true;
//       } on DioException {
//         NetworkConnection.networkAvailability = false;
//       }
//     }
//   }
// }
