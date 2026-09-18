#!/usr/bin/env bash
# ==============================================================================
# first_boot_setup.sh — Student First-Boot Personalization Wizard (GUI Mode)
# Lab 03: OperaLink Logistics Network — Pivoting, Tunneling & Lateral Movement
# Triggered via GNOME autostart .desktop file.
# Uses zenity GUI dialogs. Removes its own autostart entry on success.
# ==============================================================================

SETUP_SCRIPT="/opt/lab03-setup/setup.sh"
FIRST_BOOT_FLAG="/home/student/.lab03_provisioned"
AUTOSTART_DESKTOP="/home/student/.config/autostart/lab03-setup.desktop"

# ---- Guard: only run once ----
if [ -f "$FIRST_BOOT_FLAG" ]; then
    exit 0
fi

# ---- Dependency check ----
if ! command -v zenity >/dev/null 2>&1; then
    notify-send "Lab 03 Setup" "Error: zenity is not installed. Please contact your instructor." 2>/dev/null || true
    exit 1
fi

# ---- Welcome Dialog ----
zenity --info \
    --title="NovaTech Ethical Hacking Lab 03" \
    --width=460 \
    --text="<b>Welcome to Lab 03: NovaTech Corp</b>\n\nThis VM must be personalized using your unique <b>Student ID</b> before you can begin.\n\nThis lab covers:\n• SSH Local Port Forwarding (-L)\n• Dynamic SOCKS5 Proxies (-D)\n• SSH ProxyJump (-J)\n• Chained ProxyJump / Double Pivoting\n• SSH Key Lateral Movement\n\nClick <b>OK</b> to continue." \
    2>/dev/null || exit 1

# ---- Student ID Input + Confirmation Loop ----
while true; do
    SID=$(zenity --entry \
        --title="Lab 03 — Student ID Required" \
        --width=420 \
        --text="Enter your <b>Student ID</b> exactly as assigned by your instructor.\n\n<small>Example: 231000000</small>" \
        --entry-text="" \
        2>/dev/null)

    if [ $? -ne 0 ]; then
        zenity --warning --title="Lab 03 Setup" --width=380 \
            --text="Setup cancelled. Please log out and log back in to try again." \
            2>/dev/null || true
        exit 1
    fi

    SID="${SID// /_}"

    if [[ -z "$SID" ]]; then
        zenity --error --title="Invalid Input" --width=380 \
            --text="Student ID cannot be empty. Please try again." 2>/dev/null || true
        continue
    fi

    if [[ ! "$SID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        zenity --error --title="Invalid Input" --width=380 \
            --text="Invalid characters in Student ID.\n\nOnly letters, digits, hyphens ( - ) and underscores ( _ ) are allowed." 2>/dev/null || true
        continue
    fi

    zenity --question \
        --title="Confirm Student ID" \
        --width=420 \
        --text="Your Student ID is:\n\n<b>${SID}</b>\n\nAre you sure this is correct?\n<small>This cannot be changed after confirming.</small>" \
        2>/dev/null

    if [ $? -eq 0 ]; then
        break
    fi
done

# ---- Progress: Run setup.sh, show progress bar ----
(
    echo "# Provisioning OperaLink lab environment for ${SID}..."
    echo "10"

    sudo "$SETUP_SCRIPT" "$SID" --production > /tmp/lab03_setup.log 2>&1
    SETUP_EXIT=$?

    echo "90"
    sleep 1
    echo "100"

    echo "$SETUP_EXIT" > /tmp/lab03_setup_exit
) | zenity --progress \
    --title="Lab 03 Setup — Please Wait" \
    --width=460 \
    --text="Personalizing your lab environment...\n\nThis will take approximately 30–60 seconds.\n(Setting up network namespaces and internal services)" \
    --percentage=0 \
    --auto-close \
    --no-cancel \
    2>/dev/null

# ---- Read exit code ----
SETUP_EXIT=1
if [ -f /tmp/lab03_setup_exit ]; then
    SETUP_EXIT=$(cat /tmp/lab03_setup_exit)
    rm -f /tmp/lab03_setup_exit
fi

if [ "$SETUP_EXIT" -eq 0 ]; then
    VM_IP=$(hostname -I | awk '{print $1}')

    touch "$FIRST_BOOT_FLAG"
    rm -f "$AUTOSTART_DESKTOP" 2>/dev/null || true
    rm -f /home/student/first_boot_setup.sh 2>/dev/null || true

    zenity --info \
        --title="Lab 03 Ready! 🎉" \
        --width=500 \
        --text="<b>Your NovaTech lab environment is ready!</b>\n\n<b>Student ID:</b> ${SID}\n<b>Portal URL:</b> http://${VM_IP}:8083\n\n<b>Topology:</b>\n• DMZ Portal: http://${VM_IP}:8083\n• SSH Pivot:  pentest@${VM_IP}:2222\n• Internal:  10.10.10.20:8080 / 172.16.50.10:9090 (only via pivot)\n\nOpen a browser and navigate to the portal to begin.\n\nGood luck — pivot carefully! 🕵️" \
        2>/dev/null || true
else
    SETUP_LOG=$(cat /tmp/lab03_setup.log 2>/dev/null | tail -20 || echo "No log output.")
    zenity --error \
        --title="Lab 03 Setup Failed" \
        --width=480 \
        --text="Lab provisioning failed.\n\nPlease contact your instructor and provide the following log:\n\n<tt>${SETUP_LOG}</tt>" \
        2>/dev/null || true
fi
