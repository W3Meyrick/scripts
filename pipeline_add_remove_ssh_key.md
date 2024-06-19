```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['add', 'remove'], description: 'Action to perform: add or remove SSH key')
        string(name: 'USERNAME', defaultValue: '', description: 'Username associated with the SSH key')
        text(name: 'SSH_KEY', defaultValue: '', description: 'SSH key to add (required if action is add)')
        string(name: 'PROJECT', defaultValue: '', description: 'Project name')
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

                    // Clean up temporary file
                    sh "rm -f ${tempFile}"
                }
            }
        }
    }
}
```
