import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../capsule/capsule_page.dart';
import '../medical/medical_page.dart';
import '../more/more_page.dart';
import '../myths/myths_page.dart';
import '../postpartum/postpartum_pages.dart';
import '../pregnant/pregnant_pages.dart';
import '../settings/settings_page.dart';
import '../ttc/ttc_pages.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  var _index = 0;
  final _mythsKey = GlobalKey<MythsPageState>();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final mode = store.profile?.mode ?? LifeMode.pregnant;
    final tabs = _tabs(mode);
    final current = _index.clamp(0, tabs.length - 1);
    final accent = switch (mode) {
      LifeMode.ttc => HyaColors.sage,
      LifeMode.pregnant => HyaColors.rose,
      LifeMode.postpartum => HyaColors.gold,
    };

    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: current,
                children: [for (final tab in tabs) tab.page],
              ),
            ),
            HyaNavBar(
              index: current,
              accent: accent,
              items: [for (final tab in tabs) (tab.icon, tab.label)],
              onChanged: (value) {
                final mythsIndex = tabs.indexWhere((tab) => tab.isMyths);
                setState(() => _index = value);
                if (mythsIndex == value) {
                  _mythsKey.currentState?.refreshFromTab();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_Tab> _tabs(LifeMode mode) {
    return switch (mode) {
      LifeMode.ttc => [
          const _Tab('اليوم', Icons.spa_rounded, TtcHomePage()),
          const _Tab('الاستعداد', Icons.favorite_rounded, TtcPrepPage()),
          const _Tab('الدورة', Icons.calendar_month_rounded, CyclePage()),
          _Tab('الحكاوي', Icons.forum_rounded, MythsPage(key: _mythsKey), isMyths: true),
        ],
      LifeMode.pregnant => [
          const _Tab('الرحلة', Icons.auto_awesome_rounded, PregnantHomePage()),
          const _Tab('دليلي', Icons.health_and_safety_rounded, MedicalPage()),
          _Tab('الحكاوي', Icons.forum_rounded, MythsPage(key: _mythsKey), isMyths: true),
          const _Tab('المزيد', Icons.apps_rounded, MorePage()),
        ],
      LifeMode.postpartum => const [
          _Tab('اليوم', Icons.child_care_rounded, PostpartumHomePage()),
          _Tab('السجل', Icons.edit_note_rounded, BabyLogPage()),
          _Tab('التطعيم', Icons.vaccines_rounded, VaccinesPage()),
          _Tab('التعافي', Icons.spa_rounded, RecoveryPage()),
        ],
    };
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.page, {this.isMyths = false});

  final String label;
  final IconData icon;
  final Widget page;
  final bool isMyths;
}

void openSettings(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
}

void openCapsule(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CapsulePage()));
}
