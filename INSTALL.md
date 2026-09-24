# Ahuva NMS – Installation Guide

Ahuva NMS developed by Ahuva Enosh Varma · *Elevating Tech, Empowering Lives*
Support: Enosh Varma – varmaenosh@gmail.com

The installer does everything for you: packages, database, web server, SNMP, scheduled jobs and the admin account.
It takes about **5–15 minutes**.

---

## What you need

| | |
|---|---|
| **Server** | A fresh **Ubuntu 24.04** server (Ubuntu 22.04 and Debian 12 also work) |
| **Size** | 2 CPU, 2 GB RAM, 20 GB disk or more |
| **Access** | Root or `sudo` access and internet access |
| **GitHub token** | A read-only token for the private `enoshvarma/NMS` repository (see below) |

### Create the GitHub token (one time)

1. Open **https://github.com/settings/personal-access-tokens/new**
2. **Token name:** `Ahuva NMS install` · **Expiration:** as you like
3. **Repository access:** *Only select repositories* → choose **NMS**
4. **Permissions → Repository permissions → Contents:** *Read-only*
5. Click **Generate token** and copy it (it starts with `github_pat_`)

You can use the same token on every customer server. The installer removes it from the server after use.

---

## Install – 3 steps

Log in to the server and run these commands. Replace `YOUR_TOKEN` with the token you copied.

**Step 1 – install git**

```bash
sudo apt update && sudo apt install -y git
```

**Step 2 – download Ahuva NMS**

```bash
sudo git clone https://YOUR_TOKEN@github.com/enoshvarma/NMS.git /opt/librenms
```

**Step 3 – run the installer**

```bash
sudo bash /opt/librenms/install.sh
```

The installer asks 5 questions. Press **Enter** to accept the suggested value shown in `[brackets]`:

| Question | Example |
|---|---|
| Server IP address or name | `192.168.1.50` |
| Admin username | `admin` |
| Admin password | leave empty to generate a strong one |
| Admin email | `noc@customer.com` (optional) |
| Timezone | `Asia/Kolkata` |

When it finishes you will see:

```
==============================================================
  Ahuva NMS is installed!
==============================================================
  Open in your browser :  http://192.168.1.50/
  Username             :  admin
  Password             :  ********
```

Open the address in a browser, log in, and add your switches and routers under **Devices → Add Device**.

The login details are also saved on the server in `/root/ahuva-nms-credentials.txt` (readable by root only).

---

## Install without questions

For scripted installs, give the answers as settings and add `--yes`:

```bash
sudo AHUVA_HOST=192.168.1.50 AHUVA_ADMIN_PASS='Str0ngPass!' AHUVA_TIMEZONE=Asia/Kolkata \
     bash /opt/librenms/install.sh --yes
```

Other options: `--no-web` skips the Nginx web server setup (if you use your own web server), `--help` shows all options.

---

## If something goes wrong

* The installer stops with a red **✘** message and shows the last lines of the log.
* Fix the problem (usually the internet connection) and **run Step 3 again**. Finished steps are skipped, nothing is lost.
* Full log: `/var/log/ahuva-nms-install.log`
* Health check at any time:

  ```bash
  sudo su - librenms -c ./validate.php
  ```

Send the log or the health check output to **varmaenosh@gmail.com** for help.

---

## Updating a server

Automatic updates are off. To update a server to the latest Ahuva NMS version:

```bash
sudo su - librenms
git pull https://YOUR_TOKEN@github.com/enoshvarma/NMS.git main
./scripts/composer_wrapper.php install --no-dev
php lnms migrate --force
exit
```
