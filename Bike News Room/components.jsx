// Bike News Room — UI components

const { useState, useEffect, useRef, useMemo } = React;

const D = window.BNR_DATA;

// ============ ICONS ============
const Icon = ({ name, size = 16 }) => {
  const s = size;
  const stroke = "currentColor";
  const props = { width: s, height: s, viewBox: "0 0 24 24", fill: "none", stroke, strokeWidth: 1.6, strokeLinecap: "round", strokeLinejoin: "round" };
  switch (name) {
    case "search": return <svg {...props}><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>;
    case "bookmark": return <svg {...props}><path d="M6 3h12v18l-6-4-6 4z"/></svg>;
    case "bookmark-fill": return <svg {...props} fill="currentColor"><path d="M6 3h12v18l-6-4-6 4z"/></svg>;
    case "eye-off": return <svg {...props}><path d="M2 12s3-7 10-7c2 0 3.6.5 4.9 1.2"/><path d="M22 12s-3 7-10 7c-2 0-3.6-.5-4.9-1.2"/><path d="m4 4 16 16"/></svg>;
    case "share": return <svg {...props}><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="18" cy="18" r="2.5"/><path d="m8.2 11 7.6-3.6M8.2 13l7.6 3.6"/></svg>;
    case "x": return <svg {...props}><path d="M6 6 18 18M18 6 6 18"/></svg>;
    case "settings": return <svg {...props}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1a1.7 1.7 0 0 0 1.5-1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3 1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8 1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>;
    case "filter": return <svg {...props}><path d="M3 6h18M6 12h12M10 18h4"/></svg>;
    case "arrow-right": return <svg {...props}><path d="M5 12h14M13 5l7 7-7 7"/></svg>;
    case "arrow-up": return <svg {...props}><path d="m5 12 7-7 7 7M12 5v14"/></svg>;
    case "external": return <svg {...props}><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M19 13v6a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h6"/></svg>;
    case "home": return <svg {...props}><path d="M3 11 12 4l9 7v9a1 1 0 0 1-1 1h-5v-7h-6v7H4a1 1 0 0 1-1-1z"/></svg>;
    case "check": return <svg {...props}><path d="m5 12 5 5L20 7"/></svg>;
    case "wifi-off": return <svg {...props}><path d="M2 8.8a16 16 0 0 1 4-2.5"/><path d="M5 12.6a10 10 0 0 1 4-2.4"/><path d="M9 16.5a4 4 0 0 1 3-1.4"/><path d="M12 20h.01"/><path d="m4 4 16 16"/><path d="M18 12.6a10 10 0 0 0-4-2.3"/></svg>;
    case "inbox": return <svg {...props}><path d="M3 12v6a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-6"/><path d="M3 12 5 4h14l2 8"/><path d="M3 12h5l1 2h6l1-2h5"/></svg>;
    case "refresh": return <svg {...props}><path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/></svg>;
    case "chevron": return <svg {...props}><path d="m9 6 6 6-6 6"/></svg>;
    case "play": return <svg {...props} fill="currentColor" stroke="none"><path d="M7 5v14l12-7z"/></svg>;
    case "calendar": return <svg {...props}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
    default: return null;
  }
};

// ============ HELPERS ============
const fmtAgo = (iso) => {
  const diff = (D.NOW - new Date(iso).getTime()) / 60000;
  if (diff < 1) return "just now";
  if (diff < 60) return `${Math.round(diff)}m ago`;
  if (diff < 24 * 60) return `${Math.round(diff / 60)}h ago`;
  return `${Math.round(diff / (24 * 60))}d ago`;
};
const isLive = (a) => a.isLive || (D.NOW - new Date(a.published_at).getTime()) < 60 * 60 * 1000;
const sourceById = (id) => D.SOURCES.find((s) => s.id === id);
const discById = (id) => D.DISCIPLINES.find((d) => d.id === id);

// Initials for source chip
const srcInitials = (id) => {
  const s = sourceById(id);
  if (!s) return "?";
  return s.name.replace(/[^A-Z]/g, "").slice(0, 2) || s.name.slice(0, 2).toUpperCase();
};

// Highlight matches inside title text
const highlight = (text, q) => {
  if (!q) return text;
  const re = new RegExp(`(${q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`, "ig");
  const parts = text.split(re);
  return parts.map((p, i) => re.test(p) ? <mark key={i}>{p}</mark> : <span key={i}>{p}</span>);
};

// ============ ARTICLE CARD ============
const ImagePlaceholder = ({ article, className = "card-img" }) => {
  const angles = [125, 145, 165, 100, 80];
  const angle = angles[article.id % angles.length];
  const label = article.discipline.toUpperCase() + " · " + article.image_seed;
  return (
    <div
      className={`${className} img-ph`}
      style={{ "--ph-angle": `${angle}deg` }}
      data-label={label}
    />
  );
};

const ArticleCard = ({ article, density, selected, read, bookmarked, onClick, onBookmark, onHide, onShare, clusterMode }) => {
  const src = sourceById(article.source);
  const disc = discById(article.discipline);
  const live = isLive(article);
  const hasCluster = clusterMode === "cluster" && article.cluster && article.cluster.length;

  return (
    <article
      className={`card card-${density} disc-${article.discipline} fade-up`}
      data-selected={selected || undefined}
      data-read={read || undefined}
      onClick={onClick}
    >
      {density !== "compact" && <ImagePlaceholder article={article} />}
      <div className="card-body">
        <div className="card-meta">
          {live && <span className="live-tag"><span className="live-dot"/> LIVE</span>}
          <span className="source-name">{src?.name}</span>
          <span className="meta-sep"/>
          <span className="disc-tag">{disc?.label}</span>
          <span className="meta-sep"/>
          <span>{fmtAgo(article.published_at)}</span>
          {article.region !== "world" && <>
            <span className="meta-sep"/>
            <span>{D.REGIONS.find(r => r.id === article.region)?.label}</span>
          </>}
        </div>
        <h3 className="card-title">{article.title}</h3>
        {density !== "compact" && <p className="card-desc">{article.description}</p>}
        {hasCluster && (
          <div className="card-cluster">
            <div className="cluster-stack">
              {[article.source, ...article.cluster].slice(0, 4).map((sid, i) => (
                <span key={sid + i} className="src-chip">{srcInitials(sid)}</span>
              ))}
            </div>
            <span>+{article.cluster.length} sources covering this</span>
          </div>
        )}
      </div>
      <div className="card-actions" onClick={(e) => e.stopPropagation()}>
        <button className="card-action-btn" data-on={bookmarked || undefined} title="Bookmark" onClick={onBookmark}>
          <Icon name={bookmarked ? "bookmark-fill" : "bookmark"} size={13}/>
        </button>
        <button className="card-action-btn" title="Share" onClick={onShare}>
          <Icon name="share" size={13}/>
        </button>
        <button className="card-action-btn" title="Hide" onClick={onHide}>
          <Icon name="eye-off" size={13}/>
        </button>
      </div>
    </article>
  );
};

// ============ LIVE BANNER ============
const LiveBanner = ({ onClick }) => {
  const r = D.LIVE_RACE;
  const pct = (r.km_done / r.km_total) * 100;
  return (
    <div className="live-banner fade-up" onClick={onClick} style={{ cursor: "pointer" }}>
      <div className="live-head"><span className="live-dot"/> Live now · {r.stage}</div>
      <h2 className="live-race">{r.name}</h2>
      <div className="live-stage">{r.stageDetail} · {r.km_done}/{r.km_total} km</div>
      <div className="live-progress"><i style={{ width: `${pct}%` }}/></div>
      <div className="live-rows">
        {[r.leader, ...r.chasers].map((rider, i) => (
          <div key={i} className="live-row">
            <span className="pos">{i + 1}.</span>
            <span><strong style={{ color: "var(--fg-0)", fontWeight: 600 }}>{rider.name}</strong> <span style={{ color: "var(--fg-2)" }}>· {rider.team}</span></span>
            <span className="gap">{rider.gap}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

// ============ TOPBAR ============
const Topbar = ({ onSearch, onSettings, onBookmarks, view, onHome, persona, theme }) => {
  return (
    <div className="topbar">
      <div className="brand" onClick={onHome} style={{ cursor: "pointer" }}>
        <div className="brand-mark"/>
        <span>Bike News Room</span>
        <span className="brand-tag">v0.1</span>
      </div>
      <button className="search-pill" onClick={onSearch}>
        <Icon name="search" size={14}/>
        <span>Search riders, races, transfers…</span>
        <span className="kbd">⌘K</span>
      </button>
      <div className="topbar-actions">
        <button className="icon-btn" data-active={view === "feed" || undefined} onClick={onHome} title="Feed">
          <Icon name="home" size={16}/>
        </button>
        <button className="icon-btn" data-active={view === "bookmarks" || undefined} onClick={onBookmarks} title="Bookmarks">
          <Icon name="bookmark" size={16}/>
        </button>
        <button className="icon-btn" onClick={onSettings} title="Settings">
          <Icon name="settings" size={16}/>
        </button>
      </div>
    </div>
  );
};

// ============ SIDEBAR ============
const Sidebar = ({ filters, setFilters, counts }) => {
  const toggleArr = (key, val) => {
    setFilters(f => {
      const arr = f[key];
      return { ...f, [key]: arr.includes(val) ? arr.filter(v => v !== val) : [...arr, val] };
    });
  };
  const setOne = (key, val) => setFilters(f => ({ ...f, [key]: val }));

  return (
    <aside className="sidebar">
      <div className="side-section">
        <div className="side-label">Region {filters.regions.length > 0 && <span className="clear" onClick={() => setOne("regions", [])}>clear</span>}</div>
        {D.REGIONS.map(r => (
          <button key={r.id} className="side-item" data-selected={filters.regions.includes(r.id) || undefined} onClick={() => toggleArr("regions", r.id)}>
            <span style={{ fontSize: 16 }}>{r.flag}</span>
            <span>{r.label}</span>
            <span className="count">{counts.region[r.id] || 0}</span>
          </button>
        ))}
      </div>

      <div className="side-section">
        <div className="side-label">Discipline {filters.disciplines.length > 0 && <span className="clear" onClick={() => setOne("disciplines", [])}>clear</span>}</div>
        {D.DISCIPLINES.map(d => (
          <button key={d.id} className={`side-item disc-${d.id}`} data-selected={filters.disciplines.includes(d.id) || undefined} onClick={() => toggleArr("disciplines", d.id)}>
            <span className="dot"/>
            <span>{d.label}</span>
            <span className="count">{counts.discipline[d.id] || 0}</span>
          </button>
        ))}
      </div>

      <div className="side-section">
        <div className="side-label">Category</div>
        {D.CATEGORIES.map(c => (
          <button key={c.id} className="side-item" data-selected={filters.categories.includes(c.id) || undefined} onClick={() => toggleArr("categories", c.id)}>
            <span style={{ width: 8, height: 8, border: "1px solid var(--fg-3)", borderRadius: 2 }}/>
            <span>{c.label}</span>
            <span className="count">{counts.category[c.id] || 0}</span>
          </button>
        ))}
      </div>

      <div className="side-section">
        <div className="side-label">Time</div>
        <div className="side-time">
          {[["hour", "1H"], ["today", "1D"], ["week", "1W"], ["all", "ALL"]].map(([id, label]) => (
            <button key={id} data-on={filters.time === id || undefined} onClick={() => setOne("time", id)}>{label}</button>
          ))}
        </div>
      </div>
    </aside>
  );
};

// ============ PREVIEW RAIL ============
const PreviewRail = ({ article, bookmarked, onBookmark, onOpen }) => {
  if (!article) {
    return (
      <aside className="preview-rail">
        <div className="rail-empty">
          Hover or click an article<br/>to preview here<br/><br/>
          <span className="key">↑</span><span className="key">↓</span> to navigate · <span className="key">Enter</span> to open
        </div>
      </aside>
    );
  }
  const src = sourceById(article.source);
  const disc = discById(article.discipline);
  return (
    <aside className="preview-rail">
      <ImagePlaceholder article={article} className="rail-img" />
      <div className="rail-meta">
        {isLive(article) && <><span className="live-dot"/><span style={{ color: "var(--live)" }}>LIVE</span><span className="meta-sep" style={{ width: 2, height: 2, borderRadius: "50%", background: "var(--fg-3)" }}/></>}
        <span style={{ color: `var(--disc-${article.discipline})` }}>{disc?.label}</span>
        <span style={{ width: 2, height: 2, borderRadius: "50%", background: "var(--fg-3)" }}/>
        <span>{src?.name}</span>
        <span style={{ width: 2, height: 2, borderRadius: "50%", background: "var(--fg-3)" }}/>
        <span>{fmtAgo(article.published_at)}</span>
      </div>
      <h2 className="rail-title">{article.title}</h2>
      <p className="rail-desc">{article.description}</p>
      <button className="rail-cta" onClick={onOpen}>
        Read full article <Icon name="arrow-right" size={14}/>
      </button>
      <div className="rail-actions">
        <button className="rail-action" data-on={bookmarked || undefined} onClick={onBookmark}>
          <Icon name={bookmarked ? "bookmark-fill" : "bookmark"} size={13}/>
          {bookmarked ? "Saved" : "Bookmark"}
        </button>
        <button className="rail-action">
          <Icon name="share" size={13}/> Share
        </button>
      </div>
    </aside>
  );
};

Object.assign(window, { Icon, ArticleCard, LiveBanner, Topbar, Sidebar, PreviewRail, ImagePlaceholder, fmtAgo, isLive, sourceById, discById, srcInitials, highlight });
