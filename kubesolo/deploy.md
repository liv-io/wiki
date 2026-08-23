# Deploy

## Index

- [Deploy](#deploy)
  - [Git](#git)
  - [Bootstrap](#bootstrap)
  - [Infra](#infra)
  - [Apps](#apps)
  - [Pipeline](#pipeline)
- [Commands](#commands)
- [Appendix](#appendix)

## Deploy

### Git

- Create GitOps repository
  ```
  git init example-env
  cd ./example-env/
  ```

- Rename `master` branch to `main`
  ```
  git branch -m main
  sed -i 's@master@main@g' .git/config
  ```

- Create GitOps directory structure
  ```
  install --directory --mode=0755 ./bootstrap ./apps ./infra ./.woodpecker
  ```

#### Bootstrap

- Create `example` namespace file
  ```
  cat <<EOF > ./bootstrap/namespace.yaml
  apiVersion: v1
  kind: Namespace

  metadata:
    name: example
  EOF
  ```

- Create `infra` service account
  ```
  cat <<EOF > ./bootstrap/infra-rbac.yaml
  apiVersion: v1
  kind: ServiceAccount

  metadata:
    name: infra-deployer
    namespace: kube-system

  ---

  apiVersion: v1
  kind: Secret

  metadata:
    name: infra-deployer-token
    namespace: kube-system
    annotations:
      kubernetes.io/service-account.name: infra-deployer

  type: kubernetes.io/service-account-token

  ---

  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding

  metadata:
    name: infra-deployer-binding

  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin

  subjects:
  - kind: ServiceAccount
    name: infra-deployer
    namespace: kube-system
  EOF
  ```

- Create `example` service account
  ```
  cat <<EOF > ./bootstrap/example-rbac.yaml
  apiVersion: v1
  kind: ServiceAccount

  metadata:
    name: example-deployer
    namespace: example

  ---

  apiVersion: v1
  kind: Secret

  metadata:
    name: example-deployer-token
    namespace: example
    annotations:
      kubernetes.io/service-account.name: example-deployer

  type: kubernetes.io/service-account-token

  ---

  apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding

  metadata:
    name: example-deployer-binding
    namespace: example

  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: admin

  subjects:
  - kind: ServiceAccount
    name: example-deployer
    namespace: example
  EOF
  ```

- Create main Kustomize file
  ```
  cat <<EOF > ./bootstrap/kustomization.yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization

  resources:
    - namespace.yaml
    - infra-rbac.yaml
    - example-rbac.yaml
  EOF
  ```

- Create script to generate service account secrets
  ```
  curl --proto '=https' --tlsv1.3 \
      --location https://raw.githubusercontent.com/liv-io/wiki/refs/heads/main/kubesolo/generate-kubeconfig.sh \
      --output ./bootstrap/generate-kubeconfig.sh
  ```

- Apply `example` namespace
  ```
  kubectl apply -f ./bootstrap/namespace.yaml
  ```

- Add container registry secret to `example` namespace
  ```
  kubectl create secret docker-registry registry.liv.io \
      --docker-server="registry.liv.io" \
      --docker-username="<username>" \
      --docker-password="<password>" \
      --namespace=example
  ```

#### Infra

- Install [traefik](../traefik/README.md#install)

#### Apps

- Create `example` apps directory
  ```
  install --directory --mode=0750 ./apps/example
  ```

- Create Kustomize `deployment.yaml` file
  ```
  cat <<EOF > ./apps/example/deployment.yaml
  apiVersion: apps/v1
  kind: Deployment

  metadata:
    name: example

  spec:
    replicas: 1
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
    selector:
      matchLabels:
        app: example
    template:
      metadata:
        labels:
          app: example
      spec:
        containers:
        - name: example
          image: registry.liv.io/liv/example
          workingDir: /
          ports:
          - name: example-http
            containerPort: 8080
            protocol: TCP
          env:
          - name: PORT
            value: '8080'
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - ALL
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsGroup: 10000
            runAsUser: 10000
            seLinuxOptions:
              type: spc_t
        imagePullSecrets:
        - name: registry.liv.io
  EOF
  ```

- Create Kustomize `ingress.yaml` file
  ```
  cat <<EOF > ./apps/example/ingress.yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress

  metadata:
    name: example-ingress
    annotations:
      traefik.ingress.kubernetes.io/router.tls: "true"
      traefik.ingress.kubernetes.io/router.tls.certresolver: "myresolver"
      traefik.ingress.kubernetes.io/router.entrypoints: "websecure"

  spec:
    ingressClassName: traefik
    tls:
      - hosts:
          - example.liv.io
    rules:
    - host: example.liv.io
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: example
              port:
                number: 8080
  EOF
  ```

- Create Kustomize `service.yaml` file
  ```
  cat <<EOF > ./apps/example/service.yaml
  apiVersion: v1
  kind: Service

  metadata:
    name: example

  spec:
    type: ClusterIP
    ports:
    - port: 8080
      targetPort: example-http
      protocol: TCP
      name: http
    selector:
      app: example
  EOF
  ```

- Create Kustomize `kustomization.yaml` file
  ```
  cat <<EOF > ./apps/example/kustomization.yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization

  namespace: example

  resources:
    - service.yaml
    - deployment.yaml
    - ingress.yaml

  images:
    - name: registry.liv.io/liv/example
      newTag: 0.1.1-1
  EOF
  ```

- Render manifest
  ```
  kustomize build ./apps/example/
  kubectl kustomize ./apps/example/
  ```

- Run the client-side schema validation
  ```
  kubectl apply -k ./apps/example/ --dry-run=client
  ```

- Create `example` namespace from manifest for running the server-side schema validation
  ```
  kubectl apply -k ./apps/example/ --dry-run=server
  ```

- Apply manifest
  ```
  kubectl apply -k ./apps/example/
  ```

- Verify deployment rollout status
  ```
  kubectl rollout status -n example deployment/example
  ```

- Validate application
  ```
  kubectl get all -n example
  ```

- Inspect logs
  ```
  kubectl logs -n example deployment/example --tail=100 -f
  ```

- Show detailed description
  ```
  kubectl describe pod -n example
  ```

- Query TLS encrypted endpoint
  ```
  curl --noproxy "*" https://example.liv.io
  ```

#### Pipeline

- Apply service accounts
  ```
  kubectl apply -k ./bootstrap/
  ```

- Generate service account secrets
  ```
  ./bootstrap/generate-kubeconfig.sh infra
  ./bootstrap/generate-kubeconfig.sh example
  ```

- Create `traefik` pipeline
  ```
  cat <<EOF > ./.woodpecker/traefik.yaml
  when:
    - path:
        include:
          - '.woodpecker/traefik.yaml'
          - 'infra/traefik/**'

  clone:
    - name: git
      image: woodpeckerci/plugin-git
      volumes:
        - custom-ca-certs:/etc/ssl/certs/custom:ro
      settings:
        custom_ssl_path: /etc/ssl/certs/custom/ca1.liv.io.crt

  steps:
    - name: lint
      image: registry.liv.io/liv/k8s-ops:1.36.2-2
      environment:
        KUBECONFIG_DATA:
          from_secret: infra-deployer
      commands:
        - install --owner=k8s --group=k8s --mode=0600 /dev/null ~/.kubeconfig
        - echo "$${KUBECONFIG_DATA}" > ~/.kubeconfig
        - export KUBECONFIG=~/.kubeconfig

        - kustomize build ./infra/traefik/ --enable-helm | kubectl apply --dry-run=client -f -
        - kustomize build ./infra/traefik/ --enable-helm | kubectl apply --dry-run=server -f -

    - name: deploy
      image: registry.liv.io/liv/k8s-ops:1.36.2-2
      environment:
        KUBECONFIG_DATA:
          from_secret: infra-deployer
      when:
        - event: push
          branch: main
      commands:
        - install --owner=k8s --group=k8s --mode=0600 /dev/null ~/.kubeconfig
        - echo "$${KUBECONFIG_DATA}" > ~/.kubeconfig
        - export KUBECONFIG=~/.kubeconfig

        - kustomize build ./infra/traefik/ --enable-helm | kubectl apply -f -
        - kubectl rollout status -n kube-system deployment/traefik --timeout=90s

        - echo "OCI container version"
        - kubectl get deployment traefik -n kube-system -o jsonpath='{.spec.template.spec.containers[*].image}'

  labels:
    platform: linux/amd64
  EOF
  ```

- Create `example` pipeline
  ```
  cat <<EOF > ./.woodpecker/example.yaml
  when:
    - path:
        include:
          - '.woodpecker/example.yaml'
          - 'apps/example/**'

  clone:
    - name: git
      image: woodpeckerci/plugin-git
      volumes:
        - custom-ca-certs:/etc/ssl/certs/custom:ro
      settings:
        custom_ssl_path: /etc/ssl/certs/custom/ca1.liv.io.crt

  steps:
    - name: lint
      image: registry.liv.io/liv/k8s-ops:1.36.2-2
      environment:
        KUBECONFIG_DATA:
          from_secret: example-deployer
      commands:
        - install --owner=k8s --group=k8s --mode=0600 /dev/null ~/.kubeconfig
        - echo "$${KUBECONFIG_DATA}" > ~/.kubeconfig
        - export KUBECONFIG=~/.kubeconfig

        - kubectl apply -k ./apps/example/ --dry-run=client
        - kubectl apply -k ./apps/example/ --dry-run=server

    - name: deploy
      image: registry.liv.io/liv/k8s-ops:1.36.2-2
      environment:
        KUBECONFIG_DATA:
          from_secret: example-deployer
      when:
        - event: push
          branch: main
      commands:
        - install --owner=k8s --group=k8s --mode=0600 /dev/null ~/.kubeconfig
        - echo "$${KUBECONFIG_DATA}" > ~/.kubeconfig
        - export KUBECONFIG=~/.kubeconfig

        - kubectl apply -k ./apps/example/
        - kubectl rollout status -n example deployment/example --timeout=90s

        - echo "OCI container version"
        - kubectl get deployment example -n example -o jsonpath='{.spec.template.spec.containers[*].image}'

  labels:
    platform: linux/amd64
  EOF
  ```

## Commands

- Inspect container
  ```
  kubectl exec -it -n example deployment/example -- ps -ef
  ```

- Show detailed description
  ```
  kubectl describe pod -n example
  ```

- Inspect logs
  ```
  kubectl logs -n example deployment/example --tail=100 -f
  ```

- Get image version
  ```
  kubectl get deployment example -n example -o jsonpath='{.spec.template.spec.containers[*].image}'
  ```

- Stop container
  ```
  kubectl scale deployment example --replicas=0 -n example
  ```

- Start container
  ```
  kubectl scale deployment example --replicas=1 -n example
  ```

## Appendix

- [Traefik](https://traefik.io/traefik)
- [kubesolo](https://kubesolo.io)
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner)
