// lib/widgets/show_entry_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/screens/forms/activity_form.dart';
import 'package:cecelia_care_flutter/screens/forms/expense_form.dart';
import 'package:cecelia_care_flutter/screens/forms/meal_form.dart';
import 'package:cecelia_care_flutter/screens/forms/med_form.dart';
import 'package:cecelia_care_flutter/screens/forms/mood_form.dart';
import 'package:cecelia_care_flutter/screens/forms/pain_form.dart';
import 'package:cecelia_care_flutter/screens/forms/sleep_form.dart';
import 'package:cecelia_care_flutter/screens/forms/vital_form.dart';
import 'package:cecelia_care_flutter/screens/forms/handoff_form.dart';
import 'package:cecelia_care_flutter/screens/forms/incontinence_form.dart';
import 'package:cecelia_care_flutter/screens/forms/night_waking_form.dart';
import 'package:cecelia_care_flutter/screens/forms/visitor_form.dart';
import 'package:cecelia_care_flutter/screens/forms/hydration_form.dart';
import 'package:cecelia_care_flutter/screens/forms/custom_entry_form.dart';
import 'package:cecelia_care_flutter/providers/custom_entry_types_provider.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/compact_grid_tile.dart';

// Opens a form as a modal bottom sheet (popping the picker screen first).
void _showFormSheet(BuildContext context, Widget form) {
  Navigator.of(context).pop(); // dismiss the picker screen

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 0),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(child: form),
            ],
          ),
        ),
      );
    },
  );
}

void showEntryDialog(
  BuildContext context, {
  VoidCallback onNewMessage = _noOp,
}) {
  final l10n = AppLocalizations.of(context)!;
  final activeElder =
      Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
  final journalService =
      Provider.of<JournalServiceProvider>(context, listen: false);

  if (activeElder == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.timelineSelectElderToPost)),
    );
    return;
  }

  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => _AddLogScreen(
        l10n: l10n,
        activeElder: activeElder,
        journalService: journalService,
        onNewMessage: onNewMessage,
      ),
    ),
  );
}

class _AddLogScreen extends StatelessWidget {
  final AppLocalizations l10n;
  final ElderProfile activeElder;
  final JournalServiceProvider journalService;
  final VoidCallback onNewMessage;

  const _AddLogScreen({
    required this.l10n,
    required this.activeElder,
    required this.journalService,
    required this.onNewMessage,
  });

  @override
  Widget build(BuildContext context) {
    final String currentDateStr =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final tiles = <_LogTile>[
      _LogTile(
        icon: Icons.message_outlined,
        label: l10n.timelineNewMessageButton,
        color: AppTheme.tileIndigo,
        onTap: () {
          Navigator.of(context).pop();
          onNewMessage();
        },
      ),
      _LogTile(
        icon: Icons.medical_services_outlined,
        label: l10n.careScreenButtonAddMed,
        color: AppTheme.tileRedDeep,
        onTap: () => _showFormSheet(
          context,
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: journalService),
              ChangeNotifierProvider(
                create: (_) => MedicationDefinitionsProvider()
                  ..updateForElder(activeElder),
              ),
            ],
            child: MedForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.hotel_outlined,
        label: l10n.careScreenButtonAddSleep,
        color: AppTheme.tileIndigoDark,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: SleepForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.restaurant_menu_outlined,
        label: l10n.careScreenButtonAddFoodWater,
        color: AppTheme.tileOrange,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: MealForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.local_drink_outlined,
        label: 'Fluid Intake',
        color: AppTheme.tileBlue,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: HydrationForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.sentiment_satisfied_alt_outlined,
        label: l10n.careScreenButtonAddMood,
        color: AppTheme.tilePurple,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: MoodForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.personal_injury_outlined,
        label: l10n.careScreenButtonAddPain,
        color: AppTheme.tileOrangeDeep,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: PainForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.directions_walk_outlined,
        label: l10n.careScreenButtonAddActivity,
        color: AppTheme.tileTeal,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: ActivityForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.monitor_heart_outlined,
        label: l10n.careScreenButtonAddVital,
        color: AppTheme.tilePink,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: VitalForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.money_outlined,
        label: l10n.careScreenButtonAddExpense,
        color: AppTheme.tileBlueDark,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: ExpenseForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.swap_horiz_outlined,
        label: 'Shift Handoff',
        color: AppTheme.tileIndigo,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: HandoffForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.water_drop_outlined,
        label: 'Incontinence',
        color: AppTheme.tileBrown,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: IncontinenceForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.people_outline,
        label: 'Visitor Log',
        color: AppTheme.tilePurple,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: VisitorForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
      _LogTile(
        icon: Icons.nightlight_outlined,
        label: 'Night Waking',
        color: AppTheme.tileIndigoDark,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: NightWakingForm(
              onClose: () {},
              currentDate: currentDateStr,
              activeElder: activeElder,
            ),
          ),
        ),
      ),
    ];

    final customTypes = context.watch<CustomEntryTypesProvider>().types;
    for (final t in customTypes) {
      tiles.add(_LogTile(
        icon: t.iconData,
        label: t.name,
        color: t.color,
        onTap: () => _showFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: CustomEntryForm(
              typeDef: t,
              activeElder: activeElder,
              currentDate: currentDateStr,
            ),
          ),
        ),
      ));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: Text(l10n.dialogTitleAddNewLog),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: tiles.length,
          itemBuilder: (_, i) {
            final t = tiles[i];
            return CompactGridTile(
              icon: t.icon,
              title: t.label,
              color: t.color,
              onTap: t.onTap,
            );
          },
        ),
      ),
    );
  }
}

class _LogTile {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _LogTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

void _noOp() {}
