pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  } 

  stages {
    stage('Test 2.2') {
      environment {
        RUBY_VERSION = '2.2.0'
      }

      steps {
        milestone(1)
            
        sh './test.sh'

        junit 'spec/reports/*.xml, features/reports/*.xml'
      }
    }

    stage('Test 2.3') {
      environment {
        RUBY_VERSION = '2.3.0'
      }

      steps {
        sh './test.sh'

        junit 'spec/reports/*.xml, features/reports/*.xml'
      }
    }

    stage('Test 2.4') {
      environment {
        RUBY_VERSION = '2.4.0'
      }

      steps {
        sh './test.sh'

        junit 'spec/reports/*.xml, features/reports/*.xml'
      }
    }

    // Only publish to RubyGems if branch is 'master'
    // AND someone confirms this stage within 5 minutes
    stage('Publish to RubyGems?') {
      when {
        allOf {
          branch 'master'
          expression {
            boolean publish = false

            if(env.PUBLISH_GEM == "true") {
              return true
            }

            try {
              timeout(time: 5, unit: 'MINUTES') {
                input(message: 'Publish to RubyGems?')
                publish = true
              }
            } catch (final ignore) {
              publish = false
            }

            return publish
          }
        }
      }
      steps {
        milestone(2)
        build(job: 'release-rubygems', parameters: [
          string(name: 'GEM_NAME', value: 'conjur-api'),
          string(name: 'GEM_BRANCH', value: "${env.BRANCH_NAME}")
        ])
        milestone(3)
      }
    }
  }

  post {
    always {
      sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
    }      
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}
