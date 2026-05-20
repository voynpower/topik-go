import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/explanation_video/data/explanation_video_repository.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExplanationVideoListPage extends ConsumerWidget {
  const ExplanationVideoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedAsync = ref.watch(recommendedVideosProvider);
    final allAsync = ref.watch(explanationVideosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('문제 해설 영상')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recommendedVideosProvider);
          ref.invalidate(explanationVideosProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('추천 해설 영상', Icons.star_outline),
            const SizedBox(height: 12),
            recommendedAsync.when(
              data: (videos) => _VideoHorizontalList(videos: videos),
              loading: () => const _LoadingPlaceholder(height: 180),
              error: (err, _) => _ErrorCard(message: apiErrorMessage(err)),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('전체 영상 목록', Icons.video_library_outlined),
            const SizedBox(height: 12),
            allAsync.when(
              data: (videos) => _VideoVerticalList(videos: videos),
              loading: () => const _LoadingPlaceholder(height: 400),
              error: (err, _) => _ErrorCard(message: apiErrorMessage(err)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mintDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _VideoHorizontalList extends StatelessWidget {
  const _VideoHorizontalList({required this.videos});
  final List<ExplanationVideo> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const _EmptyCard(message: '추천 영상이 없습니다.');

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            SizedBox(width: 260, child: _VideoGridItem(video: videos[index])),
      ),
    );
  }
}

class _VideoVerticalList extends StatelessWidget {
  const _VideoVerticalList({required this.videos});
  final List<ExplanationVideo> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const _EmptyCard(message: '영상 목록이 비어있습니다.');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) => _VideoGridItem(video: videos[index]),
    );
  }
}

class _VideoGridItem extends StatelessWidget {
  const _VideoGridItem({required this.video});
  final ExplanationVideo video;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final rawUrl = video.videoUrl.trim();
          if (rawUrl.isEmpty) {
            _showError(context, '영상 주소가 없습니다.');
            return;
          }

          context.push(
            Uri(
              path: '/video-player',
              queryParameters: {'url': rawUrl, 'title': video.title},
            ).toString(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _VideoThumbnail(video: video),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(video.durationSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.targetTitle ?? '해설 영상',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.video});

  final ExplanationVideo video;

  @override
  Widget build(BuildContext context) {
    final youtubeId = YoutubePlayer.convertUrlToId(video.videoUrl);
    final thumbnailUrl = _usableThumbnail(video.thumbnailUrl)
        ? video.thumbnailUrl!
        : youtubeId == null
        ? null
        : 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';

    if (thumbnailUrl == null) {
      return Container(
        color: const Color(0xFFEAF1FF),
        child: const Icon(Icons.ondemand_video, color: Color(0xFF2E6BD9)),
      );
    }

    return Image.network(
      thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        if (youtubeId != null &&
            thumbnailUrl !=
                'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg') {
          return Image.network(
            'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
            fit: BoxFit.cover,
          );
        }
        return Container(
          color: const Color(0xFFEAF1FF),
          child: const Icon(Icons.ondemand_video, color: Color(0xFF2E6BD9)),
        );
      },
    );
  }

  bool _usableThumbnail(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return false;
    return !value.contains('cdn.example.com');
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
