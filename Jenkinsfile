@Library('github.com/fabric8io/fabric8-pipeline-library@master')
def utils = new io.fabric8.Utils()
def keycloakVersion = '3.2.0.Final'
def branchName = '3.2.0.Final-patch'

node{
    properties([
        disableConcurrentBuilds()
        ])
}

mavenTemplate{
    dockerNode{
        ws {
            timeout(time: 1, unit: 'HOURS') {
                checkout scm
                if (utils.isCI()){
                    echo 'CI not provided by fabric8 yet'

                } else if (utils.isCD()){
                    stage('build keycloak'){
                        sh "git clone -b ${branchName}  --depth 1 https://github.com/fabric8-services/keycloak.git"
                        dir('keycloak'){
                            container('maven'){
                                echo 'fabric8: Run mv clean install -DskipTests=true -Pdistribution'
                                sh 'mvn clean install -DskipTests=true -Pdistribution'

                                echo 'fabric8: Listing the directory server-dist'
                                sh 'ls distribution/server-dist/'
                                echo 'fabric8: Listing the directory target'
                                sh 'ls distribution/server-dist/target'
                                echo 'fabric8: keycloak-server build completed successfully!'
                            }
                        }
                    }

                    def tag = getNewVersion{}
                    stage('build and push image to dockerhub'){
                        container('docker'){
                            sh "cp keycloak/distribution/server-dist/target/keycloak-${keycloakVersion}.tar.gz docker"

                            sh "docker build -t docker.io/fabric8/keycloak-postgres:${tag} -f ./docker/Dockerfile ./docker"

                            sh "rm docker/keycloak-${keycloakVersion}.tar.gz"

                            sh "docker push docker.io/fabric8/keycloak-postgres:${tag}"
                            echo 'fabric8: Image pushed, ready to update deployed app'
                        }
                    }
                    updateDownstreamDependencies(tag)
                }
            }
        }
    }
}

def updateDownstreamDependencies(v) {
  pushPomPropertyChangePR {
    propertyName = 'keycloak.version'
    projects = [
            'fabric8-apps/keycloak-app'
    ]
    version = v
    containerName = 'maven'
  }
}
