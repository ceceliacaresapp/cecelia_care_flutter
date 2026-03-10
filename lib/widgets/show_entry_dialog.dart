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

void _navigateToForm(BuildContext context, Widget form) {
  final navigator = Navigator.of(context);
  navigator.pop(); // Pop the dialog first
  navigator.push(MaterialPageRoute(builder: (_) => form));
}

void showEntryDialog(BuildContext context, {required VoidCallback onNewMessage}) {
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

  final String currentDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
                onTap: () {
                  _navigateToForm(
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
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.hotel_outlined),
                title: Text(l10n.careScreenButtonAddSleep),
                onTap: () {
                  _navigateToForm(
                    dialogContext,
                    ChangeNotifierProvider.value(
                      value: journalService,
                      child: SleepForm(
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_menu_outlined),
                title: Text(l10n.careScreenButtonAddFoodWater),
                onTap: () {
                  _navigateToForm(
                    dialogContext,
                    ChangeNotifierProvider.value(
                      value: journalService,
                      child: MealForm(
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.sentiment_satisfied_alt_outlined),
                title: Text(l10n.careScreenButtonAddMood),
                onTap: () {
                  _navigateToForm(
                    dialogContext,
                    ChangeNotifierProvider.value(
                      value: journalService,
                      child: MoodForm(
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.personal_injury_outlined),
                title: Text(l10n.careScreenButtonAddPain),
                onTap: () {
                  _navigateToForm(
                    dialogContext,
                    ChangeNotifierProvider.value(
                      value: journalService,
                      child: PainForm(
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_walk_outlined),
                title: Text(l10n.careScreenButtonAddActivity),
                onTap: () {
                  _navigateToForm(
                    dialogContext,
                    ChangeNotifierProvider.value(
                      value: journalService,
                      child: ActivityForm(
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart_outlined),
                title: Text(l10n.careScreenButtonAddVital),
                onTap: () {
                  _navigateToForm(
                    dialogContext,
                    ChangeNotifierProvider.value(
                      value: journalService,
                      child: VitalForm(
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.money_outlined),
                title: Text(l10n.careScreenButtonAddExpense),
                onTap: () {
                  _navigateToForm(
                    dialogContext,
                    ChangeNotifierProvider.value(
                      value: journalService,
                      child: ExpenseForm(
                        onClose: () => Navigator.of(dialogContext).pop(),
                        currentDate: currentDateStr,
                        activeElder: activeElder,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}