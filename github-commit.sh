#!/usr/bin/env bash


declare -r SECRETS_FILE=secrets.yaml
declare -r GITHUB_URL=https://api.github.com/repos/uroesch/sandbox
declare -r GIT_NAME="Urs Roesch"
declare -r GIT_EMAIL="github@bun.ch"

export GITHUB_TOKEN=$(sops exec-env ${SECRETS_FILE} 'echo ${SANDBOX_TOKEN}')


function github::curl() {
  local url=${1}; shift;
  local data="${@}"
  curl \
  --silent \
  --header "Authorization: Bearer ${GITHUB_TOKEN}" \
  --header "Accept: application/vnd.github+json" \
  ${data:+--header "Content-Type: application/json"} \
  ${data:+--data "${data}"} \
  ${GITHUB_URL}/${url}
}

function github::fetch_head() {
  local branch=${1:-main};
  github::curl git/ref/heads/${branch} | \
    jq -r .object.sha
}

function github::create_blob() {
  local content="${1}"
  local body='{
    "content": "%s",
    "encoding": "utf-8"
  }'

  github::curl git/blobs \
    "$(printf "${body}" "${content}")" | \
    jq -r .sha
}

function github::create_tree() {
  local head_sha="${1}"; shift;
  local blob_sha="${1}"; shift;
  local path="${1}"; shift;
  local body='{
    "base_tree": "%s",
    "tree": [
      {
        "sha": "%s",
        "path": "%s",
        "mode": "100644",
        "type": "blob"
      }
    ]
  }'
  github::curl git/trees \
    "$(printf "${body}" "${head_sha}" "${blob_sha}" "${path}")" | \
    jq -r .sha
}

function github::create_commit() {
  local message="${1}"; shift;
  local tree_sha="${1}"; shift;
  local head_sha="${1}"; shift;
  local body='{
    "message": "%s",
    "tree": "%s",
    "parents": [
      "%s"
    ],
    "author": {
      "name": "%s",
      "email": "%s"
    }
  }'
  github::curl git/commits \
    "$(
      printf "${body}" \
        "${message}" \
        "${tree_sha}" \
        "${head_sha}" \
        "${GIT_NAME}" \
        "${GIT_EMAIL}"
    )" | \
    jq -r .sha
}

function github::update_head() {
  local branch="${1}"; shift;
  local commit_sha="${1}"; shift;
  local body='{
    "ref": "refs/heads/%s",
    "sha": "%s"
  }'

  github::curl git/refs/heads/${branch} \
    "$(printf "${body}" "${branch}" "${commit_sha}")"
}


function github::commit() {
  local branch=${1}; shift;
  local message=${1}; shift;
  local path=${1}; shift;
  local content=${1}; shift;

  local head_sha=$(github::fetch_head "${branch}")
  local blob_sha=$(github::create_blob "${content}")
  local tree_sha=$(github::create_tree "${head_sha}" "${blob_sha}" "${path}")
  local commit_sha=$(
   github::create_commit "${message}" "${tree_sha}" "${head_sha}"
  )
  github::update_head "${branch}" "${commit_sha}"
}

github::commit \
  "main" \
  "my github api first curl commit" \
  "curl/demo.txt" \
  "File content from curl"
