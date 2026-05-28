# ICT171 ল্যাব নোট — Step 5: Namecheap DNS Configuration

**Student:** MD Abdullah Al Azim (36018444)
**Date:** 26 May 2026
**Topic:** Domain Name System (DNS), A Records, Namecheap DNS Management

---

## ভূমিকা 📖

এই note এ আমরা গভীরভাবে বুঝবো **DNS (Domain Name System)** কী এবং কেন এটা internet এর foundation। আমাদের goal ছিল **`alazimazxyz.xyz`** domain কে **`20.5.169.97`** Azure VM IP এর সাথে connect করা — যাতে browser এ domain type করলে আমাদের nginx server এ traffic পৌঁছায়।

আজকের session এ যা যা cover করবো:

1. DNS কী এবং কেন দরকার (core concept)
2. Domain name এর structure (root, TLD, subdomain)
3. DNS record types (A, CNAME, MX, TXT)
4. Namecheap এর interface এবং DNS modes
5. কেন Custom DNS থেকে BasicDNS এ switch করতে হলো
6. 4 টা A record add করার reasoning
7. TTL এবং propagation এর mechanism
8. Real-world DNS troubleshooting

প্রতিটা topic এ ৬টা section format follow করবো।

---

# 🌐 Topic 1: DNS (Domain Name System) — The Internet's Phonebook

## ১. Concept (এটা কী এবং কেন)

**DNS** হলো internet এর "phonebook"। মানুষ মনে রাখতে পারে easy names (google.com, facebook.com), কিন্তু computers communicate করে **IP addresses** দিয়ে (যেমন 142.250.71.46)।

DNS এর কাজ: **Domain name** কে **IP address** এ translate করা।

**একটা analogy:**
- তুমি বন্ধুকে call করতে চাও → তোমার phonebook এ "Rakib" নাম search করো → phone নম্বর পাও → call করো
- Internet এ একইভাবে → তুমি browser এ `alazimazxyz.xyz` type করো → DNS লুকআপ হয় → IP `20.5.169.97` পায় → connect হয়

DNS ছাড়া internet চলতে পারতো না — কেউ মনে রাখতে পারতো না হাজার হাজার IP addresses।

## ২. Command/Syntax

DNS query করার common commands:

```bash
# Domain এর IP দেখো
dig alazimazxyz.xyz +short

# পুরো DNS details
dig alazimazxyz.xyz

# Specific DNS server থেকে query
dig @8.8.8.8 alazimazxyz.xyz

# Reverse lookup (IP থেকে domain)
dig -x 20.5.169.97

# Linux/macOS এ alternative
host alazimazxyz.xyz
nslookup alazimazxyz.xyz

# Windows এ
nslookup alazimazxyz.xyz
```

## ৩. Deep Explanation

### DNS lookup এর পুরো journey

যখন তুমি browser এ `alazimazxyz.xyz` type করো, এই steps হয়:

**Step 1: Browser cache check**
- তোমার browser প্রথমে নিজের cache check করে — recent visit করা সব domain এর IP cached থাকে
- যদি cache এ পায় → directly connect (fastest)
- যদি না পায় → next step

**Step 2: Operating System cache check**
- Browser OS এর DNS resolver কে জিজ্ঞেস করে
- OS এর own cache আছে — সেখানে check করে
- Windows এ এই cache দেখা যায়: `ipconfig /displaydns`

**Step 3: Recursive resolver (ISP / Google DNS)**
- OS cache এ না থাকলে, **recursive DNS resolver** কে query করে
- এটা সাধারণত তোমার ISP এর server (Telstra, Optus etc.)
- অথবা public resolver (Google: 8.8.8.8, Cloudflare: 1.1.1.1)

**Step 4: Root DNS server query**
- Recursive resolver root servers কে জিজ্ঞেস করে: "alazimazxyz.xyz কোথায়?"
- Root server বলে: "আমি জানি না, কিন্তু `.xyz` TLD এর authority X server এ"
- Root servers সংখ্যা সীমিত — মাত্র 13 sets worldwide (A থেকে M)

**Step 5: TLD (Top-Level Domain) server query**
- Resolver `.xyz` TLD server কে জিজ্ঞেস করে
- TLD server বলে: "alazimazxyz.xyz এর authoritative nameserver হলো dns1.registrar-servers.com / Namecheap's nameserver"

**Step 6: Authoritative nameserver query**
- Finally Namecheap এর DNS server (যেখানে আমরা records add করেছি) কে query করে
- Namecheap বলে: "alazimazxyz.xyz এর A record value 20.5.169.97"

**Step 7: Response back**
- IP address browser কে দেওয়া হয়
- Browser নতুন connection establish করে 20.5.169.97 এর সাথে
- HTTP request যায়, response আসে, page load হয়

**পুরো process ~50-200 milliseconds এ complete** হয়। এত fast যে user কিছুই বুঝে না।

### DNS server hierarchy

```
                Root DNS Servers (13 sets)
                /         |          \
              .com       .org       .xyz       ← TLD servers
              /                       \
        google.com                 alazimazxyz.xyz  ← Authoritative servers
                                  (Namecheap BasicDNS)
```

এই **hierarchical, distributed** design — কারণ:
- যদি single server এ সব DNS data থাকতো → fail হলে পুরো internet down হতো
- Distributed হওয়ায় load balanced, fault tolerant
- প্রতিটা level একটা specific responsibility এ focus করে

### Caching কেন important

প্রতিটা DNS query 6 steps complete করলে internet very slow হতো। তাই **caching everywhere**:

- Browser cache: minutes
- OS cache: minutes to hours
- Recursive resolver cache: hours (based on TTL)

এজন্য DNS change করার পর সবার কাছে নতুন value পৌঁছাতে time লাগে — এটাই **DNS propagation**।

## ৪. Real-life Server Example 🖥️

**Facebook outage 2021:**

2021 সালে Facebook (Meta) এর সব services — Facebook, WhatsApp, Instagram — 6 ঘণ্টা down ছিল। কারণ? Facebook এর BGP routes accidentally withdraw হয়ে গিয়েছিল, যার ফলে তাদের authoritative DNS servers internet থেকে disconnect হয়। মানে:
- কেউ `facebook.com` query করলে → DNS resolver Facebook এর nameservers find করতে পারছিল না
- পুরো Facebook ecosystem unreachable
- $60 million revenue loss in single day

এই incident থেকে শিক্ষা: **DNS infrastructure কোম্পানির single most critical dependency** — এটা down হলে সব down।

**আমাদের project এর scale এ:**
- আমাদের DNS down মানে শুধু আমাদের site down
- কিন্তু same principle apply করে — যদি Namecheap এর DNS service down হয়, আমাদের site reachable হবে না, even if Azure VM perfectly chalachhe

## ৫. Outcome

- DNS এর fundamental concept বুঝেছি
- Recursive lookup process বুঝেছি (browser → OS → ISP → TLD → authoritative)
- Caching কেন দরকার এবং কীভাবে work করে clear
- DNS hierarchy (root → TLD → authoritative) বুঝেছি

## ৬. When/Why Use করবো

- **Every web project এ:** Domain ছাড়া user-friendly URL নাই
- **Troubleshooting এ:** Site down হলে first check — DNS resolving কিনা?
- **Cyber security এ:** DNS poisoning, DDoS via DNS — major attack vectors
- **DevOps এ:** Multi-region deployment, geo-DNS, load balancing — সব DNS based

---

# 🏷️ Topic 2: Domain Name Structure

## ১. Concept

**Domain name** একটা hierarchical naming system — কয়েকটা parts diye তৈরি, প্রতিটার specific meaning আছে।

`alazimazxyz.xyz` কে break down করলে:

```
alazimazxyz.xyz
     │       │
     │       └── TLD (Top-Level Domain) = .xyz
     │
     └── SLD (Second-Level Domain) = alazimazxyz
```

Subdomain যোগ করলে:

```
www.alazimazxyz.xyz
 │         │      │
 │         │      └── TLD
 │         └────── SLD
 └─── Subdomain
```

## ২. Command/Syntax

```bash
# Subdomain গুলো check করো
dig www.alazimazxyz.xyz +short
dig vpn.alazimazxyz.xyz +short
dig status.alazimazxyz.xyz +short

# All DNS records দেখো
dig alazimazxyz.xyz ANY
```

## ৩. Deep Explanation

### Reading domain right-to-left

Domain names actually right থেকে left পড়তে হয় hierarchy বুঝতে:

```
www.mail.alazimazxyz.xyz
    │   │           │
    │   │           └── .xyz domain (managed by .xyz registry)
    │   └─────────────── alazimazxyz subdomain of .xyz (আমার)
    └─────────────────── mail subdomain of alazimazxyz.xyz
www subdomain of mail.alazimazxyz.xyz
```

**Implicit trailing dot:** Actually full FQDN (Fully Qualified Domain Name) হলো `alazimazxyz.xyz.` — শেষে একটা dot থাকে যেটা root domain represent করে। Browser এ আমরা type করি না, কিন্তু DNS internally এটা use করে।

### TLD types

| TLD Category | Examples | Use Case |
|---|---|---|
| **gTLD** (generic) | .com, .org, .net | General purpose |
| **ccTLD** (country code) | .au, .bd, .uk | Country-specific |
| **New gTLD** | .xyz, .tech, .app | Modern, often cheaper |
| **Sponsored** | .edu, .gov | Restricted use |

আমি `.xyz` choose করেছি কারণ:
- Cheap (~A$10/year vs .com ~A$15/year)
- Modern, tech-friendly TLD
- Branded names available (.com এ ভালো names সব taken)

### `@` symbol — Root domain

DNS records এ `@` মানে **root domain itself** (कोनো prefix ছাড়া)। যখন আমি Host field এ `@` লিখেছি, আসলে এটা represent করছিল `alazimazxyz.xyz` কে।

কেন `@` symbol? Historical convention — Old BIND DNS server এ `@` মানে "current origin"। Namecheap সহ সব DNS providers এই convention follow করে।

### Subdomain creation

কোনো subdomain create করতে — শুধু DNS record এ Host field এ subdomain name দিতে হয়:

| আমি যা type করলাম | Resulting domain |
|---|---|
| `@` | alazimazxyz.xyz |
| `www` | www.alazimazxyz.xyz |
| `vpn` | vpn.alazimazxyz.xyz |
| `status` | status.alazimazxyz.xyz |
| `mail` | mail.alazimazxyz.xyz |
| `blog.api` | blog.api.alazimazxyz.xyz (multi-level) |

**No additional cost for subdomains** — domain কেনার পর unlimited subdomains free।

## ৪. Real-life Server Example 🖥️

Real companies এর subdomain strategy:

**Google:**
- google.com → main search
- mail.google.com → Gmail
- drive.google.com → Drive
- docs.google.com → Docs
- maps.google.com → Maps

প্রতিটা subdomain একটা separate service এ point করে। User এর জন্য organized, internally different teams এই services manage করে।

**Amazon:**
- amazon.com → main shopping
- aws.amazon.com → AWS cloud
- music.amazon.com → Amazon Music
- developer.amazon.com → developer portal

**আমাদের project এর mapping:**

| Subdomain | Service | কেন |
|---|---|---|
| alazimazxyz.xyz | Ghost CMS blog | Main site |
| www.alazimazxyz.xyz | Same Ghost (redirect) | Backwards compatibility |
| vpn.alazimazxyz.xyz | WireGuard VPN | VPN client config এ use হবে |
| status.alazimazxyz.xyz | Security audit dashboard | Custom script output |

এই **multi-subdomain architecture** rubric এর "multi-purpose server with clear integration" requirement directly satisfy করে → 8 points।

## ৫. Outcome

- Domain name structure বুঝেছি (TLD, SLD, subdomain)
- `@` symbol এর meaning clear
- Subdomain organization strategy বুঝেছি
- Real-world companies কীভাবে subdomain use করে শিখেছি

## ৬. When/Why Use করবো

- **Project organization:** Different services → different subdomains
- **Production environments:** prod.app.com, staging.app.com, dev.app.com
- **API versioning:** v1.api.com, v2.api.com
- **Geographic separation:** us.app.com, eu.app.com

---

# 📋 Topic 3: DNS Record Types

## ১. Concept

DNS এ অনেক ধরনের records থাকে — প্রতিটার specific purpose। আমরা **A Record** use করেছি, কিন্তু অন্যগুলোও জানা দরকার।

| Record Type | Purpose | Example |
|---|---|---|
| **A** | Domain → IPv4 address | `example.com → 192.0.2.1` |
| **AAAA** | Domain → IPv6 address | `example.com → 2001:db8::1` |
| **CNAME** | Alias to another domain | `www.example.com → example.com` |
| **MX** | Mail server | `example.com → mail.example.com` |
| **TXT** | Text data (verification, SPF) | Verification codes |
| **NS** | Nameserver | Which DNS server is authoritative |
| **SOA** | Start of Authority | Zone metadata |
| **PTR** | Reverse lookup (IP → domain) | Reverse DNS |
| **SRV** | Service location | VoIP, chat services |

## ২. Command/Syntax

Specific record type query করতে:

```bash
# A record
dig alazimazxyz.xyz A +short

# AAAA (IPv6)
dig alazimazxyz.xyz AAAA +short

# CNAME
dig www.alazimazxyz.xyz CNAME +short

# MX (mail servers)
dig gmail.com MX +short

# TXT (verification, SPF)
dig google.com TXT +short

# NS (nameservers)
dig alazimazxyz.xyz NS +short
```

## ৩. Deep Explanation

### A Record (Address Record) — যেটা আমরা use করেছি

**A** = "Address"

A record একটা domain name কে একটা IPv4 address এ map করে। Simplest এবং most common record type।

আমাদের A records:
```
alazimazxyz.xyz       A    20.5.169.97
www.alazimazxyz.xyz   A    20.5.169.97
vpn.alazimazxyz.xyz   A    20.5.169.97
status.alazimazxyz.xyz A   20.5.169.97
```

সবগুলো same IP তে point করছে। কেন? কারণ আমাদের একটাই VM (20.5.169.97), nginx reverse proxy আলাদা subdomain গুলো আলাদা service এ route করবে।

### AAAA Record (IPv6)

IPv4 (যেমন 20.5.169.97) এর অভাব হচ্ছে — internet এ device সংখ্যা বেড়ে যাচ্ছে। তাই **IPv6** (যেমন `2001:0db8:85a3::8a2e:0370:7334`) introduce করা হয়েছে।

আমরা AAAA add করিনি কারণ:
- Azure B-series VMs এ IPv6 by default disabled
- IPv6 setup additional complexity
- Most users এখনো IPv4 দিয়ে access করে

Production সাইটে AAAA record add করা best practice modern internet এ।

### CNAME (Canonical Name)

**CNAME** = "alias for another domain"। মানে এই domain এর actual address খুঁজতে অন্য domain এর A record দেখো।

Example:
```
blog.example.com   CNAME   example.com
example.com        A       192.0.2.1
```

কেউ `blog.example.com` query করলে:
1. DNS দেখে CNAME → `example.com`
2. `example.com` query করে → 192.0.2.1
3. Final answer: 192.0.2.1

**CNAME vs A record difference:**

| CNAME | A Record |
|---|---|
| অন্য domain reference করে | Directly IP দেয় |
| 2-step lookup | 1-step lookup (faster) |
| Easier to maintain (IP change হলে শুধু A record update) | Multiple records update লাগবে |
| Root domain এ allowed না (some providers) | Anywhere use যায় |

**আমরা কেন CNAME use করিনি:**

আমি `www → CNAME → alazimazxyz.xyz` করতে পারতাম। কিন্তু A record use করেছি কারণ:
1. **Simpler** — direct IP mapping
2. **Faster** — single DNS lookup
3. **More flexible** — পরে যদি www আলাদা service এ চাই, easy change

Namecheap এর default parking page `www → CNAME → parkingpage.namecheap.com.` ছিল — সেটা delete করেছি কারণ এটা parking page এ পাঠাতো, আমাদের nginx এ না।

### MX Record (Mail Exchange)

Email servers এর জন্য। Gmail send করতে চাইলে DNS query হয়:
```
dig gmail.com MX +short
```

Returns:
```
5 gmail-smtp-in.l.google.com.
10 alt1.gmail-smtp-in.l.google.com.
20 alt2.gmail-smtp-in.l.google.com.
```

Numbers হলো **priority** — lowest first try করে। যদি fail করে, পরবর্তী priority try করে। **Built-in redundancy**।

আমরা MX add করিনি কারণ আমাদের email server নাই। চাইলে পরে Google Workspace বা ProtonMail এর সাথে integrate করতে পারি।

### TXT Record (Text)

Free-form text data store করার জন্য। Common uses:

**Domain ownership verification:**
```
google-site-verification: abc123xyz...
```
Google Search Console এ এটা add করতে বলে "প্রমাণ করো এই domain তোমার"।

**SPF (Sender Policy Framework):**
```
v=spf1 include:_spf.google.com ~all
```
কোন server email পাঠাতে পারবে from this domain — spam prevention।

**DKIM (DomainKeys Identified Mail):**
Email authenticity prove করার জন্য cryptographic signature।

আমাদের TXT এখন দরকার নাই, কিন্তু future এ যদি email setup করি, এগুলো লাগবে।

### NS Record (Nameserver)

কোন DNS server authoritative এই domain এর জন্য। Namecheap দেখায়:

```
dns1.registrar-servers.com (initially)
dns2.registrar-servers.com
```

DNS type change করার পর:
```
dns1.namecheaphosting.com (or similar)
dns2.namecheaphosting.com
```

NS records — internet কে জানায় "এই domain এর data পেতে এই server এ যাও"।

## ৪. Real-life Server Example 🖥️

Real production domain এর full DNS configuration (e.g., facebook.com):

```
facebook.com           A      157.240.241.35
facebook.com           AAAA   2a03:2880:f0fc:c:face:b00c:0:25de
www.facebook.com       A      157.240.241.35
facebook.com           MX     10 msgin.t.facebook.com
facebook.com           NS     a.ns.facebook.com
facebook.com           NS     b.ns.facebook.com
facebook.com           TXT    "v=spf1 redirect=_spf.facebook.com"
_acme-challenge.facebook.com   TXT   "..." (Let's Encrypt verification)
```

Production এ অনেক records থাকে — different services, security verification, email, IPv6, redundancy।

**আমাদের project এ এখন:**
```
alazimazxyz.xyz        A   20.5.169.97
www.alazimazxyz.xyz    A   20.5.169.97
vpn.alazimazxyz.xyz    A   20.5.169.97
status.alazimazxyz.xyz A   20.5.169.97
```

Simple কিন্তু professional — exactly যা assignment এ লাগবে।

## ৫. Outcome

- DNS record types এর variety বুঝেছি
- A vs CNAME এর difference clear
- MX, TXT, NS records এর purpose বুঝেছি
- Production-grade DNS configurations দেখেছি

## ৬. When/Why Use করবো

- **A/AAAA:** Every web service deploy এ
- **CNAME:** When pointing subdomain to main domain
- **MX:** Email server setup
- **TXT:** SSL verification, SPF/DKIM email security
- **Troubleshooting:** Know which record type to query

---

# 🏢 Topic 4: Namecheap Interface এবং DNS Modes

## ১. Concept

**Namecheap** হলো একটা domain registrar — they sell domains এবং DNS management service provide করে। তাদের interface এ multiple DNS modes আছে:

1. **Namecheap BasicDNS** — Simple, free, sufficient for most uses ✅ আমরা use করছি
2. **Namecheap Web Hosting DNS** — যদি Namecheap এর hosting কিনো
3. **Custom DNS** — তোমার own/third-party nameservers
4. **Namecheap PremiumDNS** — Paid, DDoS protection, 100% uptime SLA

## ২. Command/Syntax

Namecheap interface এ navigate করার flow:

```
namecheap.com → login
  → Dashboard
    → Domain List
      → MANAGE (next to domain)
        → Advanced DNS tab
          → Host Records section
            → ADD NEW RECORD
```

## ৩. Deep Explanation

### আমাদের case — কেন Custom DNS থেকে BasicDNS এ switch করতে হলো

প্রথমে যখন Advanced DNS tab এ গেলাম, Host Records section error message দেখাচ্ছিল:

> "You can manage host records in your cPanel account, or transfer DNS back to Namecheap BasicDNS to manage the records here."

কেন? কারণ আমার domain initially configured ছিল **Custom DNS mode** এ, with nameservers:
```
dns1.registrar-servers.com
dns2.registrar-servers.com
```

এই nameservers actually Namecheap's cPanel hosting এর জন্য। Namecheap যদি তুমি domain + hosting bundle কিনো, automatically এই nameservers set করে দেয় যাতে hosting easily integrate হয়।

কিন্তু আমার hosting Namecheap এ না — Azure এ। তাই DNS management ভিন্ন platform এ হচ্ছিল, এবং Advanced DNS tab এ records add করতে দিচ্ছিল না।

**Solution:** DNS type change করলাম **Namecheap BasicDNS** এ:

```
Domain tab → Nameservers section → 
"Custom DNS" → dropdown → "Namecheap BasicDNS" → Save
```

এর পরের effects:
- Old nameservers (registrar-servers.com) removed
- New nameservers automatically set (dns1.namecheaphosting.com etc.)
- Advanced DNS tab এ Host Records section unlocked
- আমি directly records add করতে পারলাম

### Namecheap interface এর key sections

**Domain tab:**
- Status (Active/Expired)
- Validity period
- WhoisGuard privacy
- Nameservers setting
- Redirect domain (optional URL forwarding)
- Renewal options

**Products tab:**
- Hosting add-ons
- SSL certificates
- Email products

**Sharing & Transfer tab:**
- Domain sharing
- Transfer to other registrars

**Advanced DNS tab:**
- DNS Templates (preset configurations)
- **Host Records** ← আমরা এখানে কাজ করেছি
- DNSSEC (DNS security extension)
- Mail Settings
- Personal DNS Server (custom)

### আমাদের Add Host Record popup এর fields explanation

যখন **+ ADD NEW RECORD** click করলাম, একটা popup এলো:

| Field | Value | কেন এই value |
|---|---|---|
| Record Type | A Record | Domain → IPv4 mapping |
| Host | `@`, `www`, `vpn`, `status` | Subdomain identifier |
| IP Address | `20.5.169.97` | আমাদের Azure VM IP |
| TTL | Automatic | Default caching (30 min) |

### URL Redirect কেন delete করলাম

Initial Domain tab এ একটা **URL Redirect** ছিল:
```
alazimazxyz.xyz → http://www.alazimazxyz.xyz/
```

এটা Namecheap's default — domain কেনার পর parking page এ পাঠাতো ("This domain is for sale" type page)।

**Conflict potential:**
- A record বলে: `alazimazxyz.xyz → 20.5.169.97` (আমাদের server)
- URL Redirect বলে: `alazimazxyz.xyz → http://www.alazimazxyz.xyz/` (parking)
- দুই rules simultaneously active হলে behaviour unpredictable

**Solution:** URL Redirect delete করলাম 🗑️ icon click করে। এখন শুধু A records active।

## ৪. Real-life Server Example 🖥️

Real business এ Namecheap-style DNS management:

**Startup workflow:**
1. Domain কেনে (`mybusiness.com`)
2. AWS / Azure / DigitalOcean এ server provision করে
3. DNS provider এ A records add করে (server IP)
4. SSL certificate setup (Let's Encrypt)
5. Site live

**Enterprise workflow:**
1. Multiple domains across registrars (geographic + compliance)
2. Centralized DNS management (Cloudflare, Route 53)
3. GitOps for DNS — DNS records in Git, auto-deploy
4. Monitoring — alerts if DNS resolution fails
5. DDoS protection at DNS layer

### Cloudflare vs Namecheap BasicDNS

| Feature | Namecheap BasicDNS | Cloudflare |
|---|---|---|
| Cost | Free with domain | Free tier available |
| Speed | Moderate | Very fast (global CDN) |
| DDoS protection | Basic | Excellent |
| SSL | Manual setup | Built-in |
| Analytics | Limited | Detailed |
| Use case | Small projects, simple | Production, performance-critical |

Many production sites use Cloudflare as DNS even when domain registered elsewhere — better performance এবং security এর জন্য।

## ৫. Outcome

- Namecheap interface navigate করতে পারি
- DNS modes এর difference বুঝেছি
- Custom DNS vs BasicDNS use cases clear
- DNS records add/edit/delete করতে পারি
- Real-world DNS provider choice criteria বুঝেছি

## ৬. When/Why Use করবো

- **Future domain purchases:** Same flow apply করবে
- **Job e:** DNS management common task — every web project এ
- **Troubleshooting:** "Site not loading" এর first check — DNS records correct?
- **Cost optimization:** Right DNS provider choose করা

---

# ⏱️ Topic 5: TTL (Time To Live) এবং DNS Propagation

## ১. Concept

**TTL (Time To Live)** = একটা DNS record কতক্ষণ DNS resolvers এর cache এ থাকবে।

**Propagation** = DNS change এর পর internet এর সব servers এ সেই update পৌঁছানো।

আমরা TTL = "Automatic" set করেছি, যেটা Namecheap এ default = **30 minutes**।

## ২. Command/Syntax

```bash
# TTL সহ details দেখো
dig alazimazxyz.xyz

# Specific resolver test
dig @1.1.1.1 alazimazxyz.xyz +short

# Force fresh lookup (cache bypass)
dig +trace alazimazxyz.xyz

# Windows এ DNS cache flush
ipconfig /flushdns

# Linux/macOS এ
sudo systemd-resolve --flush-caches  # systemd-based
sudo dscacheutil -flushcache  # macOS
```

## ৩. Deep Explanation

### TTL এর mechanism

যখন DNS resolver একটা domain query করে এবং response পায়, response এর সাথে TTL value আসে। Resolver সেই record cache করে exactly TTL seconds এর জন্য।

```
$ dig alazimazxyz.xyz
;; ANSWER SECTION:
alazimazxyz.xyz.   1800   IN   A   20.5.169.97
                    ↑
                  TTL = 1800 seconds = 30 minutes
```

Mean কী এই TTL?
- পরবর্তী 30 মিনিট, এই resolver alazimazxyz.xyz এর জন্য Namecheap কে আবার query করবে না
- সব users যারা এই resolver use করে — তারা cached value পাবে
- 30 মিনিট পর resolver expire করবে cache, আবার fresh query করবে

### TTL এর trade-off

**Low TTL (5 min):**

✅ **Pros:**
- DNS changes দ্রুত propagate করে
- IP change করলে quickly effect হয়
- A/B testing, frequent updates suitable

❌ **Cons:**
- More DNS queries → slightly slower page loads
- More load on DNS server
- Higher costs (if paid DNS)

**High TTL (1 day or more):**

✅ **Pros:**
- Less DNS queries → faster page loads
- Lower DNS server load
- Less bandwidth

❌ **Cons:**
- Changes take long to propagate
- If IP changes, users see down site for hours
- Less flexibility

**Best practice:**
- Normal operation: 1 hour or higher
- Before planned change: lower to 5 min, wait for old TTL expire, then make change
- After change: raise back to high TTL

### Propagation explained

When I add 4 A records এ Namecheap এ:

**Step 1: Records add to Namecheap's authoritative servers (instant)**
- Namecheap immediately updates their DNS database
- দুনিয়ার সব authoritative queries এখন correct answer পাবে

**Step 2: ISP/resolver caches (slow propagation)**
- যারা already cache করেছিল আগের answer (যেমন "no record found"), তারা পুরনো cache hold করবে negative TTL period পর্যন্ত
- Negative caching — DNS resolvers absent records ও cache করে (1-15 minutes typically)
- নতুন records ধীরে ধীরে globally propagate করে যখন cache expire হয়

**Step 3: Browser/OS caches (very slow)**
- যদি browser আগে query করে থাকে, browser cache hold করতে পারে hours পর্যন্ত
- Browser restart বা cache clear করলে fresh query হবে

**Typical propagation timeline:**
- Same ISP, fresh users: 1-5 min
- Different ISPs globally: 5-30 min
- All worldwide locations: 30 min - 24 hours

**Namecheap BasicDNS** usually very fast propagation — most checks 5-15 min এ done।

### "Why isn't my site loading yet?"

Common reason hierarchy:

**1. DNS not propagated yet (most common)**
- Test: `dig alazimazxyz.xyz +short` from terminal
- If returns IP: DNS working
- If empty: wait or check Namecheap records

**2. Browser cache**
- Test: Incognito mode
- Or: clear browser cache

**3. OS DNS cache**
- Test: `ipconfig /flushdns` (Windows)
- Then retry

**4. ISP cache stuck**
- Try different DNS resolver: `dig @1.1.1.1 alazimazxyz.xyz`
- Cloudflare's 1.1.1.1 generally fastest to update

**5. Server not actually listening**
- SSH to server: `curl http://localhost`
- If works locally but not externally — firewall issue

**6. Firewall blocking**
- Check NSG (Azure)
- Check UFW (host)

## ৪. Real-life Server Example 🖥️

**Production migration scenario:**

Company X এর server old IP `1.2.3.4` থেকে new IP `5.6.7.8` এ migrate করতে হবে। Zero downtime চাই।

**Standard procedure:**

```
Day 0: Plan migration
  → Lower TTL to 5 minutes
  → Wait 24 hours (let old TTL expire globally)

Day 1: Migration day
  → New server ready at 5.6.7.8 (running)
  → Old server still running at 1.2.3.4
  → Change DNS A record: 1.2.3.4 → 5.6.7.8
  → Most users get new IP within 5 min
  → Stragglers still hit old server (still running)
  → Both servers serve traffic for ~1 hour

Day 2: Cleanup
  → All traffic now on new server
  → Decommission old server
  → Raise TTL back to 1 hour
```

**আমাদের project এ:**
TTL Automatic (30 min) acceptable কারণ:
- Lab project, not high-traffic
- Initial setup, no migration yet
- Future changes can be planned (lower TTL first)

## ৫. Outcome

- TTL concept clearly বুঝেছি
- Caching layers কীভাবে interact করে শিখেছি
- Propagation slow হয় কেন বুঝেছি
- Troubleshooting hierarchy শিখেছি

## ৬. When/Why Use করবো

- **Production migrations:** Lower TTL ahead of changes
- **Troubleshooting:** Why DNS change not visible
- **Cost optimization:** Higher TTL = less DNS queries
- **Reliability planning:** Understand propagation expectations

---

# 🌐 Topic 6: আমরা যে 4 টা A Record Add করেছি — Each Record Explained

## ১. Concept

আমরা একই IP তে 4 টা A record add করেছি — different subdomains এর জন্য। প্রতিটার একটা specific purpose আছে।

## ২. Command/Syntax

```bash
# প্রতিটা subdomain test করো
dig alazimazxyz.xyz +short          # → 20.5.169.97
dig www.alazimazxyz.xyz +short      # → 20.5.169.97
dig vpn.alazimazxyz.xyz +short      # → 20.5.169.97
dig status.alazimazxyz.xyz +short   # → 20.5.169.97
```

## ৩. Deep Explanation

### Record 1: `@` (Root Domain)

```
Type: A Record
Host: @
Value: 20.5.169.97
TTL: Automatic
```

**Purpose:** যখন কেউ browser এ শুধু `alazimazxyz.xyz` type করে, এই record তাদের 20.5.169.97 এ পাঠায়।

**Real flow:**
1. User types `alazimazxyz.xyz` in browser
2. DNS resolves to 20.5.169.97
3. Browser connects to 20.5.169.97 port 80 (HTTP) or 443 (HTTPS)
4. Nginx serves the Ghost CMS blog

**Importance:** এটা **most critical record** — root domain access।

### Record 2: `www` Subdomain

```
Type: A Record
Host: www
Value: 20.5.169.97
TTL: Automatic
```

**Purpose:** `www.alazimazxyz.xyz` এ visit করলে same server এ পাঠায়।

**Why separate www record:**

Historical reasons + user habit:
- Older users type `www.` automatically
- Some email clients auto-prepend www
- SEO best practice — both www and non-www should work
- Pre-2010 era, "www" was the standard prefix

**Modern practice:** Either redirect www → root, or root → www. Choose one as "canonical". Nginx config পরে এটা handle করবে।

### Record 3: `vpn` Subdomain

```
Type: A Record
Host: vpn
Value: 20.5.169.97
TTL: Automatic
```

**Purpose:** WireGuard VPN endpoint এর জন্য reference।

**কেন এটা future-অর জন্য:**
- WireGuard install করবো same VM এ (port UDP 51820)
- VPN clients এ endpoint config করতে হবে: `vpn.alazimazxyz.xyz:51820`
- IP মনে রাখার চেয়ে domain easier

**Bonus benefit:** যদি future এ VPN আলাদা server এ move করি, শুধু এই A record এর IP change করলেই হবে — clients এ কিছু change লাগবে না।

### Record 4: `status` Subdomain

```
Type: A Record
Host: status
Value: 20.5.169.97
TTL: Automatic
```

**Purpose:** Security audit script এর output dashboard host করার জন্য।

**Project plan:**
- Custom Bash/Python script লিখবো যেটা security checks করবে (failed logins, SSL expiry, open ports, fail2ban status)
- Script এর output HTML format এ write করবে `/var/www/status/index.html` এ
- Nginx config করবো — `status.alazimazxyz.xyz` request আসলে এই file serve করবে
- Anyone visiting `status.alazimazxyz.xyz` will see live security health

**Rubric impact:** এটা directly script এর "verifiable output" requirement satisfy করে → 2 points।

### সব subdomain same IP — কীভাবে আলাদা service serve হবে?

প্রশ্ন: যদি 4 টা subdomain same IP তে point করে, server কীভাবে জানবে কোন service serve করবে?

**Answer: Nginx Server Block / Virtual Host**

Nginx HTTP request এর **`Host` header** check করে — browser request এ যে domain typed করেছে সেটা header এ থাকে।

```
GET / HTTP/1.1
Host: vpn.alazimazxyz.xyz
```

Nginx config files এ আমরা define করি:
```nginx
server {
    server_name alazimazxyz.xyz www.alazimazxyz.xyz;
    # → Route to Ghost CMS (port 2368)
}

server {
    server_name vpn.alazimazxyz.xyz;
    # → Show VPN config page
}

server {
    server_name status.alazimazxyz.xyz;
    # → Serve /var/www/status/index.html
}
```

Same IP, same port, কিন্তু **different services based on Host header**। এটাই **virtual hosting**।

## ৪. Real-life Server Example 🖥️

WordPress.com এর architecture (simplified):

```
yourblog.wordpress.com    A   192.0.2.50
otherblog.wordpress.com   A   192.0.2.50
thirdblog.wordpress.com   A   192.0.2.50
```

হাজার হাজার blogs same IP তে point করে। WordPress এর servers Host header দেখে decide করে কোন blog এর content serve করবে। One IP, millions of blogs।

**Cost efficient:** Public IPv4 expensive (~$5/month per IP at AWS)। Sharing via virtual hosting saves a lot।

**আমাদের project এ:** Same VM, 4 subdomain, 4 different services। Just like WordPress at smaller scale।

## ৫. Outcome

- প্রতিটা A record এর specific purpose বুঝেছি
- Subdomain strategy planning শিখেছি
- Same IP তে multiple services serve করার mechanism বুঝেছি (virtual hosting)
- Future-proof design (DNS-level abstraction)

## ৬. When/Why Use করবো

- **Multi-service projects:** এই pattern repeat হবে
- **Cost optimization:** One server, multiple services
- **Migration flexibility:** IP change করলে সব subdomain একসাথে update
- **Professional appearance:** Branded subdomains (vpn.company.com vs ugly IP)

---

# 📊 Final Summary (Step 5 সব মিলিয়ে)

আজ DNS configuration এ যা যা achieve করেছি:

```
┌──────────────────────────────────────────────────────┐
│           DNS CONFIGURATION — STEP 5 DONE            │
└──────────────────────────────────────────────────────┘

  ✅ 1. Custom DNS থেকে Namecheap BasicDNS এ switch
  ✅ 2. Old URL Redirect deleted (parkingpage)
  ✅ 3. Default CNAME deleted (www → parkingpage)
  ✅ 4. 4 টা A Record added:
        • alazimazxyz.xyz       → 20.5.169.97
        • www.alazimazxyz.xyz   → 20.5.169.97
        • vpn.alazimazxyz.xyz   → 20.5.169.97
        • status.alazimazxyz.xyz → 20.5.169.97
  ⏳ 5. DNS propagation (5-30 min wait)
  ⏳ 6. Browser test: http://alazimazxyz.xyz
```

**Final state:** Domain properly mapped to Azure VM via Namecheap BasicDNS, supporting root domain + 3 subdomains for future multi-service architecture.

---

## 🔗 Real-World Usage Table (Step 5 specific)

| আমি Lab এ যা করেছি | Real-world application |
|---|---|
| DNS type change (Custom → BasicDNS) | Migrating between DNS providers (e.g., GoDaddy → Cloudflare) |
| A Record add for root domain | Every website launch requires this |
| Multiple subdomain A records | Multi-service architecture (api.x, blog.x, app.x) |
| TTL Automatic setting | Balance between flexibility and performance |
| URL Redirect deletion | Cleaning up conflicting DNS configurations |
| DNS propagation understanding | Production migration planning |
| `dig` command for verification | Daily troubleshooting in DevOps |
| Virtual hosting via Host header | SaaS platforms (WordPress.com, Shopify) |

---

## 💡 Reflection (Assignment style answer)

এই DNS configuration session এ আমি successfully `alazimazxyz.xyz` domain কে আমার Azure VM (20.5.169.97) এর সাথে map করেছি Namecheap এর DNS management interface ব্যবহার করে। এই exercise শুধু একটা technical task ছিল না — এটা আমাকে DNS এর fundamental architecture এবং internet infrastructure কীভাবে work করে সেটা গভীরভাবে বুঝতে সাহায্য করেছে।

প্রথম যে challenge আসে সেটা ছিল **DNS mode mismatch।** Domain initially **Custom DNS** mode এ ছিল, nameservers Namecheap's cPanel hosting এর জন্য — যেখানে আমার hosting Azure এ। এই situation আমাকে শিখিয়েছে যে domain registrar এবং hosting provider আলাদা হতে পারে, এবং DNS management interface সেই অনুযায়ী configure করতে হয়। **Namecheap BasicDNS** এ switch করার পর Host Records section unlock হলো, এবং আমি directly A records add করতে পারলাম।

**Multi-subdomain architecture** plan করা ছিল একটা strategic decision। `@`, `www`, `vpn`, এবং `status` — 4 টা subdomain একই IP তে point করে, কিন্তু future এ nginx reverse proxy এর মাধ্যমে এদেরকে আলাদা services এ route করবো। এই pattern — same server hosting multiple services via virtual hosting — এটাই production environments এর foundation। WordPress.com থেকে শুরু করে enterprise SaaS platforms — সবাই same principle apply করে।

**TTL** এবং **DNS propagation** এর mechanism বুঝা একটা valuable lesson ছিল। DNS changes instant না — caching layers (browser, OS, ISP) এর কারণে updates ধীরে spread করে। এই realization production environments এ migration planning এর জন্য critical। Real engineers TTL আগে lower করে, তারপর change apply করে, after stabilization আবার raise করে।

URL Redirect এবং default CNAME delete করার decision এ আমি learned conflicting DNS rules cleanup করার importance। Multiple rules simultaneously active থাকলে behaviour unpredictable হতে পারে। **Clean configuration > clever configuration।**

আগামী step এ এই DNS configuration enable করবে SSL certificate setup (Let's Encrypt domain verification এর জন্য DNS resolve হতে হবে), Ghost CMS deployment, এবং WireGuard VPN endpoint configuration। প্রতিটা subdomain তার দায়িত্ব ঠিকমতো serve করবে nginx reverse proxy এর মাধ্যমে।

---

**শেষ। (End of Lab Note)**

*Document version: 1.0 — Created 26 May 2026*
