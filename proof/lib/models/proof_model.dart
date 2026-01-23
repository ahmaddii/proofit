class ProofModel {
  final String proofId;
  final String userId;
  final String title;
  final String? description;
  final DateTime timestamp;
  final bool lockedFlag;
  final double? latitude;
  final double? longitude;
  final List<String> mediaUrls;
  final String? audioUrl;
  final String? textContent;
  final String contentHash;
  final String? encryptionIv;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProofModel({
    required this.proofId,
    required this.userId,
    required this.title,
    this.description,
    required this.timestamp,
    required this.lockedFlag,
    this.latitude,
    this.longitude,
    required this.mediaUrls,
    this.audioUrl,
    this.textContent,
    required this.contentHash,
    this.encryptionIv,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProofModel.fromJson(Map<String, dynamic> json) {
    return ProofModel(
      proofId: json['proof_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      lockedFlag: json['locked_flag'] as bool,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      mediaUrls: json['media_urls'] != null 
          ? List<String>.from(json['media_urls'] as List)
          : [],
      audioUrl: json['audio_url'] as String?,
      textContent: json['text_content'] as String?,
      contentHash: json['content_hash'] as String,
      encryptionIv: json['encryption_iv'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proof_id': proofId,
      'user_id': userId,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'locked_flag': lockedFlag,
      'latitude': latitude,
      'longitude': longitude,
      'media_urls': mediaUrls,
      'audio_url': audioUrl,
      'text_content': textContent,
      'content_hash': contentHash,
      'encryption_iv': encryptionIv,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProofModel copyWith({
    String? proofId,
    String? userId,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? lockedFlag,
    double? latitude,
    double? longitude,
    List<String>? mediaUrls,
    String? audioUrl,
    String? textContent,
    String? contentHash,
    String? encryptionIv,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProofModel(
      proofId: proofId ?? this.proofId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      lockedFlag: lockedFlag ?? this.lockedFlag,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      audioUrl: audioUrl ?? this.audioUrl,
      textContent: textContent ?? this.textContent,
      contentHash: contentHash ?? this.contentHash,
      encryptionIv: encryptionIv ?? this.encryptionIv,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}