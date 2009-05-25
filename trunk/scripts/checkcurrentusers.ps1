#Check user logged into computers in a specific ou

$ScriptParameters = $Null

if($OU -eq $False -and $CSV -eq $False)
{
    #Define parameters
    $ScriptParameters = @();
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'Computer'
    $param | add-member NoteProperty Value ''
    $param | add-member NoteProperty Prompt 'The computer you wish to find out the current user for'
    $ScriptParameters += $param
}
$ScriptDescription = 'Checks the current user of a computer or computers'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{
    function Get-CurrentUser($computer)
    {
        $compsystem = Get-WmiObject win32_computersystem -computername $computer
        return $compsystem.username
    }

    $ErrorActionPreference = "stop"

    if($OU -eq $True)
    {
	$script:comp = $ADSObject.Properties.name[0]
    }
    elseif($CSV -eq $True)
    {
	$script:comp = $CSVObject.Computer
    }
    else
    {
        $script:comp = $Computer
    }
    $script:currUser = ''
    trap [Exception]
    {
        $script:currUser = 'Could not connect'
        continue
    }
    $script:currUser=Get-CurrentUser $script:comp
    $output = New-Object psobject
    $output | add-member noteproperty Computer $script:comp
    $output | add-member noteproperty User $script:currUser
    Write-Output $output
}