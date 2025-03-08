import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kabimreel/audio_manager.dart';
import 'package:video_trimmer/video_trimmer.dart';

// Riverpod provider for Trimmer state
final videoTrimmerProvider =
    StateNotifierProvider<VideoTrimmerNotifier, Trimmer>((ref) {
  return VideoTrimmerNotifier();
});

class VideoTrimmerNotifier extends StateNotifier<Trimmer> {
  VideoTrimmerNotifier() : super(Trimmer());

  Future<void> loadVideo(String videoPath) async {
    if (videoPath.isNotEmpty && File(videoPath).existsSync()) {
      print("📌 Loading video: $videoPath");
      // state.currentVideoFile = File(videoPath);
      await state.loadVideo(videoFile: File(videoPath));
      print("📌 Loaded video: $videoPath");


    } else {
      print("⚠️ File does not exist: $videoPath");
    }
  }
}

// State provider to track merged video path
final mergedVideoPathProvider = StateProvider<String?>((ref) => null);

class TrimmerView extends ConsumerStatefulWidget {
  final File file;
  const TrimmerView({super.key, required this.file});

  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends ConsumerState<TrimmerView> {
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    super.initState();
    ref.read(videoTrimmerProvider.notifier).loadVideo(widget.file.path);
  }

  Future<void> _saveVideo() async {
    setState(() => _progressVisibility = true);

    await ref.read(videoTrimmerProvider).saveTrimmedVideo(
          startValue: _startValue,
          endValue: _endValue,
          onSave: (String? value) {
            setState(() => _progressVisibility = false);
            if (value != null) {
              Navigator.of(context).pop(value);
            }
          },
        );
  }

  Future<void> _mergeAudio() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      String audioPath = result.files.single.path!;
      print("🎵 Selected Audio: $audioPath");

      // Await the completion of merging
      String outputFile =
          await mergeAudioWithVideo(audioPath, widget.file.path);

      // Delay to ensure UI updates smoothly
      await Future.delayed(Duration(milliseconds: 500));

      await ref.read(videoTrimmerProvider.notifier).loadVideo(outputFile);

      setState(() {
        _startValue = 0.0;
        _endValue = 1.0;
        _progressVisibility = false;
      });
    }
  }

// Wait until the file is actually created (Polling Mechanism)
  Future<bool> _waitForFile(String filePath, {int retries = 10}) async {
    int attempts = 0;
    while (attempts < retries) {
      if (File(filePath).existsSync()) {
        return true;
      }
      await Future.delayed(Duration(milliseconds: 300)); // Small delay
      attempts++;
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
    ref.read(videoTrimmerProvider).dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmer = ref.watch(videoTrimmerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _progressVisibility ? null : _saveVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Next",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progressVisibility)
            LinearProgressIndicator(backgroundColor: Colors.red),
          Expanded(child: VideoViewer(trimmer: trimmer)),
          TextButton(
            child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                size: 50.0, color: Colors.white),
            onPressed: () async {
              bool playbackState = await trimmer.videoPlaybackControl(
                  startValue: _startValue, endValue: _endValue);
              setState(() => _isPlaying = playbackState);
            },
          ),
          TrimViewer(
            trimmer: trimmer,
            viewerHeight: 50.0,
            viewerWidth: MediaQuery.of(context).size.width,
            maxVideoLength: const Duration(seconds: 20),
            onChangeStart: (value) => _startValue = value,
            onChangeEnd: (value) => _endValue = value,
            onChangePlaybackState: (value) =>
                setState(() => _isPlaying = value),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionButton(Icons.crop, "Crop", () {}),
              _buildOptionButton(Icons.music_note, "Sound", _mergeAudio),
              _buildOptionButton(Icons.tune, "Adjust", () {}),
            ],
          ),
        ],
      ),
    );
  }
}

// Reusable button function
Widget _buildOptionButton(IconData icon, String label, VoidCallback onTap) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
      const SizedBox(height: 5),
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
    ],
  );
}
