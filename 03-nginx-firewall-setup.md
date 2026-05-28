# 03 — Nginx Installation and UFW Firewall Configuration

## Objective

Install Nginx as the primary web server on the freshly provisioned VM, and configure UFW (Uncomplicated Firewall) to allow only the necessary inbound traffic. By the end of this step, the VM serves a default web page on the public internet, with all non-essential ports blocked.

## Why Nginx

Nginx is a high-performance, event-driven web server that powers a significant portion of the world's busiest websites. It was selected for this project for three reasons:

1. **Reverse proxy capability** — Nginx can sit in front of Ghost CMS (which runs on Node.js port 2368) and the security status page, routing requests to the correct backend based on the requested hostname. This allows multiple services to share ports 80 and 443.
2. **TLS termination** — Nginx handles SSL/TLS encryption efficiently, freeing backend applications from cryptographic overhead.
3. **Static file serving** — Nginx serves static files (HTML, CSS, JS, images) faster and more efficiently than application servers.

The alternative — Apache HTTP Server — is also widely used, but Nginx's event-driven architecture handles many simultaneous connections with lower memory overhead, making it more suitable for a small VM.

## Why UFW

`ufw` (Uncomplicated Firewall) is a user-friendly front-end to `iptables`, Ubuntu's built-in packet filtering system. Raw `iptables` syntax is powerful but error-prone; `ufw` provides a simpler interface for common operations.

Even with Azure's Network Security Group (NSG) filtering traffic at the cloud provider level, a host-based firewall on the VM itself provides **defense-in-depth**. If the NSG is ever misconfigured to allow additional ports, the UFW layer still enforces the intended policy.

## Step 1 — Update Package Lists and Upgrade Installed Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Breakdown

| Component | Purpose |
|-----------|---------|
| `sudo` | Executes the following command with superuser (root) privileges. Required because package management modifies system files. |
| `apt` | Advanced Package Tool — Ubuntu/Debian's package manager |
| `update` | Refreshes the local index of available packages from configured repositories. Does **not** install or upgrade anything; only updates the catalog. |
| `&&` | Shell operator meaning "if the previous command succeeded, run the next one." Prevents wasted effort if the update fails. |
| `upgrade` | Installs the latest available version of every currently installed package |
| `-y` | Auto-answers "yes" to all confirmation prompts; required for non-interactive execution |

### Why Update First

Running `apt upgrade` without first running `apt update` would compare installed packages against a stale catalog, potentially missing recent security patches. Always update before upgrading.

### Why Patch Before Installing New Services

The newly provisioned VM ships with packages frozen at the time the Azure image was built (often weeks or months ago). Unpatched packages may contain known vulnerabilities. Applying updates **before** exposing services to the internet closes this window of exposure.

## Step 2 — Install Nginx and Supporting Tools

```bash
sudo apt install -y nginx ufw curl git
```

### Packages installed

| Package | Purpose |
|---------|---------|
| `nginx` | The Nginx web server itself, including the systemd service definition |
| `ufw` | Uncomplicated Firewall — usually pre-installed but explicitly requested for safety |
| `curl` | Command-line HTTP client; useful for testing and debugging local services |
| `git` | Version control system; useful for cloning configuration repositories or scripts later |

### What `apt install` Actually Does

1. Resolves dependencies — identifies any other packages required by the requested ones
2. Downloads `.deb` package files from Ubuntu's repositories
3. Verifies cryptographic signatures on the packages
4. Unpacks the files into the correct filesystem locations
5. Runs any post-install scripts (which, in Nginx's case, start the service and enable it for boot)

## Step 3 — Verify Nginx is Running

```bash
sudo systemctl status nginx
```

### Breakdown

| Component | Purpose |
|-----------|---------|
| `systemctl` | The control utility for `systemd`, the system and service manager used by modern Ubuntu |
| `status` | Subcommand requesting the current state of a service |
| `nginx` | The service name |

### Interpreting the Output

A healthy Nginx service displays:

```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-05-26 02:04:51 UTC; 12s ago
       Docs: man:nginx(8)
    Process: 2361 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; ...
    Process: 2363 ExecStart=/usr/sbin/nginx -g daemon on; ...
   Main PID: 2392 (nginx)
      Tasks: 3 (limit: 988)
     Memory: 2.4M (peak: 5.4M)
        CPU: 19ms
     CGroup: /system.slice/nginx.service
             ├─2392 "nginx: master process /usr/sbin/nginx -g daemon on; ..."
             ├─2395 "nginx: worker process"
             └─2396 "nginx: worker process"
```

### Key Indicators

| Field | Healthy Value | Meaning |
|-------|---------------|---------|
| Coloured dot | Green (●) | Service is alive |
| `Loaded` | `loaded ... enabled` | Service definition is valid AND set to start at boot |
| `Active` | `active (running)` | Service is currently running |
| `Main PID` | A process ID number | Master process is alive |
| `Tasks` | 3 (one master + worker processes) | Nginx is operating in its normal multi-process mode |

### Exiting the Pager

`systemctl status` displays output through a pager (`less` by default). The terminal appears stuck because the pager is waiting for keyboard input.

- Press **`q`** to quit the pager and return to the shell prompt

This is a common point of confusion for new Linux users. The output is not frozen; it's waiting for input.

## Step 4 — Configure the UFW Firewall

### Critical: Order of Operations

UFW must be configured in a specific order to avoid locking yourself out of the SSH session:

1. **Allow SSH first** — before enabling the firewall
2. **Allow other services** — HTTP, HTTPS, etc.
3. **Enable the firewall** — only after rules are in place

Enabling UFW before allowing SSH would immediately terminate the current SSH session and prevent any further remote access. Recovery would require Azure's serial console or VM rebuild.

### 4a — Allow SSH

```bash
sudo ufw allow OpenSSH
```

`OpenSSH` is a pre-defined UFW application profile that corresponds to TCP port 22. UFW ships with profiles for common services in `/etc/ufw/applications.d/`.

Expected output:
```
Rules updated
Rules updated (v6)
```

The two lines confirm that rules were added for both IPv4 and IPv6.

### 4b — Allow HTTP and HTTPS

```bash
sudo ufw allow 'Nginx Full'
```

`Nginx Full` is another pre-defined profile that opens **both** port 80 (HTTP) and port 443 (HTTPS) in a single command. Alternatives are:

- `Nginx HTTP` — port 80 only
- `Nginx HTTPS` — port 443 only
- `Nginx Full` — both (used here)

The quotes are required because the profile name contains a space.

### 4c — Enable the Firewall

```bash
sudo ufw enable
```

UFW will display a warning:

```
Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```

This is a safety check. As long as the SSH allow rule was added in step 4a, the current session will not be disrupted. Type `y` and press Enter.

Expected output:
```
Firewall is active and enabled on system startup
```

The "enabled on system startup" confirmation is important — it means UFW will automatically re-activate every time the VM boots, without requiring manual intervention.

### 4d — Verify Active Rules

```bash
sudo ufw status
```

Expected output:

```
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
Nginx Full                 ALLOW       Anywhere
OpenSSH (v6)               ALLOW       Anywhere (v6)
Nginx Full (v6)            ALLOW       Anywhere (v6)
```

### Interpreting the Rule Table

| Column | Meaning |
|--------|---------|
| `To` | The local service or port the rule applies to |
| `Action` | What to do with matching traffic (ALLOW, DENY, REJECT) |
| `From` | The source address(es) allowed; `Anywhere` means any IP can connect |

### Default Deny Policy

UFW's default policy is `deny incoming, allow outgoing`. This means:

- Any inbound traffic not matching an `ALLOW` rule is silently dropped
- Outbound traffic (e.g. `apt` fetching updates, the server initiating connections) is permitted

This "default deny" stance is the security best practice — it minimises the attack surface by exposing only services that have been explicitly opened.

## Step 5 — Verify Public Accessibility

From a web browser on a separate machine, navigate to:

```
http://20.5.169.97
```

The browser displays the default Nginx welcome page:

> **Welcome to nginx!**
>
> If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

This confirms the entire stack is functioning:

1. The packet leaves the client's browser
2. Routes through the public internet to Azure's Australia East datacenter
3. Passes Azure's Network Security Group (port 80 allowed)
4. Reaches the VM
5. Passes UFW (Nginx Full rule)
6. Is received by Nginx
7. Nginx returns `/var/www/html/index.nginx-debian.html`
8. The response traverses the same path in reverse

The "Not Secure" warning shown by the browser is expected — SSL/TLS has not yet been configured. This is addressed in step 04.

## Summary of Defensive Posture After This Step

| Layer | Status |
|-------|--------|
| Azure NSG | Allows ports 22, 80, 443 only |
| UFW (host) | Allows SSH, HTTP, HTTPS only; all other inbound denied |
| SSH authentication | Key-only; password authentication not used |
| Patch level | Fully up-to-date as of provisioning date |
| Web server | Running, persistent across reboots |

The VM is now a hardened, internet-facing web server. Subsequent steps add domain mapping, encryption (SSL/TLS), application services (Ghost CMS, WireGuard), and the custom security script.
