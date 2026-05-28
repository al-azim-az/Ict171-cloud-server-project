# 01 — Azure VM Provisioning

## Objective

Provision an Ubuntu 24.04 LTS virtual machine on Microsoft Azure to serve as the foundation infrastructure for this project. This VM will host the Nginx web server, Ghost CMS, WireGuard VPN, and a custom security audit script.

## Why a Virtual Machine (IaaS) Specifically

This project uses **Infrastructure-as-a-Service (IaaS)** rather than Platform-as-a-Service (PaaS) or Software-as-a-Service (SaaS) because the assignment brief explicitly requires SSH access to the underlying operating system to demonstrate manual server configuration. With IaaS, the cloud provider supplies the hardware abstraction (compute, storage, networking) while we retain full control over the operating system layer and everything above it. This control is essential for learning real-world server administration.

## Cloud Provider Choice — Microsoft Azure

Azure was selected for three reasons:

1. **Murdoch University provides Azure for Students credits** (A$140 of free credit, renewed annually), making this exercise zero-cost.
2. Azure offers **750 free hours per month** of B-series VMs under the student program, which more than covers a single VM running 24/7.
3. Azure's Australia East region (Sydney) provides the lowest network latency from Perth, improving the developer experience for SSH sessions.

## Resource Configuration

| Resource | Value | Reasoning |
|----------|-------|-----------|
| Subscription | Azure for Students | Free credit pool for academic projects |
| Resource Group | `ict171-rg` | Logical container for all project resources; enables clean teardown by deleting the group |
| VM Name | `ict171-server` | Descriptive, project-scoped naming convention |
| Region | Australia East (Sydney, Zone 1) | Lowest latency from Perth; reduces SSH and admin overhead |
| Image | Ubuntu Server 24.04 LTS (Gen 2) | LTS = Long Term Support; security patches until 2029. Widely documented; standard server OS |
| Size | Standard_B2ats_v2 (2 vCPU, 1 GiB RAM) | Burstable performance tier; sufficient for low-traffic blog + VPN + custom script |
| OS Disk | Standard SSD (Locally Redundant Storage) | Adequate I/O performance at ~25% the cost of Premium SSD |
| Authentication | SSH public key (RSA) | Cryptographically secure; eliminates password brute-force attack surface |

### What is a Resource Group?

A Resource Group in Azure is a logical container that holds related resources (VMs, disks, public IPs, network interfaces, etc.). Grouping resources together provides three operational benefits:

1. **Atomic lifecycle management** — deleting the resource group deletes everything inside it, preventing orphaned resources that incur ongoing cost.
2. **Unified access control** — permissions can be assigned at the group level.
3. **Cost visibility** — Azure cost reports can be filtered by resource group to see exactly what a project is spending.

### Why Standard SSD over Premium SSD

Premium SSD provides higher IOPS (input/output operations per second) and lower latency, but costs approximately 4× more. For a workload that primarily serves static blog content and occasional VPN traffic, Standard SSD's performance is more than sufficient. Premium SSD becomes worthwhile only for I/O-intensive workloads such as databases under heavy load.

### Why RSA SSH Keys over Passwords

Password authentication is vulnerable to brute-force attacks. Every server with port 22 exposed to the internet receives constant automated login attempts. SSH key authentication replaces this with public-key cryptography:

- The **public key** is placed on the server in `~/.ssh/authorized_keys`
- The **private key** stays on the user's local machine
- During login, the server challenges the client to prove possession of the private key
- Without the private key, login is computationally infeasible

A 3072-bit RSA key (Azure's default) is currently considered cryptographically strong against brute-force attacks for at least the next decade.

## Inbound Network Rules (Initial)

Azure's Network Security Group (NSG) controls inbound traffic at the cloud-provider level, separate from any firewall running on the VM itself. Initial rules configured during provisioning:

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 22 | TCP | SSH | Encrypted remote administrative access |
| 80 | TCP | HTTP | Web traffic (will redirect to HTTPS after SSL setup) |
| 443 | TCP | HTTPS | TLS-encrypted web traffic |

UDP port 51820 will be added later for WireGuard VPN.

### Defense-in-Depth — NSG plus UFW

This project uses two layers of firewall:

1. **Azure NSG** — perimeter firewall at the cloud platform level; filters traffic before it reaches the VM
2. **UFW (on the VM)** — host-based firewall running inside Ubuntu

Both must allow traffic for a connection to succeed. This layered approach (defense-in-depth) is a fundamental security principle: if one layer is misconfigured or compromised, the other still provides protection.

## Provisioning Process

1. Navigated to Azure Portal → Virtual Machines → Create
2. Selected the configuration values shown in the table above
3. Generated a new RSA SSH key pair via the Azure portal
4. Downloaded the private key (`ict171-server_key.pem`) to the local machine
5. Set the inbound port rules
6. Reviewed and created the deployment

Deployment completed in approximately 3 minutes. The VM was assigned a public IPv4 address: **20.5.169.97**.

## Output

- **VM Name:** ict171-server
- **Public IPv4:** 20.5.169.97
- **Private IPv4 (Azure VNet):** 10.1.0.4
- **OS:** Ubuntu 24.04.4 LTS (kernel 6.17.0-1015-azure)
- **Resource Group:** ict171-rg
- **Region:** Australia East (Zone 1)

## Verification

VM status confirmed as "Running" in the Azure portal. Public IP allocated and visible on the VM overview page. SSH connectivity verified in step 02.

## Teardown Note

When this project is complete, the entire infrastructure can be removed by deleting the `ict171-rg` resource group. This deletes the VM, OS disk, public IP, network interface, virtual network, and Network Security Group atomically, with no residual cost.
