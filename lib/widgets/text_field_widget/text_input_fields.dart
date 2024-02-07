import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_base/widgets/poppins_text_widget.dart';

import '../../utils/colors.dart';

// ignore: must_be_immutable
class TextInputFields extends ConsumerWidget {
  final String? hintText;
  bool? isEnable = true;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? inputType;
  final TextInputAction? inputAction;
  final ValueChanged<String>? valueChanged;
  final Widget? suffixWidget;
  final Widget? prefixWidget;
  final Color? hintColor;
  final int? lengthLimit;
  int? maxLines;
  bool? readOnly;
  String? title;

  TextInputFields(
      {super.key,
      this.title,
      this.hintText,
      this.isEnable,
      this.controller,
      this.validator,
      this.valueChanged,
      this.inputType,
      this.inputAction,
      this.suffixWidget,
      this.prefixWidget,
      this.lengthLimit,
      this.maxLines,
      this.hintColor,
      this.readOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Visibility(
          visible: title != null,
          child: PoppinsTextWidget(
            fontsize: 16.sp,
            fontWeight: FontWeight.w500,
            color: textColor2,
            text: title ?? "",
          ),
        ),
        SizedBox(
          height: 8.h,
        ),
        TextFormField(
          enabled: isEnable,
          controller: controller,
          autocorrect: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          textAlignVertical: TextAlignVertical.center,
          validator: validator,
          keyboardType: inputType,
          textInputAction: inputAction,
          style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.black),
          inputFormatters: [
            LengthLimitingTextInputFormatter(lengthLimit ?? 50)
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(width: 1, color: Colors.red.shade400)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(width: 1.w, color: textFieldBorderColor)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(width: 1.w, color: textFieldBorderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(width: 1.w, color: textFieldBorderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(width: 1.w, color: textFieldBorderColor)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(width: 1.w, color: Colors.red.shade400)),
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: hintColor ?? textFieldBorderColor),
            errorStyle: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: Colors.red.shade400),
            suffixIcon: suffixWidget,
            prefixIcon: prefixWidget,
          ),
          maxLines: maxLines ?? 1,
          readOnly: readOnly ?? false,
          onChanged: valueChanged,
        ),
      ],
    );
  }
}
