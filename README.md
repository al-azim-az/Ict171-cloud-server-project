# ICT171 Cloud Server Project

**Student Name:** MD Abdullah Al Azim
**Student Number:** 36018444
**University:** Murdoch University
**Unit:** ICT171 — Introduction to Server Environments and Architectures
**Semester:** 2026 S1

---

## Server Details

| Item | Details |
|---|---|
| **Public IP Address** | 20.5.169.97 |
| **Main Domain** | https://alazimazxyz.xyz |
| **Security Dashboard** | https://status.alazimazxyz.xyz |
| **Cloud Provider** | Microsoft Azure |
| **Region** | Australia East (Sydney) |
| **Operating System** | Ubuntu Server 24.04.4 LTS |
| **Web Server** | Nginx |
| **Subdomains Served** | `@`, `www`, `status` (+ `vpn` reserved) |
| **SSL Provider** | Let's Encrypt (auto-renewal enabled) |

---

## Project Overview

This project documents the manual end-to-end setup of a multi-purpose Ubuntu server on Microsoft Azure, accessible at **alazimazxyz.xyz** with full HTTPS encryption.

The server hosts:

- A **custom landing page** at the root domain, written in hand-coded HTML and CSS
- A **security audit dashboard** at the `status` subdomain, generated automatically every hour by a custom Bash script
- A comprehensive **GitHub documentation** of every step, written in both English and Bangla, so other ICT171 students can replicate the build

All components were configured manually via SSH on a single Azure VM, using Nginx server blocks for subdomain routing, UFW + Azure NSG for layered firewall protection, and Let's Encrypt with Certbot for automated certificate management.

---

## Live Components

- 🌐 **Main Site:** [https://alazimazxyz.xyz](https://alazimazxyz.xyz) — custom landing page
- 🛡️ **Security Dashboard:** [https://status.alazimazxyz.xyz](https://status.alazimazxyz.xyz) — live security monitoring
- 🎥 **Video Explainer:** [Watch on OneDrive](https://murdochuniversity-my.sharepoint.com/personal/36018444_student_murdoch_edu_au/_layouts/15/stream.aspx?id=%2Fpersonal%2F36018444%5Fstudent%5Fmurdoch%5Fedu%5Fau%2FDocuments%2F0529%20%281%29%2Emp4&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2Ee80d4f03%2Dfe0e%2D4ea6%2D8c02%2De70ae31b5760)

---

## Documentation Index

Detailed step-by-step documentation. Each file explains both **what** was done and **why**.

### English Technical Documentation
- [01 — Azure VM Setup](01-azure-vm-setup.md)
- [02 — SSH Connection](02-ssh-connection.md)
- [03 — Nginx & Firewall Setup](03-nginx-firewall-setup.md)

### Bangla–English Lab Notes
Mixed-language deep notes explaining concepts, commands, real-world context, and reflections.
- [Lab Note — Day 1: VM, SSH, Nginx, UFW](lab-note-day1-bangla.md)
- [Lab Note — Step 5: DNS Configuration](lab-note-step5-dns.md)
- [Lab Note — Step 6: DNS Verification & GitHub Documentation](lab-note-step6-verification-github.md)
- [Lab Note — Step 7: SSL/HTTPS Setup](lab-note-step7-ssl.md)

### Source Code
- [security-audit.sh](security-audit.sh) — Custom Bash script generating the security dashboard
- [index.html](index.html) — Custom landing page source

---

## Architecture Summary

​```
USER (Browser)
    │ HTTPS request
    ▼
NAMECHEAP DNS — alazimazxyz.xyz → 20.5.169.97
    │
    ▼
AZURE NSG — allows ports 22, 80, 443
    │
    ▼
UBUNTU 24.04 VM (ict171-server)
    │
    ├── UFW Firewall (host-level)
    │
    ├── Nginx (reverse proxy + SSL termination)
    │     ├── alazimazxyz.xyz → custom landing page
    │     └── status.alazimazxyz.xyz → security dashboard
    │
    └── Cron (hourly)
          └── security-audit.sh → generates dashboard HTML
​```

This is **defense in depth** — two independent firewalls (Azure NSG + UFW host firewall), so a misconfiguration in one does not expose the server.

---

## 🛡️ Custom Security Audit Script — Detailed Breakdown

This section documents the custom Bash script (`security-audit.sh`) developed for this project, including what it does, how it was written, and how to independently verify its output.

### What the Script Does (and Why It's Useful)

This script is **not a modified lab activity** — it is an original creation built specifically to address a real-world server operations problem: **continuous, automated security visibility**.

In a production environment, administrators need to know at a glance whether the server is being attacked, whether the firewall is working, whether the SSL certificate is about to expire, and whether the system needs patching. Running individual commands manually each time is impractical. This script automates that monitoring and presents the results as a styled HTML dashboard accessible from any browser.

The script performs **seven independent security health checks** and writes the results to a public-facing dashboard:

| # | Check | Linux Tool Used | What It Detects |
|---|---|---|---|
| 1 | Failed SSH login attempts (last 24h) | `journalctl _COMM=sshd` + `grep` | Brute-force attack attempts |
| 2 | Active SSH sessions | `who` + `wc -l` | Unauthorized concurrent access |
| 3 | Listening TCP/UDP ports | `sudo ss -tuln` + `awk` | Unexpected exposed services (attack surface) |
| 4 | UFW firewall status & rules | `sudo ufw status` | Misconfigured or disabled firewall |
| 5 | SSL/TLS certificate expiry | `openssl s_client` + `openssl x509` | Certificates near expiry (with day countdown) |
| 6 | Pending system updates | `apt list --upgradable` | Unpatched security vulnerabilities |
| 7 | System resource health | `df`, `free`, `uptime`, `uname` | Disk, memory, load, kernel issues |

### Why This Script Is Creative and Useful

| Lab activity baseline | This script's contributions |
|---|---|
| Prints text to terminal | Generates styled HTML dashboard with cards |
| Run manually when needed | Runs automatically every hour via cron |
| Output disappears when terminal closes | Output is persistent, public, and verifiable online |
| One or two basic checks | Seven distinct security checks |
| Local-only utility | Published live at a real public URL |
| No state interpretation | Calculates derived values (e.g. SSL days remaining) |
| Static structure | Color-coded status badges (OK/Warn/Danger) based on logic |

The script combines **system administration**, **security monitoring**, **HTML/CSS generation**, and **automation scheduling** into a single, self-contained utility that demonstrates the breadth of the ICT171 learning outcomes in one file.

### Script Documentation — Inline Comments

The script (`security-audit.sh`) is **fully documented inline**, so anyone reading the source can understand its purpose without external context. Documentation appears in three forms:

**1. File header block** — explains the script's purpose, author, project, and the full list of checks performed:
​```bash
#!/bin/bash
#==============================================================================
# Security Audit Dashboard Generator
# Project : ICT171 Cloud Server Project
# Author  : MD Abdullah Al Azim (36018444)
# Murdoch University — 2026 S1
#
# Purpose:
#   Performs automated security health checks on the server and generates
#   a polished HTML dashboard published at https://status.alazimazxyz.xyz
#
# Checks performed:
#   1. Failed SSH login attempts (brute-force detection)
#   2. Active SSH sessions (unauthorized access detection)
#   ...
#==============================================================================
​```

**2. Section comments** — every functional block has a comment explaining its role:
​```bash
#-------------------------------------------------------------------------------
# Data Collection Section
#-------------------------------------------------------------------------------

# (1) Failed SSH login attempts from system journal (last 24h)
FAILED_SSH=$(sudo journalctl _COMM=sshd --since "24 hours ago" 2>/dev/null \
             | grep -ci "failed password" || echo "0")
​```

**3. Logic-step comments** — non-obvious calculations and decisions are explained:
​```bash
# Compute SSL certificate days remaining
if [ -n "$SSL_RAW" ]; then
    SSL_EXPIRY_EPOCH=$(date -d "$SSL_RAW" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    SSL_DAYS_LEFT=$(( (SSL_EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
fi
​```

A new reader can therefore follow the entire script top-to-bottom and understand both **what is happening** and **why each step is necessary**.

### Verifiable Output (Live Dashboard)

The script's output is **published online and is independently verifiable by anyone**, including markers, without needing access to the server.

**🔗 Live dashboard:** [https://status.alazimazxyz.xyz](https://status.alazimazxyz.xyz)

The dashboard:

- Displays a **"Last updated" timestamp** at the top that changes every time the script runs
- Shows all seven security checks as separate visual cards
- Uses **color-coded status badges** (green OK / yellow Warn) calculated from the data
- Is **automatically refreshed every hour** by the cron job — no human intervention required

This means the dashboard is not a static screenshot or pre-rendered HTML — it is the **genuine, current output** of a Bash script running on this server. The timestamp at the top of the page is the clearest proof of this; running the script via SSH and refreshing the dashboard will show a matching, updated timestamp.

### Deployment Steps (Reproducibility)

Anyone can recreate this script's deployment by following these steps:

​```bash
# 1. Create the scripts directory
mkdir -p ~/scripts

# 2. Download the script from this repository
curl -o ~/scripts/security-audit.sh \
  https://raw.githubusercontent.com/al-azim-az/ict171-cloud-server-project/main/security-audit.sh

# 3. Make it executable
chmod +x ~/scripts/security-audit.sh

# 4. Create the output directory served by Nginx
sudo mkdir -p /var/www/status

# 5. Run it once to generate the initial dashboard
sudo bash ~/scripts/security-audit.sh

# 6. Schedule it to run every hour via cron
(sudo crontab -l 2>/dev/null; echo "0 * * * * /bin/bash /home/azureuser/scripts/security-audit.sh >> /var/log/security-audit.log 2>&1") | sudo crontab -
​```

After these steps, the dashboard will be live and auto-updating.

### Nginx Configuration for the Status Subdomain

The dashboard is served by a dedicated Nginx server block (`/etc/nginx/sites-available/status`):

​```nginx
server {
    listen 80;
    listen [::]:80;
    server_name status.alazimazxyz.xyz;

    root /var/www/status;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Certbot adds the SSL configuration here automatically
    # when the certificate is expanded to cover this subdomain.
}
​```

This server block is what makes the multi-purpose architecture work — Nginx examines the `Host` header of every incoming request and routes `status.alazimazxyz.xyz` requests here, while the main domain is served by a separate block.

---

## How to Replicate

Anyone with a fresh Azure subscription and a domain can rebuild this server by following the documentation in order:

1. **Provision VM** — see [01 — Azure VM Setup](01-azure-vm-setup.md)
2. **Connect via SSH** — see [02 — SSH Connection](02-ssh-connection.md)
3. **Install Nginx + UFW** — see [03 — Nginx & Firewall Setup](03-nginx-firewall-setup.md)
4. **Configure DNS** — see [Lab Note — Step 5](lab-note-step5-dns.md)
5. **Verify and document** — see [Lab Note — Step 6](lab-note-step6-verification-github.md)
6. **Install SSL/TLS** — see [Lab Note — Step 7](lab-note-step7-ssl.md)
7. **Deploy security script** — copy [security-audit.sh](security-audit.sh) and configure cron

Estimated rebuild time from documentation: ~1 hour.

---

## References

- Microsoft Azure Documentation — https://learn.microsoft.com/en-us/azure/
- Ubuntu Server Documentation — https://ubuntu.com/server/docs
- Nginx Documentation — https://nginx.org/en/docs/
- Let's Encrypt / Certbot — https://certbot.eff.org/
- Namecheap DNS — https://www.namecheap.com/support/knowledgebase/
- Murdoch University ICT171 Course Materials — 2026 S1

---

## License

MIT License — see [LICENSE](LICENSE) for details.
