#!/bin/bash
# 1. Create Blue Team SSH User & Configure Custom Port
useradd -m -s /bin/bash analyst
echo "analyst:blue_team_rocks" | chpasswd

sed -i 's/#Port 22/Port 2275/g' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 2275/g' /etc/ssh/sshd_config
systemctl restart ssh

# 2. Install Docker & Docker Compose
apt-get update
apt-get install -y docker.io docker-compose

# 3. Create Log Forensics Directory (Blue Team Path Phase 1)
mkdir -p /opt/admin/logs
# SCENARIO75{/opt/admin/logs}

# 4. Generate Mock Telemetry & Log Forensics
# Injecting precise timestamps, IPs, Subnets, and User Agents

# -- NGINX-Style Access Logs --
cat << 'EOF' > /opt/admin/logs/access.log
192.168.1.100 - - [30/Jun/2026:18:45:00 +0700] "GET /dashboard HTTP/1.1" 200 - "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "-"
10.10.14.50 - - [30/Jun/2026:18:50:00 +0700] "GET /robots.txt HTTP/1.1" 200 - "Mozilla/5.0" "-"
10.10.14.50 - - [30/Jun/2026:18:51:55 +0700] "GET /dashboard HTTP/1.1" 200 - "Mozilla/5.0" "X-Forwarded-For: UEhBTlRPTUdSSUR7QkxVRV9MMGdfSHVudDNyX000c3Qzcn0}"
EOF

# -- Application Error Logs (Threat Hunting & IR) --
cat << 'EOF' > /opt/admin/logs/error.log
[30/Jun/2026:18:50:15 +0700] [error] [client 10.10.14.50] WAF Blocked <script> tag detected in payload.
[30/Jun/2026:18:53:10 +0700] [CRITICAL] Authentication bypass anomaly: User session accessed /dashboard without hitting /api/verify-mfa.
EOF

# Ensure the analyst user can read the logs
chown -R analyst:analyst /opt/admin/logs

# 5. Start the CTF Environment
docker-compose up -d