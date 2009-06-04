#Define parameters
$ScriptParameters = @();
$param = New-Object PSObject
$param | add-member NoteProperty Name 'displayText'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Text to display back'
$param | add-member NoteProperty Display 'Display Text'
$param | add-member NoteProperty Type "String"
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'CheckBox'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'For testing the checkbox'
$param | add-member NoteProperty Type 'Boolean'
$param | add-member NoteProperty Display 'Test CheckBox'
$ScriptParameters += $param

$ScriptDescription = 'Script for displaying a parameter'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'
$ScriptBlock = 
{
    write-output $displayText
    if($CheckBox)
    {
	write-output "Checkbox is True"
    }
    else
    {
	write-output  "Checkbox is False"
    }
	
}
