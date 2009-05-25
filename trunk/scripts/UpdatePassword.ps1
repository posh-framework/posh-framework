#
# The following parameters are required:
#
#	$strUser = User account
#	$strPassword = User account password
#	$strComputer = Computer name
#
# May 22, 2009: Jeff Patton
#
# Begin framework code
#
$ScriptParameters = @()

$param = New-Object PSObject
$param | add-member NoteProperty Name 'User'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the username'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'Password'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the new password'
$ScriptParameters += $param

if($OU -eq $False -and $CSV -eq $False)
{
    #Define parameters
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'Computer'
    $param | add-member NoteProperty Value ([ADSI]"WinNT://$env:ComputerName").name
    $param | add-member NoteProperty Prompt 'The computer that contains the local group you are adding to'
    $ScriptParameters += $param
}

$ScriptDescription = "Change the password of a user account."
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{
	function Set-UserPassword($strUser, $strPassword, $strComputer)
	{
		$objUser = [adsi]"WinNT://$strComputer/$strUser,user"
		$objUser.SetPassword($strPassword)
		$objUser.SetInfo()
	}

	If($OU -eq $True)
	{
		$script:comp = $ADSObject.Properties.name[0]
	}
	ElseIf($CSV -eq $True)
	{
	    $script:comp = $CSVObject.Computer
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
	$script:PasswordChanged=Set-UserPassword $User $Password $script:comp

	$output = New-Object psobject
	$output | add-member noteproperty Computer $script:comp
	$output | add-member noteproperty Success`? $script:Success
	$output | add-member noteproperty Message $script:ErrorMessage
	Write-Output $output
}