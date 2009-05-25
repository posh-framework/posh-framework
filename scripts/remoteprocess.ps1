#Run a given command on a computer or OU of computers remotely


$ScriptParameters = @()

$param = New-Object PSObject
$param | add-member NoteProperty Name 'Command'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the command to run on the remote computer'
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

$ScriptDescription = 'Runs a process on a remote computer or OU of computers.'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{

    function Run-Process($process, $computer)
    {
	$processClass = [wmiclass] "\\$computer\root\cimv2:win32_process"
	$returnObj = $processClass.create($process)
	if($returnObj -eq $null) { return $Null }
	    $myReturn = New-Object PSObject
	$myReturn | add-member noteproperty ReturnCode $returnObj.ReturnValue
	$myReturn | add-member noteproperty ProcessID $returnObj.ProcessID

	return $myReturn
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

    $ErrorActionPreference="stop"

    $script:returnVal = ''
    trap [Exception] {
        $script:returnVal = 'Could not connect'
        continue
    }

    $returnVal = Run-Process $command $script:comp
    if($script:returnVal -ne 'Could not connect') {
        switch ($returnVal.ReturnCode) {
            0 {$returnCode = "Successful"}
            2 {$returnCode = "Access Denied"}
            3 {$returnCode = "Insufficient Privilege"}
            8 {$returnCode = "Unknown Failure"}
            9 {$returnCode = "Path Not Found"}
            21 {$returnCode = "Invalid Parameter"}
            default {$returnCode = "Unknown return code, or null" }
        }
        $processID = $returnVal.ProcessID
    } else {
        $returnCode = 'Could not connect'
        $processID = 'Could not connect'
    }
    $output = New-Object psobject
    $output | add-member noteproperty Computer $script:comp
    $output | add-member noteproperty Return` Value $returnCode
    $output | add-member noteproperty Process` ID $processID
    write-output $output
}
