# kustomize

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

- Download, verify and install `kustomize`
  ```
  export KUSTOMIZE_VERSION="5.8.1"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/kustomize/${KUSTOMIZE_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
      --output /usr/local/src/kustomize/${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/checksums.txt \
      --output /usr/local/src/kustomize/${KUSTOMIZE_VERSION}/checksums.txt

  cd /usr/local/src/kustomize/${KUSTOMIZE_VERSION}
  sha256sum --ignore-missing --check checksums.txt

  tar --extract --gzip --file=/usr/local/src/kustomize/${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz --directory=/usr/local/src/kustomize/${KUSTOMIZE_VERSION} --no-same-owner
  chmod +x kustomize
  ln -snf /usr/local/src/kustomize/${KUSTOMIZE_VERSION}/kustomize /usr/local/bin/kustomize
  ```

## Commands

## Appendix

- [kustomize](https://kustomize.io)
