#!/bin/bash
## Swap Escape and Caps Lock (GNOME, Wayland-safe — no root/udev needed).
##
## Warning: this sets the xkb-options key directly, which replaces the
## whole array; if other xkb options ever get added here, include
## caps:swapescape alongside them in the same gsettings call rather than
## as a separate one, or this will clobber them.
##
## Idempotent: safe to re-run, and chezmoi only re-runs this once unless
## the rendered script content changes.
##
## personal-fedora only — see .chezmoiignore.

set -euo pipefail

gsettings set org.gnome.desktop.input-sources xkb-options "['caps:swapescape']"
