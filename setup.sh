#!/usr/bin/env bash
# ==============================================================================
# Lab 03 Setup Script — NovaTech Corp
# Theme: Pivoting, Tunneling & Lateral Movement
# Network: PIVOT-1 (host) → Segment Alpha (10.10.10.0/24) → Segment Beta (172.16.50.0/24)
# All segments simulated via Linux network namespaces (ip netns)
# ==============================================================================
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root: sudo ./setup.sh <STUDENT_ID> [--production]"; exit 1
fi

STUDENT_ID="${1:-student_2026}"
IS_PRODUCTION=0
for arg in "$@"; do [ "$arg" == "--production" ] && IS_PRODUCTION=1; done

SALT_FILE="/etc/lab03.conf"
SECRET_SALT=$([ -f "$SALT_FILE" ] && cat "$SALT_FILE" || echo "${2:-EHPT03_SECRET_SALT_2026}")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==[🔒] Lab 03 — Personalizing for: ${STUDENT_ID} =="

# ── Flag & Password Derivation ───────────────────────────────────────────────
FLAG_LOCALFWD=$(echo -n    "${STUDENT_ID}_LOCALFWD_${SECRET_SALT}"    | sha256sum | cut -c1-32)
FLAG_SOCKS=$(echo -n       "${STUDENT_ID}_SOCKS_${SECRET_SALT}"       | sha256sum | cut -c1-32)
FLAG_PROXYJUMP=$(echo -n   "${STUDENT_ID}_PROXYJUMP_${SECRET_SALT}"   | sha256sum | cut -c1-32)
FLAG_DOUBLEPIVOT=$(echo -n "${STUDENT_ID}_DOUBLEPIVOT_${SECRET_SALT}" | sha256sum | cut -c1-32)
FLAG_LATERAL=$(echo -n     "${STUDENT_ID}_LATERAL_${SECRET_SALT}"     | sha256sum | cut -c1-32)

# Per-student SSH password for the pentest account
PENTEST_PASS=$(echo -n "SSH_${STUDENT_ID}_${SECRET_SALT}" | sha256sum | cut -c1-16)

# ── Step 1: System users ─────────────────────────────────────────────────────
echo "[+] Step 1: Creating system users..."
id -u lab03   >/dev/null 2>&1 || useradd --system --no-create-home --shell=/usr/sbin/nologin lab03
id -u pentest >/dev/null 2>&1 || useradd -m -s /bin/bash pentest
id -u alpha   >/dev/null 2>&1 || useradd -m -s /bin/bash alpha
id -u admin   >/dev/null 2>&1 || useradd -m -s /bin/bash admin
echo "pentest:${PENTEST_PASS}" | chpasswd
echo "alpha:${PENTEST_PASS}" | chpasswd
passwd -l admin  # admin is key-only, no password login

# ── Step 2: Directory structure ───────────────────────────────────────────────
echo "[+] Step 2: Directory structure..."
mkdir -p /srv/labs/lab03/{public,data,sessions}
mkdir -p /srv/labs/lab03/public/assets/css
mkdir -p /srv/labs/lab03/services/{alpha1,alpha2-http,beta1}

# ── Step 3: Copy web portal files ────────────────────────────────────────────
echo "[+] Step 3: Copying web portal files..."
cp -r "${SCRIPT_DIR}/public/"* /srv/labs/lab03/public/

# ── Step 4: Inject flags into service HTML pages ─────────────────────────────
echo "[+] Step 4: Injecting flags..."

# ALPHA-1 HTTP :80 → Challenge 1 (Local Port Forward) flag
cat > /srv/labs/lab03/services/alpha1/index.html << EOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<title>NovaTech Internal — Alpha-1 Node</title>
<style>body{font-family:monospace;background:#0d1117;color:#58a6ff;padding:40px}
.flag{background:#161b22;border:1px solid #30363d;padding:20px;border-radius:8px;margin:20px 0;color:#3fb950;font-size:1.1em}
</style></head><body>
<h2>NovaTech Alpha-1 Internal Node</h2>
<p>IP: 10.10.10.10 | Service: Internal Configuration Store</p>
<hr>
<div class="flag">
  <strong>Challenge 1 — SSH Local Port Forward</strong><br><br>
  FLAG{${FLAG_LOCALFWD}}
</div>
<p><em>This service is not accessible from the public internet.</em></p>
</body></html>
EOF

# ALPHA-2 HTTP :8080 → Challenge 2 (SOCKS) flag
cat > /srv/labs/lab03/services/alpha2-http/index.html << EOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<title>NovaTech Internal — Alpha-2 Node</title>
<style>body{font-family:monospace;background:#0d1117;color:#58a6ff;padding:40px}
.flag{background:#161b22;border:1px solid #30363d;padding:20px;border-radius:8px;margin:20px 0;color:#3fb950;font-size:1.1em}
</style></head><body>
<h2>NovaTech Alpha-2 Internal Node</h2>
<p>IP: 10.10.10.20 | Service: Internal Monitoring Dashboard</p>
<hr>
<div class="flag">
  <strong>Challenge 2 — Dynamic SOCKS5 Proxy</strong><br><br>
  FLAG{${FLAG_SOCKS}}
</div>
<p><em>Accessible only via proxychains through an established SOCKS tunnel.</em></p>
</body></html>
EOF

# BETA-1 HTTP :9090 → Challenge 4 (Double Pivot) flag
cat > /srv/labs/lab03/services/beta1/index.html << EOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<title>NovaTech Internal — Beta-1 Node</title>
<style>body{font-family:monospace;background:#0d1117;color:#e6a817;padding:40px}
.flag{background:#161b22;border:1px solid #30363d;padding:20px;border-radius:8px;margin:20px 0;color:#3fb950;font-size:1.1em}
</style></head><body>
<h2>NovaTech Beta-1 Deep Internal Node</h2>
<p>IP: 172.16.50.10 | Segment: Beta (Tier-2 Isolation)</p>
<hr>
<div class="flag">
  <strong>Challenge 4 — Double Pivot</strong><br><br>
  FLAG{${FLAG_DOUBLEPIVOT}}
</div>
<p><em>If you reached this page, you have successfully pivoted through two network segments.</em></p>
</body></html>
EOF

# Challenge 3 (ProxyJump) flag — in alpha's home dir on ALPHA-2 (planted in the netns)
mkdir -p /home/alpha
cat > /home/alpha/flag.txt << EOF
Challenge 3 — SSH ProxyJump
FLAG{${FLAG_PROXYJUMP}}
EOF
chown alpha:alpha /home/alpha/flag.txt
chmod 644 /home/alpha/flag.txt

# notes.txt on ALPHA-2 — gives a breadcrumb (no actual creds needed; admin is key-only)
cat > /home/alpha/notes.txt << EOF
=== NovaTech Deployment Notes ===
Admin deployed id_rsa key to this host during automated provisioning.
Key is used for cross-tier SSH access to Beta segment hosts.
admin@172.16.50.10 accepts key-based auth only.
DO NOT share this key outside the corporate network.
=== End Notes ===
EOF
chown alpha:alpha /home/alpha/notes.txt
chmod 644 /home/alpha/notes.txt

# Challenge 5 (Lateral Movement) flag — in admin's home on BETA-1
mkdir -p /home/admin
echo "Challenge 5 — SSH Key Lateral Movement" > /home/admin/flag.txt
echo "FLAG{${FLAG_LATERAL}}"                  >> /home/admin/flag.txt
chown admin:admin /home/admin/flag.txt
chmod 644 /home/admin/flag.txt

# ── Step 5: Generate SSH key pair for lateral movement ───────────────────────
echo "[+] Step 5: Generating SSH key pair for lateral movement challenge..."
mkdir -p /home/alpha/.ssh
rm -f /home/alpha/.ssh/id_rsa /home/alpha/.ssh/id_rsa.pub
ssh-keygen -t rsa -b 2048 -f /home/alpha/.ssh/id_rsa -N "" -C "novatech-deploy-key" -q
chown -R alpha:alpha /home/alpha/.ssh
chmod 700 /home/alpha/.ssh
chmod 600 /home/alpha/.ssh/id_rsa
chmod 644 /home/alpha/.ssh/id_rsa.pub

# Install the public key as admin's authorized key (for BETA-1 SSH)
mkdir -p /home/admin/.ssh
cp /home/alpha/.ssh/id_rsa.pub /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh
chmod 700 /home/admin/.ssh
chmod 600 /home/admin/.ssh/authorized_keys

# ── Step 6: Build metadata ───────────────────────────────────────────────────
echo "[+] Step 6: Build metadata..."
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MACHINE_HASH="N/A"
[ -f /etc/machine-id ] && MACHINE_HASH=$(sha256sum /etc/machine-id | cut -c1-32)

printf "STUDENT_ID=%s\nBUILD_TIME=%s\nPENTEST_PASS=%s\n" \
    "$STUDENT_ID" "$BUILD_TIME" "$PENTEST_PASS" > /srv/labs/lab03/data/.studentinfo

cat << EOF > /srv/labs/lab03/.buildinfo
STUDENT_ID=${STUDENT_ID}
BUILD_TIMESTAMP=${BUILD_TIME}
MACHINE_HASH=${MACHINE_HASH}
FLAG_LOCALFWD=FLAG{${FLAG_LOCALFWD}}
FLAG_SOCKS=FLAG{${FLAG_SOCKS}}
FLAG_PROXYJUMP=FLAG{${FLAG_PROXYJUMP}}
FLAG_DOUBLEPIVOT=FLAG{${FLAG_DOUBLEPIVOT}}
FLAG_LATERAL=FLAG{${FLAG_LATERAL}}
EOF
chmod 700 /srv/labs/lab03/.buildinfo

# ── Step 7: Network Namespaces ───────────────────────────────────────────────
echo "[+] Step 7: Setting up network namespaces..."
# Cleanup any previous state
for ns in alpha beta; do ip netns del $ns 2>/dev/null || true; done
for lnk in veth-host veth-a2b; do ip link del $lnk 2>/dev/null || true; done

# Segment Alpha namespace
ip netns add alpha

# veth pair: host(veth-host:10.10.10.1) <-> alpha(veth-alpha:10.10.10.10 + .20)
ip link add veth-host type veth peer name veth-alpha
ip link set veth-alpha netns alpha

ip addr add 10.10.10.1/24 dev veth-host
ip link set veth-host up
ip netns exec alpha ip addr add 10.10.10.10/24 dev veth-alpha
ip netns exec alpha ip addr add 10.10.10.20/24 dev veth-alpha   # ALPHA-2 alias
ip netns exec alpha ip link set veth-alpha up
ip netns exec alpha ip link set lo up
ip netns exec alpha ip route add default via 10.10.10.1

# Segment Beta namespace
ip netns add beta

# veth pair: alpha(veth-a2b:172.16.50.1) <-> beta(veth-beta:172.16.50.10)
ip link add veth-a2b type veth peer name veth-beta
ip link set veth-a2b netns alpha
ip link set veth-beta netns beta

ip netns exec alpha ip addr add 172.16.50.1/24 dev veth-a2b
ip netns exec alpha ip link set veth-a2b up
ip netns exec beta  ip addr add 172.16.50.10/24 dev veth-beta
ip netns exec beta  ip link set veth-beta up
ip netns exec beta  ip link set lo up
ip netns exec beta  ip route add default via 172.16.50.1

# Enable forwarding and masquerade
sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec alpha sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -j MASQUERADE  2>/dev/null || true
iptables -t nat -A POSTROUTING -s 172.16.50.0/24 -j MASQUERADE 2>/dev/null || true

# IMPORTANT: Block direct Attacker→Alpha/Beta forwarding without pivot
# Students must go through PIVOT-1 SSH tunnel to reach internal segments
iptables -I FORWARD -d 10.10.10.0/24 -m state --state NEW \
    -i "$(ip route | awk '/default/{print $5}' | head -1)" -j DROP 2>/dev/null || true
iptables -I FORWARD -d 172.16.50.0/24 -m state --state NEW \
    -i "$(ip route | awk '/default/{print $5}' | head -1)" -j DROP 2>/dev/null || true

# ── Step 8: SSH configs for internal hosts ────────────────────────────────────
echo "[+] Step 8: Configuring internal SSH services..."

# ALPHA-2 sshd (listens on 10.10.10.20:22 inside alpha netns, password auth ON)
mkdir -p /etc/ssh/lab03
cat > /etc/ssh/lab03/sshd_alpha2.conf << 'SSHCFG'
Port 22
ListenAddress 10.10.10.20
HostKey /etc/ssh/lab03/ssh_host_alpha2_rsa_key
PidFile /var/run/sshd_alpha2.pid
AuthorizedKeysFile /home/%u/.ssh/authorized_keys
PasswordAuthentication yes
PermitRootLogin no
AllowUsers alpha
AllowTcpForwarding yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
UsePAM yes
SSHCFG

# BETA-1 sshd (listens on 172.16.50.10:22 inside beta netns, key-only)
cat > /etc/ssh/lab03/sshd_beta1.conf << 'SSHCFG'
Port 22
ListenAddress 172.16.50.10
HostKey /etc/ssh/lab03/ssh_host_beta1_rsa_key
PidFile /var/run/sshd_beta1.pid
AuthorizedKeysFile /home/%u/.ssh/authorized_keys
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
AllowUsers admin
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
UsePAM yes
SSHCFG

# Generate host keys for the internal sshd instances
[ -f /etc/ssh/lab03/ssh_host_alpha2_rsa_key ] || \
    ssh-keygen -t rsa -b 2048 -f /etc/ssh/lab03/ssh_host_alpha2_rsa_key -N "" -q
[ -f /etc/ssh/lab03/ssh_host_beta1_rsa_key ] || \
    ssh-keygen -t rsa -b 2048 -f /etc/ssh/lab03/ssh_host_beta1_rsa_key -N "" -q
chmod 600 /etc/ssh/lab03/ssh_host_*_key

# ── Step 9: Systemd services for all lab components ──────────────────────────
echo "[+] Step 9: Installing systemd services..."

# netns setup service (runs first, creates namespaces + routes)
cat > /etc/systemd/system/lab03-netns.service << 'SVC'
[Unit]
Description=Lab 03 Network Namespaces (Alpha + Beta segments)
After=network.target
Before=lab03-alpha1-http.service lab03-alpha2-http.service lab03-alpha2-ssh.service lab03-beta1-http.service lab03-beta1-ssh.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/opt/lab03-setup/netns_setup.sh
ExecStop=/opt/lab03-setup/netns_teardown.sh

[Install]
WantedBy=multi-user.target
SVC

# ALPHA-1 HTTP on 10.10.10.10:80
cat > /etc/systemd/system/lab03-alpha1-http.service << 'SVC'
[Unit]
Description=Lab 03 ALPHA-1 HTTP (10.10.10.10:80)
After=lab03-netns.service
Requires=lab03-netns.service

[Service]
Type=simple
ExecStart=/sbin/ip netns exec alpha /usr/bin/python3 -m http.server 80 --directory /srv/labs/lab03/services/alpha1 --bind 10.10.10.10
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVC

# ALPHA-2 HTTP on 10.10.10.20:8080
cat > /etc/systemd/system/lab03-alpha2-http.service << 'SVC'
[Unit]
Description=Lab 03 ALPHA-2 HTTP (10.10.10.20:8080)
After=lab03-netns.service
Requires=lab03-netns.service

[Service]
Type=simple
ExecStart=/sbin/ip netns exec alpha /usr/bin/python3 -m http.server 8080 --directory /srv/labs/lab03/services/alpha2-http --bind 10.10.10.20
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVC

# ALPHA-2 SSH on 10.10.10.20:22
cat > /etc/systemd/system/lab03-alpha2-ssh.service << 'SVC'
[Unit]
Description=Lab 03 ALPHA-2 SSH (10.10.10.20:22)
After=lab03-netns.service
Requires=lab03-netns.service

[Service]
Type=simple
ExecStart=/sbin/ip netns exec alpha /usr/sbin/sshd -D -e -f /etc/ssh/lab03/sshd_alpha2.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVC

# BETA-1 HTTP on 172.16.50.10:9090
cat > /etc/systemd/system/lab03-beta1-http.service << 'SVC'
[Unit]
Description=Lab 03 BETA-1 HTTP (172.16.50.10:9090)
After=lab03-netns.service
Requires=lab03-netns.service

[Service]
Type=simple
ExecStart=/sbin/ip netns exec beta /usr/bin/python3 -m http.server 9090 --directory /srv/labs/lab03/services/beta1 --bind 172.16.50.10
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVC

# BETA-1 SSH on 172.16.50.10:22
cat > /etc/systemd/system/lab03-beta1-ssh.service << 'SVC'
[Unit]
Description=Lab 03 BETA-1 SSH (172.16.50.10:22) key-only
After=lab03-netns.service
Requires=lab03-netns.service

[Service]
Type=simple
ExecStart=/sbin/ip netns exec beta /usr/sbin/sshd -D -e -f /etc/ssh/lab03/sshd_beta1.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVC

# Write netns setup/teardown helper scripts
cat > /opt/lab03-setup/netns_setup.sh << 'NSSETUP'
#!/bin/bash
set -e
for ns in alpha beta; do ip netns del $ns 2>/dev/null || true; done
ip link del veth-host 2>/dev/null || true

ip netns add alpha
ip netns add beta

ip link add veth-host type veth peer name veth-alpha
ip link set veth-alpha netns alpha
ip addr add 10.10.10.1/24 dev veth-host 2>/dev/null || true
ip link set veth-host up
ip netns exec alpha ip addr add 10.10.10.10/24 dev veth-alpha
ip netns exec alpha ip addr add 10.10.10.20/24 dev veth-alpha
ip netns exec alpha ip link set veth-alpha up
ip netns exec alpha ip link set lo up
ip netns exec alpha ip route add default via 10.10.10.1

ip link add veth-a2b type veth peer name veth-beta
ip link set veth-a2b netns alpha
ip link set veth-beta netns beta
ip netns exec alpha ip addr add 172.16.50.1/24 dev veth-a2b
ip netns exec alpha ip link set veth-a2b up
ip netns exec beta  ip addr add 172.16.50.10/24 dev veth-beta
ip netns exec beta  ip link set veth-beta up
ip netns exec beta  ip link set lo up
ip netns exec beta  ip route add default via 172.16.50.1

sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec alpha sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
iptables -t nat -C POSTROUTING -s 10.10.10.0/24 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -j MASQUERADE
iptables -t nat -C POSTROUTING -s 172.16.50.0/24 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 172.16.50.0/24 -j MASQUERADE
NSSETUP

cat > /opt/lab03-setup/netns_teardown.sh << 'NSTEAR'
#!/bin/bash
for ns in alpha beta; do ip netns del $ns 2>/dev/null || true; done
ip link del veth-host 2>/dev/null || true
NSTEAR

chmod +x /opt/lab03-setup/netns_setup.sh /opt/lab03-setup/netns_teardown.sh

# Enable and start all services
systemctl daemon-reload
for svc in lab03-netns lab03-alpha1-http lab03-alpha2-http lab03-alpha2-ssh lab03-beta1-http lab03-beta1-ssh; do
    systemctl enable $svc 2>/dev/null || true
    systemctl restart $svc 2>/dev/null || true
done

# ── Step 10: Configure main SSH (PIVOT-1 :2222) ───────────────────────────────
echo "[+] Step 10: Configuring PIVOT-1 SSH on port 2222..."
# Allow AllowTcpForwarding for pentest user on port 2222
cat >> /etc/ssh/sshd_config << 'SSHCFG'

# Lab 03: PIVOT-1 — pentest user SSH access with tunneling enabled
Port 2222
Match User pentest Port 2222
    PasswordAuthentication yes
    AllowTcpForwarding yes
    PermitTunnel yes
    GatewayPorts no
SSHCFG
systemctl restart sshd 2>/dev/null || true

# ── Step 11: Web portal permissions ──────────────────────────────────────────
echo "[+] Step 11: Permissions..."
id -u apache   >/dev/null 2>&1 && usermod -aG lab03 apache
id -u www-data >/dev/null 2>&1 && usermod -aG lab03 www-data
chown -R root:lab03 /srv/labs/lab03
chmod 750 /srv/labs/lab03 /srv/labs/lab03/public /srv/labs/lab03/data /srv/labs/lab03/sessions
find /srv/labs/lab03/public -type d -exec chmod 750 {} \;
find /srv/labs/lab03/public -type f -exec chmod 640 {} \;
find /srv/labs/lab03/data   -type f -exec chmod 640 {} \;

# ── Step 12: SELinux, hostname, banner ────────────────────────────────────────
echo "[+] Step 12: SELinux / hostname / banner..."
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    setsebool -P httpd_can_network_connect 1 2>/dev/null || true
    command -v semanage >/dev/null 2>&1 && {
        semanage port -m -t http_port_t -p tcp 8083 2>/dev/null || \
        semanage port -a -t http_port_t -p tcp 8083 2>/dev/null || true
        semanage fcontext -a -t httpd_sys_rw_content_t "/srv/labs/lab03(/.*)?" 2>/dev/null || true
    }
    command -v restorecon >/dev/null 2>&1 && restorecon -R /srv/labs/lab03 2>/dev/null || true
fi

HOSTNAME_TARGET="lab03-${STUDENT_ID//_/-}"
command -v hostnamectl >/dev/null 2>&1 && \
    hostnamectl set-hostname "${HOSTNAME_TARGET}" 2>/dev/null || echo "${HOSTNAME_TARGET}" > /etc/hostname

cat << EOF > /etc/motd
==============================================================================
  NovaTech Corp Ethical Hacking Black-Box Appliance (Lab 03)
  Student ID  : ${STUDENT_ID}    |    Build: ${BUILD_TIME}
  Lab Topic   : Pivoting, Tunneling & Lateral Movement
  Briefing    : http://<VM_IP>:8083
  Entry Point : ssh pentest@<VM_IP> -p 2222  (password on briefing portal)
  [!] All testing must be performed via tunnels — no direct segment access.
==============================================================================
EOF
cp /etc/motd /etc/issue

# ── Step 13: Apache / PHP-FPM ────────────────────────────────────────────────
echo "[+] Step 13: Installing Apache + PHP-FPM configs..."
FPM_CONF_COPIED=0
for FPM_DIR in "/etc/php-fpm.d" "/etc/php/8.3/fpm/pool.d" "/etc/php/8.2/fpm/pool.d"; do
    if [ -d "$FPM_DIR" ]; then
        cp "${SCRIPT_DIR}/config/lab03-php-fpm.conf" "${FPM_DIR}/lab03.conf"
        FPM_CONF_COPIED=1; break
    fi
done
[ "$FPM_CONF_COPIED" -eq 0 ] && { mkdir -p /etc/php-fpm.d; cp "${SCRIPT_DIR}/config/lab03-php-fpm.conf" /etc/php-fpm.d/lab03.conf; }

[ -d "/etc/httpd/conf.d" ]            && cp "${SCRIPT_DIR}/config/lab03-apache.conf" /etc/httpd/conf.d/lab03.conf
[ -d "/etc/apache2/sites-available" ] && { cp "${SCRIPT_DIR}/config/lab03-apache.conf" /etc/apache2/sites-available/lab03.conf; a2ensite lab03.conf || true; }

grep -q "novatech.local" /etc/hosts   || echo "127.0.0.1 novatech.local" >> /etc/hosts

systemctl restart php-fpm  || systemctl restart php8.3-fpm || systemctl restart php8.2-fpm || true
systemctl restart httpd    || systemctl restart apache2    || true

if [ "$IS_PRODUCTION" -eq 1 ]; then
    echo "[+] Production purge disabled to allow lab recovery (Finding 3)"
    # rm -f "${SCRIPT_DIR}/setup.sh" "${SCRIPT_DIR}/generate_student_flags.py"
    # rm -rf "${SCRIPT_DIR}/.git"
fi

echo "==[🎉] Lab 03 ready for ${STUDENT_ID}!"
echo "   Briefing portal : http://novatech.local:8083"
echo "   SSH entry point : ssh pentest@<VM_IP> -p 2222  (pass: ${PENTEST_PASS})"
echo "   Segment Alpha   : 10.10.10.0/24  (pivot required)"
echo "   Segment Beta    : 172.16.50.0/24 (double pivot required)"
