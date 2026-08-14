# OSCRouter — container, web interface and Home Assistant add-on

[OSCRouter](https://github.com/ETCLabs/OSCRouter) is an ETC Labs packet router
for show control traffic: OSC, sACN, Art-Net, PosiStageNet, OTP and MIDI. It
ships as a Qt desktop application for macOS and Windows.

This repository adds three things to it:

1. **A Linux port**, since neither OSCRouter nor its EosSyncLib dependency built
   for Linux before.
2. **`oscrouterd`**, the same routing engine with no GUI, driven from a browser
   over HTTP instead of Qt Widgets.
3. **A container and a Home Assistant add-on** that wrap it.

The desktop application still builds unchanged on macOS and Windows.

## Layout

```
repository.yaml     marks this as a Home Assistant add-on repository
oscrouter/          the add-on itself: config.yaml, Dockerfile, run.sh, DOCS.md
src/OSCRouter/      submodule — fork of ETCLabs/OSCRouter, branch linux-port
src/EosSyncLib/     submodule — fork of ETCLabs/EosSyncLib, branch linux-port
Dockerfile          plain container image
```

The two sources are submodules so they keep their fork history and can still be
rebased on upstream. They sit side by side under `src/` because
`OSCRouter/CMakeLists.txt` refers to `../EosSyncLib`. They are nested a level
down rather than at the root because `OSCRouter/` and `oscrouter/` would
otherwise collide on a case-insensitive filesystem such as macOS.

## Getting the sources

```bash
git clone --recurse-submodules https://github.com/alfo/oscrouter-docker
```

If you have already cloned without that flag, `git submodule update --init`
fills them in.

## Running the container

```bash
docker build -t oscrouter .
```

```bash
docker run -d --name oscrouter --network host -v $PWD/config:/config oscrouter
```

Then open <http://localhost:8099>.

**`--network host` is not optional** if you use sACN, Art-Net, PSN or OTP. Those
are multicast and broadcast protocols; on Docker's default bridge network they
do not reach the LAN, and the failure is silent — the routes will simply never
carry anything.

## Building without Docker

Requires Qt 6 (Core, Network, Qml), CMake and ALSA headers.

```bash
cmake -S src/OSCRouter -B build -DOSCROUTER_BUILD_GUI=OFF && cmake --build build
```

`OSCROUTER_BUILD_GUI` and `OSCROUTER_BUILD_DAEMON` control which of the two
targets get built. The daemon needs neither Qt Widgets nor Qt Gui, which is what
keeps the container image small.

```bash
./build/oscrouterd --config ./oscrouter.osc.txt --port 8099
```

| Option | Meaning |
| --- | --- |
| `--config <path>` | Routing file to load and save |
| `--port <n>` | Port for the web interface (default 8099) |
| `--bind <addr>` | Address to listen on (default 0.0.0.0) |
| `--allow <addr>` | Refuse connections from any other peer |
| `--direct-port <n>` | Additional unrestricted listener; 0 disables |
| `--reconnect-delay <ms>` | Retry delay for failed connections |
| `--no-start` | Load the configuration but wait to be told to start |
| `--log-packets` | Also echo per-packet traffic to stdout (noisy) |
| `--quiet` | Do not echo the routing log to stdout |

The routing log goes to stdout as well as the browser, so `docker logs` and the
Home Assistant add-on log show what the engine is doing. Per-packet lines are
left out of stdout unless you ask for them, since they arrive at traffic rates —
the web interface shows them either way.

## The web interface

One card per route rather than the desktop application's twenty column table.
The table is faithful to the original but hard to read, because the meaning of
most cells depends on a protocol chosen two cells away: "Port" is a UDP port, an
sACN universe, an OTP system number or a MIDI port depending on the row, and
"Path" is a filter on one side and a template on the other.

So each card names its fields for the protocol actually selected — **Universe**
for sACN, **System number** for OTP — hides the fields that protocol does not
use, and explains the ones it does. Collapsed, a route reads as what arrives, an
arrow, and where it goes, with a status beside it: `live`, `no traffic`,
`4m ago`, or `off`. There is a free text note on every route, a search, an
unsaved-changes bar, drag-to-reorder that also works by touch and by keyboard,
and worked examples of the `%1`, `%2` path syntax for the protocols that route
uses.

**Variables** are named addresses, on their own tab and written `$name` wherever
an IP would go. A console that appears in eight routes is defined once, and
moving it is one edit rather than eight. They are substituted only into what the
routing engine is given — the configuration keeps the name — and renaming one
updates the routes that refer to it.

TCP connections, settings, a raw file editor and a streaming log are on their
own tabs. It reads and writes the same `.osc.txt` files as the desktop
application, so configurations move between them.

Two things in the format the desktop application does not write: the per-route
note, a nineteenth field on the route record, and the `Variable,<name>,<value>`
record. Every reader of this format stops at the last field it knows about and
skips lines it does not recognise, so the desktop application loads these files
unchanged — it just drops both if it saves one back out. A route left referring
to a name nothing defines is reported as an error rather than silently routing
somewhere unintended.

The API underneath it, should you want to drive OSCRouter from a script:

| Endpoint | Purpose |
| --- | --- |
| `GET/PUT /api/config` | Whole configuration as JSON |
| `POST /api/config/apply` | Persist and restart the routing engine |
| `GET/PUT /api/file` | The raw `.osc.txt` |
| `GET /api/status` | Run state, version, counts, and configuration issues |
| `GET /api/interfaces` | Network interfaces for the interface pickers |
| `POST /api/start`, `/api/stop` | Routing engine lifecycle |
| `POST /api/mute-all` | `{"incoming": bool, "outgoing": bool}` |
| `POST /api/routes/<i>/mute` | `{"value": bool}`, applies live |
| `POST /api/routes/<i>/enable` | `{"value": bool}`, restarts the engine |
| `GET /api/events` | Server-Sent Events: `log`, `itemStates`, `status` |

`itemStates` carries a live connection state and activity flag per route
endpoint, plus the time each last carried traffic. The flag is momentary — it is
true for the tick a packet passed and cleared on the next — so it is only good
for blinking an indicator; the timestamp is what answers "is this route doing
anything".

## Home Assistant add-on

See [`oscrouter/DOCS.md`](oscrouter/DOCS.md).

Installing pulls a prebuilt image rather than compiling on the target machine.
`.github/workflows/publish.yml` builds one image per architecture on tag push
and publishes them to GHCR as
`ghcr.io/alfo/oscrouter-{amd64,aarch64}:<version>`, where the tag matches the
`version` in `oscrouter/config.yaml` — the Supervisor pulls exactly that, so the
two are read from the same place rather than written twice. Each architecture is
built on a native runner, since emulating aarch64 to compile this much C++ is
painfully slow.

## What the Linux port involved

Both `Router.h` and EosSyncLib's `EosTcp.cpp` branch as "Windows or POSIX", so
Linux takes the existing macOS path for free. Only these needed real work:

| Area | Change |
| --- | --- |
| `EosTcp_Mac.cpp` | `SO_NOSIGPIPE` is BSD-only; feature-detected, with `MSG_NOSIGNAL` on send for Linux |
| `sACN/.../ObjectSync/Linux/interlock.cpp` | `OSAtomic*` replaced with `__atomic` builtins |
| `sACN/.../Tock/Linux/tock.cpp` | `mach_absolute_time` replaced with `clock_gettime` |
| `sACN/.../AsyncSocket/Linux/IfaceSupport.cpp` | Rewritten: `AF_PACKET`/`sockaddr_ll` instead of `AF_LINK`/`sockaddr_dl`, and `/proc/net/route` instead of the BSD routing sysctl |
| `EosPlatform.cpp` | Selected the Mac backend for every non-Windows build; now `__APPLE__` only |
| `EosTimer.cpp` | `mach_absolute_time` replaced with `clock_gettime` on Linux |
| `AsyncSocketServ_select.cpp` | `sockaddr_storage::ss_len` is BSD-only, now guarded by `HAVE_SOCKADDR_SA_LEN` |
| `otp/otp.h` | `TimestampNumber` was `uint64_t`, which is `unsigned long` on 64-bit Linux and has no `QDataStream` overload; now `quint64` |
| `Router.cpp` | `QLatin1String::toUtf8` needs Qt 6.9; the call sites were plain literals and now pass them straight through |
| Several files | `<string.h>` added, which Darwin's headers provide transitively and glibc's do not |

Everything else — the Art-Net library, OTP, PSN, RtMidi, and the rest of the
sACN stack — compiled for Linux unchanged.

Verified in the container: the sACN stack starts (which exercises the rewritten
interface enumeration, since `CAsyncSocketServ::Startup` aborts if it fails),
and an OSC → sACN → OSC round trip carries data through multicast, including
source discovery.

## What has and has not been tested

Verified: the macOS desktop build still compiles; `oscrouterd` builds and runs on
macOS and in Linux containers for both `amd64` and `aarch64`; OSC routing and
path remapping carry traffic; an OSC → sACN → OSC round trip works through
multicast; the web interface, its live log and activity indicators, and the
enable/mute controls behave and persist; ingress peer restriction and
`X-Ingress-Path` stripping work against a simulated Supervisor.

Verified on a live Home Assistant install as of v0.1.2: the Supervisor pulls the
prebuilt image and starts the add-on, the routing file persists in the add-on's
config directory, the web interface works, and `host_network` genuinely gives
the container the host's own interfaces rather than a bridge — it reports the
host NIC alongside `docker0` and `hassio`, which is what sACN, Art-Net, PSN and
OTP need.

Not yet exercised on that install: ingress specifically (it was reached through
`direct_port`), and the sACN stack, since the configuration there is OSC only.

## Known limitations

- **MIDI** compiles against ALSA but needs `/dev/snd` passed into the container
  to be of any use, which rarely makes sense on a Home Assistant host.
- **Bridge networking breaks the multicast protocols.** Use host networking.
- The add-on is built for `amd64` and `aarch64`, which is what Home Assistant
  supports for new add-ons.
