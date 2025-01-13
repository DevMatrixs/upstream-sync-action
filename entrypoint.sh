#!/usr/bin/env bash

set -x

UPSTREAM_REPO=$1
UPSTREAM_BRANCH=$2
DOWNSTREAM_BRANCH=$3
GITHUB_TOKEN=$4
FETCH_ARGS=$5
MERGE_ARGS=$6
PUSH_ARGS=$7
SPAWN_LOGS=$8

# Colors for better visibility
COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;32m"      # Green for INFO
COLOR_ERROR="\033[1;31m"     # Red for ERROR
COLOR_SUCCESS="\033[1;32m"   # Green for SUCCESS
COLOR_WARNING="\033[1;33m"   # Yellow for WARNING
COLOR_BOLD="\033[1m"         # Bold text

log_error() {
  echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1"
}

log_success() {
  echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $1"
}

log_warning() {
  echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} $1"
}

# Log and check command success/failure
check_command() {
  if [ $? -ne 0 ]; then
    log_error "$1 failed."
    exit 1
  else
    log_success "$1 succeeded."
  fi
}

# Main Process
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Starting sync process..."

# Validate upstream repository
if [[ -z "$UPSTREAM_REPO" ]]; then
  log_error "Missing \$UPSTREAM_REPO"
  exit 1
fi

# Set default for downstream branch if not provided
if [[ -z "$DOWNSTREAM_BRANCH" ]]; then
  log_warning "Missing \$DOWNSTREAM_BRANCH, Defaulting to ${UPSTREAM_BRANCH}"
  DOWNSTREAM_BRANCH=$UPSTREAM_BRANCH
fi

# Check if upstream repo URL contains '.git'
if ! echo "$UPSTREAM_REPO" | grep '\.git'; then
  UPSTREAM_REPO="https://github.com/${UPSTREAM_REPO_PATH}.git"
fi

echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} UPSTREAM_REPO set to: $UPSTREAM_REPO"

# Clone the repository
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Cloning the repository..."
git clone "https://github.com/${GITHUB_REPOSITORY}.git" work
check_command "git clone"

cd work || { log_error "Missing work dir"; exit 2; }

# Configure git user details
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Configuring Git user..."
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --local user.password ${GITHUB_TOKEN}

# Set remote URL with access token
git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
check_command "git remote set-url"

# Add upstream remote
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Adding upstream remote..."
git remote add upstream "$UPSTREAM_REPO"
check_command "git remote add upstream"

# Fetch changes from upstream
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Fetching changes from upstream..."
git fetch ${FETCH_ARGS} upstream
check_command "git fetch"

# Show remotes
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Listing remotes..."
git remote -v

# Checkout the downstream branch
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Checking out branch ${DOWNSTREAM_BRANCH}..."
git checkout ${DOWNSTREAM_BRANCH}
check_command "git checkout"

# Spawn logs if needed
case ${SPAWN_LOGS} in
  (true)    
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Syncing from upstream repo and keeping CI alive."
    echo -n "UNIX Time: " >> sync-upstream-repo
    date +"%s" >> sync-upstream-repo
    git add sync-upstream-repo
    git commit -m "Syncing upstream"
    check_command "git commit";;
  (false)   
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Not spawning time logs";;
esac

# Push to origin
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Pushing changes to origin..."
git push origin
check_command "git push origin"

# Merge upstream changes
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Merging upstream changes..."
MERGE_RESULT=$(git merge ${MERGE_ARGS} upstream/${UPSTREAM_BRANCH})
check_command "git merge"

if [[ -z "$MERGE_RESULT" ]]; then
  log_error "Merge failed or no changes."
  exit 1
elif [[ $MERGE_RESULT != *"Already up to date."* ]]; then
  echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Changes detected. Committing merge."
  git commit -m "Merged upstream"
  check_command "git commit"
  git push ${PUSH_ARGS} origin ${DOWNSTREAM_BRANCH} || exit $?
  check_command "git push"
fi

# Cleanup
cd ..
rm -rf work

echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} Sync completed successfully!"
