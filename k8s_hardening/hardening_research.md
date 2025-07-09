# Available options for hardening the cluster
For hardening this specific kubernetes implementation, there are options for k3s specifically, and also kubernetes more broadly. The k3s hardening is provided by k3s, while the kubernetes hardening is available as a DISA STIG.

## [k3s documentation](https://docs.k3s.io/security/hardening-guide?utm_source=chatgpt.com&pod-sec=v1.25+and+Newer#configuration-for-kubernetes-components)
k3s offers configuration setting to harden it. these can be placed in a confiugration file, which will set the flags used when running the k3s server. 

### getting audit logs working
- because kubernetes doesn't create an audit log folder by default, we need to create one on the host machine:
`sudo mkdir -p -m 700 /var/lib/rancher/k3s/server/logs`
- an audit policy also needs to be created to log request metadata as `/var/lib/rancher/k3s/server/audit.yaml`:
```
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
```
- to enable 

### system hardening
- in addition to the other necessary settings, add the following to `/etc/rancher/k3s/config.yaml`:  
```
protect-kernel-defaults: true
secrets-encryption: true
kube-apiserver-arg:
  - "enable-admission-plugins=NodeRestriction,EventRateLimit"
  - 'admission-control-config-file=/var/lib/rancher/k3s/server/psa.yaml'
  - 'audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log'
  - 'audit-policy-file=/var/lib/rancher/k3s/server/audit.yaml'
  - 'audit-log-maxage=30'
  - 'audit-log-maxbackup=10'
  - 'audit-log-maxsize=100'
kube-controller-manager-arg:
  - 'terminated-pod-gc-threshold=10'
kubelet-arg:
  - 'streaming-connection-idle-timeout=5m'
  - "tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
```
- restrict permissions on the k3s tls certificates:
`chmod -R 600 /var/lib/rancher/k3s/server/tls/*.crt`

## [MITRE k3s automated compliance](https://github.com/mitre/k3s-cluster-stig-baseline)
- mitre also provides a 
- 
