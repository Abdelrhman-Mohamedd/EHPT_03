#!/usr/bin/env bash
# ==============================================================================
# prepare_template_vm.sh — Instructor-Run Golden Template Preparation Script
# Lab 03: NovaTech Corp — Pivoting, Tunneling & Lateral Movement
# Run ONCE on the base Rocky Linux VM (as root) before distributing to students.
#
# Usage: sudo ./prepare_template_vm.sh [SECRET_SALT]
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[-] Please run as root: sudo ./prepare_template_vm.sh [SECRET_SALT]"
    exit 1
fi

STUDENT_USER="student"
SECRET_SALT="${1:-EHPT03_SECRET_SALT_2026}"
EHPT_DIR="/opt/lab03-setup"

echo "=============================================================================="
echo "[*] Preparing Lab 03 Black-Box Template VM"
echo "    Theme: Pivoting, Tunneling & Lateral Movement"
echo "=============================================================================="

# ---- 1. Create student user ----
echo "[+] Step 1: Creating student user '${STUDENT_USER}'..."
if ! id -u "$STUDENT_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$STUDENT_USER"
    echo "    Created user ${STUDENT_USER}"
fi
gpasswd -d "$STUDENT_USER" wheel 2>/dev/null || true
gpasswd -d "$STUDENT_USER" sudo  2>/dev/null || true
echo "${STUDENT_USER}:labpassword" | chpasswd
echo "    Password set to: labpassword  (change this before distributing!)"

# ---- Hide 'cyberlabs' from GDM login screen ----
echo "[+] Step 1b: Hiding 'cyberlabs' from GDM login screen..."
mkdir -p /var/lib/AccountsService/users/
cat > /var/lib/AccountsService/users/cyberlabs << 'ACCT'
[User]
SystemAccount=true
ACCT
chmod 644 /var/lib/AccountsService/users/cyberlabs

# ---- Copy UI settings ----
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    echo "[+] Step 1c: Copying Desktop/UI settings from ${SUDO_USER} to student..."
    [ -d "/home/${SUDO_USER}/Desktop" ] && cp -r "/home/${SUDO_USER}/Desktop" "/home/${STUDENT_USER}/"
    if [ -d "/home/${SUDO_USER}/.config/dconf" ]; then
        mkdir -p "/home/${STUDENT_USER}/.config"
        cp -r "/home/${SUDO_USER}/.config/dconf" "/home/${STUDENT_USER}/.config/"
    fi
    if [ -d "/home/${SUDO_USER}/.local/share/backgrounds" ]; then
        mkdir -p "/home/${STUDENT_USER}/.local/share"
        cp -r "/home/${SUDO_USER}/.local/share/backgrounds" "/home/${STUDENT_USER}/.local/share/"
    fi
    chown -R "${STUDENT_USER}:${STUDENT_USER}" "/home/${STUDENT_USER}/Desktop" "/home/${STUDENT_USER}/.config" "/home/${STUDENT_USER}/.local" 2>/dev/null || true
fi

# ---- 2. Install dependencies ----
echo "[+] Step 2: Installing dependencies (zenity, php, openssh-server, iproute, iptables)..."
dnf install -y zenity php php-cli openssh-server iproute iptables >/dev/null 2>&1 && echo "    Packages installed." || echo "    [!] Some packages may have failed — verify manually."

# ---- 3. Store secret salt ----
echo "[+] Step 3: Storing secret salt in /etc/lab03.conf (root-only)..."
echo "${SECRET_SALT}" > /etc/lab03.conf
chown root:root /etc/lab03.conf
chmod 600 /etc/lab03.conf
echo "    Salt stored at /etc/lab03.conf  (mode: 600 — student access: DENIED)"

# ---- 4. Deploy EHPT_03 repo to /opt/lab03-setup/ ----
echo "[+] Step 4: Deploying lab files to ${EHPT_DIR}..."
mkdir -p "$EHPT_DIR"
cp -a ./* "$EHPT_DIR/"
cp -a ./.[!.]* "$EHPT_DIR/" 2>/dev/null || true
chown -R root:root "$EHPT_DIR"
chmod 700 "$EHPT_DIR"
find "$EHPT_DIR" -type d -exec chmod 700 {} \;
find "$EHPT_DIR" -type f -exec chmod 600 {} \;
chmod 500 "${EHPT_DIR}/setup.sh"
echo "    ${EHPT_DIR}  mode=700 (root:root) — student cannot ls, read, or enter"

# ---- 5. Install first-boot wizard ----
echo "[+] Step 5: Installing first_boot_setup.sh wizard..."
cp "${EHPT_DIR}/first_boot_setup.sh" "/home/${STUDENT_USER}/first_boot_setup.sh"
chown root:root "/home/${STUDENT_USER}/first_boot_setup.sh"
chmod 755 "/home/${STUDENT_USER}/first_boot_setup.sh"

AUTOSTART_DIR="/home/${STUDENT_USER}/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
cat > "${AUTOSTART_DIR}/lab03-setup.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Lab 03 First Boot Setup
Exec=bash /home/student/first_boot_setup.sh
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=3
DESKTOP
chown -R "${STUDENT_USER}:${STUDENT_USER}" "/home/${STUDENT_USER}/.config"
echo "    GNOME autostart entry created."

# ---- Suppress GNOME Initial Setup dialog ----
touch "/home/${STUDENT_USER}/.config/gnome-initial-setup-done"
chown "${STUDENT_USER}:${STUDENT_USER}" "/home/${STUDENT_USER}/.config/gnome-initial-setup-done"

# ---- 6. Narrowly scoped sudoers rule ----
echo "[+] Step 6: Configuring restricted sudoers rule..."
cat << EOF > /etc/sudoers.d/lab03-setup
# Lab 03: student may ONLY run setup.sh as root
student ALL=(root) NOPASSWD: /opt/lab03-setup/setup.sh *
EOF
chmod 440 /etc/sudoers.d/lab03-setup
visudo -c -f /etc/sudoers.d/lab03-setup && echo "    Sudoers rule OK." || echo "[!] sudoers syntax error!"

# ---- 7. Harden SSH & Generate Host Keys ----
echo "[+] Step 7: Hardening SSH and ensuring host keys exist..."
/usr/bin/ssh-keygen -A 2>/dev/null || true
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
# Ensure SSH is enabled (needed for the pivot exercise)
systemctl enable sshd
systemctl restart sshd 2>/dev/null || true
echo "    Host keys generated. Root SSH login disabled. sshd enabled for pivot exercise."

# ---- 7b. Disable SELinux and Firewalld (Lab Environment Fix) ----
echo "[+] Step 7b: Disabling SELinux and Firewalld for lab networking..."
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
echo "    SELinux set to permissive and Firewalld disabled."

# ---- 8. Install iproute2 / tools needed for netns ----
echo "[+] Step 8: Ensuring network namespace tools available..."
dnf install -y iproute2 iptables-nft 2>/dev/null || dnf install -y iproute iptables 2>/dev/null || true
modprobe tun 2>/dev/null || true
echo "    Network namespace tools ready."

# ---- 9. Pre-login banner ----
echo "[+] Step 9: Setting pre-login banner..."
cat << 'BANNER' > /etc/issue.net
╔═══════════════════════════════════════════════════════════════════╗
║    NovaTech Ethical Hacking Lab 03 — Black-Box Appliance          ║
║    Topic: Pivoting, Tunneling & Lateral Movement                  ║
║    Unauthorized access is strictly prohibited.                    ║
╚═══════════════════════════════════════════════════════════════════╝
Login as: student / labpassword (change before distributing)
BANNER

# ---- 10. Lock root password ----
echo "[+] Step 10: Locking root password..."
passwd -l root
echo "    Root account locked."

echo "=============================================================================="
echo "[✅] Template VM Preparation Complete!"
echo ""
echo "     Student User    : ${STUDENT_USER} / labpassword"
echo "     EHPT_03 Repo    : /opt/lab03-setup/  (root:root 700)"
echo "     Secret Salt     : /etc/lab03.conf    (root:root 600)"
echo "     Student Sudo    : ONLY /opt/lab03-setup/setup.sh (nothing else)"
echo "     First-Boot UI   : /home/student/first_boot_setup.sh (contains NO salt)"
echo "     SSH Service     : enabled (required for pivot exercise)"
echo "     Root Login      : LOCKED"
echo ""
echo "     Before distribution:"
echo "       1. Change student password:  passwd ${STUDENT_USER}"
echo "       2. Test first-boot wizard as student user"
echo "       3. Export the VM to .OVA or .qcow2 and hand out one copy per student."
echo "=============================================================================="
