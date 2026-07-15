# Commands

## Index

- [Getting Information](#getting-information)
- [Manage Images](#manage-images)
- [Manage Secrets](#manage-secrets)
- [Manual Upgrade](#manual-upgrade)
- [Reset Node](#reset-node)
- [Appendix](#appendix)

## Getting Information

- List all namespaces
  ```
  k0s kubectl get namespaces
  ```

- List all events
  ```
  k0s kubectl get events -A
  ```

- List versions of all pods
  ```
  k0s kubectl get all -A -o jsonpath='{range .items[*].spec.containers[*]}{.image}{"\n"}{end}' | sort
  ```

## Manage Images

- Show all images
  ```
  k0s ctr -n k8s.io images list
  ```

- Remove image
  ```
  k0s ctr -n k8s.io images remove <tag>
  ```

- Remove unused images
  ```
  k0s ctr -n k8s.io images prune --all
  ```

## Manage Secrets

- List all secrets across all namespaces
  ```
  k0s kubectl get secrets -A
  ```

- List secret for a given namespace
  ```
  k0s kubectl get secrets -n default
  ```

- Create registry secret
  ```
  k0s kubectl create secret docker-registry registry.example.com \
      --docker-server=registry.example.com \
      --docker-username="<username>" \
      --docker-password="<password>" \
      --namespace=default
  ```

- Create generic secret
  ```
  k0s kubectl create secret generic memos-config \
      --from-literal=PASSWORD="<password>" \
      --from-literal=API_KEY="<key>" \
      --namespace=default
  ```

- Create secret from file
  ```
  k0s kubectl create secret generic ssh-key-secret \
      --from-file=id_ed25519=/home/user/.ssh/id_ed25519 \
      --namespace=default
  ```

- Show secret metadata
  ```
  k0s kubectl describe secret <secret-name> -n default
  ```

- Decode secret
  ```
  k0s kubectl get secret <secret-name> -n default -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode
  ```

- Delete secret
  ```
  k0s kubectl delete secret <secret-name> -n default
  ```

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
