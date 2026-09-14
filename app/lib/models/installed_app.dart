class InstalledApp {
  final String packageId;
  final String displayName;

  const InstalledApp({required this.packageId, required this.displayName});

  factory InstalledApp.fromMap(Map map) => InstalledApp(
        packageId: map['packageId'] as String,
        displayName: map['displayName'] as String,
      );
}
