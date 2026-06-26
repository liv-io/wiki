# k0s

> To infinity and beyond!

## Index

- [Install](#install)
  - [Debian](#debian)
  - [Cosign](#cosign)
  - [yq](#yq)
  - [Helm](#helm)
  - [k0s](#k0s)
  - [k0sctl](#k0sctl)
  - [kustomize](#kustomize)
- [Config](#config)
- [Upgrade](#upgrade)
- [Commands](#commands)
- [Appendix](#appendix)

## Install

### Debian

> [!NOTE]
> Debian stable minimal (`netinst`) + OpenSSH

- Install dependencies
  ```
  apt update
  apt install --no-install-recommends -y ca-certificates curl
  ```

### Cosign

- Install [Cosign](../cosign/README.md#install)

### yq

- Install [yq](../yq/README.md#install)

### Helm

- Install [Helm](../helm/README.md#install)

### k0sctl

- Install [k0sctl](../k0sctl/README.md#install)

### kustomize

- Install [kustomize](../kustomize/README.md#install)

### k0s

- Download, verify and install `k0s`
  ```
  export K0S_VERSION="1.36.1+k0s.0"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/k0s/${K0S_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/k0s-v${K0S_VERSION}-amd64 \
      --output /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/k0s-v${K0S_VERSION}-amd64.sig \
      --output /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64.sig
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/cosign.pub \
      --output /usr/local/src/k0s/${K0S_VERSION}/cosign.pub
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/sha256sums.txt \
      --output /usr/local/src/k0s/${K0S_VERSION}/sha256sums.txt

  cosign verify-blob \
      --key /usr/local/src/k0s/${K0S_VERSION}/cosign.pub \
      --signature /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64.sig \
      /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64
  cd /usr/local/src/k0s/${K0S_VERSION}
  sha256sum --ignore-missing --check sha256sums.txt

  chmod +x /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64
  ln -snf /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64 /usr/local/bin/k0s
  ```

## Config

- [Single Node](./config/single.md)
- [Multi Node](./config/multi.md)

## Upgrade

## Commands

- [Commands](./commands.md)

## Appendix

- [k0s](https://k0sproject.io)
