# word slugs for shlink: picks /calm-otter and asks shlink to use it. Stdlib only.
import html
import json
import os
import random
import threading
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SHLINK = os.environ["SHLINK_URL"].rstrip("/")
API_KEY = os.environ["API_KEY"]
MAX_URL = 2048
TRIES = 20

ADJECTIVES = """
amber azure bold bright brave breezy bronze calm candid cheery cosmic cozy crisp daring dapper
dusty eager electric fair fancy fluffy frosty funny gentle gilded glad golden grand green
happy hardy honest humble icy ivory jade jazzy jolly keen kind lively lofty lucky lunar
mellow merry mighty misty modest nifty nimble noble olive pale perky plucky plush polite
pretty proud quick quiet rapid royal ruby rustic salty sandy scarlet sharp shiny silent
silver sleek smart snowy solid spry stellar steady stout sturdy sunlit sunny swift tender
tidy tiny tranquil true urban velvet vivid warm wild windy wise witty young zany zesty
""".split()

NOUNS = """
acorn anchor aurora badger beacon bear breeze bridge canyon castle cedar cloud comet compass
crane dolphin dune ember falcon feather finch forest fox garden gecko glacier grove harbor
harvest heron hollow ibis island jasmine kettle lagoon lantern lemon lemur lynx mango maple
meadow meteor mirror moose mountain oasis orbit orchid otter owl panda pebble pillow pine
planet prairie puffin quartz rainbow raven ridge river robin sparrow stone summit swan tiger
tulip tundra turtle valley violet walrus whale willow wolf zebra zephyr
""".split()

rng = random.SystemRandom()
# one request at a time, so two people can't race for the same slug
lock = threading.Lock()


def candidate(words):
    head = [rng.choice(ADJECTIVES) for _ in range(words - 1)]
    return "-".join(head + [rng.choice(NOUNS)])


def shlink_create(url, slug):
    """Returns the short URL, or None when the slug is already taken."""
    body = json.dumps({"longUrl": url, "customSlug": slug}).encode()
    req = urllib.request.Request(
        f"{SHLINK}/short-urls",
        data=body,
        method="POST",
        headers={"X-Api-Key": API_KEY, "Content-Type": "application/json", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.load(resp)["shortUrl"]
    except urllib.error.HTTPError as e:
        if e.code == 400 and "non-unique-slug" in e.read().decode("utf-8", "replace"):
            return None
        raise


def make_link(url):
    # two words first; a third once the two-word names run out
    words = 2
    with lock:
        while True:
            for _ in range(TRIES):
                short = shlink_create(url, candidate(words))
                if short:
                    return short
            words += 1


def valid_url(url):
    if len(url) > MAX_URL:
        return False
    parts = urllib.parse.urlsplit(url)
    return parts.scheme in ("http", "https") and bool(parts.netloc)


def page(notice=""):
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>short</title>
<style>
:root {{ color-scheme: light dark; --fg: #1d1d1f; --bg: #fafafa; }}
@media (prefers-color-scheme: dark) {{ :root {{ --fg: #eee; --bg: #161618; }} }}
body {{ font: 16px/1.4 system-ui, sans-serif; background: var(--bg); color: var(--fg);
  margin: 0 auto; max-width: 40rem; padding: 1rem; }}
input {{ font: inherit; width: 100%; box-sizing: border-box; padding: .5rem; }}
button {{ font: inherit; margin-top: .5rem; padding: .5rem 1rem; }}
a {{ word-break: break-all; }}
</style></head>
<body>
<h1>short</h1>
<form method="post" action="/">
<input type="url" name="url" placeholder="https://example.com/long/path" required autofocus>
<button type="submit">shorten</button>
</form>
{notice}
</body></html>"""


class Handler(BaseHTTPRequestHandler):
    def send_html(self, code, text):
        data = text.encode()
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if urllib.parse.urlsplit(self.path).path != "/":
            return self.send_html(404, page("<p>no such page</p>"))
        self.send_html(200, page())

    def do_POST(self):
        # tinyauth sets Remote-User on this host only after a login
        if self.path != "/" or not self.headers.get("Remote-User"):
            return self.send_html(403, page("<p>log in to make links</p>"))
        length = min(int(self.headers.get("Content-Length") or 0), 8192)
        form = urllib.parse.parse_qs(self.rfile.read(length).decode("utf-8", "replace"))
        url = (form.get("url") or [""])[0].strip()
        if not valid_url(url):
            return self.send_html(400, page("<p>that is not an http or https link</p>"))
        try:
            short = make_link(url)
        except (urllib.error.URLError, OSError, KeyError, ValueError):
            return self.send_html(502, page("<p>shlink did not answer, try again</p>"))
        link = html.escape(short)
        self.send_html(200, page(f'<p>made: <a href="{link}">{link}</a></p>'))

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
