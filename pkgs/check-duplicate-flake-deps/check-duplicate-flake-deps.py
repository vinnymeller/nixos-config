#!/usr/bin/env python3

import json
from argparse import ArgumentParser
from collections import defaultdict
from subprocess import run


def get_args():
    parser = ArgumentParser(
        description="Check for duplicated dependencies in a Nix flake."
    )
    parser.add_argument(
        "-f",
        "--flake",
        help="Path to the flake to check (defaults to current directory)",
        default=".",
        type=str,
    )
    return parser.parse_args()


def get_flake_metadata(flake: str) -> dict:
    metadata = run(["nix", "flake", "metadata", "--json", flake], capture_output=True)
    if metadata.returncode != 0:
        print("Error fetching flake metadata:", metadata.stderr.decode())
        exit(1)
    return json.loads(metadata.stdout)


def get_key(d, *keys) -> dict | str:
    for key in keys:
        d = d.get(key, {})
        if not d:
            print("Unexpected structure in flake metadata.")
            exit(1)
    return d


def main():
    args = get_args()
    flake_metadata = get_flake_metadata(args.flake)
    locked_nodes = get_key(flake_metadata, "locks", "nodes")
    user_inputs = get_key(locked_nodes, "root", "inputs")

    user_locks = defaultdict(set)

    for user_input_lock in user_inputs.values():
        lock = get_key(locked_nodes, user_input_lock, "locked")
        locked_repo = f"{lock['owner']}/{lock['repo']}".lower()
        user_locks[locked_repo].add(lock["rev"])

    duplicate_locks = defaultdict(set)
    for lock_name, lock in locked_nodes.items():
        if lock_name == "root" or lock_name in user_inputs.values():
            continue

        lock = get_key(lock, "locked")
        locked_repo = f"{lock['owner']}/{lock['repo']}".lower()
        if locked_repo in user_locks:
            duplicate_locks[locked_repo].add(lock_name)

    if not duplicate_locks:
        print("No duplicated dependencies found.")
        exit(0)

    # for each lock_name in duplicate_locks, search back through all locked inputs '.inputs' fields for the lock_name
    for lock_name, lock in locked_nodes.items():
        if lock_name == "root":
            continue
        inputs = lock.get("inputs", {})
        if not inputs:
            continue
        for input_name, input_locked_name in inputs.items():
            if isinstance(input_locked_name, str):
                for repo, names in duplicate_locks.items():
                    if input_locked_name in names:
                        print(
                            f"Duplicate dependency found: {repo} in {lock_name} (input: {input_name})"
                        )


if __name__ == "__main__":
    main()
