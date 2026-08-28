import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base/theme.dart';
import 'package:flutter_base/utils/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomizableTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final FocusNode focusNode;
  final String Function(String?)? validator;
  final Function(String) onChanged;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color focusedIconColor;
  final Color unfocusedIconColor;
  final bool hideText;
  VoidCallback? onSuffixIconPressed;
  final bool readOnly;
  Widget? prefixWidget;
  Widget? suffixWidget;
  TextInputType? textInputType;
  Function(String)? onFieldSubmit;
  EdgeInsetsGeometry? prefixPadding;
  EdgeInsetsGeometry? suffixPadding;
  List<TextInputFormatter>? inputFormatters;

  CustomizableTextField({super.key, 
    required this.controller,
    required this.hintText,
    required this.focusNode,
    required this.validator,
    required this.onChanged,
    required this.prefixIcon,
    required this.suffixIcon,
    required this.focusedIconColor,
    required this.unfocusedIconColor,
    required this.hideText,
    this.onSuffixIconPressed,
    this.readOnly = false,
    this.prefixWidget,
    this.suffixWidget,
    this.textInputType,
    this.onFieldSubmit,
    this.prefixPadding,
    this.suffixPadding,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: hideText,
      keyboardType: textInputType,
      decoration: InputDecoration(
        contentPadding:
            EdgeInsets.only(left: 0.w, right: 20.w, top: 18.h, bottom: 18.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.sp),
          borderSide: const BorderSide(
            color: colorPrimary13,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.sp),
          borderSide: const BorderSide(
            color: colorPrimary13,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.sp),
          borderSide: const BorderSide(
            color: headingColor,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.sp),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        errorStyle: GoogleFonts.poppins(
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 0,
                fontSize: 16.sp,
              ),
        ),
        prefixIcon: prefixWidget != null
            ? Container(
                padding: prefixPadding ??
                    EdgeInsets.only(
                      top: 16.h,
                      bottom: 16.h,
                      left: 20.w,
                      right: 10.w,
                    ),
                child: prefixWidget)
            : prefixIcon == null
                ? const SizedBox(
                    width: 1,
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Icon(
                      prefixIcon,
                      color: (focusNode.hasFocus)
                          ? focusedIconColor
                          : unfocusedIconColor,
                    ),
                  ),
        suffixIcon: (suffixWidget != null)
            ? Container(
                padding: suffixPadding ??
                    EdgeInsets.only(
                      top: 16.h,
                      bottom: 16.h,
                      left: 20.w,
                      right: 10.w,
                    ),
                child: suffixWidget,
              )
            : suffixIcon == null
                ? null
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: InkWell(
                      onTap: onSuffixIconPressed,
                      child: Icon(
                        suffixIcon,
                        color: unfocusedIconColor,
                      ),
                    ),
                  ),
        filled: true,
        fillColor: (focusNode.hasFocus) ? Colors.black : Colors.white,
        focusColor: Colors.black,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hintColor,
                fontSize: 16.sp,
              ),
        ),
      ),
      cursorWidth: 2.w,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmit,
      cursorColor: Colors.green,
      style: GoogleFonts.poppins(
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black,
              fontSize: 16.sp,
            ),
      ),
    );
  }
}
