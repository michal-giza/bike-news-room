// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'Wiadomości dnia';

  @override
  String get updatedJustNow => 'ZAKTUALIZOWANO PRZED CHWILĄ';

  @override
  String updatedMinutesAgo(int minutes) {
    return 'ZAKTUALIZOWANO $minutes MIN TEMU';
  }

  @override
  String updatedHoursAgo(int hours) {
    return 'ZAKTUALIZOWANO $hours GODZ. TEMU';
  }

  @override
  String updatedDaysAgo(int days) {
    return 'ZAKTUALIZOWANO $days DNI TEMU';
  }

  @override
  String storiesCount(int count) {
    return '$count ARTYKUŁÓW';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NOWYCH OD OSTATNIEJ WIZYTY';
  }

  @override
  String get scrollForMore => 'PRZEWIŃ PO WIĘCEJ';

  @override
  String get endOfFeed => '— KONIEC LISTY —';

  @override
  String get live => 'NA ŻYWO';

  @override
  String get couldNotReachNewsRoom => 'Nie udało się połączyć z redakcją';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get noArticlesMatch => 'Żadne artykuły nie pasują do tych filtrów';

  @override
  String get tryBroadeningFilters => 'Spróbuj rozszerzyć lub wyczyścić filtry.';

  @override
  String couldntLoadMore(String error) {
    return 'Nie udało się wczytać więcej: $error';
  }

  @override
  String get tabFeed => 'Aktualności';

  @override
  String get tabSearch => 'Szukaj';

  @override
  String get tabBookmarks => 'Zapisane';

  @override
  String get tabCalendar => 'Kalendarz';

  @override
  String get tabFollowing => 'Obserwowane';

  @override
  String get search => 'Szukaj';

  @override
  String get searchPlaceholderShort => 'Szukaj…';

  @override
  String get searchPlaceholderLong => 'Szukaj wyścigów, kolarzy, drużyn…';

  @override
  String get settings => 'Ustawienia';

  @override
  String get settingsAppearance => 'Wygląd';

  @override
  String get settingsTheme => 'Motyw';

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeSystem => 'Systemowy';

  @override
  String get settingsCardDensity => 'Gęstość kart';

  @override
  String get settingsDensityCompact => 'Zwarta';

  @override
  String get settingsDensityComfort => 'Standard';

  @override
  String get settingsDensityLarge => 'Duża';

  @override
  String get settingsReducedMotion => 'Mniej animacji';

  @override
  String get settingsReducedMotionDesc =>
      'Wyłącza subtelne animacje i efekt migotania.';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsLanguageSystem => 'Systemowy';

  @override
  String get settingsNotifications => 'Powiadomienia';

  @override
  String get settingsNotificationsTitle => 'Alerty informacyjne';

  @override
  String get settingsNotificationsDesc =>
      'Ciche powiadomienia z urządzenia, gdy pojawią się nowe artykuły z obserwowanych dyscyplin. Bez konta, bez wysyłania danych.';

  @override
  String get settingsNotificationsTopicsLabel => 'DYSCYPLINY';

  @override
  String get settingsNotificationsDeliveryLabel => 'DOSTARCZANIE';

  @override
  String get settingsNotificationsDeliveryInstant => 'Natychmiast';

  @override
  String get settingsNotificationsDeliveryDaily => 'Dzienne podsumowanie';

  @override
  String get settingsHiddenKeywordsLabel => 'UKRYJ SŁOWA';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Artykuły, których tytuł lub opis zawiera któreś z tych słów, są ukrywane w kanale i powiadomieniach.';

  @override
  String get settingsHiddenKeywordsHint => 'Dodaj słowo do ukrycia…';

  @override
  String get raceCardAddToCalendar => 'Dodaj do kalendarza';

  @override
  String get raceCardCalendarExportFailed =>
      'Nie udało się wyeksportować do kalendarza.';

  @override
  String get settingsYourData => 'Twoje dane';

  @override
  String get settingsExportBookmarks => 'Eksportuj zapisane';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count zapisanych · skopiowano jako JSON';
  }

  @override
  String get settingsRedoOnboarding => 'Powtórz wprowadzenie';

  @override
  String get settingsRedoOnboardingDesc =>
      'Wybierz regiony i dyscypliny od nowa.';

  @override
  String get settingsRedoOnboardingDialogTitle => 'Powtórzyć wprowadzenie?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'Przejdziemy ponownie przez wybór regionów, dyscyplin i gęstości kart. Twoje zapisane artykuły i obserwowane pozycje pozostaną.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get redo => 'Powtórz';

  @override
  String settingsBookmarksCopied(int count) {
    return 'Skopiowano $count zapisanych do schowka.';
  }

  @override
  String get settingsAbout => 'Informacje';

  @override
  String get settingsAboutApp => 'O Bike News Room';

  @override
  String get settingsPrivacy => 'Polityka prywatności';

  @override
  String get settingsTerms => 'Regulamin';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Skopiuj link';

  @override
  String get shareNative => 'Udostępnij';

  @override
  String get shareLinkCopied => 'Link skopiowany do schowka.';

  @override
  String get shareTwitter => 'Udostępnij na X';

  @override
  String get shareBluesky => 'Udostępnij na Bluesky';

  @override
  String get shareWhatsApp => 'Udostępnij przez WhatsApp';

  @override
  String get shareReddit => 'Udostępnij na Reddicie';

  @override
  String get shareTelegram => 'Udostępnij przez Telegram';

  @override
  String get alsoCoveredBy => 'INNI O TYM PISZĄ';

  @override
  String readOnSource(String source) {
    return 'Czytaj na $source';
  }

  @override
  String get summary => 'STRESZCZENIE';

  @override
  String get digestHeadline => 'Wiadomości kolarskie, codziennie o 7.';

  @override
  String get digestSubheadline =>
      'Jeden e-mail dziennie. Najważniejsze wiadomości z dnia. Bez reklam, bez spamu, anulujesz jednym kliknięciem.';

  @override
  String get digestEmailHint => 'ty@example.com';

  @override
  String get digestSubscribe => 'ZAPISZ SIĘ';

  @override
  String get digestInvalidEmail => 'To nie wygląda na adres e-mail.';

  @override
  String get digestNetworkError =>
      'Nie udało się połączyć z redakcją. Spróbuj za chwilę.';

  @override
  String get digestGenericError => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get digestSuccess =>
      'Sprawdź skrzynkę — potwierdź, aby zacząć otrzymywać podsumowania.';

  @override
  String get digestPrivacyPrefix => 'Zapisując się akceptujesz naszą ';

  @override
  String get digestPrivacyLink => 'politykę prywatności';

  @override
  String get digestPrivacySuffix => '. Możesz zrezygnować w każdej chwili.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'KROK $current / $total';
  }

  @override
  String get onboardingStepRegions => 'REGIONY';

  @override
  String get onboardingStepDisciplines => 'DYSCYPLINY';

  @override
  String get onboardingStepDensity => 'GĘSTOŚĆ';

  @override
  String get onboardingNext => 'Dalej';

  @override
  String get onboardingFinish => 'Pokaż mi wiadomości';

  @override
  String get onboardingSkip => 'Pomiń';

  @override
  String get onboardingBack => 'Wstecz';

  @override
  String get calendarFilterAll => 'WSZYSTKO';

  @override
  String get calendarEmpty => 'Brak nadchodzących wyścigów';

  @override
  String get calendarError => 'Nie udało się wczytać kalendarza';

  @override
  String get raceCardToday => 'DZIŚ';

  @override
  String get raceCardNow => 'TERAZ';

  @override
  String get raceCardTomorrow => 'JUTRO';

  @override
  String raceCardDays(int days) {
    return '$days D';
  }

  @override
  String get tooltipBookmark => 'Zapisz';

  @override
  String get tooltipClose => 'Zamknij';

  @override
  String get tooltipUnfollow => 'Przestań obserwować';

  @override
  String get shareLinkCopiedShort => 'Link skopiowany';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'Więcej…';

  @override
  String get follow => '+ OBSERWUJ';

  @override
  String followingName(String name) {
    return 'Obserwujesz: $name';
  }

  @override
  String get searchHint => 'Szukaj artykułów, kolarzy, wyścigów…';

  @override
  String get searchAddSourceTitle => 'Nie widzisz tego, czego szukasz?';

  @override
  String get searchAddSourceBody =>
      'Wklej dowolny kanał RSS lub stronę, by dodać ją jako źródło.';

  @override
  String get searchKeyToSearch => 'aby szukać';

  @override
  String get searchKeyToClose => 'aby zamknąć';

  @override
  String get breakingHeader => 'PILNE · OSTATNIA GODZINA';

  @override
  String get regionWorld => '🌍 Świat';

  @override
  String get regionEu => '🇪🇺 UE';

  @override
  String get regionPoland => '🇵🇱 Polska';

  @override
  String get regionSpain => '🇪🇸 Hiszpania';

  @override
  String get disciplineAll => 'Wszystkie';

  @override
  String get disciplineRoad => 'Szosa';

  @override
  String get disciplineMtb => 'MTB';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Tor';

  @override
  String get disciplineCx => 'Przełaj';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'OSTATNIA AKTUALIZACJA · $date';
  }

  @override
  String get aboutTitle => 'O aplikacji';

  @override
  String get aboutH1 => 'Co to jest';

  @override
  String get aboutB1 =>
      'Bike News Room to jeden kanał z wiadomościami kolarskimi z całego świata — szosa, MTB, gravel, tor i przełaj. Zbieramy je z publicznych kanałów RSS i stron wydawnictw kolarskich, federacji oraz niezależnych blogów, abyś nie musiał skakać między dwudziestoma kartami, żeby być na bieżąco.';

  @override
  String get aboutH2 => 'Jak to działa';

  @override
  String get aboutB2 =>
      'Co 30 minut nasz backend pobiera dane ze skonfigurowanych źródeł, usuwa duplikaty, klasyfikuje po regionie i dyscyplinie i wprowadza je do kanału, który czytasz. Każdy może dodać źródło przez formularz „Dodaj źródło”, a my automatycznie pokazujemy domeny często cytowane w artykułach do akceptacji.';

  @override
  String get aboutH3 => 'Bez paywalla, bez algorytmu';

  @override
  String get aboutB3 =>
      'Nie sortujemy po zaangażowaniu, nie śledzimy Cię między stronami i niczego nie sprzedajemy. Kolejność jest chronologiczna od najnowszych, z filtrami regionu i dyscypliny, które kontrolujesz Ty. Jeśli artykuł tu jest, to dlatego, że jakaś redakcja kolarska go opublikowała.';

  @override
  String get aboutH4 => 'Open source';

  @override
  String get aboutB4 =>
      'Cały kod źródłowy (backend w Rust + frontend Flutter Web) jest na GitHubie. Znalazłeś błąd, chcesz dodać nowe źródło albo zforkować projekt na inny sport? Pull requesty mile widziane.';

  @override
  String get privacyTitle => 'Polityka prywatności';

  @override
  String get privacyH1 => 'Co zbieramy';

  @override
  String get privacyB1 =>
      'Prawie nic. Frontend przechowuje Twoje preferencje (motyw, filtry, zapisane artykuły, ostatnio widziany artykuł) w pamięci lokalnej Twojej przeglądarki — nigdy nie opuszczają Twojego urządzenia. Jeśli zapiszesz się na codzienne podsumowanie, przechowujemy Twój adres e-mail oraz token potwierdzenia/rezygnacji w naszej bazie; to wszystko.';

  @override
  String get privacyH2 => 'Czego nie zbieramy';

  @override
  String get privacyB2 =>
      'Żadnych SDK do analityki, żadnych zewnętrznych trackerów, żadnych ciasteczek reklamowych, żadnego fingerprintingu, żadnego logowania adresów IP poza standardowymi logami serwera (rotowanymi co tydzień), żadnego profilu Twoich nawyków czytelniczych.';

  @override
  String get privacyH3 => 'E-mailowe podsumowanie';

  @override
  String get privacyB3 =>
      'Jeśli się zapiszesz, Twój e-mail jest używany wyłącznie do wysyłania codziennego podsumowania. Korzystamy z usługi Resend do dostarczania — widzą Twój adres podczas wysyłki, ale nie używają go do żadnego innego celu. Możesz się wypisać jednym kliknięciem z dowolnego e-maila; po wypisaniu adres pozostaje w bazie (oznaczony jako wypisany), aby nie mógł zostać ponownie zapisany przez osoby trzecie, dopóki ponownie tego nie potwierdzisz.';

  @override
  String get privacyH4 => 'Ciasteczka';

  @override
  String get privacyB4 =>
      'Nie ustawiamy ciasteczek. Pamięć lokalna przeglądarki jest używana wyłącznie dla Twoich preferencji — wyczyszczenie danych strony usuwa je.';

  @override
  String get privacyH5 => 'Twoje dane, Twój wybór';

  @override
  String get privacyB5 =>
      'Napisz na hello@bike-news-room, a usuniemy każdy zapis o subskrypcji, o który poprosisz. Niczego więcej do usunięcia nie ma, bo niczego więcej nie przechowujemy.';

  @override
  String get termsTitle => 'Regulamin';

  @override
  String get termsH1 => 'Korzystanie z usługi';

  @override
  String get termsB1 =>
      'Bike News Room to bezpłatny, publiczny agregator wiadomości. Możesz używać go do osobistego, niekomercyjnego czytania. Nie próbuj zbierać danych z API w dużym tempie — mamy limity per-IP i chętnie odpowiemy kodem 429. Jeśli potrzebujesz dostępu hurtowego, kod jest otwarty; uruchom własną instancję.';

  @override
  String get termsH2 => 'Treść artykułów';

  @override
  String get termsB2 =>
      'Nagłówki, fragmenty i linki wyświetlane w kanale pochodzą z publicznych kanałów RSS i stron wydawnictw kolarskich. Ruch z kliknięć trafia do oryginalnego wydawcy. Nie reprodukujemy pełnych artykułów — czytaj zawsze na stronie źródłowej, aby wesprzeć ludzi, którzy je tworzą.';

  @override
  String get termsH3 => 'Brak gwarancji';

  @override
  String get termsB3 =>
      'Usługa jest świadczona „tak jak jest”. Artykuły mogą zawierać nieścisłości (nie weryfikujemy faktów wydawnictw, które agregujemy). Nie używaj tego jako jedynego źródła decyzji w dniu wyścigu, negocjacji kontraktów ani niczego innego, gdzie błąd ma realny koszt.';

  @override
  String get termsH4 => 'Dodawanie źródeł';

  @override
  String get termsB4 =>
      'Każdy może zgłosić adres URL źródła. Robimy automatyczne kontrole bezpieczeństwa (URL guard, limity rozmiaru, sondowanie treści), ale zastrzegamy sobie prawo do usuwania źródeł, które okażą się spamem, nie na temat lub niskiej jakości.';

  @override
  String get termsH5 => 'Zmiany';

  @override
  String get termsB5 =>
      'Możemy okazjonalnie aktualizować ten regulamin. Istotne zmiany zostaną zaznaczone w codziennym podsumowaniu, zanim wejdą w życie.';

  @override
  String get onbRegionsTitle => 'Na czym ma się skupić wiadomościówka?';

  @override
  String get onbRegionsSub =>
      'Zawsze zobaczysz wyścigi światowe. Wybierz regiony, które dostaną dodatkową wagę.';

  @override
  String get onbDisciplinesTitle => 'Które rowery Cię wciągają?';

  @override
  String get onbDisciplinesSub =>
      'Zaznacz wszystkie pasujące — używamy tego do kolorowania i priorytetowania artykułów.';

  @override
  String get onbDensityTitle => 'Jak gęsty ma być kanał?';

  @override
  String get onbDensitySub =>
      'Możesz to zmienić w każdej chwili w ustawieniach.';

  @override
  String get onbCompactSub => 'Maksimum artykułów. Wiersze listy, bez zdjęć.';

  @override
  String get onbComfortSub => 'Zrównoważone. Zdjęcie + treść.';

  @override
  String get onbLargeSub => 'Karty redakcyjne z dużymi zdjęciami.';

  @override
  String get nameWorld => 'Świat';

  @override
  String get nameEu => 'UE';

  @override
  String get namePoland => 'Polska';

  @override
  String get nameSpain => 'Hiszpania';

  @override
  String get descWorld => 'Wszystko, wszędzie.';

  @override
  String get descEu => 'Europejskie wyścigi w centrum uwagi.';

  @override
  String get descPoland => 'Polskie wyścigi i kolarze.';

  @override
  String get descSpain => 'Hiszpańskie wyścigi i kolarze.';

  @override
  String get disciplineCxLong => 'Przełaj';

  @override
  String get descRoad => 'Klasyfikacja generalna, klasyki, sprinty.';

  @override
  String get descMtb => 'XC, DH, enduro, freeride.';

  @override
  String get descGravel => 'Długie wyścigi po szutrach.';

  @override
  String get descTrack => 'Wyścigi torowe.';

  @override
  String get descCx => 'Błoto, piasek, bariery.';

  @override
  String get descBmx => 'Wyścigi i freestyle.';
}
