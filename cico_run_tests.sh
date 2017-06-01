#!/bin/bash

. cico_setup.sh

function run_tests() {
  echo 'CICO: Cloning keycloak source code repo'
  git clone https://github.com/almighty/keycloak.git --branch master
  cd keycloak

  # echo 'CICO: Run mv clean install -pl :keycloak-server-dist -am -Pdistribution'
  # mvn clean install -pl :keycloak-server-dist -am -Pdistribution
  echo 'CICO: Run mv clean install -Pdistribution'
  mvn clean install -Pdistribution

  echo 'CICO: keycloak-server tests completed successfully!'
}

load_jenkins_vars;
install_deps;

run_tests;
