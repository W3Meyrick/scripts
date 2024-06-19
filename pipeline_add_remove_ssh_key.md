```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['add', 'remove'], description: 'Action to perform: add or remove SSH key')
        string(name: 'USERNAME', defaultValue: '', description: 'Username associated with the SSH key')
        text(name: 'SSH_KEY', defaultValue: '', description: 'SSH key to add (required if action is add)')
        string(name: 'PROJECT', defaultValue: '', description: 'Project name')
    }

    environment {
        GCS_BUCKET = 'your-fixed-bucket-name' // Replace with your actual GCS bucket name
    }

    stages {
        stage('Process SSH Key') {
            steps {
                script {
                    def action = params.ACTION
                    def username = params.USERNAME
                    def sshKey = params.SSH_KEY
                    def project = params.PROJECT
                    def tempFile = "${WORKSPACE}/existing_ssh_keys.txt"

                    // Retrieve existing SSH keys
                    sh "gcloud compute project-info describe --project=${project} --format='get(commonInstanceMetadata.items[?key==`ssh-keys`].value)' > ${tempFile}"

                    def existingKeys = readFile(tempFile).trim()

                    if (action == 'add') {
                        // Add the new SSH key
                        def formattedKey = "${username}:${sshKey}"
                        if (existingKeys) {
                            existingKeys += "\n${formattedKey}"
                        } else {
                            existingKeys = formattedKey
                        }
                    } else if (action == 'remove') {
                        // Remove the specified SSH key
                        existingKeys = existingKeys.split('\n').findAll { !it.startsWith("${username}:") }.join('\n')
                    }

                    // Write the updated keys back to the file
                    writeFile file: tempFile, text: existingKeys

                    // Update the project metadata with the new list of SSH keys
                    sh """
                        gcloud compute project-info add-metadata \\
                            --project=${project} \\
                            --metadata-from-file ssh-keys=${tempFile}
                    """

                    // Create a date formatted backup file name
                    def dateStr = new Date().format("yyyy-MM-dd")
                    def backupFileName = "ssh-keys-backup-${project}-${dateStr}.txt"

                    // Copy the temp file to the GCS bucket
                    sh "gsutil cp ${tempFile} gs://${GCS_BUCKET}/${backupFileName}"

                    // Remove old backups, keeping only the 10 most recent for the specific project
                    def backups = sh(script: "gsutil ls gs://${GCS_BUCKET}/ssh-keys-backup-${project}-*.txt", returnStdout: true).trim().split('\n')
                    if (backups.size() > 10) {
                        def filesToDelete = backups.sort().take(backups.size() - 10)
                        filesToDelete.each { file ->
                            sh "gsutil rm ${file}"
                        }
                    }

                    // Clean up temporary file
                    sh "rm -f ${tempFile}"
                }
            }
        }
    }
}
```
