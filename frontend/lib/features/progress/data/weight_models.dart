/// One recorded weigh-in.
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.recordedOn,
    required this.weightKg,
    this.note,
  });

  final int id;

  /// The day being recorded, not when it was typed.
  final DateTime recordedOn;

  final double weightKg;
  final String? note;

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as int,
        recordedOn: DateTime.parse(json['recorded_on'] as String),
        weightKg: (json['weight_kg'] as num).toDouble(),
        note: json['note'] as String?,
      );
}

/// The summary shown above the chart.
///
/// Every field is nullable: a new account has no history, and a screen that
/// needed all of this to render would show nothing at all.
class WeightTrend {
  const WeightTrend({
    this.latest,
    this.latestOn,
    this.starting,
    this.startingOn,
    this.target,
    this.totalChange,
    this.recentChange,
    this.toTarget,
    this.entryCount = 0,
  });

  final double? latest;
  final DateTime? latestOn;
  final double? starting;
  final DateTime? startingOn;
  final double? target;

  /// Signed: negative is a loss.
  final double? totalChange;
  final double? recentChange;

  /// Unsigned distance from the target.
  final double? toTarget;

  final int entryCount;

  bool get hasHistory => entryCount > 0;

  factory WeightTrend.fromJson(Map<String, dynamic> json) => WeightTrend(
        latest: (json['latest'] as num?)?.toDouble(),
        latestOn: json['latest_on'] == null
            ? null
            : DateTime.parse(json['latest_on'] as String),
        starting: (json['starting'] as num?)?.toDouble(),
        startingOn: json['starting_on'] == null
            ? null
            : DateTime.parse(json['starting_on'] as String),
        target: (json['target'] as num?)?.toDouble(),
        totalChange: (json['total_change'] as num?)?.toDouble(),
        recentChange: (json['recent_change'] as num?)?.toDouble(),
        toTarget: (json['to_target'] as num?)?.toDouble(),
        entryCount: json['entry_count'] as int? ?? 0,
      );
}

/// History and summary together, as the endpoint returns them.
class WeightHistory {
  const WeightHistory({required this.entries, required this.trend});

  /// Oldest first, which is the order the chart draws them in.
  final List<WeightEntry> entries;

  final WeightTrend trend;

  factory WeightHistory.fromJson(Map<String, dynamic> json) => WeightHistory(
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        trend: WeightTrend.fromJson(
          json['trend'] as Map<String, dynamic>? ?? const {},
        ),
      );
}