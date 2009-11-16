# This script will check to see if the specified file is on a given computer.
# This script works against an OU, local machine or csv file.
# Jeff Patton 11/16/2009

$ScriptParameters = @();
$param = New-Object PSObject
$param | add-member NoteProperty Name 'PathToFile'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'UNC or local path and filename'
$param | add-member NoteProperty Display 'Path'
$param | add-member NoteProperty Type "String"
$ScriptParameters += $param

$ScriptDescription = 'Check for the existence of a file'
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'
$ScriptBlock = 
{

     Function Check-File($computer, $path)
          {
               Test-Path -Path \\$computer\$path
          }

     If($OU -eq $True)
          {
               $script:comp = $ADSObject.Properties.name[0]
          }
               ElseIf( $CSV -eq $True)
          {
               $script:comp = $CSVObject.Computer
          }
               Else
          {
               $script:comp = $Computer
          }

     $ErrorActionPreference = "stop"
     $script:Success = $True

     trap [Exception]
     {
          $script:ErrorMessage = $_.Exception.Message
          $script:Success = $False
          continue
     }

     If ($PathToFile.Contains(":"))
     { $PathToFile = $PathToFile -replace(":","$") }

     $Script:FileExists=Check-File $script:comp $PathToFile 

     $output = New-Object psobject
     $output | add-member noteproperty Computer $script:comp
     $output | add-member noteproperty Search $PathToFile
     $output | add-member noteproperty FileExists $Script:FileExists
     Write-Output $output
}

