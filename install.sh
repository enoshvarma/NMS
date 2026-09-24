#!/usr/bin/env bash
#
# Ahuva NMS installer
# Ahuva NMS developed by Ahuva Enosh Varma - Elevating Tech, Empowering Lives
# Support: Enosh Varma <varmaenosh@gmail.com>
#
# Install with one command on a fresh Ubuntu 24.04 server:
#   curl -fsSL https://raw.githubusercontent.com/enoshvarma/NMS/main/install.sh | sudo bash
#
# Options (add after "sudo bash -s --" when using curl):
#   --yes, -y        Do not ask questions, use defaults / environment values
#   --no-web         Skip Nginx and PHP-FPM setup (use your own web server)
#   --help, -h       Show this help
#
# Environment values used with --yes (all optional):
#   AHUVA_HOST, AHUVA_ADMIN_USER, AHUVA_ADMIN_PASS, AHUVA_ADMIN_EMAIL, AHUVA_TIMEZONE
#
# The script is safe to run again: finished steps are detected and skipped.

set -Eeuo pipefail

INSTALL_DIR=/opt/librenms
NMS_USER=librenms
PHP_MIN=8.4
PHP_PKG_VER=8.4
LOG=/var/log/ahuva-nms-install.log
CRED_FILE=/root/ahuva-nms-credentials.txt
TOTAL_STEPS=11
ASSUME_YES=0
SETUP_WEB=1
REPO_URL=${AHUVA_REPO:-https://github.com/enoshvarma/NMS.git}

# ---------------------------------------------------------------- output helpers
if [ -t 1 ]; then
    C_CYAN=$'\e[36m'; C_GREEN=$'\e[32m'; C_RED=$'\e[31m'; C_YELLOW=$'\e[33m'; C_BOLD=$'\e[1m'; C_OFF=$'\e[0m'
else
    C_CYAN=''; C_GREEN=''; C_RED=''; C_YELLOW=''; C_BOLD=''; C_OFF=''
fi

STEP_NO=0
step() { STEP_NO=$((STEP_NO + 1)); printf '\n%s[%d/%d] %s%s\n' "$C_CYAN$C_BOLD" "$STEP_NO" "$TOTAL_STEPS" "$1" "$C_OFF"; echo "=== [$STEP_NO/$TOTAL_STEPS] $1" >>"$LOG"; }
ok()   { printf '  %s✔%s %s\n' "$C_GREEN" "$C_OFF" "$1"; }
info() { printf '  • %s\n' "$1"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_OFF" "$1"; echo "WARN: $1" >>"$LOG"; }
die()  { printf '\n%s✘ %s%s\n' "$C_RED" "$1" "$C_OFF"; printf '  Full log: %s\n  Support: Enosh Varma <varmaenosh@gmail.com>\n' "$LOG"; exit 1; }

on_error() {
    local code=$? line=$1
    printf '\n%s✘ Installation stopped (error %s at line %s).%s\n' "$C_RED" "$code" "$line" "$C_OFF"
    printf '  Last lines of the log (%s):\n' "$LOG"
    tail -n 15 "$LOG" 2>/dev/null | sed 's/^/    /'
    printf '\n  Fix the problem and run the installer again - finished steps are skipped.\n'
    printf '  Support: Enosh Varma <varmaenosh@gmail.com>\n'
    exit "$code"
}
trap 'on_error $LINENO' ERR

run() { echo "+ $*" >>"$LOG"; "$@" >>"$LOG" 2>&1; }
as_nms() { echo "+ (as $NMS_USER) $*" >>"$LOG"; su - "$NMS_USER" -s /bin/bash -c "cd $INSTALL_DIR && $*" >>"$LOG" 2>&1; }
has_systemd() { [ -d /run/systemd/system ]; }
svc_enable_start() {
    if has_systemd; then run systemctl enable "$1"; run systemctl restart "$1"; else run service "$1" restart; fi
}
rand_pass() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${1:-20}" || true; }

ask() { # ask VAR "Question" "default"
    local __var=$1 __q=$2 __def=${3:-} __ans=''
    if [ "$ASSUME_YES" = 1 ] || [ ! -t 0 ]; then
        printf -v "$__var" '%s' "$__def"; return
    fi
    if [ -n "$__def" ]; then read -r -p "  $__q [$__def]: " __ans; else read -r -p "  $__q: " __ans; fi
    printf -v "$__var" '%s' "${__ans:-$__def}"
}

set_env() { # set_env KEY VALUE  (in $INSTALL_DIR/.env)
    local f="$INSTALL_DIR/.env" key=$1 val=$2
    touch "$f"
    if grep -qE "^#?\s*${key}=" "$f"; then
        local esc; esc=$(printf '%s' "$val" | sed -e 's/[\/&|]/\\&/g')
        sed -i -E "s|^#?\s*${key}=.*|${key}=${esc}|" "$f"
    else
        printf '%s=%s\n' "$key" "$val" >>"$f"
    fi
}
get_env() { grep -E "^$1=" "$INSTALL_DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2- || true; }

usage() {
    cat <<'EOF'
Ahuva NMS installer

Install:   curl -fsSL https://raw.githubusercontent.com/enoshvarma/NMS/main/install.sh | sudo bash
Re-run:    sudo bash /opt/librenms/install.sh

Options:
  --yes, -y   Do not ask questions, use defaults / environment values
  --no-web    Skip Nginx and PHP-FPM setup (use your own web server)
  --help, -h  Show this help

Environment values used with --yes (all optional):
  AHUVA_HOST, AHUVA_ADMIN_USER, AHUVA_ADMIN_PASS, AHUVA_ADMIN_EMAIL, AHUVA_TIMEZONE
EOF
}

# ---------------------------------------------------------------- arguments
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --no-web) SETUP_WEB=0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg (use --help)"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------- download
# When started with "curl ... | sudo bash" (or from outside $INSTALL_DIR), download
# the code first, then continue with the copy of this script inside $INSTALL_DIR.
SELF_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
fi
INSTALL_REAL=$(cd "$INSTALL_DIR" 2>/dev/null && pwd -P || true)
if [ -z "$SELF_DIR" ] || [ -z "$INSTALL_REAL" ] || [ "$SELF_DIR" != "$INSTALL_REAL" ]; then
    [ "$(id -u)" -eq 0 ] || { echo "Please run as root:  curl -fsSL https://raw.githubusercontent.com/enoshvarma/NMS/main/install.sh | sudo bash"; exit 1; }
    if [ -f "$INSTALL_DIR/artisan" ]; then
        echo "Ahuva NMS is already downloaded in $INSTALL_DIR - updating it and continuing."
        git -C "$INSTALL_DIR" -c safe.directory="$INSTALL_DIR" pull --quiet --ff-only >/dev/null 2>&1 \
            || echo "Note: could not update $INSTALL_DIR. If the installer fails, remove it (rm -rf $INSTALL_DIR) and run the install command again."
    else
        if [ -e "$INSTALL_DIR" ] && [ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
            echo "$INSTALL_DIR already exists and is not an Ahuva NMS folder. Move it away and run the installer again."
            exit 1
        fi
        echo "Downloading Ahuva NMS to $INSTALL_DIR (this can take a few minutes)..."
        export DEBIAN_FRONTEND=noninteractive
        if ! command -v git >/dev/null 2>&1; then
            apt-get update -qq >/dev/null 2>&1 || true
            apt-get install -y -qq git ca-certificates >/dev/null \
                || { echo "Could not install git. Check the internet connection and run the command again."; exit 1; }
        fi
        git clone --quiet --depth 1 "$REPO_URL" "$INSTALL_DIR" \
            || { echo "Download failed. Check the internet connection and run the command again."; exit 1; }
        echo "Download complete."
    fi
    # read answers from the keyboard even though the script itself came through a pipe
    if ( : </dev/tty ) 2>/dev/null; then
        exec bash "$INSTALL_DIR/install.sh" "$@" </dev/tty
    fi
    exec bash "$INSTALL_DIR/install.sh" "$@"
fi

# ---------------------------------------------------------------- banner
cat <<EOF

${C_CYAN}${C_BOLD}    _    _   _ _   ___     ___       _   _ __  __ ____
   / \\  | | | | | | \\ \\   / / \\     | \\ | |  \\/  / ___|
  / _ \\ | |_| | | | |\\ \\ / / _ \\    |  \\| | |\\/| \\___ \\
 / ___ \\|  _  | |_| | \\ V / ___ \\   | |\\  | |  | |___) |
/_/   \\_\\_| |_|\\___/   \\_/_/   \\_\\  |_| \\_|_|  |_|____/${C_OFF}

  Ahuva NMS installer - developed by Ahuva Enosh Varma
  Elevating Tech, Empowering Lives

EOF

# ---------------------------------------------------------------- 1. checks
step "Checking this server"
[ "$(id -u)" -eq 0 ] || die "Please run as root:  sudo bash $INSTALL_DIR/install.sh"
: >>"$LOG" || die "Cannot write the log file $LOG"
echo "---- Ahuva NMS install started $(date)" >>"$LOG"

[ -f "$INSTALL_DIR/artisan" ] || die "Ahuva NMS code not found in $INSTALL_DIR."

# shellcheck disable=SC1091
. /etc/os-release
os_ok=0
case "${ID:-}" in
    ubuntu) dpkg --compare-versions "${VERSION_ID:-0}" ge 22.04 && os_ok=1 ;;
    debian) dpkg --compare-versions "${VERSION_ID:-0}" ge 12 && os_ok=1 ;;
esac
[ "$os_ok" = 1 ] || die "Unsupported operating system: ${PRETTY_NAME:-unknown}. Use Ubuntu 22.04 or newer (24.04 recommended) or Debian 12 or newer."
ok "Operating system: $PRETTY_NAME"

mem_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 1800 ] && ok "Memory: ${mem_mb} MB" || warn "Only ${mem_mb} MB RAM. 2 GB or more is recommended."
disk_gb=$(df -Pk "$INSTALL_DIR" | awk 'NR==2 {print int($4/1048576)}')
[ "$disk_gb" -ge 5 ] && ok "Free disk: ${disk_gb} GB" || warn "Only ${disk_gb} GB free disk. 20 GB or more is recommended."

# remove any access token from the git remote so it is not stored on the server
if remote=$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null); then
    clean=$(printf '%s' "$remote" | sed -E 's#https://[^@/]+@#https://#')
    if [ "$clean" != "$remote" ]; then
        git -C "$INSTALL_DIR" remote set-url origin "$clean"
        ok "Removed the access token from the saved repository address"
    fi
fi

# ---------------------------------------------------------------- 2. questions
step "A few questions (press Enter to accept the value in [brackets])"
default_host=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
default_host=${default_host:-$(hostname -f 2>/dev/null || hostname)}
default_tz=$(timedatectl show -p Timezone --value 2>/dev/null || true)
[ -n "$default_tz" ] || default_tz=$(cat /etc/timezone 2>/dev/null || true)
[ -n "$default_tz" ] || default_tz=$(readlink -f /etc/localtime 2>/dev/null | sed -n 's#.*/zoneinfo/##p' || true)
[ -z "$default_tz" ] || [ "$default_tz" = "Etc/UTC" ] && default_tz=Asia/Kolkata

ask HOST        "Server IP address or name users will open in the browser" "${AHUVA_HOST:-$default_host}"
ask ADMIN_USER  "Admin username"                                            "${AHUVA_ADMIN_USER:-admin}"
if [ -n "${AHUVA_ADMIN_PASS:-}" ]; then
    ADMIN_PASS=$AHUVA_ADMIN_PASS
elif [ "$ASSUME_YES" = 1 ] || [ ! -t 0 ]; then
    ADMIN_PASS=$(rand_pass 14)
else
    while :; do
        read -r -s -p "  Admin password (leave empty to generate one): " ADMIN_PASS; echo
        [ -z "$ADMIN_PASS" ] && { ADMIN_PASS=$(rand_pass 14); break; }
        [ "${#ADMIN_PASS}" -ge 8 ] || { echo "  Password must be at least 8 characters."; continue; }
        read -r -s -p "  Type the password again: " p2; echo
        [ "$ADMIN_PASS" = "$p2" ] && break || echo "  Passwords do not match, try again."
    done
fi
ask ADMIN_EMAIL "Admin email (optional)"                                    "${AHUVA_ADMIN_EMAIL:-}"
# find the correctly spelled timezone name, ignoring upper/lower case (asia/kolkata -> Asia/Kolkata)
fix_tz() {
    [ -d /usr/share/zoneinfo ] || { printf '%s' "$1"; return; }
    [ -f "/usr/share/zoneinfo/$1" ] && { printf '%s' "$1"; return; }
    (cd /usr/share/zoneinfo && find . -type f ! -path './posix/*' ! -path './right/*' | sed 's#^\./##' | grep -ixF -- "$1" | head -n1) || true
}
tz_default="${AHUVA_TIMEZONE:-$default_tz}"
while :; do
    ask TIMEZONE "Timezone" "$tz_default"
    TIMEZONE=$(fix_tz "$(printf '%s' "$TIMEZONE" | tr -d '[:space:]')")
    [ -n "$TIMEZONE" ] && break
    if [ "$ASSUME_YES" = 1 ] || [ ! -t 0 ]; then die "Unknown timezone '$tz_default'. Example: Asia/Kolkata"; fi
    echo "  Unknown timezone. Examples: Asia/Kolkata, Asia/Dubai, Europe/London, America/New_York"
done
ok "Settings saved - the rest is automatic (about 5-15 minutes)"

# ---------------------------------------------------------------- 3. packages
step "Installing system packages"
export DEBIAN_FRONTEND=noninteractive
apt_update() {
    run apt-get update && return 0
    warn "Some package sources on this server could not be refreshed (see the log). Continuing with the ones that work."
}
apt_update

php_ok() { command -v php >/dev/null && php -r "exit(version_compare(PHP_VERSION, '$PHP_MIN', '>=') ? 0 : 1);"; }
pkg_available() { apt-cache show "$1" >/dev/null 2>&1; }
# PHP version to install: the distribution default if new enough, otherwise the newest available >= $PHP_MIN
pick_php_version() {
    local def v best=""
    def=$(apt-cache depends php-cli 2>/dev/null | sed -n 's/.*Depends: php\([0-9][0-9]*\.[0-9][0-9]*\)-cli.*/\1/p' | head -n1 || true)
    if [ -n "$def" ] && dpkg --compare-versions "$def" ge "$PHP_MIN" && pkg_available "php${def}-cli"; then
        echo "$def"; return
    fi
    for v in $(apt-cache pkgnames php 2>/dev/null | sed -n 's/^php\([0-9][0-9]*\.[0-9][0-9]*\)-cli$/\1/p' | sort -V); do
        dpkg --compare-versions "$v" ge "$PHP_MIN" && best=$v
    done
    echo "$best"
}

if php_ok; then
    PHP_PKG_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    ok "PHP $(php -r 'echo PHP_VERSION;') already installed"
else
    PHP_PKG_VER=$(pick_php_version)
    if [ -z "$PHP_PKG_VER" ]; then
        info "Adding the PHP package repository (this Linux version ships an older PHP)"
        run apt-get install -y ca-certificates curl gnupg lsb-release software-properties-common
        if [ "$ID" = ubuntu ]; then
            run add-apt-repository -y -n ppa:ondrej/php
        else
            run curl -fsSL -o /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
            echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/php-sury.list
        fi
        apt_update
        PHP_PKG_VER=$(pick_php_version)
    fi
    [ -n "$PHP_PKG_VER" ] || die "PHP $PHP_MIN or newer is not available for $PRETTY_NAME."
    info "Using PHP $PHP_PKG_VER"
fi

PHP_PKGS=""
for ext in cli curl gd mbstring mysql xml zip; do PHP_PKGS="$PHP_PKGS php${PHP_PKG_VER}-${ext}"; done
[ "$SETUP_WEB" = 1 ] && PHP_PKGS="$PHP_PKGS php${PHP_PKG_VER}-fpm"
for ext in gmp snmp; do pkg_available "php${PHP_PKG_VER}-${ext}" && PHP_PKGS="$PHP_PKGS php${PHP_PKG_VER}-${ext}"; done
# skip PHP packages that are compiled in when PHP was not installed from packages
if php_ok && ! dpkg -s "php${PHP_PKG_VER}-cli" >/dev/null 2>&1; then
    need=""; for p in $PHP_PKGS; do pkg_available "$p" && need="$need $p"; done; PHP_PKGS=$need
fi

# required packages must exist; optional ones are skipped when this Linux version does not have them
BASE_PKGS=""
missing_pkgs=""
for p in acl cron curl fping git logrotate mariadb-client mariadb-server python3-dotenv python3-pymysql \
         python3-redis python3-psutil python3-pip rrdtool snmp snmpd tzdata unzip; do
    if pkg_available "$p"; then BASE_PKGS="$BASE_PKGS $p"; else missing_pkgs="$missing_pkgs $p"; fi
done
[ "$SETUP_WEB" = 1 ] && { if pkg_available nginx; then BASE_PKGS="$BASE_PKGS nginx"; else missing_pkgs="$missing_pkgs nginx"; fi; }
[ -z "$missing_pkgs" ] || die "These required packages are not available on this server:$missing_pkgs"
for p in graphviz imagemagick mtr-tiny nmap whois python3-setuptools python3-command-runner python3-systemd; do
    pkg_available "$p" && BASE_PKGS="$BASE_PKGS $p"
done

# shellcheck disable=SC2086
run apt-get install -y $BASE_PKGS || die "Installing system packages failed. Check the internet connection and run the installer again."
ok "System packages installed"

# shellcheck disable=SC2086
if ! run apt-get install -y $PHP_PKGS; then
    php_ok || die "Installing PHP $PHP_PKG_VER failed. Check the internet connection and run the installer again."
    missing=""
    for mod in curl gd mbstring mysqli pdo_mysql xml zip; do php -m | grep -ix "$mod" >/dev/null || missing="$missing $mod"; done
    [ -z "$missing" ] || die "Installing PHP packages failed and these PHP modules are missing:$missing"
    [ "$SETUP_WEB" = 0 ] || [ -d "/etc/php/$PHP_PKG_VER/fpm" ] || die "Installing php${PHP_PKG_VER}-fpm failed."
    warn "Some optional PHP packages could not be installed; the required PHP modules are present, continuing."
fi
# make "php" point at the version we installed when several PHP versions are present
[ -x "/usr/bin/php${PHP_PKG_VER}" ] && run update-alternatives --set php "/usr/bin/php${PHP_PKG_VER}" || true
php_ok || die "PHP $PHP_MIN or newer is required but $(php -r 'echo PHP_VERSION;' 2>/dev/null || echo 'none') is installed."
ok "PHP $(php -r 'echo PHP_VERSION;') ready"

# ---------------------------------------------------------------- 4. user and permissions
step "Creating the ${NMS_USER} user and setting permissions"
if id "$NMS_USER" >/dev/null 2>&1; then ok "User $NMS_USER already exists"; else
    run useradd "$NMS_USER" -d "$INSTALL_DIR" -M -r -s "$(command -v bash)"; ok "User $NMS_USER created"
fi
chown -R "$NMS_USER:$NMS_USER" "$INSTALL_DIR"
chmod 771 "$INSTALL_DIR"
for d in rrd logs bootstrap/cache storage; do
    mkdir -p "$INSTALL_DIR/$d"
    setfacl -d -m g::rwx "$INSTALL_DIR/$d" 2>>"$LOG" || true
    setfacl -R -m g::rwx "$INSTALL_DIR/$d" 2>>"$LOG" || true
done
run git config --system --add safe.directory "$INSTALL_DIR" || true
ok "Permissions set"

# ---------------------------------------------------------------- 5. timezone
step "Setting timezone to $TIMEZONE"
TIMEZONE=$(fix_tz "$TIMEZONE")
[ -n "$TIMEZONE" ] && [ -f "/usr/share/zoneinfo/$TIMEZONE" ] || die "Unknown timezone. Example: Asia/Kolkata"
if has_systemd && command -v timedatectl >/dev/null; then run timedatectl set-timezone "$TIMEZONE" || true; fi
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
echo "$TIMEZONE" >/etc/timezone
for ini in /etc/php/"$PHP_PKG_VER"/*/php.ini; do
    [ -f "$ini" ] || continue
    sed -i -E "s#^;?\s*date\.timezone\s*=.*#date.timezone = $TIMEZONE#" "$ini"
done
ok "Timezone set"

# ---------------------------------------------------------------- 6. database
step "Setting up the database"
cat >/etc/mysql/mariadb.conf.d/60-ahuva-nms.cnf <<'EOF'
# Ahuva NMS database settings
[mysqld]
innodb_file_per_table=1
lower_case_table_names=0
EOF
svc_enable_start mariadb
for _ in $(seq 1 30); do mysqladmin ping >/dev/null 2>&1 && break; sleep 1; done
mysqladmin ping >/dev/null 2>&1 || die "The database server (MariaDB) did not start."

DB_PASS=$(get_env DB_PASSWORD)
[ -n "$DB_PASS" ] || DB_PASS=$(rand_pass 24)
mysql -u root <<SQL >>"$LOG" 2>&1
CREATE DATABASE IF NOT EXISTS librenms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'librenms'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER 'librenms'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
FLUSH PRIVILEGES;
SQL
ok "Database 'librenms' ready"

# ---------------------------------------------------------------- 7. application
step "Installing Ahuva NMS application files (this is the longest step)"
composer_install() {
    if command -v composer >/dev/null 2>&1; then
        as_nms "composer install --no-dev --no-interaction --no-progress" && return 0
    else
        as_nms "./scripts/composer_wrapper.php install --no-dev --no-interaction --no-progress" && return 0
        # the composer download site can be blocked on some networks - fall back to the distribution package
        info "Installing composer from the system packages"
        run apt-get install -y composer || return 1
        [ -x "/usr/bin/php${PHP_PKG_VER}" ] && run update-alternatives --set php "/usr/bin/php${PHP_PKG_VER}" || true
        as_nms "composer install --no-dev --no-interaction --no-progress" && return 0
    fi
    return 1
}
composer_install || die "Downloading the PHP components failed. Check the internet connection and run the installer again."
ok "PHP components installed"

as_nms "python3 -m pip install --user -r requirements.txt --break-system-packages" \
    || as_nms "python3 -m pip install --user -r requirements.txt" \
    || warn "Some Python components could not be installed with pip (the system packages are usually enough)."

[ -f "$INSTALL_DIR/.env" ] || die "The configuration file $INSTALL_DIR/.env was not created."
set_env DB_HOST localhost
set_env DB_DATABASE librenms
set_env DB_USERNAME librenms
set_env DB_PASSWORD "$DB_PASS"
set_env APP_URL "http://$HOST/"
sed -i '/^INSTALL=/d' "$INSTALL_DIR/.env"
chown "$NMS_USER:$NMS_USER" "$INSTALL_DIR/.env"; chmod 640 "$INSTALL_DIR/.env"

as_nms "php lnms migrate --force --seed" || die "Building the database tables failed."
ok "Database tables built"

ADMIN_PASS=${ADMIN_PASS//\'/}
EMAIL_ARG=""
[ -n "$ADMIN_EMAIL" ] && EMAIL_ARG="--email='${ADMIN_EMAIL//\'/}'"
if as_nms "php lnms user:add --password='$ADMIN_PASS' --role=admin $EMAIL_ARG '${ADMIN_USER//\'/}'"; then
    ok "Admin user '$ADMIN_USER' created"
else
    warn "Admin user '$ADMIN_USER' already exists - its password was not changed."
    old_pass=$(sed -n 's/^Admin password: //p' "$CRED_FILE" 2>/dev/null | head -n1 || true)
    ADMIN_PASS=${old_pass:-"(unchanged - existing user)"}
fi
as_nms "php lnms config:set base_url 'http://$HOST/'" || true
as_nms "php artisan optimize:clear" || true

# ---------------------------------------------------------------- 8. web server
step "Setting up the web server"
if [ "$SETUP_WEB" = 1 ]; then
    FPM_DIR=/etc/php/$PHP_PKG_VER/fpm/pool.d
    [ -d "$FPM_DIR" ] || die "PHP-FPM $PHP_PKG_VER is not installed."
    cat >"$FPM_DIR/librenms.conf" <<EOF
; Ahuva NMS PHP-FPM pool
[librenms]
user = $NMS_USER
group = $NMS_USER
listen = /run/php-fpm-librenms.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 8
EOF
    svc_enable_start "php${PHP_PKG_VER}-fpm"

    cat >/etc/nginx/conf.d/librenms.conf <<EOF
# Ahuva NMS web server
server {
    listen      80;
    server_name $HOST _;
    root        $INSTALL_DIR/html;
    index       index.php;

    charset utf-8;
    client_max_body_size 32m;
    gzip on;
    gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ [^/]\.php(/|$) {
        fastcgi_pass unix:/run/php-fpm-librenms.sock;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi.conf;
    }
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
    rm -f /etc/nginx/sites-enabled/default
    run nginx -t || die "The web server configuration test failed."
    svc_enable_start nginx
    if command -v ufw >/dev/null && ufw status 2>/dev/null | grep "Status: active" >/dev/null; then
        run ufw allow 80/tcp; ok "Firewall: opened port 80"
    fi
    ok "Nginx and PHP-FPM configured"
else
    info "Skipped (--no-web). Point your web server at $INSTALL_DIR/html"
fi

# ---------------------------------------------------------------- 9. monitoring services
step "Setting up SNMP, scheduled jobs and log rotation"
SNMP_COMMUNITY=$(grep -E '^com2sec readonly' /etc/snmp/snmpd.conf 2>/dev/null | awk '{print $4}' | grep -v RANDOMSTRINGGOESHERE || true)
if [ -z "$SNMP_COMMUNITY" ]; then
    SNMP_COMMUNITY="ahuva$(rand_pass 10)"
    [ -f /etc/snmp/snmpd.conf ] && cp /etc/snmp/snmpd.conf "/etc/snmp/snmpd.conf.before-ahuva"
    sed -e "s/RANDOMSTRINGGOESHERE/$SNMP_COMMUNITY/" \
        -e "s/^syslocation .*/syslocation Ahuva NMS server/" \
        -e "s/^syscontact .*/syscontact ${ADMIN_EMAIL:-admin}/" \
        -e "/^extend distro/d" \
        "$INSTALL_DIR/snmpd.conf.example" >/etc/snmp/snmpd.conf
fi
svc_enable_start snmpd

cp "$INSTALL_DIR/dist/librenms.cron" /etc/cron.d/librenms
if has_systemd; then
    cp "$INSTALL_DIR/dist/librenms-scheduler.service" "$INSTALL_DIR/dist/librenms-scheduler.timer" /etc/systemd/system/
    run systemctl daemon-reload
    run systemctl enable --now librenms-scheduler.timer
else
    echo "*    *    * * *   $NMS_USER    cd $INSTALL_DIR/ && php artisan schedule:run --no-ansi --no-interaction > /dev/null 2>&1" >>/etc/cron.d/librenms
fi
svc_enable_start cron || true
cp "$INSTALL_DIR/misc/librenms.logrotate" /etc/logrotate.d/librenms
ln -sf "$INSTALL_DIR/lnms" /usr/bin/lnms
[ -d /etc/bash_completion.d ] && cp "$INSTALL_DIR/misc/lnms-completion.bash" /etc/bash_completion.d/
for f in $(readlink -f /usr/bin/fping /usr/bin/fping6 2>/dev/null | sort -u); do
    [ -f "$f" ] && { setcap cap_net_raw+ep "$f" 2>>"$LOG" || true; }
done
ok "SNMP, scheduler, cron jobs and log rotation configured"

# ---------------------------------------------------------------- 10. first device
step "Adding this server as the first monitored device"
as_nms "php lnms config:set snmp.community.+ '$SNMP_COMMUNITY'" || true
# Net-SNMP needs up to a minute after (re)starting before it reports CPU load
info "Waiting for SNMP to be ready (up to 2 minutes)"
for _ in $(seq 1 24); do
    snmpwalk -v2c -c "$SNMP_COMMUNITY" -On -t 2 -r 1 127.0.0.1 1.3.6.1.2.1.25.3.3.1.2 2>/dev/null | grep INTEGER >/dev/null && break
    sleep 5
done
if as_nms "php lnms device:add --v2c -c '$SNMP_COMMUNITY' 127.0.0.1"; then
    ok "Device 127.0.0.1 added"
else
    info "Device 127.0.0.1 was already added (or SNMP is not answering yet)"
fi
# run the scheduled jobs once now so everything is live straight away
as_nms "./discovery-wrapper.py 1" || true
as_nms "./poller-wrapper.py 4" || true
as_nms "php artisan schedule:run --no-ansi --no-interaction" || true
as_nms "php artisan schedule:test --name='schedule operational check' --no-ansi --no-interaction" || true
ok "First discovery and poll done"

# ---------------------------------------------------------------- 11. final check
step "Final check"
chown -R "$NMS_USER:$NMS_USER" "$INSTALL_DIR"
umask 077
cat >"$CRED_FILE" <<EOF
Ahuva NMS - installation details ($(date))
Web address   : http://$HOST/
Admin user    : $ADMIN_USER
Admin password: $ADMIN_PASS
Database      : librenms / user librenms / password $DB_PASS
SNMP community: $SNMP_COMMUNITY (for this server)
Support       : Enosh Varma <varmaenosh@gmail.com>
EOF
chmod 600 "$CRED_FILE"

su - "$NMS_USER" -s /bin/bash -c "cd $INSTALL_DIR && ./validate.php" >/tmp/ahuva-validate.txt 2>&1 || true
sed -i 's/\x1b\[[0-9;]*m//g' /tmp/ahuva-validate.txt
cat /tmp/ahuva-validate.txt >>"$LOG"
fails=$(grep -c '^\[FAIL\]' /tmp/ahuva-validate.txt || true)
if [ "$fails" -eq 0 ]; then
    ok "Health check passed"
else
    warn "Health check found $fails item(s) to look at. Most clear by themselves within 5 minutes, once the first scheduled poll has run."
    grep -A2 '^\[FAIL\]' /tmp/ahuva-validate.txt | sed 's/^/      /' | head -n 20
    info "Run the check again later with:  sudo su - $NMS_USER -c ./validate.php"
fi

trap - ERR
cat <<EOF

${C_GREEN}${C_BOLD}==============================================================
  Ahuva NMS is installed!
==============================================================${C_OFF}

  Open in your browser :  ${C_BOLD}http://$HOST/${C_OFF}
  Username             :  ${C_BOLD}$ADMIN_USER${C_OFF}
  Password             :  ${C_BOLD}$ADMIN_PASS${C_OFF}

  These details are saved in $CRED_FILE (readable by root only).
  Installation log     :  $LOG

  Next: log in, then add your switches and routers under
        Devices > Add Device.

  Ahuva NMS developed by Ahuva Enosh Varma
  Support: Enosh Varma <varmaenosh@gmail.com>

EOF
