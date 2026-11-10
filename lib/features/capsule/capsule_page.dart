import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/cycle_math.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

class CapsulePage extends StatelessWidget {
  const CapsulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = DateTime.now();
    final notes = [...store.capsules]..sort((a, b) => a.unlockOn.compareTo(b.unlockOn));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const HyaText('كبسولة الزمن', weight: 720, size: 18),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HyaColors.rose,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CapsuleEditorPage()));
        },
        label: const Text('رسالة جديدة'),
        icon: const Icon(Icons.edit_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const HyaText(
            'اكتبي له وهو لسه صغير، والرسالة تفضل مقفولة لحد اليوم اللي تختارينه. اللي اتكتب يتفتح للقراءة بعد المعاد، ومش بيتعدل.',
            color: HyaColors.muted,
          ),
          const SizedBox(height: 14),
          if (notes.isEmpty)
            const HyaCard(
              child: HyaText('لسه مفيش رسائل. أول رسالة ممكن تكون جملة واحدة عن النهاردة.'),
            )
          else
            for (final note in notes) ...[
              _CapsuleCard(
                note: note,
                open: note.isOpenOn(today),
                onDelete: () => store.deleteCapsule(note.id),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  const _CapsuleCard({required this.note, required this.open, required this.onDelete});

  final CapsuleNote note;
  final bool open;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      color: open ? HyaColors.card : HyaColors.goldSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: HyaText(note.title.isEmpty ? 'رسالة من غير عنوان' : note.title, weight: 720)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: HyaColors.muted)),
            ],
          ),
          HyaText(
            open ? 'اتفتحت ${formatDate(note.unlockOn)}' : 'مقفولة لحد ${formatDate(note.unlockOn)}',
            size: 12.5,
            weight: 650,
            color: HyaColors.goldDeep,
          ),
          const SizedBox(height: 8),
          HyaText(
            open ? note.body : 'الكلام مستخبي لحد المعاد. تحتفظي بيه هنا، ويتزامن مع حسابك لو Supabase متوصل.',
            height: 1.65,
          ),
        ],
      ),
    );
  }
}

class CapsuleEditorPage extends StatefulWidget {
  const CapsuleEditorPage({super.key});

  @override
  State<CapsuleEditorPage> createState() => _CapsuleEditorPageState();
}

class _CapsuleEditorPageState extends State<CapsuleEditorPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  late DateTime _unlock;

  @override
  void initState() {
    super.initState();
    _unlock = DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile;
    final anchor = profile?.babyBirthDate ??
        (profile == null ? null : CycleMath.estimatedDueDate(profile)) ??
        DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const HyaText('رسالة جديدة', weight: 720, size: 18),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(hintText: 'عنوان قصير')),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(hintText: 'يا بيبي، النهاردة أنا...'),
          ),
          const SizedBox(height: 14),
          const HyaText('تتفتح امتى؟', weight: 720),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HyaChip(
                label: 'بعد سنة',
                selected: dateOnly(_unlock) == dateOnly(DateTime.now().add(const Duration(days: 365))),
                onTap: () => setState(() => _unlock = DateTime.now().add(const Duration(days: 365))),
              ),
              HyaChip(
                label: 'أول عيد ميلاد',
                selected: dateOnly(_unlock) == dateOnly(anchor.add(const Duration(days: 365))),
                onTap: () => setState(() => _unlock = anchor.add(const Duration(days: 365))),
              ),
              HyaChip(
                label: 'أول مدرسة',
                selected: dateOnly(_unlock) == dateOnly(DateTime(anchor.year + 6, anchor.month, anchor.day)),
                onTap: () => setState(() => _unlock = DateTime(anchor.year + 6, anchor.month, anchor.day)),
              ),
              HyaChip(
                label: 'تاريخ تاني',
                selected: false,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _unlock,
                    first: DateTime.now(),
                    last: DateTime(DateTime.now().year + 30),
                  );
                  if (picked != null) setState(() => _unlock = picked);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          HyaText('المعاد: ${formatDate(_unlock)}', color: HyaColors.muted),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              if (_body.text.trim().length < 2) return;
              await store.addCapsule(title: _title.text, body: _body.text, unlockOn: _unlock);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('اقفلي الرسالة'),
          ),
        ],
      ),
    );
  }
}
