#This script will start a specified service on a given
#computer or OU of computers.

$ScriptParameters = @();
$param = New-Object PSObject
$param | add-member NoteProperty Name 'Service'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Please enter the service name you wish to start.'
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
$ScriptDescription = 'Starts a specified service on a computer or OU of computers'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{

    function Start-Service($service, $computer)
    {
	$serv = Get-WmiObject -ComputerName $computer Win32_Service -Filter "Name='$service'"
	$serv.StartService()
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

    $script:serviceStarted = ''
    trap [Exception] {
        $script:serviceStarted = 'Could not connect'
        continue
    }

    $serviceStatus = Start-Service $service $script:comp
    if($script:serviceStarted -ne 'Could not connect') {
        if($serviceStatus.ReturnValue -eq 10) {
            $script:serviceStarted = "Already Started"
        }
        elseif($serviceStatus.ReturnValue -eq 0) {
            $script:serviceStarted = "True"
        }
        else {
            $script:serviceStarted = "Unhandled Return Code: $ServiceStatus.ReturnValue"
        }
    }

    $output = New-Object psobject
    $output | add-member noteproperty Computer $script:comp
    $output | add-member noteproperty Service` Started`? $script:serviceStarted
    Write-Output $output
}
