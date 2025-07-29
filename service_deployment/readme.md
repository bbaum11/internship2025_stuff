# creating a service that uses postgresql for the cluster 
in order to demonstrate the capabilities of the kubernetes cluster, a python web service was made that works with a postgresql database.

### dependency list
- psycopg2-binary
- flask

## flask app
for this deployment [this tutorial](https://www.geeksforgeeks.org/python/making-a-flask-app-using-a-postgresql-database/) was used with minor modifications.

### [python code](flask_app/app.py)
- in order to containerize the application, the parameters to connect to the database were retrieved from environment variables
- additionally, because flask does not natively handle ingress configurations well, the ProxyFix library was used to allow the server to properly route back to the ingress address when sending requests from within the application

### [index html page](flask_app/templates/index.html)
- to also get the references to route to the right place from index.html, a script was added to set the base href to include the ingress route
- additionally, the '/'s were removed from the form button actions so that the path was relative

### [Dockerfile](flask_app/Dockerfile)
- a python image was used as the base image
- a certificate was added to the container to get tls functioality
- the [requirements](flask_app/requirements.txt) for flask and the postgresql library were installed into the container image

### [postgres manifest](manifests/postgres.yaml) and [flask manifest](manifests/flask.yaml)
- for the postgres app, it was created with a persistent volume mounted in the server's data directory and with environment variables to set the login credentials
- for the flask app, it was created with the environment variables set for the login credentials and the SCRIPT_NAME field for the ProxyFix library

### [ingress routing](manifests/ingressRoutes.yaml)
- instead of the standard kubernetes ingress resources, Traefik's IngressRoute CRD's were used instead because they allow for easier customization
- the flask server was configured to have the route of `http://<traefik_ip>/flask`
- a middleware was also configured to strip the `/flask` prefix from all incoming requests so that the flask server can properly handle them
