# SCA Tool Container

A rootless podman container to analyze SLES11, SLES12, SLES15 and ALP1 supportconfig tar files placed in the `/var/scatool/incoming` directory. The resulting SCA Report files will be placed in the `/var/scatool/reports` directory in HTML and JSON formats. Log files from the analysis session are placed in `/var/scatool/logs`.

## Directories

* `${HOME}/scatool/incoming`, `/var/scatool/incoming` - Supportconfig tarball files you want analyzed
* `${HOME}/scatool/reports`, `/var/scatool/reports` - SCA Report files in both HTML and JSON formats
* `${HOME}/scatool/logs`, `/var/scatool/logs` - scatool logs and shared files

## Projects
* Upstream Source: https://github.com/openSUSE/scatool-container
* Container Registry: https://registry.opensuse.org/cgi-bin/cooverview?srch_term=project%3D%5Ehome%3Ajrecord
* OBS Package: https://build.opensuse.org/package/show/home:jrecord:branches:openSUSE:Templates:Images:Tumbleweed/scatool-container
* `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`

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
2. Login as **scawork**:
   1. Create a symlink to the container's working directory
   2. Create the podman quadlet directory
   3. Install the `scamonitor.container` quadlet file
   4. Restart user SystemD
   5. Start the `scamonitor.service`
> [!NOTE]
> The scamonitor.service will pull the scatool:lastest image if not found. You can manually pull the image with:
> `podman pull registry.opensuse.org/home/jrecord/branches/opensuse/templates/images/tumbleweed/containers/suse/alp/workloads/scatool:latest`
   6. Check the status of `scamonitor.service`
   7. Reboot the server to enable unified cgroups
```
ln -sf ${HOME}/.local/share/containers/storage/volumes/scavol/_data ${HOME}/scatool
mkdir -p ${HOME}/.config/containers/systemd
cp scamonitor.container ${HOME}/.config/containers/systemd
systemctl --user deamon-reload
systemctl --user start scamonitor.service
systemctl --user status scamonitor.service
reboot
```

