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
#   3. Listening network ports (attack surface monitoring)
#   4. UFW firewall status (security baseline verification)
#   5. SSL/TLS certificate expiry (downtime prevention)
#   6. Pending system updates (vulnerability management)
#   7. System resource health (operational monitoring)
#
# Designed to run via cron every hour for live monitoring.
#==============================================================================

set -u
OUTPUT="/var/www/status/index.html"
DOMAIN="alazimazxyz.xyz"
NOW=$(date '+%Y-%m-%d %H:%M:%S %Z')

#-------------------------------------------------------------------------------
# Data Collection Section
#-------------------------------------------------------------------------------

# (1) Failed SSH login attempts from system journal (last 24h)
FAILED_SSH=$(sudo journalctl _COMM=sshd --since "24 hours ago" 2>/dev/null | grep -ci "failed password" || echo "0")

# (2) Active SSH sessions currently connected
ACTIVE_SESSIONS=$(who | wc -l)

# (3) Listening TCP/UDP ports
OPEN_PORTS=$(sudo ss -tuln 2>/dev/null | awk 'NR>1 && /LISTEN/ {print $5}' | sort -u | head -20)

# (4) UFW firewall status
FW_STATUS=$(sudo ufw status 2>/dev/null | head -1 | awk '{print $2}')
FW_RULES=$(sudo ufw status 2>/dev/null | tail -n +5 | head -10)

# (5) SSL certificate expiry
SSL_RAW=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -n "$SSL_RAW" ]; then
    SSL_EXPIRY_EPOCH=$(date -d "$SSL_RAW" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    SSL_DAYS_LEFT=$(( (SSL_EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    SSL_EXPIRY="$SSL_RAW ($SSL_DAYS_LEFT days remaining)"
else
    SSL_EXPIRY="Unable to check"
    SSL_DAYS_LEFT=0
fi

# (6) Pending package updates
PENDING_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")

# (7) System resource usage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
DISK_DETAIL=$(df -h / | awk 'NR==2 {print $3 " of " $2}')
MEM_TOTAL=$(free -h | awk 'NR==2 {print $2}')
MEM_USED=$(free -h | awk 'NR==2 {print $3}')
UPTIME=$(uptime -p)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
HOSTNAME=$(hostname)
KERNEL=$(uname -r)

# Determine health status colors
[ "$FAILED_SSH" -gt 50 ] && SSH_STATUS="warn" || SSH_STATUS="ok"
[ "$FW_STATUS" = "active" ] && FW_CLASS="ok" || FW_CLASS="danger"
[ "$SSL_DAYS_LEFT" -gt 14 ] && SSL_CLASS="ok" || SSL_CLASS="warn"
[ "$PENDING_UPDATES" -lt 10 ] && UPDATE_CLASS="ok" || UPDATE_CLASS="warn"

#-------------------------------------------------------------------------------
# HTML Report Generation
#-------------------------------------------------------------------------------

sudo tee "$OUTPUT" > /dev/null <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Security Dashboard — $DOMAIN</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%);
    color: #e6edf3;
    min-height: 100vh;
    padding: 30px 20px;
  }
  .container { max-width: 1100px; margin: 0 auto; }
  header {
    text-align: center;
    margin-bottom: 40px;
    padding: 30px;
    background: rgba(255,255,255,0.05);
    border-radius: 16px;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255,255,255,0.1);
  }
  header h1 {
    font-size: 2.2em;
    background: linear-gradient(90deg, #58a6ff, #a371f7);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    margin-bottom: 8px;
  }
  header p { color: #8b949e; font-size: 0.95em; }
  .meta-bar {
    display: flex; justify-content: center; gap: 20px;
    margin-top: 15px; flex-wrap: wrap; font-size: 0.85em; color: #8b949e;
  }
  .meta-bar span { background: rgba(255,255,255,0.05); padding: 4px 12px; border-radius: 20px; }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
  }
  .card {
    background: rgba(22, 27, 34, 0.7);
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 12px;
    padding: 24px;
    backdrop-filter: blur(10px);
    transition: transform 0.2s, box-shadow 0.2s;
  }
  .card:hover {
    transform: translateY(-3px);
    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
  }
  .card-header {
    display: flex; justify-content: space-between; align-items: center;
    margin-bottom: 16px; padding-bottom: 12px;
    border-bottom: 1px solid rgba(255,255,255,0.08);
  }
  .card-title { font-size: 1.05em; color: #79c0ff; font-weight: 600; }
  .badge {
    padding: 4px 12px; border-radius: 12px;
    font-size: 0.75em; font-weight: 600; text-transform: uppercase;
  }
  .badge.ok { background: rgba(63,185,80,0.2); color: #3fb950; border: 1px solid rgba(63,185,80,0.3); }
  .badge.warn { background: rgba(210,153,34,0.2); color: #d29922; border: 1px solid rgba(210,153,34,0.3); }
  .badge.danger { background: rgba(248,81,73,0.2); color: #f85149; border: 1px solid rgba(248,81,73,0.3); }
  .stat { font-size: 2em; font-weight: 700; color: #e6edf3; margin: 8px 0; }
  .stat-label { color: #8b949e; font-size: 0.85em; }
  .data-row {
    display: flex; justify-content: space-between; padding: 6px 0;
    border-bottom: 1px solid rgba(255,255,255,0.05); font-size: 0.9em;
  }
  .data-row:last-child { border-bottom: none; }
  .data-row span:last-child { color: #79c0ff; font-family: monospace; }
  pre {
    background: rgba(0,0,0,0.3); padding: 12px; border-radius: 8px;
    overflow-x: auto; font-size: 0.85em; color: #7ee787;
    border: 1px solid rgba(255,255,255,0.05);
  }
  footer {
    text-align: center; margin-top: 40px; padding: 20px;
    color: #6e7681; font-size: 0.85em;
  }
  footer a { color: #58a6ff; text-decoration: none; }
</style>
</head>
<body>
<div class="container">

  <header>
    <h1>🛡️ Server Security Dashboard</h1>
    <p>Real-time security & system health monitoring</p>
    <div class="meta-bar">
      <span>🌐 $DOMAIN</span>
      <span>🖥️ $HOSTNAME</span>
      <span>⏰ $NOW</span>
    </div>
  </header>

  <div class="grid">

    <div class="card">
      <div class="card-header">
        <span class="card-title">🔐 SSH Security</span>
        <span class="badge $SSH_STATUS">$SSH_STATUS</span>
      </div>
      <div class="stat">$FAILED_SSH</div>
      <div class="stat-label">Failed login attempts (last 24h)</div>
      <div class="data-row" style="margin-top:14px;">
        <span>Active sessions</span><span>$ACTIVE_SESSIONS</span>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <span class="card-title">🔥 Firewall (UFW)</span>
        <span class="badge $FW_CLASS">$FW_STATUS</span>
      </div>
      <div class="stat-label" style="margin-bottom:8px;">Active rules:</div>
      <pre>$FW_RULES</pre>
    </div>

    <div class="card">
      <div class="card-header">
        <span class="card-title">🔒 SSL Certificate</span>
        <span class="badge $SSL_CLASS">$SSL_DAYS_LEFT days</span>
      </div>
      <div class="stat-label">Expires:</div>
      <div style="font-family:monospace; color:#79c0ff; margin-top:8px; font-size:0.9em;">$SSL_EXPIRY</div>
    </div>

    <div class="card">
      <div class="card-header">
        <span class="card-title">📦 System Updates</span>
        <span class="badge $UPDATE_CLASS">pending</span>
      </div>
      <div class="stat">$PENDING_UPDATES</div>
      <div class="stat-label">Packages available for upgrade</div>
    </div>

    <div class="card" style="grid-column: span 2;">
      <div class="card-header">
        <span class="card-title">🌐 Listening Ports</span>
        <span class="badge ok">monitored</span>
      </div>
      <pre>$OPEN_PORTS</pre>
    </div>

    <div class="card" style="grid-column: span 2;">
      <div class="card-header">
        <span class="card-title">💻 System Health</span>
        <span class="badge ok">running</span>
      </div>
      <div class="data-row"><span>Disk usage</span><span>$DISK_USAGE ($DISK_DETAIL)</span></div>
      <div class="data-row"><span>Memory</span><span>$MEM_USED / $MEM_TOTAL</span></div>
      <div class="data-row"><span>Load average</span><span>$LOAD_AVG</span></div>
      <div class="data-row"><span>Uptime</span><span>$UPTIME</span></div>
      <div class="data-row"><span>Kernel</span><span>$KERNEL</span></div>
    </div>

  </div>

  <footer>
    Generated by <strong>security-audit.sh</strong> · 
    ICT171 Cloud Server Project · MD Abdullah Al Azim (36018444)<br>
    <a href="https://github.com/al-azim-az/ict171-cloud-server-project">View source on GitHub</a>
  </footer>

</div>
</body>
</html>
HTMLEOF

echo "[$(date '+%H:%M:%S')] Security audit complete. Report written to $OUTPUT"
