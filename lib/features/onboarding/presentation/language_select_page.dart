import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';

class LanguageSelectPage extends StatefulWidget {
  const LanguageSelectPage({super.key});

  @override
  State<LanguageSelectPage> createState() => _LanguageSelectPageState();
}

class _LanguageSelectPageState extends State<LanguageSelectPage> {
  String selected = 'ko';

  final languages = const [
    ('ko', 'Korean (한국어)'),
    ('en', 'English'),
    ('ru', 'Russian (Русский)'),
    ('uz', "Uzbek (O'zbekcha)"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Hello! Which language do you usually speak?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: languages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = languages[index];
                  final active = item.$1 == selected;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: active ? AppColors.mint : AppColors.border,
                      ),
                    ),
                    tileColor: AppColors.surface,
                    title: Text(item.$2),
                    trailing: Icon(
                      active ? Icons.check_circle : Icons.circle_outlined,
                      color: active
                          ? AppColors.mintDark
                          : AppColors.textSecondary,
                    ),
                    onTap: () => setState(() => selected = item.$1),
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: () => context.go('/goal-level'),
              child: const Text('Next Step'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
