// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'Het nieuws van vandaag';

  @override
  String get updatedJustNow => 'ZOJUIST BIJGEWERKT';

  @override
  String updatedMinutesAgo(int minutes) {
    return '$minutes MIN GELEDEN BIJGEWERKT';
  }

  @override
  String updatedHoursAgo(int hours) {
    return '$hours U GELEDEN BIJGEWERKT';
  }

  @override
  String updatedDaysAgo(int days) {
    return '$days D GELEDEN BIJGEWERKT';
  }

  @override
  String storiesCount(int count) {
    return '$count ARTIKELEN';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NIEUW SINDS JE LAATSTE BEZOEK';
  }

  @override
  String get scrollForMore => 'SCROLL VOOR MEER';

  @override
  String get endOfFeed => '— EINDE VAN HET FEED —';

  @override
  String get live => 'LIVE';

  @override
  String get couldNotReachNewsRoom => 'Kan de redactie niet bereiken';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get noArticlesMatch => 'Geen artikelen voldoen aan deze filters';

  @override
  String get tryBroadeningFilters =>
      'Probeer je filters te verruimen of te wissen.';

  @override
  String couldntLoadMore(String error) {
    return 'Kon niet meer laden: $error';
  }

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabSearch => 'Zoeken';

  @override
  String get tabBookmarks => 'Bewaard';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabFollowing => 'Gevolgd';

  @override
  String get search => 'Zoeken';

  @override
  String get searchPlaceholderShort => 'Zoeken…';

  @override
  String get searchPlaceholderLong => 'Zoek koersen, renners, ploegen…';

  @override
  String get settings => 'Instellingen';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get settingsTheme => 'Thema';

  @override
  String get settingsThemeDark => 'Donker';

  @override
  String get settingsThemeLight => 'Licht';

  @override
  String get settingsThemeSystem => 'Systeem';

  @override
  String get settingsCardDensity => 'Kaartdichtheid';

  @override
  String get settingsDensityCompact => 'Compact';

  @override
  String get settingsDensityComfort => 'Standaard';

  @override
  String get settingsDensityLarge => 'Groot';

  @override
  String get settingsReducedMotion => 'Beperkte beweging';

  @override
  String get settingsReducedMotionDesc =>
      'Sla subtiele animaties en glinster-effecten over.';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageSystem => 'Systeem';

  @override
  String get settingsNotifications => 'Meldingen';

  @override
  String get settingsNotificationsTitle => 'Nieuwsmeldingen';

  @override
  String get settingsNotificationsDesc =>
      'Stille on-device meldingen bij nieuwe artikelen uit gevolgde disciplines. Geen account, geen data verlaat je toestel.';

  @override
  String get settingsNotificationsTopicsLabel => 'DISCIPLINES';

  @override
  String get settingsNotificationsDeliveryLabel => 'BEZORGING';

  @override
  String get settingsNotificationsDeliveryInstant => 'Direct';

  @override
  String get settingsNotificationsDeliveryDaily => 'Dagelijks overzicht';

  @override
  String get settingsHiddenKeywordsLabel => 'WOORDEN VERBERGEN';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Artikelen waarvan de titel of beschrijving een van deze woorden bevat, worden verborgen in de feed en meldingen.';

  @override
  String get settingsHiddenKeywordsHint =>
      'Voeg een woord toe om te verbergen…';

  @override
  String get raceCardAddToCalendar => 'Toevoegen aan agenda';

  @override
  String get raceCardCalendarExportFailed => 'Exporteren naar agenda mislukt.';

  @override
  String get settingsYourData => 'Jouw gegevens';

  @override
  String get settingsExportBookmarks => 'Bladwijzers exporteren';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count opgeslagen · gekopieerd als JSON';
  }

  @override
  String get settingsRedoOnboarding => 'Introductie opnieuw doen';

  @override
  String get settingsRedoOnboardingDesc =>
      'Kies opnieuw regio\'s en disciplines.';

  @override
  String get settingsRedoOnboardingDialogTitle => 'Introductie opnieuw doen?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'We loodsen je opnieuw door de keuze van regio\'s, disciplines en kaartdichtheid. Bladwijzers en gevolgde items blijven behouden.';

  @override
  String get cancel => 'Annuleren';

  @override
  String get redo => 'Opnieuw';

  @override
  String settingsBookmarksCopied(int count) {
    return '$count bladwijzers naar klembord gekopieerd.';
  }

  @override
  String get settingsAbout => 'Info';

  @override
  String get settingsAboutApp => 'Over Bike News Room';

  @override
  String get settingsPrivacy => 'Privacybeleid';

  @override
  String get settingsTerms => 'Servicevoorwaarden';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Link kopiëren';

  @override
  String get shareNative => 'Delen';

  @override
  String get shareLinkCopied => 'Link naar klembord gekopieerd.';

  @override
  String get shareTwitter => 'Delen op X';

  @override
  String get shareBluesky => 'Delen op Bluesky';

  @override
  String get shareWhatsApp => 'Delen op WhatsApp';

  @override
  String get shareReddit => 'Delen op Reddit';

  @override
  String get shareTelegram => 'Delen op Telegram';

  @override
  String get alsoCoveredBy => 'OOK BERICHTEN OVER DIT VERHAAL';

  @override
  String readOnSource(String source) {
    return 'Lees op $source';
  }

  @override
  String get summary => 'SAMENVATTING';

  @override
  String get digestHeadline => 'Wielernieuws, elke ochtend om 7 uur.';

  @override
  String get digestSubheadline =>
      'Eén e-mail. De belangrijkste verhalen van de dag. Geen reclame, geen spam, met één klik uitschrijven.';

  @override
  String get digestEmailHint => 'jij@voorbeeld.com';

  @override
  String get digestSubscribe => 'INSCHRIJVEN';

  @override
  String get digestInvalidEmail => 'Dat ziet er niet uit als een e-mailadres.';

  @override
  String get digestNetworkError =>
      'Kan de redactie niet bereiken. Probeer het zo opnieuw.';

  @override
  String get digestGenericError => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get digestSuccess =>
      'Kijk in je inbox — bevestig om de samenvatting te ontvangen.';

  @override
  String get digestPrivacyPrefix =>
      'Door je in te schrijven ga je akkoord met ons ';

  @override
  String get digestPrivacyLink => 'privacybeleid';

  @override
  String get digestPrivacySuffix => '. Je kunt je altijd uitschrijven.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'STAP $current / $total';
  }

  @override
  String get onboardingStepRegions => 'REGIO\'S';

  @override
  String get onboardingStepDisciplines => 'DISCIPLINES';

  @override
  String get onboardingStepDensity => 'DICHTHEID';

  @override
  String get onboardingNext => 'Volgende';

  @override
  String get onboardingFinish => 'Naar het feed';

  @override
  String get onboardingSkip => 'Overslaan';

  @override
  String get onboardingBack => 'Terug';

  @override
  String get calendarFilterAll => 'ALLES';

  @override
  String get calendarEmpty => 'Nog geen aankomende koersen';

  @override
  String get calendarError => 'Kon de kalender niet laden';

  @override
  String get raceCardToday => 'VANDAAG';

  @override
  String get raceCardNow => 'NU';

  @override
  String get raceCardTomorrow => 'MORGEN';

  @override
  String raceCardDays(int days) {
    return '${days}D';
  }

  @override
  String get tooltipBookmark => 'Bewaren';

  @override
  String get tooltipClose => 'Sluiten';

  @override
  String get tooltipUnfollow => 'Niet meer volgen';

  @override
  String get shareLinkCopiedShort => 'Link gekopieerd';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'Meer…';

  @override
  String get follow => '+ VOLGEN';

  @override
  String followingName(String name) {
    return 'Je volgt $name';
  }

  @override
  String get searchHint => 'Zoek artikelen, renners, koersen…';

  @override
  String get searchAddSourceTitle => 'Niet gevonden wat je zoekt?';

  @override
  String get searchAddSourceBody =>
      'Plak een RSS-feed of website om die als bron toe te voegen.';

  @override
  String get searchKeyToSearch => 'om te zoeken';

  @override
  String get searchKeyToClose => 'om te sluiten';

  @override
  String get breakingHeader => 'BREKEND · LAATSTE UUR';

  @override
  String get regionWorld => '🌍 Wereld';

  @override
  String get regionEu => '🇪🇺 EU';

  @override
  String get regionPoland => '🇵🇱 Polen';

  @override
  String get regionSpain => '🇪🇸 Spanje';

  @override
  String get disciplineAll => 'Alle';

  @override
  String get disciplineRoad => 'Weg';

  @override
  String get disciplineMtb => 'MTB';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Baan';

  @override
  String get disciplineCx => 'Veldrijden';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'LAATST BIJGEWERKT · $date';
  }

  @override
  String get aboutTitle => 'Over';

  @override
  String get aboutH1 => 'Wat dit is';

  @override
  String get aboutB1 =>
      'Bike News Room is één feed voor wielernieuws van over de hele wereld — weg, MTB, gravel, baan en veldrijden. We aggregeren openbare RSS-feeds en sites van wieleruitgevers, federaties en onafhankelijke blogs, zodat je niet langer tussen twintig tabbladen hoeft te springen om bij te blijven.';

  @override
  String get aboutH2 => 'Hoe het werkt';

  @override
  String get aboutB2 =>
      'Elke 30 minuten haalt onze backend de geconfigureerde bronnen binnen, ontdubbelt bijna identieke verhalen, classificeert ze per regio en discipline en stopt ze in de feed die je leest. Iedereen kan via het formulier \"Bron toevoegen\" een bron indienen, en we tonen automatisch domeinen die we vaak in artikelen geciteerd zien voor beoordeling.';

  @override
  String get aboutH3 => 'Geen betaalmuur, geen algoritme-spelletjes';

  @override
  String get aboutB3 =>
      'We rangschikken niet op engagement, volgen je niet tussen sites en verkopen niets. De volgorde is omgekeerd chronologisch, met regio- en disciplinefilters die jij beheert. Als een verhaal hier staat, is dat omdat een wielerpublicatie het daadwerkelijk heeft gepubliceerd.';

  @override
  String get aboutH4 => 'Open source';

  @override
  String get aboutB4 =>
      'De volledige broncode (Rust-backend + Flutter-Web-frontend) staat op GitHub. Bug gevonden, een bron toevoegen of forken voor een andere sport? Pull requests welkom.';

  @override
  String get privacyTitle => 'Privacybeleid';

  @override
  String get privacyH1 => 'Wat we verzamelen';

  @override
  String get privacyB1 =>
      'Bijna niets. De frontend slaat je voorkeuren (thema, filters, bladwijzers, laatst geziene artikel) op in de lokale opslag van je browser — die verlaten je apparaat nooit. Als je je inschrijft op de dagelijkse samenvatting, bewaren we je e-mailadres en een bevestigings-/uitschrijftoken in onze database; meer niet.';

  @override
  String get privacyH2 => 'Wat we niet verzamelen';

  @override
  String get privacyB2 =>
      'Geen analytics-SDK\'s, geen externe trackers, geen advertentiecookies, geen fingerprinting, geen IP-logging buiten de standaard serverlogs (wekelijks geroteerd), geen profiel van je leesgedrag.';

  @override
  String get privacyH3 => 'E-mailsamenvatting';

  @override
  String get privacyB3 =>
      'Als je je abonneert, wordt je e-mail uitsluitend gebruikt om de dagelijkse samenvatting te versturen. We gebruiken Resend voor bezorging — zij zien het adres bij verzending maar gebruiken het nergens anders voor. Je kunt je met één klik uitschrijven vanuit elke samenvattings-mail; na uitschrijven blijft het adres in de database (gemarkeerd als zodanig) zodat het niet door derden opnieuw kan worden ingeschreven totdat je het zelf opnieuw bevestigt.';

  @override
  String get privacyH4 => 'Cookies';

  @override
  String get privacyB4 =>
      'We plaatsen geen cookies. Lokale browseropslag wordt gebruikt voor je in-app voorkeuren — site-data wissen verwijdert ze.';

  @override
  String get privacyH5 => 'Jouw gegevens, jouw keuze';

  @override
  String get privacyB5 =>
      'Mail ons op hello@bike-news-room en we verwijderen elk inschrijvingsrecord dat je ons vraagt te verwijderen. Er is verder niets te wissen omdat we verder niets opslaan.';

  @override
  String get termsTitle => 'Servicevoorwaarden';

  @override
  String get termsH1 => 'Gebruik van de dienst';

  @override
  String get termsB1 =>
      'Bike News Room is een gratis, openbare nieuwsaggregator. Je mag hem gebruiken voor persoonlijk, niet-commercieel lezen. Probeer niet de API in hoge frequentie te scrapen — er is een rate-limit per IP en we sturen je vrolijk een 429 terug. Heb je bulk toegang nodig: de code is open; draai je eigen instantie.';

  @override
  String get termsH2 => 'Inhoud van artikelen';

  @override
  String get termsB2 =>
      'Koppen, fragmenten en links in de feed komen uit openbaar beschikbare RSS-feeds en pagina\'s van wielerpublicaties. Klikverkeer gaat naar de oorspronkelijke uitgever. We reproduceren geen volledige artikelen — lees altijd op de bron om de mensen achter de berichtgeving te steunen.';

  @override
  String get termsH3 => 'Geen garantie';

  @override
  String get termsB3 =>
      'De dienst wordt aangeboden zoals die is. Artikelen kunnen onjuistheden bevatten (we doen geen factcheck op de publicaties die we aggregeren). Gebruik dit niet als enige bron voor wedstrijdbeslissingen, contractonderhandelingen of andere zaken waar fout zijn echte kosten heeft.';

  @override
  String get termsH4 => 'Bronnen toevoegen';

  @override
  String get termsB4 =>
      'Iedereen mag een bron-URL indienen. We doen automatische beveiligingschecks (URL-guard, groottelimieten, content-probe) maar behouden ons het recht voor bronnen te verwijderen die spam, off-topic of van lage kwaliteit blijken.';

  @override
  String get termsH5 => 'Wijzigingen';

  @override
  String get termsB5 =>
      'We kunnen deze voorwaarden af en toe bijwerken. Belangrijke wijzigingen worden in de dagelijkse samenvatting aangekondigd voordat ze ingaan.';

  @override
  String get onbRegionsTitle => 'Waar moet het feed zich op richten?';

  @override
  String get onbRegionsSub =>
      'Je ziet altijd het mondiale wielergebeuren. Kies welke regio\'s extra gewicht krijgen.';

  @override
  String get onbDisciplinesTitle => 'Welke fietsen trekken je aan?';

  @override
  String get onbDisciplinesSub =>
      'Vink alles aan dat van toepassing is — we gebruiken dit voor kleurmarkering en prioritering.';

  @override
  String get onbDensityTitle => 'Hoe dicht moet het feed zijn?';

  @override
  String get onbDensitySub => 'Je kunt dit altijd aanpassen vanuit het feed.';

  @override
  String get onbCompactSub =>
      'Maximaal artikelen. Lijstrijen, geen afbeeldingen.';

  @override
  String get onbComfortSub => 'Gebalanceerd. Beeld + tekst.';

  @override
  String get onbLargeSub => 'Redactionele heldenkaarten.';

  @override
  String get nameWorld => 'Wereld';

  @override
  String get nameEu => 'EU';

  @override
  String get namePoland => 'Polen';

  @override
  String get nameSpain => 'Spanje';

  @override
  String get descWorld => 'Alles, overal.';

  @override
  String get descEu => 'Focus op Europees wielrennen.';

  @override
  String get descPoland => 'Poolse koersen en renners.';

  @override
  String get descSpain => 'Spaanse koersen en renners.';

  @override
  String get disciplineCxLong => 'Veldrijden';

  @override
  String get descRoad => 'Eindklassement, klassiekers, sprints.';

  @override
  String get descMtb => 'XC, DH, enduro, freeride.';

  @override
  String get descGravel => 'Lange afstand off-road.';

  @override
  String get descTrack => 'Baanwielrennen.';

  @override
  String get descCx => 'Modder, zand, hindernissen.';

  @override
  String get descBmx => 'Race en freestyle.';
}
