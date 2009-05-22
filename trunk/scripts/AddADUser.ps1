#
# The following parameters are required:
#
#	$strUser = User account to create
#	$strGroup = Local computer group
#	$strComputer = Computer to create account on
#	$strDomain = Active Directory Domain Name
#
# May 22, 2009: Jeff Patton
#
# Begin framework code
#
$ScriptParameters = @()
$param = New-Object PSObject
$param | add-member NoteProperty Name 'User'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the username or groupname to add the group'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'ComputerOrDomain'
$param | add-member NoteProperty Value ([ADSI]"").name
$param | add-member NoteProperty Prompt 'Enter the computer or domain the user or group belongs to'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'Group'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the group to add the user or group to'
$ScriptParameters += $param

if($OU -eq $False)
{
    #Define parameters
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'Computer'
    $param | add-member NoteProperty Value '.'
    $param | add-member NoteProperty Prompt 'The computer that contains the local group you are adding to'
    $ScriptParameters += $param
}

$ScriptDescription = "Add domain users to local group accounts."
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{
	function Set-GroupMembership($strDomain, $strUser, $strGroup, $strComputer)
	{
		$objUser = [ADSI]("WinNT://$strDomain/$strUser")
		$objGroup = [ADSI]("WinNT://$strComputer/$strGroup")

		$objGroup.PSBase.Invoke("Add",$objUser.PSBase.Path)

	}

	If($OU -eq $True)
	{
		$script:comp = $ADSObject.Properties.name[0]
	}
	Else
	{
		$script:comp = $Computer
	}

	$ErrorActionPreference = "stop"
	$script:Success = $True

	trap [Exception]
	{
		$script:ErrorMessage = $_.Exception.Message
		$script:Success = $False
		continue
	}
	$script:GroupUpdated=Set-GroupMembership $ComputerOrDomain $User $Group $script:comp

	$output = New-Object psobject
	$output | add-member noteproperty Computer $script:comp
	$output | add-member noteproperty Success`? $script:Success
	$output | add-member noteproperty Message $script:ErrorMessage
	Write-Output $output
}