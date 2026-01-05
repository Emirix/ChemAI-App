class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String source;
  final String sourceLink;
  final String imageUrl;
  final DateTime publishedAt;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final String? contentFull;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.sourceLink,
    required this.imageUrl,
    required this.publishedAt,
    required this.category,
    required this.tags,
    required this.createdAt,
    this.contentFull,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      source: json['source'] ?? '',
      sourceLink: json['sourceLink'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : DateTime.now(),
      category: json['category'] ?? 'chemistry',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      contentFull: json['contentFull'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'sourceLink': sourceLink,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'contentFull': contentFull,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${publishedAt.day}.${publishedAt.month}.${publishedAt.year}';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'general_chemistry':
        return 'Genel Kimya';
      case 'biochemistry':
        return 'Biyokimya';
      case 'materials':
        return 'Malzeme Bilimi';
      case 'organic_chemistry':
        return 'Organik Kimya';
      default:
        return 'Kimya';
    }
  }
}

class NewsCategory {
  final String id;
  final String name;
  final String nameEn;

  NewsCategory({required this.id, required this.name, required this.nameEn});

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    return NewsCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'] ?? '',
    );
  }
}
