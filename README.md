## 🚀 WordPress, NginX, MariaDB and Certbot with Flexible SSL Options

Welcome! 👋 This repo contains a convenient, modularized installer to deploy WordPress with automatic TLS certificate issuance via Certbot. Choose between Cloudflare DNS challenge (for wildcard certificates) or standard HTTP challenge (no API token required).

**Why this repo?**

- ✅ Quick WordPress install
- 🔐 Flexible TLS certificate options: Cloudflare DNS or HTTP challenge
- 🎨 Modern, professional interactive UI
- 🧰 Minimal, script-driven setup

---

## ✨ Quick Start

1. Make the installer executable:

```bash
chmod +x install.sh
```

2. Run the installer (you may be prompted for `sudo`):

```bash
sudo ./install.sh
```

3. Follow the interactive prompts in the script.

---

## 🛠️ What this does

- Installs required system packages
- Downloads and configures WordPress
- **NEW:** Choose between Cloudflare DNS validation (for wildcard certs) or standard HTTP validation
- Runs Certbot to get TLS certificates
- Sets up basic permissions and automatic certificate renewals

### Project layout

```
Repository Root/
├── install.sh                  # Entry point (only file you execute)
├── lib/                        # Modular install logic
│   ├── globals.sh               # Constants & shared state
│   ├── logging.sh               # log / warn / die
│   ├── utils.sh                 # helpers (passwords, prompts, checks)
│   ├── prompts.sh               # user input & validation
│   ├── detect.sh                # environment detection
│   ├── dependencies.sh          # apt installs
│   ├── mariadb.sh               # MariaDB logic
│   ├── php.sh                   # PHP / FPM setup
│   ├── cloudflare.sh            # Cloudflare token handling
│   ├── certbot.sh               # TLS issuance & renewal
│   ├── nginx.sh                 # NGINX config
│   ├── wordpress.sh             # WP install & config
│   ├── permissions.sh           # filesystem perms
│   └── services.sh              # reload / enable services
├── templates/
│   └── nginx-site.conf.tpl      # NGINX server block template
└── README.md
```

---

## 📝 Tips & Notes

- **SSL Certificate Options:**
  - **Cloudflare DNS Challenge:** Use a Cloudflare API Token with Zone:DNS Edit permissions. Supports wildcard certificates (*.example.com).
  - **HTTP Challenge:** No API token required. Your domain must be pointed to this server. Only covers the main domain (no wildcard).
- A Global API Key will fail with "Invalid request headers" - always use an API Token.
- This script assumes a fairly standard Linux environment (Debian/Ubuntu style). Adjust as needed for other distros.
- Want to harden your WordPress install further? Check out my [WordPress Hardening Tool](https://github.com/haywardgg/wordpress-hardening) for a quick post-install security pass.

---

If anything goes wrong or you'd like a more guided setup (Docker, Nginx/Apache tuning, or automated backups), open an issue or ask for help — happy to assist! 😄

**Enjoy your new WordPress site!** 🎉

---

_Short on time?_ Run the two commands above and watch the magic happen.

# DISCLAIMER

I created this script to help me install WordPress for my clients.  

The script installs WordPress on Linux using NGINX, MariaDB, PHP, and Certbot. You can choose between:
- **Cloudflare DNS challenge** for domains hosted on Cloudflare (supports wildcard certificates)
- **HTTP challenge** for domains hosted anywhere (standard validation)

Please read the code before using it. Use at your own risk. 

## Usage

Run the all-in-one installer as `root`:

```bash
chmod +x install.sh
sudo ./install.sh
```

You will be prompted for:
- The domain name (without `www`)
- SSL certificate method (Cloudflare DNS or HTTP challenge)
- An email address for Let's Encrypt notices
- Database name and user
- A Cloudflare API token (only if using Cloudflare DNS challenge)

The script will:
- Install and configure NGINX, PHP-FPM, MariaDB, and Certbot (with or without Cloudflare DNS plugin)
- Request certificates using your chosen method (Cloudflare DNS or HTTP challenge)
- Create a database and user with generated passwords
- Download WordPress, configure `wp-config.php`, and set secure salts
- Generate and display MySQL root and WordPress database credentials at the end

### Command-line options

You can pass flags to tailor how much output you see and how prompts are handled:

- `--verbose` – show full command output.
- `--quiet` – hide most command output (default).
- `--hide-secrets` – mask passwords in the final summary.
- `--no-colour` – disable coloured output.
- `--non-interactive` – require environment variables for inputs (see examples below).
- `--dangerous` – purge MariaDB, Nginx, and /var/www/html after confirmation (irreversible).

### EXAMPLE 1: Interactive with verbose output

```bash
sudo ./install.sh --verbose --hide-secrets
```

### EXAMPLE 2: Non-interactive with Cloudflare DNS challenge

```bash
WEBSITE_NAME=example.com \
CERTBOT_EMAIL=admin@example.com \
CERT_METHOD=cloudflare \
DB_NAME=wordpress \
DB_USER=wpuser \
DB_PASSWORD='S3cur3P@ssw0rd!' \
CLOUDFLARE_API_TOKEN='your_cloudflare_api_token_here' \
sudo ./install.sh --non-interactive --quiet --hide-secrets
```

### EXAMPLE 3: Non-interactive with HTTP challenge (no Cloudflare)

```bash
WEBSITE_NAME=example.com \
CERTBOT_EMAIL=admin@example.com \
CERT_METHOD=http \
DB_NAME=wordpress \
DB_USER=wpuser \
DB_PASSWORD='S3cur3P@ssw0rd!' \
sudo ./install.sh --non-interactive --quiet --hide-secrets
```

When using `--non-interactive`:
- Set `CERT_METHOD=cloudflare` or `CERT_METHOD=http` to choose the certificate validation method
- For Cloudflare DNS method, you can omit `CLOUDFLARE_API_TOKEN` if `/root/.secrets/cloudflare.ini` already exists
- For HTTP method, no Cloudflare credentials are needed
- The MariaDB root password is saved to `/root/.secrets/mariadb-root.pass` and will be reused automatically on future runs
