#!/bin/sh -l

set -e

echo "Starting upstream sync..."

GIT_NAME="${INPUT_GIT_NAME:-${GIT_NAME:-'GitHub Actions'}}"
GIT_EMAIL="${INPUT_GIT_EMAIL:-${GIT_EMAIL:-'actions@github.com'}}"

echo "Git user: $GIT_NAME"
echo "Git email: $GIT_EMAIL"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  exit 1
fi

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo "+ Cloning repository..."
if ! git clone https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git /tmp/repo; then
  echo "Error: Failed to clone the repository."
  exit 1
fi

cd /tmp/repo

echo "+ Adding upstream repository..."
if ! git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git; then
  echo "Error: Failed to set the remote URL."
  exit 1
fi

echo "+ Fetching upstream repository..."
if ! git remote add upstream https://github.com/$INPUT_UPSTREAM_REPO.git; then
  echo "Error: Failed to add the upstream repository."
  exit 1
fi

echo "* Fetching upstream changes..."
if ! git fetch upstream; then
  echo "Error: Failed to fetch changes from upstream."
  exit 1
fi

TARGET_BRANCH="${INPUT_TARGET_BRANCH:-main}"
UPSTREAM_BRANCH="${INPUT_UPSTREAM_BRANCH:-main}"

echo "+ Checking out to the target branch: $TARGET_BRANCH..."
if ! git checkout "$TARGET_BRANCH"; then
  echo "Error: Failed to checkout to the target branch: $TARGET_BRANCH."
  exit 1
fi

echo "+ Merging from upstream branch: $UPSTREAM_BRANCH..."
if ! git merge upstream/$UPSTREAM_BRANCH --no-ff --commit --message "Sync with upstream"; then
  echo "Error: Merge conflict or failed to merge with upstream."
  exit 1
fi

# Push the changes to the remote repository
echo "+ Pushing changes to the remote repository..."
if [ "${INPUT_FORCE_PUSH}" = "true" ]; then
  echo "Force pushing to $TARGET_BRANCH..."
  if ! git push origin "$TARGET_BRANCH" --force; then
    echo "Error: Failed to force push changes to the repository."
    exit 1
  fi
else
  echo "Pushing to $TARGET_BRANCH..."
  if ! git push origin "$TARGET_BRANCH"; then
    echo "Error: Failed to push changes to the repository."
    exit 1
  fi
fi

echo "Upstream sync complete!"
