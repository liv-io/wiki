# ctr

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

- Download, verify and install `ctr`
  ```
  export CTR_VERSION="1.7.34"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/ctr/${CTR_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/containerd/containerd/releases/download/v${CTR_VERSION}/containerd-${CTR_VERSION}-linux-amd64.tar.gz \
      --output /usr/local/src/ctr/${CTR_VERSION}/containerd-${CTR_VERSION}-linux-amd64.tar.gz
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/containerd/containerd/releases/download/v${CTR_VERSION}/containerd-${CTR_VERSION}-linux-amd64.tar.gz.sha256sum \
      --output /usr/local/src/ctr/${CTR_VERSION}/containerd-${CTR_VERSION}-linux-amd64.tar.gz.sha256sum

  cd /usr/local/src/ctr/${CTR_VERSION}
  sha256sum --ignore-missing --check containerd-${CTR_VERSION}-linux-amd64.tar.gz.sha256sum

  tar --extract --gzip --strip-components=1 --file=/usr/local/src/ctr/${CTR_VERSION}/containerd-${CTR_VERSION}-linux-amd64.tar.gz --directory=/usr/local/src/ctr/${CTR_VERSION} --no-same-owner
  chmod +x /usr/local/src/ctr/${CTR_VERSION}/ctr
  ln -snf /usr/local/src/ctr/${CTR_VERSION}/ctr /usr/local/bin/ctr
  ```

## Commands

## Appendix

- [ctr](https://containerd.io)
