# ICT171 ল্যাব নোট — Cloud Server Setup (Day 1)

**Student:** MD Abdullah Al Azim
**Student ID:** 36018444
**Date:** 26 May 2026
**Topic:** Azure VM Provisioning → SSH Connection → Nginx Install → UFW Firewall

---

## ভূমিকা 📖

এই note এ আমরা একটা production-grade cloud server **শূন্য থেকে শুরু করে** কীভাবে build করি — সেটা step-by-step বুঝবো। আজ যা যা করেছি:

1. Microsoft Azure এ একটা **Virtual Machine (VM)** provision করেছি
2. Windows PowerShell থেকে **SSH** দিয়ে server এ connect করেছি
3. Server এ **Nginx web server** install করেছি
4. **UFW firewall** configure করে server টা harden করেছি
5. Public IP দিয়ে browser থেকে website access verify করেছি

প্রতিটা topic এ ৬টা করে section থাকবে যাতে exam, viva, আর real job সবখানে কাজে লাগে।

---

# 🌥️ Topic 1: Cloud Computing এবং IaaS Model

## ১. Concept (এটা কী এবং কেন)

**Cloud computing** মানে হলো internet এর মাধ্যমে computer resources (server, storage, network) ভাড়া নেওয়া। তুমি নিজে physical hardware কিনবে না — Microsoft, Amazon, বা Google তোমাকে virtual resources দেবে, তুমি যতটুকু use করবে ঠিক ততটুকুর জন্য pay করবে।

Cloud এর ৩টা main service model আছে:

| Model | কী দেয় | তুমি কী manage করো | Example |
|---|---|---|---|
| **IaaS** (Infrastructure-as-a-Service) | শুধু VM, storage, network | OS থেকে শুরু করে application, data — সব কিছু | Azure VM, AWS EC2 |
| **PaaS** (Platform-as-a-Service) | OS + runtime ready থাকে | শুধু application code | Heroku, Azure App Service |
| **SaaS** (Software-as-a-Service) | পুরো application ready | কিছু না, শুধু use করো | Gmail, Office 365 |

আমার ICT171 assignment specifically **IaaS** চায়, কারণ assignment brief এ স্পষ্ট বলা আছে — "SSH or RDP access to the actual machine and configure and deploy your server software manually।" এই hands-on control শুধু IaaS এই পাওয়া যায়।

## ২. Command/Syntax

Portal GUI দিয়ে VM বানালে কোনো command লাগে না। কিন্তু Azure CLI দিয়ে automate করা যায়:

```bash
az vm create --resource-group ict171-rg \
             --name ict171-server \
             --image Ubuntu2404 \
             --size Standard_B1s \
             --admin-username azureuser \
             --generate-ssh-keys
```

## ৩. Deep Explanation (Core basics থেকে)

Traditional setup এ একটা website host করতে হলে তোমাকে নিজে:

1. **Physical server** কিনতে হবে (লাখ টাকা cost)
2. **Data center** এ রাখতে হবে (monthly rent)
3. **Power, cooling, internet** manage করতে হবে
4. **Hardware fail** করলে নিজে দায়ী

Cloud computing এই সব problem solve করে **virtualization** এর মাধ্যমে:

- Microsoft এর data center এ একটা **mega physical server** আছে (200+ CPU cores, 1TB RAM)
- **Hypervisor** নামের special software (Hyper-V, KVM) সেই server টাকে অনেকগুলো **virtual machines** এ ভাগ করে
- প্রতিটা VM দেখতে complete computer এর মতো — কিন্তু আসলে shared hardware এর একটা slice
- তুমি pay করবে শুধু যতক্ষণ VM চালু থাকবে, যতটুকু CPU/RAM use করবে

**Analogy:** Physical server হলো বাড়ি কেনা। Cloud VM হলো apartment ভাড়া নেওয়া — দরকার নাই কিনতে হবে, ছোট bachelor space থেকে বড় family flat যেকোনো সময় switch করা যায়।

## ৪. Real-life Server Example 🖥️

**Startup company:**
এক startup নতুন web app launch করেছে Azure B2s VM এ (A$30/month)। User base বাড়ার সাথে সাথে scale up করে B4ms (4 vCPU, 16 GB RAM) তে। Hardware ভাবার দরকার নাই, কয়েকটা click এ size change হয়ে যায়।

**Enterprise (Bank):**
DBBL তাদের core banking system AWS এ migrate করেছে। Disaster recovery এর জন্য Singapore region এ mirror রাখে। Production এ D-series (database optimized) VM use করে।

**Student (আমি):**
ICT171 project এ A$140 free credit দিয়ে full server stack practice করছি। Real cost নাই, কিন্তু real-world skill build হচ্ছে।

## ৫. Outcome (কী skill পেলাম)

- Cloud service models clearly বুঝেছি (IaaS vs PaaS vs SaaS)
- Virtualization এর basic concept clear
- Pay-as-you-go pricing model বুঝেছি
- Hardware abstraction layer এর role বুঝেছি

## ৬. When/Why আমি Use করবো

- **Job interview এ:** Cloud / DevOps role এ এটাই first question
- **Personal projects এ:** Server লাগলে local laptop এ host করতে হবে না
- **Career path এ:** Cyber security, cloud architecture, SRE — সব রোলেই cloud বুঝা mandatory

---

# ☁️ Topic 2: Azure VM Provisioning

## ১. Concept

**Provisioning** মানে cloud provider এর কাছে একটা নতুন virtual machine request করা ও create হওয়া। Portal এ ৮টা important decision নিতে হয়:

1. **Subscription** (কোথায় bill যাবে)
2. **Resource Group** (কোন group এ থাকবে)
3. **VM name** (পরিচয়)
4. **Region** (কোন data center)
5. **Image** (কোন OS)
6. **Size** (CPU/RAM কত)
7. **Authentication** (password নাকি SSH key)
8. **Network ports** (কোন কোন port open থাকবে)

প্রতিটা decision এর পিছনে engineering reasoning থাকে।

## ২. Command/Syntax

Portal use করলে command লাগে না। কিন্তু পেশাদার DevOps engineer Azure CLI use করে:

```bash
# প্রথমে Resource Group বানাও
az group create --name ict171-rg --location australiaeast

# তারপর VM
az vm create \
  --resource-group ict171-rg \
  --name ict171-server \
  --image Ubuntu2404 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard
```

## ৩. Deep Explanation

### Resource Group আসলে কী?

Azure তে প্রতিটা resource (VM, disk, network card, public IP, NSG) আলাদা **object**। Resource Group হলো একটা **logical container** — same project এর সব resource একটা group এ থাকে।

Benefits:

- **Atomic delete:** Resource group delete করলে ভেতরের সব কিছু একসাথে delete হয়। কোনো orphan resource থাকে না (যেগুলো silently bill কেটে চলতে থাকে)।
- **Permission control:** পুরো group এ একজনকে access দেওয়া যায় Azure RBAC দিয়ে।
- **Cost tracking:** Project-wise cost report পাওয়া যায়।

**Analogy:** Resource Group হলো একটা folder। ভেতরে অনেক files থাকে। Folder delete করলে files ও যায়।

### Region কেন Australia East?

Network latency = distance + routing hops। Perth থেকে:

- **Australia East** (Sydney): ~50ms latency ✅
- Australia Southeast (Melbourne): ~55ms
- Southeast Asia (Singapore): ~80ms
- East US: ~250ms ❌

SSH session এ 250ms latency মানে প্রতিটা key press এর পর 0.25 second wait — extremely frustrating। Sydney closest, তাই আমি এটা choose করেছি।

### VM Size — B-series কী?

Azure এর size naming convention:

| Letter | Series | Purpose |
|---|---|---|
| **B** | Burstable | Cheap, light workload, occasional spike |
| **D** | General purpose | Balanced, production |
| **F** | Compute optimized | High CPU work |
| **E** | Memory optimized | Database servers |

**B-series এর characteristic:** Normally low CPU baseline, কিন্তু burst দরকার হলে temporarily high CPU দেয়। Web server এর জন্য perfect — বেশিরভাগ সময় idle, occasional traffic spike handle করে।

আমার VM (B2ats_v2): 2 vCPU + 1 GiB RAM, A$30/month। Light blog + VPN + custom script — sufficient।

### Image — Ubuntu 24.04 LTS কেন?

- **Ubuntu** — সবচেয়ে popular Linux distribution, biggest community
- **Server** edition — কোনো GUI নাই, শুধু command line; RAM/CPU বাঁচে
- **24.04** — April 2024 release version
- **LTS** = Long Term Support — security patches পাওয়া যাবে 2029 পর্যন্ত

**Non-LTS** version 9 মাস পরে unsupported হয় — production এ dangerous।

### SSH Public Key কেন (password এর বদলে)?

Password authentication এ:
- Hacker bot internet scan করে port 22 open machine খোঁজে
- পেলে brute force শুরু করে (millions of passwords per second)
- Weak password হলে এক সময় crack হয়ে যায়

SSH key authentication এ:
- Server এ থাকে **public key**
- আমার laptop এ থাকে **private key**
- Login এর সময় server challenge দেয়, private key দিয়ে solve করি
- Without private key — brute force impossible (centuries লাগবে)

Azure portal automatically RSA 3072-bit key pair generate করেছে। Private key (`.pem` file) আমি download করেছি।

### Inbound Ports কী কী খুলেছি?

Initially 3 টা port open করেছি:

| Port | Protocol | Service | কেন |
|---|---|---|---|
| 22 | TCP | SSH | Remote admin access |
| 80 | TCP | HTTP | Web traffic (unencrypted) |
| 443 | TCP | HTTPS | Encrypted web traffic |

পরে **UDP 51820** add করবো WireGuard VPN এর জন্য।

**Default deny principle:** যেটা explicitly open করা নাই, সেটা blocked। এটা security best practice।

## ৪. Real-life Server Example 🖥️

Office এ একজন **DevOps engineer** যখন production VM provision করে, এভাবে think করে:

- **Subscription:** Production billing account (dev/staging থেকে আলাদা)
- **Resource Group:** `prod-payments-rg` (environment-service-suffix naming)
- **Region:** User base যেখানে (Australia user হলে Sydney, US হলে us-east-1)
- **Size:** Load test result দেখে — peak hour এ কত request আসবে calculate করে
- **Image:** Company এর "golden image" — pre-hardened, security tools pre-installed
- **Network:** Private VNet এ থাকবে, public IP শুধু load balancer এর, VM private subnet এ

আমার lab project এ সব কিছু directly accessible — এটা learning এর জন্য। Real production এ আরো একটা security layer থাকে।

## ৫. Outcome

- Azure portal navigate করা শিখেছি
- VM sizing economics বুঝেছি
- Region selection এর reasoning clear
- Resource Group concept clear
- Azure এ SSH key generation শিখেছি
- Initial NSG (Network Security Group) rules set করেছি

## ৬. When/Why Use করবো

- **Career:** Azure Administrator (AZ-104), Solutions Architect (AZ-305) certification এর core skill
- **Personal projects:** ভবিষ্যতে নিজে server লাগবে — same process repeat হবে
- **Assignment 3:** এই VM আমার পুরো project এর foundation

---

# 🔐 Topic 3: SSH Connection (Windows থেকে)

## ১. Concept

**SSH (Secure Shell)** হলো encrypted remote login protocol। আমার laptop Perth এ, server Sydney তে — কিন্তু SSH এর মাধ্যমে আমি এমনভাবে server এ command run করতে পারছি যেন আমি server এর সামনে বসে আছি।

৩টা জিনিস দরকার SSH এর জন্য:
1. **Server এর public IP** (20.5.169.97)
2. **Username** (azureuser)
3. **Private key file** (`.pem`)

## ২. Command/Syntax

### Step 1: Key file কোথায় আছে খুঁজে বের করো

```powershell
Get-ChildItem -Path $HOME -Recurse -Filter *.pem -ErrorAction SilentlyContinue | Select-Object FullName
```

### Step 2: File permission lock করো (Windows-specific)

```powershell
cd "C:\Users\alazi\Downloads"
icacls .\ict171-server_key.pem /inheritance:r
icacls .\ict171-server_key.pem /grant:r "${env:USERNAME}:(R)"
```

### Step 3: SSH connection establish করো

```powershell
ssh -i .\ict171-server_key.pem azureuser@20.5.169.97
```

### Step 4: First time prompt আসলে `yes` type করো

```
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

## ৩. Deep Explanation

### Public-key Cryptography আসলে কী?

এই concept বুঝতে হলে একটু math basics দরকার। Idea টা হলো:

- একটা function `f(x)` আছে যেটা **easy to compute one way** কিন্তু **hard to reverse**
- Example: `f(x) = (large_prime_1 × large_prime_2)` — multiplication easy, কিন্তু factoring computationally infeasible
- **Public key** = এই multiplication এর result
- **Private key** = original primes

Public key সবাইকে দেওয়া যায় (server এ রাখা হয়)। Private key শুধু আমার (laptop এ protected)।

SSH login এর সময় কী হয়:

1. আমার SSH client server এ request পাঠায়: "আমি azureuser হতে চাই"
2. Server `~/.ssh/authorized_keys` এ আমার public key খুঁজে পায়
3. Server একটা random challenge generate করে, আমার public key দিয়ে encrypt করে আমাকে পাঠায়
4. শুধু আমার private key সেই challenge decrypt করতে পারবে
5. আমি decrypt করে answer ফিরে পাঠাই
6. Match হলে — authenticated ✅

এই পুরো process এ **আমার private key কখনো network এ যায় না।** সেটা আমার laptop এই থাকে।

### `icacls` কেন দরকার?

OpenSSH security check করে — যদি private key file অন্য user পড়তে পারে, SSH refuse করে use করতে (key might be compromised)। Default Windows এ `Downloads` folder এ files সবাই পড়তে পারে।

`icacls` command:

- `/inheritance:r` — parent folder থেকে inherited permissions remove করে
- `/grant:r "USERNAME:(R)"` — শুধু current user কে Read access দেয়

এটা Linux এর `chmod 600 file.pem` এর equivalent।

### `ssh -i` Command Anatomy

```
ssh -i .\ict171-server_key.pem azureuser@20.5.169.97
 │   │              │              │           │
 │   │              │              │           └─ server এর public IP
 │   │              │              └─ remote username
 │   │              └─ key এর filename
 │   └─ "identity file" flag (private key specify)
 └─ ssh client command
```

### Host Key Verification — কেন `yes` type করতে হয়?

First-time connection এ SSH server তার own public key (different from আমার) display করে। এটা একটা security check।

**Man-in-the-Middle attack scenario:**
- Hacker আমার internet traffic intercept করে
- আমাকে বলে "আমিই তোমার server" — কিন্তু আসলে fake server
- আমি login করলে hacker আমার credentials পেয়ে যায়

SSH এটা prevent করে **host key fingerprint** দিয়ে:
- প্রতিটা server এর একটা unique cryptographic fingerprint থাকে
- First connection এ SSH বলে: "এই server বলছে তার fingerprint X — accept করবে?"
- Real engineer verify করবে out-of-band (manager থেকে জানবে, server console থেকে দেখবে)
- Lab এ আমি `yes` type করি, কিন্তু real production এ proper verification মানদণ্ড

### Successful Connection এর Output

```
azureuser@ict171-server:~$
```

এটা decode করা যাক:
- `azureuser` → remote user (linux user account)
- `@` → separator
- `ict171-server` → hostname (server এর name)
- `:` → separator
- `~` → current directory (home folder = `/home/azureuser`)
- `$` → regular user prompt (root হলে `#` দেখাতো)

## ৪. Real-life Server Example 🖥️

Real engineer এর daily routine:

- সকালে office এ বসে laptop খুলবে
- একটা SSH config file আছে `~/.ssh/config`:
  ```
  Host prod-web
    HostName 52.180.42.155
    User deploy
    IdentityFile ~/.ssh/prod-key.pem
  ```
- Terminal এ শুধু type করবে: `ssh prod-web` — পুরো config auto-apply হবে
- Bash alias use করে আরো ছোট: `web` = `ssh prod-web`
- Production এ **jump host / bastion host** হয়ে access করবে (extra security)

Senior engineer একদিনে 10-20 টা server SSH করে। Trivial মনে হয় — কিন্তু underneath cryptography আর networking সব কাজ করছে।

## ৫. Outcome

- Public-key cryptography এর fundamental বুঝেছি
- OpenSSH client Windows এ use করতে পারি
- File permission secure করা (`icacls`) শিখেছি
- Host verification এর importance বুঝেছি
- Remote shell session manage করতে পারি

## ৬. When/Why Use করবো

- **Daily job:** Cloud engineer এর primary tool
- **DevOps:** Server deploy, configure, debug — সব SSH দিয়ে
- **Cyber security:** Penetration testing এ SSH knowledge essential
- **Future assignments:** যে কোনো VM, Linux box — same SSH flow

---

# 📦 Topic 4: Linux Package Management (apt)

## ১. Concept

**Package** হলো pre-compiled software bundle (binaries + config files + dependencies)। **Package manager** সেগুলো install, update, remove করে automatically।

Ubuntu/Debian এর package manager: **apt** (Advanced Package Tool)

৩টা main command:
- `apt update` — package catalog refresh
- `apt upgrade` — installed packages এর latest version install
- `apt install <package>` — নতুন package install

## ২. Command/Syntax

```bash
# System update + upgrade
sudo apt update && sudo apt upgrade -y

# Multiple package install
sudo apt install -y nginx ufw curl git
```

## ৩. Deep Explanation

### Repository Concept

Ubuntu এর হাজার হাজার package store হয় "**repositories**" এ — basically remote servers যেখানে `.deb` files থাকে। Default repositories configured থাকে `/etc/apt/sources.list` file এ।

**যখন আমি `apt update` run করি:**
- apt সব configured repos এর কাছে যায়
- "Latest catalog দাও" বলে
- Index files download করে (কোন package available, কোন version)
- Local cache update করে `/var/lib/apt/lists/` এ

**Important:** এটা install না — শুধু information refresh।

**যখন `apt upgrade` run করি:**
- Local cache compare করে installed packages এর সাথে
- যদি newer version available থাকে, download + install করে
- Dependencies handle করে automatically

### `update && upgrade` একসাথে কেন?

`update` ছাড়া `upgrade` করলে — apt পুরনো catalog দেখে upgrade try করবে। Fail হতে পারে অথবা mishandle হতে পারে। তাই **always update first**।

`&&` operator এর meaning: "previous command successful হলে next টা run করো"। যদি `update` fail করে, `upgrade` skip হবে — disaster prevent করে।

### Security Implications

Cloud image (যেটা থেকে আমার VM build হলো) — Microsoft সেটা 1-3 মাস আগে create করেছিল। সেই সময় থেকে আজ পর্যন্ত অনেক security patches release হয়েছে। Internet এ expose করার আগে update করা **mandatory**।

**Real attack story:** 2017 এ **WannaCry ransomware** Windows এর একটা vulnerability exploit করে $4 billion damage করেছিল। Patch available ছিল 2 মাস আগে। যারা update করেনি — they suffered।

### `apt install` Flow (অন্তরালে কী হয়)

```bash
sudo apt install -y nginx ufw curl git
```

apt এই কাজগুলো করে:

1. **Dependency resolve** — nginx এর আরো 10-15 packages লাগতে পারে
2. **Download** — Ubuntu's CDN থেকে `.deb` files
3. **Verify signatures** — cryptographic check (GPG)
4. **Extract** — files কোথায় যাবে সেটা `.deb` file এ specified
5. **Run post-install scripts** — service start, user create, etc.

Nginx এর case এ post-install automatically:
- `nginx` user create করে (security best practice — root এ chalanona)
- systemd service file install করে
- Service start করে
- Boot এ auto-start enable করে

### Package List Explanation

| Package | Purpose |
|---|---|
| `nginx` | High-performance web server |
| `ufw` | Simple firewall management |
| `curl` | HTTP request tool (testing/debugging) |
| `git` | Version control |

### `-y` Flag কেন?

apt normally প্রতিটা install এর আগে জিজ্ঞেস করে "Are you sure? (y/n)"। Script automation এ এটা blocker — `-y` flag automatically `y` answer দেয়।

## ৪. Real-life Server Example 🖥️

Production server এ **weekly maintenance window**:

```bash
# Mondays 2 AM (low traffic time)
sudo apt update
sudo apt list --upgradable    # কী কী update available দেখো
sudo apt upgrade -y
sudo reboot                   # kernel update হলে reboot দরকার
```

**Critical security patch** হলে emergency upgrade:

```bash
sudo apt update && sudo apt upgrade -y openssl  # শুধু openssl
```

## ৫. Outcome

- Package manager concept clear
- Repository system বুঝেছি
- Update vs upgrade difference clear
- Security patching workflow শিখেছি

## ৬. When/Why Use করবো

- **Daily admin work:** নতুন tool দরকার হলে `apt install`
- **Security:** Regular update server security এর backbone
- **Job:** Linux server admin role এর fundamental skill
- **Compliance:** PCI-DSS, ISO 27001 — সব compliance regular patching demand করে

---

# 🌐 Topic 5: Nginx Web Server

## ১. Concept

**Web server** হলো software যেটা HTTP requests handle করে আর response পাঠায়। Browser যখন `http://20.5.169.97` request করে — nginx সেই request receive করে, একটা HTML file return করে।

**Nginx** ([engine-X] pronounced) — modern, high-performance web server। Apache এর competitor।

## ২. Command/Syntax

```bash
# Service status check
sudo systemctl status nginx

# Service management
sudo systemctl start nginx        # start
sudo systemctl stop nginx         # stop
sudo systemctl restart nginx      # restart (downtime)
sudo systemctl reload nginx       # config reload (zero downtime)
sudo systemctl enable nginx       # boot এ auto-start
sudo systemctl disable nginx      # auto-start disable

# Config test
sudo nginx -t
```

## ৩. Deep Explanation

### Nginx Architecture

Nginx **2-tier process model** use করে:

1. **Master process** (root privilege) — config read করে, ports bind করে
2. **Worker processes** (non-root) — actual request handle করে

Master root এ থাকে কারণ port 80 (well-known port, < 1024) bind করতে root privilege লাগে। Workers non-root user (`www-data`) হিসেবে চলে — **security benefit:** যদি nginx exploited হয়, hacker root access পাবে না।

`systemctl status nginx` এ যেটা দেখেছি:

```
Main PID: 2392 (nginx)
Tasks: 3
├─2392 "nginx: master process /usr/sbin/nginx -g daemon on; ..."
├─2395 "nginx: worker process"
└─2396 "nginx: worker process"
```

3 process: 1 master + 2 workers (default = number of CPU cores)।

### Event-driven Model (Apache থেকে আলাদা কেন)

**Apache** traditionally **process-per-request** model use করতো:
- প্রতিটা request এর জন্য একটা new process create করতো
- 10,000 simultaneous connections = 10,000 processes
- RAM খেয়ে শেষ

**Nginx** **event-driven async** model use করে:
- এক worker process হাজার হাজার connection simultaneously handle করে
- যেমন একজন restaurant waiter — এক table এ order নেয়, kitchen এ যায়, অন্য table check করে, food deliver করে — সব async

**Result:** Same hardware এ Nginx, Apache এর চেয়ে 10-100x বেশি concurrent connection handle করতে পারে।

### systemd Service Management

**systemd** হলো modern Linux এর init system (পুরনো `init.d` এর replacement)।

| Command | Purpose |
|---|---|
| `systemctl status nginx` | Current state দেখো |
| `systemctl start nginx` | Start করো |
| `systemctl stop nginx` | Stop করো |
| `systemctl restart nginx` | Restart (brief downtime) |
| `systemctl reload nginx` | Config reload (zero downtime) ⭐ |
| `systemctl enable nginx` | Boot এ auto-start enable |
| `systemctl disable nginx` | Auto-start disable |

`enabled` status এর meaning: **VM reboot হলে nginx automatically start হবে।** এটা critical — manual start করতে হলে যদি 3 AM এ VM reboot হয়, আমি ঘুমাচ্ছি — website down থাকবে।

### Default Page কোথা থেকে আসে?

```bash
ls /var/www/html/
# output: index.nginx-debian.html
```

Nginx এর **default site root** = `/var/www/html/`। সেখানে `index.nginx-debian.html` আছে — এটাই "Welcome to nginx!" page। পরে আমি এটা replace করবো Ghost CMS দিয়ে।

**Configuration files:**
- `/etc/nginx/nginx.conf` → main config
- `/etc/nginx/sites-available/` → site configs (inactive)
- `/etc/nginx/sites-enabled/` → active sites (symlinks to available)

Pattern: ekta site bananor jonno `sites-available/` এ file create কর, তারপর `sites-enabled/` এ symlink। Production এ এভাবেই multiple sites manage হয়।

## ৪. Real-life Server Example 🖥️

Real nginx deployment এ:

- **Reverse proxy:** Nginx সামনে থাকে, backend এ Node.js / Python apps (port 3000, 5000)। Nginx URL based routing করে।
- **Load balancer:** 5 টা backend server থাকলে, nginx round-robin distribute করে traffic।
- **SSL termination:** Nginx HTTPS encryption handle করে, backends শুধু HTTP serve করে (faster)।
- **Static file serving:** Images, CSS, JS — nginx serve করে (app server এর চেয়ে faster)।
- **Rate limiting:** "Per IP max 100 requests/min" — DDoS protection।

**আমার project এ nginx কাজ করবে:**
- `alazimazxyz.xyz` → Ghost CMS (port 2368)
- `status.alazimazxyz.xyz` → Security audit script output (static file)
- All HTTPS termination via Let's Encrypt SSL

## ৫. Outcome

- Web server কীভাবে work করে বুঝেছি
- systemd service management শিখেছি
- Master-worker process model clear
- Production deployment patterns (reverse proxy, load balancer) বুঝেছি

## ৬. When/Why Use করবো

- **Every web project:** Backend deploy করতে web server লাগবেই
- **Career:** Backend developer, DevOps, SRE — সবাইকে nginx জানতে হয়
- **Microservices architecture:** API gateway হিসেবে nginx popular

---

# 🛡️ Topic 6: UFW Firewall

## ১. Concept

**Firewall** হলো software/hardware যেটা network traffic filter করে based on rules। কোন traffic ভেতরে আসবে (**ingress**), কোন traffic বাইরে যাবে (**egress**) — সব control করে।

**UFW (Uncomplicated Firewall)** হলো Ubuntu's simple front-end to `iptables` (the actual kernel-level firewall)। Raw `iptables` syntax জটিল আর error-prone; UFW সেটা simple করেছে।

## ২. Command/Syntax

```bash
sudo ufw allow OpenSSH              # Port 22 allow (SSH profile)
sudo ufw allow 'Nginx Full'         # Port 80 + 443 allow
sudo ufw enable                     # Firewall on করো
sudo ufw status                     # Current rules দেখো
sudo ufw status verbose             # আরো details
sudo ufw deny 23                    # Specific port deny
sudo ufw delete allow 80            # Rule remove
sudo ufw reset                      # All rules clear
sudo ufw app list                   # Available app profiles
```

## ৩. Deep Explanation

### Firewall কেন দরকার

Server internet এ expose হলে, হাজার হাজার bot scan করতে থাকে — open port খুঁজে। প্রতিটা open port = potential entry point for attack।

`netstat` command server এ run করে দেখলে কী কী service listening:

```bash
sudo netstat -tulpn
```

Web server এ শুধু nginx (port 80, 443) আর SSH (port 22) listen করা উচিত। অন্য port (database internally use, internal services) শুধু localhost listen করবে — outside থেকে accessible না।

**Firewall একটা extra defensive layer** — যদি ভুলে কোনো service public port এ expose হয়ে যায়, firewall block করে দেয়।

### ⚠️ CRITICAL: Order of Operations

```
1. SSH allow করো FIRST
2. অন্য services allow করো
3. তারপর firewall enable করো
```

যদি আমি firewall enable করি first, তারপর SSH allow add করি — **disaster:**
- Firewall on হওয়ার সাথে সাথে default deny চালু হয়
- আমার current SSH connection drop হয়
- আমাকে recover করতে হবে Azure portal এর serial console দিয়ে

**Real production এ engineers এই ভুল করে lock out হয়ে গেছে** — অনেক company এর horror story আছে। **Always allow access first, then enable।**

### Application Profiles

UFW শুধু port number না, application name use করতে দেয়:

```bash
sudo ufw app list
```

Output:
```
Available applications:
  Nginx Full
  Nginx HTTP
  Nginx HTTPS
  OpenSSH
```

এটা human-friendly। Otherwise লিখতে হতো: `sudo ufw allow 22/tcp`।

**`Nginx Full`** = port 80 + 443 একসাথে। Nginx package install এর সময় automatically register করেছে।

### Default Policies

UFW এর default:

- **Incoming:** DENY (সব block, exception যারা allow list এ আছে)
- **Outgoing:** ALLOW (server-initiated traffic permitted — যেমন `apt update` going out)

এটাই security best practice — **"least privilege" principle**। Default এ কিছু allow না, শুধু explicit rules।

### Status Output Decode

```
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
Nginx Full                 ALLOW       Anywhere
OpenSSH (v6)               ALLOW       Anywhere (v6)
Nginx Full (v6)            ALLOW       Anywhere (v6)
```

| Column | Meaning |
|---|---|
| **To** | Local service/port যেটা hit হয় |
| **Action** | `ALLOW` / `DENY` / `REJECT` |
| **From** | Source IP — `Anywhere` = any IP on internet |
| **v6** | IPv6 equivalent rules |

**DENY vs REJECT difference:**
- **DENY** — silent drop (attacker জানে না port exists কিনা)
- **REJECT** — explicit "no" reply পাঠায়

DENY preferred — attacker discovery harder।

### Defense-in-depth Principle

আমার setup এ **2 layer firewall**:

```
Internet → Azure NSG → VM's UFW → Nginx
            (cloud level)  (host level)
```

Both must allow traffic — যদি একটা layer misconfigured হয়, অন্যটা still protect করে।

Real-world breaches এর post-mortem দেখলে দেখা যায় — multi-layer security থাকলে attacker breach করলেই full system compromise হয় না।

## ৪. Real-life Server Example 🖥️

Production server এ firewall config:

```bash
# Office IP থেকে শুধু SSH allow
sudo ufw allow from 203.0.113.0/24 to any port 22

# Public web traffic (সবার জন্য)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Internal monitoring (Datadog agent থেকে)
sudo ufw allow from 10.0.5.0/24 to any port 8125

# Default deny everything else
sudo ufw default deny incoming
```

**আমার lab এ আমি `Anywhere` use করেছি** — practical purpose এ। Real production এ SSH access শুধু office IP / VPN range থেকে allow করা হয়। World ke SSH access দেওয়া = additional attack surface।

## ৫. Outcome

- Firewall fundamental clear
- UFW practical use শিখেছি
- Default deny + explicit allow philosophy বুঝেছি
- Order of operations এর importance বুঝেছি
- Defense-in-depth security model implement করেছি

## ৬. When/Why Use করবো

- **Every production server:** Mandatory hardening step
- **Security audits:** Tutor/auditor first check করে firewall status
- **Career:** Network security, SOC analyst, security engineer role এ firewall analysis core skill
- **Compliance:** HIPAA, PCI-DSS, ISO 27001 — সবাই firewall demand করে

---

# 📊 Final Summary (সব মিলিয়ে)

আজ যা যা achieve করেছি:

```
┌──────────────────────────────────────────────────────┐
│   CLOUD VM PROVISIONING & WEB SERVER DEPLOYMENT     │
└──────────────────────────────────────────────────────┘

  ✅ 1. Azure portal এ Ubuntu 24.04 VM provisioned
  ✅ 2. RSA SSH key pair generated
  ✅ 3. Public IP allocated: 20.5.169.97
  ✅ 4. SSH connection established Windows থেকে
  ✅ 5. System packages updated (security patches)
  ✅ 6. Nginx web server installed + verified running
  ✅ 7. UFW firewall configured (SSH + HTTP + HTTPS)
  ✅ 8. Public web access verified via browser
```

**Final state:** A hardened, internet-facing Linux web server in Australia East region, serving traffic on ports 80 (HTTP) and 443 (HTTPS), with admin access via SSH (port 22) only.

---

## 🔗 Real-World Usage Table (Lab → Project Connection)

| আমি Lab এ যা করেছি | Real-world এ যেখানে কাজে লাগবে |
|---|---|
| Azure VM provisioning | Startup new product এর জন্য staging environment deploy করে |
| SSH key authentication | DevOps team 50+ production server manage করে passwords ছাড়া |
| `apt update && upgrade` | Weekly maintenance window পুরো server fleet এ |
| Nginx installation | E-commerce site front-end (Amazon, Daraz, Pathao সব nginx-based) |
| UFW firewall | PCI-DSS compliance — payment processing requirement |
| Defense-in-depth (NSG + UFW) | Banking infrastructure customer data protect করতে |
| systemd service management | Server reboot হলেও services চলতে থাকে |

---

## 💡 Reflection (Assignment style answer)

এই practical session এ আমি successfully Microsoft Azure এ একটা virtual machine provision করেছি, যেটা আমার ICT171 cloud server project এর foundation হিসেবে কাজ করবে। এই exercise অনেকগুলো core cloud infrastructure concept reinforce করেছে, যেগুলো আগে শুধু theoretical level এ পড়েছিলাম।

**Infrastructure-as-a-Service (IaaS)** model select করার decision সরাসরি assignment এর requirement থেকে এসেছে — hands-on server administration শেখার জন্য। এই pragmatic choice আমাকে exposed করেছে সেই decisions এর সাথে যা real cloud engineers daily basis এ নেয় — appropriate region selection (Perth থেকে latency considering Australia East choose করা), VM size যা performance আর cost balance করে (Standard_B2ats_v2 burstable tier), এবং password এর বদলে SSH public-key authentication use করে attack surface minimize করা।

সবচেয়ে valuable lesson এসেছে UFW firewall configure করা থেকে। **Critical order-of-operations requirement** — SSH allow করার পরে firewall enable করা — একটা principle illustrate করেছে যা আমি future infrastructure work এ carry করবো: connectivity affect করে এমন changes carefully sequence করতে হবে যাতে accidental lockout না হয়। এটা reinforce করেছে administrative actions execute করার আগে consequences carefully think করার importance।

আমি **defense-in-depth** কে security philosophy হিসেবে appreciate করতে শিখেছি। আমার system এ এখন দুটো independent firewall (Azure এর NSG perimeter এ আর UFW host এ), যে কোনো একটা যদি misconfigured হয়, অন্যটা still unauthorized traffic block করবে। এই redundancy resilient security architecture এর cornerstone এবং একটা pattern যা আমি আমার cybersecurity career এ apply করবো।

আগামী steps এ এই base VM হোস্ট করবে Ghost CMS, একটা WireGuard VPN endpoint, এবং একটা custom security audit script। আজ যে foundation build হয়েছে — hardened, patched, firewalled, এবং শুধু cryptographic key দিয়ে accessible — সেটা সেই services এর জন্য secure platform provide করবে।

---

**শেষ। (End of Lab Note)**

*Document version: 1.0 — Created 26 May 2026*
