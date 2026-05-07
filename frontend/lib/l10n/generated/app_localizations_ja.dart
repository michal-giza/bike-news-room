// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => '今日のニュース';

  @override
  String get updatedJustNow => 'たった今更新';

  @override
  String updatedMinutesAgo(int minutes) {
    return '$minutes 分前に更新';
  }

  @override
  String updatedHoursAgo(int hours) {
    return '$hours 時間前に更新';
  }

  @override
  String updatedDaysAgo(int days) {
    return '$days 日前に更新';
  }

  @override
  String storiesCount(int count) {
    return '$count 件の記事';
  }

  @override
  String newSinceLastVisit(int count) {
    return '前回から $count 件の新着';
  }

  @override
  String get scrollForMore => 'スクロールしてさらに表示';

  @override
  String get endOfFeed => '— フィードの最後 —';

  @override
  String get live => 'ライブ';

  @override
  String get couldNotReachNewsRoom => 'ニュースルームに接続できません';

  @override
  String get retry => '再試行';

  @override
  String get noArticlesMatch => '条件に合う記事はありません';

  @override
  String get tryBroadeningFilters => 'フィルターを広げるかクリアしてください。';

  @override
  String couldntLoadMore(String error) {
    return 'さらに読み込めませんでした: $error';
  }

  @override
  String get tabFeed => 'フィード';

  @override
  String get tabSearch => '検索';

  @override
  String get tabBookmarks => 'ブックマーク';

  @override
  String get tabCalendar => 'カレンダー';

  @override
  String get tabFollowing => 'フォロー中';

  @override
  String get search => '検索';

  @override
  String get searchPlaceholderShort => '検索…';

  @override
  String get searchPlaceholderLong => 'レース・選手・チームを検索…';

  @override
  String get settings => '設定';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsCardDensity => 'カードの密度';

  @override
  String get settingsDensityCompact => 'コンパクト';

  @override
  String get settingsDensityComfort => '標準';

  @override
  String get settingsDensityLarge => '大';

  @override
  String get settingsReducedMotion => '動きを減らす';

  @override
  String get settingsReducedMotionDesc => '細かなアニメーションやシマー効果を省略します。';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSystem => 'システム';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsNotificationsTitle => 'ニュースアラート';

  @override
  String get settingsNotificationsDesc =>
      'フォロー中のディシプリンに新着記事が入ると、端末内で静かにお知らせします。アカウント不要、データ送信なし。';

  @override
  String get settingsNotificationsTopicsLabel => 'ディシプリン';

  @override
  String get settingsNotificationsDeliveryLabel => '配信';

  @override
  String get settingsNotificationsDeliveryInstant => '即時';

  @override
  String get settingsNotificationsDeliveryDaily => '1日のまとめ';

  @override
  String get settingsHiddenKeywordsLabel => '非表示キーワード';

  @override
  String get settingsHiddenKeywordsDesc =>
      'タイトルまたは説明にこれらの語のいずれかを含む記事は、フィードと通知から非表示になります。';

  @override
  String get settingsHiddenKeywordsHint => '非表示にする語を追加…';

  @override
  String get trendingHeader => 'トレンド';

  @override
  String get readerModeRead => 'アプリで読む';

  @override
  String get readerModeHide => 'リーダーを隠す';

  @override
  String get readerModeUnavailable => 'この記事はリーダーモードに対応していません（出版社の設定）。';

  @override
  String get readerModeError => '記事を読み込めませんでした。';

  @override
  String get wikiSourceLink => 'Wikipedia でもっと読む';

  @override
  String get raceCardAddToCalendar => 'カレンダーに追加';

  @override
  String get raceCardCalendarExportFailed => 'カレンダーへのエクスポートに失敗しました。';

  @override
  String get settingsYourData => 'あなたのデータ';

  @override
  String get settingsExportBookmarks => 'ブックマークをエクスポート';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count 件保存 · JSON としてコピー済み';
  }

  @override
  String get settingsRedoOnboarding => 'オンボーディングをやり直す';

  @override
  String get settingsRedoOnboardingDesc => '地域と種目を選び直します。';

  @override
  String get settingsRedoOnboardingDialogTitle => 'オンボーディングをやり直しますか？';

  @override
  String get settingsRedoOnboardingDialogBody =>
      '地域・種目・カードの密度を選び直します。ブックマークとフォロー一覧はそのまま残ります。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get redo => 'やり直す';

  @override
  String settingsBookmarksCopied(int count) {
    return '$count 件のブックマークをクリップボードにコピーしました。';
  }

  @override
  String get settingsAbout => '情報';

  @override
  String get settingsAboutApp => 'Bike News Room について';

  @override
  String get settingsPrivacy => 'プライバシーポリシー';

  @override
  String get settingsTerms => '利用規約';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'リンクをコピー';

  @override
  String get shareNative => '共有';

  @override
  String get shareLinkCopied => 'リンクをクリップボードにコピーしました。';

  @override
  String get shareTwitter => 'X で共有';

  @override
  String get shareBluesky => 'Bluesky で共有';

  @override
  String get shareWhatsApp => 'WhatsApp で共有';

  @override
  String get shareReddit => 'Reddit で共有';

  @override
  String get shareTelegram => 'Telegram で共有';

  @override
  String get alsoCoveredBy => '他にも報じています';

  @override
  String readOnSource(String source) {
    return '$source で読む';
  }

  @override
  String get summary => 'まとめ';

  @override
  String get digestHeadline => '毎朝7時に届く自転車ニュース。';

  @override
  String get digestSubheadline =>
      '1日1通のメール。今日のもっとも重要な記事だけ。広告なし、スパムなし、ワンクリックで配信停止。';

  @override
  String get digestEmailHint => 'you@example.com';

  @override
  String get digestSubscribe => '登録する';

  @override
  String get digestInvalidEmail => 'メールアドレスのようには見えません。';

  @override
  String get digestNetworkError => 'ニュースルームに接続できません。少し待ってから再試行してください。';

  @override
  String get digestGenericError => '問題が発生しました。再試行してください。';

  @override
  String get digestSuccess => '受信トレイをご確認ください — 確認するとダイジェストの配信が始まります。';

  @override
  String get digestPrivacyPrefix => '登録すると ';

  @override
  String get digestPrivacyLink => 'プライバシーポリシー';

  @override
  String get digestPrivacySuffix => ' に同意したものとみなされます。いつでも配信停止できます。';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'ステップ $current / $total';
  }

  @override
  String get onboardingStepRegions => '地域';

  @override
  String get onboardingStepDisciplines => '種目';

  @override
  String get onboardingStepDensity => '密度';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingFinish => 'フィードを表示';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingBack => '戻る';

  @override
  String get calendarFilterAll => 'すべて';

  @override
  String get calendarEmpty => '予定されているレースはまだありません';

  @override
  String get calendarError => 'カレンダーを読み込めませんでした';

  @override
  String get raceCardToday => '本日';

  @override
  String get raceCardNow => '進行中';

  @override
  String get raceCardTomorrow => '明日';

  @override
  String raceCardDays(int days) {
    return 'あと$days日';
  }

  @override
  String get tooltipBookmark => 'ブックマーク';

  @override
  String get tooltipClose => '閉じる';

  @override
  String get tooltipUnfollow => 'フォロー解除';

  @override
  String get shareLinkCopiedShort => 'リンクをコピーしました';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'その他…';

  @override
  String get follow => '+ フォロー';

  @override
  String followingName(String name) {
    return '$name をフォロー中';
  }

  @override
  String get searchHint => '記事・選手・レースを検索…';

  @override
  String get searchAddSourceTitle => 'お探しのものが見つかりませんか？';

  @override
  String get searchAddSourceBody => 'RSSフィードまたはウェブサイトを貼り付けてソースとして追加できます。';

  @override
  String get searchKeyToSearch => 'で検索';

  @override
  String get searchKeyToClose => 'で閉じる';

  @override
  String get breakingHeader => '速報 · 直近1時間';

  @override
  String get regionWorld => '🌍 世界';

  @override
  String get regionEu => '🇪🇺 EU';

  @override
  String get regionPoland => '🇵🇱 ポーランド';

  @override
  String get regionSpain => '🇪🇸 スペイン';

  @override
  String get disciplineAll => 'すべて';

  @override
  String get disciplineRoad => 'ロード';

  @override
  String get disciplineMtb => 'MTB';

  @override
  String get disciplineGravel => 'グラベル';

  @override
  String get disciplineTrack => 'トラック';

  @override
  String get disciplineCx => 'シクロクロス';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return '最終更新 · $date';
  }

  @override
  String get aboutTitle => '概要';

  @override
  String get aboutH1 => 'Bike News Room とは';

  @override
  String get aboutB1 =>
      'Bike News Room は世界中の自転車ニュース（ロード、MTB、グラベル、トラック、シクロクロス）を一つのフィードにまとめるサービスです。自転車関連メディア・連盟・個人ブログの公開RSSやサイトから集約するため、最新情報を追うために20個ものタブを行き来する必要がなくなります。';

  @override
  String get aboutH2 => '仕組み';

  @override
  String get aboutB2 =>
      '30分ごとにバックエンドが設定済みのソースを取得し、ほぼ同一の記事を重複排除し、地域・種目で分類して、お読みのフィードに反映します。誰でも「ソースを追加」フォームから提供でき、記事内で頻繁に引用されるドメインも自動的に審査用に上げます。';

  @override
  String get aboutH3 => 'ペイウォールなし、アルゴリズムの操作なし';

  @override
  String get aboutB3 =>
      'エンゲージメントで並べ替えることも、サイト間で追跡することも、何かを売ることもしません。並びは時系列の逆順で、地域と種目のフィルターはあなたが操作します。ここに記事があるのは、自転車メディアが実際に公開したからです。';

  @override
  String get aboutH4 => '独立プロジェクト';

  @override
  String get aboutB4 =>
      'Bike News Room は独立して開発されています。出版社との提携や編集上の取り決めはなく、すべての記事は公開 RSS フィードから透明性のある方法で集約されています。';

  @override
  String get privacyTitle => 'プライバシーポリシー';

  @override
  String get privacyH1 => '収集する情報';

  @override
  String get privacyB1 =>
      'ほぼ何も収集しません。フロントエンドは設定（テーマ、フィルター、ブックマーク、最後に見た記事）をブラウザのローカルストレージに保存し、デバイスから出ません。デイリーダイジェストに登録された場合のみ、メールアドレスと確認・配信停止トークンをデータベースに保存します。それだけです。';

  @override
  String get privacyH2 => '収集しない情報';

  @override
  String get privacyB2 =>
      'アナリティクスSDK、サードパーティトラッカー、広告クッキー、フィンガープリンティング、標準サーバアクセスログ（毎週ローテーション）以上のIPロギング、読者の習慣プロファイルは一切ありません。';

  @override
  String get privacyH3 => 'メールダイジェスト';

  @override
  String get privacyB3 =>
      '登録された場合、メールアドレスはデイリーダイジェスト送信のみに使用されます。配信には Resend を利用し、配信時にアドレスを参照しますが他の用途には使いません。ダイジェストメールのワンクリックでいつでも配信停止でき、解除後はアドレスを「解除済み」として残し、第三者が再登録できないようにします（再登録には本人の再確認が必要です）。';

  @override
  String get privacyH4 => 'クッキー';

  @override
  String get privacyB4 =>
      'クッキーは設定しません。ブラウザのローカルストレージはアプリ内設定のために使われ、サイトデータをクリアすると削除されます。';

  @override
  String get privacyH5 => 'あなたのデータ、あなたの選択';

  @override
  String get privacyB5 =>
      'hello@bike-news-room までメールでご連絡いただければ、購読記録の削除を承ります。それ以外に保存しているデータがないため、削除すべきものは他にありません。';

  @override
  String get termsTitle => '利用規約';

  @override
  String get termsH1 => 'サービスの利用';

  @override
  String get termsB1 =>
      'Bike News Room は個人利用向けの無料ニュースアグリゲーターです。API を大量にスクレイピングしようとしないでください — IP ごとのレート制限があり、429 を返します。API の大量利用または商用利用には書面による許可が必要です。';

  @override
  String get termsH2 => '記事のコンテンツ';

  @override
  String get termsB2 =>
      'フィードに表示される見出し・抜粋・リンクは、自転車メディアの公開RSSやページから取得したものです。クリックトラフィックは元の発行元へ送られます。記事全文は再現せず、必ず元のサイトでお読みいただき、報じている方々を支援してください。';

  @override
  String get termsH3 => '保証なし';

  @override
  String get termsB3 =>
      'サービスは現状有姿で提供されます。記事には不正確な情報が含まれる場合があります（集約しているメディアの事実確認は行っていません）。レース当日の判断、契約交渉、その他誤りに実費が伴うような事項の唯一のソースとしては使用しないでください。';

  @override
  String get termsH4 => 'ソースの追加';

  @override
  String get termsB4 =>
      '誰でもソースURLを送信できます。自動の安全チェック（URLガード、ペイロード上限、コンテンツ検査）を実施しますが、スパム・無関係・低品質と判明したソースを除外する権利を留保します。';

  @override
  String get termsH5 => '変更';

  @override
  String get termsB5 => '本規約は時々更新する可能性があります。重要な変更は施行前にデイリーダイジェストでお知らせします。';

  @override
  String get onbRegionsTitle => 'ニュースの軸はどこに置きますか？';

  @override
  String get onbRegionsSub => '世界のレースは常に表示されます。重みを増す地域を選んでください。';

  @override
  String get onbDisciplinesTitle => '気になるバイクは？';

  @override
  String get onbDisciplinesSub => '当てはまるものを全て選んでください — カラータグと優先度に使います。';

  @override
  String get onbDensityTitle => 'フィードの密度はどうしますか？';

  @override
  String get onbDensitySub => 'フィードからいつでも変更できます。';

  @override
  String get onbCompactSub => '記事数最大。リスト形式、画像なし。';

  @override
  String get onbComfortSub => 'バランス。画像 + 本文。';

  @override
  String get onbLargeSub => '編集部ヒーローカード。';

  @override
  String get nameWorld => '世界';

  @override
  String get nameEu => 'EU';

  @override
  String get namePoland => 'ポーランド';

  @override
  String get nameSpain => 'スペイン';

  @override
  String get descWorld => 'すべて、どこでも。';

  @override
  String get descEu => 'ヨーロッパのレースに注目。';

  @override
  String get descPoland => 'ポーランドのレースと選手。';

  @override
  String get descSpain => 'スペインのレースと選手。';

  @override
  String get disciplineCxLong => 'シクロクロス';

  @override
  String get descRoad => '総合、クラシック、スプリント。';

  @override
  String get descMtb => 'XC、DH、エンデューロ、フリーライド。';

  @override
  String get descGravel => 'アスファルト外の長距離。';

  @override
  String get descTrack => 'ベロドローム競技。';

  @override
  String get descCx => '泥・砂・障害物。';

  @override
  String get descBmx => 'レースとフリースタイル。';
}
