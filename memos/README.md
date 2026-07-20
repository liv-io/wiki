# Memos

## Index

- [Install](#install)
  - [Debian](#debian)
  - [k0s](#k0s)
  - [k0sctl](#k0sctl)
  - [kustomize](#kustomize)
  - [Memos](#memos)
    - [Infra](#infra)
      - [Traefik](#traefik)
      - [local-path](#local-path)
    - [Apps](#apps)
- [Commands](#commands)
- [Appendix](#appendix)

## Install

### Debian

- Install dependencies
  ```
  apt update
  apt install --no-install-recommends -y git
  ```

### k0s

- Install [k0s](../k0s/README.md#install)

- Add container registry secret
  ```
  k0s kubectl create secret docker-registry registry.liv.io \
      --docker-server="registry.liv.io" \
      --docker-username="<username>" \
      --docker-password="<password>" \
      --namespace=memos
  ```

### k0sctl

- Install [k0sctl](../k0sctl/README.md#install)

### kustomize

- Install [kustomize](../kustomize/README.md#install)

### Memos

- Initialize a Git repository as harness for the deployment files
  ```
  git init memos-prod
  cd ./memos-prod/
  ```

#### Infra

- Create the `infra` directroy structure
  ```
  install --directory --mode=0750 ./infra
  install --directory --mode=0750 ./infra/traefik
  install --directory --mode=0750 ./infra/local-path
  ```

##### Traefik

- Install [Traefik](../traefik/README.md#install)

##### local-path

- Create the `kustomization.yaml` file
  ```
  export LOCAL_PATH_PROVISIONER_VERSION="0.0.36"

  cat <<EOF > ./infra/local-path/kustomization.yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization

  resources:
    - https://github.com/rancher/local-path-provisioner/raw/v${LOCAL_PATH_PROVISIONER_VERSION}/deploy/local-path-storage.yaml

  patches:
    - target:
        kind: StorageClass
        name: local-path
      patch: |
        - op: add
          path: /metadata/annotations/storageclass.kubernetes.io~1is-default-class
          value: "true"
  EOF
  ```

- Run the client-side schema validation
  ```
  k0s kubectl apply -k ./infra/local-path/ --dry-run=client
  ```

- Run the server-side schema validation
  ```
  k0s kubectl apply -k ./infra/local-path/ --dry-run=server
  ```

- Apply manifest
  ```
  k0s kubectl apply -k ./infra/local-path/
  ```

- Restart k0s
  ```
  systemctl restart k0scontroller.service

  systemctl status k0scontroller.service --no-pager
  k0s status
  k0s kubectl get all -n kube-system
  ```

- Validate `local-path-provisioner`
  ```
  k0s kubectl get all -A -l app=local-path-provisioner
  ```

- Inspect the StorageClasses
  ```
  k0s kubectl get storageclass
  ```

#### Apps

- Create the `infra` directroy structure
  ```
  install --directory --mode=0750 ./apps
  install --directory --mode=0750 ./apps/memos
  ```

- Create the `kustomization.yaml` file
  ```
  cat <<EOF > ./apps/memos/kustomization.yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization

  namespace: memos

  resources:
    - namespace.yaml
    - pvc.yaml
    - service.yaml
    - deployment.yaml

  images:
    - name: registry.liv.io/liv/memos
      newTag: 0.29.1-1
  EOF
  ```

- Create the `namespace.yaml` file
  ```
  cat <<EOF > ./apps/memos/namespace.yaml
  apiVersion: v1
  kind: Namespace

  metadata:
    name: memos
  EOF
  ```

- Create the `pvc.yaml` file
  ```
  cat <<EOF > ./apps/memos/pvc.yaml
  apiVersion: v1
  kind: PersistentVolumeClaim

  metadata:
    name: memos-pvc
    namespace: memos

  spec:
    accessModes:
      - ReadWriteOnce
    storageClassName: local-path
    resources:
      requests:
        storage: 5Gi
  EOF
  ```

- Create the `service.yaml` file
  ```
  cat <<EOF > ./apps/memos/service.yaml
  apiVersion: v1
  kind: Service

  metadata:
    name: memos

  spec:
    type: ClusterIP
    ports:
    - port: 8081
      targetPort: memos-http
      protocol: TCP
      name: http
    selector:
      app: memos

  ---

  apiVersion: networking.k8s.io/v1
  kind: Ingress

  metadata:
    name: memos-ingress
    annotations:
      traefik.ingress.kubernetes.io/router.tls: "true"
      traefik.ingress.kubernetes.io/router.tls.certresolver: "myresolver"
      traefik.ingress.kubernetes.io/router.entrypoints: "websecure"

  spec:
    ingressClassName: traefik
    tls:
      - hosts:
          - memos.liv.io
    rules:
    - host: memos.liv.io
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: memos
              port:
                number: 8081
  EOF
  ```

- Create the `deployment.yaml` file
  ```
  cat <<EOF > ./apps/memos/deployment.yaml
  apiVersion: apps/v1
  kind: Deployment

  metadata:
    name: memos

  spec:
    replicas: 1
    strategy:
      type: Recreate
    selector:
      matchLabels:
        app: memos
    template:
      metadata:
        labels:
          app: memos
      spec:
        containers:
        - name: memos
          image: registry.liv.io/liv/memos
          workingDir: /
          ports:
          - name: memos-http
            containerPort: 8081
            protocol: TCP
          env:
          - name: PORT
            value: '8081'
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - CAP_MKNOD
              - CAP_NET_RAW
              - CAP_AUDIT_WRITE
            privileged: false
            readOnlyRootFilesystem: true
            runAsGroup: 10000
            runAsUser: 10000
            seLinuxOptions:
              type: spc_t
          volumeMounts:
          - name: memos-db
            mountPath: /var/local/memos/db
        imagePullSecrets:
        - name: registry.liv.io
        volumes:
        - name: memos-db
          persistentVolumeClaim:
            claimName: memos-pvc
  EOF
  ```

- Render manifest
  ```
  kustomize build ./apps/memos/
  k0s kubectl kustomize ./apps/memos/
  ```

- Run the client-side schema validation
  ```
  k0s kubectl apply -k ./apps/memos/ --dry-run=client
  ```

- Create `memos` namespace from manifest for running the server-side schema validation
  ```
  k0s kubectl apply -f ./apps/memos/namespace.yaml
  k0s kubectl apply -k ./apps/memos/ --dry-run=server
  ```

- Apply manifest
  ```
  k0s kubectl apply -k ./apps/memos/
  ```

- Verify deployment rollout status
  ```
  k0s kubectl rollout status -n memos deployment/memos
  ```

- Validate application
  ```
  k0s kubectl get all -n memos
  ```

- Query TLS encrypted endpoint
  ```
  curl --noproxy "*" https://memosliv.io
  ```

## Commands

- Inspect logs
  ```
  k0s kubectl logs -n memos deployment/memos --tail=100 -f
  ```

- Inspect container
  ```
  k0s kubectl exec -it -n memos deployment/memos -- ps -ef
  ```

- Stop container
  ```
  k0s kubectl scale deployment memos --replicas=0 -n memos
  ```

- Start container
  ```
  k0s kubectl scale deployment memos --replicas=1 -n memos
  ```

## Appendix

- [Memos](https://usememos.com)
