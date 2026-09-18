<?php $currentPage='topology'; require_once 'header.php'; ?>
<div class="page-header">
    <h1 class="page-title">🗺️ Network Topology</h1>
    <p class="page-subtitle">Full network map of the NovaTech Corp lab environment.</p>
</div>

<div class="table-card">
    <pre style="color:#58a6ff;font-family:'Courier New',monospace;font-size:.88rem;line-height:1.8;overflow-x:auto">
[Your Kali Attacker Machine]
        │
        │  SSH :2222   ← entry point (credentials on Mission Briefing page)
        │  HTTP :8083  ← this briefing portal
        ▼
  ┌───────────────────────────────────────────┐
  │  PIVOT-1  —  DMZ Host                     │
  │  External : &lt;VM_IP&gt;                       │
  │  Internal : 10.10.10.1  (Segment Alpha)   │
  └──────────────────┬────────────────────────┘
                     │
         ┌───────────┴──────────────┐
         │   Segment Alpha          │   10.10.10.0/24
         │   (NOT directly routable)│
         │                          │
    ┌────┴──────────┐   ┌───────────┴──────────────────┐
    │  ALPHA-1      │   │  ALPHA-2                     │
    │  10.10.10.10  │   │  10.10.10.20                 │
    │  HTTP :80     │   │  HTTP :8080  │  SSH :22      │
    │  (Flag 1)     │   │  (Flag 2)    │  (Flag 3)     │
    │               │   │  Has: ~/.ssh/id_rsa           │
    └───────────────┘   └──────────────┬───────────────┘
                                        │
                           ┌────────────┴────────────────┐
                           │   Segment Beta              │   172.16.50.0/24
                           │   (only via ALPHA-2)        │
                           │                             │
                      ┌────┴──────────────────────────┐
                      │  BETA-1                        │
                      │  172.16.50.10                  │
                      │  HTTP :9090  │  SSH :22        │
                      │  (Flag 4)    │  (Flag 5)       │
                      │  admin user — key-only SSH     │
                      └────────────────────────────────┘
    </pre>
</div>

<div class="table-card">
    <table class="data-table">
        <thead><tr><th>Host</th><th>IP</th><th>Services</th><th>Segment</th><th>Reach Via</th></tr></thead>
        <tbody>
            <tr><td>PIVOT-1</td><td><code>&lt;VM_IP&gt;</code></td><td>SSH :2222, HTTP :8083</td><td>DMZ</td><td>Direct</td></tr>
            <tr><td>ALPHA-1</td><td><code>10.10.10.10</code></td><td>HTTP :80</td><td>Alpha</td><td><code>ssh -L</code> or SOCKS proxy</td></tr>
            <tr><td>ALPHA-2</td><td><code>10.10.10.20</code></td><td>HTTP :8080, SSH :22</td><td>Alpha</td><td>SOCKS proxy or <code>ssh -J</code></td></tr>
            <tr><td>BETA-1</td><td><code>172.16.50.10</code></td><td>HTTP :9090, SSH :22</td><td>Beta</td><td>Double pivot via ALPHA-2</td></tr>
        </tbody>
    </table>
</div>
<?php require_once 'footer.php'; ?>
