import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';

class VocabularyAutoplayPage extends ConsumerStatefulWidget {
  const VocabularyAutoplayPage({
    super.key,
    required this.source,
  });

  final StudyWordSource source;

  @override
  ConsumerState<VocabularyAutoplayPage> createState() =>
      _VocabularyAutoplayPageState();
}

class _VocabularyAutoplayPageState
    extends ConsumerState<VocabularyAutoplayPage> {
  late final FlutterTts _tts;
  final ScrollController _scrollController = ScrollController();

  int _currentIndex = 0;
  bool _isPlaying = false;
  double _speechRate = 0.45;
  bool _loop = true;
  Timer? _stepTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(_speechRate);

    // Start playback automatically on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPlayback();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopPlayback();
    _tts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPlayback() {
    setState(() => _isPlaying = true);
    _playCurrentStep();
  }

  void _stopPlayback() {
    _stepTimer?.cancel();
    _stepTimer = null;
    _tts.stop();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _playCurrentStep() async {
    if (!_isPlaying || _isDisposed) return;

    final wordsAsync = ref.read(studyWordsProvider(widget.source));
    final words = wordsAsync.asData?.value;
    if (words == null || words.isEmpty) return;

    if (_currentIndex >= words.length) {
      if (_loop) {
        _currentIndex = 0;
      } else {
        _stopPlayback();
        return;
      }
    }

    _scrollToCurrentIndex();
    final word = words[_currentIndex];

    // 1. Speak Korean Word
    await _tts.stop();
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(word.word);

    // 2. Wait for audio + 1.2s thinking pause
    _stepTimer = Timer(const Duration(milliseconds: 2200), () async {
      if (!_isPlaying || _isDisposed) return;

      // 3. Speak meaning
      await _tts.speak(word.meaningKo);

      // 4. Wait for meaning audio + pause, then advance to next word
      _stepTimer = Timer(const Duration(milliseconds: 2400), () {
        if (!_isPlaying || _isDisposed) return;

        setState(() {
          _currentIndex++;
        });
        _playCurrentStep();
      });
    });
  }

  void _scrollToCurrentIndex() {
    if (_scrollController.hasClients) {
      final targetOffset = (_currentIndex * 68.0) - 100.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _nextWord(int totalLength) {
    _stepTimer?.cancel();
    _tts.stop();
    setState(() {
      if (_currentIndex + 1 < totalLength) {
        _currentIndex++;
      } else if (_loop) {
        _currentIndex = 0;
      }
    });
    if (_isPlaying) {
      _playCurrentStep();
    }
  }

  void _previousWord(int totalLength) {
    _stepTimer?.cancel();
    _tts.stop();
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else if (_loop) {
        _currentIndex = totalLength - 1;
      }
    });
    if (_isPlaying) {
      _playCurrentStep();
    }
  }

  void _changeSpeed(double rate) {
    setState(() {
      _speechRate = rate;
    });
    _tts.setSpeechRate(rate);
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(studyWordsProvider(widget.source));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.source.title} 자동재생'),
        actions: [
          IconButton(
            icon: Icon(_loop ? Icons.repeat : Icons.repeat_one),
            tooltip: _loop ? '반복 켜짐' : '한 번만 재생',
            color: _loop ? AppColors.mintDark : Colors.grey,
            onPressed: () {
              setState(() => _loop = !_loop);
            },
          ),
        ],
      ),
      body: wordsAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('자동재생할 단어가 없습니다.'));
          }

          final currentWord = words[_currentIndex < words.length ? _currentIndex : 0];

          return Column(
            children: [
              // Top Player Hero Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mintDark.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '재생 중 (${_currentIndex + 1}/${words.length})',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Row(
                          children: [
                            for (final rate in [0.35, 0.45, 0.55])
                              GestureDetector(
                                onTap: () => _changeSpeed(rate),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _speechRate == rate
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    rate == 0.35 ? '0.8x' : (rate == 0.45 ? '1.0x' : '1.2x'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _speechRate == rate ? AppColors.mintDark : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentWord.word,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentWord.meaningKo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    if (currentWord.meaningUserLang != null && currentWord.meaningUserLang!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        currentWord.meaningUserLang!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Player Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _previousWord(words.length),
                          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: _togglePlayPause,
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppColors.mintDark,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => _nextWord(words.length),
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Playlist Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.playlist_play, size: 20, color: AppColors.mintDark),
                    const SizedBox(width: 8),
                    Text(
                      '단어 목록 (${words.length}개)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              // Playlist Items
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final item = words[index];
                    final isCurrent = index == _currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          _stepTimer?.cancel();
                          _tts.stop();
                          setState(() => _currentIndex = index);
                          if (_isPlaying) {
                            _playCurrentStep();
                          }
                        },
                        leading: isCurrent
                            ? const Icon(Icons.volume_up, color: Color(0xFF16A34A))
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                        title: Text(
                          item.word,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? const Color(0xFF166534) : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          item.meaningKo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('오류 발생: $err')),
      ),
    );
  }
}
