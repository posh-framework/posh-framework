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
$param | add-member NoteProperty Name 'FolderChooser'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'For testing the folder chooser'
$param | add-member NoteProperty Type 'folder'
$param | add-member NoteProperty Display 'Test Folder'
$ScriptParameters += $param


$param = New-Object PSObject
$param | add-member NoteProperty Name 'CheckBox'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'For testing the checkbox'
$param | add-member NoteProperty Type 'Boolean'
$param | add-member NoteProperty Display 'Test CheckBox'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'ListChooser'
$param | add-member NoteProperty Value 'Peas|Carrots|Cabbage|Beats|Onions'
$param | add-member NoteProperty Prompt 'For testing the list/choice type'
$param | add-member NoteProperty Type 'List'
$param | add-member NoteProperty Display 'Favorite Vegetable'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'FileChooser'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'For testing the file chooser'
$param | add-member NoteProperty Type 'File'
$param | add-member NoteProperty Display 'Test File'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'Spinner'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'For testing the number spinner'
$param | add-member NoteProperty Type 'Number'
$param | add-member NoteProperty Display 'Test Number'
$ScriptParameters += $param



$ScriptDescription = 'Script for showing features'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'
$ScriptBlock = 
{
    write-output "Display Text: $displayText"
    if($CheckBox)
    {
	write-output "Checkbox is True"
    }
    else
    {
	write-output  "Checkbox is False"
    }
    write-output ("Spinner times 5 = " + (5*$Spinner))
    write-output "FilePath: $FileChooser"
    write-output "FolderPath: $FolderChooser"
    write-output "Favorite Vegetable: $ListChooser"
}
