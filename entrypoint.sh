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

# Required arguments check
if [ -z "$GITHUB_TOKEN" ] || [ -z "$UPSTREAM_REPO" ] || [ -z "$SOURCE_BRANCH" ] || [ -z "$TARGET_BRANCH" ]; then
    log_error "Required arguments missing: GitHub Token, Upstream Repo, Source Branch, Target Branch."
    exit 1
fi

log_header

# Git setup
log_info "GitHub token ke saath Git config setup kiya ja raha hai."
git config --global user.email "github-actions@github.com"
git config --global user.name "GitHub Actions"
git config --global url."https://$GITHUB_TOKEN@github.com".insteadOf "https://github.com"

# Mark directory as safe for Git
log_info "Workspace directory ko Git ke liye safe mark kiya ja raha hai."
git config --global --add safe.directory /github/workspace || {
    log_error "Workspace ko safe directory mark karne mein error aayi."
    exit 1
}

# Add upstream remote
log_info "Upstream remote ko add kiya ja raha hai: $UPSTREAM_REPO"
git remote add upstream https://github.com/$UPSTREAM_REPO.git || {
    log_error "Upstream remote add karne mein error aayi."
    exit 1
}

# Fetch upstream repo
log_info "Upstream repository se changes fetch kiye ja rahe hain..."
git fetch upstream || {
    log_error "Upstream se fetch karne mein error aayi."
    exit 1
}

# Check if source branch exists
log_info "Source branch '$SOURCE_BRANCH' ko check kiya ja raha hai..."
if ! git ls-remote --heads upstream $SOURCE_BRANCH > /dev/null; then
    log_error "Source branch '$SOURCE_BRANCH' upstream repository mein nahi hai."
    exit 1
fi

# Check if target branch exists
log_info "Target branch '$TARGET_BRANCH' ko check kiya ja raha hai..."
if ! git ls-remote --heads upstream $TARGET_BRANCH > /dev/null; then
    log_error "Target branch '$TARGET_BRANCH' upstream repository mein nahi hai."
    exit 1
fi

# Checkout target branch
log_info "Target branch '$TARGET_BRANCH' ko checkout kiya ja raha hai."
git checkout $TARGET_BRANCH || {
    log_error "Target branch '$TARGET_BRANCH' ko checkout karne mein error aayi."
    exit 1
}

# Direct merge from source branch to target branch
log_info "Source branch '$SOURCE_BRANCH' ko directly target branch '$TARGET_BRANCH' mein merge kiya ja raha hai..."
git merge upstream/$SOURCE_BRANCH || {
    log_error "Merge conflict ya merge failure."
    exit 1
}

# Push changes to target branch
log_info "Target branch '$TARGET_BRANCH' mein changes push kiye ja rahe hain."
git push origin $TARGET_BRANCH || {
    log_error "Target branch '$TARGET_BRANCH' mein push karne mein error aayi."
    exit 1
}

log_footer
