```bash
#!/bin/bash

# Old Artifactory domain (only a part of the URL)
OLD_DOMAIN="artifactory.ns1s.site.co.uk"

# Branch name for the update
BRANCH_NAME="snapshot-abcd-1234"

# Log file to track updates
LOG_FILE="migration_log.txt"

# Clear the log file before starting
echo "Migration Log - $(date)" > "$LOG_FILE"
echo "======================================" >> "$LOG_FILE"

# Loop through all directories in the current folder (assuming each is a Git repo)
for REPO in */; do
    # Ensure it's a directory
    [[ -d "$REPO" ]] || continue

    echo "Processing repository: $REPO"
    cd "$REPO" || continue

    # Ensure it's a Git repository
    if [ ! -d ".git" ]; then
        echo "Skipping $REPO (not a Git repository)"
        cd ..
        continue
    fi

    # Get the GitLab project URL (assumes origin is correctly set)
    GIT_REMOTE_URL=$(git config --get remote.origin.url)
    GIT_BRANCH_URL="${GIT_REMOTE_URL/.git/}/-/tree/$BRANCH_NAME"

    # Check if the branch exists locally first
    if git rev-parse --verify "$BRANCH_NAME" &>/dev/null; then
        echo "Branch '$BRANCH_NAME' exists locally. Checking it out..."
        git checkout "$BRANCH_NAME"
    else
        # Fetch remote branches and check if the branch exists remotely
        git fetch origin "$BRANCH_NAME" &>/dev/null
        if git rev-parse --verify "origin/$BRANCH_NAME" &>/dev/null; then
            echo "Branch '$BRANCH_NAME' exists on remote. Checking it out..."
            git checkout -t origin/"$BRANCH_NAME"
        else
            echo "Branch '$BRANCH_NAME' does not exist. Creating new branch..."
            git checkout -b "$BRANCH_NAME"
        fi
    fi

    # Find all occurrences of URLs containing the OLD_DOMAIN
    echo "Searching for URLs containing '$OLD_DOMAIN'..."
    mapfile -t URLS < <(grep -rEo "https?://$OLD_DOMAIN[^\"]+" . | sort -u)

    if [[ ${#URLS[@]} -eq 0 ]]; then
        echo "No matching URLs found in $REPO. Skipping update..."
        cd ..
        continue
    fi

    # Read each unique URL and prompt the user for a replacement
    for OLD_URL in "${URLS[@]}"; do
        echo "Found URL: $OLD_URL"
        echo -n "Enter the updated URL: "
        read -r NEW_URL

        if [[ -n "$NEW_URL" ]]; then
            echo "Replacing occurrences of:"
            echo "  OLD: $OLD_URL"
            echo "  NEW: $NEW_URL"

            # Perform the replacement in all files
            find . -type f -exec sed -i "s|$OLD_URL|$NEW_URL|g" {} +
        fi
    done

    # Verify changes
    MODIFIED_FILES=$(git diff --name-only)
    if [[ -n "$MODIFIED_FILES" ]]; then
        echo "Changes made in $REPO:"
        echo "$MODIFIED_FILES"

        # Commit and push changes
        git commit -am "Updating Artifactory references"
        git push --set-upstream origin "$BRANCH_NAME"

        # Log the changes
        echo "Repo: $REPO" >> "../$LOG_FILE"
        echo "Branch: $GIT_BRANCH_URL" >> "../$LOG_FILE"
        echo "Modified Files:" >> "../$LOG_FILE"
        echo "$MODIFIED_FILES" >> "../$LOG_FILE"
        echo "---------------------------" >> "../$LOG_FILE"
    else
        echo "No changes detected in $REPO."
    fi

    # Return to the parent directory
    cd ..
done

echo "All repositories processed. See '$LOG_FILE' for details."
```
