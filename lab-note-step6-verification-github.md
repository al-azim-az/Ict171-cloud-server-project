# ICT171 ল্যাব নোট — Step 6: DNS Verification & GitHub Documentation

**Student:** MD Abdullah Al Azim (36018444)
**Date:** 26 May 2026
**Topic:** DNS Propagation Testing, Live Verification, Git Version Control & Documentation

---

## ভূমিকা 📖

এই note এ আমরা cover করবো — DNS records add করার পর সেগুলো **কীভাবে verify** করতে হয় এবং **GitHub এ documentation কীভাবে professionally manage** করতে হয়।

আজকের session এ যা যা করেছি:

1. **DNS propagation testing** — 3 টা different method দিয়ে
2. **Live site verification** — browser এ domain access
3. **Git version control concepts** — commit, repository structure
4. **GitHub documentation workflow** — file upload, commit messages, timeline building

প্রতিটা topic এ ৬টা section format।

---

# 🧪 Topic 1: DNS Propagation Testing

## ১. Concept (এটা কী এবং কেন)

**DNS propagation testing** হলো verify করা যে আমাদের add করা DNS records globally সব DNS server এ পৌঁছেছে কিনা।

আমরা DNS records add করার পর সেগুলো instantly সব জায়গায় কাজ করে না। বিভিন্ন caching layer (ISP, OS, browser) এর কারণে updates ধীরে ধীরে spread করে। তাই **testing essential** — না হলে আমরা জানবো না কখন site live হয়েছে।

**3 টা testing method:**
1. Browser test (visual confirmation)
2. `dig` command (technical verification)
3. Online propagation checker (global view)

## ২. Command/Syntax

```bash
# Method 2: dig command (SSH session এ)
dig alazimazxyz.xyz +short
dig www.alazimazxyz.xyz +short
dig vpn.alazimazxyz.xyz +short
dig status.alazimazxyz.xyz +short

# Specific DNS server থেকে test
dig @8.8.8.8 alazimazxyz.xyz +short    # Google DNS
dig @1.1.1.1 alazimazxyz.xyz +short    # Cloudflare DNS

# Windows এ
nslookup alazimazxyz.xyz

# DNS cache flush (যদি stale result পাও)
ipconfig /flushdns    # Windows
```

## ৩. Deep Explanation

### Method 1: Browser Test

সবচেয়ে simple — browser এ `http://alazimazxyz.xyz` type করি।

আমরা যা দেখলাম: **"Welcome to nginx!"** page। মানে:
- DNS resolved (domain → 20.5.169.97)
- Browser connected to our Azure VM
- Nginx served the default page

**কেন `http://` `https://` না?** কারণ আমরা এখনো SSL setup করিনি। `https://` দিলে browser SSL certificate খুঁজবে, পাবে না, error দেখাবে। `http://` দিয়ে plain (unencrypted) connection হয়।

### Method 2: `dig` Command

**dig** = "Domain Information Groper" — DNS query করার powerful tool।

```bash
dig alazimazxyz.xyz +short
```

`+short` flag শুধু IP দেখায়, পুরো verbose output না। Output:
```
20.5.169.97
```

এটা return করলে = DNS resolved successfully।

**Full dig output (without +short):**
```
; <<>> DiG 9.x <<>> alazimazxyz.xyz
;; ANSWER SECTION:
alazimazxyz.xyz.    1800   IN   A   20.5.169.97
                     ↑      ↑    ↑   ↑
                    TTL   class type value
```

- **TTL (1800):** Cache duration in seconds (30 min)
- **IN:** Internet class (standard)
- **A:** Record type
- **20.5.169.97:** Resolved IP

### Method 3: Online Propagation Checker (DNSChecker.org)

এই tool worldwide multiple DNS servers থেকে একসাথে query করে দেখায় propagation status।

আমরা দেখলাম:
```
✅ San Francisco, US (OpenDNS)    → 20.5.169.97
✅ Berkeley, US (Quad9)            → 20.5.169.97
✅ Mountain View, US (Google)      → 20.5.169.97
✅ Burnaby, Canada                 → 20.5.169.97
✅ St Petersburg, Russia (Yandex)  → 20.5.169.97
✅ Cullinan, South Africa          → 20.5.169.97
✅ Amsterdam, Netherlands          → 20.5.169.97
... (প্রায় সব green)
```

World map এ green ticks মানে সেই region এ DNS propagated। Red ✗ মানে এখনো propagate হয়নি (কিছু server slow, normal)।

### Propagation কেন asymmetric হয়?

বিভিন্ন DNS server বিভিন্ন সময়ে cache refresh করে:
- Google DNS (8.8.8.8) — খুব fast, frequently updates
- Some ISP DNS — slow, hours পর্যন্ত cache hold করে
- Geographic distance ও factor — তবে আজকাল negligible

আমাদের প্রায় সব green হওয়া মানে — **Namecheap BasicDNS fast propagation দিয়েছে**, আমাদের site globally accessible।

## ৪. Real-life Server Example 🖥️

**Production deployment verification:**

একটা company নতুন server deploy করার পর DevOps engineer এই checks করে:

```bash
# 1. DNS resolves correctly?
dig newservice.company.com +short
# Expected: new server IP

# 2. From multiple geographic locations?
# Use DNSChecker.org or similar

# 3. HTTP response correct?
curl -I http://newservice.company.com
# Expected: HTTP 200 OK

# 4. Certificate valid? (after SSL)
curl -I https://newservice.company.com

# 5. Response time acceptable?
curl -o /dev/null -s -w "%{time_total}\n" http://newservice.company.com
```

Automated monitoring tools (Datadog, Pingdom, UptimeRobot) এই checks continuously করে — যদি DNS fail করে, alert পাঠায়।

## ৫. Outcome

- 3টা different DNS testing method শিখেছি
- `dig` command use করতে পারি
- Propagation এর asymmetric nature বুঝেছি
- Global propagation verify করতে পারি
- Production verification workflow বুঝেছি

## ৬. When/Why Use করবো

- **Every DNS change এর পর:** Verify before announcing live
- **Troubleshooting:** "Site not loading" — DNS resolving কিনা first check
- **Migration:** Old vs new IP propagation track করা
- **Monitoring:** Continuous DNS health checks production এ

---

# 🌐 Topic 2: Live Site Verification & HTTP Request Flow

## ১. Concept

যখন আমরা browser এ `alazimazxyz.xyz` type করে "Welcome to nginx!" দেখি — পিছনে অনেকগুলো step ঘটে। এই পুরো journey বোঝা important কারণ যেকোনো step fail করলে troubleshoot করতে হবে।

## ২. Command/Syntax

```bash
# Server response check (SSH session থেকে)
curl http://localhost              # Local test
curl -I http://alazimazxyz.xyz     # Headers only
curl -v http://alazimazxyz.xyz     # Verbose (full details)

# Response time measure
curl -o /dev/null -s -w "Time: %{time_total}s\n" http://alazimazxyz.xyz

# Check what's listening on ports
sudo netstat -tulpn | grep nginx
sudo ss -tulpn | grep :80
```

## ৩. Deep Explanation

### সম্পূর্ণ Request Flow — Browser থেকে Page পর্যন্ত

যখন আমি browser এ `alazimazxyz.xyz` type করে Enter চাপি:

**Phase 1: DNS Resolution**
```
Browser → "alazimazxyz.xyz এর IP কী?"
       → DNS lookup (browser cache → OS → ISP → ... → Namecheap)
       → Answer: 20.5.169.97
```

**Phase 2: TCP Connection**
```
Browser → 20.5.169.97 এর port 80 এ TCP handshake শুরু
       → SYN packet পাঠায়
Server → SYN-ACK ফেরত পাঠায়
Browser → ACK পাঠায়
       → Connection established (3-way handshake complete)
```

**Phase 3: Routing through layers**
```
Browser packet → Internet → Azure Australia East datacenter
              → Azure NSG checks: port 80 allowed? ✅
              → VM এর network interface
              → UFW firewall checks: Nginx Full rule? ✅
              → Reaches nginx process
```

**Phase 4: HTTP Request/Response**
```
Browser → GET / HTTP/1.1
          Host: alazimazxyz.xyz
Nginx → reads request
      → looks up /var/www/html/index.nginx-debian.html
      → HTTP 200 OK
      → sends HTML content
Browser → renders "Welcome to nginx!" page
```

**পুরো process ~100-300ms এ complete।**

### "Not secure" warning কেন আসছে?

Browser এর address bar এ দেখলাম **"Not secure"** ⚠️।

কারণ: আমরা **HTTP** (port 80) use করছি, **HTTPS** (port 443) না।

- **HTTP:** Data plain text এ যায় — কেউ intercept করলে পড়তে পারে
- **HTTPS:** Data encrypted (TLS/SSL) — intercept করলেও পড়তে পারে না

Modern browsers HTTP sites কে "Not secure" mark করে users কে warn করার জন্য। পরবর্তী step (SSL setup) এ আমরা এটা fix করবো — তখন green padlock 🔒 আসবে।

### Host Header — কীভাবে nginx জানে কোন site serve করবে

HTTP request এ একটা **Host header** থাকে:
```
GET / HTTP/1.1
Host: alazimazxyz.xyz
```

এই header দিয়ে nginx বুঝে কোন domain request করা হয়েছে। এখন আমাদের একটাই site (default), তাই সব request "Welcome to nginx" দেখায়।

পরে যখন multiple subdomains (vpn, status) এ different services দিবো, nginx এই Host header দেখে route করবে:
- `Host: alazimazxyz.xyz` → Ghost CMS
- `Host: status.alazimazxyz.xyz` → security dashboard

## ৪. Real-life Server Example 🖥️

**Debugging a "site down" incident:**

Production site down — engineer systematically check করে:

```bash
# 1. DNS resolving?
dig company.com +short
# যদি IP না আসে → DNS problem

# 2. Server reachable?
ping 1.2.3.4
# যদি timeout → network/server down

# 3. Port open?
telnet 1.2.3.4 443
# অথবা: nc -zv 1.2.3.4 443
# যদি refused → firewall বা service down

# 4. Service responding?
curl -I https://company.com
# HTTP 200 → working
# HTTP 502 → backend down
# Timeout → firewall/network

# 5. SSL valid?
openssl s_client -connect company.com:443
# Certificate expiry, chain issues check
```

এই **layered debugging approach** — DNS → network → port → service → SSL — systematic troubleshooting এর foundation।

## ৫. Outcome

- HTTP request এর complete lifecycle বুঝেছি
- TCP 3-way handshake concept clear
- "Not secure" warning এর কারণ বুঝেছি
- Host header এর role বুঝেছি
- Systematic debugging approach শিখেছি

## ৬. When/Why Use করবো

- **Every deployment:** Verify site actually working
- **Incident response:** Systematic troubleshooting
- **Performance tuning:** Response time analysis
- **Security audit:** HTTP vs HTTPS verification

---

# 📚 Topic 3: Git & Version Control Concepts

## ১. Concept

**Git** হলো একটা **version control system** — code/files এর changes track করে, history রাখে, এবং collaboration enable করে।

**GitHub** হলো Git repositories host করার একটা cloud platform (Git ≠ GitHub; Git হলো tool, GitHub হলো hosting service)।

আমরা আমাদের documentation GitHub এ রাখছি কারণ assignment requirement — এবং এটা professional practice।

## ২. Command/Syntax

```bash
# Git basic commands (command line)
git init                          # নতুন repo তৈরি
git clone <url>                   # existing repo copy
git add <file>                    # file staging
git add .                         # সব changes staging
git commit -m "message"           # changes save
git push                          # GitHub এ upload
git pull                          # GitHub থেকে download
git status                        # current state
git log                           # commit history

# আমরা GitHub web interface use করেছি, command line না
```

## ৩. Deep Explanation

### Version Control কেন দরকার

কল্পনা করো তুমি একটা document এ কাজ করছো:
- `report.doc`
- `report_final.doc`
- `report_final_v2.doc`
- `report_final_FINAL.doc`
- `report_final_FINAL_real.doc`

এই chaos! Version control এই problem solve করে:
- প্রতিটা change এর একটা snapshot (commit) রাখে
- যেকোনো পুরনো version এ ফিরে যাওয়া যায়
- কে কখন কী change করেছে track হয়
- Multiple people একসাথে কাজ করতে পারে

### Git এর core concepts

**Repository (repo):**
একটা project এর সব files + complete history এর container। আমাদের repo: `ict171-cloud-server-project`।

**Commit:**
একটা specific point in time এর snapshot। প্রতিটা commit এর:
- Unique ID (hash) — আমাদের: `93c617e`
- Message — "Add documentation: VM, SSH, Nginx, DNS lab notes"
- Timestamp
- Author

**Branch:**
Development এর parallel line। Default branch: `main`। আমরা সরাসরি main এ commit করছি (small project, solo)।

**Commit history / timeline:**
সব commits এর sequence — project এর evolution দেখায়। আমাদের timeline:
```
May 24: Initial commit (LICENSE)
May 24: Update README.md
May 26: Add documentation (5 files)
```

### আমাদের repo structure

```
ict171-cloud-server-project/
├── LICENSE                       (MIT license)
├── README.md                     (project overview + index)
├── 01-azure-vm-setup.md          (English doc)
├── 02-ssh-connection.md          (English doc)
├── 03-nginx-firewall-setup.md    (English doc)
├── lab-note-day1-bangla.md       (Bangla educational note)
└── lab-note-step5-dns.md         (Bangla DNS note)
```

### Commit message কেন important

ভালো commit message future এ help করে — কোন commit এ কী হয়েছিল বুঝতে।

**Bad commit message:**
```
"update"
"fixed stuff"
"asdf"
```

**Good commit message (আমাদের):**
```
"Add documentation: VM, SSH, Nginx, DNS lab notes"
```

Clear, descriptive, কী add হয়েছে বলে দেয়।

**Professional convention (Conventional Commits):**
```
feat: add user authentication
fix: resolve login redirect bug
docs: update API documentation
refactor: simplify database queries
```

### Timeline/Commit History — Rubric Connection

আমাদের assignment rubric বলে:
> "development timeline demonstrates that this has been iteratively improved over 3 weeks or more evidenced by commit history"

মানে — একদিনে সব commit করলে দেখায় rushed work। Multiple days এ commits দেখায় genuine iterative development।

আমাদের commits:
- May 24: Setup
- May 26: Major documentation

প্রতিদিন কাজ করলে আর commit করলে — timeline naturally build হবে। এটা authentic, fake করা যায় না সহজে।

## ৪. Real-life Server Example 🖥️

**Real software team workflow:**

```
Developer A: feature branch তৈরি করে
  git checkout -b feature/payment-integration
  → code লেখে
  git add .
  git commit -m "feat: add Stripe payment integration"
  git push origin feature/payment-integration
  → Pull Request (PR) তৈরি করে

Developer B: PR review করে
  → comments দেয়, approve করে

CI/CD pipeline:
  → automated tests run করে
  → যদি pass → merge to main
  → automatically deploy to production
```

**Infrastructure as Code (IaC):**
Modern teams server configuration ও Git এ রাখে:
```
infrastructure/
├── terraform/          (cloud resources)
├── ansible/            (server config)
├── kubernetes/         (container orchestration)
└── docs/               (documentation)
```

আমাদের project এ documentation Git এ রাখা — সেই same professional practice এর foundation।

## ৫. Outcome

- Version control এর importance বুঝেছি
- Git core concepts (repo, commit, branch) clear
- Commit message best practices শিখেছি
- Repository structure organize করতে পারি
- Professional Git workflow এর foundation বুঝেছি

## ৬. When/Why Use করবো

- **Every coding project:** Industry standard
- **Documentation:** Track changes over time
- **Collaboration:** Team projects
- **Portfolio:** GitHub profile = developer resume
- **Career:** Git skill mandatory প্রায় সব tech job এ

---

# 📤 Topic 4: GitHub Documentation Workflow

## ১. Concept

GitHub এ files add করার কয়েকটা method আছে। আমরা **web upload** method use করেছি (drag & drop)। এছাড়া command line (`git push`) আর "Create new file" method ও আছে।

## ২. Command/Syntax

```
GitHub Web Upload Flow:
  Repo → Add file → Upload files
       → drag & drop files
       → commit message লেখো
       → Commit changes

GitHub Create File Flow (folder সহ):
  Repo → Add file → Create new file
       → filename: docs/myfile.md  (docs/ folder auto-create করে)
       → content paste করো
       → Commit changes
```

## ৩. Deep Explanation

### আমাদের Upload Method

আমরা যা করলাম:
1. Repo এ গেলাম
2. **Add file → Upload files** click করলাম
3. 5টা `.md` file drag & drop করলাম
4. Commit message: "Add documentation: VM, SSH, Nginx, DNS lab notes"
5. **Commit changes** click করলাম

Result: 5টা file root level এ added, একটা single commit এ।

### Folder Structure — `docs/` কেন আমরা skip করলাম

আমি প্রথমে চেয়েছিলাম files `docs/` folder এ রাখতে:
```
docs/01-azure-vm-setup.md
docs/lab-note-day1-bangla.md
...
```

কিন্তু GitHub এর drag-drop upload interface এ folder pre-set করা কঠিন। তাই decision নিলাম — **root এ commit করি, পরে দরকার হলে move করবো।**

**কেন এটা acceptable:**
- Documentation এর location marks affect করে না
- Content quality matters, organization secondary
- পরে rename করে `docs/` folder এ move করা যায় (file rename করে `docs/` prefix দিলে GitHub auto-move করে)

### File Move করার Technique (future reference)

যদি পরে `docs/` folder এ move করতে চাই:
1. File এ click করো
2. পেন্সিল ✏️ icon (Edit)
3. Filename field এ আগে `docs/` যোগ করো:
   ```
   01-azure-vm-setup.md → docs/01-azure-vm-setup.md
   ```
4. Commit changes
5. GitHub automatically `docs/` folder তৈরি করে file move করে

### Markdown Rendering

আমাদের সব file `.md` (Markdown) format। GitHub automatically Markdown render করে:
- `#` → বড় heading
- `**text**` → **bold**
- `| col | col |` → table
- ` ```code``` ` → code block
- `- item` → bullet list

এজন্য আমাদের documentation GitHub এ সুন্দর formatted দেখায়, raw text না।

### README.md এর special role

`README.md` হলো repository এর "front page"। GitHub automatically এটা repo home page এ render করে। তাই README এ থাকে:
- Project title
- Student details
- Overview
- Documentation index (other files এর links)

আমাদের README এর Documentation Index:
```markdown
- [01 — Azure VM Provisioning](docs/01-azure-vm-setup.md)
```

⚠️ Note: যেহেতু আমরা files root এ রেখেছি (docs/ এ না), এই links গুলো এখন broken হতে পারে। পরে hয় files move করবো, নয় links update করবো।

## ৪. Real-life Server Example 🖥️

**Open source project documentation:**

বড় projects (React, Linux kernel, Kubernetes) এর GitHub structure:
```
project/
├── README.md              (overview, quick start)
├── CONTRIBUTING.md        (how to contribute)
├── LICENSE                (legal)
├── docs/                  (detailed documentation)
│   ├── installation.md
│   ├── api-reference.md
│   └── tutorials/
├── src/                   (source code)
└── tests/                 (test files)
```

ভালো documentation = project এর success এর key। Linux kernel এর documentation হাজার হাজার pages। আমাদের scale এ ছোট, কিন্তু same principle — clear, organized, complete।

**Documentation as a skill:**
Assignment brief এ বলা ছিল — "IT staff are frequently asked to write documentation।" এটা একটা core professional skill। আমাদের lab notes + technical docs এই skill demonstrate করে।

## ৫. Outcome

- GitHub web upload workflow শিখেছি
- Markdown rendering বুঝেছি
- README.md এর role clear
- File organization strategy বুঝেছি
- Professional documentation practice শিখেছি

## ৬. When/Why Use করবো

- **Every project:** Documentation mandatory
- **Job applications:** GitHub profile = portfolio
- **Team collaboration:** Shared documentation
- **Knowledge preservation:** Future self / colleagues benefit

---

# 📊 Final Summary (Step 6 সব মিলিয়ে)

DNS verification থেকে GitHub documentation পর্যন্ত যা achieve করেছি:

```
┌──────────────────────────────────────────────────────┐
│      DNS VERIFICATION & DOCUMENTATION — DONE         │
└──────────────────────────────────────────────────────┘

  ✅ 1. DNS propagation tested (3 methods)
  ✅ 2. dig command verification
  ✅ 3. Global propagation confirmed (DNSChecker.org)
  ✅ 4. alazimazxyz.xyz LIVE verified (browser)
  ✅ 5. HTTP request flow understood
  ✅ 6. 5 documentation files committed to GitHub
  ✅ 7. Development timeline building (May 24, May 26)
```

**Final state:** Domain fully propagated globally, live site serving content, comprehensive documentation version-controlled on GitHub with a building commit timeline.

---

## 🔗 Real-World Usage Table (Step 6 specific)

| আমি Lab এ যা করেছি | Real-world application |
|---|---|
| `dig` DNS verification | DevOps daily troubleshooting |
| DNSChecker global test | Production launch verification |
| HTTP request flow analysis | Incident response, debugging |
| "Not secure" identification | Security audit, SSL planning |
| Git commit workflow | Every software development team |
| Commit message conventions | Professional code collaboration |
| GitHub documentation | Open source, team knowledge base |
| README structure | Project onboarding, portfolio |

---

## 💡 Reflection (Assignment style answer)

এই session এ আমি DNS configuration এর verification এবং project documentation এর version control — দুটো critical professional skill practice করেছি।

**DNS propagation testing** শেখা একটা valuable lesson ছিল। DNS records add করার পর সেগুলো instantly globally effective হয় না — caching layers এর কারণে updates ধীরে spread করে। আমি তিনটা different method ব্যবহার করেছি verification এর জন্য: browser দিয়ে visual confirmation, `dig` command দিয়ে technical verification, এবং DNSChecker.org দিয়ে global propagation view। এই multi-method approach reinforce করেছে যে একটা single test যথেষ্ট না — comprehensive verification multiple angles থেকে করতে হয়। DNSChecker এর world map এ প্রায় সব location এ green ticks দেখা একটা satisfying confirmation ছিল যে আমার site globally accessible।

`alazimazxyz.xyz` browser এ load করে "Welcome to nginx!" দেখা শুধু একটা milestone না — এটা পুরো request flow এর successful completion প্রমাণ করে: DNS resolution → TCP handshake → Azure NSG → UFW firewall → nginx response। আমি এই layered journey বুঝেছি, যা future troubleshooting এর জন্য essential। Browser এর "Not secure" warning ও আমাকে পরবর্তী step (SSL/TLS) এর প্রয়োজনীয়তা মনে করিয়ে দিয়েছে।

**Git এবং GitHub** ব্যবহার করে documentation manage করা professional software development এর foundation। আমি বুঝেছি version control কীভাবে chaos (multiple "final" versions) prevent করে, কীভাবে commit history একটা project এর evolution document করে, এবং কেন descriptive commit messages important। আমার assignment rubric specifically commit timeline এর উপর জোর দেয় — iterative development over multiple days। এই requirement আমাকে শিখিয়েছে যে documentation একটা continuous process, last-minute task না।

যদিও আমি files প্রথমে `docs/` folder এ রাখতে চেয়েছিলাম, GitHub এর web interface এর constraint এর কারণে root এ commit করেছি — এটা একটা pragmatic decision যা শেখায় perfectionism এর চেয়ে progress important। File location marks affect করে না; documentation এর quality এবং completeness matters।

আগামী step এ এই foundation এর উপর SSL/TLS certificate setup করবো (Let's Encrypt), যা site কে HTTPS এ secure করবে এবং "Not secure" warning সরাবে। DNS এখন properly resolved থাকায় Let's Encrypt domain verification সফল হবে।

---

**শেষ। (End of Lab Note)**

*Document version: 1.0 — Created 26 May 2026*
