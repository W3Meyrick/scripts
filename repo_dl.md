```bash
#!/bin/bash

# Define GitLab base URL
GITLAB_BASE_URL="https://gitlab.com"

# Path to the text file containing repository paths
TEXT_FILE="repos.txt"

# Read repositories line by line and clone them
while IFS= read -r REPO_PATH; do
    if [[ -n "$REPO_PATH" ]]; then  # Skip empty lines
        FULL_REPO_URL="$GITLAB_BASE_URL/$REPO_PATH.git"
        echo "Cloning from $FULL_REPO_URL..."
        
        git clone "$FULL_REPO_URL"
        
        if [ $? -eq 0 ]; then
            echo "Successfully cloned $FULL_REPO_URL"
        else
            echo "Failed to clone $FULL_REPO_URL"
        fi
    fi
done < "$TEXT_FILE"

echo "All repositories processed."


```
