# yq

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

- Download, verify and install `yq`
  ```
  export YQ_VERSION="4.53.3"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/yq/${YQ_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64.tar.gz \
      --output /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64.tar.gz

  tar --extract --gzip --file=/usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64.tar.gz --directory=/usr/local/src/yq/${YQ_VERSION} --no-same-owner

  chmod +x /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64
  ln -snf /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
  ```

## Commands

## Appendix

- [yq](https://github.com/mikefarah/yq)
