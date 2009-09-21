#Given an OU or computer, this prints out the MAC-Address
#of all the computers

$ScriptParameters = @();

if($OU -eq $False -and $CSV -eq $False)
{
    #Define parameters
    $ScriptParameters = @();
    $param = New-Object PSObject
    $param | add-member NoteProperty Name 'group'
    $param | add-member NoteProperty Value ''
    $param | add-member NoteProperty Prompt 'Name of group you want membership of'
    $ScriptParameters += $param
}

$ScriptDescription = 'Returns a list of users in a group'
$ScriptThreaded = $True
$ScriptADSObjectType = 'group'

$ScriptBlock =
{
	function Get-GroupMembers($group) {
	        $from = 0
	        $script:all = $false;
	        $members = @()
	        while (! $all) {
	                trap [Exception] {
	                        $script:all = $True;
	                        continue
	                }
	                $to = $from + 999
	                $DS = New-Object DirectoryServices.DirectorySearcher($group,"(objectClass=*)","member;range=$from-$to",'Base')
	                $members += $ds.findall() | foreach {$_.properties | foreach {$_.item($_.PropertyNames -like 'member;*')}}
			if ($members.length -lt 2) {$script:all = $true	}
	                $from += 1000
	        }
	        return $members
	}

    $ErrorActionPreference="stop"

    if($OU -eq $True)
    {
	$script:group = $ADSObject.path
    }
    elseif($CSV -eq $True)
    {
	$script:group = $CSVObject.Group
    }
    else
    {
        $script:comp = $group
    }

    trap [Exception]
    {
	continue
    }
    $script:members = Get-GroupMembers $script:group
    Write-Output ([String]$ADSObject.properties.cn + ":")
    foreach ($member in $script:members) {
	$UserSID = ([ADSI]"LDAP://$member").cn
	$objSID = New-Object System.Security.Principal.SecurityIdentifier($UserSID)
	$objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
	Write-Output ([String]"`t" + $objUser.Value)
	
    }
}
