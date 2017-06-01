

# Almighty-Keycloak Docker Image

To build this image is necessary to previously generate the executables of this
project.

`$ mvn clean install -DskipTests -pl :keycloak-server-dist -am -P distribution`

This generates some tarballs with the required executables. In our case, we just
need to copy the generated tarball from `server-dist` e.g. `keycloak-3.0.0.Final.tar.gz`.
You can find this tarball in `./distribution/server-dist/target/` directory.

`$ cp ../distribution/server-dist/target/keycloak-3.0.0.Final.tar.gz .`

Then you just need to build the docker image:

`$ docker build --tag IMAGE_NAME .`

If you would like to build image for clustered mode add build argument

`$ docker build  --build-arg OPERATING_MODE=clustered --tag IMAGE_NAME .`

# Openshift Configuration for clustered deployment

Majority of the config is defined in `DeploymentConfig` files you can find in `openshift` folder in the root of this repository.

There is one thing needed however to have properly functioning cluster (using [k8s PING protocol in `jgroups`](https://github.com/jgroups-extras/jgroups-kubernetes)). 
Service account has to have `view` privileges. This can be enabled using `oc` cli as follows:

```
$ oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default -n $(oc project -q)
```

