// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Cecelia Care';

  @override
  String get loginButton => '登录';

  @override
  String get settingsTitle => '设置';

  @override
  String get languageSetting => '语言';

  @override
  String get manageElderProfilesTitle => '管理老人档案';

  @override
  String get createProfileButton => '创建个人资料';

  @override
  String get pleaseLogInToManageProfiles => '请登录以管理老人档案。';

  @override
  String calendarScreenTitle(String elderName) {
    return '$elderName的日历';
  }

  @override
  String get formOptionOther => '其他';

  @override
  String get formLabelNotesOptional => '备注 (可选)';

  @override
  String get cancelButton => '取消';

  @override
  String get updateButton => '更新';

  @override
  String get saveButton => '保存';

  @override
  String get okButton => '确定';

  @override
  String get deleteButton => '删除';

  @override
  String get removeButton => '移除';

  @override
  String get inviteButton => '邀请';

  @override
  String get activeButton => '当前活动';

  @override
  String get setActiveButton => '设为当前';

  @override
  String get sendInviteButton => '发送邀请';

  @override
  String get formUnknownUser => '未知用户';

  @override
  String get timePickerHelpText => '选择时间';

  @override
  String get expenseFormTitleEdit => '编辑费用';

  @override
  String get expenseFormTitleNew => '新增费用';

  @override
  String get expenseFormLabelDescription => '描述';

  @override
  String get expenseFormHintDescription => '例如：处方药补充';

  @override
  String get expenseFormValidationDescription => '请输入描述。';

  @override
  String get expenseFormLabelAmount => '金额';

  @override
  String get expenseFormHintAmount => '例如：25.50';

  @override
  String get expenseFormValidationAmountEmpty => '请输入金额。';

  @override
  String get expenseFormValidationAmountInvalid => '请输入有效的正数金额。';

  @override
  String get expenseFormLabelCategory => '类别';

  @override
  String get expenseCategoryMedical => '医疗';

  @override
  String get expenseCategoryGroceries => '杂货';

  @override
  String get expenseCategorySupplies => '用品';

  @override
  String get expenseCategoryHousehold => '家庭用品';

  @override
  String get expenseCategoryPersonalCare => '个人护理';

  @override
  String get expenseFormValidationCategory => '请选择一个类别。';

  @override
  String get expenseFormHintNotes => '在此处添加任何相关备注...';

  @override
  String get formErrorFailedToUpdateExpense => '更新费用失败。请重试。';

  @override
  String get formErrorFailedToSaveExpense => '保存费用失败。请重试。';

  @override
  String get mealFormTitleEdit => '编辑膳食/饮水记录';

  @override
  String get mealFormTitleNew => '记录膳食/饮水';

  @override
  String get mealFormLabelIntakeType => '摄入类型';

  @override
  String get mealFormIntakeCategoryFood => '食物';

  @override
  String get mealFormIntakeCategoryWater => '水';

  @override
  String get mealFormLabelMealType => '膳食类型';

  @override
  String get mealFormMealTypeBreakfast => '早餐';

  @override
  String get mealFormMealTypeLunch => '午餐';

  @override
  String get mealFormMealTypeSnack => '点心';

  @override
  String get mealFormMealTypeDinner => '晚餐';

  @override
  String get mealFormLabelDescription => '描述';

  @override
  String get mealFormHintFoodDescription => '例如：鸡汤、吐司';

  @override
  String get mealFormValidationFoodDescription => '请描述食物。';

  @override
  String get mealFormLabelWaterContext => '饮水情况 (可选)';

  @override
  String get mealFormHintWaterContext => '例如：服药时、口渴时';

  @override
  String get mealFormLabelWaterAmount => '量';

  @override
  String get mealFormHintWaterAmount => '例如：1杯、200毫升';

  @override
  String get mealFormValidationWaterAmount => '请指明饮水量。';

  @override
  String get mealFormHintFoodNotes => '例如：吃得很好，不喜欢胡萝卜';

  @override
  String get mealFormHintWaterNotes => '例如：喝得很慢';

  @override
  String get formErrorFailedToUpdateMeal => '更新膳食记录失败。请重试。';

  @override
  String get formErrorFailedToSaveMeal => '保存膳食记录失败。请重试。';

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
  String get medFormTitleEdit => '编辑药物记录';

  @override
  String get medFormTitleNew => '记录药物';

  @override
  String get medFormTimePickerHelpText => '选择用药时间';

  @override
  String get medFormLabelName => '药物名称';

  @override
  String get medFormHintNameCustom => '或输入自定义药物名称';

  @override
  String get medFormHintName => '输入药物名称';

  @override
  String get medFormValidationName => '请输入药物名称。';

  @override
  String get medFormLabelDose => '剂量 (可选)';

  @override
  String get medFormHintDose => '例如：1片、10毫克';

  @override
  String get medFormLabelTime => '时间 (可选)';

  @override
  String get medFormHintTime => '选择时间';

  @override
  String get medFormLabelMarkAsTaken => '标记为已服用';

  @override
  String get formErrorFailedToUpdateMed => '更新药物记录失败。请重试。';

  @override
  String get formErrorFailedToSaveMed => '保存药物记录失败。请重试。';

  @override
  String get moodFormTitleEdit => '编辑心情';

  @override
  String get moodFormTitleNew => '记录心情';

  @override
  String get moodHappy => '😊 开心';

  @override
  String get moodContent => '🙂 满足';

  @override
  String get moodSad => '😟 伤心';

  @override
  String get moodAnxious => '😬 焦虑';

  @override
  String get moodCalm => '😌 平静';

  @override
  String get moodIrritable => '😠 易怒';

  @override
  String get moodAgitated => '😫 烦躁';

  @override
  String get moodPlayful => '🥳 愉快';

  @override
  String get moodTired => '😴 疲倦';

  @override
  String get moodOptionOther => '📝 其他';

  @override
  String get moodFormLabelSelectMood => '选择心情';

  @override
  String get moodFormValidationSelectOrSpecifyMood => '请选择或指定一种心情。';

  @override
  String get moodFormValidationSpecifyOtherMood => '请指定心情。';

  @override
  String get moodFormHintSpecifyOtherMood => '描述心情...';

  @override
  String get moodFormLabelIntensity => '程度 (1-5, 可选)';

  @override
  String get moodFormHintIntensity => '1 (轻微) - 5 (严重)';

  @override
  String get moodFormValidationIntensityRange => '程度必须在1到5之间。';

  @override
  String get moodFormHintNotes => '例如：散步后感觉良好';

  @override
  String get moodFormButtonUpdate => '更新心情';

  @override
  String get moodFormButtonSave => '保存心情';

  @override
  String get formErrorFailedToUpdateMood => '更新心情失败。请重试。';

  @override
  String get formErrorFailedToSaveMood => '保存心情失败。请重试。';

  @override
  String get painFormTitleEdit => '编辑疼痛记录';

  @override
  String get painFormTitleNew => '记录疼痛';

  @override
  String get painTypeAching => '酸痛';

  @override
  String get painTypeBurning => '灼痛';

  @override
  String get painTypeDull => '隐痛';

  @override
  String get painTypeSharp => '锐痛';

  @override
  String get painTypeShooting => '放射痛';

  @override
  String get painTypeStabbing => '刺痛';

  @override
  String get painTypeThrobbing => '搏动性疼痛';

  @override
  String get painTypeTender => '压痛';

  @override
  String get painFormLabelLocation => '位置';

  @override
  String get painFormHintLocation => '例如：左膝、下背部';

  @override
  String get painFormValidationLocation => '请指明疼痛位置。';

  @override
  String get painFormLabelIntensity => '程度 (0-10)';

  @override
  String get painFormHintIntensity => '0 (无痛) - 10 (剧痛)';

  @override
  String get painFormValidationIntensityEmpty => '请输入疼痛程度。';

  @override
  String get painFormValidationIntensityRange => '程度必须在0到10之间。';

  @override
  String get painFormLabelDescription => '描述';

  @override
  String get painFormValidationSelectOrSpecifyDescription => '请选择或指定疼痛描述。';

  @override
  String get painFormValidationSpecifyOtherDescription => '请指定疼痛描述。';

  @override
  String get painFormHintSpecifyOtherDescription => '描述疼痛...';

  @override
  String get painFormHintNotes => '例如：活动后加重，休息后缓解';

  @override
  String get formErrorFailedToUpdatePain => '更新疼痛记录失败。请重试。';

  @override
  String get formErrorFailedToSavePain => '保存疼痛记录失败。请重试。';

  @override
  String get sleepFormTitleEdit => '编辑睡眠记录';

  @override
  String get sleepFormTitleNew => '记录睡眠';

  @override
  String get sleepQualityGood => '良好';

  @override
  String get sleepQualityFair => '一般';

  @override
  String get sleepQualityPoor => '差';

  @override
  String get sleepQualityRestless => '不安稳';

  @override
  String get sleepQualityInterrupted => '中断';

  @override
  String get sleepFormLabelWentToBed => '入睡时间';

  @override
  String get sleepFormHintTimeWentToBed => '选择时间';

  @override
  String get sleepFormValidationTimeWentToBed => '请选择入睡时间。';

  @override
  String get sleepFormLabelWokeUp => '起床时间 (可选)';

  @override
  String get sleepFormHintTimeWokeUp => '选择时间';

  @override
  String get sleepFormLabelTotalDuration => '总时长 (可选)';

  @override
  String get sleepFormHintTotalDuration => '例如：7小时、7小时30分钟';

  @override
  String get sleepFormLabelQuality => '质量';

  @override
  String get sleepFormValidationSelectQuality => '请选择睡眠质量。';

  @override
  String get sleepFormLabelDescribeOtherQuality => '描述其他质量';

  @override
  String get sleepFormHintDescribeOtherQuality => '描述睡眠质量...';

  @override
  String get sleepFormValidationDescribeOtherQuality => '请描述睡眠质量。';

  @override
  String get sleepFormLabelNaps => '午睡 (可选)';

  @override
  String get sleepFormHintNaps => '例如：1次、30分钟';

  @override
  String get sleepFormLabelGeneralNotes => '一般备注 (可选)';

  @override
  String get sleepFormHintGeneralNotes => '例如：醒来感觉神清气爽';

  @override
  String get sleepFormButtonUpdate => '更新睡眠';

  @override
  String get sleepFormButtonSave => '保存睡眠';

  @override
  String get formErrorFailedToUpdateSleep => '更新睡眠记录失败。请重试。';

  @override
  String get formErrorFailedToSaveSleep => '保存睡眠记录失败。请重试。';

  @override
  String get vitalFormTitleEdit => '编辑生命体征';

  @override
  String get vitalFormTitleNew => '记录生命体征';

  @override
  String get vitalTypeBPLabel => '血压';

  @override
  String get vitalTypeBPUnit => 'mmHg';

  @override
  String get vitalTypeBPPlaceholder => '例如：120/80';

  @override
  String get vitalTypeHRLabel => '心率';

  @override
  String get vitalTypeHRUnit => 'bpm';

  @override
  String get vitalTypeHRPlaceholder => '例如：70';

  @override
  String get vitalTypeWTLabel => '体重';

  @override
  String get vitalTypeWTUnit => '公斤/磅';

  @override
  String get vitalTypeWTPlaceholder => '例如：65公斤 或 143磅';

  @override
  String get vitalTypeBGLabel => '血糖';

  @override
  String get vitalTypeBGUnit => 'mg/dL 或 mmol/L';

  @override
  String get vitalTypeBGPlaceholder => '例如：90 mg/dL';

  @override
  String get vitalTypeTempLabel => '体温';

  @override
  String get vitalTypeTempUnit => '°C/°F';

  @override
  String get vitalTypeTempPlaceholder => '例如：36.5°C 或 97.7°F';

  @override
  String get vitalTypeO2Label => '血氧饱和度';

  @override
  String get vitalTypeO2Unit => '%';

  @override
  String get vitalTypeO2Placeholder => '例如：98';

  @override
  String get vitalFormLabelType => '类型';

  @override
  String get vitalFormLabelValue => '数值';

  @override
  String get vitalFormValidationValueEmpty => '请输入数值。';

  @override
  String get vitalFormValidationBPFormat => '请输入\'收缩压/舒张压\'格式的血压，例如：120/80。';

  @override
  String get vitalFormValidationValueNumeric => '请输入数字值。';

  @override
  String get vitalFormHintNotes => '例如：饭后测量';

  @override
  String get vitalFormButtonUpdate => '更新体征';

  @override
  String get vitalFormButtonSave => '保存体征';

  @override
  String get formErrorFailedToUpdateVital => '更新生命体征失败。请重试。';

  @override
  String get formErrorFailedToSaveVital => '保存生命体征失败。请重试。';

  @override
  String get settingsUserProfileNotLoaded => '用户个人资料未加载';

  @override
  String get settingsDisplayNameCannotBeEmpty => '显示名称不能为空';

  @override
  String get settingsProfileUpdatedSuccess => '个人资料更新成功';

  @override
  String settingsErrorUpdatingProfile(String errorMessage) {
    return '更新个人资料时出错：$errorMessage';
  }

  @override
  String get settingsSelectElderFirstMedDef => '请先选择老人档案以管理药物定义';

  @override
  String get settingsMedNameRequired => '药物名称为必填项';

  @override
  String get settingsMedDefaultTimeFormatError =>
      '无效的时间格式。请使用 HH:mm 格式 (例如：09:00)';

  @override
  String get settingsMedDefAddedSuccess => '药物定义添加成功';

  @override
  String get settingsClearDataErrorElderOrUserMissing => '无法清除数据：缺少当前老人或用户';

  @override
  String get settingsClearDataErrorNotAdmin => '您不是此老人档案的主要管理员。数据只能由主要管理员清除。';

  @override
  String settingsClearDataDialogTitle(String elderName) {
    return '清除 $elderName 的所有数据？';
  }

  @override
  String get settingsClearDataDialogContent =>
      '此操作不可逆，并将删除此老人的所有相关记录（药物、膳食、生命体征等）。您确定要继续吗？';

  @override
  String get settingsClearDataDialogConfirmButton => '是，清除所有数据';

  @override
  String settingsClearDataSuccess(String elderName) {
    return '$elderName 的所有数据已清除。';
  }

  @override
  String settingsClearDataErrorGeneric(String errorMessage) {
    return '清除数据时出错：$errorMessage';
  }

  @override
  String get languageNameEn => '英语 (English)';

  @override
  String get languageNameEs => '西班牙语 (Español)';

  @override
  String get languageNameJa => '日语 (日本語)';

  @override
  String get languageNameKo => '韩语 (한국어)';

  @override
  String get languageNameZh => '中文';

  @override
  String get settingsTitleMyAccount => '我的账户';

  @override
  String get settingsLabelDisplayName => '显示名称';

  @override
  String get settingsHintDisplayName => '输入您的显示名称';

  @override
  String get settingsLabelDOB => '出生日期';

  @override
  String get settingsHintDOB => '选择您的出生日期';

  @override
  String get settingsButtonSaveProfile => '保存个人资料';

  @override
  String get settingsButtonSignOut => '退出登录';

  @override
  String get settingsErrorLoadingProfile => '加载个人资料时出错。';

  @override
  String get settingsTitleLanguage => '语言设置';

  @override
  String get settingsLabelSelectLanguage => '选择应用语言';

  @override
  String settingsLanguageChangedConfirmation(String languageTag) {
    return '语言已更改为 $languageTag。';
  }

  @override
  String get settingsTitleElderProfileManagement => '老人档案管理';

  @override
  String settingsCurrentElder(String elderName) {
    return '当前活动老人：$elderName';
  }

  @override
  String get settingsNoActiveElderSelected => '未选择活动老人。请选择或创建一个。';

  @override
  String get settingsErrorNavToManageElderProfiles => '无法导航至老人档案管理。用户未登录。';

  @override
  String get settingsButtonManageElderProfiles => '管理老人档案';

  @override
  String settingsTitleAdminActions(String elderName) {
    return '$elderName 的管理操作';
  }

  @override
  String get settingsButtonClearAllData => '清除此老人的所有数据';

  @override
  String get settingsTitleMedicationDefinitions => '药物定义';

  @override
  String get settingsSubtitleAddNewMedDef => '添加新的药物定义：';

  @override
  String get settingsLabelMedName => '药物名称';

  @override
  String get settingsHintMedName => '例如：赖诺普利';

  @override
  String get settingsLabelMedDose => '默认剂量 (可选)';

  @override
  String get settingsHintMedDose => '例如：10毫克，1片';

  @override
  String get settingsLabelMedDefaultTime => '默认时间 (HH:mm, 可选)';

  @override
  String get settingsHintMedDefaultTime => '例如：08:00';

  @override
  String get settingsButtonAddMedDef => '添加药物定义';

  @override
  String get settingsSelectElderToAddMedDefs => '选择一个老人档案以添加药物定义。';

  @override
  String get settingsSelectElderToViewMedDefs => '选择一个老人档案以查看药物定义。';

  @override
  String settingsNoMedDefsForElder(String elderName) {
    return '未找到 $elderName 的药物定义。';
  }

  @override
  String settingsExistingMedDefsForElder(String elderNameOrFallback) {
    return '$elderNameOrFallback 的现有定义：';
  }

  @override
  String get settingsSelectedElderFallback => '已选老人';

  @override
  String settingsMedDefDosePrefix(String dose) {
    return '剂量：$dose';
  }

  @override
  String settingsMedDefDefaultTimePrefix(String time) {
    return '时间：$time';
  }

  @override
  String get settingsTooltipDeleteMedDef => '删除此药物定义';

  @override
  String settingsDeleteMedDefDialogTitle(String medName) {
    return '删除“$medName”定义？';
  }

  @override
  String get settingsDeleteMedDefDialogContent =>
      '您确定要删除此药物定义吗？这不会影响过去的药物记录，但会将其从未来记录的选项中移除。';

  @override
  String settingsMedDefDeletedSuccess(String medName) {
    return '药物定义“$medName”已删除。';
  }

  @override
  String get errorNotLoggedIn => '错误：用户未登录。';

  @override
  String get errorElderIdMissing => '错误：缺少老人ID。';

  @override
  String profileUpdatedSnackbar(String profileName) {
    return '$profileName 的个人资料已更新。';
  }

  @override
  String profileCreatedSnackbar(String profileName) {
    return '$profileName 的个人资料已创建。';
  }

  @override
  String errorSavingProfile(String errorMessage) {
    return '保存个人资料时出错：$errorMessage';
  }

  @override
  String get errorSelectElderAndEmail => '请选择一个老人档案并输入有效的电子邮件地址。';

  @override
  String invitationSentSnackbar(String email) {
    return '邀请已发送至 $email。';
  }

  @override
  String errorSendingInvitation(String errorMessage) {
    return '发送邀请时出错：$errorMessage';
  }

  @override
  String get removeCaregiverDialogTitle => '移除照护者？';

  @override
  String removeCaregiverDialogContent(String caregiverIdentifier) {
    return '您确定要将 $caregiverIdentifier 从此老人的照护者中移除吗？';
  }

  @override
  String caregiverRemovedSnackbar(String caregiverIdentifier) {
    return '照护者 $caregiverIdentifier 已移除。';
  }

  @override
  String errorRemovingCaregiver(String errorMessage) {
    return '移除照护者时出错：$errorMessage';
  }

  @override
  String get tooltipEditProfile => '编辑个人资料';

  @override
  String get dobLabelPrefix => '出生日期：';

  @override
  String get allergiesLabelPrefix => '过敏史：';

  @override
  String get dietLabelPrefix => '饮食：';

  @override
  String get primaryAdminLabel => '主要管理员：';

  @override
  String get adminNotAssigned => '未分配';

  @override
  String get loadingAdminInfo => '正在加载管理员信息...';

  @override
  String caregiversLabel(int count) {
    return '照护者 ($count名)：';
  }

  @override
  String get noCaregiversYet => '尚无照护者。';

  @override
  String get errorLoadingCaregiverNames => '加载照护者姓名时出错。';

  @override
  String get caregiverAdminSuffix => '(管理员)';

  @override
  String tooltipRemoveCaregiver(String identifier) {
    return '移除 $identifier';
  }

  @override
  String profileSetActiveSnackbar(String profileName) {
    return '$profileName 现在是活动的个人资料。';
  }

  @override
  String inviteDialogTitle(String profileName) {
    return '邀请照护者加入 $profileName 的个人资料';
  }

  @override
  String get caregiversEmailLabel => '照护者的电子邮件';

  @override
  String get enterEmailHint => '输入电子邮件地址';

  @override
  String get createElderProfileTitle => '创建新的老人档案';

  @override
  String editProfileTitle(String profileNameOrFallback) {
    return '编辑 $profileNameOrFallback';
  }

  @override
  String get profileNameLabel => '档案名称';

  @override
  String get validatorPleaseEnterName => '请输入名称。';

  @override
  String get dateOfBirthLabel => '出生日期';

  @override
  String get allergiesLabel => '过敏史 (逗号分隔)';

  @override
  String get dietaryRestrictionsLabel => '饮食限制 (逗号分隔)';

  @override
  String get createNewProfileButton => '创建新档案';

  @override
  String get saveChangesButton => '保存更改';

  @override
  String get errorPrefix => '错误：';

  @override
  String get noElderProfilesFound => '未找到老人档案。';

  @override
  String get createNewProfileOrWait => '创建新档案或等待邀请。';

  @override
  String get fabNewProfile => '新建档案';

  @override
  String get activityTypeWalk => '散步';

  @override
  String get activityTypeExercise => '锻炼';

  @override
  String get activityTypePhysicalTherapy => '物理治疗';

  @override
  String get activityTypeOccupationalTherapy => '作业治疗';

  @override
  String get activityTypeOuting => '外出';

  @override
  String get activityTypeSocialVisit => '社交访问';

  @override
  String get activityTypeReading => '阅读';

  @override
  String get activityTypeTV => '看电视/电影';

  @override
  String get activityTypeGardening => '园艺';

  @override
  String get assistanceLevelIndependent => '独立';

  @override
  String get assistanceLevelStandbyAssist => '备用协助';

  @override
  String get assistanceLevelWithWalker => '使用助行器';

  @override
  String get assistanceLevelWithCane => '使用拐杖';

  @override
  String get assistanceLevelWheelchair => '轮椅';

  @override
  String get assistanceLevelMinAssist => '最少协助 (Min A)';

  @override
  String get assistanceLevelModAssist => '中等协助 (Mod A)';

  @override
  String get assistanceLevelMaxAssist => '最大协助 (Max A)';

  @override
  String get formErrorFailedToUpdateActivity => '更新活动失败。请重试。';

  @override
  String get formErrorFailedToSaveActivity => '保存活动失败。请重试。';

  @override
  String get activityFormTitleEdit => '编辑活动';

  @override
  String get activityFormTitleNew => '记录新活动';

  @override
  String get activityFormLabelActivityType => '活动类型';

  @override
  String get activityFormHintActivityType => '选择或输入活动';

  @override
  String get activityFormValidationActivityType => '请选择或指定活动类型。';

  @override
  String get activityFormLabelDuration => '持续时间 (可选)';

  @override
  String get activityFormHintDuration => '例如：30分钟、1小时';

  @override
  String get activityFormLabelAssistance => '协助级别 (可选)';

  @override
  String get activityFormHintAssistance => '选择协助级别';

  @override
  String get activityFormHintNotes => '例如：享受了阳光，走到了公园';

  @override
  String get notApplicable => '不适用';

  @override
  String careScreenWaterLog(String description) {
    return '饮水：$description';
  }

  @override
  String careScreenMealLog(String mealType, String description) {
    return '$mealType：$description';
  }

  @override
  String get careScreenMealGeneric => '膳食';

  @override
  String careScreenWaterContext(String contextDetails) {
    return '情况：$contextDetails';
  }

  @override
  String careScreenNotes(String noteContent) {
    return '备注：$noteContent';
  }

  @override
  String careScreenLoggedBy(String userName) {
    return '记录人：$userName';
  }

  @override
  String get careScreenTooltipEditFoodWater => '编辑食物/饮水条目';

  @override
  String get careScreenTooltipDeleteFoodWater => '删除食物/饮水条目';

  @override
  String get careScreenErrorMissingIdDelete => '错误：无法删除条目，缺少ID。';

  @override
  String get careScreenErrorFailedToLoad => '加载当天记录失败。请重试。';

  @override
  String get careScreenButtonAddFoodWater => '添加食物/饮水';

  @override
  String get careScreenSectionTitleMoodBehavior => '心情与行为';

  @override
  String get careScreenNoMoodBehaviorLogged => '今日无心情或行为记录。';

  @override
  String careScreenMood(String mood) {
    return '心情：$mood';
  }

  @override
  String careScreenMoodIntensity(String intensityLevel) {
    return '程度：$intensityLevel';
  }

  @override
  String get careScreenTooltipEditMood => '编辑心情条目';

  @override
  String get careScreenTooltipDeleteMood => '删除心情条目';

  @override
  String get careScreenButtonAddMood => '添加心情/行为';

  @override
  String get careScreenSectionTitlePain => '疼痛';

  @override
  String get careScreenNoPainLogged => '今日无疼痛记录。';

  @override
  String careScreenPainLog(
      String location, String description, String intensityDetails) {
    return '疼痛：$location - $description$intensityDetails';
  }

  @override
  String careScreenPainIntensity(String intensityValue) {
    return '程度：$intensityValue';
  }

  @override
  String get careScreenTooltipEditPain => '编辑疼痛条目';

  @override
  String get careScreenTooltipDeletePain => '删除疼痛条目';

  @override
  String get careScreenButtonAddPain => '添加疼痛记录';

  @override
  String get careScreenSectionTitleActivity => '活动';

  @override
  String get careScreenNoActivitiesLogged => '今日无活动记录。';

  @override
  String get careScreenUnknownActivity => '未知活动';

  @override
  String careScreenActivityDuration(String duration) {
    return '时长：$duration';
  }

  @override
  String careScreenActivityAssistance(String assistanceLevel) {
    return '协助：$assistanceLevel';
  }

  @override
  String get careScreenTooltipEditActivity => '编辑活动条目';

  @override
  String get careScreenTooltipDeleteActivity => '删除活动条目';

  @override
  String get careScreenButtonAddActivity => '添加活动';

  @override
  String get careScreenSectionTitleVitals => '生命体征';

  @override
  String get careScreenNoVitalsLogged => '今日无生命体征记录。';

  @override
  String careScreenVitalLog(String vitalType, String value, String unit) {
    return '$vitalType：$value $unit';
  }

  @override
  String get careScreenTooltipEditVital => '编辑生命体征条目';

  @override
  String get careScreenTooltipDeleteVital => '删除生命体征条目';

  @override
  String get careScreenButtonAddVital => '添加生命体征';

  @override
  String get careScreenSectionTitleExpenses => '费用';

  @override
  String get careScreenNoExpensesLogged => '今日无费用记录。';

  @override
  String careScreenExpenseLog(String description, String amount) {
    return '$description：¥$amount';
  }

  @override
  String careScreenExpenseCategory(String category, String noteDetails) {
    return '类别：$category$noteDetails';
  }

  @override
  String get careScreenTooltipEditExpense => '编辑费用条目';

  @override
  String get careScreenTooltipDeleteExpense => '删除费用条目';

  @override
  String get careScreenButtonAddExpense => '添加费用';

  @override
  String get calendarErrorLoadEvents => '加载日历事件失败。请重试。';

  @override
  String get calendarErrorUserNotLoggedIn => '错误：用户未登录。无法加载日历事件。';

  @override
  String get calendarErrorEditMissingId => '错误：无法编辑事件，缺少ID。';

  @override
  String get calendarErrorEditPermission => '错误：您无权编辑此事件。';

  @override
  String get calendarErrorUpdateOriginalMissing => '错误：缺少用于更新的原始事件数据。';

  @override
  String get calendarErrorUpdatePermission => '错误：您无权更新此事件。';

  @override
  String get calendarEventAddedSuccess => '事件添加成功。';

  @override
  String get calendarEventUpdatedSuccess => '事件更新成功。';

  @override
  String calendarErrorSaveEvent(String errorMessage) {
    return '保存事件时出错：$errorMessage';
  }

  @override
  String get calendarErrorDeleteMissingId => '错误：无法删除事件，缺少ID。';

  @override
  String get calendarErrorDeletePermission => '错误：您无权删除此事件。';

  @override
  String get calendarConfirmDeleteTitle => '确认删除';

  @override
  String calendarConfirmDeleteContent(String eventTitle) {
    return '您确定要删除事件“$eventTitle”吗？';
  }

  @override
  String get calendarUntitledEvent => '无标题事件';

  @override
  String get eventDeletedSuccess => '事件删除成功。';

  @override
  String get errorCouldNotDeleteEvent => '错误：无法删除事件。';

  @override
  String get calendarNoElderSelected => '未选择老人。请选择一位老人以查看其日历。';

  @override
  String get calendarAddNewEventButton => '添加新事件';

  @override
  String calendarEventsOnDate(String formattedDate) {
    return '$formattedDate的事件：';
  }

  @override
  String get calendarNoEventsScheduled => '今日无预定事件。';

  @override
  String get calendarTooltipEditEvent => '编辑事件';

  @override
  String get calendarEventTypePrefix => '类型：';

  @override
  String get calendarEventTimePrefix => '时间：';

  @override
  String get calendarEventNotesPrefix => '备注：';

  @override
  String get expenseUncategorized => '未分类';

  @override
  String expenseErrorProcessingData(String errorMessage) {
    return '处理费用数据时出错：$errorMessage';
  }

  @override
  String expenseErrorFetching(String errorMessage) {
    return '获取费用时出错：$errorMessage';
  }

  @override
  String get expenseUnknownUser => '未知用户';

  @override
  String get expenseSelectElderPrompt => '请选择一个老人档案以查看费用。';

  @override
  String get expenseLoading => '正在加载费用...';

  @override
  String get expenseScreenTitle => '费用';

  @override
  String expenseForElder(String elderName) {
    return '$elderName的费用';
  }

  @override
  String get expensePrevWeekButton => '上一周';

  @override
  String get expenseNextWeekButton => '下一周';

  @override
  String get expenseNoExpensesThisWeek => '本周无费用记录。';

  @override
  String get expenseSummaryByCategoryTitle => '按类别汇总 (本周)';

  @override
  String get expenseNoExpensesInCategoryThisWeek => '所选周内此类别无费用。';

  @override
  String get expenseWeekTotalLabel => '本周总计：';

  @override
  String get expenseDetailedByUserTitle => '详细费用 (本周 - 按用户)';

  @override
  String expenseCategoryLabel(String categoryName) {
    return '类别：$categoryName';
  }

  @override
  String get errorEnterEmailPassword => '请输入电子邮件和密码。';

  @override
  String get errorLoginFailedDefault => '登录失败。请检查您的凭据或网络连接。';

  @override
  String get loginScreenTitle => '欢迎来到 Cecelia Care';

  @override
  String get settingsLabelRelationshipToElder => '与被照顾者的关系';

  @override
  String get settingsHintRelationshipToElder => '例如：儿子/女儿、配偶、照护者';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get emailHint => '请输入电子邮件地址';

  @override
  String get passwordLabel => '密码';

  @override
  String get dontHaveAccountSignUp => '没有账户？注册';

  @override
  String get signUpNotImplemented => '注册功能尚未实现。';

  @override
  String get homeScreenBaseTitleTimeline => '时间线';

  @override
  String homeScreenBaseTitleCareLog(String term) {
    return '$term护理日志';
  }

  @override
  String homeScreenBaseTitleCalendar(String term) {
    return '$term日历';
  }

  @override
  String get homeScreenBaseTitleExpenses => '费用';

  @override
  String get homeScreenBaseTitleSettings => '设置';

  @override
  String get mustBeLoggedInToAddData => '您必须登录才能添加数据。';

  @override
  String get mustBeLoggedInToUpdateData => '您必须登录才能更新数据。';

  @override
  String selectTermToViewCareLog(String term) {
    return '请选择一位$term以查看护理日志。';
  }

  @override
  String get selectElderToViewCareLog => '请选择一位被照顾者以查看护理日志。';

  @override
  String get goToSettingsButton => '前往设置';

  @override
  String selectTermToViewCalendar(String term) {
    return '请选择一位$term以查看日历。';
  }

  @override
  String get bottomNavTimeline => '时间线';

  @override
  String bottomNavCareLog(Object term) {
    return '$term日志';
  }

  @override
  String bottomNavCalendar(Object term) {
    return '$term日历';
  }

  @override
  String get bottomNavExpenses => '费用';

  @override
  String get bottomNavSettings => '设置';

  @override
  String get timelineUnknownTime => '未知时间';

  @override
  String get timelineInvalidTime => '无效时间';

  @override
  String get timelineMustBeLoggedInToPost => '您必须登录才能发布消息。';

  @override
  String get timelineSelectElderToPost => '请选择一个活动老人档案以发布到时间线。';

  @override
  String get timelineAnonymousUser => '匿名';

  @override
  String timelineCouldNotPostMessage(String errorMessage) {
    return '无法发布消息：$errorMessage';
  }

  @override
  String get timelinePleaseLogInToView => '请登录以查看时间线。';

  @override
  String get timelineSelectElderToView => '请选择一个老人档案以查看时间线。';

  @override
  String timelineWriteMessageHint(String elderName) {
    return '在 $elderName 的时间线上写一条消息...';
  }

  @override
  String get timelineUnknownUser => '未知用户';

  @override
  String get timelinePostButton => '发布';

  @override
  String get timelineCancelButton => '取消';

  @override
  String get timelinePostMessageToTimelineButton => '发布消息到时间线';

  @override
  String get timelineLoading => '正在加载时间线...';

  @override
  String timelineErrorLoading(String errorMessage) {
    return '加载时间线时出错：$errorMessage';
  }

  @override
  String timelineNoEntriesYet(String elderName) {
    return '$elderName 的时间线尚无条目。成为第一个发布的人吧！';
  }

  @override
  String get timelineItemTitleMessage => '消息';

  @override
  String get timelineEmptyMessage => '[空消息]';

  @override
  String get timelineItemTitleMedication => '药物';

  @override
  String get timelineItemTitleSleep => '睡眠';

  @override
  String get timelineItemTitleMeal => '膳食';

  @override
  String get timelineItemTitleMood => '心情';

  @override
  String get timelineItemTitlePain => '疼痛';

  @override
  String get timelineItemTitleActivity => '活动';

  @override
  String get timelineItemTitleVital => '生命体征';

  @override
  String get timelineItemTitleExpense => '费用';

  @override
  String get timelineItemTitleEntry => '条目';

  @override
  String get timelineNoDetailsProvided => '未提供详细信息。';

  @override
  String timelineLoggedBy(String userName) {
    return '记录人：$userName';
  }

  @override
  String timelineErrorRenderingItem(String index, String errorDetails) {
    return '渲染索引 $index 的条目时出错：$errorDetails';
  }

  @override
  String get timelineSummaryDetailsUnavailable => '详细信息不可用';

  @override
  String get timelineSummaryNotApplicable => '不适用';

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
  String get timelineSummaryMedicationStatusTaken => '已服用';

  @override
  String get timelineSummaryMedicationStatusNotTaken => '未服用';

  @override
  String get timelineSummaryMealTypeGeneric => '膳食';

  @override
  String timelineSummarySleepQualityFormat(String quality) {
    return '睡眠质量：$quality';
  }

  @override
  String timelineSummarySleepFormat(
      String wentToBed, String wokeUp, String quality) {
    return '入睡：$wentToBed，起床：$wokeUp。$quality';
  }

  @override
  String timelineSummaryMealFormat(String mealType, String description) {
    return '$mealType：$description';
  }

  @override
  String timelineSummaryMoodNotesFormat(String notes) {
    return '(备注：$notes)';
  }

  @override
  String timelineSummaryMoodFormat(String mood, String notes) {
    return '心情：$mood $notes';
  }

  @override
  String timelineSummaryPainLocationFormat(String location) {
    return '位置：$location';
  }

  @override
  String timelineSummaryPainFormat(String level, String location) {
    return '疼痛程度：$level/10 $location';
  }

  @override
  String timelineSummaryActivityDurationFormat(String duration) {
    return '$duration 的活动';
  }

  @override
  String timelineSummaryActivityFormat(String activityType, String duration) {
    return '$activityType $duration';
  }

  @override
  String timelineSummaryVitalFormatGeneric(
      String vitalType, String value, String unit) {
    return '$vitalType：$value $unit';
  }

  @override
  String timelineSummaryVitalFormatBP(String systolic, String diastolic) {
    return '血压：$systolic/$diastolic mmHg';
  }

  @override
  String timelineSummaryVitalFormatHR(String heartRate) {
    return '心率：$heartRate bpm';
  }

  @override
  String timelineSummaryVitalFormatTemp(String temperature) {
    return '体温：$temperature°';
  }

  @override
  String timelineSummaryVitalNote(String note) {
    return '备注：$note';
  }

  @override
  String get timelineSummaryVitalsRecorded => '记录的生命体征';

  @override
  String timelineSummaryExpenseDescriptionFormat(String description) {
    return '($description)';
  }

  @override
  String timelineSummaryExpenseFormat(
      String category, String amount, String description) {
    return '$category：¥$amount $description';
  }

  @override
  String get timelineSummaryErrorProcessing => '处理时间线详细信息时出错。';

  @override
  String get timelineItemTitleImage => 'Image Uploaded';

  @override
  String timelineSummaryImageFormat(Object title) {
    return 'Image: $title';
  }

  @override
  String get careScreenErrorMissingIdGeneral => '错误：缺少条目ID，无法继续。';

  @override
  String get careScreenErrorEditPermission => '错误：您无权编辑此条目。';

  @override
  String get careScreenErrorUpdateMedStatus => '更新药物状态时出错。请重试。';

  @override
  String get careScreenLoadingRecords => '正在加载今日记录...';

  @override
  String get careScreenErrorNoRecords => '未找到记录或发生错误。';

  @override
  String get careScreenSectionTitleMeds => '药物';

  @override
  String get careScreenNoMedsLogged => '今日无药物记录。';

  @override
  String get careScreenUnknownMedication => '未知药物';

  @override
  String get careScreenTooltipEditMed => '编辑药物条目';

  @override
  String get careScreenTooltipDeleteMed => '删除药物条目';

  @override
  String get careScreenButtonAddMed => '添加药物';

  @override
  String get careScreenSectionTitleSleep => '睡眠';

  @override
  String get careScreenNoSleepLogged => '今日无睡眠记录。';

  @override
  String careScreenSleepTimeRange(String wentToBed, String wokeUp) {
    return '$wentToBed - $wokeUp';
  }

  @override
  String careScreenSleepQuality(String quality, String duration) {
    return '睡眠质量：$quality $duration';
  }

  @override
  String careScreenSleepNaps(String naps) {
    return '午睡：$naps';
  }

  @override
  String get careScreenTooltipEditSleep => '编辑睡眠条目';

  @override
  String get careScreenTooltipDeleteSleep => '删除睡眠条目';

  @override
  String get careScreenButtonAddSleep => '添加睡眠';

  @override
  String get careScreenSectionTitleFoodWater => '膳食与饮水';

  @override
  String get careScreenNoFoodWaterLogged => '今日无膳食或饮水记录。';

  @override
  String errorEnterValidEmailPasswordMinLength(int minLength) {
    return '请输入有效的电子邮件和密码（至少$minLength个字符）。';
  }

  @override
  String get errorSignUpFailedDefault => '注册失败。请重试或检查您的网络连接。';

  @override
  String get signUpScreenTitle => '创建账户';

  @override
  String get createAccountTitle => '创建您的账户';

  @override
  String get signUpButton => '注册';

  @override
  String get termElderDefault => '被照顾者';

  @override
  String get formErrorGenericSaveUpdate => '保存或更新时出错。请重试。';

  @override
  String get formSuccessActivitySaved => '活动记录保存成功。';

  @override
  String get formSuccessActivityUpdated => '活动记录更新成功。';

  @override
  String get formSuccessExpenseSaved => '费用记录保存成功。';

  @override
  String get formSuccessExpenseUpdated => '费用记录更新成功。';

  @override
  String get formSuccessMealSaved => '膳食记录保存成功。';

  @override
  String get formSuccessMealUpdated => '膳食记录更新成功。';

  @override
  String get formSuccessMedSaved => '药物记录保存成功。';

  @override
  String get formSuccessMedUpdated => '药物记录更新成功。';

  @override
  String get formSuccessMoodSaved => '心情记录保存成功。';

  @override
  String get formSuccessMoodUpdated => '心情记录更新成功。';

  @override
  String get formSuccessPainSaved => '疼痛记录保存成功。';

  @override
  String get formSuccessPainUpdated => '疼痛记录更新成功。';

  @override
  String get formSuccessSleepSaved => '睡眠记录保存成功。';

  @override
  String get formSuccessSleepUpdated => '睡眠记录更新成功。';

  @override
  String get formSuccessVitalSaved => '生命体征保存成功。';

  @override
  String get formSuccessVitalUpdated => '生命体征更新成功。';

  @override
  String get formErrorNoItemToDelete => '没有可删除的条目。';

  @override
  String get formConfirmDeleteTitle => '确认删除';

  @override
  String get formConfirmDeleteVitalMessage => '您确定要删除此生命体征记录吗？';

  @override
  String get formSuccessVitalDeleted => '生命体征记录已删除。';

  @override
  String get formErrorFailedToDeleteVital => '删除生命体征记录失败。';

  @override
  String get formTooltipDeleteVital => '删除生命体征';

  @override
  String get formConfirmDeleteMealMessage => '您确定要删除此膳食记录吗？';

  @override
  String get formSuccessMealDeleted => '膳食记录已删除。';

  @override
  String get formErrorFailedToDeleteMeal => '删除膳食记录失败。';

  @override
  String get formTooltipDeleteMeal => '删除膳食';

  @override
  String get goToTodayButtonLabel => '回到今天';

  @override
  String get formConfirmDeleteMedMessage => '您确定要删除此药物记录吗？';

  @override
  String get formSuccessMedDeleted => '药物记录已删除。';

  @override
  String get formErrorFailedToDeleteMed => '删除药物记录失败。';

  @override
  String get formTooltipDeleteMed => '删除药物';

  @override
  String get formConfirmDeleteMoodMessage => '您确定要删除此心情记录吗？';

  @override
  String get formSuccessMoodDeleted => '心情记录已删除。';

  @override
  String get formErrorFailedToDeleteMood => '删除心情记录失败。';

  @override
  String get formTooltipDeleteMood => '删除心情';

  @override
  String get formConfirmDeletePainMessage => '您确定要删除此疼痛记录吗？';

  @override
  String get formSuccessPainDeleted => '疼痛记录已删除。';

  @override
  String get formErrorFailedToDeletePain => '删除疼痛记录失败。';

  @override
  String get formTooltipDeletePain => '删除疼痛';

  @override
  String get formConfirmDeleteActivityMessage => '您确定要删除此活动记录吗？';

  @override
  String get formSuccessActivityDeleted => '活动记录已删除。';

  @override
  String get formErrorFailedToDeleteActivity => '删除活动记录失败。';

  @override
  String get formTooltipDeleteActivity => '删除活动';

  @override
  String get formConfirmDeleteSleepMessage => '您确定要删除此睡眠记录吗？';

  @override
  String get formSuccessSleepDeleted => '睡眠记录已删除。';

  @override
  String get formErrorFailedToDeleteSleep => '删除睡眠记录失败。';

  @override
  String get formTooltipDeleteSleep => '删除睡眠';

  @override
  String get formConfirmDeleteExpenseMessage => '您确定要删除此费用记录吗？';

  @override
  String get formSuccessExpenseDeleted => '费用记录已删除。';

  @override
  String get formErrorFailedToDeleteExpense => '删除费用记录失败。';

  @override
  String get formTooltipDeleteExpense => '删除费用';

  @override
  String get userSelectorSendToLabel => '发送至：';

  @override
  String get userSelectorAudienceAll => '所有用户';

  @override
  String get userSelectorAudienceSpecific => '特定用户';

  @override
  String get userSelectorNoUsersAvailable => '没有其他可选用户。';

  @override
  String get timelinePostingToAll => '发布给：所有用户';

  @override
  String timelinePostingToCount(String count) {
    return '发布给：$count 位特定用户';
  }

  @override
  String get timelinePrivateMessageIndicator => '私人消息';

  @override
  String get timelineEditMessage => '编辑消息';

  @override
  String get timelineDeleteMessage => '删除消息';

  @override
  String get timelineConfirmDeleteMessageTitle => '删除消息？';

  @override
  String get timelineConfirmDeleteMessageContent => '您确定要删除此消息吗？';

  @override
  String get timelineMessageDeletedSuccess => '消息已删除。';

  @override
  String timelineErrorDeletingMessage(String errorMessage) {
    return '删除消息时出错：$errorMessage';
  }

  @override
  String get timelineMessageUpdatedSuccess => '消息已更新。';

  @override
  String timelineErrorUpdatingMessage(String errorMessage) {
    return '更新消息时出错：$errorMessage';
  }

  @override
  String get timelineUpdateButton => '更新';

  @override
  String get timelineHideMessage => '隐藏消息';

  @override
  String get timelineMessageHiddenSuccess => '消息已从您的视图中隐藏。';

  @override
  String get timelineShowHiddenMessagesButton => '显示已隐藏';

  @override
  String get timelineHideHiddenMessagesButton => '显示全部';

  @override
  String get timelineUnhideMessage => '取消隐藏消息';

  @override
  String get timelineMessageUnhiddenSuccess => '消息已取消隐藏。';

  @override
  String get timelineNoHiddenMessages => '此时间线没有隐藏的消息。';

  @override
  String get selfCareScreenTitle => '自我关怀';

  @override
  String get settingsTitleNotificationPreferences => '通知设置';

  @override
  String get settingsItemNotificationPreferences => '通知偏好设置';

  @override
  String get landingPageAlreadyLoggedIn => '您已登录！';

  @override
  String get manageMedications => '药物管理';

  @override
  String get medicationsScreenTitleGeneric => '药物';

  @override
  String medicationsScreenTitleForElder(String name) {
    return '$name的药物';
  }

  @override
  String get medicationsSearchHint => '搜索药物名称';

  @override
  String get medicationsDoseHint => '例如：10毫克';

  @override
  String get medicationsScheduleHint => '例如：上午/下午';

  @override
  String get medicationsListEmpty => '尚未添加药物';

  @override
  String get medicationsDoseNotSet => '剂量未设定';

  @override
  String get medicationsScheduleNotSet => '服用时间未设定';

  @override
  String get medicationsTooltipDelete => '删除药物';

  @override
  String medicationsConfirmDeleteTitle(String medName) {
    return '删除“$medName”？';
  }

  @override
  String get medicationsConfirmDeleteContent => '此操作无法撤销。';

  @override
  String medicationsDeletedSuccess(String medName) {
    return '药物“$medName”已移除。';
  }

  @override
  String get rxNavGenericSearchError => '无法获取药物列表。请重试。';

  @override
  String get medicationsValidationNameRequired => '名称为必填项';

  @override
  String get medicationsValidationDoseRequired => '剂量为必填项';

  @override
  String get medicationsInteractionsFoundTitle => '发现可能的药物相互作用';

  @override
  String get medicationsNoInteractionsFound => '未发现药物相互作用';

  @override
  String get medicationsInteractionsSaveAnyway => '仍然保存';

  @override
  String get medicationsAddDialogTitle => '添加药物';

  @override
  String medicationsAddedSuccess(String medName) {
    return '药物“$medName”已添加。';
  }

  @override
  String get routeErrorGenericMessage => '出错了，请重试。';

  @override
  String get goHomeButton => '返回首页';

  @override
  String get settingsTitleHelpfulResources => '实用资源';

  @override
  String get settingsItemHelpfulResources => '查看实用资源';

  @override
  String get timelineFilterOnlyMyLogs => '仅我的记录:';

  @override
  String get timelineFilterFromDate => '从';

  @override
  String get timelineFilterToDate => '至';

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
