import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kabimreel/main.dart';
import 'package:kabimreel/video_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:whitecodel_reels/whitecodel_reels.dart';

import 'video_upload/video_edit_page.dart';

// Video Provider (Mock Data)

// Like State Provider
final likeProvider = StateProvider<int>((ref) => 1000);
final isLikedProvider = StateProvider<bool>((ref) => false);

class ReelsPage extends ConsumerWidget {
  const ReelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsyncValue = ref.watch(videoProvider);

    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.redAccent,
          icon: const Icon(Icons.upload, color: Colors.white),
          label: const Text(
            "Upload",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.video,
              allowCompression: false,
            );
            if (result != null) {
              final path = result.files.single.path;
              if (path != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TrimmerView(file: File(path)),
                  ),
                );
              }
            }
          },
        ),
        backgroundColor: Colors.black,
        body: videosAsyncValue.when(
          data: (videos) => GestureDetector(
            onDoubleTap: () {}, // Prevent accidental interactions
            child: WhiteCodelReels(
              key: UniqueKey(),
              context: context,
              loader: const Center(child: CircularProgressIndicator()),
              isCaching: true,
              videoList: videos,
              builder: (context, index, child, videoPlayerController,
                  pageController) {
                return _ReelItem(
                  videoPlayerController: videoPlayerController,
                  child: child,
                );
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Center(
            child: Text("Error loading videos",
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _ReelItem extends ConsumerStatefulWidget {
  final VideoPlayerController videoPlayerController;
  final Widget child;

  const _ReelItem({required this.videoPlayerController, required this.child});

  @override
  _ReelItemState createState() => _ReelItemState();
}

class _ReelItemState extends ConsumerState<_ReelItem>
    with TickerProviderStateMixin, RouteAware {
  bool isReadMore = false;
  bool _showLikeAnimation = false;
  bool isLiked = false; // State for like status
  int likeCount = 1000; // State for like count
  late final StreamController<double> videoProgressController;
  late AnimationController _likeAnimationController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPushNext() {
    widget.videoPlayerController.pause();
  }

  @override
  void didPopNext() {
    widget.videoPlayerController.play();
  }

  @override
  void initState() {
    super.initState();
    videoProgressController = StreamController<double>.broadcast();
    widget.videoPlayerController.addListener(_updateProgress);

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.3,
    );
  }

  void _updateProgress() {
    final position = widget.videoPlayerController.value.position.inMilliseconds;
    final duration = widget.videoPlayerController.value.duration.inMilliseconds;
    if (duration > 0) {
      videoProgressController.add(position / duration);
    }
  }

  void _increaseLikeCount() {
    setState(() {
      if (isLiked) {
        likeCount--;
      } else {
        likeCount++;
        _showLikeAnimation = true;
      }
      isLiked = !isLiked;
    });

    _likeAnimationController.forward(from: 0.8).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showLikeAnimation = false);
        }
      });
    });
  }

  @override
  void dispose() {
    widget.videoPlayerController.removeListener(_updateProgress);
    videoProgressController.close();
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _increaseLikeCount,
      child: Stack(
        children: [
          widget.child,
          _buildHeartAnimation(),
          _buildDescriptionSection(),
          _buildActionButtons(),
          SizedBox(
            height: 30,
          ),
          _buildProgressBar(),
          SizedBox(
            height: 30,
          )
        ],
      ),
    );
  }

  Widget _buildHeartAnimation() {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showLikeAnimation ? 1.0 : 0.0,
        child: Center(
          child: AnimatedScale(
            scale: _showLikeAnimation ? 1.2 : 0.8,
            duration: const Duration(milliseconds: 300),
            child:
                const Icon(Icons.favorite, color: Colors.redAccent, size: 100),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => setState(() => isReadMore = !isReadMore),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.5)
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text("Shree Krishna",
                      style: TextStyle(color: Colors.white, fontSize: 16))
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Awesome reel video showcasing creativity...',
                maxLines: isReadMore ? null : 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 70,
      right: 10,
      child: Column(
        children: [
          GestureDetector(
            onTap: _increaseLikeCount,
            child: AnimatedScale(
              scale: isLiked ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.favorite,
                color: isLiked ? Colors.redAccent : Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            likeCount.toString(),
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
              HugeIcons.strokeRoundedComment01, '476', Colors.white),
          _buildActionButton(HugeIcons.strokeRoundedShare05, '', Colors.white),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        IconButton(onPressed: () {}, icon: Icon(icon, color: color)),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: StreamBuilder<double>(
        stream: videoProgressController.stream,
        builder: (context, snapshot) {
          return SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
              trackHeight: 2,
            ),
            child: Slider(
              value: snapshot.data ?? 0.0,
              min: 0.0,
              max: 1.0,
              activeColor: Colors.red,
              inactiveColor: Colors.white,
              onChanged: (value) {
                final position =
                    widget.videoPlayerController.value.duration * value;
                widget.videoPlayerController.seekTo(position);
              },
            ),
          );
        },
      ),
    );
  }
}
