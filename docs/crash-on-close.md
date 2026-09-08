# GNOME Network Displays 0.99.0 aborts on window close

Status: upstream bug, fixed in GNOME's git, not yet in a tagged release.
Not an Omarchy or plugin bug. Diagnosed on 2026-09-08 from systemd-coredump.

## Symptom

Closing the GNOME Network Displays window ends the process with SIGABRT and a
core dump. Omarchy shows a "Process crashed: gnome-network-displays"
notification. This happens on every close of the AUR build of 0.99.0. No data
is lost: the crash happens during teardown after the window is already gone,
and the PulseAudio null-sink module is unloaded before the crashing call.

## Mechanism

Symbolized backtrace of the main thread, innermost last:

```
gnome_nd_window_finalize   nd-window.c:533      g_clear_object (&self->pulse)
nd_pulseaudio_finalize     nd-pulseaudio.c:384  pa_context_disconnect ()
libpulse                   fires the state callback synchronously (TERMINATED)
nd_pulseaudio_state_cb     nd-pulseaudio.c:271  g_autofree cleanup
g_free -> glibc abort      free(): invalid pointer
```

In `nd_pulseaudio_state_cb`, `g_autofree gchar *sink_name` is declared bare
inside the `PA_CONTEXT_READY` case of a switch with no enclosing braces. When
the switch jumps to the `PA_CONTEXT_TERMINATED` case it skips the initializer,
but the variable is still in scope, so the early `return` runs the cleanup
attribute and frees whatever stack garbage the variable holds. glibc rejects
the pointer and aborts. On some runs the garbage could instead be a live heap
pointer and corrupt memory silently instead of aborting.

## Fix

Upstream commit
[9512cac8](https://gitlab.gnome.org/GNOME/gnome-network-displays/-/commit/9512cac8)
"Add new scope for case when using g_autofree" (2026-05-20) wraps the case in
braces. It is newer than the 0.99.0 tag (2026-01-23).

Until a new release lands, either build from git master, or add that commit
as a patch to the local PKGBUILD and rebuild:

```sh
cd ~/.cache/yay/gnome-network-displays
curl -LO https://gitlab.gnome.org/GNOME/gnome-network-displays/-/commit/9512cac8.patch
# add 9512cac8.patch to source=() and sha256sums=(), apply it in prepare(),
# then rebuild:
makepkg -si
```
