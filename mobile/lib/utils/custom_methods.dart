import 'dart:developer';

import 'package:diffutil_dart/diffutil.dart' as diffutil;
import 'package:flutter/material.dart';
import 'package:flutter_base/utils/pagination_controller.dart';


void navigateToNextPage(PaginationController paginationController) {
  paginationController.nextPage();
}

void navigateToPreviousPage(PaginationController paginationController) {
  paginationController.previousPage();
}

Widget buildItem({required Widget builder}) {
  return builder;
}

void applyUpdates({required List<dynamic> oldList, required List<dynamic> newList, required Function(int, dynamic) insert, required Function(int, dynamic) remove,
  Function(int, dynamic, dynamic)? change, Function(int, int, dynamic)? move}) {
  var listDiff = diffutil.calculateListDiff(oldList, newList).getUpdatesWithData();
  for (final update in listDiff) {
    update.when(
      insert: insert,
      remove: remove,
      change: change?? (pos, oldData, newData) {
        log('change on $pos from $oldData to $newData');
      },
      move: move?? (from, to, data) {
        print('move $data from $from to $to');
      },
    );
  }
}