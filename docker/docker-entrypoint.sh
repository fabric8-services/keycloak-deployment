#!/bin/bash


KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:-"almighty"}
KEYCLOAK_SERVER_DOMAIN=${KEYCLOAK_SERVER_DOMAIN:-"localhost"}
INTERNAL_POD_IP=${INTERNAL_POD_IP:-"127.0.0.1"}


echo "Create keycloak store"
keytool -genkey -alias ${KEYCLOAK_SERVER_DOMAIN} -keyalg RSA -keystore keycloak.jks -validity 10950 -keypass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD << ANSWERS
${KEYCLOAK_SERVER_DOMAIN}
Keycloak
Red Hat
Westford
MA
US
yes
ANSWERS

mv keycloak.jks ./standalone/configuration

# Set the password of the keystore to the configuration file
sed -i -e "s/%%KEYSTORE_PASSWORD%%/${KEYSTORE_PASSWORD}/" ./standalone/configuration/standalone.xml
sed -i -e "s/%%KEYSTORE_PASSWORD%%/${KEYSTORE_PASSWORD}/" ./standalone/configuration/standalone-ha.xml

if [ $KEYCLOAK_USER ] && [ $KEYCLOAK_PASSWORD ]; then
    echo "Adding a new user..."
    /opt/jboss/keycloak/bin/add-user-keycloak.sh --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD
fi

if [[ "${MANUAL_MIGRATION}" == "yes" ]]; then
  export PGPASSWORD=${POSTGRESQL_ADMIN_PASSWORD}
  echo "Running manual db migration..."
  exec psql -U $POSTGRES_USER -h $POSTGRES_PORT_5432_TCP_ADDR -d $POSTGRES_DATABASE -a -q -f /opt/jboss/keycloak/keycloak-database-pre-update.sql
fi


if [[ "${OPERATING_MODE}" == "clustered" ]]; then
  echo "Starting keycloak-server on clustered mode..."
  exec /opt/jboss/keycloak/bin/standalone.sh --server-config=standalone-ha.xml -bmanagement=$INTERNAL_POD_IP -bprivate=$INTERNAL_POD_IP $@
else
  if [[ "${MANUAL_MIGRATION}" == "yes" ]]; then
    echo "Starting keycloak-server on standalone mode and migration post update script..."
    export PGPASSWORD=${POSTGRESQL_ADMIN_PASSWORD}
    # Run the server in parallel and wait 3minutes to run the script of post update
    (exec /opt/jboss/keycloak/bin/standalone.sh $@) & (sleep 180; exec psql -U $POSTGRES_USER -h $POSTGRES_PORT_5432_TCP_ADDR -d $POSTGRES_DATABASE -a -q -f /opt/jboss/keycloak/keycloak-database-post-update.sql)
  else
    echo "Starting keycloak-server on standalone mode..."
    exec /opt/jboss/keycloak/bin/standalone.sh $@
  fi
fi
exit $?
