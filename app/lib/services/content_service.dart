import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/book_summary.dart';

// TODO: 본인 GitHub 저장소로 변경
const _githubOwner = 'exhic';
const _githubRepo = 'bookpulse';
const _contentPath = 'content';

final contentServiceProvider = Provider((ref) => ContentService());

final summaryListProvider = FutureProvider<List<BookSummary>>((ref) async {
  return ref.read(contentServiceProvider).fetchAll();
});

class ContentService {
  /// GitHub API로 content/ 폴더의 파일 목록을 가져옵니다.
  Future<List<BookSummary>> fetchAll() async {
    final listUrl = 'https://api.github.com/repos/$_githubOwner/$_githubRepo/contents/$_contentPath';
    final listResp = await http.get(Uri.parse(listUrl), headers: {
      'Accept': 'application/vnd.github+json',
    });

    if (listResp.statusCode != 200) throw Exception('콘텐츠 목록 로드 실패');

    final files = (jsonDecode(listResp.body) as List)
        .where((f) => f['name'].toString().endsWith('.md'))
        .toList()
        ..sort((a, b) => b['name'].compareTo(a['name'])); // 최신순

    // 각 파일 내용을 병렬로 가져오기
    final futures = files.map((f) => _fetchOne(f['name'], f['download_url']));
    final summaries = await Future.wait(futures);
    return summaries.whereType<BookSummary>().toList();
  }

  Future<BookSummary?> _fetchOne(String filename, String downloadUrl) async {
    try {
      final resp = await http.get(Uri.parse(downloadUrl));
      if (resp.statusCode != 200) return null;
      final markdown = utf8.decode(resp.bodyBytes);
      return BookSummary.fromMarkdown(filename, markdown);
    } catch (_) {
      return null;
    }
  }
}
