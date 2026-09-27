import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/vocabulary/presentation/pages/voca_list_tab_view.dart';
import 'package:topik_go/features/vocabulary/presentation/pages/voca_study_hub_tab_view.dart';

class VocabularyPage extends ConsumerStatefulWidget {
  const VocabularyPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends ConsumerState<VocabularyPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13161F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13161F),
        elevation: 0,
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(20),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(strings.tabWordbook),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(strings.tabStudyHub),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VocaListTabView(),
          VocaStudyHubTabView(),
        ],
      ),
    );
  }
}
