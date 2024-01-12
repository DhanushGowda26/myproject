pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/DhanushGowda26/task'
            }
        }

        stage('Setup Virtual Environment') {
            steps {
                 dir('myproject')
                sh '''
                    python3 -m venv .venv
                    source .venv/bin/activate
                    pip install -r requirements.txt  # Install your project dependencies
                '''
            }
        }
        stage('Deploy to Servers and test') {
            steps {
                // here we have used jenkins global credentials
                sshagent(['your_ssh_credentials_id']) {
                    sh '''
                        scp -r . ubuntu@3.145.37.182:/home/ubuntu/myproject
                        scp -r . ubuntu@3.128.155.51:/home/ubuntu/myproject
                    '''
                }

                // SSH into each server and restart the application
                sh '''
                    ssh ubuntu@3.145.37.182 'cd /home/ubuntu/myproject && pkill gunicorn && nohup gunicorn -b 0.0.0.0:8000 -t 120 app:app & &&  .venv/bin/python test/test_candidates.py http://3.145.37.182:8000'
                    ssh ubuntu@3.128.155.51 'cd /home/ubuntu/myproject && pkill gunicorn && nohup gunicorn -b 0.0.0.0:8000 -t 120 app:app & &&  .venv/bin/python test/test_candidates.py http://3.128.155.51:8000'
                '''
            }
        }
    }
    post {
        always {
            // Deactivate the virtual environment
            sh 'deactivate'
        }
    }
}
