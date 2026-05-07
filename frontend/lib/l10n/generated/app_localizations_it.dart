// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'Le notizie di oggi';

  @override
  String get updatedJustNow => 'AGGIORNATO ORA';

  @override
  String updatedMinutesAgo(int minutes) {
    return 'AGGIORNATO $minutes MIN FA';
  }

  @override
  String updatedHoursAgo(int hours) {
    return 'AGGIORNATO $hours ORE FA';
  }

  @override
  String updatedDaysAgo(int days) {
    return 'AGGIORNATO $days GIORNI FA';
  }

  @override
  String storiesCount(int count) {
    return '$count ARTICOLI';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NUOVI DALLA TUA ULTIMA VISITA';
  }

  @override
  String get scrollForMore => 'SCORRI PER ALTRO';

  @override
  String get endOfFeed => '— FINE DEL FEED —';

  @override
  String get live => 'LIVE';

  @override
  String get couldNotReachNewsRoom => 'Impossibile contattare la redazione';

  @override
  String get retry => 'Riprova';

  @override
  String get noArticlesMatch => 'Nessun articolo corrisponde a questi filtri';

  @override
  String get tryBroadeningFilters => 'Prova ad ampliare o cancellare i filtri.';

  @override
  String couldntLoadMore(String error) {
    return 'Impossibile caricare altro: $error';
  }

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabSearch => 'Cerca';

  @override
  String get tabBookmarks => 'Salvati';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabFollowing => 'Seguiti';

  @override
  String get search => 'Cerca';

  @override
  String get searchPlaceholderShort => 'Cerca…';

  @override
  String get searchPlaceholderLong => 'Cerca corse, corridori, squadre…';

  @override
  String get settings => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsCardDensity => 'Densità schede';

  @override
  String get settingsDensityCompact => 'Compatta';

  @override
  String get settingsDensityComfort => 'Standard';

  @override
  String get settingsDensityLarge => 'Ampia';

  @override
  String get settingsReducedMotion => 'Movimento ridotto';

  @override
  String get settingsReducedMotionDesc =>
      'Salta animazioni discrete ed effetti di luce.';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsNotifications => 'Notifiche';

  @override
  String get settingsNotificationsTitle => 'Avvisi notizie';

  @override
  String get settingsNotificationsDesc =>
      'Notifiche locali discrete quando arrivano nuovi articoli sulle discipline che segui. Niente account, niente dati trasmessi.';

  @override
  String get settingsNotificationsTopicsLabel => 'DISCIPLINE';

  @override
  String get settingsNotificationsDeliveryLabel => 'CONSEGNA';

  @override
  String get settingsNotificationsDeliveryInstant => 'Istantaneo';

  @override
  String get settingsNotificationsDeliveryDaily => 'Riepilogo giornaliero';

  @override
  String get settingsHiddenKeywordsLabel => 'NASCONDI PAROLE';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Le notizie il cui titolo o descrizione contiene una di queste parole vengono nascoste dal feed e dalle notifiche.';

  @override
  String get settingsHiddenKeywordsHint => 'Aggiungi una parola da nascondere…';

  @override
  String get trendingHeader => 'IN TENDENZA';

  @override
  String get readerModeRead => 'Leggi nell\'app';

  @override
  String get readerModeHide => 'Nascondi lettore';

  @override
  String get readerModeUnavailable =>
      'Modalità lettore non disponibile per questo articolo (l\'editore lo impedisce).';

  @override
  String get readerModeError => 'Impossibile caricare l\'articolo.';

  @override
  String get wikiSourceLink => 'Continua su Wikipedia';

  @override
  String get raceCardAddToCalendar => 'Aggiungi al calendario';

  @override
  String get raceCardCalendarExportFailed =>
      'Esportazione nel calendario non riuscita.';

  @override
  String get settingsYourData => 'I tuoi dati';

  @override
  String get settingsExportBookmarks => 'Esporta salvati';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count salvati · copiati come JSON';
  }

  @override
  String get settingsRedoOnboarding => 'Rifai l\'introduzione';

  @override
  String get settingsRedoOnboardingDesc =>
      'Scegli regioni e discipline da capo.';

  @override
  String get settingsRedoOnboardingDialogTitle => 'Rifare l\'introduzione?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'Ti faremo scegliere di nuovo regioni, discipline e densità. I tuoi salvati e i seguiti restano invariati.';

  @override
  String get cancel => 'Annulla';

  @override
  String get redo => 'Rifai';

  @override
  String settingsBookmarksCopied(int count) {
    return 'Copiati $count salvati negli appunti.';
  }

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsAboutApp => 'Informazioni su Bike News Room';

  @override
  String get settingsPrivacy => 'Informativa privacy';

  @override
  String get settingsTerms => 'Termini di servizio';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Copia link';

  @override
  String get shareNative => 'Condividi';

  @override
  String get shareLinkCopied => 'Link copiato negli appunti.';

  @override
  String get shareTwitter => 'Condividi su X';

  @override
  String get shareBluesky => 'Condividi su Bluesky';

  @override
  String get shareWhatsApp => 'Condividi su WhatsApp';

  @override
  String get shareReddit => 'Condividi su Reddit';

  @override
  String get shareTelegram => 'Condividi su Telegram';

  @override
  String get alsoCoveredBy => 'ANCHE COPERTO DA';

  @override
  String readOnSource(String source) {
    return 'Leggi su $source';
  }

  @override
  String get summary => 'RIASSUNTO';

  @override
  String get digestHeadline => 'Notizie di ciclismo, ogni mattina alle 7.';

  @override
  String get digestSubheadline =>
      'Una sola email. Le storie più importanti della giornata. Niente pubblicità, niente spam, disiscrizione in un clic.';

  @override
  String get digestEmailHint => 'tu@esempio.com';

  @override
  String get digestSubscribe => 'ISCRIVITI';

  @override
  String get digestInvalidEmail => 'Questo non sembra un indirizzo email.';

  @override
  String get digestNetworkError =>
      'Impossibile raggiungere la redazione. Riprova fra un minuto.';

  @override
  String get digestGenericError => 'Qualcosa è andato storto. Riprova.';

  @override
  String get digestSuccess =>
      'Controlla la posta — conferma per iniziare a ricevere il riepilogo.';

  @override
  String get digestPrivacyPrefix => 'Iscrivendoti accetti la nostra ';

  @override
  String get digestPrivacyLink => 'informativa sulla privacy';

  @override
  String get digestPrivacySuffix => '. Disiscriviti quando vuoi.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'PASSO $current / $total';
  }

  @override
  String get onboardingStepRegions => 'REGIONI';

  @override
  String get onboardingStepDisciplines => 'DISCIPLINE';

  @override
  String get onboardingStepDensity => 'DENSITÀ';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingFinish => 'Mostrami il feed';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingBack => 'Indietro';

  @override
  String get calendarFilterAll => 'TUTTI';

  @override
  String get calendarEmpty => 'Nessuna corsa imminente';

  @override
  String get calendarError => 'Impossibile caricare il calendario';

  @override
  String get raceCardToday => 'OGGI';

  @override
  String get raceCardNow => 'ORA';

  @override
  String get raceCardTomorrow => 'DOMANI';

  @override
  String raceCardDays(int days) {
    return '${days}G';
  }

  @override
  String get tooltipBookmark => 'Salva';

  @override
  String get tooltipClose => 'Chiudi';

  @override
  String get tooltipUnfollow => 'Smetti di seguire';

  @override
  String get shareLinkCopiedShort => 'Link copiato';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'Altro…';

  @override
  String get follow => '+ SEGUI';

  @override
  String followingName(String name) {
    return 'Stai seguendo $name';
  }

  @override
  String get searchHint => 'Cerca articoli, corridori, corse…';

  @override
  String get searchAddSourceTitle => 'Non trovi quello che cerchi?';

  @override
  String get searchAddSourceBody =>
      'Incolla un feed RSS o un sito per aggiungerlo come fonte.';

  @override
  String get searchKeyToSearch => 'per cercare';

  @override
  String get searchKeyToClose => 'per chiudere';

  @override
  String get breakingHeader => 'ULTIMA ORA · ULTIMA ORA';

  @override
  String get regionWorld => '🌍 Mondo';

  @override
  String get regionEu => '🇪🇺 UE';

  @override
  String get regionPoland => '🇵🇱 Polonia';

  @override
  String get regionSpain => '🇪🇸 Spagna';

  @override
  String get disciplineAll => 'Tutte';

  @override
  String get disciplineRoad => 'Strada';

  @override
  String get disciplineMtb => 'MTB';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Pista';

  @override
  String get disciplineCx => 'Ciclocross';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'ULTIMO AGGIORNAMENTO · $date';
  }

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String get aboutH1 => 'Cos\'è';

  @override
  String get aboutB1 =>
      'Bike News Room è un unico feed di notizie ciclistiche da tutto il mondo — strada, MTB, gravel, pista e ciclocross. Aggreghiamo da feed RSS pubblici e siti di testate ciclistiche, federazioni e blog indipendenti, così smetti di saltare tra venti schede per restare aggiornato.';

  @override
  String get aboutH2 => 'Come funziona';

  @override
  String get aboutB2 =>
      'Ogni 30 minuti il backend recupera le fonti configurate, deduplica le notizie quasi identiche, le classifica per regione e disciplina e le inserisce nel feed che stai leggendo. Chiunque può aggiungere una fonte tramite il modulo \"Aggiungi una fonte\", e mostriamo automaticamente i domini citati spesso negli articoli per la revisione.';

  @override
  String get aboutH3 => 'Niente paywall, niente giochetti d\'algoritmo';

  @override
  String get aboutB3 =>
      'Non ordiniamo per engagement, non ti tracciamo tra i siti e non vendiamo nulla. L\'ordine è cronologico inverso, con i filtri per regione e disciplina che controlli tu. Se una notizia è qui, è perché una testata ciclistica l\'ha effettivamente pubblicata.';

  @override
  String get aboutH4 => 'Progetto indipendente';

  @override
  String get aboutB4 =>
      'Bike News Room è sviluppato in modo indipendente. Niente accordi editoriali — ogni articolo arriva da feed RSS pubblici che aggreghiamo in modo trasparente.';

  @override
  String get privacyTitle => 'Informativa sulla privacy';

  @override
  String get privacyH1 => 'Cosa raccogliamo';

  @override
  String get privacyB1 =>
      'Quasi nulla. Il frontend salva le tue preferenze (tema, filtri, salvati, ultimo articolo visto) nello storage locale del browser — non lasciano mai il tuo dispositivo. Se ti iscrivi al riepilogo giornaliero, conserviamo l\'indirizzo email e un token di conferma/disiscrizione nel nostro database; tutto qui.';

  @override
  String get privacyH2 => 'Cosa non raccogliamo';

  @override
  String get privacyB2 =>
      'Nessun SDK di analytics, nessun tracker di terze parti, nessun cookie pubblicitario, nessun fingerprinting, nessun log degli IP oltre ai log standard del server (ruotati settimanalmente), nessun profilo delle tue abitudini di lettura.';

  @override
  String get privacyH3 => 'Riepilogo via email';

  @override
  String get privacyB3 =>
      'Se ti iscrivi, l\'email viene usata solo per inviarti il riepilogo giornaliero. Usiamo Resend per la consegna — vedono l\'indirizzo durante la consegna ma non lo usano per altro. Puoi disiscriverti con un clic da qualunque email del riepilogo; una volta disiscritto, l\'indirizzo resta in archivio (marcato come tale) così non può essere riscritto da terzi finché non confermi nuovamente tu.';

  @override
  String get privacyH4 => 'Cookie';

  @override
  String get privacyB4 =>
      'Non impostiamo cookie. Lo storage locale del browser è usato solo per le tue preferenze — cancellando i dati del sito li elimini.';

  @override
  String get privacyH5 => 'I tuoi dati, la tua scelta';

  @override
  String get privacyB5 =>
      'Scrivici a hello@bike-news-room e cancelleremo qualunque registrazione di iscrizione tu ci chieda. Non c\'è nient\'altro da cancellare perché non c\'è nient\'altro memorizzato.';

  @override
  String get termsTitle => 'Termini di servizio';

  @override
  String get termsH1 => 'Uso del servizio';

  @override
  String get termsB1 =>
      'Bike News Room è un aggregatore di notizie gratuito per uso personale. Non provare a fare scraping dell\'API ad alto volume — c\'è un rate-limit per IP e risponderemo con 429. L\'uso massivo o commerciale dell\'API richiede autorizzazione scritta.';

  @override
  String get termsH2 => 'Contenuto degli articoli';

  @override
  String get termsB2 =>
      'Titoli, estratti e link mostrati nel feed provengono da feed RSS pubblici e pagine di testate ciclistiche. Il traffico dei clic va all\'editore originale. Non riproduciamo articoli interi — leggi sempre sul sito di origine per supportare chi fa il giornalismo.';

  @override
  String get termsH3 => 'Nessuna garanzia';

  @override
  String get termsB3 =>
      'Il servizio è fornito \"così com\'è\". Gli articoli possono contenere imprecisioni (non verifichiamo i fatti delle testate che aggreghiamo). Non usarlo come unica fonte per decisioni in giornata di gara, trattative contrattuali o qualunque cosa in cui sbagliare ha un costo reale.';

  @override
  String get termsH4 => 'Aggiunta di fonti';

  @override
  String get termsB4 =>
      'Chiunque può inviare un URL come fonte. Eseguiamo controlli di sicurezza automatici (URL guard, limiti di payload, sondaggio del contenuto) ma ci riserviamo il diritto di rimuovere fonti che si rivelino spam, fuori tema o di bassa qualità.';

  @override
  String get termsH5 => 'Modifiche';

  @override
  String get termsB5 =>
      'Possiamo aggiornare occasionalmente questi termini. Le modifiche sostanziali saranno segnalate nel riepilogo giornaliero prima della loro entrata in vigore.';

  @override
  String get onbRegionsTitle => 'Su cosa deve concentrarsi il feed?';

  @override
  String get onbRegionsSub =>
      'Vedrai sempre le corse mondiali. Scegli quali regioni ricevono peso extra.';

  @override
  String get onbDisciplinesTitle => 'Quali bici ti appassionano?';

  @override
  String get onbDisciplinesSub =>
      'Spunta tutte quelle pertinenti — le usiamo per colorare e dare priorità alle notizie.';

  @override
  String get onbDensityTitle => 'Quanto deve essere denso il feed?';

  @override
  String get onbDensitySub => 'Puoi cambiarlo in qualsiasi momento dal feed.';

  @override
  String get onbCompactSub =>
      'Massimo numero di articoli. Solo elenco, senza immagini.';

  @override
  String get onbComfortSub => 'Equilibrato. Immagine + testo.';

  @override
  String get onbLargeSub => 'Schede editoriali in evidenza.';

  @override
  String get nameWorld => 'Mondo';

  @override
  String get nameEu => 'UE';

  @override
  String get namePoland => 'Polonia';

  @override
  String get nameSpain => 'Spagna';

  @override
  String get descWorld => 'Tutto, ovunque.';

  @override
  String get descEu => 'Focus sulle corse europee.';

  @override
  String get descPoland => 'Corse e corridori polacchi.';

  @override
  String get descSpain => 'Corse e corridori spagnoli.';

  @override
  String get disciplineCxLong => 'Ciclocross';

  @override
  String get descRoad => 'Classifica, classiche, volate.';

  @override
  String get descMtb => 'XC, DH, enduro, freeride.';

  @override
  String get descGravel => 'Lunga distanza off-road.';

  @override
  String get descTrack => 'Corse su pista.';

  @override
  String get descCx => 'Fango, sabbia, ostacoli.';

  @override
  String get descBmx => 'Corsa e freestyle.';
}
