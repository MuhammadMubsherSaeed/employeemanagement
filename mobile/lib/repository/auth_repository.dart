
import 'package:flutter_base/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepository = StateProvider((ref) => _AuthRepository(ref));

// final databaseProvider = StateProvider((ref) =>
//     MyDatabase()
// );

class _AuthRepository {
  Ref ref;

  _AuthRepository(this.ref);

  // Future<SyncResponse> apiSync() async {
  //   try {
  //     String? deviceId = await _getId();
  //     bool isDownloaded = await Utils.getIsDownload();
  //     Map<String, dynamic> data = {
  //       "downloaded": isDownloaded ? 0 : 1,
  //       "device_id": deviceId,
  //     };
  //     Response response = await ref.read(networkRepositoryProvider).getRequest(
  //         EnvironmentConfig.SYNC, UrlSuffix.POST, false,
  //         data: data);
  //
  //     SyncResponse syncResponse = SyncResponse.fromJson(response.data);
  //     return syncResponse;
  //   } catch (error) {
  //     throw DataException(message: error.toString());
  //   }
  // }

  // Future<LoginResponse> apiLogin(String phoneNumber) async {
  //   try {
  //     String? deviceToken = "";
  //     try {
  //       deviceToken = await FirebaseMessaging.instance.getToken();
  //     } catch (ex, stack) {
  //       if (Constants.showLogs == 1) {
  //         // print(ex.toString());
  //         await FirebaseCrashlytics.instance
  //             .recordError(ex, stack, reason: ex.toString(), fatal: false);
  //       }
  //     }
  //     String? deviceId = await _getId();
  //     LoginRequestModel loginRequestModel;
  //     loginRequestModel = LoginRequestModel(
  //         userName: phoneNumber, deviceToken: deviceToken, deviceId: deviceId);
  //     Response response = await ref.read(networkRepositoryProvider).getRequest(
  //         (EnvironmentConfig.LOGIN_URL), UrlSuffix.POST, false,
  //         data: await loginRequestModel.toJson());
  //     LoginResponse loginResponse = LoginResponse.fromJson(response.data);
  //     if (loginResponse.success ?? false) {
  //       if (loginResponse.data != null) {
  //         Utils.setUserData(loginResponse.data!);
  //         Utils.setAccessToken(loginResponse.data!.accessToken!);
  //         Utils.setIsLoggedIn(false);
  //       }
  //     }
  //     return loginResponse;
  //   } catch (error) {
  //     throw DataException(message: error.toString());
  //   }
  // }

  // Future<ServerResponse> apiForgetPassword(String cnic, String userType) async {
  //   try {
  //     ForgetPasswordRequestModel forgetPasswordRequestModel =
  //         ForgetPasswordRequestModel(userName: cnic, userType: userType);
  //     Response response = await read(networkRepositoryProvider).getRequest(
  //         (EnvironmentConfig.BASE_API_URL_DEV +
  //             EnvironmentConfig.FORGET_PASSWORD),
  //         UrlSuffix.POST,
  //         false,
  //         data: forgetPasswordRequestModel.toJson());
  //     ServerResponse serverResponse = ServerResponse.fromJson(response.data);
  //     return serverResponse;
  //   } catch (error) {
  //     throw DataException(message: error.toString());
  //   }
  // }
  //
  // Future<EmployerRegistrationSubmitResponse> apiRegisterEmployee(
  //     EmployeeRegistrationRequestModel employeeRegistrationRequestModel) async {
  //   try {
  //     FormData formDataBody =
  //         FormData.fromMap(await employeeRegistrationRequestModel.toJson());
  //
  //     Response response = await read(networkRepositoryProvider).getRequest(
  //         (EnvironmentConfig.BASE_API_URL_DEV + EnvironmentConfig.REGISTER),
  //         UrlSuffix.POST,
  //         false,
  //         isMultipart: true,
  //         formData: formDataBody);
  //     EmployerRegistrationSubmitResponse employerRegistrationSubmitResponse =
  //         EmployerRegistrationSubmitResponse.fromJson(response.data);
  //     // if (loginResponse.status != null && loginResponse.status!) {
  //     //   await insertLoginResponse(loginResponse);
  //     // }
  //     return employerRegistrationSubmitResponse;
  //   } catch (error) {
  //     throw DataException(message: error.toString());
  //   }
  // }
  //
  // Future<EmployerRegistrationSubmitResponse> apiUpdateEmployee(
  //     EmployeeRegistrationRequestModel employeeRegistrationRequestModel) async {
  //   try {
  //     FormData formDataBody =
  //         FormData.fromMap(await employeeRegistrationRequestModel.toJson());
  //     Response response = await read(networkRepositoryProvider).getRequest(
  //         (EnvironmentConfig.BASE_API_URL_DEV +
  //             EnvironmentConfig.UPDATE_EMPLOYEE),
  //         UrlSuffix.POST,
  //         true,
  //         isMultipart: true,
  //         formData: formDataBody);
  //     EmployerRegistrationSubmitResponse employerRegistrationSubmitResponse =
  //         EmployerRegistrationSubmitResponse.fromJson(response.data);
  //     // if (loginResponse.status != null && loginResponse.status!) {
  //     //   await insertLoginResponse(loginResponse);
  //     // }
  //     return employerRegistrationSubmitResponse;
  //   } catch (error) {
  //     throw DataException(message: error.toString());
  //   }
  // }
  //
  // Future<EmployerRegistrationSubmitResponse> apiRegisterEmployer(
  //     EmployerRegistrationRequestModel employerRegistrationRequestModel) async {
  //   try {
  //     FormData formDataBody =
  //         FormData.fromMap(await employerRegistrationRequestModel.toJson());
  //
  //     Response response = await read(networkRepositoryProvider).getRequest(
  //         (EnvironmentConfig.BASE_API_URL_DEV +
  //             EnvironmentConfig.REGISTER_EMPLOYER),
  //         UrlSuffix.POST,
  //         false,
  //         isMultipart: true,
  //         formData: formDataBody);
  //     EmployerRegistrationSubmitResponse employerRegistrationSubmitResponse =
  //         EmployerRegistrationSubmitResponse.fromJson(response.data);
  //     // if (loginResponse.status != null && loginResponse.status!) {
  //     //   await insertLoginResponse(loginResponse);
  //     // }
  //     return employerRegistrationSubmitResponse;
  //   } catch (error) {
  //     throw DataException(message: error.toString());
  //   }
  // }
  //
  // Future<EmployerRegistrationSubmitResponse> apiUpdateEmployer(
  //     EmployerRegistrationRequestModel employeeRegistrationRequestModel) async {
  //   try {
  //     FormData formDataBody =
  //         FormData.fromMap(await employeeRegistrationRequestModel.toJson());
  //     Response response = await read(networkRepositoryProvider).getRequest(
  //         (EnvironmentConfig.BASE_API_URL_DEV +
  //             EnvironmentConfig.UPDATE_EMPLOYER),
  //         UrlSuffix.POST,
  //         true,
  //         isMultipart: true,
  //         formData: formDataBody);
  //     EmployerRegistrationSubmitResponse employerRegistrationSubmitResponse =
  //         EmployerRegistrationSubmitResponse.fromJson(response.data);
  //     // if (loginResponse.status != null && loginResponse.status!) {
  //     //   await insertLoginResponse(loginResponse);
  //     // }
  //     return employerRegistrationSubmitResponse;
  //   } catch (error) {
  //     throw DataException(message: error.toString());
  //   }
  // }

// Future<UserRegisterResponse> apiSignUp(String name, String cnic, String mobile) async {
//   try {
//     RegisterRequestModel signupRequestModel = RegisterRequestModel(
//         name,cnic, mobile);
//     Response response = await read(networkRepositoryProvider).getRequest(EnvironmentConfig.REGISTER, UrlSuffix.POST, false, data: signupRequestModel.toJson());
//     UserRegisterResponse registerResponse = UserRegisterResponse.fromJson(response.data);
//     return registerResponse;
//   } catch (error) {
//     throw DataException(message: error.toString());
//   }
// }

// Api For otp verification
// Future<OTPVerifyResponse> apiVerifyOtp(String cnic, String otp) async {
//   try {
//     VerifyOtpRequestModel verifyOtpRequestModel = VerifyOtpRequestModel(
//        cnic:cnic,otp:otp);
//     Response response = await read(networkRepositoryProvider).getRequest(EnvironmentConfig.VERIFY_OTP, UrlSuffix.POST, false, data: verifyOtpRequestModel.toJson());
//     OTPVerifyResponse otpVerifyResponse = OTPVerifyResponse.fromJson(response.data);
//     return otpVerifyResponse;
//   } catch (error) {
//     throw DataException(message: error.toString());
//   }
// }
//
// Future<OTPSendResponse> apiSendOtp(String cnic) async {
//   try {
//     SendOtpRequestModel sendOtpRequestModel = SendOtpRequestModel(
//        cnic:cnic);
//     Response response = await read(networkRepositoryProvider).getRequest(EnvironmentConfig.SEND_OTP, UrlSuffix.POST, false, data: sendOtpRequestModel.toJson());
//     OTPSendResponse otpSendResponse = OTPSendResponse.fromJson(response.data);
//     return otpSendResponse;
//   } catch (error) {
//     throw DataException(message: error.toString());
//   }
// }

// Api For Change Password
// Future<ResetPasswordResponse> apiSetPassword(String cnic,String password,String confirmPassword) async {
//   try {
//     ResetPasswordRequestModel resetPasswordRequestModel = ResetPasswordRequestModel(cnic:cnic,password:password,confirmPassword: confirmPassword);
//     Response response = await read(networkRepositoryProvider).getRequest(EnvironmentConfig.RESET_PASSWORD, UrlSuffix.POST,false,data:resetPasswordRequestModel.toJson());
//     ResetPasswordResponse resetPasswordResponse = ResetPasswordResponse.fromJson(response.data);
//     return resetPasswordResponse;
//   } catch (error) {
//     throw DataException(message: error.toString());
//   }
// }

// Insert User Login Response To Local DB
// Future<int> insertLoginResponse(LoginResponse response) async {
//   return await read(databaseProvider).loginResponseDao.insertLoginData(
//       response);
// }
// // Update User Details in Local DB
// Future<int> updateUserDetails(UserDetailsResponse response) async {
//   return await read(databaseProvider).loginResponseDao.updateUserData(
//       response);
// }
// // Delete All Users from Local DB
// Future<void> deleteUser() async {
//   return await read(databaseProvider).loginResponseDao.deleteAll();
// }
// // Get User Data from Local DB
// Future<LoginResponse?> getUserData() async {
//   return await read(databaseProvider).loginResponseDao.getUserData();
// }

// Get User Data from Local DB
//   Future<List<Menu>> getAllMenuData() async {
//     return await read(databaseProvider).menuDao.getAllData();
//   }
//
//   Future<List<MenuItemCategories>> getAllMenuItemCategoriesData() async {
//     return await read(databaseProvider).menuItemCategoriesDao.getAllData();
//   }

  Future<void> removeAllData() async {
    await Utils.removeUserData();
    await Utils.removeAccessToken();
    await Utils.removeIsLoggedIn();
  }
}
