# homelab

Hardware and setup baseline for my homelab.

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

**Raspberry Pi 3B+**

- Count: 3–4 nodes
- Networking: Gigabit Ethernet
- Storage: SD card (initial), optional USB SSD later
- Role:
  - Kubernetes cluster nodes
  - container workloads

### Power (Pi)

**Raspberry Pi PoE+ HAT**

- 802.3af/at compatible
- Active cooling
- Powered via switch (no USB PSU required)
- Role:
  - clean power delivery
  - remote power cycling via UniFi

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
 │ Pi 1  │   │ Pi 2  │ ...  │ Pi N  │  (PoE)
 └───────┘   └───────┘      └───────┘

 (Rear)
 NAS → Patch Panel → Switch
```

## 🧠 Design Decisions

1. **PoE-first design**
   - All Pis powered via PoE
   - Eliminates power bricks
   - Enables remote reboot via switch

2. **Stateless-first cluster**
   - Pis boot from SD (initially)
   - Persistent storage via Synology (NFS)

3. **Patch panel for cleanliness**
   - Front-facing clean cabling
   - Rear contains device wiring

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
- Kubernetes cluster (k3s recommended)
- NFS provisioner from Synology
- Monitoring stack (Prometheus/Grafana)
- Optional SSD upgrade per node

## 🎯 Summary

- 10″ rack, tightly packed
- PoE-powered Pi cluster
- NAS-backed storage
- Clean front, managed rear
- Designed for incremental evolution
