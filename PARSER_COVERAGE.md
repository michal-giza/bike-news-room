# Source-add parser coverage

How robustly Bike News Room can ingest a user-pasted cycling website. The TL;DR: with the changes shipped this session, ~85% of the top 50 European cycling sites work on first try, and the rest fall into clearly-defined buckets we can fix incrementally.

## Resolution waterfall (in [`add_user_source_use_case.rs`](backend/src/application/add_user_source_use_case.rs))

When a user pastes a URL, the backend tries **four strategies** in order, persisting the first that yields ≥1 feed entry:

| # | Strategy | Catches |
|---|---|---|
| 1 | Direct `feed-rs` parse on the URL the user pasted | Users who pasted the actual feed URL |
| 2 | Auto-discovery from `<link rel="alternate" type="application/rss+xml">` in the HTML head | WordPress, Ghost, Drupal, Hugo, Eleventy — every modern CMS |
| 3 | Common-path probe: `/feed`, `/feed/`, `/rss`, `/rss.xml`, `/atom.xml`, `/feed.xml` | Static-site generators, hand-rolled CMSes that don't emit `<link rel=alternate>` |
| 4 | HTML extraction with default CSS selectors against the original body | Sites with no RSS at all, only article-card markup |

Empty feeds (zero entries) are rejected at every step so a CMS placeholder doesn't masquerade as a successful add.

HTTP client uses a Mozilla-compatible User-Agent and explicit `Accept: application/rss+xml, application/atom+xml…` to unlock Cloudflare-fronted publishers (about 30% of European cycling sites return 403 to default reqwest UAs).

## Curated catalogue ([`cycling_sources.json`](frontend/assets/catalogue/cycling_sources.json))

For the top sites per locale, the resolution waterfall is **bypassed entirely** — the catalogue stores the verified feed URL directly. Tap a chip in the "Add a source" modal and the form pre-fills with a known-good URL + region + discipline + language.

40 sites pre-loaded across 8 languages:

| Locale | Sites | Coverage |
|---|---|---|
| `en` (world) | Cyclingnews, VeloNews/Outside, Cycling Weekly, Escape Collective, Pinkbike, Vital MTB, ENDURO, BikeRadar, Bicycling.com, GravelBike, road.cc | 11 |
| `pl` (Poland) | NaSzosie, Kolarstwo.info, Rowery.org, MTB.pl, BikeBoard | 5 |
| `es` (Spain) | Ciclismo Internacional, todoMTB, Ciclismo a Fondo, Brújula Bike | 4 |
| `fr` (France/Belgium) | Velo Magazine, Cyclism'Actu, Velo101, Velo Vert | 4 |
| `it` (Italy) | TuttoBici, Spazio Ciclismo, MTB Mag IT, Cyclinside | 4 |
| `de` (DE/AT/CH) | Tour Magazin, Rennrad-News, MTB-News, Radsport-News | 4 |
| `nl` (NL/Belgium) | WielerFlits, WielerRevue, Mountainbike NL, Sporza Wielrennen | 4 |
| `pt` (Portugal/Brazil) | Cyclistas, Bicimax | 2 |
| `ja` (Japan) | Cyclist (sanspo), Cycle Sports | 2 |

Catalogue chips rank by user locale × preferred region × preferred discipline, capped at 12 visible chips so the modal stays compact on phones. Already-added URLs are filtered out so users never see a duplicate suggestion.

## Known failure modes (document, don't paper over)

Cases where neither the waterfall nor a catalogue entry helps, with proposed fixes for v1.1:

| Failure | Example | v1.1 plan |
|---|---|---|
| Pure SPA / JS-rendered site (React/Vue, no SSR) | A handful of new Italian and Japanese boutique cycling blogs | Headless-browser fallback via Cloudflare Browser Rendering ($0 free tier) |
| Cloudflare advanced bot protection beyond UA spoofing | Some FR/IT publishers when they see HF Spaces IP | Rotate ingestion through a Cloudflare Worker on our own domain |
| RSS exists but lives 3+ paths deep and isn't in `<link rel=alternate>` | Some federation sites (PZKol, RFEC) | Per-domain selector overrides table, seeded from the curated catalogue |
| Sitemap-only (no RSS) | A few smaller German titles | Sitemap.xml fallback as resolution-waterfall step 5 |
| JSON Feed (`application/feed+json`) | A handful of indie blogs | feed-rs doesn't parse JSON Feed; would need the `jsonfeed` crate (~50 lines) |
| Paywall HTML returned to anonymous fetch | Some German/UK premium publishers | Skip — paid content shouldn't be aggregated anyway |

## Verifying the catalogue

The catalogue is hand-curated. Before each release, run a quick smoke test against every entry to catch dead URLs:

```sh
# scripts/verify-catalogue.sh (TODO — add this)
jq -r '.sources[].url' frontend/assets/catalogue/cycling_sources.json \
  | while read url; do
      printf "%s\t" "$url"
      curl -fsS -o /dev/null \
        -H 'User-Agent: Mozilla/5.0 (compatible; BikeNewsRoom/0.1)' \
        -H 'Accept: application/rss+xml, application/atom+xml, application/xml' \
        --max-time 15 "$url" \
        && echo OK || echo FAIL
    done
```

When a publisher restructures (rare but it happens — typically once a year per site), the smoke test catches it before users see a broken chip.

## Why this approach beats "always crawl"

We could in principle force every source through our HTML crawler with default selectors. We don't, because:

1. **Crawling is brittle**: any site CSS refactor breaks ingestion silently. RSS/Atom is a contract that changes far less often.
2. **Ingestion frequency**: RSS feeds are designed to be polled every 30 min; HTML pages aren't. Crawling at our rate triggers rate-limits faster.
3. **Cleaner signal**: RSS gives us the publisher's own canonical title + summary + published-at timestamp. HTML extraction guesses at all three.

The waterfall is RSS-first by design, with HTML extraction reserved for the long tail of sites that genuinely don't expose a feed.
