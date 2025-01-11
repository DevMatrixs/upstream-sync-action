#!/bin/sh -l

set -e

echo "Starting upstream sync..."

GIT_NAME="${INPUT_GIT_NAME:-${GIT_NAME:-'GitHub Actions'}}"
GIT_EMAIL="${INPUT_GIT_EMAIL:-${GIT_EMAIL:-'actions@github.com'}}"

echo "Git user: $GIT_NAME"
echo "Git email: $GIT_EMAIL"

GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo "Cloning repository..."
if ! git clone -q https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git /tmp/repo; then
  echo "Error: Failed to clone the repository."
  exit 1
fi

cd /tmp/repo

echo "Adding upstream repository..."
if ! git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git; then
  echo "Error: Failed to set the remote URL."
  exit 1
fi

echo "Fetching upstream repository..."
if ! git remote add upstream https://github.com/${INPUT_UPSTREAM_REPO}.git; then
  echo "Error: Failed to add the upstream repository."
  exit 1
fi

if ! git fetch -q upstream; then
  echo "Error: Failed to fetch changes from upstream."
  exit 1
fi

TARGET_BRANCH="${INPUT_TARGET_BRANCH:-main}"
UPSTREAM_BRANCH="${INPUT_UPSTREAM_BRANCH:-main}"

echo "Checking out to the target branch: $TARGET_BRANCH..."
if ! git checkout -q "$TARGET_BRANCH"; then
  echo "Error: Failed to checkout to the target branch: $TARGET_BRANCH."
  exit 1
fi

echo "Merging from upstream branch: $UPSTREAM_BRANCH..."
if ! git merge -q upstream/$UPSTREAM_BRANCH --no-ff --commit --message "Sync with upstream"; then
  echo "Error: Merge conflict or failed to merge with upstream."
  exit 1
fi

if [ $? -ne 0 ]; then
  echo "Conflict detected during merge. Please resolve the conflicts manually."
  exit 1
fi

echo "Pushing changes to target branch: $TARGET_BRANCH..."
if [ "$INPUT_FORCE_PUSH" = "true" ]; then
  if ! git push -q origin "$TARGET_BRANCH" --force; then
    echo "Error: Failed to force push to the target branch: $TARGET_BRANCH."
    exit 1
  fi
else
  if ! git push -q origin "$TARGET_BRANCH"; then
    echo "Error: Failed to push to the target branch: $TARGET_BRANCH."
    exit 1
  fi
fi

echo "Upstream sync complete!"
