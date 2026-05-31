# Proxmox 9 Upgrade

## Upgrade

- Start a `tmux` session in case of connectivity issues

  ```
  tmux
  ```

- Run the Proxmox upgrade checker

  ```
  pve8to9
  ```

- Shutdown virtual machines

  ```
  for vm in $(qm list | grep 'running' | tr -s ' ' '#' | cut -d '#' -f2) ; do timeout 1 qm shutdown ${vm} ; done
  qm list
  ```

- Disable start-on-boot

  ```
  for vm in $(qm list | tr -s ' ' '#' | cut -d '#' -f2) ; do qm set ${vm} -onboot 0 ; done
  ```

- Update APT repositories

  ```
  sed -i 's@bookworm@trixie@g' /etc/apt/sources.list
  sed -i 's@bookworm@trixie@g' /etc/apt/sources.list.d/proxmox.list
  ```

- Update APT cache

  ```
  apt update
  ```

- Run APT upgrade

  ```
  DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y dist-upgrade
  ```

- Reboot system

  ```
  sleep 3 && reboot
  ```

- Start a `tmux` session in case of connectivity issues

  ```
  tmux
  ```

- Disable Proxmox enterprise and ceph repositories

  ```
  ls -l /etc/apt/sources.list.d/
  sed -i 's@^deb @#deb @g' /etc/apt/sources.list.d/*enterprise*
  sed -i 's@^deb @#deb @g' /etc/apt/sources.list.d/*ceph*
  sed -i 's@^@#@g' /etc/apt/sources.list.d/pve-enterprise.sources
  ```

- Update APT cache

  ```
  apt update

- Remove unused packages

  ```
  apt autoremove --purge
  ```

- Upgrade ZFS pools

  ```
  for pool in $(zpool list -Ho name) ; do zpool upgrade ${pool} ; done
  zpool list
  ```

- Run Ansible playbook to ensure correct configuration

  ```
  ansible-playbook all.yml --limit=<fqdn>
  ansible-playbook hypervisor.yml --limit=<fqdn>
  ```

- Reboot system

  ```
  sleep 3 && reboot
  ```

- Start a `tmux` session in case of connectivity issues

  ```
  tmux
  ```

- Enable start-on-boot

  ```
  for vm in $(qm list | tr -s ' ' '#' | cut -d '#' -f2) ; do qm set ${vm} -onboot 1; done
  ```

- Start virtual machines

  ```
  for vm in $(qm list | tr -s ' ' '#' | cut -d '#' -f2) ; do qm start ${vm} ; done
  qm list
  ```

- Inspect logs

  ```
  grep -IirE "fatal|emerg|alert|crit|err|warn|corrupt|fail" /var/log/
  ```

## Appendix

- Resume terminated APT installation process

  ```
  dpkg --configure --pending
  ```
