#!/usr/bin/env pwsh

$SecretFile = 'secrets.yaml'
$Owner      = 'uroesch'
$RepoName   = 'sandbox'


Function Set-Credentials {

  $Secret = ( `
    sops exec-env secrets.yaml 'echo $SANDBOX_TOKEN' | `
    ConvertTo-SecureString -AsPlainText -Force `
  )
  $Credentials = New-Object System.Management.Automation.PSCredential `
    $Owner, `
    $Secret
  Set-GitHubAuthentication -Credential $Credentials
}


Function Commit-File {

  Param (
    [String] $CommitMessage,
    [String] $Path,
    [String] $Content
  )

  Set-GitHubContent `
    -OwnerName $Owner `
    -RepositoryName $RepoName `
    -Path $Path `
    -CommitMessage $CommitMessage `
    -Content $Content `
    -BranchName main
}

Set-Credentials
Commit-File `
  -CommitMessage "Commit message 1" `
  -Path "Files/Message1.txt" `
  -Content "Message 2"

Commit-File `
  -CommitMessage "Commit message 2" `
  -Path "Files/Message2.txt" `
  -Content "Message 2"
