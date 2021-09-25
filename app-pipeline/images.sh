#!/bin/sh

# failsafe
set -eEuo pipefail

# Load config values
# echo "Loading variables..."
# source ./install/variables.conf
pwd
# Echo substitution variables
#echo ${_REGION}
#echo ${_ARTIFACT_REPO}
#echo ${_RUN_SERVICE}
echo $(cat ./REGION)
echo $(cat ./ARTIFACT_REPO)
echo $(cat ./RUN_SERVICE)

# KMS NOTE: "--sort-by" command seems to be broke; modified commands are below this block
# test - list all images and count
#echo "Listing image history"
#gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --sort-by=UPDATE_TIME
#echo "Counting image history"
#gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --sort-by=UPDATE_TIME  | grep -v DIGEST | wc -l
echo "Counting image history"
gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags  | grep -v DIGEST | wc -l

# demote 'oldest' to ''
for DIGEST in $(gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --filter="tags='oldest'" --format='get(DIGEST)'); do
  echo "Demoting 'oldest' -> '': " + $DIGEST
  gcloud artifacts docker tags delete -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:oldest"
done

# demote 'older' to 'oldest'
for DIGEST in $(gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --filter="tags='older'" --format='get(DIGEST)'); do
  echo "Demoting 'older' -> 'oldest': " + $DIGEST
  gcloud artifacts docker tags add -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE@${DIGEST}" "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:oldest"
  gcloud artifacts docker tags delete -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:older"
done

# demote 'old' to 'older'
for DIGEST in $(gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --filter="tags='old'" --format='get(DIGEST)'); do
  echo "Demoting 'old' -> 'older': " + $DIGEST
  gcloud artifacts docker tags add -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE@${DIGEST}" "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:older"
  gcloud artifacts docker tags delete -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:old"
done

# demote 'live' to 'old'
for DIGEST in $(gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --filter="tags='live'" --format='get(DIGEST)'); do
  echo "Demoting 'live' -> 'old': " + $DIGEST
  gcloud artifacts docker tags add -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE@${DIGEST}" "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:old"
  gcloud artifacts docker tags delete -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:live"
done

# update 'staged' to 'live'
for DIGEST in $(gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --filter="tags='staged'" --format='get(DIGEST)'); do
  echo "Updating 'staged' -> 'live': " + $DIGEST
  gcloud artifacts docker tags add -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE@${DIGEST}" "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:live"
  gcloud artifacts docker tags delete -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE:staged"
done

# delete untagged images
for DIGEST in $(gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --filter="tags=''" --format='get(DIGEST)'); do
  echo "Deleting untagged image: " + $DIGEST
  gcloud artifacts docker images delete -q "$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE@${DIGEST}"
done

# KMS NOTE: "--sort-by" command seems to be broke; modified commands are below this block
# test - list all images and count
#echo "Listing image history"
#gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --sort-by=UPDATE_TIME
#echo "Counting image history"
#gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags --sort-by=UPDATE_TIME  | grep -v DIGEST | wc -l
echo "Counting image history"
gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO/$RUN_SERVICE --include-tags  | grep -v DIGEST | wc -l