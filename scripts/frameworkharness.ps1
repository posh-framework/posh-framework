#Define parameters
$ScriptParameters = @();
$param = New-Object PSObject
$param | add-member NoteProperty Name 'displayText'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Text to display back'
$ScriptParameters += $param

$ScriptDescription = 'Script for displaying a parameter'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'
$ScriptBlock = {write-output $displayText}
