pipeline {
    agent any

    options {
        // Keeps disk space clean on AWS Free Tier EBS volumes
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 15, unit: 'MINUTES')
    }

    environment {
        // Change this to your Docker Hub username and image name
        DOCKER_IMAGE_NAME = "devops-cicd-app"
        DOCKER_HUB_USER   = "harshu9671"
        DOCKER_CREDS_ID   = "dockerhub-credentials"
        FULL_IMAGE_NAME   = "${DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}"
    }

    stages {
        stage('1. Checkout SCM') {
            steps {
                echo "===> Checking out source code from Git..."
                checkout scm
                script {
                    // GIT_COMMIT is only guaranteed after checkout has completed.
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_SHA}"
                }
            }
        }

        stage('2. Test & Quality Checks') {
            steps {
                echo "===> Running automated unit & smoke tests..."
                sh '''
                    # Install dependencies and execute test suite
                    npm ci
                    npm test
                '''
            }
        }

        stage('3. Build Docker Image') {
            steps {
                echo "===> Building Docker Image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}..."
                sh '''
                    docker build -t ${FULL_IMAGE_NAME}:${IMAGE_TAG} -t ${FULL_IMAGE_NAME}:latest .
                '''
            }
        }

        stage('4. Push to Docker Hub') {
            steps {
                echo "===> Authenticating and pushing Docker image..."
                // Requires 'Username with password' credential in Jenkins with ID 'dockerhub-credentials'
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        trap 'docker logout >/dev/null 2>&1 || true' EXIT
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${FULL_IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('5. Deploy Container') {
            steps {
                echo "===> Deploying container with rollback-safe deployment script..."
                sh '''
                    chmod +x scripts/deploy.sh
                    ./scripts/deploy.sh ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('6. Post-Deployment Verification') {
            steps {
                echo "===> Verifying container health status..."
                sh '''
                    curl -sf http://localhost:3000/health || (echo "Health check failed!" && exit 1)
                    echo "Application is verified UP and healthy!"
                '''
            }
        }
    }

    post {
        always {
            echo "===> Cleaning up Jenkins workspace..."
            cleanWs()
        }
        success {
            echo "========================================================================"
            echo "🎉 PIPELINE SUCCESS: Deployed version ${IMAGE_TAG} successfully!"
            echo "========================================================================"
            // Optional Email Notification (uncomment once Jenkins Email Extension plugin is configured)
            /*
            emailext (
                subject: "✅ SUCCESS: Build #${BUILD_NUMBER} - ${JOB_NAME}",
                body: """<p>Pipeline succeeded for commit ${GIT_COMMIT.take(7)}.</p>
                         <p>Docker Image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}</p>
                         <p>Console Log: <a href='${BUILD_URL}'>${BUILD_URL}</a></p>""",
                to: 'your-email@example.com',
                mimeType: 'text/html'
            )
            */
        }
        failure {
            echo "========================================================================"
            echo "❌ PIPELINE FAILED: Build #${BUILD_NUMBER} encountered an error."
            echo "========================================================================"
            /*
            emailext (
                subject: "❌ FAILURE: Build #${BUILD_NUMBER} - ${JOB_NAME}",
                body: """<p>Pipeline failed for commit ${GIT_COMMIT.take(7)}.</p>
                         <p>Console Log: <a href='${BUILD_URL}'>${BUILD_URL}</a></p>""",
                to: 'your-email@example.com',
                mimeType: 'text/html'
            )
            */
        }
    }
}
