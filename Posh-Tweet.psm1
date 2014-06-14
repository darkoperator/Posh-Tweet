<#
.Synopsis
   Saves the API Tokens for the Twitter Application Profile the module will use.
.DESCRIPTION
   Saves the API Tokens for the Twitter Application Profile the module will use.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-TweetToken
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $APIKey,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $APISecret,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $AccessToken,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]
        $AccessTokenSecret,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
        [securestring]$MasterPassword

    )

    Begin
    {
    }
    Process
    {
        $TokenHash = @{
            APIKey = $APIKey
            APISecret = $APISecret
            AccessToken = $AccessToken
            AccessTokenSecret = $AccessTokenSecret
        }
        
        $ConfigAsJson = ConvertTo-Json -InputObject $TokenHash -Compress

        $SecureKeyString = ConvertTo-SecureString -String "$($ConfigAsJson)"  -AsPlainText -Force
        $EncryptedString = $SecureKeyString | ConvertFrom-SecureString -SecureKey $MasterPassword

        $FolderName = 'Posh-Tweet'
        $ConfigName = 'config.json'
        
        if (!(Test-Path "$($env:AppData)\$FolderName"))
        {
            Write-Verbose -Message 'Seems this is the first time the config has been set.'
            Write-Verbose -Message "Creating folder $("$($env:AppData)\$FolderName")"
            New-Item -ItemType directory -Path "$($env:AppData)\$FolderName" | Out-Null
        }
        
        Write-Verbose -Message "Saving the information to configuration file $("$($env:AppData)\$FolderName\$ConfigName")"
        "$($EncryptedString)"  | Set-Content  "$($env:AppData)\$FolderName\$ConfigName" -Force
        
    }
    End
    {
    }
}


<#
.Synopsis
   Connect to the Twitter service using previously saved Applicantion OAuth 
   information.
.DESCRIPTION
   Connect to the Twitter service using previously saved Applicantion OAuth 
   information.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Connect-TweetService
{
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [securestring]$MasterPassword
    )

    Begin
    {
        # Test if configuration file exists.
        if (!(Test-Path "$($env:AppData)\Posh-Tweet\config.json"))
        {
            throw 'Configuration has not been set, Set-TweetTokens to configure the API Tokens.'
        }
    }
    Process
    {
        $Config = Get-Content -Path "$($env:AppData)\Posh-Tweet\config.json"
        
        $SecString = ConvertTo-SecureString -SecureKey $MasterPassword -String $Config

        # Decrypt the secure string.
        $SecureStringToBSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecString)
        $APIKeystring = [Runtime.InteropServices.Marshal]::PtrToStringAuto($SecureStringToBSTR)

        $ConfigObj = $APIKeystring | ConvertFrom-Json

        try
        {
            [Tweetinvi.TwitterCredentials]::Credentials = [Tweetinvi.TwitterCredentials]::CreateCredentials(
                                                            $ConfigObj.AccessToken,
                                                            $ConfigObj.AccessTokenSecret,
                                                            $ConfigObj.APIKey,
                                                            $ConfigObj.APISecret)
            [Tweetinvi.User]::GetLoggedUser()
        }
        catch
        {
            Write-Error -Message 'Could not connect to twitter with saved credentials'
            $_
        }
                                                            
    }
    End
    {
    }
}


<#
.Synopsis
   Returns the current rate limits for methods belonging to the specified 
   resource families.
.DESCRIPTION
   Each 1.1 API resource belongs to a "resource family" which is indicated 
   in its method documentation. You can typically determine a method's 
   resource family from the first component of the path after the resource 
   version.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetRateLimit
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param()

    Begin
    {
         $logged = [Tweetinvi.User]::GetLoggedUser()
         if ($logged -eq $null)
         {
            Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.' -ErrorAction Stop
         }
    }
    Process
    {
        [Tweetinvi.RateLimit]::GetCurrentCredentialsRateLimits()
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Send-Tweet
{
    [CmdletBinding(DefaultParameterSetName = 'Std')]
    [OutputType([psobject])]
    Param
    (
        # Twitter message to send. Limit of 140 charecters.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateLength(1,140)]
        [string]
        $Message,

        # The ID of an existing status that the update is in reply to.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [long]
        $ReplyToID,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName = 'WithMedia')]
        [ValidateScript({Test-Path $_})]
        [string]
        $Image,

        # The latitude of the location this tweet refers to. This parameter 
        # will be ignored unless it is inside the range -90.0 to +90.0 (North 
        # is positive) inclusive.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Latitude,

        # The longitude of the location this tweet refers to. The valid ranges
        # for longitude is -180.0 to +180.0 (East is positive) inclusive. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Longitude

    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
         if ($logged -eq $null)
         {
            Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
            return
         }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
           {
               'std' 
               {
                    $tweet = [Tweetinvi.Tweet]::CreateTweet($Message)
                    if ($ReplyToID)
                    {
                        $tweet.InReplyToStatusId($ReplyToID)
                    }
               }

               'WithMedia'
               {
                    [byte[]]$file1 = Get-Content -Encoding Byte -Path $Image
                    $tweet = [Tweetinvi.Tweet]::CreateTweet($Message)
                    $tweet.AddMedia($file1)
               }
           }

           if ($ReplyToID)
            {
                $tweet.InReplyToStatusId($ReplyToID)
            }

            if ($Longitude)
            {
                $sent = [Tweetinvi.Tweet]::TweetController.PublishTweetWithGeo($tweet, $Longitude, $Latitude)
            }
            else
            {
                $sent = [Tweetinvi.Tweet]::PublishTweet($tweet)
            }

            if ($sent)
            {
                $tweet
            }
    }
    End{}

 }


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-Tweet
{
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType()]
    Param
    (

        # The ID of an existing status to remove..
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Tweet')]
        [Tweetinvi.Core.Interfaces.ITweet]
        $Tweet

    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
         if ($logged -eq $null)
         {
            Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
            return
         }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
           {
               'Id' 
               {
                    Write-Verbose -Message "Removing status with Id $($Id)"
                    $Destroyed = [Tweetinvi.Tweet]::DestroyTweet($Id)
               }

               'Tweet'
               {
                    Write-Verbose -Message "Removing status with Id $($Tweet.Id)"
                    $Destroyed = [Tweetinvi.Tweet]::DestroyTweet($Tweet)
               }
           }

           if($Destroyed)
           {
                Write-Verbose 'Status deleted.'
           }
           else
           {
                Write-Error -Message 'Could not delete status.'
           }
           
    }
    End{}

 }


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-TweetFavorite
{
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    Param
    (

        # The ID of an existing status to remove..
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Tweet')]
        [Tweetinvi.Core.Interfaces.ITweet]
        $Tweet

    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
         if ($logged -eq $null)
         {
            Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
            return
         }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
           {
               'Id' 
               {
                    Write-Verbose -Message "Setting favorite status to Tweet with Id $($Id)"
                    $favorited = [Tweetinvi.Tweet]::FavoriteTweet($Id)
                    $favorited
               }

               'Tweet'
               {
                    Write-Verbose -Message "Setting favorite status to Tweet with Id $($Tweet.Id)"
                    $favorited = [Tweetinvi.Tweet]::FavoriteTweet($Tweet)
                    $favorited
               }
           }

           if($favorited)
           {
                Write-Verbose 'Status added to favorite list.'
           }
           else
           {
                Write-verbose -Message 'Could not add to favorite list.'
           }
           
    }
    End{}

 }


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-TweetFavorite
{
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    Param
    (

        # The ID of an existing status to remove..
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Tweet')]
        [Tweetinvi.Core.Interfaces.ITweet]
        $Tweet

    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
         if ($logged -eq $null)
         {
            Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
            return
         }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
           {
               'Id' 
               {
                    Write-Verbose -Message "Removing favorite status to Tweet with Id $($Id)"
                    $query = "https://api.twitter.com/1.1/favorites/destroy.json?id=$($Id)"
                    $removed = [Tweetinvi.TwitterAccessor]::TryExecutePOSTQuery($query)
                    $removed
               }

               'Tweet'
               {
                    Write-Verbose -Message "Removing favorite status to Tweet with Id $($Tweet.Id)"
                    $query = "https://api.twitter.com/1.1/favorites/destroy.json?id=$($Tweet.Id)"
                    $removed = [Tweetinvi.TwitterAccessor]::TryExecutePOSTQuery($query)
                    $removed
               }
           }

           if($removed)
           {
                Write-Verbose 'Status added to favorite list.'
           }
           else
           {
                Write-verbose -Message 'Could not add to favorite list.'
           }
           
    }
    End{}

 }


 <#
.Synopsis
   Returns a collection of the most recent Tweets and retweets posted by 
   the authenticating user and the users they follow. 
.DESCRIPTION
   Returns a collection of the most recent Tweets and retweets posted by the 
   authenticating user and the users they follow. The home timeline is central 
   to how most users interact with the Twitter service. 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetTimeline
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Specifies the number of records to retrieve. Must be less than or 
        # equal to 200. Defaults to 20.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateRange(1,200)]
        [int]
        $Count = 20,

        # This parameter will prevent replies from appearing in the returned 
        # timeline. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ExclueReplies,

        # Returns results with an ID greater than (that is, more recent than)
        # the specified ID. There are limits to the number of Tweets which can
        # be accessed. If the limit of Tweets has occured since the since_id,
        # the since_id will be forced to the oldest ID available.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $SinceID,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $MaxID
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           return
        }
    }
    Process
    {   
        $TimelineParams = [Tweetinvi.Timeline]::CreateHomeTimelineRequestParameter()

        $TimelineParams.MaximumNumberOfTweetsToRetrieve = $Count

        if ($ExclueReplies) { $TimelineParams.ExcludeReplies = $true }

        if ($MaxID) { $TimelineParams.MaxId = $MaxID }

        if ($SinceID) { $TimelineParams.SinceId = $SinceID }

        [Tweetinvi.Timeline]::GetHomeTimeline($TimelineParams)
    }
    End{}
}


<#
.Synopsis
   Allows one to enable or disable retweets and device notifications 
   from the specified user.
.DESCRIPTION
   Allows one to enable or disable retweets and device notifications 
   from the specified user.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetMentionTimeline
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Specifies the number of records to retrieve. Must be less than or 
        # equal to 200. Defaults to 20.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $Count = 20,

        # This parameter will prevent replies from appearing in the returned 
        # timeline. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ExclueReplies,

        # Returns results with an ID greater than (that is, more recent than)
        # the specified ID. There are limits to the number of Tweets which can
        # be accessed. If the limit of Tweets has occured since the since_id,
        # the since_id will be forced to the oldest ID available.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $SinceID,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $MaxID
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           return
        }
    }
    Process
    {   
        $TimelineParams = [Tweetinvi.Timeline]::CreateMentionsTimelineRequestParameters()

        $TimelineParams.MaximumNumberOfTweetsToRetrieve = $Count

        if ($ExclueReplies) { $TimelineParams.ExcludeReplies = $true }

        if ($MaxID) { $TimelineParams.MaxId = $MaxID }

        if ($SinceID) { $TimelineParams.SinceId = $SinceID }

        [Tweetinvi.Timeline]::GetMentionsTimeline($TimelineParams)
    }
    End{}
}


<#
.Synopsis
   Allows one to enable or disable retweets and device notifications 
   from the specified user.
.DESCRIPTION
   Allows one to enable or disable retweets and device notifications 
   from the specified user.
.EXAMPLE
   Update-TweetFriendNotification -ScreenName "infosectactico" -EnableDeviceNotification
#>
function Update-TweetFriendNotification
{
     [CmdletBinding(DefaultParameterSetName = 'ScreenName')]
    Param
    (

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $EnableDeviceNotification,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $EnableRetweetNotification,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $DisableDeviceNotification,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $DisableRetweetNotification
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
        }
    }
    Process
    {
        $URI = 'https://api.twitter.com/1.1/friendships/update.json?'
        $paramstring = ""

        # Set parameters
        if ($EnableDeviceNotification)   
        { 
            Write-Verbose -Message 'Enable device notification was selected.'
            $paramstring + "&device=true" | Out-Null 
        }

        if ($EnableRetweetNotification)  
        { 
            Write-Verbose -Message 'Enable retweet notification was selected.'
            $paramstring + "&retweets=true" | Out-Null 
        }

        if ($DisableDeviceNotification)  
        { 
            Write-Verbose -Message 'Disable device notification was selected.'
            $paramstring + "&device=false" | Out-Null 
        }

        if ($DisableRetweetNotification) 
        { 
            Write-Verbose -Message 'Disable retweet notification was selected.'
            $paramstring + '&retweets=false' | Out-Null 
        }

        switch ($PSCmdlet.ParameterSetName)
        {
            'Id'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromId($Id)
                if ($TweetUser -ne $null)
                {
                    Write-Verbose -Message "Updating notifications for $($TweetUser.ScreenName)."
                    $query = "$($URI)user_id=$($TweetUser.Id)$($paramstring)"
                    $FiendshipSettings = [Tweetinvi.TwitterAccessor]::TryExecutePOSTQuery($query)
                    $FiendshipSettings
                }
                else
                {
                    Write-Error -Message "Could not find a user with Id $($Id)."
                }
            }
            'ScreenName'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromScreenName($ScreenName)
                if ($TweetUser -ne $null)
                {
                    Write-Verbose -Message "Updating notifications for $($ScreenName)."
                    $query = "$($URI)screen_name=$($ScreenName)$($paramstring)"
                    $FiendshipSettings = [Tweetinvi.TwitterAccessor]::TryExecutePOSTQuery($query)
                    $FiendshipSettings
                }
                else
                {
                    Write-Error -Message "Could not find a user with screen name $($ScreenName)."
                }
            }
        }
    }
    End
    {
    }
}

##################
# Direct Message #
##################

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Send-TweetDM
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Recipient,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateLength(1,140)]
        [string]
        $Message
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
        }
    }
    Process
    {
        $userobj = [Tweetinvi.User]::GetUserFromScreenName('infosectactico')
        if ($userobj)
        {
            [Tweetinvi.Message]::CreateMessage($Message, $userobj).Publish()
        }
        else
        {
            Write-Error -Message 'Recipient could not be found'   
        }
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetDMSent
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $Count = 20
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           
        }
    }
    Process
    {
        [Tweetinvi.Message]::GetLatestMessagesSent($Count)
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetDMReceived
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $Count = 20
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           
        }
    }
    Process
    {
        [Tweetinvi.Message]::GetLatestMessagesReceived($Count)
    }
    End
    {
    }
}


########
# User #
########


 <#
 .Synopsis
    Short description
 .DESCRIPTION
    Long description
 .EXAMPLE
    Example of how to use this cmdlet
 .EXAMPLE
    Another example of how to use this cmdlet
 #>
 function Get-TweetUser
 {
     [CmdletBinding(DefaultParameterSetName = 'ScreenName')]
     Param
     (
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0,
                    ParameterSetName = 'Id')]
         [int32]
         $Id,
         
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0,
                    ParameterSetName = 'ScreenName')]
         [string]
         $ScreenName
     )
 
     Begin
     {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           
        }
     }
     Process
     {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Id' 
            {
                $Tuser = [Tweetinvi.User]::GetUserFromId($Id)
                if ($Tuser)
                {
                    $Tuser
                }
                else
                {
                    Write-Error -Message "User with Id $($Id) was not found."
                    return
                }
                }
            'ScreenName' 
            {
                if ($ScreenName)
                {
                    $Tuser = [Tweetinvi.User]::GetUserFromScreenName($ScreenName)
                    if ($Tuser)
                    {
                        $Tuser
                    }
                    else
                    {
                        Write-Error -Message "User with screen name $($ScreenName) was not found."
                        return
                    }
                }
                else
                {
                    [Tweetinvi.User]::GetLoggedUser()
                }
            }   
        }
     }
     End
     {
     }
 }


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetUserFollower
{
     [CmdletBinding(DefaultParameterSetName = 'LoggedOn')]
    Param
    (

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [Int]
        $Count = 20
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
        }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'LoggedOn'
            {
                $LoggedOnUser = [Tweetinvi.User]::GetLoggedUser()
                [Tweetinvi.User]::GetFollowers($LoggedOnUser, $Count)
            }
            'Id'
            {
                [Tweetinvi.User]::GetFollowers($Id, $Count)
            }
            'ScreenName'
            {
                [Tweetinvi.User]::GetFollowers($ScreenName, $Count)
            }
        }
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetUserFriend
{
     [CmdletBinding(DefaultParameterSetName = 'LoggedOn')]
    Param
    (

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [Int]
        $Count = 20
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
        }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'LoggedOn'
            {
                $LoggedOnUser = [Tweetinvi.User]::GetLoggedUser()
                [Tweetinvi.User]::GetFriends($LoggedOnUser, $Count)
            }
            'Id'
            {
                [Tweetinvi.User]::GetFriends($Id, $Count)
            }
            'ScreenName'
            {
                [Tweetinvi.User]::GetFriends($ScreenName, $Count)
            }
        }
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetUserFavorite
{
    [CmdletBinding(DefaultParameterSetName = 'LoggedOn')]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [Int]
        $Count = 20
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
        }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'LoggedOn'
            {
                $LoggedOnUser = [Tweetinvi.User]::GetLoggedUser()
                [Tweetinvi.User]::GetFavouriteTweets($LoggedOnUser, $Count)
            }
            'Id'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromId($Id)
                if ($TweetUser -ne $null)
                {
                    [Tweetinvi.User]::GetFavouriteTweets($TweetUser, $Count)
                }
                else
                {
                    Write-Error -Message "Could not find a user with Id $($Id)."
                }
            }
            'ScreenName'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromScreenName($ScreenName)
                if ($TweetUser -ne $null)
                {
                    [Tweetinvi.User]::GetFavouriteTweets($TweetUser, $Count)
                }
                else
                {
                    Write-Error -Message "Could not find a user with screen name $($ScreenName)."
                }
            }
        }
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Block-TweetUser
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           return
        }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Id'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromId($Id)
                if ($TweetUser -ne $null)
                {
                    [Tweetinvi.User]::BlockUser($TweetUser)
                }
                else
                {
                    Write-Error -Message "Could not find a user with Id $($Id)."
                }
            }
            'ScreenName'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromScreenName($ScreenName)
                if ($TweetUser -ne $null)
                {
                    [Tweetinvi.User]::BlockUser($TweetUser)
                }
                else
                {
                    Write-Error -Message "Could not find a user with screen name $($ScreenName)."
                }
            }
        }
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Unblock-TweetUser
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           return
        }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Id'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromId($Id)
                if ($TweetUser -ne $null)
                {
                    {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName = 'Id')]
        [long]
        $Id
    )

    Begin
    {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           return
        }
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Id'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromId($Id)
                if ($TweetUser -ne $null)
                {
                    $query = "https://api.twitter.com/1/blocks/destroy.json?user_id=$($TweetUser.Id)"
                    $blockSuccessfullyDestroyed = [Tweetinvi.TwitterAccessor]::TryExecutePOSTQuery($query)
                    $blockSuccessfullyDestroyed
                }
                else
                {
                    Write-Error -Message "Could not find a user with Id $($Id)."
                }
            }
            'ScreenName'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromScreenName($ScreenName)
                if ($TweetUser -ne $null)
                {
                    $query = "https://api.twitter.com/1/blocks/destroy.json?user_id=$($TweetUser.Id)"
                    $blockSuccessfullyDestroyed = [Tweetinvi.TwitterAccessor]::TryExecutePOSTQuery($query)
                    $blockSuccessfullyDestroyed
                }
                else
                {
                    Write-Error -Message "Could not find a user with screen name $($ScreenName)."
                }
            }
        }
    }
    End
    {
    }
}
                }
                else
                {
                    Write-Error -Message "Could not find a user with Id $($Id)."
                }
            }
            'ScreenName'
            {
                $TweetUser = [Tweetinvi.User]::GetUserFromScreenName($ScreenName)
                if ($TweetUser -ne $null)
                {
                    [Tweetinvi.User]::BlockUser($TweetUser)
                }
                else
                {
                    Write-Error -Message "Could not find a user with screen name $($ScreenName)."
                }
            }
        }
    }
    End
    {
    }
}


 ##########
 # Search #
 ##########

 <#
 .Synopsis
    Short description
 .DESCRIPTION
    Long description
 .EXAMPLE
    Example of how to use this cmdlet
 .EXAMPLE
    Another example of how to use this cmdlet
 #>
 function Search-Tweet
 {
     [CmdletBinding(DefaultParameterSetName = 'Regular')]
     Param
     (
         # The number of tweets to return per page, up to a maximum of 100.
         [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName = 'Regular')]
        [ValidateRange(1,100)]
        [int]
        $Count = 20,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $Query,

        # Returns results with an ID greater than (that is, more recent than)
        # the specified ID. There are limits to the number of Tweets which can
        # be accessed. If the limit of Tweets has occured since the since_id,
        # the since_id will be forced to the oldest ID available.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $SinceID,

        # Returns results with an ID less than (that is, older than) or equal 
        # to the specified ID.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $MaxID,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [DateTime]
        $Since,

        # Returns tweets generated before the given date. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [DateTime]
        $Until,

        # Optional. Specifies what type of search results you would prefer to receive. 
        # The current default is "mixed." Valid values include:
        # * mixed: Include both popular and real time results in the response.
        # * recent: return only the most recent results in the response
        # * popular: return only the most popular results in the response.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('Mixed', 'Recent', 'Popular')]
        [String]
        $SearchType,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = 'Geo')]
        [double]
        $Latitude,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = 'Geo')]
        [double]
        $Longitude,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = 'Geo')]
        [int]
        $Radius,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('All', 'OriginalTweetsOnly', 'RetweetsOnly')]
        [String]
        $Filter

     )
 
     Begin
     {
        $logged = [Tweetinvi.User]::GetLoggedUser()
        if ($logged -eq $null)
        {
           Write-Error -Message 'You are not currently logged in, please use Connect-TweetService command to connect.'
           return
        }
     }
     Process
     {
        # Set Parameters
        $SearchParams = [Tweetinvi.Search]::GenerateSearchTweetParameter($Query)

        # SetFilter
        if ($Filter)
        {
            switch ($Filter)
            {
                'All'                
                { $UseFilter = [Tweetinvi.Core.Interfaces.Models.Parameters.TweetSearchFilter]::All }
                
                'OriginalTweetsOnly' 
                { $UseFilter = [Tweetinvi.Core.Interfaces.Models.Parameters.TweetSearchFilter]::OriginalTweetsOnly }
                
                'RetweetsOnly'       
                { $UseFilter = [Tweetinvi.Core.Interfaces.Models.Parameters.TweetSearchFilter]::RetweetsOnly }
            }

            $SearchParams.TweetSearchFilter = $UseFilter
        }

        # Set search type.
        if ($SearchType)
        {
            switch ($SearchType)
            {
                'Mixed'                
                { $SrchType = [Tweetinvi.Core.Enum.SearchResultType]::Mixed }
                
                'Recent' 
                { $SrchType = [Tweetinvi.Core.Enum.SearchResultType]::Recent }
                
                'Popular'       
                { $SrchType = [Tweetinvi.Core.Enum.SearchResultType]::Popular }
            }

            $SearchParams.SearchType = $SrchType
        }

        # Set Geo Search
        if ($PSCmdlet.ParameterSetName -eq 'Geo')
        {
            $SearchParams.SetGeoCode($Longitude, $Latitude, $Radius)
        }

        # Set remaining parameters
        if ($Count) {$SearchParams.MaximumNumberOfResults = $Count}
        if ($MaxID) {$SearchParams.MaxId = $MaxID}
        if ($SinceID) {$SearchParams.SinceId = $SinceID}
        if ($Since) {$SearchParams.Since = $Since}
        if ($Until) {$SearchParams.Until = $Until}

        [Tweetinvi.Search]::SearchTweets($SearchParams)
     }
     End
     {
     }
 }