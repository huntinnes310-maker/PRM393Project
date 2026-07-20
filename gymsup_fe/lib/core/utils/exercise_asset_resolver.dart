/// Suy ra đường dẫn asset ảnh cục bộ cho 1 bài tập dựa trên tên (slug hoá),
/// dùng khi backend không trả về imageUrl dạng network hợp lệ.
String resolveExerciseAssetPath(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+$|^-+'), '');
  if (slug == 'barbell-bench-press' ||
      slug == 'dumbbell-bench-press' ||
      slug == 'incline-barbell-press') {
    return 'assets/exercises/images/$slug.png';
  }
  return 'assets/exercises/images/$slug.webp';
}
