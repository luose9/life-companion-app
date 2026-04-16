/// 爱好作品档案
class HobbyWork {
  int? id;
  int hobbyId;
  String? title;
  String? imagePath;     // 本地文件路径（图片/视频/GIF/音频等）
  String? mediaType;     // image, video, gif, audio, file
  String? note;
  String? emotion;       // 创作时的心情
  int? createdAt;

  HobbyWork({
    this.id,
    required this.hobbyId,
    this.title,
    this.imagePath,
    this.mediaType,
    this.note,
    this.emotion,
    this.createdAt,
  });

  factory HobbyWork.fromMap(Map<String, dynamic> m) => HobbyWork(
        id: m['id'] as int?,
        hobbyId: m['hobby_id'] as int,
        title: m['title'] as String?,
        imagePath: m['image_path'] as String?,
        mediaType: m['media_type'] as String?,
        note: m['note'] as String?,
        emotion: m['emotion'] as String?,
        createdAt: m['created_at'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'hobby_id': hobbyId,
        'title': title,
        'image_path': imagePath,
        'media_type': mediaType,
        'note': note,
        'emotion': emotion,
        'created_at': createdAt,
      };

  /// 根据文件扩展名推断媒体类型
  static String detectMediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'bmp', 'webp', 'heic', 'heif'].contains(ext)) return 'image';
    if (['gif'].contains(ext)) return 'gif';
    if (['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv', '3gp', 'webm'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma'].contains(ext)) return 'audio';
    return 'file';
  }
}
