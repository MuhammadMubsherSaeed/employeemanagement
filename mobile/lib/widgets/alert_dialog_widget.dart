// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_base/widgets/poppins_text_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AlertDialogWidget extends ConsumerStatefulWidget {
  String title;
  Widget contentWidget;
  Widget? actionsWidget;
  AlertDialogWidget(
      {super.key,
      required this.title,
      required this.contentWidget,
      required this.actionsWidget});

  @override
  AlertDialogWidgetState createState() => AlertDialogWidgetState();
}

class AlertDialogWidgetState extends ConsumerState<AlertDialogWidget> {
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return AlertDialog(
          backgroundColor: Colors.white,
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          title: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20))),
              child: Padding(
                padding: EdgeInsets.only(top: 15.h, bottom: 15.h, right: 20.w),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 30.w, right: 30.w),
                      child: Align(
                        alignment: Alignment.center,
                        child: PoppinsTextWidget(
                            fontsize: 25.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            textAlign: TextAlign.center,
                            text: widget.title),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: const Icon(
                              Icons.close,
                            ),
                          )),
                    ),
                  ],
                ),
              )),
          content: widget.contentWidget,
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            (widget.actionsWidget != null)
                ? widget.actionsWidget!
                : Container(),
          ],
        );
      },
    );
  }
}

// void showNoInternetDialog(
//     String title, String content, BuildContext context, Function callback) {
//   StylishDialog(
//     context: context,
//     alertType: StylishDialogType.ERROR,
//     titleText: title,
//     contentText: content,
//     dismissOnTouchOutside: false,
//     cancelButton: ElevatedButtonWithoutIcon(
//       btnText: context.loc?.text_close ?? UIUtils.checkNullString(false),
//       color: appColor,
//       callback: () {
//         callback();
//       },
//     ),
//   ).show();
// }
