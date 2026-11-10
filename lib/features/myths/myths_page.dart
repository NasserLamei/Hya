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
  State<MythsPage> createState() => MythsPageState();
}

class MythsPageState extends State<MythsPage> {
  var _tab = 0;
  final _mythQuery = TextEditingController();
  final _mythCheck = TextEditingController();
  final _othersQuery = TextEditingController();
  final _myTitle = TextEditingController();
  final _myBody = TextEditingController();
  final _myTopic = TextEditingController();
  final _myWeek = TextEditingController();
  final _myPregnancyNumber = TextEditingController(text: '1');

  static const _othersPageSize = 10;

  var _checked = false;
  var _loadingOthers = false;
  var _loadingMoreOthers = false;
  var _savingMine = false;
  var _weekSeeded = false;
  var _showName = false;
  var _othersOffset = 0;
  var _othersHasMore = false;
  String? _saveNote;
  List<CommunityStory> _others = const [];

  @override
  void initState() {
    super.initState();
    _mythQuery.addListener(() => setState(() {}));
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
    _myWeek.text = (estimatedWeek != null && estimatedWeek > 0) ? '$estimatedWeek' : '1';
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
    _myPregnancyNumber.dispose();
    super.dispose();
  }

  Future<void> _loadOthers({bool append = false}) async {
    if (append) {
      if (_loadingMoreOthers || _loadingOthers || !_othersHasMore) return;
      setState(() => _loadingMoreOthers = true);
    } else {
      setState(() {
        _loadingOthers = true;
        _loadingMoreOthers = false;
        _othersOffset = 0;
        _othersHasMore = false;
      });
    }

    try {
      final offset = append ? _othersOffset : 0;
      final rows = await RemoteSync.fetchPublicStories(
        query: _othersQuery.text,
        limit: _othersPageSize,
        offset: offset,
        excludeUserId: RemoteSync.userId,
      );
      if (!mounted) return;
      setState(() {
        _others = append ? [..._others, ...rows] : rows;
        _othersOffset = offset + rows.length;
        _othersHasMore = rows.length >= _othersPageSize;
        _loadingOthers = false;
        _loadingMoreOthers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!append) _others = const [];
        _loadingOthers = false;
        _loadingMoreOthers = false;
        if (!append) _othersHasMore = false;
      });
    }
  }

  /// بيتنادى لما المستخدم يضغط تاب الحكاوي من تحت.
  Future<void> refreshFromTab() async {
    if (_tab == 1) {
      await _loadOthers();
    } else if (_tab == 2 && mounted) {
      await StoreScope.of(context).refreshMyStoriesFromCloud();
    } else if (_tab == 0) {
      setState(() {});
    }
  }

  void _maybeLoadMoreOthers(ScrollNotification notification) {
    if (_tab != 1 || !_othersHasMore || _loadingOthers || _loadingMoreOthers) return;
    if (notification is! ScrollUpdateNotification && notification is! OverscrollNotification) {
      return;
    }
    final metrics = notification.metrics;
    if (!metrics.hasPixels || !metrics.hasContentDimensions) return;
    if (metrics.pixels < metrics.maxScrollExtent - 240) return;
    _loadOthers(append: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _maybeLoadMoreOthers(notification);
        return false;
      },
      child: SoftPage(
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
      ),
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
          const HyaEmptyView(
            icon: Icons.search_off_rounded,
            title: 'مفيش نتيجة مطابقة',
            body: 'جرّبي كلمة تانية، أو افحصي الجملة فوق. مكتبة هي بتغطي الشائعات الشائعة بهدوء من غير تخويف.',
          )
        else
          for (final myth in myths) ...[
            _MythResult(myth: myth, compact: true),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _othersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _othersQuery,
          decoration: InputDecoration(
            hintText: 'دوّري في تجارب الآخرين… غثيان، نوم، خوف',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'بحث',
              onPressed: () => _loadOthers(),
              icon: const Icon(Icons.search_rounded),
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _loadOthers(),
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
          'للخصوصية: بنشوف السن والأسبوع ورقم الحمل (بكر ولا لأ). الاسم اختياري. الحكاوي مش تشخيص طبي.',
          size: 12.5,
          color: HyaColors.muted,
        ),
        const SizedBox(height: 12),
        if (_loadingOthers)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: HyaLoader(size: 64, label: 'بتحمّل الحكاوي...')),
          )
        else if (_others.isEmpty)
          const HyaEmptyView(
            icon: Icons.forum_outlined,
            title: 'لسه مفيش تجارب ظاهرة',
            body: 'لما الأمهات يكتبوا وينشروا، الحكاوي هتظهر هنا. اضغطي تاب الحكاوي تاني عشان تتحدّث القائمة.',
          )
        else ...[
          for (final story in _others) ...[
            _StoryCard(story: story),
            const SizedBox(height: 8),
          ],
          if (_loadingMoreOthers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: HyaLoader(size: 40, label: 'بتحمّل كمان...')),
            ),
        ],
      ],
    );
  }

  Widget _mineTab(AppStore store) {
    final stories = store.myStories;
    final profile = store.profile;
    final age = profile?.motherAge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HyaCard(
          color: const Color(0xFFFFF6F4),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: HyaColors.roseDeep, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: HyaText('اكتبي تجربتكِ', size: 18, weight: 760),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const HyaText(
                'حكاية شخصية بهدوء. السن بيتاخد من حسابكِ، ومش بديل عن كلام الطبيب.',
                size: 13,
                color: HyaColors.muted,
                height: 1.45,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HyaColors.line.withValues(alpha: 0.8)),
                ),
                child: Row(
                  children: [
                    Icon(
                      age == null ? Icons.info_outline_rounded : Icons.cake_rounded,
                      size: 18,
                      color: age == null ? HyaColors.goldDeep : HyaColors.roseDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HyaText(
                        age == null
                            ? 'سنكِ لسه مش متسجل — كمّليه من الإعدادات.'
                            : 'سنكِ في الحساب: $age سنة',
                        size: 13.5,
                        weight: 650,
                        color: age == null ? HyaColors.goldDeep : HyaColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('العنوان', hint: 'اختياري'),
              const SizedBox(height: 6),
              TextField(
                controller: _myTitle,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'مثال: أول أسبوع عرفت فيه',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('الأسبوع الكام؟', hint: 'من حسابكِ'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _myWeek,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'مثال: 12',
                            prefixIcon: Icon(Icons.calendar_month_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('الحمل رقم كام؟', hint: '١ = بكر'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _myPregnancyNumber,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: '١ بكر / ٢ تاني…',
                            prefixIcon: Icon(Icons.pregnant_woman_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const HyaText(
                'الأسبوع من بياناتكِ في هي. و«الحمل رقم كام» عشان نعرف بكر ولا عندكِ أطفال قبل كده.',
                size: 12,
                color: HyaColors.muted,
                height: 1.4,
              ),
              const SizedBox(height: 12),
              const _FieldLabel('الموضوع'),
              const SizedBox(height: 6),
              TextField(
                controller: _myTopic,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'حمل، غثيان، نوم…',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
              ),
              const SizedBox(height: 12),
              const _FieldLabel('التفاصيل'),
              const SizedBox(height: 6),
              TextField(
                controller: _myBody,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'اكتبي اللي حسيتيه أو اللي ساعدكِ…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HyaColors.line.withValues(alpha: 0.75)),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  value: _showName,
                  activeThumbColor: HyaColors.rose,
                  title: const HyaText('أظهري اسمي مع التجربة', size: 14, weight: 700),
                  subtitle: HyaText(
                    _showName
                        ? 'هيظهر اسمكِ مع السن وأسبوع الحمل.'
                        : 'للخصوصية: الاسم مش هيظهر، وهيتكتب «ماما» مع السن والأسبوع ورقم الحمل.',
                    size: 12,
                    color: HyaColors.muted,
                    height: 1.4,
                  ),
                  onChanged: (value) => setState(() => _showName = value),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _savingMine
                      ? null
                      : () async {
                          final week = int.tryParse(_myWeek.text.trim());
                          final pregnancyNumber = int.tryParse(_myPregnancyNumber.text.trim());
                          if (week == null) {
                            setState(() => _saveNote = 'اكتبي الأسبوع الكام.');
                            return;
                          }
                          if (pregnancyNumber == null) {
                            setState(() => _saveNote = 'اكتبي الحمل رقم كام (١ = بكر).');
                            return;
                          }
                          if (_myBody.text.trim().length < 8) {
                            setState(() => _saveNote = 'اكتبي تفاصيل أوضح شوية عن تجربتكِ.');
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
                            pregnancyNumber: pregnancyNumber,
                            showName: _showName,
                          );
                          if (!mounted) return;
                          setState(() {
                            _savingMine = false;
                            _saveNote = error ??
                                (RemoteSync.signedIn
                                    ? 'اتنشرت واتزامنت.'
                                    : 'اتحفظت على الموبايل. لما تسجّلي الدخول هتتزامن.');
                          });
                          if (error == null) {
                            _myTitle.clear();
                            _myBody.clear();
                            _myTopic.clear();
                            _myPregnancyNumber.text = '1';
                            _weekSeeded = false;
                            _seedWeek(store);
                            _loadOthers();
                          }
                        },
                  child: _savingMine
                      ? const HyaButtonLoader()
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('انشري تجربتي'),
                          ],
                        ),
                ),
              ),
              if (_saveNote != null) ...[
                const SizedBox(height: 10),
                HyaText(_saveNote!, size: 13, weight: 650, color: HyaColors.roseDeep),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: SectionLabel('تجاربي')),
            HyaText(
              stories.isEmpty ? 'فاضية' : '${stories.length}',
              size: 13,
              weight: 700,
              color: HyaColors.muted,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (stories.isEmpty)
          const HyaEmptyView(
            icon: Icons.edit_note_rounded,
            title: 'لسه ما كتبتيش تجربتكِ',
            body: 'اكتبي جملة عن يومكِ أو أسبوعكِ فوق، وانشريها. هي مساحة حكاوي، مش تشخيص طبي.',
          )
        else
          for (final story in stories) ...[
            _StoryCard(
              story: story,
              mine: true,
              onDelete: () => store.deleteStory(story.id),
            ),
            const SizedBox(height: 10),
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

}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HyaText(text, size: 13, weight: 720, color: HyaColors.ink),
        if (hint != null) ...[
          const SizedBox(width: 6),
          HyaText('($hint)', size: 12, color: HyaColors.muted),
        ],
      ],
    );
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
    final label = mine ? story.displayName : story.publicLabel;
    return HyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      story.showName || mine ? Icons.person_rounded : Icons.person_off_outlined,
                      size: 16,
                      color: HyaColors.sageDeep,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: HyaText(
                        label,
                        size: 13,
                        weight: 720,
                        color: HyaColors.sageDeep,
                      ),
                    ),
                  ],
                ),
              ),
              HyaText(formatDate(story.createdAt), size: 12, color: HyaColors.muted),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (story.pregnancyWeek != null)
                _MetaChip('الأسبوع ${story.pregnancyWeek}', const Color(0xFFFFF0ED), HyaColors.roseDeep),
              if (story.pregnancyNumber != null)
                _MetaChip(
                  story.pregnancyNumberLabel,
                  const Color(0xFFEAF4FF),
                  const Color(0xFF3D5A80),
                ),
              if (story.motherAge != null)
                _MetaChip('السن: ${story.motherAge}', HyaColors.amberSoft, HyaColors.goldDeep),
              _MetaChip(story.topic, HyaColors.sageSoft, HyaColors.sageDeep),
              if (!story.showName && !mine)
                const _MetaChip('بدون اسم', Color(0xFFF3E6EC), HyaColors.roseDeep),
            ],
          ),
          const SizedBox(height: 10),
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
