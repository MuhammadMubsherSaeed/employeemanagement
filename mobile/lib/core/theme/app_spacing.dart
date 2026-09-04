import 'package:flutter/material.dart';

export 'package:flutter_base/core/theme/app_radius.dart';
export 'package:flutter_base/core/theme/app_shadows.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double mdLg = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xl2 = 40;
  static const double xxl = 48;

  static const EdgeInsets screen = EdgeInsets.all(md);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(md, sm, md, lg);
  static const EdgeInsets listGap = EdgeInsets.only(bottom: sm);
}
