#!/bin/bash

get_release_parts() {
    local tag="$1"
    # Remove 'v' prefix and split by '.'
    echo "${tag#v}" | tr '.' ' '
}

get_previous_tag() {
    local tag="$1"
    local parts=($(get_release_parts "$tag"))
    local major=${parts[0]}
    local minor=${parts[1]}
    local patch=${parts[2]}
    
    # Get all tags in reverse order
    local tag_list=($(git tag --list 'v*' | sort -V -r))
    
    for tag_name in "${tag_list[@]}"; do
        local curr=($(get_release_parts "$tag_name"))
        
        # Skip if not 3 parts
        if [ ${#curr[@]} -ne 3 ]; then
            continue
        fi
        
        local curr_major=${curr[0]}
        local curr_minor=${curr[1]}
        local curr_patch=${curr[2]}
        
        # Logic from Dart version
        if [[ ($patch -eq $curr_patch && $minor -eq $curr_minor && $major -ne $curr_major) ||
              ($patch -eq 0 && $curr_patch -eq 0 && $minor -ne 0 && $minor -ne $curr_minor) ||
              ($patch -ne 0 && $patch -ne $curr_patch) ]]; then
            echo "$tag_name"
            return
        fi
    done
}

gen_release() {
    local tag="$1"
    local till_tag=$(get_previous_tag "$tag")
    
    # Prepare git log command
    local git_cmd=("git" "log" "--pretty=format:%s")
    if [ -n "$till_tag" ]; then
        git_cmd+=("${till_tag}..HEAD")
    fi
    
    # Get commit messages and filter them
    local comments=()
    while IFS= read -r line; do
        # Skip merge and revert commits
        if [[ "$line" != *"Merge pull"* && "$line" != *"Revert"* ]]; then
            # Extract first sentence and remove quotes
            local comment=$(echo "$line" | cut -d'.' -f1 | sed 's/"//g')
            comments+=("- $comment")
        fi
    done < <("${git_cmd[@]}")
    
    # Remove duplicates
    local unique_comments=($(printf '%s\n' "${comments[@]}" | sort -u))
    
    # Add section headers
    local all_comments=("${unique_comments[@]}")
    all_comments+=(
        "## [CI] Critical Issue(s)"
        "## [NF] New Functionality"
        "## [CR] Change Request(s)"
        "## [BF] Bug Fix(es)"
        "## [...] Other(s)"
    )
    
    # Sort comments according to the order
    local output=""
    local order=("[CI]" "[NF]" "[CR]" "[BF]" "[" "")
    
    for order_item in "${order[@]}"; do
        for comment in "${all_comments[@]}"; do
            if [[ "$comment" == *"$order_item"* ]]; then
                # Headers come first within same category
                if [[ "$comment" == "##"* ]]; then
                    output="$comment"$'\n'"$output"
                else
                    output="$output$comment"$'\n'
                fi
            fi
        done
    done
    
    echo "$output"
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 <tag>"
    echo "Example: $0 v1.2.3"
    exit 1
fi

gen_release "$1"