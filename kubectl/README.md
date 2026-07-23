# kubectl

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

- Download, verify and install `kubectl`
  ```
  export KUBECTL_VERSION="1.36.2"

  install --directory --owner=root --group=root --mode=0755 /usr/local/src/kubectl/${KUBECTL_VERSION}

  curl --proto '=https' --tlsv1.3 \
      --location https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
      --output /usr/local/src/kubectl/${KUBECTL_VERSION}/kubectl

  curl --proto '=https' --tlsv1.3 \
      --location https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256 \
      --output /usr/local/src/kubectl/${KUBECTL_VERSION}/kubectl.sha256

  cd /usr/local/src/kubectl/${KUBECTL_VERSION}
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

  chmod +x kubectl
  ln -snf /usr/local/src/kubectl/${KUBECTL_VERSION}/kubectl /usr/local/bin/kubectl
  ```

## Commands

## Appendix

- [kubectl](https://kubernetes.io/docs/tasks/tools)
