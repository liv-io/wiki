# go

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

- Download, verify and install `go`
  ```
  export GO_VERSION="1.27.2"
  export GO_CHECKSUM="ecbadb99091a3f46e31f5f934b068b1864eafa7995211b39eaddf76996045fe5"

  rm -rf /usr/local/share/go

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/go/${GO_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
      --output /usr/local/src/go/${GO_VERSION}/go${GO_VERSION}.linux-amd64.tar.gz

  WORKDIR /usr/local/src/go
  RUN sha256sum --ignore-missing --check go${GO_VERSION}.linux-amd64.tar.gz.sha256

  tar --extract --gzip --file=/usr/local/src/go/${GO_VERSION}/go${GO_VERSION}.linux-amd64.tar.gz --directory=/usr/local/share

  cat <<EOF > /etc/profile.d/go.sh
  PATH=${PATH}:/usr/local/share/go/bin
  EOF

  source /etc/profile.d/go.sh

  go version
  ```

## Commands

## Appendix

- [go](https://go.dev)
