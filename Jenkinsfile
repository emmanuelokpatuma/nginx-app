@Library('mySharedLibrary') _

def buildTag = ''

pipeline {
    agent { label 'build-agent' }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Git branch to build')
        string(name: 'APP_VERSION', defaultValue: '1.0.0', description: 'App version/tag')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'DEPLOY', defaultValue: true, description: 'Deploy after build?')
    }

    environment {
        HELM_RELEASE = 'nginx-app'
        K8S_NAMESPACE = 'default'
        DOCKER_REGISTRY = 'omagu' // replace with your Docker registry
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/gititc778/sampleApp.git', branch: "${params.BRANCH}"
            }
        }

        stage('Generate Build Tag') {
            steps {
                script {
                    buildTag = "${params.APP_VERSION}-${env.BUILD_NUMBER}"
                    echo "Generated build tag: ${buildTag}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    buildDocker("${buildTag}") // calls your shared library function
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    pushDocker("${buildTag}") // calls your shared library function
                }
            }
        }

        stage('Deploy via Helm') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                script {
                    sh """
                        helm upgrade --install ${HELM_RELEASE} ./charts/nginx-app \
                            --namespace ${K8S_NAMESPACE} \
                            --set image.repository=${DOCKER_REGISTRY}/nginx-app \
                            --set image.tag=${buildTag} \
                            --wait
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Build tag: ${buildTag}"
        }
    }
}
