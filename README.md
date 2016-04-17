Posh-Tweet
==========

PowerShell Module for interacting with Twitter


Log on https://apps.twitter.com with your twitter account and register a new app.
Retrieve your APIKey, APISecret and generate a set of access Token

Think of a masterPassword to encrypt those information onto your disk.

```powershell
$twitSet = @{
    'APIKey'='AAAAAAAAAAAAAAAAAAAAAAAAA'
    'APISecret'='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
    'AccessToken'='111111111-1111111111111111111111111111111111111111'
    'AccessTokenSecret'='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
    'MasterPassword'=("yourpassword" | ConvertTo-SecureString -AsPlainText -Force)
}

Set-TweetToken @twitSet
Connect-TweetService -MasterPassword ("yourpassword" | ConvertTo-SecureString -AsPlainText -Force)

```
