#!/usr/bin/env bash

WORKTREE_ROOT=$(git worktree list | awk '{print $1}' | head -n 1)

git_branches() {
    git for-each-ref --sort=committerdate --format='%(refname:short)' refs/heads refs/remotes
}

err_branch_exists() {
    if git_branches | grep -Fxq "$1"; then
        echo "Branch $1 already exists"
        exit 1
    fi
}

COMMANDS="switch\nadd\nnew\nremove\norphan"

COMMAND=${1:-""}
if [ -z "$COMMAND" ]; then
    COMMAND=$(echo -e "$COMMANDS" | fzf --prompt="Command: ")
fi

if [ "$COMMAND" == "switch" ]; then
    twm -p "$( (git worktree list | awk '{print $1}') | fzf --prompt="Branch to switch to: ")"

elif [ "$COMMAND" == "add" ]; then
    NEW_WORKTREE=$(git_branches | fzf --prompt="Branch to add worktree for: ")
    WORKTREE_PATH="$WORKTREE_ROOT/$NEW_WORKTREE"
    git worktree add "$WORKTREE_PATH" "$NEW_WORKTREE"
    twm -p "$WORKTREE_PATH"

elif [ "$COMMAND" == "remove" ]; then
    CURRENT_DIR=$(pwd)
    REMOVE_WORKTREE=$( (git worktree list | awk '{print $1}') | fzf --prompt="Worktree to remove: ")
    git worktree remove "$REMOVE_WORKTREE" --force
    if [ "$CURRENT_DIR" == "$REMOVE_WORKTREE" ]; then
        twm -p "$WORKTREE_ROOT"
    fi

elif [ "$COMMAND" == "new" ]; then
    echo -n "Enter a name for your new branch: "
    read -r NEW_BRANCH
    err_branch_exists "$NEW_BRANCH"
    BASE_BRANCH=$(git_branches | fzf --prompt="Base $NEW_BRANCH off of: ")
    WORKTREE_PATH="$WORKTREE_ROOT/$NEW_BRANCH"

    git branch "$NEW_BRANCH" "$BASE_BRANCH"
    git worktree add "$WORKTREE_PATH" "$NEW_BRANCH"
    twm -p "$WORKTREE_PATH"

elif [ "$COMMAND" == "orphan" ]; then
    echo -n "Enter a name for your new orphan branch: "
    read -r NEW_BRANCH
    err_branch_exists "$NEW_BRANCH"
    WORKTREE_PATH="$WORKTREE_ROOT/$NEW_BRANCH"
    TEMP_BRANCH="__helper_$NEW_BRANCH"
    git branch "$TEMP_BRANCH"
    git worktree add "$WORKTREE_PATH" "$TEMP_BRANCH"
    pushd "$WORKTREE_PATH"
    git checkout --orphan "$NEW_BRANCH"
    git rm --cached -r .
    git clean -fdx -e '!/.git/'
    git commit --allow-empty -m "Initial commit"
    git branch -D "$TEMP_BRANCH"
    popd
    twm -p "$WORKTREE_PATH"

else
    echo "Unknown command: $COMMAND" >&1
    exit 1
fi
