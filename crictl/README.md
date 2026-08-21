# crictl

## Index

- [Install](#install)
- [Commands](#commands)
- [Appendix](#appendix)

## Install

- Install dependencies
  ```
  apt update
  apt install --no-install-recommends -y ca-certificates curl tar
  ```

- Download, verify and install `crictl`
  ```
  export CRICTL_VERSION="1.36.0"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/crictl/${CRICTL_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz \
      --output /usr/local/src/crictl/${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz.sha256 \
      --output /usr/local/src/crictl/${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz.sha256

  cd /usr/local/src/crictl/${CRICTL_VERSION}
  echo "$(cat crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz.sha256)  crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz" | sha256sum --check -

  tar --extract --gzip --file=/usr/local/src/crictl/${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz --directory=/usr/local/src/crictl/${CRICTL_VERSION} --no-same-owner
  chmod +x /usr/local/src/crictl/${CRICTL_VERSION}/crictl
  ln -snf /usr/local/src/crictl/${CRICTL_VERSION}/crictl /usr/local/bin/crictl
  ```

## Commands

## Appendix

- [crictl](https://github.com/kubernetes-sigs/cri-tools)
