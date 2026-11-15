# homelab

Public-facing description of my homelab: hardware, topology, design decisions, and recommendations. See `INVENTORY.md` for the canonical hardware list.

Exact configurations, manifests, secrets, hostnames, and IP allocations live in a separate private `homelab-ops` repo and do not appear here.

## 🧱 Physical Rack

- **Rack:** DeskPi RackMate T2 12U (Black, Light version)
- **Form factor:** 10″ rack, ~260mm depth
- **Layout style:** front-clean (patch panel), rear-managed cabling

## 💾 Core Hardware

### NAS

**Synology DS1513+**

- 5-bay NAS, 5× 4TB WD Red in Synology Hybrid RAID (one-drive fault tolerance), about 14.5TB usable
- 4× Gigabit Ethernet, with link aggregation in use
- Role:
  - SMB storage today, NFS once the cluster needs it
  - persistent volumes for the cluster (planned)
  - backups

**Western Digital ShareSpace**

- Single Ethernet
- Role:
  - secondary storage / backup / staging

### Network

**Ubiquiti UniFi Switch Lite 16 PoE**

- 16× Gigabit ports
- 8× PoE+ (802.3at)
- Fanless
- Role:
  - core switch
  - PoE provider for Pis
  - VLAN support (future)
- Management: adopted into [UniFi OS Server](https://ui.com/download) on a workstation, where it runs as a macOS app with a bundled VM. No Cloud Key / Dream Machine in the rack, so the controller host must be reachable on the LAN to push config changes.

**Upstream: Netgear Orbi mesh**

- Consumer mesh router and satellites, outside the rack
- Role:
  - internet gateway, DHCP and DNS for the whole LAN
  - Wi-Fi
- The Orbi router connects to the internet service. The rack switch plugs into the Orbi router. The controller workstation reaches the rack over the Wi-Fi mesh.

### Compute Cluster

**4× Raspberry Pi 4B 4GB**

- BCM2711 (Cortex-A72), 4GB LPDDR4
- True gigabit ethernet (dedicated PCIe, not shared with USB)
- USB 3.0
- Storage: SD card (initial), optional USB SSD later
- Role:
  - cluster nodes (k3s recommended, nothing deployed yet)
  - container workloads

### Power (Pi)

**Raspberry Pi PoE+ HAT** (4×, one per node)

- 802.3af/at compatible
- Active cooling
- Powered via switch (no USB PSU required)
- Role:
  - clean power delivery
  - remote power cycling via UniFi

PoE budget headroom is tight: 4× Pi 4B + HAT at load ≈ 34W of the switch's 45W total PoE budget, leaving ~11W for any future PoE device (camera, AP).

### Rack Accessories

**GeeekPi 10″ 2U Raspberry Pi Rack Mount**

- Holds up to 4 Pis
- Front-facing ports
- PoE + USB accessible from front

**10″ 12-port patch panel**

- Front-facing ports

**Rear-mounted power board**

- 5 AC sockets (1 extra-wide for bricks)
- 1× USB-C (5V/3A) and 3× USB-A

Additional:

- 1× extra 10″ shelf (for second NAS)

## 🔌 Cabling

**Front (visible)**

- Patch panel → switch: 0.15m + 0.2m black Cat6 cables
- Pi → switch: 0.25m black Cat6

**Rear (hidden)**

- NAS → patch panel
- SSD (future) → Pi via short USB (≤20cm)

**Cable management**

- Black Velcro (cut-to-length)
- No zip ties

## 🧩 Topology

```
          ┌───────────────┐
          │ Patch Panel   │
          └──────┬────────┘
                 │ (short cables)
          ┌──────▼────────┐
          │ UniFi Switch  │
          └──────┬────────┘
     ┌───────────┼──────────────┐
     │           │              │
 ┌───▼───┐   ┌───▼───┐      ┌───▼───┐
 │ Pi 4B │   │ Pi 4B │ ...  │ Pi 4B │  (PoE)
 └───────┘   └───────┘      └───────┘

 (Rear)
 NAS → Patch Panel → Switch

 (Upstream)
 Switch → Orbi router (gateway, DHCP, DNS) → Internet
 Controller workstation → Wi-Fi mesh → Orbi router
```

## 📍 Current Status

As of November 2026:

- **Controller:** UniFi OS Server is running on the workstation.
- **Storage:** both NASes are online and serve SMB and AFP. Both act as Time Machine targets. NFS is not enabled on either yet.
- **Services on the Synology:** Plex Media Server, plus a nightly offsite backup of photos and home videos to Amazon Glacier.
- **Pi cluster:** the nodes are powered over PoE but not yet imaged. No orchestration is deployed.

## 🧠 Design Decisions

1. **PoE-first design**
   - All Pis powered via PoE+ HAT
   - Eliminates power bricks
   - Enables remote reboot via switch port-cycle

2. **Stateless-first cluster**
   - Pis boot from SD (initially)
   - Persistent storage via Synology (NFS, not yet enabled)

3. **Patch panel for cleanliness**
   - Front-facing clean cabling
   - Rear contains device wiring

## 🧮 Clustering & Orchestration

Cluster spec: 4× Pi 4B 4GB → ~16GB total RAM, 16 cores, gigabit interconnect, PoE port-cycle for remote reboot, NAS-backed persistent storage.

### Recommendation: k3s, single-server + 3 agents

This is a recommendation, not a decision: nothing is deployed yet.

[k3s](https://k3s.io) is Rancher's lightweight Kubernetes: a single ARM-friendly binary, ~512MB resident, designed for edge / low-resource hardware. It runs standard Kubernetes manifests and Helm charts, has native arm64 builds, and integrates cleanly with NFS-backed persistent volumes from the Synology.

Start with **one server node + three agent nodes**:

- One Pi runs the control plane (kube-apiserver + embedded sqlite); three are pure workers
- Workload state lives on NFS, so a failed agent is a cheap SD-reflash + rejoin
- Simpler to operate and reason about than HA; promote to a 3-server embedded-etcd HA cluster later if control-plane availability matters more than worker capacity

### Alternatives

| Option           | When it would win                                                |
|------------------|------------------------------------------------------------------|
| microk8s         | Want batteries-included (DNS, ingress, storage) over minimalism  |
| Docker Swarm     | Want clustering without the Kubernetes learning curve            |
| Nomad            | Care about non-container workloads in the same scheduler         |
| `docker compose` | ≤2 services total, no real scheduling need                       |

### Open decisions

- GitOps tool (Flux / ArgoCD / `kubectl apply` from a Makefile)
- Ingress (Traefik is bundled with k3s; nginx / Caddy are alternatives)
- Storage provisioner (NFS subdir provisioner vs Synology CSI vs static PVs)

## 💿 Node Provisioning

Recommended baseline for the four nodes. It holds whichever orchestrator wins.

1. **Image:** Raspberry Pi OS Lite (64-bit), written with Raspberry Pi Imager. No desktop, an arm64 userland, and the PoE+ HAT fan works without extra packages.
2. **Customise in Imager:** a unique hostname per node, one user with SSH public-key login only, timezone and locale. No Wi-Fi.
3. **Addressing:** a DHCP reservation per node on the router, so addresses stay stable.
4. **First boot:** full package upgrade and bootloader EEPROM update. Then enable the memory cgroup on the kernel command line (`cgroup_memory=1 cgroup_enable=memory`), which k3s and other container runtimes need.
5. **SD card care:** use high-endurance cards and keep write-heavy state on the NAS. If cards wear, move the control-plane node to a USB SSD first.

Ubuntu Server LTS (arm64) is the alternative. It would win if the same distribution is wanted everywhere. It costs an extra kernel-modules package for k3s networking and manual PoE fan configuration.

## 📦 Storage Strategy

**Initial**

- SD cards for Pis
- NAS for persistent data

**Future (optional)**

- USB SSD per Pi
- Mounted internally (behind rack)
- Short USB cables (≤20cm)

## 🧱 Rack Layout (U allocation)

Top to bottom, U12 at the top. Positions are read from a photo of the front of the rack, so the unit counts for the two NASes are approximate.

| U          | Device                                  | Notes                                                    |
|------------|-----------------------------------------|----------------------------------------------------------|
| U11 to U12 | UniFi Switch Lite 16 PoE                | Ports face front                                         |
| U10        | 12-port patch panel                     | Directly under the switch, so patch cables stay short    |
| U9         | Blank panel                             | Gap for the cable drop from the switch to the Pis        |
| U7 to U8   | GeeekPi 2U Raspberry Pi mount           | 4× Pi 4B, each cabled straight up to the switch          |
| U4 to U6   | Western Digital ShareSpace              | Free-standing unit                                       |
| U1 to U3   | Synology DS1513+                        | Free-standing unit on the rack floor, heaviest at the bottom |

The rack is full. There is no spare U for further hardware without removing the blank panel.

## ⚠️ Constraints

- Rack depth: tight (~260mm)
- Cable length must be short
- No dangling devices (SSD, etc.)
- Limited U space → avoid unnecessary hardware

## 🔜 Future Enhancements

- VLAN segmentation (UniFi)
- Monitoring stack (Prometheus/Grafana)
- Optional SSD upgrade per node
- Refresh the NAS drives (the current set is around ten years old)
- 3-server HA control plane (promotion from single-server k3s)

## 🎯 Summary

- 10″ rack, tightly packed
- PoE-powered Pi cluster
- NAS-backed storage
- Clean front, managed rear
- Designed for incremental evolution
