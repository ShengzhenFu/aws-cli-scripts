# install certbot on Ubuntu 22.04
sudo apt install python3 python3-venv libaugeas0
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot

wget https://github.com/joohoi/acme-dns-certbot-joohoi/raw/master/acme-dns-auth.py
chmod +x acme-dns-auth.py
nano acme-dns-auth.py
#!/usr/bin/env python3
cp acme-dns-auth.py /etc/letsencrypt/
# make sure /etc/letsencrypt is empty before you run
certbot certonly --manual --agree-tos --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preerred-challenges dns --debug-challenges -d harbor.yourdomain.com
# please add a cname record to your dns panel
# _acme-challenge.harbor.yourdomain.com CNAME xxxx-xxxx-xxxx-xxxx-xxx.auth.acme-dns.io


# renew 
certbot renew --dry-run
certbot renew
cp /etc/letsencrypt/live/harbor.yourdomain.com/fullchain.pem /data/secret/cert/server.crt
cp /etc/letsencrypt/live/harbor.yourdomain.com/privkey.pem   /data/secret/cert/server.key

