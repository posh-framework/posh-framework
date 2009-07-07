# Backup all GPOs in a specified domain to a specified folder
# Requires that GPMC has been installed.
$ScriptParameters = @()

$param = New-Object PSObject
$param | add-member NoteProperty Name 'DomainName'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'The FQDN domain name of you wish to backup the GPOs for, i.e. domain.example.com'
$param | add-member NoteProperty Display 'Domain Name FQDN'
$param | add-member NoteProperty Type "String"
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'BackupDirectory'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Path to folder to backup GPOs'
$param | add-member NoteProperty Type 'folder'
$param | add-member NoteProperty Display 'Backup Directory'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'BackupComment'
$param | add-member NoteProperty Value (get-date).toString()
$param | add-member NoteProperty Prompt 'Comment to add to the backup'
$param | add-member NoteProperty Display 'Backup Comment'
$param | add-member NoteProperty Type "String"
$ScriptParameters += $param



$ScriptDescription = 'Group Policy Management Console required.  Does a backup of all GPOs to a specified folder'
$ScriptThreaded = $False
$OU = $False
$CSV = $False

$ScriptBlock = 
{
    $ErrorActionPreference = "stop"

    trap [Exception]
    {
	write-error $_.Exception.Message
	exit
    }
    
    #Grab all the GPOs in the domain with an empty search, and then
    #loop through and back them up
    $GPMCObject = New-Object -ComObject GPMgmt.GPM
    $GPMConstants = $GPMCObject.GetConstants()
    $GPMDomain = $GPMCObject.GetDomain($DomainName, "", $GPMConstants.UseAnyDC)
    $AllGPSearch = $GPMCObject.CreateSearchCriteria()
    $AllGPOs = $GPMDomain.SearchGPOs($AllGPSearch)
    foreach($GPO in $AllGPOs)
    {
	$output = New-Object PSObject
	$output | add-member noteproperty Name $GPO.DisplayName
	$result = $GPO.Backup($BackupDirectory, $BackupComment)
	$overallStatus = $result.OverallStatus()
	$status = "Success"
	if($overallStatus.Status.Count -gt 0)
	{
	    $status = "Failed"
	}
	$output | add-member noteProperty Status $status
	write-output $output
    }
}