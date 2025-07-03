# deploying gitlab runners in the airgapped environment
## on the non-airgapped device
1. download the gitlab runner main and helper images
```
podman pull registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1
podman pull registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v18.1.1
podman save -m registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1 registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v18.1.1 | gzip > gitlab-images.tar.gz
```
2. download the tarballs for helm itself and the gitlab runner helm chart
```
curl -LO https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz
curl -LO https://gitlab.com/gitlab-org/charts/gitlab-runner/-/archive/0-78-stable/gitlab-runner-0-78-stable.tar.gz
```
3. move the files onto the airgapped machine hosting the kubernetes cluster

## on the airgapped network
### getting tls
- if you are working with custom tls certificates, you will need to configure tls on the gitlab runner image. The easiest way to do this is do download your certificate and create a Dockerfile that copies it over and updates the trusted certifiacates, as shown with this Dockerfile:
```
FROM registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1
ARG src="<certificate>.crt"
ARG target="/usr/local/share/ca-certificates/<certificate>.crt"
COPY ${src} ${target}
RUN update-ca-certificates
```
- then run `podman build -t my-gitlab-runner:alpine-v18.1.1 .`

### in gitlab project
1. `Settings -> CI/CD -> Runners -> Create project runner`
2. Add tags and lock to current projects
3. Copy the runner authentication token

#### install helm
1. unzip the helm archive file
`tar -xzvf gitlab-runner-0-78-stable.tar.gz`
2. move the executable to `/usr/bin`  
`mv ./linux-amd64/helm /usr/bin/helm`

#### deploy the helm chart
1. edit the following fields of `values.yaml` for the helm chart, using the runner authentication token from the UI:
```
image:
  registry: registry.gitlab.com
  image: gitlab-org/my-gitlab-runner
gitlabUrl: https://<gitlab_url>/
runnerToken: <auth_token>
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
serviceAccount:
  create: true
```
2. configure the gitlab container registry mirror in `/etc/rancher/k3s/registries.yaml`:
```
mirrors:
  ...
    ...
      -  ...
  registry.gitlab.com:
    endpoint:
      - "http://<private_registry_ip>:5000"
```
3. set the kubeconfig global variable
`export KUBECONFIG=/etc/rancher/k3s/k3s.yaml`
4. deploy runner helm chart
`helm install gitlab runner . -f values.yaml`

#### test the pipeline
1. in the gitlab repository, add the CI/CD configuration file `.gitlab-ci.yml`  
```
test-runner:
  script:
    - echo "testing the runner as $(whoami)"
```
2. after committing the chagnes, the pipeline should run. after selecting the job, the output should show as the run being successful with the command output shown.
