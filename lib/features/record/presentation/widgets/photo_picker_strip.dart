import 'package:flutter/material.dart';
import 'package:restree/core/constants/app_limits.dart';
import 'package:restree/core/theme/app_colors.dart';

/// 04단계 사진 첨부 스트립 — 설계서 v1.3 §3.1에 따라
/// 질문 문구와 본문 텍스트박스 "사이"에 배치된다.
///
/// 좌측 첫 칸은 추가 버튼(현재 n/10 표시), 이후 선택된 사진 썸네일이 가로 스크롤된다.
class PhotoPickerStrip extends StatelessWidget {
  final List<String> imageUrls;
  final ValueChanged<List<String>> onChanged;

  const PhotoPickerStrip({super.key, required this.imageUrls, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(
            count: imageUrls.length,
            onTap: imageUrls.length >= AppLimits.photoMaxCount
                ? null
                : () {
                    // TODO: image_picker로 선택 → Firebase Storage
                    // users/{uid}/records/{date}/photos/{index}.jpg 업로드 (v1.4 §5)
                  },
          ),
          ...imageUrls.map((url) => _Thumbnail(
                url: url,
                // TODO: 수정 화면에서의 개별 사진 삭제/추가 UI는 미확정 (v1.5 §6.3)
                onRemove: () => onChanged(imageUrls.where((u) => u != url).toList()),
              )),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _AddButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 28),
            const SizedBox(height: 6),
            Text('$count/${AppLimits.photoMaxCount}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _Thumbnail({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceMuted,
      ),
      // TODO: cached_network_image로 실제 사진 렌더링
      child: const Icon(Icons.photo, color: AppColors.textSecondary),
    );
  }
}
