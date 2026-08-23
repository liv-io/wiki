# kubesolo

> To infinity and beyond!

## Index

- [Install](#install)
  - [Debian](#debian)
  - [yq](#yq)
  - [helm](#helm)
  - [kustomize](#kustomize)
  - [kubectl](#kubectl)
  - [kubesoloctl](#kubesoloctl)
- [Config](#config)
  - [kubesolo](#kubesolo)
    - [Local-Path](#local-path)
    - [Traefik](#traefik)
- [Upgrade](#upgrade)
- [Commands](#commands)
- [Deploy](#deploy)
- [Appendix](#appendix)

## Install

### Debian

> [!NOTE]
> Debian stable minimal (`netinst`) + OpenSSH

- Install dependencies
  ```
  apt update
  apt install --no-install-recommends -y ca-certificates curl iptables
  ```

### yq

- Install [yq](../yq/README.md#install)

### helm

- Install [helm](../helm/README.md#install)

### kustomize

- Install [kustomize](../kustomize/README.md#install)

### kubectl

- Install [kubectl](../kubectl/README.md#install)

### kubesoloctl

- Install [kubesoloctl](../kubesoloctl/README.md#install)

## Config

### kubesolo

- Add http/https proxy settings
  ```
  install --directory --owner=root --group=root --mode=0755 /etc/systemd/system/kubesolo.service.d

  NO_PROXY_SYS="${NO_PROXY:-$no_proxy}"
  NO_PROXY_K8S=".svc,.cluster.local,10.42.0.0/16,10.43.0.0/16,10.244.0.0/16,10.96.0.0/12,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
  NO_PROXY_SUM="${NO_PROXY_SYS:+${NO_PROXY_SYS},}${NO_PROXY_K8S}"

  cat <<EOF > /etc/systemd/system/kubesolo.service.d/http-proxy.conf
  [Service]
  Environment="HTTP_PROXY=${HTTP_PROXY:-$http_proxy}"
  Environment="HTTPS_PROXY=${HTTPS_PROXY:-$https_proxy}"
  Environment="NO_PROXY=${NO_PROXY_SUM}"
  EOF

  systemctl daemon-reload
  ```

- Add `local-path-provisioner` configuration
  ```
  install --directory --owner=root --group=root --mode=0755 /opt/local-path-provisioner
  install --directory --owner=root --group=root --mode=0755 /etc/systemd/system/kubesolo.service.d

  cat <<EOF > /etc/systemd/system/kubesolo.service.d/override.conf
  [Service]
  Environment="KUBESOLO_NAME=$(hostname -s)"
  Environment="KUBESOLO_LOCAL_STORAGE_SHARED_PATH=/opt/local-path-provisioner"
  EOF

  systemctl daemon-reload
  ```

- Download and install offline `kubesolo`
  ```
  export KUBESOLO_VERSION="1.1.9"
  export KUBESOLO_CHECKSUM="407465105993fe8e863c138ccbb6b73688c0d10f3561aa023026516d28b6c612"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/kubesolo/${KUBESOLO_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/portainer/kubesolo/releases/download/v${KUBESOLO_VERSION}/kubesolo-v${KUBESOLO_VERSION}-linux-amd64-offline.tar.gz \
      --output /usr/local/src/kubesolo/${KUBESOLO_VERSION}/kubesolo-v${KUBESOLO_VERSION}-linux-amd64-offline.tar.gz

  cd /usr/local/src/kubesolo/${KUBESOLO_VERSION}
  echo "${KUBESOLO_CHECKSUM}  kubesolo-v${KUBESOLO_VERSION}-linux-amd64-offline.tar.gz" | sha256sum --check

  kubesoloctl install --offline-install /usr/local/src/kubesolo/${KUBESOLO_VERSION}/kubesolo-v${KUBESOLO_VERSION}-linux-amd64-offline.tar.gz
  ```

- Symlink `admin` kubeconfig
  ```
  install --directory --owner=root --group=root --mode=0700 /root/.kube
  ln -snf /var/lib/kubesolo/pki/admin/admin.kubeconfig /root/.kube/config
  ```

- Validate status of node
  ```
  kubectl get nodes
  kubectl get all -A
  ```

#### Traefik

- Install [traefik](../traefik/README.md#install)

## Upgrade

- Upgrade `kubesolo` to specific version
  ```
  kubesoloctl upgrade --version=v1.1.9
  ```

## Commands

## Deploy

- [Deploy](./deploy.md)

## Appendix

- [Traefik](https://traefik.io/traefik)
- [kubesolo](https://kubesolo.io)
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner)
