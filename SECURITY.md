# Security Documentation

This document describes the security measures implemented in the Rayan Azure deployment project.

---

## Table of Contents

1. [SSH Key Authentication](#ssh-key-authentication)
2. [Network Security (NSG)](#network-security-nsg)
3. [Application Security](#application-security)
4. [Operating System Security](#operating-system-security)
5. [Security Checklist](#security-checklist)

---

## SSH Key Authentication

### Why SSH Keys Instead of Passwords?

Password authentication is vulnerable to brute-force attacks. SSH key pairs use asymmetric cryptography, which is significantly more secure.

### How It Works

```
┌──────────────┐                        ┌──────────────┐
│  Your PC     │                        │  Azure VM    │
│              │                        │              │
│  Private Key │ ──── SSH Handshake ──► │  Public Key  │
│  (id_rsa)    │ ◄─── Challenge ─────── │  (authorized │
│              │ ──── Signed Response ─► │   _keys)     │
│              │ ◄─── Access Granted ─── │              │
└──────────────┘                        └──────────────┘
```

1. **Private key** stays on your local machine (never share this!)
2. **Public key** is placed on the server in `~/.ssh/authorized_keys`
3. During login, the server sends a challenge that only your private key can sign
4. Password login is **disabled** in our Bicep template (`disablePasswordAuthentication: true`)

### Key Generation

```bash
# Generate a 4096-bit RSA key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Your keys are stored at:
#   Private: ~/.ssh/id_rsa      (NEVER share this)
#   Public:  ~/.ssh/id_rsa.pub  (safe to share)
```

### Best Practices

- Use a strong passphrase on your private key
- Never share or commit your private key
- Use 4096-bit RSA or Ed25519 keys
- Rotate keys periodically
- Use `ssh-agent` to avoid typing the passphrase repeatedly

---

## Network Security (NSG)

### What is a Network Security Group?

An NSG is an Azure firewall that filters network traffic to and from Azure resources. It contains security rules that allow or deny inbound/outbound traffic.

### Our NSG Rules

| Priority | Name           | Port  | Protocol | Source    | Action | Purpose                    |
|----------|----------------|-------|----------|-----------|--------|----------------------------|
| 1000     | Allow-SSH      | 22    | TCP      | Any       | Allow  | Remote management via SSH  |
| 1100     | Allow-HTTP     | 80    | TCP      | Any       | Allow  | Web traffic (future use)   |
| 1200     | Allow-App-Port | 5000  | TCP      | Any       | Allow  | Direct application access  |
| 65000    | DenyAllInbound | All   | All      | Any       | Deny   | Block everything else      |

### How NSG Rules Work

```
Internet Traffic
      │
      ▼
┌─────────────────────────────┐
│  Network Security Group     │
│                             │
│  Rule 1000: Port 22  ✓     │──► SSH Access
│  Rule 1100: Port 80  ✓     │──► HTTP Access
│  Rule 1200: Port 5000 ✓    │──► App Access
│  Rule 65000: Deny All ✗    │──► Blocked
│                             │
└─────────────────────────────┘
```

Rules are evaluated in priority order (lowest number = highest priority). Once a matching rule is found, no further rules are evaluated.

### Production Recommendations

For a production environment, consider these additional security measures:

1. **Restrict SSH source IP**: Instead of allowing SSH from `*` (anywhere), limit it to your IP address
   ```
   sourceAddressPrefix: '<YOUR_IP>/32'
   ```

2. **Use a bastion host**: Azure Bastion provides secure SSH access without exposing port 22 to the internet

3. **Remove port 5000**: In production, use a reverse proxy (Nginx) on port 80 and close port 5000

---

## Application Security

### Kestrel Web Server

The .NET application uses Kestrel as its web server. Security considerations:

1. **Non-root execution**: The application runs as `azureuser`, not root
2. **Bound to 0.0.0.0:5000**: Listens on all interfaces on port 5000
3. **No HTTPS in this setup**: For production, add TLS termination

### Systemd Security Hardening

Our `webapp.service` file includes several security directives:

```ini
# Prevents the service from gaining new privileges
NoNewPrivileges=true

# Provides a private /tmp directory
PrivateTmp=true

# Makes the filesystem read-only except for specific paths
ProtectSystem=strict

# Restricts access to home directories
ProtectHome=read-only

# Only /opt/webapp is writable
ReadWritePaths=/opt/webapp
```

### What Each Directive Does

| Directive | Purpose |
|-----------|---------|
| `NoNewPrivileges` | The process cannot escalate privileges via setuid/setgid |
| `PrivateTmp` | The service gets its own /tmp, isolated from other services |
| `ProtectSystem=strict` | The entire filesystem is read-only except explicitly allowed paths |
| `ProtectHome=read-only` | Home directories are mounted read-only |
| `ReadWritePaths` | Explicitly grants write access only where needed |

### Production Recommendations

1. **Enable HTTPS**: Use Let's Encrypt with Certbot for free TLS certificates
2. **Add a reverse proxy**: Use Nginx in front of Kestrel for better security
3. **Enable rate limiting**: Protect against DDoS attacks
4. **Set security headers**: Add X-Frame-Options, Content-Security-Policy, etc.
5. **Keep dependencies updated**: Regularly run `dotnet list package --vulnerable`

---

## Operating System Security

### Ubuntu Server Hardening

The setup script includes basic security measures:

1. **System updates**: `apt-get update && apt-get upgrade`
2. **Firewall (UFW)**: Only required ports are open
3. **No unnecessary services**: Minimal Ubuntu Server installation

### Additional Recommendations

For a production environment:

1. **Enable automatic security updates**:
   ```bash
   sudo apt-get install unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

2. **Configure fail2ban** to protect against brute-force attacks:
   ```bash
   sudo apt-get install fail2ban
   sudo systemctl enable fail2ban
   ```

3. **Disable root login**:
   ```bash
   # In /etc/ssh/sshd_config
   PermitRootLogin no
   ```

4. **Monitor logs regularly**:
   ```bash
   # Check authentication logs
   sudo tail -f /var/log/auth.log

   # Check application logs
   journalctl -u webapp -f
   ```

---

## Security Checklist

Use this checklist before considering the deployment "complete":

- [ ] SSH key authentication is working
- [ ] Password authentication is disabled
- [ ] NSG rules are correctly configured
- [ ] Only necessary ports are open (22, 80, 5000)
- [ ] Application runs as non-root user
- [ ] System packages are up to date
- [ ] UFW firewall is active
- [ ] Systemd security directives are in place
- [ ] No sensitive data in source code or git history
- [ ] Application logs are being captured by journald

### For Production (Beyond This Project)

- [ ] HTTPS/TLS is enabled
- [ ] SSH source IP is restricted
- [ ] fail2ban is installed and configured
- [ ] Automatic security updates are enabled
- [ ] Reverse proxy (Nginx) is configured
- [ ] Security headers are set
- [ ] Regular backup strategy is in place
- [ ] Monitoring and alerting is configured
