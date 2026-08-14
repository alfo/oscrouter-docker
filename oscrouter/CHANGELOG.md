# Changelog

## 0.1.1 — prebuilt images

Installing no longer compiles OSCRouter on your machine. The add-on now pulls a
prebuilt image from GitHub Container Registry, built for `amd64` and `aarch64`,
which turns an install on a Raspberry Pi from the better part of an hour into a
download.

To go back to building from source on the machine, delete the `image:` line from
`config.yaml`.

Also adds the OSCRouter icon, in the add-on listing and in the web interface.

## 0.1.0 — first pre-release

First packaged version. **Not yet run on a live Home Assistant install**, so
treat it as experimental and expect to read the add-on log if something does not
come up.

Runs [ETC Labs OSCRouter](https://github.com/ETCLabs/OSCRouter) headless, with a
web interface in place of its desktop UI.

- Routing table with per-row enable and mute, live per-endpoint activity
  indicators, TCP connections, settings, and a streaming log.
- Reads and writes the same `.osc.txt` files as the desktop application, so
  configurations move between the two.
- Served through ingress, so it sits behind Home Assistant's own login. Only the
  Supervisor proxy at 172.30.32.2 may reach it. `direct_port` optionally exposes
  it on a plain port with no authentication; off by default.
- Runs on the host network, which sACN, Art-Net, PSN and OTP require — they are
  multicast and do not survive Docker's bridge network.
- The routing log is echoed to the add-on log as well as the browser.

Known limitations:

- MIDI is compiled in but unusable without `/dev/snd` mapped through, which this
  add-on does not request.
- The routing ports are bound on the Home Assistant host itself, so they must
  not collide with anything else running there.

Building this the first time compiles OSCRouter from source and takes a while,
noticeably longer on a Raspberry Pi than on an Intel machine.
