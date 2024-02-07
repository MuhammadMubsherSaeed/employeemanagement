
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ElevatedButtonWithIcon extends StatefulWidget {
  final Function? callback;
  final Color? color;
  final Color? textColor;
  final String? btnText;
  final IconData? icons;

  const ElevatedButtonWithIcon(
      {super.key,
      required this.callback,
      required this.color,
      this.textColor,
      required this.btnText,
      this.icons});

  @override
  _ElevatedButtonWithIconState createState() => _ElevatedButtonWithIconState();
}

class _ElevatedButtonWithIconState extends State<ElevatedButtonWithIcon> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: TextButton(
          style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              backgroundColor: MaterialStateProperty.all<Color>(widget.color!),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      side: BorderSide(color: Colors.transparent)))),
          onPressed: () {
            widget.callback!();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                  alignment: Alignment.center,
                  child: Text(widget.btnText!,

                      style: TextStyle(fontSize: 14.sp,color: widget.textColor??Colors.white))),
              Align(
                alignment: Alignment.centerRight,
                child: widget.icons != null ? Icon(
                  widget.icons,
                  color: Colors.white,
                  size: 20.h,
                ):Container(),
              ),
            ],
          )),
    );
  }
}
