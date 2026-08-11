class LikeUnlikeModel {
  final bool liked;
  final int likeCount;

  LikeUnlikeModel({
    required this.liked,
    required this.likeCount,
  });

  factory LikeUnlikeModel.fromJson(Map<String, dynamic> json) {
    return LikeUnlikeModel(
      liked: json['liked'] ?? false,
      likeCount: json['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'liked': liked,
      'likeCount': likeCount,
    };
  }
}
