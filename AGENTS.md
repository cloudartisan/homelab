# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is the **public-facing** description of my homelab — hardware, topology, design decisions, and recommendations. Anything committed here is readable by anyone on the internet.

**Scope boundary:** narrative and architectural content only. Exact configurations, manifests, scripts, secrets, hostnames, IP addresses, MAC addresses, Tailscale auth keys, cloudflared tokens, NFS export specifics, and similar operational detail belong in the separate **private `cloudartisan/homelab-ops` repo** — never commit them here, even temporarily. If a change starts to feel like "ops" rather than "what the homelab is", it belongs in the other repo.

See `README.md` for the full hardware and physical-layout baseline, and `INVENTORY.md` for the flat hardware list.

## Platform facts that shape code and config

- **Compute target:** Raspberry Pi 4B 4GB nodes (BCM2711 Cortex-A72, ARM; SD-card root). Container images and binaries must be ARM-compatible (`linux/arm64` preferred; `linux/arm/v7` works); amd64-only artefacts will not run. Unlike the older 3B+, the 4B has a dedicated PCIe-backed gigabit NIC (no USB-bus sharing), so full gigabit throughput is realistic.
- **Orchestration is undecided.** Options on the table include bare systemd installs, `docker compose`, and k3s; Proxmox is not viable on the Pi 4B nodes (it targets x86-64; the Pis are ARM). Don't assume Kubernetes, containerd, or any specific ingress exists until it's committed to the repo. Ask before scaffolding in a particular direction.
- **Persistent storage model:** NAS-backed, not node-local. Synology DS1513+ provides NFS / SMB; Pi nodes are treated as stateless (rebuildable from SD). WD ShareSpace is secondary/backup only.
- **Power and lifecycle:** PoE-first and uniform. All four nodes run on Raspberry Pi PoE+ HATs — no independent PSU. Reboots happen by cycling the UniFi switch port, not by pulling cables. Automation that "restarts a node" should assume PoE port cycling is the mechanism. The Lite 16 PoE has a 45W total PoE budget; 4× Pi 4B + HAT at load is ~34W, leaving ~11W headroom for any future PoE device.
- **Network:** single flat LAN today via UniFi Switch Lite 16 PoE; VLAN segmentation is future work. Don't assume VLAN isolation exists yet.
- **Management plane:** the UniFi switch is adopted into UniFi OS Server running on an off-rack workstation (the machine this repo is normally edited from) — there is no in-rack Cloud Key / Dream Machine. Any change to switch config (PoE port toggles, VLANs, firmware) requires the controller host to be powered on and reachable on the LAN. UniFi OS Server publishes a fixed set of host ports (8080, 8443, 8880–8882, 8444, 9543, 11443, 11084, 3478/udp, 5005, 5514/udp, 5671, 6789, 10003/udp); if any are already bound on the controller host the container exits immediately with code 125/126 — check `lsof -nP -iTCP:<port> -sTCP:LISTEN` before assuming the app itself is broken.

## Candidate workloads

Services under consideration (not yet deployed — inform design choices, but don't scaffold them unprompted):

- **PiHole** — network-wide DNS with ad/tracker blocking.
- **Tailscale** — mesh VPN for remote access into the lab.
- **Reverse proxy / external ingress** — likely Cloudflare Tunnel (`cloudflared`), possibly alongside or instead of a local reverse proxy (Traefik, Caddy, nginx).

Because orchestration is undecided, pick per-service deployment shape pragmatically (compose file, systemd unit, Helm chart) rather than forcing a single pattern prematurely.

## Repo status

The private ops repo exists at `/Users/david/Projects/homelab-ops` (`cloudartisan/homelab-ops`). Host inventory and scan results live there.

Leak checks are the only tooling so far:

- `main` is protected: changes go through a pull request and the `leak-scan` check must pass. Direct pushes to `main` are rejected.
- `pre-commit run --all-files` runs both local hooks (gitleaks on staged changes, and the private-detail check). Enable per clone with `pre-commit install`.
- `.github/scripts/check-private-details.sh` runs the private-detail check alone. It rejects RFC 1918 addresses, MAC addresses, `.local` hostnames and Tailscale keys in tracked files.

No manifests or playbooks committed yet. As Ansible/k3s/Helm/compose/Terraform content lands, add to this file:

- The actual commands (bootstrap, apply, reconcile, lint, test) — including how to run a single test or a single playbook/role.
- Top-level directory responsibilities.
- Host inventory conventions and how secrets are handled.
- Non-obvious operational constraints (drain-before-reconfigure, hardware quirks, etc.).

Don't invent structure that isn't there — update this file from observed reality.

## Conventions

- UK English in prose and documentation.
