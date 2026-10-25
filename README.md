# omarchy-spotify

A Spotify widget for the [Omarchy](https://omarchy.org/) shell bar. The bar shows only the Spotify icon; click it to open a popup with the current track and playback controls. It is a Spotify-only fork of Omarchy's built-in `omarchy.media` plugin and uses your theme's colors.

## Features

- Bar: just the Spotify icon, tinted with the accent color while playing
- Popup: album art, title (scrolls when long), artist, album
- Progress bar with click-and-drag seeking and a hover time preview
- Previous / play-pause / next, plus shuffle and repeat (off, playlist, track)
- "Open Spotify" button when Spotify isn't running
- Closes on outside click or Esc
- Spotify only: browser tabs, mpv and other players are ignored (this includes media keys and the OSD)

## Requirements

- Omarchy with the shell plugin system (`omarchy plugin --help` should work)
- Spotify (the desktop client, which exposes MPRIS)

## Install

```bash
omarchy plugin add git@github.com:dbohry/omarchy-spotify.git --enable
```

Or manually:

```bash
git clone git@github.com:dbohry/omarchy-spotify.git ~/.config/omarchy/plugins/spotify
omarchy plugin enable spotify --section right
```

This plugin provides its own media service, so disable the stock one to avoid running two:

```bash
omarchy plugin disable omarchy.media
```

If the icon doesn't appear, restart the shell:

```bash
omarchy restart shell
```

## Moving the icon

```bash
omarchy bar move spotify --section right
```

## Update

```bash
omarchy plugin update spotify
```

## Uninstall

```bash
omarchy plugin remove spotify
omarchy plugin enable omarchy.media
```

## Layout

| File | Purpose |
|------|---------|
| `manifest.json` | Plugin metadata |
| `BarWidget.qml` | Bar icon and popup UI |
| `Service.qml` | MPRIS service, filtered to Spotify |
| `MediaModel.js` | Helpers from the stock media plugin |

Based on the `omarchy.media` plugin from Omarchy. See its license for terms.
