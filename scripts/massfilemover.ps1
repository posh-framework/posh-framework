#Uses the framework to copy a file to a remote computer

$ScriptParameters = @();
$param = New-Object PSObject
$param | add-member NoteProperty Name 'FromFile'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Please enter the path of the file you wish to copy on the remote computer.'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'ToFile'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Please enter the path you would like the file to be copied to.'
$ScriptParameters += $param

if($OU -eq $False)
{
    #Define parameters
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'Computer'
    $param | add-member NoteProperty Value ''
    $param | add-member NoteProperty Prompt 'The computer you wish to find out the current user for'
    $ScriptParameters += $param
}

$ScriptDescription = 'Copies a file to a remote computer using the administrative C$ Share.'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'

$ScriptBlock =
{
    $ErrorActionPreference = "stop"

    if($OU -eq $True)
    {
	$script:comp = $ADSObject.Properties.name[0]
    }
    else
    {
        $script:comp = $Computer
    }

    $script:copySuccess = 'True'
    trap [Exception]
    {
        $script:copySuccess = 'False'
        continue
    }
    cp $fromFile \\$comp\$ToFile
    $output = New-Object psobject
    $output | add-member noteproperty Computer $script:comp
    $output | add-member noteproperty Successful $script:copySuccess
    Write-Output $output
}
