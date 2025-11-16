#!/bin/bash

# File: codebase_percentage_by_user.sh

# Ensure the script is executed within a git repository.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a Git repository."
  exit 1
fi

# Check for user input.
if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  echo "Provide the username to calculate the percentage of code they have touched."
  exit 1
fi

USER=$1

# Calculate the total number of lines in the repository.
total_lines=$(git ls-files | xargs wc -l | tail -n1 | awk '{print $1}')

# Calculate the total number of lines attributed to the user.
user_lines=$(git ls-files | xargs -I {} git blame --line-porcelain {} 2>/dev/null | \
  grep "^author " | \
  awk -v user="$USER" 'tolower($2) == tolower(user)' | \
  wc -l)

# Ensure we don't divide by zero.
if [ "$total_lines" -eq 0 ]; then
  echo "The repository appears to be empty. Unable to calculate percentages."
  exit 1
fi

# Calculate the percentage.
percentage=$(awk "BEGIN {printf \"%.2f\", ($user_lines / $total_lines) * 100}")

# Output the result.
echo "User '$USER' has touched $user_lines out of $total_lines lines of code, which is $percentage% of the codebase."

exit 0
