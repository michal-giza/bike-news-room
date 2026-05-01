# Claude Designer Prompt — Bike News Room

> Paste everything below into Claude Designer to kick off mockups.

---

## Project: Bike News Room — Cycling News Aggregator (Web)

I'm building a **cycling news aggregation platform** — a "news room" for bike racing fans, similar in spirit to live war-room news feeds but focused on cycling. It ingests articles from RSS feeds and crawls websites across all cycling disciplines (road, MTB, gravel, track, cyclocross, BMX) and aggregates them into one fast, scannable interface.

**Coverage starts with:** Poland, Spain, World — expanding to full EU.
**Tech:** Flutter Web frontend, Rust backend, SQLite. Will be deployed to Cloudflare Pages.

---

## Audience

Two distinct rider personas — design must work beautifully for both:

1. **Young riders (16–30)** — MTB, gravel, BMX, e-bikes. Fast scrolling, dark mode, energy, video content, social-feel, Instagram/TikTok-influenced UI patterns.
2. **Older / lifelong fans (40–70)** — Road racing fans, follow Tour de France / Giro / Vuelta, results-focused, want clean readable typography, quick access to standings and race calendars.

**Bridge the gap:** Modern but not gimmicky. Fast but not overwhelming. Clean editorial typography with subtle motion.

---

## Core Flow

```
[Landing/Feed] → [Article Card] → [Detail View] → [Source Site (external link)]
       ↑                                  ↓
   [Filters]                       [Bookmark] [Hide] [Share]
       ↓
[Region · Discipline · Category]
       ↓
[Search]
```

### Primary screens to design:

1. **Home / Live Feed** — main aggregated feed, infinite scroll
2. **Article Detail** — expanded view with image, summary, source attribution, "read on source" CTA
3. **Filters / Discovery panel** — filter sidebar / drawer
4. **Search** — full-text search with result highlighting
5. **Preferences** — user customization (saved locally, no auth in MVP)
6. **Empty / Loading / Error states** — for each major view
7. **Mobile responsive** — single column, bottom nav, swipe gestures

---

## Features to Cover

### Feed view
- Article cards: thumbnail, title, source name + favicon, region flag, discipline badge, category tag, "X minutes/hours ago"
- "LIVE" indicator for articles < 1 hour old (subtle pulse animation)
- Card density toggle (compact / comfortable / large)
- Sticky filter bar at top with active filter chips
- Pull-to-refresh on mobile, click-to-refresh on desktop
- Infinite scroll with skeleton loaders

### Filters & navigation
- **Region:** Poland 🇵🇱 / Spain 🇪🇸 / World 🌍 / EU 🇪🇺 (multi-select)
- **Discipline:** Road, MTB, Gravel, Track, CX, BMX, E-bike (multi-select with icons)
- **Category:** Race Results, Transfers, Equipment Reviews, Events/Calendar, General
- **Time:** Last hour / Today / This week / All time
- **Source:** filter by specific publisher (CyclingNews, Pinkbike, etc.)
- Active filters shown as removable chips at top
- "Reset filters" link

### Article interactions
- **Tap card →** detail view (modal/drawer on desktop, full screen on mobile)
- **Detail view shows:** large hero image, title, source + date, AI summary (when added), full description excerpt, link to original
- **Quick actions on each card:**
  - Bookmark (saved locally)
  - Hide article (remove from view, soft dismiss)
  - Hide source (mute publisher entirely)
  - Share (copy link, native share on mobile)
  - Mark as read

### Local preferences (no login required in MVP)
- Theme: Dark (default) / Light / Auto
- Language: English / Polish / Spanish
- Default region & disciplines (saved on first visit via questionnaire)
- Card density preference
- Hidden sources list
- Bookmarked articles
- Read history (last 100 articles)
- Notification preferences (when added)

### Search
- Full-text search across titles & descriptions
- Highlight matching terms in results
- Recent searches
- Suggested searches (trending: rider names, race names)

### Onboarding (first visit)
- Friendly 3-step setup: pick region(s), pick disciplines, pick density
- Skippable, all defaults sensible
- No account required

### Empty / Edge states
- No articles match filters → suggest broadening filters
- Connection lost → cached articles + retry button
- New articles available while reading → floating "X new articles" pill
- Article source unavailable → graceful degraded card

---

## Visual Direction

### Mood
- **News room aesthetic:** dense info, clear hierarchy, editorial feel
- **Cycling energy:** dynamic, motion-aware, not stiff
- Inspired by: The Verge, Hacker News density + Apple News polish + Strava's energy
- **NOT** like: generic Bootstrap blogs, cluttered news sites with ads

### Color palette suggestions (designer to refine)
- **Dark mode (default):** near-black background, off-white text, vivid accent
- **Discipline colors** (badges):
  - Road: electric blue `#2563EB`
  - MTB: forest green `#16A34A`
  - Gravel: amber `#D97706`
  - Track: violet `#7C3AED`
  - CX: red `#DC2626`
  - BMX: pink `#EC4899`
- **Categories** in muted neutral tones — discipline is the visual anchor
- **Live indicator:** soft red pulse `#EF4444`

### Typography
- **Headlines:** modern serif (e.g., Source Serif, Newsreader) — gives editorial gravitas, works for older audience
- **Body / UI:** clean sans-serif (Inter, Geist) — for younger audience comfort
- **Mono accents:** for timestamps, source names, technical info

### Motion & animation
- Card hover: subtle lift + shadow + image zoom (transform, GPU-friendly)
- Tap/click: brief scale-down (`active:scale-95`)
- Filter changes: smooth re-layout (FLIP-style)
- Infinite scroll: fade-up new cards
- "Live" indicator: gentle 2s pulse
- Discipline badges on article load: staggered fade-in
- Page transitions: sharp slide for detail, no bouncy springs
- **Respect `prefers-reduced-motion`** — full accessibility

### Layout
- **Desktop:** 3-column at 1440px+ (sidebar filters / feed / preview pane), 2-column at 1024px (filters drawer toggle), 1-column under 768px
- **Mobile:** bottom nav (Feed, Search, Bookmarks, Settings), sticky filter bar, swipeable category chips
- Generous whitespace — don't crowd

---

## Backend Data Shape (for designer reference)

The backend exposes this article shape — design cards/detail around this:

```json
{
  "id": 91,
  "title": "Tour of Turkey: Berwick takes race lead on stage 6...",
  "description": "Australian takes second place to overhaul previous race leader...",
  "url": "https://www.cyclingnews.com/...",
  "image_url": "https://cdn.../image.jpg",
  "published_at": "2026-05-01T12:54:29+00:00",
  "category": "results",
  "region": "world",
  "discipline": "road",
  "language": "en",
  "source_title": "CyclingNews"
}
```

Categories: `results`, `transfers`, `equipment`, `events`, `general`
Regions: `poland`, `spain`, `world`, `eu`
Disciplines: `road`, `mtb`, `gravel`, `track`, `cx`, `all`

---

## Deliverables Requested

Please produce:

1. **Style guide / design tokens** — color palette, typography scale, spacing, radius, shadow system
2. **Component library** — article card (3 densities), filter chip, badge, button, search bar, empty/loading/error states
3. **Key screens (dark + light):**
   - Desktop home feed (1440px)
   - Mobile home feed (375px)
   - Article detail (modal + full-page variant)
   - Filter drawer
   - Search results
   - Preferences screen
   - Onboarding flow (3 steps)
4. **Microinteractions spec** — short notes/GIFs on hover, tap, transitions
5. **Accessibility notes** — contrast ratios (WCAG AA min), focus states, reduced-motion variants

---

## Things to Question / Gaps to Identify

I'd like the designer to actively flag any gaps in this brief. Specifically think about:

- **Source trust signals** — should we display source authority differently? (e.g., UCI official vs. independent blog)
- **Duplicate handling** — when 5 sources cover the same story, do we cluster them on one card with "5 sources" indicator, or show separately?
- **Live race results** — should there be a special "live race" mode with auto-refresh and bigger cards?
- **Race calendar view** — separate from news feed? Calendar widget? List view?
- **Rider/team pages** — future feature, but design should anticipate (entity tagging on cards)
- **Personalization onboarding** — depth vs. friction tradeoff — how minimal can we go?
- **Older user accommodations** — font size toggle? High contrast mode beyond dark/light?
- **Younger user hooks** — short video previews? "Trending" reactions? Streaks?
- **Notifications UI** — in-app notification center for breaking news, even pre-push-notifications
- **Multi-language UX** — switching language, mixed-language feeds

If something seems underspecified, propose 2-3 options with tradeoffs rather than asking — show me thinking through the design.

---

## Success Criteria

- A road-cycling fan in their 60s can scan today's Vuelta results in under 10 seconds
- A 22-year-old MTB rider gets pulled in by the visual energy and bookmarks 3 articles in their first session
- Polish-speaking visitor immediately sees Polish content option
- Loads fast, feels alive without being noisy
- Looks distinctly *not* like a generic WordPress news theme

Please include a short reasoning section per major design choice so I understand the *why*, not just the *what*.
