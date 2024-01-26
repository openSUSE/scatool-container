# SCA Tool Container

A rootless podman container to analyze SLES11, SLES12, SLES15 and ALP1 supportconfig tar files placed in the `/var/scatool/incoming` directory. The resulting SCA Report files will be placed in the `/var/scatool/reports` directory in HTML and JSON formats. Log files from the analysis session are placed in `/var/scatool/logs`.

> [!NOTE]
> The container can run as any non-root user. However, a user will be created, **scawork**, dedicated to analyzing supportconfigs.

## Directories
* `/var/scatool/incoming` to `${HOME}/scatool/incoming` - Supportconfig tarball files you want analyzed
* `/var/scatool/reports` to `${HOME}/scatool/reports` - SCA Report files in both HTML and JSON formats
* `/var/scatool/logs` to `${HOME}/scatool/logs` - scatool logs and shared files

## Index to Sections
* [Rootless SystemD Service on ALP1](#installation-and-configuration-for-user-systemd-container-on-alp1)
* [Rootless SystemD Service on SLES 15 SP5](#installation-and-configuration-for-user-systemd-container-on-sles-15-sp5)
* [Rootless SystemD Service on SLE Micro 5.5](#installation-and-configuration-for-user-systemd-container-on-sle-micro-55)
* [Rootless Container as Needed on Any](#how-to-use-the-sca-tool-container-as-needed)
* [How to Update the SCA Tool Container](#how-to-update-the-sca-tool-container)

## Projects
* Upstream Source: https://github.com/openSUSE/scatool-container
* Container Registry: https://registry.opensuse.org/cgi-bin/cooverview?srch_term=project%3D%5Ehome%3Ajrecord
* OBS Package: https://build.opensuse.org/package/show/home:jrecord:branches:openSUSE:Templates:Images:Tumbleweed/scatool-container
* `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

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

# Installation and Configuration for User SystemD Container on ALP1
1. Install SUSE ALP with podman
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
[[ -d /etc/supportutils ]] && echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportutils/supportconfig.conf || echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportconfig.conf
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=1 /g' /etc/default/grub
transactional-update run grub2-mkconfig -o /boot/grub2/grub.cfg
```
3. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Install the [scamonitor.container](https://github.com/openSUSE/scatool-container/blob/main/scamonitor.container) quadlet file

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

4. Reboot the server. This will enable unified cgroups and confirm the container service will start at boot time.
5. Login as **scawork**:
   1. Check for cgroup version 2
   2. Check the `scamonitor.service` status
```
podman info | grep cgroupVersion
  cgroupVersion: v2

systemctl --user status scamonitor.service
```

# Installation and Configuration for User SystemD Container on SLES 15 SP5
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
grub2-mkconfig -o /boot/grub2/grub.cfg
```

4. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Create an empty `${HOME}/.config/containers/mounts.conf` file
   4. Install the [scamonitor.container](https://github.com/openSUSE/scatool-container/blob/main/scamonitor.container) quadlet file

> [!NOTE]
> The `scamonitor.service` will pull the `scatool:latest` image if not found. You can manually pull the image with:  
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
touch ${HOME}/.config/containers/mounts.conf
cp scamonitor.container ${HOME}/.config/containers/systemd
```
5. Reboot the server. This will enable unified cgroups and confirm the container service will start at boot time.
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
transactional-update run grub2-mkconfig -o /boot/grub2/grub.cfg
```

3. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Create an empty `${HOME}/.config/containers/mounts.conf` file
   4. Install the [scamonitor.container](https://github.com/openSUSE/scatool-container/blob/1219101-quadlet/scamonitor.container) quadlet file

> [!NOTE]
> The `scamonitor.service` will pull the `scatool:latest` image if not found. You can manually pull the image with:  
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
touch ${HOME}/.config/containers/mounts.conf
cp scamonitor.container ${HOME}/.config/containers/systemd
```
4. Reboot the server. This will enable unified cgroups and confirm the container service will start at boot time.
5. Login as **scawork**:
   1. Check for cgroup version 2
   2. Check the `scamonitor.service` status
```
podman info | grep cgroupVersion
  cgroupVersion: v2

systemctl --user status scamonitor
```

# How to Update the SCA Tool Container
1. Pull the new image
2. Restart the `scamonitor.service` or re-run the SCA Tool Container as needed
```
podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest
systemtl --user restart scamonitor.service
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

