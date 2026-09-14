class TrackedApp {
  final String packageId;
  final String displayName;
  final int dailyLimitMinutes;
  final int warnBeforeMinutes;

  const TrackedApp({
    required this.packageId,
    required this.displayName,
    required this.dailyLimitMinutes,
    this.warnBeforeMinutes = 5,
  });

  TrackedApp copyWith({
    String? displayName,
    int? dailyLimitMinutes,
    int? warnBeforeMinutes,
  }) {
    return TrackedApp(
      packageId: packageId,
      displayName: displayName ?? this.displayName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      warnBeforeMinutes: warnBeforeMinutes ?? this.warnBeforeMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'packageId': packageId,
        'displayName': displayName,
        'dailyLimitMinutes': dailyLimitMinutes,
        'warnBeforeMinutes': warnBeforeMinutes,
      };

  factory TrackedApp.fromMap(Map map) => TrackedApp(
        packageId: map['packageId'] as String,
        displayName: map['displayName'] as String,
        dailyLimitMinutes: map['dailyLimitMinutes'] as int,
        warnBeforeMinutes: (map['warnBeforeMinutes'] as int?) ?? 5,
      );
}
