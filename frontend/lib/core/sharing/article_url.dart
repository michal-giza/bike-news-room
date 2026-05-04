/// Builds the canonical share URL for an article.
///
/// We point at the **backend** /article/:id endpoint so crawlers (Twitter,
/// WhatsApp, Slack, etc.) hit our OpenGraph stub and get a rich preview
/// card. Real users hitting that URL get a 302 redirect to the SPA.
///
/// Configurable via `--dart-define=ARTICLE_URL_BASE=…` so staging and prod
/// can point at different backends without recompiling.
library;

const _defaultBase = String.fromEnvironment(
  'ARTICLE_URL_BASE',
  defaultValue: 'https://michal-giza-bike-news-room.hf.space/article',
);

String articleShareUrl(int articleId) => '$_defaultBase/$articleId';
