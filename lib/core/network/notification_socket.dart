import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Live notifications over Socket.IO.
///
/// The backend serves the `/notifications` namespace from the origin
/// `https://fahimstack.tech` on the path `/beatx-api/socket.io`, and reads the
/// access token from the handshake's `auth: {token}`. Each new notification
/// arrives as a `notification` event carrying `{notification, unreadCount}`.
///
/// The token is fetched afresh on every (re)connect, so a reconnection after a
/// token refresh uses the new token. `GET /notifications` stays the history
/// and the fallback for anything missed while disconnected.
class NotificationSocket {
  NotificationSocket({
    required this.origin,
    required this.path,
    required this.accessToken,
    this.namespace = '/notifications',
  });

  final String origin;
  final String path;
  final String namespace;

  /// Returns the current access token, or null when signed out.
  final Future<String?> Function() accessToken;

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// The namespace URL handed to the client, e.g.
  /// `https://fahimstack.tech/notifications`.
  @visibleForTesting
  String get namespaceUrl {
    final base = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    return '$base$namespace';
  }

  /// Connects, replacing any earlier connection.
  ///
  /// [onNotification] receives each `notification` event's payload;
  /// [onConnectionChanged] reports connect/disconnect for status displays.
  /// [onReconnected] runs on every connect after the first, so the caller can
  /// re-read what it may have missed.
  void connect({
    required void Function(Object? payload) onNotification,
    void Function(bool connected)? onConnectionChanged,
    VoidCallback? onReconnected,
  }) {
    disconnect();

    final options = io.OptionBuilder()
        .setTransports(['websocket'])
        .setPath(path)
        .enableForceNew()
        .enableReconnection()
        .disableAutoConnect()
        .setAuthFn((send) {
          accessToken().then(
            (token) => send({'token': token ?? ''}),
            onError: (_) => send({'token': ''}),
          );
        })
        .build();

    final socket = io.io(namespaceUrl, options);
    var connectedBefore = false;

    socket.onConnect((_) {
      onConnectionChanged?.call(true);
      if (connectedBefore) onReconnected?.call();
      connectedBefore = true;
    });
    socket.onDisconnect((_) => onConnectionChanged?.call(false));
    socket.onConnectError((error) {
      debugPrint('notification socket connect error: $error');
      onConnectionChanged?.call(false);
    });
    socket.on('notification', onNotification);

    _socket = socket;
    socket.connect();
  }

  /// Closes the connection, e.g. on sign-out.
  void disconnect() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
  }
}
