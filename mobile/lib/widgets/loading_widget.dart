import 'package:flutter/material.dart';
import 'package:flutter_base/models/states.dart';
import 'package:flutter_base/widgets/poppins_text_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../providers/api_auth_notifier.dart';
import '../../utils/colors.dart';
import '../../utils/strings.dart';

class LoadingWidget extends ConsumerStatefulWidget {
  const LoadingWidget({
    super.key,
  });

  @override
  LoadingWidgetState createState() => LoadingWidgetState();
}

class LoadingWidgetState extends ConsumerState<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  Widget build(BuildContext context) {
    final apiNotifier = ref.watch(apiAuthNotifierProvider);
    return Visibility(
      visible: apiNotifier.states == States.LOADING,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                  child: Column(children: [
                    SpinKitCircle(
                      color: primaryColor,
                      size: 60.0,
                      controller: animationController,
                    ),
                    SizedBox(height: 5.h),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        child: PoppinsTextWidget(
                          text: loading,
                          fontsize: 20.sp,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    )
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  dispose() {
    animationController.dispose(); // you need this
    super.dispose();
  }
}
