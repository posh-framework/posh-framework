#Add FullControl to a file and User/Group

$ScriptParameters = @()
$param = New-Object PSObject
$param | add-member NoteProperty Name 'UserOrGroup'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the username or groupname to give full control'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'ComputerOrDomain'
$param | add-member NoteProperty Value '.'
$param | add-member NoteProperty Prompt 'Enter the computer or domain the user or group belong to'
$ScriptParameters += $param

$param = New-Object PSObject
$param | add-member NoteProperty Name 'Path'
$param | add-member NoteProperty Value ''
$param | add-member NoteProperty Prompt 'Enter the path to add full control to'
$ScriptParameters += $param

$ScriptDescription = 'Adds Full Control to a file or folder'
$OU = $False
$CSV = $False
$ScriptBlock = 
{
    function Add-FullControl($path, [ADSI]$user)
    {
	$acl = get-acl -path $path
	$sid = New-Object System.Security.Principal.SecurityIdentifier($user.objectSid[0], 0)
	$prop=[System.Security.AccessControl.PropagationFlags]::InheritOnly
	$object = Get-ChildItem $path
	if( $object.PSIsContainer -eq $True)
	{
	    $Inherit=[System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
	}
	else
	{
	    $Inherit = 'None'
	}
	$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid,"FullControl", $Inherit, $Prop, "Allow")
	$acl.AddAccessRule($accessRule)
	$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid,"FullControl", "Allow")
	$acl.AddAccessRule($accessRule)
	set-acl -AclObject $acl -Path $path
    }
    
    $ErrorActionPreference = "stop"
    
    trap [Exception]
    {
	write-host "An Error Ocurred trying to give full control:"
	write-host $_.Exception.Message
	continue
    }
    $SecurityObject = [ADSI] ("WinNT://$ComputerOrDomain/$UserOrGroup")
    
    Add-FullControl $Path $SecurityObject
    
}
