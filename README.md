# SCA Tool Container

A rootless podman container to analyze SLES11, SLES12, SLES15 and ALP1 supportconfig tar files placed in the `/var/scatool/incoming` directory. The resulting SCA Report files will be placed in the `/var/scatool/reports` directory in HTML and JSON formats. Log files from the analysis session are placed in `/var/scatool/logs`.

> [!NOTE]
> The container can run as any non-root user. However, a user will be created, **scawork**, dedicated to analyzing supportconfigs.

## Directories
* `/var/scatool/incoming` to `${HOME}/scatool/incoming` - Supportconfig tarball files you want analyzed
* `/var/scatool/reports` to `${HOME}/scatool/reports` - SCA Report files in both HTML and JSON formats
* `/var/scatool/logs` to `${HOME}/scatool/logs` - scatool logs and shared files

## Index to Sections
* [Rootless SystemD Service on ALP1 and SLE Micro 6.0](#installation-and-configuration-for-user-systemd-container-on-alp1-and-sle-micro-60)
* [Rootless SystemD Service on SLES 15 SP5](#installation-and-configuration-for-user-systemd-container-on-sles-15-sp5)
* [Rootless SystemD Service on SLE Micro 5.5](#installation-and-configuration-for-user-systemd-container-on-sle-micro-55)
* [Rootless Container as Needed on Any](#how-to-use-the-sca-tool-container-as-needed)
* [How to Update the SCA Tool Container](#how-to-update-the-sca-tool-container)
* [Troubleshooting Issues](#troubleshooting-issues)

## Projects
* Upstream Source: https://github.com/openSUSE/scatool-container
* Container Registry: https://registry.opensuse.org/cgi-bin/cooverview?srch_term=project%3D%5Ehome%3Ajrecord
* OBS Package: https://build.opensuse.org/package/show/home:jrecord:branches:openSUSE:Templates:Images:Tumbleweed/scatool-container
  - `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`
* SUSE:ALP:Workloads Package: https://build.opensuse.org/package/show/SUSE:ALP:Workloads/scatool-container
  - `podman pull registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/scatool:latest`


> [!NOTE]
> All instructions assume you will be running the SCA Tool Container as a user SystemD process. If you do not intend to run it under SystemD, but only on an as-needed basis, skip to [How to Use the SCA Tool Container as Needed](#how-to-use-the-sca-tool-container-as-needed) below.

# How to Analyze Supportconfigs
1. Run supportconfigs on the servers you wish to analyze
2. Copy the supportconfigs to the SCA Tool Container's `${HOME}/scatool/incoming` directory
```
scp /var/log/scc_*txz scawork@<your_host>:~/scatool/incoming
```
3. Login as **scawork**
4. Supportconfigs are created with 600 permissions by default. Change the permissions so the SCA Tool Container can read the the supportconfigs files.
5. Check on the supportconig analysis status
6. Look in the `${HOME}/scatool/reports` directory for SCA Report files in HTML and JSON formats
```
sudo chmod 644 ${HOME}/scatool/incoming/*
podman logs scamonitor
ls -l ${HOME}/scatool/reports
```
7. Each supportconfig will have a corresponding analysis file in the `${HOME}/scatool/logs` directory

# Installation and Configuration for User SystemD Container on ALP1 and SLE Micro 6.0
1. Install SUSE ALP1 or SLE Micro 6.0
2. Login as **root**:
   1. Add the scawork user
   2. Assign scawork a password
   3. Enable linger for scawork
   4. Configure supportconfig to gather podman information from scawork
```
useradd -m scawork
echo 'scawork:<password>' | chpasswd
loginctl enable-linger scawork
[[ -d /etc/supportutils ]] && echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportutils/supportconfig.conf || echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportconfig.conf
```
3. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Install the [scamonitor.container](https://github.com/openSUSE/scatool-container/blob/main/scamonitor.container) quadlet file to `${HOME}/.config/containers/systemd/scamonitor.container`

> [!NOTE]
> The `scamonitor.service` will pull the `scatool:latest` image if not found. You can manually pull the image with:  
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
cp scamonitor.container ${HOME}/.config/containers/systemd
```
> [!TIP]
> You can run `/usr/lib/systemd/system-generators/podman-system-generator --user --dryrun` to check if a valid systemd unit will be generated

4. Start `scamonitor.service`
   1. You can reboot the server to confirm the `scamonitor.service` starts as expected. The scamonitor.service unit file will automatcially be generated.
      1. `sudo reboot`
      2. Login as **scawork**:
      3. Check the status `systemctl --user status scamonitor.service`
   2. If you don't want to reboot:
      1. Run `systemctl --user daemon-reload` to generate the service unit
      2. Run `systemctl --user start scamonitor.service`
      3. Check the status of the service with `systemctl --user status scamonitor.service`

# Installation and Configuration for User SystemD Container on SLES 15 SP5
> [!NOTE]
> You can install on SLES 15 SP4 as well, but no terminal logging is available. SLES 15 SP5 and higher is recommened.
1. Install SUSE SLES 15 SP5
2. Install podman from the Containers Module
3. Login as **root**:
   1. Add the scawork user
   2. Assign scawork a password
   3. Enable linger for scawork
   4. Configure supportconfig to gather podman information from scawork
   5. Configure unified cgroups on boot
   6. Add scawork to the systemd-journal group so it can see the container logs
   7. Update grub.cfg
```
useradd -m scawork
echo 'scawork:<password>' | chpasswd
loginctl enable-linger scawork
[[ -d /etc/supportutils ]] && echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportutils/supportconfig.conf || echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportconfig.conf
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=1 /g' /etc/default/grub
sed -i -e 's/systemd-journal:x:\(.*\):/systemd-journal:x:\1:scawork/g' /etc/group
config -o /boot/grub2/grub.cfg
```

4. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Create an empty `${HOME}/.config/containers/mounts.conf` file
   4. Install the [scamonitor.container](https://github.com/openSUSE/scatool-container/blob/main/scamonitor.container) quadlet file to `${HOME}/.config/containers/systemd/scamonitor.container`

> [!NOTE]
> The `scamonitor.service` will pull the `scatool:latest` image if not found. You can manually pull the image with:  
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
touch ${HOME}/.config/containers/mounts.conf
cp scamonitor.container ${HOME}/.config/containers/systemd
```
5. Reboot the server. This will enable unified cgroups v2 and confirm the container service will start at boot time.
6. Login as **scawork**:
   1. Check for cgroup version 2
   2. Check the `scamonitor.service` status
```
podman info | grep cgroupVersion
  cgroupVersion: v2

systemctl --user status scamonitor
```

# Installation and Configuration for User SystemD Container on SLE Micro 5.5
1. Install SUSE SLE Micro 5.5 
2. Login as **root**:
   1. Add the scawork user
   2. Assign scawork a password
   3. Enable linger for scawork
   4. Configure supportconfig to gather podman information from scawork
   5. Configure unified cgroups on boot
   6. Add scawork to the systemd-journal group so it can see the container logs
   7. Update grub.cfg
```
useradd -m scawork
echo 'scawork:<password>' | chpasswd
loginctl enable-linger scawork
[[ -d /etc/supportutils ]] && echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportutils/supportconfig.conf || echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportconfig.conf
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=1 /g' /etc/default/grub
sed -i -e 's/systemd-journal:x:\(.*\):/systemd-journal:x:\1:scawork/g' /etc/group
transactional-update grub.cfg
```

3. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Create an empty `${HOME}/.config/containers/mounts.conf` file
   4. Install the [scamonitor.container](https://github.com/openSUSE/scatool-container/blob/main/scamonitor.container) quadlet file to `${HOME}/.config/containers/systemd/scamonitor.container`

> [!NOTE]
> The `scamonitor.service` will pull the `scatool:latest` image if not found. You can manually pull the image with:  
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
touch ${HOME}/.config/containers/mounts.conf
cp scamonitor.container ${HOME}/.config/containers/systemd
```
4. Reboot the server. This will enable unified cgroups v2 and confirm the container service will start at boot time.
5. Login as **scawork**:
   1. Check for cgroup version 2
   2. Check the `scamonitor.service` status
```
podman info | grep cgroupVersion
  cgroupVersion: v2

systemctl --user status scamonitor
```

# How to Use the SCA Tool Container as Needed
1. Login as **scawork**
2. Pull the SCA Tool Container now and each time you want to update the container
3. Run the container to initialize the volume
4. Create a symlink to the container's working directory
```
podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest
podman run -d --rm -v scavol:/var/scatool:z scatool:latest
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
```

5. Copy the supportconfigs to the SCA Tool Container's incoming directory
```
scp root@<supportconfig_server>:/var/log/scc_*txz ${HOME}/scatool/incoming
chmod 644 ${HOME}/scatool/incoming/*
```
6. Run the SCA Tool Container to analyze all supportconfigs in the incoming directory
```
podman run -dt --rm -v scavol:/var/scatool:z --name sca scatool:latest
```
7. Check on the supportconig analysis status
8. Look in the `${HOME}/scatool/reports` directory for SCA Report files in HTML and JSON formats
```
podman logs sca
ls -l ${HOME}/scatool/reports
```

# How to Update the SCA Tool Container
1. Pull the new image
2. Restart the `scamonitor.service` or re-run the SCA Tool Container as needed
```
podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest
systemtl --user restart scamonitor.service
```

# Troubleshooting Issues
## The SystemD Unit is not created from the quadlet file
1. Login as **scawork**
2. Make sure the `${HOME}/.config/containers/systemd/scamonitor.container` file is present
```
> ls -l ${HOME}/.config/containers/systemd/scamonitor.container
-rw-r--r--. 1 scawork users 497 Jan 26 10:18 /home/scawork/.config/containers/systemd/scamonitor.container
```
3. Run `/usr/lib/systemd/system-generators/podman-system-generator --user --dryrun`. Observe any errors and correct them. Repeat the command until it displays a valid systemd unit file like this:
```
> /usr/lib/systemd/system-generators/podman-system-generator --user --dryrun
quadlet-generator[1503]: Loading source unit file /home/scawork/.config/containers/systemd/scamonitor.container
---scamonitor.service---
# Podman Quadlet Container File
[Unit]
Description=SCA Tool Container
Wants=network-online.target
After=network-online.target
SourcePath=/home/scawork/.config/containers/systemd/scamonitor.container
RequiresMountsFor=%t/containers

[X-Container]
Image=registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest
Environment=MONITORING=1
Environment=MONITORING_ID=ce4ebd84-bb19-4d42-a077-870ca0ad024d
Volume=scavol:/var/scatool
ContainerName=scamonitor

[Service]
Restart=on-failure
TimeoutStartSec=300
Environment=PODMAN_SYSTEMD_UNIT=%n
KillMode=mixed
ExecStop=/usr/bin/podman rm -f -i --cidfile=%t/%N.cid
ExecStopPost=-/usr/bin/podman rm -f -i --cidfile=%t/%N.cid
Delegate=yes
Type=notify
NotifyAccess=all
SyslogIdentifier=%N
ExecStart=/usr/bin/podman run --name=scamonitor --cidfile=%t/%N.cid --replace --rm --cgroups=split --sdnotify=conmon -d -v scavol:/var/scatool --env MONITORING=1 --env MONITORING_ID=ce4ebd84-bb19-4d42-a077-870ca0ad024d registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest

[Install]
WantedBy=default.target
```
4. Once you know the systemd unit file will be created, you can reboot the server to confirm the service will start automatically at boot time.
5. If you don't want to reboot:
   1. Run `systemctl --user daemon-reload` to generate the service unit
   2. Run `systemctl --user start scamonitor.service`
   3. Check the status of the service with `systemctl --user status scamonitor.service`

## The SCA Tool Container image is missing
1. Login as **scawork**
2. Run `podman images` to confirm the container image is missing
```
> podman images
REPOSITORY  TAG         IMAGE ID    CREATED     SIZE
```
3. Run `systemctl --user status scamonitor.service` to check the status
```
> systemctl --user status scamonitor
● scamonitor.service - SCA Tool Container
     Loaded: loaded (/home/scawork/.config/containers/systemd/scamonitor.container; generated)
     Active: activating (start) since Fri 2024-01-26 10:22:53 UTC; 42s ago
   Main PID: 1014 (podman)
      Tasks: 18 (limit: 4667)
     Memory: 86.1M
        CPU: 154ms
     CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/scamonitor.service
             ├─ 1014 /usr/bin/podman run --name=scamonitor --cidfile=/run/user/1000/scamonitor.cid --replace --rm --cgroups=split --sdnotify=conmon -d -v scavol:/var/scatool --env MONITORING=1 --env MONITORING_ID=>
             ├─ 1070 /usr/bin/podman run --name=scamonitor --cidfile=/run/user/1000/scamonitor.cid --replace --rm --cgroups=split --sdnotify=conmon -d -v scavol:/var/scatool --env MONITORING=1 --env MONITORING_ID=>
             └─ 1075 catatonit -P

Jan 26 10:22:53 localhost.localdomain systemd[917]: Starting SCA Tool Container...
Jan 26 10:22:53 slem55 podman[1070]: 2024-01-26 10:22:53.360779919 +0000 UTC m=+0.072545099 system refresh
Jan 26 10:22:53 slem55 scamonitor[1070]: Trying to pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest...
Jan 26 10:22:53 slem55 scamonitor[1070]: Pulling image registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest inside systemd: setting pull tim>
Jan 26 10:23:04 slem55 scamonitor[1070]: time="2024-01-26T10:23:04Z" level=warning msg="Failed, retrying in 1s ... (1/3). Error: initializing source docker://registry.opensuse.org/home/jrecord/branches/opensuse/te>
Jan 26 10:23:15 slem55 scamonitor[1070]: time="2024-01-26T10:23:15Z" level=warning msg="Failed, retrying in 1s ... (2/3). Error: initializing source docker://registry.opensuse.org/home/jrecord/branches/opensuse/te>
Jan 26 10:23:27 slem55 scamonitor[1070]: time="2024-01-26T10:23:27Z" level=warning msg="Failed, retrying in 1s ... (3/3). Error: initializing source docker://registry.opensuse.org/home/jrecord/branches/opensuse/te>
```
4. The `Error: initializing source` usually means the registry is busy or down, and the `Active: activating` status means systemd is trying to pull the current SCA Tool Container image from the registry.
5. Manually pull the image until it downloads successfully.
```
> podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest
Trying to pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest...
Getting image source signatures
Copying blob bb3d399028e9 done   | 
Copying blob b784dfba2061 done   | 
Copying config cd2a1d820a done   | 
Writing manifest to image destination
cd2a1d820afc1d3654140ecc1f91af076e3681a1d5d9bcbfe1ac7440681c66c3

> podman images
REPOSITORY                                                                                                              TAG         IMAGE ID      CREATED       SIZE
registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool  latest      cd2a1d820afc  36 hours ago  305 MB
```
6. Once downloaded, start the `scamonitor.service` with `systemctl --user start scamonitor.service`
```
> systemctl --user start scamonitor.service
> systemctl --user status scamonitor.service
● scamonitor.service - SCA Tool Container
     Loaded: loaded (/home/scawork/.config/containers/systemd/scamonitor.container; generated)
     Active: active (running) since Fri 2024-01-26 10:37:58 UTC; 3min 12s ago
   Main PID: 1610 (conmon)
      Tasks: 4 (limit: 4667)
     Memory: 15.1M
        CPU: 1.609s
     CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/scamonitor.service
             ├─libpod-payload-12d9db8a2c1abe7472de6a179b876f0e2e0f7d9f297eaa30dfff614377ca8e03
             │ ├─ 1620 /bin/bash /usr/local/bin/entrypoint.sh
             │ └─ 1750 sleep 5
             └─runtime
               ├─ 1603 /usr/bin/slirp4netns --disable-host-loopback --mtu=65520 --enable-sandbox --enable-seccomp --enable-ipv6 -c -r 3 -e 4 --netns-type=path /run/user/1000/netns/netns-db274823-5519-fdd8-9536-cf2>
               └─ 1610 /usr/bin/conmon --api-version 1 -c 12d9db8a2c1abe7472de6a179b876f0e2e0f7d9f297eaa30dfff614377ca8e03 -u 12d9db8a2c1abe7472de6a179b876f0e2e0f7d9f297eaa30dfff614377ca8e03 -r /usr/bin/runc -b /h>

Jan 26 10:37:58 slem55 scamonitor[1610]:          sle15sp4 : 230       
Jan 26 10:37:58 slem55 scamonitor[1610]:          sle15sp5 : 1         
Jan 26 10:37:58 slem55 scamonitor[1610]:              8162 : Total Available Patterns
Jan 26 10:37:58 slem55 scamonitor[1610]: 
Jan 26 10:37:58 slem55 scamonitor[1610]: 
Jan 26 10:37:58 slem55 scamonitor[1610]: 2024-01-26 10:37:58.547195913 +0000 UTC [Warn] Entrypoint:   Create missing directory: /var/scatool/incoming
Jan 26 10:37:58 slem55 scamonitor[1610]: 2024-01-26 10:37:58.548584858 +0000 UTC [Warn] Entrypoint:   Create missing directory: /var/scatool/reports
Jan 26 10:37:58 slem55 scamonitor[1610]: 2024-01-26 10:37:58.549757927 +0000 UTC [Warn] Entrypoint:   Create missing directory: /var/scatool/logs
Jan 26 10:37:58 slem55 scamonitor[1610]: 2024-01-26 10:37:58.550906023 +0000 UTC [Mode] Entrypoint:   Monitoring /var/scatool/incoming
Jan 26 10:37:58 slem55 scamonitor[1610]: 2024-01-26 10:37:58.551342527 +0000 UTC [Note] Entrypoint:   Monitoring interval: 5 sec
```

## No container logs are showing
1. The `scamonitor.service` and podman logs are not showing under SLES 15 SP5 or SLE Micro 5.5 even though the container is running
> [!WARNING]
> Despite the fix, the issue persists with SLES 15 SP4
```
> podman ps
CONTAINER ID  IMAGE                                                                                                                          COMMAND     CREATED        STATUS        PORTS       NAMES
cb77dc513e89  registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest              3 minutes ago  Up 3 minutes              scamonitor

> podman logs scamonitor

> systemctl --user status scamonitor.service
● scamonitor.service - SCA Tool Container
     Loaded: loaded (/home/scawork/.config/containers/systemd/scamonitor.container; generated)
     Active: active (running) since Fri 2024-01-26 04:06:15 MST; 3min 38s ago
   Main PID: 1657 (conmon)
      Tasks: 4 (limit: 1953)
     Memory: 345.5M
        CPU: 3.765s
     CGroup: /user.slice/user-1002.slice/user@1002.service/app.slice/scamonitor.service
             ├─libpod-payload-cb77dc513e89cba4fbf4786634d0ecde848d65abb2221d240626a62f77bbdb16
             │ ├─ 1667 /bin/bash /usr/local/bin/entrypoint.sh
             │ └─ 1815 sleep 5
             └─runtime
               ├─ 1651 /usr/bin/slirp4netns --disable-host-loopback --mtu=65520 --enable-sandbox --enable-seccomp --enable-ipv6 -c -r 3 -e 4 --netns-type=path /run/user/1002/netns/netns-6bb5a176-2f11-2a67-e0a5-a66>
               └─ 1657 /usr/bin/conmon --api-version 1 -c cb77dc513e89cba4fbf4786634d0ecde848d65abb2221d240626a62f77bbdb16 -u cb77dc513e89cba4fbf4786634d0ecde848d65abb2221d240626a62f77bbdb16 -r /usr/bin/runc -b /h>
```
2. Add scawork to the `systemd-journal` group
```
> sudo usermod -a -G systemd-journal scawork
> grep systemd-journal /etc/group
systemd-journal:x:482:scawork
```
3. Logout and log back in as **scawork**
4. Check the logs
```
> podman logs scamonitor
2024-01-26 11:15:05.940182557 +0000 UTC [Note] Entrypoint:   Supportconfig analysis workload container starting
2024-01-26 11:15:05.941219104 +0000 UTC [Note] Entrypoint:   Package versions:
sca-patterns-base-1.6.0-2.1.noarch
sca-server-report-1.6.1-1.1.noarch
sca-patterns-sle15-1.5.6-1.1.noarch
sca-patterns-sle12-1.5.6-1.1.noarch
sca-patterns-sle11-1.5.4-1.1.noarch
sca-patterns-alp1-2.0.1-1.1.noarch

2024-01-26 11:15:05.985088034 +0000 UTC [Note] Entrypoint:   SCA Tool patterns:
#####################################################################################
#   SCA Tool v3.0.1
#####################################################################################

Pattern Library Summary
      
Pattern Directory : Count     
================= : =====     
          alp1all : 12        
         sle11all : 135       
         sle11sp0 : 6         
         sle11sp1 : 180       
         sle11sp2 : 290       
         sle11sp3 : 360       
         sle11sp4 : 382       
         sle12all : 121       
         sle12sp0 : 547       
         sle12sp1 : 571       
         sle12sp2 : 691       
         sle12sp3 : 634       
         sle12sp4 : 709       
         sle12sp5 : 986       
         sle15all : 59        
         sle15sp0 : 414       
         sle15sp1 : 659       
         sle15sp2 : 731       
         sle15sp3 : 444       
         sle15sp4 : 230       
         sle15sp5 : 1         
             8162 : Total Available Patterns


2024-01-26 11:15:06.039957681 +0000 UTC [Mode] Entrypoint:   Monitoring /var/scatool/incoming
2024-01-26 11:15:06.040352603 +0000 UTC [Note] Entrypoint:   Monitoring interval: 5 sec
```
