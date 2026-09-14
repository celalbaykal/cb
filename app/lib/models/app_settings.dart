class AppSettings {
  final int totalDailyLimitMinutes;
  final int warnBeforeMinutes;
  final String blockMessage;
  final int reblockCooldownMinutes;

  const AppSettings({
    this.totalDailyLimitMinutes = 120,
    this.warnBeforeMinutes = 10,
    this.blockMessage =
        "I promised myself I wouldn't lose more of today to this screen.",
    this.reblockCooldownMinutes = 15,
  });

  AppSettings copyWith({
    int? totalDailyLimitMinutes,
    int? warnBeforeMinutes,
    String? blockMessage,
    int? reblockCooldownMinutes,
  }) {
    return AppSettings(
      totalDailyLimitMinutes:
          totalDailyLimitMinutes ?? this.totalDailyLimitMinutes,
      warnBeforeMinutes: warnBeforeMinutes ?? this.warnBeforeMinutes,
      blockMessage: blockMessage ?? this.blockMessage,
      reblockCooldownMinutes:
          reblockCooldownMinutes ?? this.reblockCooldownMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'totalDailyLimitMinutes': totalDailyLimitMinutes,
        'warnBeforeMinutes': warnBeforeMinutes,
        'blockMessage': blockMessage,
        'reblockCooldownMinutes': reblockCooldownMinutes,
      };

  factory AppSettings.fromMap(Map map) => AppSettings(
        totalDailyLimitMinutes: (map['totalDailyLimitMinutes'] as int?) ?? 120,
        warnBeforeMinutes: (map['warnBeforeMinutes'] as int?) ?? 10,
        blockMessage: (map['blockMessage'] as String?) ??
            "I promised myself I wouldn't lose more of today to this screen.",
        reblockCooldownMinutes:
            (map['reblockCooldownMinutes'] as int?) ?? 15,
      );
}
