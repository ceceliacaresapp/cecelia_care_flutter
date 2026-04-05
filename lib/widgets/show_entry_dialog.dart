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
import 'package:cecelia_care_flutter/screens/forms/hydration_form.dart';
import 'package:cecelia_care_flutter/screens/forms/custom_entry_form.dart';
import 'package:cecelia_care_flutter/providers/custom_entry_types_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// FIX: _navigateToForm replaced with _showFormSheet.
//
// Previously each form was pushed as a full Scaffold page via
// MaterialPageRoute, which navigated the user completely away from the
// timeline — jarring and context-breaking.
//
// Now every form opens as a modal bottom sheet. The user stays visually
// oriented in the app, and dismissal (swipe down or the × button) returns
// them exactly where they were.
//
// Implementation notes:
//  - isScrollControlled: true lets the sheet grow up to 92% screen height
//    so even the longer forms (med, pain, vital) have enough room.
//  - useSafeArea: true keeps content clear of notches / home indicators.
//  - viewInsets.bottom padding pushes content up when the keyboard appears,
//    preventing fields from being hidden.
//  - Forms no longer have AppBars — they use FormSheetHeader instead.
// ---------------------------------------------------------------------------
void _showFormSheet(BuildContext context, Widget form) {
  Navigator.of(context, rootNavigator: true).pop(); // dismiss the entry-type picker dialog

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
              // Drag handle
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

  final String currentDateStr =
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.dialogTitleAddNewLog),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.message_outlined),
                title: Text(l10n.timelineNewMessageButton),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  onNewMessage();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.medical_services_outlined),
                title: Text(l10n.careScreenButtonAddMed),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.hotel_outlined),
                title: Text(l10n.careScreenButtonAddSleep),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.restaurant_menu_outlined),
                title: Text(l10n.careScreenButtonAddFoodWater),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.sentiment_satisfied_alt_outlined),
                title: Text(l10n.careScreenButtonAddMood),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.personal_injury_outlined),
                title: Text(l10n.careScreenButtonAddPain),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.directions_walk_outlined),
                title: Text(l10n.careScreenButtonAddActivity),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.monitor_heart_outlined),
                title: Text(l10n.careScreenButtonAddVital),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.money_outlined),
                title: Text(l10n.careScreenButtonAddExpense),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.swap_horiz_outlined),
                title: const Text('Shift Handoff'),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.water_drop_outlined,
                    color: Color(0xFF795548)),
                title: const Text('Incontinence'),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.nightlight_outlined,
                    color: Color(0xFF283593)),
                title: const Text('Night Waking'),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              ListTile(
                leading: const Icon(Icons.local_drink_outlined,
                    color: Color(0xFF0288D1)),
                title: const Text('Fluid Intake'),
                onTap: () => _showFormSheet(
                  dialogContext,
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
              // ── Custom entry types ──────────────────────────────
              Builder(builder: (ctx) {
                final customTypes =
                    ctx.watch<CustomEntryTypesProvider>().types;
                if (customTypes.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    const Divider(),
                    ...customTypes.map((t) => ListTile(
                          leading: Icon(t.iconData, color: t.color),
                          title: Text(t.name),
                          onTap: () => _showFormSheet(
                            dialogContext,
                            ChangeNotifierProvider.value(
                              value: journalService,
                              child: CustomEntryForm(
                                typeDef: t,
                                activeElder: activeElder,
                                currentDate: currentDateStr,
                              ),
                            ),
                          ),
                        )),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

void _noOp() {}
