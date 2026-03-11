#!/bin/bash
# lib/poll.sh — GitHub issue polling via gh CLI
# Fetches new issues and provides filtering functions

fetch_issues() {
  local repo="$1"
  local since="${2:-}"
  local args=(issue list --repo "$repo" --state open --json "number,title,labels,createdAt,url,author,body" --limit 50)
  if [[ -n "$since" ]]; then
    args+=(--search "created:>=$since")
  fi
  gh "${args[@]}" 2>/dev/null || echo "[]"
}

parse_issues() {
  jq '[.[] | {
    number: .number,
    title: .title,
    labels: [.labels[]?.name],
    created_at: .createdAt,
    url: .url,
    author: .author.login,
    body: (.body // "")
  }]'
}

filter_by_labels() {
  local wanted_labels="$1"
  jq --argjson wanted "$wanted_labels" '
    if ($wanted | length) == 0 then .
    else [.[] | select(
      (.labels | length == 0) or
      ([ .labels[] | if type == "object" then .name else . end ] as $l |
       $wanted | any(. as $w | $l | any(. == $w)))
    )]
    end
  '
}

filter_ignore_labels() {
  local ignore_labels="$1"
  jq --argjson ignore "$ignore_labels" '
    [.[] | select(
      [ .labels[] | if type == "object" then .name else . end ] as $l |
      ($ignore | all(. as $ig | $l | all(. != $ig)))
    )]
  '
}

filter_new_issues() {
  local last_seen="$1"
  jq --argjson last "$last_seen" '[.[] | select(.number > $last)]'
}

filter_max_age() {
  local max_age_days="$1"
  local cutoff
  cutoff=$(date -u -v-"${max_age_days}"d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
           date -u -d "${max_age_days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  if [[ -n "$cutoff" ]]; then
    jq --arg cutoff "$cutoff" '[.[] | select(.created_at >= $cutoff)]'
  else
    cat
  fi
}

has_new_issues() {
  local repo="$1" last_seen="$2"
  local count
  count=$(fetch_issues "$repo" | parse_issues | filter_new_issues "$last_seen" | jq 'length')
  [[ "$count" -gt 0 ]]
}

# --- PR Polling Functions ---

fetch_prs() {
  local repo="$1"
  gh pr list --repo "$repo" --state open \
    --json number,title,author,createdAt,labels,headRefName,commits 2>/dev/null || echo "[]"
}

parse_prs() {
  jq '[.[] | {
    number: .number,
    title: .title,
    author: .author.login,
    created_at: .createdAt,
    labels: [.labels[]?.name],
    head_ref: .headRefName,
    commits: [.commits[]?.messageHeadline]
  }]'
}

filter_new_prs() {
  local last_seen="$1"
  jq --argjson last "$last_seen" '[.[] | select(.number > $last)]'
}

filter_ignored_prs() {
  local ignore_authors="${1:-}" ignore_labels="${2:-}"
  if [[ -n "$ignore_authors" && -n "$ignore_labels" ]]; then
    jq --arg authors "$ignore_authors" --arg labels "$ignore_labels" '
      ($authors | split(",")) as $auth_list |
      ($labels | split(",")) as $lbl_list |
      [.[] | .author as $a | select(
        ($auth_list | all(. != $a)) and
        ([.labels[]? // empty] | all(. as $l | $lbl_list | all(. != $l)))
      )]'
  elif [[ -n "$ignore_authors" ]]; then
    jq --arg authors "$ignore_authors" '
      ($authors | split(",")) as $auth_list |
      [.[] | .author as $a | select($auth_list | all(. != $a))]'
  elif [[ -n "$ignore_labels" ]]; then
    jq --arg labels "$ignore_labels" '
      ($labels | split(",")) as $lbl_list |
      [.[] | select(
        [.labels[]? // empty] | all(. as $l | $lbl_list | all(. != $l))
      )]'
  else
    cat
  fi
}
