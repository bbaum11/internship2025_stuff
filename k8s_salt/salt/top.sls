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

base:
    '*':
        - order: 1
        - installation/dependencies
        - order: 2
        - registry/create_registry # sets up and populates the private image registry if pillar is set to true
        - registry/deploy_created_registry # pulls the image for the registry if not (assuming there is a prepopulated registry image)
        - hardening/config_file
        - installation/binary_setup
        - installation/services # setting up gitlab runner and metallb
        - order: 3
        - installation/rke2_init # manifests are added to the auto deploy directory here
        - order: 4
        - installation/rke2_startup # startup rke2
        - order: 5
        - hardening/permissions
        - order: 6
        - hardening/oscap