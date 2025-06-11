```groovy
pipeline {
    agent any
    stages {
        stage('Identify Changes') {
            steps {
                script {
                    // Get list of changed files between HEAD and previous commit on main
                    def changedFiles = sh(script: "git diff --name-only HEAD~1 HEAD", returnStdout: true).trim().split("\n")

                    // Determine which projects were touched
                    def affectedProjects = [] as Set
                    for (file in changedFiles) {
                        if (file.startsWith("gcp-project-1/")) {
                            affectedProjects << "gcp-project-1"
                        }
                        if (file.startsWith("gcp-project-2/")) {
                            affectedProjects << "gcp-project-2"
                        }
                        // Add more as needed
                    }

                    // Store affected projects in environment variable for later use
                    env.AFFECTED_PROJECTS = affectedProjects.join(',')
                }
            }
        }

        stage('Run Affected Project Pipelines') {
            when {
                expression { return env.AFFECTED_PROJECTS?.trim() }
            }
            steps {
                script {
                    def projects = env.AFFECTED_PROJECTS.split(',')
                    for (project in projects) {
                        // Run steps or call other jobs as needed
                        build job: "${project}-pipeline", wait: false
                    }
                }
            }
        }
    }
}

```
