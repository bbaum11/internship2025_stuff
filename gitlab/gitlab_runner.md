# setting up gitlab runners using the k8s executors (minikube with an internet connection was used for testing purposes
#### images needed:  
- registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v18.1.1
- registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1  
#### chart needed:
- `helm pull gitlab-runner --repo https://charts.gitlab.io/`

### getting tls
- if you are working with custom tls certificates, you will need to configure tls on the gitlab runner image. The easiest way to do this is do download your certificate and create a Dockerfile that copies it over and updates the trusted certifiacates, as shown with this Dockerfile:
```
FROM registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1
ARG src="<certificate>.crt"
ARG target="/usr/local/share/ca-certificates/<certificate>.crt"
```
- then run `podman build -t my-gitlab-runner:alpine-v18.1.1 .`

### in gitlab project
1. `Settings -> CI/CD -> Runners -> Create project runner`
2. Add tags and lock to current projects
3. Get runner authentication token

### on cluster
1. `openssl s_client -showcerts -connect gitlab.com:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > ~/<gitlab_url>.crt`
2. edit the following fields of `values.yaml` for the helm chart:
```
gitlabUrl: https://<gitlab_url>/
runnerToken: <auth_token>
certsSecretName: mycerts
rbac:
  create: true
  rules:
     - resources: ["events"]
       verbs: ["list", "watch"]
     - resources: ["namespaces"]
       verbs: ["create", "delete"]
     - resources: ["pods"]
       verbs: ["create","delete","get"]
     - apiGroups: [""]
       resources: ["pods/attach","pods/exec"]
       verbs: ["get","create","patch","delete"]
     - apiGroups: [""]
       resources: ["pods/log"]
       verbs: ["get","list"]
     - resources: ["secrets"]
       verbs: ["create","delete","get","update"]
     - resources: ["serviceaccounts"]
       verbs: ["get"]
     - resources: ["services"]
       verbs: ["create","get"]
```
4. deploy runner helm chart
5. create cert secret. *note: the name of the file containing the cert must match the server URL exactly.*:  
`kubectl create secret generic mycerts --from-file=./<gitlab_url>.crt`
6. if using custom certs, they need to be added to the kubernetes nodes. specifically with minikube, do `minikube ssh` and add the cert to `/usr/local/share/ca-certificates/` and run `sudo update-ca-certificates`
