import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../core/cycle_math.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/remote.dart';
import '../../core/safety.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../data/myths.dart';
import '../../widgets/ui.dart';

class MythsPage extends StatefulWidget {
  const MythsPage({super.key});

  @override
  State<MythsPage> createState() => _MythsPageState();
}

class _MythsPageState extends State<MythsPage> {
  var _tab = 0;
  final _mythQuery = TextEditingController();
  final _mythCheck = TextEditingController();
  final _othersQuery = TextEditingController();
  final _myTitle = TextEditingController();
  final _myBody = TextEditingController();
  final _myTopic = TextEditingController(text: 'حمل');
  final _myWeek = TextEditingController();

  var _checked = false;
  var _loadingOthers = false;
  var _savingMine = false;
  var _weekSeeded = false;
  String? _saveNote;
  List<CommunityStory> _others = const [];

  @override
  void initState() {
    super.initState();
    _mythQuery.addListener(() => setState(() {}));
    _othersQuery.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = StoreScope.of(context);
      store.refreshMyStoriesFromCloud();
      _seedWeek(store);
      _loadOthers();
    });
  }

  void _seedWeek(AppStore store) {
    if (_weekSeeded) return;
    final profile = store.profile;
    final lmp = profile == null ? null : CycleMath.estimatedLmp(profile);
    final estimatedWeek = lmp == null ? null : CycleMath.gestationalAge(lmp, DateTime.now()).week;
    if (estimatedWeek != null && estimatedWeek > 0) {
      _myWeek.text = '$estimatedWeek';
    }
    _weekSeeded = true;
  }

  @override
  void dispose() {
    _mythQuery.dispose();
    _mythCheck.dispose();
    _othersQuery.dispose();
    _myTitle.dispose();
    _myBody.dispose();
    _myTopic.dispose();
    _myWeek.dispose();
    super.dispose();
  }

  Future<void> _loadOthers() async {
    setState(() => _loadingOthers = true);
    try {
      final rows = await RemoteSync.fetchPublicStories(query: _othersQuery.text);
      if (!mounted) return;
      final me = RemoteSync.userId;
      setState(() {
        _others = [
          for (final story in rows)
            if (me == null || story.userId != me) story,
        ];
        _loadingOthers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _others = const [];
        _loadingOthers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);

    return SoftPage(
      children: [
        const PageHeader(kicker: 'خرافات وتجارب بهدوء', title: 'الحكاوي'),
        const SizedBox(height: 8),
        const HyaText(
          'هنا تفحصي الشائعات، وتقرأي تجارب ناس تانية، وتكتبي تجربتكِ من غير ما التطبيق يبقى دكتور.',
          color: HyaColors.muted,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            HyaChip(
              label: 'خرافات',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            HyaChip(
              label: 'تجارب الآخرين',
              selected: _tab == 1,
              onTap: () {
                setState(() => _tab = 1);
                _loadOthers();
              },
            ),
            HyaChip(
              label: 'تجربتي',
              selected: _tab == 2,
              onTap: () {
                setState(() => _tab = 2);
                store.refreshMyStoriesFromCloud();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_tab == 0) _mythsTab(),
        if (_tab == 1) _othersTab(),
        if (_tab == 2) _mineTab(store),
      ],
    );
  }

  Widget _mythsTab() {
    final filter = _mythQuery.text.trim();
    final myths = filter.isEmpty
        ? mythLibrary
        : [
            for (final myth in mythLibrary)
              if (_matchesMyth(myth, filter)) myth,
          ];
    final text = _mythCheck.text.trim();
    final red = text.isNotEmpty && isRedFlag(text);
    final match = text.isEmpty || red ? null : matchMyth(text, mythLibrary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _mythQuery,
          decoration: const InputDecoration(
            hintText: 'دوّري في الخرافات… مانجا، شكل البطن، أعشاب',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        const HyaText('أو الصقي جملة و افحصيها', size: 13, weight: 650, color: HyaColors.muted),
        const SizedBox(height: 8),
        TextField(
          controller: _mythCheck,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'مثلًا: المانجا بتشوّه الجنين'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => setState(() => _checked = true),
          child: const Text('افحصي الكلام'),
        ),
        const SizedBox(height: 12),
        if (_checked && text.isNotEmpty && red) const _UrgentCard(),
        if (_checked && text.isNotEmpty && !red && match != null) _MythResult(myth: match),
        if (_checked && text.isNotEmpty && !red && match == null)
          const HyaCard(
            child: HyaText(
              'الجملة دي مش في مكتبة هي. ما نطمناش وما نخوفناش. اسألي طبيب المتابعة، وخصوصًا لو الكلام عن دواء أو نزيف أو حركة البيبي.',
            ),
          ),
        const SizedBox(height: 16),
        SectionLabel(filter.isEmpty ? 'شائعات بتتكرر' : 'نتائج البحث (${myths.length})'),
        const SizedBox(height: 8),
        if (myths.isEmpty)
          const HyaCard(child: HyaText('مفيش خرافة مطابقة للكلمة دي. جرّبي كلمة تانية.'))
        else
          for (final myth in myths) ...[
            _MythResult(myth: myth, compact: true),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _othersTab() {
    final filter = _othersQuery.text.trim();
    final filtered = filter.isEmpty
        ? _others
        : [
            for (final story in _others)
              if (_matchesStory(story, filter)) story,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _othersQuery,
          decoration: const InputDecoration(
            hintText: 'دوّري في تجارب الآخرين… غثيان، نوم، خوف',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (_) => _loadOthers(),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: _loadingOthers ? null : _loadOthers,
          child: _loadingOthers ? const HyaButtonLoader(color: HyaColors.rose) : const Text('حدّثي القائمة'),
        ),
        const SizedBox(height: 10),
        if (!RemoteSync.ready)
          const HyaCard(
            color: HyaColors.amberSoft,
            child: HyaText(
              'Supabase لسه مش متوصل من المفاتيح. شغّلي الجدول community_stories من supabase/schema.sql وحطّي SUPABASE_URL و SUPABASE_ANON_KEY.',
              color: HyaColors.goldDeep,
            ),
          )
        else if (!RemoteSync.signedIn)
          const HyaCard(
            child: HyaText(
              'تقدري تقرأي التجارب العامة. عشان تنشري تجربتكِ وتزامنها، سجّلي الدخول من الإعدادات.',
            ),
          ),
        const SizedBox(height: 8),
        const HyaText(
          'التجارب حكاوي شخصية، مش تشخيص. لو حسيتي بحاجة خطيرة: الدكتور أو الإسعاف ١٢٣.',
          size: 12.5,
          color: HyaColors.muted,
        ),
        const SizedBox(height: 12),
        if (_loadingOthers)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: HyaLoader(size: 64, label: 'بتحمّل الحكاوي...')),
          )
        else if (filtered.isEmpty)
          const HyaCard(child: HyaText('لسه مفيش تجارب ظاهرة. لما حد يكتب وينشر، هتظهر هنا.'))
        else
          for (final story in filtered) ...[
            _StoryCard(story: story),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _mineTab(AppStore store) {
    final stories = store.myStories;
    final profile = store.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HyaText(
          'اكتبي تجربتكِ، وأسبوع الحمل. السن بيتاخد من حسابكِ لما تعملي لوجين.',
          size: 13,
          color: HyaColors.muted,
        ),
        const SizedBox(height: 10),
        HyaCard(
          color: const Color(0xFFFFF6F4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: HyaText(
            profile?.motherAge == null
                ? 'سنكِ لسه مش متسجل. كمّليه من الإعدادات ← الحساب أو بياناتك.'
                : 'سنكِ المتسجل: ${profile!.motherAge} سنة',
            size: 13.5,
            weight: 650,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _myTitle,
          decoration: const InputDecoration(hintText: 'عنوان قصير (اختياري)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _myWeek,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'أنا في الأسبوع الكام؟ (مثال: 8)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _myTopic,
          decoration: const InputDecoration(hintText: 'الموضوع: حمل / غثيان / نوم…'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _myBody,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'اكتبي تجربتكِ هنا…'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _savingMine
              ? null
              : () async {
                  final week = int.tryParse(_myWeek.text.trim());
                  if (week == null) {
                    setState(() => _saveNote = 'اكتبي رقم أسبوع الحمل.');
                    return;
                  }
                  setState(() {
                    _savingMine = true;
                    _saveNote = null;
                  });
                  final error = await store.addStory(
                    title: _myTitle.text,
                    body: _myBody.text,
                    topic: _myTopic.text,
                    pregnancyWeek: week,
                  );
                  if (!mounted) return;
                  setState(() {
                    _savingMine = false;
                    _saveNote = error ??
                        (RemoteSync.signedIn
                            ? 'اتسجلت واتزامنت على Supabase.'
                            : 'اتحفظت على الموبايل. لما تسجّلي الدخول هتتزامن.');
                  });
                  if (error == null) {
                    _myTitle.clear();
                    _myBody.clear();
                    _myTopic.text = 'حمل';
                    _loadOthers();
                  }
                },
          child: Text(_savingMine ? 'بيتحفظ…' : 'انشري تجربتي'),
        ),
        if (_saveNote != null) ...[
          const SizedBox(height: 8),
          HyaText(_saveNote!, size: 13, color: HyaColors.roseDeep),
        ],
        const SizedBox(height: 16),
        const SectionLabel('تجاربي'),
        const SizedBox(height: 8),
        if (stories.isEmpty)
          const HyaCard(child: HyaText('لسه ما كتبتيش حاجة. أول تجربة هتظهر هنا.'))
        else
          for (final story in stories) ...[
            _StoryCard(
              story: story,
              mine: true,
              onDelete: () => store.deleteStory(story.id),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  bool _matchesMyth(MythEntry myth, String raw) {
    final q = normalizeArabic(raw);
    if (q.isEmpty) return true;
    final hay = normalizeArabic('${myth.claim} ${myth.truth} ${myth.verdict} ${myth.keywords.join(' ')}');
    return hay.contains(q);
  }

  bool _matchesStory(CommunityStory story, String raw) {
    final q = normalizeArabic(raw);
    if (q.isEmpty) return true;
    final hay = normalizeArabic('${story.title} ${story.body} ${story.topic} ${story.displayName}');
    return hay.contains(q);
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard();

  @override
  Widget build(BuildContext context) {
    return const HyaCard(
      color: HyaColors.redSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyaText('دي مش خرافة تتفحصيها', size: 18, weight: 760, color: HyaColors.red),
          SizedBox(height: 6),
          HyaText(
            'النزيف، قلة الحركة، الصداع الشديد، الزغللة، ضيق النفس، أو نزول المياه محتاجين طبيب أو الإسعاف ١٢٣. التطبيق مش هيقولك إن البيبي كويس.',
            height: 1.6,
          ),
        ],
      ),
    );
  }
}

class _MythResult extends StatelessWidget {
  const _MythResult({required this.myth, this.compact = false});

  final MythEntry myth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyaText(myth.verdict, size: 12.5, weight: 700, color: HyaColors.roseDeep),
          const SizedBox(height: 4),
          HyaText(myth.claim, weight: 720, size: compact ? 15 : 17),
          const SizedBox(height: 6),
          HyaText(myth.truth, height: 1.6, size: compact ? 13.5 : 15),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        'من تطبيق هي\n${myth.claim}\n${myth.verdict}: ${myth.truth}\n\nالمعلومة استرشادية، والطبيب هو المرجع.',
                  ),
                );
              },
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('ابعتي الرد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.text, this.bg, this.fg);

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: HyaText(text, size: 11.5, weight: 650, color: fg),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, this.mine = false, this.onDelete});

  final CommunityStory story;
  final bool mine;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: HyaText(
                  story.displayName,
                  size: 12.5,
                  weight: 700,
                  color: HyaColors.sageDeep,
                ),
              ),
              HyaText(formatDate(story.createdAt), size: 12, color: HyaColors.muted),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaChip(story.topic, HyaColors.sageSoft, HyaColors.sageDeep),
              if (story.pregnancyWeek != null)
                _MetaChip('الأسبوع ${story.pregnancyWeek}', const Color(0xFFFFF0ED), HyaColors.roseDeep),
              if (story.motherAge != null)
                _MetaChip('السن ${story.motherAge}', HyaColors.amberSoft, HyaColors.goldDeep),
            ],
          ),
          const SizedBox(height: 8),
          HyaText(story.title, weight: 740, size: 16),
          const SizedBox(height: 6),
          HyaText(story.body, height: 1.6),
          if (mine && onDelete != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onDelete,
                child: const Text('امسحي'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
