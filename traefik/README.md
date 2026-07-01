# Traefik

## Index

- [Install](#install)
- [Config](#config)
  - [TLS Optons](#tls-options)
- [Upgrade](#upgrade)
- [Commands](#commands)
- [Appendix](#appendix)

### Install

- Create the infra deployment directory for Traefik
  ```
  install --directory --owner=root --group=root --mode=0750 ./infra/traefik
  ```

- Copy (or symlink) root CA certificate
  ```
  cp /usr/local/share/ca-certificates/ca1.liv.io.crt ./infra/traefik/
  ```

- Create the Traefik `kustomization.yaml`
  ```
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
            value: "http://fp.liv.io:3128"
          - name: HTTPS_PROXY
            value: "http://fp.liv.io:3128"
          - name: NO_PROXY
            value: "localhost,127.0.0.1,::1,bs.liv.io,backup.liv.io,ca.liv.io,10.1.13.61,10.244.0.0/16,10.96.0.0/12,memos02.liv.io,.svc,.cluster.local"
  EOF
  ```

- Render manifest
  ```
  kustomize build ./infra/traefik/ --enable-helm | k0s kubectl apply --dry-run=client -f -
  kustomize build ./infra/traefik/ --enable-helm | k0s kubectl apply --dry-run=server -f -
  ```

- Apply manifest
  ```
  kustomize build ./infra/traefik/ --enable-helm | k0s kubectl apply -f -
  ```

- Verify deployment rollout status
  ```
  k0s kubectl rollout status -n kube-system deployment/traefik
  ```

- Validate Traefik
  ```
  k0s kubectl get all -n kube-system -l app.kubernetes.io/name=traefik
  ```

- Inspect logs
  ```
  k0s kubectl logs -n kube-system deployment/traefik --tail=100 -f
  ```

- Enable dashboard ad-hoc
  ```
  k0s kubectl port-forward -n kube-system deployment/traefik 8080:8080
  ```

## Config

### TLS Options

- Get the Traefik version
  ```
  k0s kubectl get all -A -l app.kubernetes.io/name=traefik -o jsonpath='{.items[*].spec.containers[*].image}'
  ```

- Apply the Traefik Custom Resource Definition (CRD) and Role-Based Access Control (RBAC)
  ```
  export TRAEFIK_VERSION="3.7.5"

  k0s kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/refs/tags/v${TRAEFIK_VERSION}/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

  k0s kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v${TRAEFIK_VERSION}/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
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
  k0s kubectl apply -f ./infra/traefik/tlsconfig.yaml
  ```

- Check for Post-Quantum Cryptography (PQC) support
  ```
  openssl s_client -connect host.domain.tld:443 -tls1_3 -groups "X25519MLKEM768" -brief
  ```

## Upgrade

- List Traefik version
  ```
  k0s kubectl get all -A -l app.kubernetes.io/name=traefik -o jsonpath='{.items[*].spec.containers[*].image}'
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
  kustomize build ./infra/traefik/ --enable-helm | k0s kubectl apply -f -
  ```

- Verify deployment rollout status
  ```
  k0s kubectl rollout status -n kube-system deployment/traefik
  ```

- Validate Traefik
  ```
  k0s kubectl get all -n kube-system -l app.kubernetes.io/name=traefik
  ```

- List Traefik version
  ```
  k0s kubectl get all -A -l app.kubernetes.io/name=traefik -o jsonpath='{.items[*].spec.containers[*].image}'
  ```

- Optional: Force delete the old pod
  ```
  k0s kubectl rollout restart deployment/traefik -n kube-system
  ```

## Appendix

- [Traefik Ingress](https://github.com/k0sproject/k0s/blob/main/docs/examples/traefik-ingress.md)
- [Traefik](https://traefik.io/traefik)
