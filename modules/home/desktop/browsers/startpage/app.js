// services: [{ category, services: [{ name, host, url, tags, icon }] }]
// filled from beacon's nginx hosts by default.nix
const SERVICES = @services@;

// 24x24 stroke icons, keyed by SERVICES[].icon
const ICONS =
{
  film: '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M7 3v18M17 3v18M3 8h4M3 16h4M17 8h4M17 16h4M7 12h10"/>',
  music: '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
  image: '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-5-5L5 21"/>',
  headphones: '<path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1v-6h3zM3 19a2 2 0 0 0 2 2h1v-6H3z"/>',
  notebook: '<path d="M5 4a2 2 0 0 1 2-2h12v20H7a2 2 0 0 1-2-2z"/><path d="M9 7h6M9 11h6M3 6h4M3 10h4M3 14h4"/>',
  check: '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="m8 12 3 3 5-6"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',
  rss: '<path d="M4 11a9 9 0 0 1 9 9M4 4a16 16 0 0 1 16 16"/><circle cx="5" cy="19" r="1"/>',
  bookmark: '<path d="m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>',
  utensils: '<path d="M3 2v7a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2V2M7 2v20M21 15V2a5 5 0 0 0-5 5v6a2 2 0 0 0 2 2h3zm0 0v7"/>',
  card: '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20M6 15h4"/>',
  file: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/>',
  filetext: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h5"/>',
  folder: '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
  sync: '<path d="M21 12a9 9 0 0 1-15.5 6.2L3 16M3 12a9 9 0 0 1 15.5-6.2L21 8"/><path d="M21 3v5h-5M3 21v-5h5"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  shapes: '<rect x="3" y="3" width="8" height="8" rx="1"/><circle cx="17" cy="17" r="4"/><path d="M17.5 3 21 9h-7z"/>',
  clipboard: '<rect x="8" y="2" width="8" height="4" rx="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>',
  workflow: '<rect x="3" y="3" width="6" height="6" rx="1"/><rect x="15" y="15" width="6" height="6" rx="1"/><path d="M9 6h4a2 2 0 0 1 2 2v7"/>',
  eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  git: '<circle cx="6" cy="5" r="2"/><circle cx="6" cy="19" r="2"/><circle cx="18" cy="7" r="2"/><path d="M6 7v10M18 9a6 6 0 0 1-6 6H8"/>',
  lock: '<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
  terminal: '<rect x="2" y="3" width="20" height="18" rx="2"/><path d="m6 9 3 3-3 3M12 15h6"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/>',
  grid: '<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/>',
  activity: '<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
  chart: '<path d="M3 3v18h18"/><path d="m7 15 4-4 3 3 5-6"/>',
  disk: '<rect x="2" y="13" width="20" height="8" rx="2"/><path d="M5.5 5.5 2 13h20l-3.5-7.5A2 2 0 0 0 16.7 4H7.3a2 2 0 0 0-1.8 1.5zM6 17h.01M10 17h.01"/>',
  idcard: '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="11" r="2"/><path d="M6 16a3 3 0 0 1 6 0M15 10h3M15 14h3"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
};

const $ = (id) => document.getElementById(id);
const input = $("q");
const panesEl = $("panes");
const modeEl = $("mode");

// fuzzy: query chars in order; consecutive and word-start hits score more
const isWordStart = (text, i) => i === 0 || /[\s\-_./:]/.test(text[i - 1]);

function fuzzy(query, text)
{
  const t = text.toLowerCase();
  let best = null;
  // try each start of the first char, greedy after it
  for (let start = t.indexOf(query[0]); start !== -1; start = t.indexOf(query[0], start + 1))
  {
    const positions = [start];
    let score = isWordStart(t, start) ? 10 : 1;
    let last = start;
    for (let qi = 1; qi < query.length; qi++)
    {
      const i = t.indexOf(query[qi], last + 1);
      if (i === -1)
      {
        score = -1;
        break;
      }
      if (i === last + 1) score += 8;
      else if (isWordStart(t, i)) score += 6;
      else score += 1 - Math.min(i - last, 10) / 10;
      positions.push(i);
      last = i;
    }
    if (score < 0) continue;
    // the whole query as one run
    if (last - start === query.length - 1) score += 4 * query.length;
    score -= start / 10;
    if (!best || score > best.score) best = { score, positions };
  }
  return best;
}

// name and host carry highlights; category, tags and url only rank
function match(query, s, category)
{
  const name = fuzzy(query, s.name);
  const host = fuzzy(query, s.host);
  const rest = [category, s.url, ...s.tags].map((x) => fuzzy(query, x)).filter(Boolean);
  const scores =
  [
    name && name.score * 1.25,
    host && host.score * 1.1,
    ...rest.map((r) => r.score),
  ].filter((x) => x !== null && x !== undefined && x !== false);
  if (!scores.length) return null;
  return { score: Math.max(...scores), name: name ? name.positions : [], host: host ? host.positions : [] };
}

function highlight(el, text, positions)
{
  el.textContent = "";
  const set = new Set(positions);
  let run = "";
  let marked = false;
  const flush = () =>
  {
    if (!run) return;
    if (marked)
    {
      const m = document.createElement("mark");
      m.textContent = run;
      el.append(m);
    }
    else el.append(run);
    run = "";
  };
  [...text].forEach((ch, i) =>
  {
    if (set.has(i) !== marked)
    {
      flush();
      marked = set.has(i);
    }
    run += ch;
  });
  flush();
}

// build panes
const panes = SERVICES.map((group, gi) =>
{
  const fieldset = document.createElement("fieldset");
  fieldset.className = "pane";
  const legend = document.createElement("legend");
  legend.innerHTML = gi < 9 ? `<span class="index">[${gi + 1}]</span> ` : "";
  legend.append(group.category);
  fieldset.append(legend);

  const rows = group.services.map((s) =>
  {
    const a = document.createElement("a");
    a.className = "row";
    a.href = s.url;
    a.title = s.url;
    a.innerHTML =
      '<span class="cursor">&gt;</span>' +
      `<span class="icon"><svg viewBox="0 0 24 24" aria-hidden="true">${ICONS[s.icon] || ICONS.globe}</svg></span>` +
      '<span class="name"></span><span class="host"></span>';
    const row = { s, category: group.category, el: a, nameEl: a.children[2], hostEl: a.children[3] };
    row.nameEl.textContent = s.name;
    row.hostEl.textContent = s.host;
    a.addEventListener("mouseenter", () => setActive(visible.indexOf(row)));
    fieldset.append(a);
    return row;
  });

  panesEl.append(fieldset);
  return { el: fieldset, rows };
});

const all = panes.flatMap((p) => p.rows);
let visible = all.slice();
let active = 0;

function setActive(i)
{
  if (i < 0 || !visible.length) return;
  visible.forEach((r) => r.el.classList.remove("active"));
  active = Math.min(i, visible.length - 1);
  const r = visible[active];
  r.el.classList.add("active");
  r.el.scrollIntoView({ block: "nearest" });
}

function filter()
{
  const q = input.value.trim().toLowerCase().replace(/\s+/g, "");
  let best = null;

  panes.forEach((p) =>
  {
    const ranked = p.rows
      .map((r) => ({ r, m: q ? match(q, r.s, r.category) : { score: 0, name: [], host: [] } }))
      .filter((x) => x.m);
    ranked.sort((a, b) => b.m.score - a.m.score);

    p.rows.forEach((r) => (r.el.hidden = true));
    ranked.forEach(({ r, m }) =>
    {
      r.el.hidden = false;
      highlight(r.nameEl, r.s.name, m.name);
      highlight(r.hostEl, r.s.host, m.host);
      // best matches first within the pane
      p.el.append(r.el);
      if (!best || m.score > best.m.score) best = { r, m };
    });
    p.el.hidden = ranked.length === 0;
  });

  visible = panes.flatMap((p) => [...p.el.querySelectorAll(".row:not([hidden])")])
    .map((el) => all.find((r) => r.el === el));
  $("empty").hidden = visible.length > 0;
  $("count").textContent = `${visible.length}/${all.length}`;
  visible.length ? setActive(q && best ? visible.indexOf(best.r) : 0) : all.forEach((r) => r.el.classList.remove("active"));
}

function launch(newTab)
{
  const r = visible[active];
  if (!r) return;
  if (newTab) window.open(r.s.url, "_blank");
  else location.href = r.s.url;
}

function setMode()
{
  const search = document.activeElement === input;
  modeEl.textContent = search ? "SEARCH" : "NORMAL";
  modeEl.classList.toggle("search", search);
}

function clear()
{
  input.value = "";
  input.blur();
  filter();
  setActive(0);
}

input.addEventListener("input", filter);
input.addEventListener("focus", setMode);
input.addEventListener("blur", setMode);

document.addEventListener("keydown", (e) =>
{
  const typing = document.activeElement === input;
  const mod = e.ctrlKey || e.metaKey;

  if (mod && e.key.toLowerCase() === "k")
  {
    e.preventDefault();
    input.focus();
    input.select();
  }
  else if (e.key === "Enter")
  {
    e.preventDefault();
    launch(mod);
  }
  else if (e.key === "Escape")
  {
    e.preventDefault();
    clear();
  }
  else if (e.key === "ArrowDown" || e.key === "ArrowUp")
  {
    e.preventDefault();
    setActive(Math.max(0, active + (e.key === "ArrowDown" ? 1 : -1)));
  }
  else if (typing || mod || e.altKey)
  {
    // typing and browser shortcuts pass through
  }
  else if (e.key === "/")
  {
    e.preventDefault();
    input.focus();
  }
  else if (e.key === "j" || e.key === "k")
  {
    e.preventDefault();
    setActive(Math.max(0, active + (e.key === "j" ? 1 : -1)));
  }
  else if (/^[1-9]$/.test(e.key))
  {
    e.preventDefault();
    const pane = panes[Number(e.key) - 1];
    const el = pane && !pane.el.hidden && pane.el.querySelector(".row:not([hidden])");
    if (el) setActive(visible.findIndex((r) => r.el === el));
  }
  else if (e.key.length === 1 && e.key !== " ")
  {
    // any other letter starts a filter
    e.preventDefault();
    input.focus();
    input.value += e.key;
    filter();
  }
});

// clock
function tick()
{
  $("clock").textContent = new Date().toLocaleTimeString([], { hour12: false });
}
tick();
setInterval(tick, 1000);

filter();
setMode();
