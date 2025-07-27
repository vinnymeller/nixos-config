#!/usr/bin/env bash

flake_path="${1:-.}"

check_dependency() {
	local dep_name="$1"
	if ! command -v "$dep_name" &>/dev/null; then
		echo "Error: $dep_name is not installed. Please install it to run this script." >&2
		exit 1
	fi
}

check_dependency "nix"
check_dependency "jq"

metadata=$(nix flake metadata "$flake_path" --json)

jq '
  # Store all nodes in a variable for easy lookup.
  .locks.nodes as $all_nodes
  |
  (
    # Step 1: Define $conflicting_repos by finding repos with multiple unique narHashes.
    (
      (
        $all_nodes
        | to_entries
        | reduce .[] as $entry ({};
            if $entry.value.locked.owner and $entry.value.locked.repo then
              .["\($entry.value.locked.owner)/\($entry.value.locked.repo)"] += [$entry.key]
            else . end
          )
      )
      | to_entries
      # FIX: Removed a stray period before the `[` that caused a syntax error.
      | map(select(([.value[] | $all_nodes[.].locked.narHash | select(. != null)] | unique | length) > 1))
      | from_entries
    ) as $conflicting_repos

    # Step 2: Create a reverse mapping for the conflicting nodes.
    | ($conflicting_repos | to_entries | map(.key as $repo | .value[] as $node | {key: $node, value: $repo}) | from_entries) as $node_to_repo

    # Step 3: Find all consumers of these conflicting nodes.
    | (
      $all_nodes
      | to_entries
      | reduce .[] as $consumer ({};
          reduce (($consumer.value.inputs // {} | to_entries))[] as $input (.;
            ($input.value | (if type == "array" then .[-1] else . end)) as $target_node
            | if $node_to_repo | has($target_node) then
                ($node_to_repo[$target_node]) as $repo
                | .[$repo][($consumer.key)] += [$target_node]
              else . end
          )
        )
      )
  )
  # Step 4: Post-process the results to implement the final filtering logic.
  | (
      # Get the managed nodes list again for use in this final pipeline.
      ($all_nodes.root.inputs | to_entries | map(.value | if type == "array" then .[-1] else . end)) as $managed_nodes
      # a) Remove the `root` consumer entirely.
      | . | map_values(del(.root))
      # b) For each remaining consumer, remove any nodes they use if that node is in the managed list.
      | map_values(map_values(map(select(. as $node | ($managed_nodes | index($node) | not)))))
      # c) Clean up any consumers with empty lists.
      | map_values(to_entries | map(select(.value | length > 0)) | from_entries)
      # d) Clean up any repos with no consumers left.
      | to_entries | map(select(.value | length > 0)) | from_entries
    )
' <<<"$metadata"

