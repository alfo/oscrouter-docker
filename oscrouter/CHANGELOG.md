# Changelog

## 0.3.0 — variables

Named addresses, on a tab of their own. Give an address a name once, then write
`$name` instead of the IP in any route or TCP connection.

The problem this solves is that a console or a media server tends to appear in
every route that touches it. Moving it meant editing each of those routes and
getting all of them right; now it is one edit, and the routes follow.

- Written `$name` in any address field, on either end of a route, in the
  multicast interface, or in a TCP connection.
- Routes show the name rather than the address, since that is what makes them
  readable at a glance. Hovering shows what it currently resolves to, and the
  route editor shows it under the field.
- Each variable lists how many addresses use it, so it is clear what a change
  will affect before making it.
- Renaming updates every route that refers to it.
- A route referring to a name that nothing defines is reported as an error and
  is not run, rather than being routed to a guess.

Substitution happens only on the way to the routing engine. The configuration
file keeps the names, which is the entire point of them.

The desktop OSCRouter application reads these files unchanged — it skips the
`Variable` records the same way it skips anything else it does not recognise —
but it does not write them, so saving a file there drops the definitions and
leaves the routes reporting the names as undefined.

## 0.2.2 — stops showing things twice

Two separate causes of the same symptom, both of which show up most when
something is retrying in the background — a TCP connection that cannot reach its
far end, say, since that produces a steady supply of material to duplicate.

**The log repeated itself.** Home Assistant's ingress closes connections it
considers idle, and the browser silently reopens the event stream. On every one
of those reconnections the add-on replayed its entire log history, so lines
already on screen were appended again, and again. The stream now numbers its
messages and a reconnecting browser is sent only what it missed. Restarting the
add-on is recognised as a new run, so the log still fills correctly rather than
being suppressed as already seen.

**A route could appear twice in the list.** Dragging holds on to the card being
moved, but the list is rebuilt whenever anything else re-renders it — an enable
or mute request coming back while a drag was in progress was enough. The next
movement put the held card back into a list it no longer belonged to, leaving
two copies of the same route. Worse, saving in that state could write the route
to the configuration twice.

## 0.2.1 — drag to reorder

Routes can be dragged into order by the grip at the left of each card. Order
means nothing to the routing engine, which matches on addresses rather than
position, so this is for arranging a configuration the way the person reading it
thinks about it — grouping everything for one console together, or pushing the
routes you are not sure about to the bottom.

Works with a mouse and with touch, so it is usable from a phone opening the
add-on from the Home Assistant sidebar. The grip is also a keyboard control:
focus it and use the up and down arrows. Dragging is disabled while a search is
active, since only some of the routes are on screen and there is no sensible
answer to where a dragged one should land. **Move up** and **Move down** remain
in each route's menu.

Also fixes the route header wrapping on narrow screens, where the name could be
pushed onto a line below the controls that describe it.

## 0.2.0 — a routing interface you can read

The routing table was a faithful copy of the desktop application's, which is a
twenty column spreadsheet in which the meaning of most cells depends on a
protocol chosen two cells away. **Port** meant a UDP port, an sACN universe, an
OTP system number or a MIDI port depending on the row; **Path** meant a filter
on one side and a template on the other. It is now one card per route.

**Each route says what it does.** Collapsed, a route reads as a sentence —
what arrives, an arrow, where it goes — with its own status beside it: `live`,
`no traffic`, `4m ago`, or `off`. Whether a route is actually carrying anything
was previously knowable only by watching an indicator blink at the instant a
packet passed.

**Fields are named for the protocol you picked.** Choose sACN and the field is
labelled **Universe**, with the note that universes start at 1; choose OTP and
it is **System number**, 0 to 200. Fields a protocol does not use are not shown
at all, and the ones it does use carry a line saying what they are for — that
leaving an outgoing IP blank replies to the sender, that a blank incoming
address filter routes everything.

**Notes on every route.** A free text field for why the route exists, shown on
the card. This is the one thing the file format did not carry and the desktop
application still does not: it reads these files unchanged but drops the notes
if it saves one back.

**Other things it now tells you rather than hides:**

- The multicast interface is its own field. The desktop application hides it
  inside the IP field as `group,interface`.
- Routes travelling over a defined TCP connection are marked `TCP`.
- Editing shows an **unsaved changes** bar, because edits do nothing until they
  are applied. Enable and mute still take effect immediately, except while there
  are unsaved edits, so one click cannot write a half-finished configuration.
- Problems name the route they are about, and clicking the name opens it.
- Search across names, notes, addresses and protocols.
- Duplicate, reorder and delete from a menu on each route.
- Worked examples of the `%1`, `%2` path syntax, and of the sACN, Art-Net, PSN,
  MIDI and OTP address forms, shown for the protocols that route actually uses.
- A first run offers a few starting points rather than an empty form.

## 0.1.3 — stops losing routes, and says what will not run

**Fixes data loss.** Opening a configuration containing a route the engine could
not use — an sACN route with universe 0, or any half-finished row — dropped that
route and then wrote the result back, deleting it. Routes are now kept, and the
**File** tab writes back exactly what you typed.

**Says why nothing is running.** A route can be well formed and still never
carry anything, and previously the only sign was one line in the log. Problems
now appear above the routing table with the offending row marked:

- an incoming port or universe that is not valid for its protocol, which stops
  that route running — universe 0 for sACN is the common one, since the column
  says "Port" and 0 looks unset rather than impossible
- an incoming IP of `127.0.0.1`, which accepts traffic only from Home Assistant
  itself and looks exactly like a wrong port from the sending end
- nothing runnable at all, which is why routing would not start

**Fixes a phantom route.** The settings line was also being parsed as a route,
then silently discarded for having no port.

`/api/status` now reports the running version.

## 0.1.2 — icon placement

Keeps the icon beside the title when the interface is narrow, such as on a phone
opening the add-on from the Home Assistant sidebar. Previously it wrapped onto a
line of its own.

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
