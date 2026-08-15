/// Answer of `POST /songs/:id/like`, which toggles the like on a song.
///
/// Both fields are nullable so a backend that only acknowledges the call can
/// be told apart from one reporting the new state — the caller then flips its
/// own state instead of leaving a stale heart on screen.
class SongLikeModel {
  final bool? liked;
  final int? likeCount;

  SongLikeModel({this.liked, this.likeCount});

  factory SongLikeModel.fromJson(Map<String, dynamic> json) {
    final liked = json['liked'] ?? json['isLiked'];
    final likeCount = json['likeCount'];

    return SongLikeModel(
      liked: liked is bool ? liked : null,
      likeCount: likeCount is num ? likeCount.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'liked': liked,
      'likeCount': likeCount,
    };
  }
}
