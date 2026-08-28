// ignore_for_file: must_be_immutable, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base/utils/colors.dart';
import 'package:flutter_base/utils/strings.dart';
import 'package:flutter_base/widgets/poppins_text_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TitleTextFormFieldWidget extends ConsumerStatefulWidget {
  String title;
  var filteringTextInputFormatter;
  TextInputType textInputType;
  TextEditingController textEditingController;
  String hint;
  bool? readOnly;
  Color? textFieldBackgroundColor;
  int? maxLines;
  FocusNode? focusNode;
  String? Function(String?)? onValidate;
  TitleTextFormFieldWidget(
      {super.key,
      required this.title,
      required this.textEditingController,
      required this.hint,
      required this.filteringTextInputFormatter,
      required this.textInputType,
      this.textFieldBackgroundColor,
      this.maxLines,
      this.readOnly,
      this.focusNode,
      this.onValidate});

  @override
  TitleTextFormFieldWidgetState createState() =>
      TitleTextFormFieldWidgetState();
}

class TitleTextFormFieldWidgetState
    extends ConsumerState<TitleTextFormFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Visibility(
          visible: (widget.title != ""),
          child: Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: PoppinsTextWidget(
              fontsize: 20.sp,
              fontWeight: FontWeight.w500,
              color: textColor2,
              text: widget.title,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 5.h),
          child: TextFormField(
            controller: widget.textEditingController,
            focusNode: widget.focusNode,
            validator: widget.onValidate ?? (value) {
                    if (value!.isEmpty) {
                      return fieldEmpty;
                    }
                    return null;
                  },
            style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black),
            keyboardType: widget.textInputType,
            inputFormatters: [
              widget.filteringTextInputFormatter,
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9+\- _]*"))
            ],
            maxLines: widget.maxLines ?? 1,
            decoration: InputDecoration(
              fillColor: (widget.textFieldBackgroundColor != null)
                  ? widget.textFieldBackgroundColor
                  : Colors.white,
              filled: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
              hintText: widget.hint,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w300,
                  color: hintColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: textFieldBorderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: textFieldBorderColor,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: redColor,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: redColor,
                ),
              ),
            ),
            readOnly: widget.readOnly ?? false,
          ),
        ),
      ],
    );
  }
}
