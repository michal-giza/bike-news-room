// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'Today\'s wire';

  @override
  String get updatedJustNow => 'UPDATED JUST NOW';

  @override
  String updatedMinutesAgo(int minutes) {
    return 'UPDATED ${minutes}M AGO';
  }

  @override
  String updatedHoursAgo(int hours) {
    return 'UPDATED ${hours}H AGO';
  }

  @override
  String updatedDaysAgo(int days) {
    return 'UPDATED ${days}D AGO';
  }

  @override
  String storiesCount(int count) {
    return '$count STORIES';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NEW SINCE YOUR LAST VISIT';
  }

  @override
  String get scrollForMore => 'SCROLL FOR MORE';

  @override
  String get endOfFeed => '— END OF FEED —';

  @override
  String get live => 'LIVE';

  @override
  String get couldNotReachNewsRoom => 'Couldn\'t reach the news room';

  @override
  String get retry => 'Retry';

  @override
  String get noArticlesMatch => 'No articles match these filters';

  @override
  String get tryBroadeningFilters => 'Try broadening or clearing your filters.';

  @override
  String couldntLoadMore(String error) {
    return 'Couldn\'t load more: $error';
  }

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabBookmarks => 'Bookmarks';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabFollowing => 'Following';

  @override
  String get search => 'Search';

  @override
  String get searchPlaceholderShort => 'Search…';

  @override
  String get searchPlaceholderLong => 'Search races, riders, teams…';

  @override
  String get settings => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsCardDensity => 'Card density';

  @override
  String get settingsDensityCompact => 'Compact';

  @override
  String get settingsDensityComfort => 'Comfort';

  @override
  String get settingsDensityLarge => 'Large';

  @override
  String get settingsReducedMotion => 'Reduced motion';

  @override
  String get settingsReducedMotionDesc =>
      'Skip subtle animations and shimmer effects.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsTitle => 'News alerts';

  @override
  String get settingsNotificationsDesc =>
      'Quiet on-device notifications when new stories land for the disciplines you follow. No account, no data leaves your phone.';

  @override
  String get settingsNotificationsTopicsLabel => 'DISCIPLINES';

  @override
  String get settingsNotificationsDeliveryLabel => 'DELIVERY';

  @override
  String get settingsNotificationsDeliveryInstant => 'Instant';

  @override
  String get settingsNotificationsDeliveryDaily => 'Daily digest';

  @override
  String get settingsHiddenKeywordsLabel => 'HIDE KEYWORDS';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Stories whose title or description contain any of these words are hidden from the feed and notifications.';

  @override
  String get settingsHiddenKeywordsHint => 'Add a word to hide…';

  @override
  String get raceCardAddToCalendar => 'Add to calendar';

  @override
  String get raceCardCalendarExportFailed => 'Could not export to calendar.';

  @override
  String get settingsYourData => 'Your data';

  @override
  String get settingsExportBookmarks => 'Export bookmarks';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count saved · copied as JSON';
  }

  @override
  String get settingsRedoOnboarding => 'Redo onboarding';

  @override
  String get settingsRedoOnboardingDesc =>
      'Pick fresh regions and disciplines.';

  @override
  String get settingsRedoOnboardingDialogTitle => 'Redo onboarding?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'We\'ll walk you through picking regions, disciplines, and card density again. Your bookmarks and following list will stay intact.';

  @override
  String get cancel => 'Cancel';

  @override
  String get redo => 'Redo';

  @override
  String settingsBookmarksCopied(int count) {
    return 'Copied $count bookmarks to clipboard.';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutApp => 'About Bike News Room';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Copy link';

  @override
  String get shareNative => 'Share';

  @override
  String get shareLinkCopied => 'Link copied to clipboard.';

  @override
  String get shareTwitter => 'Share on X';

  @override
  String get shareBluesky => 'Share on Bluesky';

  @override
  String get shareWhatsApp => 'Share on WhatsApp';

  @override
  String get shareReddit => 'Share on Reddit';

  @override
  String get shareTelegram => 'Share on Telegram';

  @override
  String get alsoCoveredBy => 'ALSO COVERED BY';

  @override
  String readOnSource(String source) {
    return 'Read on $source';
  }

  @override
  String get summary => 'SUMMARY';

  @override
  String get digestHeadline => 'Cycling news, every morning at 7.';

  @override
  String get digestSubheadline =>
      'One email. The day\'s most important stories. No ads, no spam, unsubscribe in one click.';

  @override
  String get digestEmailHint => 'you@example.com';

  @override
  String get digestSubscribe => 'SUBSCRIBE';

  @override
  String get digestInvalidEmail => 'That doesn\'t look like an email.';

  @override
  String get digestNetworkError =>
      'Couldn\'t reach the news room. Try again in a minute.';

  @override
  String get digestGenericError => 'Something went wrong. Try again.';

  @override
  String get digestSuccess =>
      'Check your inbox — confirm to start receiving the digest.';

  @override
  String get digestPrivacyPrefix => 'By subscribing you agree to our ';

  @override
  String get digestPrivacyLink => 'privacy policy';

  @override
  String get digestPrivacySuffix => '. Unsubscribe anytime.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'STEP $current / $total';
  }

  @override
  String get onboardingStepRegions => 'REGIONS';

  @override
  String get onboardingStepDisciplines => 'DISCIPLINES';

  @override
  String get onboardingStepDensity => 'DENSITY';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Show me the wire';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingBack => 'Back';

  @override
  String get calendarFilterAll => 'ALL';

  @override
  String get calendarEmpty => 'No upcoming races yet';

  @override
  String get calendarError => 'Couldn\'t load the calendar';

  @override
  String get raceCardToday => 'TODAY';

  @override
  String get raceCardNow => 'NOW';

  @override
  String get raceCardTomorrow => 'TOMORROW';

  @override
  String raceCardDays(int days) {
    return '${days}D';
  }

  @override
  String get tooltipBookmark => 'Bookmark';

  @override
  String get tooltipClose => 'Close';

  @override
  String get tooltipUnfollow => 'Unfollow';

  @override
  String get shareLinkCopiedShort => 'Link copied';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'More…';

  @override
  String get follow => '+ FOLLOW';

  @override
  String followingName(String name) {
    return 'Following $name';
  }

  @override
  String get searchHint => 'Search articles, riders, races…';

  @override
  String get searchAddSourceTitle => 'Don\'t see what you\'re looking for?';

  @override
  String get searchAddSourceBody =>
      'Paste any RSS feed or website to add it as a source.';

  @override
  String get searchKeyToSearch => 'to search';

  @override
  String get searchKeyToClose => 'to close';

  @override
  String get breakingHeader => 'BREAKING · LAST HOUR';

  @override
  String get regionWorld => '🌍 World';

  @override
  String get regionEu => '🇪🇺 EU';

  @override
  String get regionPoland => '🇵🇱 Poland';

  @override
  String get regionSpain => '🇪🇸 Spain';

  @override
  String get disciplineAll => 'All';

  @override
  String get disciplineRoad => 'Road';

  @override
  String get disciplineMtb => 'MTB';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Track';

  @override
  String get disciplineCx => 'CX';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'LAST UPDATED · $date';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutH1 => 'What this is';

  @override
  String get aboutB1 =>
      'Bike News Room is a single feed for cycling news from around the world — road, MTB, gravel, track, and cyclocross. We aggregate from public RSS feeds and websites of cycling publications, federations, and independent blogs, so you stop hopping between twenty tabs to keep up.';

  @override
  String get aboutH2 => 'How it works';

  @override
  String get aboutB2 =>
      'Every 30 minutes our backend pulls from the configured sources, deduplicates near-identical stories, classifies by region and discipline, and pushes them into the feed you\'re reading. Sources can be added by anyone via the \"Add a source\" form, and we automatically surface candidate domains we see being cited often in articles for review.';

  @override
  String get aboutH3 => 'No paywall, no algorithm games';

  @override
  String get aboutB3 =>
      'We don\'t rank by engagement, we don\'t track you between sites, and we don\'t sell anything. The order is reverse-chronological with regional and discipline filters you control. If a story is here, it\'s because a cycling publication actually published it.';

  @override
  String get aboutH4 => 'Open source';

  @override
  String get aboutB4 =>
      'The full source code (Rust backend + Flutter Web frontend) is on GitHub. Found a bug, want a new source added, or want to fork it for another sport? Pull requests welcome.';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyH1 => 'What we collect';

  @override
  String get privacyB1 =>
      'Almost nothing. The frontend stores your preferences (theme, filters, bookmarks, the article you\'ve last seen) in your browser\'s local storage — they never leave your device. If you sign up for the daily digest, we store your email address and a confirmation/unsubscribe token in our database; that\'s it.';

  @override
  String get privacyH2 => 'What we don\'t collect';

  @override
  String get privacyB2 =>
      'No analytics SDKs, no third-party trackers, no advertising cookies, no fingerprinting, no IP-address logging beyond standard server access logs (rotated weekly), no profile of your reading habits.';

  @override
  String get privacyH3 => 'Email digest';

  @override
  String get privacyB3 =>
      'If you subscribe, your email is used solely to send you the daily digest. We use Resend to deliver — they see the address while delivering, but don\'t use it for any other purpose. You can unsubscribe with one click from any digest email; once unsubscribed, the address stays in our database (marked as such) so it can\'t be re-signed-up by a third party until you explicitly re-confirm.';

  @override
  String get privacyH4 => 'Cookies';

  @override
  String get privacyB4 =>
      'We don\'t set cookies. Browser local storage is used for your in-app preferences — clearing site data wipes them.';

  @override
  String get privacyH5 => 'Your data, your choice';

  @override
  String get privacyB5 =>
      'Email us at hello@bike-news-room and we\'ll delete any subscription record you ask us to. There\'s nothing else to delete because there\'s nothing else to store.';

  @override
  String get termsTitle => 'Terms of Service';

  @override
  String get termsH1 => 'Use of the service';

  @override
  String get termsB1 =>
      'Bike News Room is a free, public news aggregator. You may use it for personal, non-commercial reading. Don\'t try to scrape the API at high volume — there\'s a per-IP rate limit and we\'ll happily 429 you. If you need bulk access, the source code is open; run your own instance.';

  @override
  String get termsH2 => 'Article content';

  @override
  String get termsB2 =>
      'Headlines, snippets, and links displayed in the feed are sourced from publicly available RSS feeds and pages of cycling publications. Click-through traffic is sent to the original publisher. We don\'t reproduce full articles — always read on the source site to support the people doing the reporting.';

  @override
  String get termsH3 => 'No warranty';

  @override
  String get termsB3 =>
      'The service is provided as-is. Articles may contain inaccuracies (we don\'t fact-check the publications we aggregate). Don\'t use this as your only source for race-day decisions, contract negotiations, or anything else where being wrong has real cost.';

  @override
  String get termsH4 => 'Adding sources';

  @override
  String get termsB4 =>
      'Anyone can submit a source URL. We do automated safety checks (URL guard, payload limits, content probe) but we reserve the right to remove sources that turn out to be spam, off-topic, or low-quality.';

  @override
  String get termsH5 => 'Changes';

  @override
  String get termsB5 =>
      'We may update these terms occasionally. Material changes will be flagged in the daily digest before they take effect.';

  @override
  String get onbRegionsTitle => 'Where should the wire focus?';

  @override
  String get onbRegionsSub =>
      'You\'ll always see global racing. Pick which regions get extra weight.';

  @override
  String get onbDisciplinesTitle => 'Which bikes pull you in?';

  @override
  String get onbDisciplinesSub =>
      'Pick all that apply — we use this to colour-tag and prioritise stories.';

  @override
  String get onbDensityTitle => 'How dense should the feed be?';

  @override
  String get onbDensitySub => 'You can change this any time from the feed.';

  @override
  String get onbCompactSub => 'Maximum stories. List rows, no images.';

  @override
  String get onbComfortSub => 'Balanced. Image + body.';

  @override
  String get onbLargeSub => 'Editorial hero cards.';

  @override
  String get nameWorld => 'World';

  @override
  String get nameEu => 'EU';

  @override
  String get namePoland => 'Poland';

  @override
  String get nameSpain => 'Spain';

  @override
  String get descWorld => 'Everything, everywhere.';

  @override
  String get descEu => 'European racing focus.';

  @override
  String get descPoland => 'PL races + riders.';

  @override
  String get descSpain => 'ES races + riders.';

  @override
  String get disciplineCxLong => 'Cyclocross';

  @override
  String get descRoad => 'GC, classics, sprints.';

  @override
  String get descMtb => 'XC, DH, enduro, freeride.';

  @override
  String get descGravel => 'Long-format off-tarmac.';

  @override
  String get descTrack => 'Velodrome racing.';

  @override
  String get descCx => 'Mud, sand, barriers.';

  @override
  String get descBmx => 'Race + freestyle.';
}
