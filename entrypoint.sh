#!/bin/bash

if [ -z "$UPSTREAM_REPO" ] || [ -z "$BRANCH" ] || [ -z "$TARGET_BRANCH" ] || [ -z "$GH_TOKEN" ]; then
  echo "Error: Missing required environment variables."
  exit 1
fi

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"

git clone --branch $BRANCH https://$GITHUB_ACTOR:${GH_TOKEN}@github.com/$GITHUB_REPOSITORY.git
if [ $? -ne 0 ]; then
  echo "Failed: Cloning repository failed."
  exit 1
fi

cd $(basename "$GITHUB_REPOSITORY" .git)

git remote add upstream $UPSTREAM_REPO
if [ $? -ne 0 ]; then
  echo "Failed: Adding upstream remote failed."
  exit 1
fi

git fetch upstream
if [ $? -ne 0 ]; then
  echo "Failed: Fetching upstream changes failed."
  exit 1
fi

git checkout $TARGET_BRANCH
if [ $? -ne 0 ]; then
  echo "Failed: Checking out target branch failed."
  exit 1
fi

git merge upstream/$BRANCH
if [ $? -ne 0 ]; then
  echo "Failed: Merging changes failed."
  exit 1
fi

git push origin $TARGET_BRANCH
if [ $? -ne 0 ]; then
  echo "Failed: Pushing changes failed."
  exit 1
fi

echo "Passed: Sync and merge successful!"
