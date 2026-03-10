// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Cecelia Care';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get languageSetting => 'Idioma';

  @override
  String get manageElderProfilesTitle => 'Gestionar Perfiles de Ancianos';

  @override
  String get createProfileButton => 'Crear Perfil';

  @override
  String get pleaseLogInToManageProfiles =>
      'Por favor, inicie sesión para gestionar los perfiles de ancianos.';

  @override
  String calendarScreenTitle(String elderName) {
    return 'Calendario para $elderName';
  }

  @override
  String get formOptionOther => 'Otro';

  @override
  String get formLabelNotesOptional => 'Notas (Opcional)';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get updateButton => 'Actualizar';

  @override
  String get saveButton => 'Guardar';

  @override
  String get okButton => 'Aceptar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get removeButton => 'Quitar';

  @override
  String get inviteButton => 'Invitar';

  @override
  String get activeButton => 'Activo';

  @override
  String get setActiveButton => 'Establecer Activo';

  @override
  String get sendInviteButton => 'Enviar Invitación';

  @override
  String get formUnknownUser => 'Usuario Desconocido';

  @override
  String get timePickerHelpText => 'SELECCIONAR HORA';

  @override
  String get expenseFormTitleEdit => 'Editar Gasto';

  @override
  String get expenseFormTitleNew => 'Nuevo Gasto';

  @override
  String get expenseFormLabelDescription => 'Descripción';

  @override
  String get expenseFormHintDescription => 'Ej: Recarga de receta';

  @override
  String get expenseFormValidationDescription =>
      'Por favor, ingrese una descripción.';

  @override
  String get expenseFormLabelAmount => 'Monto';

  @override
  String get expenseFormHintAmount => 'Ej: 25.50';

  @override
  String get expenseFormValidationAmountEmpty => 'Por favor, ingrese un monto.';

  @override
  String get expenseFormValidationAmountInvalid =>
      'Por favor, ingrese un monto positivo válido.';

  @override
  String get expenseFormLabelCategory => 'Categoría';

  @override
  String get expenseCategoryMedical => 'Médico';

  @override
  String get expenseCategoryGroceries => 'Comestibles';

  @override
  String get expenseCategorySupplies => 'Suministros';

  @override
  String get expenseCategoryHousehold => 'Hogar';

  @override
  String get expenseCategoryPersonalCare => 'Cuidado Personal';

  @override
  String get expenseFormValidationCategory =>
      'Por favor, seleccione una categoría.';

  @override
  String get expenseFormHintNotes => 'Añada cualquier nota relevante aquí...';

  @override
  String get formErrorFailedToUpdateExpense =>
      'Error al actualizar el gasto. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSaveExpense =>
      'Error al guardar el gasto. Por favor, inténtelo de nuevo.';

  @override
  String get mealFormTitleEdit => 'Editar Comida / Ingesta de Agua';

  @override
  String get mealFormTitleNew => 'Registrar Comida / Ingesta de Agua';

  @override
  String get mealFormLabelIntakeType => 'Tipo de Ingesta';

  @override
  String get mealFormIntakeCategoryFood => 'Comida';

  @override
  String get mealFormIntakeCategoryWater => 'Agua';

  @override
  String get mealFormLabelMealType => 'Tipo de Comida';

  @override
  String get mealFormMealTypeBreakfast => 'Desayuno';

  @override
  String get mealFormMealTypeLunch => 'Almuerzo';

  @override
  String get mealFormMealTypeSnack => 'Merienda';

  @override
  String get mealFormMealTypeDinner => 'Cena';

  @override
  String get mealFormLabelDescription => 'Descripción';

  @override
  String get mealFormHintFoodDescription => 'Ej: Sopa de pollo, tostada';

  @override
  String get mealFormValidationFoodDescription =>
      'Por favor, describa la comida.';

  @override
  String get mealFormLabelWaterContext => 'Contexto del Agua (Opcional)';

  @override
  String get mealFormHintWaterContext => 'Ej: Con medicación, Sediento/a';

  @override
  String get mealFormLabelWaterAmount => 'Cantidad';

  @override
  String get mealFormHintWaterAmount => 'Ej: 1 vaso, 200ml';

  @override
  String get mealFormValidationWaterAmount =>
      'Por favor, especifique la cantidad de agua.';

  @override
  String get mealFormHintFoodNotes =>
      'Ej: Comió bien, no le gustaron las zanahorias';

  @override
  String get mealFormHintWaterNotes => 'Ej: Bebió lentamente';

  @override
  String get formErrorFailedToUpdateMeal =>
      'Error al actualizar la comida. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSaveMeal =>
      'Error al guardar la comida. Por favor, inténtelo de nuevo.';

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
  String get medFormTitleEdit => 'Editar Medicación';

  @override
  String get medFormTitleNew => 'Registrar Medicación';

  @override
  String get medFormTimePickerHelpText => 'SELECCIONAR HORA DE MEDICACIÓN';

  @override
  String get medFormLabelName => 'Nombre del Medicamento';

  @override
  String get medFormHintNameCustom =>
      'O escriba un nombre de medicamento personalizado';

  @override
  String get medFormHintName => 'Ingrese el nombre del medicamento';

  @override
  String get medFormValidationName =>
      'Por favor, ingrese el nombre del medicamento.';

  @override
  String get medFormLabelDose => 'Dosis (Opcional)';

  @override
  String get medFormHintDose => 'Ej: 1 tableta, 10mg';

  @override
  String get medFormLabelTime => 'Hora (Opcional)';

  @override
  String get medFormHintTime => 'Seleccionar hora';

  @override
  String get medFormLabelMarkAsTaken => 'Marcar como Tomado';

  @override
  String get formErrorFailedToUpdateMed =>
      'Error al actualizar la medicación. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSaveMed =>
      'Error al guardar la medicación. Por favor, inténtelo de nuevo.';

  @override
  String get moodFormTitleEdit => 'Editar Estado de Ánimo';

  @override
  String get moodFormTitleNew => 'Registrar Estado de Ánimo';

  @override
  String get moodHappy => '😊 Feliz';

  @override
  String get moodContent => '🙂 Contento/a';

  @override
  String get moodSad => '😟 Triste';

  @override
  String get moodAnxious => '😬 Ansioso/a';

  @override
  String get moodCalm => '😌 Calmado/a';

  @override
  String get moodIrritable => '😠 Irritable';

  @override
  String get moodAgitated => '😫 Agitado/a';

  @override
  String get moodPlayful => '🥳 Juguetón/a';

  @override
  String get moodTired => '😴 Cansado/a';

  @override
  String get moodOptionOther => '📝 Otro';

  @override
  String get moodFormLabelSelectMood => 'Seleccionar Estado de Ánimo';

  @override
  String get moodFormValidationSelectOrSpecifyMood =>
      'Por favor, seleccione o especifique un estado de ánimo.';

  @override
  String get moodFormValidationSpecifyOtherMood =>
      'Por favor, especifique el estado de ánimo.';

  @override
  String get moodFormHintSpecifyOtherMood => 'Describa el estado de ánimo...';

  @override
  String get moodFormLabelIntensity => 'Intensidad (1-5, Opcional)';

  @override
  String get moodFormHintIntensity => '1 (Leve) - 5 (Severo)';

  @override
  String get moodFormValidationIntensityRange =>
      'La intensidad debe estar entre 1 y 5.';

  @override
  String get moodFormHintNotes => 'Ej: Sintiéndose bien después de un paseo';

  @override
  String get moodFormButtonUpdate => 'Actualizar Ánimo';

  @override
  String get moodFormButtonSave => 'Guardar Ánimo';

  @override
  String get formErrorFailedToUpdateMood =>
      'Error al actualizar el estado de ánimo. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSaveMood =>
      'Error al guardar el estado de ánimo. Por favor, inténtelo de nuevo.';

  @override
  String get painFormTitleEdit => 'Editar Registro de Dolor';

  @override
  String get painFormTitleNew => 'Registrar Dolor';

  @override
  String get painTypeAching => 'Adolorido';

  @override
  String get painTypeBurning => 'Ardiente';

  @override
  String get painTypeDull => 'Sordo';

  @override
  String get painTypeSharp => 'Agudo';

  @override
  String get painTypeShooting => 'Punzante';

  @override
  String get painTypeStabbing => 'Apuñalador';

  @override
  String get painTypeThrobbing => 'Palpitante';

  @override
  String get painTypeTender => 'Sensible';

  @override
  String get painFormLabelLocation => 'Ubicación';

  @override
  String get painFormHintLocation => 'Ej: Rodilla izquierda, Espalda baja';

  @override
  String get painFormValidationLocation =>
      'Por favor, especifique la ubicación del dolor.';

  @override
  String get painFormLabelIntensity => 'Intensidad (0-10)';

  @override
  String get painFormHintIntensity => '0 (Sin dolor) - 10 (Peor dolor)';

  @override
  String get painFormValidationIntensityEmpty =>
      'Por favor, ingrese la intensidad del dolor.';

  @override
  String get painFormValidationIntensityRange =>
      'La intensidad debe estar entre 0 y 10.';

  @override
  String get painFormLabelDescription => 'Descripción';

  @override
  String get painFormValidationSelectOrSpecifyDescription =>
      'Por favor, seleccione o especifique una descripción del dolor.';

  @override
  String get painFormValidationSpecifyOtherDescription =>
      'Por favor, especifique la descripción del dolor.';

  @override
  String get painFormHintSpecifyOtherDescription => 'Describa el dolor...';

  @override
  String get painFormHintNotes =>
      'Ej: Peor después de la actividad, aliviado con reposo';

  @override
  String get formErrorFailedToUpdatePain =>
      'Error al actualizar el registro de dolor. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSavePain =>
      'Error al guardar el registro de dolor. Por favor, inténtelo de nuevo.';

  @override
  String get sleepFormTitleEdit => 'Editar Registro de Sueño';

  @override
  String get sleepFormTitleNew => 'Registrar Sueño';

  @override
  String get sleepQualityGood => 'Bueno';

  @override
  String get sleepQualityFair => 'Regular';

  @override
  String get sleepQualityPoor => 'Malo';

  @override
  String get sleepQualityRestless => 'Inquieto';

  @override
  String get sleepQualityInterrupted => 'Interrumpido';

  @override
  String get sleepFormLabelWentToBed => 'Se acostó a las';

  @override
  String get sleepFormHintTimeWentToBed => 'Seleccionar hora';

  @override
  String get sleepFormValidationTimeWentToBed =>
      'Por favor, seleccione la hora en que se acostó.';

  @override
  String get sleepFormLabelWokeUp => 'Se despertó a las (Opcional)';

  @override
  String get sleepFormHintTimeWokeUp => 'Seleccionar hora';

  @override
  String get sleepFormLabelTotalDuration => 'Duración Total (Opcional)';

  @override
  String get sleepFormHintTotalDuration => 'Ej: 7 horas, 7h 30m';

  @override
  String get sleepFormLabelQuality => 'Calidad';

  @override
  String get sleepFormValidationSelectQuality =>
      'Por favor, seleccione la calidad del sueño.';

  @override
  String get sleepFormLabelDescribeOtherQuality => 'Describir Otra Calidad';

  @override
  String get sleepFormHintDescribeOtherQuality =>
      'Describa la calidad del sueño...';

  @override
  String get sleepFormValidationDescribeOtherQuality =>
      'Por favor, describa la calidad del sueño.';

  @override
  String get sleepFormLabelNaps => 'Siestas (Opcional)';

  @override
  String get sleepFormHintNaps => 'Ej: 1 siesta, 30 mins';

  @override
  String get sleepFormLabelGeneralNotes => 'Notas Generales (Opcional)';

  @override
  String get sleepFormHintGeneralNotes =>
      'Ej: Se despertó sintiéndose renovado/a';

  @override
  String get sleepFormButtonUpdate => 'Actualizar Sueño';

  @override
  String get sleepFormButtonSave => 'Guardar Sueño';

  @override
  String get formErrorFailedToUpdateSleep =>
      'Error al actualizar el registro de sueño. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSaveSleep =>
      'Error al guardar el registro de sueño. Por favor, inténtelo de nuevo.';

  @override
  String get vitalFormTitleEdit => 'Editar Signo Vital';

  @override
  String get vitalFormTitleNew => 'Registrar Signo Vital';

  @override
  String get vitalTypeBPLabel => 'Presión Arterial';

  @override
  String get vitalTypeBPUnit => 'mmHg';

  @override
  String get vitalTypeBPPlaceholder => 'Ej: 120/80';

  @override
  String get vitalTypeHRLabel => 'Frecuencia Cardíaca';

  @override
  String get vitalTypeHRUnit => 'lpm';

  @override
  String get vitalTypeHRPlaceholder => 'Ej: 70';

  @override
  String get vitalTypeWTLabel => 'Peso';

  @override
  String get vitalTypeWTUnit => 'kg/lbs';

  @override
  String get vitalTypeWTPlaceholder => 'Ej: 65 kg o 143 lbs';

  @override
  String get vitalTypeBGLabel => 'Glucosa en Sangre';

  @override
  String get vitalTypeBGUnit => 'mg/dL o mmol/L';

  @override
  String get vitalTypeBGPlaceholder => 'Ej: 90 mg/dL';

  @override
  String get vitalTypeTempLabel => 'Temperatura';

  @override
  String get vitalTypeTempUnit => '°C/°F';

  @override
  String get vitalTypeTempPlaceholder => 'Ej: 36.5°C o 97.7°F';

  @override
  String get vitalTypeO2Label => 'Saturación de Oxígeno';

  @override
  String get vitalTypeO2Unit => '%';

  @override
  String get vitalTypeO2Placeholder => 'Ej: 98';

  @override
  String get vitalFormLabelType => 'Tipo';

  @override
  String get vitalFormLabelValue => 'Valor';

  @override
  String get vitalFormValidationValueEmpty => 'Por favor, ingrese un valor.';

  @override
  String get vitalFormValidationBPFormat =>
      'Ingrese PA como \'SIS/DIA\', ej: 120/80.';

  @override
  String get vitalFormValidationValueNumeric =>
      'Por favor, ingrese un valor numérico.';

  @override
  String get vitalFormHintNotes => 'Ej: Tomado después de la comida';

  @override
  String get vitalFormButtonUpdate => 'Actualizar Vital';

  @override
  String get vitalFormButtonSave => 'Guardar Vital';

  @override
  String get formErrorFailedToUpdateVital =>
      'Error al actualizar el signo vital. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSaveVital =>
      'Error al guardar el signo vital. Por favor, inténtelo de nuevo.';

  @override
  String get settingsUserProfileNotLoaded => 'Perfil de usuario no cargado.';

  @override
  String get settingsDisplayNameCannotBeEmpty =>
      'El nombre para mostrar no puede estar vacío.';

  @override
  String get settingsProfileUpdatedSuccess =>
      'Perfil actualizado correctamente.';

  @override
  String settingsErrorUpdatingProfile(String errorMessage) {
    return 'Error al actualizar el perfil: $errorMessage';
  }

  @override
  String get settingsSelectElderFirstMedDef =>
      'Por favor, seleccione primero un perfil de anciano para gestionar las definiciones de medicamentos.';

  @override
  String get settingsMedNameRequired =>
      'El nombre del medicamento es obligatorio.';

  @override
  String get settingsMedDefaultTimeFormatError =>
      'Formato de hora inválido. Por favor, use HH:mm (ej: 09:00).';

  @override
  String get settingsMedDefAddedSuccess =>
      'Definición de medicamento agregada correctamente.';

  @override
  String get settingsClearDataErrorElderOrUserMissing =>
      'No se pueden borrar los datos: Falta el anciano activo o el usuario.';

  @override
  String get settingsClearDataErrorNotAdmin =>
      'No eres el administrador principal del perfil de este anciano. Los datos solo pueden ser borrados por el administrador principal.';

  @override
  String settingsClearDataDialogTitle(String elderName) {
    return '¿Borrar todos los datos de $elderName?';
  }

  @override
  String get settingsClearDataDialogContent =>
      'Esta acción es irreversible y eliminará todos los registros asociados (medicamentos, comidas, signos vitales, etc.) para este anciano. ¿Estás seguro de que quieres continuar?';

  @override
  String get settingsClearDataDialogConfirmButton =>
      'Sí, Borrar Todos los Datos';

  @override
  String settingsClearDataSuccess(String elderName) {
    return 'Todos los datos de $elderName han sido borrados.';
  }

  @override
  String settingsClearDataErrorGeneric(String errorMessage) {
    return 'Error al borrar los datos: $errorMessage';
  }

  @override
  String get languageNameEn => 'English (Inglés)';

  @override
  String get languageNameEs => 'Español';

  @override
  String get languageNameJa => '日本語 (Japonés)';

  @override
  String get languageNameKo => '한국어 (Coreano)';

  @override
  String get languageNameZh => '中文 (Chino)';

  @override
  String get settingsTitleMyAccount => 'Mi Cuenta';

  @override
  String get settingsLabelDisplayName => 'Nombre para Mostrar';

  @override
  String get settingsHintDisplayName => 'Ingrese su nombre para mostrar';

  @override
  String get settingsLabelDOB => 'Fecha de Nacimiento';

  @override
  String get settingsHintDOB => 'Seleccione su fecha de nacimiento';

  @override
  String get settingsButtonSaveProfile => 'Guardar Perfil';

  @override
  String get settingsButtonSignOut => 'Cerrar Sesión';

  @override
  String get settingsErrorLoadingProfile => 'Error al cargar el perfil.';

  @override
  String get settingsTitleLanguage => 'Configuración de Idioma';

  @override
  String get settingsLabelSelectLanguage =>
      'Seleccionar Idioma de la Aplicación';

  @override
  String settingsLanguageChangedConfirmation(String languageTag) {
    return 'Idioma cambiado a $languageTag.';
  }

  @override
  String get settingsTitleElderProfileManagement =>
      'Gestión de Perfiles de Ancianos';

  @override
  String settingsCurrentElder(String elderName) {
    return 'Anciano Activo Actual: $elderName';
  }

  @override
  String get settingsNoActiveElderSelected =>
      'Ningún anciano activo seleccionado. Por favor, seleccione o cree uno.';

  @override
  String get settingsErrorNavToManageElderProfiles =>
      'No se pudo navegar a la gestión de perfiles de ancianos. Usuario no ha iniciado sesión.';

  @override
  String get settingsButtonManageElderProfiles =>
      'Gestionar Perfiles de Ancianos';

  @override
  String settingsTitleAdminActions(String elderName) {
    return 'Acciones de Administrador para $elderName';
  }

  @override
  String get settingsButtonClearAllData =>
      'Borrar Todos los Datos de Este Anciano';

  @override
  String get settingsTitleMedicationDefinitions =>
      'Definiciones de Medicamentos';

  @override
  String get settingsSubtitleAddNewMedDef =>
      'Agregar Nueva Definición de Medicamento:';

  @override
  String get settingsLabelMedName => 'Nombre del Medicamento';

  @override
  String get settingsHintMedName => 'Ej: Lisinopril';

  @override
  String get settingsLabelMedDose => 'Dosis Predeterminada (Opcional)';

  @override
  String get settingsHintMedDose => 'Ej: 10mg, 1 tableta';

  @override
  String get settingsLabelMedDefaultTime =>
      'Hora Predeterminada (HH:mm, Opcional)';

  @override
  String get settingsHintMedDefaultTime => 'Ej: 08:00';

  @override
  String get settingsButtonAddMedDef => 'Agregar Definición de Medicamento';

  @override
  String get settingsSelectElderToAddMedDefs =>
      'Seleccione un perfil de anciano para agregar definiciones de medicamentos.';

  @override
  String get settingsSelectElderToViewMedDefs =>
      'Seleccione un perfil de anciano para ver las definiciones de medicamentos.';

  @override
  String settingsNoMedDefsForElder(String elderName) {
    return 'No se encontraron definiciones de medicamentos para $elderName.';
  }

  @override
  String settingsExistingMedDefsForElder(String elderNameOrFallback) {
    return 'Definiciones Existentes para $elderNameOrFallback:';
  }

  @override
  String get settingsSelectedElderFallback => 'Anciano Seleccionado';

  @override
  String settingsMedDefDosePrefix(String dose) {
    return 'Dosis: $dose';
  }

  @override
  String settingsMedDefDefaultTimePrefix(String time) {
    return 'Hora: $time';
  }

  @override
  String get settingsTooltipDeleteMedDef =>
      'Eliminar esta definición de medicamento';

  @override
  String settingsDeleteMedDefDialogTitle(String medName) {
    return '¿Eliminar la definición de \'$medName\'?';
  }

  @override
  String get settingsDeleteMedDefDialogContent =>
      '¿Está seguro de que desea eliminar esta definición de medicamento? Esto no afectará los registros de medicamentos pasados, pero la eliminará como opción para registros futuros.';

  @override
  String settingsMedDefDeletedSuccess(String medName) {
    return 'Definición de medicamento \'$medName\' eliminada.';
  }

  @override
  String get errorNotLoggedIn => 'Error: Usuario no ha iniciado sesión.';

  @override
  String get errorElderIdMissing => 'Error: Falta el ID del anciano.';

  @override
  String profileUpdatedSnackbar(String profileName) {
    return 'Perfil de $profileName actualizado.';
  }

  @override
  String profileCreatedSnackbar(String profileName) {
    return 'Perfil de $profileName creado.';
  }

  @override
  String errorSavingProfile(String errorMessage) {
    return 'Error al guardar el perfil: $errorMessage';
  }

  @override
  String get errorSelectElderAndEmail =>
      'Por favor, seleccione un perfil de anciano e ingrese una dirección de correo electrónico válida.';

  @override
  String invitationSentSnackbar(String email) {
    return 'Invitación enviada a $email.';
  }

  @override
  String errorSendingInvitation(String errorMessage) {
    return 'Error al enviar la invitación: $errorMessage';
  }

  @override
  String get removeCaregiverDialogTitle => '¿Quitar Cuidador?';

  @override
  String removeCaregiverDialogContent(String caregiverIdentifier) {
    return '¿Está seguro de que desea quitar a $caregiverIdentifier como cuidador de este anciano?';
  }

  @override
  String caregiverRemovedSnackbar(String caregiverIdentifier) {
    return 'Cuidador $caregiverIdentifier quitado.';
  }

  @override
  String errorRemovingCaregiver(String errorMessage) {
    return 'Error al quitar el cuidador: $errorMessage';
  }

  @override
  String get tooltipEditProfile => 'Editar Perfil';

  @override
  String get dobLabelPrefix => 'FDN:';

  @override
  String get allergiesLabelPrefix => 'Alergias:';

  @override
  String get dietLabelPrefix => 'Dieta:';

  @override
  String get primaryAdminLabel => 'Administrador Principal:';

  @override
  String get adminNotAssigned => 'No asignado';

  @override
  String get loadingAdminInfo => 'Cargando información del administrador...';

  @override
  String caregiversLabel(int count) {
    return 'Cuidadores ($count):';
  }

  @override
  String get noCaregiversYet => 'Aún no hay cuidadores.';

  @override
  String get errorLoadingCaregiverNames =>
      'Error al cargar los nombres de los cuidadores.';

  @override
  String get caregiverAdminSuffix => '(Admin)';

  @override
  String tooltipRemoveCaregiver(String identifier) {
    return 'Quitar a $identifier';
  }

  @override
  String profileSetActiveSnackbar(String profileName) {
    return '$profileName es ahora el perfil activo.';
  }

  @override
  String inviteDialogTitle(String profileName) {
    return 'Invitar Cuidador al Perfil de $profileName';
  }

  @override
  String get caregiversEmailLabel => 'Correo Electrónico del Cuidador';

  @override
  String get enterEmailHint => 'Ingrese la dirección de correo electrónico';

  @override
  String get createElderProfileTitle => 'Crear Nuevo Perfil de Anciano';

  @override
  String editProfileTitle(String profileNameOrFallback) {
    return 'Editar $profileNameOrFallback';
  }

  @override
  String get profileNameLabel => 'Nombre del Perfil';

  @override
  String get validatorPleaseEnterName => 'Por favor, ingrese un nombre.';

  @override
  String get dateOfBirthLabel => 'Fecha de Nacimiento';

  @override
  String get allergiesLabel => 'Alergias (separadas por comas)';

  @override
  String get dietaryRestrictionsLabel =>
      'Restricciones Alimentarias (separadas por comas)';

  @override
  String get createNewProfileButton => 'Crear Nuevo Perfil';

  @override
  String get saveChangesButton => 'Guardar Cambios';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get noElderProfilesFound => 'No se encontraron perfiles de ancianos.';

  @override
  String get createNewProfileOrWait =>
      'Cree un nuevo perfil o espere una invitación.';

  @override
  String get fabNewProfile => 'Nuevo Perfil';

  @override
  String get activityTypeWalk => 'Caminata';

  @override
  String get activityTypeExercise => 'Ejercicio';

  @override
  String get activityTypePhysicalTherapy => 'Fisioterapia';

  @override
  String get activityTypeOccupationalTherapy => 'Terapia Ocupacional';

  @override
  String get activityTypeOuting => 'Salida';

  @override
  String get activityTypeSocialVisit => 'Visita Social';

  @override
  String get activityTypeReading => 'Lectura';

  @override
  String get activityTypeTV => 'Ver TV/Películas';

  @override
  String get activityTypeGardening => 'Jardinería';

  @override
  String get assistanceLevelIndependent => 'Independiente';

  @override
  String get assistanceLevelStandbyAssist => 'Asistencia en Espera';

  @override
  String get assistanceLevelWithWalker => 'Con Andador';

  @override
  String get assistanceLevelWithCane => 'Con Bastón';

  @override
  String get assistanceLevelWheelchair => 'Silla de Ruedas';

  @override
  String get assistanceLevelMinAssist => 'Asistencia Mínima (Min A)';

  @override
  String get assistanceLevelModAssist => 'Asistencia Moderada (Mod A)';

  @override
  String get assistanceLevelMaxAssist => 'Asistencia Máxima (Max A)';

  @override
  String get formErrorFailedToUpdateActivity =>
      'Error al actualizar la actividad. Por favor, inténtelo de nuevo.';

  @override
  String get formErrorFailedToSaveActivity =>
      'Error al guardar la actividad. Por favor, inténtelo de nuevo.';

  @override
  String get activityFormTitleEdit => 'Editar Actividad';

  @override
  String get activityFormTitleNew => 'Registrar Nueva Actividad';

  @override
  String get activityFormLabelActivityType => 'Tipo de Actividad';

  @override
  String get activityFormHintActivityType =>
      'Seleccione o escriba la actividad';

  @override
  String get activityFormValidationActivityType =>
      'Por favor, seleccione o especifique un tipo de actividad.';

  @override
  String get activityFormLabelDuration => 'Duración (Opcional)';

  @override
  String get activityFormHintDuration => 'Ej: 30 minutos, 1 hora';

  @override
  String get activityFormLabelAssistance => 'Nivel de Asistencia (Opcional)';

  @override
  String get activityFormHintAssistance => 'Seleccione el nivel de asistencia';

  @override
  String get activityFormHintNotes =>
      'Ej: Disfrutó del sol, caminó hasta el parque';

  @override
  String get notApplicable => 'No aplica';

  @override
  String careScreenWaterLog(String description) {
    return 'Agua: $description';
  }

  @override
  String careScreenMealLog(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String get careScreenMealGeneric => 'Comida';

  @override
  String careScreenWaterContext(String contextDetails) {
    return 'Contexto: $contextDetails';
  }

  @override
  String careScreenNotes(String noteContent) {
    return 'Notas: $noteContent';
  }

  @override
  String careScreenLoggedBy(String userName) {
    return 'Registrado por: $userName';
  }

  @override
  String get careScreenTooltipEditFoodWater => 'Editar Entrada de Comida/Agua';

  @override
  String get careScreenTooltipDeleteFoodWater =>
      'Eliminar Entrada de Comida/Agua';

  @override
  String get careScreenErrorMissingIdDelete =>
      'Error: No se puede eliminar la entrada, falta el ID.';

  @override
  String get careScreenErrorFailedToLoad =>
      'Error al cargar los registros de este día. Por favor, inténtelo de nuevo.';

  @override
  String get careScreenButtonAddFoodWater => 'Añadir Comida / Agua';

  @override
  String get careScreenSectionTitleMoodBehavior =>
      'Estado de Ánimo y Comportamiento';

  @override
  String get careScreenNoMoodBehaviorLogged =>
      'No se ha registrado ningún estado de ánimo o comportamiento para este día.';

  @override
  String careScreenMood(String mood) {
    return 'Ánimo: $mood';
  }

  @override
  String careScreenMoodIntensity(String intensityLevel) {
    return 'Intensidad: $intensityLevel';
  }

  @override
  String get careScreenTooltipEditMood => 'Editar Entrada de Ánimo';

  @override
  String get careScreenTooltipDeleteMood => 'Eliminar Entrada de Ánimo';

  @override
  String get careScreenButtonAddMood => 'Añadir Ánimo / Comportamiento';

  @override
  String get careScreenSectionTitlePain => 'Dolor';

  @override
  String get careScreenNoPainLogged =>
      'No se ha registrado dolor para este día.';

  @override
  String careScreenPainLog(
      String location, String description, String intensityDetails) {
    return 'Dolor: $location - $description$intensityDetails';
  }

  @override
  String careScreenPainIntensity(String intensityValue) {
    return 'Intensidad: $intensityValue';
  }

  @override
  String get careScreenTooltipEditPain => 'Editar Entrada de Dolor';

  @override
  String get careScreenTooltipDeletePain => 'Eliminar Entrada de Dolor';

  @override
  String get careScreenButtonAddPain => 'Añadir Registro de Dolor';

  @override
  String get careScreenSectionTitleActivity => 'Actividades';

  @override
  String get careScreenNoActivitiesLogged =>
      'No se han registrado actividades para este día.';

  @override
  String get careScreenUnknownActivity => 'Actividad Desconocida';

  @override
  String careScreenActivityDuration(String duration) {
    return 'Duración: $duration';
  }

  @override
  String careScreenActivityAssistance(String assistanceLevel) {
    return 'Asistencia: $assistanceLevel';
  }

  @override
  String get careScreenTooltipEditActivity => 'Editar Entrada de Actividad';

  @override
  String get careScreenTooltipDeleteActivity => 'Eliminar Entrada de Actividad';

  @override
  String get careScreenButtonAddActivity => 'Añadir Actividad';

  @override
  String get careScreenSectionTitleVitals => 'Signos Vitales';

  @override
  String get careScreenNoVitalsLogged =>
      'No se han registrado signos vitales para este día.';

  @override
  String careScreenVitalLog(String vitalType, String value, String unit) {
    return '$vitalType: $value $unit';
  }

  @override
  String get careScreenTooltipEditVital => 'Editar Entrada de Signo Vital';

  @override
  String get careScreenTooltipDeleteVital => 'Eliminar Entrada de Signo Vital';

  @override
  String get careScreenButtonAddVital => 'Añadir Signo Vital';

  @override
  String get careScreenSectionTitleExpenses => 'Gastos';

  @override
  String get careScreenNoExpensesLogged =>
      'No se han registrado gastos para este día.';

  @override
  String careScreenExpenseLog(String description, String amount) {
    return '$description: \$$amount';
  }

  @override
  String careScreenExpenseCategory(String category, String noteDetails) {
    return 'Categoría: $category$noteDetails';
  }

  @override
  String get careScreenTooltipEditExpense => 'Editar Entrada de Gasto';

  @override
  String get careScreenTooltipDeleteExpense => 'Eliminar Entrada de Gasto';

  @override
  String get careScreenButtonAddExpense => 'Añadir Gasto';

  @override
  String get calendarErrorLoadEvents =>
      'Error al cargar los eventos del calendario. Por favor, inténtelo de nuevo.';

  @override
  String get calendarErrorUserNotLoggedIn =>
      'Error: Usuario no ha iniciado sesión. No se pueden cargar los eventos del calendario.';

  @override
  String get calendarErrorEditMissingId =>
      'Error: No se puede editar el evento, falta el ID.';

  @override
  String get calendarErrorEditPermission =>
      'Error: No tiene permiso para editar este evento.';

  @override
  String get calendarErrorUpdateOriginalMissing =>
      'Error: Faltan los datos originales del evento para la actualización.';

  @override
  String get calendarErrorUpdatePermission =>
      'Error: No tiene permiso para actualizar este evento.';

  @override
  String get calendarEventAddedSuccess => 'Evento añadido correctamente.';

  @override
  String get calendarEventUpdatedSuccess => 'Evento actualizado correctamente.';

  @override
  String calendarErrorSaveEvent(String errorMessage) {
    return 'Error al guardar el evento: $errorMessage';
  }

  @override
  String get calendarErrorDeleteMissingId =>
      'Error: No se puede eliminar el evento, falta el ID.';

  @override
  String get calendarErrorDeletePermission =>
      'Error: No tiene permiso para eliminar este evento.';

  @override
  String get calendarConfirmDeleteTitle => 'Confirmar Eliminación';

  @override
  String calendarConfirmDeleteContent(String eventTitle) {
    return '¿Está seguro de que desea eliminar el evento \'$eventTitle\'?';
  }

  @override
  String get calendarUntitledEvent => 'Evento Sin Título';

  @override
  String get eventDeletedSuccess => 'Evento eliminado correctamente.';

  @override
  String get errorCouldNotDeleteEvent =>
      'Error: No se pudo eliminar el evento.';

  @override
  String get calendarNoElderSelected =>
      'Ningún anciano seleccionado. Por favor, seleccione un anciano para ver su calendario.';

  @override
  String get calendarAddNewEventButton => 'Añadir Nuevo Evento';

  @override
  String calendarEventsOnDate(String formattedDate) {
    return 'Eventos el $formattedDate:';
  }

  @override
  String get calendarNoEventsScheduled =>
      'No hay eventos programados para este día.';

  @override
  String get calendarTooltipEditEvent => 'Editar Evento';

  @override
  String get calendarEventTypePrefix => 'Tipo:';

  @override
  String get calendarEventTimePrefix => 'Hora:';

  @override
  String get calendarEventNotesPrefix => 'Notas:';

  @override
  String get expenseUncategorized => 'Sin Categoría';

  @override
  String expenseErrorProcessingData(String errorMessage) {
    return 'Error al procesar los datos de gastos: $errorMessage';
  }

  @override
  String expenseErrorFetching(String errorMessage) {
    return 'Error al obtener los gastos: $errorMessage';
  }

  @override
  String get expenseUnknownUser => 'Usuario Desconocido';

  @override
  String get expenseSelectElderPrompt =>
      'Por favor, seleccione un perfil de anciano para ver los gastos.';

  @override
  String get expenseLoading => 'Cargando gastos...';

  @override
  String get expenseScreenTitle => 'Gastos';

  @override
  String expenseForElder(String elderName) {
    return 'Gastos de $elderName';
  }

  @override
  String get expensePrevWeekButton => 'Semana Anterior';

  @override
  String get expenseNextWeekButton => 'Semana Siguiente';

  @override
  String get expenseNoExpensesThisWeek =>
      'No hay gastos registrados para esta semana.';

  @override
  String get expenseSummaryByCategoryTitle =>
      'Resumen por Categoría (Esta Semana)';

  @override
  String get expenseNoExpensesInCategoryThisWeek =>
      'No hay gastos en esta categoría para la semana seleccionada.';

  @override
  String get expenseWeekTotalLabel => 'Total de la Semana:';

  @override
  String get expenseDetailedByUserTitle =>
      'Gastos Detallados (Esta Semana - Por Usuario)';

  @override
  String expenseCategoryLabel(String categoryName) {
    return 'Categoría: $categoryName';
  }

  @override
  String get errorEnterEmailPassword =>
      'Por favor, ingrese correo electrónico y contraseña.';

  @override
  String get errorLoginFailedDefault =>
      'Inicio de sesión fallido. Verifique sus credenciales o conexión de red.';

  @override
  String get loginScreenTitle => 'Bienvenido a Cecelia Care';

  @override
  String get settingsLabelRelationshipToElder =>
      'Relación con el Receptor de Cuidados';

  @override
  String get settingsHintRelationshipToElder =>
      'Ej: Hijo/a, Cónyuge, Cuidador/a';

  @override
  String get emailLabel => 'Correo Electrónico';

  @override
  String get emailHint => 'Ingrese su correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get dontHaveAccountSignUp => '¿No tiene una cuenta? Regístrese';

  @override
  String get signUpNotImplemented =>
      'La funcionalidad de registro aún no está implementada.';

  @override
  String get homeScreenBaseTitleTimeline => 'Cronología';

  @override
  String homeScreenBaseTitleCareLog(String term) {
    return 'Registro de $term';
  }

  @override
  String homeScreenBaseTitleCalendar(String term) {
    return 'Calendario de $term';
  }

  @override
  String get homeScreenBaseTitleExpenses => 'Gastos';

  @override
  String get homeScreenBaseTitleSettings => 'Configuración';

  @override
  String get mustBeLoggedInToAddData =>
      'Debe iniciar sesión para agregar datos.';

  @override
  String get mustBeLoggedInToUpdateData =>
      'Debe iniciar sesión para actualizar datos.';

  @override
  String selectTermToViewCareLog(String term) {
    return 'Seleccione un $term para ver el Registro de Cuidado.';
  }

  @override
  String get selectElderToViewCareLog =>
      'Seleccione un Receptor de Cuidados para ver el Registro de Cuidado.';

  @override
  String get goToSettingsButton => 'Ir a Configuración';

  @override
  String selectTermToViewCalendar(String term) {
    return 'Seleccione un $term para ver el Calendario.';
  }

  @override
  String get bottomNavTimeline => 'Cronología';

  @override
  String bottomNavCareLog(Object term) {
    return 'Registro de $term';
  }

  @override
  String bottomNavCalendar(Object term) {
    return 'Calendario de $term';
  }

  @override
  String get bottomNavExpenses => 'Gastos';

  @override
  String get bottomNavSettings => 'Ajustes';

  @override
  String get timelineUnknownTime => 'Hora desconocida';

  @override
  String get timelineInvalidTime => 'Hora inválida';

  @override
  String get timelineMustBeLoggedInToPost =>
      'Debe iniciar sesión para publicar un mensaje.';

  @override
  String get timelineSelectElderToPost =>
      'Por favor, seleccione un perfil de anciano activo para publicar en su cronología.';

  @override
  String get timelineAnonymousUser => 'Anónimo';

  @override
  String timelineCouldNotPostMessage(String errorMessage) {
    return 'No se pudo publicar el mensaje: $errorMessage';
  }

  @override
  String get timelinePleaseLogInToView =>
      'Por favor, inicie sesión para ver la cronología.';

  @override
  String get timelineSelectElderToView =>
      'Por favor, seleccione un perfil de anciano para ver su cronología.';

  @override
  String timelineWriteMessageHint(String elderName) {
    return 'Escriba un mensaje para la cronología de $elderName...';
  }

  @override
  String get timelineUnknownUser => 'Usuario Desconocido';

  @override
  String get timelinePostButton => 'Publicar';

  @override
  String get timelineCancelButton => 'Cancelar';

  @override
  String get timelinePostMessageToTimelineButton =>
      'Publicar Mensaje en la Cronología';

  @override
  String get timelineLoading => 'Cargando cronología...';

  @override
  String timelineErrorLoading(String errorMessage) {
    return 'Error al cargar la cronología: $errorMessage';
  }

  @override
  String timelineNoEntriesYet(String elderName) {
    return 'Aún no hay entradas para $elderName. ¡Sé el primero en publicar!';
  }

  @override
  String get timelineItemTitleMessage => 'Mensaje';

  @override
  String get timelineEmptyMessage => '[Mensaje Vacío]';

  @override
  String get timelineItemTitleMedication => 'Medicación';

  @override
  String get timelineItemTitleSleep => 'Sueño';

  @override
  String get timelineItemTitleMeal => 'Comida';

  @override
  String get timelineItemTitleMood => 'Estado de Ánimo';

  @override
  String get timelineItemTitlePain => 'Dolor';

  @override
  String get timelineItemTitleActivity => 'Actividad';

  @override
  String get timelineItemTitleVital => 'Signo Vital';

  @override
  String get timelineItemTitleExpense => 'Gasto';

  @override
  String get timelineItemTitleEntry => 'Entrada';

  @override
  String get timelineNoDetailsProvided => 'No se proporcionaron detalles.';

  @override
  String timelineLoggedBy(String userName) {
    return 'Registrado por $userName';
  }

  @override
  String timelineErrorRenderingItem(String index, String errorDetails) {
    return 'Error al renderizar el ítem en el índice $index: $errorDetails';
  }

  @override
  String get timelineSummaryDetailsUnavailable => 'Detalles no disponibles';

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
  String get timelineSummaryMedicationStatusTaken => 'Tomada';

  @override
  String get timelineSummaryMedicationStatusNotTaken => 'No Tomada';

  @override
  String get timelineSummaryMealTypeGeneric => 'Comida';

  @override
  String timelineSummarySleepQualityFormat(String quality) {
    return 'Calidad: $quality';
  }

  @override
  String timelineSummarySleepFormat(
      String wentToBed, String wokeUp, String quality) {
    return 'Cama: $wentToBed, Despertó: $wokeUp. $quality';
  }

  @override
  String timelineSummaryMealFormat(String mealType, String description) {
    return '$mealType: $description';
  }

  @override
  String timelineSummaryMoodNotesFormat(String notes) {
    return '(Notas: $notes)';
  }

  @override
  String timelineSummaryMoodFormat(String mood, String notes) {
    return 'Ánimo: $mood $notes';
  }

  @override
  String timelineSummaryPainLocationFormat(String location) {
    return 'en $location';
  }

  @override
  String timelineSummaryPainFormat(String level, String location) {
    return 'Nivel de Dolor: $level/10 $location';
  }

  @override
  String timelineSummaryActivityDurationFormat(String duration) {
    return 'durante $duration';
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
    return 'PA: $systolic/$diastolic mmHg';
  }

  @override
  String timelineSummaryVitalFormatHR(String heartRate) {
    return 'FC: $heartRate lpm';
  }

  @override
  String timelineSummaryVitalFormatTemp(String temperature) {
    return 'Temp: $temperature°';
  }

  @override
  String timelineSummaryVitalNote(String note) {
    return 'Nota: $note';
  }

  @override
  String get timelineSummaryVitalsRecorded => 'Signos Vitales Registrados';

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
      'Error al procesar detalles para la cronología.';

  @override
  String get timelineItemTitleImage => 'Image Uploaded';

  @override
  String timelineSummaryImageFormat(Object title) {
    return 'Image: $title';
  }

  @override
  String get careScreenErrorMissingIdGeneral =>
      'Error: Falta el ID del elemento. No se puede continuar.';

  @override
  String get careScreenErrorEditPermission =>
      'Error: No tiene permiso para editar este elemento.';

  @override
  String get careScreenErrorUpdateMedStatus =>
      'Error al actualizar el estado de la medicación. Por favor, inténtelo de nuevo.';

  @override
  String get careScreenLoadingRecords => 'Cargando registros de hoy...';

  @override
  String get careScreenErrorNoRecords =>
      'No se encontraron registros para este día o ocurrió un error.';

  @override
  String get careScreenSectionTitleMeds => 'Medicamentos';

  @override
  String get careScreenNoMedsLogged =>
      'No se han registrado medicamentos para este día.';

  @override
  String get careScreenUnknownMedication => 'Medicación Desconocida';

  @override
  String get careScreenTooltipEditMed => 'Editar Entrada de Medicación';

  @override
  String get careScreenTooltipDeleteMed => 'Eliminar Entrada de Medicación';

  @override
  String get careScreenButtonAddMed => 'Añadir Medicación';

  @override
  String get careScreenSectionTitleSleep => 'Sueño';

  @override
  String get careScreenNoSleepLogged =>
      'No se ha registrado sueño para este día.';

  @override
  String careScreenSleepTimeRange(String wentToBed, String wokeUp) {
    return '$wentToBed - $wokeUp';
  }

  @override
  String careScreenSleepQuality(String quality, String duration) {
    return 'Calidad: $quality $duration';
  }

  @override
  String careScreenSleepNaps(String naps) {
    return 'Siestas: $naps';
  }

  @override
  String get careScreenTooltipEditSleep => 'Editar Entrada de Sueño';

  @override
  String get careScreenTooltipDeleteSleep => 'Eliminar Entrada de Sueño';

  @override
  String get careScreenButtonAddSleep => 'Añadir Sueño';

  @override
  String get careScreenSectionTitleFoodWater => 'Ingesta de Comida y Agua';

  @override
  String get careScreenNoFoodWaterLogged =>
      'No se ha registrado ingesta de comida o agua para este día.';

  @override
  String errorEnterValidEmailPasswordMinLength(int minLength) {
    return 'Por favor, ingrese un correo electrónico válido y una contraseña (mínimo $minLength caracteres).';
  }

  @override
  String get errorSignUpFailedDefault =>
      'Registro fallido. Por favor, inténtelo de nuevo o verifique su conexión de red.';

  @override
  String get signUpScreenTitle => 'Crear Cuenta';

  @override
  String get createAccountTitle => 'Crear su Cuenta';

  @override
  String get signUpButton => 'Registrarse';

  @override
  String get termElderDefault => 'Receptor de Cuidados';

  @override
  String get formErrorGenericSaveUpdate =>
      'Error al guardar o actualizar. Por favor, inténtelo de nuevo.';

  @override
  String get formSuccessActivitySaved => 'Actividad guardada correctamente.';

  @override
  String get formSuccessActivityUpdated =>
      'Actividad actualizada correctamente.';

  @override
  String get formSuccessExpenseSaved => 'Gasto guardado correctamente.';

  @override
  String get formSuccessExpenseUpdated => 'Gasto actualizado correctamente.';

  @override
  String get formSuccessMealSaved => 'Comida guardada correctamente.';

  @override
  String get formSuccessMealUpdated => 'Comida actualizada correctamente.';

  @override
  String get formSuccessMedSaved => 'Medicación guardada correctamente.';

  @override
  String get formSuccessMedUpdated => 'Medicación actualizada correctamente.';

  @override
  String get formSuccessMoodSaved => 'Estado de ánimo guardado correctamente.';

  @override
  String get formSuccessMoodUpdated =>
      'Estado de ánimo actualizado correctamente.';

  @override
  String get formSuccessPainSaved =>
      'Registro de dolor guardado correctamente.';

  @override
  String get formSuccessPainUpdated =>
      'Registro de dolor actualizado correctamente.';

  @override
  String get formSuccessSleepSaved =>
      'Registro de sueño guardado correctamente.';

  @override
  String get formSuccessSleepUpdated =>
      'Registro de sueño actualizado correctamente.';

  @override
  String get formSuccessVitalSaved => 'Signo vital guardado correctamente.';

  @override
  String get formSuccessVitalUpdated =>
      'Signo vital actualizado correctamente.';

  @override
  String get formErrorNoItemToDelete => 'No hay elemento para eliminar.';

  @override
  String get formConfirmDeleteTitle => 'Confirmar Eliminación';

  @override
  String get formConfirmDeleteVitalMessage =>
      '¿Está seguro de que desea eliminar este registro de signo vital?';

  @override
  String get formSuccessVitalDeleted => 'Registro de signo vital eliminado.';

  @override
  String get formErrorFailedToDeleteVital =>
      'No se pudo eliminar el registro de signo vital.';

  @override
  String get formTooltipDeleteVital => 'Eliminar signo vital';

  @override
  String get formConfirmDeleteMealMessage =>
      '¿Está seguro de que desea eliminar este registro de comida?';

  @override
  String get formSuccessMealDeleted => 'Registro de comida eliminado.';

  @override
  String get formErrorFailedToDeleteMeal =>
      'No se pudo eliminar el registro de comida.';

  @override
  String get formTooltipDeleteMeal => 'Eliminar comida';

  @override
  String get goToTodayButtonLabel => 'Ir a Hoy';

  @override
  String get formConfirmDeleteMedMessage =>
      '¿Está seguro de que desea eliminar este registro de medicación?';

  @override
  String get formSuccessMedDeleted => 'Registro de medicación eliminado.';

  @override
  String get formErrorFailedToDeleteMed =>
      'No se pudo eliminar el registro de medicación.';

  @override
  String get formTooltipDeleteMed => 'Eliminar medicación';

  @override
  String get formConfirmDeleteMoodMessage =>
      '¿Está seguro de que desea eliminar este registro de estado de ánimo?';

  @override
  String get formSuccessMoodDeleted => 'Registro de estado de ánimo eliminado.';

  @override
  String get formErrorFailedToDeleteMood =>
      'No se pudo eliminar el registro de estado de ánimo.';

  @override
  String get formTooltipDeleteMood => 'Eliminar estado de ánimo';

  @override
  String get formConfirmDeletePainMessage =>
      '¿Está seguro de que desea eliminar este registro de dolor?';

  @override
  String get formSuccessPainDeleted => 'Registro de dolor eliminado.';

  @override
  String get formErrorFailedToDeletePain =>
      'No se pudo eliminar el registro de dolor.';

  @override
  String get formTooltipDeletePain => 'Eliminar dolor';

  @override
  String get formConfirmDeleteActivityMessage =>
      '¿Está seguro de que desea eliminar este registro de actividad?';

  @override
  String get formSuccessActivityDeleted => 'Registro de actividad eliminado.';

  @override
  String get formErrorFailedToDeleteActivity =>
      'No se pudo eliminar el registro de actividad.';

  @override
  String get formTooltipDeleteActivity => 'Eliminar actividad';

  @override
  String get formConfirmDeleteSleepMessage =>
      '¿Está seguro de que desea eliminar este registro de sueño?';

  @override
  String get formSuccessSleepDeleted => 'Registro de sueño eliminado.';

  @override
  String get formErrorFailedToDeleteSleep =>
      'No se pudo eliminar el registro de sueño.';

  @override
  String get formTooltipDeleteSleep => 'Eliminar sueño';

  @override
  String get formConfirmDeleteExpenseMessage =>
      '¿Está seguro de que desea eliminar este registro de gasto?';

  @override
  String get formSuccessExpenseDeleted => 'Registro de gasto eliminado.';

  @override
  String get formErrorFailedToDeleteExpense =>
      'No se pudo eliminar el registro de gasto.';

  @override
  String get formTooltipDeleteExpense => 'Eliminar gasto';

  @override
  String get userSelectorSendToLabel => 'Enviar a:';

  @override
  String get userSelectorAudienceAll => 'Todos los Usuarios';

  @override
  String get userSelectorAudienceSpecific => 'Usuarios Específicos';

  @override
  String get userSelectorNoUsersAvailable =>
      'No hay otros usuarios disponibles para seleccionar.';

  @override
  String get timelinePostingToAll => 'Publicando para: Todos los usuarios';

  @override
  String timelinePostingToCount(String count) {
    return 'Publicando para: $count usuarios específicos';
  }

  @override
  String get timelinePrivateMessageIndicator => 'Mensaje Privado';

  @override
  String get timelineEditMessage => 'Editar Mensaje';

  @override
  String get timelineDeleteMessage => 'Eliminar Mensaje';

  @override
  String get timelineConfirmDeleteMessageTitle => '¿Eliminar Mensaje?';

  @override
  String get timelineConfirmDeleteMessageContent =>
      '¿Está seguro de que desea eliminar este mensaje?';

  @override
  String get timelineMessageDeletedSuccess => 'Mensaje eliminado.';

  @override
  String timelineErrorDeletingMessage(String errorMessage) {
    return 'Error al eliminar el mensaje: $errorMessage';
  }

  @override
  String get timelineMessageUpdatedSuccess => 'Mensaje actualizado.';

  @override
  String timelineErrorUpdatingMessage(String errorMessage) {
    return 'Error al actualizar el mensaje: $errorMessage';
  }

  @override
  String get timelineUpdateButton => 'Actualizar';

  @override
  String get timelineHideMessage => 'Ocultar Mensaje';

  @override
  String get timelineMessageHiddenSuccess => 'Mensaje ocultado de tu vista.';

  @override
  String get timelineShowHiddenMessagesButton => 'Mostrar Ocultos';

  @override
  String get timelineHideHiddenMessagesButton => 'Mostrar Todos';

  @override
  String get timelineUnhideMessage => 'Mostrar Mensaje';

  @override
  String get timelineMessageUnhiddenSuccess => 'Mensaje mostrado.';

  @override
  String get timelineNoHiddenMessages =>
      'No tiene mensajes ocultos para esta cronología.';

  @override
  String get selfCareScreenTitle => 'Autocuidado';

  @override
  String get settingsTitleNotificationPreferences =>
      'Configuración de Notificaciones';

  @override
  String get settingsItemNotificationPreferences =>
      'Preferencias de Notificación';

  @override
  String get landingPageAlreadyLoggedIn => 'Ya has iniciado sesión.';

  @override
  String get manageMedications => 'Gestionar Medicamentos';

  @override
  String get medicationsScreenTitleGeneric => 'Medicamentos';

  @override
  String medicationsScreenTitleForElder(String name) {
    return 'Medicamentos de $name';
  }

  @override
  String get medicationsSearchHint => 'Buscar nombre del medicamento';

  @override
  String get medicationsDoseHint => 'Ej: 10 mg';

  @override
  String get medicationsScheduleHint => 'Ej: AM / PM';

  @override
  String get medicationsListEmpty => 'Aún no hay medicamentos añadidos';

  @override
  String get medicationsDoseNotSet => 'Dosis no establecida';

  @override
  String get medicationsScheduleNotSet => 'Horario no establecido';

  @override
  String get medicationsTooltipDelete => 'Eliminar medicamento';

  @override
  String medicationsConfirmDeleteTitle(String medName) {
    return '¿Eliminar \'$medName\'?';
  }

  @override
  String get medicationsConfirmDeleteContent => 'Esto no se puede deshacer.';

  @override
  String medicationsDeletedSuccess(String medName) {
    return 'Medicamento \'$medName\' eliminado.';
  }

  @override
  String get rxNavGenericSearchError =>
      'No se pudo obtener la lista de medicamentos. Inténtelo de nuevo.';

  @override
  String get medicationsValidationNameRequired => 'Nombre requerido';

  @override
  String get medicationsValidationDoseRequired => 'Dosis requerida';

  @override
  String get medicationsInteractionsFoundTitle =>
      'Posibles interacciones encontradas';

  @override
  String get medicationsNoInteractionsFound =>
      'No se encontraron interacciones';

  @override
  String get medicationsInteractionsSaveAnyway => 'Guardar de todos modos';

  @override
  String get medicationsAddDialogTitle => 'Añadir medicamento';

  @override
  String medicationsAddedSuccess(String medName) {
    return 'Medicamento \'$medName\' añadido.';
  }

  @override
  String get routeErrorGenericMessage =>
      'Algo salió mal. Por favor, inténtelo de nuevo.';

  @override
  String get goHomeButton => 'Ir a Inicio';

  @override
  String get settingsTitleHelpfulResources => 'Recursos Útiles';

  @override
  String get settingsItemHelpfulResources => 'Ver Recursos Útiles';

  @override
  String get timelineFilterOnlyMyLogs => 'Solo Mis Registros:';

  @override
  String get timelineFilterFromDate => 'Desde';

  @override
  String get timelineFilterToDate => 'Hasta';

  @override
  String get medicationsInteractionsSectionTitle => 'Interacciones';

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
