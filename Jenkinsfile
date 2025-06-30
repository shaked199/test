pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        IMAGE_NAME = 'shaked19924/nginx'
    }
    
    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    def timestamp = sh(script: "date +%Y%m%d%H%M", returnStdout: true).trim()
                    def imageTag = "${IMAGE_NAME}:${timestamp}"
                    
                    sh "docker build -t ${imageTag} ."
                    env.IMAGE_TAG = imageTag
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                script {
                    sh "echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin"
                    sh "docker push ${env.IMAGE_TAG}"
                }
            }
        }
    }
    
    post {
        always {
            sh "docker logout"
        }
    }
}