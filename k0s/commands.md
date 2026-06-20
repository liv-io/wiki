# Commands

## Index

- [Manual Upgrade](#manual-upgrade)
- [Reset Node](#reset-node)
- [Appendix](#appendix)

## Manual Upgrade

- Download, verify and install latest [k0s](README.md#k0s) release

- Stop the node
  ```
  systemctl stop k0scontroller.service
  ```

- Update the systemd unit file
  ```
  k0s install controller --config /etc/k0s/k0s.yaml --single --profile=low-power --start --force
  ```

- Vacuum the Kine SQLite database
  ```
  sqlite3 /var/lib/k0s/db/kine.db "VACUUM;"
  ```

- Start and verify node
  ```
  systemctl start k0scontroller.service

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

- Validate status of node
  ```
  k0s kubectl get nodes
  k0s kubectl get all -n kube-system
  ```

## Reset Node

- Reset node and remove configuration
  ```
  systemctl unmask k0scontroller.service
  systemctl stop k0scontroller.service 2>/dev/null
  systemctl daemon-reload
  systemctl reset-failed
  k0s reset
  rm -rf /etc/k0s /root/.kube/ /root/k0s-controller.token
  ```

## Appendix

- [Upgrade](https://docs.k0sproject.io/head/upgrade)
- [CLI](https://docs.k0sproject.io/stable/cli)
