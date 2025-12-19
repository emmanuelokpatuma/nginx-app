@Library('mySharedLibrary') _  // Ensure your shared library is available

def buildTag = ''  // Variable to store build tag

pipeline {
    agent { label 'build-agent' }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Git branch to build')
        string(name: 'APP_VERSION', defaultValue: '1.0.0', description: 'App version/tag')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'DEPLOY', defaultValue: true, description: 'Deploy after build?')
    }

    environment {
        HELM_RELEASE = 'nginx-app'  // Helm release name
        K8S_NAMESPACE = "${params.ENV}"   // Kubernetes namespace
        SONAR_PROJECT_KEY = 'sampleapp'
        SONAR_HOST_URL = 'http://20.75.196.235:9000/'  // Jenkins credentials ID for Docker
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
                script {
                    def branchToBuild = params.BRANCH ?: 'master'
                    git branch: branchToBuild,
                        url: 'https://github.com/emmanuelokpatuma/nginx-app.git', 
                        credentialsId: 'github-credentials' 
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool name: 'mysonarscanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                    withSonarQubeEnv('sonarkube-swathi') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=${SONAR_HOST_URL} \
                                -Dsonar.login=$SONAR_AUTH_TOKEN
                        """
                    }
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image and tag it
                    sh "docker build -t omagu/nginx-app:${params.APP_VERSION} ."
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'omagu',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push omagu/nginx-app:${params.APP_VERSION}
                    """
                }
            }
        }

        stage('Azure Login & AKS Setup') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aks-login', 
                    usernameVariable: 'AZURE_CLIENT_ID', 
                    passwordVariable: 'AZURE_CLIENT_SECRET'
                )]) {
                    sh """
                        az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant 2b32b1fa-7899-482e-a6de-be99c0ff5516
                        az aks get-credentials --resource-group rg-dev-flux --name aks-dev-flux-cluster --overwrite-existing
                        kubectl get pods -n default
                    """
                }
            }
        }

        stage('Create Helm Chart') {
            steps {
                script {
                    if (!fileExists('helm-chart/Chart.yaml')) {
                        sh 'helm create helm-chart'
                    }
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                sh """
                    echo "Deploying Helm chart to AKS..."
                    helm upgrade --install ${HELM_RELEASE} ./helm-chart \
                        --namespace ${params.ENV} \
                        --set image.tag=${params.APP_VERSION} \
                        --create-namespace
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Build tag: ${buildTag}"
        }
    }
}
