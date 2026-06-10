import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';

void main() {
  test('cleans repeated reading passage for one question', () {
    final question = Question.fromJson({
      'id': 'topik2-102-reading-q06',
      'set_id': 'topik2-102-reading',
      'section': 'reading',
      'question_type': 'multiple_choice',
      'question_number': 6,
      'question_passages': {
        'content':
            '※ [5~8] 다음은 무엇에 대한 글인지 고르십시오. (각 2점)\n'
            '5.\n걸을 때 발이 편하게~\n가볍고 디자인도 예뻐요.\n\n'
            '6.\n더러워진 옷을 새 옷처럼!\n두꺼운 이불도 맡겨 주세요.\n\n'
            '달리기, 지금 바로 시작하세요.\n활기찬 내일이 기다립니다.\n\n'
            '환경 보호\n8.\n6.\n\n'
            '더러워진 옷을 새 옷처럼!\n두꺼운 이불도 맡겨 주세요.',
      },
      'question_options': [
        {'option_number': 1, 'content': '은행'},
        {'option_number': 2, 'content': '시장'},
        {'option_number': 3, 'content': '세탁소'},
        {'option_number': 4, 'content': '가구점'},
      ],
    });

    expect(question.passageText, contains('더러워진 옷'));
    expect(question.passageText, isNot(contains('달리기')));
    expect(question.passageText, isNot(contains('환경 보호')));
  });

  test('keeps long shared reading passage context', () {
    final question = Question.fromJson({
      'id': 'topik2-102-reading-q46',
      'set_id': 'topik2-102-reading',
      'section': 'reading',
      'question_type': 'multiple_choice',
      'question_number': 46,
      'question_passages': {
        'content':
            '※ [46~47] 다음을 읽고 물음에 답하십시오. (각 2점)\n'
            '전 세계 바다 밑에는 400개가 넘는 해저 전선이 대양과 연안을 따라\n'
            '설치돼 있다. 나라 간 정보 통신의 99%가 이 해저 전선을 통해 이루어진다.\n'
            '46. 윗글에 나타난 필자의 태도로 가장 알맞은 것을 고르십시오.',
      },
      'question_options': [
        {'option_number': 1, 'content': '보기 1'},
      ],
    });

    expect(question.passageText, contains('전 세계 바다 밑'));
    expect(question.passageText, contains('46. 윗글'));
  });

  test('cleans leaked next question text from option content', () {
    final question = Question.fromJson({
      'id': 'topik2-102-reading-q05',
      'set_id': 'topik2-102-reading',
      'section': 'reading',
      'question_type': 'multiple_choice',
      'question_number': 5,
      'question_options': [
        {'option_number': 4, 'content': '선풍기\n6.'},
      ],
    });

    expect(question.options.single.text, '선풍기');
  });

  test(
    'cleans previous listening transcript when current question starts later',
    () {
      final question = Question.fromJson({
        'id': 'topik2-102-listening-q02',
        'set_id': 'topik2-102-listening',
        'section': 'listening',
        'question_type': 'multiple_choice',
        'question_number': 2,
        'question_passages': {
          'content':
              '※ 11~3] 다음을 듣고 가장 알맞은 그림 또는 그래프를 고르십시오. (각 2점)\n'
              '남자 : 이 책을 소포로 보내고 싶은데요. 소포 상자 살 수 있지요?\n'
              '여자: 네. 손님, 상자는 이쪽에서 고르시면 돼요.\n'
              '남자 : 네, 한번 볼게요.\n\n'
              '2.\n'
              '여자 : 어, 낚싯대가 움직인다. 물고기 잡은 것 같아.\n'
              '남자 : 그래? 낚싯대 잘 잡고 천천히 당겨서 올려 봐.\n'
              '여자 : 응. 그런데 진짜 무겁다.',
        },
        'question_options': [
          {'option_number': 1, 'content': '1'},
        ],
      });

      expect(question.passageText, contains('낚싯대'));
      expect(question.passageText, isNot(contains('소포')));
    },
  );
}
