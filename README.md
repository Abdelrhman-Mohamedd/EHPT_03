# Lab 03: NovaTech Corp — Network Pivoting & Lateral Movement (Ethical Hacking Lab)

This repository contains the complete network topology configs, setup scripts, service definitions, and instructor verification tools for **Lab 03**.

## Lab Theme: Pivoting, Tunneling & Lateral Movement

Lab 03 is a **pure network-level** lab. There are no web application vulnerabilities. Students are given initial SSH access to a DMZ host and must use tunneling and pivoting techniques to reach progressively deeper isolated network segments.

**Skills Covered:**
- SSH Local Port Forwarding (`-L`)
- SSH Dynamic SOCKS5 Proxy (`-D`) + `proxychains`
- SSH ProxyJump (`-J`) for single-hop pivot
- Double Pivot — chained SSH jumps to reach a 3rd network tier
- Lateral Movement via SSH Key Theft (`id_rsa` reuse)

## Lab Architecture (Network Topology)

```
[Attacker / Kali Linux]
        │
        │  SSH port 2222  ─── credentials given in lab manual
        │  HTTP port 8083 ─── mission briefing portal
        ▼
┌──────────────────────────────────────────────┐
│  PIVOT-1 — DMZ Host                          │
│  External: <VM_IP>                           │
│  Internal: 10.10.10.1  (Segment Alpha NIC)   │
└──────────────────┬───────────────────────────┘
                   │  Segment Alpha: 10.10.10.0/24
                   │  (NOT directly reachable from attacker)
          ┌────────┴────────┐
          ▼                 ▼
  ┌──────────────┐  ┌───────────────────────────────────┐
  │  ALPHA-1     │  │  ALPHA-2                          │
  │  10.10.10.10 │  │  10.10.10.20                      │
  │  HTTP :80    │  │  HTTP :8080  │  SSH :22            │
  └──────────────┘  │  Has: ~/.ssh/id_rsa  + notes.txt  │
                    └──────────────┬────────────────────┘
                                   │  Segment Beta: 172.16.50.0/24
                                   │  (only reachable from Segment Alpha)
                                   ▼
                          ┌─────────────────────────────┐
                          │  BETA-1                     │
                          │  172.16.50.10               │
                          │  HTTP :9090  │  SSH :22     │
                          │  Key-only SSH (admin user)  │
                          └─────────────────────────────┘
```

> All three network segments are simulated on a **single Rocky Linux VM** using Linux network namespaces (`ip netns`). No second VM is required.

## Appliance Hardening & Anti-Tampering Model

1. **Instructor-Prepared Template**: `prepare_template_vm.sh` locks down the VM, hides the instructor account, and moves all lab assets to `/opt/lab03-setup/` (`root:root 700`).
2. **Automated GUI First-Boot Setup**: Student logs in, a `zenity` popup asks for their Student ID, provisions the lab, then self-deletes.
3. **Cryptographic Flag Binding**: All 5 flags are derived from `sha256(STUDENT_ID + FLAG_TYPE + SECRET_SALT)`. Salt stored in `/etc/lab03.conf` (`root:root 600`).
4. **Per-Student SSH Password**: The `pentest` account password is also derived from the Student ID — unique per student, given on the briefing portal.
5. **Network Isolation**: Segments Alpha and Beta are unreachable without establishing pivots — enforced by `iptables` and network namespace routing rules.

## Quick Start (Instructor Setup)

```bash
# 1. Clone repository
git clone https://github.com/YourOrg/EHPT_03.git
cd EHPT_03

# 2. Prepare the Template VM (Run Once)
sudo ./prepare_template_vm.sh

# 3. Export VM and distribute to students
```
