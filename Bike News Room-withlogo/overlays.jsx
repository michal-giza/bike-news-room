// Bike News Room — overlays and secondary screens
const { useState: useStateO, useEffect: useEffectO, useRef: useRefO, useMemo: useMemoO } = React;
const DO = window.BNR_DATA;

// ============ DETAIL MODAL ============
const ArticleModal = ({ article, onClose, bookmarked, onBookmark, allArticles }) => {
  useEffectO(() => {
    const onKey = (e) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => { window.removeEventListener("keydown", onKey); document.body.style.overflow = ""; };
  }, [onClose]);

  if (!article) return null;
  const src = window.sourceById(article.source);
  const disc = window.discById(article.discipline);
  const cluster = (article.cluster || []).map(window.sourceById).filter(Boolean);

  return (
    <div className="modal-scrim" onClick={onClose}>
      <div className={`modal disc-${article.discipline}`} onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div className="modal-meta">
            {window.isLive(article) && <><span className="live-dot"/><span style={{ color: "var(--live)" }}>LIVE</span></>}
            <span style={{ color: `var(--disc-${article.discipline})`, fontWeight: 600 }}>{disc?.label}</span>
            <span style={{ width: 2, height: 2, borderRadius: "50%", background: "var(--fg-3)" }}/>
            <span>{src?.name}</span>
            <span style={{ width: 2, height: 2, borderRadius: "50%", background: "var(--fg-3)" }}/>
            <span>{window.fmtAgo(article.published_at)}</span>
          </div>
          <div className="modal-actions">
            <button className="card-action-btn" data-on={bookmarked || undefined} onClick={onBookmark} title="Bookmark">
              <window.Icon name={bookmarked ? "bookmark-fill" : "bookmark"} size={14}/>
            </button>
            <button className="card-action-btn" title="Share"><window.Icon name="share" size={14}/></button>
            <button className="card-action-btn" title="Hide"><window.Icon name="eye-off" size={14}/></button>
            <button className="card-action-btn" onClick={onClose} title="Close"><window.Icon name="x" size={14}/></button>
          </div>
        </div>
        <div className="modal-body">
          <window.ImagePlaceholder article={article} className="modal-hero"/>
          <h1 className="modal-title">{article.title}</h1>
          <div className="modal-byline">
            <span style={{ color: "var(--fg-0)", fontWeight: 600 }}>{src?.name}</span>
            <span>·</span>
            <span>{new Date(article.published_at).toUTCString().slice(5, 22)}</span>
            <span>·</span>
            <span>{article.language.toUpperCase()}</span>
          </div>
          <div className="summary-block">
            <div className="summary-label"><span className="ai-glyph"/> AI summary · 3 sources</div>
            <p className="summary-text">{article.description} The reporting consensus across {cluster.length + 1} sources highlights the timing and significance of the move within the wider GC battle.</p>
          </div>
          <p className="modal-desc">{article.description}</p>
          <a href={article.url} target="_blank" rel="noopener" className="modal-cta">
            Read on {src?.name} <window.Icon name="external" size={14}/>
          </a>
          {cluster.length > 0 && (
            <div className="modal-others">
              <h4>Also covered by · {cluster.length} sources</h4>
              {cluster.map(s => (
                <div key={s.id} className="other-row">
                  <span className="name">{s.name}</span>
                  <span className="arrow"><window.Icon name="arrow-right" size={14}/></span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// ============ SEARCH OVERLAY ============
const SearchOverlay = ({ onClose, onSelect, articles }) => {
  const [q, setQ] = useStateO("");
  const inputRef = useRefO();
  useEffectO(() => {
    inputRef.current?.focus();
    const onKey = (e) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const results = useMemoO(() => {
    if (!q.trim()) return [];
    const lo = q.toLowerCase();
    return articles
      .filter(a => a.title.toLowerCase().includes(lo) || a.description.toLowerCase().includes(lo))
      .slice(0, 8);
  }, [q, articles]);

  return (
    <div className="search-overlay" onClick={onClose}>
      <div className="search-box" onClick={(e) => e.stopPropagation()}>
        <div className="search-input-row">
          <window.Icon name="search" size={18}/>
          <input ref={inputRef} value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search riders, races, equipment…"/>
          <button className="card-action-btn" onClick={onClose}><window.Icon name="x" size={14}/></button>
        </div>
        <div className="search-results">
          {!q && <>
            <div className="search-section-label">Trending</div>
            <div className="suggested-pills">
              {DO.SUGGESTED.map(s => (
                <button key={s} className="sug-pill" onClick={() => setQ(s)}>{s}</button>
              ))}
            </div>
            <div className="search-section-label">Recent</div>
            {DO.RECENT_SEARCHES.map(s => (
              <div key={s} className="search-result" onClick={() => setQ(s)}>
                <div>
                  <div className="res-title">{s}</div>
                  <div className="res-meta">recent</div>
                </div>
                <window.Icon name="arrow-up" size={14}/>
              </div>
            ))}
          </>}
          {q && results.length === 0 && (
            <div style={{ padding: "30px 20px", textAlign: "center", color: "var(--fg-2)", fontSize: 13 }}>
              No results for <strong style={{ color: "var(--fg-0)" }}>"{q}"</strong>
            </div>
          )}
          {q && results.length > 0 && <>
            <div className="search-section-label">{results.length} results</div>
            {results.map((a, i) => (
              <div key={a.id} className="search-result" data-active={i === 0 || undefined} onClick={() => onSelect(a)}>
                <div>
                  <div className="res-title">{window.highlight(a.title, q)}</div>
                  <div className="res-meta">{window.sourceById(a.source)?.name} · {window.discById(a.discipline)?.label} · {window.fmtAgo(a.published_at)}</div>
                </div>
                <window.Icon name="arrow-right" size={14}/>
              </div>
            ))}
          </>}
        </div>
        <div className="search-foot">
          <span><span className="key">↑↓</span> navigate</span>
          <span><span className="key">↵</span> open</span>
          <span><span className="key">esc</span> close</span>
        </div>
      </div>
    </div>
  );
};

// ============ ONBOARDING ============
const Onboarding = ({ onDone }) => {
  const [step, setStep] = useStateO(0);
  const [regions, setRegions] = useStateO(["world"]);
  const [disciplines, setDisciplines] = useStateO([]);
  const [density, setDensity] = useStateO("comfortable");

  const toggle = (arr, set, val) => set(arr.includes(val) ? arr.filter(v => v !== val) : [...arr, val]);

  const steps = [
    {
      title: "Where do you ride?",
      lede: "Pick the regions you want news from. You can change this anytime — and we'll always show World by default.",
      content: (
        <div className="option-grid">
          {DO.REGIONS.map(r => (
            <button key={r.id} className="opt" data-on={regions.includes(r.id) || undefined} onClick={() => toggle(regions, setRegions, r.id)}>
              <span className="opt-flag">{r.flag}</span>
              <div className="opt-title">{r.label}</div>
              <div className="opt-sub">{r.id === "world" ? "Global wire" : r.id.toUpperCase()}</div>
            </button>
          ))}
        </div>
      ),
    },
    {
      title: "What do you ride?",
      lede: "We'll prioritize these disciplines in your feed. Multi-select — most riders pick two or three.",
      content: (
        <div className="option-grid">
          {DO.DISCIPLINES.map(d => (
            <button key={d.id} className={`opt disc-${d.id}`} data-on={disciplines.includes(d.id) || undefined} onClick={() => toggle(disciplines, setDisciplines, d.id)}>
              <div style={{ width: 28, height: 28, borderRadius: 6, background: `var(--disc-${d.id})`, opacity: 0.9, marginBottom: 10 }}/>
              <div className="opt-title">{d.label}</div>
              <div className="opt-sub">{d.id === "road" ? "Tour, Giro, Vuelta" : d.id === "mtb" ? "XCO · DH · Enduro" : d.id === "gravel" ? "Unbound · SBT GRVL" : d.id === "track" ? "UCI Worlds · Champs League" : d.id === "cx" ? "Worldcup · X²O" : "Race · Park"}</div>
            </button>
          ))}
        </div>
      ),
    },
    {
      title: "How dense?",
      lede: "How much do you want to see at once? You can switch densities from the feed.",
      content: (
        <div className="option-grid" style={{ gridTemplateColumns: "1fr 1fr 1fr" }}>
          {[
            { id: "compact", title: "Compact", sub: "Headlines only", lines: 3 },
            { id: "comfortable", title: "Comfortable", sub: "Image + summary", lines: 2 },
            { id: "large", title: "Large", sub: "Magazine view", lines: 1 },
          ].map(o => (
            <button key={o.id} className="opt" data-on={density === o.id || undefined} onClick={() => setDensity(o.id)}>
              <div style={{ display: "grid", gap: 4, marginBottom: 12 }}>
                {Array.from({ length: o.lines }).map((_, i) => (
                  <div key={i} style={{ display: "grid", gridTemplateColumns: o.id === "large" ? "1fr" : o.id === "comfortable" ? "32px 1fr" : "1fr", gap: 6 }}>
                    {o.id === "large" && <div style={{ height: 28, background: "var(--bg-3)", borderRadius: 3 }}/>}
                    {o.id === "comfortable" && <div style={{ height: 22, background: "var(--bg-3)", borderRadius: 3 }}/>}
                    <div>
                      <div style={{ height: 4, background: "var(--bg-3)", marginBottom: 3, borderRadius: 2 }}/>
                      <div style={{ height: 4, background: "var(--bg-3)", width: "70%", borderRadius: 2 }}/>
                    </div>
                  </div>
                ))}
              </div>
              <div className="opt-title">{o.title}</div>
              <div className="opt-sub">{o.sub}</div>
            </button>
          ))}
        </div>
      ),
    },
  ];

  const s = steps[step];

  return (
    <div className="onboard-scrim">
      <div className="onboard fade-up" key={step}>
        <div className="onboard-step">
          <span>Step {step + 1} of 3</span>
          <span style={{ flex: 1 }}/>
          <span style={{ fontFamily: "var(--serif)", fontSize: 16, fontWeight: 600, letterSpacing: "-0.01em", textTransform: "none", color: "var(--fg-0)" }}>Bike News Room</span>
        </div>
        <div className="onboard-progress">
          {[0, 1, 2].map(i => <i key={i} data-on={i <= step || undefined}/>)}
        </div>
        <h1>{s.title}</h1>
        <p className="lede">{s.lede}</p>
        {s.content}
        <div className="onboard-foot">
          <button className="btn-ghost" onClick={onDone}>Skip — use defaults</button>
          <div style={{ display: "flex", gap: 8 }}>
            {step > 0 && <button className="btn-ghost" onClick={() => setStep(step - 1)}>Back</button>}
            {step < 2 ? (
              <button className="btn-primary" onClick={() => setStep(step + 1)}>
                Continue <window.Icon name="arrow-right" size={14}/>
              </button>
            ) : (
              <button className="btn-primary" onClick={() => onDone({ regions, disciplines, density })}>
                Start reading <window.Icon name="arrow-right" size={14}/>
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

// ============ EMPTY / ERROR / LOADING STATES ============
const EmptyState = ({ kind, onAction }) => {
  const variants = {
    "no-results": {
      glyph: <window.Icon name="inbox" size={22}/>,
      title: "Nothing here yet",
      sub: "No articles match your filters. Try broadening regions or disciplines.",
      cta: "Reset filters",
    },
    "offline": {
      glyph: <window.Icon name="wifi-off" size={22}/>,
      title: "You're offline",
      sub: "Showing cached articles from your last session. We'll refresh when you're back.",
      cta: "Retry",
    },
    "no-bookmarks": {
      glyph: <window.Icon name="bookmark" size={22}/>,
      title: "No bookmarks yet",
      sub: "Save articles from the feed to read them later — works offline too.",
      cta: "Browse feed",
    },
  };
  const v = variants[kind] || variants["no-results"];
  return (
    <div className="state-block">
      <div className="state-glyph">{v.glyph}</div>
      <h3 className="state-title">{v.title}</h3>
      <p className="state-sub">{v.sub}</p>
      <button className="btn-primary" onClick={onAction}>{v.cta}</button>
    </div>
  );
};

const SkeletonCard = ({ density }) => {
  if (density === "compact") {
    return (
      <div className="card card-compact" style={{ borderColor: "var(--line-soft)" }}>
        <div className="card-meta">
          <span className="skeleton" style={{ width: 60, height: 8 }}/>
          <span className="skeleton" style={{ width: 40, height: 8 }}/>
        </div>
        <div className="skeleton" style={{ width: "70%", height: 14, marginTop: 6 }}/>
      </div>
    );
  }
  return (
    <div className="card card-comfort" style={{ borderColor: "var(--line-soft)" }}>
      <div className="skeleton" style={{ width: 132, height: 88 }}/>
      <div className="card-body">
        <div style={{ display: "flex", gap: 8, marginBottom: 8 }}>
          <span className="skeleton" style={{ width: 60, height: 8 }}/>
          <span className="skeleton" style={{ width: 40, height: 8 }}/>
        </div>
        <div className="skeleton" style={{ width: "90%", height: 14, marginBottom: 6 }}/>
        <div className="skeleton" style={{ width: "60%", height: 14, marginBottom: 10 }}/>
        <div className="skeleton" style={{ width: "100%", height: 10, marginBottom: 4 }}/>
        <div className="skeleton" style={{ width: "75%", height: 10 }}/>
      </div>
    </div>
  );
};

Object.assign(window, { ArticleModal, SearchOverlay, Onboarding, EmptyState, SkeletonCard });
