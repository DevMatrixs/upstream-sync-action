#!/bin/bash

log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

log_separator() {
    echo -e "\033[1;30m-------------------------------------------------\033[0m"
}

log_header() {
    echo -e "\033[1;34mUpstream Sync Process Started...\033[0m"
    log_separator
}

log_footer() {
    log_separator
    echo -e "\033[1;34mUpstream Sync Process Completed.\033[0m"
}

GITHUB_TOKEN=$1
UPSTREAM_REPO=$2
SOURCE_BRANCH=$3
TARGET_BRANCH=$4

# Check if all required arguments are provided
if [ -z "$GITHUB_TOKEN" ] || [ -z "$UPSTREAM_REPO" ] || [ -z "$SOURCE_BRANCH" ] || [ -z "$TARGET_BRANCH" ]; then
    log_error "Missing required arguments: GitHub Token, Upstream Repo, Source Branch, or Target Branch."
    exit 1
fi

log_header

# Configure Git
log_info "Setting up Git config with GitHub token for authentication."
git config --global user.email "github-actions@github.com"
git config --global user.name "GitHub Actions"
git config --global url."https://$GITHUB_TOKEN@github.com".insteadOf "https://github.com"

# Handle "dubious ownership" error by marking the directory as safe
log_info "Marking the workspace directory as safe for Git operations."
git config --global --add safe.directory /github/workspace || {
    log_error "Failed to mark /github/workspace as a safe directory."
    exit 1
}

# Add upstream remote
log_info "Adding upstream remote: $UPSTREAM_REPO"
git remote add upstream https://github.com/$UPSTREAM_REPO.git || {
    log_error "Failed to add upstream remote."
    exit 1
}

# Fetch upstream repository
log_info "Fetching changes from upstream repository..."
git fetch upstream || {
    log_error "Fetching from upstream failed."
    exit 1
}

# Check if source branch exists
log_info "Checking if the source branch '$SOURCE_BRANCH' exists..."
if ! git ls-remote --heads upstream $SOURCE_BRANCH > /dev/null; then
    log_error "Source branch '$SOURCE_BRANCH' does not exist in upstream repository."
    exit 1
fi

# Check if target branch exists
log_info "Checking if the target branch '$TARGET_BRANCH' exists..."
if ! git ls-remote --heads upstream $TARGET_BRANCH > /dev/null; then
    log_error "Target branch '$TARGET_BRANCH' does not exist in upstream repository."
    exit 1
fi

# Checkout the target branch
log_info "Checking out the target branch: $TARGET_BRANCH"
git checkout $TARGET_BRANCH || {
    log_error "Failed to checkout target branch '$TARGET_BRANCH'."
    exit 1
}

# Create a temporary branch from the source branch
log_info "Creating temporary branch from source branch: $SOURCE_BRANCH"
git checkout -b temp-branch upstream/$SOURCE_BRANCH || {
    log_error "Failed to create temporary branch from source branch '$SOURCE_BRANCH'."
    exit 1
}

# Merge changes
log_info "Merging changes from source branch '$SOURCE_BRANCH' into target branch '$TARGET_BRANCH'..."
git merge temp-branch || {
    log_error "Merge conflict detected or merge failed."
    exit 1
}

# Push changes to the target branch
log_info "Pushing changes to the target branch: $TARGET_BRANCH"
git push origin $TARGET_BRANCH || {
    log_error "Failed to push changes to target branch '$TARGET_BRANCH'."
    exit 1
}

# Delete temporary branch
log_info "Deleting temporary branch: temp-branch"
git branch -D temp-branch || {
    log_error "Failed to delete temporary branch."
    exit 1
}

log_footer
