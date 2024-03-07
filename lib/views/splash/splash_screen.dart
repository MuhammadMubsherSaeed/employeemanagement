import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_base/models/response/sync/SyncResponse.dart';
import 'package:flutter_base/models/states.dart';
import 'package:flutter_base/providers/api_auth_notifier.dart';
import 'package:flutter_base/route/routes.dart';
import 'package:flutter_base/utils/image_assets.dart';
import 'package:flutter_base/utils/strings.dart';
import 'package:flutter_base/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../widgets/dialog_widget/dialog_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen> {
  // final apiNotifier = ref.watch(apiAuthNotifierProvider);
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () async {
      bool isLoggedIn = await Utils.getIsLoggedIn();
      print(isLoggedIn);
      if (!isLoggedIn) {
        _navigateTo(Routes.LOGIN);
      } else {
        _navigateTo(Routes.HOME);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiNotifier = ref.watch(apiAuthNotifierProvider);
    ref.listen(apiAuthNotifierProvider, (previous, apiStatesModel) async {
      switch (apiStatesModel.states) {
        case States.APPUPDATE:
          if (apiStatesModel.data is SyncResponse) {
            final response = apiStatesModel.data as SyncResponse;
            if ((response.version?.isForceUpdate ?? 0) == 1) {
              DialogBuilder.showUpdateOrSessionDialog(
                context: context,
                title: "Update",
                content: response.version?.dialogeMessage ?? "",
                acceptButtonTitle: "OK",
                onAcceptPressed: () {},
                isDismissible: false,
              );
            } else {
              DialogBuilder.showUpdateOrSessionDialog(
                context: context,
                title: "Update",
                content: response.version?.dialogeMessage ?? "",
                acceptButtonTitle: "OK",
                cancelButtonTitle: "Not now",
                onAcceptPressed: () {},
                onCancelledPressed: () {},
                isDismissible: false,
              );
            }
          }
          break;

        case States.SESSIONEXPIRED:
          DialogBuilder.showUpdateOrSessionDialog(
            context: context,
            title: sessionExpiredText,
            content: sessionExpiredContent,
            acceptButtonTitle: "OK",
            onAcceptPressed: () {},
            isDismissible: false,
          );
          break;
        case States.ERROR:
          // DialogBuilder.showNoInternetDialog(
          //     textSyncFailed, apiStatesModel.message, context, () {
          //   Navigator.pop(context);
          //   SystemNavigator.pop();
          // });
          // print(apiStatesModel.message);
          await Utils.setIsDownload(true);
          bool isLoggedIn = await Utils.getIsLoggedIn();
          print(isLoggedIn);
          if (!isLoggedIn) {
            _navigateTo(Routes.LOGIN);
          } else {
            _navigateTo(Routes.HOME);
          }
          break;
        case States.DATA:
          // if (apiStatesModel.data is SyncResponse) {
          //   final _response = apiStatesModel.data as SyncResponse;
          //   if (!(_response).success!) {
          //     if (_response.statusCode == 400) {
          //       DialogBuilder.showLogoutDialog(
          //         title: "Session Expired",
          //         content: sessionExpiredText,
          //         isCancelable: false,
          //         buttonText: "OK",
          //         context: context,
          //         callback: () async {
          //           await ref.read(authRepository).removeAllData();
          //           Navigator.pushNamedAndRemoveUntil(
          //               context, Routes.LOGIN, (route) => false);
          //         },
          //       );
          //     }
          //   } else {
          //     if (_response.data != null) {
          //       // await checkPermissions();
          //       await Utils.setIsDownload(true);
          //       bool isLoggedIn = await Utils.getIsLoggedIn();
          //       print(isLoggedIn);
          //       if (!isLoggedIn) {
          //         _navigateTo(Routes.LOGIN);
          //       } else {
          //         _navigateTo(Routes.HOME);
          //       }
          //     } else {
          //       await Utils.setIsDownload(true);
          //       bool isLoggedIn = await Utils.getIsLoggedIn();
          //       print(isLoggedIn);
          //       if (!isLoggedIn) {
          //         _navigateTo(Routes.LOGIN);
          //       } else {
          //         _navigateTo(Routes.HOME);
          //       }
          //     }
          //   }
          // }
          break;
        default:
          break;
      }
    });
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              splashBackgroundImage,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                splashLogoImage,
                height: 148.h,
                width: 148.w,
              ),
              SizedBox(
                height: 16.h,
              ),
              Image.asset(
                splashTextImage,
                width: 154.w,
                height: 130.h,
              ),
              // PoppinsTextWidget(
              //   text: quaidText.toUpperCase(),
              //   color: Colors.white,
              //   fontsize: 50.sp,
              //   fontWeight: FontWeight.w700,
              // ),
              // SizedBox(
              //   height: 1.h,
              // ),
              // PoppinsTextWidget(
              //   text: receptionText,
              //   color: Colors.white,
              //   fontsize: 26.sp,
              //   fontWeight: FontWeight.w400,
              // ),
              Visibility(
                visible: apiNotifier == States.LOADING,
                child: Positioned(
                  bottom: 20.h,
                  child: const SizedBox(
                    // width: _imageWidth ?? 60.w,
                    // height: MediaQuery.of(context).size.height,
                    child: SpinKitCircle(
                      color: Colors.white,
                      size: 50.0,
                    ),
                  ),
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.only(bottom: 20.h),
              //   child: Align(
              //     alignment: Alignment.bottomCenter,
              //     child: PoppinsTextWidget(
              //       text: poweredByPitb,
              //       color: Colors.white,
              //       fontsize: 20.sp,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> checkPermissions() async {
    await Permission.location.request();
    await Permission.locationAlways.request();
    await Permission.locationWhenInUse.request();
    await Permission.location.request();
  }

  _navigateTo(String routeName) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => false);
  }
}
