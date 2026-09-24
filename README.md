# Ahuva NMS

**Ahuva NMS developed by Ahuva Enosh Varma**
*Elevating Tech, Empowering Lives*

Ahuva NMS is an auto-discovering network monitoring system. It discovers devices over CDP, FDP, LLDP, OSPF, BGP, SNMP and ARP, and supports a wide range of network hardware and operating systems, including Cisco, Juniper, Aruba, Allied Telesis, HP, Linux and Windows.

## Features

- Automatic network discovery and topology maps
- SNMP polling, graphs and historical performance data
- Alerting (email, Slack, Teams, Telegram, webhooks and more)
- Device, port, wireless, sensor and service monitoring
- REST API, distributed polling, role-based access
- Dark theme by default

## Installation

Three commands on a fresh Ubuntu 24.04 server (full guide: [INSTALL.md](INSTALL.md)):

```bash
sudo apt update && sudo apt install -y git
sudo git clone https://YOUR_TOKEN@github.com/enoshvarma/NMS.git /opt/librenms
sudo bash /opt/librenms/install.sh
```

The installer sets up everything and prints the web address and admin login at the end.
Automatic code updates are **off** by default; see INSTALL.md for how to update.

## Support

For issues, support and customisation contact:

**Enosh Varma** – [varmaenosh@gmail.com](mailto:varmaenosh@gmail.com)

## License

Ahuva NMS is distributed under the GNU General Public License v3.0. See [LICENSE.txt](LICENSE.txt).

- Ahuva NMS branding and modifications: Copyright (C) 2026 Ahuva Enosh Varma
- Other portions: Copyright (C) their respective authors, see [AUTHORS.md](AUTHORS.md)
