// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'Le fil du jour';

  @override
  String get updatedJustNow => 'MISE À JOUR À L\'INSTANT';

  @override
  String updatedMinutesAgo(int minutes) {
    return 'MISE À JOUR IL Y A $minutes MIN';
  }

  @override
  String updatedHoursAgo(int hours) {
    return 'MISE À JOUR IL Y A $hours H';
  }

  @override
  String updatedDaysAgo(int days) {
    return 'MISE À JOUR IL Y A $days J';
  }

  @override
  String storiesCount(int count) {
    return '$count ARTICLES';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NOUVEAUX DEPUIS VOTRE DERNIÈRE VISITE';
  }

  @override
  String get scrollForMore => 'FAITES DÉFILER POUR PLUS';

  @override
  String get endOfFeed => '— FIN DU FIL —';

  @override
  String get live => 'EN DIRECT';

  @override
  String get couldNotReachNewsRoom =>
      'Impossible de joindre la salle de rédaction';

  @override
  String get retry => 'Réessayer';

  @override
  String get noArticlesMatch => 'Aucun article ne correspond à ces filtres';

  @override
  String get tryBroadeningFilters =>
      'Essayez d\'élargir ou d\'effacer vos filtres.';

  @override
  String couldntLoadMore(String error) {
    return 'Impossible de charger plus : $error';
  }

  @override
  String get tabFeed => 'Fil';

  @override
  String get tabSearch => 'Rechercher';

  @override
  String get tabBookmarks => 'Favoris';

  @override
  String get tabCalendar => 'Calendrier';

  @override
  String get tabFollowing => 'Suivis';

  @override
  String get search => 'Rechercher';

  @override
  String get searchPlaceholderShort => 'Rechercher…';

  @override
  String get searchPlaceholderLong =>
      'Cherchez une course, un coureur, une équipe…';

  @override
  String get settings => 'Paramètres';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsCardDensity => 'Densité des cartes';

  @override
  String get settingsDensityCompact => 'Compacte';

  @override
  String get settingsDensityComfort => 'Standard';

  @override
  String get settingsDensityLarge => 'Large';

  @override
  String get settingsReducedMotion => 'Mouvement réduit';

  @override
  String get settingsReducedMotionDesc =>
      'Désactive les animations subtiles et les effets de brillance.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsTitle => 'Alertes actualités';

  @override
  String get settingsNotificationsDesc =>
      'Des notifications locales discrètes quand de nouveaux articles arrivent pour les disciplines que vous suivez. Sans compte, sans envoi de données.';

  @override
  String get settingsNotificationsTopicsLabel => 'DISCIPLINES';

  @override
  String get settingsNotificationsDeliveryLabel => 'LIVRAISON';

  @override
  String get settingsNotificationsDeliveryInstant => 'Instantané';

  @override
  String get settingsNotificationsDeliveryDaily => 'Résumé quotidien';

  @override
  String get settingsHiddenKeywordsLabel => 'MASQUER DES MOTS';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Les actualités dont le titre ou la description contient l\'un de ces mots sont masquées du fil et des notifications.';

  @override
  String get settingsHiddenKeywordsHint => 'Ajouter un mot à masquer…';

  @override
  String get raceCardAddToCalendar => 'Ajouter au calendrier';

  @override
  String get raceCardCalendarExportFailed =>
      'Échec de l\'export vers le calendrier.';

  @override
  String get settingsYourData => 'Vos données';

  @override
  String get settingsExportBookmarks => 'Exporter les favoris';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count enregistrés · copiés en JSON';
  }

  @override
  String get settingsRedoOnboarding => 'Refaire l\'introduction';

  @override
  String get settingsRedoOnboardingDesc =>
      'Choisissez à nouveau régions et disciplines.';

  @override
  String get settingsRedoOnboardingDialogTitle => 'Refaire l\'introduction ?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'Nous vous guiderons à nouveau pour choisir les régions, disciplines et densité des cartes. Vos favoris et abonnements restent intacts.';

  @override
  String get cancel => 'Annuler';

  @override
  String get redo => 'Refaire';

  @override
  String settingsBookmarksCopied(int count) {
    return '$count favoris copiés dans le presse-papiers.';
  }

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsAboutApp => 'À propos de Bike News Room';

  @override
  String get settingsPrivacy => 'Politique de confidentialité';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Copier le lien';

  @override
  String get shareNative => 'Partager';

  @override
  String get shareLinkCopied => 'Lien copié dans le presse-papiers.';

  @override
  String get shareTwitter => 'Partager sur X';

  @override
  String get shareBluesky => 'Partager sur Bluesky';

  @override
  String get shareWhatsApp => 'Partager sur WhatsApp';

  @override
  String get shareReddit => 'Partager sur Reddit';

  @override
  String get shareTelegram => 'Partager sur Telegram';

  @override
  String get alsoCoveredBy => 'AUSSI COUVERT PAR';

  @override
  String readOnSource(String source) {
    return 'Lire sur $source';
  }

  @override
  String get summary => 'RÉSUMÉ';

  @override
  String get digestHeadline => 'Le cyclisme, chaque matin à 7 h.';

  @override
  String get digestSubheadline =>
      'Un seul e-mail. Les histoires les plus importantes du jour. Sans pub, sans spam, désinscription en un clic.';

  @override
  String get digestEmailHint => 'vous@exemple.com';

  @override
  String get digestSubscribe => 'S\'ABONNER';

  @override
  String get digestInvalidEmail =>
      'Cela ne ressemble pas à une adresse e-mail.';

  @override
  String get digestNetworkError =>
      'Impossible de joindre la salle de rédaction. Réessayez dans une minute.';

  @override
  String get digestGenericError => 'Une erreur est survenue. Réessayez.';

  @override
  String get digestSuccess =>
      'Vérifiez votre boîte mail — confirmez pour commencer à recevoir le récap.';

  @override
  String get digestPrivacyPrefix => 'En vous abonnant, vous acceptez notre ';

  @override
  String get digestPrivacyLink => 'politique de confidentialité';

  @override
  String get digestPrivacySuffix => '. Désabonnez-vous quand vous voulez.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'ÉTAPE $current / $total';
  }

  @override
  String get onboardingStepRegions => 'RÉGIONS';

  @override
  String get onboardingStepDisciplines => 'DISCIPLINES';

  @override
  String get onboardingStepDensity => 'DENSITÉ';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingFinish => 'Voir le fil';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingBack => 'Retour';

  @override
  String get calendarFilterAll => 'TOUTES';

  @override
  String get calendarEmpty => 'Pas encore de courses à venir';

  @override
  String get calendarError => 'Impossible de charger le calendrier';

  @override
  String get raceCardToday => 'AUJOURD\'HUI';

  @override
  String get raceCardNow => 'EN COURS';

  @override
  String get raceCardTomorrow => 'DEMAIN';

  @override
  String raceCardDays(int days) {
    return '$days J';
  }

  @override
  String get tooltipBookmark => 'Enregistrer';

  @override
  String get tooltipClose => 'Fermer';

  @override
  String get tooltipUnfollow => 'Ne plus suivre';

  @override
  String get shareLinkCopiedShort => 'Lien copié';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'Plus…';

  @override
  String get follow => '+ SUIVRE';

  @override
  String followingName(String name) {
    return 'Vous suivez $name';
  }

  @override
  String get searchHint => 'Cherchez articles, coureurs, courses…';

  @override
  String get searchAddSourceTitle =>
      'Vous ne trouvez pas ce que vous cherchez ?';

  @override
  String get searchAddSourceBody =>
      'Collez n\'importe quel flux RSS ou site pour l\'ajouter comme source.';

  @override
  String get searchKeyToSearch => 'pour rechercher';

  @override
  String get searchKeyToClose => 'pour fermer';

  @override
  String get breakingHeader => 'URGENT · DERNIÈRE HEURE';

  @override
  String get regionWorld => '🌍 Monde';

  @override
  String get regionEu => '🇪🇺 UE';

  @override
  String get regionPoland => '🇵🇱 Pologne';

  @override
  String get regionSpain => '🇪🇸 Espagne';

  @override
  String get disciplineAll => 'Toutes';

  @override
  String get disciplineRoad => 'Route';

  @override
  String get disciplineMtb => 'VTT';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Piste';

  @override
  String get disciplineCx => 'Cyclo-cross';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'DERNIÈRE MISE À JOUR · $date';
  }

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutH1 => 'De quoi s\'agit-il';

  @override
  String get aboutB1 =>
      'Bike News Room est un seul fil d\'actualité cycliste, du monde entier — route, VTT, gravel, piste et cyclo-cross. Nous agrégeons des flux RSS publics et des sites de publications cyclistes, fédérations et blogs indépendants, pour que vous arrêtiez de jongler entre vingt onglets pour suivre l\'actu.';

  @override
  String get aboutH2 => 'Comment ça marche';

  @override
  String get aboutB2 =>
      'Toutes les 30 minutes, notre backend récupère les sources configurées, déduplique les articles quasi-identiques, les classe par région et discipline, puis les pousse dans le fil que vous lisez. N\'importe qui peut ajouter une source via le formulaire « Ajouter une source », et nous remontons automatiquement les domaines fréquemment cités dans les articles pour examen.';

  @override
  String get aboutH3 => 'Pas de paywall, pas de jeu d\'algorithme';

  @override
  String get aboutB3 =>
      'Nous ne classons pas par engagement, ne vous suivons pas entre les sites et ne vendons rien. L\'ordre est anti-chronologique, avec des filtres région et discipline que vous contrôlez. Si un article est ici, c\'est qu\'une publication cycliste l\'a réellement publié.';

  @override
  String get aboutH4 => 'Open source';

  @override
  String get aboutB4 =>
      'L\'ensemble du code source (backend Rust + frontend Flutter Web) est sur GitHub. Bug trouvé, source à ajouter, fork pour un autre sport ? Les pull requests sont bienvenues.';

  @override
  String get privacyTitle => 'Politique de confidentialité';

  @override
  String get privacyH1 => 'Ce que nous collectons';

  @override
  String get privacyB1 =>
      'Presque rien. Le frontend stocke vos préférences (thème, filtres, favoris, dernier article vu) dans le stockage local du navigateur — elles ne quittent jamais votre appareil. Si vous vous abonnez au récap quotidien, nous gardons votre adresse e-mail et un jeton de confirmation/désabonnement dans notre base ; c\'est tout.';

  @override
  String get privacyH2 => 'Ce que nous ne collectons pas';

  @override
  String get privacyB2 =>
      'Aucun SDK d\'analytique, aucun traqueur tiers, aucun cookie publicitaire, aucun fingerprinting, aucun log d\'IP au-delà des logs standards du serveur (rotation hebdomadaire), aucun profil de vos habitudes de lecture.';

  @override
  String get privacyH3 => 'Récap par e-mail';

  @override
  String get privacyB3 =>
      'Si vous vous abonnez, votre e-mail sert uniquement à vous envoyer le récap quotidien. Nous utilisons Resend pour la livraison — ils voient l\'adresse au moment de l\'envoi mais ne l\'utilisent pour rien d\'autre. Vous pouvez vous désabonner en un clic depuis n\'importe quel e-mail ; une fois désabonnée, l\'adresse reste dans la base (marquée comme telle) pour qu\'elle ne puisse pas être réinscrite par un tiers tant que vous ne reconfirmez pas.';

  @override
  String get privacyH4 => 'Cookies';

  @override
  String get privacyB4 =>
      'Nous ne posons pas de cookies. Le stockage local du navigateur sert uniquement à vos préférences — vider les données du site les efface.';

  @override
  String get privacyH5 => 'Vos données, votre choix';

  @override
  String get privacyB5 =>
      'Écrivez-nous à hello@bike-news-room et nous supprimerons tout enregistrement d\'abonnement que vous nous demandez. Il n\'y a rien d\'autre à supprimer car nous ne stockons rien d\'autre.';

  @override
  String get termsTitle => 'Conditions d\'utilisation';

  @override
  String get termsH1 => 'Utilisation du service';

  @override
  String get termsB1 =>
      'Bike News Room est un agrégateur d\'actualités gratuit et public. Vous pouvez l\'utiliser pour une lecture personnelle et non commerciale. N\'essayez pas de scraper l\'API à haute fréquence — il y a une limite par IP et nous renverrons volontiers un 429. Pour un accès massif, le code est ouvert ; déployez votre propre instance.';

  @override
  String get termsH2 => 'Contenu des articles';

  @override
  String get termsB2 =>
      'Les titres, extraits et liens affichés dans le fil proviennent de flux RSS publics et de pages de publications cyclistes. Le trafic des clics est envoyé à l\'éditeur original. Nous ne reproduisons pas les articles entiers — lisez toujours sur le site source pour soutenir celles et ceux qui les rédigent.';

  @override
  String get termsH3 => 'Aucune garantie';

  @override
  String get termsB3 =>
      'Le service est fourni en l\'état. Les articles peuvent contenir des inexactitudes (nous ne vérifions pas les faits des publications agrégées). Ne l\'utilisez pas comme seule source pour des décisions de course, des négociations contractuelles ou tout ce où une erreur a un coût réel.';

  @override
  String get termsH4 => 'Ajout de sources';

  @override
  String get termsB4 =>
      'N\'importe qui peut soumettre une URL de source. Nous effectuons des contrôles de sécurité automatisés (URL guard, limites de taille, sondage de contenu) mais nous nous réservons le droit de retirer les sources qui s\'avéreraient être du spam, hors-sujet ou de mauvaise qualité.';

  @override
  String get termsH5 => 'Modifications';

  @override
  String get termsB5 =>
      'Nous pouvons mettre à jour ces conditions occasionnellement. Les changements importants seront annoncés dans le récap quotidien avant leur entrée en vigueur.';

  @override
  String get onbRegionsTitle => 'Sur quoi le fil doit-il se concentrer ?';

  @override
  String get onbRegionsSub =>
      'Vous verrez toujours les courses mondiales. Choisissez les régions à mettre en avant.';

  @override
  String get onbDisciplinesTitle => 'Quels vélos vous attirent ?';

  @override
  String get onbDisciplinesSub =>
      'Cochez tout ce qui s\'applique — nous l\'utilisons pour le code couleur et la priorisation.';

  @override
  String get onbDensityTitle => 'À quel point le fil doit-il être dense ?';

  @override
  String get onbDensitySub =>
      'Vous pourrez le modifier à tout moment depuis le fil.';

  @override
  String get onbCompactSub => 'Maximum d\'articles. Liste, sans images.';

  @override
  String get onbComfortSub => 'Équilibré. Image + texte.';

  @override
  String get onbLargeSub => 'Grandes cartes éditoriales.';

  @override
  String get nameWorld => 'Monde';

  @override
  String get nameEu => 'UE';

  @override
  String get namePoland => 'Pologne';

  @override
  String get nameSpain => 'Espagne';

  @override
  String get descWorld => 'Tout, partout.';

  @override
  String get descEu => 'Focus sur les courses européennes.';

  @override
  String get descPoland => 'Courses et coureurs polonais.';

  @override
  String get descSpain => 'Courses et coureurs espagnols.';

  @override
  String get disciplineCxLong => 'Cyclo-cross';

  @override
  String get descRoad => 'Classement général, classiques, sprints.';

  @override
  String get descMtb => 'XC, DH, enduro, freeride.';

  @override
  String get descGravel => 'Longues distances hors asphalte.';

  @override
  String get descTrack => 'Courses sur piste.';

  @override
  String get descCx => 'Boue, sable, barrières.';

  @override
  String get descBmx => 'Course et freestyle.';
}
