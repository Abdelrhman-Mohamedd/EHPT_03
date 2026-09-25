# Lab 03 Assessment & Anti-Cheating Grading Rubric
## NovaTech Corp — Pivoting, Tunneling & Lateral Movement

**Entry Point:** `ssh pentest@<VM_IP> -p 2222`
**Build Isolation:** Per-student VM with cryptographic flag binding
**Total Points:** 100 | **Coverage:** SSH Tunneling · SOCKS Proxy · ProxyJump · Double Pivot · Key-based Lateral Movement

---

## Anti-Cheating & Submission Rules

1. **Cryptographic Flag Verification** — Every flag verified against `generate_student_flags.py`. Mismatch = **0/100 + plagiarism referral**.
2. **Uncropped Terminal Screenshots** — Must show the full terminal including the shell prompt with hostname (`lab03-<student-id>`). Screenshots cropped to hide the prompt are rejected.
3. **Command Evidence Required** — For every challenge, students must include the **exact SSH/proxychains command** that established the tunnel, not just the flag output. Flags without command evidence score 0 for that challenge.
4. **Plagiarism Check** — Report narratives and `.buildinfo` machine hashes cross-checked across all submissions.

---

## Grading Breakdown

| Category | Description | Points |
| :--- | :--- | :---: |
| **1. Executive Summary & Network Diagram** | Scope, topology diagram, tool usage, attack-chain narrative | 15 pts |
| **2. Challenge Findings & PoCs** | Command evidence + screenshot + valid flag for all 5 challenges | 50 pts |
| **3. Root Cause Analysis** | Why each misconfiguration enables the attack | 15 pts |
| **4. Remediation & Network Hardening** | Specific firewall rules, SSH hardening, credential hygiene | 20 pts |
| **Total** | | **100 pts** |

---

## Detailed Evaluation Criteria

### 1. Executive Summary & Network Diagram (15 pts)
- **15–13:** Clear executive summary; accurate network topology diagram labelling all 3 segments with correct IPs; systematic kill-chain documented (foothold → local fwd → SOCKS → ProxyJump → double pivot → lateral).
- **12–8:** Acceptable summary; topology partially correct or missing Beta segment.
- **7–0:** No diagram or incorrect topology; no attack-chain narrative.

---

### 2. Challenge Findings & Proof-of-Concept (50 pts / 10 pts each)

#### Challenge 1 — SSH Local Port Forward (10 pts)
- **Technique:** `ssh -L <local_port>:10.10.10.10:80 pentest@<VM_IP> -p 2222 -N`
- **Evidence required:**
  - Screenshot of the `ssh -L` command running in terminal.
  - Screenshot of `curl http://127.0.0.1:<port>/` output **or** browser showing the flag page, with hostname visible in a separate terminal.
  - Valid `FLAG{LOCALFWD}` matching `generate_student_flags.py`.
- **Grading:**
  - 10 pts: Correct `-L` syntax, correct IPs/ports, flag verified.
  - 7 pts: Correct approach but minor syntax issue or missing command screenshot.
  - 0 pts: Flag submitted without command evidence, or flag doesn't match.

#### Challenge 2 — Dynamic SOCKS5 Proxy (10 pts)
- **Technique:** `ssh -D 1080 -N pentest@<VM_IP> -p 2222` + `proxychains4 curl http://10.10.10.20:8080/`
- **Evidence required:**
  - Screenshot of `ssh -D` command.
  - Contents of `/etc/proxychains4.conf` showing `socks5 127.0.0.1 1080`.
  - Screenshot of `proxychains4 curl` or `proxychains4 nmap` output showing the flag.
  - Valid `FLAG{SOCKS}`.
- **Grading:**
  - 10 pts: Correct SOCKS setup, proxychains configured, flag verified.
  - 5 pts: Flag submitted but proxychains config not shown or nmap scan missing.
  - 0 pts: No SOCKS evidence.

#### Challenge 3 — SSH ProxyJump (10 pts)
- **Technique:** `ssh -J pentest@<VM_IP>:2222 alpha@10.10.10.20`
- **Evidence required:**
  - Screenshot of the `-J` command and the resulting shell prompt on ALPHA-2 (showing username@hostname).
  - `cat ~/flag.txt` output showing `FLAG{PROXYJUMP}`.
  - Student notes the presence of `~/.ssh/id_rsa` and `~/notes.txt` (discovery leads to challenges 4 & 5).
- **Grading:**
  - 10 pts: Correct ProxyJump, shell on ALPHA-2 confirmed, flag verified, id_rsa noted.
  - 7 pts: Correct jump but no mention of id_rsa discovery.
  - 0 pts: No ProxyJump evidence.

#### Challenge 4 — Double Pivot (10 pts)
- **Technique:** `ssh -J pentest@<VM_IP>:2222,alpha@10.10.10.20 -L 9090:172.16.50.10:9090 alpha@10.10.10.20 -N` + `curl http://127.0.0.1:9090/`
- **Evidence required:**
  - Screenshot of the double-jump SSH command (two entries in `-J` or use of `~/.ssh/config` ProxyJump chain).
  - Screenshot of `curl` output from BETA-1 containing `FLAG{DOUBLEPIVOT}`.
  - Student explains why a single pivot was insufficient (Beta is not reachable from Attacker via PIVOT-1 alone).
- **Grading:**
  - 10 pts: Correct double-jump syntax, flag verified, explains Beta isolation.
  - 7 pts: Flag obtained but ProxyJump chain not properly documented.
  - 0 pts: No double-pivot evidence.

#### Challenge 5 — SSH Key Lateral Movement (10 pts)
- **Technique:** Exfiltrate `~/.ssh/id_rsa` from ALPHA-2 via `scp -J`, then `ssh -i id_rsa -J ... admin@172.16.50.10`
- **Evidence required:**
  - `scp` or `cat`/copy command used to retrieve `id_rsa` from ALPHA-2.
  - `ssh -i id_rsa ... admin@172.16.50.10` command and resulting shell prompt showing `admin@beta-1`.
  - `cat ~/flag.txt` output showing `FLAG{LATERAL}`.
  - Student documents where the key was found and why it granted access (authorized_keys on BETA-1).
- **Grading:**
  - 10 pts: Full key theft documented, admin shell on BETA-1, flag verified.
  - 7 pts: Flag obtained but key exfiltration method not documented.
  - 0 pts: No key theft evidence.

---

### 3. Root Cause Analysis (15 pts)
- **15–13:** All 5 misconfigurations correctly identified with root causes:
  - **Local Fwd / SOCKS:** No egress firewall between Attacker and Segment Alpha via PIVOT-1 — `iptables FORWARD ACCEPT` instead of an allowlist; fix: restrict forwarding to only necessary IP/port pairs.
  - **SOCKS:** SSH server on PIVOT-1 allows `AllowTcpForwarding yes` without restriction; fix: `AllowTcpForwarding local` or disable with `PermitTunnel no` for non-admin users.
  - **ProxyJump:** ALPHA-2's sshd accepts password auth with a weak credential reused from PIVOT-1; fix: enforce key-only auth (`PasswordAuthentication no`), unique passwords per tier.
  - **Double Pivot:** No firewall rule between Segment Alpha and Segment Beta; ALPHA-2 is dual-homed with no egress control; fix: restrict ALPHA-2's forward chain — only specific internal services should cross segments.
  - **Key Lateral Movement:** `id_rsa` private key stored on a shared/intermediate host with `644` permissions; `authorized_keys` on BETA-1 trusts this key without restriction; fix: never store private keys on shared hosts; use `from="10.10.10.20"` in `authorized_keys` to restrict key usage; rotate all keys immediately.
- **12–8:** Most root causes correct; minor gaps.
- **7–0:** Shallow or incorrect analysis.

---

### 4. Remediation & Network Hardening (20 pts)
- **20–17:** Specific, actionable fixes:
  - **Firewall segmentation:** `iptables -P FORWARD DROP` on PIVOT-1; only allow `ESTABLISHED,RELATED`; whitelist only necessary flows.
  - **SSH hardening on PIVOT-1:** `AllowTcpForwarding no` or `local` only; `PermitTunnel no`; `AllowUsers pentest`; `MaxAuthTries 3`.
  - **Segment Alpha/Beta isolation:** iptables rules on ALPHA-2 blocking unrestricted forwarding to Beta; add `iptables -A FORWARD -s 10.10.10.0/24 -d 172.16.50.0/24 -j DROP` except for specific allowed flows.
  - **Credential hygiene:** Unique passwords per service account per tier; disable password auth on internal SSH (`PasswordAuthentication no`).
  - **SSH key management:** Remove all private keys from shared hosts; use SSH certificates with short TTLs; restrict `authorized_keys` entries with `from=`, `no-port-forwarding`, `no-X11-forwarding` options.
  - **Monitoring:** Deploy network IDS (Suricata/Snort) to detect SOCKS proxy patterns; log and alert on unusual SSH forwarding; monitor for `id_rsa` file access.
- **16–10:** Generic recommendations without specific rules or commands.
- **9–0:** Minimal or missing remediation.
