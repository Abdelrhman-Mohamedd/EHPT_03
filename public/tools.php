<?php $currentPage='tools'; require_once 'header.php'; ?>
<div class="page-header">
    <h1 class="page-title">🧰 Tools Reference</h1>
    <p class="page-subtitle">Command reference for all techniques used in Lab 03.</p>
</div>

<div class="table-card">
    <h3 style="margin-bottom:16px;font-size:1rem;">SSH Port Forwarding Cheatsheet</h3>
    <table class="data-table">
        <thead><tr><th>Flag</th><th>Technique</th><th>Command Template</th></tr></thead>
        <tbody>
            <tr>
                <td><code>-L</code></td>
                <td>Local Port Forward</td>
                <td><code>ssh -L &lt;local_port&gt;:&lt;remote_host&gt;:&lt;remote_port&gt; user@pivot -p 2222 -N</code></td>
            </tr>
            <tr>
                <td><code>-D</code></td>
                <td>Dynamic SOCKS Proxy</td>
                <td><code>ssh -D 1080 -N -q user@pivot -p 2222</code></td>
            </tr>
            <tr>
                <td><code>-R</code></td>
                <td>Remote Port Forward</td>
                <td><code>ssh -R &lt;remote_port&gt;:&lt;local_host&gt;:&lt;local_port&gt; user@pivot -p 2222 -N</code></td>
            </tr>
            <tr>
                <td><code>-J</code></td>
                <td>ProxyJump (single hop)</td>
                <td><code>ssh -J user@pivot:2222 user@internal_host</code></td>
            </tr>
            <tr>
                <td><code>-J</code> chain</td>
                <td>ProxyJump (double hop)</td>
                <td><code>ssh -J user@pivot:2222,user@alpha2 user@beta1</code></td>
            </tr>
            <tr>
                <td><code>-i</code></td>
                <td>Key-based auth</td>
                <td><code>ssh -i ./id_rsa user@host</code></td>
            </tr>
        </tbody>
    </table>
</div>

<div class="table-card">
    <h3 style="margin-bottom:16px;font-size:1rem;">proxychains4 Setup</h3>
    <pre style="background:#0a0d14;color:#a8d8a8;padding:16px;border-radius:6px;font-family:'Courier New',monospace;font-size:.85rem;overflow-x:auto">
# 1. Start SOCKS5 tunnel (run in background terminal)
ssh -D 1080 -N -q pentest@&lt;VM_IP&gt; -p 2222 &

# 2. Edit /etc/proxychains4.conf
#    Change strict_chain → dynamic_chain
#    Add to [ProxyList]:  socks5  127.0.0.1  1080

# 3. Use proxychains with any tool
proxychains4 nmap  -sT -Pn -p 22,80,8080,9090 10.10.10.0/24
proxychains4 curl  http://10.10.10.20:8080/
proxychains4 ssh   alpha@10.10.10.20
    </pre>
</div>

<div class="table-card">
    <h3 style="margin-bottom:16px;font-size:1rem;">~/.ssh/config — Simplify Chained Jumps</h3>
    <pre style="background:#0a0d14;color:#a8d8a8;padding:16px;border-radius:6px;font-family:'Courier New',monospace;font-size:.85rem;overflow-x:auto">
Host pivot1
    HostName &lt;VM_IP&gt;
    Port     2222
    User     pentest

Host alpha2
    HostName 10.10.10.20
    User     alpha
    ProxyJump pivot1

Host beta1
    HostName 172.16.50.10
    User     admin
    IdentityFile ~/.ssh/alpha2_id_rsa
    ProxyJump alpha2

# With this config:
ssh alpha2                                  # challenge 3
ssh -L 9090:172.16.50.10:9090 -N alpha2    # challenge 4 (port-forward via ALPHA-2)
ssh beta1                                   # challenge 5 (key in IdentityFile above)
    </pre>
</div>
<?php require_once 'footer.php'; ?>
