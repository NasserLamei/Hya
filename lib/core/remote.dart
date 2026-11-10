import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'cycle_math.dart';
import 'models.dart';
import 'safety.dart';

class AuthOutcome {
  const AuthOutcome({required this.ok, required this.message});

  final bool ok;
  final String message;
}

class RemoteSnapshot {
  const RemoteSnapshot({
    required this.profile,
    required this.hospitalChecks,
    required this.vaccineChecks,
    required this.logs,
    required this.capsules,
    required this.babyLogs,
  });

  final Profile profile;
  final Set<String> hospitalChecks;
  final Set<String> vaccineChecks;
  final List<DailyLog> logs;
  final List<CapsuleNote> capsules;
  final List<BabyLogEntry> babyLogs;
}

class RemoteSync {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// لازم يتضاف في Supabase → Authentication → URL Configuration → Redirect URLs
  static const authCallbackUrl = 'hya://auth-callback';

  static bool get configured => url.isNotEmpty && anonKey.isNotEmpty;
  static bool ready = false;
  static bool passwordRecoveryPending = false;
  static final _recoveryEvents = StreamController<void>.broadcast();

  static Stream<void> get passwordRecoveryEvents => _recoveryEvents.stream;

  static Future<void> init() async {
    if (!configured) return;
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
    ready = true;
    _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        passwordRecoveryPending = true;
        _recoveryEvents.add(null);
      }
    });
  }

  static SupabaseClient get _client => Supabase.instance.client;

  static bool get signedIn => ready && _client.auth.currentSession != null;

  static String? get email => ready ? _client.auth.currentUser?.email : null;

  static String? get userId => ready ? _client.auth.currentUser?.id : null;

  static Future<bool> emailIsRegistered(String email) async {
    if (!ready) return false;
    try {
      final result = await _client.rpc('email_is_registered', params: {'check_email': email.trim()});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String name,
    required int motherAge,
  }) async {
    if (!ready) {
      return const AuthOutcome(
        ok: false,
        message: 'مفاتيح Supabase مش موجودة. التطبيق شغال على الموبايل من غير حساب لحد ما تتوصل.',
      );
    }
    final cleanEmail = email.trim();
    if (await emailIsRegistered(cleanEmail)) {
      return const AuthOutcome(ok: false, message: 'الإيميل ده متسجل قبل كده. دخّلي بيه أو جرّبي إيميل تاني.');
    }
    try {
      final response = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': name.trim(),
          'mother_age': motherAge,
        },
      );
      if (response.session == null) {
        return const AuthOutcome(
          ok: true,
          message: 'الحساب اتعمل. لو التفعيل بالإيميل شغّال في Supabase، افتحي الرسالة وبعدين سجّلي الدخول.',
        );
      }
      return const AuthOutcome(ok: true, message: 'الحساب اتسجل، والبيانات هتتزامن.');
    } catch (error) {
      return AuthOutcome(ok: false, message: _authMessage(error));
    }
  }

  static Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    if (!ready) {
      return const AuthOutcome(
        ok: false,
        message: 'مفاتيح Supabase مش موجودة. التطبيق شغال على الموبايل من غير حساب لحد ما تتوصل.',
      );
    }
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
      return const AuthOutcome(ok: true, message: 'تم الدخول، وجاري مزامنة البيانات.');
    } catch (error) {
      return AuthOutcome(ok: false, message: _authMessage(error));
    }
  }

  static Future<void> signOut() async {
    if (!signedIn) return;
    await _client.auth.signOut();
  }

  /// بيبعت إيميل الاستعادة، واللينك يفتح التطبيق (hya://auth-callback) مش localhost.
  static Future<AuthOutcome> sendResetLink(String email) async {
    if (!ready) {
      return const AuthOutcome(
        ok: false,
        message: 'مفاتيح Supabase مش موجودة. التطبيق شغال على الموبايل من غير حساب لحد ما تتوصل.',
      );
    }
    final cleanEmail = email.trim();
    if (!cleanEmail.contains('@')) {
      return const AuthOutcome(ok: false, message: 'اكتبي الإيميل عشان نبعتلكِ لينك تغيير كلمة السر.');
    }
    try {
      await _client.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: authCallbackUrl,
      );
      return const AuthOutcome(
        ok: true,
        message: 'بعتنا لينك على الإيميل. افتحيه من الموبايل وهيفتح تطبيق هي عشان تعيّني كلمة سر جديدة.',
      );
    } catch (error) {
      return AuthOutcome(ok: false, message: _authMessage(error));
    }
  }

  static void clearPasswordRecovery() {
    passwordRecoveryPending = false;
  }

  static Future<AuthOutcome> updatePassword(String password) async {
    if (!ready || !signedIn) {
      return const AuthOutcome(ok: false, message: 'لازم تكوني داخلة بحسابك عشان تغيّري كلمة السر.');
    }
    if (password.length < 6) {
      return const AuthOutcome(ok: false, message: 'كلمة السر لازم تبقى ٦ حروف على الأقل.');
    }
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      return const AuthOutcome(ok: true, message: 'كلمة السر اتغيرت.');
    } catch (error) {
      return AuthOutcome(ok: false, message: _authMessage(error));
    }
  }

  static Future<RemoteSnapshot?> pull() async {
    final id = userId;
    if (!signedIn || id == null) return null;
    final profileRow = await _client.from('profiles').select().eq('id', id).maybeSingle();
    if (profileRow == null) return null;

    final logRows = await _client.from('daily_logs').select().eq('user_id', id);
    final capsuleRows = await _client.from('time_capsules').select().eq('user_id', id);
    final babyRows = await _client.from('baby_logs').select().eq('user_id', id);

    return RemoteSnapshot(
      profile: _profileFromRow(profileRow),
      hospitalChecks: _stringSet(profileRow['hospital_checks']),
      vaccineChecks: _stringSet(profileRow['vaccine_checks']),
      logs: [
        for (final row in logRows as List) _logFromRow(row as Map),
      ],
      capsules: [
        for (final row in capsuleRows as List) _capsuleFromRow(row as Map),
      ],
      babyLogs: [
        for (final row in babyRows as List) _babyFromRow(row as Map),
      ],
    );
  }

  static Future<void> pushProfile({
    required Profile profile,
    required Set<String> hospitalChecks,
    required Set<String> vaccineChecks,
  }) async {
    final id = userId;
    if (!signedIn || id == null) return;
    await _client.from('profiles').upsert({
      'id': id,
      'full_name': profile.name,
      'current_mode': lifeModeToJson(profile.mode),
      'last_period_date': profile.lastPeriodDate == null ? null : isoDate(profile.lastPeriodDate!),
      'cycle_length': profile.cycleLength,
      'expected_due_date': profile.expectedDueDate == null ? null : isoDate(profile.expectedDueDate!),
      'baby_name': profile.babyName,
      'baby_birth_date': profile.babyBirthDate == null ? null : isoDate(profile.babyBirthDate!),
      'delivery_type': switch (profile.deliveryType) {
        DeliveryType.natural => 'natural',
        DeliveryType.cesarean => 'cesarean',
        null => null,
      },
      'mother_age': profile.motherAge,
      'photo_url': profile.photoUrl,
      'hospital_checks': hospitalChecks.toList(),
      'vaccine_checks': vaccineChecks.toList(),
    });
  }

  static Future<void> pushLog(DailyLog log) async {
    final id = userId;
    if (!signedIn || id == null) return;
    await _client.from('daily_logs').upsert({
      'user_id': id,
      'log_date': isoDate(log.date),
      'mood': log.mood,
      'symptoms': log.symptoms,
      'bb_temperature': log.temperature,
      'kicks': log.kicks,
    }, onConflict: 'user_id,log_date');
  }

  static Future<void> pushCapsule(CapsuleNote note) async {
    final id = userId;
    if (!signedIn || id == null) return;
    await _client.from('time_capsules').upsert({
      'id': note.id,
      'user_id': id,
      'title': note.title,
      'message_text': note.body,
      'unlock_date': isoDate(note.unlockOn),
      'created_at': note.createdAt.toUtc().toIso8601String(),
    });
  }

  static Future<void> deleteCapsule(String capsuleId) async {
    final id = userId;
    if (!signedIn || id == null) return;
    await _client.from('time_capsules').delete().eq('id', capsuleId).eq('user_id', id);
  }

  static Future<void> pushBabyLog(BabyLogEntry entry) async {
    final id = userId;
    if (!signedIn || id == null) return;
    await _client.from('baby_logs').upsert({
      'id': entry.id,
      'user_id': id,
      'log_type': entry.type,
      'note': entry.note,
      'logged_at': entry.at.toUtc().toIso8601String(),
    });
  }

  static Future<List<CommunityStory>> fetchPublicStories({String query = ''}) async {
    if (!ready) return const [];
    var request = _client
        .from('community_stories')
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(80);
    final rows = await request;
    final stories = [
      for (final row in rows as List) _storyFromRow(row as Map),
    ];
    final needle = normalizeArabic(query);
    if (needle.isEmpty) return stories;
    return [
      for (final story in stories)
        if (normalizeArabic('${story.title} ${story.body} ${story.topic} ${story.displayName}').contains(needle)) story,
    ];
  }

  static Future<List<CommunityStory>> fetchMyStories() async {
    final id = userId;
    if (!signedIn || id == null) return const [];
    final rows = await _client
        .from('community_stories')
        .select()
        .eq('user_id', id)
        .order('created_at', ascending: false);
    return [
      for (final row in rows as List) _storyFromRow(row as Map),
    ];
  }

  static Future<void> pushStory(CommunityStory story) async {
    final id = userId;
    if (!signedIn || id == null) return;
    await _client.from('community_stories').upsert({
      'id': story.id,
      'user_id': id,
      'display_name': story.displayName,
      'title': story.title,
      'body': story.body,
      'topic': story.topic,
      'pregnancy_week': story.pregnancyWeek,
      'mother_age': story.motherAge,
      'is_public': story.isPublic,
      'created_at': story.createdAt.toUtc().toIso8601String(),
    });
  }

  static Future<void> deleteStory(String storyId) async {
    final id = userId;
    if (!signedIn || id == null) return;
    await _client.from('community_stories').delete().eq('id', storyId).eq('user_id', id);
  }

  static CommunityStory _storyFromRow(Map row) {
    return CommunityStory(
      id: row['id'] as String,
      userId: (row['user_id'] as String?) ?? '',
      displayName: (row['display_name'] as String?) ?? 'ماما',
      title: (row['title'] as String?) ?? '',
      body: (row['body'] as String?) ?? '',
      topic: (row['topic'] as String?) ?? 'حمل',
      pregnancyWeek: (row['pregnancy_week'] as num?)?.toInt(),
      motherAge: (row['mother_age'] as num?)?.toInt(),
      isPublic: row['is_public'] as bool? ?? true,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  static Profile _profileFromRow(Map row) {
    final delivery = row['delivery_type'] as String?;
    return Profile(
      name: (row['full_name'] as String?)?.trim() ?? '',
      mode: lifeModeFromJson(row['current_mode'] as String?),
      lastPeriodDate: parseIsoDate(row['last_period_date'] as String?),
      cycleLength: (row['cycle_length'] as num?)?.toInt() ?? 28,
      expectedDueDate: parseIsoDate(row['expected_due_date'] as String?),
      babyName: row['baby_name'] as String?,
      babyBirthDate: parseIsoDate(row['baby_birth_date'] as String?),
      deliveryType: switch (delivery) {
        'natural' => DeliveryType.natural,
        'cesarean' => DeliveryType.cesarean,
        _ => null,
      },
      motherAge: (row['mother_age'] as num?)?.toInt(),
      photoUrl: row['photo_url'] as String?,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  static DailyLog _logFromRow(Map row) {
    final symptoms = row['symptoms'];
    return DailyLog(
      id: row['id'] as String,
      date: parseIsoDate(row['log_date'] as String?) ?? dateOnly(DateTime.now()),
      mood: row['mood'] as String?,
      symptoms: symptoms is List ? symptoms.map((item) => item.toString()).toList() : const [],
      temperature: (row['bb_temperature'] as num?)?.toDouble(),
      kicks: (row['kicks'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  static CapsuleNote _capsuleFromRow(Map row) {
    return CapsuleNote(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      body: (row['message_text'] as String?) ?? '',
      unlockOn: parseIsoDate(row['unlock_date'] as String?) ?? dateOnly(DateTime.now()),
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  static BabyLogEntry _babyFromRow(Map row) {
    return BabyLogEntry(
      id: row['id'] as String,
      type: (row['log_type'] as String?) ?? 'diaper',
      at: DateTime.tryParse(row['logged_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      note: row['note'] as String?,
    );
  }

  static Set<String> _stringSet(Object? raw) {
    if (raw is List) return raw.map((item) => item.toString()).toSet();
    return {};
  }

  static String _authMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('invalid login') || text.contains('invalid credentials')) {
      return 'الإيميل أو كلمة السر مش مظبوطين.';
    }
    if (text.contains('already registered') ||
        text.contains('already been registered') ||
        text.contains('user already exists') ||
        text.contains('email address has already been registered')) {
      return 'الإيميل ده متسجل قبل كده. دخّلي بيه أو جرّبي إيميل تاني.';
    }
    if (text.contains('redirect')) {
      return 'ضيفِ hya://auth-callback في Authentication → URL Configuration → Redirect URLs.';
    }
    if (text.contains('rate limit') || text.contains('over_email') || text.contains('email_send')) {
      return 'بعتي طلبات كتير. استنّي شوية وجرّبي تاني.';
    }
    if (text.contains('unable to validate email') ||
        text.contains('invalid email') ||
        text.contains('email address is invalid')) {
      return 'راجعي صيغة الإيميل.';
    }
    if (text.contains('password') && (text.contains('least') || text.contains('short') || text.contains('weak'))) {
      return 'كلمة السر لازم تبقى ٦ حروف على الأقل.';
    }
    if (text.contains('network') || text.contains('socket') || text.contains('failed host')) {
      return 'النتيجة ما وصلتش. اتأكدي من الإنترنت.';
    }
    return 'ما قدرناش نكمّل دلوقتي. اتأكدي إن Redirect URL متضاف في Supabase، وجرّبي تاني.';
  }
}
