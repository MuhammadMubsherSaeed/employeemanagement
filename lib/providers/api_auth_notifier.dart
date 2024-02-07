import 'package:flutter/material.dart';
import 'package:flutter_base/models/states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/my_database.dart';
import '../utils/constants.dart';

final apiAuthNotifierProvider =
    StateNotifierProvider.autoDispose<ApiAuthNotifier, ApiStatesModel>(
        (ref) => ApiAuthNotifier(ref),
        name: "apiAuthNotifierProvider");

// final databaseProvider = StateProvider((ref) => MyDatabase());

// Login
final phoneLoginProvider = StateProvider((ref) => "");
final passwordLoginProvider = StateProvider((ref) => "");

// Otp
final otpCodeProvider = StateProvider((ref) => "");

// Register
final nameProvider = StateProvider((ref) => "");
final cnicProvider = StateProvider((ref) => "");
final mobileNumberProvider = StateProvider((ref) => "");
final emailProvider = StateProvider((ref) => "");
final cityProvider = StateProvider((ref) => "");
final ppProvider = StateProvider((ref) => "");
final wardProvider = StateProvider((ref) => "");
final partyDesignationProvider = StateProvider((ref) => "");
final partyWingProvider = StateProvider((ref) => "");

// final provinceValueProvider = StateProvider(
//     (ref) => Province(provinceId: -1, provinceName: dropdownHintText));
// final provinceFutureProvider = FutureProvider<List<Province>>((ref) async {
//   List<Province> provinceList = [];
//   var db = await ref.read(databaseProvider.notifier).state;
//   provinceList = await db.provinceDao.findAllProvince();
//   return provinceList;
// });

// final divisionValueProvider = StateProvider(
//     (ref) => Division(divisionId: -1, divisionName: dropdownHintText));
// final divisionFutureProvider = FutureProvider<List<Division>>((ref) async {
//   List<Division> divisionList = [];
//   Province selectedProvince = ref.watch(provinceValueProvider.notifier).state;
//   var db = await ref.read(databaseProvider.notifier).state;
//   if (selectedProvince.provinceId != -1) {
//     divisionList = await db.divisionDao
//         .findDistrictWithProvinceId(selectedProvince.provinceId);
//     if (divisionList.isEmpty) {
//       ref.invalidate(districtFutureProvider);
//     }
//   }
//   return divisionList;
// });

// final databaseProvider = StateProvider((ref) => getDbInstance());
//
// Future<MyDatabase> getDbInstance() async {
//   MyDatabase? databaseInstance;
//   final database = $FloorMyDatabase.databaseBuilder(Constants.dbName).build();
//   await database.then((value) => {databaseInstance = value});
//   return databaseInstance!;
// }

final databaseProvider = StateProvider((ref) => MyDatabase());

class ApiAuthNotifier extends StateNotifier<ApiStatesModel> {
  final AutoDisposeStateNotifierProviderRef _ref;

  ApiAuthNotifier(this._ref) : super(ApiStatesModel(States.IDLE, "", null));

  void isLoading(String loadingMessage) {
    state = ApiStatesModel(States.LOADING, loadingMessage, null);
  }

  void isError(String errorMessage) {
    state = ApiStatesModel(States.ERROR, errorMessage, null);
  }

  void isSuccess(String successMessage) {
    state = ApiStatesModel(States.DATA, successMessage, null);
  }

  void isSessionExpired(String sessionExpiredMessage) {
    state = ApiStatesModel(States.SESSIONEXPIRED, sessionExpiredMessage, null);
  }

  // Future<void> apiSync() async {
  //   try {
  //     state = ApiStatesModel(States.LOADING, "", null);
  //     SyncResponse response = await _ref.read(authRepository).apiSync();
  //     if (response.success != null && response.success!) {
  //       await insertSyncResponse(response);
  //     }
  //     if (response.statusCode == 400) {
  //       state =
  //           ApiStatesModel(States.SESSIONEXPIRED, response.message!, response);
  //     } else if (response.statusCode == 1000) {
  //       state = ApiStatesModel(States.APPUPDATE, response, response);
  //     } else {
  //       state = ApiStatesModel(States.DATA, response.message!, response);
  //     }
  //   } on DataException catch (error) {
  //     state = ApiStatesModel(States.ERROR, error.message, null);
  //   }
  // }

  // Future<void> apiLogin(BuildContext context) async {
  //   String phoneNumber = _ref.watch(phoneLoginProvider);
  //   try {
  //     state = ApiStatesModel(States.LOADING, pleaseWaitSignIn, null);
  //     LoginResponse response =
  //         await _ref.read(authRepository).apiLogin(phoneNumber);
  //     state = ApiStatesModel(States.DATA, response.message!, response);
  //   } on DataException catch (error) {
  //     state = ApiStatesModel(States.ERROR, error.message, null);
  //   }
  // }
}

class ApiStatesModel {
  ApiStatesModel(this.states, this.message, this.data);

  States states;
  String message;
  dynamic data;
}
