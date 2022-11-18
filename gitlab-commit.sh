#!/usr/bin/env bash

declare -r SECRETS_FILE=secrets.yaml
declare -r GITLAB_PROJECT=uroesch/gitlab-api-commit
declare -r GITLAB_PROJECT_ID=${GITLAB_PROJECT//\//%2F}
declare -r GITLAB_URL="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}"
declare -r COMMIT_TEMPLATE="$(cat <<JSON | jq -r -c
  {
    "branch": "%s",
    "commit_message": "%s",
    "actions": [
      {
        "action": "create",
        "file_path": "%s",
        "content": "%s"
      }
    ]
  }
JSON
)"

export GITLAB_TOKEN=$(sops exec-env ${SECRETS_FILE} 'echo ${GITLAB_COM_TOKEN}')

function gitlab::curl() {
  local url=${1}; shift;
  local data="${@}"
  curl \
  --silent \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --header "Accept: application/json" \
  ${data:+--header "Content-Type: application/json"} \
  ${data:+--data "${data}"} \
  ${GITLAB_URL}/${url}
}

function gitlab::commit() {
  local branch=${1}; shift;
  local message=${1}; shift;
  local path=${1}; shift;
  local content=${1}; shift;

  gitlab::curl repository/commits $( \
    printf "${COMMIT_TEMPLATE}" \
     "${branch}" \
     "${message}" \
     "${path}" \
     "${content}" \
  )
}

gitlab::commit \
  "main" \
  "my api first commit" \
  "foobar/barfoo.txt" \
  "File content for foobar/barfoo.txt"
