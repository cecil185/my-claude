#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
tokens_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')

# Git branch (skip lock files to avoid blocking)
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Extract Linear ticket from branch (e.g. DP-100)
ticket=""
if [ -n "$branch" ]; then
  ticket=$(echo "$branch" | grep -oE '[A-Z]+-[0-9]+')
fi

# Directory: show last two path components
dir_display=""
if [ -n "$cwd" ]; then
  dir_display=$(echo "$cwd" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}')
fi

# Build left segment: dir + ticket (if any) + branch
left=""
[ -n "$dir_display" ] && left="$dir_display"
if [ -n "$ticket" ]; then
  left="$left  [$ticket]"
elif [ -n "$branch" ]; then
  left="$left  $branch"
fi

# AWS profile
aws_profile="${AWS_PROFILE:-}"

# Format token count as e.g. 12k or 1.2m
tokens_fmt=""
if [ -n "$tokens_used" ] && [ "$tokens_used" != "null" ]; then
  tokens_fmt=$(echo "$tokens_used" | awk '{
    if ($1 >= 1000000) printf "%.1fm", $1/1000000
    else if ($1 >= 1000) printf "%.0fk", $1/1000
    else printf "%d", $1
  }')
fi

# Build right segment: aws profile + model + tokens
right=""
[ -n "$aws_profile" ] && right="$aws_profile"
[ -n "$model" ] && right="${right:+$right  }$model"
[ -n "$tokens_fmt" ] && right="${right:+$right  }ctx:${tokens_fmt}"

# Print as a single line with separator
if [ -n "$left" ] && [ -n "$right" ]; then
  printf '%s   |   %s' "$left" "$right"
elif [ -n "$left" ]; then
  printf '%s' "$left"
else
  printf '%s' "$right"
fi
