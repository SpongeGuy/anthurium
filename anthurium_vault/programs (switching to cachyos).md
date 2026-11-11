# currently in use
zen
obsidian
audacity
kitty
godot-mono
discord
steam
obs-studio
nemo (file browser)
blender
spotify (spicetify)

i'm switching from linux mint to cachyos i3 edition. what do i need to keep in mind? i am familiar with i3/tiling window managers and the terminal.


will cachyos automatically detect video drivers? i use nvidia rtx 5060 so how do i manage drivers?
how do i manage bluetooth connections?
wifi connections?
pipewire patches/sinks (helvum), how to set default applications going into which sink for what device?




---
`sudo pacman -Syu` run this regularly
AUR is `paru`
- automounting: `udiskie`
- browser: `qutebrowser`
- terminal: `kitty`
- `spotify`, `godot-mono`

> i won't be using a file explorer very often, so i'll just download nemo so i have it in case of emergency

sponge@kitchen-sink

keep home safe:
	put `/home` on its own partition that way more distro-hopping is relatively painless
	reinstall by formatting only the `/` partition, keeping `/home` intact. (how does this work? will i still be able to change things on `/` if i am on `/home`?)
	choosing btrfs creates a separate `@home` subvolume (what does this mean)

On a reinstall you choose **manual partitioning** in the installer and tell it:

- the `/` partition: **format**, because this is the OS being replaced
- the `/home` partition: **mount at `/home`, don’t format**, so your files survive


drivers
	i'm using nvidia-driver-595-open (ubuntu/mint package name)
	cachyos detects hardware using `chwd` and installs drivers automatically

bluetooth
	`bluez` is the backend
	use `bluetui` for a tui

wifi
	cachyos uses Networkmanager
	use `nmtui` for a tui

pipewire
	cachyos uses pipewire with wireplumber
	ill be real i need more basic tldr format instructions on how to use pipewire to route audio (for recording purposes)
	`qpwgraph` is a patchbay which can save and restore link layouts


directories i have to move to my external drive before transitioning:
- `~/.ssh`
- `~/.local/share/fonts`
- `~/.local/share/PrismLauncher/`
- `~/dev/`
- `~/doc/`
- `~/media/`
- `~/.config` 