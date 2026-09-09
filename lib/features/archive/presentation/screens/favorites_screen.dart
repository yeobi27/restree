import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/widgets/empty_state.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/record_preview_card.dart';

/// 즐겨찾기 목록 — 아카이브 우측 상단 북마크 아이콘 진입 (v1.4 §6).
/// records.isFavorite == true 인 레코드만 모아 보여준다.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('즐겨찾기'),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (records) {
          if (records.isEmpty) {
            return const EmptyState(message: '즐겨찾기한 기록이 없어요.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => RecordPreviewCard(record: records[i]),
          );
        },
      ),
    );
  }
}
