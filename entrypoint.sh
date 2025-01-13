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

echo -e "\033[1;34m[INFO] \033[0m Starting sync process..."

if [[ -z "$UPSTREAM_REPO" ]]; then
  echo -e "\033[1;31m[ERROR] \033[0m Missing \$UPSTREAM_REPO"
  exit 1
fi

if [[ -z "$DOWNSTREAM_BRANCH" ]]; then
  echo -e "\033[1;33m[WARNING] \033[0m Missing \$DOWNSTREAM_BRANCH, Defaulting to ${UPSTREAM_BRANCH}"
  DOWNSTREAM_BRANCH=$UPSTREAM_BRANCH
fi

if ! echo "$UPSTREAM_REPO" | grep '\.git'; then
  UPSTREAM_REPO="https://github.com/${UPSTREAM_REPO_PATH}.git"
fi

echo -e "\033[1;32m[INFO] \033[0m UPSTREAM_REPO set to: $UPSTREAM_REPO"

git clone "https://github.com/${GITHUB_REPOSITORY}.git" work
cd work || { echo -e "\033[1;31m[ERROR] \033[0m Missing work dir" && exit 2; }

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --local user.password ${GITHUB_TOKEN}

git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git remote add upstream "$UPSTREAM_REPO"
git fetch ${FETCH_ARGS} upstream
git remote -v

git checkout ${DOWNSTREAM_BRANCH}

case ${SPAWN_LOGS} in
  (true)    echo -n "Syncing from upstream repo https://github.com/dabreadman/sync-upstream-repo, keeping CI alive."\
            "UNIX Time: " >> sync-upstream-repo
            date +"%s" >> sync-upstream-repo
            git add sync-upstream-repo
            git commit sync-upstream-repo -m "Syncing upstream";;
  (false)   echo -e "\033[1;33m[INFO] \033[0m Not spawning time logs";;
esac

git push origin

MERGE_RESULT=$(git merge ${MERGE_ARGS} upstream/${UPSTREAM_BRANCH})

if [[ -z "$MERGE_RESULT" ]]; then
  echo -e "\033[1;31m[ERROR] \033[0m Merge failed or no changes."
  exit 1
elif [[ $MERGE_RESULT != *"Already up to date."* ]]; then
  git commit -m "Merged upstream"
  git push ${PUSH_ARGS} origin ${DOWNSTREAM_BRANCH} || exit $?
fi

cd ..
rm -rf work

echo -e "\033[1;32m[INFO] \033[0m Sync completed successfully!"
