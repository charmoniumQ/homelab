- AP: Enable only 1 5GHz and 1 2.4GHz band with SSID and passphrases.
- Router: Allocate static DNS
- Router: Configure DHCP server to set DNS = 1.1.1.1 1.0.0.1; 2606:4700:4700::1111 2606:4700:4700::1001
- Router: Enable port forward 4259 -> 22, 60000:61000 -> same
- Server + interactive: Installed 21.04
  - Added user 'sam'
- Server + interactive: Install Docker and harden SSH (requires logout)

```
sudo snap install docker
sudo addgroup --system docker
sudo adduser $USER docker
sudo snap disable docker
sudo snap enable docker

sudo apt-get install -y openssh-server magic-wormhole
# add SSH key for $(USER) with wormhole
sudo sed '0,/.*PermitRootLogin.*/s//PermitRootLogin no/' -i /etc/ssh/sshd_config
sudo sed '0,/.*PasswordAuthentication.*/s//PasswordAuthentication no/' -i /etc/ssh/sshd_config
sudo sed '0,/.*X11Forwarding.*/s//X11Forwarding no/' -i /etc/ssh/sshd_config
sudo systemctl sshd restart
```

- Server by SSH: 
```
sudo apt update && sudo apt dist-upgrade -y && sudo apt autoremove -y

sudo apt-get install -y fail2ban unattended-upgrades mosh tmux

sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
# uncomment others

sudo ufw allow in on port 22 proto tcp
sudo ufw allow in on port 60000:61000 proto tcp
sudo ufw enable
```
