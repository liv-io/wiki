# Config

## Index

- [talosctl](#talosctl)
  - [Bootstrap Node](#bootstrap-node)
  - [Additional Node](#additional-node)
- [Appendix](#appendix)
  - [Reset Node](#reset-node)

## talosctl

- Generate cluster configuration files
  ```
  export CLUSTER="rnd"
  export DISK="/dev/sda"
  export INTERFACE="ens18"
  export GATEWAY="10.1.17.1"
  export DNS="10.1.11.1"
  export NTP="10.1.11.1"
  export T01="10.1.17.31/24"
  export T02="10.1.17.32/24"
  export T03="10.1.17.33/24"
  export VIP="10.1.17.30"

  talosctl gen config ${CLUSTER} https://${VIP}:6443
  ```

- Create node configuration files
```
for i in 1 2 3; do
  NODE="T0${i}"
  ADDRESS="${!NODE}"

  cat <<EOF > t0${i}.yaml
machine:
  install:
    disk: ${DISK}
  time:
    servers:
      - ${NTP}
  network:
    nameservers:
      - ${DNS}
    interfaces:
      - interface: ${INTERFACE}
        addresses:
          - ${ADDRESS}
        routes:
          - network: 0.0.0.0/0
            gateway: ${GATEWAY}
        vip:
          ip: ${VIP}
cluster:
  allowSchedulingOnControlPlanes: true
---
apiVersion: v1alpha1
kind: HostnameConfig
hostname: ${NODE,,}
auto: off
EOF
done
```

- Apply configuration
  ```
  talosctl apply-config --insecure -n 10.1.17.31 --file controlplane.yaml --config-patch @t01.yaml
  talosctl apply-config --insecure -n 10.1.17.32 --file controlplane.yaml --config-patch @t02.yaml
  talosctl apply-config --insecure -n 10.1.17.33 --file controlplane.yaml --config-patch @t03.yaml
  ```

- Load Talos configuration
  ```
  export TALOSCONFIG="$(pwd)/talosconfig"
  ```

- Configure control plane API endpoints
  ```
  talosctl config endpoint 10.1.17.31 10.1.17.32 10.1.17.33
  ```

- Configure default target nodes
  ```
  talosctl config node 10.1.17.31 10.1.17.32 10.1.17.33
  ```

- Bootstrap the `etcd` cluster (only run once!)
  ```
  talosctl bootstrap -n 10.1.17.31
  ```

- List all cluster members
  ```
  talosctl get members
  ```

- Check DNS and NTP health
  ```
  talosctl get dnsupstream
  talosctl get timestatus
  ```

## Appendix
