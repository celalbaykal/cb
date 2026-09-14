class UsageSnapshot {
  final Map<String, int> minutesByPackage;
  final int totalMinutes;

  const UsageSnapshot({required this.minutesByPackage, required this.totalMinutes});

  factory UsageSnapshot.fromMap(Map raw) {
    final byPackage = <String, int>{};
    final rawByPackage = raw['minutesByPackage'];
    if (rawByPackage is Map) {
      rawByPackage.forEach((key, value) {
        byPackage[key.toString()] = (value as num).toInt();
      });
    }
    return UsageSnapshot(
      minutesByPackage: byPackage,
      totalMinutes: (raw['totalMinutes'] as num?)?.toInt() ??
          byPackage.values.fold(0, (sum, v) => sum + v),
    );
  }

  static const empty = UsageSnapshot(minutesByPackage: {}, totalMinutes: 0);
}
