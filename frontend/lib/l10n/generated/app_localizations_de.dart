// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'Die Nachrichten von heute';

  @override
  String get updatedJustNow => 'GERADE EBEN AKTUALISIERT';

  @override
  String updatedMinutesAgo(int minutes) {
    return 'VOR $minutes MIN AKTUALISIERT';
  }

  @override
  String updatedHoursAgo(int hours) {
    return 'VOR $hours STD. AKTUALISIERT';
  }

  @override
  String updatedDaysAgo(int days) {
    return 'VOR $days TAGEN AKTUALISIERT';
  }

  @override
  String storiesCount(int count) {
    return '$count ARTIKEL';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NEUE SEIT DEINEM LETZTEN BESUCH';
  }

  @override
  String get scrollForMore => 'WEITER SCROLLEN FÜR MEHR';

  @override
  String get endOfFeed => '— ENDE DES FEEDS —';

  @override
  String get live => 'LIVE';

  @override
  String get couldNotReachNewsRoom =>
      'Die Redaktion ist gerade nicht erreichbar';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noArticlesMatch => 'Keine Artikel passen zu diesen Filtern';

  @override
  String get tryBroadeningFilters =>
      'Versuche, Filter zu erweitern oder zu entfernen.';

  @override
  String couldntLoadMore(String error) {
    return 'Konnte nicht mehr laden: $error';
  }

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabSearch => 'Suche';

  @override
  String get tabBookmarks => 'Lesezeichen';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabFollowing => 'Folge ich';

  @override
  String get search => 'Suchen';

  @override
  String get searchPlaceholderShort => 'Suchen…';

  @override
  String get searchPlaceholderLong => 'Rennen, Fahrer, Teams suchen…';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsCardDensity => 'Kartendichte';

  @override
  String get settingsDensityCompact => 'Kompakt';

  @override
  String get settingsDensityComfort => 'Standard';

  @override
  String get settingsDensityLarge => 'Groß';

  @override
  String get settingsReducedMotion => 'Reduzierte Bewegung';

  @override
  String get settingsReducedMotionDesc =>
      'Subtile Animationen und Schimmer-Effekte überspringen.';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsNotificationsTitle => 'Newsalarme';

  @override
  String get settingsNotificationsDesc =>
      'Stille Geräte-Benachrichtigungen, sobald neue Artikel aus deinen Disziplinen eintreffen. Kein Konto, keine Daten verlassen dein Telefon.';

  @override
  String get settingsNotificationsTopicsLabel => 'DISZIPLINEN';

  @override
  String get settingsNotificationsDeliveryLabel => 'ZUSTELLUNG';

  @override
  String get settingsNotificationsDeliveryInstant => 'Sofort';

  @override
  String get settingsNotificationsDeliveryDaily => 'Tageszusammenfassung';

  @override
  String get settingsHiddenKeywordsLabel => 'WÖRTER AUSBLENDEN';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Artikel, deren Titel oder Beschreibung eines dieser Wörter enthalten, werden im Feed und in Benachrichtigungen ausgeblendet.';

  @override
  String get settingsHiddenKeywordsHint => 'Wort zum Ausblenden hinzufügen…';

  @override
  String get raceCardAddToCalendar => 'Zum Kalender hinzufügen';

  @override
  String get raceCardCalendarExportFailed =>
      'Export zum Kalender fehlgeschlagen.';

  @override
  String get settingsYourData => 'Deine Daten';

  @override
  String get settingsExportBookmarks => 'Lesezeichen exportieren';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count gespeichert · als JSON kopiert';
  }

  @override
  String get settingsRedoOnboarding => 'Einrichtung wiederholen';

  @override
  String get settingsRedoOnboardingDesc =>
      'Regionen und Disziplinen neu auswählen.';

  @override
  String get settingsRedoOnboardingDialogTitle => 'Einrichtung wiederholen?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'Wir führen dich erneut durch die Auswahl von Regionen, Disziplinen und Kartendichte. Lesezeichen und Folge-Liste bleiben erhalten.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get redo => 'Wiederholen';

  @override
  String settingsBookmarksCopied(int count) {
    return '$count Lesezeichen in die Zwischenablage kopiert.';
  }

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsAboutApp => 'Über Bike News Room';

  @override
  String get settingsPrivacy => 'Datenschutzerklärung';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Link kopieren';

  @override
  String get shareNative => 'Teilen';

  @override
  String get shareLinkCopied => 'Link in die Zwischenablage kopiert.';

  @override
  String get shareTwitter => 'Auf X teilen';

  @override
  String get shareBluesky => 'Auf Bluesky teilen';

  @override
  String get shareWhatsApp => 'Per WhatsApp teilen';

  @override
  String get shareReddit => 'Auf Reddit teilen';

  @override
  String get shareTelegram => 'Per Telegram teilen';

  @override
  String get alsoCoveredBy => 'AUCH BERICHTET VON';

  @override
  String readOnSource(String source) {
    return 'Auf $source lesen';
  }

  @override
  String get summary => 'ZUSAMMENFASSUNG';

  @override
  String get digestHeadline => 'Radsport-Nachrichten, jeden Morgen um 7.';

  @override
  String get digestSubheadline =>
      'Eine E-Mail. Die wichtigsten Geschichten des Tages. Keine Werbung, kein Spam, mit einem Klick abbestellen.';

  @override
  String get digestEmailHint => 'du@beispiel.com';

  @override
  String get digestSubscribe => 'ABONNIEREN';

  @override
  String get digestInvalidEmail =>
      'Das sieht nicht nach einer E-Mail-Adresse aus.';

  @override
  String get digestNetworkError =>
      'Die Redaktion ist gerade nicht erreichbar. Versuch es in einer Minute.';

  @override
  String get digestGenericError =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get digestSuccess =>
      'Schau in dein Postfach — bestätige, um den Newsletter zu erhalten.';

  @override
  String get digestPrivacyPrefix => 'Mit dem Abonnieren akzeptierst du unsere ';

  @override
  String get digestPrivacyLink => 'Datenschutzerklärung';

  @override
  String get digestPrivacySuffix => '. Du kannst jederzeit abbestellen.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'SCHRITT $current / $total';
  }

  @override
  String get onboardingStepRegions => 'REGIONEN';

  @override
  String get onboardingStepDisciplines => 'DISZIPLINEN';

  @override
  String get onboardingStepDensity => 'DICHTE';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingFinish => 'Zum Feed';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingBack => 'Zurück';

  @override
  String get calendarFilterAll => 'ALLE';

  @override
  String get calendarEmpty => 'Noch keine bevorstehenden Rennen';

  @override
  String get calendarError => 'Kalender konnte nicht geladen werden';

  @override
  String get raceCardToday => 'HEUTE';

  @override
  String get raceCardNow => 'JETZT';

  @override
  String get raceCardTomorrow => 'MORGEN';

  @override
  String raceCardDays(int days) {
    return '$days T';
  }

  @override
  String get tooltipBookmark => 'Lesezeichen';

  @override
  String get tooltipClose => 'Schließen';

  @override
  String get tooltipUnfollow => 'Nicht mehr folgen';

  @override
  String get shareLinkCopiedShort => 'Link kopiert';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'Mehr…';

  @override
  String get follow => '+ FOLGEN';

  @override
  String followingName(String name) {
    return 'Du folgst $name';
  }

  @override
  String get searchHint => 'Artikel, Fahrer, Rennen suchen…';

  @override
  String get searchAddSourceTitle => 'Nicht gefunden, was du suchst?';

  @override
  String get searchAddSourceBody =>
      'Füge einen RSS-Feed oder eine Website ein, um sie als Quelle hinzuzufügen.';

  @override
  String get searchKeyToSearch => 'zum Suchen';

  @override
  String get searchKeyToClose => 'zum Schließen';

  @override
  String get breakingHeader => 'EILMELDUNG · LETZTE STUNDE';

  @override
  String get regionWorld => '🌍 Welt';

  @override
  String get regionEu => '🇪🇺 EU';

  @override
  String get regionPoland => '🇵🇱 Polen';

  @override
  String get regionSpain => '🇪🇸 Spanien';

  @override
  String get disciplineAll => 'Alle';

  @override
  String get disciplineRoad => 'Straße';

  @override
  String get disciplineMtb => 'MTB';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Bahn';

  @override
  String get disciplineCx => 'Querfeldein';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'ZULETZT AKTUALISIERT · $date';
  }

  @override
  String get aboutTitle => 'Über';

  @override
  String get aboutH1 => 'Worum es geht';

  @override
  String get aboutB1 =>
      'Bike News Room ist ein einzelner Feed für Radsport-Nachrichten aus der ganzen Welt — Straße, MTB, Gravel, Bahn und Querfeldein. Wir aggregieren öffentliche RSS-Feeds und Webseiten von Radsport-Publikationen, Verbänden und unabhängigen Blogs, damit du nicht zwischen zwanzig Tabs hin- und herspringst, um auf dem Laufenden zu bleiben.';

  @override
  String get aboutH2 => 'Wie es funktioniert';

  @override
  String get aboutB2 =>
      'Alle 30 Minuten zieht unser Backend von den konfigurierten Quellen, dedupliziert nahezu identische Geschichten, klassifiziert nach Region und Disziplin und schiebt sie in den Feed, den du gerade liest. Quellen kann jeder über das Formular „Quelle hinzufügen“ einreichen, und wir zeigen automatisch Domains an, die häufig in Artikeln zitiert werden.';

  @override
  String get aboutH3 => 'Keine Paywall, keine Algorithmus-Spielchen';

  @override
  String get aboutB3 =>
      'Wir sortieren nicht nach Engagement, tracken dich nicht zwischen Seiten und verkaufen nichts. Die Reihenfolge ist umgekehrt chronologisch, mit Region- und Disziplin-Filtern, die du steuerst. Wenn eine Geschichte hier auftaucht, dann weil eine Radsport-Publikation sie tatsächlich veröffentlicht hat.';

  @override
  String get aboutH4 => 'Open Source';

  @override
  String get aboutB4 =>
      'Der gesamte Quellcode (Rust-Backend + Flutter-Web-Frontend) ist auf GitHub. Bug gefunden, neue Quelle hinzuzufügen oder Fork für einen anderen Sport? Pull Requests willkommen.';

  @override
  String get privacyTitle => 'Datenschutzerklärung';

  @override
  String get privacyH1 => 'Was wir erfassen';

  @override
  String get privacyB1 =>
      'Fast nichts. Das Frontend speichert deine Einstellungen (Design, Filter, Lesezeichen, zuletzt gesehener Artikel) im lokalen Speicher deines Browsers — sie verlassen dein Gerät nie. Wenn du den täglichen Newsletter abonnierst, speichern wir deine E-Mail-Adresse und ein Bestätigungs-/Abmelde-Token in unserer Datenbank; das ist alles.';

  @override
  String get privacyH2 => 'Was wir nicht erfassen';

  @override
  String get privacyB2 =>
      'Keine Analytics-SDKs, keine Drittanbieter-Tracker, keine Werbe-Cookies, kein Fingerprinting, kein IP-Adressen-Logging über Standard-Serverlogs hinaus (wöchentlich rotiert), kein Profil deiner Lesegewohnheiten.';

  @override
  String get privacyH3 => 'E-Mail-Newsletter';

  @override
  String get privacyB3 =>
      'Wenn du abonnierst, wird deine E-Mail ausschließlich für den Versand des täglichen Newsletters verwendet. Wir nutzen Resend zur Zustellung — sie sehen die Adresse beim Versenden, verwenden sie aber für nichts anderes. Du kannst dich mit einem Klick aus jeder Newsletter-E-Mail abmelden; nach der Abmeldung bleibt die Adresse markiert in der Datenbank, damit Dritte sie nicht erneut anmelden können, bis du selbst erneut bestätigst.';

  @override
  String get privacyH4 => 'Cookies';

  @override
  String get privacyB4 =>
      'Wir setzen keine Cookies. Der lokale Browser-Speicher wird für deine In-App-Einstellungen genutzt — Daten der Seite löschen entfernt sie.';

  @override
  String get privacyH5 => 'Deine Daten, deine Wahl';

  @override
  String get privacyB5 =>
      'Schreib uns an hello@bike-news-room und wir löschen jede Newsletter-Eintragung, um die du uns bittest. Es gibt sonst nichts zu löschen, weil sonst nichts gespeichert wird.';

  @override
  String get termsTitle => 'Nutzungsbedingungen';

  @override
  String get termsH1 => 'Nutzung des Dienstes';

  @override
  String get termsB1 =>
      'Bike News Room ist ein kostenloser, öffentlicher News-Aggregator. Du darfst ihn für persönliche, nicht-kommerzielle Lektüre nutzen. Versuche nicht, die API mit hohem Volumen zu scrapen — es gibt ein Rate-Limit pro IP, und wir antworten gern mit 429. Bei Bedarf an Massenzugriff: der Code ist offen; betreibe deine eigene Instanz.';

  @override
  String get termsH2 => 'Artikelinhalte';

  @override
  String get termsB2 =>
      'Schlagzeilen, Auszüge und Links im Feed stammen aus öffentlich zugänglichen RSS-Feeds und Seiten von Radsport-Publikationen. Der Klick-Traffic geht an den ursprünglichen Verlag. Wir reproduzieren keine vollständigen Artikel — lies immer auf der Quellseite, um die Menschen zu unterstützen, die berichten.';

  @override
  String get termsH3 => 'Keine Garantie';

  @override
  String get termsB3 =>
      'Der Dienst wird so wie er ist bereitgestellt. Artikel können Ungenauigkeiten enthalten (wir prüfen die Fakten der aggregierten Publikationen nicht). Nutze ihn nicht als alleinige Quelle für Renntag-Entscheidungen, Vertragsverhandlungen oder anderes, wo Irrtum reale Kosten hat.';

  @override
  String get termsH4 => 'Quellen hinzufügen';

  @override
  String get termsB4 =>
      'Jeder kann eine Quell-URL einreichen. Wir führen automatisierte Sicherheitsprüfungen durch (URL-Guard, Größenlimits, Inhalts-Probe), behalten uns aber das Recht vor, Quellen zu entfernen, die sich als Spam, Off-Topic oder minderwertig erweisen.';

  @override
  String get termsH5 => 'Änderungen';

  @override
  String get termsB5 =>
      'Wir können diese Bedingungen gelegentlich aktualisieren. Wesentliche Änderungen werden im täglichen Newsletter angekündigt, bevor sie wirksam werden.';

  @override
  String get onbRegionsTitle => 'Worauf soll sich der Feed konzentrieren?';

  @override
  String get onbRegionsSub =>
      'Du siehst immer das globale Renngeschehen. Wähle, welche Regionen extra Gewicht bekommen.';

  @override
  String get onbDisciplinesTitle => 'Welche Räder ziehen dich an?';

  @override
  String get onbDisciplinesSub =>
      'Wähle alle zutreffenden — wir nutzen das für Farb-Tags und Priorisierung.';

  @override
  String get onbDensityTitle => 'Wie dicht soll der Feed sein?';

  @override
  String get onbDensitySub => 'Du kannst das jederzeit im Feed ändern.';

  @override
  String get onbCompactSub =>
      'Maximale Anzahl Artikel. Listenzeilen, keine Bilder.';

  @override
  String get onbComfortSub => 'Ausgewogen. Bild + Text.';

  @override
  String get onbLargeSub => 'Redaktionelle Hero-Karten.';

  @override
  String get nameWorld => 'Welt';

  @override
  String get nameEu => 'EU';

  @override
  String get namePoland => 'Polen';

  @override
  String get nameSpain => 'Spanien';

  @override
  String get descWorld => 'Alles, überall.';

  @override
  String get descEu => 'Fokus auf europäisches Rennen.';

  @override
  String get descPoland => 'PL-Rennen und -Fahrer.';

  @override
  String get descSpain => 'ES-Rennen und -Fahrer.';

  @override
  String get disciplineCxLong => 'Querfeldein';

  @override
  String get descRoad => 'GC, Klassiker, Sprints.';

  @override
  String get descMtb => 'XC, DH, Enduro, Freeride.';

  @override
  String get descGravel => 'Langstrecke abseits des Asphalts.';

  @override
  String get descTrack => 'Bahnrennen.';

  @override
  String get descCx => 'Schlamm, Sand, Hindernisse.';

  @override
  String get descBmx => 'Rennen + Freestyle.';
}
