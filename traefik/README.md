# Traefik

## Index

- [Install](#install)
- [Config](#config)
  - [TLS Optons](#tls-options)
- [Upgrade](#upgrade)
- [Commands](#commands)
- [Appendix](#appendix)

### Install

- Create GitOps repository
  ```
  git init example-env
  cd ./example-env/
  ```

- Rename `master` branch to `main`
  ```
  git branch -m main
  ```

- Create GitOps directory structure
  ```
  install --directory --mode=0755 ./infra
  ```

- Create the infra deployment directory for Traefik
  ```
  install --directory --mode=0750 ./infra/traefik
  ```

- Copy (or symlink) root CA certificate
  ```
  cp /usr/local/share/ca-certificates/ca1.liv.io.crt ./infra/traefik/
  ```

- Create the Traefik `kustomization.yaml`
  ```
  NO_PROXY_SYS="${NO_PROXY:-$no_proxy}"
  NO_PROXY_K8S=".svc,.cluster.local,10.42.0.0/16,10.43.0.0/16,10.244.0.0/16,10.96.0.0/12,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
  NO_PROXY_SUM="${NO_PROXY_SYS:+${NO_PROXY_SYS},}${NO_PROXY_K8S}"

  cat <<EOF > ./infra/traefik/kustomization.yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization

  generatorOptions:
    disableNameSuffixHash: true

  configMapGenerator:
    - name: internal-ca-cert
      namespace: kube-system
      files:
        - ca1.liv.io.crt

  helmCharts:
    - name: traefik
      repo: https://traefik.github.io/charts
      version: 41.0.1
      releaseName: traefik
      namespace: kube-system
      valuesInline:
        updateStrategy:
          type: Recreate

        deployment:
          kind: Deployment
          replicas: 1
          initContainers:
            - name: volume-permissions
              image: busybox:1.36
              command: ["sh", "-c", "touch /data/acme.json && chmod -v 600 /data/acme.json && chown -v 65532:65532 /data/acme.json"]
              securityContext:
                runAsNonRoot: false
                runAsGroup: 0
                runAsUser: 0
              volumeMounts:
                - name: data
                  mountPath: /data

        providers:
          kubernetesIngress:
            publishedService:
              enabled: false
          kubernetesCRD:
            enabled: true

        ports:
          web:
            hostPort: 80
            http:
              redirections:
                entryPoint:
                  to: websecure
                  scheme: https
                  permanent: true
          websecure:
            hostPort: 443

        persistence:
          enabled: true
          storageClass: local-path
          size: 128Mi

        volumes:
          - name: internal-ca-cert
            mountPath: /etc/traefik/ca
            type: configMap

        certificatesResolvers:
          myresolver:
            acme:
              email: admin@liv.io
              caServer: https://ca.liv.io/acme/acme/directory
              storage: /data/acme.json
              httpChallenge:
                entryPoint: web

        env:
          - name: LEGO_CA_CERTIFICATES
            value: /etc/traefik/ca/ca1.liv.io.crt
          - name: HTTP_PROXY
            value: "${HTTP_PROXY:-$http_proxy}"
          - name: HTTPS_PROXY
            value: "${HTTPS_PROXY:-$https_proxy}"
          - name: NO_PROXY
            value: "${NO_PROXY_SUM}"
  EOF
  ```

- Render manifest
  ```
  kustomize build ./infra/traefik/ --enable-helm | kubectl apply --dry-run=client -f -
  kustomize build ./infra/traefik/ --enable-helm | kubectl apply --dry-run=server -f -
  ```

- Apply manifest
  ```
  kustomize build ./infra/traefik/ --enable-helm | kubectl apply -f -
  ```

- Verify deployment rollout status
  ```
  kubectl rollout status -n kube-system deployment/traefik
  ```

- Validate Traefik
  ```
  kubectl get all -n kube-system -l app.kubernetes.io/name=traefik
  ```

- Get the `traefik` image version
  ```
  kubectl get deployment traefik -n kube-system -o jsonpath='{.spec.template.spec.containers[*].image}'
  ```

- Inspect logs
  ```
  kubectl logs -n kube-system deployment/traefik --tail=100 -f
  ```

- Enable dashboard ad-hoc
  ```
  kubectl port-forward -n kube-system deployment/traefik 8080:8080
  ```

## Config

### TLS Options

- Apply the Traefik Custom Resource Definition (CRD) and Role-Based Access Control (RBAC)
  ```
  export TRAEFIK_VERSION="3.7.6"

  kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/refs/tags/v${TRAEFIK_VERSION}/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

  kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v${TRAEFIK_VERSION}/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
  ```

- Create the `tlsoptions.yaml` configuration file

  ```
  cat <<EOF > ./infra/traefik/tlsconfig.yaml
  apiVersion: traefik.io/v1alpha1
  kind: TLSOption

  metadata:
    name: default
    namespace: kube-system

  spec:
    minVersion: VersionTLS12
    maxVersion: VersionTLS13
    cipherSuites:
      - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
      - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    curvePreferences:
      - X25519MLKEM768
      - X25519
      - CurveP521
      - CurveP384
    sniStrict: true
  EOF
  ```

- Apply the `tlsoptions.yaml` configuration
  ```
  kubectl apply -f ./infra/traefik/tlsconfig.yaml
  ```

- Check for Post-Quantum Cryptography (PQC) support
  ```
  openssl s_client -connect host.domain.tld:443 -tls1_3 -groups "X25519MLKEM768" -brief
  ```

## Upgrade

- Get the `traefik` image version
  ```
  kubectl get deployment traefik -n kube-system -o jsonpath='{.spec.template.spec.containers[*].image}'
  ```

- Update the Traefik `kustomization.yaml`
  ```
  ...

   helmCharts:
     - name: traefik
       repo: https://traefik.github.io/charts
  -   version: 41.0.0
  +   version: 41.0.1
  ```

- Apply manifest
  ```
  kustomize build ./infra/traefik/ --enable-helm | kubectl apply -f -
  ```

- Verify deployment rollout status
  ```
  kubectl rollout status -n kube-system deployment/traefik
  ```

- Validate Traefik
  ```
  kubectl get all -n kube-system -l app.kubernetes.io/name=traefik
  ```

- Get the `traefik` image version
  ```
  kubectl get deployment traefik -n kube-system -o jsonpath='{.spec.template.spec.containers[*].image}'
  ```

- Optional: Force delete the old pod
  ```
  kubectl rollout restart -n kube-system deployment/traefik
  ```

## Appendix

- [Traefik Helm Chart](https://github.com/traefik/traefik-helm-chart)
- [Traefik Ingress](https://github.com/k0sproject/k0s/blob/main/docs/examples/traefik-ingress.md)
- [Traefik](https://traefik.io/traefik)
