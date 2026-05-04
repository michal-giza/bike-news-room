import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Bike News Room'**
  String get appName;

  /// No description provided for @todaysWire.
  ///
  /// In en, this message translates to:
  /// **'Today\'s wire'**
  String get todaysWire;

  /// No description provided for @updatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'UPDATED JUST NOW'**
  String get updatedJustNow;

  /// No description provided for @updatedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'UPDATED {minutes}M AGO'**
  String updatedMinutesAgo(int minutes);

  /// No description provided for @updatedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'UPDATED {hours}H AGO'**
  String updatedHoursAgo(int hours);

  /// No description provided for @updatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'UPDATED {days}D AGO'**
  String updatedDaysAgo(int days);

  /// No description provided for @storiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} STORIES'**
  String storiesCount(int count);

  /// No description provided for @newSinceLastVisit.
  ///
  /// In en, this message translates to:
  /// **'{count} NEW SINCE YOUR LAST VISIT'**
  String newSinceLastVisit(int count);

  /// No description provided for @scrollForMore.
  ///
  /// In en, this message translates to:
  /// **'SCROLL FOR MORE'**
  String get scrollForMore;

  /// No description provided for @endOfFeed.
  ///
  /// In en, this message translates to:
  /// **'— END OF FEED —'**
  String get endOfFeed;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @couldNotReachNewsRoom.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the news room'**
  String get couldNotReachNewsRoom;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noArticlesMatch.
  ///
  /// In en, this message translates to:
  /// **'No articles match these filters'**
  String get noArticlesMatch;

  /// No description provided for @tryBroadeningFilters.
  ///
  /// In en, this message translates to:
  /// **'Try broadening or clearing your filters.'**
  String get tryBroadeningFilters;

  /// No description provided for @couldntLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more: {error}'**
  String couldntLoadMore(String error);

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get tabFeed;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get tabBookmarks;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get tabFollowing;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchPlaceholderShort.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchPlaceholderShort;

  /// No description provided for @searchPlaceholderLong.
  ///
  /// In en, this message translates to:
  /// **'Search races, riders, teams…'**
  String get searchPlaceholderLong;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Card density'**
  String get settingsCardDensity;

  /// No description provided for @settingsDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get settingsDensityCompact;

  /// No description provided for @settingsDensityComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get settingsDensityComfort;

  /// No description provided for @settingsDensityLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsDensityLarge;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get settingsReducedMotion;

  /// No description provided for @settingsReducedMotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Skip subtle animations and shimmer effects.'**
  String get settingsReducedMotionDesc;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsYourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsYourData;

  /// No description provided for @settingsExportBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Export bookmarks'**
  String get settingsExportBookmarks;

  /// No description provided for @settingsExportBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} saved · copied as JSON'**
  String settingsExportBookmarksDesc(int count);

  /// No description provided for @settingsRedoOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Redo onboarding'**
  String get settingsRedoOnboarding;

  /// No description provided for @settingsRedoOnboardingDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick fresh regions and disciplines.'**
  String get settingsRedoOnboardingDesc;

  /// No description provided for @settingsRedoOnboardingDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Redo onboarding?'**
  String get settingsRedoOnboardingDialogTitle;

  /// No description provided for @settingsRedoOnboardingDialogBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll walk you through picking regions, disciplines, and card density again. Your bookmarks and following list will stay intact.'**
  String get settingsRedoOnboardingDialogBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @settingsBookmarksCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} bookmarks to clipboard.'**
  String settingsBookmarksCopied(int count);

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Bike News Room'**
  String get settingsAboutApp;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTerms;

  /// No description provided for @settingsVersionLine.
  ///
  /// In en, this message translates to:
  /// **'BIKE NEWS ROOM · v{version}'**
  String settingsVersionLine(String version);

  /// No description provided for @shareCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareCopy;

  /// No description provided for @shareNative.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareNative;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard.'**
  String get shareLinkCopied;

  /// No description provided for @shareTwitter.
  ///
  /// In en, this message translates to:
  /// **'Share on X'**
  String get shareTwitter;

  /// No description provided for @shareBluesky.
  ///
  /// In en, this message translates to:
  /// **'Share on Bluesky'**
  String get shareBluesky;

  /// No description provided for @shareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareWhatsApp;

  /// No description provided for @shareReddit.
  ///
  /// In en, this message translates to:
  /// **'Share on Reddit'**
  String get shareReddit;

  /// No description provided for @shareTelegram.
  ///
  /// In en, this message translates to:
  /// **'Share on Telegram'**
  String get shareTelegram;

  /// No description provided for @alsoCoveredBy.
  ///
  /// In en, this message translates to:
  /// **'ALSO COVERED BY'**
  String get alsoCoveredBy;

  /// No description provided for @readOnSource.
  ///
  /// In en, this message translates to:
  /// **'Read on {source}'**
  String readOnSource(String source);

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get summary;

  /// No description provided for @digestHeadline.
  ///
  /// In en, this message translates to:
  /// **'Cycling news, every morning at 7.'**
  String get digestHeadline;

  /// No description provided for @digestSubheadline.
  ///
  /// In en, this message translates to:
  /// **'One email. The day\'s most important stories. No ads, no spam, unsubscribe in one click.'**
  String get digestSubheadline;

  /// No description provided for @digestEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get digestEmailHint;

  /// No description provided for @digestSubscribe.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE'**
  String get digestSubscribe;

  /// No description provided for @digestInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email.'**
  String get digestInvalidEmail;

  /// No description provided for @digestNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the news room. Try again in a minute.'**
  String get digestNetworkError;

  /// No description provided for @digestGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get digestGenericError;

  /// No description provided for @digestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox — confirm to start receiving the digest.'**
  String get digestSuccess;

  /// No description provided for @digestPrivacyPrefix.
  ///
  /// In en, this message translates to:
  /// **'By subscribing you agree to our '**
  String get digestPrivacyPrefix;

  /// No description provided for @digestPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get digestPrivacyLink;

  /// No description provided for @digestPrivacySuffix.
  ///
  /// In en, this message translates to:
  /// **'. Unsubscribe anytime.'**
  String get digestPrivacySuffix;

  /// No description provided for @onboardingStepCounter.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} / {total}'**
  String onboardingStepCounter(int current, int total);

  /// No description provided for @onboardingStepRegions.
  ///
  /// In en, this message translates to:
  /// **'REGIONS'**
  String get onboardingStepRegions;

  /// No description provided for @onboardingStepDisciplines.
  ///
  /// In en, this message translates to:
  /// **'DISCIPLINES'**
  String get onboardingStepDisciplines;

  /// No description provided for @onboardingStepDensity.
  ///
  /// In en, this message translates to:
  /// **'DENSITY'**
  String get onboardingStepDensity;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Show me the wire'**
  String get onboardingFinish;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @calendarFilterAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get calendarFilterAll;

  /// No description provided for @calendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming races yet'**
  String get calendarEmpty;

  /// No description provided for @calendarError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the calendar'**
  String get calendarError;

  /// No description provided for @raceCardToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get raceCardToday;

  /// No description provided for @raceCardNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get raceCardNow;

  /// No description provided for @raceCardTomorrow.
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get raceCardTomorrow;

  /// No description provided for @raceCardDays.
  ///
  /// In en, this message translates to:
  /// **'{days}D'**
  String raceCardDays(int days);

  /// No description provided for @tooltipBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get tooltipBookmark;

  /// No description provided for @tooltipClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tooltipClose;

  /// No description provided for @tooltipUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get tooltipUnfollow;

  /// No description provided for @shareLinkCopiedShort.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get shareLinkCopiedShort;

  /// No description provided for @shareXTwitter.
  ///
  /// In en, this message translates to:
  /// **'X / Twitter'**
  String get shareXTwitter;

  /// No description provided for @shareMore.
  ///
  /// In en, this message translates to:
  /// **'More…'**
  String get shareMore;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'+ FOLLOW'**
  String get follow;

  /// No description provided for @followingName.
  ///
  /// In en, this message translates to:
  /// **'Following {name}'**
  String followingName(String name);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles, riders, races…'**
  String get searchHint;

  /// No description provided for @searchAddSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t see what you\'re looking for?'**
  String get searchAddSourceTitle;

  /// No description provided for @searchAddSourceBody.
  ///
  /// In en, this message translates to:
  /// **'Paste any RSS feed or website to add it as a source.'**
  String get searchAddSourceBody;

  /// No description provided for @searchKeyToSearch.
  ///
  /// In en, this message translates to:
  /// **'to search'**
  String get searchKeyToSearch;

  /// No description provided for @searchKeyToClose.
  ///
  /// In en, this message translates to:
  /// **'to close'**
  String get searchKeyToClose;

  /// No description provided for @breakingHeader.
  ///
  /// In en, this message translates to:
  /// **'BREAKING · LAST HOUR'**
  String get breakingHeader;

  /// No description provided for @regionWorld.
  ///
  /// In en, this message translates to:
  /// **'🌍 World'**
  String get regionWorld;

  /// No description provided for @regionEu.
  ///
  /// In en, this message translates to:
  /// **'🇪🇺 EU'**
  String get regionEu;

  /// No description provided for @regionPoland.
  ///
  /// In en, this message translates to:
  /// **'🇵🇱 Poland'**
  String get regionPoland;

  /// No description provided for @regionSpain.
  ///
  /// In en, this message translates to:
  /// **'🇪🇸 Spain'**
  String get regionSpain;

  /// No description provided for @disciplineAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get disciplineAll;

  /// No description provided for @disciplineRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get disciplineRoad;

  /// No description provided for @disciplineMtb.
  ///
  /// In en, this message translates to:
  /// **'MTB'**
  String get disciplineMtb;

  /// No description provided for @disciplineGravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get disciplineGravel;

  /// No description provided for @disciplineTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get disciplineTrack;

  /// No description provided for @disciplineCx.
  ///
  /// In en, this message translates to:
  /// **'CX'**
  String get disciplineCx;

  /// No description provided for @disciplineBmx.
  ///
  /// In en, this message translates to:
  /// **'BMX'**
  String get disciplineBmx;

  /// No description provided for @infoLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'LAST UPDATED · {date}'**
  String infoLastUpdated(String date);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutH1.
  ///
  /// In en, this message translates to:
  /// **'What this is'**
  String get aboutH1;

  /// No description provided for @aboutB1.
  ///
  /// In en, this message translates to:
  /// **'Bike News Room is a single feed for cycling news from around the world — road, MTB, gravel, track, and cyclocross. We aggregate from public RSS feeds and websites of cycling publications, federations, and independent blogs, so you stop hopping between twenty tabs to keep up.'**
  String get aboutB1;

  /// No description provided for @aboutH2.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get aboutH2;

  /// No description provided for @aboutB2.
  ///
  /// In en, this message translates to:
  /// **'Every 30 minutes our backend pulls from the configured sources, deduplicates near-identical stories, classifies by region and discipline, and pushes them into the feed you\'re reading. Sources can be added by anyone via the \"Add a source\" form, and we automatically surface candidate domains we see being cited often in articles for review.'**
  String get aboutB2;

  /// No description provided for @aboutH3.
  ///
  /// In en, this message translates to:
  /// **'No paywall, no algorithm games'**
  String get aboutH3;

  /// No description provided for @aboutB3.
  ///
  /// In en, this message translates to:
  /// **'We don\'t rank by engagement, we don\'t track you between sites, and we don\'t sell anything. The order is reverse-chronological with regional and discipline filters you control. If a story is here, it\'s because a cycling publication actually published it.'**
  String get aboutB3;

  /// No description provided for @aboutH4.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get aboutH4;

  /// No description provided for @aboutB4.
  ///
  /// In en, this message translates to:
  /// **'The full source code (Rust backend + Flutter Web frontend) is on GitHub. Found a bug, want a new source added, or want to fork it for another sport? Pull requests welcome.'**
  String get aboutB4;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @privacyH1.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get privacyH1;

  /// No description provided for @privacyB1.
  ///
  /// In en, this message translates to:
  /// **'Almost nothing. The frontend stores your preferences (theme, filters, bookmarks, the article you\'ve last seen) in your browser\'s local storage — they never leave your device. If you sign up for the daily digest, we store your email address and a confirmation/unsubscribe token in our database; that\'s it.'**
  String get privacyB1;

  /// No description provided for @privacyH2.
  ///
  /// In en, this message translates to:
  /// **'What we don\'t collect'**
  String get privacyH2;

  /// No description provided for @privacyB2.
  ///
  /// In en, this message translates to:
  /// **'No analytics SDKs, no third-party trackers, no advertising cookies, no fingerprinting, no IP-address logging beyond standard server access logs (rotated weekly), no profile of your reading habits.'**
  String get privacyB2;

  /// No description provided for @privacyH3.
  ///
  /// In en, this message translates to:
  /// **'Email digest'**
  String get privacyH3;

  /// No description provided for @privacyB3.
  ///
  /// In en, this message translates to:
  /// **'If you subscribe, your email is used solely to send you the daily digest. We use Resend to deliver — they see the address while delivering, but don\'t use it for any other purpose. You can unsubscribe with one click from any digest email; once unsubscribed, the address stays in our database (marked as such) so it can\'t be re-signed-up by a third party until you explicitly re-confirm.'**
  String get privacyB3;

  /// No description provided for @privacyH4.
  ///
  /// In en, this message translates to:
  /// **'Cookies'**
  String get privacyH4;

  /// No description provided for @privacyB4.
  ///
  /// In en, this message translates to:
  /// **'We don\'t set cookies. Browser local storage is used for your in-app preferences — clearing site data wipes them.'**
  String get privacyB4;

  /// No description provided for @privacyH5.
  ///
  /// In en, this message translates to:
  /// **'Your data, your choice'**
  String get privacyH5;

  /// No description provided for @privacyB5.
  ///
  /// In en, this message translates to:
  /// **'Email us at hello@bike-news-room and we\'ll delete any subscription record you ask us to. There\'s nothing else to delete because there\'s nothing else to store.'**
  String get privacyB5;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsTitle;

  /// No description provided for @termsH1.
  ///
  /// In en, this message translates to:
  /// **'Use of the service'**
  String get termsH1;

  /// No description provided for @termsB1.
  ///
  /// In en, this message translates to:
  /// **'Bike News Room is a free, public news aggregator. You may use it for personal, non-commercial reading. Don\'t try to scrape the API at high volume — there\'s a per-IP rate limit and we\'ll happily 429 you. If you need bulk access, the source code is open; run your own instance.'**
  String get termsB1;

  /// No description provided for @termsH2.
  ///
  /// In en, this message translates to:
  /// **'Article content'**
  String get termsH2;

  /// No description provided for @termsB2.
  ///
  /// In en, this message translates to:
  /// **'Headlines, snippets, and links displayed in the feed are sourced from publicly available RSS feeds and pages of cycling publications. Click-through traffic is sent to the original publisher. We don\'t reproduce full articles — always read on the source site to support the people doing the reporting.'**
  String get termsB2;

  /// No description provided for @termsH3.
  ///
  /// In en, this message translates to:
  /// **'No warranty'**
  String get termsH3;

  /// No description provided for @termsB3.
  ///
  /// In en, this message translates to:
  /// **'The service is provided as-is. Articles may contain inaccuracies (we don\'t fact-check the publications we aggregate). Don\'t use this as your only source for race-day decisions, contract negotiations, or anything else where being wrong has real cost.'**
  String get termsB3;

  /// No description provided for @termsH4.
  ///
  /// In en, this message translates to:
  /// **'Adding sources'**
  String get termsH4;

  /// No description provided for @termsB4.
  ///
  /// In en, this message translates to:
  /// **'Anyone can submit a source URL. We do automated safety checks (URL guard, payload limits, content probe) but we reserve the right to remove sources that turn out to be spam, off-topic, or low-quality.'**
  String get termsB4;

  /// No description provided for @termsH5.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get termsH5;

  /// No description provided for @termsB5.
  ///
  /// In en, this message translates to:
  /// **'We may update these terms occasionally. Material changes will be flagged in the daily digest before they take effect.'**
  String get termsB5;

  /// No description provided for @onbRegionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should the wire focus?'**
  String get onbRegionsTitle;

  /// No description provided for @onbRegionsSub.
  ///
  /// In en, this message translates to:
  /// **'You\'ll always see global racing. Pick which regions get extra weight.'**
  String get onbRegionsSub;

  /// No description provided for @onbDisciplinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Which bikes pull you in?'**
  String get onbDisciplinesTitle;

  /// No description provided for @onbDisciplinesSub.
  ///
  /// In en, this message translates to:
  /// **'Pick all that apply — we use this to colour-tag and prioritise stories.'**
  String get onbDisciplinesSub;

  /// No description provided for @onbDensityTitle.
  ///
  /// In en, this message translates to:
  /// **'How dense should the feed be?'**
  String get onbDensityTitle;

  /// No description provided for @onbDensitySub.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time from the feed.'**
  String get onbDensitySub;

  /// No description provided for @onbCompactSub.
  ///
  /// In en, this message translates to:
  /// **'Maximum stories. List rows, no images.'**
  String get onbCompactSub;

  /// No description provided for @onbComfortSub.
  ///
  /// In en, this message translates to:
  /// **'Balanced. Image + body.'**
  String get onbComfortSub;

  /// No description provided for @onbLargeSub.
  ///
  /// In en, this message translates to:
  /// **'Editorial hero cards.'**
  String get onbLargeSub;

  /// No description provided for @nameWorld.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get nameWorld;

  /// No description provided for @nameEu.
  ///
  /// In en, this message translates to:
  /// **'EU'**
  String get nameEu;

  /// No description provided for @namePoland.
  ///
  /// In en, this message translates to:
  /// **'Poland'**
  String get namePoland;

  /// No description provided for @nameSpain.
  ///
  /// In en, this message translates to:
  /// **'Spain'**
  String get nameSpain;

  /// No description provided for @descWorld.
  ///
  /// In en, this message translates to:
  /// **'Everything, everywhere.'**
  String get descWorld;

  /// No description provided for @descEu.
  ///
  /// In en, this message translates to:
  /// **'European racing focus.'**
  String get descEu;

  /// No description provided for @descPoland.
  ///
  /// In en, this message translates to:
  /// **'PL races + riders.'**
  String get descPoland;

  /// No description provided for @descSpain.
  ///
  /// In en, this message translates to:
  /// **'ES races + riders.'**
  String get descSpain;

  /// No description provided for @disciplineCxLong.
  ///
  /// In en, this message translates to:
  /// **'Cyclocross'**
  String get disciplineCxLong;

  /// No description provided for @descRoad.
  ///
  /// In en, this message translates to:
  /// **'GC, classics, sprints.'**
  String get descRoad;

  /// No description provided for @descMtb.
  ///
  /// In en, this message translates to:
  /// **'XC, DH, enduro, freeride.'**
  String get descMtb;

  /// No description provided for @descGravel.
  ///
  /// In en, this message translates to:
  /// **'Long-format off-tarmac.'**
  String get descGravel;

  /// No description provided for @descTrack.
  ///
  /// In en, this message translates to:
  /// **'Velodrome racing.'**
  String get descTrack;

  /// No description provided for @descCx.
  ///
  /// In en, this message translates to:
  /// **'Mud, sand, barriers.'**
  String get descCx;

  /// No description provided for @descBmx.
  ///
  /// In en, this message translates to:
  /// **'Race + freestyle.'**
  String get descBmx;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'nl',
    'pl',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
