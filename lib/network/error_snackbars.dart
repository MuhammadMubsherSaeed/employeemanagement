import 'package:flutter/material.dart';

class ErrorSnackbars {
  static showInternetConnectError(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    const snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        "Please Check your Internet Connection!",
        textScaleFactor: 1.0,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static showNoDataFound(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    const snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        "No Record found!",
        textScaleFactor: 1.0,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static showServerError(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    const snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        "Application cannot able to connect with Server!",
        textScaleFactor: 1.0,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static showTokenExpired(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    const snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        "User Unauthentic, Re-login the Application!",
        textScaleFactor: 1.0,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    // LoginScreenFunctions.navigateToLoginScreen(context);
  }

  static showCustomSnackBar(BuildContext context, String msg, Color? color) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackBar = SnackBar(
      backgroundColor: color,
      content: Text(
        msg,
        textScaleFactor: 1.0,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
