wget https://github.com/goharbor/harbor/releases/download/v2.11.0/harbor-offline-installer-v2.11.0.tgz
tar -xzvf harbor-offline-installer-v2.11.0.tgz
cd harbor || exit
# update harbor.yml on below lines
###############################
hostname: habor.yourdomain.com
http:
  port: 80
https:
  port: 443
  certificate: /etc/letsencrypt/live/harbor-yourdomain.com/fullchain.pem
  private_key: /etc/letsencrypt/live/harbor-yourdomain.com/privkey.pem
harbor_admin_password: Harbor12345

# use letsencrypt.sh to generate certificate
# generate docker compose file and configs
./prepare
# start Harbor
docker compose up -d

# create A record in DNS panel to resolve to harbor.yourdomain.com

