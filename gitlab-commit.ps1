#!/usr/bin/env pwsh

$SecretFile    = 'secrets.yaml'
$Owner         = 'uroesch'
$RepoName      = 'gitlab-api-commit'
$GitlabBaseUrl = 'https://gitlab.com/api/v4/projects'

Filter UrlEncode {
  [System.Web.HTTPUtility]::UrlEncode($_)
}

Function Gitlab-Token {
  $Token = ( sops exec-env secrets.yaml 'echo $GITLAB_COM_TOKEN' )
  Return $Token
}

Function Gitlab-Headers {
  Return @{
    'PRIVATE-TOKEN' = Gitlab-Token
    'Accept'        = 'application/json'
  }
}

Function Gitlab-Url {

  Param (
    [String] $Owner,
    [String] $Repo,
    [String] $Action
  )
  $ProjectId = @($Owner, $Repo) -join "/" | UrlEncode
  Return @($GitlabBaseUrl, $ProjectId, 'repository', $Action) -join "/"
}

Function Gitlab-Commit {

  Param (
    [String] $OwnerName,
    [String] $RepositoryName,
    [String] $CommitMessage,
    [String] $Path,
    [String] $Content,
    [String] $BranchName
  )

  $Body = @{
    branch         = $BranchName
    commit_message = $CommitMessage
    actions        = @(
      @{
         action     = "create"
         file_path  = $Path
         content    = $Content
      }
    )
  } | ConvertTo-Json
  $Uri = Gitlab-Url -Owner $OwnerName -Repo $RepositoryName -Action 'commits'

  Invoke-RestMethod `
    -Method Post `
    -ContentType 'application/json' `
    -Headers $(Gitlab-Headers) `
    -Body $Body `
    -Uri $Uri
}

Gitlab-Commit `
  -OwnerName $Owner `
  -RepositoryName $RepoName `
  -BranchName 'main' `
  -CommitMessage "Commit message 1" `
  -Path "Files/Message2.txt" `
  -Content "Message 2"
