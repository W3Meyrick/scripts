export response=$(gcloud services list --log-http 2>&1 | awk '/-- response start --/,/-- response end --/ { if ($0 ~ /status:/) { sub("status: ", "", $0); print $0 } }')
