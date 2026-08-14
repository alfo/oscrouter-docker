# OSCRouter

Routes show control traffic between OSC, sACN, Art-Net, PosiStageNet, OTP and
MIDI, with a routing table you edit from the Home Assistant sidebar.

This wraps [ETC Labs OSCRouter](https://github.com/ETCLabs/OSCRouter), which is
community software rather than an official ETC product.

> **Pre-release.** The routing engine, the container and the web interface are
> tested, but this add-on has not yet been installed on a live Home Assistant.
> If it misbehaves, the add-on log is the place to look — the routing engine
> writes to it as well as to the browser.

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

The **Routing** tab is one row per route:

- **On** enables the route. Changing it rebuilds the routing engine.
- **Mute** silences the destination without restarting anything.
- The dots beside **Incoming** and **Outgoing** show connection state — grey for
  uninitialised, amber connecting, green running, red failed — and flash white
  as packets pass.
- **Min** and **Max** scale numeric arguments; leave them empty to pass values
  through untouched.
- **Script** attaches JavaScript to a route, for rewrites the path syntax cannot
  express.

**Save & Apply** writes the file and restarts routing. Edits to the table are
not live until you do.

The log at the bottom streams from the routing engine as it runs, which is the
quickest way to tell whether packets are arriving at all and what they contain.

## Troubleshooting

**Nothing routes.** Check the log for `UDP IN` lines. If none appear, the
packets are not reaching the host — check the source device's destination
address, and that the port is not taken by something else on the host.

**sACN or Art-Net see nothing.** Set the interface explicitly in **Settings**
rather than leaving it on default; a Home Assistant host with several interfaces
may otherwise pick the wrong one.

**MIDI devices do not appear.** MIDI needs `/dev/snd` mapped into the add-on,
which this add-on does not request. It is rarely useful on a Home Assistant
host, so it is unsupported here.
