# OSCRouter

Routes show control traffic between OSC, sACN, Art-Net, PosiStageNet, OTP and
MIDI, with routes you edit from the Home Assistant sidebar.

This wraps [ETC Labs OSCRouter](https://github.com/ETCLabs/OSCRouter), which is
community software rather than an official ETC product.

> **Pre-release.** It installs and runs on a live Home Assistant, but it has not
> been through a real show. If it misbehaves, the add-on log is the place to
> look — the routing engine writes there as well as to the browser.

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. From the ⋮ menu choose **Repositories**, and add the URL of this repository.
3. Install **OSCRouter**, then **Start** it.
4. Open it from the sidebar.

Installing pulls a prebuilt image for your architecture, so it takes about as
long as any other add-on.

To build from source on the machine instead — because you have changed
something, or want to run your own fork — delete the `image:` line from
`config.yaml`. The build then clones `SOURCE_REPO` from `build.yaml`, which has
to be a repository laid out like this one, with OSCRouter and EosSyncLib as
submodules under `src/`; upstream ETC Labs builds for macOS and Windows only and
will not compile here. Expect that to take a while, and considerably longer on a
Raspberry Pi than on an Intel box.

## Configuration

| Option | Default | Meaning |
| --- | --- | --- |
| `config_file` | `oscrouter.osc.txt` | Routing file inside the add-on's config directory |
| `reconnect_delay` | `5000` | Milliseconds before retrying a failed connection |
| `direct_port` | `0` | Also serve the interface on this port, bypassing ingress. `0` disables it |

The routing file lives in the add-on's own configuration directory, so it
survives updates and can be opened with the File Editor add-on. It is the same
`.osc.txt` format the desktop OSCRouter reads, so a configuration built on a
laptop can be pasted in through the **File** tab.

### About `direct_port`

Ingress puts the interface behind Home Assistant's own login. `direct_port`
does not: **anyone who can reach that port can change your routing**, with no
authentication at all. Turn it on only if you need to reach OSCRouter from a
device that cannot go through Home Assistant, and only on a trusted network.

## Networking

The add-on runs with `host_network`, which it has to. sACN, Art-Net, PSN and OTP
are multicast and broadcast protocols and do not work across Docker's bridge
network. It also means the ports in your routing table are bound directly on the
Home Assistant host, so they must not collide with anything else running there.

Port 8099 is used for the web interface.

## Usage

The **Routes** tab is one card per route. Collapsed, a card reads as what
arrives, an arrow, and where it goes. Click it to edit.

- The **grip** at the left drags a route into a different position, by mouse or
  by touch; with it focused, the up and down arrow keys do the same. Order means
  nothing to the routing engine — it matches on addresses, not position — so
  this is purely for arranging things the way you think about them.
- The **tick** enables the route. Changing it rebuilds the routing engine.
- **Mute** silences the destination without restarting anything.
- The chip on the right says whether the route is carrying anything: `live`,
  how long ago it last did, `no traffic` since the router started, or `off`.
- The dots beside each end show connection state — grey for uninitialised, amber
  connecting, green running, red failed — and flash white as packets pass.
- Fields are named for the protocol you choose. The same field is the **Port**
  for OSC, the **Universe** for sACN and Art-Net, and the **System number** for
  OTP; fields a protocol does not use are hidden.
- **Notes** is free text for why the route exists. It is saved with the
  configuration, and is the one thing the desktop application does not keep.
- **Value range** scales or clips numeric arguments; leave it alone to pass
  values through untouched.
- **Use a script instead** attaches JavaScript to a route, for rewrites the
  path syntax cannot express.
- **How addresses and levels are written** has worked examples of the `%1`,
  `%2` syntax for the protocols that route uses.

## Variables

The **Variables** tab holds named addresses. Give the address of a console, a
media server or a lighting desk a name once, then write `$name` instead of the
IP in any route or TCP connection.

The point is what happens when something moves. A desk that appears in eight
routes is one edit here rather than eight edits spread across the routing list,
with no chance of missing one. Renaming a variable updates the routes that refer
to it, and each row shows how many addresses are using it.

Routes show the name rather than the address, since that is what makes them
readable; hover to see what it currently resolves to. A route referring to a
name that no longer exists is reported as an error and is not run — nothing is
routed to a guess.

**Save & Apply** writes the file and restarts routing. Edits do nothing until
you do, which is what the amber bar at the top is telling you. Enable and mute
are the exception and take effect at once — unless there are unsaved edits, in
which case they wait for the save too.

The log at the bottom streams from the routing engine as it runs, which is the
quickest way to tell whether packets are arriving at all and what they contain.

## Troubleshooting

**Nothing routes.** Check the log for `UDP IN` lines. If none appear, the
packets are not reaching the host — check the source device's destination
address, and that the port is not taken by something else on the host.

**Nothing arrives from other machines, but the route looks right.** Check the
incoming **IP**. Set to `127.0.0.1` it accepts only what is sent from Home
Assistant itself, so a console or laptop elsewhere on the network cannot reach
it however correct the port is. Leave it **empty** to listen on every interface,
which is usually what you want, or set it to the Home Assistant host's own LAN
address to listen on just that one.

**sACN or Art-Net see nothing.** Set the interface explicitly in **Settings**
rather than leaving it on default; a Home Assistant host with several interfaces
may otherwise pick the wrong one.

**MIDI devices do not appear.** MIDI needs `/dev/snd` mapped into the add-on,
which this add-on does not request. It is rarely useful on a Home Assistant
host, so it is unsupported here.
