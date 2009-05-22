#Script lists out the last reboot time of a computer or OU of
#computers.

$ScriptParameters = $Null

if($OU -eq $False)
{
    #Define parameters
    $ScriptParameters = @();
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'Computer'
    $param | add-member NoteProperty Value ''
    $param | add-member NoteProperty Prompt 'The computer you wish to find out the current user for'
    $ScriptParameters += $param
}
$ScriptDescription = 'Checks the last reboot time of a computer or computers'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{

    $ErrorActionPreference="stop"

    function Get-LastBoot($computer)
    {
	$date = Get-WmiObject Win32_OperatingSystem -ComputerName $computer | foreach{$_.LastBootUpTime}
	$RebootTime = [System.DateTime]::ParseExact($date.split('.')[0],'yyyyMMddHHmmss',$null)
	$RebootTime
    }
    if($OU -eq $True)
    {
	$script:comp = $ADSObject.Properties.name[0]
    }
    else
    {
        $script:comp = $Computer
    }

    $script:rebootTime = ''
    trap [Exception]
    {
        $script:rebootTime = 'Could Not Connect'
        continue
    }
    $script:rebootTime = Get-LastBoot $script:comp
    $output = New-Object psobject
    $output | add-member noteproperty Computer $script:comp
    $output | add-member noteproperty Reboot` Time $script:rebootTime
    Write-Output $output
}
