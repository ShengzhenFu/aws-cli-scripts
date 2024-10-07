# create pod
sudo podman pod create -n webapp -p 8080:80
# generate index.html to serve in the container
mkdir -p ~/pod-volume
cat >> ~/pod-volume <<EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Hello from podman container</title>
  </head>
  <body>
    <h1>A message from a pod in podman container</h1>
  </body>
</html>
EOF

# attach container to the pod
sudo podman run -dt -v ~/pod-volume:/usr/share/nginx/html --pod webapp --security-opt="seccomp=unconfined" --name hello-podman nginx

sudo podman pod ps
sudo podman pod stop webapp
sudo podman pod start webapp

# systemd for pod
podman generate systemd --files --name webapp
sudo cp pod-webapp.service container-hello-podman.service /etc/systemd/system

systemctl status pod-webapp.service
systemctl is-enabled pod-webapp.service
systemctl enable pod-webapp.service
systemctl start pod-webapp.service

# destroy all
systemctl stop pod-webapp.service
systemctl stop container-hello-podman.service
systemctl disable pod-webapp.service
systemctl disable container-hello-podman.service
rm /etc/systemd/pod-webapp.service
rm /etc/systemd/container-hello-podman.service
systemctl daemon-reload
podman stop webapp
podman rm webapp
