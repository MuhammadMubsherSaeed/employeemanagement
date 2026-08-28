import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_base/models/response/sync/SyncResponse.dart';
import 'package:flutter_base/models/states.dart';
import 'package:flutter_base/providers/api_auth_notifier.dart';
import 'package:flutter_base/route/routes.dart';
import 'package:flutter_base/utils/custom_methods.dart';
import 'package:flutter_base/utils/image_assets.dart';
import 'package:flutter_base/utils/strings.dart';
import 'package:flutter_base/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_base/utils/pagination_controller.dart';

import '../../widgets/dialog_widget/dialog_widget.dart';

final itemsList = StateProvider<List>((ref) => []);

class PaginationScreen extends ConsumerStatefulWidget {
  const PaginationScreen({super.key});

  @override
  ConsumerState<PaginationScreen> createState() => PaginationScreenState();
}

class PaginationScreenState extends ConsumerState<PaginationScreen> {
  // final apiNotifier = ref.watch(apiAuthNotifierProvider);

  late PaginationController _paginationController;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _paginationController = PaginationController(
        items: ref.read(itemsList.notifier).state, pageItems: 25, ref: ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeItemsList();

      _paginationController.updatePages();
    });
  }

  void initializeItemsList() {
    // Generate items list and notify listeners
    var items =
        List.generate(500, (index) => Item(id: '$index', name: 'Item $index'));
    ref.read(itemsList.notifier).state = items;
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
        title: const Text("Pagination"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemCount: _paginationController.pageItems,
                itemBuilder: (context, index) {
                  int itemIndex = ref.watch(_paginationController.currentPage) *
                          _paginationController.pageItems +
                      index;
                  if (itemIndex < _paginationController.items.length) {
                    return Card(
                        child: Text(ref.watch(itemsList)[itemIndex].name));
                  } else {
                    return const SizedBox
                        .shrink(); // Return an empty widget if there's no item
                  }
                },
              ),
            ),

            // Expanded(
            //   child: buildItem(builder: (index) => ListTile(title: Text(_paginationController.items[index].name)), index: _paginationController.pageItems, paginationController: _paginationController),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                !ref.watch(_paginationController.hasPreviousPage)
                    ? const SizedBox()
                    : IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          navigateToPreviousPage(_paginationController);
                        },
                      ),
                !ref.watch(_paginationController.hasNextPage)
                    ? const SizedBox()
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          navigateToNextPage(_paginationController);
                        },
                        // disabled:,
                      ),
              ],
            ),
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
