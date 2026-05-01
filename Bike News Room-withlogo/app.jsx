// Bike News Room — main app
const { useState: useStateA, useEffect: useEffectA, useMemo: useMemoA, useRef: useRefA } = React;
const DA = window.BNR_DATA;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "persona": "younger",
  "theme": "dark",
  "density": "comfortable",
  "duplicateMode": "cluster",
  "showLiveBanner": true,
  "reduceMotion": false,
  "showOnboarding": false
}/*EDITMODE-END*/;

const App = () => {
  const [tweaks, setTweak] = window.useTweaks(TWEAK_DEFAULTS);

  const [view, setView] = useStateA("feed"); // feed | bookmarks
  const [filters, setFilters] = useStateA({
    regions: [], disciplines: [], categories: [], time: "all",
  });
  const [selectedId, setSelectedId] = useStateA(null);
  const [openId, setOpenId] = useStateA(null);
  const [readIds, setReadIds] = useStateA(new Set());
  const [bookmarks, setBookmarks] = useStateA(new Set(DA.SEED_BOOKMARKS));
  const [hidden, setHidden] = useStateA(new Set());
  const [searchOpen, setSearchOpen] = useStateA(false);
  const [onboardOpen, setOnboardOpen] = useStateA(tweaks.showOnboarding);
  const [stateDemo, setStateDemo] = useStateA(null); // null | "no-results" | "offline" | "loading"
  const [showNewPill, setShowNewPill] = useStateA(false);

  // Keyboard
  useEffectA(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); setSearchOpen(true); }
      if (e.key === "/" && !searchOpen && !openId) { e.preventDefault(); setSearchOpen(true); }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [searchOpen, openId]);

  // New articles pill demo — show after delay
  useEffectA(() => {
    const t = setTimeout(() => setShowNewPill(true), 4000);
    return () => clearTimeout(t);
  }, []);

  // Theme + persona
  useEffectA(() => {
    document.documentElement.setAttribute("data-theme", tweaks.theme);
    document.documentElement.setAttribute("data-persona", tweaks.persona);
    document.documentElement.setAttribute("data-reduce-motion", String(tweaks.reduceMotion));
  }, [tweaks.theme, tweaks.persona, tweaks.reduceMotion]);

  // Filter the article list
  const filteredArticles = useMemoA(() => {
    let arr = DA.ARTICLES.filter(a => !hidden.has(a.id));
    if (filters.regions.length) arr = arr.filter(a => filters.regions.includes(a.region));
    if (filters.disciplines.length) arr = arr.filter(a => filters.disciplines.includes(a.discipline));
    if (filters.categories.length) arr = arr.filter(a => filters.categories.includes(a.category));
    if (filters.time !== "all") {
      const cutoffs = { hour: 60, today: 60 * 24, week: 60 * 24 * 7 };
      const max = cutoffs[filters.time];
      arr = arr.filter(a => (DA.NOW - new Date(a.published_at).getTime()) / 60000 <= max);
    }
    return arr.sort((a, b) => new Date(b.published_at) - new Date(a.published_at));
  }, [filters, hidden]);

  const counts = useMemoA(() => {
    const c = { region: {}, discipline: {}, category: {} };
    DA.ARTICLES.forEach(a => {
      c.region[a.region] = (c.region[a.region] || 0) + 1;
      c.discipline[a.discipline] = (c.discipline[a.discipline] || 0) + 1;
      c.category[a.category] = (c.category[a.category] || 0) + 1;
    });
    return c;
  }, []);

  // Selected article (for preview rail)
  const selected = filteredArticles.find(a => a.id === selectedId) || filteredArticles[0];
  const open = DA.ARTICLES.find(a => a.id === openId);

  // Action handlers
  const toggleBookmark = (id) => setBookmarks(s => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });
  const hideArticle = (id) => setHidden(s => new Set(s).add(id));
  const markRead = (id) => setReadIds(s => new Set(s).add(id));

  const openArticle = (a) => {
    markRead(a.id);
    setOpenId(a.id);
  };

  const activeFilterChips = [
    ...filters.regions.map(id => ({ key: `r-${id}`, label: DA.REGIONS.find(r => r.id === id)?.label, remove: () => setFilters(f => ({ ...f, regions: f.regions.filter(x => x !== id) })) })),
    ...filters.disciplines.map(id => ({ key: `d-${id}`, label: DA.DISCIPLINES.find(d => d.id === id)?.label, disc: id, remove: () => setFilters(f => ({ ...f, disciplines: f.disciplines.filter(x => x !== id) })) })),
    ...filters.categories.map(id => ({ key: `c-${id}`, label: DA.CATEGORIES.find(c => c.id === id)?.label, remove: () => setFilters(f => ({ ...f, categories: f.categories.filter(x => x !== id) })) })),
  ];

  // Bookmarks view
  const bookmarkedArticles = DA.ARTICLES.filter(a => bookmarks.has(a.id));

  const liveArticle = filteredArticles.find(a => a.isLive);
  const showLive = tweaks.showLiveBanner && liveArticle && view === "feed" && !stateDemo;

  return (
    <div className="app-root">
      <window.Topbar
        view={view}
        onSearch={() => setSearchOpen(true)}
        onSettings={() => setOnboardOpen(true)}
        onBookmarks={() => setView("bookmarks")}
        onHome={() => setView("feed")}
      />

      <div className="app-shell">
        <window.Sidebar filters={filters} setFilters={setFilters} counts={counts}/>

        <main className="feed">
          {view === "feed" && (
            <>
              <div className="feed-head">
                <h1 className="feed-title">{filters.regions.length || filters.disciplines.length ? "Filtered feed" : "Today's wire"}</h1>
                <div className="feed-sub">
                  <span className="live-dot"/>
                  Updated {window.fmtAgo(new Date(DA.NOW).toISOString())} · {filteredArticles.length} stories
                </div>
              </div>

              {(activeFilterChips.length > 0 || true) && (
                <div className="active-chips">
                  {activeFilterChips.length === 0 ? (
                    <>
                      <span className="chip"><span style={{ width: 6, height: 6, borderRadius: "50%", background: "var(--accent)" }}/>All disciplines · All regions</span>
                      <span style={{ fontFamily: "var(--mono)", fontSize: 11, color: "var(--fg-3)", textTransform: "uppercase", letterSpacing: "0.1em" }}>· no filters applied</span>
                    </>
                  ) : (
                    <>
                      {activeFilterChips.map(c => (
                        <span key={c.key} className={`chip chip-active ${c.disc ? "disc-" + c.disc : ""}`} onClick={c.remove}>
                          {c.label} <span className="x">×</span>
                        </span>
                      ))}
                      <button className="chip" onClick={() => setFilters({ regions: [], disciplines: [], categories: [], time: filters.time })}>
                        Reset all
                      </button>
                    </>
                  )}
                  <div className="chip-density">
                    {["compact", "comfortable", "large"].map(d => (
                      <button key={d} data-on={tweaks.density === d || undefined} onClick={() => setTweak("density", d)}>
                        {d.charAt(0).toUpperCase() + d.slice(1, 4)}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {showNewPill && !stateDemo && (
                <div className="new-pill" onClick={() => setShowNewPill(false)}>
                  <span className="live-dot" style={{ marginRight: 6 }}/>
                  4 new articles · refresh
                </div>
              )}

              {showLive && <window.LiveBanner onClick={() => openArticle(liveArticle)}/>}

              {stateDemo === "no-results" && <window.EmptyState kind="no-results" onAction={() => { setFilters({ regions: [], disciplines: [], categories: [], time: "all" }); setStateDemo(null); }}/>}
              {stateDemo === "offline" && <window.EmptyState kind="offline" onAction={() => setStateDemo(null)}/>}
              {stateDemo === "loading" && (
                <div>{Array.from({ length: 6 }).map((_, i) => <window.SkeletonCard key={i} density={tweaks.density}/>)}</div>
              )}

              {!stateDemo && filteredArticles.length === 0 && <window.EmptyState kind="no-results" onAction={() => setFilters({ regions: [], disciplines: [], categories: [], time: "all" })}/>}

              {!stateDemo && filteredArticles.length > 0 && (
                <div className={tweaks.density === "compact" ? "" : ""}>
                  {filteredArticles.map(a => (
                    <window.ArticleCard
                      key={a.id}
                      article={a}
                      density={tweaks.density}
                      selected={selected?.id === a.id}
                      read={readIds.has(a.id)}
                      bookmarked={bookmarks.has(a.id)}
                      clusterMode={tweaks.duplicateMode}
                      onClick={() => { setSelectedId(a.id); openArticle(a); }}
                      onBookmark={(e) => { e.stopPropagation(); toggleBookmark(a.id); }}
                      onHide={(e) => { e.stopPropagation(); hideArticle(a.id); }}
                      onShare={(e) => { e.stopPropagation(); }}
                    />
                  ))}
                  <div style={{ textAlign: "center", padding: "32px 0 16px", color: "var(--fg-3)", fontFamily: "var(--mono)", fontSize: 11, textTransform: "uppercase", letterSpacing: "0.14em" }}>
                    — End of feed · pull up for more —
                  </div>

                  {/* State demo controls */}
                  <div style={{ display: "flex", gap: 8, justifyContent: "center", flexWrap: "wrap", marginTop: 16 }}>
                    <button className="chip" onClick={() => setStateDemo("loading")}>Show loading state</button>
                    <button className="chip" onClick={() => setStateDemo("no-results")}>Show empty state</button>
                    <button className="chip" onClick={() => setStateDemo("offline")}>Show offline state</button>
                    <button className="chip" onClick={() => setOnboardOpen(true)}>Show onboarding</button>
                  </div>
                </div>
              )}
            </>
          )}

          {view === "bookmarks" && (
            <>
              <div className="feed-head">
                <h1 className="feed-title">Bookmarks</h1>
                <div className="feed-sub">{bookmarkedArticles.length} saved · synced locally</div>
              </div>
              {bookmarkedArticles.length === 0 ? (
                <window.EmptyState kind="no-bookmarks" onAction={() => setView("feed")}/>
              ) : (
                bookmarkedArticles.map(a => (
                  <window.ArticleCard
                    key={a.id}
                    article={a}
                    density="comfortable"
                    bookmarked
                    onClick={() => openArticle(a)}
                    onBookmark={(e) => { e.stopPropagation(); toggleBookmark(a.id); }}
                    onHide={(e) => { e.stopPropagation(); hideArticle(a.id); }}
                    onShare={(e) => { e.stopPropagation(); }}
                  />
                ))
              )}
            </>
          )}
        </main>

        <window.PreviewRail
          article={selected}
          bookmarked={selected ? bookmarks.has(selected.id) : false}
          onBookmark={() => selected && toggleBookmark(selected.id)}
          onOpen={() => selected && openArticle(selected)}
        />
      </div>

      {/* Mobile bottom nav */}
      <nav className="bottom-nav">
        <div className="bottom-nav-inner">
          <button className="bn-btn" data-on={view === "feed" || undefined} onClick={() => setView("feed")}>
            <window.Icon name="home" size={18}/> Feed
          </button>
          <button className="bn-btn" onClick={() => setSearchOpen(true)}>
            <window.Icon name="search" size={18}/> Search
          </button>
          <button className="bn-btn" data-on={view === "bookmarks" || undefined} onClick={() => setView("bookmarks")}>
            <window.Icon name="bookmark" size={18}/> Saved
          </button>
          <button className="bn-btn" onClick={() => setOnboardOpen(true)}>
            <window.Icon name="settings" size={18}/> Settings
          </button>
        </div>
      </nav>

      {open && (
        <window.ArticleModal
          article={open}
          bookmarked={bookmarks.has(open.id)}
          onBookmark={() => toggleBookmark(open.id)}
          onClose={() => setOpenId(null)}
          allArticles={DA.ARTICLES}
        />
      )}
      {searchOpen && (
        <window.SearchOverlay
          articles={DA.ARTICLES}
          onClose={() => setSearchOpen(false)}
          onSelect={(a) => { setSearchOpen(false); openArticle(a); }}
        />
      )}
      {onboardOpen && (
        <window.Onboarding onDone={(prefs) => {
          if (prefs?.regions) setFilters(f => ({ ...f, regions: prefs.regions, disciplines: prefs.disciplines }));
          if (prefs?.density) setTweak("density", prefs.density);
          setOnboardOpen(false);
        }}/>
      )}

      {/* Tweaks panel */}
      <window.TweaksPanel title="Tweaks">
        <window.TweakSection title="Persona mode" subtitle="Flips type scale, density, motion">
          <window.TweakRadio
            value={tweaks.persona}
            onChange={(v) => setTweak("persona", v)}
            options={[
              { value: "younger", label: "Younger" },
              { value: "bridge", label: "Bridge" },
              { value: "older", label: "Older" },
            ]}
          />
        </window.TweakSection>
        <window.TweakSection title="Theme">
          <window.TweakRadio
            value={tweaks.theme}
            onChange={(v) => setTweak("theme", v)}
            options={[{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }]}
          />
        </window.TweakSection>
        <window.TweakSection title="Card density">
          <window.TweakRadio
            value={tweaks.density}
            onChange={(v) => setTweak("density", v)}
            options={[
              { value: "compact", label: "Compact" },
              { value: "comfortable", label: "Comfort" },
              { value: "large", label: "Large" },
            ]}
          />
        </window.TweakSection>
        <window.TweakSection title="Duplicate handling" subtitle="When N sources cover one story">
          <window.TweakRadio
            value={tweaks.duplicateMode}
            onChange={(v) => setTweak("duplicateMode", v)}
            options={[{ value: "cluster", label: "Cluster" }, { value: "list", label: "List" }]}
          />
        </window.TweakSection>
        <window.TweakSection title="Live race banner">
          <window.TweakToggle value={tweaks.showLiveBanner} onChange={(v) => setTweak("showLiveBanner", v)}/>
        </window.TweakSection>
        <window.TweakSection title="Reduce motion">
          <window.TweakToggle value={tweaks.reduceMotion} onChange={(v) => setTweak("reduceMotion", v)}/>
        </window.TweakSection>
        <window.TweakSection title="Show onboarding flow">
          <window.TweakButton onClick={() => setOnboardOpen(true)}>Open onboarding</window.TweakButton>
        </window.TweakSection>
      </window.TweaksPanel>
    </div>
  );
};

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
