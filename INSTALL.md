# Ahuva NMS – Installation Guide (Ubuntu 24.04)

Ahuva NMS developed by Ahuva Enosh Varma. Support: Enosh Varma – varmaenosh@gmail.com

Run every command as `root` (or with `sudo`) unless it says to switch to the `librenms` user.

## 1. Install packages

Ahuva NMS needs **PHP 8.4 or newer**. Ubuntu 24.04 ships PHP 8.3, so add the PHP 8.4 repository first:

```bash
apt update
apt install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
apt update
apt install -y acl curl fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny \
  nginx-full nmap php8.4-cli php8.4-curl php8.4-fpm php8.4-gd php8.4-gmp php8.4-mbstring \
  php8.4-mysql php8.4-snmp php8.4-xml php8.4-zip python3-command-runner python3-dotenv \
  python3-pymysql python3-redis python3-setuptools python3-psutil python3-systemd python3-pip \
  rrdtool snmp snmpd unzip whois
php -v   # must show 8.4.x
```

## 2. Create the system user

```bash
useradd librenms -d /opt/librenms -M -r -s "$(which bash)"
```

## 3. Get the code (private repository)

The repository is private, so the server needs a GitHub access token with read access to `enoshvarma/NMS`
(GitHub → Settings → Developer settings → Fine-grained tokens → repository `NMS`, permission *Contents: Read-only*).

```bash
cd /opt
git clone https://<YOUR_TOKEN>@github.com/enoshvarma/NMS.git librenms
git -C /opt/librenms remote set-url origin https://github.com/enoshvarma/NMS.git   # do not leave the token on the server
chown -R librenms:librenms /opt/librenms
chmod 771 /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
```

## 4. PHP dependencies (as the librenms user)

```bash
su - librenms
./scripts/composer_wrapper.php install --no-dev
exit
```

## 5. Timezone

Set the same timezone (for example `Asia/Kolkata`) in both PHP files and the system:

```bash
sed -i 's#^;date.timezone =.*#date.timezone = Asia/Kolkata#' /etc/php/*/fpm/php.ini /etc/php/*/cli/php.ini
timedatectl set-timezone Asia/Kolkata
```

## 6. Database

Add to `/etc/mysql/mariadb.conf.d/50-server.cnf` under `[mysqld]`:

```
innodb_file_per_table=1
lower_case_table_names=0
```

```bash
systemctl enable --now mariadb
systemctl restart mariadb
mysql -u root <<'SQL'
CREATE DATABASE librenms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'librenms'@'localhost' IDENTIFIED BY 'CHANGE_THIS_PASSWORD';
GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
SQL
```

## 7. PHP-FPM pool

```bash
PHPVER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
cp /etc/php/$PHPVER/fpm/pool.d/www.conf /etc/php/$PHPVER/fpm/pool.d/librenms.conf
sed -i -e 's/^\[www\]/[librenms]/' -e 's/^user = www-data/user = librenms/' -e 's/^group = www-data/group = librenms/' \
  -e 's#^listen = .*#listen = /run/php-fpm-librenms.sock#' /etc/php/$PHPVER/fpm/pool.d/librenms.conf
systemctl restart php$PHPVER-fpm
```

## 8. Nginx

Create `/etc/nginx/conf.d/librenms.conf` (replace `nms.example.com` with the server's name or IP):

```nginx
server {
  listen      80;
  server_name nms.example.com;
  root        /opt/librenms/html;
  index       index.php;

  charset utf-8;
  gzip on;
  gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
  location / {
    try_files $uri $uri/ /index.php?$query_string;
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
```

```bash
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
```

## 9. lnms command, SNMP, scheduler, log rotation

```bash
ln -s /opt/librenms/lnms /usr/bin/lnms
cp /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/

cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf
sed -i 's/RANDOMSTRINGGOESHERE/YOUR_COMMUNITY/' /etc/snmp/snmpd.conf
systemctl enable --now snmpd

cp /opt/librenms/dist/librenms-scheduler.service /opt/librenms/dist/librenms-scheduler.timer /etc/systemd/system/
systemctl enable --now librenms-scheduler.timer
cp /opt/librenms/dist/librenms.cron /etc/cron.d/librenms
cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

setcap cap_net_raw+ep /usr/bin/fping
```

## 10. Web installer

Open `http://<server>/install` in a browser and follow the steps:
pre-install checks → database (user `librenms`, the password from step 6) → build database → create admin user → finish.

## 11. Check the installation

```bash
su - librenms -c './validate.php'
```

Fix anything marked `[FAIL]` using the `[FIX]` hint shown under it.

## Updates

Automatic updates are **off** by default. To update a customer server:

```bash
su - librenms
git pull https://<YOUR_TOKEN>@github.com/enoshvarma/NMS.git main
./scripts/composer_wrapper.php install --no-dev
./lnms migrate --force
exit
```
