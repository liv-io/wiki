# Install

## Index

- [Debian](#debian)
- [Cosign](#cosign)
- [k0s](#k0s)
- [k0sctl](#k0sctl)
- [Appendix](#appendix)

## Debian

> [!NOTE]
> Debian stable minimal (`netinst`) + OpenSSH

- Install dependencies
```
apt update
apt install --no-install-recommends -y ca-certificates curl tar
```

- Install `yq` (written in Go)
  ```
  export YQ_VERSION="4.53.2"
  install --directory --owner=root --group=root --mode=0755 /usr/local/src/yq/${YQ_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64.tar.gz \
      --output /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64.tar.gz

  tar --extract --gzip --file=/usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64.tar.gz --directory=/usr/local/src/yq/${YQ_VERSION} --no-same-owner

  chmod +x /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64
  ln -snf /usr/local/src/yq/${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
  ```

## Cosign

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

## k0s

- Download, verify and install `k0s`
  ```
  export K0S_VERSION="1.35.4+k0s.0"
  install --directory --owner=root --group=root --mode=0755 /usr/local/src/k0s/${K0S_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/k0s-v${K0S_VERSION}-amd64 \
      --output /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/k0s-v${K0S_VERSION}-amd64.sig \
      --output /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64.sig
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/cosign.pub \
      --output /usr/local/src/k0s/${K0S_VERSION}/cosign.pub
  curl --proto '=https' --tlsv1.3 \
      --location https://github.com/k0sproject/k0s/releases/download/v${K0S_VERSION//+/%2B}/sha256sums.txt \
      --output /usr/local/src/k0s/${K0S_VERSION}/sha256sums.txt

  cosign verify-blob \
      --key /usr/local/src/k0s/${K0S_VERSION}/cosign.pub \
      --signature /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64.sig \
      /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64
  cd /usr/local/src/k0s/${K0S_VERSION}
  sha256sum --ignore-missing --check sha256sums.txt

  chmod +x /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64
  ln -snf /usr/local/src/k0s/${K0S_VERSION}/k0s-v${K0S_VERSION}-amd64 /usr/local/bin/k0s
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
      --location https://github.com/k0sproject/k0sctl/releases/download/v${K0SCTL_VERSION}/k0sctl-linux-arm64 \
      --output /usr/local/src/k0sctl/${K0SCTL_VERSION}/k0sctl-linux-arm64

  cd /usr/local/src/k0sctl/${K0SCTL_VERSION}
  sha256sum --ignore-missing --check checksums.txt

  chmod +x /usr/local/src/k0sctl/${K0SCTL_VERSION}/k0sctl-linux-arm64
  ln -snf /usr/local/src/k0sctl/${K0SCTL_VERSION}/k0sctl-linux-arm64 /usr/local/bin/k0sctl
  ```

## Appendix

- [cosign](https://github.com/sigstore/cosign)
- [k0s](https://github.com/k0sproject/k0s)
- [k0sctl](https://github.com/k0sproject/k0sctl)
