# k0sctl

## Index

- [Install](#install)
- [Commands](#commands)
- [Appendix](#appendix)

## Install

- Install dependencies
  ```
  apt update
  apt install --no-install-recommends -y ca-certificates curl
  ```

## k0sctl

- Download, verify and install `k0sctl`
  ```
  export K0SCTL_VERSION="0.30.1"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/k0sctl/${K0SCTL_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0sctl/releases/download/v${K0SCTL_VERSION}/checksums.txt \
      --output /usr/local/src/k0sctl/${K0SCTL_VERSION}/checksums.txt
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0sctl/releases/download/v${K0SCTL_VERSION}/k0sctl-linux-amd64 \
      --output /usr/local/src/k0sctl/${K0SCTL_VERSION}/k0sctl-linux-amd64

  cd /usr/local/src/k0sctl/${K0SCTL_VERSION}
  sha256sum --ignore-missing --check checksums.txt

  chmod +x /usr/local/src/k0sctl/${K0SCTL_VERSION}/k0sctl-linux-amd64
  ln -snf /usr/local/src/k0sctl/${K0SCTL_VERSION}/k0sctl-linux-amd64 /usr/local/bin/k0sctl
  ```

## Commands

## Appendix

- [k0sctl](https://github.com/k0sproject/k0sctl)
