# ICT171 Cloud Server Project

**Student Name:** MD ABDULLAH AL AZIM
**Student Number:** 36018444
**Unit:** ICT171 — Introduction to Server Environments and Architectures
**Semester:** 2026 S1

## Live Server
- **Domain:** https://alazimazxyz.xyz (will update once configured)
- **Public IP:** TBD (will update after VM provisioning)
- **Video Explainer:** TBD (link added after recording)

## Project Overview
A multi-purpose Ubuntu server hosted on Microsoft Azure, running:
- Ghost CMS for the main website
- WireGuard VPN for secure remote access
- Custom security audit script with web-accessible output

All services run on a single Azure VM with Nginx reverse proxy and manually configured Let's Encrypt SSL.

## Documentation Index
- [01 — Azure VM Provisioning](docs/01-azure-vm-setup.md)
- [02 — Initial Server Hardening](docs/02-server-hardening.md)
- [03 — DNS Configuration](docs/03-dns-setup.md)
- [04 — Nginx & SSL Setup](docs/04-nginx-ssl.md)
- [05 — Ghost CMS Installation](docs/05-ghost-install.md)
- [06 — WireGuard VPN Setup](docs/06-wireguard-vpn.md)
- [07 — Security Audit Script](docs/07-audit-script.md)
