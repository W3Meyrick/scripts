```groovy
def folderName = 'my-folder'
def pattern = ~/^build-.*/  // Regex for job names starting with "build-"

def folder = Jenkins.instance.getItemByFullName(folderName)
if (folder && folder instanceof com.cloudbees.hudson.plugins.folder.Folder) {
    folder.getItems().each { job ->
        if (job.name ==~ pattern) {
            job.disable()
            println "Disabled: ${folderName}/${job.name}"
        }
    }
} else {
    println "Folder not found or is not a folder: ${folderName}"
}
```
