# SCA Tool Container

A rootless podman container to analyze SLES11, SLES12, SLES15 and ALP1 supportconfig tar files placed in the `/var/scatool/incoming` directory. The resulting SCA Report files will be placed in the `/var/scatool/reports` directory in HTML and JSON formats. Log files from the analysis session are placed in `/var/scatool/logs`.

## Directories

* `/var/scatool/incoming` - Supportconfig tarball files you want analyzed
* `/var/scatool/reports` - SCA Report files in both HTML and JSON formats
* `/var/scatool/logs` - scatool logs and shared files

# Installation

1. Install SUSE ALP or SLES15 SP5
2. Install podman from the Containers Module

> [!NOTE]
> The container can run as any non-root user. However, I will create a user, scawork, dedicated to analyzing supportconfigs.

# Configuration

1. Login as **root**:
   1. Add the scawork user
   2. Assign scawork a password
   3. Configure supportconfig to gather podman information from scawork
   4. Configure unified cgroups on boot

```
useradd -m scawork
echo "scawork:<password>" | chpasswd
echo 'LOCAL_PODMAN_USERS=scawork' >> /etc/supportutils/supportconfig.conf
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=1 /g' /etc/default/grub
```

2. **On ALP1**
   1. Update grub.cfg
> `transactional-update run grub2-mkconfig -o /boot/grub2/grub.cfg`

3. **On SLES15**
   1. Give scawork access to zypper credentials
   2. Add scawork to the systemd-journal group so it can see the container logs
   3. Update grub.cfg

```
setfacl -m u:scawork:r /etc/zypp/credentials.d/*
sed -i -e 's/systemd-journal:x:\(.*\):/systemd-journal:x:\1:scawork/g' /etc/group
grub2-mkconfig -o /boot/grub2/grub.cfg
```

4. reboot

5. Login as **scawork**:
   1. Enable linger for scawork
   2. Create a symlink to the container's working directory
   3. Create the podman volume for the container
   4. Pull the current scatool container image

```
sudo loginctl enable-linger scawork
sudo ln -sf ~/.local/share/containers/storage/volumes/scavol/_data /var/scatool
podman volume create scavol
podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/scatool:latest
```

# Options for Running the Container

Option A) Running the Container as a non-root SystemD Service:
 1.  Follow Configuration steps 1-2 above
 2.  Login as **scawork**
 3.  > podman run -dt -v scavol:/var/scatool:z -e MONITORING=1 --name scamonitor scatool:latest
 4.  > mkdir -p ~/.config/systemd/user
 5.  > podman generate systemd --new --name scamonitor > ~/.config/systemd/user/container-scamonitor.service
 6.  > systemctl --user daemon-reload
 7.  > systemctl --user enable container-scamonitor.service
 8.  > sudo reboot # to confirm the service starts at boot and login again as scawork
 9.  > systemctl --user status container-scamonitor.service
10.  Run supportconfig as various servers
11.  Copy the desired supportconfig tarballs to scawork@<your_host>:/var/scatool/incoming
12.  Change the permissions so the container can read the supportconfigs
     > chmod 644 /var/scatool/incoming/*
13.  Check to see if the SCA Reports have finished.
     > podman logs scamonitor
14.  When finished, the JSON and HTML SCA Report files will be saved in the /var/scatool/reports directory.
     > ls -l /var/scatool/reports
15.  Repeat steps 11-15 for any new additional supportconfigs to analyze
16.  Check the status of the running scamonitor container with one of the following:
16.1 > systemctl --user status container-scamonitor
16.2 > podman logs scamonitor

Option B) Running the Container as Needed:
1.  Follow Configuration steps 1-2 above
2.  Login as **scawork**
3   > podman run -d --rm -v scavol:/var/scatool:z scatool:latest
4.  Run supportconfig as various servers
5.  Copy the desired supportconfig tarballs to scawork@<your_host>:/var/scatool/incoming
6.  Change the permissions so the container can read the supportconfigs
    > chmod 644 /var/scatool/incoming/*
7.  Each time you want to anlyze supportconfigs in the incoming directory, run:
    > podman run -dt --rm -v scavol:/var/scatool:z scatool:latest
8.  When finished, the JSON and HTML SCA Report files will be saved in the /var/scatool/reports directory.
    > ls -l /var/scatool/reports
9.  Repeat steps 5-8 for any new additional supportconfigs to analyze

#Running the Container with a Shell

`podman run -it -v scavol:/var/scatool:z --entrypoint=/bin/bash scatool:latest`

# How to Update the Container
1. Login as **scawork**
2. > `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/scatool:latest`
3. > `systemctl --user restart container-scamonitor.service` # If running Option A.

