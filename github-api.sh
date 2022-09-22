#!/usr/bin/env bash


declare -r SECRETS_FILE=secrets.yaml
declare -r GITHUB_URL=https://api.github.com/repos/uroesch/sandbox

export GITHUB_TOKEN=$(sops exec-env ${SECRETS_FILE} 'echo ${SANDBOX_TOKEN}') 


function gh_curl() {
  local url=${1}; shift;
  local data="${@}"
  curl \
  --silent \
  --header "Accept: application/vnd.github+json" \
  --header "Authorization: Bearer ${GITHUB_TOKEN}" \
  --data "${data}" \
  ${GITHUB_URL}/${url}
}


# list commits
#gh_curl commits

# list branches 
#gh_curl branches

# get a reference 
#gh_curl git/ref/heads/main #| jq -r .url)

# create a blob
gh_curl git/blobs '{"content":"Super artifact","encoding":"utf-8"}'


# commit a message 
#gh_curl ${GITHUB_URL}/git/commits \
#-d '
#  { 
#    "message":"my commit message",
#    "author":{"name":"Urs Roesch","email":"github@github.com","date":"'$(date -u +%FT%T%:z)'"},"parents":["7d1b31e74ee336d15cbd21741bc88a537ed063a0"],"tree":"827efc6d56897b048c772eb4087f854f46256132",9E9QiJqMYdWQPWkaBIRRz5cET6HPB48YNXAAUsfmuYsGrnVLYbG+\nUpC6I97VybYHTy2O9XSGoaLeMI9CsFn38ycAxxbWagk5mhclNTP5mezIq6wKSwmr\nX11FW3n1J23fWZn5HJMBsRnUCgzqzX3871IqLYHqRJ/bpZ4h20RhTyPj5c/z7QXp\neSakNQMfbbMcljkha+ZMuVQX1K9aRlVqbmv3ZMWh+OijLYVU2bc=\n=5Io4\n-----END PGP SIGNATURE-----\n"}'
