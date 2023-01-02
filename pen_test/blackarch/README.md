

# BlackArch Linux

## pull official blackarch docker image
```bash
podman pull docker.io/blackarchlinux/blackarch
```


## run blackarch
```bash
podman run -it -d --name blackarch \
docker.io/blackarchlinux/blackarch

podman exec blackarch pacman -Syu --noconfirm
```

```bash
## (optional), use script to install packages
podman cp ./blacktoolin.py blackarch:/home
podman exec blackarch pacman -S python3 --noconfirm
podman exec -it blackarch /bin/bash
python /home/blacktoolin.py
```

