# setting up gitlab runners using the k8s executors

deploy cluster (im using minikube for now)
images needed:
- registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v18.1.1
- registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1

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
```
4. deploy runner helm chart
5. create cert secret. *note: the name of the file containing the cert must match the server URL exactly.*:  
`kubectl create secret generic mycerts --from-file=./<gitlab_url>.crt`
