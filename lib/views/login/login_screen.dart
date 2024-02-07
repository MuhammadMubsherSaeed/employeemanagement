
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base/models/response/login_response/LoginResponse.dart';
import 'package:flutter_base/models/states.dart';
import 'package:flutter_base/providers/api_auth_notifier.dart';
import 'package:flutter_base/route/routes.dart';
import 'package:flutter_base/utils/colors.dart';
import 'package:flutter_base/utils/image_assets.dart';
import 'package:flutter_base/utils/strings.dart';
import 'package:flutter_base/utils/utils.dart';
import 'package:flutter_base/widgets/button_widget/customizable_button.dart';
import 'package:flutter_base/widgets/dialog_widget/dialog_widget.dart';
import 'package:flutter_base/widgets/loading_widget.dart';
import 'package:flutter_base/widgets/poppins_text_widget.dart';
import 'package:flutter_base/widgets/text_field_widget/customizable_textfield.dart';
import 'package:flutter_base/widgets/text_field_widget/text_input_fields.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = MaskedTextController(mask: "0000-0000000");
  final passwordController = MaskedTextController(mask: "0000-0000000");
  final usernameFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  onFocusChange() {
    if (usernameFocusNode.hasFocus || passwordFocusNode.hasFocus) {
      // ref.read(LoginProvieder.scrollPhysiscProvider.notifier).state = true;
    } else {
      // ref.read(LoginProvieder.scrollPhysiscProvider.notifier).state = false;
    }
  }

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    usernameFocusNode.removeListener(() {
      onFocusChange();
      usernameFocusNode.dispose();
    });

    passwordFocusNode.removeListener(() {
      onFocusChange();
      passwordFocusNode.dispose();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ApiStatesModel>(apiAuthNotifierProvider,
        (previous, apiStatesModel) {
      switch (apiStatesModel.states) {
        case States.ERROR:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(apiStatesModel.message),
          ));
          break;
        case States.DATA:
          if (apiStatesModel.data is LoginResponse) {
            final response = apiStatesModel.data as LoginResponse;
            if (!(response).success!) {
              if (response.statusCode == 700) {
                Utils.showUpdateDialog(
                    message: response.message ?? "Please Update your app",
                    context: context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(apiStatesModel.message),
                ));
              }
            } else {
              if (response.data != null) {
                if (response.data!.username != null) {
                  if (response.data!.otpVerificationRequired == 1) {
                    print('My OTp: ${response.data?.otpCode.toString()}');
                    // Navigator.of(context).pushNamed(Routes.OTP);
                  } else {
                    Utils.setIsLoggedIn(true);
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(Routes.HOME, (route) => false);
                  }
                } else {
                  // Fluttertoast.showToast(
                  //     msg: _response.message!, toastLength: Toast.LENGTH_SHORT);
                }
              } else {
                // Fluttertoast.showToast(
                //     msg: "Data not found.", toastLength: Toast.LENGTH_SHORT);
              }
            }
          }
          break;
        case States.SESSIONEXPIRED:
          DialogBuilder.showLogoutDialog(
            title: sessionExpiredText,
            content: sessionExpiredContent,
            isCancelable: false,
            buttonText: "OK",
            context: context,
            callback: () {},
          );
          break;
        default:
          break;
      }
    });
    return Stack(
      children: [
        _mainLayout(),
        const LoadingWidget(),
      ],
    );
  }

  Widget _mainLayout() {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    SizedBox(
                      height: 38.h,
                    ),
                    Image.asset(
                      splashLogoImage,
                      height: 148.h,
                      width: 148.w,
                    ),
                    SizedBox(
                      height: 18.h,
                    ),
                    PoppinsTextWidget(
                      fontsize: 24.sp,
                      fontWeight: FontWeight.w500,
                      color: textColor1,
                      text: "Welcome to",
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: appName,
                            style: GoogleFonts.poppins(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 64.h,
                    ),
                    TextInputFields(
                      title: mobileNumberText,
                      hintText: "03xx-xxxxxxx",
                      isEnable: true,
                      controller: usernameController,
                      validator: (value) {
                        if (value!.length < 12) {
                          return "Enter correct mobile number";
                        } else {
                          return null;
                        }
                      },
                      valueChanged: (value) =>
                          ref.read(phoneLoginProvider.notifier).state = value,
                      inputType: TextInputType.number,
                      inputAction: TextInputAction.done,
                      prefixWidget: const Icon(
                        Icons.quick_contacts_mail_rounded,
                        color: primaryColor,
                      ),
                      hintColor: hintColor,
                    ),
                    SizedBox(
                      height: 12.h,
                    ),
                    CustomizableTextField(
                      controller: usernameController,
                      hintText: "03xx-xxxxxxx",
                      focusNode: FocusNode(),
                      validator: (value) {
                        return "";
                      },
                      onChanged: (value) {},
                      prefixIcon: null,
                      suffixIcon: null,
                      prefixWidget: const Icon(
                        Icons.quick_contacts_mail_rounded,
                        color: primaryColor,
                      ),
                      //Prefix Widget != null
                      prefixPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 16.h,
                      ),
                      suffixPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 16.h,
                      ),
                      focusedIconColor: Colors.black,
                      unfocusedIconColor: Colors.grey,
                      hideText: false,
                      textInputType: TextInputType.number,
                    ),
                    CustomizableTextField(
                      controller: usernameController,
                      hintText: "03xx-xxxxxxx",
                      focusNode: FocusNode(),
                      validator: (value) {
                        return "";
                      },
                      onChanged: (value) {},
                      prefixIcon: null,
                      suffixIcon: null,
                      prefixWidget: const Icon(
                        Icons.lock,
                        color: primaryColor,
                      ),
                      suffixWidget: InkWell(
                          onTap: () {},
                          child: const Icon(
                            Icons.remove_red_eye_sharp,
                            color: Colors.grey,
                          )),
                      //if using suffixIcon than use code below for onclick
                      // onSuffixIconPressed: ,
                      //Prefix Widget != null
                      prefixPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 16.h,
                      ),
                      suffixPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 16.h,
                      ),
                      focusedIconColor: Colors.black,
                      unfocusedIconColor: Colors.grey,
                      hideText: true,
                      textInputType: TextInputType.number,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 18.h,
                              width: 18.h,
                              decoration: BoxDecoration(
                                border: Border.all(color: primaryColor),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.check,
                                  color: primaryColor,
                                  size: 14.sp,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8.w,
                            ),
                            PoppinsTextWidget(
                              fontsize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: textColor3,
                              text: rememberMeText,
                            ),
                          ],
                        ),
                        PoppinsTextWidget(
                          fontsize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: textColor3,
                          text: forgotPassword,
                        ),
                      ],
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 40.h,
                      ),
                    ),
                    CustomizableTextButton(
                      prefixButtonIcon: null,
                      suffixButtonIcon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                      isFullWidth: true,
                      isOutlined: false,
                      buttonTitle: signIn,
                      onPressed: () async {
                        DialogBuilder.showUpdateOrSessionDialog(
                          context: context,
                          title: "Session Expired",
                          content:
                              "Your session has been expired please login again",
                          acceptButtonTitle: "OK",
                          onAcceptPressed: () {},
                          cancelButtonTitle: "Not now",
                          onCancelledPressed: () {},
                        );
                      },
                      buttonTitleStyle: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      buttonBorderRadius: 10,
                      buttonColor: primaryColor,
                    ),
                    CustomizableTextButton(
                      prefixButtonIcon: null,
                      suffixButtonIcon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.black,
                      ),
                      isFullWidth: false,
                      isOutlined: true,
                      buttonTitle: signIn,
                      onPressed: () async {
                        // print(await FirebaseMessaging.instance.getToken());
                        await Utils.isAllPermissionsGranted();
                        if (formKey.currentState!.validate()) {}
                      },
                      buttonTitleStyle: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      buttonBorderRadius: 10,
                      buttonColor: primaryColor,
                    ),
                    Row(
                      children: [
                        CustomizableTextButton(
                          suffixButtonIcon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                          ),
                          isFullWidth: false,
                          isOutlined: true,
                          buttonTitle: null,
                          onPressed: () async {
                            // print(await FirebaseMessaging.instance.getToken());
                            await Utils.isAllPermissionsGranted();
                            if (formKey.currentState!.validate()) {}
                          },
                          buttonTitleStyle: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          buttonBorderRadius: 10,
                          buttonColor: primaryColor,
                        ),
                        SizedBox(
                          width: 10.w,
                        ),
                        CustomizableTextButton(
                          suffixButtonIcon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                          isFullWidth: false,
                          isOutlined: false,
                          buttonTitle: null,
                          onPressed: () async {
                            // print(await FirebaseMessaging.instance.getToken());
                            FirebaseCrashlytics.instance.crash();
                          },
                          buttonTitleStyle: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          buttonBorderRadius: 10,
                          buttonColor: primaryColor,
                        ),
                      ],
                    ),
                    CustomizableTextButton(
                      prefixButtonIcon: Icon(
                        Icons.home_outlined,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      isFullWidth: false,
                      isOutlined: false,
                      buttonTitle: signIn,
                      onPressed: () async {
                        // print(await FirebaseMessaging.instance.getToken());
                        await Utils.isAllPermissionsGranted();
                        if (formKey.currentState!.validate()) {}
                      },
                      buttonTitleStyle: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      buttonBorderRadius: 10,
                      buttonColor: primaryColor,
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    CustomizableTextButton(
                      prefixButtonIcon: null,
                      suffixButtonIcon: null,
                      isFullWidth: true,
                      isOutlined: false,
                      buttonTitle: registerText,
                      onPressed: () {
                        Navigator.of(context).pushNamed(Routes.REGISTER);
                      },
                      buttonTitleStyle: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      buttonBorderRadius: 10,
                      buttonColor: primaryColor,
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     PoppinsTextWidget(
                    //       fontsize: 18.sp,
                    //       fontWeight: FontWeight.w400,
                    //       color: textColor5,
                    //       text: dontHaveAnAccountText,
                    //     ),
                    //     InkWell(
                    //       onTap: () {
                    //         ref.invalidate(divisionValueProvider);
                    //         ref.invalidate(districtValueProvider);
                    //         ref.invalidate(tehsilValueProvider);
                    //         ref.invalidate(ucsValueProvider);
                    //         ref.invalidate(ppValueProvider);
                    //         Navigator.of(context).pushNamed(Routes.SIGNUP);
                    //       },
                    //       child: PoppinsTextWidget(
                    //         fontsize: 18.sp,
                    //         fontWeight: FontWeight.w500,
                    //         color: primaryColor,
                    //         text: registerText,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(
                      height: 24.h,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
