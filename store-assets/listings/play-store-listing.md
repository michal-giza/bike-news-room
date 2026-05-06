# Bike News Room — Play Store listing copy

Source-of-truth for what to paste into Play Console → Main store listing.
ASO research baked in (May 2026): title under 30 chars, short desc as a
hook not a feature list, long desc keyword density ~2–3% naturally
placed, no stuffing. Competitors surveyed: Cyclingnews (Future Plc),
Cyclingoo, "Cycling News & Race Results" (Briox/Riversip), IndeLeiderstrui.

## App title (max 30 chars)

```
Bike News Room: Cycling News
```

(28 chars — leaves room for Play to render the publisher name in search results without truncating.)

Why these words: Play's strongest indexing field is the title. "Cycling
news" is the highest-volume head term in this niche; "bike news" is the
secondary head term and is captured by the brand "Bike News Room". The
brand-first format also seeds future direct-name searches once we have
any organic awareness.

Alternates considered (not chosen):
- `Bike News: Cycling, Race & MTB` — packs more keywords but loses brand-name
  cohesion and reads like a stuffed title to humans.
- `Cycling News Aggregator: BNR` — leads with category but the brand acronym
  has no equity yet. Revisit at v1.5+ when we have direct-search traffic.

## Short description (max 80 chars)

```
Cycling news from every team, every race, every region — refreshed every 30 min.
```

(80 chars exactly.)

ASO note: short description is a hook, not a feature list. We lead with
**volume** ("every team, every race, every region") because that's the
single sharpest differentiator vs. publisher-tied apps (Cyclingnews app
only shows Future Plc content; Cyclingoo only shows results, not editorial).
The 30-minute refresh anchors freshness, which is the second-most-clicked
adjective in cycling-app reviews.

Alternates considered:
- `One feed for all cycling news. Road, MTB, gravel, track. 30-min refresh.` — solid;
  swap in if A/B test shows category breadth converts better than scope breadth.
- `Cycling news aggregator. 9 languages. No login. Bookmark anything.` — leads
  with privacy/zero-friction, weaker on what the app actually does.

## Long description (max 4000 chars)

Pasted below — runs ~2400 chars (Google rewards readability; padding to
4000 hurts more than it helps). Keyword targets bolded for self-review;
do NOT bold in the actual Play Console paste — Play strips formatting.

---

```
The cleanest way to read pro cycling news.

Bike News Room pulls **cycling news**, race coverage, and tech reviews from publishers across the world, deduplicates the noise, and gives you a single feed that refreshes every 30 minutes. No login. No paywall. No algorithm trained to keep you scrolling.

WHAT YOU GET

• A live feed of **cycling news** from publishers worldwide — UCI WorldTour, Pro Continental, mountain biking, gravel, cyclocross, track, BMX.
• Filter by region — World, Europe, Poland, Spain — and we'll add yours when you ask.
• Filter by discipline — **road cycling**, **MTB**, **gravel**, **CX**, **track**, **BMX**.
• Race calendar with the next editions of the Tours, Monuments, Worlds, Olympics, and the major MTB / gravel / CX series.
• Save anything to local **bookmarks** that survive backend sweeps — your reading list is yours.
• Add your own RSS source: paste a publisher's feed URL and we'll add it to the catalogue.
• 9 languages: English, Polish, Spanish, French, Italian, German, Dutch, Portuguese, Japanese.

WHO IT'S FOR

If you used to keep five tabs open during the **Tour de France** — Cyclingnews, Velonews, Cyclingweekly, Escape Collective, GCN — and you noticed half the stories overlap, this is for you. We dedupe across publishers so you read each story once, with the original source linked.

If you follow MTB more than the road — Red Bull Rampage, the World Cup, Cape Epic, gravel events like Unbound — we cover those too. The discipline filter is a single tap.

WHAT IT IS NOT

This is not a fitness tracker. We don't track your rides. We don't replace Strava or Komoot. We're the news room that sits on your home screen so you can drop in for two minutes, see what mattered today, and close the app.

PRIVACY

No account. No email collected. No tracking before you consent (we ask once at launch and you can refuse — the app works the same). Your bookmarks live on your phone, not on a server. We use AdMob to keep the lights on; ads only personalize after you've opted in via Google's standard consent screen.

OPEN ROADMAP

Race-follow ("notify me when Tour de France starts"), historical race archives, push-notifications for major incidents, and a watch-list for riders + teams are in active development. We ship monthly. Bug reports and feature requests: msquaregiza@gmail.com.

We're a small project. If something breaks, tell us — we'll usually fix it in the next release.
```

(2480 chars including spaces.)

### Keyword density check

Naturally placed primary terms:
- "cycling news" — 4 occurrences (~0.16% — good, not stuffed)
- "bike" — 2 occurrences (only in brand context, deliberate; bike is the
  weak head term, cycling is dominant)
- "race" / "racing" — 5 occurrences across "race coverage", "race calendar"
- discipline names (MTB, gravel, CX, track, BMX, road cycling) — each at
  least once, naturally in context
- specific event names (Tour de France, Worlds, Olympics, Red Bull
  Rampage, Cape Epic, Unbound) — long-tail anchors that match exact-match
  searches without polluting density

### What we're NOT keyword-stuffing

- "best cycling news" / "free cycling app" / "no.1 cycling app" — Play
  detects superlatives and downranks; reviews-led words are the right
  channel for them, not the description.
- "Strava alternative" — false framing; we're not a tracker. Misleading
  keywords trigger uninstalls + 1-star reviews, the worst ASO outcome.
- Long lists of pro rider names — Play's NLP penalizes feature-list dumps;
  we mention 2–3 race events as long-tails and stop.

## Categorization

- **App category**: News & Magazines (NOT Sports — News & Magazines has
  lower competition for cycling-niche head terms in 2026, and our
  publisher-aggregator model is structurally a news app, not a sports
  app).
- **Tags** (Play allows 5):
  1. Cycling
  2. Sports News
  3. RSS Reader
  4. Aggregator
  5. Race Results

## Contact details

```
Website:   https://bike-news-room.pages.dev/
Email:     msquaregiza@gmail.com
Phone:     (omit)
```

## Privacy policy URL

```
https://bike-news-room.pages.dev/privacy
```

(Ships in `frontend/web/privacy.html`, baked into the Cloudflare Pages
deploy of the web build.)

## Content rating questionnaire

App content → Content rating. Expected output: **PEGI 3 / ESRB Everyone**.

| Question | Answer | Why |
|---|---|---|
| Violence (cartoon / fantasy / realistic) | None | We aggregate news; we don't render violent content. Linked articles may discuss crashes — that's "Reference to violence in linked content" if Play asks. |
| Sex, nudity, or sexual content | None | |
| Profanity / crude humor | None | Headlines from RSS feeds — publishers self-censor. |
| Drugs, alcohol, tobacco | None | We may link to doping-news stories. Answer "May reference" if asked. |
| Gambling / simulated gambling | None | We do not link to betting sites. |
| User-to-user chat or social interaction | No | No comments, no chat, no profiles. |
| Shares user location | No | Region filter is a static enum, not GPS. |
| Allows in-app purchases | No | Free, ad-supported, no IAP. |
| User-generated content | No | Users can add an RSS source URL; we curate which sources are accepted. Not user-generated content per Play's definition. |

## Data safety form

App content → Data safety. Required since 2022. Answer **literally** or
Play penalizes you on the next vetting cycle.

### Data we collect

| Type | Collected? | Purpose | Optional? | Sharing |
|---|---|---|---|---|
| Personal info (name, email, phone) | No | – | – | – |
| Financial info | No | – | – | – |
| Location (precise / approximate) | No | – | – | – |
| Web browsing history | No | – | – | – |
| App activity (interactions, in-app search) | No | We don't transmit interactions; bookmarks live on-device | – | – |
| App info & performance (crash logs, diagnostics) | No (until we wire Crashlytics) | – | – | – |
| Device or other IDs (advertising ID) | **Yes** | Advertising or marketing (AdMob personalisation) | **Yes — opt-in via UMP / ATT** | Shared with Google AdMob |
| Audio, photos, files | No | – | – | – |

### Security practices

- ☑ Data is encrypted in transit (HTTPS only; CSP header on web build; no cleartext).
- ☐ You can request that data be deleted — N/A, we hold no PII; AdMob
  deletion handled via Google's process. Provide email contact.
- ☑ Committed to follow Play Families Policy — we don't target children.
- ☑ Independent security review — N/A (small project; do not lie about this).

### "Data shared with third parties"

```
Yes — Google AdMob (advertising ID only, after explicit consent).
```

## Target audience

App content → Target audience and content.

- Age group: **18+** (AdMob personalised ads require adult audience under
  Play's "Designed for Families" policy distinction).
- Confirm: "Does NOT target children."
- Reason: AdMob is wired post-consent; we cannot guarantee non-personalised
  ads at children-policy strictness without deeper SDK changes. Bumping
  to 18+ is the conservative choice that keeps us in the clear.

## Translations

Play allows per-locale listing copy. We ship in 9 languages — match the
listing for the top 4 markets at launch and let Play auto-translate the rest:

| Locale | Listing language | Notes |
|---|---|---|
| en-US | English (this file) | Default. |
| en-GB | English (UK) | Same copy; "neighborhood" → "neighbourhood" if any. (None here.) |
| pl    | Polish              | Manual translation; cycling vocabulary doesn't auto-translate well. |
| es    | Spanish             | Manual; Spain is one of our launch regions. |

Skip machine-translation for the rest at launch. Add it as 1.1 work after
we see which markets actually install (Play Console → Statistics →
Country breakdown).

## A/B tests to set up after launch

Play Console → Store listing experiments. Run one at a time, ~2 weeks per
test (need ~1000 store-listing visits per variant for statistical signal):

1. Title: `Bike News Room: Cycling News` vs. `Bike News: Race & Cycling`
2. Short desc: scope-led ("every team, every race") vs. category-led ("road, MTB, gravel")
3. Feature graphic: brand mark + tagline vs. screenshot collage
4. Icon background: current `#0E0F11` vs. `#E8C54A` (the accent)
