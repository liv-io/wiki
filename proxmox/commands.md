# Commands

## Index

- [Commands](#commands)
  - [ZFS](#zfs)
- [Appendix](#appendix)

## Commands

### ZFS

- Create RAID-1 (mirror)
  ```
  zpool create -f -o ashift=12 data1 mirror /dev/disk1 /dev/disk2
  ```

- Create RAID-5 (RAID-Z with 1 parity)
  ```
  zpool create -f -o ashift=12 data1 raidz1 /dev/disk1 /dev/disk2 /dev/disk3
  ```

- Create RAID-10 (mirror + stripe)
  ```
  zpool create -f -o ashift=12 data1 mirror /dev/disk1 /dev/disk2 mirror /dev/disk3 /dev/disk4
  ```

- Configure ZFS properties
  ```
  zfs set atime=off rpool
  zfs set checksum=on rpool
  zfs set compression=lz4 rpool
  zfs set sync=standard rpool

  zfs set atime=off data1
  zfs set checksum=on data1
  zfs set compression=lz4 data1
  zfs set sync=disabled data1
  ```

- List ZFS properties
  ```
  zfs get all rpool | grep -iE " atime|checksum|compression|sync" | sort
  zfs get all data1 | grep -iE " atime|checksum|compression|sync" | sort
  ```

- Add ZFS pool to Proxmox storage
  ```
  cat <<EOF >> /etc/pve/storage.cfg
  zfspool: data1
      pool data1
      sparse
      content images
  EOF
  ```

## Appendix
