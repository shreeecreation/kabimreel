import 'package:flutter_riverpod/flutter_riverpod.dart';

class LikeNotifier extends StateNotifier<Map<int, bool>> {
  LikeNotifier() : super({});

  void toggleLike(int index) {
    state = {
      ...state,
      index: !(state[index] ?? false),
    };
  }
}

final likeProvider = StateNotifierProvider<LikeNotifier, Map<int, bool>>((ref) {
  return LikeNotifier();
});
