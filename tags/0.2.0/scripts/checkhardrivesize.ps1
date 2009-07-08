#Check the size of a computer or OU of computer's hard drive
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
$ScriptDescription = "Check the size of a computer or OU of computer's hard drive"
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{

    function Get-DiskSizes($computer)
    {
        $disks = Get-WmiObject win32_diskdrive -computername $computer
	$disksizes = @()
	foreach($disk in $disks)
	{
	    $diskbytes = [double] $disk.size
	    $diskbytes = $diskbytes/1024/1024/1024
	    $disksizes += $diskbytes
	}
        return $disksizes
    }

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

    $ErrorActionPreference = "stop"
    $script:diskSizes = ''
    trap [Exception]
    {
        $script:diskSizes = 'Could not connect'
        continue
    }
    $script:diskSizes = Get-DiskSizes $script:comp
    foreach($drive in $script:diskSizes)
    {
	$output = new-object psobject
	$output | add-member noteproperty Computer $script:comp
	$output | add-member noteproperty Disk` Size $drive
	Write-Output $output
    }
}
