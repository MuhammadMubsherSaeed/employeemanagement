import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base/models/response/sync/SyncResponse.dart';
import 'package:flutter_base/models/states.dart';
import 'package:flutter_base/providers/api_auth_notifier.dart';
import 'package:flutter_base/route/routes.dart';
import 'package:flutter_base/utils/custom_methods.dart';
import 'package:flutter_base/utils/image_assets.dart';
import 'package:flutter_base/utils/strings.dart';
import 'package:flutter_base/utils/utils.dart';
import 'package:flutter_base/widgets/button_widget/customizable_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/colors.dart';

class DiffUtillScreen extends ConsumerStatefulWidget {
  const DiffUtillScreen({super.key});

  @override
  ConsumerState<DiffUtillScreen> createState() => DiffUtillScreenState();
}

class DiffUtillScreenState extends ConsumerState<DiffUtillScreen> {

  final oldList = StateProvider<List<int>>((ref) => [1, 2, 3]);
  final newList = StateProvider<List<int> >((ref) => [2, 4, 3, 5, 6]);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final apiNotifier = ref.watch(apiAuthNotifierProvider);
    // ref.listen(apiAuthNotifierProvider, (previous, apiStatesModel) async {
    //   switch (apiStatesModel.states) {
    //     case States.APPUPDATE:
    //       if (apiStatesModel.data is SyncResponse) {
    //         final response = apiStatesModel.data as SyncResponse;
    //         if ((response.version?.isForceUpdate ?? 0) == 1) {
    //           DialogBuilder.showUpdateOrSessionDialog(
    //             context: context,
    //             title: "Update",
    //             content: response.version?.dialogeMessage ?? "",
    //             acceptButtonTitle: "OK",
    //             onAcceptPressed: () {},
    //             isDismissible: false,
    //           );
    //         } else {
    //           DialogBuilder.showUpdateOrSessionDialog(
    //             context: context,
    //             title: "Update",
    //             content: response.version?.dialogeMessage ?? "",
    //             acceptButtonTitle: "OK",
    //             cancelButtonTitle: "Not now",
    //             onAcceptPressed: () {},
    //             onCancelledPressed: () {},
    //             isDismissible: false,
    //           );
    //         }
    //       }
    //       break;
    //
    //     case States.SESSIONEXPIRED:
    //       DialogBuilder.showUpdateOrSessionDialog(
    //         context: context,
    //         title: sessionExpiredText,
    //         content: sessionExpiredContent,
    //         acceptButtonTitle: "OK",
    //         onAcceptPressed: () {},
    //         isDismissible: false,
    //       );
    //       break;
    //     case States.ERROR:
    //       // DialogBuilder.showNoInternetDialog(
    //       //     textSyncFailed, apiStatesModel.message, context, () {
    //       //   Navigator.pop(context);
    //       //   SystemNavigator.pop();
    //       // });
    //       // print(apiStatesModel.message);
    //       await Utils.setIsDownload(true);
    //       bool isLoggedIn = await Utils.getIsLoggedIn();
    //       print(isLoggedIn);
    //       if (!isLoggedIn) {
    //         _navigateTo(Routes.LOGIN);
    //       } else {
    //         _navigateTo(Routes.HOME);
    //       }
    //       break;
    //     case States.DATA:
    //       // if (apiStatesModel.data is SyncResponse) {
    //       //   final _response = apiStatesModel.data as SyncResponse;
    //       //   if (!(_response).success!) {
    //       //     if (_response.statusCode == 400) {
    //       //       DialogBuilder.showLogoutDialog(
    //       //         title: "Session Expired",
    //       //         content: sessionExpiredText,
    //       //         isCancelable: false,
    //       //         buttonText: "OK",
    //       //         context: context,
    //       //         callback: () async {
    //       //           await ref.read(authRepository).removeAllData();
    //       //           Navigator.pushNamedAndRemoveUntil(
    //       //               context, Routes.LOGIN, (route) => false);
    //       //         },
    //       //       );
    //       //     }
    //       //   } else {
    //       //     if (_response.data != null) {
    //       //       // await checkPermissions();
    //       //       await Utils.setIsDownload(true);
    //       //       bool isLoggedIn = await Utils.getIsLoggedIn();
    //       //       print(isLoggedIn);
    //       //       if (!isLoggedIn) {
    //       //         _navigateTo(Routes.LOGIN);
    //       //       } else {
    //       //         _navigateTo(Routes.HOME);
    //       //       }
    //       //     } else {
    //       //       await Utils.setIsDownload(true);
    //       //       bool isLoggedIn = await Utils.getIsLoggedIn();
    //       //       print(isLoggedIn);
    //       //       if (!isLoggedIn) {
    //       //         _navigateTo(Routes.LOGIN);
    //       //       } else {
    //       //         _navigateTo(Routes.HOME);
    //       //       }
    //       //     }
    //       //   }
    //       // }
    //       break;
    //     default:
    //       break;
    //   }
    // });
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Diff Utill"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[



            Text("old list ${ref.watch(oldList)}"),
            Text("new list ${ref.watch(newList)}"),
            SizedBox(height: 10,),

            Padding(
              padding: EdgeInsets.all(10),
                child:CustomizableTextButton(
              prefixButtonIcon: null,
              suffixButtonIcon: null,
              isFullWidth: true,
              isOutlined: false,
              buttonTitle: diffUtil,
              onPressed: () {
                log("//test diff before add new data $newList and old is $oldList ");
                applyUpdates(oldList: ref.read(oldList.notifier).state, newList: ref.read(newList.notifier).state, insert: (pos, data) {
                  ref.read(oldList.notifier).state.insert(pos, data);
                  setState(() {

                  });
                }, remove: (pos, data) {
                  ref.read(oldList.notifier).state.removeAt(pos);
                  setState(() {

                  });
                },);
                log("//test diff after add new data ${ref.read(newList.notifier).state} and old is ${ref.read(oldList.notifier).state} test");
              },
              buttonTitleStyle: TextStyle(
                fontSize: 16.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              buttonBorderRadius: 10,
              buttonColor: primaryColor,
            )),
          ],
        ),
      ),
    );
  }

}


class Item {
  final String id;
  final String name;

  Item({required this.id, required this.name});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
    );
  }
}