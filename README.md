# Wireless Display Cast

Omarchy bar plugin `shady.wireless-display-cast`. Click the cast icon to check
prerequisites and open GNOME Network Displays. It owns receiver discovery,
connection progress, screen selection, and disconnect controls. This plugin
does not infer an active cast from whether the app is running.

## Requirements

Install the Miracast backend: `omarchy pkg aur add gnome-network-displays`.
GNOME Network Displays needs compatible Wi-Fi Direct hardware, NetworkManager
with wpa_supplicant, video/audio codecs, and a working screen-sharing portal
and PipeWire on Wayland. Keep your receiver in its Miracast mode.

Upstream setup and troubleshooting:
https://github.com/GNOME/gnome-network-displays/blob/master/README.md

## Use

1. Click the Wireless Display Cast bar icon.
2. Open the picker and select your receiver.
3. Approve a screen in the sharing prompt.
4. Disconnect through GNOME Network Displays when finished.

If audio stays local, select the Network-Displays output in audio settings.
The plugin never starts sharing automatically or changes network configuration.
The prerequisite check is advisory, not an end-to-end casting test.

## Install from GitHub

```sh
omarchy plugin add https://github.com/shadyuop/omarchy-wireless-display-cast --enable
```

Requires an Omarchy version with shell plugin support. The plugin uses Bash,
`jq`, `nmcli`, and `systemctl` to check prerequisites. Installing the plugin does
not install GNOME Network Displays automatically.

## Local installation

Copy this directory to `~/.config/omarchy/plugins/shady.wireless-display-cast`,
then run `omarchy-shell shell rescanPlugins` and
`omarchy plugin enable shady.wireless-display-cast`.

Disable with `omarchy plugin disable shady.wireless-display-cast`.
Validate with `omarchy plugin validate .` and `bash -n cast-helper`.

## License

[MIT](LICENSE) © 2026 Shady S. Samuel.
