#Given an OU or computer, this prints out the MAC-Address
#of all the computers

$ScriptParameters = @();
$param = New-Object PSObject
$param | add-member NoteProperty Name 'IPPart'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Used to filter the interesting network adapter, can be something like .168. or 192.168.'
$ScriptParameters += $param

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

$ScriptDescription = 'Gets the MAC Address of a computer or OU of computers on an IP range'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{

    $ErrorActionPreference="stop"

    if($OU -eq $True)
    {
	$script:comp = $ADSObject.Properties.name[0]
    }
    else
    {
        $script:comp = $Computer
    }

    trap [Exception]
    {
	continue
    }
    $output = new-object psobject
    $output | add-member noteproperty Computer $script:comp
    $netconfig = Get-WmiObject Win32_NetworkAdapterConfiguration -computername $comp | Where-Object {$_.IPAddress -Like "*$IPPart*"}
    if($netconfig.length -gt 1)
    {
	$mac = [String] $netconfig[0].MACAddress
    }
    else
    {
	$mac = [String] $netconfig.MACAddress
    }

    $output | add-member noteproperty MACAddress $mac
    Write-Output $output
}
