# hardening rke2
after reviewing the available configuration options for k3s ([here](hardening_research.md)), the conclusion was made to instead use RKE2, comes with less needed configuration for security and a maintained DISA STIG, as opposed to the generic kuberetes one.

## configurations
to harden the rke2 cluster, it is necessary to edit the main configuration file, set correct file permissions, and ensure that deployed components are configured correctly

### main config file
RKE2 allows for the use of the `/etc/rancher/rke2/config.yaml` file, which configures the arguments passed to the main binary. this file is not created by defualt, so it needs to be created with the following configuration:  
```
profile: "cis"
# anonymous auth may need to sometimes be enabled for things lke health checks
kube-apiserver-arg:
  --authorization-mode=RBAC,Node
  - audit-log-maxage=30
  - anonymous-auth=false
  - insecure-port=0
  - "tls-min-version=VersionTLS12"
  - "tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
kubelet-arg:
  --protect-kernel-defaults=true
  - streaming-connection-idle-timeout=5m
  - authorization-mode=Webhook
  --read-only-port=0
kube-controller-manager-arg: 
  - use-service-account-credentials=true
  - "tls-min-version=VersionTLS12"
  - "tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
anonymous-auth: false
kube-scheduler-arg: 
  - "tls-min-version=VersionTLS12"
  - "tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
write-kubeconfig-mode: "0600"
```
**Note that the "cis" profile is provided by RKE2 and is used to help pass the platform's CIS benchmark. If there are conflicting security configurations, the service will not start**

### file permissions
the following file permissions are needed to proivde CIS compliance:
- `/etc/rancher/ke2/`
  - `./*`
    - 0600 permissions
    - root:root
- `/var/lib/rancher/rke2/`
  - `./*`
    - root:root
- `/var/lib/rancher/rke2/agent/`
  - `./*`
    - root:root
  - `pod-manifests`
    - 0700 permissions
  - `etc`
    - 0700 permissions
  - `*.kubeconfig`
    - 0640 permissions
  - `*.crt` and `*.key`
    - 0600 permissions
- `/var/lib/rancher/rke2/agent/`
  - `data`
    - root:root
    - 0750 permissions
- `/var/lib/rancher/rke2/data/`
  - `./*`
    - root:root
    - 0640 permissions
- `/var/lib/rancher/rke2/server/`
  - `./*`
    - root:root
  - `cred`, `db`, and `tls`
    - 0700 permissions
  - `manifests` and `logs`
    - 0750 permissions
  - `token`
    - 0600 permissions
### deployed component configurations
to keep the deployed configurations secure, the following practices are nessecary  
- keep stuff in separate namespaces
- don't store secrets as environment variables and properly store them (like with a vault)
- ensure PPSM CAL compliance
- remove old components after updated versions have been enstalled (pods using older images)
