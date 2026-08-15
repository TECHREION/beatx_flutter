import 'package:get/get.dart';

/// A like the player screen can toggle for whatever is currently playing.
///
/// [PlayerController] is shared between songs, podcast episodes and
/// audiobooks, and each kind likes through its own endpoint. Implementations
/// bind themselves to the play session that loaded them, so at most one
/// reports [canLike] at a time and the screen can simply take the one that
/// does.
abstract class PlayerLikeTarget {
  /// Whether what is playing is liked right now.
  RxBool get isLiked;

  /// The last failure, or empty. Cleared when a toggle starts.
  RxString get errorMessage;

  /// Whether this target owns what the shared player is playing.
  bool get canLike;

  /// Likes what is playing, or unlikes it when it is already liked.
  Future<void> toggleLike();
}
