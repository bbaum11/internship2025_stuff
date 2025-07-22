# required parameters:
#   - gitlab runner token
#   - gitlab url
#   - metallb ip range
#   - tls cert name
#   - whether or not to do the registry creation (podman is slow)
#       - the image to use if not
#   - (maybe) ip address space for the k8s pods and services
# ------------------------------
# this setup is to create a host node (and later an agent)
# that has a private docker registry it will be pulling images
# from. instead of having an http repo to pull other files
# from, they will instead be served from the salt master
# example usage:
# salt '*' state.apply pillar='{"metallb_pool":"192.168.47.115-192.168.47.130", "runner_token":"TEST_TOKEN", "gitlab_url":"TEST_URL", "create_registry":True, "cert_filename":"<cert>.crt", "registry_image":"REGISTRY_IMAGE"}'

base:
    '*':
        - order: 1
        - installation/dependencies
        - order: 2
        - registry/create_registry # sets up and populates the private image registry if pillar is set to true
        - registry/deploy_created_registry # pulls the image for the registry if not (assuming there is a prepopulated registry image)
        - hardening/config_file
        - installation/binary_setup # adding helm and k9s to the host
        - installation/services # setting up gitlab runner and metallb. manifests are added to the auto deploy directory here
        - order: 3
        - installation/rke2_init # the rke2 core archives are setup here
        - order: 4
        - installation/rke2_startup # startup rke2
        - order: 5
        - hardening/permissions # editing file permissions for the rke2 files. the script job fails despite working when running normally.
        - order: 6
        - hardening/oscap # os hardening