# Config

## Index

- [Debian](#debian)
- [k0s](#k0s)
  - [Local-Path](#local-path)
  - [Containerd](#containerd)
  - [Traefik](#traefik)
  - [Calico](#calico)
  - [Apps](#apps)
- [Appendix](#appendix)

## Debian

- Add http/https proxy settings
  ```
  install --directory --owner=root --group=root --mode=0755 /etc/systemd/system/k0scontroller.service.d

  cat <<EOF > /etc/systemd/system/k0scontroller.service.d/http-proxy.conf
  [Service]
  Environment="HTTP_PROXY=http://fp.liv.io:3128"
  Environment="HTTPS_PROXY=http://fp.liv.io:3128"
  Environment="NO_PROXY=localhost,127.0.0.1,::1,bs.liv.io,backup.liv.io,ca.liv.io,10.1.13.61,10.244.0.0/16,10.96.0.0/12,memos02.liv.io,.svc,.cluster.local"
  EOF

  systemctl daemon-reload
  ```

## k0s

- Generate configuration file
  ```
  export CLUSTER="memos"
  export DNS="10.1.11.1"

  install --directory --owner=root --group=root --mode=0755 /etc/k0s
  k0s config create > /etc/k0s/k0s.yaml
  ```

- Modify configuration file
  ```
  yq -i '.metadata.name = strenv(CLUSTER)' /etc/k0s/k0s.yaml
  yq -i '.spec.controllerManager.extraArgs["leader-elect"] = "false"' /etc/k0s/k0s.yaml
  yq -i '.spec.network.dns.upstreamNameServers = [strenv(DNS)]' /etc/k0s/k0s.yaml
  yq -i '.spec.scheduler.extraArgs["leader-elect"] = "false"' /etc/k0s/k0s.yaml
  yq -i '.spec.storage.type = "kine" | del(.spec.storage.etcd) | del(.spec.installConfig.users.etcdUser)' /etc/k0s/k0s.yaml
  yq -i '.spec.telemetry.enabled = false' /etc/k0s/k0s.yaml
  yq -i '.spec.workerProfiles = [{"name": "low-power", "values": {"housekeepingInterval": "30s", "nodeStatusUpdateFrequency": "30s"}}]' /etc/k0s/k0s.yaml
  ```

- Validate configuration file
  ```
  k0s config validate --config /etc/k0s/k0s.yaml
  ```

- Start and verify node
  ```
  k0s install controller --config /etc/k0s/k0s.yaml --single --profile=low-power --start

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

- Validate status of node
  ```
  k0s kubectl get nodes
  k0s kubectl get all -n kube-system
  ```

### Local-Path

- Apply `local-path-provisioner`
  ```
  export LOCAL_PATH_PROVISIONER_VERSION="0.0.36"

  k0s kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v${LOCAL_PATH_PROVISIONER_VERSION}/deploy/local-path-storage.yaml
  ```

- Wait until `local-path-provisioner` is ready
  ```
  k0s kubectl get pods -n local-path-storage -w
  ```

- Validate `local-path-provisioner`
  ```
  k0s kubectl get all -A -l app=local-path-provisioner
  ```

- Inspect the StorageClasses
  ```
  k0s kubectl get storageclass
  ```

### Containerd

- Add container registry credentials to Containerd
  ```
  export USERNAME="<username>"
  export PASSWORD="<password>"

  install --directory --owner=root --group=root --mode=0750 /etc/k0s/containerd.d

  cat <<EOF > /etc/k0s/containerd.d/registry-auth.toml
  version = 3

  [plugins."io.containerd.cri.v1.images".registry.configs."registry.liv.io".auth]
    username = "${USERNAME}"
    password = "${PASSWORD}"
  EOF
  ```

- Validate the `k0s` system
  ```
  k0s sysinfo | grep -v '(pass)'
  ```

### Traefik

- Install [Traefik](../../traefik/README.md#install)

### Calico

> [!NOTE]
>  Optional: Use Calico as Container Network Interface (CNI)

- Install, enable and start `nftables`
  ```
  apt -y --no-install-recommends install nftables
  systemctl enable nftables.service
  systemctl start nftables.service
  ```

- Modify configuration file
  ```
  yq -i '.spec.network.kubeProxy.mode = "nftables"' /etc/k0s/k0s.yaml
  yq -i '.spec.network.provider = "calico"' /etc/k0s/k0s.yaml
  ```

- Update the systemd unit file
  ```
  k0s install controller --config /etc/k0s/k0s.yaml --single --iptables-mode nft --profile=low-power --start --force
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

### Apps

- Deploy an application to k0s

> [!TIP]
>  See [Memos](../../memos/README.md) for a practical example

## Appendix

- [Calico](https://docs.tigera.io/calico)
- [Containerd](https://containerd.io)
- [Kine](https://github.com/k3s-io/kine)
- [Kube-Router](https://kube-router.io)
- [Traefik Ingress](https://github.com/k0sproject/k0s/blob/main/docs/examples/traefik-ingress.md)
- [Traefik](https://traefik.io/traefik)
- [k0s Configuration Options](https://github.com/k0sproject/k0s/blob/main/docs/configuration.md)
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner)
