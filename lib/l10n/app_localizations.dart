import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cecelia Care'**
  String get appTitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @manageElderProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Elder Profiles'**
  String get manageElderProfilesTitle;

  /// No description provided for @createProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfileButton;

  /// No description provided for @pleaseLogInToManageProfiles.
  ///
  /// In en, this message translates to:
  /// **'Please log in to manage elder profiles.'**
  String get pleaseLogInToManageProfiles;

  /// Title for the calendar screen, includes elder's name
  ///
  /// In en, this message translates to:
  /// **'Calendar for {elderName}'**
  String calendarScreenTitle(String elderName);

  /// No description provided for @formOptionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get formOptionOther;

  /// No description provided for @formLabelNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get formLabelNotesOptional;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @inviteButton.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteButton;

  /// No description provided for @activeButton.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeButton;

  /// No description provided for @setActiveButton.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get setActiveButton;

  /// No description provided for @sendInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInviteButton;

  /// No description provided for @formUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get formUnknownUser;

  /// No description provided for @timePickerHelpText.
  ///
  /// In en, this message translates to:
  /// **'SELECT TIME'**
  String get timePickerHelpText;

  /// No description provided for @expenseFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get expenseFormTitleEdit;

  /// No description provided for @expenseFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New Expense'**
  String get expenseFormTitleNew;

  /// No description provided for @expenseFormLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get expenseFormLabelDescription;

  /// No description provided for @expenseFormHintDescription.
  ///
  /// In en, this message translates to:
  /// **'e.g., Prescription refill'**
  String get expenseFormHintDescription;

  /// No description provided for @expenseFormValidationDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description.'**
  String get expenseFormValidationDescription;

  /// No description provided for @expenseFormLabelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseFormLabelAmount;

  /// No description provided for @expenseFormHintAmount.
  ///
  /// In en, this message translates to:
  /// **'e.g., 25.50'**
  String get expenseFormHintAmount;

  /// Validation error for empty expense amount
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get expenseFormValidationAmountEmpty;

  /// Validation error for invalid expense amount
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than 0'**
  String get expenseFormValidationAmountInvalid;

  /// No description provided for @expenseFormLabelCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseFormLabelCategory;

  /// No description provided for @expenseCategoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get expenseCategoryMedical;

  /// No description provided for @expenseCategoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get expenseCategoryGroceries;

  /// No description provided for @expenseCategorySupplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get expenseCategorySupplies;

  /// No description provided for @expenseCategoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get expenseCategoryHousehold;

  /// No description provided for @expenseCategoryPersonalCare.
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get expenseCategoryPersonalCare;

  /// No description provided for @expenseFormValidationCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get expenseFormValidationCategory;

  /// No description provided for @expenseFormHintNotes.
  ///
  /// In en, this message translates to:
  /// **'Add any relevant notes here...'**
  String get expenseFormHintNotes;

  /// No description provided for @formErrorFailedToUpdateExpense.
  ///
  /// In en, this message translates to:
  /// **'Failed to update expense. Please try again.'**
  String get formErrorFailedToUpdateExpense;

  /// No description provided for @formErrorFailedToSaveExpense.
  ///
  /// In en, this message translates to:
  /// **'Failed to save expense. Please try again.'**
  String get formErrorFailedToSaveExpense;

  /// No description provided for @mealFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Meal / Water Intake'**
  String get mealFormTitleEdit;

  /// No description provided for @mealFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Log Meal / Water Intake'**
  String get mealFormTitleNew;

  /// No description provided for @mealFormLabelIntakeType.
  ///
  /// In en, this message translates to:
  /// **'Intake Type'**
  String get mealFormLabelIntakeType;

  /// No description provided for @mealFormIntakeCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get mealFormIntakeCategoryFood;

  /// No description provided for @mealFormIntakeCategoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get mealFormIntakeCategoryWater;

  /// No description provided for @mealFormLabelMealType.
  ///
  /// In en, this message translates to:
  /// **'Meal Type'**
  String get mealFormLabelMealType;

  /// No description provided for @mealFormMealTypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealFormMealTypeBreakfast;

  /// No description provided for @mealFormMealTypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealFormMealTypeLunch;

  /// No description provided for @mealFormMealTypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealFormMealTypeSnack;

  /// No description provided for @mealFormMealTypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealFormMealTypeDinner;

  /// No description provided for @mealFormLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mealFormLabelDescription;

  /// No description provided for @mealFormHintFoodDescription.
  ///
  /// In en, this message translates to:
  /// **'e.g., Chicken soup, toast'**
  String get mealFormHintFoodDescription;

  /// No description provided for @mealFormValidationFoodDescription.
  ///
  /// In en, this message translates to:
  /// **'Please describe the food.'**
  String get mealFormValidationFoodDescription;

  /// No description provided for @mealFormLabelWaterContext.
  ///
  /// In en, this message translates to:
  /// **'Water Context (Optional)'**
  String get mealFormLabelWaterContext;

  /// No description provided for @mealFormHintWaterContext.
  ///
  /// In en, this message translates to:
  /// **'e.g., With medication, Thirsty'**
  String get mealFormHintWaterContext;

  /// No description provided for @mealFormLabelWaterAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get mealFormLabelWaterAmount;

  /// No description provided for @mealFormHintWaterAmount.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1 glass, 200ml'**
  String get mealFormHintWaterAmount;

  /// No description provided for @mealFormValidationWaterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please specify the amount of water.'**
  String get mealFormValidationWaterAmount;

  /// No description provided for @mealFormHintFoodNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Ate well, disliked carrots'**
  String get mealFormHintFoodNotes;

  /// No description provided for @mealFormHintWaterNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Drank slowly'**
  String get mealFormHintWaterNotes;

  /// No description provided for @formErrorFailedToUpdateMeal.
  ///
  /// In en, this message translates to:
  /// **'Failed to update meal. Please try again.'**
  String get formErrorFailedToUpdateMeal;

  /// No description provided for @formErrorFailedToSaveMeal.
  ///
  /// In en, this message translates to:
  /// **'Failed to save meal. Please try again.'**
  String get formErrorFailedToSaveMeal;

  /// No description provided for @eventFormHintSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get eventFormHintSelectTime;

  /// No description provided for @mealFormLabelCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get mealFormLabelCalories;

  /// No description provided for @mealFormHintCalories.
  ///
  /// In en, this message translates to:
  /// **'e.g., 500'**
  String get mealFormHintCalories;

  /// No description provided for @sleepFormHintQuality.
  ///
  /// In en, this message translates to:
  /// **'Rate quality (1-10)'**
  String get sleepFormHintQuality;

  /// No description provided for @sleepFormValidationQualityRange.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number between 1 and 10'**
  String get sleepFormValidationQualityRange;

  /// No description provided for @medFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get medFormTitleEdit;

  /// No description provided for @medFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Log Medication'**
  String get medFormTitleNew;

  /// No description provided for @medFormTimePickerHelpText.
  ///
  /// In en, this message translates to:
  /// **'SELECT MEDICATION TIME'**
  String get medFormTimePickerHelpText;

  /// No description provided for @medFormLabelName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medFormLabelName;

  /// No description provided for @medFormHintNameCustom.
  ///
  /// In en, this message translates to:
  /// **'Or type custom medication name'**
  String get medFormHintNameCustom;

  /// No description provided for @medFormHintName.
  ///
  /// In en, this message translates to:
  /// **'Enter medication name'**
  String get medFormHintName;

  /// No description provided for @medFormValidationName.
  ///
  /// In en, this message translates to:
  /// **'Please enter medication name.'**
  String get medFormValidationName;

  /// No description provided for @medFormLabelDose.
  ///
  /// In en, this message translates to:
  /// **'Dose (Optional)'**
  String get medFormLabelDose;

  /// No description provided for @medFormHintDose.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1 tablet, 10mg'**
  String get medFormHintDose;

  /// No description provided for @medFormLabelTime.
  ///
  /// In en, this message translates to:
  /// **'Time (Optional)'**
  String get medFormLabelTime;

  /// No description provided for @medFormHintTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get medFormHintTime;

  /// No description provided for @medFormLabelMarkAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get medFormLabelMarkAsTaken;

  /// No description provided for @formErrorFailedToUpdateMed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update medication. Please try again.'**
  String get formErrorFailedToUpdateMed;

  /// No description provided for @formErrorFailedToSaveMed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save medication. Please try again.'**
  String get formErrorFailedToSaveMed;

  /// No description provided for @moodFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Mood'**
  String get moodFormTitleEdit;

  /// No description provided for @moodFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Log Mood'**
  String get moodFormTitleNew;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'😊 Happy'**
  String get moodHappy;

  /// No description provided for @moodContent.
  ///
  /// In en, this message translates to:
  /// **'🙂 Content'**
  String get moodContent;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'😟 Sad'**
  String get moodSad;

  /// No description provided for @moodAnxious.
  ///
  /// In en, this message translates to:
  /// **'😬 Anxious'**
  String get moodAnxious;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'😌 Calm'**
  String get moodCalm;

  /// No description provided for @moodIrritable.
  ///
  /// In en, this message translates to:
  /// **'😠 Irritable'**
  String get moodIrritable;

  /// No description provided for @moodAgitated.
  ///
  /// In en, this message translates to:
  /// **'😫 Agitated'**
  String get moodAgitated;

  /// No description provided for @moodPlayful.
  ///
  /// In en, this message translates to:
  /// **'🥳 Playful'**
  String get moodPlayful;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'😴 Tired'**
  String get moodTired;

  /// No description provided for @moodOptionOther.
  ///
  /// In en, this message translates to:
  /// **'📝 Other'**
  String get moodOptionOther;

  /// No description provided for @moodFormLabelSelectMood.
  ///
  /// In en, this message translates to:
  /// **'Select Mood'**
  String get moodFormLabelSelectMood;

  /// Validation error for missing mood selection
  ///
  /// In en, this message translates to:
  /// **'Please select a mood or specify \'Other\''**
  String get moodFormValidationSelectOrSpecifyMood;

  /// Validation error for missing 'Other' mood description
  ///
  /// In en, this message translates to:
  /// **'Please specify the \'Other\' mood'**
  String get moodFormValidationSpecifyOtherMood;

  /// No description provided for @moodFormHintSpecifyOtherMood.
  ///
  /// In en, this message translates to:
  /// **'Describe the mood...'**
  String get moodFormHintSpecifyOtherMood;

  /// No description provided for @moodFormLabelIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity (1-5, Optional)'**
  String get moodFormLabelIntensity;

  /// No description provided for @moodFormHintIntensity.
  ///
  /// In en, this message translates to:
  /// **'1 (Mild) - 5 (Severe)'**
  String get moodFormHintIntensity;

  /// Validation error for mood intensity range
  ///
  /// In en, this message translates to:
  /// **'Intensity must be between 1 and 5'**
  String get moodFormValidationIntensityRange;

  /// No description provided for @moodFormHintNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Feeling good after a walk'**
  String get moodFormHintNotes;

  /// No description provided for @moodFormButtonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Mood'**
  String get moodFormButtonUpdate;

  /// No description provided for @moodFormButtonSave.
  ///
  /// In en, this message translates to:
  /// **'Save Mood'**
  String get moodFormButtonSave;

  /// No description provided for @formErrorFailedToUpdateMood.
  ///
  /// In en, this message translates to:
  /// **'Failed to update mood. Please try again.'**
  String get formErrorFailedToUpdateMood;

  /// No description provided for @formErrorFailedToSaveMood.
  ///
  /// In en, this message translates to:
  /// **'Failed to save mood. Please try again.'**
  String get formErrorFailedToSaveMood;

  /// No description provided for @painFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Pain Log'**
  String get painFormTitleEdit;

  /// No description provided for @painFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Log Pain'**
  String get painFormTitleNew;

  /// No description provided for @painTypeAching.
  ///
  /// In en, this message translates to:
  /// **'Aching'**
  String get painTypeAching;

  /// No description provided for @painTypeBurning.
  ///
  /// In en, this message translates to:
  /// **'Burning'**
  String get painTypeBurning;

  /// No description provided for @painTypeDull.
  ///
  /// In en, this message translates to:
  /// **'Dull'**
  String get painTypeDull;

  /// No description provided for @painTypeSharp.
  ///
  /// In en, this message translates to:
  /// **'Sharp'**
  String get painTypeSharp;

  /// No description provided for @painTypeShooting.
  ///
  /// In en, this message translates to:
  /// **'Shooting'**
  String get painTypeShooting;

  /// No description provided for @painTypeStabbing.
  ///
  /// In en, this message translates to:
  /// **'Stabbing'**
  String get painTypeStabbing;

  /// No description provided for @painTypeThrobbing.
  ///
  /// In en, this message translates to:
  /// **'Throbbing'**
  String get painTypeThrobbing;

  /// No description provided for @painTypeTender.
  ///
  /// In en, this message translates to:
  /// **'Tender'**
  String get painTypeTender;

  /// No description provided for @painFormLabelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get painFormLabelLocation;

  /// No description provided for @painFormHintLocation.
  ///
  /// In en, this message translates to:
  /// **'e.g., Left knee, Lower back'**
  String get painFormHintLocation;

  /// No description provided for @painFormValidationLocation.
  ///
  /// In en, this message translates to:
  /// **'Please specify the location of pain.'**
  String get painFormValidationLocation;

  /// No description provided for @painFormLabelIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity (0-10)'**
  String get painFormLabelIntensity;

  /// No description provided for @painFormHintIntensity.
  ///
  /// In en, this message translates to:
  /// **'0 (No pain) - 10 (Worst pain)'**
  String get painFormHintIntensity;

  /// No description provided for @painFormValidationIntensityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter pain intensity.'**
  String get painFormValidationIntensityEmpty;

  /// No description provided for @painFormValidationIntensityRange.
  ///
  /// In en, this message translates to:
  /// **'Intensity must be between 0 and 10.'**
  String get painFormValidationIntensityRange;

  /// No description provided for @painFormLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get painFormLabelDescription;

  /// Validation error for missing pain description
  ///
  /// In en, this message translates to:
  /// **'Please select a description or specify \'Other\''**
  String get painFormValidationSelectOrSpecifyDescription;

  /// Validation error for missing 'Other' pain description
  ///
  /// In en, this message translates to:
  /// **'Please specify the \'Other\' description'**
  String get painFormValidationSpecifyOtherDescription;

  /// No description provided for @painFormHintSpecifyOtherDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe the pain...'**
  String get painFormHintSpecifyOtherDescription;

  /// No description provided for @painFormHintNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Worse after activity, relieved by rest'**
  String get painFormHintNotes;

  /// No description provided for @formErrorFailedToUpdatePain.
  ///
  /// In en, this message translates to:
  /// **'Failed to update pain log. Please try again.'**
  String get formErrorFailedToUpdatePain;

  /// No description provided for @formErrorFailedToSavePain.
  ///
  /// In en, this message translates to:
  /// **'Failed to save pain log. Please try again.'**
  String get formErrorFailedToSavePain;

  /// No description provided for @sleepFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Sleep Log'**
  String get sleepFormTitleEdit;

  /// No description provided for @sleepFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep'**
  String get sleepFormTitleNew;

  /// No description provided for @sleepQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get sleepQualityGood;

  /// No description provided for @sleepQualityFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get sleepQualityFair;

  /// No description provided for @sleepQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepQualityPoor;

  /// No description provided for @sleepQualityRestless.
  ///
  /// In en, this message translates to:
  /// **'Restless'**
  String get sleepQualityRestless;

  /// No description provided for @sleepQualityInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get sleepQualityInterrupted;

  /// No description provided for @sleepFormLabelWentToBed.
  ///
  /// In en, this message translates to:
  /// **'Went to Bed'**
  String get sleepFormLabelWentToBed;

  /// No description provided for @sleepFormHintTimeWentToBed.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get sleepFormHintTimeWentToBed;

  /// No description provided for @sleepFormValidationTimeWentToBed.
  ///
  /// In en, this message translates to:
  /// **'Please select time went to bed.'**
  String get sleepFormValidationTimeWentToBed;

  /// No description provided for @sleepFormLabelWokeUp.
  ///
  /// In en, this message translates to:
  /// **'Woke Up (Optional)'**
  String get sleepFormLabelWokeUp;

  /// No description provided for @sleepFormHintTimeWokeUp.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get sleepFormHintTimeWokeUp;

  /// No description provided for @sleepFormLabelTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Duration (Optional)'**
  String get sleepFormLabelTotalDuration;

  /// No description provided for @sleepFormHintTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'e.g., 7 hours, 7h 30m'**
  String get sleepFormHintTotalDuration;

  /// No description provided for @sleepFormLabelQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get sleepFormLabelQuality;

  /// Validation error for missing sleep quality
  ///
  /// In en, this message translates to:
  /// **'Please select sleep quality'**
  String get sleepFormValidationSelectQuality;

  /// No description provided for @sleepFormLabelDescribeOtherQuality.
  ///
  /// In en, this message translates to:
  /// **'Describe Other Quality'**
  String get sleepFormLabelDescribeOtherQuality;

  /// No description provided for @sleepFormHintDescribeOtherQuality.
  ///
  /// In en, this message translates to:
  /// **'Describe the sleep quality...'**
  String get sleepFormHintDescribeOtherQuality;

  /// Validation error for missing description of 'Other' sleep quality
  ///
  /// In en, this message translates to:
  /// **'Please describe the \'Other\' sleep quality'**
  String get sleepFormValidationDescribeOtherQuality;

  /// No description provided for @sleepFormLabelNaps.
  ///
  /// In en, this message translates to:
  /// **'Naps (Optional)'**
  String get sleepFormLabelNaps;

  /// No description provided for @sleepFormHintNaps.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1 nap, 30 mins'**
  String get sleepFormHintNaps;

  /// No description provided for @sleepFormLabelGeneralNotes.
  ///
  /// In en, this message translates to:
  /// **'General Notes (Optional)'**
  String get sleepFormLabelGeneralNotes;

  /// No description provided for @sleepFormHintGeneralNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Woke up feeling refreshed'**
  String get sleepFormHintGeneralNotes;

  /// No description provided for @sleepFormButtonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Sleep'**
  String get sleepFormButtonUpdate;

  /// No description provided for @sleepFormButtonSave.
  ///
  /// In en, this message translates to:
  /// **'Save Sleep'**
  String get sleepFormButtonSave;

  /// No description provided for @formErrorFailedToUpdateSleep.
  ///
  /// In en, this message translates to:
  /// **'Failed to update sleep log. Please try again.'**
  String get formErrorFailedToUpdateSleep;

  /// No description provided for @formErrorFailedToSaveSleep.
  ///
  /// In en, this message translates to:
  /// **'Failed to save sleep log. Please try again.'**
  String get formErrorFailedToSaveSleep;

  /// No description provided for @vitalFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Vital Sign'**
  String get vitalFormTitleEdit;

  /// No description provided for @vitalFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Log Vital Sign'**
  String get vitalFormTitleNew;

  /// No description provided for @vitalTypeBPLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get vitalTypeBPLabel;

  /// No description provided for @vitalTypeBPUnit.
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get vitalTypeBPUnit;

  /// No description provided for @vitalTypeBPPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 120/80'**
  String get vitalTypeBPPlaceholder;

  /// No description provided for @vitalTypeHRLabel.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get vitalTypeHRLabel;

  /// No description provided for @vitalTypeHRUnit.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get vitalTypeHRUnit;

  /// No description provided for @vitalTypeHRPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 70'**
  String get vitalTypeHRPlaceholder;

  /// No description provided for @vitalTypeWTLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get vitalTypeWTLabel;

  /// No description provided for @vitalTypeWTUnit.
  ///
  /// In en, this message translates to:
  /// **'kg/lbs'**
  String get vitalTypeWTUnit;

  /// No description provided for @vitalTypeWTPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 65 kg or 143 lbs'**
  String get vitalTypeWTPlaceholder;

  /// No description provided for @vitalTypeBGLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Glucose'**
  String get vitalTypeBGLabel;

  /// No description provided for @vitalTypeBGUnit.
  ///
  /// In en, this message translates to:
  /// **'mg/dL or mmol/L'**
  String get vitalTypeBGUnit;

  /// No description provided for @vitalTypeBGPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 90 mg/dL'**
  String get vitalTypeBGPlaceholder;

  /// No description provided for @vitalTypeTempLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get vitalTypeTempLabel;

  /// No description provided for @vitalTypeTempUnit.
  ///
  /// In en, this message translates to:
  /// **'°C/°F'**
  String get vitalTypeTempUnit;

  /// No description provided for @vitalTypeTempPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 36.5°C or 97.7°F'**
  String get vitalTypeTempPlaceholder;

  /// No description provided for @vitalTypeO2Label.
  ///
  /// In en, this message translates to:
  /// **'Oxygen Saturation'**
  String get vitalTypeO2Label;

  /// No description provided for @vitalTypeO2Unit.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get vitalTypeO2Unit;

  /// No description provided for @vitalTypeO2Placeholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 98'**
  String get vitalTypeO2Placeholder;

  /// No description provided for @vitalFormLabelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get vitalFormLabelType;

  /// No description provided for @vitalFormLabelValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get vitalFormLabelValue;

  /// Validation error for empty vital value
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get vitalFormValidationValueEmpty;

  /// No description provided for @vitalFormValidationBPFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter BP as \'SYS/DIA\', e.g., 120/80.'**
  String get vitalFormValidationBPFormat;

  /// No description provided for @vitalFormValidationValueNumeric.
  ///
  /// In en, this message translates to:
  /// **'Please enter a numeric value.'**
  String get vitalFormValidationValueNumeric;

  /// No description provided for @vitalFormHintNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Taken after meal'**
  String get vitalFormHintNotes;

  /// No description provided for @vitalFormButtonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Vital'**
  String get vitalFormButtonUpdate;

  /// No description provided for @vitalFormButtonSave.
  ///
  /// In en, this message translates to:
  /// **'Save Vital'**
  String get vitalFormButtonSave;

  /// No description provided for @formErrorFailedToUpdateVital.
  ///
  /// In en, this message translates to:
  /// **'Failed to update vital. Please try again.'**
  String get formErrorFailedToUpdateVital;

  /// No description provided for @formErrorFailedToSaveVital.
  ///
  /// In en, this message translates to:
  /// **'Failed to save vital. Please try again.'**
  String get formErrorFailedToSaveVital;

  /// No description provided for @settingsUserProfileNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'User profile not loaded.'**
  String get settingsUserProfileNotLoaded;

  /// No description provided for @settingsDisplayNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty.'**
  String get settingsDisplayNameCannotBeEmpty;

  /// No description provided for @settingsProfileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get settingsProfileUpdatedSuccess;

  /// No description provided for @settingsErrorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {errorMessage}'**
  String settingsErrorUpdatingProfile(String errorMessage);

  /// No description provided for @settingsSelectElderFirstMedDef.
  ///
  /// In en, this message translates to:
  /// **'Please select an elder profile first to manage medication definitions.'**
  String get settingsSelectElderFirstMedDef;

  /// No description provided for @settingsMedNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Medication name is required.'**
  String get settingsMedNameRequired;

  /// No description provided for @settingsMedDefaultTimeFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid time format. Please use HH:mm (e.g., 09:00).'**
  String get settingsMedDefaultTimeFormatError;

  /// No description provided for @settingsMedDefAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication definition added successfully.'**
  String get settingsMedDefAddedSuccess;

  /// No description provided for @settingsClearDataErrorElderOrUserMissing.
  ///
  /// In en, this message translates to:
  /// **'Cannot clear data: Active elder or user is missing.'**
  String get settingsClearDataErrorElderOrUserMissing;

  /// No description provided for @settingsClearDataErrorNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'You are not the primary admin for this elder\'s profile. Data can only be cleared by the primary admin.'**
  String get settingsClearDataErrorNotAdmin;

  /// No description provided for @settingsClearDataDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data for {elderName}?'**
  String settingsClearDataDialogTitle(String elderName);

  /// No description provided for @settingsClearDataDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible and will delete all associated records (medications, meals, vitals, etc.) for this elder. Are you sure you want to proceed?'**
  String get settingsClearDataDialogContent;

  /// No description provided for @settingsClearDataDialogConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Yes, Clear All Data'**
  String get settingsClearDataDialogConfirmButton;

  /// No description provided for @settingsClearDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data for {elderName} has been cleared.'**
  String settingsClearDataSuccess(String elderName);

  /// No description provided for @settingsClearDataErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error clearing data: {errorMessage}'**
  String settingsClearDataErrorGeneric(String errorMessage);

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameEs.
  ///
  /// In en, this message translates to:
  /// **'Español (Spanish)'**
  String get languageNameEs;

  /// No description provided for @languageNameJa.
  ///
  /// In en, this message translates to:
  /// **'日本語 (Japanese)'**
  String get languageNameJa;

  /// No description provided for @languageNameKo.
  ///
  /// In en, this message translates to:
  /// **'한국어 (Korean)'**
  String get languageNameKo;

  /// No description provided for @languageNameZh.
  ///
  /// In en, this message translates to:
  /// **'中文 (Chinese)'**
  String get languageNameZh;

  /// No description provided for @settingsTitleMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get settingsTitleMyAccount;

  /// No description provided for @settingsLabelDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get settingsLabelDisplayName;

  /// No description provided for @settingsHintDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get settingsHintDisplayName;

  /// No description provided for @settingsLabelDOB.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get settingsLabelDOB;

  /// No description provided for @settingsHintDOB.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get settingsHintDOB;

  /// No description provided for @settingsButtonSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get settingsButtonSaveProfile;

  /// No description provided for @settingsButtonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsButtonSignOut;

  /// No description provided for @settingsErrorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile.'**
  String get settingsErrorLoadingProfile;

  /// No description provided for @settingsTitleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get settingsTitleLanguage;

  /// No description provided for @settingsLabelSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select App Language'**
  String get settingsLabelSelectLanguage;

  /// No description provided for @settingsLanguageChangedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {languageTag}.'**
  String settingsLanguageChangedConfirmation(String languageTag);

  /// No description provided for @settingsTitleElderProfileManagement.
  ///
  /// In en, this message translates to:
  /// **'Elder Profile Management'**
  String get settingsTitleElderProfileManagement;

  /// No description provided for @settingsCurrentElder.
  ///
  /// In en, this message translates to:
  /// **'Current Active Elder: {elderName}'**
  String settingsCurrentElder(String elderName);

  /// No description provided for @settingsNoActiveElderSelected.
  ///
  /// In en, this message translates to:
  /// **'No active elder selected. Please select or create one.'**
  String get settingsNoActiveElderSelected;

  /// No description provided for @settingsErrorNavToManageElderProfiles.
  ///
  /// In en, this message translates to:
  /// **'Could not navigate to manage elder profiles. User not logged in.'**
  String get settingsErrorNavToManageElderProfiles;

  /// No description provided for @settingsButtonManageElderProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage Elder Profiles'**
  String get settingsButtonManageElderProfiles;

  /// No description provided for @settingsTitleAdminActions.
  ///
  /// In en, this message translates to:
  /// **'Admin Actions for {elderName}'**
  String settingsTitleAdminActions(String elderName);

  /// No description provided for @settingsButtonClearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data for This Elder'**
  String get settingsButtonClearAllData;

  /// No description provided for @settingsTitleMedicationDefinitions.
  ///
  /// In en, this message translates to:
  /// **'Medication Definitions'**
  String get settingsTitleMedicationDefinitions;

  /// No description provided for @settingsSubtitleAddNewMedDef.
  ///
  /// In en, this message translates to:
  /// **'Add New Medication Definition:'**
  String get settingsSubtitleAddNewMedDef;

  /// No description provided for @settingsLabelMedName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get settingsLabelMedName;

  /// No description provided for @settingsHintMedName.
  ///
  /// In en, this message translates to:
  /// **'e.g., Lisinopril'**
  String get settingsHintMedName;

  /// No description provided for @settingsLabelMedDose.
  ///
  /// In en, this message translates to:
  /// **'Default Dose (Optional)'**
  String get settingsLabelMedDose;

  /// No description provided for @settingsHintMedDose.
  ///
  /// In en, this message translates to:
  /// **'e.g., 10mg, 1 tablet'**
  String get settingsHintMedDose;

  /// No description provided for @settingsLabelMedDefaultTime.
  ///
  /// In en, this message translates to:
  /// **'Default Time (HH:mm, Optional)'**
  String get settingsLabelMedDefaultTime;

  /// No description provided for @settingsHintMedDefaultTime.
  ///
  /// In en, this message translates to:
  /// **'e.g., 08:00'**
  String get settingsHintMedDefaultTime;

  /// No description provided for @settingsButtonAddMedDef.
  ///
  /// In en, this message translates to:
  /// **'Add Medication Definition'**
  String get settingsButtonAddMedDef;

  /// No description provided for @settingsSelectElderToAddMedDefs.
  ///
  /// In en, this message translates to:
  /// **'Select an elder profile to add medication definitions.'**
  String get settingsSelectElderToAddMedDefs;

  /// No description provided for @settingsSelectElderToViewMedDefs.
  ///
  /// In en, this message translates to:
  /// **'Select an elder profile to view medication definitions.'**
  String get settingsSelectElderToViewMedDefs;

  /// No description provided for @settingsNoMedDefsForElder.
  ///
  /// In en, this message translates to:
  /// **'No medication definitions found for {elderName}.'**
  String settingsNoMedDefsForElder(String elderName);

  /// No description provided for @settingsExistingMedDefsForElder.
  ///
  /// In en, this message translates to:
  /// **'Existing Definitions for {elderNameOrFallback}:'**
  String settingsExistingMedDefsForElder(String elderNameOrFallback);

  /// No description provided for @settingsSelectedElderFallback.
  ///
  /// In en, this message translates to:
  /// **'Selected Elder'**
  String get settingsSelectedElderFallback;

  /// No description provided for @settingsMedDefDosePrefix.
  ///
  /// In en, this message translates to:
  /// **'Dose: {dose}'**
  String settingsMedDefDosePrefix(String dose);

  /// No description provided for @settingsMedDefDefaultTimePrefix.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String settingsMedDefDefaultTimePrefix(String time);

  /// No description provided for @settingsTooltipDeleteMedDef.
  ///
  /// In en, this message translates to:
  /// **'Delete this medication definition'**
  String get settingsTooltipDeleteMedDef;

  /// No description provided for @settingsDeleteMedDefDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \'{medName}\' Definition?'**
  String settingsDeleteMedDefDialogTitle(String medName);

  /// No description provided for @settingsDeleteMedDefDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication definition? This will not affect past medication logs but will remove it as an option for future logs.'**
  String get settingsDeleteMedDefDialogContent;

  /// No description provided for @settingsMedDefDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication definition \'{medName}\' deleted.'**
  String settingsMedDefDeletedSuccess(String medName);

  /// No description provided for @errorNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Error: User not logged in.'**
  String get errorNotLoggedIn;

  /// No description provided for @errorElderIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Error: Elder ID is missing.'**
  String get errorElderIdMissing;

  /// No description provided for @profileUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Profile for {profileName} updated.'**
  String profileUpdatedSnackbar(String profileName);

  /// No description provided for @profileCreatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Profile for {profileName} created.'**
  String profileCreatedSnackbar(String profileName);

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {errorMessage}'**
  String errorSavingProfile(String errorMessage);

  /// No description provided for @errorSelectElderAndEmail.
  ///
  /// In en, this message translates to:
  /// **'Please select an elder profile and enter a valid email address.'**
  String get errorSelectElderAndEmail;

  /// No description provided for @invitationSentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}.'**
  String invitationSentSnackbar(String email);

  /// No description provided for @errorSendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error sending invitation: {errorMessage}'**
  String errorSendingInvitation(String errorMessage);

  /// No description provided for @removeCaregiverDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Caregiver?'**
  String get removeCaregiverDialogTitle;

  /// No description provided for @removeCaregiverDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {caregiverIdentifier} as a caregiver for this elder?'**
  String removeCaregiverDialogContent(String caregiverIdentifier);

  /// No description provided for @caregiverRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Caregiver {caregiverIdentifier} removed.'**
  String caregiverRemovedSnackbar(String caregiverIdentifier);

  /// No description provided for @errorRemovingCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Error removing caregiver: {errorMessage}'**
  String errorRemovingCaregiver(String errorMessage);

  /// No description provided for @tooltipEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get tooltipEditProfile;

  /// No description provided for @dobLabelPrefix.
  ///
  /// In en, this message translates to:
  /// **'DOB:'**
  String get dobLabelPrefix;

  /// No description provided for @allergiesLabelPrefix.
  ///
  /// In en, this message translates to:
  /// **'Allergies:'**
  String get allergiesLabelPrefix;

  /// No description provided for @dietLabelPrefix.
  ///
  /// In en, this message translates to:
  /// **'Diet:'**
  String get dietLabelPrefix;

  /// No description provided for @primaryAdminLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Admin:'**
  String get primaryAdminLabel;

  /// No description provided for @adminNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get adminNotAssigned;

  /// No description provided for @loadingAdminInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading admin info...'**
  String get loadingAdminInfo;

  /// No description provided for @caregiversLabel.
  ///
  /// In en, this message translates to:
  /// **'Caregivers ({count}):'**
  String caregiversLabel(int count);

  /// No description provided for @noCaregiversYet.
  ///
  /// In en, this message translates to:
  /// **'No caregivers yet.'**
  String get noCaregiversYet;

  /// No description provided for @errorLoadingCaregiverNames.
  ///
  /// In en, this message translates to:
  /// **'Error loading caregiver names.'**
  String get errorLoadingCaregiverNames;

  /// No description provided for @caregiverAdminSuffix.
  ///
  /// In en, this message translates to:
  /// **'(Admin)'**
  String get caregiverAdminSuffix;

  /// No description provided for @tooltipRemoveCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Remove {identifier}'**
  String tooltipRemoveCaregiver(String identifier);

  /// No description provided for @profileSetActiveSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{profileName} is now the active profile.'**
  String profileSetActiveSnackbar(String profileName);

  /// No description provided for @inviteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Caregiver to {profileName}\'s Profile'**
  String inviteDialogTitle(String profileName);

  /// No description provided for @caregiversEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Caregiver\'s Email'**
  String get caregiversEmailLabel;

  /// No description provided for @enterEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get enterEmailHint;

  /// No description provided for @createElderProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Elder Profile'**
  String get createElderProfileTitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {profileNameOrFallback}'**
  String editProfileTitle(String profileNameOrFallback);

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileNameLabel;

  /// No description provided for @validatorPleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get validatorPleaseEnterName;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @allergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies (comma-separated)'**
  String get allergiesLabel;

  /// No description provided for @dietaryRestrictionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Dietary Restrictions (comma-separated)'**
  String get dietaryRestrictionsLabel;

  /// No description provided for @createNewProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Create New Profile'**
  String get createNewProfileButton;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @noElderProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No elder profiles found.'**
  String get noElderProfilesFound;

  /// No description provided for @createNewProfileOrWait.
  ///
  /// In en, this message translates to:
  /// **'Create a new profile or wait for an invitation.'**
  String get createNewProfileOrWait;

  /// No description provided for @fabNewProfile.
  ///
  /// In en, this message translates to:
  /// **'New Profile'**
  String get fabNewProfile;

  /// No description provided for @activityTypeWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get activityTypeWalk;

  /// No description provided for @activityTypeExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get activityTypeExercise;

  /// No description provided for @activityTypePhysicalTherapy.
  ///
  /// In en, this message translates to:
  /// **'Physical Therapy'**
  String get activityTypePhysicalTherapy;

  /// No description provided for @activityTypeOccupationalTherapy.
  ///
  /// In en, this message translates to:
  /// **'Occupational Therapy'**
  String get activityTypeOccupationalTherapy;

  /// No description provided for @activityTypeOuting.
  ///
  /// In en, this message translates to:
  /// **'Outing'**
  String get activityTypeOuting;

  /// No description provided for @activityTypeSocialVisit.
  ///
  /// In en, this message translates to:
  /// **'Social Visit'**
  String get activityTypeSocialVisit;

  /// No description provided for @activityTypeReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get activityTypeReading;

  /// No description provided for @activityTypeTV.
  ///
  /// In en, this message translates to:
  /// **'Watching TV/Movies'**
  String get activityTypeTV;

  /// No description provided for @activityTypeGardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get activityTypeGardening;

  /// No description provided for @assistanceLevelIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get assistanceLevelIndependent;

  /// No description provided for @assistanceLevelStandbyAssist.
  ///
  /// In en, this message translates to:
  /// **'Standby Assist'**
  String get assistanceLevelStandbyAssist;

  /// No description provided for @assistanceLevelWithWalker.
  ///
  /// In en, this message translates to:
  /// **'With Walker'**
  String get assistanceLevelWithWalker;

  /// No description provided for @assistanceLevelWithCane.
  ///
  /// In en, this message translates to:
  /// **'With Cane'**
  String get assistanceLevelWithCane;

  /// No description provided for @assistanceLevelWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair'**
  String get assistanceLevelWheelchair;

  /// No description provided for @assistanceLevelMinAssist.
  ///
  /// In en, this message translates to:
  /// **'Minimal Assist (Min A)'**
  String get assistanceLevelMinAssist;

  /// No description provided for @assistanceLevelModAssist.
  ///
  /// In en, this message translates to:
  /// **'Moderate Assist (Mod A)'**
  String get assistanceLevelModAssist;

  /// No description provided for @assistanceLevelMaxAssist.
  ///
  /// In en, this message translates to:
  /// **'Maximum Assist (Max A)'**
  String get assistanceLevelMaxAssist;

  /// No description provided for @formErrorFailedToUpdateActivity.
  ///
  /// In en, this message translates to:
  /// **'Failed to update activity. Please try again.'**
  String get formErrorFailedToUpdateActivity;

  /// No description provided for @formErrorFailedToSaveActivity.
  ///
  /// In en, this message translates to:
  /// **'Failed to save activity. Please try again.'**
  String get formErrorFailedToSaveActivity;

  /// No description provided for @activityFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity'**
  String get activityFormTitleEdit;

  /// No description provided for @activityFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Log New Activity'**
  String get activityFormTitleNew;

  /// No description provided for @activityFormLabelActivityType.
  ///
  /// In en, this message translates to:
  /// **'Activity Type'**
  String get activityFormLabelActivityType;

  /// No description provided for @activityFormHintActivityType.
  ///
  /// In en, this message translates to:
  /// **'Select or type activity'**
  String get activityFormHintActivityType;

  /// No description provided for @activityFormValidationActivityType.
  ///
  /// In en, this message translates to:
  /// **'Please select or specify an activity type.'**
  String get activityFormValidationActivityType;

  /// No description provided for @activityFormLabelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (Optional)'**
  String get activityFormLabelDuration;

  /// No description provided for @activityFormHintDuration.
  ///
  /// In en, this message translates to:
  /// **'e.g., 30 minutes, 1 hour'**
  String get activityFormHintDuration;

  /// No description provided for @activityFormLabelAssistance.
  ///
  /// In en, this message translates to:
  /// **'Level of Assistance (Optional)'**
  String get activityFormLabelAssistance;

  /// No description provided for @activityFormHintAssistance.
  ///
  /// In en, this message translates to:
  /// **'Select level of assistance'**
  String get activityFormHintAssistance;

  /// No description provided for @activityFormHintNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Enjoyed the sunshine, walked to the park'**
  String get activityFormHintNotes;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notApplicable;

  /// Log entry for water intake, showing description or amount.
  ///
  /// In en, this message translates to:
  /// **'Water: {description}'**
  String careScreenWaterLog(String description);

  /// Log entry for a meal, showing meal type and description.
  ///
  /// In en, this message translates to:
  /// **'{mealType}: {description}'**
  String careScreenMealLog(String mealType, String description);

  /// No description provided for @careScreenMealGeneric.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get careScreenMealGeneric;

  /// Context for water intake.
  ///
  /// In en, this message translates to:
  /// **'Context: {contextDetails}'**
  String careScreenWaterContext(String contextDetails);

  /// Displays notes for an entry.
  ///
  /// In en, this message translates to:
  /// **'Notes: {noteContent}'**
  String careScreenNotes(String noteContent);

  /// Indicates who logged the entry.
  ///
  /// In en, this message translates to:
  /// **'Logged by: {userName}'**
  String careScreenLoggedBy(String userName);

  /// No description provided for @careScreenTooltipEditFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Edit Food/Water Entry'**
  String get careScreenTooltipEditFoodWater;

  /// No description provided for @careScreenTooltipDeleteFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Delete Food/Water Entry'**
  String get careScreenTooltipDeleteFoodWater;

  /// No description provided for @careScreenErrorMissingIdDelete.
  ///
  /// In en, this message translates to:
  /// **'Error: Cannot delete entry, ID is missing.'**
  String get careScreenErrorMissingIdDelete;

  /// No description provided for @careScreenErrorFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load records for this day. Please try again.'**
  String get careScreenErrorFailedToLoad;

  /// No description provided for @careScreenButtonAddFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Add Food / Water'**
  String get careScreenButtonAddFoodWater;

  /// No description provided for @careScreenSectionTitleMoodBehavior.
  ///
  /// In en, this message translates to:
  /// **'Mood & Behavior'**
  String get careScreenSectionTitleMoodBehavior;

  /// No description provided for @careScreenNoMoodBehaviorLogged.
  ///
  /// In en, this message translates to:
  /// **'No mood or behavior logged for this day.'**
  String get careScreenNoMoodBehaviorLogged;

  /// Displays the logged mood.
  ///
  /// In en, this message translates to:
  /// **'Mood: {mood}'**
  String careScreenMood(String mood);

  /// Displays the intensity of the mood.
  ///
  /// In en, this message translates to:
  /// **'Intensity: {intensityLevel}'**
  String careScreenMoodIntensity(String intensityLevel);

  /// No description provided for @careScreenTooltipEditMood.
  ///
  /// In en, this message translates to:
  /// **'Edit Mood Entry'**
  String get careScreenTooltipEditMood;

  /// No description provided for @careScreenTooltipDeleteMood.
  ///
  /// In en, this message translates to:
  /// **'Delete Mood Entry'**
  String get careScreenTooltipDeleteMood;

  /// No description provided for @careScreenButtonAddMood.
  ///
  /// In en, this message translates to:
  /// **'Add Mood / Behavior'**
  String get careScreenButtonAddMood;

  /// No description provided for @careScreenSectionTitlePain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get careScreenSectionTitlePain;

  /// No description provided for @careScreenNoPainLogged.
  ///
  /// In en, this message translates to:
  /// **'No pain logged for this day.'**
  String get careScreenNoPainLogged;

  /// Log entry for pain.
  ///
  /// In en, this message translates to:
  /// **'Pain: {location} - {description}{intensityDetails}'**
  String careScreenPainLog(
      String location, String description, String intensityDetails);

  /// Displays pain intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity: {intensityValue}'**
  String careScreenPainIntensity(String intensityValue);

  /// No description provided for @careScreenTooltipEditPain.
  ///
  /// In en, this message translates to:
  /// **'Edit Pain Entry'**
  String get careScreenTooltipEditPain;

  /// No description provided for @careScreenTooltipDeletePain.
  ///
  /// In en, this message translates to:
  /// **'Delete Pain Entry'**
  String get careScreenTooltipDeletePain;

  /// No description provided for @careScreenButtonAddPain.
  ///
  /// In en, this message translates to:
  /// **'Add Pain Log'**
  String get careScreenButtonAddPain;

  /// No description provided for @careScreenSectionTitleActivity.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get careScreenSectionTitleActivity;

  /// No description provided for @careScreenNoActivitiesLogged.
  ///
  /// In en, this message translates to:
  /// **'No activities logged for this day.'**
  String get careScreenNoActivitiesLogged;

  /// No description provided for @careScreenUnknownActivity.
  ///
  /// In en, this message translates to:
  /// **'Unknown Activity'**
  String get careScreenUnknownActivity;

  /// Displays activity duration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String careScreenActivityDuration(String duration);

  /// Displays level of assistance for an activity.
  ///
  /// In en, this message translates to:
  /// **'Assistance: {assistanceLevel}'**
  String careScreenActivityAssistance(String assistanceLevel);

  /// No description provided for @careScreenTooltipEditActivity.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity Entry'**
  String get careScreenTooltipEditActivity;

  /// No description provided for @careScreenTooltipDeleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete Activity Entry'**
  String get careScreenTooltipDeleteActivity;

  /// No description provided for @careScreenButtonAddActivity.
  ///
  /// In en, this message translates to:
  /// **'Add Activity'**
  String get careScreenButtonAddActivity;

  /// No description provided for @careScreenSectionTitleVitals.
  ///
  /// In en, this message translates to:
  /// **'Vital Signs'**
  String get careScreenSectionTitleVitals;

  /// No description provided for @careScreenNoVitalsLogged.
  ///
  /// In en, this message translates to:
  /// **'No vital signs logged for this day.'**
  String get careScreenNoVitalsLogged;

  /// Log entry for a vital sign.
  ///
  /// In en, this message translates to:
  /// **'{vitalType}: {value} {unit}'**
  String careScreenVitalLog(String vitalType, String value, String unit);

  /// No description provided for @careScreenTooltipEditVital.
  ///
  /// In en, this message translates to:
  /// **'Edit Vital Sign Entry'**
  String get careScreenTooltipEditVital;

  /// No description provided for @careScreenTooltipDeleteVital.
  ///
  /// In en, this message translates to:
  /// **'Delete Vital Sign Entry'**
  String get careScreenTooltipDeleteVital;

  /// No description provided for @careScreenButtonAddVital.
  ///
  /// In en, this message translates to:
  /// **'Add Vital Sign'**
  String get careScreenButtonAddVital;

  /// No description provided for @careScreenSectionTitleExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get careScreenSectionTitleExpenses;

  /// No description provided for @careScreenNoExpensesLogged.
  ///
  /// In en, this message translates to:
  /// **'No expenses logged for this day.'**
  String get careScreenNoExpensesLogged;

  /// Log entry for an expense.
  ///
  /// In en, this message translates to:
  /// **'{description}: \${amount}'**
  String careScreenExpenseLog(String description, String amount);

  /// Displays expense category and optional notes.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}{noteDetails}'**
  String careScreenExpenseCategory(String category, String noteDetails);

  /// No description provided for @careScreenTooltipEditExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense Entry'**
  String get careScreenTooltipEditExpense;

  /// No description provided for @careScreenTooltipDeleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense Entry'**
  String get careScreenTooltipDeleteExpense;

  /// No description provided for @careScreenButtonAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get careScreenButtonAddExpense;

  /// No description provided for @calendarErrorLoadEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading calendar events. Please try again.'**
  String get calendarErrorLoadEvents;

  /// No description provided for @calendarErrorUserNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Error: User not logged in. Cannot load calendar events.'**
  String get calendarErrorUserNotLoggedIn;

  /// No description provided for @calendarErrorEditMissingId.
  ///
  /// In en, this message translates to:
  /// **'Error: Cannot edit event, ID is missing.'**
  String get calendarErrorEditMissingId;

  /// No description provided for @calendarErrorEditPermission.
  ///
  /// In en, this message translates to:
  /// **'Error: You do not have permission to edit this event.'**
  String get calendarErrorEditPermission;

  /// No description provided for @calendarErrorUpdateOriginalMissing.
  ///
  /// In en, this message translates to:
  /// **'Error: Original event data missing for update.'**
  String get calendarErrorUpdateOriginalMissing;

  /// No description provided for @calendarErrorUpdatePermission.
  ///
  /// In en, this message translates to:
  /// **'Error: You do not have permission to update this event.'**
  String get calendarErrorUpdatePermission;

  /// No description provided for @calendarEventAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event added successfully.'**
  String get calendarEventAddedSuccess;

  /// No description provided for @calendarEventUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event updated successfully.'**
  String get calendarEventUpdatedSuccess;

  /// Error message when saving a calendar event fails.
  ///
  /// In en, this message translates to:
  /// **'Error saving event: {errorMessage}'**
  String calendarErrorSaveEvent(String errorMessage);

  /// No description provided for @calendarErrorDeleteMissingId.
  ///
  /// In en, this message translates to:
  /// **'Error: Cannot delete event, ID is missing.'**
  String get calendarErrorDeleteMissingId;

  /// No description provided for @calendarErrorDeletePermission.
  ///
  /// In en, this message translates to:
  /// **'Error: You do not have permission to delete this event.'**
  String get calendarErrorDeletePermission;

  /// No description provided for @calendarConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get calendarConfirmDeleteTitle;

  /// Confirmation message for deleting a calendar event.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the event \'{eventTitle}\'?'**
  String calendarConfirmDeleteContent(String eventTitle);

  /// No description provided for @calendarUntitledEvent.
  ///
  /// In en, this message translates to:
  /// **'Untitled Event'**
  String get calendarUntitledEvent;

  /// No description provided for @eventDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event deleted successfully.'**
  String get eventDeletedSuccess;

  /// No description provided for @errorCouldNotDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not delete event.'**
  String get errorCouldNotDeleteEvent;

  /// No description provided for @calendarNoElderSelected.
  ///
  /// In en, this message translates to:
  /// **'No elder selected. Please select an elder to view their calendar.'**
  String get calendarNoElderSelected;

  /// No description provided for @calendarAddNewEventButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Event'**
  String get calendarAddNewEventButton;

  /// Header for the list of events on a specific date.
  ///
  /// In en, this message translates to:
  /// **'Events on {formattedDate}:'**
  String calendarEventsOnDate(String formattedDate);

  /// No description provided for @calendarNoEventsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled for this day.'**
  String get calendarNoEventsScheduled;

  /// No description provided for @calendarTooltipEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get calendarTooltipEditEvent;

  /// No description provided for @calendarEventTypePrefix.
  ///
  /// In en, this message translates to:
  /// **'Type:'**
  String get calendarEventTypePrefix;

  /// No description provided for @calendarEventTimePrefix.
  ///
  /// In en, this message translates to:
  /// **'Time:'**
  String get calendarEventTimePrefix;

  /// No description provided for @calendarEventNotesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get calendarEventNotesPrefix;

  /// No description provided for @expenseUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get expenseUncategorized;

  /// Error message when processing expense data fails.
  ///
  /// In en, this message translates to:
  /// **'Error processing expense data: {errorMessage}'**
  String expenseErrorProcessingData(String errorMessage);

  /// Error message when fetching expenses fails.
  ///
  /// In en, this message translates to:
  /// **'Error fetching expenses: {errorMessage}'**
  String expenseErrorFetching(String errorMessage);

  /// No description provided for @expenseUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get expenseUnknownUser;

  /// No description provided for @expenseSelectElderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select an elder profile to view expenses.'**
  String get expenseSelectElderPrompt;

  /// No description provided for @expenseLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading expenses...'**
  String get expenseLoading;

  /// No description provided for @expenseScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenseScreenTitle;

  /// Title indicating expenses for a specific elder.
  ///
  /// In en, this message translates to:
  /// **'Expenses for {elderName}'**
  String expenseForElder(String elderName);

  /// No description provided for @expensePrevWeekButton.
  ///
  /// In en, this message translates to:
  /// **'Previous Week'**
  String get expensePrevWeekButton;

  /// No description provided for @expenseNextWeekButton.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get expenseNextWeekButton;

  /// No description provided for @expenseNoExpensesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No expenses logged for this week.'**
  String get expenseNoExpensesThisWeek;

  /// No description provided for @expenseSummaryByCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary by Category (This Week)'**
  String get expenseSummaryByCategoryTitle;

  /// No description provided for @expenseNoExpensesInCategoryThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this category for the selected week.'**
  String get expenseNoExpensesInCategoryThisWeek;

  /// No description provided for @expenseWeekTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Week Total:'**
  String get expenseWeekTotalLabel;

  /// No description provided for @expenseDetailedByUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed Expenses (This Week - By User)'**
  String get expenseDetailedByUserTitle;

  /// Label for expense category.
  ///
  /// In en, this message translates to:
  /// **'Category: {categoryName}'**
  String expenseCategoryLabel(String categoryName);

  /// No description provided for @errorEnterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password.'**
  String get errorEnterEmailPassword;

  /// No description provided for @errorLoginFailedDefault.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials or network connection.'**
  String get errorLoginFailedDefault;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Cecelia Care'**
  String get loginScreenTitle;

  /// Label for the relationship to elder field in user account settings
  ///
  /// In en, this message translates to:
  /// **'Relationship to Elder'**
  String get settingsLabelRelationshipToElder;

  /// Hint text for the relationship to elder field
  ///
  /// In en, this message translates to:
  /// **'e.g., Son/Daughter, Spouse, Caregiver'**
  String get settingsHintRelationshipToElder;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @dontHaveAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccountSignUp;

  /// No description provided for @signUpNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Sign up functionality is not yet implemented.'**
  String get signUpNotImplemented;

  /// No description provided for @homeScreenBaseTitleTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get homeScreenBaseTitleTimeline;

  /// Title for the care log screen, term is dynamic.
  ///
  /// In en, this message translates to:
  /// **'{term} Care Log'**
  String homeScreenBaseTitleCareLog(String term);

  /// Title for the calendar screen, term is dynamic.
  ///
  /// In en, this message translates to:
  /// **'{term} Calendar'**
  String homeScreenBaseTitleCalendar(String term);

  /// No description provided for @homeScreenBaseTitleExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get homeScreenBaseTitleExpenses;

  /// No description provided for @homeScreenBaseTitleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeScreenBaseTitleSettings;

  /// No description provided for @mustBeLoggedInToAddData.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to add data.'**
  String get mustBeLoggedInToAddData;

  /// No description provided for @mustBeLoggedInToUpdateData.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to update data.'**
  String get mustBeLoggedInToUpdateData;

  /// Message shown when no term is selected for the care log.
  ///
  /// In en, this message translates to:
  /// **'Please select a {term} from Settings to view the Care Log.'**
  String selectTermToViewCareLog(String term);

  /// Message shown when no Elder is selected for the care log, using the fixed term 'Elder'.
  ///
  /// In en, this message translates to:
  /// **'Please select an Elder from Settings to view the Care Log.'**
  String get selectElderToViewCareLog;

  /// No description provided for @goToSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettingsButton;

  /// Message shown when no term is selected for the calendar.
  ///
  /// In en, this message translates to:
  /// **'Please select a {term} from Settings to view the Calendar.'**
  String selectTermToViewCalendar(String term);

  /// No description provided for @bottomNavTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get bottomNavTimeline;

  /// Bottom navigation label for care log.
  ///
  /// In en, this message translates to:
  /// **'Care Log'**
  String bottomNavCareLog(Object term);

  /// Bottom navigation label for calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String bottomNavCalendar(Object term);

  /// No description provided for @bottomNavExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get bottomNavExpenses;

  /// No description provided for @bottomNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get bottomNavSettings;

  /// No description provided for @timelineUnknownTime.
  ///
  /// In en, this message translates to:
  /// **'Unknown time'**
  String get timelineUnknownTime;

  /// No description provided for @timelineInvalidTime.
  ///
  /// In en, this message translates to:
  /// **'Invalid time'**
  String get timelineInvalidTime;

  /// No description provided for @timelineMustBeLoggedInToPost.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to post a message.'**
  String get timelineMustBeLoggedInToPost;

  /// No description provided for @timelineSelectElderToPost.
  ///
  /// In en, this message translates to:
  /// **'Please select an active elder profile to post to their timeline.'**
  String get timelineSelectElderToPost;

  /// No description provided for @timelineAnonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get timelineAnonymousUser;

  /// Error message when posting a timeline message fails.
  ///
  /// In en, this message translates to:
  /// **'Could not post message: {errorMessage}'**
  String timelineCouldNotPostMessage(String errorMessage);

  /// No description provided for @timelinePleaseLogInToView.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view the timeline.'**
  String get timelinePleaseLogInToView;

  /// No description provided for @timelineSelectElderToView.
  ///
  /// In en, this message translates to:
  /// **'Please select an elder profile to view their timeline.'**
  String get timelineSelectElderToView;

  /// Hint text for the timeline message input field.
  ///
  /// In en, this message translates to:
  /// **'Write a message for {elderName}\'s timeline...'**
  String timelineWriteMessageHint(String elderName);

  /// No description provided for @timelineUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get timelineUnknownUser;

  /// No description provided for @timelinePostButton.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get timelinePostButton;

  /// No description provided for @timelineCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get timelineCancelButton;

  /// No description provided for @timelinePostMessageToTimelineButton.
  ///
  /// In en, this message translates to:
  /// **'Post Message to Timeline'**
  String get timelinePostMessageToTimelineButton;

  /// No description provided for @timelineLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading timeline...'**
  String get timelineLoading;

  /// Error message when loading timeline entries fails.
  ///
  /// In en, this message translates to:
  /// **'Error loading timeline: {errorMessage}'**
  String timelineErrorLoading(String errorMessage);

  /// Message shown when there are no timeline entries for an elder.
  ///
  /// In en, this message translates to:
  /// **'No entries yet for {elderName}. Be the first to post!'**
  String timelineNoEntriesYet(String elderName);

  /// No description provided for @timelineItemTitleMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get timelineItemTitleMessage;

  /// No description provided for @timelineEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'[Empty Message]'**
  String get timelineEmptyMessage;

  /// No description provided for @timelineItemTitleMedication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get timelineItemTitleMedication;

  /// No description provided for @timelineItemTitleSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get timelineItemTitleSleep;

  /// No description provided for @timelineItemTitleMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get timelineItemTitleMeal;

  /// No description provided for @timelineItemTitleMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get timelineItemTitleMood;

  /// No description provided for @timelineItemTitlePain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get timelineItemTitlePain;

  /// No description provided for @timelineItemTitleActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get timelineItemTitleActivity;

  /// No description provided for @timelineItemTitleVital.
  ///
  /// In en, this message translates to:
  /// **'Vital Sign'**
  String get timelineItemTitleVital;

  /// No description provided for @timelineItemTitleExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get timelineItemTitleExpense;

  /// No description provided for @timelineItemTitleEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get timelineItemTitleEntry;

  /// No description provided for @timelineNoDetailsProvided.
  ///
  /// In en, this message translates to:
  /// **'No details provided.'**
  String get timelineNoDetailsProvided;

  /// Indicates who logged a timeline entry.
  ///
  /// In en, this message translates to:
  /// **'Logged by {userName}'**
  String timelineLoggedBy(String userName);

  /// Error message for a specific timeline item rendering issue.
  ///
  /// In en, this message translates to:
  /// **'Error rendering item at index {index}: {errorDetails}'**
  String timelineErrorRenderingItem(String index, String errorDetails);

  /// No description provided for @timelineSummaryDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Details unavailable'**
  String get timelineSummaryDetailsUnavailable;

  /// No description provided for @timelineSummaryNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get timelineSummaryNotApplicable;

  /// Format for medication status in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'({status})'**
  String timelineSummaryMedicationStatusFormat(String status);

  /// Format for medication summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'{medName} {dose} {status}'**
  String timelineSummaryMedicationFormat(
      String medName, String dose, String status);

  /// Status text for medication taken in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get timelineSummaryMedicationStatusTaken;

  /// Status text for medication not taken in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'Not Taken'**
  String get timelineSummaryMedicationStatusNotTaken;

  /// Generic term for a meal type in timeline summary if specific type is missing.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get timelineSummaryMealTypeGeneric;

  /// Format for sleep quality in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'Quality: {quality}'**
  String timelineSummarySleepQualityFormat(String quality);

  /// Format for sleep summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'Bed: {wentToBed}, Up: {wokeUp}. {quality}'**
  String timelineSummarySleepFormat(
      String wentToBed, String wokeUp, String quality);

  /// Format for meal summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'{mealType}: {description}'**
  String timelineSummaryMealFormat(String mealType, String description);

  /// Format for mood notes in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'(Notes: {notes})'**
  String timelineSummaryMoodNotesFormat(String notes);

  /// Format for mood summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'Mood: {mood} {notes}'**
  String timelineSummaryMoodFormat(String mood, String notes);

  /// Format for pain location in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'at {location}'**
  String timelineSummaryPainLocationFormat(String location);

  /// Format for pain summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'Pain Level: {level}/10 {location}'**
  String timelineSummaryPainFormat(String level, String location);

  /// Format for activity duration in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'for {duration}'**
  String timelineSummaryActivityDurationFormat(String duration);

  /// Format for activity summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'{activityType} {duration}'**
  String timelineSummaryActivityFormat(String activityType, String duration);

  /// Generic format for a vital sign in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'{vitalType}: {value} {unit}'**
  String timelineSummaryVitalFormatGeneric(
      String vitalType, String value, String unit);

  /// Format for blood pressure in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'BP: {systolic}/{diastolic} mmHg'**
  String timelineSummaryVitalFormatBP(String systolic, String diastolic);

  /// Format for heart rate in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'HR: {heartRate} bpm'**
  String timelineSummaryVitalFormatHR(String heartRate);

  /// Format for temperature in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'Temp: {temperature}°'**
  String timelineSummaryVitalFormatTemp(String temperature);

  /// Format for vital sign notes in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String timelineSummaryVitalNote(String note);

  /// No description provided for @timelineSummaryVitalsRecorded.
  ///
  /// In en, this message translates to:
  /// **'Vitals Recorded'**
  String get timelineSummaryVitalsRecorded;

  /// Format for expense description in timeline summary.
  ///
  /// In en, this message translates to:
  /// **'({description})'**
  String timelineSummaryExpenseDescriptionFormat(String description);

  /// Format for expense summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'{category}: \${amount} {description}'**
  String timelineSummaryExpenseFormat(
      String category, String amount, String description);

  /// No description provided for @timelineSummaryErrorProcessing.
  ///
  /// In en, this message translates to:
  /// **'Error processing details for timeline.'**
  String get timelineSummaryErrorProcessing;

  /// Title for a timeline entry that is an image upload.
  ///
  /// In en, this message translates to:
  /// **'Image Uploaded'**
  String get timelineItemTitleImage;

  /// Format for image summary in timeline.
  ///
  /// In en, this message translates to:
  /// **'Image: {title}'**
  String timelineSummaryImageFormat(Object title);

  /// No description provided for @careScreenErrorMissingIdGeneral.
  ///
  /// In en, this message translates to:
  /// **'Error: Item ID is missing. Cannot proceed.'**
  String get careScreenErrorMissingIdGeneral;

  /// No description provided for @careScreenErrorEditPermission.
  ///
  /// In en, this message translates to:
  /// **'Error: You do not have permission to edit this item.'**
  String get careScreenErrorEditPermission;

  /// No description provided for @careScreenErrorUpdateMedStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating medication status. Please try again.'**
  String get careScreenErrorUpdateMedStatus;

  /// No description provided for @careScreenLoadingRecords.
  ///
  /// In en, this message translates to:
  /// **'Loading records for today...'**
  String get careScreenLoadingRecords;

  /// No description provided for @careScreenErrorNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records found for this day or an error occurred.'**
  String get careScreenErrorNoRecords;

  /// No description provided for @careScreenSectionTitleMeds.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get careScreenSectionTitleMeds;

  /// No description provided for @careScreenNoMedsLogged.
  ///
  /// In en, this message translates to:
  /// **'No medications logged for this day.'**
  String get careScreenNoMedsLogged;

  /// No description provided for @careScreenUnknownMedication.
  ///
  /// In en, this message translates to:
  /// **'Unknown Medication'**
  String get careScreenUnknownMedication;

  /// No description provided for @careScreenTooltipEditMed.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication Entry'**
  String get careScreenTooltipEditMed;

  /// No description provided for @careScreenTooltipDeleteMed.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication Entry'**
  String get careScreenTooltipDeleteMed;

  /// No description provided for @careScreenButtonAddMed.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get careScreenButtonAddMed;

  /// No description provided for @careScreenSectionTitleSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get careScreenSectionTitleSleep;

  /// No description provided for @careScreenNoSleepLogged.
  ///
  /// In en, this message translates to:
  /// **'No sleep logged for this day.'**
  String get careScreenNoSleepLogged;

  /// Displays the sleep time range.
  ///
  /// In en, this message translates to:
  /// **'{wentToBed} - {wokeUp}'**
  String careScreenSleepTimeRange(String wentToBed, String wokeUp);

  /// Displays sleep quality and optional duration.
  ///
  /// In en, this message translates to:
  /// **'Quality: {quality} {duration}'**
  String careScreenSleepQuality(String quality, String duration);

  /// Displays nap information.
  ///
  /// In en, this message translates to:
  /// **'Naps: {naps}'**
  String careScreenSleepNaps(String naps);

  /// No description provided for @careScreenTooltipEditSleep.
  ///
  /// In en, this message translates to:
  /// **'Edit Sleep Entry'**
  String get careScreenTooltipEditSleep;

  /// No description provided for @careScreenTooltipDeleteSleep.
  ///
  /// In en, this message translates to:
  /// **'Delete Sleep Entry'**
  String get careScreenTooltipDeleteSleep;

  /// No description provided for @careScreenButtonAddSleep.
  ///
  /// In en, this message translates to:
  /// **'Add Sleep'**
  String get careScreenButtonAddSleep;

  /// No description provided for @careScreenSectionTitleFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Food & Water Intake'**
  String get careScreenSectionTitleFoodWater;

  /// No description provided for @careScreenNoFoodWaterLogged.
  ///
  /// In en, this message translates to:
  /// **'No food or water intake logged for this day.'**
  String get careScreenNoFoodWaterLogged;

  /// Error message when email is invalid or password is too short during sign up.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email and a password with at least {minLength} characters.'**
  String errorEnterValidEmailPasswordMinLength(int minLength);

  /// Default error message if sign up fails for an unknown reason.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed. Please try again.'**
  String get errorSignUpFailedDefault;

  /// Title for the Sign Up screen.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpScreenTitle;

  /// Header text on the sign up form.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// Label for the sign up button.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// The default term used if the user has not specified one.
  ///
  /// In en, this message translates to:
  /// **'Care Recipient'**
  String get termElderDefault;

  /// No description provided for @formErrorGenericSaveUpdate.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while saving or updating. Please try again.'**
  String get formErrorGenericSaveUpdate;

  /// No description provided for @formSuccessActivitySaved.
  ///
  /// In en, this message translates to:
  /// **'Activity saved successfully.'**
  String get formSuccessActivitySaved;

  /// No description provided for @formSuccessActivityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Activity updated successfully.'**
  String get formSuccessActivityUpdated;

  /// No description provided for @formSuccessExpenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved successfully.'**
  String get formSuccessExpenseSaved;

  /// No description provided for @formSuccessExpenseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully.'**
  String get formSuccessExpenseUpdated;

  /// No description provided for @formSuccessMealSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal saved successfully.'**
  String get formSuccessMealSaved;

  /// No description provided for @formSuccessMealUpdated.
  ///
  /// In en, this message translates to:
  /// **'Meal updated successfully.'**
  String get formSuccessMealUpdated;

  /// No description provided for @formSuccessMedSaved.
  ///
  /// In en, this message translates to:
  /// **'Medication saved successfully.'**
  String get formSuccessMedSaved;

  /// No description provided for @formSuccessMedUpdated.
  ///
  /// In en, this message translates to:
  /// **'Medication updated successfully.'**
  String get formSuccessMedUpdated;

  /// No description provided for @formSuccessMoodSaved.
  ///
  /// In en, this message translates to:
  /// **'Mood saved successfully.'**
  String get formSuccessMoodSaved;

  /// No description provided for @formSuccessMoodUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mood updated successfully.'**
  String get formSuccessMoodUpdated;

  /// No description provided for @formSuccessPainSaved.
  ///
  /// In en, this message translates to:
  /// **'Pain log saved successfully.'**
  String get formSuccessPainSaved;

  /// No description provided for @formSuccessPainUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pain log updated successfully.'**
  String get formSuccessPainUpdated;

  /// No description provided for @formSuccessSleepSaved.
  ///
  /// In en, this message translates to:
  /// **'Sleep log saved successfully.'**
  String get formSuccessSleepSaved;

  /// No description provided for @formSuccessSleepUpdated.
  ///
  /// In en, this message translates to:
  /// **'Sleep log updated successfully.'**
  String get formSuccessSleepUpdated;

  /// No description provided for @formSuccessVitalSaved.
  ///
  /// In en, this message translates to:
  /// **'Vital sign saved successfully.'**
  String get formSuccessVitalSaved;

  /// No description provided for @formSuccessVitalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vital sign updated successfully.'**
  String get formSuccessVitalUpdated;

  /// No description provided for @formErrorNoItemToDelete.
  ///
  /// In en, this message translates to:
  /// **'No item selected for deletion.'**
  String get formErrorNoItemToDelete;

  /// No description provided for @formConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get formConfirmDeleteTitle;

  /// No description provided for @formConfirmDeleteVitalMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this vital entry?'**
  String get formConfirmDeleteVitalMessage;

  /// No description provided for @formSuccessVitalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vital entry deleted.'**
  String get formSuccessVitalDeleted;

  /// No description provided for @formErrorFailedToDeleteVital.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete vital entry.'**
  String get formErrorFailedToDeleteVital;

  /// No description provided for @formTooltipDeleteVital.
  ///
  /// In en, this message translates to:
  /// **'Delete vital entry'**
  String get formTooltipDeleteVital;

  /// No description provided for @formConfirmDeleteMealMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this meal entry?'**
  String get formConfirmDeleteMealMessage;

  /// No description provided for @formSuccessMealDeleted.
  ///
  /// In en, this message translates to:
  /// **'Meal entry deleted.'**
  String get formSuccessMealDeleted;

  /// No description provided for @formErrorFailedToDeleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete meal entry.'**
  String get formErrorFailedToDeleteMeal;

  /// No description provided for @formTooltipDeleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete meal entry'**
  String get formTooltipDeleteMeal;

  /// Label for the button that navigates the Care Screen to the current day.
  ///
  /// In en, this message translates to:
  /// **'Go to Today'**
  String get goToTodayButtonLabel;

  /// Confirmation message before deleting a medication entry.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication entry?'**
  String get formConfirmDeleteMedMessage;

  /// Snackbar message shown after successfully deleting a medication entry.
  ///
  /// In en, this message translates to:
  /// **'Medication entry deleted.'**
  String get formSuccessMedDeleted;

  /// Snackbar message shown if deleting a medication entry fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete medication entry.'**
  String get formErrorFailedToDeleteMed;

  /// Tooltip for the delete button on a medication entry form.
  ///
  /// In en, this message translates to:
  /// **'Delete medication entry'**
  String get formTooltipDeleteMed;

  /// No description provided for @formConfirmDeleteMoodMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this mood entry?'**
  String get formConfirmDeleteMoodMessage;

  /// No description provided for @formSuccessMoodDeleted.
  ///
  /// In en, this message translates to:
  /// **'Mood entry deleted.'**
  String get formSuccessMoodDeleted;

  /// No description provided for @formErrorFailedToDeleteMood.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete mood entry.'**
  String get formErrorFailedToDeleteMood;

  /// No description provided for @formTooltipDeleteMood.
  ///
  /// In en, this message translates to:
  /// **'Delete mood entry'**
  String get formTooltipDeleteMood;

  /// No description provided for @formConfirmDeletePainMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this pain log?'**
  String get formConfirmDeletePainMessage;

  /// No description provided for @formSuccessPainDeleted.
  ///
  /// In en, this message translates to:
  /// **'Pain log deleted.'**
  String get formSuccessPainDeleted;

  /// No description provided for @formErrorFailedToDeletePain.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete pain log.'**
  String get formErrorFailedToDeletePain;

  /// No description provided for @formTooltipDeletePain.
  ///
  /// In en, this message translates to:
  /// **'Delete pain log'**
  String get formTooltipDeletePain;

  /// No description provided for @formConfirmDeleteActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this activity entry?'**
  String get formConfirmDeleteActivityMessage;

  /// No description provided for @formSuccessActivityDeleted.
  ///
  /// In en, this message translates to:
  /// **'Activity entry deleted.'**
  String get formSuccessActivityDeleted;

  /// No description provided for @formErrorFailedToDeleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete activity entry.'**
  String get formErrorFailedToDeleteActivity;

  /// No description provided for @formTooltipDeleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete activity entry'**
  String get formTooltipDeleteActivity;

  /// No description provided for @formConfirmDeleteSleepMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this sleep log?'**
  String get formConfirmDeleteSleepMessage;

  /// No description provided for @formSuccessSleepDeleted.
  ///
  /// In en, this message translates to:
  /// **'Sleep log deleted.'**
  String get formSuccessSleepDeleted;

  /// No description provided for @formErrorFailedToDeleteSleep.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete sleep log.'**
  String get formErrorFailedToDeleteSleep;

  /// No description provided for @formTooltipDeleteSleep.
  ///
  /// In en, this message translates to:
  /// **'Delete sleep log'**
  String get formTooltipDeleteSleep;

  /// No description provided for @formConfirmDeleteExpenseMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense entry?'**
  String get formConfirmDeleteExpenseMessage;

  /// No description provided for @formSuccessExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense entry deleted.'**
  String get formSuccessExpenseDeleted;

  /// No description provided for @formErrorFailedToDeleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete expense entry.'**
  String get formErrorFailedToDeleteExpense;

  /// No description provided for @formTooltipDeleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete expense entry'**
  String get formTooltipDeleteExpense;

  /// No description provided for @userSelectorSendToLabel.
  ///
  /// In en, this message translates to:
  /// **'Send to:'**
  String get userSelectorSendToLabel;

  /// No description provided for @userSelectorAudienceAll.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get userSelectorAudienceAll;

  /// No description provided for @userSelectorAudienceSpecific.
  ///
  /// In en, this message translates to:
  /// **'Specific Users'**
  String get userSelectorAudienceSpecific;

  /// No description provided for @userSelectorNoUsersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No other users available for selection.'**
  String get userSelectorNoUsersAvailable;

  /// No description provided for @timelinePostingToAll.
  ///
  /// In en, this message translates to:
  /// **'Posting to: All Users'**
  String get timelinePostingToAll;

  /// Message indicating the number of users a timeline post is being sent to.
  ///
  /// In en, this message translates to:
  /// **'Posting to: {count} specific users'**
  String timelinePostingToCount(String count);

  /// No description provided for @timelinePrivateMessageIndicator.
  ///
  /// In en, this message translates to:
  /// **'Private Message'**
  String get timelinePrivateMessageIndicator;

  /// No description provided for @timelineEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get timelineEditMessage;

  /// No description provided for @timelineDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get timelineDeleteMessage;

  /// No description provided for @timelineConfirmDeleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message?'**
  String get timelineConfirmDeleteMessageTitle;

  /// No description provided for @timelineConfirmDeleteMessageContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get timelineConfirmDeleteMessageContent;

  /// No description provided for @timelineMessageDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message deleted.'**
  String get timelineMessageDeletedSuccess;

  /// No description provided for @timelineErrorDeletingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error deleting message: {errorMessage}'**
  String timelineErrorDeletingMessage(String errorMessage);

  /// No description provided for @timelineMessageUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message updated.'**
  String get timelineMessageUpdatedSuccess;

  /// No description provided for @timelineErrorUpdatingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error updating message: {errorMessage}'**
  String timelineErrorUpdatingMessage(String errorMessage);

  /// No description provided for @timelineUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get timelineUpdateButton;

  /// No description provided for @timelineHideMessage.
  ///
  /// In en, this message translates to:
  /// **'Hide Message'**
  String get timelineHideMessage;

  /// No description provided for @timelineMessageHiddenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message hidden from your view.'**
  String get timelineMessageHiddenSuccess;

  /// No description provided for @timelineShowHiddenMessagesButton.
  ///
  /// In en, this message translates to:
  /// **'Show Hidden'**
  String get timelineShowHiddenMessagesButton;

  /// No description provided for @timelineHideHiddenMessagesButton.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get timelineHideHiddenMessagesButton;

  /// No description provided for @timelineUnhideMessage.
  ///
  /// In en, this message translates to:
  /// **'Unhide Message'**
  String get timelineUnhideMessage;

  /// No description provided for @timelineMessageUnhiddenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message unhidden.'**
  String get timelineMessageUnhiddenSuccess;

  /// No description provided for @timelineNoHiddenMessages.
  ///
  /// In en, this message translates to:
  /// **'You have no hidden messages for this timeline.'**
  String get timelineNoHiddenMessages;

  /// Title for the Self Care screen
  ///
  /// In en, this message translates to:
  /// **'Self Care'**
  String get selfCareScreenTitle;

  /// No description provided for @settingsTitleNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get settingsTitleNotificationPreferences;

  /// No description provided for @settingsItemNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get settingsItemNotificationPreferences;

  /// No description provided for @landingPageAlreadyLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You’re already logged in!'**
  String get landingPageAlreadyLoggedIn;

  /// No description provided for @manageMedications.
  ///
  /// In en, this message translates to:
  /// **'Manage Medications'**
  String get manageMedications;

  /// No description provided for @medicationsScreenTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsScreenTitleGeneric;

  /// Title for the medications screen, specific to an elder.
  ///
  /// In en, this message translates to:
  /// **'{name}’s Medications'**
  String medicationsScreenTitleForElder(String name);

  /// No description provided for @medicationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search drug name'**
  String get medicationsSearchHint;

  /// No description provided for @medicationsDoseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10 mg'**
  String get medicationsDoseHint;

  /// No description provided for @medicationsScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AM / PM'**
  String get medicationsScheduleHint;

  /// No description provided for @medicationsListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No medications added yet'**
  String get medicationsListEmpty;

  /// No description provided for @medicationsDoseNotSet.
  ///
  /// In en, this message translates to:
  /// **'Dose not set'**
  String get medicationsDoseNotSet;

  /// No description provided for @medicationsScheduleNotSet.
  ///
  /// In en, this message translates to:
  /// **'Schedule not set'**
  String get medicationsScheduleNotSet;

  /// No description provided for @medicationsTooltipDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete medication'**
  String get medicationsTooltipDelete;

  /// No description provided for @medicationsConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \'{medName}\'?'**
  String medicationsConfirmDeleteTitle(String medName);

  /// No description provided for @medicationsConfirmDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get medicationsConfirmDeleteContent;

  /// No description provided for @medicationsDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication \'{medName}\' removed.'**
  String medicationsDeletedSuccess(String medName);

  /// No description provided for @rxNavGenericSearchError.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch drug list. Try again.'**
  String get rxNavGenericSearchError;

  /// No description provided for @medicationsValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get medicationsValidationNameRequired;

  /// No description provided for @medicationsValidationDoseRequired.
  ///
  /// In en, this message translates to:
  /// **'Dose required'**
  String get medicationsValidationDoseRequired;

  /// No description provided for @medicationsInteractionsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible interactions found'**
  String get medicationsInteractionsFoundTitle;

  /// No description provided for @medicationsNoInteractionsFound.
  ///
  /// In en, this message translates to:
  /// **'No interactions found'**
  String get medicationsNoInteractionsFound;

  /// No description provided for @medicationsInteractionsSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get medicationsInteractionsSaveAnyway;

  /// No description provided for @medicationsAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get medicationsAddDialogTitle;

  /// No description provided for @medicationsAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication \'{medName}\' added.'**
  String medicationsAddedSuccess(String medName);

  /// No description provided for @routeErrorGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get routeErrorGenericMessage;

  /// No description provided for @goHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHomeButton;

  /// No description provided for @settingsTitleHelpfulResources.
  ///
  /// In en, this message translates to:
  /// **'Helpful Resources'**
  String get settingsTitleHelpfulResources;

  /// No description provided for @settingsItemHelpfulResources.
  ///
  /// In en, this message translates to:
  /// **'View Helpful Resources'**
  String get settingsItemHelpfulResources;

  /// No description provided for @timelineFilterOnlyMyLogs.
  ///
  /// In en, this message translates to:
  /// **'Only My Logs:'**
  String get timelineFilterOnlyMyLogs;

  /// No description provided for @timelineFilterFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get timelineFilterFromDate;

  /// No description provided for @timelineFilterToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get timelineFilterToDate;

  /// Title for the section warning about possible medication interactions.
  ///
  /// In en, this message translates to:
  /// **'Potential Medication Interactions'**
  String get medicationsInteractionsSectionTitle;

  /// No description provided for @inclusiveLanguageGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Inclusive Language Guidance'**
  String get inclusiveLanguageGuideTitle;

  /// No description provided for @inclusiveLanguageTip1Title.
  ///
  /// In en, this message translates to:
  /// **'Respect Preferred Names'**
  String get inclusiveLanguageTip1Title;

  /// No description provided for @inclusiveLanguageTip1Content.
  ///
  /// In en, this message translates to:
  /// **'Always use a person\'s preferred name. If you\'re unsure, ask respectfully: \'What name do you prefer to be called?\''**
  String get inclusiveLanguageTip1Content;

  /// No description provided for @inclusiveLanguageTip2Title.
  ///
  /// In en, this message translates to:
  /// **'Use Correct Pronouns'**
  String get inclusiveLanguageTip2Title;

  /// No description provided for @inclusiveLanguageTip2Content.
  ///
  /// In en, this message translates to:
  /// **'If you know someone\'s preferred pronouns, use them consistently. If you don\'t know, use gender-neutral language (they/them) or ask: \'What are your preferred pronouns?\''**
  String get inclusiveLanguageTip2Content;

  /// Label for the sexual orientation field in user account settings
  ///
  /// In en, this message translates to:
  /// **'Sexual Orientation'**
  String get settingsLabelSexualOrientation;

  /// No description provided for @settingsHintSexualOrientation.
  ///
  /// In en, this message translates to:
  /// **'Enter your sexual orientation (optional)'**
  String get settingsHintSexualOrientation;

  /// Label for the gender identity field in user account settings
  ///
  /// In en, this message translates to:
  /// **'Gender Identity'**
  String get settingsLabelGenderIdentity;

  /// No description provided for @settingsHintGenderIdentity.
  ///
  /// In en, this message translates to:
  /// **'Enter your gender identity (optional)'**
  String get settingsHintGenderIdentity;

  /// Label for the preferred pronouns field in user account settings
  ///
  /// In en, this message translates to:
  /// **'Preferred Pronouns'**
  String get settingsLabelPreferredPronouns;

  /// No description provided for @settingsHintPreferredPronouns.
  ///
  /// In en, this message translates to:
  /// **'e.g., she/her, he/him, they/them (optional)'**
  String get settingsHintPreferredPronouns;

  /// Error message when a URL cannot be launched.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {urlString}'**
  String couldNotLaunchUrl(String urlString);

  /// Title for the Helpful Resources screen
  ///
  /// In en, this message translates to:
  /// **'Helpful Resources'**
  String get helpfulResourcesTitle;

  /// Greeting message for the home screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}! Thank you for trusting Cecelia Care to help you support {elderName}\'s well-being.'**
  String homeScreenWelcomeGreeting(String userName, String elderName);

  /// Label for the user goals/challenges field in My Account settings.
  ///
  /// In en, this message translates to:
  /// **'My Caregiving Goals/Challenges'**
  String get settingsLabelUserGoals;

  /// Hint text for the user goals/challenges field in My Account settings.
  ///
  /// In en, this message translates to:
  /// **'What support are you looking for? (e.g., managing medications, tracking mood changes, coordinating with other caregivers)'**
  String get settingsHintUserGoals;

  /// No description provided for @badgeLabelFirstMoodLog.
  ///
  /// In en, this message translates to:
  /// **'Mood Monitor'**
  String get badgeLabelFirstMoodLog;

  /// No description provided for @badgeDescriptionFirstMoodLog.
  ///
  /// In en, this message translates to:
  /// **'Congratulations on logging your first mood entry!'**
  String get badgeDescriptionFirstMoodLog;

  /// No description provided for @badgeLabelFirstMedLog.
  ///
  /// In en, this message translates to:
  /// **'Medication Tracker'**
  String get badgeLabelFirstMedLog;

  /// No description provided for @badgeDescriptionFirstMedLog.
  ///
  /// In en, this message translates to:
  /// **'You\'ve successfully logged your first medication entry.'**
  String get badgeDescriptionFirstMedLog;

  /// No description provided for @badgeLabelFirstActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Starter'**
  String get badgeLabelFirstActivityLog;

  /// No description provided for @badgeDescriptionFirstActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Great job logging your first activity!'**
  String get badgeDescriptionFirstActivityLog;

  /// No description provided for @badgeLabelMedMaestro10.
  ///
  /// In en, this message translates to:
  /// **'Medication Maestro (10)'**
  String get badgeLabelMedMaestro10;

  /// No description provided for @badgeDescriptionMedMaestro10.
  ///
  /// In en, this message translates to:
  /// **'Logged 10 medication entries. You\'re a pro!'**
  String get badgeDescriptionMedMaestro10;

  /// No description provided for @badgeLabelActivityChampion7.
  ///
  /// In en, this message translates to:
  /// **'Activity Champion (7 Days)'**
  String get badgeLabelActivityChampion7;

  /// No description provided for @badgeDescriptionActivityChampion7.
  ///
  /// In en, this message translates to:
  /// **'Logged an activity every day for a week!'**
  String get badgeDescriptionActivityChampion7;

  /// No description provided for @badgesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'My Achievements'**
  String get badgesScreenTitle;

  /// No description provided for @badgesScreenNoBadges.
  ///
  /// In en, this message translates to:
  /// **'No badges available yet. Keep using the app to earn them!'**
  String get badgesScreenNoBadges;

  /// Title for the achievements/badges section on the Self Care screen.
  ///
  /// In en, this message translates to:
  /// **'My Achievements'**
  String get selfCareScreenAchievementsTitle;

  /// Message shown on Self Care screen when no badges are unlocked.
  ///
  /// In en, this message translates to:
  /// **'No badges unlocked yet. Keep up the great work!'**
  String get selfCareScreenNoBadgesUnlocked;

  /// Title for the Image Upload screen link in settings
  ///
  /// In en, this message translates to:
  /// **'Image Scanner & Uploader'**
  String get imageUploadScreenTitle;

  /// Error message shown when trying to access image upload without an active elder.
  ///
  /// In en, this message translates to:
  /// **'Please select an active elder profile to upload images.'**
  String get imageUploadErrorNoElderSelected;

  /// Error message when image picking fails.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {errorDetails}'**
  String imageUploadErrorPicking(String errorDetails);

  /// Error message when user tries to upload without selecting a file.
  ///
  /// In en, this message translates to:
  /// **'No file selected. Please pick an image first.'**
  String get imageUploadErrorNoFileSelected;

  /// Error message when an unauthenticated user tries to upload.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to upload images.'**
  String get imageUploadErrorNotLoggedIn;

  /// Default title for an uploaded image if user doesn't provide one.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Image'**
  String get imageUploadDefaultTitle;

  /// Success message after image upload.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully!'**
  String get imageUploadSuccess;

  /// Error message when image upload to storage or Firestore fails.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed: {errorDetails}'**
  String imageUploadErrorFailed(String errorDetails);

  /// Header text indicating for which elder the image is being uploaded.
  ///
  /// In en, this message translates to:
  /// **'Upload Image for {elderName}'**
  String imageUploadForElder(String elderName);

  /// No description provided for @imageUploadButtonGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get imageUploadButtonGallery;

  /// No description provided for @imageUploadButtonCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get imageUploadButtonCamera;

  /// No description provided for @imageUploadPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Preview:'**
  String get imageUploadPreviewTitle;

  /// No description provided for @imageUploadErrorLoadingPreview.
  ///
  /// In en, this message translates to:
  /// **'Error loading preview'**
  String get imageUploadErrorLoadingPreview;

  /// No description provided for @imageUploadLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Title (Optional)'**
  String get imageUploadLabelTitle;

  /// No description provided for @imageUploadHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for the image'**
  String get imageUploadHintTitle;

  /// No description provided for @imageUploadStatusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get imageUploadStatusUploading;

  /// No description provided for @imageUploadButtonUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get imageUploadButtonUpload;

  /// Title for the section displaying already uploaded images.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Images'**
  String get uploadedImagesSectionTitle;

  /// Message shown when no images are found for the selected elder.
  ///
  /// In en, this message translates to:
  /// **'No images uploaded yet for this elder.'**
  String get noImagesUploadedYet;

  /// Placeholder text when an image URL is invalid or image cannot be loaded in the grid.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @emergencyContactSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContactSectionTitle;

  /// No description provided for @emergencyContactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get emergencyContactNameLabel;

  /// No description provided for @emergencyContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get emergencyContactPhoneLabel;

  /// No description provided for @emergencyContactRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get emergencyContactRelationshipLabel;

  /// No description provided for @calendarRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Reminders'**
  String get calendarRemindersTitle;

  /// No description provided for @calendarReminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Reminder'**
  String get calendarReminderNotificationTitle;

  /// No description provided for @calendarReminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder for \"{title}\" set for {datetime}.'**
  String calendarReminderSet(String title, String datetime);

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @vaccineCovid19.
  ///
  /// In en, this message translates to:
  /// **'COVID-19 Vaccine'**
  String get vaccineCovid19;

  /// No description provided for @vaccineCovid19Freq.
  ///
  /// In en, this message translates to:
  /// **'At least 2 doses of current vaccine for adults 65+'**
  String get vaccineCovid19Freq;

  /// No description provided for @vaccineInfluenza.
  ///
  /// In en, this message translates to:
  /// **'Influenza (Flu) Vaccine'**
  String get vaccineInfluenza;

  /// No description provided for @vaccineInfluenzaFreq.
  ///
  /// In en, this message translates to:
  /// **'1 dose annually'**
  String get vaccineInfluenzaFreq;

  /// No description provided for @vaccineRSV.
  ///
  /// In en, this message translates to:
  /// **'RSV Vaccine'**
  String get vaccineRSV;

  /// No description provided for @vaccineRSVFreq.
  ///
  /// In en, this message translates to:
  /// **'1 dose, recommended for adults ≥60 years'**
  String get vaccineRSVFreq;

  /// No description provided for @vaccineTdap.
  ///
  /// In en, this message translates to:
  /// **'Tdap/Td Vaccine'**
  String get vaccineTdap;

  /// No description provided for @vaccineTdapFreq.
  ///
  /// In en, this message translates to:
  /// **'Booster every 10 years'**
  String get vaccineTdapFreq;

  /// No description provided for @vaccineShingles.
  ///
  /// In en, this message translates to:
  /// **'Shingles (Zoster) Vaccine'**
  String get vaccineShingles;

  /// No description provided for @vaccineShinglesFreq.
  ///
  /// In en, this message translates to:
  /// **'2 doses for healthy adults ≥50 years'**
  String get vaccineShinglesFreq;

  /// No description provided for @vaccinePneumococcal.
  ///
  /// In en, this message translates to:
  /// **'Pneumococcal Vaccine'**
  String get vaccinePneumococcal;

  /// No description provided for @vaccinePneumococcalFreq.
  ///
  /// In en, this message translates to:
  /// **'All adults ≥65 years'**
  String get vaccinePneumococcalFreq;

  /// No description provided for @vaccineHepatitisB.
  ///
  /// In en, this message translates to:
  /// **'Hepatitis B Vaccine'**
  String get vaccineHepatitisB;

  /// No description provided for @vaccineHepatitisBFreq.
  ///
  /// In en, this message translates to:
  /// **'For adults 60+ with risk factors'**
  String get vaccineHepatitisBFreq;

  /// No description provided for @checkupPhysicalExam.
  ///
  /// In en, this message translates to:
  /// **'Annual Physical Exam'**
  String get checkupPhysicalExam;

  /// No description provided for @checkupPhysicalExamFreq.
  ///
  /// In en, this message translates to:
  /// **'Annually'**
  String get checkupPhysicalExamFreq;

  /// No description provided for @checkupMammogram.
  ///
  /// In en, this message translates to:
  /// **'Mammogram'**
  String get checkupMammogram;

  /// No description provided for @checkupMammogramFreq.
  ///
  /// In en, this message translates to:
  /// **'Every 1-2 years for women'**
  String get checkupMammogramFreq;

  /// No description provided for @checkupPapTest.
  ///
  /// In en, this message translates to:
  /// **'Cervical Cancer (Pap test)'**
  String get checkupPapTest;

  /// No description provided for @checkupPapTestFreq.
  ///
  /// In en, this message translates to:
  /// **'May not be needed if over 65 with normal test history'**
  String get checkupPapTestFreq;

  /// No description provided for @checkupColonCancer.
  ///
  /// In en, this message translates to:
  /// **'Colon Cancer Screening'**
  String get checkupColonCancer;

  /// No description provided for @checkupColonCancerFreq.
  ///
  /// In en, this message translates to:
  /// **'Colonoscopy every 10 years'**
  String get checkupColonCancerFreq;

  /// No description provided for @checkupLungCancer.
  ///
  /// In en, this message translates to:
  /// **'Lung Cancer Screening'**
  String get checkupLungCancer;

  /// No description provided for @checkupLungCancerFreq.
  ///
  /// In en, this message translates to:
  /// **'Yearly for long-time smokers'**
  String get checkupLungCancerFreq;

  /// No description provided for @checkupProstateCancer.
  ///
  /// In en, this message translates to:
  /// **'Prostate Cancer (DRE/PSA)'**
  String get checkupProstateCancer;

  /// No description provided for @checkupProstateCancerFreq.
  ///
  /// In en, this message translates to:
  /// **'Discuss with provider (men 55-70)'**
  String get checkupProstateCancerFreq;

  /// No description provided for @checkupSkinCancer.
  ///
  /// In en, this message translates to:
  /// **'Skin Cancer Checks'**
  String get checkupSkinCancer;

  /// No description provided for @checkupSkinCancerFreq.
  ///
  /// In en, this message translates to:
  /// **'Regular checks as needed'**
  String get checkupSkinCancerFreq;

  /// No description provided for @checkupBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get checkupBloodPressure;

  /// No description provided for @checkupBloodPressureFreq.
  ///
  /// In en, this message translates to:
  /// **'At least annually'**
  String get checkupBloodPressureFreq;

  /// No description provided for @checkupCholesterol.
  ///
  /// In en, this message translates to:
  /// **'Cholesterol Screening'**
  String get checkupCholesterol;

  /// No description provided for @checkupCholesterolFreq.
  ///
  /// In en, this message translates to:
  /// **'Every 4-6 years for normal risk'**
  String get checkupCholesterolFreq;

  /// No description provided for @checkupBloodGlucose.
  ///
  /// In en, this message translates to:
  /// **'Blood Glucose (A1C)'**
  String get checkupBloodGlucose;

  /// No description provided for @checkupBloodGlucoseFreq.
  ///
  /// In en, this message translates to:
  /// **'Every 3 years if results are normal'**
  String get checkupBloodGlucoseFreq;

  /// No description provided for @checkupVision.
  ///
  /// In en, this message translates to:
  /// **'Vision Screening'**
  String get checkupVision;

  /// No description provided for @checkupVisionFreq.
  ///
  /// In en, this message translates to:
  /// **'Annually for 50+'**
  String get checkupVisionFreq;

  /// No description provided for @checkupHearing.
  ///
  /// In en, this message translates to:
  /// **'Hearing Screening'**
  String get checkupHearing;

  /// No description provided for @checkupHearingFreq.
  ///
  /// In en, this message translates to:
  /// **'Every 1-3 years for 65+'**
  String get checkupHearingFreq;

  /// No description provided for @checkupBoneDensity.
  ///
  /// In en, this message translates to:
  /// **'Bone Density (DXA)'**
  String get checkupBoneDensity;

  /// No description provided for @checkupBoneDensityFreq.
  ///
  /// In en, this message translates to:
  /// **'Every 1-2 years if on osteoporosis medicine'**
  String get checkupBoneDensityFreq;

  /// No description provided for @checkupCognitive.
  ///
  /// In en, this message translates to:
  /// **'Cognitive Assessment'**
  String get checkupCognitive;

  /// No description provided for @checkupCognitiveFreq.
  ///
  /// In en, this message translates to:
  /// **'Annually for 65+'**
  String get checkupCognitiveFreq;

  /// No description provided for @checkupMentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health Screening'**
  String get checkupMentalHealth;

  /// No description provided for @checkupMentalHealthFreq.
  ///
  /// In en, this message translates to:
  /// **'As needed, during annual physical'**
  String get checkupMentalHealthFreq;

  /// No description provided for @timelineFilterResetDates.
  ///
  /// In en, this message translates to:
  /// **'Reset Dates'**
  String get timelineFilterResetDates;

  /// No description provided for @dialogTitleAddNewLog.
  ///
  /// In en, this message translates to:
  /// **'Add a New Log'**
  String get dialogTitleAddNewLog;

  /// No description provided for @formTooltipVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Tap for voice input'**
  String get formTooltipVoiceInput;

  /// No description provided for @journalEntryCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Journal entry cannot be empty.'**
  String get journalEntryCannotBeEmpty;

  /// No description provided for @journalEntryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Journal entry updated successfully!'**
  String get journalEntryUpdatedSuccessfully;

  /// No description provided for @journalEntryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Journal entry added successfully!'**
  String get journalEntryAddedSuccessfully;

  /// No description provided for @journalEntryDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Journal entry deleted successfully.'**
  String get journalEntryDeletedSuccessfully;

  /// No description provided for @failedToDeleteJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete journal entry.'**
  String get failedToDeleteJournalEntry;

  /// No description provided for @caregiverJournal.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Journal'**
  String get caregiverJournal;

  /// No description provided for @pleaseLogInToAccessJournal.
  ///
  /// In en, this message translates to:
  /// **'Please log in to access your journal.'**
  String get pleaseLogInToAccessJournal;

  /// No description provided for @editJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Journal Entry'**
  String get editJournalEntry;

  /// No description provided for @addJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Add New Journal Entry'**
  String get addJournalEntry;

  /// No description provided for @writeYourEntryHere.
  ///
  /// In en, this message translates to:
  /// **'Write your entry here...'**
  String get writeYourEntryHere;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @noJournalEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet.'**
  String get noJournalEntriesYet;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No Content'**
  String get noContent;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @updateEntry.
  ///
  /// In en, this message translates to:
  /// **'Update Entry'**
  String get updateEntry;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel Edit'**
  String get cancelEdit;

  /// No description provided for @dailyMood.
  ///
  /// In en, this message translates to:
  /// **'Daily Mood'**
  String get dailyMood;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get optionalNote;

  /// No description provided for @breakReminders.
  ///
  /// In en, this message translates to:
  /// **'Break Reminders'**
  String get breakReminders;

  /// No description provided for @hydrate.
  ///
  /// In en, this message translates to:
  /// **'Hydrate'**
  String get hydrate;

  /// No description provided for @stretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get stretch;

  /// No description provided for @walk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get walk;

  /// No description provided for @caregiverJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Journal'**
  String get caregiverJournalTitle;

  /// No description provided for @caregiverJournalButton.
  ///
  /// In en, this message translates to:
  /// **'Open Caregiver Journal'**
  String get caregiverJournalButton;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @selfCareReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-Care Reminder'**
  String get selfCareReminderTitle;

  /// No description provided for @timeTo.
  ///
  /// In en, this message translates to:
  /// **'Time to'**
  String get timeTo;

  /// No description provided for @timelineAddNewLogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a new log'**
  String get timelineAddNewLogTooltip;

  /// No description provided for @timelineNewMessageButton.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get timelineNewMessageButton;

  /// No description provided for @settingsTitleCareRecipientProfileManagement.
  ///
  /// In en, this message translates to:
  /// **'Care Recipient Management'**
  String get settingsTitleCareRecipientProfileManagement;

  /// No description provided for @settingsCurrentCareRecipient.
  ///
  /// In en, this message translates to:
  /// **'Active Care Recipient: {profileName}'**
  String settingsCurrentCareRecipient(String profileName);

  /// No description provided for @settingsNoActiveCareRecipientSelected.
  ///
  /// In en, this message translates to:
  /// **'No active care recipient is selected.'**
  String get settingsNoActiveCareRecipientSelected;

  /// No description provided for @settingsButtonManageCareRecipientProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage Care Recipient Profiles'**
  String get settingsButtonManageCareRecipientProfiles;

  /// No description provided for @settingsErrorNavToManageCareRecipientProfiles.
  ///
  /// In en, this message translates to:
  /// **'Could not navigate to manage profiles.'**
  String get settingsErrorNavToManageCareRecipientProfiles;

  /// No description provided for @manageCareRecipientProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Care Recipient Profiles'**
  String get manageCareRecipientProfilesTitle;

  /// No description provided for @createCareRecipientProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Care Recipient Profile'**
  String get createCareRecipientProfileTitle;

  /// No description provided for @noCareRecipientProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No care recipient profiles found.'**
  String get noCareRecipientProfilesFound;

  /// No description provided for @errorCareRecipientIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Care Recipient ID is missing, cannot update.'**
  String get errorCareRecipientIdMissing;

  /// No description provided for @errorSelectCareRecipientAndEmail.
  ///
  /// In en, this message translates to:
  /// **'Please select a care recipient and enter an email.'**
  String get errorSelectCareRecipientAndEmail;

  /// No description provided for @timelineFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline Filters'**
  String get timelineFiltersTitle;

  /// No description provided for @careScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get careScreenTitle;

  /// No description provided for @budgetTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Tracker'**
  String get budgetTrackerTitle;

  /// No description provided for @settingsProfileNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get settingsProfileNoChanges;

  /// No description provided for @formErrorNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Error: User not authenticated. Please sign in again.'**
  String get formErrorNotAuthenticated;

  /// No description provided for @activityFormLabelActivityTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Activity Type*'**
  String get activityFormLabelActivityTypeRequired;

  /// No description provided for @medFormLabelNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Medication Name*'**
  String get medFormLabelNameRequired;

  /// No description provided for @vitalFormLabelTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Vital Type*'**
  String get vitalFormLabelTypeRequired;

  /// No description provided for @medicationsTooltipAskCecelia.
  ///
  /// In en, this message translates to:
  /// **'Ask Cecelia about medications'**
  String get medicationsTooltipAskCecelia;

  /// No description provided for @formErrorUserOrElderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not find user or care recipient profile.'**
  String get formErrorUserOrElderNotFound;

  /// No description provided for @medicationDefinitionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save medication to the managed list.'**
  String get medicationDefinitionSaveFailed;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @settingsTitleCareRecipientManagement.
  ///
  /// In en, this message translates to:
  /// **'Care Recipient Management'**
  String get settingsTitleCareRecipientManagement;

  /// No description provided for @settingsActiveCareRecipient.
  ///
  /// In en, this message translates to:
  /// **'Active: {name}'**
  String settingsActiveCareRecipient(String name);

  /// No description provided for @settingsNoActiveCareRecipient.
  ///
  /// In en, this message translates to:
  /// **'No active care recipient is selected.'**
  String get settingsNoActiveCareRecipient;

  /// No description provided for @settingsItemManageProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage Care Recipient Profiles'**
  String get settingsItemManageProfiles;

  /// No description provided for @settingsErrorCouldNotNavigateToProfiles.
  ///
  /// In en, this message translates to:
  /// **'Could not navigate to manage profiles.'**
  String get settingsErrorCouldNotNavigateToProfiles;

  /// No description provided for @settingsItemClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data for This Care Recipient'**
  String get settingsItemClearData;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @cancelReminder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reminder'**
  String get cancelReminder;

  /// No description provided for @ceceliaBotName.
  ///
  /// In en, this message translates to:
  /// **'Cecelia'**
  String get ceceliaBotName;

  /// No description provided for @chatWithCeceliaTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with Cecelia'**
  String get chatWithCeceliaTitle;

  /// No description provided for @ceceliaInitialGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am a specialized bot for medication interactions. How can I assist you today?'**
  String get ceceliaInitialGreeting;

  /// No description provided for @geminiUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get geminiUnknownError;

  /// No description provided for @notificationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferencesTitle;

  /// No description provided for @medsNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get medsNotificationsLabel;

  /// No description provided for @calendarNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar Events'**
  String get calendarNotificationsLabel;

  /// No description provided for @selfCareNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Self-Care Reminders'**
  String get selfCareNotificationsLabel;

  /// No description provided for @chatNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat Message Notifications'**
  String get chatNotificationsLabel;

  /// No description provided for @healthRemindersNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Health Reminders'**
  String get healthRemindersNotificationsLabel;

  /// No description provided for @generalNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'General App Notifications'**
  String get generalNotificationsLabel;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {details}'**
  String genericError(String details);

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String characterCount(int count, int max);

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(String date);

  /// No description provided for @medicationsInteractionDetails.
  ///
  /// In en, this message translates to:
  /// **'{severity} interaction with {otherDrug}: {description}'**
  String medicationsInteractionDetails(
      Object severity, Object otherDrug, Object description);

  /// No description provided for @calendarEventStarting.
  ///
  /// In en, this message translates to:
  /// **'Event starting: {eventTitle}'**
  String calendarEventStarting(String eventTitle);

  /// No description provided for @calendarErrorSavingReminder.
  ///
  /// In en, this message translates to:
  /// **'Error saving reminder: {details}'**
  String calendarErrorSavingReminder(String details);

  /// No description provided for @calendarConfirmCancelReminder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the reminder for \"{reminderTitle}\"?'**
  String calendarConfirmCancelReminder(String reminderTitle);

  /// No description provided for @calendarReminderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Reminder for \"{reminderTitle}\" cancelled.'**
  String calendarReminderCancelled(String reminderTitle);

  /// No description provided for @calendarReminderSetFor.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for:'**
  String get calendarReminderSetFor;

  /// No description provided for @selfCareReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time to {activity}.'**
  String selfCareReminderBody(String activity);

  /// No description provided for @geminiFirebaseError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred with the AI service: {details}'**
  String geminiFirebaseError(String details);

  /// No description provided for @geminiCommunicationError.
  ///
  /// In en, this message translates to:
  /// **'I\'m sorry, I encountered a communication error: {details}'**
  String geminiCommunicationError(String details);

  /// No description provided for @geminiUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected system error occurred: {details}'**
  String geminiUnexpectedError(String details);

  /// No description provided for @vitalFormLabelValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Value ({unit})*'**
  String vitalFormLabelValueRequired(String unit);

  /// No description provided for @notificationChannelDefaultName.
  ///
  /// In en, this message translates to:
  /// **'General Notifications'**
  String get notificationChannelDefaultName;

  /// No description provided for @notificationChannelDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Channel for general app notifications.'**
  String get notificationChannelDefaultDescription;

  /// No description provided for @notificationChannelCalendarName.
  ///
  /// In en, this message translates to:
  /// **'Calendar Events'**
  String get notificationChannelCalendarName;

  /// No description provided for @notificationChannelCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for upcoming calendar events.'**
  String get notificationChannelCalendarDescription;

  /// No description provided for @notificationChannelMedRemindersName.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get notificationChannelMedRemindersName;

  /// No description provided for @notificationChannelMedRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders to take scheduled medications.'**
  String get notificationChannelMedRemindersDescription;

  /// No description provided for @notificationChannelSelfCareName.
  ///
  /// In en, this message translates to:
  /// **'Self-Care Breaks'**
  String get notificationChannelSelfCareName;

  /// No description provided for @notificationChannelSelfCareDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders to hydrate, stretch, and take a walk.'**
  String get notificationChannelSelfCareDescription;

  /// No description provided for @notificationChannelChatMessagesName.
  ///
  /// In en, this message translates to:
  /// **'Chat Messages'**
  String get notificationChannelChatMessagesName;

  /// No description provided for @notificationChannelChatMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for new direct messages.'**
  String get notificationChannelChatMessagesDescription;

  /// No description provided for @notificationChannelHealthRemindersName.
  ///
  /// In en, this message translates to:
  /// **'Health Reminders'**
  String get notificationChannelHealthRemindersName;

  /// No description provided for @notificationChannelHealthRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for important health checkups and vaccines.'**
  String get notificationChannelHealthRemindersDescription;

  /// No description provided for @medicationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminder: {medName}'**
  String medicationReminderTitle(String medName);

  /// No description provided for @medicationReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time to take {dosage} for {elderName}.'**
  String medicationReminderBody(String dosage, String elderName);

  /// Text to indicate an event lasts the entire day.
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get calendarAllDay;

  /// Text shown when the user has denied microphone permission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission was denied.'**
  String get formErrorMicPermissionDenied;

  /// Text shown when the AI fails to process a request.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during AI processing.'**
  String get formErrorAiProcessing;

  /// Formats the calories in the timeline summary for meals.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String timelineSummaryMealCaloriesFormat(String calories);

  /// Validation message shown when the event title is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter an event title.'**
  String get eventFormValidationTitle;

  /// Validation message shown when the event start date/time is not set.
  ///
  /// In en, this message translates to:
  /// **'Please select a start date and time.'**
  String get eventFormValidationStartDateTime;

  /// Dialog title for creating a new event.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get eventFormTitleCreate;

  /// Dialog title for editing an existing event.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get eventFormTitleEdit;

  /// Label for the event title input field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get eventFormLabelTitle;

  /// Label for the event type selector.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get eventFormLabelType;

  /// Label for the all-day toggle.
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get eventFormLabelAllDay;

  /// Label for the start date picker.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get eventFormLabelStartDate;

  /// Label for the end date picker.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get eventFormLabelEndDate;

  /// Label for the date picker when the event is all-day.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get eventFormLabelDate;

  /// Label for the start time picker.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get eventFormLabelStartTime;

  /// Label for the end time picker.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get eventFormLabelEndTime;

  /// Hint text for the date selection field.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get eventFormHintSelectDate;

  /// Error message when a required field is empty
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String validationErrorRequired(String fieldName);

  /// Error message when a field expects a number but gets text
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number for {fieldName}'**
  String validationErrorInvalidNumber(String fieldName);

  /// Error message when a number is outside the allowed range
  ///
  /// In en, this message translates to:
  /// **'{fieldName} must be between {min} and {max}'**
  String validationErrorNumericRange(String fieldName, String min, String max);

  /// Error message when a number must be positive
  ///
  /// In en, this message translates to:
  /// **'{fieldName} must be a positive number'**
  String validationErrorPositiveNumber(String fieldName);

  /// Error message when a field format (like regex) is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid format for {fieldName}'**
  String validationErrorInvalidFormat(String fieldName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
