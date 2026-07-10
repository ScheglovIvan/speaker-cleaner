import 'package:flutter/widgets.dart';

import '../state/language_state.dart';

/// Inherited scope that re-localizes the UI when the selected language changes.
///
/// It wraps the whole app (installed in `MaterialApp.builder`, above the
/// Navigator) and is bound to [LanguageState] via [InheritedNotifier]. Any
/// widget that reads a string through `context.l10n` registers as a dependent,
/// so a [LanguageState.setLanguage] / `notifyListeners()` rebuilds every visible
/// screen — including pushed routes — in the new language with no restart.
class LanguageScope extends InheritedNotifier<LanguageState> {
  const LanguageScope({
    super.key,
    required LanguageState state,
    required Widget child,
  }) : super(notifier: state, child: child);

  /// Current locale code, registering the caller as a dependent so it rebuilds
  /// on language change.
  static String codeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    return (scope?.notifier ?? LanguageState.instance).code;
  }
}

/// A translator bound to one locale code. Obtain via `context.l10n`.
///
/// [tr] returns the translation of an English source string for the active
/// language, falling back to the English source when a translation is missing
/// (so partially-translated screens still render cleanly).
class AppStrings {
  const AppStrings(this.code);

  final String code;

  String tr(String source) {
    if (code == 'en') return source;
    final row = _kStrings[source];
    if (row == null) return source;
    return row[code] ?? source;
  }
}

/// `context.l10n.tr('English source')` — the ergonomic entry point used by
/// every screen. Reading it subscribes the widget to language changes.
extension L10nContext on BuildContext {
  AppStrings get l10n => AppStrings(LanguageScope.codeOf(this));
}

/// Translation table, keyed by the English source string, then by locale code.
///
/// Locales: vi, zh-Hans, zh-Hant, fr, de, it, nl, ru, es, pt, ja, ko.
/// English is the source and is returned as-is (never stored here). Missing
/// entries fall back to the English source.
const Map<String, Map<String, String>> _kStrings = <String, Map<String, String>>{
  // ---- Bottom tab bar ------------------------------------------------------
  'Cleaner': {
    'vi': 'Vệ sinh', 'zh-Hans': '清洁', 'zh-Hant': '清潔', 'fr': 'Nettoyage',
    'de': 'Reiniger', 'it': 'Pulizia', 'nl': 'Reiniger', 'ru': 'Очистка',
    'es': 'Limpiador', 'pt': 'Limpeza', 'ja': 'クリーナー', 'ko': '클리너',
  },
  'Mode': {
    'vi': 'Chế độ', 'zh-Hans': '模式', 'zh-Hant': '模式', 'fr': 'Mode',
    'de': 'Modus', 'it': 'Modalità', 'nl': 'Modus', 'ru': 'Режим',
    'es': 'Modo', 'pt': 'Modo', 'ja': 'モード', 'ko': '모드',
  },
  'dB Meter': {
    'vi': 'Đo dB', 'zh-Hans': '分贝仪', 'zh-Hant': '分貝儀', 'fr': 'Sonomètre',
    'de': 'dB-Messer', 'it': 'Misuratore dB', 'nl': 'dB-meter', 'ru': 'Шумомер',
    'es': 'Medidor dB', 'pt': 'Medidor dB', 'ja': 'dBメーター', 'ko': 'dB 측정기',
  },
  'Stereo': {
    'vi': 'Âm thanh nổi', 'zh-Hans': '立体声', 'zh-Hant': '立體聲', 'fr': 'Stéréo',
    'de': 'Stereo', 'it': 'Stereo', 'nl': 'Stereo', 'ru': 'Стерео',
    'es': 'Estéreo', 'pt': 'Estéreo', 'ja': 'ステレオ', 'ko': '스테레오',
  },

  // ---- Settings (0003) -----------------------------------------------------
  'Settings': {
    'vi': 'Cài đặt', 'zh-Hans': '设置', 'zh-Hant': '設定', 'fr': 'Réglages',
    'de': 'Einstellungen', 'it': 'Impostazioni', 'nl': 'Instellingen',
    'ru': 'Настройки', 'es': 'Ajustes', 'pt': 'Configurações', 'ja': '設定',
    'ko': '설정',
  },
  'Full access to all features': {
    'vi': 'Toàn quyền truy cập mọi tính năng', 'zh-Hans': '完整使用所有功能',
    'zh-Hant': '完整使用所有功能', 'fr': 'Accès complet à toutes les fonctions',
    'de': 'Voller Zugriff auf alle Funktionen',
    'it': 'Accesso completo a tutte le funzioni',
    'nl': 'Volledige toegang tot alle functies',
    'ru': 'Полный доступ ко всем функциям',
    'es': 'Acceso completo a todas las funciones',
    'pt': 'Acesso completo a todos os recursos', 'ja': 'すべての機能にフルアクセス',
    'ko': '모든 기능 전체 이용',
  },
  'Get Pro': {
    'vi': 'Nâng cấp Pro', 'zh-Hans': '获取 Pro', 'zh-Hant': '取得 Pro',
    'fr': 'Passer à Pro', 'de': 'Pro holen', 'it': 'Ottieni Pro',
    'nl': 'Pro halen', 'ru': 'Получить Pro', 'es': 'Obtener Pro',
    'pt': 'Obter Pro', 'ja': 'Pro を入手', 'ko': 'Pro 받기',
  },
  'Change Language': {
    'vi': 'Đổi ngôn ngữ', 'zh-Hans': '更改语言', 'zh-Hant': '更改語言',
    'fr': 'Changer de langue', 'de': 'Sprache ändern', 'it': 'Cambia lingua',
    'nl': 'Taal wijzigen', 'ru': 'Изменить язык', 'es': 'Cambiar idioma',
    'pt': 'Alterar idioma', 'ja': '言語を変更', 'ko': '언어 변경',
  },
  'Select your preferred language': {
    'vi': 'Chọn ngôn ngữ ưa thích của bạn', 'zh-Hans': '选择您偏好的语言',
    'zh-Hant': '選擇您偏好的語言', 'fr': 'Sélectionnez votre langue préférée',
    'de': 'Wähle deine bevorzugte Sprache',
    'it': 'Seleziona la tua lingua preferita', 'nl': 'Kies je voorkeurstaal',
    'ru': 'Выберите предпочитаемый язык',
    'es': 'Selecciona tu idioma preferido',
    'pt': 'Selecione seu idioma preferido', 'ja': '使用する言語を選択',
    'ko': '선호하는 언어를 선택하세요',
  },
  'Share App': {
    'vi': 'Chia sẻ ứng dụng', 'zh-Hans': '分享应用', 'zh-Hant': '分享應用程式',
    'fr': "Partager l'app", 'de': 'App teilen', 'it': "Condividi l'app",
    'nl': 'App delen', 'ru': 'Поделиться приложением', 'es': 'Compartir app',
    'pt': 'Compartilhar app', 'ja': 'アプリを共有', 'ko': '앱 공유',
  },
  'Share this app with friends': {
    'vi': 'Chia sẻ ứng dụng này với bạn bè', 'zh-Hans': '与朋友分享此应用',
    'zh-Hant': '與朋友分享此應用程式', 'fr': 'Partagez cette app avec vos amis',
    'de': 'Teile diese App mit Freunden',
    'it': 'Condividi questa app con gli amici',
    'nl': 'Deel deze app met vrienden',
    'ru': 'Поделитесь приложением с друзьями',
    'es': 'Comparte esta app con amigos',
    'pt': 'Compartilhe este app com amigos', 'ja': 'このアプリを友達と共有',
    'ko': '친구에게 이 앱 공유',
  },
  'Feedback': {
    'vi': 'Phản hồi', 'zh-Hans': '反馈', 'zh-Hant': '意見回饋',
    'fr': 'Commentaires', 'de': 'Feedback', 'it': 'Feedback', 'nl': 'Feedback',
    'ru': 'Отзыв', 'es': 'Comentarios', 'pt': 'Feedback', 'ja': 'フィードバック',
    'ko': '피드백',
  },
  'Tell us what you think': {
    'vi': 'Hãy cho chúng tôi biết ý kiến của bạn', 'zh-Hans': '告诉我们您的想法',
    'zh-Hant': '告訴我們您的想法', 'fr': 'Dites-nous ce que vous pensez',
    'de': 'Sag uns deine Meinung', 'it': 'Dicci cosa ne pensi',
    'nl': 'Vertel ons wat je denkt', 'ru': 'Расскажите, что вы думаете',
    'es': 'Cuéntanos qué opinas', 'pt': 'Diga-nos o que você acha',
    'ja': 'ご意見をお聞かせください', 'ko': '의견을 알려주세요',
  },

  // ---- Language (0004) -----------------------------------------------------
  'Language': {
    'vi': 'Ngôn ngữ', 'zh-Hans': '语言', 'zh-Hant': '語言', 'fr': 'Langue',
    'de': 'Sprache', 'it': 'Lingua', 'nl': 'Taal', 'ru': 'Язык',
    'es': 'Idioma', 'pt': 'Idioma', 'ja': '言語', 'ko': '언어',
  },
  'Save': {
    'vi': 'Lưu', 'zh-Hans': '保存', 'zh-Hant': '儲存', 'fr': 'Enregistrer',
    'de': 'Speichern', 'it': 'Salva', 'nl': 'Opslaan', 'ru': 'Сохранить',
    'es': 'Guardar', 'pt': 'Salvar', 'ja': '保存', 'ko': '저장',
  },

  // ---- Home (0011) ---------------------------------------------------------
  'Tips & Test Speaker': {
    'vi': 'Mẹo & Kiểm tra loa', 'zh-Hans': '提示与扬声器测试',
    'zh-Hant': '提示與喇叭測試', 'fr': 'Conseils et test du haut-parleur',
    'de': 'Tipps & Lautsprechertest', 'it': 'Consigli e test altoparlante',
    'nl': 'Tips & Luidspreker testen', 'ru': 'Советы и проверка динамика',
    'es': 'Consejos y prueba del altavoz', 'pt': 'Dicas e teste do alto-falante',
    'ja': 'ヒントとスピーカーテスト', 'ko': '팁 및 스피커 테스트',
  },
  'Follow simple steps to clean your speaker better.': {
    'vi': 'Làm theo các bước đơn giản để vệ sinh loa tốt hơn.',
    'zh-Hans': '按照简单步骤更好地清洁扬声器。',
    'zh-Hant': '按照簡單步驟更好地清潔喇叭。',
    'fr': 'Suivez des étapes simples pour mieux nettoyer votre haut-parleur.',
    'de': 'Folge einfachen Schritten, um deinen Lautsprecher besser zu reinigen.',
    'it': "Segui semplici passaggi per pulire meglio l'altoparlante.",
    'nl': 'Volg eenvoudige stappen om je luidspreker beter te reinigen.',
    'ru': 'Следуйте простым шагам, чтобы лучше очистить динамик.',
    'es': 'Sigue pasos sencillos para limpiar mejor tu altavoz.',
    'pt': 'Siga passos simples para limpar melhor o alto-falante.',
    'ja': '簡単な手順でスピーカーをより良く清掃しましょう。',
    'ko': '간단한 단계로 스피커를 더 깨끗하게 청소하세요.',
  },
  "Start Today's Routine": {
    'vi': 'Bắt đầu bài hôm nay', 'zh-Hans': '开始今日程序',
    'zh-Hant': '開始今日程序', 'fr': 'Commencer la routine du jour',
    'de': 'Heutige Routine starten', 'it': 'Inizia la routine di oggi',
    'nl': 'Routine van vandaag starten', 'ru': 'Начать сегодняшнюю программу',
    'es': 'Iniciar la rutina de hoy', 'pt': 'Iniciar rotina de hoje',
    'ja': '今日のルーティンを開始', 'ko': '오늘의 루틴 시작',
  },
  'Run Again': {
    'vi': 'Chạy lại', 'zh-Hans': '再次运行', 'zh-Hant': '再次執行',
    'fr': 'Relancer', 'de': 'Erneut ausführen', 'it': 'Riavvia',
    'nl': 'Opnieuw uitvoeren', 'ru': 'Запустить снова', 'es': 'Ejecutar de nuevo',
    'pt': 'Executar novamente', 'ja': 'もう一度実行', 'ko': '다시 실행',
  },

  // ---- Modes (0012) --------------------------------------------------------
  'Clean Dust': {
    'vi': 'Làm sạch bụi', 'zh-Hans': '清除灰尘', 'zh-Hant': '清除灰塵',
    'fr': 'Nettoyer la poussière', 'de': 'Staub entfernen',
    'it': 'Pulisci la polvere', 'nl': 'Stof verwijderen', 'ru': 'Очистка от пыли',
    'es': 'Limpiar polvo', 'pt': 'Limpar poeira', 'ja': 'ほこりを除去',
    'ko': '먼지 청소',
  },
  'Clear your speaker for better sound': {
    'vi': 'Làm sạch loa để âm thanh tốt hơn', 'zh-Hans': '清理扬声器，获得更好音质',
    'zh-Hant': '清理喇叭，獲得更好音質',
    'fr': 'Dégagez votre haut-parleur pour un meilleur son',
    'de': 'Reinige deinen Lautsprecher für besseren Klang',
    'it': "Libera l'altoparlante per un suono migliore",
    'nl': 'Maak je luidspreker vrij voor beter geluid',
    'ru': 'Очистите динамик для лучшего звука',
    'es': 'Despeja tu altavoz para un mejor sonido',
    'pt': 'Limpe seu alto-falante para um som melhor',
    'ja': 'スピーカーをきれいにして音質を向上', 'ko': '스피커를 청소해 더 좋은 소리를',
  },
  'Vibrate Cleaner': {
    'vi': 'Vệ sinh rung', 'zh-Hans': '震动清洁', 'zh-Hant': '震動清潔',
    'fr': 'Nettoyage par vibration', 'de': 'Vibrationsreiniger',
    'it': 'Pulizia a vibrazione', 'nl': 'Trilreiniger', 'ru': 'Виброочистка',
    'es': 'Limpiador por vibración', 'pt': 'Limpeza por vibração',
    'ja': '振動クリーナー', 'ko': '진동 클리너',
  },
  'Use vibration to push out dust and water': {
    'vi': 'Dùng rung để đẩy bụi và nước ra ngoài', 'zh-Hans': '用震动排出灰尘和水',
    'zh-Hant': '用震動排出灰塵和水',
    'fr': 'Utilisez la vibration pour expulser poussière et eau',
    'de': 'Nutze Vibration, um Staub und Wasser auszustoßen',
    'it': 'Usa la vibrazione per espellere polvere e acqua',
    'nl': 'Gebruik trillingen om stof en water eruit te duwen',
    'ru': 'Вибрация выталкивает пыль и воду',
    'es': 'Usa la vibración para expulsar polvo y agua',
    'pt': 'Use a vibração para expelir poeira e água',
    'ja': '振動でほこりと水を押し出す', 'ko': '진동으로 먼지와 물을 밀어내기',
  },
  'Blow to Clean': {
    'vi': 'Thổi để làm sạch', 'zh-Hans': '吹气清洁', 'zh-Hant': '吹氣清潔',
    'fr': 'Souffler pour nettoyer', 'de': 'Reinigen durch Blasen',
    'it': 'Soffia per pulire', 'nl': 'Blazen om te reinigen',
    'ru': 'Продувка для очистки', 'es': 'Soplar para limpiar',
    'pt': 'Soprar para limpar', 'ja': '吹き飛ばして清掃', 'ko': '불어서 청소',
  },
  'Clean your speaker with air sound': {
    'vi': 'Làm sạch loa bằng âm thanh gió', 'zh-Hans': '用气流声清洁扬声器',
    'zh-Hant': '用氣流聲清潔喇叭',
    'fr': "Nettoyez votre haut-parleur avec un son d'air",
    'de': 'Reinige deinen Lautsprecher mit Luftschall',
    'it': "Pulisci l'altoparlante con il suono dell'aria",
    'nl': 'Reinig je luidspreker met luchtgeluid',
    'ru': 'Очистите динамик звуком воздуха',
    'es': 'Limpia tu altavoz con sonido de aire',
    'pt': 'Limpe seu alto-falante com som de ar',
    'ja': '空気音でスピーカーを清掃', 'ko': '바람 소리로 스피커 청소',
  },

  // ---- Stereo (0002) -------------------------------------------------------
  'Stereo Mixer': {
    'vi': 'Bộ trộn âm nổi', 'zh-Hans': '立体声混音器', 'zh-Hant': '立體聲混音器',
    'fr': 'Mixeur stéréo', 'de': 'Stereo-Mixer', 'it': 'Mixer stereo',
    'nl': 'Stereomixer', 'ru': 'Стереомикшер', 'es': 'Mezclador estéreo',
    'pt': 'Mixer estéreo', 'ja': 'ステレオミキサー', 'ko': '스테레오 믹서',
  },
  'Active Channels': {
    'vi': 'Kênh đang hoạt động', 'zh-Hans': '活动声道', 'zh-Hant': '使用中的聲道',
    'fr': 'Canaux actifs', 'de': 'Aktive Kanäle', 'it': 'Canali attivi',
    'nl': 'Actieve kanalen', 'ru': 'Активные каналы', 'es': 'Canales activos',
    'pt': 'Canais ativos', 'ja': 'アクティブなチャンネル', 'ko': '활성 채널',
  },
  'Left Speaker': {
    'vi': 'Loa trái', 'zh-Hans': '左扬声器', 'zh-Hant': '左喇叭',
    'fr': 'Haut-parleur gauche', 'de': 'Linker Lautsprecher',
    'it': 'Altoparlante sinistro', 'nl': 'Linkerluidspreker',
    'ru': 'Левый динамик', 'es': 'Altavoz izquierdo',
    'pt': 'Alto-falante esquerdo', 'ja': '左スピーカー', 'ko': '왼쪽 스피커',
  },
  'Right Speaker': {
    'vi': 'Loa phải', 'zh-Hans': '右扬声器', 'zh-Hant': '右喇叭',
    'fr': 'Haut-parleur droit', 'de': 'Rechter Lautsprecher',
    'it': 'Altoparlante destro', 'nl': 'Rechterluidspreker',
    'ru': 'Правый динамик', 'es': 'Altavoz derecho',
    'pt': 'Alto-falante direito', 'ja': '右スピーカー', 'ko': '오른쪽 스피커',
  },
  'Top Earpiece': {
    'vi': 'Loa thoại trên', 'zh-Hans': '顶部听筒', 'zh-Hant': '頂部聽筒',
    'fr': 'Écouteur supérieur', 'de': 'Oberer Hörer',
    'it': 'Auricolare superiore', 'nl': 'Bovenste oorluidspreker',
    'ru': 'Верхний динамик', 'es': 'Auricular superior',
    'pt': 'Alto-falante superior', 'ja': '上部イヤピース', 'ko': '상단 수화부',
  },
  'Auto Cycle': {
    'vi': 'Tự động luân phiên', 'zh-Hans': '自动循环', 'zh-Hant': '自動循環',
    'fr': 'Cycle auto', 'de': 'Auto-Zyklus', 'it': 'Ciclo automatico',
    'nl': 'Auto-cyclus', 'ru': 'Автоцикл', 'es': 'Ciclo automático',
    'pt': 'Ciclo automático', 'ja': '自動サイクル', 'ko': '자동 순환',
  },
  'Stop': {
    'vi': 'Dừng', 'zh-Hans': '停止', 'zh-Hant': '停止', 'fr': 'Arrêter',
    'de': 'Stopp', 'it': 'Ferma', 'nl': 'Stop', 'ru': 'Стоп', 'es': 'Detener',
    'pt': 'Parar', 'ja': '停止', 'ko': '정지',
  },

  // ---- Before You Start (0008/0009) ---------------------------------------
  'Before You Start': {
    'vi': 'Trước khi bắt đầu', 'zh-Hans': '开始之前', 'zh-Hant': '開始之前',
    'fr': 'Avant de commencer', 'de': 'Bevor du beginnst',
    'it': 'Prima di iniziare', 'nl': 'Voordat je begint', 'ru': 'Перед началом',
    'es': 'Antes de empezar', 'pt': 'Antes de começar', 'ja': '始める前に',
    'ko': '시작하기 전에',
  },
  'Set volume to maximum': {
    'vi': 'Đặt âm lượng tối đa', 'zh-Hans': '将音量调到最大',
    'zh-Hant': '將音量調到最大', 'fr': 'Réglez le volume au maximum',
    'de': 'Lautstärke auf Maximum stellen', 'it': 'Imposta il volume al massimo',
    'nl': 'Zet het volume op maximaal', 'ru': 'Установите максимальную громкость',
    'es': 'Sube el volumen al máximo', 'pt': 'Coloque o volume no máximo',
    'ja': '音量を最大にする', 'ko': '볼륨을 최대로 설정',
  },
  'Generate strong vibration power': {
    'vi': 'Tạo lực rung mạnh', 'zh-Hans': '产生强劲震动', 'zh-Hant': '產生強勁震動',
    'fr': 'Générez une forte puissance de vibration',
    'de': 'Erzeuge starke Vibrationskraft',
    'it': 'Genera una forte potenza di vibrazione',
    'nl': 'Genereer sterke trilkracht', 'ru': 'Создайте мощную вибрацию',
    'es': 'Genera una fuerte potencia de vibración',
    'pt': 'Gere forte potência de vibração', 'ja': '強い振動を発生させる',
    'ko': '강한 진동을 생성',
  },
  'Place speaker facing down': {
    'vi': 'Đặt loa hướng xuống', 'zh-Hans': '将扬声器朝下放置',
    'zh-Hant': '將喇叭朝下放置', 'fr': 'Placez le haut-parleur vers le bas',
    'de': 'Lautsprecher nach unten richten',
    'it': "Posiziona l'altoparlante rivolto verso il basso",
    'nl': 'Plaats de luidspreker naar beneden', 'ru': 'Расположите динамик вниз',
    'es': 'Coloca el altavoz hacia abajo',
    'pt': 'Coloque o alto-falante voltado para baixo',
    'ja': 'スピーカーを下向きに置く', 'ko': '스피커를 아래로 향하게 놓기',
  },
  'Help debris move out of the grill.': {
    'vi': 'Giúp cặn bẩn thoát khỏi lưới loa.', 'zh-Hans': '帮助碎屑排出扬声器网。',
    'zh-Hant': '幫助碎屑排出喇叭網。', 'fr': 'Aide les débris à sortir de la grille.',
    'de': 'Hilft, Schmutz aus dem Gitter zu befördern.',
    'it': 'Aiuta i detriti a uscire dalla griglia.',
    'nl': 'Helpt vuil uit het rooster te bewegen.',
    'ru': 'Помогает мусору выйти из решётки.',
    'es': 'Ayuda a que la suciedad salga de la rejilla.',
    'pt': 'Ajuda os resíduos a saírem da grade.',
    'ja': 'ゴミがグリルから出るのを助けます。',
    'ko': '이물질이 그릴 밖으로 나오도록 돕습니다.',
  },
  'Keep device on a flat surface': {
    'vi': 'Giữ thiết bị trên bề mặt phẳng', 'zh-Hans': '将设备放在平面上',
    'zh-Hant': '將裝置放在平面上', 'fr': 'Gardez l’appareil sur une surface plane',
    'de': 'Gerät auf einer ebenen Fläche halten',
    'it': 'Tieni il dispositivo su una superficie piana',
    'nl': 'Houd het apparaat op een vlakke ondergrond',
    'ru': 'Держите устройство на ровной поверхности',
    'es': 'Mantén el dispositivo en una superficie plana',
    'pt': 'Mantenha o dispositivo em uma superfície plana',
    'ja': 'デバイスを平らな面に置く', 'ko': '기기를 평평한 곳에 두기',
  },
  'Maintain stable vibration.': {
    'vi': 'Duy trì rung ổn định.', 'zh-Hans': '保持稳定震动。',
    'zh-Hant': '保持穩定震動。', 'fr': 'Maintient une vibration stable.',
    'de': 'Sorgt für stabile Vibration.', 'it': 'Mantiene una vibrazione stabile.',
    'nl': 'Houdt de trilling stabiel.',
    'ru': 'Обеспечивает стабильную вибрацию.',
    'es': 'Mantiene una vibración estable.',
    'pt': 'Mantém uma vibração estável.', 'ja': '安定した振動を保ちます。',
    'ko': '안정적인 진동을 유지합니다.',
  },
  'Start Cleaning': {
    'vi': 'Bắt đầu vệ sinh', 'zh-Hans': '开始清洁', 'zh-Hant': '開始清潔',
    'fr': 'Commencer le nettoyage', 'de': 'Reinigung starten',
    'it': 'Inizia la pulizia', 'nl': 'Reiniging starten', 'ru': 'Начать очистку',
    'es': 'Comenzar limpieza', 'pt': 'Começar limpeza', 'ja': '清掃を開始',
    'ko': '청소 시작',
  },
  'Preparing…': {
    'vi': 'Đang chuẩn bị…', 'zh-Hans': '正在准备…', 'zh-Hant': '正在準備…',
    'fr': 'Préparation…', 'de': 'Wird vorbereitet…', 'it': 'Preparazione…',
    'nl': 'Voorbereiden…', 'ru': 'Подготовка…', 'es': 'Preparando…',
    'pt': 'Preparando…', 'ja': '準備中…', 'ko': '준비 중…',
  },

  // ---- 7-Day Plan (0006/0010) ---------------------------------------------
  '7-Day Cleaning Plan': {
    'vi': 'Kế hoạch vệ sinh 7 ngày', 'zh-Hans': '7天清洁计划',
    'zh-Hant': '7天清潔計畫', 'fr': 'Programme de nettoyage de 7 jours',
    'de': '7-Tage-Reinigungsplan', 'it': 'Piano di pulizia di 7 giorni',
    'nl': '7-daags reinigingsplan', 'ru': '7-дневный план очистки',
    'es': 'Plan de limpieza de 7 días', 'pt': 'Plano de limpeza de 7 dias',
    'ja': '7日間クリーニングプラン', 'ko': '7일 청소 플랜',
  },
  'Complete 7 days to fully refresh your speakers': {
    'vi': 'Hoàn thành 7 ngày để làm mới loa hoàn toàn',
    'zh-Hans': '完成7天，彻底焕新您的扬声器', 'zh-Hant': '完成7天，徹底煥新您的喇叭',
    'fr': 'Terminez 7 jours pour rafraîchir complètement vos haut-parleurs',
    'de': 'Schließe 7 Tage ab, um deine Lautsprecher vollständig aufzufrischen',
    'it': 'Completa 7 giorni per rinfrescare completamente gli altoparlanti',
    'nl': 'Voltooi 7 dagen om je luidsprekers volledig te verfrissen',
    'ru': 'Пройдите 7 дней, чтобы полностью обновить динамики',
    'es': 'Completa 7 días para renovar por completo tus altavoces',
    'pt': 'Complete 7 dias para renovar totalmente seus alto-falantes',
    'ja': '7日間を完了してスピーカーを完全にリフレッシュ',
    'ko': '7일을 완료해 스피커를 완전히 새롭게',
  },

  // ---- Paywall (0001) ------------------------------------------------------
  '3-DAY FREE TRIAL': {
    'vi': 'DÙNG THỬ MIỄN PHÍ 3 NGÀY', 'zh-Hans': '3天免费试用',
    'zh-Hant': '3天免費試用', 'fr': 'ESSAI GRATUIT DE 3 JOURS',
    'de': '3 TAGE KOSTENLOS TESTEN', 'it': 'PROVA GRATUITA DI 3 GIORNI',
    'nl': '3 DAGEN GRATIS PROBEREN', 'ru': '3 ДНЯ БЕСПЛАТНО',
    'es': 'PRUEBA GRATIS DE 3 DÍAS', 'pt': 'TESTE GRÁTIS DE 3 DIAS',
    'ja': '3日間無料トライアル', 'ko': '3일 무료 체험',
  },
  'Start Free Trial': {
    'vi': 'Bắt đầu dùng thử miễn phí', 'zh-Hans': '开始免费试用',
    'zh-Hant': '開始免費試用', 'fr': "Commencer l'essai gratuit",
    'de': 'Kostenlose Testphase starten', 'it': 'Inizia la prova gratuita',
    'nl': 'Gratis proefperiode starten', 'ru': 'Начать бесплатный период',
    'es': 'Iniciar prueba gratuita', 'pt': 'Iniciar teste grátis',
    'ja': '無料トライアルを開始', 'ko': '무료 체험 시작',
  },
  'Restore Purchases': {
    'vi': 'Khôi phục giao dịch', 'zh-Hans': '恢复购买', 'zh-Hant': '還原購買項目',
    'fr': 'Restaurer les achats', 'de': 'Käufe wiederherstellen',
    'it': 'Ripristina acquisti', 'nl': 'Aankopen herstellen',
    'ru': 'Восстановить покупки', 'es': 'Restaurar compras',
    'pt': 'Restaurar compras', 'ja': '購入を復元', 'ko': '구매 복원',
  },
  'Clean Now': {
    'vi': 'Vệ sinh ngay', 'zh-Hans': '立即清洁', 'zh-Hant': '立即清潔',
    'fr': 'Nettoyer maintenant', 'de': 'Jetzt reinigen', 'it': 'Pulisci ora',
    'nl': 'Nu reinigen', 'ru': 'Очистить сейчас', 'es': 'Limpiar ahora',
    'pt': 'Limpar agora', 'ja': '今すぐ清掃', 'ko': '지금 청소',
  },
  'Privacy': {
    'vi': 'Quyền riêng tư', 'zh-Hans': '隐私', 'zh-Hant': '隱私權',
    'fr': 'Confidentialité', 'de': 'Datenschutz', 'it': 'Privacy',
    'nl': 'Privacy', 'ru': 'Конфиденциальность', 'es': 'Privacidad',
    'pt': 'Privacidade', 'ja': 'プライバシー', 'ko': '개인정보',
  },
  'Term Of Use': {
    'vi': 'Điều khoản sử dụng', 'zh-Hans': '使用条款', 'zh-Hant': '使用條款',
    'fr': "Conditions d'utilisation", 'de': 'Nutzungsbedingungen',
    'it': "Termini d'uso", 'nl': 'Gebruiksvoorwaarden',
    'ru': 'Условия использования', 'es': 'Términos de uso',
    'pt': 'Termos de uso', 'ja': '利用規約', 'ko': '이용약관',
  },

  // ---- Splash (0000/0005) --------------------------------------------------
  'Loading wonderful places…': {
    'vi': 'Đang tải những điều tuyệt vời…', 'zh-Hans': '正在加载精彩内容…',
    'zh-Hant': '正在載入精彩內容…', 'fr': 'Chargement en cours…',
    'de': 'Wird geladen…', 'it': 'Caricamento in corso…', 'nl': 'Laden…',
    'ru': 'Загрузка…', 'es': 'Cargando…', 'pt': 'Carregando…',
    'ja': '読み込み中…', 'ko': '불러오는 중…',
  },

  // ---- dB Meter ------------------------------------------------------------
  'Start Measuring': {
    'vi': 'Bắt đầu đo', 'zh-Hans': '开始测量', 'zh-Hant': '開始測量',
    'fr': 'Commencer la mesure', 'de': 'Messung starten',
    'it': 'Inizia a misurare', 'nl': 'Meting starten', 'ru': 'Начать измерение',
    'es': 'Comenzar a medir', 'pt': 'Começar a medir', 'ja': '測定を開始',
    'ko': '측정 시작',
  },
  'Enable Microphone': {
    'vi': 'Bật micrô', 'zh-Hans': '启用麦克风', 'zh-Hant': '啟用麥克風',
    'fr': 'Activer le micro', 'de': 'Mikrofon aktivieren',
    'it': 'Attiva il microfono', 'nl': 'Microfoon inschakelen',
    'ru': 'Включить микрофон', 'es': 'Activar micrófono',
    'pt': 'Ativar microfone', 'ja': 'マイクを有効にする', 'ko': '마이크 켜기',
  },
  'Tap start to measure': {
    'vi': 'Nhấn bắt đầu để đo', 'zh-Hans': '点击开始进行测量',
    'zh-Hant': '點擊開始進行測量', 'fr': 'Appuyez sur démarrer pour mesurer',
    'de': 'Zum Messen auf Start tippen', 'it': 'Tocca avvia per misurare',
    'nl': 'Tik op start om te meten', 'ru': 'Нажмите «Старт», чтобы измерить',
    'es': 'Toca iniciar para medir', 'pt': 'Toque em iniciar para medir',
    'ja': '開始をタップして測定', 'ko': '측정하려면 시작을 누르세요',
  },
  'Quiet': {
    'vi': 'Yên tĩnh', 'zh-Hans': '安静', 'zh-Hant': '安靜', 'fr': 'Silencieux',
    'de': 'Leise', 'it': 'Silenzioso', 'nl': 'Stil', 'ru': 'Тихо',
    'es': 'Silencioso', 'pt': 'Silencioso', 'ja': '静か', 'ko': '조용함',
  },
  'Moderate': {
    'vi': 'Vừa phải', 'zh-Hans': '适中', 'zh-Hant': '適中', 'fr': 'Modéré',
    'de': 'Mäßig', 'it': 'Moderato', 'nl': 'Matig', 'ru': 'Умеренно',
    'es': 'Moderado', 'pt': 'Moderado', 'ja': '普通', 'ko': '보통',
  },
  'Loud': {
    'vi': 'Ồn', 'zh-Hans': '响亮', 'zh-Hant': '響亮', 'fr': 'Fort', 'de': 'Laut',
    'it': 'Forte', 'nl': 'Luid', 'ru': 'Громко', 'es': 'Fuerte', 'pt': 'Alto',
    'ja': '大きい', 'ko': '시끄러움',
  },
  'Very Loud': {
    'vi': 'Rất ồn', 'zh-Hans': '非常响', 'zh-Hant': '非常響', 'fr': 'Très fort',
    'de': 'Sehr laut', 'it': 'Molto forte', 'nl': 'Zeer luid',
    'ru': 'Очень громко', 'es': 'Muy fuerte', 'pt': 'Muito alto',
    'ja': 'とても大きい', 'ko': '매우 시끄러움',
  },
  'Microphone access is needed to measure sound. Enable it to start.': {
    'vi': 'Cần quyền truy cập micrô để đo âm thanh. Hãy bật để bắt đầu.',
    'zh-Hans': '测量声音需要麦克风权限。请启用后开始。',
    'zh-Hant': '測量聲音需要麥克風權限。請啟用後開始。',
    'fr': 'L’accès au micro est nécessaire pour mesurer le son. Activez-le pour commencer.',
    'de': 'Für die Schallmessung wird Mikrofonzugriff benötigt. Aktiviere ihn zum Starten.',
    'it': 'Per misurare il suono serve l’accesso al microfono. Attivalo per iniziare.',
    'nl': 'Microfoontoegang is nodig om geluid te meten. Schakel het in om te starten.',
    'ru': 'Для измерения звука нужен доступ к микрофону. Включите его, чтобы начать.',
    'es': 'Se necesita acceso al micrófono para medir el sonido. Actívalo para empezar.',
    'pt': 'É necessário acesso ao microfone para medir o som. Ative para começar.',
    'ja': '音を測定するにはマイクへのアクセスが必要です。有効にして開始してください。',
    'ko': '소리를 측정하려면 마이크 접근이 필요합니다. 켜서 시작하세요.',
  },
};
