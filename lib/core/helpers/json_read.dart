/// Tolerant readers for API payloads: a missing or odd field reads as empty
/// rather than throwing and losing the rest of the response.
library;

String readId(Map<String, dynamic> json) =>
    (json['_id'] ?? json['id'] ?? '').toString();

String readString(Object? value) => value?.toString() ?? '';

int readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// A server money string such as `৳1,250.50`, or null when there is none.
String? readDisplay(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? readDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();

List<Map<String, dynamic>> readMaps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];

/// What to print in place of a money string the server did not send.
const String missingDisplay = '—';
