## 🚀 WordPress, NginX, MariaDB and Python3-Certbot-DNS-Cloudflare

Welcome! 👋 This repo contains a convenient, modularized installer to deploy WordPress with Python3 and automatically obtain TLS certificates via Certbot, using Cloudflare DNS for validation.

**Why this repo?**

- ✅ Quick WordPress install
- 🔐 Automatic Certbot TLS issuance (Cloudflare DNS challenge)
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

- Installs required system packages and Python3 environment
- Downloads and configures WordPress
- Runs Certbot with Cloudflare DNS validation to get TLS certs
- Sets up basic permissions and (optionally) cron renewals

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

- Use a Cloudflare **API Token** with Zone:DNS Edit permissions (a Global API Key will fail with "Invalid request headers").
- This script assumes a fairly standard Linux environment (Debian/Ubuntu style). Adjust as needed for other distros.
- Want to harden your WordPress install further? Check out my [WordPress Hardening Tool](https://github.com/haywardgg/wp-hardening-tool) for a quick post-install security pass.

---

If anything goes wrong or you'd like a more guided setup (Docker, Nginx/Apache tuning, or automated backups), open an issue or ask for help — happy to assist! 😄

**Enjoy your new WordPress site!** 🎉

---

_Short on time?_ Run the two commands above and watch the magic happen.

# DISCLAIMER

I created this script to help me install WordPress for my clients.  

The script installs WordPress on Linux, using NGINX, MariaDB, PHP and Certbot (for Cloudflare domains). Please read the code before using it, as you'll need to provide a API Token with Zone Access only, etc.

Use at your own risk. 

## Usage

Run the all-in-one installer as `root`:

```bash
chmod +x install.sh
sudo ./install.sh
```

You will be prompted for:
- The domain name (without `www`)
- An email address for Let's Encrypt notices
- Database name and user
- A Cloudflare API token with DNS edit permissions

The script will:
- Install and configure NGINX, PHP-FPM, MariaDB, and Certbot with the Cloudflare DNS plugin
- Request certificates for the apex domain and wildcard
- Create a database and user with generated passwords
- Download WordPress, configure `wp-config.php`, and set secure salts
- Generate and display MySQL root and WordPress database credentials at the end

### Command-line options

You can pass flags to tailor how much output you see and how prompts are handled:

- `--verbose` – show full command output.
- `--quiet` – hide most command output (default).
- `--hide-secrets` – mask passwords in the final summary.
- `--no-colour` – disable coloured output.
- `--non-interactive` – require environment variables for inputs (website, certificate email, database name and password, Cloudflare key, etc.).

### EXAMPLE 1:

```sudo ./install.sh --verbose --hide-secrets```

### EXAMPLE 2:

```WEBSITE_NAME=example.com \
CERTBOT_EMAIL=admin@example.com \
DB_NAME=wordpress \
DB_USER=wpuser \
DB_PASSWORD='S3cur3P@ssw0rd!' \
CLOUDFLARE_API_TOKEN='cf_api_token_here' \
sudo ./install.sh --non-interactive --quiet --hide-secrets
```

When using `--non-interactive`, you can omit the Cloudflare API key if `/root/.secrets/cloudflare.ini` already exists; the installer will reuse that file. Otherwise, provide the Cloudflare API token via environment variable so certificate issuance can proceed without any manual input.

The installer also saves the MariaDB root password to `/root/.secrets/mariadb-root.pass` and will reuse it automatically on future runs; you will only be prompted for the root password if the stored value is missing or invalid.
