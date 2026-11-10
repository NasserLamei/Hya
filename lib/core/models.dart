import 'cycle_math.dart';

enum LifeMode { ttc, pregnant, postpartum }

enum DeliveryType { natural, cesarean }

LifeMode lifeModeFromJson(String? raw) {
  return switch (raw) {
    'ttc' => LifeMode.ttc,
    'postpartum' => LifeMode.postpartum,
    _ => LifeMode.pregnant,
  };
}

String lifeModeToJson(LifeMode mode) {
  return switch (mode) {
    LifeMode.ttc => 'ttc',
    LifeMode.pregnant => 'pregnant',
    LifeMode.postpartum => 'postpartum',
  };
}

class Profile {
  const Profile({
    required this.name,
    required this.mode,
    this.lastPeriodDate,
    this.cycleLength = 28,
    this.expectedDueDate,
    this.babyName,
    this.babyBirthDate,
    this.deliveryType,
    this.motherAge,
    this.photoPath,
    this.photoUrl,
    required this.updatedAt,
  });

  final String name;
  final LifeMode mode;
  final DateTime? lastPeriodDate;
  final int cycleLength;
  final DateTime? expectedDueDate;
  final String? babyName;
  final DateTime? babyBirthDate;
  final DeliveryType? deliveryType;
  final int? motherAge;
  final String? photoPath;
  final String? photoUrl;
  final DateTime updatedAt;

  Profile copyWith({
    String? name,
    LifeMode? mode,
    DateTime? lastPeriodDate,
    bool clearLastPeriod = false,
    int? cycleLength,
    DateTime? expectedDueDate,
    bool clearDueDate = false,
    String? babyName,
    DateTime? babyBirthDate,
    DeliveryType? deliveryType,
    bool clearDelivery = false,
    int? motherAge,
    bool clearMotherAge = false,
    String? photoPath,
    bool clearPhotoPath = false,
    String? photoUrl,
    bool clearPhotoUrl = false,
    DateTime? updatedAt,
  }) {
    return Profile(
      name: name ?? this.name,
      mode: mode ?? this.mode,
      lastPeriodDate: clearLastPeriod ? null : (lastPeriodDate ?? this.lastPeriodDate),
      cycleLength: cycleLength ?? this.cycleLength,
      expectedDueDate: clearDueDate ? null : (expectedDueDate ?? this.expectedDueDate),
      babyName: babyName ?? this.babyName,
      babyBirthDate: babyBirthDate ?? this.babyBirthDate,
      deliveryType: clearDelivery ? null : (deliveryType ?? this.deliveryType),
      motherAge: clearMotherAge ? null : (motherAge ?? this.motherAge),
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'mode': lifeModeToJson(mode),
        'lastPeriodDate': lastPeriodDate == null ? null : isoDate(lastPeriodDate!),
        'cycleLength': cycleLength,
        'expectedDueDate': expectedDueDate == null ? null : isoDate(expectedDueDate!),
        'babyName': babyName,
        'babyBirthDate': babyBirthDate == null ? null : isoDate(babyBirthDate!),
        'deliveryType': switch (deliveryType) {
          DeliveryType.natural => 'natural',
          DeliveryType.cesarean => 'cesarean',
          null => null,
        },
        'motherAge': motherAge,
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> json) {
    final delivery = json['deliveryType'] as String?;
    return Profile(
      name: (json['name'] as String?)?.trim() ?? '',
      mode: lifeModeFromJson(json['mode'] as String?),
      lastPeriodDate: parseIsoDate(json['lastPeriodDate'] as String?),
      cycleLength: (json['cycleLength'] as num?)?.toInt() ?? 28,
      expectedDueDate: parseIsoDate(json['expectedDueDate'] as String?),
      babyName: json['babyName'] as String?,
      babyBirthDate: parseIsoDate(json['babyBirthDate'] as String?),
      deliveryType: switch (delivery) {
        'natural' => DeliveryType.natural,
        'cesarean' => DeliveryType.cesarean,
        _ => null,
      },
      motherAge: (json['motherAge'] as num?)?.toInt(),
      photoPath: json['photoPath'] as String?,
      photoUrl: json['photoUrl'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class OnboardingDraft {
  const OnboardingDraft({
    required this.mode,
    this.lastPeriodDate,
    this.cycleLength = 28,
    this.expectedDueDate,
    this.babyName,
    this.babyBirthDate,
    this.deliveryType,
  });

  final LifeMode mode;
  final DateTime? lastPeriodDate;
  final int cycleLength;
  final DateTime? expectedDueDate;
  final String? babyName;
  final DateTime? babyBirthDate;
  final DeliveryType? deliveryType;

  int? estimatedPregnancyWeek([DateTime? today]) {
    if (mode != LifeMode.pregnant || lastPeriodDate == null) return null;
    final age = CycleMath.gestationalAge(lastPeriodDate!, dateOnly(today ?? DateTime.now()));
    if (age.week < 1) return 1;
    return age.week.clamp(1, 45);
  }

  Profile toProfile({
    required String name,
    required int motherAge,
    String? photoPath,
    int? pregnancyWeek,
  }) {
    var lmp = lastPeriodDate;
    var due = expectedDueDate;
    if (mode == LifeMode.pregnant) {
      if (pregnancyWeek != null) {
        lmp = CycleMath.lmpFromPregnancyWeek(pregnancyWeek);
        due = CycleMath.dueDateFromLmp(lmp);
      } else if (lmp != null && due == null) {
        due = CycleMath.dueDateFromLmp(lmp);
      } else if (due != null && lmp == null) {
        lmp = CycleMath.lmpFromDueDate(due);
      }
    }
    return Profile(
      name: name.trim(),
      mode: mode,
      lastPeriodDate: mode == LifeMode.postpartum ? null : lmp,
      cycleLength: cycleLength,
      expectedDueDate: mode == LifeMode.pregnant ? due : null,
      babyName: babyName,
      babyBirthDate: babyBirthDate,
      deliveryType: mode == LifeMode.postpartum ? deliveryType : null,
      motherAge: motherAge,
      photoPath: photoPath,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': lifeModeToJson(mode),
        'lastPeriodDate': lastPeriodDate == null ? null : isoDate(lastPeriodDate!),
        'cycleLength': cycleLength,
        'expectedDueDate': expectedDueDate == null ? null : isoDate(expectedDueDate!),
        'babyName': babyName,
        'babyBirthDate': babyBirthDate == null ? null : isoDate(babyBirthDate!),
        'deliveryType': switch (deliveryType) {
          DeliveryType.natural => 'natural',
          DeliveryType.cesarean => 'cesarean',
          null => null,
        },
      };

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) {
    final delivery = json['deliveryType'] as String?;
    return OnboardingDraft(
      mode: lifeModeFromJson(json['mode'] as String?),
      lastPeriodDate: parseIsoDate(json['lastPeriodDate'] as String?),
      cycleLength: (json['cycleLength'] as num?)?.toInt() ?? 28,
      expectedDueDate: parseIsoDate(json['expectedDueDate'] as String?),
      babyName: json['babyName'] as String?,
      babyBirthDate: parseIsoDate(json['babyBirthDate'] as String?),
      deliveryType: switch (delivery) {
        'natural' => DeliveryType.natural,
        'cesarean' => DeliveryType.cesarean,
        _ => null,
      },
    );
  }
}

class DailyLog {
  const DailyLog({
    required this.id,
    required this.date,
    this.mood,
    this.symptoms = const [],
    this.temperature,
    this.kicks = 0,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String? mood;
  final List<String> symptoms;
  final double? temperature;
  final int kicks;
  final DateTime updatedAt;

  DailyLog copyWith({
    String? mood,
    bool clearMood = false,
    List<String>? symptoms,
    double? temperature,
    bool clearTemperature = false,
    int? kicks,
    DateTime? updatedAt,
  }) {
    return DailyLog(
      id: id,
      date: date,
      mood: clearMood ? null : (mood ?? this.mood),
      symptoms: symptoms ?? this.symptoms,
      temperature: clearTemperature ? null : (temperature ?? this.temperature),
      kicks: kicks ?? this.kicks,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': isoDate(date),
        'mood': mood,
        'symptoms': symptoms,
        'temperature': temperature,
        'kicks': kicks,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as String,
      date: parseIsoDate(json['date'] as String?) ?? dateOnly(DateTime.now()),
      mood: json['mood'] as String?,
      symptoms: ((json['symptoms'] as List?) ?? const []).map((item) => item.toString()).toList(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      kicks: (json['kicks'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class CapsuleNote {
  const CapsuleNote({
    required this.id,
    required this.title,
    required this.body,
    required this.unlockOn,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime unlockOn;
  final DateTime createdAt;

  bool isOpenOn(DateTime today) => !dateOnly(today).isBefore(dateOnly(unlockOn));

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'unlockOn': isoDate(unlockOn),
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory CapsuleNote.fromJson(Map<String, dynamic> json) {
    return CapsuleNote(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      unlockOn: parseIsoDate(json['unlockOn'] as String?) ?? dateOnly(DateTime.now()),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class BabyLogEntry {
  const BabyLogEntry({
    required this.id,
    required this.type,
    required this.at,
    this.note,
  });

  final String id;
  final String type;
  final DateTime at;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'at': at.toUtc().toIso8601String(),
        'note': note,
      };

  factory BabyLogEntry.fromJson(Map<String, dynamic> json) {
    return BabyLogEntry(
      id: json['id'] as String,
      type: (json['type'] as String?) ?? 'diaper',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
    );
  }
}

class CommunityStory {
  const CommunityStory({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.title,
    required this.body,
    required this.topic,
    this.pregnancyWeek,
    this.motherAge,
    required this.isPublic,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String title;
  final String body;
  final String topic;
  final int? pregnancyWeek;
  final int? motherAge;
  final bool isPublic;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'displayName': displayName,
        'title': title,
        'body': body,
        'topic': topic,
        'pregnancyWeek': pregnancyWeek,
        'motherAge': motherAge,
        'isPublic': isPublic,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory CommunityStory.fromJson(Map<String, dynamic> json) {
    return CommunityStory(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? 'ماما',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      topic: (json['topic'] as String?) ?? 'حمل',
      pregnancyWeek: (json['pregnancyWeek'] as num?)?.toInt(),
      motherAge: (json['motherAge'] as num?)?.toInt(),
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
