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

  cat <<EOF > /etc/systemd/system/kubesolo.service.d/http-proxy.conf
  [Service]
  Environment="HTTP_PROXY=http://fp.liv.io:3128"
  Environment="HTTPS_PROXY=http://fp.liv.io:3128"
  Environment="NO_PROXY=localhost,127.0.0.1,::1,bs.liv.io,backup.liv.io,ca.liv.io,10.1.13.43,10.42.0.0/16,10.43.0.0/16,10.244.0.0/16,10.96.0.0/12,example.liv.io,.svc,.cluster.local"
  EOF

  systemctl daemon-reload
  ```

- Add `local-path-provisioner` configuration
  ```
  install --directory --owner=root --group=root --mode=0755 /opt/local-path-provisioner
  install --directory --owner=root --group=root --mode=0755 /etc/systemd/system/kubesolo.service.d

  cat <<EOF > /etc/systemd/system/kubesolo.service.d/override.conf
  [Service]
  Environment="KUBESOLO_LOCAL_STORAGE_SHARED_PATH=/opt/local-path-provisioner"
  EOF

  systemctl daemon-reload
  ```

- Run system pre-flight
  ```
  kubesoloctl check
  ```

- Install `kubesolo`
  ```
  kubesoloctl install
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

- Install [Traefik](../../traefik/README.md#install)

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
