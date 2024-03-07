import 'package:flutter/material.dart';
import 'package:flutter_base/widgets/poppins_text_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ElevatedButtonWithoutIcon extends StatefulWidget {
  final Function callback;
  final Color? color;
  final String? btnText;
  final String? textColor;
  final double? textSize;

  const ElevatedButtonWithoutIcon({
    super.key,
    required this.callback,
    required this.color,
    required this.btnText,
    this.textColor,
    this.textSize,
  });

  @override
  _ElevatedButtonWithoutIconState createState() =>
      _ElevatedButtonWithoutIconState();
}

class _ElevatedButtonWithoutIconState extends State<ElevatedButtonWithoutIcon> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            backgroundColor: MaterialStateProperty.all<Color>(widget.color!),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    side: BorderSide(color: Colors.transparent)))),
        onPressed: () {
          widget.callback();
        },
        child: Center(
            child: PoppinsTextWidget(
          text: widget.btnText!,
          fontsize: widget.textSize ?? 16.sp,
          color: widget.textColor == null ? Colors.white : Colors.black,
          fontWeight: FontWeight.normal,
        )));
  }
}
