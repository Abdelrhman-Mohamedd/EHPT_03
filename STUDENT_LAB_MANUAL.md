<div style="text-align: center; margin-top: 50px;">
  <h1 style="color: #2c3e50; font-size: 3em; border-bottom: 2px solid #e67e22; padding-bottom: 10px;">NovaTech Corp — Network Penetration Test</h1>
  <h2 style="color: #7f8c8d; font-weight: 300;">Ethical Hacking Lab 03 &mdash; Pivoting, Tunneling &amp; Lateral Movement</h2>
</div>

<br><br>

<div style="background-color: #ecf0f1; padding: 20px; border-left: 5px solid #e74c3c; border-radius: 5px;">
  <h3 style="margin-top: 0; color: #c0392b;">🚨 Rules of Engagement</h3>
  <ul>
    <li><strong>Initial Access:</strong> You are given SSH credentials for PIVOT-1. This is your <em>only</em> starting point.</li>
    <li><strong>Scope:</strong> PIVOT-1 (<code>&lt;VM_IP&gt;</code>), Segment Alpha (<code>10.10.10.0/24</code>), Segment Beta (<code>172.16.50.0/24</code>).</li>
    <li><strong>Out of Scope:</strong> Do NOT attempt OS-level privilege escalation, attack the host hypervisor, or brute-force any service. All challenges are solved with standard tunneling and lateral movement techniques.</li>
    <li><strong>Integrity:</strong> Flags are cryptographically bound to your Student ID. Submitting another student's flag = automatic zero.</li>
  </ul>
</div>

---

## 🏢 Scenario

You are a Penetration Tester contracted by **NovaTech Corp** to assess their internal network segmentation. Your point of contact has provided you with SSH credentials to a DMZ jump host.

Intelligence gathered during the pre-engagement phase suggests that NovaTech's internal network is **poorly segmented** — the same service account credentials are reused across multiple tiers, and SSH private keys have been left on shared hosts without proper access controls.

Your objective: reach every internal network segment and prove that an attacker with only DMZ access can achieve **full lateral movement** across the entire corporate network.

---

## 💻 Attacker Environment & Required Tools

You will act as the external attacker. **You must use a separate Virtual Machine (e.g., Kali Linux, Parrot Security OS) to solve this lab.** Your attacker VM must be on the same network (Bridged or NAT Network) as the NovaTech Lab Appliance.

**Ensure the following tools are installed on your Kali VM:**
* **`ssh` / `scp`:** The built-in OpenSSH client (essential for port forwarding and ProxyJump).
* **`proxychains4`:** Used to route traffic from standard tools (like `curl` or `nmap`) through your SSH SOCKS proxy.
* **`curl`:** Used to interact with internal HTTP APIs.
* **Web Browser + FoxyProxy (Optional):** Highly recommended for viewing internal web dashboards through your SOCKS5 proxy.

---

## 🗺️ Network Topology

```
[Your Kali Attacker Machine]
        │
        │  SSH :2222   ← your entry point (credentials below)
        ▼
  PIVOT-1 — DMZ Host (<VM_IP>)
  Internal: 10.10.10.1
        │
        │  ── Segment Alpha: 10.10.10.0/24 ──────────────────────
        │
        ├──► ALPHA-1   10.10.10.10   HTTP :80
        │
        └──► ALPHA-2   10.10.10.20   HTTP :8080  │  SSH :22
                  │
                  │  ── Segment Beta: 172.16.50.0/24 ───────────
                  │         (only reachable via ALPHA-2)
                  └──► BETA-1    172.16.50.10   HTTP :9090  │  SSH :22
```

> ⚠️ Segments Alpha and Beta are **not directly routable** from your machine. You must establish tunnels to reach them.

---

## 🔑 Your Starting Credentials

| Host | Address | User | Password |
|------|---------|------|---------|
| PIVOT-1 | `<VM_IP>:2222` | `pentest` | **shown on the briefing portal** |

The briefing portal at `http://<VM_IP>:8083` will display your personalized SSH password after first-boot setup.

---

## 🎯 Lab Challenges

<table style="width: 100%; border-collapse: collapse;">
  <thead>
    <tr style="background-color: #34495e; color: white;">
      <th style="padding: 10px; border: 1px solid #bdc3c7;">#</th>
      <th style="padding: 10px; border: 1px solid #bdc3c7;">Challenge</th>
      <th style="padding: 10px; border: 1px solid #bdc3c7;">Technique</th>
      <th style="padding: 10px; border: 1px solid #bdc3c7;">Target</th>
      <th style="padding: 10px; border: 1px solid #bdc3c7;">Flag</th>
      <th style="padding: 10px; border: 1px solid #bdc3c7;">Pts</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">1</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><strong>SSH Local Port Forward</strong></td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>ssh -L</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;">ALPHA-1 HTTP :80</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>FLAG{LOCALFWD}</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">10</td>
    </tr>
    <tr style="background-color:#f9f9f9;">
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">2</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><strong>Dynamic SOCKS5 Proxy</strong></td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>ssh -D</code> + proxychains</td>
      <td style="padding:10px;border:1px solid #bdc3c7;">ALPHA-2 HTTP :8080</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>FLAG{SOCKS}</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">10</td>
    </tr>
    <tr>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">3</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><strong>SSH ProxyJump</strong></td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>ssh -J</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;">ALPHA-2 SSH :22</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>FLAG{PROXYJUMP}</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">10</td>
    </tr>
    <tr style="background-color:#f9f9f9;">
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">4</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><strong>Double Pivot</strong></td>
      <td style="padding:10px;border:1px solid #bdc3c7;">Chained <code>-J</code> + <code>-L</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;">BETA-1 HTTP :9090</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>FLAG{DOUBLEPIVOT}</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">10</td>
    </tr>
    <tr>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">5</td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><strong>SSH Key Lateral Movement</strong></td>
      <td style="padding:10px;border:1px solid #bdc3c7;">Stolen <code>id_rsa</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;">BETA-1 SSH :22 as <code>admin</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;"><code>FLAG{LATERAL}</code></td>
      <td style="padding:10px;border:1px solid #bdc3c7;text-align:center;">10</td>
    </tr>
  </tbody>
</table>

---

## 🛠️ Methodology & Hints

<div style="display: flex; flex-wrap: wrap; gap: 15px;">

<div style="flex:1;min-width:300px;background:#fdfefe;border:1px solid #dcdde1;padding:15px;border-radius:8px;box-shadow:0 4px 6px rgba(0,0,0,0.05);">
  <h4 style="color:#2980b9;margin-top:0;">🔌 Challenge 1 — Local Port Forward</h4>
  <p>You cannot reach <code>10.10.10.10:80</code> directly. Use SSH to <strong>forward a local port on your Kali machine</strong> through PIVOT-1 to reach ALPHA-1's HTTP service:<br><br>
  <code>ssh -L &lt;local_port&gt;:10.10.10.10:80 pentest@&lt;VM_IP&gt; -p 2222 -N</code><br><br>
  Then browse to <code>http://127.0.0.1:&lt;local_port&gt;/</code> on your Kali machine.</p>
</div>

<div style="flex:1;min-width:300px;background:#fdfefe;border:1px solid #dcdde1;padding:15px;border-radius:8px;box-shadow:0 4px 6px rgba(0,0,0,0.05);">
  <h4 style="color:#27ae60;margin-top:0;">🧦 Challenge 2 — Dynamic SOCKS Proxy</h4>
  <p>A local port forward only reaches <em>one</em> host/port. A <strong>dynamic SOCKS5 proxy</strong> routes <em>all</em> traffic through the pivot:<br><br>
  <code>ssh -D 1080 -N pentest@&lt;VM_IP&gt; -p 2222</code><br><br>
  Configure <code>proxychains4</code> to use <code>socks5 127.0.0.1 1080</code>, then use <code>proxychains curl</code> to reach <code>10.10.10.20:8080</code>. Try scanning the segment first: <code>proxychains nmap -sT -Pn 10.10.10.0/24</code></p>
</div>

<div style="flex:1;min-width:300px;background:#fdfefe;border:1px solid #dcdde1;padding:15px;border-radius:8px;box-shadow:0 4px 6px rgba(0,0,0,0.05);">
  <h4 style="color:#8e44ad;margin-top:0;">🚀 Challenge 3 — SSH ProxyJump</h4>
  <p>ProxyJump lets you SSH <em>through</em> one host to reach another in a single command — no SOCKS config needed:<br><br>
  <code>ssh -J pentest@&lt;VM_IP&gt;:2222 alpha@10.10.10.20</code><br><br>
  You are now in a shell on ALPHA-2. Look around — check <code>~/.ssh/</code>, read <code>~/notes.txt</code>. The flag is in <code>~/flag.txt</code>.</p>
</div>

<div style="flex:1;min-width:300px;background:#fdfefe;border:1px solid #dcdde1;padding:15px;border-radius:8px;box-shadow:0 4px 6px rgba(0,0,0,0.05);">
  <h4 style="color:#f39c12;margin-top:0;">⛓️ Challenge 4 — Double Pivot</h4>
  <p>Segment Beta (<code>172.16.50.0/24</code>) is only reachable <em>through</em> ALPHA-2. Chain two jumps or combine ProxyJump with a port forward:<br><br>
  <code>ssh -J pentest@&lt;VM_IP&gt;:2222,alpha@10.10.10.20 -L 9090:172.16.50.10:9090 alpha@10.10.10.20 -N</code><br><br>
  Then <code>curl http://127.0.0.1:9090/</code> to get the flag from BETA-1.</p>
</div>

<div style="flex:1;min-width:300px;background:#fff8e1;border:1px solid #ffe082;padding:15px;border-radius:8px;box-shadow:0 4px 6px rgba(0,0,0,0.05);">
  <h4 style="color:#e67e22;margin-top:0;">🔑 Challenge 5 — SSH Key Lateral Movement</h4>
  <p>On ALPHA-2 (where you landed in Challenge 3), explore <code>~/.ssh/</code>. There is a private key (<code>id_rsa</code>) left by a careless admin. Copy it to your machine and use it to authenticate as <code>admin</code> on BETA-1 — no password needed:<br><br>
  <code>ssh -i id_rsa -J pentest@&lt;VM_IP&gt;:2222,alpha@10.10.10.20 admin@172.16.50.10</code><br><br>
  <code>cat ~/flag.txt</code></p>
</div>

</div>

---

## 🧰 Recommended Tools

| Tool | Purpose |
|------|---------|
| `ssh` | Port forwarding, ProxyJump, key auth |
| `proxychains4` | Route tools through SOCKS5 proxy |
| `nmap` | Network discovery through proxy (`-sT -Pn`) |
| `curl` | HTTP requests through proxy |
| `scp` / `ssh cat` | Exfiltrate the `id_rsa` key from ALPHA-2 |
| `~/.ssh/config` | Simplify chained SSH configs |

---

## 📝 Reporting Requirements

For **each challenge** your report must include:

1. **Technique & Target** — e.g., "Challenge 1: SSH `-L` local port forward to ALPHA-1 (10.10.10.10:80)"
2. **Exact Command(s)** — every SSH, curl, nmap, proxychains command used
3. **Step-by-Step Reproduction** — clear enough to reproduce from scratch
4. **Screenshot Evidence** — showing the full terminal with hostname (`lab03-<student-id>`) visible in prompt, and the `FLAG{...}` output
5. **Security Impact** — why is this misconfiguration dangerous? What should NovaTech fix?

<br>

<div style="text-align:center;padding:20px;background-color:#2c3e50;color:white;border-radius:5px;">
  <h3 style="margin:0;">Good luck — pivot deep and move laterally! 🕵️</h3>
</div>
