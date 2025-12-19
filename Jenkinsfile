@Library('mySharedLibrary') _  // Ensure your shared library is available

def buildTag = ''  // Variable to store build tag

pipeline {
    agent any

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Git branch to build')
        string(name: 'APP_VERSION', defaultValue: '1.0.0', description: 'App version/tag')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'DEPLOY', defaultValue: true, description: 'Deploy after build?')
    }

    environment {
        HELM_RELEASE = 'nginx-app'  // Name of your Helm release
        K8S_NAMESPACE = 'default'  // Kubernetes namespace
        DOCKER_REGISTRY = 'omagu'  // Docker registry name
        DOCKER_CREDENTIALS = 'docker-cred-id'  // Jenkins credentials ID for Docker
        KUBE_CREDENTIALS = 'aks-kubeconfig'  // Jenkins credentials ID for Kubernetes config
        // SONARQUBE_SERVER = 'SonarQubeServer1'  // Name of your SonarQube server configured in Jenkins
    }

    stages {
        stage('Generate Build Tag') {
            steps {
                script {
                    buildTag = "${params.APP_VERSION}-${env.BUILD_NUMBER}"
                    echo "Generated build tag: ${buildTag}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/emmanuelokpatuma/nginx-app.git', branch: "${params.BRANCH}"
            }
        }

        // stage('SonarQube Analysis') {
        //     steps {
        //         script {
        //             // Run SonarQube analysis
        //             withSonarQubeEnv(SONARQUBE_SERVER) {
        //                 sh 'mvn clean verify sonar:sonar'  // Adjust for your build tool, like Gradle or npm
        //             }
        //         }
        //     }
        // }

        // stage('SonarQube Quality Gate') {
        //     steps {
        //         script {
        //             // Wait for SonarQube quality gate status
        //             def qualityGate = waitForQualityGate()  // Checks SonarQube quality gate status
        //             if (qualityGate.status != 'OK') {
        //                 error "Quality gate failed: ${qualityGate.status}"  // Fail if quality gate fails
        //             }
        //         }
        //     }
        // }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image and tag it
                    docker.withRegistry('https://index.docker.io/v1/', env.DOCKER_CREDENTIALS) {
                        sh "docker build -t ${DOCKER_REGISTRY}/nginx-app:${buildTag} ."
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Push Docker image to the registry
                    docker.withRegistry('https://index.docker.io/v1/', env.DOCKER_CREDENTIALS) {
                        sh "docker push ${DOCKER_REGISTRY}/nginx-app:${buildTag}"
                    }
                }
            }
        }

        stage('Deploy to AKS') {
            when { expression { params.DEPLOY } }
            steps {
                script {
                    // Deploy to AKS using Helm
                    withCredentials([file(credentialsId: env.KUBE_CREDENTIALS, variable: 'KUBECONFIG')]) {
                        sh """
                        helm upgrade --install ${HELM_RELEASE} ./helm-chart --namespace ${K8S_NAMESPACE} --set image.tag=${buildTag} --set environment=${params.ENV}
                        """
                    }
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
