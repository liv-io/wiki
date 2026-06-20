# Config

## Index

- [Debian](#debian)
- [k0s](#k0s)
  - [OpenEBS](#openebs)
  - [Containerd](#containerd)
  - [Traefik](#traefik)
  - [Container](#container)
  - [Calico](#calico)
- [Appendix](#appendix)

## Debian

- Add http/https proxy settings
  ```
  install --directory --owner=root --group=root --mode=0755 /etc/systemd/system/k0scontroller.service.d

  cat <<EOF > /etc/systemd/system/k0scontroller.service.d/http-proxy.conf
  [Service]
  Environment="HTTP_PROXY=http://fp.liv.io:3128"
  Environment="HTTPS_PROXY=http://fp.liv.io:3128"
  Environment="NO_PROXY=localhost,127.0.0.1,::1,bs.liv.io,backup.liv.io,ca.liv.io,10.1.13.61,10.244.0.0/16,10.96.0.0/12,memos02.liv.io,.svc,.cluster.local"
  EOF

  systemctl daemon-reload
  ```

## k0s

- Generate configuration file
  ```
  export CLUSTER="memos"
  export DNS="10.1.11.1"

  install --directory --owner=root --group=root --mode=0755 /etc/k0s
  k0s config create > /etc/k0s/k0s.yaml
  ```

- Modify configuration file
  ```
  yq -i '.metadata.name = strenv(CLUSTER)' /etc/k0s/k0s.yaml
  yq -i '.spec.controllerManager.extraArgs += {"leader-elect-lease-duration": "300s", "leader-elect-renew-deadline": "240s", "leader-elect-retry-period": "60s"}' /etc/k0s/k0s.yaml
  yq -i '.spec.network.dns.upstreamNameServers = [strenv(DNS)]' /etc/k0s/k0s.yaml
  yq -i '.spec.scheduler.extraArgs += {"leader-elect-lease-duration": "300s","leader-elect-renew-deadline": "240s","leader-elect-retry-period": "60s"}' /etc/k0s/k0s.yaml
  yq -i '.spec.storage.type = "kine" | del(.spec.storage.etcd) | del(.spec.installConfig.users.etcdUser)' /etc/k0s/k0s.yaml
  yq -i '.spec.telemetry.enabled = false' /etc/k0s/k0s.yaml
  yq -i '.spec.workerProfiles = [{"name": "low-power", "values": {"housekeepingInterval": "30s", "nodeStatusUpdateFrequency": "30s"}}]' /etc/k0s/k0s.yaml
  ```

- Validate configuration file
  ```
  k0s config validate --config /etc/k0s/k0s.yaml
  ```

- Start and verify node
  ```
  k0s install controller --config /etc/k0s/k0s.yaml --single --profile=low-power --start

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

- Validate status of node
  ```
  k0s kubectl get nodes
  k0s kubectl get all -n kube-system
  ```

### OpenEBS

- Download and apply `local-path-provisioner`
  ```
  export LOCAL_PATH_PROVISIONER_VERSION="0.0.36"

  git clone --single-branch --branch v${LOCAL_PATH_PROVISIONER_VERSION} https://github.com/rancher/local-path-provisioner.git
  k0s kubectl apply -f ./local-path-provisioner/deploy/local-path-storage.yaml
  ```

- Configure OpenEBS storage extension
  ```
  yq -i '.spec.extensions.storage.type = "openebs_local_storage"' /etc/k0s/k0s.yaml
  yq -i '.spec.extensions.storage.create_default_storage_class = true' /etc/k0s/k0s.yaml
  ```

- Restart k0s
  ```
  systemctl restart k0scontroller.service

  systemctl status k0scontroller.service --no-pager
  k0s status
  k0s kubectl get all -n kube-system
  ```

- Validate OpenEBS
  ```
  k0s kubectl get all -A -l app=local-path-provisioner
  ```

- Inspect the StorageClasses
  ```
  k0s kubectl get storageclass
  ```

### Containerd

- Add container registry credentials to Containerd
  ```
  export USERNAME="<username>"
  export PASSWORD="<password>"

  install --directory --owner=root --group=root --mode=0750 /etc/k0s/containerd.d

  cat <<EOF > /etc/k0s/containerd.d/registry-auth.toml
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.liv.io".auth]
    username = "${USERNAME}"
    password = "${PASSWORD}"
  EOF
  ```

### Traefik

- Create a Kustomize deployment directory for Traefik
  ```
  install --directory --owner=root --group=root --mode=0750 ./kustomize/traefik
  ```

- Copy (or symlink) root CA certificate
  ```
  cp /usr/local/share/ca-certificates/ca1.liv.io.crt ./kustomize/traefik/
  ```

- Create the Traefik `kustomization.yaml`
  ```
  cat <<EOF > ./kustomize/traefik/kustomization.yaml
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
      version: 40.3.0
      releaseName: traefik
      namespace: kube-system
      valuesInline:

        deployment:
          kind: Deployment
          replicas: 1
          updateStrategy:
            type: Recreate
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
            enabled: false

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
  kustomize build ./kustomize/traefik/ --enable-helm | k0s kubectl apply --dry-run=client -f -
  kustomize build ./kustomize/traefik/ --enable-helm | k0s kubectl apply --dry-run=server -f -
  ```

- Apply manifest
  ```
  kustomize build ./kustomize/traefik/ --enable-helm | k0s kubectl apply -f -
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

### Container

- Create a Kustomize deployment directory for an example application `memos`
  ```
  install --directory --owner=root --group=root --mode=0750 ./kustomize/memos
  ```

- Create the `kustomization.yaml` file
  ```
  cat <<EOF > ./kustomize/memos/kustomization.yaml
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
  cat <<EOF > ./kustomize/memos/namespace.yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    name: memos
  EOF
  ```

- Create the `pvc.yaml` file
  ```
  cat <<EOF > ./kustomize/memos/pvc.yaml
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
  cat <<EOF > ./kustomize/memos/service.yaml
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
          - memos02.liv.io
    rules:
    - host: memos02.liv.io
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
  cat <<EOF > ./kustomize/memos/deployment.yaml
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
        volumes:
        - name: memos-db
          persistentVolumeClaim:
            claimName: memos-pvc
  EOF
  ```

- Render manifest
  ```
  kustomize build ./kustomize/memos/
  k0s kubectl kustomize ./kustomize/memos/
  ```

- Run the client-side schema validation
  ```
  k0s kubectl apply -k ./kustomize/memos/ --dry-run=client
  ```

- Run the server-side schema validation
  ```
  k0s kubectl create namespace memos --dry-run=client -o yaml | k0s kubectl apply -f -
  k0s kubectl apply -k ./kustomize/memos/ --dry-run=server
  ```

- Apply manifest
  ```
  k0s kubectl apply -k ./kustomize/memos/
  ```

- Verify deployment rollout status
  ```
  k0s kubectl rollout status -n memos deployment/memos
  ```

- Validate application
  ```
  k0s kubectl get all -n memos
  ```

- Inspect logs
  ```
  k0s kubectl logs -n memos deployment/memos --tail=100 -f
  ```

- Inspect container
  ```
  k0s kubectl exec -it -n memos deployment/memos -- ps -ef
  ```

- Query TLS encrypted endpoint
  ```
  curl --noproxy "*" https://memos02.liv.io
  ```

### Calico

> [!NOTE]
>  Optional: Use Calico as Container Network Interface (CNI)

- Install, enable and start `nftables`
  ```
  apt -y --no-install-recommends install nftables
  systemctl enable nftables.service
  systemctl start nftables.service
  ```

- Modify configuration file
  ```
  yq -i '.spec.network.kubeProxy.mode = "nftables"' /etc/k0s/k0s.yaml
  yq -i '.spec.network.provider = "calico"' /etc/k0s/k0s.yaml
  ```

- Update the systemd unit file
  ```
  k0s install controller --config /etc/k0s/k0s.yaml --single --iptables-mode nft --profile=low-power --start --force
  ```

- Start and verify node
  ```
  systemctl start k0scontroller.service

  systemctl status k0scontroller.service --no-pager
  k0s status
  ```

- Validate status of node
  ```
  k0s kubectl get nodes
  k0s kubectl get all -n kube-system
  ```

## Appendix

- [Calico](https://docs.tigera.io/calico)
- [Containerd](https://containerd.io)
- [Kine](https://github.com/k3s-io/kine)
- [OpenEBS](https://openebs.io)
- [Traefik Ingress](https://github.com/k0sproject/k0s/blob/main/docs/examples/traefik-ingress.md)
- [Traefik](https://traefik.io/traefik)
- [k0s Configuration Options](https://github.com/k0sproject/k0s/blob/main/docs/configuration.md)
