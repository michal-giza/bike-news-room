// Bike News Room — Tokens & components canvas
const { useState: uS } = React;
const D2 = window.BNR_DATA;

// ===== Token swatch primitives =====
const Swatch = ({ token, label, sub, dark }) => (
  <div style={{ display: "grid", gridTemplateColumns: "56px 1fr", gap: 12, alignItems: "center", padding: "10px 0", borderBottom: "1px solid var(--line-soft)" }}>
    <div style={{ width: 56, height: 56, borderRadius: 8, background: `var(${token})`, border: "1px solid var(--line)" }}/>
    <div>
      <div style={{ fontFamily: "var(--mono)", fontSize: 12, color: "var(--fg-0)" }}>{label}</div>
      <div style={{ fontFamily: "var(--mono)", fontSize: 10, color: "var(--fg-2)", textTransform: "uppercase", letterSpacing: "0.08em" }}>{token} {sub && `· ${sub}`}</div>
    </div>
  </div>
);

const Section = ({ title, children, w = 720 }) => (
  <div style={{ width: w, background: "var(--bg-1)", border: "1px solid var(--line)", borderRadius: 12, padding: 28, color: "var(--fg-0)" }}>
    <div style={{ fontFamily: "var(--mono)", fontSize: 11, color: "var(--fg-2)", textTransform: "uppercase", letterSpacing: "0.16em", marginBottom: 18 }}>{title}</div>
    {children}
  </div>
);

const SubH = ({ children }) => (
  <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, letterSpacing: "-0.02em", margin: "0 0 14px" }}>{children}</div>
);

// ===== Cards =====
const ColorsCard = () => (
  <Section title="Colors · Dark surfaces">
    <SubH>Surfaces & ink</SubH>
    <Swatch token="--bg-0" label="bg-0 · page" sub="oklch(0.14 0.006 250)"/>
    <Swatch token="--bg-1" label="bg-1 · card"/>
    <Swatch token="--bg-2" label="bg-2 · hover"/>
    <Swatch token="--bg-3" label="bg-3 · selected"/>
    <Swatch token="--fg-0" label="fg-0 · primary"/>
    <Swatch token="--fg-1" label="fg-1 · secondary"/>
    <Swatch token="--fg-2" label="fg-2 · meta"/>
    <Swatch token="--fg-3" label="fg-3 · disabled"/>
    <SubH>Accent & live</SubH>
    <Swatch token="--accent" label="accent · sodium hi-vis" sub="oklch(0.78 0.18 95)"/>
    <Swatch token="--live" label="live · race red" sub="oklch(0.68 0.22 25)"/>
    <SubH>Discipline · used quiet</SubH>
    {D2.DISCIPLINES.map(d => <Swatch key={d.id} token={`--disc-${d.id}`} label={`disc-${d.id} · ${d.label}`}/>)}
  </Section>
);

const TypeCard = () => (
  <Section title="Typography">
    <SubH>Type stack</SubH>
    <div style={{ display: "grid", gap: 16 }}>
      <div>
        <div style={{ fontFamily: "var(--mono)", fontSize: 10, color: "var(--fg-2)", textTransform: "uppercase", letterSpacing: "0.14em", marginBottom: 4 }}>Newsreader · serif headlines</div>
        <div style={{ fontFamily: "var(--serif)", fontSize: 48, fontWeight: 600, letterSpacing: "-0.025em", lineHeight: 1.05 }}>Berwick takes Turkey lead</div>
      </div>
      <div>
        <div style={{ fontFamily: "var(--mono)", fontSize: 10, color: "var(--fg-2)", textTransform: "uppercase", letterSpacing: "0.14em", marginBottom: 4 }}>Inter Tight · UI & body</div>
        <div style={{ fontSize: 16, lineHeight: 1.55, color: "var(--fg-1)" }}>The 24-year-old Australian overhauled previous race leader with a long-range solo move on the Tahtalı ascent.</div>
      </div>
      <div>
        <div style={{ fontFamily: "var(--mono)", fontSize: 10, color: "var(--fg-2)", textTransform: "uppercase", letterSpacing: "0.14em", marginBottom: 4 }}>JetBrains Mono · meta & timestamps</div>
        <div style={{ fontFamily: "var(--mono)", fontSize: 12, color: "var(--fg-1)", textTransform: "uppercase", letterSpacing: "0.08em" }}>CYCLINGNEWS · ROAD · 18M AGO · LIVE</div>
      </div>
    </div>
    <hr className="hr" style={{ margin: "22px 0" }}/>
    <SubH>Scale</SubH>
    <div style={{ display: "grid", gap: 10 }}>
      {[
        ["display 64", 64, "serif", 600],
        ["xl 48", 48, "serif", 600],
        ["L 32", 32, "serif", 600],
        ["M 22", 22, "serif", 600],
        ["S 17", 17, "serif", 600],
        ["body 14", 14, "sans", 400],
        ["meta 11", 11, "mono", 500],
      ].map(([l, sz, fam, w]) => (
        <div key={l} style={{ display: "grid", gridTemplateColumns: "120px 1fr", alignItems: "baseline", gap: 16 }}>
          <span style={{ fontFamily: "var(--mono)", fontSize: 11, color: "var(--fg-2)", textTransform: "uppercase", letterSpacing: "0.08em" }}>{l}</span>
          <span style={{ fontFamily: `var(--${fam})`, fontSize: sz, fontWeight: w, letterSpacing: sz > 24 ? "-0.02em" : 0, lineHeight: 1.15 }}>The quick Pidcock</span>
        </div>
      ))}
    </div>
  </Section>
);

const SpacingCard = () => (
  <Section title="Spacing · Radius · Shadows" w={520}>
    <SubH>Spacing scale</SubH>
    <div style={{ display: "grid", gap: 8 }}>
      {[["s-1", 4], ["s-2", 8], ["s-3", 12], ["s-4", 16], ["s-5", 20], ["s-6", 24], ["s-8", 32], ["s-10", 40], ["s-12", 48], ["s-16", 64]].map(([t, v]) => (
        <div key={t} style={{ display: "grid", gridTemplateColumns: "70px 80px 1fr", gap: 10, alignItems: "center" }}>
          <span style={{ fontFamily: "var(--mono)", fontSize: 11, color: "var(--fg-2)" }}>{t}</span>
          <span style={{ fontFamily: "var(--mono)", fontSize: 11, color: "var(--fg-1)" }}>{v}px</span>
          <span style={{ display: "block", height: 8, width: v, background: "var(--accent)", borderRadius: 2 }}/>
        </div>
      ))}
    </div>
    <hr className="hr" style={{ margin: "22px 0" }}/>
    <SubH>Radii</SubH>
    <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
      {["r-1", "r-2", "r-3", "r-4", "r-pill"].map(t => (
        <div key={t} style={{ textAlign: "center" }}>
          <div style={{ width: 64, height: 48, background: "var(--bg-2)", border: "1px solid var(--line)", borderRadius: `var(--${t})`, marginBottom: 6 }}/>
          <div style={{ fontFamily: "var(--mono)", fontSize: 10, color: "var(--fg-2)" }}>{t}</div>
        </div>
      ))}
    </div>
    <hr className="hr" style={{ margin: "22px 0" }}/>
    <SubH>Shadows</SubH>
    <div style={{ display: "flex", gap: 18 }}>
      {["shadow-1", "shadow-2", "shadow-pop"].map(t => (
        <div key={t} style={{ flex: 1, textAlign: "center" }}>
          <div style={{ height: 56, background: "var(--bg-1)", borderRadius: 8, boxShadow: `var(--${t})`, marginBottom: 8 }}/>
          <div style={{ fontFamily: "var(--mono)", fontSize: 10, color: "var(--fg-2)" }}>{t}</div>
        </div>
      ))}
    </div>
  </Section>
);

const ChipsCard = () => {
  const [on, setOn] = uS({ road: true, mtb: false, gravel: false });
  return (
    <Section title="Chips · Filter system" w={520}>
      <SubH>Active filter chips</SubH>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 22 }}>
        <span className="chip chip-active disc-road">Road <span className="x">×</span></span>
        <span className="chip chip-active disc-mtb">MTB <span className="x">×</span></span>
        <span className="chip">Reset all</span>
      </div>
      <SubH>Toggle chips</SubH>
      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 22 }}>
        {Object.keys(on).map(k => (
          <span key={k} className={`chip ${on[k] ? "chip-active disc-" + k : ""}`} onClick={() => setOn(s => ({ ...s, [k]: !s[k] }))} style={{ cursor: "pointer" }}>
            {k}
          </span>
        ))}
      </div>
      <SubH>Density toggle</SubH>
      <div className="chip-density" style={{ marginLeft: 0, display: "inline-flex" }}>
        <button data-on>Comp</button><button>Comf</button><button>Larg</button>
      </div>
    </Section>
  );
};

const CardsCard = () => {
  const a = D2.ARTICLES[0];
  return (
    <Section title="Article cards · 3 densities" w={780}>
      <SubH>Compact</SubH>
      <div style={{ background: "var(--bg-0)", padding: 12, borderRadius: 8, marginBottom: 22 }}>
        <window.ArticleCard article={a} density="compact" clusterMode="list" onClick={() => {}} onBookmark={() => {}} onHide={() => {}} onShare={() => {}}/>
        <window.ArticleCard article={D2.ARTICLES[1]} density="compact" clusterMode="list" onClick={() => {}} onBookmark={() => {}} onHide={() => {}} onShare={() => {}}/>
      </div>
      <SubH>Comfortable</SubH>
      <div style={{ background: "var(--bg-0)", padding: 12, borderRadius: 8, marginBottom: 22 }}>
        <window.ArticleCard article={a} density="comfortable" clusterMode="cluster" onClick={() => {}} onBookmark={() => {}} onHide={() => {}} onShare={() => {}}/>
      </div>
      <SubH>Large</SubH>
      <div style={{ background: "var(--bg-0)", padding: 12, borderRadius: 8 }}>
        <window.ArticleCard article={D2.ARTICLES[2]} density="large" clusterMode="list" onClick={() => {}} onBookmark={() => {}} onHide={() => {}} onShare={() => {}}/>
      </div>
    </Section>
  );
};

const StatesCard = () => (
  <Section title="States · Empty / loading / error" w={780}>
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
      <div style={{ background: "var(--bg-0)", borderRadius: 8, padding: 8 }}>
        <window.EmptyState kind="no-results" onAction={() => {}}/>
      </div>
      <div style={{ background: "var(--bg-0)", borderRadius: 8, padding: 8 }}>
        <window.EmptyState kind="offline" onAction={() => {}}/>
      </div>
    </div>
    <hr className="hr" style={{ margin: "22px 0" }}/>
    <SubH>Skeleton loaders</SubH>
    <div style={{ background: "var(--bg-0)", padding: 12, borderRadius: 8 }}>
      <window.SkeletonCard density="comfortable"/>
      <window.SkeletonCard density="comfortable"/>
    </div>
  </Section>
);

const LiveCard = () => (
  <Section title="Live race banner" w={520}>
    <window.LiveBanner onClick={() => {}}/>
  </Section>
);

const App2 = () => (
  <window.DesignCanvas>
    <window.DCSection id="tokens" title="Design tokens" subtitle="Color, type, spacing, radii, shadows">
      <window.DCArtboard id="colors" label="Colors" width={780} height={1240}><div style={{ background: "var(--bg-0)", padding: 24, height: "100%" }}><ColorsCard/></div></window.DCArtboard>
      <window.DCArtboard id="type" label="Typography" width={780} height={920}><div style={{ background: "var(--bg-0)", padding: 24, height: "100%" }}><TypeCard/></div></window.DCArtboard>
      <window.DCArtboard id="space" label="Spacing · Radius · Shadows" width={580} height={920}><div style={{ background: "var(--bg-0)", padding: 24, height: "100%" }}><SpacingCard/></div></window.DCArtboard>
    </window.DCSection>
    <window.DCSection id="components" title="Components" subtitle="Cards, chips, live banner, states">
      <window.DCArtboard id="cards" label="Article cards" width={840} height={920}><div style={{ background: "var(--bg-0)", padding: 24, height: "100%" }}><CardsCard/></div></window.DCArtboard>
      <window.DCArtboard id="chips" label="Chips & filters" width={580} height={520}><div style={{ background: "var(--bg-0)", padding: 24, height: "100%" }}><ChipsCard/></div></window.DCArtboard>
      <window.DCArtboard id="live" label="Live banner" width={580} height={520}><div style={{ background: "var(--bg-0)", padding: 24, height: "100%" }}><LiveCard/></div></window.DCArtboard>
      <window.DCArtboard id="states" label="States gallery" width={840} height={620}><div style={{ background: "var(--bg-0)", padding: 24, height: "100%" }}><StatesCard/></div></window.DCArtboard>
    </window.DCSection>
  </window.DesignCanvas>
);

ReactDOM.createRoot(document.getElementById("root")).render(<App2/>);
