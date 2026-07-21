# Cosign

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

- Download, verify and install `cosign`
  ```
  export COSIGN_VERSION="3.1.2"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/cosign/${COSIGN_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64 \
      --output /usr/local/src/cosign/${COSIGN_VERSION}/cosign-linux-amd64
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64.sigstore.json \
      --output /usr/local/src/cosign/${COSIGN_VERSION}/cosign-linux-amd64.sigstore.json

  chmod +x /usr/local/src/cosign/${COSIGN_VERSION}/cosign-linux-amd64
  ln -s /usr/local/src/cosign/${COSIGN_VERSION}/cosign-linux-amd64 /usr/local/bin/cosign

  cosign verify-blob \
      --bundle /usr/local/src/cosign/${COSIGN_VERSION}/cosign-linux-amd64.sigstore.json \
      --certificate-identity keyless@projectsigstore.iam.gserviceaccount.com \
      --certificate-oidc-issuer https://accounts.google.com \
      /usr/local/src/cosign/${COSIGN_VERSION}/cosign-linux-amd64
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign_checksums.txt \
      --output /usr/local/src/cosign/${COSIGN_VERSION}/cosign_checksums.txt
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign_checksums.txt.sigstore.json \
      --output /usr/local/src/cosign/${COSIGN_VERSION}/cosign_checksums.txt.sigstore.json

  cosign verify-blob \
      --bundle /usr/local/src/cosign/${COSIGN_VERSION}/cosign_checksums.txt.sigstore.json \
      --certificate-identity keyless@projectsigstore.iam.gserviceaccount.com \
      --certificate-oidc-issuer https://accounts.google.com \
      /usr/local/src/cosign/${COSIGN_VERSION}/cosign_checksums.txt

  cd /usr/local/src/cosign/${COSIGN_VERSION}
  sha256sum --ignore-missing --check cosign_checksums.txt
  ```

## Commands

## Appendix

- [Cosign](https://github.com/sigstore/cosign)
