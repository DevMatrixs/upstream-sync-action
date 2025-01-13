#!/bin/bash

set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

date_stamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

print_info() {
    echo -e "${GREEN}[INFO] $1${RESET} $(date_stamp)"
}

print_error() {
    echo -e "${RED}[ERROR] $1${RESET} $(date_stamp)"
}

check_repo_exists() {
    print_info "Checking if the repository exists at $1..."
    git ls-remote "$1" &> /dev/null
    if [[ $? -ne 0 ]]; then
        print_error "Repository does not exist or invalid URL: $1"
        exit 1
    fi
    print_info "Repository exists: $1"
}

set_git_config() {
    if [[ -n "$CUSTOM_USER_NAME" && -n "$CUSTOM_USER_EMAIL" ]]; then
        print_info "Setting custom Git user name and email..."
        git config --global user.name "$CUSTOM_USER_NAME"
        git config --global user.email "$CUSTOM_USER_EMAIL"
        print_info "Custom Git user name and email set."
    else
        print_info "No custom Git user info provided, using default Git config."
    fi
}

GITHUB_TOKEN=$1
FORK_REPO=$2
UPSTREAM_REPO=$3
BRANCH=${4:-main}
CUSTOM_USER_NAME=$5
CUSTOM_USER_EMAIL=$6

if [[ -z "$GITHUB_TOKEN" || -z "$FORK_REPO" || -z "$UPSTREAM_REPO" ]]; then
    print_error "Missing required arguments."
    echo "Usage: entrypoint.sh <GITHUB_TOKEN> <FORK_REPO> <UPSTREAM_REPO> [BRANCH] [CUSTOM_USER_NAME] [CUSTOM_USER_EMAIL]"
    exit 1
fi

print_info "Starting the synchronization process..."

check_repo_exists "$FORK_REPO"
check_repo_exists "$UPSTREAM_REPO"

print_info "Validating branch '$BRANCH' in upstream repository..."
git ls-remote --heads "$UPSTREAM_REPO" "$BRANCH" &> /dev/null
if [[ $? -ne 0 ]]; then
    print_error "Branch '$BRANCH' does not exist in upstream repository: $UPSTREAM_REPO"
    exit 1
else
    print_info "Branch '$BRANCH' validated successfully."
fi

print_info "Cloning the fork repository..."
git clone https://$GITHUB_TOKEN@$FORK_REPO repo
cd repo
print_info "Fork repository cloned successfully."

print_info "Adding upstream repository..."
git remote add upstream $UPSTREAM_REPO
print_info "Upstream repository added successfully."

set_git_config

print_info "Fetching upstream changes..."
git fetch upstream
print_info "Upstream changes fetched successfully."

print_info "Checking out the branch '$BRANCH'..."
git checkout $BRANCH
print_info "Branch '$BRANCH' checked out successfully."

print_info "Merging upstream/$BRANCH into $BRANCH..."
git merge upstream/$BRANCH --no-ff -m "Syncing with upstream/$BRANCH"
if [[ $? -ne 0 ]]; then
    print_error "Merge conflict occurred during the merge."
    print_error "Please resolve the conflicts manually and then commit the changes."
    git status
    exit 1
else
    print_info "Merge completed successfully."
fi

print_info "Pushing changes back to fork repository..."
git push origin $BRANCH
print_info "Changes pushed to fork repository successfully."

print_info "Synchronization process completed successfully!"
