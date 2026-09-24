# Ahuva NMS – Installation Guide

Ahuva NMS developed by Ahuva Enosh Varma · *Elevating Tech, Empowering Lives*
Support: Enosh Varma – varmaenosh@gmail.com

---

## What you need

| | |
|---|---|
| **Server** | A fresh **Ubuntu 24.04** server (Ubuntu 22.04 and Debian 12 also work) |
| **Size** | 2 CPU, 2 GB RAM, 20 GB disk or more (4 CPU / 8 GB / 100 GB for 200+ devices) |
| **Network** | A fixed IP address and internet access |
| **Access** | A user with `sudo` rights |

No GitHub account or token is needed.

---

## Install – one command

Log in to the server (for example `ssh youruser@192.168.1.50`) and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/enoshvarma/NMS/main/install.sh | sudo bash
```

If `curl` is missing, install it first with `sudo apt install -y curl`.

The installer downloads Ahuva NMS and asks **5 questions**. Press **Enter** to accept the suggested value in `[brackets]`:

| Question | Example |
|---|---|
| Server IP address or name | `192.168.1.50` |
| Admin username | `admin` |
| Admin password | leave empty to generate a strong one |
| Admin email | `noc@customer.com` (optional) |
| Timezone | `Asia/Kolkata` |

Then it works by itself for about **5–15 minutes** and finishes with:

```
==============================================================
  Ahuva NMS is installed!
==============================================================
  Open in your browser :  http://192.168.1.50/
  Username             :  admin
  Password             :  ********
```

Open the address in a browser and log in. The login details are also saved in
`/root/ahuva-nms-credentials.txt` – show them with `sudo cat /root/ahuva-nms-credentials.txt`.

---

## Add your first switch or router

1. On the device, enable SNMP v2c read-only, for example:
   * Cisco: `snmp-server community AhuvaRO RO`
   * Allied Telesis: `snmp-server community AhuvaRO ro`
2. In Ahuva NMS open **Devices → Add Device**, enter the device IP, choose **v2c**, community `AhuvaRO`, and click **Add Device**.

Graphs appear within 5–10 minutes.

---

## Install without questions

```bash
curl -fsSL https://raw.githubusercontent.com/enoshvarma/NMS/main/install.sh \
  | sudo AHUVA_HOST=192.168.1.50 AHUVA_ADMIN_PASS='Str0ngPass!' AHUVA_TIMEZONE=Asia/Kolkata bash -s -- --yes
```

Other options: `--no-web` skips the Nginx web server setup (if you use your own web server).

---

## If something goes wrong

* The installer stops with a red **✘** message and shows the last lines of the log.
* Fix the problem (usually the internet connection) and run it again:

  ```bash
  sudo bash /opt/librenms/install.sh
  ```

  Finished steps are skipped, nothing is lost.
* Full log: `/var/log/ahuva-nms-install.log`
* Health check at any time: `sudo su - librenms -c ./validate.php`
  (two "fping6" lines on a server without IPv6 can be ignored)

Send the log or the health check output to **varmaenosh@gmail.com** for help.

---

## Updating a server

Automatic updates are off. To update to the latest Ahuva NMS version:

```bash
sudo su - librenms -c 'git pull && ./scripts/composer_wrapper.php install --no-dev && php lnms migrate --force'
```
