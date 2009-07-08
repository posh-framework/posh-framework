#
# The following parameters are required:
#
# $strRoot = Hive to start in
# $strPath = Reg Path
# $strComputer = Computer to create account on
#
# June 22, 2009: Jeff Patton
#
# Begin framework code
#
$ScriptParameters = @()
$param = New-Object PSObject
$param | add-member NoteProperty Name 'RegRoot'
$param | add-member NoteProperty Display 'Registry Root'
$param | add-member NoteProperty Type 'Choice'
$param | add-member NoteProperty Value 'LocalMachine|CurrentUser'
$param | add-member NoteProperty Prompt 'Enter the hive you wish to open ex. HKLM'
$ScriptParameters += $param
 
$param = New-Object PSObject
$param | add-member NoteProperty Name 'RegPath'
$param | add-member NoteProperty Display 'Registry Path'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the path to the registry key you wish to view.'
$ScriptParameters += $param
 
$param = New-Object PSObject
$param | add-member NoteProperty Name 'RegKey'
$param | add-member NoteProperty Display 'Registry Key'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the key that you wsih to view'
$ScriptParameters += $param
 
if($OU -eq $False -and $CSV -eq $False)
{
    #Define parameters
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'Computer'
    $param | add-member NoteProperty Value ([ADSI]"WinNT://$env:ComputerName").name
    $param | add-member NoteProperty Prompt 'The computer that contains the local group you are adding to'
    $ScriptParameters += $param
}
 
$ScriptDescription = "Allows you to view a specific registry entry"
$ScriptThreaded = $True
$ScriptADSObjectType = 'computer'
 
$ScriptBlock =
{
    function Get-RemoteRegistry([string] $root, [string] $path, [string] $computer)
    {
        if($path -eq "") {
            return "A valid path should be provided"
        }
	
        #Access Remote Registry Key using OpenRemoteBaseKey method. The syntax shown below is
        #used to access static methods on types
        $rootkey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($root,$computer)
   
        #Traverse the registry hierarchy
        $key = $rootKey.OpenSubKey($path, $true)
        return $key;
    }

    If($OU -eq $True)
    {
        $script:comp = [String] $ADSObject.Properties.name[0]
    }
    ElseIf( $CSV -eq $True)
    {
        $script:comp = [String]$CSVObject.Computer
    }
    Else
    {
        $script:comp = $Computer
    }
    
    $ErrorActionPreference = "stop"
    $script:Success = $True
    $script:ErrorMessage = ''

    trap [Exception]
    {
        $script:ErrorMessage = $_.Exception.Message
        $script:Success = $False
        continue
    }

    
    $CheckReg = Get-RemoteRegistry $RegRoot $RegPath $script:comp
    $Val = [String] $CheckReg.GetValue($RegKey)

    $output = New-Object psobject
    $output | add-member noteproperty Value $Val
    $output | add-member noteproperty Computer $script:comp
    $output | add-member noteproperty Success`? $script:Success
    $output | add-member noteproperty Message $script:ErrorMessage
    Write-Output $output
}

