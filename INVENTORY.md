# Hardware Inventory

Canonical list of physical homelab hardware. See `README.md` for design rationale, topology, and operational notes; this file is the flat "what's in the rack" reference.

## Compute

| Qty | Model                        | Notes                                                                |
|-----|------------------------------|----------------------------------------------------------------------|
| 1   | Raspberry Pi 3B+             | Gigabit ethernet, supports PoE+ HAT (HAT currently fitted)           |
| 3   | Raspberry Pi 3 Model B v1.2  | 10/100 ethernet, pre-dates PoE+ HAT header pinout — USB-powered     |

## Storage

| Qty | Model                       | Notes                                                            |
|-----|-----------------------------|------------------------------------------------------------------|
| 1   | Synology DS1513+            | 5-bay NAS, 4× GigE (LAG capable), NFS/SMB — primary storage     |
| 1   | Western Digital ShareSpace  | Single ethernet — secondary / backup / staging                  |

## Network

| Qty | Model                              | Notes                                                       |
|-----|------------------------------------|-------------------------------------------------------------|
| 1   | Ubiquiti UniFi Switch Lite 16 PoE  | 16× GigE, 8× PoE+ (802.3at), 45W total PoE budget, fanless |

## Rack & Mounting

| Qty | Model                                  | Notes                                          |
|-----|----------------------------------------|------------------------------------------------|
| 1   | DeskPi RackMate T2                     | 10″ 12U rack, ~260mm depth, black              |
| 1   | GeeekPi 10″ 2U Raspberry Pi Rack Mount | Holds up to 4 Pis, front-facing ports          |
| 1   | 10″ 12-port patch panel                | Front-facing ports                             |
| 1   | 10″ shelf (spare)                      | Earmarked for second NAS                       |

## Power

| Qty | Model                       | Notes                                                                      |
|-----|-----------------------------|----------------------------------------------------------------------------|
| 1   | Raspberry Pi PoE+ HAT       | Fitted to the 3B+; active cooling; remote reboot via UniFi port-cycle     |
| 1   | 4-port rear power board     | 1× USB-C (5V/3A) + 3× USB-A; USB total budget 4.2A; powers the three 3Bs  |

## Planned

| Qty | Model                | Notes                                                                                   |
|-----|----------------------|-----------------------------------------------------------------------------------------|
| 4   | Raspberry Pi 4B 4GB  | To replace / supplement the older Pis; all support PoE+ HAT                            |
| 3–4 | Raspberry Pi PoE+ HAT| One per new 4B (3 if the existing HAT on the 3B+ is freed and re-used)                 |
