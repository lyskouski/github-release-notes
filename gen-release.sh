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
    local till_tag
    till_tag=$(get_previous_tag "$tag")
    
    # Prepare git log command
    local git_cmd=("git" "log" "--pretty=format:%s")
    if [ -n "$till_tag" ]; then
        git_cmd+=("${till_tag}..HEAD")
    fi
    
    # Get commit messages
    local comments=()
    while IFS= read -r line; do
        local comment
        comment=$(echo "$line" | cut -d'.' -f1 | sed 's/"//g')
        comments+=("- $comment")
    done < <("${git_cmd[@]}")

    # Remove duplicates
    local unique_comments=()
    while IFS= read -r line; do
        unique_comments+=("$line")
    done < <(printf '%s\n' "${comments[@]}" | sort -u)

    # Header definitions
    declare -A headers=(
        ["[AD]"]="## [AD] Architecture Description Records"
        ["[CI]"]="## [CI] Critical Issue"
        ["[NF]"]="## [NF] New Functionality"
        ["[CR]"]="## [CR] Change Request"
        ["[RF]"]="## [RF] Refactoring"
        ["[BF]"]="## [BF] Bug Fix"
        ["[DC]"]="## [DC] Documentation Change"
        ["[BP]"]="## [BP] Build Process improvements (CI/CD Change)"
        ["["]="## [...] Others"
    )

    # Define the desired output order of abbreviations
    local order=("[AD]" "[CI]" "[NF]" "[CR]" "[RF]" "[BF]" "[DC]" "[BP]" "[")

    # Group commits by abbreviation
    declare -A grouped
    for c in "${unique_comments[@]}"; do
        if [[ $c =~ \[([A-Z]+)\] ]]; then
            local abbr="[${BASH_REMATCH[1]}]"
        else
            abbr="["
        fi
        grouped["$abbr"]+="$c"$'\n'
    done

    # Print only headers that have commits, with their commits
    for abbr in "${order[@]}"; do
        if [[ -n "${grouped[$abbr]}" ]]; then
            echo "${headers[$abbr]}"
            printf '%s' "${grouped[$abbr]}"
        fi
    done
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 <tag>"
    echo "Example: $0 v1.2.3"
    exit 1
fi

gen_release "$1"
