#!/bin/bash

# SPDX-FileCopyrightText: 2026 CSC - IT Center for Science Ltd. <www.csc.fi>
#
# SPDX-License-Identifier: MIT

# Script for rsyncing projects from local to a remote HPC system,
# so that folder structure is preserved relative to a configurable "root" directory

# --- Replace with your username ---
REMOTE_USER=""

# Files are synced to /scratch/<summer school project>/$USER/$REMOTE_DIRECTORY.
# You can change to this to something else if you wish.
REMOTE_DIRECTORY="rsync"

if [ ! -n "$REMOTE_USER" ]; then
    echo "ERROR: Edit the script and set REMOTE_USER as your csc username."
    exit 1
fi

# Target remote is last argument. Earlier arguments are passed to rsync later.
TARGET_REMOTE="${@: -1}"
if [[ "$TARGET_REMOTE" != "lumi" && "$TARGET_REMOTE" != "mahti" ]]; then
    echo "Usage: $0 <additional rsync options> [lumi|mahti]"
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOCAL_ROOT=${SCRIPT_DIR}/../..

# --- Directories to sync (relative to LOCAL_ROOT). Will include subdirectories ---
SYNC_DIRS=(
    "summerschool"
)

# --- Remote config ---
if [[ "$TARGET_REMOTE" == "lumi" ]]; then
    REMOTE_HOST="$REMOTE_USER@lumi.csc.fi"
    REMOTE_ROOT="/scratch/project_462001452/$REMOTE_USER/$REMOTE_DIRECTORY"
elif [[ "$TARGET_REMOTE" == "mahti" ]]; then
    REMOTE_HOST="$REMOTE_USER@mahti.csc.fi"
    REMOTE_ROOT="/scratch/project_2019219/$REMOTE_USER/$REMOTE_DIRECTORY"
fi

# Rsync common options:
# -a : Archive mode (preserves permissions, symlinks, etc.)
# -v : Verbose (prints which file is being synced)
# -z : Compress data during transfer
# --mkpath : Create missing directories on the remote
# --exclude : Ignore specified files/patterns
# --exclude-from : like --exclude but read the patterns from file

# See tools/.rsyncignore for our default excludes. For example, we don't rsync image files.
# Some more flags that you may find useful; add as necessary.
# -P : Show progress for each file
# --delete : Remove remote files that are not present locally
RSYNC_OPTS=(-avz
    --exclude-from="$SCRIPT_DIR/../.gitignore"
    --exclude-from="$SCRIPT_DIR/.rsyncignore"
)
# Rsync version on Mahti is too old and does not support --mkpath. Parent directories must be created manually.
if [[ "$TARGET_REMOTE" == "lumi" ]]; then
    RSYNC_OPTS+=(--mkpath)
fi

# Append additional rsync flags, if any
length=$(($#-1))
EXTRA_OPTS=${@:1:$length}
RSYNC_OPTS+=($EXTRA_OPTS)

# --- Sync each subdirectory ---
for SUBDIR in "${SYNC_DIRS[@]}"; do
    # Note: the trailing / is important for preserving directory structure
    LOCAL_PATH="$LOCAL_ROOT/$SUBDIR/"
    REMOTE_PATH="$REMOTE_HOST:$REMOTE_ROOT/$SUBDIR"

    echo ">>> Syncing $SUBDIR -> $REMOTE_HOST:$REMOTE_ROOT/$SUBDIR"

    rsync "${RSYNC_OPTS[@]}" "$LOCAL_PATH" "$REMOTE_PATH"

    # Catch io error when parent directory doesn't exist on mahti and print a more descriptive error message.
    RSYNC_EXCODE="$?"
    if [[ $RSYNC_EXCODE -eq 11 ]] && [[ "$TARGET_REMOTE" == "mahti" ]] && [[ "$SUBDIR" == "summerschool" ]]; then
        echo -e "\nERROR: Rsync on Mahti is too old to automatically create parent directories. \n  Create $REMOTE_ROOT/$SUBDIR manually and try again."
        exit 1
    fi
    if [[ $RSYNC_EXCODE -ne 0 ]]; then
        echo "ERROR: rsync failed for $SUBDIR" >&2
        exit 1
    fi
done

echo ">>> Done."
