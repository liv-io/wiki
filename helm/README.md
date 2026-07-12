# Helm

## Index

- [Install](#install)
- [Commands](#commands)
- [Appendix](#appendix)

## Install

- Install dependencies
  ```
  apt update
  apt install --no-install-recommends -y ca-certificates curl gpg tar
  ```

- Download, verify and install `helm`
  ```
  export HELM_VERSION="4.2.3"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/helm/${HELM_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
      --output /usr/local/src/helm/${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz
  curl --proto '=https' --tlsv1.3 \
      --location https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256 \
      --output /usr/local/src/helm/${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/helm/helm/releases/download/v${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.asc \
      --output /usr/local/src/helm/${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.asc
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/helm/helm/releases/download/v${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256.asc \
      --output /usr/local/src/helm/${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256.asc
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/helm/helm/releases/download/v${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum.asc \
      --output /usr/local/src/helm/${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum.asc
  curl --proto '=https' --tlsv1.3 \
      --location https://raw.githubusercontent.com/helm/helm/refs/tags/v${HELM_VERSION}/KEYS \
      --output /usr/local/src/helm/${HELM_VERSION}/KEYS

  cd /usr/local/src/helm/${HELM_VERSION}
  gpg --import KEYS
  gpg --verify helm-v${HELM_VERSION}-linux-amd64.tar.gz.asc helm-v${HELM_VERSION}-linux-amd64.tar.gz
  gpg --verify helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256.asc helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256
  echo "$(cat helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256)  helm-v${HELM_VERSION}-linux-amd64.tar.gz" | sha256sum --check -

  tar --extract --gzip --file=/usr/local/src/helm/${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz --directory=/usr/local/src/helm/${HELM_VERSION} --no-same-owner
  chmod +x /usr/local/src/helm/${HELM_VERSION}/linux-amd64/helm
  ln -snf /usr/local/src/helm/${HELM_VERSION}/linux-amd64/helm /usr/local/bin/helm
  ```

## Commands

## Appendix

- [Helm](https://helm.sh)
