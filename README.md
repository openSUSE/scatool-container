# SCA Tool Container

A rootless podman container to analyze SLES11, SLES12, SLES15 and ALP1 supportconfig tar files placed in the `/var/scatool/incoming` directory. The resulting SCA Report files will be placed in the `/var/scatool/reports` directory in HTML and JSON formats. Log files from the analysis session are placed in `/var/scatool/logs`.

## Directories
* `/var/scatool/incoming` to `${HOME}/scatool/incoming` - Supportconfig tarball files you want analyzed
* `/var/scatool/reports` to `${HOME}/scatool/reports` - SCA Report files in both HTML and JSON formats
* `/var/scatool/logs` to `${HOME}/scatool/logs` - scatool logs and shared files

## Projects
* Upstream Source: https://github.com/openSUSE/scatool-container
* Container Registry: https://registry.opensuse.org/cgi-bin/cooverview?srch_term=project%3D%5Ehome%3Ajrecord
* OBS Package: https://build.opensuse.org/package/show/home:jrecord:branches:openSUSE:Templates:Images:Tumbleweed/scatool-container
* `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

> [!NOTE]
> All instructions assume you will be running the SCA Tool Container as a user SystemD process. If you do not intend to run it under SystemD, but only on an as-needed basis, skip to [How to Use the SCA Tool Container as Needed](#how-to-use-the-sca-tool-container-as-needed) below.

# How to Analyze Supportconfigs
1. Run supportconfigs on the servers you wish to analyze
2. Copy the supportconfigs to the SCA Tool Container's incoming directory
```
scp /var/log/scc_*txz scawork@<your_host>:~/scatool/incoming
```
3. Login as **scawork**
4. Supportconfigs are created with 600 permissions by default. Change the permissions so the supportconfigs in the incoming directory can be read by the SCA Tool Container.
5. Check on the supportconig analysis status
6. Look in the ${HOME}/scatool/reports directory for SCA Report files in HTML and JSON formats
```
sudo chmod 644 ${HOME}/scatool/incoming/*
podman logs scamonitor
ls -l ${HOME}/scatool/reports
```
7. Each supportconfig will have a corresponding analysis file in the ${HOME}/scatool/logs directory

# Installation and Configuration for User SystemD Container on ALP1
1. Install SUSE ALP with podman

> [!NOTE]
> The container can run as any non-root user. However, I will create a user, **scawork**, dedicated to analyzing supportconfigs.

2. Login as **root**:
   1. Add the scawork user
   2. Assign scawork a password
   3. Enable linger for scawork
   4. Configure supportconfig to gather podman information from scawork
   5. Configure unified cgroups on boot
   6. Update grub
```
useradd -m scawork
echo 'scawork:<password>' | chpasswd
loginctl enable-linger scawork
echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportutils/supportconfig.conf
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=1 /g' /etc/default/grub
transactional-update run grub2-mkconfig -o /boot/grub2/grub.cfg
```
3. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Install the [scamonitor.container](https://github.com/openSUSE/scatool-container/blob/1219101-quadlet/scamonitor.container) quadlet file
   4. Restart user SystemD
   5. Start the `scamonitor.service`

> [!NOTE]
> The `scamonitor.service` will pull the `scatool:lastest` image if not found. You can manually pull the image with:
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

   6. Check the status of `scamonitor.service`
```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
cp scamonitor.container ${HOME}/.config/containers/systemd
systemctl --user deamon-reload
systemctl --user start scamonitor.service
systemctl --user status scamonitor.service
```
4. Reboot the server
5. Login as **scawork**:
6. Check for cgroup version 2
7. Check the `scamonitor.service` status
```
podman info | grep cgroupVersion
  cgroupVersion: v2

systemctl --user show -p SubState -p ActiveState scamonitor
  ActiveState=active
  SubState=running
```

# Installation and Configuration for User SystemD Container on SLES 15 SP5
1. Install SUSE SLES 15 SP5
2. Install podman from the Containers Module

> [!NOTE]
> The container can run as any non-root user. However, I will create a user, **scawork**, dedicated to analyzing supportconfigs.

3. Login as **root**:
   1. Add the scawork user
   2. Assign scawork a password
   3. Configure supportconfig to gather podman information from scawork
   4. Configure unified cgroups on boot
   5. Give scawork access to zypper credentials
   6. Add scawork to the systemd-journal group so it can see the container logs
   7. Update grub.cfg
```
useradd -m scawork
echo 'scawork:<password>' | chpasswd
echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportutils/supportconfig.conf
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=1 /g' /etc/default/grub
setfacl -m u:scawork:r /etc/zypp/credentials.d/*
sed -i -e 's/systemd-journal:x:\(.*\):/systemd-journal:x:\1:scawork/g' /etc/group
grub2-mkconfig -o /boot/grub2/grub.cfg
```

4. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Install the `scamonitor.container` quadlet file
   4. Restart user SystemD
   5. Start the `scamonitor.service`

> [!NOTE]
> The `scamonitor.service` will pull the `scatool:lastest` image if not found. You can manually pull the image with:
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

   6. Check the status of `scamonitor.service`
```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
cp scamonitor.container ${HOME}/.config/containers/systemd
systemctl --user daemon-reload
systemctl --user start scamonitor.service
systemctl --user status scamonitor.service
```
5. Reboot the server
6. Login as **scawork**:
7. Check for cgroup version 2
8. Check the `scamonitor.service` status
```
podman info | grep cgroupVersion
  cgroupVersion: v2

systemctl --user show -p SubState -p ActiveState scamonitor
  ActiveState=active
  SubState=running
```

# How to Update the SCA Tool Container
1. Pull the new image
2. Restart the scamonitor.service
```
podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest
systemtl --user restart scamonitor.service
```

# How to Use the SCA Tool Container as Needed
1. Login as **scawork**
2. Pull the SCA Tool Container
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
podman run -dt --rm -v scavol:/var/scatool:z scatool:latest
```
7. Check on the supportconig analysis status
8. Look in the `${HOME}/scatool/reports` directory for SCA Report files in HTML and JSON formats
```
podman logs scamonitor
ls -l ${HOME}/scatool/reports
```
9. To update the container, just pull the new image before running the container again
```
podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest
```

