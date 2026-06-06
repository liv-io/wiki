# Commands

## Index

- [k0s](#k0s)
- [Appendix](#appendix)

## k0s

- Reset node and remove configuration
  ```
  systemctl unmask k0scontroller.service
  systemctl stop k0scontroller.service 2>/dev/null
  systemctl daemon-reload
  systemctl reset-failed
  k0s reset
  rm -rf /etc/k0s /root/.kube/ /root/k0s-controller.token
  ```

## Appendix

- [CLI Documentation](https://docs.k0sproject.io/stable/cli)
