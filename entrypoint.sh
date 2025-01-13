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

log_info() {
  echo -e "\033[1;34m[INFO] \033[0m $1"
}

log_error() {
  echo -e "\033[1;31m[ERROR] \033[0m $1"
}

# Log and check command success/failure
check_command() {
  if [ $? -ne 0 ]; then
    log_error "$1 failed."
    exit 1
  else
    log_info "$1 succeeded."
  fi
}

log_info "Starting sync process..."

if [[ -z "$UPSTREAM_REPO" ]]; then
  log_error "Missing \$UPSTREAM_REPO"
  exit 1
fi

if [[ -z "$DOWNSTREAM_BRANCH" ]]; then
  log_info "Missing \$DOWNSTREAM_BRANCH, Defaulting to ${UPSTREAM_BRANCH}"
  DOWNSTREAM_BRANCH=$UPSTREAM_BRANCH
fi

if ! echo "$UPSTREAM_REPO" | grep '\.git'; then
  UPSTREAM_REPO="https://github.com/${UPSTREAM_REPO_PATH}.git"
fi

log_info "UPSTREAM_REPO set to: $UPSTREAM_REPO"

git clone "https://github.com/${GITHUB_REPOSITORY}.git" work
check_command "git clone"

cd work || { log_error "Missing work dir"; exit 2; }

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --local user.password ${GITHUB_TOKEN}

git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
check_command "git remote set-url"

git remote add upstream "$UPSTREAM_REPO"
check_command "git remote add upstream"

git fetch ${FETCH_ARGS} upstream
check_command "git fetch"

git remote -v

git checkout ${DOWNSTREAM_BRANCH}
check_command "git checkout"

case ${SPAWN_LOGS} in
  (true)    
    log_info "Syncing from upstream repo https://github.com/dabreadman/sync-upstream-repo, keeping CI alive."
    echo -n "UNIX Time: " >> sync-upstream-repo
    date +"%s" >> sync-upstream-repo
    git add sync-upstream-repo
    git commit sync-upstream-repo -m "Syncing upstream"
    check_command "git commit";;
  (false)   
    log_info "Not spawning time logs";;
esac

git push origin
check_command "git push origin"

MERGE_RESULT=$(git merge ${MERGE_ARGS} upstream/${UPSTREAM_BRANCH})
check_command "git merge"

if [[ -z "$MERGE_RESULT" ]]; then
  log_error "Merge failed or no changes."
  exit 1
elif [[ $MERGE_RESULT != *"Already up to date."* ]]; then
  git commit -m "Merged upstream"
  check_command "git commit"
  git push ${PUSH_ARGS} origin ${DOWNSTREAM_BRANCH} || exit $?
  check_command "git push"
fi

cd ..
rm -rf work

log_info "Sync completed successfully!"
