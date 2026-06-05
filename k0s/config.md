# Config

## Index

- [Debian](#debian)
- [k0s](#k0s)
  - [Bootstrap Node](#bootstrap-node)
  - [Additional Node](#additional-node)
  - [Cluster](#cluster)
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

- Generate configuration file
  ```
  export CLUSTER="rnd"
  export DNS="10.1.11.1"
  export K01="10.1.17.41"
  export K02="10.1.17.42"
  export K03="10.1.17.43"
  export KEEPALIVED_PASSWORD="D9Lw4QdR"
  export VIP="10.1.17.40"

  install --directory --owner=root --group=root --mode=0755 /etc/k0s
  k0s config create > /etc/k0s/k0s.yaml
  ```

- Modify configuration file
  ```
  yq -i '.metadata.name = strenv(CLUSTER)' /etc/k0s/k0s.yaml
  yq -i '.spec.api.sans = [strenv(VIP)]' /etc/k0s/k0s.yaml
  yq -i '.spec.network.controlPlaneLoadBalancing = {"enabled": true, "type": "Keepalived", "keepalived": {"vrrpInstances": [{"virtualIPs": [strenv(VIP) + "/24"], "authPass": strenv(KEEPALIVED_PASSWORD)}]}}' /etc/k0s/k0s.yaml
  yq -i '.spec.network.controlPlaneLoadBalancing.keepalived.virtualServers = [{"ipAddress": .spec.api.externalAddress, "port": .spec.api.port, "backends": [{"ipAddress": strenv(K01), "port": .spec.api.port}, {"ipAddress": strenv(K02), "port": .spec.api.port}, {"ipAddress": strenv(K03), "port": .spec.api.port}]}]' /etc/k0s/k0s.yaml
  yq -i '.spec.network.dns.upstreamNameServers = [strenv(DNS)]' /etc/k0s/k0s.yaml
  yq -i '.spec.network.nodeLocalLoadBalancing.enabled = true | .spec.network.nodeLocalLoadBalancing.type = "EnvoyProxy"' /etc/k0s/k0s.yaml
  yq -i '.spec.storage.etcd.extraArgs."auto-compaction-retention" = "1"' /etc/k0s/k0s.yaml
  yq -i 'del(.spec.api.address) | del(.spec.storage.etcd.peerAddress)' /etc/k0s/k0s.yaml
  ```

- Validate configuration file
  ```
  k0s config validate --config /etc/k0s/k0s.yaml
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

- Copy configuration file and token from bootstrap-node
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

### Cluster

- Validate status of all nodes
  ```
  k0s kubectl get nodes
  ```

- Validate core system pods
  ```
  k0s kubectl get pods -n kube-system
  ```

## Appendix

- [Control Plane Load Balancing](https://docs.k0sproject.io/stable/cplb)
