import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginationController {
  WidgetRef ref;
  List items;
  int pageItems;
  // int currentPage = 0;
  final currentPage = StateProvider<int>((ref) => 0);
  final hasNextPage = StateProvider<bool>((ref) => true);
  final hasPreviousPage = StateProvider<bool>((ref) => false);
  // bool hasNextPage = true;
  // bool hasPreviousPage = false;

  PaginationController({required this.items, required this.pageItems, required this.ref});

  void updatePages() {
    ref.read(hasNextPage.notifier).state = ref.read(currentPage.notifier).state+1 < (items.length / pageItems).ceil();
    ref.read(hasPreviousPage.notifier).state = ref.read(currentPage.notifier).state > 0;
  }

  void nextPage() {
    if (ref.read(hasNextPage.notifier).state) {
      ref.read(currentPage.notifier).state++;
      updatePages();
    }
  }

  void previousPage() {
    if (ref.read(hasPreviousPage.notifier).state) {
      ref.read(currentPage.notifier).state--;
      updatePages();
    }
  }
}
