// type to filter services; Enter opens the selected one, else searches Startpage
const $ = (id) => document.getElementById(id);
const form = $("search");
const input = $("q");
const hint = $("hint");
const groups = $("groups");

// clock
const greet = (h) => (h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening");
function tick()
{
  const now = new Date();
  $("clock").textContent = now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false });
  $("date").textContent = now.toLocaleDateString([], { weekday: "long", day: "numeric", month: "long" });
  $("greeting").textContent = greet(now.getHours());
}
tick();
setInterval(tick, 1000);

// cards
const cards = SERVICES
  .slice()
  .sort((a, b) => a.name.localeCompare(b.name))
  .map((s) =>
  {
    const a = document.createElement("a");
    a.className = "card";
    a.href = s.url;
    a.title = s.url.replace("https://", "");

    const icon = document.createElement("span");
    icon.className = "icon";
    if (s.icon)
    {
      const img = document.createElement("img");
      img.src = s.icon;
      img.alt = "";
      icon.append(img);
    }
    else
    {
      icon.classList.add("letter");
      icon.textContent = s.name[0].toUpperCase();
    }

    const label = document.createElement("span");
    label.className = "label";
    label.innerHTML = '<span class="name"></span><span class="desc"></span>';
    label.firstChild.textContent = s.name;
    label.lastChild.textContent = s.desc || s.host;

    a.append(icon, label);
    return { s, el: a, text: [s.name, s.desc, s.host].join(" ").toLowerCase() };
  });

const sections = GROUPS.map((name) =>
{
  const members = cards.filter((c) => c.s.group === name);
  const section = document.createElement("section");
  section.className = "group";
  section.innerHTML = "<h2></h2>";
  section.firstChild.textContent = name;
  const grid = document.createElement("div");
  grid.className = "grid";
  members.forEach((c) => grid.append(c.el));
  section.append(grid);
  if (members.length) groups.append(section);
  return { section, members };
});

// filtering
const onPage = sections.flatMap((g) => g.members);
let matches = [];
let selected = -1;

function score(c, q)
{
  const name = c.s.name.toLowerCase();
  if (name.startsWith(q)) return 0;
  if (c.s.host.startsWith(q)) return 1;
  if (name.includes(q)) return 2;
  return c.text.includes(q) ? 3 : -1;
}

function select(i)
{
  matches.forEach((c) => c.el.classList.remove("selected"));
  selected = matches.length ? (i + matches.length) % matches.length : -1;
  const c = matches[selected];
  if (c)
  {
    c.el.classList.add("selected");
    c.el.scrollIntoView({ block: "nearest" });
  }
  showHint();
}

function showHint()
{
  const q = input.value.trim();
  const c = matches[selected];
  if (!q) hint.textContent = "";
  else if (c) hint.innerHTML = "↵ open <b></b> · ⇧↵ search Startpage · ↑↓ pick";
  else hint.innerHTML = "↵ search Startpage for <b></b>";
  const b = hint.querySelector("b");
  if (b) b.textContent = c ? c.s.name : q;
}

function filter()
{
  const q = input.value.trim().toLowerCase();
  const ranked = cards
    .map((c) => ({ c, r: q ? score(c, q) : 0 }))
    .filter((x) => x.r >= 0);
  cards.forEach((c) => (c.el.hidden = !ranked.some((x) => x.c === c)));
  sections.forEach((g) => (g.section.hidden = g.members.every((c) => c.el.hidden)));

  // best first, then page order
  matches = q ? ranked.sort((a, b) => a.r - b.r || onPage.indexOf(a.c) - onPage.indexOf(b.c)).map((x) => x.c) : [];
  select(0);
}

input.addEventListener("input", filter);

input.addEventListener("keydown", (e) =>
{
  if (e.key === "ArrowDown" || e.key === "ArrowUp")
  {
    e.preventDefault();
    select(selected + (e.key === "ArrowDown" ? 1 : -1));
  }
  else if (e.key === "Escape")
  {
    input.value = "";
    filter();
  }
  else if (e.key === "Enter" && !e.shiftKey && matches[selected])
  {
    e.preventDefault();
    location.href = matches[selected].s.url;
  }
});

form.addEventListener("submit", (e) =>
{
  if (!input.value.trim()) e.preventDefault();
});

// "/" anywhere focuses the search
document.addEventListener("keydown", (e) =>
{
  if (e.key === "/" && document.activeElement !== input)
  {
    e.preventDefault();
    input.focus();
  }
});

input.focus();
