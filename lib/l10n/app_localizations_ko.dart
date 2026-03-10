// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '세실리아 케어';

  @override
  String get loginButton => '로그인';

  @override
  String get settingsTitle => '설정';

  @override
  String get languageSetting => '언어';

  @override
  String get manageElderProfilesTitle => '노인 프로필 관리';

  @override
  String get createProfileButton => '프로필 만들기';

  @override
  String get pleaseLogInToManageProfiles => '노인 프로필을 관리하려면 로그인하십시오.';

  @override
  String calendarScreenTitle(String elderName) {
    return '$elderName님의 달력';
  }

  @override
  String get formOptionOther => '기타';

  @override
  String get formLabelNotesOptional => '메모 (선택 사항)';

  @override
  String get cancelButton => '취소';

  @override
  String get updateButton => '업데이트';

  @override
  String get saveButton => '저장';

  @override
  String get okButton => '확인';

  @override
  String get deleteButton => '삭제';

  @override
  String get removeButton => '제거';

  @override
  String get inviteButton => '초대';

  @override
  String get activeButton => '활성';

  @override
  String get setActiveButton => '활성으로 설정';

  @override
  String get sendInviteButton => '초대 보내기';

  @override
  String get formUnknownUser => '알 수 없는 사용자';

  @override
  String get timePickerHelpText => '시간 선택';

  @override
  String get expenseFormTitleEdit => '비용 편집';

  @override
  String get expenseFormTitleNew => '새 비용';

  @override
  String get expenseFormLabelDescription => '설명';

  @override
  String get expenseFormHintDescription => '예: 처방약 재구매';

  @override
  String get expenseFormValidationDescription => '설명을 입력해주세요.';

  @override
  String get expenseFormLabelAmount => '금액';

  @override
  String get expenseFormHintAmount => '예: 25.50';

  @override
  String get expenseFormValidationAmountEmpty => '금액을 입력해주세요.';

  @override
  String get expenseFormValidationAmountInvalid => '유효한 양수 금액을 입력해주세요.';

  @override
  String get expenseFormLabelCategory => '카테고리';

  @override
  String get expenseCategoryMedical => '의료';

  @override
  String get expenseCategoryGroceries => '식료품';

  @override
  String get expenseCategorySupplies => '소모품';

  @override
  String get expenseCategoryHousehold => '가정용품';

  @override
  String get expenseCategoryPersonalCare => '개인 위생용품';

  @override
  String get expenseFormValidationCategory => '카테고리를 선택해주세요.';

  @override
  String get expenseFormHintNotes => '관련 메모를 여기에 추가하세요...';

  @override
  String get formErrorFailedToUpdateExpense => '비용 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSaveExpense => '비용 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get mealFormTitleEdit => '식사 / 수분 섭취 편집';

  @override
  String get mealFormTitleNew => '식사 / 수분 섭취 기록';

  @override
  String get mealFormLabelIntakeType => '섭취 유형';

  @override
  String get mealFormIntakeCategoryFood => '음식';

  @override
  String get mealFormIntakeCategoryWater => '물';

  @override
  String get mealFormLabelMealType => '식사 종류';

  @override
  String get mealFormMealTypeBreakfast => '아침';

  @override
  String get mealFormMealTypeLunch => '점심';

  @override
  String get mealFormMealTypeSnack => '간식';

  @override
  String get mealFormMealTypeDinner => '저녁';

  @override
  String get mealFormLabelDescription => '설명';

  @override
  String get mealFormHintFoodDescription => '예: 닭고기 수프, 토스트';

  @override
  String get mealFormValidationFoodDescription => '음식 설명을 입력해주세요.';

  @override
  String get mealFormLabelWaterContext => '수분 섭취 상황 (선택 사항)';

  @override
  String get mealFormHintWaterContext => '예: 약 복용 시, 목마를 때';

  @override
  String get mealFormLabelWaterAmount => '양';

  @override
  String get mealFormHintWaterAmount => '예: 1잔, 200ml';

  @override
  String get mealFormValidationWaterAmount => '물의 양을 지정해주세요.';

  @override
  String get mealFormHintFoodNotes => '예: 잘 먹음, 당근 싫어함';

  @override
  String get mealFormHintWaterNotes => '예: 천천히 마심';

  @override
  String get formErrorFailedToUpdateMeal => '식사 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSaveMeal => '식사 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get eventFormHintSelectTime => 'Select Time';

  @override
  String get mealFormLabelCalories => 'Calories';

  @override
  String get mealFormHintCalories => 'e.g., 500';

  @override
  String get sleepFormHintQuality => 'Rate quality (1-10)';

  @override
  String get sleepFormValidationQualityRange =>
      'Please enter a number between 1 and 10';

  @override
  String get medFormTitleEdit => '약물 편집';

  @override
  String get medFormTitleNew => '약물 기록';

  @override
  String get medFormTimePickerHelpText => '약물 복용 시간 선택';

  @override
  String get medFormLabelName => '약물 이름';

  @override
  String get medFormHintNameCustom => '또는 사용자 지정 약물 이름 입력';

  @override
  String get medFormHintName => '약물 이름 입력';

  @override
  String get medFormValidationName => '약물 이름을 입력해주세요.';

  @override
  String get medFormLabelDose => '복용량 (선택 사항)';

  @override
  String get medFormHintDose => '예: 1정, 10mg';

  @override
  String get medFormLabelTime => '시간 (선택 사항)';

  @override
  String get medFormHintTime => '시간 선택';

  @override
  String get medFormLabelMarkAsTaken => '복용함으로 표시';

  @override
  String get formErrorFailedToUpdateMed => '약물 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSaveMed => '약물 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get moodFormTitleEdit => '기분 편집';

  @override
  String get moodFormTitleNew => '기분 기록';

  @override
  String get moodHappy => '😊 행복함';

  @override
  String get moodContent => '🙂 만족함';

  @override
  String get moodSad => '😟 슬픔';

  @override
  String get moodAnxious => '😬 불안함';

  @override
  String get moodCalm => '😌 차분함';

  @override
  String get moodIrritable => '😠 짜증남';

  @override
  String get moodAgitated => '😫 초조함';

  @override
  String get moodPlayful => '🥳 장난스러움';

  @override
  String get moodTired => '😴 피곤함';

  @override
  String get moodOptionOther => '📝 기타';

  @override
  String get moodFormLabelSelectMood => '기분 선택';

  @override
  String get moodFormValidationSelectOrSpecifyMood => '기분을 선택하거나 지정해주세요.';

  @override
  String get moodFormValidationSpecifyOtherMood => '기분을 지정해주세요.';

  @override
  String get moodFormHintSpecifyOtherMood => '기분을 설명해주세요...';

  @override
  String get moodFormLabelIntensity => '강도 (1-5, 선택 사항)';

  @override
  String get moodFormHintIntensity => '1 (약함) - 5 (강함)';

  @override
  String get moodFormValidationIntensityRange => '강도는 1에서 5 사이여야 합니다.';

  @override
  String get moodFormHintNotes => '예: 산책 후 기분이 좋음';

  @override
  String get moodFormButtonUpdate => '기분 업데이트';

  @override
  String get moodFormButtonSave => '기분 저장';

  @override
  String get formErrorFailedToUpdateMood => '기분 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSaveMood => '기분 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get painFormTitleEdit => '통증 기록 편집';

  @override
  String get painFormTitleNew => '통증 기록';

  @override
  String get painTypeAching => '쑤시는 통증';

  @override
  String get painTypeBurning => '타는 듯한 통증';

  @override
  String get painTypeDull => '둔한 통증';

  @override
  String get painTypeSharp => '날카로운 통증';

  @override
  String get painTypeShooting => '쏘는 듯한 통증';

  @override
  String get painTypeStabbing => '찌르는 듯한 통증';

  @override
  String get painTypeThrobbing => '욱신거리는 통증';

  @override
  String get painTypeTender => '압통';

  @override
  String get painFormLabelLocation => '위치';

  @override
  String get painFormHintLocation => '예: 왼쪽 무릎, 허리 아래';

  @override
  String get painFormValidationLocation => '통증 위치를 지정해주세요.';

  @override
  String get painFormLabelIntensity => '강도 (0-10)';

  @override
  String get painFormHintIntensity => '0 (통증 없음) - 10 (최악의 통증)';

  @override
  String get painFormValidationIntensityEmpty => '통증 강도를 입력해주세요.';

  @override
  String get painFormValidationIntensityRange => '강도는 0에서 10 사이여야 합니다.';

  @override
  String get painFormLabelDescription => '설명';

  @override
  String get painFormValidationSelectOrSpecifyDescription =>
      '통증 설명을 선택하거나 지정해주세요.';

  @override
  String get painFormValidationSpecifyOtherDescription => '통증 설명을 지정해주세요.';

  @override
  String get painFormHintSpecifyOtherDescription => '통증을 설명해주세요...';

  @override
  String get painFormHintNotes => '예: 활동 후 악화, 휴식 시 완화';

  @override
  String get formErrorFailedToUpdatePain => '통증 기록 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSavePain => '통증 기록 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get sleepFormTitleEdit => '수면 기록 편집';

  @override
  String get sleepFormTitleNew => '수면 기록';

  @override
  String get sleepQualityGood => '좋음';

  @override
  String get sleepQualityFair => '보통';

  @override
  String get sleepQualityPoor => '나쁨';

  @override
  String get sleepQualityRestless => '뒤척임';

  @override
  String get sleepQualityInterrupted => '중단됨';

  @override
  String get sleepFormLabelWentToBed => '취침 시간';

  @override
  String get sleepFormHintTimeWentToBed => '시간 선택';

  @override
  String get sleepFormValidationTimeWentToBed => '취침 시간을 선택해주세요.';

  @override
  String get sleepFormLabelWokeUp => '기상 시간 (선택 사항)';

  @override
  String get sleepFormHintTimeWokeUp => '시간 선택';

  @override
  String get sleepFormLabelTotalDuration => '총 수면 시간 (선택 사항)';

  @override
  String get sleepFormHintTotalDuration => '예: 7시간, 7시간 30분';

  @override
  String get sleepFormLabelQuality => '수면의 질';

  @override
  String get sleepFormValidationSelectQuality => '수면의 질을 선택해주세요.';

  @override
  String get sleepFormLabelDescribeOtherQuality => '기타 수면의 질 설명';

  @override
  String get sleepFormHintDescribeOtherQuality => '수면의 질을 설명해주세요...';

  @override
  String get sleepFormValidationDescribeOtherQuality => '수면의 질을 설명해주세요.';

  @override
  String get sleepFormLabelNaps => '낮잠 (선택 사항)';

  @override
  String get sleepFormHintNaps => '예: 1회, 30분';

  @override
  String get sleepFormLabelGeneralNotes => '일반 메모 (선택 사항)';

  @override
  String get sleepFormHintGeneralNotes => '예: 상쾌하게 일어남';

  @override
  String get sleepFormButtonUpdate => '수면 업데이트';

  @override
  String get sleepFormButtonSave => '수면 저장';

  @override
  String get formErrorFailedToUpdateSleep => '수면 기록 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSaveSleep => '수면 기록 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get vitalFormTitleEdit => '활력 징후 편집';

  @override
  String get vitalFormTitleNew => '활력 징후 기록';

  @override
  String get vitalTypeBPLabel => '혈압';

  @override
  String get vitalTypeBPUnit => 'mmHg';

  @override
  String get vitalTypeBPPlaceholder => '예: 120/80';

  @override
  String get vitalTypeHRLabel => '심박수';

  @override
  String get vitalTypeHRUnit => 'bpm';

  @override
  String get vitalTypeHRPlaceholder => '예: 70';

  @override
  String get vitalTypeWTLabel => '체중';

  @override
  String get vitalTypeWTUnit => 'kg/lbs';

  @override
  String get vitalTypeWTPlaceholder => '예: 65 kg 또는 143 lbs';

  @override
  String get vitalTypeBGLabel => '혈당';

  @override
  String get vitalTypeBGUnit => 'mg/dL 또는 mmol/L';

  @override
  String get vitalTypeBGPlaceholder => '예: 90 mg/dL';

  @override
  String get vitalTypeTempLabel => '체온';

  @override
  String get vitalTypeTempUnit => '°C/°F';

  @override
  String get vitalTypeTempPlaceholder => '예: 36.5°C 또는 97.7°F';

  @override
  String get vitalTypeO2Label => '산소 포화도';

  @override
  String get vitalTypeO2Unit => '%';

  @override
  String get vitalTypeO2Placeholder => '예: 98';

  @override
  String get vitalFormLabelType => '종류';

  @override
  String get vitalFormLabelValue => '값';

  @override
  String get vitalFormValidationValueEmpty => '값을 입력해주세요.';

  @override
  String get vitalFormValidationBPFormat =>
      '혈압을 \'수축기/이완기\'로 입력하세요 (예: 120/80).';

  @override
  String get vitalFormValidationValueNumeric => '숫자 값을 입력해주세요.';

  @override
  String get vitalFormHintNotes => '예: 식후 측정';

  @override
  String get vitalFormButtonUpdate => '활력 징후 업데이트';

  @override
  String get vitalFormButtonSave => '활력 징후 저장';

  @override
  String get formErrorFailedToUpdateVital => '활력 징후 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSaveVital => '활력 징후 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get settingsUserProfileNotLoaded => '사용자 프로필을 로드하지 못했습니다.';

  @override
  String get settingsDisplayNameCannotBeEmpty => '표시 이름을 비워 둘 수 없습니다.';

  @override
  String get settingsProfileUpdatedSuccess => '프로필이 성공적으로 업데이트되었습니다.';

  @override
  String settingsErrorUpdatingProfile(String errorMessage) {
    return '프로필 업데이트 중 오류 발생: $errorMessage';
  }

  @override
  String get settingsSelectElderFirstMedDef =>
      '약물 정의를 관리하려면 먼저 노인 프로필을 선택하십시오.';

  @override
  String get settingsMedNameRequired => '약물 이름은 필수입니다.';

  @override
  String get settingsMedDefaultTimeFormatError =>
      '잘못된 시간 형식입니다. HH:mm 형식을 사용하십시오 (예: 09:00).';

  @override
  String get settingsMedDefAddedSuccess => '약물 정의가 성공적으로 추가되었습니다.';

  @override
  String get settingsClearDataErrorElderOrUserMissing =>
      '데이터를 지울 수 없습니다: 활성 노인 또는 사용자가 없습니다.';

  @override
  String get settingsClearDataErrorNotAdmin =>
      '귀하는 이 노인 프로필의 주 관리자가 아닙니다. 데이터는 주 관리자만 지울 수 있습니다.';

  @override
  String settingsClearDataDialogTitle(String elderName) {
    return '$elderName님의 모든 데이터를 지우시겠습니까?';
  }

  @override
  String get settingsClearDataDialogContent =>
      '이 작업은 되돌릴 수 없으며 이 노인과 관련된 모든 기록(약물, 식사, 활력 징후 등)이 삭제됩니다. 계속하시겠습니까?';

  @override
  String get settingsClearDataDialogConfirmButton => '예, 모든 데이터 지우기';

  @override
  String settingsClearDataSuccess(String elderName) {
    return '$elderName님의 모든 데이터가 지워졌습니다.';
  }

  @override
  String settingsClearDataErrorGeneric(String errorMessage) {
    return '데이터 지우기 중 오류 발생: $errorMessage';
  }

  @override
  String get languageNameEn => '영어 (English)';

  @override
  String get languageNameEs => '스페인어 (Español)';

  @override
  String get languageNameJa => '일본어 (日本語)';

  @override
  String get languageNameKo => '한국어';

  @override
  String get languageNameZh => '중국어 (中文)';

  @override
  String get settingsTitleMyAccount => '내 계정';

  @override
  String get settingsLabelDisplayName => '표시 이름';

  @override
  String get settingsHintDisplayName => '표시 이름 입력';

  @override
  String get settingsLabelDOB => '생년월일';

  @override
  String get settingsHintDOB => '생년월일 선택';

  @override
  String get settingsButtonSaveProfile => '프로필 저장';

  @override
  String get settingsButtonSignOut => '로그아웃';

  @override
  String get settingsErrorLoadingProfile => '프로필 로드 중 오류 발생.';

  @override
  String get settingsTitleLanguage => '언어 설정';

  @override
  String get settingsLabelSelectLanguage => '앱 언어 선택';

  @override
  String settingsLanguageChangedConfirmation(String languageTag) {
    return '언어가 $languageTag(으)로 변경되었습니다.';
  }

  @override
  String get settingsTitleElderProfileManagement => '노인 프로필 관리';

  @override
  String settingsCurrentElder(String elderName) {
    return '현재 활성 노인: $elderName님';
  }

  @override
  String get settingsNoActiveElderSelected =>
      '활성 노인이 선택되지 않았습니다. 선택하거나 생성하십시오.';

  @override
  String get settingsErrorNavToManageElderProfiles =>
      '노인 프로필 관리로 이동할 수 없습니다. 사용자가 로그인하지 않았습니다.';

  @override
  String get settingsButtonManageElderProfiles => '노인 프로필 관리';

  @override
  String settingsTitleAdminActions(String elderName) {
    return '$elderName님 관리자 작업';
  }

  @override
  String get settingsButtonClearAllData => '이 노인의 모든 데이터 지우기';

  @override
  String get settingsTitleMedicationDefinitions => '약물 정의';

  @override
  String get settingsSubtitleAddNewMedDef => '새 약물 정의 추가:';

  @override
  String get settingsLabelMedName => '약물 이름';

  @override
  String get settingsHintMedName => '예: 리시노프릴';

  @override
  String get settingsLabelMedDose => '기본 복용량 (선택 사항)';

  @override
  String get settingsHintMedDose => '예: 10mg, 1정';

  @override
  String get settingsLabelMedDefaultTime => '기본 시간 (HH:mm, 선택 사항)';

  @override
  String get settingsHintMedDefaultTime => '예: 08:00';

  @override
  String get settingsButtonAddMedDef => '약물 정의 추가';

  @override
  String get settingsSelectElderToAddMedDefs => '약물 정의를 추가하려면 노인 프로필을 선택하십시오.';

  @override
  String get settingsSelectElderToViewMedDefs => '약물 정의를 보려면 노인 프로필을 선택하십시오.';

  @override
  String settingsNoMedDefsForElder(String elderName) {
    return '$elderName님에 대한 약물 정의를 찾을 수 없습니다.';
  }

  @override
  String settingsExistingMedDefsForElder(String elderNameOrFallback) {
    return '$elderNameOrFallback의 기존 정의:';
  }

  @override
  String get settingsSelectedElderFallback => '선택된 노인';

  @override
  String settingsMedDefDosePrefix(String dose) {
    return '복용량: $dose';
  }

  @override
  String settingsMedDefDefaultTimePrefix(String time) {
    return '시간: $time';
  }

  @override
  String get settingsTooltipDeleteMedDef => '이 약물 정의 삭제';

  @override
  String settingsDeleteMedDefDialogTitle(String medName) {
    return '\'$medName\' 정의를 삭제하시겠습니까?';
  }

  @override
  String get settingsDeleteMedDefDialogContent =>
      '이 약물 정의를 삭제하시겠습니까? 과거 약물 기록에는 영향을 미치지 않지만 향후 기록 옵션에서는 제거됩니다.';

  @override
  String settingsMedDefDeletedSuccess(String medName) {
    return '약물 정의 \'$medName\'이(가) 삭제되었습니다.';
  }

  @override
  String get errorNotLoggedIn => '오류: 사용자가 로그인하지 않았습니다.';

  @override
  String get errorElderIdMissing => '오류: 노인 ID가 없습니다.';

  @override
  String profileUpdatedSnackbar(String profileName) {
    return '$profileName님의 프로필이 업데이트되었습니다.';
  }

  @override
  String profileCreatedSnackbar(String profileName) {
    return '$profileName님의 프로필이 생성되었습니다.';
  }

  @override
  String errorSavingProfile(String errorMessage) {
    return '프로필 저장 중 오류 발생: $errorMessage';
  }

  @override
  String get errorSelectElderAndEmail => '노인 프로필을 선택하고 유효한 이메일 주소를 입력하십시오.';

  @override
  String invitationSentSnackbar(String email) {
    return '$email(으)로 초대가 전송되었습니다.';
  }

  @override
  String errorSendingInvitation(String errorMessage) {
    return '초대 전송 중 오류 발생: $errorMessage';
  }

  @override
  String get removeCaregiverDialogTitle => '돌봄 제공자 제거?';

  @override
  String removeCaregiverDialogContent(String caregiverIdentifier) {
    return '$caregiverIdentifier님을 이 노인의 돌봄 제공자에서 제거하시겠습니까?';
  }

  @override
  String caregiverRemovedSnackbar(String caregiverIdentifier) {
    return '돌봄 제공자 $caregiverIdentifier님이 제거되었습니다.';
  }

  @override
  String errorRemovingCaregiver(String errorMessage) {
    return '돌봄 제공자 제거 중 오류 발생: $errorMessage';
  }

  @override
  String get tooltipEditProfile => '프로필 편집';

  @override
  String get dobLabelPrefix => '생년월일:';

  @override
  String get allergiesLabelPrefix => '알레르기:';

  @override
  String get dietLabelPrefix => '식이요법:';

  @override
  String get primaryAdminLabel => '주 관리자:';

  @override
  String get adminNotAssigned => '할당되지 않음';

  @override
  String get loadingAdminInfo => '관리자 정보 로드 중...';

  @override
  String caregiversLabel(int count) {
    return '돌봄 제공자 ($count명):';
  }

  @override
  String get noCaregiversYet => '아직 돌봄 제공자가 없습니다.';

  @override
  String get errorLoadingCaregiverNames => '돌봄 제공자 이름 로드 중 오류 발생.';

  @override
  String get caregiverAdminSuffix => '(관리자)';

  @override
  String tooltipRemoveCaregiver(String identifier) {
    return '$identifier 제거';
  }

  @override
  String profileSetActiveSnackbar(String profileName) {
    return '$profileName님이 이제 활성 프로필입니다.';
  }

  @override
  String inviteDialogTitle(String profileName) {
    return '$profileName님 프로필에 돌봄 제공자 초대';
  }

  @override
  String get caregiversEmailLabel => '돌봄 제공자 이메일';

  @override
  String get enterEmailHint => '이메일 주소 입력';

  @override
  String get createElderProfileTitle => '새 노인 프로필 만들기';

  @override
  String editProfileTitle(String profileNameOrFallback) {
    return '$profileNameOrFallback 편집';
  }

  @override
  String get profileNameLabel => '프로필 이름';

  @override
  String get validatorPleaseEnterName => '이름을 입력해주세요.';

  @override
  String get dateOfBirthLabel => '생년월일';

  @override
  String get allergiesLabel => '알레르기 (쉼표로 구분)';

  @override
  String get dietaryRestrictionsLabel => '식이 제한 (쉼표로 구분)';

  @override
  String get createNewProfileButton => '새 프로필 만들기';

  @override
  String get saveChangesButton => '변경 사항 저장';

  @override
  String get errorPrefix => '오류: ';

  @override
  String get noElderProfilesFound => '노인 프로필을 찾을 수 없습니다.';

  @override
  String get createNewProfileOrWait => '새 프로필을 만들거나 초대를 기다리십시오.';

  @override
  String get fabNewProfile => '새 프로필';

  @override
  String get activityTypeWalk => '산책';

  @override
  String get activityTypeExercise => '운동';

  @override
  String get activityTypePhysicalTherapy => '물리 치료';

  @override
  String get activityTypeOccupationalTherapy => '작업 치료';

  @override
  String get activityTypeOuting => '외출';

  @override
  String get activityTypeSocialVisit => '사교 방문';

  @override
  String get activityTypeReading => '독서';

  @override
  String get activityTypeTV => 'TV/영화 시청';

  @override
  String get activityTypeGardening => '정원 가꾸기';

  @override
  String get assistanceLevelIndependent => '독립적';

  @override
  String get assistanceLevelStandbyAssist => '대기 보조';

  @override
  String get assistanceLevelWithWalker => '보행기 사용';

  @override
  String get assistanceLevelWithCane => '지팡이 사용';

  @override
  String get assistanceLevelWheelchair => '휠체어';

  @override
  String get assistanceLevelMinAssist => '최소 보조 (Min A)';

  @override
  String get assistanceLevelModAssist => '중간 보조 (Mod A)';

  @override
  String get assistanceLevelMaxAssist => '최대 보조 (Max A)';

  @override
  String get formErrorFailedToUpdateActivity => '활동 업데이트에 실패했습니다. 다시 시도해주세요.';

  @override
  String get formErrorFailedToSaveActivity => '활동 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get activityFormTitleEdit => '활동 편집';

  @override
  String get activityFormTitleNew => '새 활동 기록';

  @override
  String get activityFormLabelActivityType => '활동 유형';

  @override
  String get activityFormHintActivityType => '활동 선택 또는 입력';

  @override
  String get activityFormValidationActivityType => '활동 유형을 선택하거나 지정하십시오.';

  @override
  String get activityFormLabelDuration => '지속 시간 (선택 사항)';

  @override
  String get activityFormHintDuration => '예: 30분, 1시간';

  @override
  String get activityFormLabelAssistance => '도움 수준 (선택 사항)';

  @override
  String get activityFormHintAssistance => '도움 수준 선택';

  @override
  String get activityFormHintNotes => '예: 햇볕을 즐김, 공원까지 걸어감';

  @override
  String get notApplicable => '해당 없음';

  @override
  String careScreenWaterLog(String description) {
    return '물: $description';
  }

  @override
  String careScreenMealLog(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String get careScreenMealGeneric => '식사';

  @override
  String careScreenWaterContext(String contextDetails) {
    return '상황: $contextDetails';
  }

  @override
  String careScreenNotes(String noteContent) {
    return '메모: $noteContent';
  }

  @override
  String careScreenLoggedBy(String userName) {
    return '기록자: $userName';
  }

  @override
  String get careScreenTooltipEditFoodWater => '음식/물 항목 편집';

  @override
  String get careScreenTooltipDeleteFoodWater => '음식/물 항목 삭제';

  @override
  String get careScreenErrorMissingIdDelete => '오류: ID가 없어 항목을 삭제할 수 없습니다.';

  @override
  String get careScreenErrorFailedToLoad => '이날의 기록을 불러오는데 실패했습니다. 다시 시도해 주세요.';

  @override
  String get careScreenButtonAddFoodWater => '음식/물 추가';

  @override
  String get careScreenSectionTitleMoodBehavior => '기분 및 행동';

  @override
  String get careScreenNoMoodBehaviorLogged => '이날 기록된 기분이나 행동이 없습니다.';

  @override
  String careScreenMood(String mood) {
    return '기분: $mood';
  }

  @override
  String careScreenMoodIntensity(String intensityLevel) {
    return '강도: $intensityLevel';
  }

  @override
  String get careScreenTooltipEditMood => '기분 항목 편집';

  @override
  String get careScreenTooltipDeleteMood => '기분 항목 삭제';

  @override
  String get careScreenButtonAddMood => '기분/행동 추가';

  @override
  String get careScreenSectionTitlePain => '통증';

  @override
  String get careScreenNoPainLogged => '이날 기록된 통증이 없습니다.';

  @override
  String careScreenPainLog(
      String location, String description, String intensityDetails) {
    return '통증: $location - $description$intensityDetails';
  }

  @override
  String careScreenPainIntensity(String intensityValue) {
    return '강도: $intensityValue';
  }

  @override
  String get careScreenTooltipEditPain => '통증 항목 편집';

  @override
  String get careScreenTooltipDeletePain => '통증 항목 삭제';

  @override
  String get careScreenButtonAddPain => '통증 기록 추가';

  @override
  String get careScreenSectionTitleActivity => '활동';

  @override
  String get careScreenNoActivitiesLogged => '이날 기록된 활동이 없습니다.';

  @override
  String get careScreenUnknownActivity => '알 수 없는 활동';

  @override
  String careScreenActivityDuration(String duration) {
    return '지속 시간: $duration';
  }

  @override
  String careScreenActivityAssistance(String assistanceLevel) {
    return '도움: $assistanceLevel';
  }

  @override
  String get careScreenTooltipEditActivity => '활동 항목 편집';

  @override
  String get careScreenTooltipDeleteActivity => '활동 항목 삭제';

  @override
  String get careScreenButtonAddActivity => '활동 추가';

  @override
  String get careScreenSectionTitleVitals => '활력 징후';

  @override
  String get careScreenNoVitalsLogged => '이날 기록된 활력 징후가 없습니다.';

  @override
  String careScreenVitalLog(String vitalType, String value, String unit) {
    return '$vitalType: $value $unit';
  }

  @override
  String get careScreenTooltipEditVital => '활력 징후 항목 편집';

  @override
  String get careScreenTooltipDeleteVital => '활력 징후 항목 삭제';

  @override
  String get careScreenButtonAddVital => '활력 징후 추가';

  @override
  String get careScreenSectionTitleExpenses => '비용';

  @override
  String get careScreenNoExpensesLogged => '이날 기록된 비용이 없습니다.';

  @override
  String careScreenExpenseLog(String description, String amount) {
    return '$description: ₩$amount';
  }

  @override
  String careScreenExpenseCategory(String category, String noteDetails) {
    return '카테고리: $category$noteDetails';
  }

  @override
  String get careScreenTooltipEditExpense => '비용 항목 편집';

  @override
  String get careScreenTooltipDeleteExpense => '비용 항목 삭제';

  @override
  String get careScreenButtonAddExpense => '비용 추가';

  @override
  String get calendarErrorLoadEvents => '캘린더 일정을 불러오는 데 실패했습니다. 다시 시도해주세요.';

  @override
  String get calendarErrorUserNotLoggedIn =>
      '오류: 사용자가 로그인하지 않았습니다. 캘린더 일정을 불러올 수 없습니다.';

  @override
  String get calendarErrorEditMissingId => '오류: ID가 없어 일정을 편집할 수 없습니다.';

  @override
  String get calendarErrorEditPermission => '오류: 이 일정을 편집할 권한이 없습니다.';

  @override
  String get calendarErrorUpdateOriginalMissing => '오류: 업데이트할 원본 일정 데이터가 없습니다.';

  @override
  String get calendarErrorUpdatePermission => '오류: 이 일정을 업데이트할 권한이 없습니다.';

  @override
  String get calendarEventAddedSuccess => '일정이 성공적으로 추가되었습니다.';

  @override
  String get calendarEventUpdatedSuccess => '일정이 성공적으로 업데이트되었습니다.';

  @override
  String calendarErrorSaveEvent(String errorMessage) {
    return '일정 저장 중 오류 발생: $errorMessage';
  }

  @override
  String get calendarErrorDeleteMissingId => '오류: ID가 없어 일정을 삭제할 수 없습니다.';

  @override
  String get calendarErrorDeletePermission => '오류: 이 일정을 삭제할 권한이 없습니다.';

  @override
  String get calendarConfirmDeleteTitle => '삭제 확인';

  @override
  String calendarConfirmDeleteContent(String eventTitle) {
    return '\'$eventTitle\' 일정을 삭제하시겠습니까?';
  }

  @override
  String get calendarUntitledEvent => '제목 없는 일정';

  @override
  String get eventDeletedSuccess => '일정이 성공적으로 삭제되었습니다.';

  @override
  String get errorCouldNotDeleteEvent => '오류: 일정을 삭제할 수 없습니다.';

  @override
  String get calendarNoElderSelected => '선택된 노인이 없습니다. 캘린더를 보려면 노인을 선택하십시오.';

  @override
  String get calendarAddNewEventButton => '새 일정 추가';

  @override
  String calendarEventsOnDate(String formattedDate) {
    return '$formattedDate의 일정:';
  }

  @override
  String get calendarNoEventsScheduled => '이날 예정된 일정이 없습니다.';

  @override
  String get calendarTooltipEditEvent => '일정 편집';

  @override
  String get calendarEventTypePrefix => '유형:';

  @override
  String get calendarEventTimePrefix => '시간:';

  @override
  String get calendarEventNotesPrefix => '메모:';

  @override
  String get expenseUncategorized => '미분류';

  @override
  String expenseErrorProcessingData(String errorMessage) {
    return '비용 데이터 처리 중 오류 발생: $errorMessage';
  }

  @override
  String expenseErrorFetching(String errorMessage) {
    return '비용 조회 중 오류 발생: $errorMessage';
  }

  @override
  String get expenseUnknownUser => '알 수 없는 사용자';

  @override
  String get expenseSelectElderPrompt => '비용을 보려면 노인 프로필을 선택하십시오.';

  @override
  String get expenseLoading => '비용 로드 중...';

  @override
  String get expenseScreenTitle => '비용';

  @override
  String expenseForElder(String elderName) {
    return '$elderName님의 비용';
  }

  @override
  String get expensePrevWeekButton => '지난 주';

  @override
  String get expenseNextWeekButton => '다음 주';

  @override
  String get expenseNoExpensesThisWeek => '이번 주에 기록된 비용이 없습니다.';

  @override
  String get expenseSummaryByCategoryTitle => '카테고리별 요약 (이번 주)';

  @override
  String get expenseNoExpensesInCategoryThisWeek => '선택한 주의 이 카테고리에는 비용이 없습니다.';

  @override
  String get expenseWeekTotalLabel => '주간 총계:';

  @override
  String get expenseDetailedByUserTitle => '상세 비용 (이번 주 - 사용자별)';

  @override
  String expenseCategoryLabel(String categoryName) {
    return '카테고리: $categoryName';
  }

  @override
  String get errorEnterEmailPassword => '이메일과 비밀번호를 입력해주세요.';

  @override
  String get errorLoginFailedDefault =>
      '로그인에 실패했습니다. 자격 증명을 확인하거나 네트워크 연결을 확인하세요.';

  @override
  String get loginScreenTitle => '세실리아 케어에 오신 것을 환영합니다';

  @override
  String get settingsLabelRelationshipToElder => '돌봄 대상자와의 관계';

  @override
  String get settingsHintRelationshipToElder => '예: 아들/딸, 배우자, 간병인';

  @override
  String get emailLabel => '이메일';

  @override
  String get emailHint => '이메일 주소를 입력하세요';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get dontHaveAccountSignUp => '계정이 없으신가요? 회원가입';

  @override
  String get signUpNotImplemented => '회원가입 기능은 아직 구현되지 않았습니다.';

  @override
  String get homeScreenBaseTitleTimeline => '타임라인';

  @override
  String homeScreenBaseTitleCareLog(String term) {
    return '$term 케어 기록';
  }

  @override
  String homeScreenBaseTitleCalendar(String term) {
    return '$term 캘린더';
  }

  @override
  String get homeScreenBaseTitleExpenses => '비용';

  @override
  String get homeScreenBaseTitleSettings => '설정';

  @override
  String get mustBeLoggedInToAddData => '데이터를 추가하려면 로그인해야 합니다.';

  @override
  String get mustBeLoggedInToUpdateData => '데이터를 업데이트하려면 로그인해야 합니다.';

  @override
  String selectTermToViewCareLog(String term) {
    return '케어 기록을 보려면 $term을(를) 선택하세요.';
  }

  @override
  String get selectElderToViewCareLog => '돌봄 기록을 보려면 돌봄 대상자를 선택하세요.';

  @override
  String get goToSettingsButton => '설정으로 이동';

  @override
  String selectTermToViewCalendar(String term) {
    return '캘린더를 보려면 $term을(를) 선택하세요.';
  }

  @override
  String get bottomNavTimeline => '타임라인';

  @override
  String bottomNavCareLog(Object term) {
    return '$term 기록';
  }

  @override
  String bottomNavCalendar(Object term) {
    return '$term 캘린더';
  }

  @override
  String get bottomNavExpenses => '비용';

  @override
  String get bottomNavSettings => '설정';

  @override
  String get timelineUnknownTime => '알 수 없는 시간';

  @override
  String get timelineInvalidTime => '잘못된 시간';

  @override
  String get timelineMustBeLoggedInToPost => '메시지를 게시하려면 로그인해야 합니다.';

  @override
  String get timelineSelectElderToPost => '타임라인에 게시하려면 활성 노인 프로필을 선택하세요.';

  @override
  String get timelineAnonymousUser => '익명';

  @override
  String timelineCouldNotPostMessage(String errorMessage) {
    return '메시지를 게시할 수 없습니다: $errorMessage';
  }

  @override
  String get timelinePleaseLogInToView => '타임라인을 보려면 로그인하세요.';

  @override
  String get timelineSelectElderToView => '타임라인을 보려면 노인 프로필을 선택하세요.';

  @override
  String timelineWriteMessageHint(String elderName) {
    return '$elderName님의 타임라인에 메시지를 작성하세요...';
  }

  @override
  String get timelineUnknownUser => '알 수 없는 사용자';

  @override
  String get timelinePostButton => '게시';

  @override
  String get timelineCancelButton => '취소';

  @override
  String get timelinePostMessageToTimelineButton => '타임라인에 메시지 게시';

  @override
  String get timelineLoading => '타임라인 로드 중...';

  @override
  String timelineErrorLoading(String errorMessage) {
    return '타임라인 로드 오류: $errorMessage';
  }

  @override
  String timelineNoEntriesYet(String elderName) {
    return '$elderName님의 항목이 아직 없습니다. 첫 번째로 게시해보세요!';
  }

  @override
  String get timelineItemTitleMessage => '메시지';

  @override
  String get timelineEmptyMessage => '[빈 메시지]';

  @override
  String get timelineItemTitleMedication => '약물';

  @override
  String get timelineItemTitleSleep => '수면';

  @override
  String get timelineItemTitleMeal => '식사';

  @override
  String get timelineItemTitleMood => '기분';

  @override
  String get timelineItemTitlePain => '통증';

  @override
  String get timelineItemTitleActivity => '활동';

  @override
  String get timelineItemTitleVital => '활력 징후';

  @override
  String get timelineItemTitleExpense => '비용';

  @override
  String get timelineItemTitleEntry => '항목';

  @override
  String get timelineNoDetailsProvided => '세부 정보가 제공되지 않았습니다.';

  @override
  String timelineLoggedBy(String userName) {
    return '$userName님이 기록';
  }

  @override
  String timelineErrorRenderingItem(String index, String errorDetails) {
    return '인덱스 $index의 항목 렌더링 오류: $errorDetails';
  }

  @override
  String get timelineSummaryDetailsUnavailable => '세부 정보 이용 불가';

  @override
  String get timelineSummaryNotApplicable => '해당 없음';

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
  String get timelineSummaryMedicationStatusTaken => '복용 완료';

  @override
  String get timelineSummaryMedicationStatusNotTaken => '미복용';

  @override
  String get timelineSummaryMealTypeGeneric => '식사';

  @override
  String timelineSummarySleepQualityFormat(String quality) {
    return '수면의 질: $quality';
  }

  @override
  String timelineSummarySleepFormat(
      String wentToBed, String wokeUp, String quality) {
    return '취침: $wentToBed, 기상: $wokeUp. $quality';
  }

  @override
  String timelineSummaryMealFormat(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String timelineSummaryMoodNotesFormat(String notes) {
    return '(메모: $notes)';
  }

  @override
  String timelineSummaryMoodFormat(String mood, String notes) {
    return '기분: $mood $notes';
  }

  @override
  String timelineSummaryPainLocationFormat(String location) {
    return '$location에서';
  }

  @override
  String timelineSummaryPainFormat(String level, String location) {
    return '통증 강도: $level/10 $location';
  }

  @override
  String timelineSummaryActivityDurationFormat(String duration) {
    return '$duration 동안';
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
    return '혈압: $systolic/$diastolic mmHg';
  }

  @override
  String timelineSummaryVitalFormatHR(String heartRate) {
    return '심박수: $heartRate bpm';
  }

  @override
  String timelineSummaryVitalFormatTemp(String temperature) {
    return '체온: $temperature°';
  }

  @override
  String timelineSummaryVitalNote(String note) {
    return '메모: $note';
  }

  @override
  String get timelineSummaryVitalsRecorded => '활력 징후 기록됨';

  @override
  String timelineSummaryExpenseDescriptionFormat(String description) {
    return '($description)';
  }

  @override
  String timelineSummaryExpenseFormat(
      String category, String amount, String description) {
    return '$category: ₩$amount $description';
  }

  @override
  String get timelineSummaryErrorProcessing => '타임라인 세부 정보 처리 오류.';

  @override
  String get timelineItemTitleImage => 'Image Uploaded';

  @override
  String timelineSummaryImageFormat(Object title) {
    return 'Image: $title';
  }

  @override
  String get careScreenErrorMissingIdGeneral => '오류: 항목 ID가 없습니다. 계속할 수 없습니다.';

  @override
  String get careScreenErrorEditPermission => '오류: 이 항목을 편집할 권한이 없습니다.';

  @override
  String get careScreenErrorUpdateMedStatus => '약물 상태 업데이트 오류. 다시 시도해주세요.';

  @override
  String get careScreenLoadingRecords => '오늘의 기록 로드 중...';

  @override
  String get careScreenErrorNoRecords => '이날 기록을 찾을 수 없거나 오류가 발생했습니다.';

  @override
  String get careScreenSectionTitleMeds => '약물';

  @override
  String get careScreenNoMedsLogged => '이날 기록된 약물이 없습니다.';

  @override
  String get careScreenUnknownMedication => '알 수 없는 약물';

  @override
  String get careScreenTooltipEditMed => '약물 항목 편집';

  @override
  String get careScreenTooltipDeleteMed => '약물 항목 삭제';

  @override
  String get careScreenButtonAddMed => '약물 추가';

  @override
  String get careScreenSectionTitleSleep => '수면';

  @override
  String get careScreenNoSleepLogged => '이날 기록된 수면이 없습니다.';

  @override
  String careScreenSleepTimeRange(String wentToBed, String wokeUp) {
    return '$wentToBed - $wokeUp';
  }

  @override
  String careScreenSleepQuality(String quality, String duration) {
    return '수면의 질: $quality $duration';
  }

  @override
  String careScreenSleepNaps(String naps) {
    return '낮잠: $naps';
  }

  @override
  String get careScreenTooltipEditSleep => '수면 항목 편집';

  @override
  String get careScreenTooltipDeleteSleep => '수면 항목 삭제';

  @override
  String get careScreenButtonAddSleep => '수면 추가';

  @override
  String get careScreenSectionTitleFoodWater => '식사 및 수분 섭취';

  @override
  String get careScreenNoFoodWaterLogged => '이날 기록된 식사 또는 수분 섭취가 없습니다.';

  @override
  String errorEnterValidEmailPasswordMinLength(int minLength) {
    return '유효한 이메일과 비밀번호(최소 $minLength자)를 입력해주세요.';
  }

  @override
  String get errorSignUpFailedDefault =>
      '가입에 실패했습니다. 다시 시도하거나 네트워크 연결을 확인해주세요.';

  @override
  String get signUpScreenTitle => '계정 만들기';

  @override
  String get createAccountTitle => '계정 생성';

  @override
  String get signUpButton => '가입하기';

  @override
  String get termElderDefault => '돌봄 대상자';

  @override
  String get formErrorGenericSaveUpdate =>
      '저장 또는 업데이트 중 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get formSuccessActivitySaved => '활동이 성공적으로 저장되었습니다.';

  @override
  String get formSuccessActivityUpdated => '활동이 성공적으로 업데이트되었습니다.';

  @override
  String get formSuccessExpenseSaved => '비용이 성공적으로 저장되었습니다.';

  @override
  String get formSuccessExpenseUpdated => '비용이 성공적으로 업데이트되었습니다.';

  @override
  String get formSuccessMealSaved => '식사가 성공적으로 저장되었습니다.';

  @override
  String get formSuccessMealUpdated => '식사가 성공적으로 업데이트되었습니다.';

  @override
  String get formSuccessMedSaved => '약물 정보가 성공적으로 저장되었습니다.';

  @override
  String get formSuccessMedUpdated => '약물 정보가 성공적으로 업데이트되었습니다.';

  @override
  String get formSuccessMoodSaved => '기분이 성공적으로 저장되었습니다.';

  @override
  String get formSuccessMoodUpdated => '기분이 성공적으로 업데이트되었습니다.';

  @override
  String get formSuccessPainSaved => '통증 기록이 성공적으로 저장되었습니다.';

  @override
  String get formSuccessPainUpdated => '통증 기록이 성공적으로 업데이트되었습니다.';

  @override
  String get formSuccessSleepSaved => '수면 기록이 성공적으로 저장되었습니다.';

  @override
  String get formSuccessSleepUpdated => '수면 기록이 성공적으로 업데이트되었습니다.';

  @override
  String get formSuccessVitalSaved => '활력 징후가 성공적으로 저장되었습니다.';

  @override
  String get formSuccessVitalUpdated => '활력 징후가 성공적으로 업데이트되었습니다.';

  @override
  String get formErrorNoItemToDelete => '삭제할 항목이 없습니다.';

  @override
  String get formConfirmDeleteTitle => '삭제 확인';

  @override
  String get formConfirmDeleteVitalMessage => '이 활력 징후 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessVitalDeleted => '활력 징후 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeleteVital => '활력 징후 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeleteVital => '활력 징후 삭제';

  @override
  String get formConfirmDeleteMealMessage => '이 식사 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessMealDeleted => '식사 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeleteMeal => '식사 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeleteMeal => '식사 삭제';

  @override
  String get goToTodayButtonLabel => '오늘로 이동';

  @override
  String get formConfirmDeleteMedMessage => '이 약물 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessMedDeleted => '약물 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeleteMed => '약물 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeleteMed => '약물 삭제';

  @override
  String get formConfirmDeleteMoodMessage => '이 기분 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessMoodDeleted => '기분 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeleteMood => '기분 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeleteMood => '기분 삭제';

  @override
  String get formConfirmDeletePainMessage => '이 통증 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessPainDeleted => '통증 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeletePain => '통증 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeletePain => '통증 삭제';

  @override
  String get formConfirmDeleteActivityMessage => '이 활동 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessActivityDeleted => '활동 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeleteActivity => '활동 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeleteActivity => '활동 삭제';

  @override
  String get formConfirmDeleteSleepMessage => '이 수면 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessSleepDeleted => '수면 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeleteSleep => '수면 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeleteSleep => '수면 삭제';

  @override
  String get formConfirmDeleteExpenseMessage => '이 비용 기록을 삭제하시겠습니까?';

  @override
  String get formSuccessExpenseDeleted => '비용 기록이 삭제되었습니다.';

  @override
  String get formErrorFailedToDeleteExpense => '비용 기록 삭제에 실패했습니다.';

  @override
  String get formTooltipDeleteExpense => '비용 삭제';

  @override
  String get userSelectorSendToLabel => '수신인:';

  @override
  String get userSelectorAudienceAll => '모든 사용자';

  @override
  String get userSelectorAudienceSpecific => '특정 사용자';

  @override
  String get userSelectorNoUsersAvailable => '선택 가능한 다른 사용자가 없습니다.';

  @override
  String get timelinePostingToAll => '게시 대상: 모든 사용자';

  @override
  String timelinePostingToCount(String count) {
    return '게시 대상: $count명의 특정 사용자';
  }

  @override
  String get timelinePrivateMessageIndicator => '개인 메시지';

  @override
  String get timelineEditMessage => '메시지 수정';

  @override
  String get timelineDeleteMessage => '메시지 삭제';

  @override
  String get timelineConfirmDeleteMessageTitle => '메시지를 삭제하시겠습니까?';

  @override
  String get timelineConfirmDeleteMessageContent => '이 메시지를 정말로 삭제하시겠습니까?';

  @override
  String get timelineMessageDeletedSuccess => '메시지가 삭제되었습니다.';

  @override
  String timelineErrorDeletingMessage(String errorMessage) {
    return '메시지 삭제 중 오류 발생: $errorMessage';
  }

  @override
  String get timelineMessageUpdatedSuccess => '메시지가 업데이트되었습니다.';

  @override
  String timelineErrorUpdatingMessage(String errorMessage) {
    return '메시지 업데이트 중 오류 발생: $errorMessage';
  }

  @override
  String get timelineUpdateButton => '업데이트';

  @override
  String get timelineHideMessage => '메시지 숨기기';

  @override
  String get timelineMessageHiddenSuccess => '메시지가 숨겨졌습니다.';

  @override
  String get timelineShowHiddenMessagesButton => '숨김 항목 보기';

  @override
  String get timelineHideHiddenMessagesButton => '모두 보기';

  @override
  String get timelineUnhideMessage => '메시지 숨기기 취소';

  @override
  String get timelineMessageUnhiddenSuccess => '메시지 숨기기가 취소되었습니다.';

  @override
  String get timelineNoHiddenMessages => '숨겨진 메시지가 없습니다.';

  @override
  String get selfCareScreenTitle => '셀프 케어';

  @override
  String get settingsTitleNotificationPreferences => '알림 설정';

  @override
  String get settingsItemNotificationPreferences => '알림 환경 설정';

  @override
  String get landingPageAlreadyLoggedIn => '이미 로그인되어 있습니다!';

  @override
  String get manageMedications => '약물 관리';

  @override
  String get medicationsScreenTitleGeneric => '약물';

  @override
  String medicationsScreenTitleForElder(String name) {
    return '$name님의 약물';
  }

  @override
  String get medicationsSearchHint => '약물 이름 검색';

  @override
  String get medicationsDoseHint => '예: 10mg';

  @override
  String get medicationsScheduleHint => '예: 오전/오후';

  @override
  String get medicationsListEmpty => '아직 추가된 약물이 없습니다';

  @override
  String get medicationsDoseNotSet => '복용량이 설정되지 않았습니다';

  @override
  String get medicationsScheduleNotSet => '일정이 설정되지 않았습니다';

  @override
  String get medicationsTooltipDelete => '약물 삭제';

  @override
  String medicationsConfirmDeleteTitle(String medName) {
    return '\'$medName\'을(를) 삭제하시겠습니까?';
  }

  @override
  String get medicationsConfirmDeleteContent => '이 작업은 되돌릴 수 없습니다.';

  @override
  String medicationsDeletedSuccess(String medName) {
    return '약물 \'$medName\'이(가) 제거되었습니다.';
  }

  @override
  String get rxNavGenericSearchError => '약물 목록을 가져올 수 없습니다. 다시 시도해주세요.';

  @override
  String get medicationsValidationNameRequired => '이름이 필요합니다';

  @override
  String get medicationsValidationDoseRequired => '복용량이 필요합니다';

  @override
  String get medicationsInteractionsFoundTitle => '상호작용 가능성이 발견되었습니다';

  @override
  String get medicationsNoInteractionsFound => '상호작용이 발견되지 않았습니다';

  @override
  String get medicationsInteractionsSaveAnyway => '그래도 저장하시겠습니까';

  @override
  String get medicationsAddDialogTitle => '약물 추가';

  @override
  String medicationsAddedSuccess(String medName) {
    return '약물 \'$medName\'이(가) 추가되었습니다.';
  }

  @override
  String get routeErrorGenericMessage => '문제가 발생했습니다. 다시 시도해주세요.';

  @override
  String get goHomeButton => '홈으로 가기';

  @override
  String get settingsTitleHelpfulResources => '유용한 자료';

  @override
  String get settingsItemHelpfulResources => '유용한 자료 보기';

  @override
  String get timelineFilterOnlyMyLogs => '내 기록만:';

  @override
  String get timelineFilterFromDate => '시작일';

  @override
  String get timelineFilterToDate => '종료일';

  @override
  String get medicationsInteractionsSectionTitle => '상호작용';

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
      'Please select an active elder profile to upload images.';

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
  String get noImagesUploadedYet => 'No images uploaded yet for this elder.';

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
  String get generalNotificationsLabel => 'General App Notifications';

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
