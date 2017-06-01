# Keycloak-deployment

This repository contains all our scripts to deploy keycloak on Openshift and minishift.
Also we have scripts to bake our own docker image using the keycloak source code
from our repository `almighty/keycloak`.

# Almighty-Keycloak Docker Image

To build this image it is necessary to have previously generated the executables of this
project. To do this, run the following Maven command in the almighty/keycloak repository:

`$ mvn clean install -DskipTests -pl :keycloak-server-dist -am -P distribution`

This generates some tarballs with the required executables. To build the docker image,
copy the generated tar file (e.g. `keycloak-3.0.0.Final.tar.gz`) from the almighty/keycloak
repository into the docker folder, like so:

`$ cp $KEYCLOAK_REPO/distribution/server-dist/target/keycloak-3.0.0.Final.tar.gz $KEYCLOAK_DEPLOYMENT_REPO/docker`

Then you just need to build the docker image.  Change into the docker directory and run the following command:

`$ docker build --tag IMAGE_NAME .`

If you would like to build image for clustered mode add build argument

`$ docker build  --build-arg OPERATING_MODE=clustered --tag IMAGE_NAME .`

Note that, this docker image installs the certificate to securely talk to OpenShift Online.
This step is done inside the `install_certificate.sh` script which adds this
certificate into the Java system keystore at building time. We assume this certificate
points to `tsrv.devshift.net`. So any change to the certificate requires rebuilding the
Docker image.

In the content of the Dockerfile, you can find these ENV variables:
```
ENV OSO_ADDRESS tsrv.devshift.net:8443
ENV OSO_DOMAIN_NAME tsrv.devshift.net
```

Also note that it is possible to use a certificate from minishift.  To do this, first obtain the
IP address of your minishift instance:

```
minishift ip
```

Then edit docker/Dockerfile and replace these values with the minishift IP (this is just an example,
the address will most likely be different):

```
ENV OSO_ADDRESS 192.168.42.134:8443
ENV OSO_DOMAIN_NAME 192.168.42.134
```

The command for building the docker image will need to be slightly different, since docker build by default does not
have access to local IP addresses. Add the --network="host" parameter to allow the install_certificate.sh script to 
connect to minishift and retrieve the certificate:

`$ docker build --network="host" --tag IMAGE_NAME .`


# Openshift Configuration for clustered deployment

Majority of the config is defined in `DeploymentConfig` files you can find in `openshift` folder in the root of this repository.

There is one thing needed however to have properly functioning cluster (using [k8s PING protocol in `jgroups`](https://github.com/jgroups-extras/jgroups-kubernetes)). 
Service account has to have `view` privileges. This can be enabled using `oc` cli as follows:

```
$ oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default -n $(oc project -q)
```

# Deploying Keycloak to Minishift

To deploy a Keycloak cluster in minishift use the following commands:

```
oc new-project keycloak --display-name="Keycloak server" \
--description="keycloak server + postgres"

oc new-app -f postgresql.json
sleep 20

# deploying 3 keycloak instances
oc new-app -f keycloak.json
```

### Customization options

#### KeyCloak

edit environment variables:

                "env":[
                  {
                    "name":"KEYCLOAK_USER",
                    "value":"admin"
                  },
                  {
                    "name":"KEYCLOAK_PASSWORD",
                    "value":"admin"
                  },
                  {
                    "name":"POSTGRES_DATABASE",
                    "value":"userdb"
                  },
                  {
                    "name":"POSTGRES_USER",
                    "value":"keycloak"
                  },
                  {
                    "name":"POSTGRES_PASSWORD",
                    "value":"password"
                  },
                  {
                    "name":"POSTGRES_PORT_5432_TCP_ADDR",
                    "value":"postgres"
                  },
                  {
                    "name":"POSTGRES_PORT_5432_TCP_PORT",
                    "value":"5432"
                  },
                  {
                    "name":"OPERATING_MODE",
                    "value":"clustered"
                  }
                ]


#### Postgresql

            "env": [
              {
                "name": "POSTGRESQL_USER",
                "value": "keycloak"
              },
              {
                "name": "POSTGRESQL_PASSWORD",
                "value": "password"
              },
              {
                "name": "POSTGRESQL_DATABASE",
                "value": "userdb"
              },
              {
                "name": "POSTGRESQL_ADMIN_PASSWORD",
                "value": "password"
              }
            ]
