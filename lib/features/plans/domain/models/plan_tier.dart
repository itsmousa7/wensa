enum PlanTier {
  basic,
  growth,
  pro;

  static PlanTier fromId(String? id) => switch (id) {
        'growth' => PlanTier.growth,
        'pro'    => PlanTier.pro,
        _        => PlanTier.basic,
      };

  String get id => name; // 'basic' | 'growth' | 'pro'

  bool operator >=(PlanTier other) => index >= other.index;
  bool operator <=(PlanTier other) => index <= other.index;
  bool operator >(PlanTier other)  => index > other.index;
  bool operator <(PlanTier other)  => index < other.index;
}
