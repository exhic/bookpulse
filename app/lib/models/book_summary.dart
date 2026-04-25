/// 책 요약 데이터 모델
class BookSummary {
  final String title;
  final String author;
  final DateTime date;
  final List<String> categories;
  final List<String> tags;
  final String oneLiner;       // 한 줄 요약
  final String fullContent;    // 전체 마크다운 원문
  final String filename;       // GitHub 파일명 (고유 ID 역할)

  const BookSummary({
    required this.title,
    required this.author,
    required this.date,
    required this.categories,
    required this.tags,
    required this.oneLiner,
    required this.fullContent,
    required this.filename,
  });

  /// GitHub content/ 폴더의 마크다운 파일을 파싱해 생성
  factory BookSummary.fromMarkdown(String filename, String markdown) {
    final titleMatch = RegExp(r'^title:\s*"?(.+?)"?\s*$', multiLine: true).firstMatch(markdown);
    final authorMatch = RegExp(r'^author:\s*"?(.+?)"?\s*$', multiLine: true).firstMatch(markdown);
    final dateMatch = RegExp(r'^date:\s*(.+?)\s*$', multiLine: true).firstMatch(markdown);
    final categoriesMatch = RegExp(r'^categories:\s*\[(.+?)\]', multiLine: true).firstMatch(markdown);
    final tagsMatch = RegExp(r'^tags:\s*\[(.+?)\]', multiLine: true).firstMatch(markdown);
    final oneLinerMatch = RegExp(r'## 한 줄 요약\n(.+)').firstMatch(markdown);

    return BookSummary(
      filename: filename,
      title: titleMatch?.group(1)?.trim() ?? filename,
      author: authorMatch?.group(1)?.trim() ?? '',
      date: dateMatch != null
          ? DateTime.tryParse(dateMatch.group(1)!.trim()) ?? DateTime.now()
          : DateTime.now(),
      categories: categoriesMatch != null
          ? categoriesMatch.group(1)!.split(',').map((e) => e.trim()).toList()
          : [],
      tags: tagsMatch != null
          ? tagsMatch.group(1)!.split(',').map((e) => e.trim()).toList()
          : [],
      oneLiner: oneLinerMatch?.group(1)?.trim() ?? '',
      fullContent: markdown,
    );
  }
}
