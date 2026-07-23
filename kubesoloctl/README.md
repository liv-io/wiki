# kubesoloctl

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

- Download, verify and install `kubesoloctl`
  ```
  export KUBESOLOCTL_VERSION="1.1.9"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/kubesoloctl/${KUBESOLOCTL_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/portainer/kubesolo/releases/download/v${KUBESOLOCTL_VERSION}/kubesoloctl-linux-amd64 \
      --output /usr/local/src/kubesoloctl/${KUBESOLOCTL_VERSION}/kubesoloctl-linux-amd64

  chmod +x /usr/local/src/kubesoloctl/${KUBESOLOCTL_VERSION}/kubesoloctl-linux-amd64
  ln -snf /usr/local/src/kubesoloctl/${KUBESOLOCTL_VERSION}/kubesoloctl-linux-amd64 /usr/local/bin/kubesoloctl
  ```

## Commands

## Appendix

- [kubesolo](https://kubesolo.io)
