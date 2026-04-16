import 'dart:convert';
import 'package:http/http.dart' as http;

/// 从公开 API 搜索媒体信息（封面图、创作者、标签）
/// 优先使用国内可访问的接口
class MediaSearchService {

  static const _timeout = Duration(seconds: 12);

  /// 判断是否为豆瓣图片（需要 Referer 才能加载）
  static bool isDoubanImage(String? url) =>
      url != null && url.contains('doubanio.com');

  /// 用于 CachedNetworkImage 的 httpHeaders
  static Map<String, String> imageHeaders(String? url) {
    if (isDoubanImage(url)) {
      return {'Referer': 'https://www.douban.com/'};
    }
    return {};
  }

  /// ── 搜索音乐（iTunes 优先，网易云备选） ──────────────────────
  static Future<List<MediaResult>> searchMusic(String query) async {
    if (query.trim().isEmpty) return [];

    // 1) iTunes — 封面可靠
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=5&country=cn',
      );
      final resp = await http.get(uri).timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          return results.map((r) => MediaResult(
            title: r['trackName'] ?? r['collectionName'] ?? '',
            creator: r['artistName'] ?? '',
            imageUrl: (r['artworkUrl100'] ?? '').toString().replaceAll('100x100', '600x600'),
            tags: r['primaryGenreName'] ?? '',
          )).toList();
        }
      }
    } catch (_) {}

    // 2) 网易云（仅歌名+歌手，无封面）
    try {
      final uri = Uri.parse('https://music.163.com/api/search/get');
      final resp = await http.post(uri, body: {
        's': query,
        'type': '1',
        'limit': '5',
        'offset': '0',
      }, headers: {
        'Referer': 'https://music.163.com/',
        'User-Agent': 'Mozilla/5.0',
      }).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body);
      final songs = data['result']?['songs'] as List? ?? [];
      if (songs.isEmpty) return [];
      return songs.map((s) {
        final artists = (s['artists'] as List?)?.map((a) => a['name']).join(', ') ?? '';
        return MediaResult(
          title: s['name'] ?? '',
          creator: artists,
          imageUrl: '',
          tags: '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// ── 搜索书籍（豆瓣建议 → Open Library 双源） ──────
  static Future<List<MediaResult>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    // 1) 尝试豆瓣书籍建议 API
    final douban = await _searchDoubanBookSuggest(query);
    if (douban.isNotEmpty) return douban;

    // 2) Open Library（国内可访问）
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=5',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final docs = data['docs'] as List? ?? [];
        if (docs.isNotEmpty) {
          return docs.take(5).map((d) {
            final coverId = d['cover_i'];
            final coverUrl = coverId != null
                ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
                : '';
            final authors = (d['author_name'] as List?)?.join(', ') ?? '';
            final subjects = (d['subject'] as List?)?.take(3).join(',') ?? '';
            return MediaResult(
              title: d['title'] ?? '',
              creator: authors,
              imageUrl: coverUrl,
              tags: subjects,
            );
          }).toList();
        }
      }
    } catch (_) {}

    return [];
  }

  /// ── 搜索电影（豆瓣建议[仅电影] → iTunes） ──────
  static Future<List<MediaResult>> searchMovie(String query) async {
    if (query.trim().isEmpty) return [];

    // 豆瓣建议 API — 过滤掉有 episode 的（电视剧）
    final douban = await _searchDoubanMovieSuggest(query, tvOnly: false);
    if (douban.isNotEmpty) return douban;

    // iTunes 中国区
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=movie&limit=5&country=cn',
      );
      final resp = await http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body);
      final results = data['results'] as List? ?? [];
      return results.map((r) => MediaResult(
        title: r['trackName'] ?? '',
        creator: r['artistName'] ?? '',
        imageUrl: (r['artworkUrl100'] ?? '').toString().replaceAll('100x100', '600x600'),
        tags: r['primaryGenreName'] ?? '',
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// ── 搜索电视剧（豆瓣建议[有episode的] → iTunes） ──────
  static Future<List<MediaResult>> searchTV(String query) async {
    if (query.trim().isEmpty) return [];

    // 豆瓣建议 API — 只保留有 episode 的（电视剧）
    final douban = await _searchDoubanMovieSuggest(query, tvOnly: true);
    if (douban.isNotEmpty) return douban;

    // 不过滤 episode 再试一次（豆瓣可能全部标 movie）
    final doubanAll = await _searchDoubanMovieSuggest(query, tvOnly: null);
    if (doubanAll.isNotEmpty) return doubanAll;

    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=tvShow&limit=5&country=cn',
      );
      final resp = await http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body);
      final results = data['results'] as List? ?? [];
      return results.map((r) => MediaResult(
        title: r['trackName'] ?? r['collectionName'] ?? '',
        creator: r['artistName'] ?? '',
        imageUrl: (r['artworkUrl100'] ?? '').toString().replaceAll('100x100', '600x600'),
        tags: r['primaryGenreName'] ?? '',
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// ── 搜索游戏（豆瓣 → iTunes software） ──────
  static Future<List<MediaResult>> searchGame(String query) async {
    if (query.trim().isEmpty) return [];

    // 豆瓣通常也能搜到热门游戏（会在 movie suggest 里）
    final douban = await _searchDoubanMovieSuggest(query, tvOnly: null);
    if (douban.isNotEmpty) return douban;

    // iTunes 搜索手机游戏
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=software&limit=5&country=cn',
      );
      final resp = await http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body);
      final results = data['results'] as List? ?? [];
      return results.map((r) => MediaResult(
        title: r['trackName'] ?? '',
        creator: r['artistName'] ?? '',
        imageUrl: (r['artworkUrl512'] ?? r['artworkUrl100'] ?? '').toString(),
        tags: r['primaryGenreName'] ?? '',
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// ── 豆瓣电影/电视建议 API ──
  /// tvOnly: true=只要电视剧, false=只要电影, null=不过滤
  static Future<List<MediaResult>> _searchDoubanMovieSuggest(String query, {bool? tvOnly}) async {
    try {
      final uri = Uri.parse(
        'https://movie.douban.com/j/subject_suggest?q=${Uri.encodeComponent(query)}',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14)',
        'Referer': 'https://www.douban.com/',
      }).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body);
      if (list is! List || list.isEmpty) return [];
      var items = list.where((item) =>
          item['title'] != null && item['title'].toString().isNotEmpty);
      if (tvOnly != null) {
        items = items.where((item) {
          // 豆瓣用 episode 字段区分：有集数的是电视剧
          final ep = item['episode']?.toString() ?? '';
          final hasEpisode = ep.isNotEmpty && ep != '' && ep != '0';
          return tvOnly ? hasEpisode : !hasEpisode;
        });
      }
      return items.take(5).map((item) {
        return MediaResult(
          title: item['title']?.toString() ?? '',
          creator: item['sub_title']?.toString() ?? '',
          imageUrl: (item['img'] ?? '').toString(),
          tags: item['year']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// ── 豆瓣书籍建议 API ──
  static Future<List<MediaResult>> _searchDoubanBookSuggest(String query) async {
    try {
      final uri = Uri.parse(
        'https://book.douban.com/j/subject_suggest?q=${Uri.encodeComponent(query)}',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14)',
        'Referer': 'https://book.douban.com/',
      }).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body);
      if (list is! List || list.isEmpty) return [];
      return list.take(5).map((item) {
        return MediaResult(
          title: item['title']?.toString() ?? '',
          creator: item['author_name']?.toString() ?? item['sub_title']?.toString() ?? '',
          imageUrl: (item['pic'] ?? item['img'] ?? '').toString(),
          tags: item['year']?.toString() ?? '',
        );
      }).where((r) => r.title.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// 通用搜索（根据类型路由）
  static Future<List<MediaResult>> search(String mediaType, String query) async {
    switch (mediaType) {
      case 'music': return searchMusic(query);
      case 'book': return searchBooks(query);
      case 'movie': return searchMovie(query);
      case 'tv': return searchTV(query);
      case 'game': return searchGame(query);
      default: return [];
    }
  }
}

class MediaResult {
  final String title;
  final String creator;
  final String imageUrl;
  final String tags;

  MediaResult({
    required this.title,
    required this.creator,
    required this.imageUrl,
    required this.tags,
  });
}
