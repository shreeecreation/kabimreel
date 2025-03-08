import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'video_repository.dart';

final videoProvider = FutureProvider<List<String>>((ref) async {
  return await VideoRepository().getVideos();
});
