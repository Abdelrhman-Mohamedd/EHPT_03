<?php
$currentPage = 'dashboard';
require_once 'header.php';
$vm_ip = $_SERVER['SERVER_ADDR'] ?? '<VM_IP>';
?>

<div class="hero">
    <div class="hero-badge">🔴 CONFIDENTIAL — AUTHORIZED PERSONNEL ONLY</div>
    <h1 class="hero-title">NovaTech Corp — Penetration Test Brief</h1>
    <p class="hero-subtitle">Lab 03: Pivoting, Tunneling &amp; Lateral Movement</p>
</div>

<!-- ── CREDENTIALS BOX ── -->
<div class="creds-box">
    <h2>🔑 Your Entry Point — PIVOT-1 SSH Access</h2>
    <p>You have been granted initial SSH access to the DMZ jump host. These are your <strong>only starting credentials</strong>.</p>
    <div class="creds-grid">
        <div class="cred-item">
            <span class="cred-label">Host</span>
            <code class="cred-value"><?= htmlspecialchars($vm_ip) ?></code>
        </div>
        <div class="cred-item">
            <span class="cred-label">Port</span>
            <code class="cred-value">2222</code>
        </div>
        <div class="cred-item">
            <span class="cred-label">Username</span>
            <code class="cred-value">pentest</code>
        </div>
        <div class="cred-item">
            <span class="cred-label">Password</span>
            <code class="cred-value cred-password"><?= htmlspecialchars($GLOBALS['PENTEST_PASS']) ?></code>
        </div>
    </div>
    <div class="cmd-block">
        <span class="cmd-label">Quick connect:</span>
        <code>ssh pentest@<?= htmlspecialchars($vm_ip) ?> -p 2222</code>
    </div>
</div>

<!-- ── TOPOLOGY SUMMARY ── -->
<div class="section-title">Network Segments</div>
<div class="segment-grid">
    <div class="segment-card segment-dmz">
        <div class="seg-header">🌐 DMZ — PIVOT-1</div>
        <div class="seg-ip"><?= htmlspecialchars($vm_ip) ?></div>
        <div class="seg-detail">SSH :2222 — your entry</div>
        <div class="seg-access access-open">✅ Directly reachable</div>
    </div>
    <div class="segment-card segment-alpha">
        <div class="seg-header">🔒 Segment Alpha</div>
        <div class="seg-ip">10.10.10.0/24</div>
        <div class="seg-detail">ALPHA-1 (10.10.10.10) HTTP :80<br>ALPHA-2 (10.10.10.20) HTTP :8080, SSH :22</div>
        <div class="seg-access access-locked">🔴 Requires pivot via PIVOT-1</div>
    </div>
    <div class="segment-card segment-beta">
        <div class="seg-header">🔐 Segment Beta</div>
        <div class="seg-ip">172.16.50.0/24</div>
        <div class="seg-detail">BETA-1 (172.16.50.10) HTTP :9090, SSH :22</div>
        <div class="seg-access access-locked">🔴 Requires double pivot via ALPHA-2</div>
    </div>
</div>

<!-- ── CHALLENGES ── -->
<div class="section-title">Your 5 Challenges</div>
<div class="challenge-list">
    <div class="challenge-card">
        <div class="ch-num">1</div>
        <div class="ch-body">
            <div class="ch-title">SSH Local Port Forward <code>(-L)</code></div>
            <div class="ch-desc">Forward a local port on your Kali machine through PIVOT-1 to reach ALPHA-1's HTTP service at <code>10.10.10.10:80</code>. Browse the page to get <strong>FLAG{LOCALFWD}</strong>.</div>
            <div class="ch-hint">Hint: <code>ssh -L 8080:10.10.10.10:80 pentest@<?= htmlspecialchars($vm_ip) ?> -p 2222 -N</code></div>
        </div>
    </div>
    <div class="challenge-card">
        <div class="ch-num">2</div>
        <div class="ch-body">
            <div class="ch-title">Dynamic SOCKS5 Proxy <code>(-D)</code> + proxychains</div>
            <div class="ch-desc">Set up a SOCKS5 proxy through PIVOT-1. Use proxychains to scan Segment Alpha and access ALPHA-2's HTTP service at <code>10.10.10.20:8080</code>. Get <strong>FLAG{SOCKS}</strong>.</div>
            <div class="ch-hint">Hint: <code>ssh -D 1080 -N pentest@<?= htmlspecialchars($vm_ip) ?> -p 2222</code> then <code>proxychains curl http://10.10.10.20:8080/</code></div>
        </div>
    </div>
    <div class="challenge-card">
        <div class="ch-num">3</div>
        <div class="ch-body">
            <div class="ch-title">SSH ProxyJump <code>(-J)</code></div>
            <div class="ch-desc">Use ProxyJump to SSH directly into ALPHA-2 (<code>10.10.10.20</code>) via PIVOT-1 in a single command. Read <code>~/flag.txt</code> on ALPHA-2 for <strong>FLAG{PROXYJUMP}</strong>. Also explore <code>~/.ssh/</code>.</div>
            <div class="ch-hint">Hint: <code>ssh -J pentest@<?= htmlspecialchars($vm_ip) ?>:2222 alpha@10.10.10.20</code></div>
        </div>
    </div>
    <div class="challenge-card">
        <div class="ch-num">4</div>
        <div class="ch-body">
            <div class="ch-title">Double Pivot (Chained ProxyJump)</div>
            <div class="ch-desc">Chain two SSH jumps to reach Segment Beta (<code>172.16.50.0/24</code>). Tunnel a local port to BETA-1's HTTP at <code>172.16.50.10:9090</code>. Get <strong>FLAG{DOUBLEPIVOT}</strong>.</div>
            <div class="ch-hint">Hint: Use <code>-J pentest@<?= htmlspecialchars($vm_ip) ?>:2222,alpha@10.10.10.20</code> with <code>-L</code> to port-forward BETA-1's HTTP.</div>
        </div>
    </div>
    <div class="challenge-card">
        <div class="ch-num">5</div>
        <div class="ch-body">
            <div class="ch-title">SSH Key Lateral Movement</div>
            <div class="ch-desc">On ALPHA-2, you will find a private key (<code>~/.ssh/id_rsa</code>). Exfiltrate it to your Kali machine and use it to authenticate as <code>admin</code> on BETA-1. Read <code>~/flag.txt</code> for <strong>FLAG{LATERAL}</strong>.</div>
            <div class="ch-hint">Hint: <code>scp -J pentest@<?= htmlspecialchars($vm_ip) ?>:2222 alpha@10.10.10.20:~/.ssh/id_rsa ./key.pem</code> then <code>ssh -i key.pem -J ... admin@172.16.50.10</code></div>
        </div>
    </div>
</div>

<div class="notice-box">
    <strong>📋 Student ID:</strong> <code><?= htmlspecialchars($GLOBALS['STUDENT_ID']) ?></code> — Your flags are cryptographically bound to this ID. Include it visible in all screenshots.
</div>

<?php require_once 'footer.php'; ?>
