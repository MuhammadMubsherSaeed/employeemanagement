import 'package:flutter_base/widgets/button_widget/elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stylish_dialog/stylish_dialog.dart';

import '../../utils/colors.dart';
import '../../utils/strings.dart';

class DialogBuilder {
  final BuildContext context;
  final String? title;

  DialogBuilder(this.context, {this.title});

//   showLoadingDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//             onWillPop: () async => false,
//             child: AlertDialog(
//               shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.all(Radius.circular(8.0))),
//               backgroundColor: Colors.white,
//               content: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Padding(
//                         padding: const EdgeInsets.only(bottom: 16),
//                         child: SizedBox(
//                           child: SpinKitWave(
//                             color: lightBlueColor,
//                             size: 24.0,
//                           ),
//                         )),
//                     Padding(
//                         padding: const EdgeInsets.only(bottom: 4),
//                         child: PoppinsTextWidget(
//                           color: appBarTitleColor,
//                           fontsize: 12,
//                           textAlign: TextAlign.center,
//                           text: "Logging Out...", fontWeight: FontWeight.normal,
//                         ))
//                     // _getText(displayedText!)
//                   ]),
//             ));
//       },
//     );
//   }
//
//   hideDialog() {
//     Navigator.of(context).pop();
//   }
// }
//
// showAlertDialog(BuildContext context, String title, String content,
//     final Function? callback) {
//   // set up the AlertDialog
//   AlertDialog alert = AlertDialog(
//     title: TitleTextFields(text: title),
//     content: NormalTextField(
//       text: content,
//       fontSize: 16.sp,
//     ),
//     actions: [
//       TextButton(
//         child: TitleTextFields(
//           text: "Cancel",
//           color: appColor,
//           fontSize: 16.sp,
//         ),
//         onPressed: () {
//           callback!(0);
//         },
//       ),
//       TextButton(
//         child: TitleTextFields(
//           text: "OK",
//           color: appColor,
//           fontSize: 16.sp,
//         ),
//         onPressed: () {
//           callback!(1);
//         },
//       )
//     ],
//   );
//
//   // show the dialog
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return alert;
//     },
//   );
// }
//
// void showGenericDialog(StylishDialogType? dialogType, String content,
//     BuildContext context, Function callback) {
//   StylishDialog(
//     context: context,
//     alertType: dialogType ?? StylishDialogType.ERROR,
//     // titleText: title,
//     contentText: content,
//     dismissOnTouchOutside: false,
//     cancelButton: ElevatedButtonWithoutIcon(
//       btnText: enTextOk,
//       color: greenColor,
//       callback: () {
//         Navigator.pop(context);
//         callback();
//       },
//     ),
//   ).show();
// }

  static void showNoInternetDialog(
      String title, String content, BuildContext context, Function callback) {
    StylishDialog(
      context: context,
      alertType: StylishDialogType.ERROR,
      title: Text(title),
      content: Text(content),
      dismissOnTouchOutside: false,
      cancelButton: ElevatedButtonWithoutIcon(
        btnText: close,
        color: Colors.red,
        callback: () {
          callback();
        },
      ),
    ).show();
  }

  static void showPermissionSettingsDialog(String title, String content,
      BuildContext context, Function callback, Function cancelCallback) {
    StylishDialog(
      context: context,
      alertType: StylishDialogType.ERROR,
      title: Text(title),
      content: Text(content),
      dismissOnTouchOutside: false,
      confirmButton: ElevatedButtonWithoutIcon(
        btnText: settingsText,
        color: primaryColor,
        callback: () {
          callback();
        },
      ),
      cancelButton: ElevatedButtonWithoutIcon(
        btnText: close,
        color: Colors.red,
        callback: () {
          cancelCallback();
        },
      ),
    ).show();
  }

  static void showFakeLocationDialog(
      String title, String content, BuildContext context, Function callback) {
    StylishDialog(
      context: context,
      alertType: StylishDialogType.ERROR,
      title: Text(title),
      content: Text(content),
      dismissOnTouchOutside: false,
      cancelButton: ElevatedButtonWithoutIcon(
        btnText: close,
        color: Colors.red,
        callback: () {
          callback();
        },
      ),
    ).show();
  }

  void showPermissionDialog(
      String title, String content, BuildContext context, Function callback) {
    StylishDialog(
      context: context,
      alertType: StylishDialogType.ERROR,
      title: Text(title),
      content: Text(content),
      dismissOnTouchOutside: false,
      confirmButton: ElevatedButtonWithoutIcon(
        btnText: "Retry",
        color: redColor,
        callback: callback,
      ),
      cancelButton: ElevatedButtonWithoutIcon(
        btnText: "Close",
        color: redColor,
        callback: () {
          Navigator.pop(context);
        },
      ),
    ).show();
  }

  static void showLogoutDialog(
      {required String title,
      required String content,
      required bool isCancelable,
      required String buttonText,
      required BuildContext context,
      required Function callback}) {
    StylishDialog(
      context: context,
      // progressColor: redColor,
      alertType: StylishDialogType.WARNING,
      // titleText: title,
      content: Text(content),
      dismissOnTouchOutside: false,
      confirmButton: Center(
        child: ElevatedButtonWithoutIcon(
          btnText: buttonText,
          color: redColor,
          callback: () {
            callback();
          },
        ),
      ),

      // cancelButton: Visibility(
      //   maintainSize: false,
      //   visible: false,
      //   child: GestureDetector(
      //     onTap: () {
      //       Navigator.pop(context);
      //     },
      //     child: PoppinsTextWidget(
      //       text: close,
      //       color: redColor,
      //       fontsize: 12.sp,
      //       fontWeight: FontWeight.normal,
      //     ),
      //   ),
      // ),
    ).show();
  }

  static void showUpdateOrSessionDialog(
      {required BuildContext context,
      required String title,
      required String content,
      required String acceptButtonTitle,
      required VoidCallback onAcceptPressed,
      String? cancelButtonTitle,
      VoidCallback? onCancelledPressed,
      bool? isDismissible}) {
    showDialog(
      //show confirm dialogue
      //the return value will be from "Yes" or "No" options
      context: context,
      barrierDismissible: isDismissible ?? true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.only(
                  left: 20.w, right: 20.w, top: 16.h, bottom: 8.h),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      textStyle:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          content,
                          style: GoogleFonts.poppins(
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      (cancelButtonTitle != null)
                          ? TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                if (onCancelledPressed != null) {
                                  onCancelledPressed();
                                }
                              },
                              child: Text(
                                cancelButtonTitle,
                                style: GoogleFonts.poppins(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ),
                            )
                          : Container(),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onAcceptPressed();
                        },
                        child: Text(
                          acceptButtonTitle,
                          style: GoogleFonts.poppins(
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// void showCameraOptionsDialog({
//   required BuildContext context,
//   required VoidCallback onCameraSelect,
//   required VoidCallback onGallerySelect,
// }) {
//   showDialog(
//       context: context,
//       builder: (ctx) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: Container(
//             height: 26.h,
//             width: MediaQuery.of(context).size.width,
//             padding: EdgeInsets.symmetric(vertical: 2.h),
//             decoration: BoxDecoration(
//               color: whiteColor,
//               borderRadius: BorderRadius.circular(5),
//             ),
//             child: Column(
//               children: [
//                 TitleTextFields(
//                   text: "Choose Option",
//                   color: appDarkBlueBackgroundColor,
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w600,
//                   textAlign: TextAlign.left,
//                 ),
//                 SizedBox(
//                   height: 4.h,
//                 ),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 16.w),
//                   child: Column(
//                     children: [
//                       _imagePickerOptionButton(context, cameraImage, "Camera",
//                           () {
//                         onCameraSelect();
//                         Navigator.pop(ctx);
//                       }),
//                       SizedBox(
//                         height: 2.h,
//                       ),
//                       _imagePickerOptionButton(context, galleryImage, "Gallery",
//                           () {
//                         onGallerySelect();
//                         Navigator.pop(ctx);
//                       }),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//         );
//       });
// }
//
// Widget _imagePickerOptionButton(BuildContext context, String iconImage,
//     String title, VoidCallback onPressed) {
//   return InkWell(
//     onTap: onPressed,
//     child: Container(
//       height: 6.h,
//       width: MediaQuery.of(context).size.width,
//       decoration: BoxDecoration(
//         border: Border.all(color: lightBlueBorderColor),
//         borderRadius: BorderRadius.circular(5),
//       ),
//       padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SvgPicture.asset(
//             iconImage,
//             height: 4.h,
//             width: 8.w,
//             color: lightBlueBorderColor,
//           ),
//           SizedBox(
//             width: 4.w,
//           ),
//           TitleTextFields(
//             text: title,
//             color: appDarkBlueBackgroundColor,
//             fontSize: 16.sp,
//             fontWeight: FontWeight.w400,
//             textAlign: TextAlign.left,
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// void showImagesDialog(
//     BuildContext context, List<AlbumGallery> albumGalleryList, index) {
//   showDialog(
//       barrierColor: Colors.black87,
//       context: context,
//       builder: (ctx) {
//         return Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               height: 30.h,
//               child: GFCarousel(
//                 height: 30.h,
//                 viewportFraction: 1.0,
//                 enableInfiniteScroll: false,
//                 activeIndicator: textFieldColor,
//                 passiveIndicator: historyGreyColor,
//                 activeDotBorder: Border.all(
//                   color: whiteColor,
//                 ),
//                 hasPagination: true,
//                 items: [
//                   for (int i = 0;
//                       i < albumGalleryList[index].pictures!.length;
//                       i++)
//                     imageWidget(context, (albumGalleryList[index]).pictures![i])
//                 ],
//               ),
//             ),
//           ],
//         );
//       });
// }
//
// Widget imageWidget(BuildContext context, Pictures picture) {
//   return Container(
//     height: 30.h,
//     width: MediaQuery.of(context).size.width,
//     child: Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CachedNetworkImage(
//               imageUrl: "${picture.path!}",
//               // "",
//               imageBuilder: (context, imageProvider) {
//                 return Container(
//                   height: 30.h,
//                   width: MediaQuery.of(context).size.width - 12.w,
//                   decoration: BoxDecoration(
//                     image: DecorationImage(
//                       image: imageProvider,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 );
//               },
//               progressIndicatorBuilder: (context, url, downloadProgress) =>
//                   Container(
//                 height: 5.h,
//                 width: 5.h,
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     value: downloadProgress.progress,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ),
//               errorWidget: (context, url, error) => Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.error,
//                     ),
//                     SizedBox(
//                       height: 1,
//                     ),
//                     TitleTextFields(
//                       text: "No Image Found",
//                       color: Colors.black,
//                       fontSize: 15.sp,
//                       fontWeight: FontWeight.normal,
//                     ),
//                   ],
//                 ),
//               ),
//               fit: BoxFit.contain,
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }
//
// void showVideoDialog(BuildContext context, VideoPlayerController _controller,
//     CustomVideoPlayerController customVideoPlayerController) {
//   showDialog(
//       barrierColor: Colors.black87,
//       context: context,
//       builder: (ctx) {
//         try {
//           return Scaffold(
//             backgroundColor: Colors.black87,
//             body: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   height: MediaQuery.of(ctx).size.height - 10.h,
//                   width: MediaQuery.of(ctx).size.width,
//                   child: Column(
//                     children: [
//                       RotatedBox(
//                         quarterTurns: 1,
//                         child: _controller.value.isInitialized
//                             ? AspectRatio(
//                                 aspectRatio: _controller.value.aspectRatio,
//                                 child: Stack(
//                                   children: [
//                                     CustomVideoPlayer(
//                                         customVideoPlayerController:
//                                             customVideoPlayerController),
//                                   ],
//                                 ),
//                               )
//                             : Container(),
//                       ),
//                       SizedBox(
//                         height: 2.h,
//                       ),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           GestureDetector(
//                             onTap: () async {
//                               await _controller.dispose();
//                               Navigator.pop(ctx);
//                             },
//                             child: Container(
//                               height: 24,
//                               width: 24,
//                               decoration: BoxDecoration(
//                                 color: whiteColor,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Center(
//                                 child: Icon(
//                                   Icons.close,
//                                   color: appDarkBlueBackgroundColor,
//                                   size: 14.sp,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         } catch (ex) {
//           return Scaffold(
//             backgroundColor: Colors.black87,
//             body: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   height: MediaQuery.of(ctx).size.height - 10.h,
//                   width: MediaQuery.of(ctx).size.width,
//                   child: Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           GestureDetector(
//                             onTap: () async {
//                               await _controller.dispose();
//                               Navigator.pop(ctx);
//                             },
//                             child: Container(
//                               height: 24,
//                               width: 24,
//                               decoration: BoxDecoration(
//                                 color: whiteColor,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Center(
//                                 child: Icon(
//                                   Icons.close,
//                                   color: appDarkBlueBackgroundColor,
//                                   size: 14.sp,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           TitleTextFields(
//                             text: "Unable to Play Video",
//                             color: whiteColor,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//       });
}
