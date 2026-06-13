# Config

## Index

- [Debian](#debian)
- [k0s](#k0s)
  - [OpenEBS](#openebs)
  - [Containerd](#containerd)
  - [Traefik](#traefik)
  - [Container](#container)
- [Appendix](#appendix)

## Debian

- Install, enable and start `nftables`
  ```
  apt -y --no-install-recommends install nftables
  systemctl enable nftables.service
  systemctl start nftables.service
  ```

- Add http/https proxy settings
  ```
  install --directory --owner=root --group=root --mode=0755 /etc/systemd/system/k0scontroller.service.d

  cat <<EOF > /etc/systemd/system/k0scontroller.service.d/http-proxy.conf
  [Service]
  Environment="HTTP_PROXY=http://fp.liv.io:3128"
  Environment="HTTPS_PROXY=http://fp.liv.io:3128"
  Environment="NO_PROXY=NO_PROXY=localhost,127.0.0.1,::1,bs.liv.io,backup.liv.io,ca.liv.io,10.1.13.61,10.244.0.0/16,10.96.0.0/12,memos02.liv.io,.svc,.cluster.local"
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
  yq -i '.spec.extensions.storage.type = "openebs_local_storage"' /etc/k0s/k0s.yaml
  yq -i '.spec.network.dns.upstreamNameServers = [strenv(DNS)]' /etc/k0s/k0s.yaml
  yq -i '.spec.network.kubeProxy.mode = "nftables"' /etc/k0s/k0s.yaml
  yq -i '.spec.network.provider = "calico"' /etc/k0s/k0s.yaml
  yq -i '.spec.storage.type = "kine" | del(.spec.storage.etcd) | del(.spec.installConfig.users.etcdUser)' /etc/k0s/k0s.yaml
  ```

- Validate configuration file
  ```
  k0s config validate --config /etc/k0s/k0s.yaml
  ```

- Start and verify ncde
  ```
  k0s install controller --config /etc/k0s/k0s.yaml --single --iptables-mode nft --start

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

- Validate status of node
  ```
  k0s kubectl get nodes
  k0s kubectl get all -n kube-system
  ```

### OpenEBS

- todo
  ```
  export LOCAL_PATH_PROVISIONER_VERSION="0.0.36"

  git clone --single-branch --branch v${LOCAL_PATH_PROVISIONER_VERSION} https://github.com/rancher/local-path-provisioner.git
  k0s kubectl apply -f local-path-provisioner/deploy/local-path-storage.yaml
  k0s kubectl get all -n kube-system
  ```

- OpenEBS storage
  ```
  yq -i '.spec.extensions.storage.type = "openebs_local_storage"' /etc/k0s/k0s.yaml
  yq -i '.spec.extensions.storage.create_default_storage_class = true' /etc/k0s/k0s.yaml
  ```

- Restart k0s
  ```
  systemctl restart k0scontroller.service

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

- Validate the cluster storage classes
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
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.liv.io".auth]
    username = "${USERNAME}"
    password = "${PASSWORD}"
  EOF
  ```

### Traefik

### Container

## Appendix

- [Calico](https://docs.tigera.io/calico)
- [Containerd](https://containerd.io)
- [Kine](https://github.com/k3s-io/kine)
- [OpenEBS](https://openebs.io)
- [Traefik Ingress](https://github.com/k0sproject/k0s/blob/main/docs/examples/traefik-ingress.md)
- [Traefik](https://traefik.io/traefik)
- [k0s Configuration Options](https://github.com/k0sproject/k0s/blob/main/docs/configuration.md)
