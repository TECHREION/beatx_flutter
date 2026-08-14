class SaveProgressData {
  final int positionMs;

  const SaveProgressData({this.positionMs = 0});

  factory SaveProgressData.fromJson(Map<String, dynamic> json) =>
      SaveProgressData(positionMs: (json['positionMs'] as num?)?.toInt() ?? 0);
}
