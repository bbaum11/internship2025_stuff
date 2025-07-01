# setting up gitlab runners using the k8s executors
get helm  
`curl -LO https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz'

### getting the chart
helm repo add gitlab https://charts.gitlab.io
helm pull gitlab/gitlab-runner

### getting the image
helm search repo -l gitlab/gitlab-runner
podman pull registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1

## move charts to httpd and image to docker registry

## edit values.yaml to pull from the local registry
change `registry` from **registry.gitlab.com** to **192.168.47.102:5000**
