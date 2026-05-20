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

- 5-bay NAS
- 4× Gigabit Ethernet (link aggregation capable)
- Role:
  - NFS / SMB storage
  - Kubernetes persistent volumes
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
- Management: adopted into [UniFi OS Server](https://ui.com/download) on a workstation. No Cloud Key / Dream Machine in the rack, so the controller host must be reachable on the LAN to push config changes.

### Compute Cluster

**4× Raspberry Pi 4B 4GB**

- BCM2711 (Cortex-A72), 4GB LPDDR4
- True gigabit ethernet (dedicated PCIe, not shared with USB)
- USB 3.0
- Storage: SD card (initial), optional USB SSD later
- Role:
  - Kubernetes cluster nodes
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
```

## 🧠 Design Decisions

1. **PoE-first design**
   - All Pis powered via PoE+ HAT
   - Eliminates power bricks
   - Enables remote reboot via switch port-cycle

2. **Stateless-first cluster**
   - Pis boot from SD (initially)
   - Persistent storage via Synology (NFS)

3. **Patch panel for cleanliness**
   - Front-facing clean cabling
   - Rear contains device wiring

## 🧮 Clustering & Orchestration

Cluster spec: 4× Pi 4B 4GB → ~16GB total RAM, 16 cores, gigabit interconnect, PoE port-cycle for remote reboot, NAS-backed persistent storage.

### Recommendation: k3s, single-server + 3 agents

[k3s](https://k3s.io) is Rancher's lightweight Kubernetes — single ARM-friendly binary, ~512MB resident, designed for edge / low-resource hardware. It runs standard Kubernetes manifests and Helm charts, has native arm64 builds, and integrates cleanly with NFS-backed persistent volumes from the Synology.

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

## 📦 Storage Strategy

**Initial**

- SD cards for Pis
- NAS for persistent data

**Future (optional)**

- USB SSD per Pi
- Mounted internally (behind rack)
- Short USB cables (≤20cm)

## 🧱 Rack Layout (U allocation)

_TBD_

## ⚠️ Constraints

- Rack depth: tight (~260mm)
- Cable length must be short
- No dangling devices (SSD, etc.)
- Limited U space → avoid unnecessary hardware

## 🔜 Future Enhancements

- VLAN segmentation (UniFi)
- Monitoring stack (Prometheus/Grafana)
- Optional SSD upgrade per node
- 3-server HA control plane (promotion from single-server k3s)

## 🎯 Summary

- 10″ rack, tightly packed
- PoE-powered Pi cluster
- NAS-backed storage
- Clean front, managed rear
- Designed for incremental evolution
