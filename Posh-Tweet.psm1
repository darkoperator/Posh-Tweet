
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

        $FolderName = "Posh-Tweet"
        $ConfigName = "config.json"
        
        if (!(Test-Path "$($env:AppData)\$FolderName"))
        {
            Write-Verbose -Message "Seems this is the first time the config has been set."
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
    [OutputType([HigLabo.Net.Twitter.TwitterClient])]
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
            throw "Configuration has not been set, Set-TweetTokens to configure the API Tokens."
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

        $TwitterClient = New-Object HigLabo.Net.Twitter.TwitterClient($ConfigObj.APIKey,
                                                                      $ConfigObj.APISecret,
                                                                      $ConfigObj.AccessToken,
                                                                      $ConfigObj.AccessTokenSecret)

        # Save client instance in to a variable other functions can use.
        $Global:TweetInstance = $TwitterClient
        
        $TwitterClient
    }
    End
    {
    }
}


<#
.Synopsis
   Returns settings (including current trend, geo and sleep time information) 
   for the authenticating user.
.DESCRIPTION
   Returns settings (including current trend, geo and sleep time information) 
   for the authenticating user.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetAccountSetting
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param()

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $AccountSettingResponse = $TwClient.GetAccountSettings()
        $JSONPSCustom = $AccountSettingResponse.JsonText | ConvertFrom-Json
        $JSONPSCustom.pstypenames.insert(0,'Tweet.Account.Setting')
        $JSONPSCustom
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
function Get-TweetApplicationRateLimit
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param()

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $AppLimitResult = $TwClient.GetApplicationRateLimitStatus()
        $JSONPSCustom = $AppLimitResult.JsonText | ConvertFrom-Json
        $JSONPSCustom.pstypenames.insert(0,'Tweet.Application.Limit')
        $JSONPSCustom
    }
    End
    {
    }
}


<#
.Synopsis
   Updates the authenticating user's current status, also known as tweeting. 
.DESCRIPTION
   Updates the authenticating user's current status, also known as tweeting. 
.EXAMPLE
   Sending a Tweet

   PS C:\> Send-Tweet -Message "@digininja cant complain"


    ID        : 439382933800255488
    Text      : @digininja cant complain
    CreatedAt : 2/28/2014 12:53:49 PM +00:00
    Source    : <a href="http://github.com/darkoperator" rel="nofollow">Posh-Tweet</a>
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

        # The latitude of the location this tweet refers to. This parameter 
        # will be ignored unless it is inside the range -90.0 to +90.0 (North 
        # is positive) inclusive.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = 'Geo')]
        [string]
        $Latitude,

        # The longitude of the location this tweet refers to. The valid ranges
        # for longitude is -180.0 to +180.0 (East is positive) inclusive. 
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = 'Geo')]
        [string]
        $Longitude
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        $TweetOps = New-Object HigLabo.Net.Twitter.UpdateStatusCommand 
    }
    Process
    {
        $TweetOps.Status = $Message
        if ($ReplyToID)
        {
            $TweetOps.InReplyToStatusID = $ReplyToID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Geo')
        {
            $TweetOps.Longitude = $Longitude
            $TweetOps.Latitude = $Latitude
        }

        $TweetResult = $TwClient.UpdateStatus($TweetOps)
        $TweetResult.pstypenames.insert(0,'Tweet.SentMessage')
        $TweetResult
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
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [long]
        $Id
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $StatusMsg = $TweetInstance.DestroyStatus($Id)
        $StatusMsg.pstypenames.insert(0,'Tweet.SentMessage')
        $StatusMsg
    }
    End
    {
    }
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
        [int]
        $Count,

        # This parameter will prevent replies from appearing in the returned 
        # timeline. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ExcludeReplies,

        # Returns results with an ID greater than (that is, more recent than)
        # the specified ID. There are limits to the number of Tweets which can
        # be accessed. If the limit of Tweets has occured since the since_id,
        # the since_id will be forced to the oldest ID available.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $SinceID
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        # Set options for the query of messages
        $TimelineOptions = new-object HigLabo.Net.Twitter.GetHomeTimelineCommand
    }
    Process
    {
        if ($Count)
        {
            $TimelineOptions.Count = $Count
        }

        if ($ExcludeReplies)
        {
            $TimelineOptions.ExcludeReplies = 'true'
        }

        if ($SinceID)
        {
            $TimelineOptions.SinceID = $SinceID
        }


        $TimelineResult = $TwClient.GetHomeTimeline($TimelineOptions)
        foreach($Message in $TimelineResult)
        {
            $Message.pstypenames.insert(0,'Tweet.Message')
            $Message | Add-Member -NotePropertyName Name -NotePropertyValue $Message.User.Name
            $Message | Add-Member -NotePropertyName ScreenName -NotePropertyValue $Message.User.ScreenName
            $Message
        }
    }
    End{}
}


<#
.Synopsis
   Returns the 20 most recent mentions (tweets containing a users's 
   @screen_name) for the authenticating user.
.DESCRIPTION
   Returns the 20 most recent mentions (tweets containing a users's 
   @screen_name) for the authenticating user. The timeline returned 
   is the equivalent of the one seen when you view your mentions on 
   twitter.com. 
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
        $Count,

        # This parameter will prevent replies from appearing in the returned 
        # timeline. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ExcludeReplies,

        # Returns results with an ID greater than (that is, more recent than)
        # the specified ID. There are limits to the number of Tweets which can
        # be accessed. If the limit of Tweets has occured since the since_id,
        # the since_id will be forced to the oldest ID available.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $SinceID
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        # Set options for the query of messages
        $TimelineOptions = new-object HigLabo.Net.Twitter.GetMentionsTimelineCommand
    }
    Process
    {
        if ($Count)
        {
            $TimelineOptions.Count = $Count
        }

        if ($ExcludeReplies)
        {
            $TimelineOptions.ExcludeReplies = 'true'
        }

        if ($SinceID)
        {
            $TimelineOptions.SinceID = $SinceID
        }


        $TimelineResult = $TwClient.GetMentionsTimeline($TimelineOptions)
        foreach($Message in $TimelineResult)
        {
            $Message.pstypenames.insert(0,'Tweet.Message')
            $Message | Add-Member -NotePropertyName Name -NotePropertyValue $Message.User.Name
            $Message | Add-Member -NotePropertyName ScreenName -NotePropertyValue $Message.User.ScreenName
            $Message
        }
    }
    End{}
}

<#
.Synopsis
   Returns the most recent tweets authored by the authenticating user 
   that have been retweeted by others. 
.DESCRIPTION
   Returns the most recent tweets authored by the authenticating user 
   that have been retweeted by others. 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetRetweetTimeline
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
        $Count,

        # This parameter will prevent replies from appearing in the returned 
        # timeline. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ExcludeReplies,

        # Returns results with an ID greater than (that is, more recent than)
        # the specified ID. There are limits to the number of Tweets which can
        # be accessed. If the limit of Tweets has occured since the since_id,
        # the since_id will be forced to the oldest ID available.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $SinceID
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        # Set options for the query of messages
        $TimelineOptions = new-object HigLabo.Net.Twitter.GetRetweetsOfMeTimelineCommand
    }
    Process
    {
        if ($Count)
        {
            $TimelineOptions.Count = $Count
        }

        if ($ExcludeReplies)
        {
            $TimelineOptions.ExcludeReplies = 'true'
        }

        if ($SinceID)
        {
            $TimelineOptions.SinceID = $SinceID
        }


        $TimelineResult = $TwClient.GetRetweetsOfMeTimeline($TimelineOptions)
        foreach($Message in $TimelineResult)
        {
            $Message.pstypenames.insert(0,'Tweet.Message')
            $Message | Add-Member -NotePropertyName Name -NotePropertyValue $Message.User.Name
            $Message | Add-Member -NotePropertyName ScreenName -NotePropertyValue $Message.User.ScreenName
            $Message
        }
    }
    End{}
}

<#
.Synopsis
   Returns the most recent tweets authored by the authenticating user 
   that have been retweeted by others. 
.DESCRIPTION
   Returns the most recent tweets authored by the authenticating user 
   that have been retweeted by others. 
.EXAMPLE
   PS C:\ Get-TweetUserTimeline -ScreenName jsnover -Count 2 -IncludeRT


    ID         : 437942603602862082
    Name       : jsnover
    ScreenName : jsnover
    Text       : @SuchTechnology DSC is a platform that Chef/Puppet can layer on.  We'll get the ecosystem to write providers &amp; everyone can use them.
    CreatedAt  : 2/24/2014 1:30:27 PM +00:00
    Source     : web

    ID         : 437941912608071680
    Name       : jsnover
    ScreenName : jsnover
    Text       : RT @SuchTechnology: If you are your team's genius or you ever worked with one, please take 5 to read @jsnover post "On Heroes" http://t.co/…
    CreatedAt  : 2/24/2014 1:27:43 PM +00:00
    Source     : web

#>
function Get-TweetUserTimeline
{
    [CmdletBinding(DefaultParameterSetName = 'ScreenName')]
    [OutputType([psobject])]
    Param
    (
        # Specifies the number of records to retrieve. Must be less than or 
        # equal to 200. Defaults to 20.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $Count,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName = 'UserID')]
        [string]
        $UserID,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName = 'ScreenName')]
        [string]
        $ScreenName,

        # This parameter will prevent replies from appearing in the returned 
        # timeline. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ExcludeReplies,

        # Returns results with an ID greater than (that is, more recent than)
        # the specified ID. There are limits to the number of Tweets which can
        # be accessed. If the limit of Tweets has occured since the since_id,
        # the since_id will be forced to the oldest ID available.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $SinceID,

        # Include ReTweets since the timeline will strip any native retweets 
        # (though they will still count toward both the maximal length of the 
        # timeline and the slice selected by the count parameter). 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $IncludeRT
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        # Set options for the query of messages
        $TimelineOptions = new-object HigLabo.Net.Twitter.GetUserTimelineCommand
    }
    Process
    {
        if ($Count){ $TimelineOptions.Count = $Count }

        if ($ExcludeReplies){ $TimelineOptions.ExcludeReplies = 'true' }

        if ($SinceID){ $TimelineOptions.SinceID = $SinceID }

        if ($IncludeRT){ $TimelineOptions.IncludeRts = "true" }

        if ($PSCmdlet.ParameterSetName -eq 'ScreenName')
        {
            $TimelineOptions.ScreenName = $ScreenName
        }
        else
        {
            $TimelineOptions.UserID = $UserID
        }


        $TimelineResult = $TwClient.GetUserTimeline($TimelineOptions)
        foreach($Message in $TimelineResult)
        {
            $Message.pstypenames.insert(0,'Tweet.Message')
            $Message | Add-Member -NotePropertyName Name -NotePropertyValue $Message.User.Name
            $Message | Add-Member -NotePropertyName ScreenName -NotePropertyValue $Message.User.ScreenName
            $Message
        }
    }
    End{}
}


<#
.SYNOPSIS
    Returns the most recent direct messages sent to the authenticating user

.DESCRIPTION
    Returns the 20 most recent direct messages by default sent to the
    authenticating user. Includes detailed information about the sender
    and recipient user. 

.PARAMETER Count
    Specifies the number of records to retrieve. Must be less than or 
    equal to 200. Defaults to 20.

.PARAMETER SinceID
    Returns results with an ID greater than (that is, more recent than)
    the specified ID. There are limits to the number of Tweets which can
    be accessed. If the limit of Tweets has occured since the since_id,
    the since_id will be forced to the oldest ID available.

.PARAMETER MaxID
    Returns results with an ID less than (that is, older than) or equal 
    to the specified ID.


.NOTES
    Important: This method requires an access token with RWD (read, write & 
    direct message) permissions.

#>
function Get-TweetDMTimeline
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
        $Count,

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
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        # Set options for the query of messages
        $TimelineOptions = New-Object HigLabo.Net.Twitter.GetDirectMessageListCommand
    }
    Process
    {
        if ($Count)
        {
            $TimelineOptions.Count = $Count
        }

        if ($MaxID)
        {
            $TimelineOptions.MaxID = $MaxID
        }

        if ($Page)
        {
            $TimelineOptions.Page = $Page
        }

        if ($SinceID)
        {
            $TimelineOptions.SinceID = $SinceID
        }


        $TimelineResult = $TwClient.GetDirectMessageList($TimelineOptions)
        foreach($Message in $TimelineResult)
        {
            $Message.pstypenames.insert(0,'Tweet.DirectMessage')
            $Message
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
function Get-TweetDMSentTimeline
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
        $Count,

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
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        # Set options for the query of messages
        $TimelineOptions = New-Object HigLabo.Net.Twitter.GetDirectMessageListCommand
    }
    Process
    {
        if ($Count)
        {
            $TimelineOptions.Count = $Count
        }

        if ($MaxID)
        {
            $TimelineOptions.MaxID = $MaxID
        }

        if ($Page)
        {
            $TimelineOptions.Page = $Page
        }

        if ($SinceID)
        {
            $TimelineOptions.SinceID = $SinceID
        }


        $TimelineResult = $TwClient.GetDirectMessageListSent($TimelineOptions)
        foreach($Message in $TimelineResult)
        {
            $Message.pstypenames.insert(0,'Tweet.DirectMessage')
            $Message
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
function Remove-TweetDMMessage
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
        [long]
        $Id
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $DeletedDM = $TwClient.DestroyDirectMessage($Id)
        $DeletedDM.pstypenames.insert(0,'Tweet.DirectMessage')
        $DeletedDM
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
function Send-TweetDM
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Twitter message to send. Limit of 140 charecters.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateLength(1,140)]
        [string]
        $Message,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ScreenName
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        $DMOps = New-Object HigLabo.Net.Twitter.NewDirectMessageCommand
    }
    Process
    {
        $DMOps.Text = $Message
        $DMOps.ScreenName = $ScreenName
        $TweetResult = $TwClient.NewDirectMessage($DMOps)
        $TweetResult.pstypenames.insert(0,'Tweet.DirectMessage')
        $TweetResult
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
function Get-TweetBlockList
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]$IncludeEntities,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]$SkipStatus
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        $BlockCmd = New-Object HigLabo.Net.Twitter.GetBlocksListCommand

        if ($IncludeEntities)
        {
            $BlockCmd.IncludeEntities = $IncludeEntities
        }

        if ($SkipStatus)
        {
            $BlockCmd.SkipStatus = $SkipStatus
        }
    }
    Process
    {
        $BlockedUsers = $TwClient.GetBlocksList($BlockCmd).users
        foreach($bUser in $BlockedUsers)
        {
            $bUser.pstypenames.insert(0, 'Tweet.User.Blocked')
            $bUser
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
            Position=0)]
        $ScreenName
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        $BlockOps = New-Object HigLabo.Net.Twitter.CreateBlocksCommand
    }
    Process
    {
        $BlockOps.ScreenName = $ScreenName
        $bUser = $TwClient.CreateBlocks($BlockOps)

        $bUser.pstypenames.insert(0, 'Tweet.User.Blocked')
        $bUser
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
            Position=0)]
        $ScreenName
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        $BlockOps = New-Object HigLabo.Net.Twitter.DestroyBlocksCommand
    }
    Process
    {
        $BlockOps.ScreenName = $ScreenName
        $bUser = $TwClient.DestroyBlocks($BlockOps)

        $bUser.pstypenames.insert(0, 'Tweet.User.Blocked')
        $bUser
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
function Remove-TweetFollow
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $ScreenName
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $TwUser = $TwClient.DestroyFriendship($ScreenName)
        $TwUser.pstypenames.insert(0, 'Tweet.User')
        $TwUser
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
function Add-TweetFollow
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $ScreenName
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $TwUser = $TwClient.CreateFriendship($ScreenName)
        $TwUser.pstypenames.insert(0, 'Tweet.User')
        $TwUser
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
function Get-TweetFollowing
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Param1,

        # Param2 help description
        [int]
        $Param2
    )

    Begin
    {
    }
    Process
    {
    }
    End
    {
    }
}
