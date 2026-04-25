import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book_summary.dart';

class DetailScreen extends StatelessWidget {
  final BookSummary summary;
  const DetailScreen({super.key, required this.summary});

  // frontmatter 제거 후 본문만 추출
  String get _bodyMarkdown {
    final content = summary.fullContent;
    if (content.startsWith('---')) {
      final end = content.indexOf('---', 3);
      if (end != -1) return content.substring(end + 3).trim();
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(summary.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share 패키지 연동
            },
          ),
        ],
      ),
      body: Markdown(
        data: _bodyMarkdown,
        padding: const EdgeInsets.all(16),
        onTapLink: (text, href, title) {
          if (href != null) launchUrl(Uri.parse(href));
        },
        styleSheet: MarkdownStyleSheet(
          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          p: const TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}
