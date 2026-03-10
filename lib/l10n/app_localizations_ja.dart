// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'セシリアケア';

  @override
  String get loginButton => 'ログイン';

  @override
  String get settingsTitle => '設定';

  @override
  String get languageSetting => '言語';

  @override
  String get manageElderProfilesTitle => '高齢者プロファイルの管理';

  @override
  String get createProfileButton => 'プロファイル作成';

  @override
  String get pleaseLogInToManageProfiles => '高齢者プロファイルを管理するにはログインしてください。';

  @override
  String calendarScreenTitle(String elderName) {
    return '$elderNameさんのカレンダー';
  }

  @override
  String get formOptionOther => 'その他';

  @override
  String get formLabelNotesOptional => 'メモ (任意)';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get updateButton => '更新';

  @override
  String get saveButton => '保存';

  @override
  String get okButton => 'OK';

  @override
  String get deleteButton => '削除';

  @override
  String get removeButton => '削除';

  @override
  String get inviteButton => '招待';

  @override
  String get activeButton => '有効';

  @override
  String get setActiveButton => '有効にする';

  @override
  String get sendInviteButton => '招待を送信';

  @override
  String get formUnknownUser => '不明なユーザー';

  @override
  String get timePickerHelpText => '時間を選択';

  @override
  String get expenseFormTitleEdit => '経費編集';

  @override
  String get expenseFormTitleNew => '新規経費';

  @override
  String get expenseFormLabelDescription => '説明';

  @override
  String get expenseFormHintDescription => '例: 処方箋の補充';

  @override
  String get expenseFormValidationDescription => '説明を入力してください。';

  @override
  String get expenseFormLabelAmount => '金額';

  @override
  String get expenseFormHintAmount => '例: 25.50';

  @override
  String get expenseFormValidationAmountEmpty => '金額を入力してください。';

  @override
  String get expenseFormValidationAmountInvalid => '有効な正の金額を入力してください。';

  @override
  String get expenseFormLabelCategory => 'カテゴリ';

  @override
  String get expenseCategoryMedical => '医療';

  @override
  String get expenseCategoryGroceries => '食料品';

  @override
  String get expenseCategorySupplies => '消耗品';

  @override
  String get expenseCategoryHousehold => '家庭用品';

  @override
  String get expenseCategoryPersonalCare => 'パーソナルケア';

  @override
  String get expenseFormValidationCategory => 'カテゴリを選択してください。';

  @override
  String get expenseFormHintNotes => '関連するメモをここに追加...';

  @override
  String get formErrorFailedToUpdateExpense => '経費の更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSaveExpense => '経費の保存に失敗しました。もう一度お試しください。';

  @override
  String get mealFormTitleEdit => '食事・水分摂取の編集';

  @override
  String get mealFormTitleNew => '食事・水分摂取の記録';

  @override
  String get mealFormLabelIntakeType => '摂取タイプ';

  @override
  String get mealFormIntakeCategoryFood => '食事';

  @override
  String get mealFormIntakeCategoryWater => '水分';

  @override
  String get mealFormLabelMealType => '食事の種類';

  @override
  String get mealFormMealTypeBreakfast => '朝食';

  @override
  String get mealFormMealTypeLunch => '昼食';

  @override
  String get mealFormMealTypeSnack => '間食';

  @override
  String get mealFormMealTypeDinner => '夕食';

  @override
  String get mealFormLabelDescription => '説明';

  @override
  String get mealFormHintFoodDescription => '例: チキンスープ、トースト';

  @override
  String get mealFormValidationFoodDescription => '食事内容を記述してください。';

  @override
  String get mealFormLabelWaterContext => '水分摂取の状況 (任意)';

  @override
  String get mealFormHintWaterContext => '例: 服薬時、喉が渇いた時';

  @override
  String get mealFormLabelWaterAmount => '量';

  @override
  String get mealFormHintWaterAmount => '例: コップ1杯、200ml';

  @override
  String get mealFormValidationWaterAmount => '水分量を指定してください。';

  @override
  String get mealFormHintFoodNotes => '例: よく食べた、人参が嫌いだった';

  @override
  String get mealFormHintWaterNotes => '例: ゆっくり飲んだ';

  @override
  String get formErrorFailedToUpdateMeal => '食事の更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSaveMeal => '食事の保存に失敗しました。もう一度お試しください。';

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
  String get medFormTitleEdit => '投薬編集';

  @override
  String get medFormTitleNew => '投薬記録';

  @override
  String get medFormTimePickerHelpText => '投薬時間を選択';

  @override
  String get medFormLabelName => '薬剤名';

  @override
  String get medFormHintNameCustom => 'またはカスタム薬剤名を入力';

  @override
  String get medFormHintName => '薬剤名を入力';

  @override
  String get medFormValidationName => '薬剤名を入力してください。';

  @override
  String get medFormLabelDose => '用量 (任意)';

  @override
  String get medFormHintDose => '例: 1錠、10mg';

  @override
  String get medFormLabelTime => '時間 (任意)';

  @override
  String get medFormHintTime => '時間を選択';

  @override
  String get medFormLabelMarkAsTaken => '服用済みにする';

  @override
  String get formErrorFailedToUpdateMed => '投薬の更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSaveMed => '投薬の保存に失敗しました。もう一度お試しください。';

  @override
  String get moodFormTitleEdit => '気分の編集';

  @override
  String get moodFormTitleNew => '気分の記録';

  @override
  String get moodHappy => '😊 嬉しい';

  @override
  String get moodContent => '🙂 満足';

  @override
  String get moodSad => '😟 悲しい';

  @override
  String get moodAnxious => '😬 不安';

  @override
  String get moodCalm => '😌 穏やか';

  @override
  String get moodIrritable => '😠 イライラ';

  @override
  String get moodAgitated => '😫 興奮';

  @override
  String get moodPlayful => '🥳 陽気';

  @override
  String get moodTired => '😴 疲れた';

  @override
  String get moodOptionOther => '📝 その他';

  @override
  String get moodFormLabelSelectMood => '気分を選択';

  @override
  String get moodFormValidationSelectOrSpecifyMood => '気分を選択または指定してください。';

  @override
  String get moodFormValidationSpecifyOtherMood => '気分を指定してください。';

  @override
  String get moodFormHintSpecifyOtherMood => '気分を記述してください...';

  @override
  String get moodFormLabelIntensity => '強度 (1-5, 任意)';

  @override
  String get moodFormHintIntensity => '1 (軽度) - 5 (重度)';

  @override
  String get moodFormValidationIntensityRange => '強度は1から5の間でなければなりません。';

  @override
  String get moodFormHintNotes => '例: 散歩の後気分が良い';

  @override
  String get moodFormButtonUpdate => '気分を更新';

  @override
  String get moodFormButtonSave => '気分を保存';

  @override
  String get formErrorFailedToUpdateMood => '気分の更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSaveMood => '気分の保存に失敗しました。もう一度お試しください。';

  @override
  String get painFormTitleEdit => '痛みの記録編集';

  @override
  String get painFormTitleNew => '痛みの記録';

  @override
  String get painTypeAching => 'ズキズキする痛み';

  @override
  String get painTypeBurning => '焼けるような痛み';

  @override
  String get painTypeDull => '鈍い痛み';

  @override
  String get painTypeSharp => '鋭い痛み';

  @override
  String get painTypeShooting => '突き刺すような痛み';

  @override
  String get painTypeStabbing => '刺すような痛み';

  @override
  String get painTypeThrobbing => '脈打つような痛み';

  @override
  String get painTypeTender => '圧痛';

  @override
  String get painFormLabelLocation => '場所';

  @override
  String get painFormHintLocation => '例: 左膝、腰';

  @override
  String get painFormValidationLocation => '痛みの場所を指定してください。';

  @override
  String get painFormLabelIntensity => '強度 (0-10)';

  @override
  String get painFormHintIntensity => '0 (痛みなし) - 10 (最悪の痛み)';

  @override
  String get painFormValidationIntensityEmpty => '痛みの強度を入力してください。';

  @override
  String get painFormValidationIntensityRange => '強度は0から10の間でなければなりません。';

  @override
  String get painFormLabelDescription => '説明';

  @override
  String get painFormValidationSelectOrSpecifyDescription =>
      '痛みの説明を選択または指定してください。';

  @override
  String get painFormValidationSpecifyOtherDescription => '痛みの説明を指定してください。';

  @override
  String get painFormHintSpecifyOtherDescription => '痛みを記述してください...';

  @override
  String get painFormHintNotes => '例: 活動後に悪化、安静で軽減';

  @override
  String get formErrorFailedToUpdatePain => '痛みの記録の更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSavePain => '痛みの記録の保存に失敗しました。もう一度お試しください。';

  @override
  String get sleepFormTitleEdit => '睡眠記録の編集';

  @override
  String get sleepFormTitleNew => '睡眠記録';

  @override
  String get sleepQualityGood => '良い';

  @override
  String get sleepQualityFair => '普通';

  @override
  String get sleepQualityPoor => '悪い';

  @override
  String get sleepQualityRestless => '落ち着かない';

  @override
  String get sleepQualityInterrupted => '中断された';

  @override
  String get sleepFormLabelWentToBed => '就寝時間';

  @override
  String get sleepFormHintTimeWentToBed => '時間を選択';

  @override
  String get sleepFormValidationTimeWentToBed => '就寝時間を選択してください。';

  @override
  String get sleepFormLabelWokeUp => '起床時間 (任意)';

  @override
  String get sleepFormHintTimeWokeUp => '時間を選択';

  @override
  String get sleepFormLabelTotalDuration => '合計時間 (任意)';

  @override
  String get sleepFormHintTotalDuration => '例: 7時間, 7時間30分';

  @override
  String get sleepFormLabelQuality => '質';

  @override
  String get sleepFormValidationSelectQuality => '睡眠の質を選択してください。';

  @override
  String get sleepFormLabelDescribeOtherQuality => 'その他の質を記述';

  @override
  String get sleepFormHintDescribeOtherQuality => '睡眠の質を記述してください...';

  @override
  String get sleepFormValidationDescribeOtherQuality => '睡眠の質を記述してください。';

  @override
  String get sleepFormLabelNaps => '昼寝 (任意)';

  @override
  String get sleepFormHintNaps => '例: 1回、30分';

  @override
  String get sleepFormLabelGeneralNotes => '一般的なメモ (任意)';

  @override
  String get sleepFormHintGeneralNotes => '例: スッキリ目覚めた';

  @override
  String get sleepFormButtonUpdate => '睡眠を更新';

  @override
  String get sleepFormButtonSave => '睡眠を保存';

  @override
  String get formErrorFailedToUpdateSleep => '睡眠記録の更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSaveSleep => '睡眠記録の保存に失敗しました。もう一度お試しください。';

  @override
  String get vitalFormTitleEdit => 'バイタルサイン編集';

  @override
  String get vitalFormTitleNew => 'バイタルサイン記録';

  @override
  String get vitalTypeBPLabel => '血圧';

  @override
  String get vitalTypeBPUnit => 'mmHg';

  @override
  String get vitalTypeBPPlaceholder => '例: 120/80';

  @override
  String get vitalTypeHRLabel => '心拍数';

  @override
  String get vitalTypeHRUnit => 'bpm';

  @override
  String get vitalTypeHRPlaceholder => '例: 70';

  @override
  String get vitalTypeWTLabel => '体重';

  @override
  String get vitalTypeWTUnit => 'kg/lbs';

  @override
  String get vitalTypeWTPlaceholder => '例: 65 kg または 143 lbs';

  @override
  String get vitalTypeBGLabel => '血糖値';

  @override
  String get vitalTypeBGUnit => 'mg/dL または mmol/L';

  @override
  String get vitalTypeBGPlaceholder => '例: 90 mg/dL';

  @override
  String get vitalTypeTempLabel => '体温';

  @override
  String get vitalTypeTempUnit => '°C/°F';

  @override
  String get vitalTypeTempPlaceholder => '例: 36.5°C または 97.7°F';

  @override
  String get vitalTypeO2Label => '酸素飽和度';

  @override
  String get vitalTypeO2Unit => '%';

  @override
  String get vitalTypeO2Placeholder => '例: 98';

  @override
  String get vitalFormLabelType => '種類';

  @override
  String get vitalFormLabelValue => '値';

  @override
  String get vitalFormValidationValueEmpty => '値を入力してください。';

  @override
  String get vitalFormValidationBPFormat =>
      '血圧を「収縮期/拡張期」で入力してください (例: 120/80)。';

  @override
  String get vitalFormValidationValueNumeric => '数値を入力してください。';

  @override
  String get vitalFormHintNotes => '例: 食後に測定';

  @override
  String get vitalFormButtonUpdate => 'バイタルを更新';

  @override
  String get vitalFormButtonSave => 'バイタルを保存';

  @override
  String get formErrorFailedToUpdateVital => 'バイタルサインの更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSaveVital => 'バイタルサインの保存に失敗しました。もう一度お試しください。';

  @override
  String get settingsUserProfileNotLoaded => 'ユーザープロファイルが読み込まれていません。';

  @override
  String get settingsDisplayNameCannotBeEmpty => '表示名は空にできません。';

  @override
  String get settingsProfileUpdatedSuccess => 'プロファイルが正常に更新されました。';

  @override
  String settingsErrorUpdatingProfile(String errorMessage) {
    return 'プロファイルの更新中にエラーが発生しました: $errorMessage';
  }

  @override
  String get settingsSelectElderFirstMedDef =>
      '薬剤定義を管理するには、まず高齢者プロファイルを選択してください。';

  @override
  String get settingsMedNameRequired => '薬剤名は必須です。';

  @override
  String get settingsMedDefaultTimeFormatError =>
      '無効な時刻形式です。HH:mm形式で入力してください (例: 09:00)。';

  @override
  String get settingsMedDefAddedSuccess => '薬剤定義が正常に追加されました。';

  @override
  String get settingsClearDataErrorElderOrUserMissing =>
      'データを消去できません: アクティブな高齢者またはユーザーがいません。';

  @override
  String get settingsClearDataErrorNotAdmin =>
      'あなたはこの高齢者のプロファイルの主要管理者ではありません。データは主要管理者のみが消去できます。';

  @override
  String settingsClearDataDialogTitle(String elderName) {
    return '$elderNameさんの全データを消去しますか？';
  }

  @override
  String get settingsClearDataDialogContent =>
      'この操作は元に戻せません。この高齢者に関連するすべての記録（薬剤、食事、バイタルなど）が削除されます。続行しますか？';

  @override
  String get settingsClearDataDialogConfirmButton => 'はい、全データを消去します';

  @override
  String settingsClearDataSuccess(String elderName) {
    return '$elderNameさんの全データが消去されました。';
  }

  @override
  String settingsClearDataErrorGeneric(String errorMessage) {
    return 'データの消去中にエラーが発生しました: $errorMessage';
  }

  @override
  String get languageNameEn => '英語 (English)';

  @override
  String get languageNameEs => 'スペイン語 (Español)';

  @override
  String get languageNameJa => '日本語';

  @override
  String get languageNameKo => '韓国語 (한국어)';

  @override
  String get languageNameZh => '中国語 (中文)';

  @override
  String get settingsTitleMyAccount => 'マイアカウント';

  @override
  String get settingsLabelDisplayName => '表示名';

  @override
  String get settingsHintDisplayName => '表示名を入力';

  @override
  String get settingsLabelDOB => '生年月日';

  @override
  String get settingsHintDOB => '生年月日を選択';

  @override
  String get settingsButtonSaveProfile => 'プロファイルを保存';

  @override
  String get settingsButtonSignOut => 'サインアウト';

  @override
  String get settingsErrorLoadingProfile => 'プロファイルの読み込み中にエラーが発生しました。';

  @override
  String get settingsTitleLanguage => '言語設定';

  @override
  String get settingsLabelSelectLanguage => 'アプリの言語を選択';

  @override
  String settingsLanguageChangedConfirmation(String languageTag) {
    return '言語が$languageTagに変更されました。';
  }

  @override
  String get settingsTitleElderProfileManagement => '高齢者プロファイル管理';

  @override
  String settingsCurrentElder(String elderName) {
    return '現在アクティブな高齢者: $elderNameさん';
  }

  @override
  String get settingsNoActiveElderSelected =>
      'アクティブな高齢者が選択されていません。選択または作成してください。';

  @override
  String get settingsErrorNavToManageElderProfiles =>
      '高齢者プロファイル管理に移動できませんでした。ユーザーがログインしていません。';

  @override
  String get settingsButtonManageElderProfiles => '高齢者プロファイルを管理';

  @override
  String settingsTitleAdminActions(String elderName) {
    return '$elderNameさんの管理者アクション';
  }

  @override
  String get settingsButtonClearAllData => 'この高齢者の全データを消去';

  @override
  String get settingsTitleMedicationDefinitions => '薬剤定義';

  @override
  String get settingsSubtitleAddNewMedDef => '新しい薬剤定義を追加:';

  @override
  String get settingsLabelMedName => '薬剤名';

  @override
  String get settingsHintMedName => '例: リシノプリル';

  @override
  String get settingsLabelMedDose => 'デフォルト用量 (任意)';

  @override
  String get settingsHintMedDose => '例: 10mg、1錠';

  @override
  String get settingsLabelMedDefaultTime => 'デフォルト時刻 (HH:mm, 任意)';

  @override
  String get settingsHintMedDefaultTime => '例: 08:00';

  @override
  String get settingsButtonAddMedDef => '薬剤定義を追加';

  @override
  String get settingsSelectElderToAddMedDefs =>
      '薬剤定義を追加するには高齢者プロファイルを選択してください。';

  @override
  String get settingsSelectElderToViewMedDefs =>
      '薬剤定義を表示するには高齢者プロファイルを選択してください。';

  @override
  String settingsNoMedDefsForElder(String elderName) {
    return '$elderNameさんの薬剤定義は見つかりませんでした。';
  }

  @override
  String settingsExistingMedDefsForElder(String elderNameOrFallback) {
    return '$elderNameOrFallbackの既存の定義:';
  }

  @override
  String get settingsSelectedElderFallback => '選択された高齢者';

  @override
  String settingsMedDefDosePrefix(String dose) {
    return '用量: $dose';
  }

  @override
  String settingsMedDefDefaultTimePrefix(String time) {
    return '時刻: $time';
  }

  @override
  String get settingsTooltipDeleteMedDef => 'この薬剤定義を削除';

  @override
  String settingsDeleteMedDefDialogTitle(String medName) {
    return '「$medName」の定義を削除しますか？';
  }

  @override
  String get settingsDeleteMedDefDialogContent =>
      'この薬剤定義を削除してもよろしいですか？過去の投薬記録には影響しませんが、今後の記録のオプションからは削除されます。';

  @override
  String settingsMedDefDeletedSuccess(String medName) {
    return '薬剤定義「$medName」が削除されました。';
  }

  @override
  String get errorNotLoggedIn => 'エラー: ユーザーがログインしていません。';

  @override
  String get errorElderIdMissing => 'エラー: 高齢者IDがありません。';

  @override
  String profileUpdatedSnackbar(String profileName) {
    return '$profileNameさんのプロファイルが更新されました。';
  }

  @override
  String profileCreatedSnackbar(String profileName) {
    return '$profileNameさんのプロファイルが作成されました。';
  }

  @override
  String errorSavingProfile(String errorMessage) {
    return 'プロファイルの保存中にエラーが発生しました: $errorMessage';
  }

  @override
  String get errorSelectElderAndEmail => '高齢者プロファイルを選択し、有効なメールアドレスを入力してください。';

  @override
  String invitationSentSnackbar(String email) {
    return '$emailに招待を送信しました。';
  }

  @override
  String errorSendingInvitation(String errorMessage) {
    return '招待の送信中にエラーが発生しました: $errorMessage';
  }

  @override
  String get removeCaregiverDialogTitle => '介護者を削除しますか？';

  @override
  String removeCaregiverDialogContent(String caregiverIdentifier) {
    return '$caregiverIdentifierをこの高齢者の介護者から削除してもよろしいですか？';
  }

  @override
  String caregiverRemovedSnackbar(String caregiverIdentifier) {
    return '介護者$caregiverIdentifierが削除されました。';
  }

  @override
  String errorRemovingCaregiver(String errorMessage) {
    return '介護者の削除中にエラーが発生しました: $errorMessage';
  }

  @override
  String get tooltipEditProfile => 'プロファイルを編集';

  @override
  String get dobLabelPrefix => '生年月日:';

  @override
  String get allergiesLabelPrefix => 'アレルギー:';

  @override
  String get dietLabelPrefix => '食事制限:';

  @override
  String get primaryAdminLabel => '主要管理者:';

  @override
  String get adminNotAssigned => '未割り当て';

  @override
  String get loadingAdminInfo => '管理者情報を読み込み中...';

  @override
  String caregiversLabel(int count) {
    return '介護者 ($count名):';
  }

  @override
  String get noCaregiversYet => 'まだ介護者はいません。';

  @override
  String get errorLoadingCaregiverNames => '介護者名の読み込み中にエラーが発生しました。';

  @override
  String get caregiverAdminSuffix => '(管理者)';

  @override
  String tooltipRemoveCaregiver(String identifier) {
    return '$identifierを削除';
  }

  @override
  String profileSetActiveSnackbar(String profileName) {
    return '$profileNameさんがアクティブなプロファイルになりました。';
  }

  @override
  String inviteDialogTitle(String profileName) {
    return '$profileNameさんのプロファイルに介護者を招待';
  }

  @override
  String get caregiversEmailLabel => '介護者のメールアドレス';

  @override
  String get enterEmailHint => 'メールアドレスを入力';

  @override
  String get createElderProfileTitle => '新しい高齢者プロファイルを作成';

  @override
  String editProfileTitle(String profileNameOrFallback) {
    return '$profileNameOrFallbackを編集';
  }

  @override
  String get profileNameLabel => 'プロファイル名';

  @override
  String get validatorPleaseEnterName => '名前を入力してください。';

  @override
  String get dateOfBirthLabel => '生年月日';

  @override
  String get allergiesLabel => 'アレルギー (カンマ区切り)';

  @override
  String get dietaryRestrictionsLabel => '食事制限 (カンマ区切り)';

  @override
  String get createNewProfileButton => '新しいプロファイルを作成';

  @override
  String get saveChangesButton => '変更を保存';

  @override
  String get errorPrefix => 'エラー: ';

  @override
  String get noElderProfilesFound => '高齢者プロファイルが見つかりません。';

  @override
  String get createNewProfileOrWait => '新しいプロファイルを作成するか、招待をお待ちください。';

  @override
  String get fabNewProfile => '新規プロファイル';

  @override
  String get activityTypeWalk => '散歩';

  @override
  String get activityTypeExercise => '運動';

  @override
  String get activityTypePhysicalTherapy => '理学療法';

  @override
  String get activityTypeOccupationalTherapy => '作業療法';

  @override
  String get activityTypeOuting => '外出';

  @override
  String get activityTypeSocialVisit => '訪問';

  @override
  String get activityTypeReading => '読書';

  @override
  String get activityTypeTV => 'テレビ/映画鑑賞';

  @override
  String get activityTypeGardening => '園芸';

  @override
  String get assistanceLevelIndependent => '自立';

  @override
  String get assistanceLevelStandbyAssist => '見守り支援';

  @override
  String get assistanceLevelWithWalker => '歩行器使用';

  @override
  String get assistanceLevelWithCane => '杖使用';

  @override
  String get assistanceLevelWheelchair => '車椅子';

  @override
  String get assistanceLevelMinAssist => '最小介助 (Min A)';

  @override
  String get assistanceLevelModAssist => '中等度介助 (Mod A)';

  @override
  String get assistanceLevelMaxAssist => '最大介助 (Max A)';

  @override
  String get formErrorFailedToUpdateActivity =>
      'アクティビティの更新に失敗しました。もう一度お試しください。';

  @override
  String get formErrorFailedToSaveActivity => 'アクティビティの保存に失敗しました。もう一度お試しください。';

  @override
  String get activityFormTitleEdit => 'アクティビティを編集';

  @override
  String get activityFormTitleNew => '新しいアクティビティを記録';

  @override
  String get activityFormLabelActivityType => 'アクティビティの種類';

  @override
  String get activityFormHintActivityType => 'アクティビティを選択または入力';

  @override
  String get activityFormValidationActivityType => 'アクティビティの種類を選択または指定してください。';

  @override
  String get activityFormLabelDuration => '時間 (任意)';

  @override
  String get activityFormHintDuration => '例: 30分、1時間';

  @override
  String get activityFormLabelAssistance => '介助レベル (任意)';

  @override
  String get activityFormHintAssistance => '介助レベルを選択';

  @override
  String get activityFormHintNotes => '例: 日差しを楽しんだ、公園まで歩いた';

  @override
  String get notApplicable => '該当なし';

  @override
  String careScreenWaterLog(String description) {
    return '水分: $description';
  }

  @override
  String careScreenMealLog(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String get careScreenMealGeneric => '食事';

  @override
  String careScreenWaterContext(String contextDetails) {
    return '状況: $contextDetails';
  }

  @override
  String careScreenNotes(String noteContent) {
    return 'メモ: $noteContent';
  }

  @override
  String careScreenLoggedBy(String userName) {
    return '記録者: $userName';
  }

  @override
  String get careScreenTooltipEditFoodWater => '食事/水分エントリを編集';

  @override
  String get careScreenTooltipDeleteFoodWater => '食事/水分エントリを削除';

  @override
  String get careScreenErrorMissingIdDelete => 'エラー: IDがないためエントリを削除できません。';

  @override
  String get careScreenErrorFailedToLoad => 'この日の記録の読み込みに失敗しました。もう一度お試しください。';

  @override
  String get careScreenButtonAddFoodWater => '食事/水分を追加';

  @override
  String get careScreenSectionTitleMoodBehavior => '気分と行動';

  @override
  String get careScreenNoMoodBehaviorLogged => 'この日の気分や行動の記録はありません。';

  @override
  String careScreenMood(String mood) {
    return '気分: $mood';
  }

  @override
  String careScreenMoodIntensity(String intensityLevel) {
    return '強度: $intensityLevel';
  }

  @override
  String get careScreenTooltipEditMood => '気分エントリを編集';

  @override
  String get careScreenTooltipDeleteMood => '気分エントリを削除';

  @override
  String get careScreenButtonAddMood => '気分/行動を追加';

  @override
  String get careScreenSectionTitlePain => '痛み';

  @override
  String get careScreenNoPainLogged => 'この日の痛みの記録はありません。';

  @override
  String careScreenPainLog(
      String location, String description, String intensityDetails) {
    return '痛み: $location - $description$intensityDetails';
  }

  @override
  String careScreenPainIntensity(String intensityValue) {
    return '強度: $intensityValue';
  }

  @override
  String get careScreenTooltipEditPain => '痛みエントリを編集';

  @override
  String get careScreenTooltipDeletePain => '痛みエントリを削除';

  @override
  String get careScreenButtonAddPain => '痛みの記録を追加';

  @override
  String get careScreenSectionTitleActivity => 'アクティビティ';

  @override
  String get careScreenNoActivitiesLogged => 'この日のアクティビティの記録はありません。';

  @override
  String get careScreenUnknownActivity => '不明なアクティビティ';

  @override
  String careScreenActivityDuration(String duration) {
    return '時間: $duration';
  }

  @override
  String careScreenActivityAssistance(String assistanceLevel) {
    return '介助: $assistanceLevel';
  }

  @override
  String get careScreenTooltipEditActivity => 'アクティビティエントリを編集';

  @override
  String get careScreenTooltipDeleteActivity => 'アクティビティエントリを削除';

  @override
  String get careScreenButtonAddActivity => 'アクティビティを追加';

  @override
  String get careScreenSectionTitleVitals => 'バイタルサイン';

  @override
  String get careScreenNoVitalsLogged => 'この日のバイタルサインの記録はありません。';

  @override
  String careScreenVitalLog(String vitalType, String value, String unit) {
    return '$vitalType: $value $unit';
  }

  @override
  String get careScreenTooltipEditVital => 'バイタルサインエントリを編集';

  @override
  String get careScreenTooltipDeleteVital => 'バイタルサインエントリを削除';

  @override
  String get careScreenButtonAddVital => 'バイタルサインを追加';

  @override
  String get careScreenSectionTitleExpenses => '経費';

  @override
  String get careScreenNoExpensesLogged => 'この日の経費の記録はありません。';

  @override
  String careScreenExpenseLog(String description, String amount) {
    return '$description: ¥$amount';
  }

  @override
  String careScreenExpenseCategory(String category, String noteDetails) {
    return 'カテゴリ: $category$noteDetails';
  }

  @override
  String get careScreenTooltipEditExpense => '経費エントリを編集';

  @override
  String get careScreenTooltipDeleteExpense => '経費エントリを削除';

  @override
  String get careScreenButtonAddExpense => '経費を追加';

  @override
  String get calendarErrorLoadEvents => 'カレンダーイベントの読み込みに失敗しました。もう一度お試しください。';

  @override
  String get calendarErrorUserNotLoggedIn =>
      'エラー: ユーザーがログインしていません。カレンダーイベントを読み込めません。';

  @override
  String get calendarErrorEditMissingId => 'エラー: IDがないためイベントを編集できません。';

  @override
  String get calendarErrorEditPermission => 'エラー: このイベントを編集する権限がありません。';

  @override
  String get calendarErrorUpdateOriginalMissing =>
      'エラー: 更新のための元のイベントデータがありません。';

  @override
  String get calendarErrorUpdatePermission => 'エラー: このイベントを更新する権限がありません。';

  @override
  String get calendarEventAddedSuccess => 'イベントが正常に追加されました。';

  @override
  String get calendarEventUpdatedSuccess => 'イベントが正常に更新されました。';

  @override
  String calendarErrorSaveEvent(String errorMessage) {
    return 'イベントの保存中にエラーが発生しました: $errorMessage';
  }

  @override
  String get calendarErrorDeleteMissingId => 'エラー: IDがないためイベントを削除できません。';

  @override
  String get calendarErrorDeletePermission => 'エラー: このイベントを削除する権限がありません。';

  @override
  String get calendarConfirmDeleteTitle => '削除の確認';

  @override
  String calendarConfirmDeleteContent(String eventTitle) {
    return 'イベント「$eventTitle」を削除してもよろしいですか？';
  }

  @override
  String get calendarUntitledEvent => '無題のイベント';

  @override
  String get eventDeletedSuccess => 'イベントが正常に削除されました。';

  @override
  String get errorCouldNotDeleteEvent => 'エラー: イベントを削除できませんでした。';

  @override
  String get calendarNoElderSelected => '高齢者が選択されていません。カレンダーを表示する高齢者を選択してください。';

  @override
  String get calendarAddNewEventButton => '新しいイベントを追加';

  @override
  String calendarEventsOnDate(String formattedDate) {
    return '$formattedDateのイベント:';
  }

  @override
  String get calendarNoEventsScheduled => 'この日には予定されているイベントはありません。';

  @override
  String get calendarTooltipEditEvent => 'イベントを編集';

  @override
  String get calendarEventTypePrefix => '種類:';

  @override
  String get calendarEventTimePrefix => '時間:';

  @override
  String get calendarEventNotesPrefix => 'メモ:';

  @override
  String get expenseUncategorized => '未分類';

  @override
  String expenseErrorProcessingData(String errorMessage) {
    return '経費データの処理中にエラーが発生しました: $errorMessage';
  }

  @override
  String expenseErrorFetching(String errorMessage) {
    return '経費の取得中にエラーが発生しました: $errorMessage';
  }

  @override
  String get expenseUnknownUser => '不明なユーザー';

  @override
  String get expenseSelectElderPrompt => '経費を表示するには高齢者プロファイルを選択してください。';

  @override
  String get expenseLoading => '経費を読み込み中...';

  @override
  String get expenseScreenTitle => '経費';

  @override
  String expenseForElder(String elderName) {
    return '$elderNameさんの経費';
  }

  @override
  String get expensePrevWeekButton => '前の週';

  @override
  String get expenseNextWeekButton => '次の週';

  @override
  String get expenseNoExpensesThisWeek => '今週記録された経費はありません。';

  @override
  String get expenseSummaryByCategoryTitle => 'カテゴリ別概要 (今週)';

  @override
  String get expenseNoExpensesInCategoryThisWeek => '選択した週のこのカテゴリには経費がありません。';

  @override
  String get expenseWeekTotalLabel => '週合計:';

  @override
  String get expenseDetailedByUserTitle => '詳細経費 (今週 - ユーザー別)';

  @override
  String expenseCategoryLabel(String categoryName) {
    return 'カテゴリ: $categoryName';
  }

  @override
  String get errorEnterEmailPassword => 'メールアドレスとパスワードの両方を入力してください。';

  @override
  String get errorLoginFailedDefault =>
      'ログインに失敗しました。認証情報を確認するか、ネットワーク接続を確認してください。';

  @override
  String get loginScreenTitle => 'セシリアケアへようこそ';

  @override
  String get settingsLabelRelationshipToElder => 'ケア対象者との関係';

  @override
  String get settingsHintRelationshipToElder => '例: 息子/娘、配偶者、介護者';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get emailHint => 'メールアドレスを入力';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get dontHaveAccountSignUp => 'アカウントをお持ちではありませんか？ サインアップ';

  @override
  String get signUpNotImplemented => 'サインアップ機能はまだ実装されていません。';

  @override
  String get homeScreenBaseTitleTimeline => 'タイムライン';

  @override
  String homeScreenBaseTitleCareLog(String term) {
    return '$termのケア記録';
  }

  @override
  String homeScreenBaseTitleCalendar(String term) {
    return '$termのカレンダー';
  }

  @override
  String get homeScreenBaseTitleExpenses => '経費';

  @override
  String get homeScreenBaseTitleSettings => '設定';

  @override
  String get mustBeLoggedInToAddData => 'データを追加するにはログインする必要があります。';

  @override
  String get mustBeLoggedInToUpdateData => 'データを更新するにはログインする必要があります。';

  @override
  String selectTermToViewCareLog(String term) {
    return 'ケア記録を表示するには、$termを選択してください。';
  }

  @override
  String get selectElderToViewCareLog => 'ケア記録を表示するにはケア対象者を選択してください。';

  @override
  String get goToSettingsButton => '設定へ移動';

  @override
  String selectTermToViewCalendar(String term) {
    return 'カレンダーを表示するには、$termを選択してください。';
  }

  @override
  String get bottomNavTimeline => 'タイムライン';

  @override
  String bottomNavCareLog(Object term) {
    return '$termの記録';
  }

  @override
  String bottomNavCalendar(Object term) {
    return '$termのカレンダー';
  }

  @override
  String get bottomNavExpenses => '経費';

  @override
  String get bottomNavSettings => '設定';

  @override
  String get timelineUnknownTime => '不明な時間';

  @override
  String get timelineInvalidTime => '無効な時間';

  @override
  String get timelineMustBeLoggedInToPost => 'メッセージを投稿するにはログインする必要があります。';

  @override
  String get timelineSelectElderToPost =>
      'タイムラインに投稿するには、アクティブな高齢者プロファイルを選択してください。';

  @override
  String get timelineAnonymousUser => '匿名';

  @override
  String timelineCouldNotPostMessage(String errorMessage) {
    return 'メッセージを投稿できませんでした: $errorMessage';
  }

  @override
  String get timelinePleaseLogInToView => 'タイムラインを表示するにはログインしてください。';

  @override
  String get timelineSelectElderToView => 'タイムラインを表示するには高齢者プロファイルを選択してください。';

  @override
  String timelineWriteMessageHint(String elderName) {
    return '$elderNameさんのタイムラインにメッセージを書いてください...';
  }

  @override
  String get timelineUnknownUser => '不明なユーザー';

  @override
  String get timelinePostButton => '投稿';

  @override
  String get timelineCancelButton => 'キャンセル';

  @override
  String get timelinePostMessageToTimelineButton => 'タイムラインにメッセージを投稿';

  @override
  String get timelineLoading => 'タイムラインを読み込み中...';

  @override
  String timelineErrorLoading(String errorMessage) {
    return 'タイムラインの読み込みエラー: $errorMessage';
  }

  @override
  String timelineNoEntriesYet(String elderName) {
    return '$elderNameさんのエントリはまだありません。最初に投稿しましょう！';
  }

  @override
  String get timelineItemTitleMessage => 'メッセージ';

  @override
  String get timelineEmptyMessage => '[空のメッセージ]';

  @override
  String get timelineItemTitleMedication => '投薬';

  @override
  String get timelineItemTitleSleep => '睡眠';

  @override
  String get timelineItemTitleMeal => '食事';

  @override
  String get timelineItemTitleMood => '気分';

  @override
  String get timelineItemTitlePain => '痛み';

  @override
  String get timelineItemTitleActivity => 'アクティビティ';

  @override
  String get timelineItemTitleVital => 'バイタルサイン';

  @override
  String get timelineItemTitleExpense => '経費';

  @override
  String get timelineItemTitleEntry => 'エントリ';

  @override
  String get timelineNoDetailsProvided => '詳細は提供されていません。';

  @override
  String timelineLoggedBy(String userName) {
    return '$userNameによる記録';
  }

  @override
  String timelineErrorRenderingItem(String index, String errorDetails) {
    return 'インデックス$indexのアイテムのレンダリングエラー: $errorDetails';
  }

  @override
  String get timelineSummaryDetailsUnavailable => '詳細利用不可';

  @override
  String get timelineSummaryNotApplicable => '該当なし';

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
  String get timelineSummaryMedicationStatusTaken => '服用済み';

  @override
  String get timelineSummaryMedicationStatusNotTaken => '未服用';

  @override
  String get timelineSummaryMealTypeGeneric => '食事';

  @override
  String timelineSummarySleepQualityFormat(String quality) {
    return '質: $quality';
  }

  @override
  String timelineSummarySleepFormat(
      String wentToBed, String wokeUp, String quality) {
    return '就寝: $wentToBed, 起床: $wokeUp. $quality';
  }

  @override
  String timelineSummaryMealFormat(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String timelineSummaryMoodNotesFormat(String notes) {
    return '(メモ: $notes)';
  }

  @override
  String timelineSummaryMoodFormat(String mood, String notes) {
    return '気分: $mood $notes';
  }

  @override
  String timelineSummaryPainLocationFormat(String location) {
    return '$locationにて';
  }

  @override
  String timelineSummaryPainFormat(String level, String location) {
    return '痛みのレベル: $level/10 $location';
  }

  @override
  String timelineSummaryActivityDurationFormat(String duration) {
    return '$duration間';
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
    return '血圧: $systolic/$diastolic mmHg';
  }

  @override
  String timelineSummaryVitalFormatHR(String heartRate) {
    return '心拍数: $heartRate bpm';
  }

  @override
  String timelineSummaryVitalFormatTemp(String temperature) {
    return '体温: $temperature°';
  }

  @override
  String timelineSummaryVitalNote(String note) {
    return 'メモ: $note';
  }

  @override
  String get timelineSummaryVitalsRecorded => 'バイタルサイン記録済み';

  @override
  String timelineSummaryExpenseDescriptionFormat(String description) {
    return '($description)';
  }

  @override
  String timelineSummaryExpenseFormat(
      String category, String amount, String description) {
    return '$category: ¥$amount $description';
  }

  @override
  String get timelineSummaryErrorProcessing => 'タイムラインの詳細処理エラー。';

  @override
  String get timelineItemTitleImage => 'Image Uploaded';

  @override
  String timelineSummaryImageFormat(Object title) {
    return 'Image: $title';
  }

  @override
  String get careScreenErrorMissingIdGeneral => 'エラー: アイテムIDがありません。続行できません。';

  @override
  String get careScreenErrorEditPermission => 'エラー: このアイテムを編集する権限がありません。';

  @override
  String get careScreenErrorUpdateMedStatus => '投薬状況の更新エラー。もう一度お試しください。';

  @override
  String get careScreenLoadingRecords => '今日の記録を読み込み中...';

  @override
  String get careScreenErrorNoRecords => 'この日の記録が見つからないか、エラーが発生しました。';

  @override
  String get careScreenSectionTitleMeds => '投薬';

  @override
  String get careScreenNoMedsLogged => 'この日の投薬記録はありません。';

  @override
  String get careScreenUnknownMedication => '不明な薬剤';

  @override
  String get careScreenTooltipEditMed => '投薬エントリを編集';

  @override
  String get careScreenTooltipDeleteMed => '投薬エントリを削除';

  @override
  String get careScreenButtonAddMed => '投薬を追加';

  @override
  String get careScreenSectionTitleSleep => '睡眠';

  @override
  String get careScreenNoSleepLogged => 'この日の睡眠記録はありません。';

  @override
  String careScreenSleepTimeRange(String wentToBed, String wokeUp) {
    return '$wentToBed - $wokeUp';
  }

  @override
  String careScreenSleepQuality(String quality, String duration) {
    return '質: $quality $duration';
  }

  @override
  String careScreenSleepNaps(String naps) {
    return '昼寝: $naps';
  }

  @override
  String get careScreenTooltipEditSleep => '睡眠エントリを編集';

  @override
  String get careScreenTooltipDeleteSleep => '睡眠エントリを削除';

  @override
  String get careScreenButtonAddSleep => '睡眠を追加';

  @override
  String get careScreenSectionTitleFoodWater => '食事と水分摂取';

  @override
  String get careScreenNoFoodWaterLogged => 'この日の食事または水分摂取の記録はありません。';

  @override
  String errorEnterValidEmailPasswordMinLength(int minLength) {
    return '有効なメールアドレスとパスワード（最低$minLength文字）を入力してください。';
  }

  @override
  String get errorSignUpFailedDefault => '登録に失敗しました。もう一度試すか、ネットワーク接続を確認してください。';

  @override
  String get signUpScreenTitle => 'アカウント作成';

  @override
  String get createAccountTitle => 'アカウントを作成';

  @override
  String get signUpButton => '登録する';

  @override
  String get termElderDefault => 'ケア対象者';

  @override
  String get formErrorGenericSaveUpdate => '保存または更新中にエラーが発生しました。もう一度お試しください。';

  @override
  String get formSuccessActivitySaved => 'アクティビティが正常に保存されました。';

  @override
  String get formSuccessActivityUpdated => 'アクティビティが正常に更新されました。';

  @override
  String get formSuccessExpenseSaved => '経費が正常に保存されました。';

  @override
  String get formSuccessExpenseUpdated => '経費が正常に更新されました。';

  @override
  String get formSuccessMealSaved => '食事が正常に保存されました。';

  @override
  String get formSuccessMealUpdated => '食事が正常に更新されました。';

  @override
  String get formSuccessMedSaved => '投薬が正常に保存されました。';

  @override
  String get formSuccessMedUpdated => '投薬が正常に更新されました。';

  @override
  String get formSuccessMoodSaved => '気分が正常に保存されました。';

  @override
  String get formSuccessMoodUpdated => '気分が正常に更新されました。';

  @override
  String get formSuccessPainSaved => '痛みの記録が正常に保存されました。';

  @override
  String get formSuccessPainUpdated => '痛みの記録が正常に更新されました。';

  @override
  String get formSuccessSleepSaved => '睡眠記録が正常に保存されました。';

  @override
  String get formSuccessSleepUpdated => '睡眠記録が正常に更新されました。';

  @override
  String get formSuccessVitalSaved => 'バイタルサインが正常に保存されました。';

  @override
  String get formSuccessVitalUpdated => 'バイタルサインが正常に更新されました。';

  @override
  String get formErrorNoItemToDelete => '削除する項目がありません。';

  @override
  String get formConfirmDeleteTitle => '削除の確認';

  @override
  String get formConfirmDeleteVitalMessage => 'このバイタルサイン記録を削除してもよろしいですか？';

  @override
  String get formSuccessVitalDeleted => 'バイタルサイン記録が削除されました。';

  @override
  String get formErrorFailedToDeleteVital => 'バイタルサイン記録の削除に失敗しました。';

  @override
  String get formTooltipDeleteVital => 'バイタルサインを削除';

  @override
  String get formConfirmDeleteMealMessage => 'この食事記録を削除してもよろしいですか？';

  @override
  String get formSuccessMealDeleted => '食事記録が削除されました。';

  @override
  String get formErrorFailedToDeleteMeal => '食事記録の削除に失敗しました。';

  @override
  String get formTooltipDeleteMeal => '食事を削除';

  @override
  String get goToTodayButtonLabel => '今日へ';

  @override
  String get formConfirmDeleteMedMessage => 'この投薬記録を削除してもよろしいですか？';

  @override
  String get formSuccessMedDeleted => '投薬記録が削除されました。';

  @override
  String get formErrorFailedToDeleteMed => '投薬記録の削除に失敗しました。';

  @override
  String get formTooltipDeleteMed => '投薬を削除';

  @override
  String get formConfirmDeleteMoodMessage => 'この気分記録を削除してもよろしいですか？';

  @override
  String get formSuccessMoodDeleted => '気分記録が削除されました。';

  @override
  String get formErrorFailedToDeleteMood => '気分記録の削除に失敗しました。';

  @override
  String get formTooltipDeleteMood => '気分を削除';

  @override
  String get formConfirmDeletePainMessage => 'この痛みの記録を削除してもよろしいですか？';

  @override
  String get formSuccessPainDeleted => '痛みの記録が削除されました。';

  @override
  String get formErrorFailedToDeletePain => '痛みの記録の削除に失敗しました。';

  @override
  String get formTooltipDeletePain => '痛みを削除';

  @override
  String get formConfirmDeleteActivityMessage => 'このアクティビティ記録を削除してもよろしいですか？';

  @override
  String get formSuccessActivityDeleted => 'アクティビティ記録が削除されました。';

  @override
  String get formErrorFailedToDeleteActivity => 'アクティビティ記録の削除に失敗しました。';

  @override
  String get formTooltipDeleteActivity => 'アクティビティを削除';

  @override
  String get formConfirmDeleteSleepMessage => 'この睡眠記録を削除してもよろしいですか？';

  @override
  String get formSuccessSleepDeleted => '睡眠記録が削除されました。';

  @override
  String get formErrorFailedToDeleteSleep => '睡眠記録の削除に失敗しました。';

  @override
  String get formTooltipDeleteSleep => '睡眠を削除';

  @override
  String get formConfirmDeleteExpenseMessage => 'この経費記録を削除してもよろしいですか？';

  @override
  String get formSuccessExpenseDeleted => '経費記録が削除されました。';

  @override
  String get formErrorFailedToDeleteExpense => '経費記録の削除に失敗しました。';

  @override
  String get formTooltipDeleteExpense => '経費を削除';

  @override
  String get userSelectorSendToLabel => '送信先:';

  @override
  String get userSelectorAudienceAll => 'すべてのユーザー';

  @override
  String get userSelectorAudienceSpecific => '特定のユーザー';

  @override
  String get userSelectorNoUsersAvailable => '選択可能な他のユーザーがいません。';

  @override
  String get timelinePostingToAll => '投稿先: すべてのユーザー';

  @override
  String timelinePostingToCount(String count) {
    return '投稿先: $count人の特定ユーザー';
  }

  @override
  String get timelinePrivateMessageIndicator => 'プライベートメッセージ';

  @override
  String get timelineEditMessage => 'メッセージを編集';

  @override
  String get timelineDeleteMessage => 'メッセージを削除';

  @override
  String get timelineConfirmDeleteMessageTitle => 'メッセージを削除しますか？';

  @override
  String get timelineConfirmDeleteMessageContent => 'このメッセージを削除してもよろしいですか？';

  @override
  String get timelineMessageDeletedSuccess => 'メッセージが削除されました。';

  @override
  String timelineErrorDeletingMessage(String errorMessage) {
    return 'メッセージの削除中にエラーが発生しました: $errorMessage';
  }

  @override
  String get timelineMessageUpdatedSuccess => 'メッセージが更新されました。';

  @override
  String timelineErrorUpdatingMessage(String errorMessage) {
    return 'メッセージの更新中にエラーが発生しました: $errorMessage';
  }

  @override
  String get timelineUpdateButton => '更新';

  @override
  String get timelineHideMessage => 'メッセージを非表示';

  @override
  String get timelineMessageHiddenSuccess => 'メッセージが非表示になりました。';

  @override
  String get timelineShowHiddenMessagesButton => '非表示を表示';

  @override
  String get timelineHideHiddenMessagesButton => 'すべて表示';

  @override
  String get timelineUnhideMessage => 'メッセージを再表示';

  @override
  String get timelineMessageUnhiddenSuccess => 'メッセージが再表示されました。';

  @override
  String get timelineNoHiddenMessages => '非表示のメッセージはありません。';

  @override
  String get selfCareScreenTitle => 'セルフケア';

  @override
  String get settingsTitleNotificationPreferences => '通知設定';

  @override
  String get settingsItemNotificationPreferences => '通知の基本設定';

  @override
  String get landingPageAlreadyLoggedIn => 'すでにログインしています！';

  @override
  String get manageMedications => '薬剤管理';

  @override
  String get medicationsScreenTitleGeneric => '薬剤';

  @override
  String medicationsScreenTitleForElder(String name) {
    return '$nameさんの薬剤';
  }

  @override
  String get medicationsSearchHint => '薬剤名を検索';

  @override
  String get medicationsDoseHint => '例: 10mg';

  @override
  String get medicationsScheduleHint => '例: 午前/午後';

  @override
  String get medicationsListEmpty => '薬剤はまだ追加されていません';

  @override
  String get medicationsDoseNotSet => '用量が設定されていません';

  @override
  String get medicationsScheduleNotSet => 'スケジュールが設定されていません';

  @override
  String get medicationsTooltipDelete => '薬剤を削除';

  @override
  String medicationsConfirmDeleteTitle(String medName) {
    return '「$medName」を削除しますか？';
  }

  @override
  String get medicationsConfirmDeleteContent => 'この操作は元に戻せません。';

  @override
  String medicationsDeletedSuccess(String medName) {
    return '薬剤「$medName」が削除されました。';
  }

  @override
  String get rxNavGenericSearchError => '薬剤リストを取得できませんでした。もう一度お試しください。';

  @override
  String get medicationsValidationNameRequired => '名前が必要です';

  @override
  String get medicationsValidationDoseRequired => '用量が必要です';

  @override
  String get medicationsInteractionsFoundTitle => '相互作用の可能性が見つかりました';

  @override
  String get medicationsNoInteractionsFound => '相互作用は見つかりませんでした';

  @override
  String get medicationsInteractionsSaveAnyway => 'それでも保存しますか';

  @override
  String get medicationsAddDialogTitle => '薬剤を追加';

  @override
  String medicationsAddedSuccess(String medName) {
    return '薬剤「$medName」が追加されました。';
  }

  @override
  String get routeErrorGenericMessage => '問題が発生しました。もう一度お試しください。';

  @override
  String get goHomeButton => 'ホームへ戻る';

  @override
  String get settingsTitleHelpfulResources => '役立つリソース';

  @override
  String get settingsItemHelpfulResources => '役立つリソースを表示';

  @override
  String get timelineFilterOnlyMyLogs => '自分の記録のみ:';

  @override
  String get timelineFilterFromDate => '開始日';

  @override
  String get timelineFilterToDate => '終了日';

  @override
  String get medicationsInteractionsSectionTitle => '相互作用';

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
