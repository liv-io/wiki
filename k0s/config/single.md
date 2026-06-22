# Config

## Index

- [Debian](#debian)
- [k0s](#k0s)
  - [Local-Path](#local-path)
  - [Containerd](#containerd)
  - [Traefik](#traefik)
  - [Calico](#calico)
  - [Apps](#apps)
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

### Local-Path

- Download and apply `local-path-provisioner`
  ```
  export LOCAL_PATH_PROVISIONER_VERSION="0.0.36"

  git clone --single-branch --branch v${LOCAL_PATH_PROVISIONER_VERSION} https://github.com/rancher/local-path-provisioner.git
  k0s kubectl apply -f ./local-path-provisioner/deploy/local-path-storage.yaml
  ```

- Configure `local-path-provisioner` storage extension
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

- Validate `local-path-provisioner`
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
  version = 3

  [plugins."io.containerd.cri.v1.images".registry.configs."registry.liv.io".auth]
    username = "${USERNAME}"
    password = "${PASSWORD}"
  EOF
  ```

### Traefik

- Create a Kustomize deployment directory for Traefik
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

### Apps

- Deploy an application to k0s

> [!TIP]
>  See [Memos](../../memos/README.md) for a practical example

## Appendix

- [Calico](https://docs.tigera.io/calico)
- [Containerd](https://containerd.io)
- [Kine](https://github.com/k3s-io/kine)
- [Kube-Router](https://kube-router.io)
- [Traefik Ingress](https://github.com/k0sproject/k0s/blob/main/docs/examples/traefik-ingress.md)
- [Traefik](https://traefik.io/traefik)
- [k0s Configuration Options](https://github.com/k0sproject/k0s/blob/main/docs/configuration.md)
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner)
