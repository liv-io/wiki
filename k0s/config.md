# Config

## Index

- [Debian](#debian)
- [k0s](#k0s)
  - [Bootstrap Node](#bootstrap-node)
  - [Additional Node](#additional-node)
- [Appendix](#appendix)
  - [Reset Node](#reset-node)

## Debian

- Install, enable and start `nftables`
  ```
  apt -y --no-install-recommends install nftables
  systemctl enable nftables.service
  systemctl start nftables.service
  ```

## k0s

### Bootstrap Node

- Config node
  ```
  install --directory --owner=root --group=root --mode=0755 /etc/k0s
  k0s config create > /etc/k0s/k0s.yaml

  export CLUSTER_VIP="10.1.17.40"
  yq -i 'del(.spec.api.address) | del(.spec.storage.etcd.peerAddress)' /etc/k0s/k0s.yaml
  yq -i '.spec.api.externalAddress = strenv(CLUSTER_VIP)' /etc/k0s/k0s.yaml
  yq -i '.spec.api.sans = [strenv(CLUSTER_VIP)]' /etc/k0s/k0s.yaml
  yq -i '.spec.network.controlPlaneLoadBalancing = {"enabled": true, "type": "Keepalived", "keepalived": {"vrrpInstances": [{"virtualIPs": ["10.1.17.40/24"], "authPass": "<password>"}]}}' /etc/k0s/k0s.yaml
  ```

- Start and verify node
  ```
  k0s install controller -c /etc/k0s/k0s.yaml --enable-worker --no-taints --force --start

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

- Generate token for additional nodes
  ```
  k0s token create --role=controller --expiry=1h > /root/k0s-controller.token
  ```

### Additional Nodes

- Copy config and token from bootstrap-node
  ```
  install --directory --owner=root --group=root --mode=0755 /etc/k0s

  cat <<EOF > /etc/k0s/k0s.yaml
  <config>
  EOF

  cat <<EOF > /root/k0s-controller.token
  <token>
  EOF
  ```

- Start and verify node
  ```
  k0s install controller -c /etc/k0s/k0s.yaml --token-file /root/k0s-controller.token --enable-worker --no-taints --force --start

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

## Appendix

### Reset Node

- Reset node and clean-up system
  ```
  systemctl unmask k0scontroller.service
  systemctl stop k0scontroller.service 2>/dev/null
  systemctl daemon-reload
  systemctl reset-failed
  k0s reset
  rm -rf /etc/k0s /root/.kube/ /root/k0s-controller.token
  ```
