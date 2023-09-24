#!/bin/sh

# failsafe
set -eEuo pipefail

# list all images and count
echo "Counting image history"
gcloud artifacts docker images list $(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE) --include-tags  | grep -v DIGEST | wc -l

# demote 'live' to 'previous'
for DIGEST in $(gcloud artifacts docker images list $(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE) --include-tags --filter="tags='live'" --format='get(DIGEST)'); do
  echo "Demoting 'live' -> 'previous': " + $DIGEST
  gcloud artifacts docker tags add -q "$(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE)@${DIGEST}" "$(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE):previous"
  gcloud artifacts docker tags delete -q "$(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE):live"
done

# update 'staged' to 'live'
for DIGEST in $(gcloud artifacts docker images list $(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE) --include-tags --filter="tags='staged'" --format='get(DIGEST)'); do
  echo "Updating 'staged' -> 'live': " + $DIGEST
  gcloud artifacts docker tags add -q "$(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE)@${DIGEST}" "$(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE):live"
  gcloud artifacts docker tags delete -q "$(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE):staged"
done

# delete untagged images
for DIGEST in $(gcloud artifacts docker images list $(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE) --include-tags --filter="tags=''" --format='get(DIGEST)'); do
  echo "Deleting untagged image: " + $DIGEST
  gcloud artifacts docker images delete -q "$(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE)@${DIGEST}"
done

# list all images and count
echo "Counting image history"
gcloud artifacts docker images list $(cat ./REGION)-docker.pkg.dev/$(cat ./PROJECT_ID)/$(cat ./ARTIFACT_REPO)/$(cat ./RUN_SERVICE) --include-tags  | grep -v DIGEST | wc -l