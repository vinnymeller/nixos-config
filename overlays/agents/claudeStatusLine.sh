input=$(cat)

GREEN='\033[32m'
RED='\033[31m'
CYAN='\033[36m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RESET='\033[0m'

model=$(echo "$input" | jq -r '.model.display_name')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')
git_diff=$(git diff HEAD --numstat 2>/dev/null | awk '{added+=$1; removed+=$2} END {print added+0, removed+0}')
lines_added=$(echo "$git_diff" | cut -d' ' -f1)
lines_removed=$(echo "$git_diff" | cut -d' ' -f2)

git_info="${CYAN}${branch}${RESET}"
if [ "$lines_added" -gt 0 ] || [ "$lines_removed" -gt 0 ]; then
	git_info="$git_info ${GREEN}+$lines_added${RESET} ${RED}-$lines_removed${RESET}"
fi

context_info=""
if [ -n "$context_pct" ] && [ "$context_pct" != "null" ]; then
	formatted_pct=$(printf "%.0f" "$context_pct")
	context_info=" | ${YELLOW}ctx:${formatted_pct}%${RESET}"
fi

cost_info=""
if [ -n "$session_cost" ] && [ "$session_cost" != "null" ]; then
	formatted_cost=$(printf "%.2f" "$session_cost")
	cost_info=" | ${MAGENTA}\$$formatted_cost${RESET}"
fi

token_info=""
if [ -n "$input_tokens" ] && [ "$input_tokens" != "null" ]; then
	token_info=" ${MAGENTA}in:${input_tokens} out:${output_tokens}${RESET}"
fi

echo -e "$git_info | $model${context_info}${cost_info}${token_info}"
