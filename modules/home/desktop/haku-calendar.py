"""haku-calendar: the dashboard's calendar, as standard .ics files in a vdir.

One .ics per series in DIR: the master event, plus an override for each
changed occurrence (RECURRENCE-ID). Reads go through recurring-ical-events,
writes through icalendar. Times are local; see ZONE.
"""

import argparse
import datetime as dt
import glob
import json
import os
import re
import sys
import uuid
from zoneinfo import ZoneInfo

import icalendar
import recurring_ical_events
from dateutil import parser as dateparser

PROG = "haku-calendar"
SENTINEL = ".changed"


def fail(msg):
    print(f"{PROG}: {msg}", file=sys.stderr)
    sys.exit(1)


def local_zone():
    name = os.environ.get("TZ", "").lstrip(":")
    if not name:
        try:
            name = os.path.realpath("/etc/localtime").split("zoneinfo/", 1)[1]
        except IndexError:
            name = "UTC"
    try:
        return ZoneInfo(name)
    except (KeyError, ValueError):
        return ZoneInfo("UTC")


ZONE = local_zone()


def aware(value):
    return value if value.tzinfo else value.replace(tzinfo=ZONE)


def midnight(day):
    return dt.datetime(day.year, day.month, day.day, tzinfo=ZONE)


def stamp(value):
    """Unix seconds of a DATE (its local midnight) or a DATE-TIME."""
    if isinstance(value, dt.datetime):
        return int(aware(value).timestamp())
    return int(midnight(value).timestamp())


def parse_day(text):
    word = text.strip().lower()
    today = dt.datetime.now(ZONE).date()
    if word == "today":
        return today
    if word == "tomorrow":
        return today + dt.timedelta(days=1)
    try:
        return dateparser.parse(text).date()
    except (ValueError, OverflowError):
        fail(f"can't read the date {text!r}")


def parse_moment(text):
    """A date and time such as "2026-11-24 10:00" or "tomorrow 9:00"."""
    match = re.match(r"^(today|tomorrow)\b\s*(.*)$", text.strip(), re.IGNORECASE)
    try:
        if match:
            day = parse_day(match.group(1))
            if not match.group(2):
                return midnight(day)
            clock = dateparser.parse(match.group(2)).time()
            return dt.datetime.combine(day, clock, tzinfo=ZONE)
        return aware(dateparser.parse(text))
    except (ValueError, OverflowError):
        fail(f"can't read the time {text!r}")


def parse_length(text):
    """"45m", "1h30m" or a bare number of minutes."""
    if re.fullmatch(r"\d+", text):
        return dt.timedelta(minutes=int(text))
    parts = re.findall(r"(\d+)([smhdw])", text)
    if not parts or "".join(n + u for n, u in parts) != text:
        fail(f"can't read the length {text!r}")
    units = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800}
    return dt.timedelta(seconds=sum(int(n) * units[u] for n, u in parts))


def span(comp):
    start = comp["DTSTART"].dt
    if "DTEND" in comp:
        return comp["DTEND"].dt - start
    if "DURATION" in comp:
        return comp["DURATION"].dt
    if isinstance(start, dt.datetime):
        return dt.timedelta(0)
    return dt.timedelta(days=1)


# --- files -----------------------------------------------------------------


def read_file(path):
    try:
        with open(path, "rb") as f:
            cal = icalendar.Calendar.from_ical(f.read())
    except (OSError, ValueError) as err:
        fail(f"can't read {path}: {err}")
    events = list(cal.walk("VEVENT"))
    master = next((c for c in events if "RECURRENCE-ID" not in c), None)
    overrides = [c for c in events if "RECURRENCE-ID" in c]
    return master, overrides


def load(dirpath):
    """Every series in DIR, for the recurrence engine and for lookups."""
    cal = icalendar.Calendar()
    masters, paths = {}, {}
    for path in sorted(glob.glob(os.path.join(dirpath, "*.ics"))):
        master, overrides = read_file(path)
        if master is None:
            continue
        uid = str(master["UID"])
        masters[uid] = master
        paths[uid] = path
        cal.add_component(master)
        for comp in overrides:
            cal.add_component(comp)
    return cal, masters, paths


def save(dirpath, uid, path, comps):
    cal = icalendar.Calendar()
    cal.add("prodid", "-//haku//haku-calendar//EN")
    cal.add("version", "2.0")
    for comp in comps:
        cal.add_component(comp)
    os.makedirs(dirpath, exist_ok=True)
    path = path or os.path.join(dirpath, uid + ".ics")
    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(cal.to_ical())
    os.replace(tmp, path)
    touch(dirpath)


def remove(dirpath, path):
    os.remove(path)
    touch(dirpath)


def touch(dirpath):
    # the dashboard follows this file, so it reloads after a write
    with open(os.path.join(dirpath, SENTINEL), "a"):
        os.utime(os.path.join(dirpath, SENTINEL), None)


# --- reading -------------------------------------------------------------------


def inherited(comp, master, name):
    """A field an override doesn't set comes from its series."""
    if name in comp:
        return comp[name]
    return master.get(name, "")


def row(comp, masters):
    uid = str(comp["UID"])
    master = masters.get(uid, comp)
    start = comp["DTSTART"].dt
    end = start + span(comp)
    allday = not isinstance(start, dt.datetime)
    origin = comp["RECURRENCE-ID"].dt if "RECURRENCE-ID" in comp else start

    category = ""
    cats = inherited(comp, master, "CATEGORIES") or None
    if cats is not None:
        first = cats[0] if isinstance(cats, list) else cats
        category = first.cats[0] if first.cats else ""

    rrule = master["RRULE"].to_ical().decode() if "RRULE" in master else ""
    return {
        "id": uid,
        "title": str(inherited(comp, master, "SUMMARY")),
        "description": str(inherited(comp, master, "DESCRIPTION")),
        "category": category,
        "location": str(inherited(comp, master, "LOCATION")),
        "start": start.isoformat() if allday else "",
        "end": end.isoformat() if allday else "",
        "start_ts": stamp(start),
        "end_ts": stamp(end),
        "all_day": 1 if allday else 0,
        "rrule": rrule,
        "recurring": bool(rrule),
        "occurrence": stamp(origin),
        "status": str(comp.get("STATUS", "CONFIRMED")).lower(),
        "calendar": "local",
    }


def cmd_query(args):
    cal, masters, _ = load(args.dir)
    first = midnight(parse_day(args.start))
    last = midnight(parse_day(args.to) + dt.timedelta(days=1))
    rows = [row(c, masters) for c in recurring_ical_events.of(cal).between(first, last)]
    rows.sort(key=lambda r: (r["start_ts"], r["id"]))
    print(json.dumps(rows))


# --- writing ------------------------------------------------------------------


def set_text(comp, name, value):
    if value is None:
        return
    comp.pop(name, None)
    if value:
        comp.add(name, value)


def set_categories(comp, value):
    if value is None:
        return
    comp.pop("CATEGORIES", None)
    if value:
        comp.add("CATEGORIES", [value])


def parse_start(text, allday):
    if allday:
        return parse_day(text)
    return parse_moment(text)


def parse_end(text, duration, start, allday):
    """DTEND for start. An all-day end is the last day, inclusive."""
    if duration is not None:
        length = parse_length(duration)
        if allday:
            return start + dt.timedelta(days=max(1, length.days))
        return start + length
    if text is not None:
        if allday:
            return parse_day(text) + dt.timedelta(days=1)
        return parse_moment(text)
    return start + (dt.timedelta(days=1) if allday else dt.timedelta(hours=1))


def check_order(start, end):
    if stamp(end) < stamp(start):
        fail("the end is before the start")


def cmd_add(args):
    if not args.title:
        fail("an event needs a title")
    allday = bool(args.all_day)
    start = parse_start(args.start or fail("an event needs a start"), allday)
    end = parse_end(args.end, args.duration, start, allday)
    check_order(start, end)

    uid = f"{uuid.uuid4()}@haku"
    comp = icalendar.Event()
    comp.add("uid", uid)
    comp.add("dtstamp", dt.datetime.now(dt.timezone.utc))
    comp.add("sequence", 0)
    comp.add("summary", args.title)
    comp.add("dtstart", start)
    comp.add("dtend", end)
    comp.add("status", "CONFIRMED")
    if args.rrule:
        comp.add("rrule", icalendar.prop.vRecur.from_ical(args.rrule.removeprefix("RRULE:")))
    set_categories(comp, args.category)
    set_text(comp, "LOCATION", args.location)
    set_text(comp, "DESCRIPTION", args.description)
    save(args.dir, uid, None, [comp])


def occurrence_at(master, ts):
    """The original start of the occurrence at ts, the type master uses."""
    when = dt.datetime.fromtimestamp(ts, ZONE)
    return when if isinstance(master["DTSTART"].dt, dt.datetime) else when.date()


def apply_changes(comp, args, allday):
    """Write the fields given onto comp; allday None keeps its type."""
    if args.title:
        set_text(comp, "SUMMARY", args.title)
    set_categories(comp, args.category)
    set_text(comp, "LOCATION", args.location)
    set_text(comp, "DESCRIPTION", args.description)

    start = comp["DTSTART"].dt
    length = span(comp)
    if allday is None:
        allday = not isinstance(start, dt.datetime)
    if args.start is not None:
        start = parse_start(args.start, allday)
    elif allday != (not isinstance(start, dt.datetime)):
        # switching type with no new start: keep the day, pick 09:00
        day = start if not isinstance(start, dt.datetime) else start.date()
        start = dt.datetime.combine(day, dt.time(9, 0), tzinfo=ZONE) if not allday else day
        length = None
    if args.end is not None or args.duration is not None:
        end = parse_end(args.end, args.duration, start, allday)
    elif length is None:
        end = parse_end(None, None, start, allday)
    else:
        end = start + length
    check_order(start, end)
    comp.pop("DTSTART", None)
    comp.pop("DTEND", None)
    comp.pop("DURATION", None)
    comp.add("dtstart", start)
    comp.add("dtend", end)
    comp["SEQUENCE"] = icalendar.vInt(int(comp.get("SEQUENCE", 0)) + 1)


def cmd_edit(args):
    _, masters, paths = load(args.dir)
    master = masters.get(args.uid) or fail(f"no event {args.uid}")
    path = paths[args.uid]
    _, overrides = read_file(path)
    allday = {True: True, False: False, None: None}[args.allday]

    if args.occurrence is not None:
        origin = occurrence_at(master, args.occurrence)
        target = next((o for o in overrides if stamp(o["RECURRENCE-ID"].dt) == args.occurrence), None)
        if target is None:
            # only the time; the rest falls back to the series
            target = icalendar.Event()
            target.add("uid", args.uid)
            target.add("dtstamp", dt.datetime.now(dt.timezone.utc))
            target.add("sequence", 0)
            target.add("recurrence-id", origin)
            target.add("dtstart", origin)
            target.add("dtend", origin + span(master))
            overrides.append(target)
        apply_changes(target, args, allday)
        comps = [master] + overrides
    else:
        if args.rrule is not None:
            master.pop("RRULE", None)
            if args.rrule:
                master.add("rrule", icalendar.prop.vRecur.from_ical(args.rrule.removeprefix("RRULE:")))
        apply_changes(master, args, allday)
        comps = [master] + overrides
    save(args.dir, args.uid, path, comps)


def cmd_rm(args):
    _, masters, paths = load(args.dir)
    master = masters.get(args.uid) or fail(f"no event {args.uid}")
    path = paths[args.uid]
    if args.occurrence is None or "RRULE" not in master:
        remove(args.dir, path)
        return
    _, overrides = read_file(path)
    overrides = [o for o in overrides if stamp(o["RECURRENCE-ID"].dt) != args.occurrence]
    master.add("exdate", occurrence_at(master, args.occurrence))
    save(args.dir, args.uid, path, [master] + overrides)


def flags_parser():
    parser = argparse.ArgumentParser(prog=PROG)
    parser.add_argument("--dir", required=True, help="the calendar folder (a vdir)")
    commands = parser.add_subparsers(dest="command", required=True)

    query = commands.add_parser("query", help="events from one day to another, as JSON")
    query.add_argument("--from", dest="start", required=True)
    query.add_argument("--to", required=True)
    query.add_argument("--format", default="json", choices=["json"])
    query.set_defaults(run=cmd_query)

    def fields(p):
        p.add_argument("--title")
        p.add_argument("--start")
        p.add_argument("--end")
        p.add_argument("--duration")
        p.add_argument("--category")
        p.add_argument("--location")
        p.add_argument("--description")
        p.add_argument("--rrule")

    add = commands.add_parser("add", help="a new event")
    fields(add)
    add.add_argument("--all-day", action="store_true")
    add.set_defaults(run=cmd_add)

    edit = commands.add_parser("edit", help="change an event or one occurrence")
    edit.add_argument("uid")
    fields(edit)
    when = edit.add_mutually_exclusive_group()
    when.add_argument("--all-day", dest="allday", action="store_const", const=True)
    when.add_argument("--timed", dest="allday", action="store_const", const=False)
    edit.add_argument("--occurrence", type=int)
    edit.set_defaults(run=cmd_edit, allday=None)

    rm = commands.add_parser("rm", help="delete an event or one occurrence")
    rm.add_argument("uid")
    rm.add_argument("--occurrence", type=int)
    rm.set_defaults(run=cmd_rm)
    return parser


def main():
    args = flags_parser().parse_args()
    # so the dashboard can watch the sentinel before the first write
    os.makedirs(args.dir, exist_ok=True)
    open(os.path.join(args.dir, SENTINEL), "a").close()
    args.run(args)


if __name__ == "__main__":
    main()
