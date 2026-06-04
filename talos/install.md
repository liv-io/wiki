# Install

## Index

- [Client](#client)
  - [Cosign](#cosign)
  - [yq](#yq)
  - [talosctl](#talosctl)
- [Talos](#talos)
- [yq](#yq)
- [Appendix](#appendix)

## Client

- Install dependencies
  ```
  apt update
  apt install --no-install-recommends -y ca-certificates curl
  ```

### Cosign

- Download, verify and install `cosign`
  ```
  export COSIGN_VERSION="3.0.6"
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

### yq

- Download, verify and install `yq`
  ```
  export YQ_VERSION="4.53.2"
  install --directory --owner=root --group=root --mode=0755 /usr/local/src/yq/${YQ_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/checksums \
      --output /usr/local/src/yq/${YQ_VERSION}/checksums
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/checksums.bundle \
      --output /usr/local/src/yq/${YQ_VERSION}/checksums.bundle
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 \
      --output /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64

  cosign verify-blob \
      --bundle /usr/local/src/yq/${YQ_VERSION}/checksums.bundle \
      --certificate-identity-regexp '^https://github.com/mikefarah/yq' \
      --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
      /usr/local/src/yq/${YQ_VERSION}/checksums

  cd /usr/local/src/yq/${YQ_VERSION}
  grep "^yq_linux_amd64" checksums | grep -q "$(sha256sum yq_linux_amd64 | awk '{print $1}')" && echo "yq_linux_amd64: OK" || echo "yq_linux_amd64: FAILED"

  chmod +x /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64
  ln -snf /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
  ```

### talosctl

- Download, verify and install `talosctl`
  ```
  export TALOS_VERSION="1.13.3"
  install --directory --owner=root --group=root --mode=0755 /usr/local/src/talosctl/${TALOS_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/siderolabs/talos/releases/download/v${TALOS_VERSION}/sha256sum.txt \
      --output /usr/local/src/talosctl/${TALOS_VERSION}/sha256sum.txt
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/siderolabs/talos/releases/download/v${TALOS_VERSION}/sha256sum.txt.bundle \
      --output /usr/local/src/talosctl/${TALOS_VERSION}/sha256sum.txt.bundle
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/siderolabs/talos/releases/download/v${TALOS_VERSION}/talosctl-linux-amd64 \
      --output /usr/local/src/talosctl/${TALOS_VERSION}/talosctl-linux-amd64

  cosign verify-blob \
      --bundle /usr/local/src/talosctl/${TALOS_VERSION}/sha256sum.txt.bundle \
      --certificate-identity-regexp '^https://github.com/siderolabs/talos' \
      --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
      /usr/local/src/talosctl/${TALOS_VERSION}/sha256sum.txt

  cd /usr/local/src/talosctl/${TALOS_VERSION}
  sha256sum --ignore-missing --check sha256sum.txt

  chmod +x /usr/local/src/talosctl/${TALOS_VERSION}/talosctl-linux-amd64
  ln -snf /usr/local/src/talosctl/${TALOS_VERSION}/talosctl-linux-amd64 /usr/local/bin/talosctl
  ```

## Talos

> [!NOTE]
> Boot Talos ISO image and apply network config

## Appendix

- [Cosign](https://github.com/sigstore/cosign)
- [Talos](https://github.com/siderolabs/talos)
- [talosctl](https://github.com/siderolabs/talos)
- [yq](https://github.com/mikefarah/yq)
