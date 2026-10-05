enum LegalDocumentType {
  termsOfService,
  privacyPolicy,
}

class LegalUrls {
  static const String termsOfServiceUrl = 'https://topik-api.duckdns.org/terms';
  static const String privacyPolicyUrl = 'https://topik-api.duckdns.org/privacy-policy';
}

class LegalDocumentSection {
  const LegalDocumentSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class LegalDocumentData {
  const LegalDocumentData({
    required this.type,
    required this.title,
    required this.effectiveDate,
    required this.introduction,
    required this.sections,
    required this.externalUrl,
  });

  final LegalDocumentType type;
  final String title;
  final String effectiveDate;
  final String introduction;
  final List<LegalDocumentSection> sections;
  final String externalUrl;
}

class LegalDocuments {
  static LegalDocumentData getDocument(LegalDocumentType type, {String languageCode = 'ko'}) {
    final isKorean = languageCode == 'ko';

    switch (type) {
      case LegalDocumentType.termsOfService:
        return isKorean ? _koTerms : _enTerms;
      case LegalDocumentType.privacyPolicy:
        return isKorean ? _koPrivacy : _enPrivacy;
    }
  }

  // ---------------------------------------------------------------------------
  // Korean Documents
  // ---------------------------------------------------------------------------

  static const _koTerms = LegalDocumentData(
    type: LegalDocumentType.termsOfService,
    title: 'TOPIK GO 서비스 이용약관',
    effectiveDate: '시행일자: 2026년 10월 1일',
    introduction:
        '본 약관은 TOPIK GO(이하 "서비스")가 제공하는 한국어능력시험(TOPIK) 대비 모바일 애플리케이션 및 제반 서비스의 이용 조건 및 절차에 관한 기본적인 사항을 규정합니다.',
    externalUrl: LegalUrls.termsOfServiceUrl,
    sections: [
      LegalDocumentSection(
        title: '제1조 (목적)',
        body:
            '본 약관은 회원이 서비스가 제공하는 디지털 학습 콘텐츠(기출문제, 모의고사, 단어장, 문법, AI 해설 등)를 이용함에 있어 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
      ),
      LegalDocumentSection(
        title: '제2조 (용어의 정의)',
        body:
            '1. "서비스"란 TOPIK GO 앱 및 관련 서버에서 제공하는 일체의 학습 기능을 의미합니다.\n2. "회원"이란 본 약관에 동의하고 계정을 생성하여 서비스를 이용하는 자를 의미합니다.\n3. "콘텐츠"란 서비스 내 제공되는 문제, 해설, 음원, 동영상, 단어, 문법 등의 학습 자료를 의미합니다.',
      ),
      LegalDocumentSection(
        title: '제3조 (약관의 효력 및 변경)',
        body:
            '1. 본 약관은 서비스를 이용하고자 하는 자가 본 약관에 동의함으로써 효력이 발생합니다.\n2. 서비스는 관련 법령을 위배하지 않는 범위 내에서 약관을 변경할 수 있으며, 변경된 약관은 앱 내 공지사항 또는 설정을 통해 공지합니다.',
      ),
      LegalDocumentSection(
        title: '제4조 (회원가입 및 계정 관리)',
        body:
            '1. 이용자는 서비스가 정한 절차에 따라 가입을 신청하며, 이메일 인증 또는 소셜 계정 연동을 통해 가입할 수 있습니다.\n2. 회원은 본인의 계정 정보를 타인에게 양도하거나 대여할 수 없으며, 계정 관리 소홀로 인한 책임은 회원 본인에게 있습니다.',
      ),
      LegalDocumentSection(
        title: '제5조 (서비스의 제공 및 이용)',
        body:
            '1. 서비스는 연중무휴 1일 24시간 제공을 원칙으로 하되, 시스템 점검 또는 기술적 필요에 따라 일시 중단될 수 있습니다.\n2. 서비스 내 일부 기능(AI 예문 생성, 실시간 번역 등)에는 인공지능 기술이 활용되며, 이는 학습 보조용으로 제공됩니다.',
      ),
      LegalDocumentSection(
        title: '제6조 (이용자의 의무 및 금지사항)',
        body:
            '회원은 다음 행위를 하여서는 안 됩니다:\n• 타인의 정보 도용 또는 허위 정보 등록\n• 서비스 내 제공되는 학습 콘텐츠의 무단 복제, 배포, 상업적 이용 또는 리버스 엔지니어링\n• 서비스의 정상적인 운영을 방해하는 해킹 또는 악성 프로그램 유포\n• 기타 관계 법령이나 공서양속에 반하는 행위',
      ),
      LegalDocumentSection(
        title: '제7조 (계정 해지 및 탈퇴)',
        body:
            '회원은 언제든지 서비스 내 [설정 > 회원 탈퇴]를 통해 이용계약을 해지할 수 있습니다. 탈퇴 완료 시 회원의 모든 학습 이력, 오답노트, 단어장은 영구 삭제되며 복구되지 않습니다.',
      ),
      LegalDocumentSection(
        title: '제8조 (면책 조항)',
        body:
            '1. 천재지변 또는 불가항력으로 인해 서비스를 제공할 수 없는 경우 서비스 제공에 관한 책임이 면제됩니다.\n2. 서비스에서 제공하는 학습 콘텐츠 및 점수 예측은 수험생의 학습 참고용이며, 공식 시험의 성적을 보증하지 않습니다.',
      ),
      LegalDocumentSection(
        title: '제9조 (준거법 및 관할)',
        body:
            '본 약관의 해석 및 회원과 서비스 간의 분쟁에 대하여는 대한민국 법률을 적용하며, 분쟁 발생 시 관할 법원에 소를 제기할 수 있습니다.',
      ),
    ],
  );

  static const _koPrivacy = LegalDocumentData(
    type: LegalDocumentType.privacyPolicy,
    title: 'TOPIK GO 개인정보처리방침',
    effectiveDate: '시행일자: 2026년 10월 1일',
    introduction:
        'TOPIK GO(이하 "서비스")는 이용자의 개인정보를 소중히 다루며, 「개인정보 보호법」 및 관련 법령을 준수합니다. 본 방침은 서비스가 수집하는 정보, 이용 목적, 보관 및 파기 절차에 대해 안내합니다.',
    externalUrl: LegalUrls.privacyPolicyUrl,
    sections: [
      LegalDocumentSection(
        title: '1. 수집하는 개인정보 항목',
        body:
            '• 필수 항목: 이메일 주소, 비밀번호(단방향 암호화 저장), 닉네임\n• 소셜 로그인 시: 소셜 제공업체 고유 식별자(Google, Kakao), 프로필 닉네임, 이메일\n• 학습 이용 기록: 모의고사 응시 기록, 답안, 점수, 단어장 및 문법 저장 내역, 목표 TOPIK 등급, 선호 학습 언어\n• 서비스 이용 및 기기 정보: 기기 식별자, 접속 로그, 서비스 이용 기록',
      ),
      LegalDocumentSection(
        title: '2. 개인정보의 수집 및 이용 목적',
        body:
            '• 회원 식별 및 계정 가입·관리\n• 맞춤형 한국어 능력시험(TOPIK) 학습 콘텐츠 및 AI 해설 제공\n• 모의고사 채점, 학습 진도 및 성적 분석 데이터 제공\n• 서비스 공지사항 전달, 문의 대응 및 고객 지원\n• 부정 이용 방지 및 서비스 품질 개선',
      ),
      LegalDocumentSection(
        title: '3. 개인정보의 보유 및 이용 기간',
        body:
            '• 이용자의 개인정보는 회원 탈퇴 시까지 보유 및 이용됩니다.\n• 회원 탈퇴 시: 앱 내 [설정 > 회원 탈퇴] 또는 탈퇴 요청 시 이용자의 개인정보 및 모든 학습 데이터(시험 세션, 답안, 단어장, 오답노트 등)는 즉시 영구 삭제 및 파기됩니다.\n• 관계 법령의 규정에 따라 보존할 필요가 있는 경우, 해당 법령에서 정한 기간 동안 분리 보관합니다.',
      ),
      LegalDocumentSection(
        title: '4. 개인정보의 제3자 제공 및 위탁',
        body:
            '• 서비스는 이용자의 동의 없이 개인정보를 외부에 제공하지 않습니다.\n• 원활한 클라우드 인프라 제공을 위해 Amazon Web Services(AWS)에 호스팅을 위탁하여 안전하게 관리합니다.',
      ),
      LegalDocumentSection(
        title: '5. 이용자의 권리와 행사 방법',
        body:
            '• 이용자는 언제든지 앱 내 프로필 설정을 통해 자신의 개인정보를 조회하거나 수정할 수 있습니다.\n• 이용자는 언제든지 앱 내 [설정 > 회원 탈퇴] 기능을 통해 즉시 계정을 삭제하고 모든 데이터의 파기를 요청할 수 있습니다.',
      ),
      LegalDocumentSection(
        title: '6. 개인정보의 안전성 확보 조치',
        body:
            '• 비밀번호 및 민감 정보의 안전한 단방향 암호화(Bcrypt, Salt) 적용\n• SSL/TLS 전송 구간 암호화를 통한 안전한 네트워크 통신\n• 비인가 접근 차단을 위한 접근 통제 시스템 및 방화벽 운영',
      ),
      LegalDocumentSection(
        title: '7. 개인정보 보호책임자 및 문의처',
        body:
            '개인정보 처리와 관련한 문의사항이나 불만 처리는 아래 연락처로 문의해 주시기 바랍니다.\n• 담당자: TOPIK GO 개인정보보호 담당자\n• 문의 이메일: husanboy.hakimov.dev@gmail.com',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // English Documents
  // ---------------------------------------------------------------------------

  static const _enTerms = LegalDocumentData(
    type: LegalDocumentType.termsOfService,
    title: 'TOPIK GO Terms of Service',
    effectiveDate: 'Effective Date: October 1, 2026',
    introduction:
        'These Terms of Service govern your use of the TOPIK GO mobile application and related services provided for Korean Language Proficiency Test (TOPIK) preparation.',
    externalUrl: LegalUrls.termsOfServiceUrl,
    sections: [
      LegalDocumentSection(
        title: 'Article 1 (Purpose)',
        body:
            'The purpose of these Terms is to define the rights, obligations, and responsibilities of the users and the service in connection with digital learning content (past exams, mock tests, vocabulary, grammar, AI explanations).',
      ),
      LegalDocumentSection(
        title: 'Article 2 (Definitions)',
        body:
            '1. "Service" refers to the TOPIK GO application and related server operations.\n2. "Member" refers to an individual who agrees to these Terms and creates an account to use the Service.\n3. "Content" refers to questions, audio, videos, vocabulary, and grammar study materials provided in the Service.',
      ),
      LegalDocumentSection(
        title: 'Article 3 (Account Management)',
        body:
            'Members must manage their account credentials securely and are responsible for all activities occurring under their accounts. Account transfer or sharing with third parties is strictly prohibited.',
      ),
      LegalDocumentSection(
        title: 'Article 4 (Prohibited Conduct)',
        body:
            'Users must not:\n• Use false information or impersonate others\n• Reproduce, distribute, or reverse-engineer learning content without authorization\n• Interfere with system integrity or deploy malicious code',
      ),
      LegalDocumentSection(
        title: 'Article 5 (Account Deletion & Data Removal)',
        body:
            'Members may terminate their account at any time via [Settings > Delete Account] within the application. Upon account deletion, all study records, bookmarks, and vocabulary are permanently and irrecoverably removed.',
      ),
      LegalDocumentSection(
        title: 'Article 6 (Disclaimer)',
        body:
            'Content and score predictions are provided for reference only and do not guarantee official test outcomes.',
      ),
    ],
  );

  static const _enPrivacy = LegalDocumentData(
    type: LegalDocumentType.privacyPolicy,
    title: 'TOPIK GO Privacy Policy',
    effectiveDate: 'Effective Date: October 1, 2026',
    introduction:
        'TOPIK GO ("Service") values user privacy and complies with applicable data protection laws. This Privacy Policy explains what data we collect, why we collect it, how it is used, and how it is destroyed.',
    externalUrl: LegalUrls.privacyPolicyUrl,
    sections: [
      LegalDocumentSection(
        title: '1. Information We Collect',
        body:
            '• Account Credentials: Email address, encrypted password, nickname\n• Social Login: Provider account identifier (Google, Kakao), email, profile nickname\n• Learning Data: Mock exam answers, session history, scores, saved vocabulary, grammar bookmarks, target TOPIK level\n• Technical Data: Device identifiers, access logs, OS version',
      ),
      LegalDocumentSection(
        title: '2. Purpose of Collection',
        body:
            '• Member identification and account management\n• Delivering personalized TOPIK test preparation content and AI study explanations\n• Scoring mock exams and analyzing learning progress\n• Customer support, service updates, and fraudulent activity prevention',
      ),
      LegalDocumentSection(
        title: '3. Data Retention and Account Deletion',
        body:
            '• Personal information is retained only while your account is active.\n• Immediate Deletion: When you delete your account via [Settings > Delete Account], your personal data and all learning sessions, answers, and bookmarks are permanently purged.\n• In accordance with Google Play Store policies, in-app account and data deletion is fully supported.',
      ),
      LegalDocumentSection(
        title: '4. Third-Party Services and Hosting',
        body:
            'We do not sell or share personal data with external third parties for marketing purposes. Infrastructure hosting is maintained via Amazon Web Services (AWS) under strict security protocols.',
      ),
      LegalDocumentSection(
        title: '5. User Rights',
        body:
            'You have the right to access, rectify, or delete your personal data at any time directly through the application settings.',
      ),
      LegalDocumentSection(
        title: '6. Contact Us',
        body:
            'If you have questions regarding this Privacy Policy or your data, please contact:\n• Privacy Officer: TOPIK GO Privacy Team\n• Email: husanboy.hakimov.dev@gmail.com',
      ),
    ],
  );
}
