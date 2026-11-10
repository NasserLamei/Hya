import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cycle_math.dart';
import 'ids.dart';
import 'models.dart';
import 'remote.dart';
import 'safety.dart';

class AppStore extends ChangeNotifier {
  Profile? profile;
  OnboardingDraft? draft;
  List<DailyLog> logs = [];
  List<CapsuleNote> capsules = [];
  List<BabyLogEntry> babyLogs = [];
  List<CommunityStory> myStories = [];
  Set<String> hospitalChecks = {};
  Set<String> vaccineChecks = {};
  bool onboardingDone = false;
  bool ready = false;
  bool passwordRecovery = false;
  String? syncNote;

  static const _profileKey = 'hya.profile';
  static const _draftKey = 'hya.draft';
  static const _onboardingKey = 'hya.onboardingDone';
  static const _logsKey = 'hya.logs';
  static const _capsulesKey = 'hya.capsules';
  static const _babyKey = 'hya.baby';
  static const _storiesKey = 'hya.stories';
  static const _hospitalKey = 'hya.hospital';
  static const _vaccineKey = 'hya.vaccines';

  String? get accountEmail => RemoteSync.email;
  bool get cloudReady => RemoteSync.ready;
  bool get signedIn => RemoteSync.signedIn;
  bool get needsAuth => onboardingDone && profile == null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    profile = _readProfile(prefs.getString(_profileKey));
    draft = _readDraft(prefs.getString(_draftKey));
    onboardingDone = prefs.getBool(_onboardingKey) ?? profile != null;
    logs = _readList(prefs.getString(_logsKey), DailyLog.fromJson);
    capsules = _readList(prefs.getString(_capsulesKey), CapsuleNote.fromJson);
    babyLogs = _readList(prefs.getString(_babyKey), BabyLogEntry.fromJson);
    myStories = _readList(prefs.getString(_storiesKey), CommunityStory.fromJson);
    hospitalChecks = (prefs.getStringList(_hospitalKey) ?? const []).toSet();
    vaccineChecks = (prefs.getStringList(_vaccineKey) ?? const []).toSet();
    await _pullIfNeeded();
    passwordRecovery = RemoteSync.passwordRecoveryPending;
    RemoteSync.passwordRecoveryEvents.listen((_) {
      passwordRecovery = true;
      notifyListeners();
    });
    ready = true;
    notifyListeners();
  }

  Future<void> finishOnboarding(OnboardingDraft value) async {
    draft = value;
    onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    await prefs.setString(_draftKey, jsonEncode(value.toJson()));
    notifyListeners();
  }

  Future<void> saveProfile(Profile value) async {
    profile = value.copyWith(updatedAt: DateTime.now());
    await _persist();
    await _guard(() => RemoteSync.pushProfile(
          profile: profile!,
          hospitalChecks: hospitalChecks,
          vaccineChecks: vaccineChecks,
        ));
    notifyListeners();
  }

  Future<void> clearAll() async {
    profile = null;
    draft = null;
    onboardingDone = false;
    logs = [];
    capsules = [];
    babyLogs = [];
    myStories = [];
    hospitalChecks = {};
    vaccineChecks = {};
    syncNote = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_draftKey);
    await prefs.remove(_onboardingKey);
    await prefs.remove(_logsKey);
    await prefs.remove(_capsulesKey);
    await prefs.remove(_babyKey);
    await prefs.remove(_storiesKey);
    await prefs.remove(_hospitalKey);
    await prefs.remove(_vaccineKey);
    notifyListeners();
  }

  DailyLog? logFor(DateTime day) {
    final target = dateOnly(day);
    for (final log in logs) {
      if (dateOnly(log.date) == target) return log;
    }
    return null;
  }

  Future<void> setMood(String mood) => _updateToday((log) => log.copyWith(mood: mood));

  Future<void> toggleSymptom(String symptom) {
    return _updateToday((log) {
      final next = [...log.symptoms];
      if (next.contains(symptom)) {
        next.remove(symptom);
      } else {
        next.add(symptom);
      }
      return log.copyWith(symptoms: next);
    });
  }

  Future<void> setTemperature(double? value) {
    return _updateToday((log) {
      if (value == null) return log.copyWith(clearTemperature: true);
      return log.copyWith(temperature: value);
    });
  }

  Future<void> addKicks(int delta) {
    return _updateToday((log) => log.copyWith(kicks: (log.kicks + delta).clamp(0, 200)));
  }

  Future<void> addCapsule({
    required String title,
    required String body,
    required DateTime unlockOn,
  }) async {
    final note = CapsuleNote(
      id: newId(),
      title: title.trim(),
      body: body.trim(),
      unlockOn: dateOnly(unlockOn),
      createdAt: DateTime.now(),
    );
    capsules = [note, ...capsules];
    await _persist();
    await _guard(() => RemoteSync.pushCapsule(note));
    notifyListeners();
  }

  Future<void> deleteCapsule(String id) async {
    capsules = capsules.where((note) => note.id != id).toList();
    await _persist();
    await _guard(() => RemoteSync.deleteCapsule(id));
    notifyListeners();
  }

  Future<void> addBabyLog(String type) async {
    final entry = BabyLogEntry(id: newId(), type: type, at: DateTime.now());
    babyLogs = [entry, ...babyLogs];
    if (babyLogs.length > 400) {
      babyLogs = babyLogs.take(400).toList();
    }
    await _persist();
    await _guard(() => RemoteSync.pushBabyLog(entry));
    notifyListeners();
  }

  Future<String?> addStory({
    required String title,
    required String body,
    required String topic,
    required int pregnancyWeek,
    bool isPublic = true,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedBody.length < 8) return 'اكتبي التجربة بجملتين على الأقل.';
    if (pregnancyWeek < 1 || pregnancyWeek > 45) return 'اختاري أسبوع الحمل من ١ لـ ٤٥.';
    if (profile?.motherAge == null) {
      return 'كمّلي سنكِ من الحساب أو بياناتك قبل ما تنشري التجربة.';
    }
    if (isRedFlag(trimmedBody) || isRedFlag(trimmedTitle)) {
      return 'لو الكلام عن نزيف أو حركة أقل أو صداع شديد: ده للدكتور أو الإسعاف ١٢٣، مش منشور.';
    }
    final name = (profile?.name.trim().isNotEmpty ?? false) ? profile!.name.trim().split(' ').first : 'ماما';
    final story = CommunityStory(
      id: newId(),
      userId: RemoteSync.userId ?? 'local',
      displayName: name,
      title: trimmedTitle.isEmpty ? 'تجربتي' : trimmedTitle,
      body: trimmedBody,
      topic: topic.trim().isEmpty ? 'حمل' : topic.trim(),
      pregnancyWeek: pregnancyWeek,
      motherAge: profile!.motherAge,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );
    myStories = [story, ...myStories];
    await _persist();
    await _guard(() => RemoteSync.pushStory(story));
    notifyListeners();
    return null;
  }

  Future<void> deleteStory(String id) async {
    myStories = myStories.where((story) => story.id != id).toList();
    await _persist();
    await _guard(() => RemoteSync.deleteStory(id));
    notifyListeners();
  }

  Future<void> refreshMyStoriesFromCloud() async {
    if (!RemoteSync.signedIn) return;
    final remote = await _guardValue(RemoteSync.fetchMyStories);
    if (remote == null) return;
    final map = {for (final story in myStories) story.id: story};
    for (final story in remote) {
      map[story.id] = story;
    }
    myStories = map.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persist();
    notifyListeners();
  }

  Future<void> toggleHospital(String id) async {
    hospitalChecks = {...hospitalChecks};
    if (!hospitalChecks.add(id)) hospitalChecks.remove(id);
    await _persist();
    await _pushProfile();
    notifyListeners();
  }

  Future<void> toggleVaccine(String id) async {
    vaccineChecks = {...vaccineChecks};
    if (!vaccineChecks.add(id)) vaccineChecks.remove(id);
    await _persist();
    await _pushProfile();
    notifyListeners();
  }

  String? lastFeedSide() {
    final feeds = babyLogs.where((entry) => entry.type == 'feed_left' || entry.type == 'feed_right').toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    if (feeds.isEmpty) return null;
    return feeds.first.type;
  }

  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String name,
    required int motherAge,
    String? photoPath,
    int? pregnancyWeek,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return const AuthOutcome(ok: false, message: 'اكتبي اسمكِ.');
    }
    if (motherAge < 14 || motherAge > 60) {
      return const AuthOutcome(ok: false, message: 'اكتبي سن صحيح (من ١٤ لـ ٦٠).');
    }
    final source = draft ??
        OnboardingDraft(
          mode: profile?.mode ?? LifeMode.pregnant,
          lastPeriodDate: profile?.lastPeriodDate,
          cycleLength: profile?.cycleLength ?? 28,
          expectedDueDate: profile?.expectedDueDate,
          babyName: profile?.babyName,
          babyBirthDate: profile?.babyBirthDate,
          deliveryType: profile?.deliveryType,
        );
    if (source.mode == LifeMode.pregnant) {
      final week = pregnancyWeek ?? source.estimatedPregnancyWeek();
      if (week == null || week < 1 || week > 45) {
        return const AuthOutcome(ok: false, message: 'اكتبي أسبوع الحمل (من ١ لـ ٤٥).');
      }
    }

    final outcome = await RemoteSync.signUp(
      email: email,
      password: password,
      name: cleanName,
      motherAge: motherAge,
    );
    syncNote = outcome.message;
    if (!outcome.ok) {
      notifyListeners();
      return outcome;
    }

    final built = source.toProfile(
      name: cleanName,
      motherAge: motherAge,
      photoPath: photoPath,
      pregnancyWeek: source.mode == LifeMode.pregnant
          ? (pregnancyWeek ?? source.estimatedPregnancyWeek())
          : null,
    );
    profile = built;
    onboardingDone = true;
    await _persist();
    await _persistDraftFlags();
    if (RemoteSync.signedIn) {
      await _afterAuth();
      await saveProfile(built);
    }
    notifyListeners();
    return outcome;
  }

  Future<AuthOutcome> signIn(String email, String password) async {
    final outcome = await RemoteSync.signIn(email: email, password: password);
    syncNote = outcome.message;
    if (outcome.ok && RemoteSync.signedIn) {
      await _afterAuth();
      final current = profile;
      final needsDraft = draft != null &&
          (current == null ||
              current.name.trim().isEmpty ||
              (draft!.mode == LifeMode.pregnant && current.lastPeriodDate == null));
      if (needsDraft) {
        final week = draft!.estimatedPregnancyWeek();
        profile = draft!.toProfile(
          name: current?.name.trim().isNotEmpty == true ? current!.name : 'ماما',
          motherAge: current?.motherAge ?? 25,
          photoPath: current?.photoPath,
          pregnancyWeek: draft!.mode == LifeMode.pregnant ? week : null,
        );
        await _persist();
        await saveProfile(profile!);
      }
      if (profile == null) {
        syncNote = 'الحساب موجود، بس مفيش بيانات رحلة محفوظة عليه. اعملي حساب جديد أو كمّلي من الإعدادات.';
        notifyListeners();
        return AuthOutcome(ok: false, message: syncNote!);
      }
      onboardingDone = true;
      await _persistDraftFlags();
    }
    notifyListeners();
    return outcome;
  }

  Future<AuthOutcome> sendResetLink(String email) async {
    final outcome = await RemoteSync.sendResetLink(email);
    syncNote = outcome.message;
    notifyListeners();
    return outcome;
  }

  Future<AuthOutcome> updatePassword(String password) async {
    final outcome = await RemoteSync.updatePassword(password);
    syncNote = outcome.message;
    if (outcome.ok) {
      passwordRecovery = false;
      RemoteSync.clearPasswordRecovery();
      await RemoteSync.signOut();
    }
    notifyListeners();
    return outcome;
  }

  void dismissPasswordRecovery() {
    passwordRecovery = false;
    RemoteSync.clearPasswordRecovery();
    notifyListeners();
  }

  Future<void> signOut() async {
    final current = profile;
    await RemoteSync.signOut();
    if (current != null) {
      draft = OnboardingDraft(
        mode: current.mode,
        lastPeriodDate: current.lastPeriodDate,
        cycleLength: current.cycleLength,
        expectedDueDate: current.expectedDueDate,
        babyName: current.babyName,
        babyBirthDate: current.babyBirthDate,
        deliveryType: current.deliveryType,
      );
    }
    profile = null;
    onboardingDone = true;
    syncNote = 'خرجتي من الحساب. دخّلي تاني أو اعملي حساب جديد.';
    await _persist();
    notifyListeners();
  }

  Future<void> _afterAuth() async {
    final remote = await _guardValue(RemoteSync.pull);
    if (remote == null) {
      await _pushEverything();
      return;
    }
    _merge(remote);
    await _persist();
    await _pushEverything();
  }

  Future<void> _pullIfNeeded() async {
    if (!RemoteSync.signedIn) return;
    final remote = await _guardValue(RemoteSync.pull);
    if (remote == null) return;
    _merge(remote);
    await _persist();
  }

  void _merge(RemoteSnapshot remote) {
    final local = profile;
    final remoteWins = local == null || !local.updatedAt.isAfter(remote.profile.updatedAt);
    if (remoteWins) {
      profile = remote.profile.copyWith(
        photoPath: local?.photoPath,
        motherAge: remote.profile.motherAge ?? local?.motherAge,
      );
      hospitalChecks = remote.hospitalChecks;
      vaccineChecks = remote.vaccineChecks;
    } else if (remote.profile.motherAge != null && local.motherAge == null) {
      profile = local.copyWith(motherAge: remote.profile.motherAge, photoUrl: remote.profile.photoUrl);
    }

    final byDate = {for (final log in logs) isoDate(log.date): log};
    for (final log in remote.logs) {
      final key = isoDate(log.date);
      final existing = byDate[key];
      if (existing == null || log.updatedAt.isAfter(existing.updatedAt)) {
        byDate[key] = log;
      }
    }
    logs = byDate.values.toList()..sort((a, b) => b.date.compareTo(a.date));

    final capsuleMap = {for (final note in capsules) note.id: note};
    for (final note in remote.capsules) {
      capsuleMap.putIfAbsent(note.id, () => note);
    }
    capsules = capsuleMap.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final babyMap = {for (final entry in babyLogs) entry.id: entry};
    for (final entry in remote.babyLogs) {
      babyMap.putIfAbsent(entry.id, () => entry);
    }
    babyLogs = babyMap.values.toList()..sort((a, b) => b.at.compareTo(a.at));
    if (babyLogs.length > 400) babyLogs = babyLogs.take(400).toList();
  }

  Future<void> _pushEverything() async {
    final current = profile;
    if (current == null) return;
    await _guard(() async {
      await RemoteSync.pushProfile(
        profile: current,
        hospitalChecks: hospitalChecks,
        vaccineChecks: vaccineChecks,
      );
      for (final log in logs) {
        await RemoteSync.pushLog(log);
      }
      for (final note in capsules) {
        await RemoteSync.pushCapsule(note);
      }
      for (final entry in babyLogs.take(80)) {
        await RemoteSync.pushBabyLog(entry);
      }
      for (final story in myStories.take(80)) {
        await RemoteSync.pushStory(story);
      }
    });
    await refreshMyStoriesFromCloud();
  }

  Future<void> _pushProfile() {
    final current = profile;
    if (current == null) return Future.value();
    return _guard(() => RemoteSync.pushProfile(
          profile: current,
          hospitalChecks: hospitalChecks,
          vaccineChecks: vaccineChecks,
        ));
  }

  Future<void> _updateToday(DailyLog Function(DailyLog log) change) async {
    final today = dateOnly(DateTime.now());
    final current = logFor(today) ??
        DailyLog(
          id: newId(),
          date: today,
          updatedAt: DateTime.now(),
        );
    final next = change(current).copyWith(updatedAt: DateTime.now());
    logs = [
      next,
      ...logs.where((log) => dateOnly(log.date) != today),
    ];
    await _persist();
    await _guard(() => RemoteSync.pushLog(next));
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (profile == null) {
      await prefs.remove(_profileKey);
    } else {
      await prefs.setString(_profileKey, jsonEncode(profile!.toJson()));
    }
    await prefs.setString(_logsKey, jsonEncode(logs.map((log) => log.toJson()).toList()));
    await prefs.setString(_capsulesKey, jsonEncode(capsules.map((note) => note.toJson()).toList()));
    await prefs.setString(_babyKey, jsonEncode(babyLogs.map((entry) => entry.toJson()).toList()));
    await prefs.setString(_storiesKey, jsonEncode(myStories.map((story) => story.toJson()).toList()));
    await prefs.setStringList(_hospitalKey, hospitalChecks.toList());
    await prefs.setStringList(_vaccineKey, vaccineChecks.toList());
    await _persistDraftFlags(prefs: prefs);
  }

  Future<void> _persistDraftFlags({SharedPreferences? prefs}) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    await store.setBool(_onboardingKey, onboardingDone);
    if (draft == null) {
      await store.remove(_draftKey);
    } else {
      await store.setString(_draftKey, jsonEncode(draft!.toJson()));
    }
  }

  OnboardingDraft? _readDraft(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return OnboardingDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (!RemoteSync.signedIn) return;
    try {
      await action();
      syncNote = null;
    } catch (_) {
      syncNote = 'التغيير محفوظ على الموبايل. المزامنة مع Supabase هتكمّل لما النت يظبط.';
    }
  }

  Future<T?> _guardValue<T>(Future<T?> Function() action) async {
    try {
      return await action();
    } catch (_) {
      syncNote = 'ما قدرناش نجيب النسخة السحابية دلوقتي. البيانات المحلية لسه موجودة.';
      return null;
    }
  }

  Profile? _readProfile(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  List<T> _readList<T>(String? raw, T Function(Map<String, dynamic> json) decode) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) decode(item) else if (item is Map) decode(item.cast<String, dynamic>()),
      ];
    } catch (_) {
      return [];
    }
  }
}
