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
- 🎥 **Video Explainer:** *(link will be added after upload)*

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

```
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
```

This is **defense in depth** — two independent firewalls (Azure NSG + UFW host firewall), so a misconfiguration in one does not expose the server.

---

## Security Audit Script

A custom Bash script that performs seven security health checks and publishes a styled HTML dashboard:

1. Failed SSH login attempts (from system journal) — brute-force detection
2. Active SSH sessions — unauthorized access detection
3. Listening network ports — attack surface monitoring
4. UFW firewall status — security baseline verification
5. SSL/TLS certificate expiry — downtime prevention
6. Pending system updates — vulnerability management
7. System resource health — operational monitoring

The script runs via cron every hour at minute zero. The output is published live at [https://status.alazimazxyz.xyz](https://status.alazimazxyz.xyz) and is independently verifiable.

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
