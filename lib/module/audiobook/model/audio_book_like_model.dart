/// Answer of `POST /audiobooks/:id/like`, which toggles the like on a book.
///
/// Both fields are nullable so a backend that only acknowledges the call can
/// be told apart from one reporting the new state — the caller then flips its
/// own state instead of leaving a stale heart on screen.
class AudioBookLikeModel {
  final bool? liked;
  final int? likeCount;

  AudioBookLikeModel({this.liked, this.likeCount});

  factory AudioBookLikeModel.fromJson(Map<String, dynamic> json) {
    final liked = json['liked'] ?? json['isLiked'];
    final likeCount = json['likeCount'];

    return AudioBookLikeModel(
      liked: liked is bool ? liked : null,
      likeCount: likeCount is num ? likeCount.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'liked': liked, 'likeCount': likeCount};
  }
}
