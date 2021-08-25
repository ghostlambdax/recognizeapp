def result = 1 // 1 by default means that the tests should be executed
def tasksCount = 8 
def gitCommit
def tasks = [:]
pipeline {
  options {
    buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '1'))
    timestamps ()
    //skipDefaultCheckout()
  }
  // agent { node { label 'jnlp-ec2-slave-default' } }
  agent any
  parameters {
    string(name: 'RUN_TEST', defaultValue: 'task_1,task_2,task_3,task_4,task_5,task_6,task_7,task_8', description: '', trim: true)
    string(name: 'REFRESH_CACHE', defaultValue: 'false', description: '', trim: true)
    string(name: 'AWS_DEFAULT_REGION', defaultValue: 'us-west-1', description: '' , trim: true)
  }
  environment {
    AWS_DEFAULT_REGION = "${params.AWS_DEFAULT_REGION}"
    RAILS_ENV          = "test"
    STASH_NAME         = "repository"
  }
  stages {
    stage('Initiating Pipeline'){
      steps{
        script{
          try {
            // parallel(tasks)
            if (env.CHANGE_ID) {
              echo "CHANGE_ID: ${env.CHANGE_ID}"
              echo "CHANGE_BRANCH: ${env.CHANGE_BRANCH}"
              echo "GIT_COMMIT: ${env.GIT_COMMIT}"
              gitCommit = env.GIT_COMMIT
              if (env.CHANGE_BRANCH.startsWith("releases")) {
                build job: '../DeploymentProcess/Ready to Deploy', parameters: [[$class: 'StringParameterValue', name: 'COMMIT', value: gitCommit], [$class: 'StringParameterValue', name: 'BRANCH', value: env.BRANCH_NAME], [$class: 'StringParameterValue', name: 'BUILD', value: env.BUILD_NUMBER], [$class: 'StringParameterValue', name: 'PRBRANCH', value: env.CHANGE_BRANCH]]
              }
              else {
                build job: '../DeploymentProcess/Ready to Patagonia', parameters: [[$class: 'StringParameterValue', name: 'COMMIT', value: gitCommit], [$class: 'StringParameterValue', name: 'BRANCH', value: env.BRANCH_NAME], [$class: 'StringParameterValue', name: 'BUILD', value: env.BUILD_NUMBER], [$class: 'StringParameterValue', name: 'PRBRANCH', value: env.CHANGE_BRANCH]]
                build job: '../DeploymentProcess/Ready to Everest', parameters: [[$class: 'StringParameterValue', name: 'COMMIT', value: gitCommit], [$class: 'StringParameterValue', name: 'BRANCH', value: env.BRANCH_NAME], [$class: 'StringParameterValue', name: 'BUILD', value: env.BUILD_NUMBER], [$class: 'StringParameterValue', name: 'PRBRANCH', value: env.CHANGE_BRANCH]]
              }
            }
          } catch (e) {
            currentBuild.result = "FAILED"
            throw e
          } finally {
            notifyBuild(currentBuild.result)
          }
        }
      }
    }
  }
}
def taskJob(int i, int res) {
  return {
    if (params.RUN_TEST.contains("task_${i}") && res != 0) {
      node('jnlp-ec2-slave') {
        try {
          stage ("task_${i}"){
            unstash "${STASH_NAME}"
            // Installing gems
            def install="true"
            sh "./nclouds/install_gems.sh ${params.REFRESH_CACHE} ${install}"
            sh "./nclouds/jenkins_test.sh ${i}"
            sh "./nclouds/start_test.sh ${i}"
          }
        }finally {
            sh 'killall -9 bundle || exit 0'
            sh 'killall -9 chrome || exit 0'
            deleteDir()
        }
      }
    }else if (params.RUN_TEST.contains("debug_${i}") && res != 0) {
      stage ("task_${i}"){
        sh "echo Debugging test for task ${i}, sleeping 6000"
        sh "sleep 6000"

      }      
    }else{
      stage ("task_${i}"){
        sh "echo Skipping test for task ${i}"
      }
    }
  }
}
def notifyBuild(String buildStatus = 'STARTED') {
  // // Default values
  // def colorName = 'RED'
  // def colorCode = '#FF0000'
  // def subject = ""
  // def details = """<p>STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
  //   <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>"""
  // // build status of null means successful
  // buildStatus =  buildStatus ?: 'SUCCESSFUL'
  // if (env.CHANGE_ID) {
  //   branch = env.CHANGE_BRANCH
  //   subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'\n ${branch} \n${env.CHANGE_TITLE}"
  // }
  // else {
  //   branch = env.BRANCH_NAME
  //   subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' - ${branch}"
  // }
  // def summary = "${subject}\n ${env.BUILD_URL}"
  // // Override default values based on build status
  // if (buildStatus == 'STARTED' || buildStatus == 'BUILDING'){
  //   color = 'YELLOW'
  //   colorCode = '#FFFF00'
  // } else if (buildStatus == 'SUCCESSFUL') {
  //   color = 'GREEN'
  //   colorCode = '#00FF00'
  // } else {
  //   color = 'RED'
  //   colorCode = '#FF0000'
  // }
  // // Send notifications
  // // slackSend (color: colorCode, message: summary)
}
