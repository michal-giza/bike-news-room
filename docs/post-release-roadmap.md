# Bike News Room — post-release roadmap

What to expect from the first 90 days, what to measure, and the
prioritised next-step backlog. Numbers below come from May 2026
benchmarks for News & Magazines apps on Google Play (Sensor Tower,
yellowHEAD, AppTunix, UXCam — see the sources at the bottom of the
listing doc).

---

## Stage 1 — Internal testing track (week 0 → week 1)

Before promoting to production. Unfiltered, fast iteration.

### Goal

Catch the bugs that the integration suite + live-backend smoke could
not reach. Things humans notice that automated tests don't:

- Splash → first frame transition feels slow / janky.
- A specific RSS feed's article images load broken (publisher CDN
  changed).
- The UMP consent flow gets stuck on a particular Android version.
- A Polish user finds a translation that's literal-but-wrong.

### How to get testers

Play Console → Testing → Internal testing → Testers tab. Add up to
100 emails. Easiest pool:

- 5–10 close cycling friends — fastest, highest signal.
- The r/cycling subreddit "looking for beta testers" thread (post
  once a week max — they hate spam).
- Your local cycling club's Discord / WhatsApp.
- Twitter / Bluesky #cycling tag with a clear ask (NOT a public
  download link — paste the Play Console internal link only in DM).

### What to measure (first week)

| Metric | Where it lives | Bad-news threshold |
|---|---|---|
| Crash-free user rate | Play Console → Quality → Crashes & ANRs | < 99.0% |
| ANR rate | Same | > 0.47% (Play's "bad behaviour" threshold) |
| Pre-launch report findings | Quality → Pre-launch report | Any P0 / P1 |
| Internal feedback tickets | Email + GitHub Issues | Anything affecting > 10% of testers |

### Exit criteria for Stage 2

- ≥ 7 days clean, no P0 / P1 bugs open.
- Pre-launch report "stability" tab green on all 5 robo-test devices.
- ≥ 5 testers report "I've used it daily for 2+ days and still works".

---

## Stage 2 — Closed testing → open testing (week 1 → week 4)

Goal: validate the listing converts, then loosen the gate.

### What to expect on install volume

The listing is brand-new with zero reviews and zero brand search
volume. Without paid promotion the first month, baseline expectation
is **~10–80 organic installs total** across weeks 2-4. Anything more
is upside. This is the median for a new News & Magazines app with
solid ASO but no marketing spend (Sensor Tower 2026 benchmarks).

The single biggest lever in this stage is **store listing
conversion** — the % of people who land on your store page and tap
Install. Industry median for News is **22-28%**; below 18% means the
listing is failing. The variables that move it:

- App icon contrast at 48px size.
- First two screenshots (most users never scroll past).
- Star rating (you don't have one yet — every install you get
  matters).
- Short description (the single line above the install button).

### Action: A/B test the listing

Play Console → Store listing experiments. Run **one test at a time**,
2-week minimum per variant. You need ~1000 visits per variant for
statistical power, which means experiments only become useful AFTER
you have organic traffic. In week 2-4 most of your traffic will be
direct from internal-test invites; experiments arm but won't conclude.

Pre-stage the experiments now, set them live in Stage 3:

1. **Title**: `Bike News Room: Cycling News` vs. `Bike News: Race & Cycling`
2. **Short desc**: scope-led ("every team, every race") vs.
   category-led ("road, MTB, gravel")
3. **Feature graphic**: brand-mark + tagline (current) vs.
   screenshot collage of the feed
4. **Icon**: current `#0E0F11` background vs. `#E8C54A` (accent)

Document each result in `docs/aso-experiments.md` (create per-test
when you run them).

### What to measure (weeks 2-4)

| Metric | Target | Where |
|---|---|---|
| Store-listing visit → install conversion | 22–28% (median) | Play Console → Acquisition |
| Day-1 retention | 25–30% | Statistics → Retention |
| Day-7 retention | 10–15% | Same |
| Crash-free user rate | ≥ 99.5% | Quality |
| Avg session length | 1.5–4 minutes | Engagement |
| Sessions per active user / week | ≥ 3 | Same |
| 1-star reviews | 0 | Reviews tab |

### Exit criteria for production

- 7 consecutive days at ≥ 99.5% crash-free.
- ≥ 100 unique installers across internal+closed testing.
- No 1-star reviews or all 1-stars resolved (replied + reproduced + fixed).

---

## Stage 3 — Production launch (week 4)

### What to expect

A new app on Play Production WITHOUT a paid launch campaign typically
sees:

- **Day 1**: 5–30 organic installs (Play seeds your listing in
  category-relevant searches; ranking starts low).
- **Week 1**: 30–150 cumulative installs.
- **Day 30**: 150–600 cumulative installs.
- **Day 90**: 500–2000 cumulative installs IF retention is decent and
  the niche (cycling news) keeps trending.

Retention will look brutal:

- 71% of installers churn (stop opening) within the first 90 days —
  this is the new-app norm, not a sign of failure.
- Day 1 retention 25-30% means 70-75% of installers don't return on
  day 2. Expected.
- Day 30 retention on Android averages ~2%. We aim for ~5% because
  cycling-news is a returning-interest niche (every race weekend
  re-activates).

Don't conflate "low DAU" with "failed product" until you're past
day 60 with both retention AND conversion below median.

### What to measure (weeks 4-12)

The four numbers that matter, in priority order:

1. **Crash-free users %** — must stay ≥ 99.5%. Anything below 99.0%
   is a blocker; fix immediately.
2. **Day-7 retention** — leading indicator of whether the app is
   sticky. Trend is more informative than absolute number; aim for
   "going up over consecutive cohorts".
3. **Store-listing conversion %** — if this drops below 18% after
   you have ≥ 5 reviews, the listing is failing; rotate
   screenshots / short desc.
4. **Time-on-app per session** — under 60s means people open
   accidentally; over 5 minutes means they're engaged. Cycling-news
   sweet spot is 90s-3min.

### Reviews ops

Reply to **every** review within 48h, including 5-star ones. Play's
algorithm reads reply latency as a signal — devs who reply fast get
ranking boosts in their category. Template responses for the four
common patterns:

- **5★ no comment** → "Thanks for the install + rating. Anything you'd want us to add? msquaregiza@gmail.com."
- **4★ minor gripe** → name the gripe, say when it's fixed in the next release.
- **3★ confused** → ask for the screen + Android version, offer to debug via email.
- **1★ broken** → never argue. Acknowledge, ask for crash details, fix it, reply when shipped. If it's an unreasonable review, flag it via Play (rarely succeeds).

---

## Prioritised feature backlog (post-launch)

Order is highest-impact-on-retention first, NOT
easiest-to-implement.

### v1.1 — Push notifications (highest retention impact)

Push is the single highest-leverage feature we can ship for a news
app. Industry benchmark: enabling well-targeted push lifts Day-30
retention by 30-90% on news apps (yellowHEAD 2026).

What to ship:
- "Race is live" notifications for races the user follows.
- "Major incident" notifications (crash, win, transfer) inferred from
  the existing live-ticker tags.
- Per-discipline opt-in (someone who only follows MTB doesn't want
  TdF notifications).
- Hard cap: ≤ 2 per day. Cycling-news is bursty; 2 is enough to keep
  the app top-of-mind without becoming spam.

Implementation surface: Firebase Cloud Messaging. Already-loaded
Firebase pattern from the four-layer ATT/UMP skill applies.

**Estimated effort**: 1 week. **Expected D30 retention lift**:
+ 40-60% absolute on the FCM-opt-in cohort.

### v1.2 — Race-follow with archive (the big one)

Already designed in [`/.claude/plans/i-want-you-to-noble-flurry.md`](../.claude/plans/i-want-you-to-noble-flurry.md). Three PRs:

- PR 1 (frontend): race kind in WatchedKind + alias fan-out + race seed + bookmark snapshot store. ~5h.
- PR 2 (full-stack): race_articles table + retention exemption + matcher + past-race API + Following race tab. ~8h.
- PR 3 (backend): Internet Archive backfill for top 15 races × 3 years. ~10h.

**Expected impact**: turns the app from "news of today" into "the
place I check during the Tour". Race-follow users are the cohort
that converts to D30 retention > 20%.

### v1.3 — Riders-and-teams watchlist UX overhaul

The watchlist exists in code but the UI for adding a rider /
filtering by them is buried. After race-follow ships, riders are the
next-most-asked feature. Surface candidates we should pre-seed in
the watchlist catalogue (already done) and make discoverable.

### v1.4 — Cross-device sync

Anonymous device id + `/api/bookmarks` endpoint. Nice-to-have, not a
churn fix. Schedule once we have ≥ 1000 DAU and bookmark-volume tells
us cross-device is actually a missed need.

### v1.5 — Web-app push (PWA) + offline reading

Cycling fans read on commutes; offline reading would lift session
length on the web build. Service-worker work; not a Play release
concern.

---

## Marketing experiments worth running (cheap, high learning)

In priority order:

1. **r/cycling AMA** when v1.1 push lands. Free, single highest
   organic-install spike for a cycling app. Title: "I built a free
   ad-supported cycling news aggregator with Polish + Spanish
   coverage; AMA". Be honest about the AdMob, share the install
   link.
2. **Cyclingnews / Bikeradar / Cycling Weekly forum threads**.
   Old-school, but cyclists who read forums also install apps. One
   thread per major site; respond to questions for ~48h.
3. **Bluesky + Mastodon over Twitter/X**. Cycling Twitter migrated
   in 2024-25; the bike-Bluesky community is small but engaged.
4. **Strava clubs**. Some Strava clubs have 50k+ members and pinned
   posts get serious eyeballs. Find 3 cycling-news-themed clubs and
   ask the moderators if a one-line "we built this app, free, no
   login" mention is OK.
5. **Skip Reddit ads, paid Play search, Apple Search Ads**. Returns
   too low at our DAU level. Re-evaluate at 5k DAU.

Total marketing spend through Stage 4: **$0**. The math doesn't work
on paid acquisition until we know our LTV (probably ~$0.30–$1.50 for
an ad-supported news app), and we won't know that until we see at
least 90 days of AdMob revenue.

---

## When to pull the plug

Honest stop-loss criteria. If by **day 90** ALL of the following are
true, the product is not finding its market and we should consider
pivoting:

- < 100 installs cumulative.
- Day-7 retention < 8%.
- < 3 unsolicited 5-star reviews.
- Average session < 60 seconds.

What "pivot" means: not necessarily kill the project, but stop
shipping new features and instead investigate why retention is so
low. Likely culprits at that signal level: content depth (10 Polish
articles isn't enough; backfill more sources), user acquisition (we
need a marketing push not a feature push), or the niche itself
(cycling-news is just smaller than we modeled — fold it into a
broader "all sports news" aggregator).

If the day-90 numbers are above the floor (≥ 200 installs, ≥ 10% D7
retention, ≥ 5 reviews ≥ 4 stars average), keep shipping the v1.x
roadmap.

---

## Revenue expectations

AdMob banner + interstitial revenue for a News & Magazines app on
Android, US/EU traffic, no premium tier:

- **eCPM**: $0.40–$2.50 (median ~$1.20).
- **Sessions per active user per month**: 12–25 if D30 retention
  hits 5%.
- **Ad impressions per session**: 2-4 (banner refreshes + 1
  interstitial on every 4th cold launch).
- **Per-MAU revenue**: $0.10–$0.40.

Translate: at **1000 MAU** expect **$100–$400/month** gross AdMob
revenue. Net (after Google's 32% cut) ≈ $68-$272.

Not a business at that scale. Becomes a business at 50k MAU
(~$5k/month net). We are at least 18 months away from that on
organic alone.

---

## Sources

- [yellowHEAD — App Retention Rate Benchmarks for Google Play (2026)](https://www.yellowhead.com/blog/app-retention-rates-benchmarks/)
- [UXCam — Mobile App Retention Benchmarks by Industry (2026)](https://uxcam.com/blog/mobile-app-retention-benchmarks/)
- [Sensor Tower — App Performance Insights](https://sensortower.com/product/mobile-app/app-performance-insights)
- [BusinessOfApps — App Retention Rates 2026](https://www.businessofapps.com/data/app-retention-rates/)
- [AppTweak — Google Play Store optimization guide](https://www.apptweak.com/en/aso-blog/aso-for-google-play-app-store-optimization-guide-for-android)
- [ASOWorld — Google Play Keyword Research Checklist 2026](https://asoworld.com/insight/aso-checklist-the-complete-guide-to-google-play-store-keyword-research-in-2025/)
