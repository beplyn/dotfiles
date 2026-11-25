# Pelican servers -> mc-router routes; wake stopped ones on join; stop them when empty
import asyncio
import json
import os
import re
import socket
import struct
import time
import urllib.request

PANEL = os.environ["PANEL_URL"].rstrip("/")
ROUTER = os.environ["ROUTER_URL"].rstrip("/")
SUFFIX = os.environ["ROUTE_SUFFIX"]
WAKER_OFFSET = int(os.environ["WAKER_OFFSET"])
GAME_HOST = os.environ.get("GAME_HOST", "127.0.0.1")  # where docker publishes game ports
IDLE = int(os.environ["IDLE_SECONDS"])
CREDS = os.environ["CREDENTIALS_DIRECTORY"]
with open(os.path.join(CREDS, "api-token")) as f:
    TOKEN = f.read().strip()

wakers = {}       # waker port -> server identifier
listeners = []
last_active = {}  # identifier -> last time a player or a join was seen
last_checked = {}
last_start = {}


def call(base, method, path, body=None, auth=False):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    if auth:
        headers["Authorization"] = "Bearer " + TOKEN
    req = urllib.request.Request(base + path, data=data, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=15) as r:
        raw = r.read()
    return json.loads(raw) if raw else {}


def panel(method, path, body=None):
    return call(PANEL, method, "/api/client" + path, body, auth=True)


def router(method, path, body=None):
    return call(ROUTER, method, path, body)


def slug(name, ident):
    s = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return s or ident


def servers():
    found = {}
    used = set()
    for item in panel("GET", "?type=admin-all")["data"]:
        a = item["attributes"]
        ident = a["identifier"]
        allocs = panel("GET", f"/servers/{ident}")["attributes"]["relationships"]["allocations"]["data"]
        alloc = next((x["attributes"] for x in allocs if x["attributes"].get("is_default")), None)
        if alloc is None and allocs:
            alloc = allocs[0]["attributes"]
        if alloc is None:
            continue
        label = slug(a["name"], ident)
        if label in used:
            label = ident
        used.add(label)
        state = panel("GET", f"/servers/{ident}/resources")["attributes"]["current_state"]
        found[ident] = {"label": label, "ip": alloc["ip"], "port": alloc["port"], "state": state}
    return found


async def ensure_waker(ident, port):
    if port in wakers:
        return
    wakers[port] = ident
    # kept in a list so the listeners outlive this call
    listeners.append(await asyncio.start_server(
        lambda r, w, p=port: handle(r, w, p), "127.0.0.1", port + WAKER_OFFSET))


async def start_if_offline(ident, state):
    if state != "offline" or time.time() - last_start.get(ident, 0) < 60:
        return
    last_start[ident] = time.time()
    await asyncio.to_thread(panel, "POST", f"/servers/{ident}/power", {"signal": "start"})


async def handle(reader, writer, port):
    # a player hit a stopped server: boot it, hold the connection, then pipe it through
    ident = wakers[port]
    last_active[ident] = time.time()
    try:
        state = (await asyncio.to_thread(panel, "GET", f"/servers/{ident}/resources"))["attributes"]["current_state"]
        await start_if_offline(ident, state)
        deadline = time.time() + 180
        while True:
            try:
                br, bw = await asyncio.open_connection("127.0.0.1", port)
                break
            except OSError:
                if time.time() > deadline:
                    writer.close()
                    return
                await asyncio.sleep(1)
        await asyncio.gather(pipe(reader, bw), pipe(br, writer))
    except OSError:
        writer.close()


async def pipe(src, dst):
    try:
        while data := await src.read(65536):
            dst.write(data)
            await dst.drain()
    except OSError:
        pass
    finally:
        dst.close()


def read_varint(s):
    n = shift = 0
    while True:
        b = recv(s, 1)[0]
        n |= (b & 0x7F) << shift
        if not b & 0x80:
            return n
        shift += 7


def recv(s, n):
    buf = b""
    while len(buf) < n:
        chunk = s.recv(n - len(buf))
        if not chunk:
            raise OSError("closed")
        buf += chunk
    return buf


def varint(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        if not n:
            return out + bytes([b])
        out += bytes([b | 0x80])


def players(port):
    # server list ping: the count of online players, None if it can't be read
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=5) as s:
            host = b"localhost"
            hs = b"".join([b"\x00", varint(765), varint(len(host)), host,
                           struct.pack(">H", port), varint(1)])
            s.sendall(varint(len(hs)) + hs + varint(1) + b"\x00")
            recv_len = read_varint(s)
            pkt = recv(s, recv_len)
            i, n, shift = 1, 0, 0
            while True:
                b = pkt[i]
                i += 1
                n |= (b & 0x7F) << shift
                if not b & 0x80:
                    break
                shift += 7
            return json.loads(pkt[i:i + n])["players"]["online"]
    except (OSError, ValueError, KeyError, IndexError):
        return None


async def sync_routes(found):
    want = {}
    for ident, s in found.items():
        host = f"{s['label']}.{SUFFIX}"
        port = s["port"]
        await ensure_waker(ident, port)
        # only a running server gets its real port; anything else goes to the waker
        ip = s["ip"] if s["ip"] != "0.0.0.0" else GAME_HOST
        want[host] = f"{ip}:{port}" if s["state"] == "running" else f"127.0.0.1:{port + WAKER_OFFSET}"
    current = await asyncio.to_thread(router, "GET", "/routes")
    for host in current:
        if host.endswith("." + SUFFIX) and host not in want:
            await asyncio.to_thread(router, "DELETE", f"/routes/{host}")
    for host, backend in want.items():
        if (current.get(host) or {}).get("backend") != backend:
            await asyncio.to_thread(router, "POST", "/routes",
                                    {"serverAddress": host, "backend": backend})


async def idle(found):
    now = time.time()
    for ident, s in found.items():
        if s["state"] != "running":
            last_active.pop(ident, None)
            continue
        last_active.setdefault(ident, now)
        if now - last_checked.get(ident, 0) < 60:
            continue
        last_checked[ident] = now
        n = await asyncio.to_thread(players, s["port"])
        if n is None:
            continue
        if n:
            last_active[ident] = now
        elif now - last_active[ident] >= IDLE:
            print(f"idle {s['label']}: stopping", flush=True)
            await asyncio.to_thread(panel, "POST", f"/servers/{ident}/power", {"signal": "stop"})
            last_active.pop(ident, None)


async def main():
    while True:
        try:
            found = await asyncio.to_thread(servers)
            await sync_routes(found)
            await idle(found)
        except Exception as e:  # keep looping; Panel or the router may be restarting
            print("sync failed:", e, flush=True)
        await asyncio.sleep(15)


if __name__ == "__main__":
    asyncio.run(main())
