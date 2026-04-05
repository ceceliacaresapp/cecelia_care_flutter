// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cecelia Care';

  @override
  String get loginButton => 'Login';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSetting => 'Language';

  @override
  String get manageElderProfilesTitle => 'Manage Care Recipients';

  @override
  String get createProfileButton => 'Create Profile';

  @override
  String get pleaseLogInToManageProfiles =>
      'Please log in to manage care recipient profiles.';

  @override
  String calendarScreenTitle(String elderName) {
    return 'Calendar for $elderName';
  }

  @override
  String get formOptionOther => 'Other';

  @override
  String get formLabelNotesOptional => 'Notes (Optional)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get updateButton => 'Update';

  @override
  String get saveButton => 'Save';

  @override
  String get okButton => 'OK';

  @override
  String get deleteButton => 'Delete';

  @override
  String get removeButton => 'Remove';

  @override
  String get inviteButton => 'Invite';

  @override
  String get activeButton => 'Active';

  @override
  String get setActiveButton => 'Set Active';

  @override
  String get sendInviteButton => 'Send Invite';

  @override
  String get formUnknownUser => 'Unknown User';

  @override
  String get timePickerHelpText => 'SELECT TIME';

  @override
  String get expenseFormTitleEdit => 'Edit Expense';

  @override
  String get expenseFormTitleNew => 'New Expense';

  @override
  String get expenseFormLabelDescription => 'Description';

  @override
  String get expenseFormHintDescription => 'e.g., Prescription refill';

  @override
  String get expenseFormValidationDescription => 'Please enter a description.';

  @override
  String get expenseFormLabelAmount => 'Amount';

  @override
  String get expenseFormHintAmount => 'e.g., 25.50';

  @override
  String get expenseFormValidationAmountEmpty => 'Please enter an amount';

  @override
  String get expenseFormValidationAmountInvalid =>
      'Please enter a valid amount greater than 0';

  @override
  String get expenseFormLabelCategory => 'Category';

  @override
  String get expenseCategoryMedical => 'Medical';

  @override
  String get expenseCategoryGroceries => 'Groceries';

  @override
  String get expenseCategorySupplies => 'Supplies';

  @override
  String get expenseCategoryHousehold => 'Household';

  @override
  String get expenseCategoryPersonalCare => 'Personal Care';

  @override
  String get expenseFormValidationCategory => 'Please select a category.';

  @override
  String get expenseFormHintNotes => 'Add any relevant notes here...';

  @override
  String get formErrorFailedToUpdateExpense =>
      'Failed to update expense. Please try again.';

  @override
  String get formErrorFailedToSaveExpense =>
      'Failed to save expense. Please try again.';

  @override
  String get mealFormTitleEdit => 'Edit Meal / Water Intake';

  @override
  String get mealFormTitleNew => 'Log Meal / Water Intake';

  @override
  String get mealFormLabelIntakeType => 'Intake Type';

  @override
  String get mealFormIntakeCategoryFood => 'Food';

  @override
  String get mealFormIntakeCategoryWater => 'Water';

  @override
  String get mealFormLabelMealType => 'Meal Type';

  @override
  String get mealFormMealTypeBreakfast => 'Breakfast';

  @override
  String get mealFormMealTypeLunch => 'Lunch';

  @override
  String get mealFormMealTypeSnack => 'Snack';

  @override
  String get mealFormMealTypeDinner => 'Dinner';

  @override
  String get mealFormLabelDescription => 'Description';

  @override
  String get mealFormHintFoodDescription => 'e.g., Chicken soup, toast';

  @override
  String get mealFormValidationFoodDescription => 'Please describe the food.';

  @override
  String get mealFormLabelWaterContext => 'Water Context (Optional)';

  @override
  String get mealFormHintWaterContext => 'e.g., With medication, Thirsty';

  @override
  String get mealFormLabelWaterAmount => 'Amount';

  @override
  String get mealFormHintWaterAmount => 'e.g., 1 glass, 200ml';

  @override
  String get mealFormValidationWaterAmount =>
      'Please specify the amount of water.';

  @override
  String get mealFormHintFoodNotes => 'e.g., Ate well, disliked carrots';

  @override
  String get mealFormHintWaterNotes => 'e.g., Drank slowly';

  @override
  String get formErrorFailedToUpdateMeal =>
      'Failed to update meal. Please try again.';

  @override
  String get formErrorFailedToSaveMeal =>
      'Failed to save meal. Please try again.';

  @override
  String get eventFormHintSelectTime => 'Select Time';

  @override
  String get mealFormLabelCalories => 'Calories';

  @override
  String get mealFormHintCalories => 'e.g., 500';

  @override
  String get sleepFormHintQuality => 'Rate quality (1-5)';

  @override
  String get sleepFormValidationQualityRange =>
      'Please enter a number between 1 and 5';

  @override
  String get medFormTitleEdit => 'Edit Medication';

  @override
  String get medFormTitleNew => 'Log Medication';

  @override
  String get medFormTimePickerHelpText => 'SELECT MEDICATION TIME';

  @override
  String get medFormLabelName => 'Medication Name';

  @override
  String get medFormHintNameCustom => 'Or type custom medication name';

  @override
  String get medFormHintName => 'Enter medication name';

  @override
  String get medFormValidationName => 'Please enter medication name.';

  @override
  String get medFormLabelDose => 'Dose (Optional)';

  @override
  String get medFormHintDose => 'e.g., 1 tablet, 10mg';

  @override
  String get medFormLabelTime => 'Time (Optional)';

  @override
  String get medFormHintTime => 'Select time';

  @override
  String get medFormLabelMarkAsTaken => 'Mark as Taken';

  @override
  String get formErrorFailedToUpdateMed =>
      'Failed to update medication. Please try again.';

  @override
  String get formErrorFailedToSaveMed =>
      'Failed to save medication. Please try again.';

  @override
  String get moodFormTitleEdit => 'Edit Mood';

  @override
  String get moodFormTitleNew => 'Log Mood';

  @override
  String get moodHappy => '😊 Happy';

  @override
  String get moodContent => '🙂 Content';

  @override
  String get moodSad => '😟 Sad';

  @override
  String get moodAnxious => '😬 Anxious';

  @override
  String get moodCalm => '😌 Calm';

  @override
  String get moodIrritable => '😠 Irritable';

  @override
  String get moodAgitated => '😫 Agitated';

  @override
  String get moodPlayful => '🥳 Playful';

  @override
  String get moodTired => '😴 Tired';

  @override
  String get moodOptionOther => '📝 Other';

  @override
  String get moodFormLabelSelectMood => 'Select Mood';

  @override
  String get moodFormValidationSelectOrSpecifyMood =>
      'Please select a mood or specify \'Other\'';

  @override
  String get moodFormValidationSpecifyOtherMood =>
      'Please specify the \'Other\' mood';

  @override
  String get moodFormHintSpecifyOtherMood => 'Describe the mood...';

  @override
  String get moodFormLabelIntensity => 'Intensity (1-5, Optional)';

  @override
  String get moodFormHintIntensity => '1 (Mild) - 5 (Severe)';

  @override
  String get moodFormValidationIntensityRange =>
      'Intensity must be between 1 and 5';

  @override
  String get moodFormHintNotes => 'e.g., Feeling good after a walk';

  @override
  String get moodFormButtonUpdate => 'Update Mood';

  @override
  String get moodFormButtonSave => 'Save Mood';

  @override
  String get formErrorFailedToUpdateMood =>
      'Failed to update mood. Please try again.';

  @override
  String get formErrorFailedToSaveMood =>
      'Failed to save mood. Please try again.';

  @override
  String get painFormTitleEdit => 'Edit Pain Log';

  @override
  String get painFormTitleNew => 'Log Pain';

  @override
  String get painTypeAching => 'Aching';

  @override
  String get painTypeBurning => 'Burning';

  @override
  String get painTypeDull => 'Dull';

  @override
  String get painTypeSharp => 'Sharp';

  @override
  String get painTypeShooting => 'Shooting';

  @override
  String get painTypeStabbing => 'Stabbing';

  @override
  String get painTypeThrobbing => 'Throbbing';

  @override
  String get painTypeTender => 'Tender';

  @override
  String get painFormLabelLocation => 'Location';

  @override
  String get painFormHintLocation => 'e.g., Left knee, Lower back';

  @override
  String get painFormValidationLocation =>
      'Please specify the location of pain.';

  @override
  String get painFormLabelIntensity => 'Intensity (0-10)';

  @override
  String get painFormHintIntensity => '0 (No pain) - 10 (Worst pain)';

  @override
  String get painFormValidationIntensityEmpty => 'Please enter pain intensity.';

  @override
  String get painFormValidationIntensityRange =>
      'Intensity must be between 0 and 10.';

  @override
  String get painFormLabelDescription => 'Description';

  @override
  String get painFormValidationSelectOrSpecifyDescription =>
      'Please select a description or specify \'Other\'';

  @override
  String get painFormValidationSpecifyOtherDescription =>
      'Please specify the \'Other\' description';

  @override
  String get painFormHintSpecifyOtherDescription => 'Describe the pain...';

  @override
  String get painFormHintNotes =>
      'e.g., Worse after activity, relieved by rest';

  @override
  String get formErrorFailedToUpdatePain =>
      'Failed to update pain log. Please try again.';

  @override
  String get formErrorFailedToSavePain =>
      'Failed to save pain log. Please try again.';

  @override
  String get sleepFormTitleEdit => 'Edit Sleep Log';

  @override
  String get sleepFormTitleNew => 'Log Sleep';

  @override
  String get sleepQualityGood => 'Good';

  @override
  String get sleepQualityFair => 'Fair';

  @override
  String get sleepQualityPoor => 'Poor';

  @override
  String get sleepQualityRestless => 'Restless';

  @override
  String get sleepQualityInterrupted => 'Interrupted';

  @override
  String get sleepFormLabelWentToBed => 'Went to Bed';

  @override
  String get sleepFormHintTimeWentToBed => 'Select time';

  @override
  String get sleepFormValidationTimeWentToBed =>
      'Please select time went to bed.';

  @override
  String get sleepFormLabelWokeUp => 'Woke Up (Optional)';

  @override
  String get sleepFormHintTimeWokeUp => 'Select time';

  @override
  String get sleepFormLabelTotalDuration => 'Total Duration (Optional)';

  @override
  String get sleepFormHintTotalDuration => 'e.g., 7 hours, 7h 30m';

  @override
  String get sleepFormLabelQuality => 'Quality';

  @override
  String get sleepFormValidationSelectQuality => 'Please select sleep quality';

  @override
  String get sleepFormLabelDescribeOtherQuality => 'Describe Other Quality';

  @override
  String get sleepFormHintDescribeOtherQuality =>
      'Describe the sleep quality...';

  @override
  String get sleepFormValidationDescribeOtherQuality =>
      'Please describe the \'Other\' sleep quality';

  @override
  String get sleepFormLabelNaps => 'Naps (Optional)';

  @override
  String get sleepFormHintNaps => 'e.g., 1 nap, 30 mins';

  @override
  String get sleepFormLabelGeneralNotes => 'General Notes (Optional)';

  @override
  String get sleepFormHintGeneralNotes => 'e.g., Woke up feeling refreshed';

  @override
  String get sleepFormButtonUpdate => 'Update Sleep';

  @override
  String get sleepFormButtonSave => 'Save Sleep';

  @override
  String get formErrorFailedToUpdateSleep =>
      'Failed to update sleep log. Please try again.';

  @override
  String get formErrorFailedToSaveSleep =>
      'Failed to save sleep log. Please try again.';

  @override
  String get vitalFormTitleEdit => 'Edit Vital Sign';

  @override
  String get vitalFormTitleNew => 'Log Vital Sign';

  @override
  String get vitalTypeBPLabel => 'Blood Pressure';

  @override
  String get vitalTypeBPUnit => 'mmHg';

  @override
  String get vitalTypeBPPlaceholder => 'e.g., 120/80';

  @override
  String get vitalTypeHRLabel => 'Heart Rate';

  @override
  String get vitalTypeHRUnit => 'bpm';

  @override
  String get vitalTypeHRPlaceholder => 'e.g., 70';

  @override
  String get vitalTypeWTLabel => 'Weight';

  @override
  String get vitalTypeWTUnit => 'kg/lbs';

  @override
  String get vitalTypeWTPlaceholder => 'e.g., 65 kg or 143 lbs';

  @override
  String get vitalTypeBGLabel => 'Blood Glucose';

  @override
  String get vitalTypeBGUnit => 'mg/dL or mmol/L';

  @override
  String get vitalTypeBGPlaceholder => 'e.g., 90 mg/dL';

  @override
  String get vitalTypeTempLabel => 'Temperature';

  @override
  String get vitalTypeTempUnit => '°C/°F';

  @override
  String get vitalTypeTempPlaceholder => 'e.g., 36.5°C or 97.7°F';

  @override
  String get vitalTypeO2Label => 'Oxygen Saturation';

  @override
  String get vitalTypeO2Unit => '%';

  @override
  String get vitalTypeO2Placeholder => 'e.g., 98';

  @override
  String get vitalFormLabelType => 'Type';

  @override
  String get vitalFormLabelValue => 'Value';

  @override
  String get vitalFormValidationValueEmpty => 'Please enter a value';

  @override
  String get vitalFormValidationBPFormat =>
      'Enter BP as \'SYS/DIA\', e.g., 120/80.';

  @override
  String get vitalFormValidationValueNumeric => 'Please enter a numeric value.';

  @override
  String get vitalFormHintNotes => 'e.g., Taken after meal';

  @override
  String get vitalFormButtonUpdate => 'Update Vital';

  @override
  String get vitalFormButtonSave => 'Save Vital';

  @override
  String get formErrorFailedToUpdateVital =>
      'Failed to update vital. Please try again.';

  @override
  String get formErrorFailedToSaveVital =>
      'Failed to save vital. Please try again.';

  @override
  String get settingsUserProfileNotLoaded => 'User profile not loaded.';

  @override
  String get settingsDisplayNameCannotBeEmpty =>
      'Display name cannot be empty.';

  @override
  String get settingsProfileUpdatedSuccess => 'Profile updated successfully.';

  @override
  String settingsErrorUpdatingProfile(String errorMessage) {
    return 'Error updating profile: $errorMessage';
  }

  @override
  String get settingsSelectElderFirstMedDef =>
      'Please select a care recipient first to manage medication definitions.';

  @override
  String get settingsMedNameRequired => 'Medication name is required.';

  @override
  String get settingsMedDefaultTimeFormatError =>
      'Invalid time format. Please use HH:mm (e.g., 09:00).';

  @override
  String get settingsMedDefAddedSuccess =>
      'Medication definition added successfully.';

  @override
  String get settingsClearDataErrorElderOrUserMissing =>
      'Cannot clear data: Active care recipient or user is missing.';

  @override
  String get settingsClearDataErrorNotAdmin =>
      'You are not the primary admin for this care recipient\'s profile. Data can only be cleared by the primary admin.';

  @override
  String settingsClearDataDialogTitle(String elderName) {
    return 'Clear All Data for $elderName?';
  }

  @override
  String get settingsClearDataDialogContent =>
      'This action is irreversible and will delete all associated records (medications, meals, vitals, etc.) for this care recipient. Are you sure you want to proceed?';

  @override
  String get settingsClearDataDialogConfirmButton => 'Yes, Clear All Data';

  @override
  String settingsClearDataSuccess(String elderName) {
    return 'All data for $elderName has been cleared.';
  }

  @override
  String settingsClearDataErrorGeneric(String errorMessage) {
    return 'Error clearing data: $errorMessage';
  }

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameEs => 'Español (Spanish)';

  @override
  String get languageNameJa => '日本語 (Japanese)';

  @override
  String get languageNameKo => '한국어 (Korean)';

  @override
  String get languageNameZh => '中文 (Chinese)';

  @override
  String get settingsTitleMyAccount => 'My Account';

  @override
  String get settingsLabelDisplayName => 'Display Name';

  @override
  String get settingsHintDisplayName => 'Enter your display name';

  @override
  String get settingsLabelDOB => 'Date of Birth';

  @override
  String get settingsHintDOB => 'Select your date of birth';

  @override
  String get settingsButtonSaveProfile => 'Save Profile';

  @override
  String get settingsButtonSignOut => 'Sign Out';

  @override
  String get settingsErrorLoadingProfile => 'Error loading profile.';

  @override
  String get settingsTitleLanguage => 'Language Settings';

  @override
  String get settingsLabelSelectLanguage => 'Select App Language';

  @override
  String settingsLanguageChangedConfirmation(String languageTag) {
    return 'Language changed to $languageTag.';
  }

  @override
  String get settingsTitleElderProfileManagement => 'Care Recipient Management';

  @override
  String settingsCurrentElder(String elderName) {
    return 'Active Care Recipient: $elderName';
  }

  @override
  String get settingsNoActiveElderSelected =>
      'No active care recipient selected. Please select or create one.';

  @override
  String get settingsErrorNavToManageElderProfiles =>
      'Could not navigate to manage care recipients. User not logged in.';

  @override
  String get settingsButtonManageElderProfiles => 'Manage Care Recipients';

  @override
  String settingsTitleAdminActions(String elderName) {
    return 'Admin Actions for $elderName';
  }

  @override
  String get settingsButtonClearAllData =>
      'Clear All Data for This Care Recipient';

  @override
  String get settingsTitleMedicationDefinitions => 'Medication Definitions';

  @override
  String get settingsSubtitleAddNewMedDef => 'Add New Medication Definition:';

  @override
  String get settingsLabelMedName => 'Medication Name';

  @override
  String get settingsHintMedName => 'e.g., Lisinopril';

  @override
  String get settingsLabelMedDose => 'Default Dose (Optional)';

  @override
  String get settingsHintMedDose => 'e.g., 10mg, 1 tablet';

  @override
  String get settingsLabelMedDefaultTime => 'Default Time (HH:mm, Optional)';

  @override
  String get settingsHintMedDefaultTime => 'e.g., 08:00';

  @override
  String get settingsButtonAddMedDef => 'Add Medication Definition';

  @override
  String get settingsSelectElderToAddMedDefs =>
      'Select a care recipient to add medication definitions.';

  @override
  String get settingsSelectElderToViewMedDefs =>
      'Select a care recipient to view medication definitions.';

  @override
  String settingsNoMedDefsForElder(String elderName) {
    return 'No medication definitions found for $elderName.';
  }

  @override
  String settingsExistingMedDefsForElder(String elderNameOrFallback) {
    return 'Existing Definitions for $elderNameOrFallback:';
  }

  @override
  String get settingsSelectedElderFallback => 'Selected Care Recipient';

  @override
  String settingsMedDefDosePrefix(String dose) {
    return 'Dose: $dose';
  }

  @override
  String settingsMedDefDefaultTimePrefix(String time) {
    return 'Time: $time';
  }

  @override
  String get settingsTooltipDeleteMedDef => 'Delete this medication definition';

  @override
  String settingsDeleteMedDefDialogTitle(String medName) {
    return 'Delete \'$medName\' Definition?';
  }

  @override
  String get settingsDeleteMedDefDialogContent =>
      'Are you sure you want to delete this medication definition? This will not affect past medication logs but will remove it as an option for future logs.';

  @override
  String settingsMedDefDeletedSuccess(String medName) {
    return 'Medication definition \'$medName\' deleted.';
  }

  @override
  String get errorNotLoggedIn => 'Error: User not logged in.';

  @override
  String get errorElderIdMissing => 'Error: Care recipient ID is missing.';

  @override
  String profileUpdatedSnackbar(String profileName) {
    return 'Profile for $profileName updated.';
  }

  @override
  String profileCreatedSnackbar(String profileName) {
    return 'Profile for $profileName created.';
  }

  @override
  String errorSavingProfile(String errorMessage) {
    return 'Error saving profile: $errorMessage';
  }

  @override
  String get errorSelectElderAndEmail =>
      'Please select a care recipient and enter a valid email address.';

  @override
  String invitationSentSnackbar(String email) {
    return 'Invitation sent to $email.';
  }

  @override
  String errorSendingInvitation(String errorMessage) {
    return 'Error sending invitation: $errorMessage';
  }

  @override
  String get removeCaregiverDialogTitle => 'Remove Caregiver?';

  @override
  String removeCaregiverDialogContent(String caregiverIdentifier) {
    return 'Are you sure you want to remove $caregiverIdentifier as a caregiver for this care recipient?';
  }

  @override
  String caregiverRemovedSnackbar(String caregiverIdentifier) {
    return 'Caregiver $caregiverIdentifier removed.';
  }

  @override
  String errorRemovingCaregiver(String errorMessage) {
    return 'Error removing caregiver: $errorMessage';
  }

  @override
  String get tooltipEditProfile => 'Edit Profile';

  @override
  String get dobLabelPrefix => 'DOB:';

  @override
  String get allergiesLabelPrefix => 'Allergies:';

  @override
  String get dietLabelPrefix => 'Diet:';

  @override
  String get primaryAdminLabel => 'Primary Admin:';

  @override
  String get adminNotAssigned => 'Not assigned';

  @override
  String get loadingAdminInfo => 'Loading admin info...';

  @override
  String caregiversLabel(int count) {
    return 'Caregivers ($count):';
  }

  @override
  String get noCaregiversYet => 'No caregivers yet.';

  @override
  String get errorLoadingCaregiverNames => 'Error loading caregiver names.';

  @override
  String get caregiverAdminSuffix => '(Admin)';

  @override
  String tooltipRemoveCaregiver(String identifier) {
    return 'Remove $identifier';
  }

  @override
  String profileSetActiveSnackbar(String profileName) {
    return '$profileName is now the active profile.';
  }

  @override
  String inviteDialogTitle(String profileName) {
    return 'Invite Caregiver to $profileName\'s Profile';
  }

  @override
  String get caregiversEmailLabel => 'Caregiver\'s Email';

  @override
  String get enterEmailHint => 'Enter email address';

  @override
  String get createElderProfileTitle => 'Create New Care Recipient';

  @override
  String editProfileTitle(String profileNameOrFallback) {
    return 'Edit $profileNameOrFallback';
  }

  @override
  String get profileNameLabel => 'Profile Name';

  @override
  String get validatorPleaseEnterName => 'Please enter a name.';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get allergiesLabel => 'Allergies (comma-separated)';

  @override
  String get dietaryRestrictionsLabel =>
      'Dietary Restrictions (comma-separated)';

  @override
  String get createNewProfileButton => 'Create New Profile';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get noElderProfilesFound => 'No care recipient profiles found.';

  @override
  String get createNewProfileOrWait =>
      'Create a new profile or wait for an invitation.';

  @override
  String get fabNewProfile => 'New Profile';

  @override
  String get activityTypeWalk => 'Walk';

  @override
  String get activityTypeExercise => 'Exercise';

  @override
  String get activityTypePhysicalTherapy => 'Physical Therapy';

  @override
  String get activityTypeOccupationalTherapy => 'Occupational Therapy';

  @override
  String get activityTypeOuting => 'Outing';

  @override
  String get activityTypeSocialVisit => 'Social Visit';

  @override
  String get activityTypeReading => 'Reading';

  @override
  String get activityTypeTV => 'Watching TV/Movies';

  @override
  String get activityTypeGardening => 'Gardening';

  @override
  String get assistanceLevelIndependent => 'Independent';

  @override
  String get assistanceLevelStandbyAssist => 'Standby Assist';

  @override
  String get assistanceLevelWithWalker => 'With Walker';

  @override
  String get assistanceLevelWithCane => 'With Cane';

  @override
  String get assistanceLevelWheelchair => 'Wheelchair';

  @override
  String get assistanceLevelMinAssist => 'Minimal Assist (Min A)';

  @override
  String get assistanceLevelModAssist => 'Moderate Assist (Mod A)';

  @override
  String get assistanceLevelMaxAssist => 'Maximum Assist (Max A)';

  @override
  String get formErrorFailedToUpdateActivity =>
      'Failed to update activity. Please try again.';

  @override
  String get formErrorFailedToSaveActivity =>
      'Failed to save activity. Please try again.';

  @override
  String get activityFormTitleEdit => 'Edit Activity';

  @override
  String get activityFormTitleNew => 'Log New Activity';

  @override
  String get activityFormLabelActivityType => 'Activity Type';

  @override
  String get activityFormHintActivityType => 'Select or type activity';

  @override
  String get activityFormValidationActivityType =>
      'Please select or specify an activity type.';

  @override
  String get activityFormLabelDuration => 'Duration (Optional)';

  @override
  String get activityFormHintDuration => 'e.g., 30 minutes, 1 hour';

  @override
  String get activityFormLabelAssistance => 'Level of Assistance (Optional)';

  @override
  String get activityFormHintAssistance => 'Select level of assistance';

  @override
  String get activityFormHintNotes =>
      'e.g., Enjoyed the sunshine, walked to the park';

  @override
  String get notApplicable => 'N/A';

  @override
  String careScreenWaterLog(String description) {
    return 'Water: $description';
  }

  @override
  String careScreenMealLog(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String get careScreenMealGeneric => 'Meal';

  @override
  String careScreenWaterContext(String contextDetails) {
    return 'Context: $contextDetails';
  }

  @override
  String careScreenNotes(String noteContent) {
    return 'Notes: $noteContent';
  }

  @override
  String careScreenLoggedBy(String userName) {
    return 'Logged by: $userName';
  }

  @override
  String get careScreenTooltipEditFoodWater => 'Edit Food/Water Entry';

  @override
  String get careScreenTooltipDeleteFoodWater => 'Delete Food/Water Entry';

  @override
  String get careScreenErrorMissingIdDelete =>
      'Error: Cannot delete entry, ID is missing.';

  @override
  String get careScreenErrorFailedToLoad =>
      'Failed to load records for this day. Please try again.';

  @override
  String get careScreenButtonAddFoodWater => 'Add Food / Water';

  @override
  String get careScreenSectionTitleMoodBehavior => 'Mood & Behavior';

  @override
  String get careScreenNoMoodBehaviorLogged =>
      'No mood or behavior logged for this day.';

  @override
  String careScreenMood(String mood) {
    return 'Mood: $mood';
  }

  @override
  String careScreenMoodIntensity(String intensityLevel) {
    return 'Intensity: $intensityLevel';
  }

  @override
  String get careScreenTooltipEditMood => 'Edit Mood Entry';

  @override
  String get careScreenTooltipDeleteMood => 'Delete Mood Entry';

  @override
  String get careScreenButtonAddMood => 'Add Mood / Behavior';

  @override
  String get careScreenSectionTitlePain => 'Pain';

  @override
  String get careScreenNoPainLogged => 'No pain logged for this day.';

  @override
  String careScreenPainLog(
      String location, String description, String intensityDetails) {
    return 'Pain: $location - $description$intensityDetails';
  }

  @override
  String careScreenPainIntensity(String intensityValue) {
    return 'Intensity: $intensityValue';
  }

  @override
  String get careScreenTooltipEditPain => 'Edit Pain Entry';

  @override
  String get careScreenTooltipDeletePain => 'Delete Pain Entry';

  @override
  String get careScreenButtonAddPain => 'Add Pain Log';

  @override
  String get careScreenSectionTitleActivity => 'Activities';

  @override
  String get careScreenNoActivitiesLogged =>
      'No activities logged for this day.';

  @override
  String get careScreenUnknownActivity => 'Unknown Activity';

  @override
  String careScreenActivityDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String careScreenActivityAssistance(String assistanceLevel) {
    return 'Assistance: $assistanceLevel';
  }

  @override
  String get careScreenTooltipEditActivity => 'Edit Activity Entry';

  @override
  String get careScreenTooltipDeleteActivity => 'Delete Activity Entry';

  @override
  String get careScreenButtonAddActivity => 'Add Activity';

  @override
  String get careScreenSectionTitleVitals => 'Vital Signs';

  @override
  String get careScreenNoVitalsLogged => 'No vital signs logged for this day.';

  @override
  String careScreenVitalLog(String vitalType, String value, String unit) {
    return '$vitalType: $value $unit';
  }

  @override
  String get careScreenTooltipEditVital => 'Edit Vital Sign Entry';

  @override
  String get careScreenTooltipDeleteVital => 'Delete Vital Sign Entry';

  @override
  String get careScreenButtonAddVital => 'Add Vital Sign';

  @override
  String get careScreenSectionTitleExpenses => 'Expenses';

  @override
  String get careScreenNoExpensesLogged => 'No expenses logged for this day.';

  @override
  String careScreenExpenseLog(String description, String amount) {
    return '$description: \$$amount';
  }

  @override
  String careScreenExpenseCategory(String category, String noteDetails) {
    return 'Category: $category$noteDetails';
  }

  @override
  String get careScreenTooltipEditExpense => 'Edit Expense Entry';

  @override
  String get careScreenTooltipDeleteExpense => 'Delete Expense Entry';

  @override
  String get careScreenButtonAddExpense => 'Add Expense';

  @override
  String get calendarErrorLoadEvents =>
      'Error loading calendar events. Please try again.';

  @override
  String get calendarErrorUserNotLoggedIn =>
      'Error: User not logged in. Cannot load calendar events.';

  @override
  String get calendarErrorEditMissingId =>
      'Error: Cannot edit event, ID is missing.';

  @override
  String get calendarErrorEditPermission =>
      'Error: You do not have permission to edit this event.';

  @override
  String get calendarErrorUpdateOriginalMissing =>
      'Error: Original event data missing for update.';

  @override
  String get calendarErrorUpdatePermission =>
      'Error: You do not have permission to update this event.';

  @override
  String get calendarEventAddedSuccess => 'Event added successfully.';

  @override
  String get calendarEventUpdatedSuccess => 'Event updated successfully.';

  @override
  String calendarErrorSaveEvent(String errorMessage) {
    return 'Error saving event: $errorMessage';
  }

  @override
  String get calendarErrorDeleteMissingId =>
      'Error: Cannot delete event, ID is missing.';

  @override
  String get calendarErrorDeletePermission =>
      'Error: You do not have permission to delete this event.';

  @override
  String get calendarConfirmDeleteTitle => 'Confirm Delete';

  @override
  String calendarConfirmDeleteContent(String eventTitle) {
    return 'Are you sure you want to delete the event \'$eventTitle\'?';
  }

  @override
  String get calendarUntitledEvent => 'Untitled Event';

  @override
  String get eventDeletedSuccess => 'Event deleted successfully.';

  @override
  String get errorCouldNotDeleteEvent => 'Error: Could not delete event.';

  @override
  String get calendarNoElderSelected =>
      'No care recipient selected. Please select a care recipient to view their calendar.';

  @override
  String get calendarAddNewEventButton => 'Add New Event';

  @override
  String calendarEventsOnDate(String formattedDate) {
    return 'Events on $formattedDate:';
  }

  @override
  String get calendarNoEventsScheduled => 'No events scheduled for this day.';

  @override
  String get calendarTooltipEditEvent => 'Edit Event';

  @override
  String get calendarEventTypePrefix => 'Type:';

  @override
  String get calendarEventTimePrefix => 'Time:';

  @override
  String get calendarEventNotesPrefix => 'Notes:';

  @override
  String get expenseUncategorized => 'Uncategorized';

  @override
  String expenseErrorProcessingData(String errorMessage) {
    return 'Error processing expense data: $errorMessage';
  }

  @override
  String expenseErrorFetching(String errorMessage) {
    return 'Error fetching expenses: $errorMessage';
  }

  @override
  String get expenseUnknownUser => 'Unknown User';

  @override
  String get expenseSelectElderPrompt =>
      'Please select a care recipient to view expenses.';

  @override
  String get expenseLoading => 'Loading expenses...';

  @override
  String get expenseScreenTitle => 'Expenses';

  @override
  String expenseForElder(String elderName) {
    return 'Expenses for $elderName';
  }

  @override
  String get expensePrevWeekButton => 'Previous Week';

  @override
  String get expenseNextWeekButton => 'Next Week';

  @override
  String get expenseNoExpensesThisWeek => 'No expenses logged for this week.';

  @override
  String get expenseSummaryByCategoryTitle => 'Summary by Category (This Week)';

  @override
  String get expenseNoExpensesInCategoryThisWeek =>
      'No expenses in this category for the selected week.';

  @override
  String get expenseWeekTotalLabel => 'Week Total:';

  @override
  String get expenseDetailedByUserTitle =>
      'Detailed Expenses (This Week - By User)';

  @override
  String expenseCategoryLabel(String categoryName) {
    return 'Category: $categoryName';
  }

  @override
  String get errorEnterEmailPassword => 'Please enter both email and password.';

  @override
  String get errorLoginFailedDefault =>
      'Login failed. Please check your credentials or network connection.';

  @override
  String get loginScreenTitle => 'Cecelia Care';

  @override
  String get settingsLabelRelationshipToElder =>
      'Relationship to Care Recipient';

  @override
  String get settingsHintRelationshipToElder =>
      'e.g., Son/Daughter, Spouse, Caregiver';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get dontHaveAccountSignUp => 'Don\'t have an account? Sign Up';

  @override
  String get signUpNotImplemented =>
      'Sign up functionality is not yet implemented.';

  @override
  String get homeScreenBaseTitleTimeline => 'Timeline';

  @override
  String homeScreenBaseTitleCareLog(String term) {
    return '$term Care Log';
  }

  @override
  String homeScreenBaseTitleCalendar(String term) {
    return '$term Calendar';
  }

  @override
  String get homeScreenBaseTitleExpenses => 'Expenses';

  @override
  String get homeScreenBaseTitleSettings => 'Settings';

  @override
  String get mustBeLoggedInToAddData => 'You must be logged in to add data.';

  @override
  String get mustBeLoggedInToUpdateData =>
      'You must be logged in to update data.';

  @override
  String selectTermToViewCareLog(String term) {
    return 'Please select a $term from Settings to view the Care Log.';
  }

  @override
  String get selectElderToViewCareLog =>
      'Please select a care recipient from Settings to view the Care Log.';

  @override
  String get goToSettingsButton => 'Go to Settings';

  @override
  String selectTermToViewCalendar(String term) {
    return 'Please select a $term from Settings to view the Calendar.';
  }

  @override
  String get bottomNavTimeline => 'Timeline';

  @override
  String bottomNavCareLog(Object term) {
    return 'Care Log';
  }

  @override
  String bottomNavCalendar(Object term) {
    return 'Calendar';
  }

  @override
  String get bottomNavExpenses => 'Expenses';

  @override
  String get bottomNavSettings => 'Settings';

  @override
  String get timelineUnknownTime => 'Unknown time';

  @override
  String get timelineInvalidTime => 'Invalid time';

  @override
  String get timelineMustBeLoggedInToPost =>
      'You must be logged in to post a message.';

  @override
  String get timelineSelectElderToPost =>
      'Please select an active care recipient to post to their timeline.';

  @override
  String get timelineAnonymousUser => 'Anonymous';

  @override
  String timelineCouldNotPostMessage(String errorMessage) {
    return 'Could not post message: $errorMessage';
  }

  @override
  String get timelinePleaseLogInToView => 'Please log in to view the timeline.';

  @override
  String get timelineSelectElderToView =>
      'Please select a care recipient to view their timeline.';

  @override
  String timelineWriteMessageHint(String elderName) {
    return 'Write a message for $elderName\'s timeline...';
  }

  @override
  String get timelineUnknownUser => 'Unknown User';

  @override
  String get timelinePostButton => 'Post';

  @override
  String get timelineCancelButton => 'Cancel';

  @override
  String get timelinePostMessageToTimelineButton => 'Post Message to Timeline';

  @override
  String get timelineLoading => 'Loading timeline...';

  @override
  String timelineErrorLoading(String errorMessage) {
    return 'Error loading timeline: $errorMessage';
  }

  @override
  String timelineNoEntriesYet(String elderName) {
    return 'No entries yet for $elderName. Be the first to post!';
  }

  @override
  String get timelineItemTitleMessage => 'Message';

  @override
  String get timelineEmptyMessage => '[Empty Message]';

  @override
  String get timelineItemTitleMedication => 'Medication';

  @override
  String get timelineItemTitleSleep => 'Sleep';

  @override
  String get timelineItemTitleMeal => 'Meal';

  @override
  String get timelineItemTitleMood => 'Mood';

  @override
  String get timelineItemTitlePain => 'Pain';

  @override
  String get timelineItemTitleActivity => 'Activity';

  @override
  String get timelineItemTitleVital => 'Vital Sign';

  @override
  String get timelineItemTitleExpense => 'Expense';

  @override
  String get timelineItemTitleEntry => 'Entry';

  @override
  String get timelineNoDetailsProvided => 'No details provided.';

  @override
  String timelineLoggedBy(String userName) {
    return 'Logged by $userName';
  }

  @override
  String timelineErrorRenderingItem(String index, String errorDetails) {
    return 'Error rendering item at index $index: $errorDetails';
  }

  @override
  String get timelineSummaryDetailsUnavailable => 'Details unavailable';

  @override
  String get timelineSummaryNotApplicable => 'N/A';

  @override
  String timelineSummaryMedicationStatusFormat(String status) {
    return '($status)';
  }

  @override
  String timelineSummaryMedicationFormat(
      String medName, String dose, String status) {
    return '$medName $dose $status';
  }

  @override
  String get timelineSummaryMedicationStatusTaken => 'Taken';

  @override
  String get timelineSummaryMedicationStatusNotTaken => 'Not Taken';

  @override
  String get timelineSummaryMealTypeGeneric => 'Meal';

  @override
  String timelineSummarySleepQualityFormat(String quality) {
    return 'Quality: $quality';
  }

  @override
  String timelineSummarySleepFormat(
      String wentToBed, String wokeUp, String quality) {
    return 'Bed: $wentToBed, Up: $wokeUp. $quality';
  }

  @override
  String timelineSummaryMealFormat(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String timelineSummaryMoodNotesFormat(String notes) {
    return '(Notes: $notes)';
  }

  @override
  String timelineSummaryMoodFormat(String mood, String notes) {
    return 'Mood: $mood $notes';
  }

  @override
  String timelineSummaryPainLocationFormat(String location) {
    return 'at $location';
  }

  @override
  String timelineSummaryPainFormat(String level, String location) {
    return 'Pain Level: $level/10 $location';
  }

  @override
  String timelineSummaryActivityDurationFormat(String duration) {
    return 'for $duration';
  }

  @override
  String timelineSummaryActivityFormat(String activityType, String duration) {
    return '$activityType $duration';
  }

  @override
  String timelineSummaryVitalFormatGeneric(
      String vitalType, String value, String unit) {
    return '$vitalType: $value $unit';
  }

  @override
  String timelineSummaryVitalFormatBP(String systolic, String diastolic) {
    return 'BP: $systolic/$diastolic mmHg';
  }

  @override
  String timelineSummaryVitalFormatHR(String heartRate) {
    return 'HR: $heartRate bpm';
  }

  @override
  String timelineSummaryVitalFormatTemp(String temperature) {
    return 'Temp: $temperature°';
  }

  @override
  String timelineSummaryVitalNote(String note) {
    return 'Note: $note';
  }

  @override
  String get timelineSummaryVitalsRecorded => 'Vitals Recorded';

  @override
  String timelineSummaryExpenseDescriptionFormat(String description) {
    return '($description)';
  }

  @override
  String timelineSummaryExpenseFormat(
      String category, String amount, String description) {
    return '$category: \$$amount $description';
  }

  @override
  String get timelineSummaryErrorProcessing =>
      'Error processing details for timeline.';

  @override
  String get timelineItemTitleImage => 'Image Uploaded';

  @override
  String timelineSummaryImageFormat(Object title) {
    return 'Image: $title';
  }

  @override
  String get careScreenErrorMissingIdGeneral =>
      'Error: Item ID is missing. Cannot proceed.';

  @override
  String get careScreenErrorEditPermission =>
      'Error: You do not have permission to edit this item.';

  @override
  String get careScreenErrorUpdateMedStatus =>
      'Error updating medication status. Please try again.';

  @override
  String get careScreenLoadingRecords => 'Loading records for today...';

  @override
  String get careScreenErrorNoRecords =>
      'No records found for this day or an error occurred.';

  @override
  String get careScreenSectionTitleMeds => 'Medications';

  @override
  String get careScreenNoMedsLogged => 'No medications logged for this day.';

  @override
  String get careScreenUnknownMedication => 'Unknown Medication';

  @override
  String get careScreenTooltipEditMed => 'Edit Medication Entry';

  @override
  String get careScreenTooltipDeleteMed => 'Delete Medication Entry';

  @override
  String get careScreenButtonAddMed => 'Add Medication';

  @override
  String get careScreenSectionTitleSleep => 'Sleep';

  @override
  String get careScreenNoSleepLogged => 'No sleep logged for this day.';

  @override
  String careScreenSleepTimeRange(String wentToBed, String wokeUp) {
    return '$wentToBed - $wokeUp';
  }

  @override
  String careScreenSleepQuality(String quality, String duration) {
    return 'Quality: $quality $duration';
  }

  @override
  String careScreenSleepNaps(String naps) {
    return 'Naps: $naps';
  }

  @override
  String get careScreenTooltipEditSleep => 'Edit Sleep Entry';

  @override
  String get careScreenTooltipDeleteSleep => 'Delete Sleep Entry';

  @override
  String get careScreenButtonAddSleep => 'Add Sleep';

  @override
  String get careScreenSectionTitleFoodWater => 'Food & Water Intake';

  @override
  String get careScreenNoFoodWaterLogged =>
      'No food or water intake logged for this day.';

  @override
  String errorEnterValidEmailPasswordMinLength(int minLength) {
    return 'Please enter a valid email and a password with at least $minLength characters.';
  }

  @override
  String get errorSignUpFailedDefault => 'Sign up failed. Please try again.';

  @override
  String get signUpScreenTitle => 'Sign Up';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get termElderDefault => 'Care Recipient';

  @override
  String get formErrorGenericSaveUpdate =>
      'An error occurred while saving or updating. Please try again.';

  @override
  String get formSuccessActivitySaved => 'Activity saved successfully.';

  @override
  String get formSuccessActivityUpdated => 'Activity updated successfully.';

  @override
  String get formSuccessExpenseSaved => 'Expense saved successfully.';

  @override
  String get formSuccessExpenseUpdated => 'Expense updated successfully.';

  @override
  String get formSuccessMealSaved => 'Meal saved successfully.';

  @override
  String get formSuccessMealUpdated => 'Meal updated successfully.';

  @override
  String get formSuccessMedSaved => 'Medication saved successfully.';

  @override
  String get formSuccessMedUpdated => 'Medication updated successfully.';

  @override
  String get formSuccessMoodSaved => 'Mood saved successfully.';

  @override
  String get formSuccessMoodUpdated => 'Mood updated successfully.';

  @override
  String get formSuccessPainSaved => 'Pain log saved successfully.';

  @override
  String get formSuccessPainUpdated => 'Pain log updated successfully.';

  @override
  String get formSuccessSleepSaved => 'Sleep log saved successfully.';

  @override
  String get formSuccessSleepUpdated => 'Sleep log updated successfully.';

  @override
  String get formSuccessVitalSaved => 'Vital sign saved successfully.';

  @override
  String get formSuccessVitalUpdated => 'Vital sign updated successfully.';

  @override
  String get formErrorNoItemToDelete => 'No item selected for deletion.';

  @override
  String get formConfirmDeleteTitle => 'Confirm Delete';

  @override
  String get formConfirmDeleteVitalMessage =>
      'Are you sure you want to delete this vital entry?';

  @override
  String get formSuccessVitalDeleted => 'Vital entry deleted.';

  @override
  String get formErrorFailedToDeleteVital => 'Failed to delete vital entry.';

  @override
  String get formTooltipDeleteVital => 'Delete vital entry';

  @override
  String get formConfirmDeleteMealMessage =>
      'Are you sure you want to delete this meal entry?';

  @override
  String get formSuccessMealDeleted => 'Meal entry deleted.';

  @override
  String get formErrorFailedToDeleteMeal => 'Failed to delete meal entry.';

  @override
  String get formTooltipDeleteMeal => 'Delete meal entry';

  @override
  String get goToTodayButtonLabel => 'Go to Today';

  @override
  String get formConfirmDeleteMedMessage =>
      'Are you sure you want to delete this medication entry?';

  @override
  String get formSuccessMedDeleted => 'Medication entry deleted.';

  @override
  String get formErrorFailedToDeleteMed => 'Failed to delete medication entry.';

  @override
  String get formTooltipDeleteMed => 'Delete medication entry';

  @override
  String get formConfirmDeleteMoodMessage =>
      'Are you sure you want to delete this mood entry?';

  @override
  String get formSuccessMoodDeleted => 'Mood entry deleted.';

  @override
  String get formErrorFailedToDeleteMood => 'Failed to delete mood entry.';

  @override
  String get formTooltipDeleteMood => 'Delete mood entry';

  @override
  String get formConfirmDeletePainMessage =>
      'Are you sure you want to delete this pain log?';

  @override
  String get formSuccessPainDeleted => 'Pain log deleted.';

  @override
  String get formErrorFailedToDeletePain => 'Failed to delete pain log.';

  @override
  String get formTooltipDeletePain => 'Delete pain log';

  @override
  String get formConfirmDeleteActivityMessage =>
      'Are you sure you want to delete this activity entry?';

  @override
  String get formSuccessActivityDeleted => 'Activity entry deleted.';

  @override
  String get formErrorFailedToDeleteActivity =>
      'Failed to delete activity entry.';

  @override
  String get formTooltipDeleteActivity => 'Delete activity entry';

  @override
  String get formConfirmDeleteSleepMessage =>
      'Are you sure you want to delete this sleep log?';

  @override
  String get formSuccessSleepDeleted => 'Sleep log deleted.';

  @override
  String get formErrorFailedToDeleteSleep => 'Failed to delete sleep log.';

  @override
  String get formTooltipDeleteSleep => 'Delete sleep log';

  @override
  String get formConfirmDeleteExpenseMessage =>
      'Are you sure you want to delete this expense entry?';

  @override
  String get formSuccessExpenseDeleted => 'Expense entry deleted.';

  @override
  String get formErrorFailedToDeleteExpense =>
      'Failed to delete expense entry.';

  @override
  String get formTooltipDeleteExpense => 'Delete expense entry';

  @override
  String get userSelectorSendToLabel => 'Send to:';

  @override
  String get userSelectorAudienceAll => 'All Users';

  @override
  String get userSelectorAudienceSpecific => 'Specific Users';

  @override
  String get userSelectorNoUsersAvailable =>
      'No other users available for selection.';

  @override
  String get timelinePostingToAll => 'Posting to: All Users';

  @override
  String timelinePostingToCount(String count) {
    return 'Posting to: $count specific users';
  }

  @override
  String get timelinePrivateMessageIndicator => 'Private Message';

  @override
  String get timelineEditMessage => 'Edit Message';

  @override
  String get timelineDeleteMessage => 'Delete Message';

  @override
  String get timelineConfirmDeleteMessageTitle => 'Delete Message?';

  @override
  String get timelineConfirmDeleteMessageContent =>
      'Are you sure you want to delete this message?';

  @override
  String get timelineMessageDeletedSuccess => 'Message deleted.';

  @override
  String timelineErrorDeletingMessage(String errorMessage) {
    return 'Error deleting message: $errorMessage';
  }

  @override
  String get timelineMessageUpdatedSuccess => 'Message updated.';

  @override
  String timelineErrorUpdatingMessage(String errorMessage) {
    return 'Error updating message: $errorMessage';
  }

  @override
  String get timelineUpdateButton => 'Update';

  @override
  String get timelineHideMessage => 'Hide Message';

  @override
  String get timelineMessageHiddenSuccess => 'Message hidden from your view.';

  @override
  String get timelineShowHiddenMessagesButton => 'Show Hidden';

  @override
  String get timelineHideHiddenMessagesButton => 'Show All';

  @override
  String get timelineUnhideMessage => 'Unhide Message';

  @override
  String get timelineMessageUnhiddenSuccess => 'Message unhidden.';

  @override
  String get timelineNoHiddenMessages =>
      'You have no hidden messages for this timeline.';

  @override
  String get selfCareScreenTitle => 'Self Care';

  @override
  String get settingsTitleNotificationPreferences => 'Notification Settings';

  @override
  String get settingsItemNotificationPreferences => 'Notification Preferences';

  @override
  String get landingPageAlreadyLoggedIn => 'You’re already logged in!';

  @override
  String get manageMedications => 'Manage Medications';

  @override
  String get medicationsScreenTitleGeneric => 'Medications';

  @override
  String medicationsScreenTitleForElder(String name) {
    return '$name’s Medications';
  }

  @override
  String get medicationsSearchHint => 'Search drug name';

  @override
  String get medicationsDoseHint => 'e.g. 10 mg';

  @override
  String get medicationsScheduleHint => 'e.g. AM / PM';

  @override
  String get medicationsListEmpty => 'No medications added yet';

  @override
  String get medicationsDoseNotSet => 'Dose not set';

  @override
  String get medicationsScheduleNotSet => 'Schedule not set';

  @override
  String get medicationsTooltipDelete => 'Delete medication';

  @override
  String medicationsConfirmDeleteTitle(String medName) {
    return 'Delete \'$medName\'?';
  }

  @override
  String get medicationsConfirmDeleteContent => 'This cannot be undone.';

  @override
  String medicationsDeletedSuccess(String medName) {
    return 'Medication \'$medName\' removed.';
  }

  @override
  String get rxNavGenericSearchError => 'Could not fetch drug list. Try again.';

  @override
  String get medicationsValidationNameRequired => 'Name required';

  @override
  String get medicationsValidationDoseRequired => 'Dose required';

  @override
  String get medicationsInteractionsFoundTitle => 'Possible interactions found';

  @override
  String get medicationsNoInteractionsFound => 'No interactions found';

  @override
  String get medicationsInteractionsSaveAnyway => 'Save anyway';

  @override
  String get medicationsAddDialogTitle => 'Add medication';

  @override
  String medicationsAddedSuccess(String medName) {
    return 'Medication \'$medName\' added.';
  }

  @override
  String get routeErrorGenericMessage =>
      'Something went wrong. Please try again.';

  @override
  String get goHomeButton => 'Go Home';

  @override
  String get settingsTitleHelpfulResources => 'Helpful Resources';

  @override
  String get settingsItemHelpfulResources => 'View Helpful Resources';

  @override
  String get timelineFilterOnlyMyLogs => 'Only My Logs:';

  @override
  String get timelineFilterFromDate => 'From';

  @override
  String get timelineFilterToDate => 'To';

  @override
  String get medicationsInteractionsSectionTitle =>
      'Potential Medication Interactions';

  @override
  String get inclusiveLanguageGuideTitle => 'Inclusive Language Guidance';

  @override
  String get inclusiveLanguageTip1Title => 'Respect Preferred Names';

  @override
  String get inclusiveLanguageTip1Content =>
      'Always use a person\'s preferred name. If you\'re unsure, ask respectfully: \'What name do you prefer to be called?\'';

  @override
  String get inclusiveLanguageTip2Title => 'Use Correct Pronouns';

  @override
  String get inclusiveLanguageTip2Content =>
      'If you know someone\'s preferred pronouns, use them consistently. If you don\'t know, use gender-neutral language (they/them) or ask: \'What are your preferred pronouns?\'';

  @override
  String get settingsLabelSexualOrientation => 'Sexual Orientation';

  @override
  String get settingsHintSexualOrientation =>
      'Enter your sexual orientation (optional)';

  @override
  String get settingsLabelGenderIdentity => 'Gender Identity';

  @override
  String get settingsHintGenderIdentity =>
      'Enter your gender identity (optional)';

  @override
  String get settingsLabelPreferredPronouns => 'Preferred Pronouns';

  @override
  String get settingsHintPreferredPronouns =>
      'e.g., she/her, he/him, they/them (optional)';

  @override
  String couldNotLaunchUrl(String urlString) {
    return 'Could not launch $urlString';
  }

  @override
  String get helpfulResourcesTitle => 'Helpful Resources';

  @override
  String homeScreenWelcomeGreeting(String userName, String elderName) {
    return 'Welcome, $userName! Thank you for trusting Cecelia Care to help you support $elderName\'s well-being.';
  }

  @override
  String get settingsLabelUserGoals => 'My Caregiving Goals/Challenges';

  @override
  String get settingsHintUserGoals =>
      'What support are you looking for? (e.g., managing medications, tracking mood changes, coordinating with other caregivers)';

  @override
  String get badgeLabelFirstMoodLog => 'Mood Monitor';

  @override
  String get badgeDescriptionFirstMoodLog =>
      'Congratulations on logging your first mood entry!';

  @override
  String get badgeLabelFirstMedLog => 'Medication Tracker';

  @override
  String get badgeDescriptionFirstMedLog =>
      'You\'ve successfully logged your first medication entry.';

  @override
  String get badgeLabelFirstActivityLog => 'Activity Starter';

  @override
  String get badgeDescriptionFirstActivityLog =>
      'Great job logging your first activity!';

  @override
  String get badgeLabelMedMaestro10 => 'Medication Maestro (10)';

  @override
  String get badgeDescriptionMedMaestro10 =>
      'Logged 10 medication entries. You\'re a pro!';

  @override
  String get badgeLabelActivityChampion7 => 'Activity Champion (7 Days)';

  @override
  String get badgeDescriptionActivityChampion7 =>
      'Logged an activity every day for a week!';

  @override
  String get badgesScreenTitle => 'My Achievements';

  @override
  String get badgesScreenNoBadges =>
      'No badges available yet. Keep using the app to earn them!';

  @override
  String get selfCareScreenAchievementsTitle => 'My Achievements';

  @override
  String get selfCareScreenNoBadgesUnlocked =>
      'No badges unlocked yet. Keep up the great work!';

  @override
  String get imageUploadScreenTitle => 'Image Scanner & Uploader';

  @override
  String get imageUploadErrorNoElderSelected =>
      'Please select an active care recipient to upload images.';

  @override
  String imageUploadErrorPicking(String errorDetails) {
    return 'Error picking image: $errorDetails';
  }

  @override
  String get imageUploadErrorNoFileSelected =>
      'No file selected. Please pick an image first.';

  @override
  String get imageUploadErrorNotLoggedIn =>
      'You must be logged in to upload images.';

  @override
  String get imageUploadDefaultTitle => 'Uploaded Image';

  @override
  String get imageUploadSuccess => 'Image uploaded successfully!';

  @override
  String imageUploadErrorFailed(String errorDetails) {
    return 'Image upload failed: $errorDetails';
  }

  @override
  String imageUploadForElder(String elderName) {
    return 'Upload Image for $elderName';
  }

  @override
  String get imageUploadButtonGallery => 'Choose from Gallery';

  @override
  String get imageUploadButtonCamera => 'Take Photo';

  @override
  String get imageUploadPreviewTitle => 'Image Preview:';

  @override
  String get imageUploadErrorLoadingPreview => 'Error loading preview';

  @override
  String get imageUploadLabelTitle => 'Image Title (Optional)';

  @override
  String get imageUploadHintTitle => 'Enter a title for the image';

  @override
  String get imageUploadStatusUploading => 'Uploading...';

  @override
  String get imageUploadButtonUpload => 'Upload Image';

  @override
  String get uploadedImagesSectionTitle => 'Uploaded Images';

  @override
  String get noImagesUploadedYet =>
      'No images uploaded yet for this care recipient.';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get emergencyContactSectionTitle => 'Emergency Contact';

  @override
  String get emergencyContactNameLabel => 'Contact Name';

  @override
  String get emergencyContactPhoneLabel => 'Contact Phone';

  @override
  String get emergencyContactRelationshipLabel => 'Relationship';

  @override
  String get calendarRemindersTitle => 'Health Reminders';

  @override
  String get calendarReminderNotificationTitle => 'Health Reminder';

  @override
  String calendarReminderSet(String title, String datetime) {
    return 'Reminder for \"$title\" set for $datetime.';
  }

  @override
  String get setReminder => 'Set Reminder';

  @override
  String get vaccineCovid19 => 'COVID-19 Vaccine';

  @override
  String get vaccineCovid19Freq =>
      'At least 2 doses of current vaccine for adults 65+';

  @override
  String get vaccineInfluenza => 'Influenza (Flu) Vaccine';

  @override
  String get vaccineInfluenzaFreq => '1 dose annually';

  @override
  String get vaccineRSV => 'RSV Vaccine';

  @override
  String get vaccineRSVFreq => '1 dose, recommended for adults ≥60 years';

  @override
  String get vaccineTdap => 'Tdap/Td Vaccine';

  @override
  String get vaccineTdapFreq => 'Booster every 10 years';

  @override
  String get vaccineShingles => 'Shingles (Zoster) Vaccine';

  @override
  String get vaccineShinglesFreq => '2 doses for healthy adults ≥50 years';

  @override
  String get vaccinePneumococcal => 'Pneumococcal Vaccine';

  @override
  String get vaccinePneumococcalFreq => 'All adults ≥65 years';

  @override
  String get vaccineHepatitisB => 'Hepatitis B Vaccine';

  @override
  String get vaccineHepatitisBFreq => 'For adults 60+ with risk factors';

  @override
  String get checkupPhysicalExam => 'Annual Physical Exam';

  @override
  String get checkupPhysicalExamFreq => 'Annually';

  @override
  String get checkupMammogram => 'Mammogram';

  @override
  String get checkupMammogramFreq => 'Every 1-2 years for women';

  @override
  String get checkupPapTest => 'Cervical Cancer (Pap test)';

  @override
  String get checkupPapTestFreq =>
      'May not be needed if over 65 with normal test history';

  @override
  String get checkupColonCancer => 'Colon Cancer Screening';

  @override
  String get checkupColonCancerFreq => 'Colonoscopy every 10 years';

  @override
  String get checkupLungCancer => 'Lung Cancer Screening';

  @override
  String get checkupLungCancerFreq => 'Yearly for long-time smokers';

  @override
  String get checkupProstateCancer => 'Prostate Cancer (DRE/PSA)';

  @override
  String get checkupProstateCancerFreq => 'Discuss with provider (men 55-70)';

  @override
  String get checkupSkinCancer => 'Skin Cancer Checks';

  @override
  String get checkupSkinCancerFreq => 'Regular checks as needed';

  @override
  String get checkupBloodPressure => 'Blood Pressure';

  @override
  String get checkupBloodPressureFreq => 'At least annually';

  @override
  String get checkupCholesterol => 'Cholesterol Screening';

  @override
  String get checkupCholesterolFreq => 'Every 4-6 years for normal risk';

  @override
  String get checkupBloodGlucose => 'Blood Glucose (A1C)';

  @override
  String get checkupBloodGlucoseFreq => 'Every 3 years if results are normal';

  @override
  String get checkupVision => 'Vision Screening';

  @override
  String get checkupVisionFreq => 'Annually for 50+';

  @override
  String get checkupHearing => 'Hearing Screening';

  @override
  String get checkupHearingFreq => 'Every 1-3 years for 65+';

  @override
  String get checkupBoneDensity => 'Bone Density (DXA)';

  @override
  String get checkupBoneDensityFreq =>
      'Every 1-2 years if on osteoporosis medicine';

  @override
  String get checkupCognitive => 'Cognitive Assessment';

  @override
  String get checkupCognitiveFreq => 'Annually for 65+';

  @override
  String get checkupMentalHealth => 'Mental Health Screening';

  @override
  String get checkupMentalHealthFreq => 'As needed, during annual physical';

  @override
  String get timelineFilterResetDates => 'Reset Dates';

  @override
  String get dialogTitleAddNewLog => 'Add a New Log';

  @override
  String get formTooltipVoiceInput => 'Tap for voice input';

  @override
  String get journalEntryCannotBeEmpty => 'Journal entry cannot be empty.';

  @override
  String get journalEntryUpdatedSuccessfully =>
      'Journal entry updated successfully!';

  @override
  String get journalEntryAddedSuccessfully =>
      'Journal entry added successfully!';

  @override
  String get journalEntryDeletedSuccessfully =>
      'Journal entry deleted successfully.';

  @override
  String get failedToDeleteJournalEntry => 'Failed to delete journal entry.';

  @override
  String get caregiverJournal => 'Caregiver Journal';

  @override
  String get pleaseLogInToAccessJournal =>
      'Please log in to access your journal.';

  @override
  String get editJournalEntry => 'Edit Journal Entry';

  @override
  String get addJournalEntry => 'Add New Journal Entry';

  @override
  String get writeYourEntryHere => 'Write your entry here...';

  @override
  String get error => 'Error';

  @override
  String get noJournalEntriesYet => 'No journal entries yet.';

  @override
  String get date => 'Date';

  @override
  String get noContent => 'No Content';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get updateEntry => 'Update Entry';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get cancelEdit => 'Cancel Edit';

  @override
  String get dailyMood => 'Daily Mood';

  @override
  String get optionalNote => 'Optional note';

  @override
  String get breakReminders => 'Break Reminders';

  @override
  String get hydrate => 'Hydrate';

  @override
  String get stretch => 'Stretch';

  @override
  String get walk => 'Walk';

  @override
  String get caregiverJournalTitle => 'Caregiver Journal';

  @override
  String get caregiverJournalButton => 'Open Caregiver Journal';

  @override
  String get off => 'Off';

  @override
  String get selfCareReminderTitle => 'Self-Care Reminder';

  @override
  String get timeTo => 'Time to';

  @override
  String get timelineAddNewLogTooltip => 'Add a new log';

  @override
  String get timelineNewMessageButton => 'New Message';

  @override
  String get settingsTitleCareRecipientProfileManagement =>
      'Care Recipient Management';

  @override
  String settingsCurrentCareRecipient(String profileName) {
    return 'Active Care Recipient: $profileName';
  }

  @override
  String get settingsNoActiveCareRecipientSelected =>
      'No active care recipient is selected.';

  @override
  String get settingsButtonManageCareRecipientProfiles =>
      'Manage Care Recipient Profiles';

  @override
  String get settingsErrorNavToManageCareRecipientProfiles =>
      'Could not navigate to manage profiles.';

  @override
  String get manageCareRecipientProfilesTitle =>
      'Manage Care Recipient Profiles';

  @override
  String get createCareRecipientProfileTitle => 'Create Care Recipient Profile';

  @override
  String get noCareRecipientProfilesFound =>
      'No care recipient profiles found.';

  @override
  String get errorCareRecipientIdMissing =>
      'Care Recipient ID is missing, cannot update.';

  @override
  String get errorSelectCareRecipientAndEmail =>
      'Please select a care recipient and enter an email.';

  @override
  String get timelineFiltersTitle => 'Timeline Filters';

  @override
  String get careScreenTitle => 'Care';

  @override
  String get budgetTrackerTitle => 'Budget Tracker';

  @override
  String get settingsProfileNoChanges => 'No changes to save.';

  @override
  String get formErrorNotAuthenticated =>
      'Error: User not authenticated. Please sign in again.';

  @override
  String get activityFormLabelActivityTypeRequired => 'Activity Type*';

  @override
  String get medFormLabelNameRequired => 'Medication Name*';

  @override
  String get vitalFormLabelTypeRequired => 'Vital Type*';

  @override
  String get medicationsTooltipAskCecelia => 'Ask Cecelia about medications';

  @override
  String get formErrorUserOrElderNotFound =>
      'Error: Could not find user or care recipient profile.';

  @override
  String get medicationDefinitionSaveFailed =>
      'Failed to save medication to the managed list.';

  @override
  String get errorTitle => 'Error';

  @override
  String get settingsTitleCareRecipientManagement =>
      'Care Recipient Management';

  @override
  String settingsActiveCareRecipient(String name) {
    return 'Active: $name';
  }

  @override
  String get settingsNoActiveCareRecipient =>
      'No active care recipient is selected.';

  @override
  String get settingsItemManageProfiles => 'Manage Care Recipient Profiles';

  @override
  String get settingsErrorCouldNotNavigateToProfiles =>
      'Could not navigate to manage profiles.';

  @override
  String get settingsItemClearData => 'Clear All Data for This Care Recipient';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get editReminder => 'Edit Reminder';

  @override
  String get cancelReminder => 'Cancel Reminder';

  @override
  String get ceceliaBotName => 'Cecelia';

  @override
  String get chatWithCeceliaTitle => 'Chat with Cecelia';

  @override
  String get ceceliaInitialGreeting =>
      'Hello! I am a specialized bot for medication interactions. How can I assist you today?';

  @override
  String get geminiUnknownError => 'An unknown error occurred.';

  @override
  String get notificationPreferencesTitle => 'Notification Preferences';

  @override
  String get medsNotificationsLabel => 'Medication Reminders';

  @override
  String get calendarNotificationsLabel => 'Calendar Events';

  @override
  String get selfCareNotificationsLabel => 'Self-Care Reminders';

  @override
  String get chatNotificationsLabel => 'Chat Message Notifications';

  @override
  String get healthRemindersNotificationsLabel => 'Health Reminders';

  @override
  String get sundowningAlertLabel => 'Sundowning Alert';

  @override
  String get sundowningAlertSubtitle => 'Daily 3 PM reminder with calming tips';

  @override
  String get generalNotificationsLabel => 'General App Notifications';

  @override
  String get multiViewAll => 'All';

  @override
  String get multiViewAllCareRecipients => 'All Care Recipients';

  @override
  String get multiViewSelectToAccessTools =>
      'Select a care recipient to access care tools';

  @override
  String genericError(String details) {
    return 'An error occurred: $details';
  }

  @override
  String characterCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String dateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String medicationsInteractionDetails(
      Object severity, Object otherDrug, Object description) {
    return '$severity interaction with $otherDrug: $description';
  }

  @override
  String calendarEventStarting(String eventTitle) {
    return 'Event starting: $eventTitle';
  }

  @override
  String calendarErrorSavingReminder(String details) {
    return 'Error saving reminder: $details';
  }

  @override
  String calendarConfirmCancelReminder(String reminderTitle) {
    return 'Are you sure you want to cancel the reminder for \"$reminderTitle\"?';
  }

  @override
  String calendarReminderCancelled(String reminderTitle) {
    return 'Reminder for \"$reminderTitle\" cancelled.';
  }

  @override
  String get calendarReminderSetFor => 'Reminder set for:';

  @override
  String selfCareReminderBody(String activity) {
    return 'Time to $activity.';
  }

  @override
  String geminiFirebaseError(String details) {
    return 'An error occurred with the AI service: $details';
  }

  @override
  String geminiCommunicationError(String details) {
    return 'I\'m sorry, I encountered a communication error: $details';
  }

  @override
  String geminiUnexpectedError(String details) {
    return 'An unexpected system error occurred: $details';
  }

  @override
  String vitalFormLabelValueRequired(String unit) {
    return 'Value ($unit)*';
  }

  @override
  String get notificationChannelDefaultName => 'General Notifications';

  @override
  String get notificationChannelDefaultDescription =>
      'Channel for general app notifications.';

  @override
  String get notificationChannelCalendarName => 'Calendar Events';

  @override
  String get notificationChannelCalendarDescription =>
      'Notifications for upcoming calendar events.';

  @override
  String get notificationChannelMedRemindersName => 'Medication Reminders';

  @override
  String get notificationChannelMedRemindersDescription =>
      'Daily reminders to take scheduled medications.';

  @override
  String get notificationChannelSelfCareName => 'Self-Care Breaks';

  @override
  String get notificationChannelSelfCareDescription =>
      'Reminders to hydrate, stretch, and take a walk.';

  @override
  String get notificationChannelChatMessagesName => 'Chat Messages';

  @override
  String get notificationChannelChatMessagesDescription =>
      'Notifications for new direct messages.';

  @override
  String get notificationChannelHealthRemindersName => 'Health Reminders';

  @override
  String get notificationChannelHealthRemindersDescription =>
      'Notifications for important health checkups and vaccines.';

  @override
  String medicationReminderTitle(String medName) {
    return 'Medication Reminder: $medName';
  }

  @override
  String medicationReminderBody(String dosage, String elderName) {
    return 'Time to take $dosage for $elderName.';
  }

  @override
  String get calendarAllDay => 'All Day';

  @override
  String get formErrorMicPermissionDenied =>
      'Microphone permission was denied.';

  @override
  String get formErrorAiProcessing => 'An error occurred during AI processing.';

  @override
  String timelineSummaryMealCaloriesFormat(String calories) {
    return '$calories kcal';
  }

  @override
  String get eventFormValidationTitle => 'Please enter an event title.';

  @override
  String get eventFormValidationStartDateTime =>
      'Please select a start date and time.';

  @override
  String get eventFormTitleCreate => 'Create Event';

  @override
  String get eventFormTitleEdit => 'Edit Event';

  @override
  String get eventFormLabelTitle => 'Title';

  @override
  String get eventFormLabelType => 'Type';

  @override
  String get eventFormLabelAllDay => 'All Day';

  @override
  String get eventFormLabelStartDate => 'Start Date';

  @override
  String get eventFormLabelEndDate => 'End Date';

  @override
  String get eventFormLabelDate => 'Date';

  @override
  String get eventFormLabelStartTime => 'Start Time';

  @override
  String get eventFormLabelEndTime => 'End Time';

  @override
  String get eventFormHintSelectDate => 'Select date';

  @override
  String validationErrorRequired(String fieldName) {
    return '$fieldName is required';
  }

  @override
  String validationErrorInvalidNumber(String fieldName) {
    return 'Please enter a valid number for $fieldName';
  }

  @override
  String validationErrorNumericRange(String fieldName, String min, String max) {
    return '$fieldName must be between $min and $max';
  }

  @override
  String validationErrorPositiveNumber(String fieldName) {
    return '$fieldName must be a positive number';
  }

  @override
  String validationErrorInvalidFormat(String fieldName) {
    return 'Invalid format for $fieldName';
  }
}
