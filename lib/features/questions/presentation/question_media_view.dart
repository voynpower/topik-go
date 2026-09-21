import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:pdfrx/pdfrx.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart'
    show Question, QuestionMedia;

/// Shared helpers for question media (reading/listening practice, mock exam).

bool isImageMedia(QuestionMedia media) {
  final type = media.mediaType.toLowerCase();
  final url = media.url.toLowerCase();
  return type.contains('image') ||
      url.endsWith('.png') ||
      url.endsWith('.jpg') ||
      url.endsWith('.jpeg') ||
      url.endsWith('.webp');
}

bool isDocumentMedia(QuestionMedia media) {
  final type = media.mediaType.toLowerCase();
  final url = media.url.toLowerCase();
  return type.contains('document') ||
      type.contains('pdf') ||
      url.endsWith('.pdf');
}

/// True when the question asks to pick a picture/graph answer.
bool isVisualChoiceQuestion(Question question) {
  final content = '${question.passageText ?? ''}\n${question.prompt}';
  return content.contains('그림') || content.contains('그래프');
}

/// TOPIK II listening questions 1–3 always present picture options.
bool isListeningPictureQuestion(Question question) {
  final number = question.questionNumber;
  if (number <= 0 || number > 3) return false;
  final section = question.section.toLowerCase();
  return section.isEmpty || section == 'listening';
}

/// Renders an image media file served by the API.
class QuestionImage extends StatelessWidget {
  const QuestionImage({super.key, required this.media});

  final QuestionMedia media;

  @override
  Widget build(BuildContext context) {
    final url = resolveApiMediaUrl(media.url);
    if (url.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('이미지를 불러오지 못했습니다.'),
            );
          },
        ),
      ),
    );
  }
}

/// Renders the picture/graph region of the TOPIK II exam paper PDF that the
/// backend attaches as a `document` media. The crop table mirrors the exam
/// paper layout used by the mock exam screen (1190 x 1684 pages).
class ExamPaperDocumentPreview extends StatefulWidget {
  const ExamPaperDocumentPreview({
    super.key,
    required this.media,
    required this.questionNumber,
    this.height = 260,
  });

  final QuestionMedia media;
  final int questionNumber;
  final double height;

  @override
  State<ExamPaperDocumentPreview> createState() =>
      _ExamPaperDocumentPreviewState();
}

class _ExamPaperDocumentPreviewState extends State<ExamPaperDocumentPreview> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadCroppedImage();
  }

  @override
  void didUpdateWidget(covariant ExamPaperDocumentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.url != widget.media.url ||
        oldWidget.questionNumber != widget.questionNumber) {
      _imageFuture = _loadCroppedImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('문제에 연결된 그림 자료를 표시할 수 없습니다.'),
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            snapshot.data!,
            width: double.infinity,
            height: widget.height,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  Future<Uint8List> _loadCroppedImage() async {
    final response = await Dio().get<List<int>>(
      resolveApiMediaUrl(widget.media.url),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    final document = await PdfDocument.openData(
      bytes,
      sourceName: 'exam-paper-${widget.questionNumber}-${widget.media.id}',
    );

    try {
      final pageCount = document.pages.length;
      final pageNumber = _examPaperPage(widget.questionNumber, pageCount);
      if (pageNumber <= 0 || pageNumber > pageCount) {
        throw StateError('PDF page $pageNumber is out of range');
      }
      final page = document.pages[pageNumber - 1];
      final crop = _examPaperCrop(widget.questionNumber, pageCount);
      final rendered = await page.render(
        x: crop.$1,
        y: crop.$2,
        width: crop.$3,
        height: crop.$4,
        fullWidth: 1190,
        fullHeight: 1684,
      );
      if (rendered == null) throw StateError('PDF crop rendering failed');

      try {
        final raster = image.Image.fromBytes(
          width: rendered.width,
          height: rendered.height,
          bytes: rendered.pixels.buffer,
          numChannels: 4,
          order: image.ChannelOrder.bgra,
        );
        return Uint8List.fromList(image.encodePng(raster));
      } finally {
        rendered.dispose();
      }
    } finally {
      await document.dispose();
    }
  }

  int _examPaperPage(int questionNumber, int pageCount) {
    // 102회 PDF(3페이지: 듣기 통합)는 1번=1p, 2번=2p, 3번=3p.
    if (pageCount <= 3 && questionNumber >= 1 && questionNumber <= 3) {
      return questionNumber;
    }
    // 83회 PDF(듣기+쓰기 통합)는 1~2번이 5페이지, 3번이 6페이지에 있음.
    if (pageCount >= 6 && questionNumber >= 1 && questionNumber <= 3) {
      return questionNumber <= 2 ? 5 : 6;
    }
    if (questionNumber <= 3) return questionNumber;
    if (questionNumber <= 6) return 4;
    return ((questionNumber - 7) ~/ 2) + 5;
  }

  (int, int, int, int) _examPaperCrop(int questionNumber, int pageCount) {
    // 102회 PDF용 크롭.
    if (pageCount <= 3) {
      switch (questionNumber) {
        case 1:
          return (150, 505, 880, 495);
        case 2:
          return (150, 355, 880, 495);
        case 3:
          return (150, 450, 880, 635);
      }
    }
    // 83회 PDF용 크롭.
    if (pageCount >= 6) {
      switch (questionNumber) {
        case 1:
          return (185, 315, 850, 490);
        case 2:
          return (185, 890, 850, 495);
        case 3:
          return (180, 240, 855, 620);
      }
    }
    switch (questionNumber) {
      case 1:
        return (230, 500, 760, 520);
      case 2:
        return (230, 300, 760, 620);
      case 3:
        return (230, 400, 760, 700);
      default:
        return (180, 240, 830, 760);
    }
  }
}
