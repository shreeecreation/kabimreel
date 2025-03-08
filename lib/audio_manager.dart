import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<String> mergeAudioWithVideo(String audioPath, String videoPath) async {
  try {
    String outputPath =
        '${(await getApplicationDocumentsDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
    String command =
        '-i ${videoPath} -i ${audioPath} -filter_complex "[0:a][1:a]amix=inputs=2:duration=first" -c:v copy -c:a aac $outputPath';
    print("📌 Running FFmpeg command: $command");
    final session = await FFmpegKit.execute(command);
    final returnedCode = await session.getReturnCode();
    if (returnedCode?.getValue() == 0) {
      // Merge successful, update the video controller with the new file
      return outputPath;
    } else {
      return '';
    }
  } catch (e) {
    print('🚨 Error merging audio with video: $e');
    return '';
  }
}
