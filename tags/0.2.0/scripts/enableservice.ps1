#This script enables and starts a specified service on a computer
#or OU of computers
#TODO: Write handler for the return codes of change-service and 
#      start-service

$ScriptParameters = @();
$param = New-Object PSObject
$param | add-member NoteProperty Name 'ServiceName'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Please enter the service name you wish to enable.'
$ScriptParameters += $param

if($OU -eq $False -and $CSV -eq $False)
{
    #Define parameters
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'Computer'
    $param | add-member NoteProperty Value ''
    $param | add-member NoteProperty Prompt 'The computer you wish to find out the current user for'
    $ScriptParameters += $param
}

$ScriptDescription = 'Enables and starts a specified service on a computer or OU of computers'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock = 
{

    function Start-Service($service, $computer) 
    {
	$serv = Get-WmiObject -ComputerName $computer Win32_Service -Filter "Name='$service'"
	$serv.StartService()
    }

    function Change-Service($service, $startMode, $computer)
    {
	$serv = Get-WmiObject -ComputerName $computer Win32_Service -Filter "Name='$service'"
	$serv.ChangeStartMode($startMode)
    }

    $ErrorActionPreference="stop"

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

    trap [Exception]
    {
        Write-Output "Error enabling $ServiceName on $comp"
        continue
    }
    
    Write-Output "Setting $ServiceName to "Automatic" on $script:comp"
    Change-Service "SAVService" "Automatic" $script:$comp
    Write-Output "Starting Sophos on $script:comp"
    Start-Service "SAVService" $script:$comp 
}
