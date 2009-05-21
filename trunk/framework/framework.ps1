
#  Copyright (C) 2009 Carson Gee
#  Thread- Functions copyright Adam Weigert
#
#  x@carsongee.com
#  242 Michigan St.
#  Lawrence, KS 66044

#    This file is part of Powershell Framework.

#    Powershell Framework is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation version 3 of the License.

#    Powershell Framework is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

param (
   [string] $ScriptPath = '',
   [boolean] $OU = $False,
   $Parameters = $Null,
   [string] $ADSPath = $Null
)

function Parse-Parameters {
    param (
        [PSObject] $ScriptParameters,
        $ArgParameters
    )

    if($ScriptParameters.length -eq 0)
    {
	#Don't care what was passed in, there are no parameters
	return $ScriptParameters
    }
    if($ArgParameters -ne $Null -and $ArgParameters -ne '')
    {
	$PassedParameters = @();
        foreach($Item in $ArgParameters)
	{
	    $values = ([String]$item).split(':')
	    $nameValue = $values[1]
	    if($nameValue -eq '' -or $nameValue -eq $Null)
	    {
		$getParams = $True
	    }
	    $param = New-Object PSObject
            $param | add-member noteproperty Name $values[0]
            $param | add-member noteproperty Value $nameValue
            $PassedParameters += $param
	}
    }
    #Now I have script passed and arg passed parameters
    #fill in the script passed vars with the arg passed values
    foreach($Item in $ScriptParameters)
    {
	$PassedParam = $PassedParameters | Where-Object {$_.Name -eq $Item.Name}
        if($PassedParam.Value -ne $Null -and $PassedParam.Value -ne '')
	{
	    $Item.Value = $PassedParam.Value
	}
    }
    return ,$ScriptParameters

}

function Build-Parameters
{
    param (
        $OU = $False,
        $Parameters = $Null,
        $ADSPath = ''
    )
    $getADSPath = $False
    if($OU -eq $True -and $ADSPath -ne '')
    {
	$CleanADSPath = $ADSPath
    }
    if($OU -eq $True -and $ADSPath -eq '')
    {
        $getADSPath = $True
    }
    $getParams = $False
    if( $Parameters.length -gt 0 )
    {
	foreach($Parameter in $Parameters)
	{
	    if($Parameter.Value -eq $Null -or $Parameter.Value -eq '')
	    {
		$getParams = $True
	        break
	    }
	}
    }
    
    $return_object = New-Object PSObject
    $return_object | add-member noteproperty Parameters $Parameters
    $return_object | add-member noteproperty OU $OU
    $return_object | add-member noteproperty ADSPath $CleanADSPath

    #Create and display the GUI for picking OU, and Parameters
    if( $getParams -eq $True -or $getADSPath -eq $True )
    {
	$new_param_object = Show-ParamGUI $getADSPath $getParams $Parameters
        if( $getParams -eq $True )
	{
	    $return_object.Parameters = $new_param_object.Parameters
	}
	if( $getADSPath -eq $True )
	{
	    $return_object.ADSPath = $new_param_object.ADSPath
	}
    } 
    return $return_object

}

function Show-ScriptChooser
{

    function go
    {
	$kill = $form.close()
    }

    function Browse-Folders
    {
	$app = New-Object -com Shell.Application
	$path = (Get-Location).path
	$folder = $app.BrowseForFolder(0, "Select a folder to look for framework scripts in.", 0,'Desktop') 
	if($folder.Self.Path -ne '')
	{
	    $fileText.Text = $folder.Self.Path
	    Populate-Scripts
	}
    }

    function Populate-Scripts
    {
	$kill = $ScriptList.Items.Clear()
	#Test populating listview
	$scripts = Get-ChildItem -Path $FileText.Text -Filter '*.ps1'
	$path = $FileText.Text
	$i = 0
	if( $scripts.length -gt 0 )
	{
	    foreach($script in $scripts)
	    {
		if( $script.Name -eq 'framework.ps1')
		{
		    break
		}
		#Find ps1 files in the $path that have framework variables
		#Then dot source the script from a [ScriptBlock] "sand box"
		#that matches and grab the value of the Description
		$ScriptMatch = Get-Content $path\$script | Select-String -pattern 'ScriptBlock','ScriptDescription','ScriptParameters'
		if( $ScriptMatch.Count -gt 2 )
		{
		    $eval = 
		    {
			. $path\$script
			$LI = New-Object System.Windows.Forms.ListViewItem
			$LI.Name = $script.Name
			$LI.Text = $script.Name
			$kill = $LI.SubItems.add($ScriptDescription)
			$kill = $ScriptList.Items.Add($LI)
		    }
		    $eval.Invoke()
		}
	    }
	}
    }

    $kill = [reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
    $form = New-Object Windows.Forms.Form
    $form.text = "Select Necessary Parameters"
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $False
    $form.MinimizeBox = $False
    $yOffset = 20
    $folderLabel = New-Object Windows.Forms.Label
    $folderLabel.Location = New-Object Drawing.Point 10,$yOffset
    $folderLabel.Size = New-Object Drawing.Point 200, 20
    $folderLabel.Text = "Folder Containing Framework Script:"
    $form.controls.add($folderLabel)

    #File picking textbox and button
    $fileText = New-Object Windows.Forms.TextBox
    $fileText.Location = New-Object Drawing.Point 210, $yOffset
    $fileText.Size = New-Object Drawing.Point 150, 20
    $currentDir = Get-Location
    $fileText.Text = $currentDir.Path
    $form.controls.add($fileText)

    #Stupid MTA/STA junk, use com instead of .NET for browser dialog
    #$folderDialog = New-Object Windows.Forms.FolderBrowserDialog
    #$folderDialog.ShowNewFolderButton = $False
    #$folderDialog.Description = "Select a folder to look for framework scripts in."
    #$folderDialog.SelectedPath = $currendDir.Path

    $fileButton = New-Object Windows.Forms.Button
    $fileButton.Location = New-Object Drawing.Point 360, $yOffset
    $fileButton.Size = New-Object Drawing.Point 135, 20
    $fileButton.Text = 'Browse...'
    $fileButton.add_click({Browse-Folders})
    $yOffset += 25
    $form.controls.add($fileButton)
   
    #OU Flag Checkbox
    $ouLabel = New-Object Windows.Forms.Label
    $ouLabel.Location = New-Object Drawing.Point 10,$yOffset
    $ouLabel.Size = New-Object Drawing.Point 140, 20
    $ouLabel.Text = "Run script against OU?"
    $form.controls.add($ouLabel)

    $ouCheckBox = New-Object Windows.Forms.CheckBox
    $ouCheckBox.Location = New-Object Drawing.Point 220,$yOffset
    $ouCheckBox.Size = New-Object Drawing.Point 150, 20    
    $ouCheckBox.checked = $OU
    $form.controls.add($ouCheckBox)
    $yOffset += 30
    

    #ListView for showing the scripts that are framework compatible
    $listLabel = New-Object Windows.Forms.Label
    $listLabel.Location = New-Object Drawing.Point 10,$yOffset
    $listLabel.Size = New-Object Drawing.Point 200, 20
    $listLabel.Text = "Framework Scripts:"
    $yOffset += 25
    $form.controls.add($listLabel)

    $ScriptList = New-Object System.Windows.Forms.ListView
    $ScriptList.Location = New-Object Drawing.Point 10, $yOffset
    $ScriptList.Size = New-Object Drawing.Point 490, 300
    $ScriptList.View = 'Details'
    $ScriptList.MultiSelect = $False
    $ScriptPath = ''
    $ScriptList.add_doubleClick({go})

    $colName = $ScriptList.Columns.add('Name')
    $colName.Width = 150
    $colDescription = $ScriptList.Columns.add('Description')
    $colDescription.Width = 315
    $yOffset += 305
    $form.controls.add($ScriptList)
    Populate-Scripts

    $finishButton = New-Object Windows.Forms.Button
    $finishButton.Location = New-Object Drawing.Point 360,$yOffset
    $finishButton.Size = New-Object Drawing.Point 140,20
    $finishButton.Text = "Run Script"
    $kill = $finishButton.add_click({go})
    $form.controls.add($finishButton)    
      
    $form.Size = New-Object Drawing.Point 510, ($yOffset+50)
    $kill = $form.ShowDialog()
    if( $ScriptList.SelectedItems[0].Text -eq $Null )
    {
	return ''
    }
    $ScriptPath = $FileText.Text + '\' + $ScriptList.SelectedItems[0].Text
    #Return ScriptPath and OU
    $return_object = New-Object PSObject
    $return_object | Add-Member NoteProperty OU $OUCheckBox.Checked
    $return_object | Add-Member NoteProperty ScriptPath $ScriptPath
    return $return_object
}

function Show-ParamGUI($getOU, $getParams, $parameters)
{

    function go
    {
	$kill = $form.close()
    }
    

    $kill = [reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
    $form = New-Object Windows.Forms.Form
    $form.text = "Select Necessary Parameters"
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $False
    $form.MinimizeBox = $False
    $yOffset = 20
	
    if($getOU -eq $True)
    {
	$domainLabel = New-Object Windows.Forms.Label
	$domainLabel.Location = New-Object Drawing.Point 10,20
	$domainLabel.Size = New-Object Drawing.Point 150, 20
	$domainLabel.Text = "Select or type in a domain:"


	#Domain picking combo box
	$domainCombo = New-Object Windows.Forms.ComboBox
	$domainCombo.Location = New-Object Drawing.Point 165, 15
	$domainCombo.Size = New-Object Drawing.Point 150, 20
	$domainCombo.TabIndex = 1
	$currentDN = [String] ([ADSI]"").distinguishedName[0]
	$kill = $domainCombo.Items.Add($currentDN)
	$domainCombo.SelectedIndex = 0
	
	$getOUsButton = New-Object Windows.Forms.Button
	$getOUsButton.Location = New-Object Drawing.Point 165, 35
	$getOUsButton.Size = New-Object Drawing.Point 150, 20
	$getOUsButton.Text = "Get OUs"
	$getOUsButton.add_click({populateTree $OUTree})

	$OULabel = New-Object Windows.Forms.Label
	$OULabel.Location = New-Object Drawing.Point 10, 70
	$OULabel.Size = New-Object Drawing.Point 190, 20
	$OULabel.Text = "Select an Organizational Unit:"
	
	$OUTree = New-Object Windows.Forms.TreeView
	$OUTree.Location = New-Object Drawing.Point 10, 90
	$OUTree.Size = New-Object Drawing.Point 300, 250
	$kill = populateTree $OUTree
	$yOffset = 350
	   
	$form.controls.add($domainLabel)
	$form.controls.add($domainCombo)
	$form.controls.add($getOUsButton)
	$form.controls.add($OULabel)
	$form.controls.add($OUTree)
    }
    if($getParams -eq $True)
    {
	$paramFields = @();
	foreach($param in $parameters)
	{
   	    $paramLabel = New-Object Windows.Forms.Label
	    $paramLabel.Location = New-Object Drawing.Point 10, $yOffset
	    $paramLabel.Size = New-Object Drawing.Point 150, 20
	    $paramLabel.Text = $param.Name

	    #Domain picking combo box
	    $paramTextBox = New-Object Windows.Forms.TextBox
	    $paramTextBox.Location = New-Object Drawing.Point 165, $yOffset
	    $paramTextBox.Size = New-Object Drawing.Point 150, 20
	    $paramTextBox.Text = $param.Value
	    $toolTip = New-Object Windows.Forms.ToolTip
	    $toolTip.SetToolTip($paramTextBox, $param.Prompt)
	    $toolTip.active = $True
	    $paramField = New-Object PSObject
	    $paramField | add-member NoteProperty Name $param.Name
	    $paramField | add-member NoteProperty Box $paramTextBox
	    $paramFields+=$paramField
	    $yOffset+= 25
	    $form.controls.add($paramLabel)
	    $form.controls.add($paramTextBox)
	}
    }

    $finishButton = New-Object Windows.Forms.Button
    $finishButton.Location = New-Object Drawing.Point 165,$yOffset
    $finishButton.Size = New-Object Drawing.Point 140,20
    $finishButton.Text = "Go"
    $kill = $finishButton.add_click({go})
    $form.controls.add($finishButton)	

    #Show the form

    $form.Size = New-Object Drawing.Point 320, ($yOffset+50)
    $kill = $form.ShowDialog()
    #Return PSObject with ADSPath and parameter array
    $return_val = New-Object PSObject
    if($getOU -eq $True)
    {
	$return_val | add-member NoteProperty ADSPath ($OUTree.SelectedNode.Text + $domainCombo.Text)
    }
    if($getParams -eq $True)
    {
	$return_params = @();
	foreach($field in $paramFields)
	{
	    $return_param = New-Object PSObject
	    $return_param | add-member NoteProperty Name $field.Name
	    $return_param | add-member NoteProperty Value $field.Box.Text
	    $return_params += $return_param
        }
	$return_val | add-member NoteProperty Parameters $return_params
    }
    
    return $return_val
}

function populateTree($treeView)
{
	#Clear Tree
	$kill = $treeView.nodes.clear()
	$kill = recurseOUs "" $treeView $domainCombo.text
}

function recurseOUs($value, $currentNode, $domain)
{

	$childNodes = Get-ChildOUs $value $domain
	
	if($childNodes -ne $Null)
	{
		foreach($child in $childNodes)
		{
			$ads = [String] $child.properties.adspath
			$ads = $ads.replace('LDAP://','')
			$ads = $ads.remove($ads.IndexOf("DC="))
			$childNode = New-Object Windows.Forms.TreeNode($ads)
			$kill = $currentNode.Nodes.add($childNode)
			$kill = recurseOUs $ads $childNode $domain
		}
	}
}

function Get-ChildOUs($searchpath, $domain)
{

	if( ($domain -eq $Null) -or ($domain -eq "") )
	{
	    $searchDomain = ([ADSI]"").distinguishedName
	}
	else
	{
		$searchDomain = $domain
	}

	if( $searchpath -eq $Null )
	{
		$searchpath = ""
	}
	$ADsPath = "LDAP://$searchpath" + $searchDomain	
	$root = [ADSI]$ADsPath
	$Searcher = new-object DirectoryServices.DirectorySearcher($root)
	$Searcher.SearchScope = "OneLevel"
	
	$Searcher.filter = "(objectClass=organizationalUnit)"
	$OUs = $Searcher.findall()

	return $OUs
}

function New-Thread
{
    $config   = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.RunspaceConfiguration
    $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($config)
    $thread   = New-Object System.Object
    
        $thread = $thread | Add-Member NoteProperty "Runspace" $runspace -passThru
        $thread = $thread | Add-Member NoteProperty "Pipeline" $null -passThru        
        $thread = $thread | Add-Member ScriptProperty "IsRunning" { return ($this.Pipeline -ne $null -and $this.Pipeline.PipelineStateInfo.State -eq "Running") } -passThru

    $runspace.Open()
    
    return $thread
}

function Start-Thread
{
    param
    (
        [ScriptBlock] $scriptBlock = $(throw "The parameter -scriptBlock is required."),
        [object]      $thread      = $null
    )
    
    if ($thread -eq $null)
    {
        $thread = New-Thread
    }
    
    if ($thread.IsRunning)
    {
        throw "The thread is already running."
    }
    
    if ($thread.Pipeline -ne $null)
    {
        $thread.Pipeline.Dispose()
    }
    
    $thread.Pipeline = $thread.Runspace.CreatePipeline($scriptBlock)
    $thread.Pipeline.Input.Close()
    $thread.Pipeline.InvokeAsync()
    
    return $thread
}

function Stop-Thread
{
    param
    (
        [object] $thread = $(throw "The parameter -thread is required.")
    )
    
    if ($thread.Pipeline -ne $null)
    {
        if ($thread.Pipeline.PipelineStateInfo.State -eq "Running")
	{
            $thread.Pipeline.StopAsync()
        }
    }
}

function Read-Thread
{
    param
    (
        [object] $thread = $(throw "The parameter -thread is required.")
    )
    
    if ($thread.Pipeline -ne $null)
    {
        $thread.Pipeline.Error.NonBlockingRead() |% { Write-Error $_ }
        $thread.Pipeline.Output.NonBlockingRead() |% { Write-Output $_ }
    }
}

function Join-Thread
{
    param
    (
        [object]   $thread  = $(throw "The parameter -thread is required."),
        [TimeSpan] $timeout = [TimeSpan]::MaxValue
    )
    
    if ($thread.Pipeline -ne $null)
    {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $timedOut  = $false
        
        while ($true)
	{
            Read-Thread -thread $thread
            
            if ($thread.Pipeline.Error.EndOfPipeline -and $thread.Pipeline.Output.EndOfPipeline)
            {
                break
            }
            
            $thread.Pipeline.Output.WaitHandle.WaitOne(250, $false) | Out-Null
            
            if ($stopwatch.Elapsed -gt $timeout)
            {
                $timedOut = $true
                break
            }
        }
        
        if (-not $timedOut)
	{
            Stop-Thread $thread
            
            if ($thread.Pipeline.PipelineStateInfo.State -eq "Failed")
            {
                throw $thread.Pipeline.PipelineStateInfo.Reason
            }
        }
    }
}

function Invoke-ThreadExpression
{
    param
    (
        [object]      $thread = $(throw "The parameter -thread is required."),
        [ScriptBlock] $scriptBlock = $(throw "The parameter -scriptBlock is required.")
    )
    
    if ($thread.Pipeline -ne $null -and $thread.Pipeline.PipelineStateInfo.State -eq "Running")
    {
        throw "The thread is already running."
    }
    
    $pipeline = $thread.Runspace.CreatePipeline($scriptBlock)
    $pipeline.Invoke()
    
    $pipeline.Output.ReadToEnd() |% { Write-Output $_ }
    $pipeline.Error.ReadToEnd() |% { Write-Error $_ }
    
    if ($pipeline.PipelineStateInfo.State -eq "Failed")
    {
        throw $pipeline.PipelineStateInfo.Reason
    }
    
    $pipeline.Dispose()
}

function Get-ThreadVariable
{
    param
    (
        [object] $thread = $(throw "The parameter -thread is required."),
        [string] $name   = $(throw "The parameter -name is required.")
    )
    
    if ($thread.IsRunning)
    {
        throw "The thread is already running."
    }
    
    $thread.Runspace.SessionStateProxy.GetVariable($name)
}

function Set-ThreadVariable
{
    param
    (
        [object] $thread = $(throw "The parameter -thread is required."),
        [string] $name   = $(throw "The parameter -name is required."),
        [object] $value
    )
    
    if ($thread.IsRunning)
    {
        throw "The thread is already running."
    }
    
    $thread.Runspace.SessionStateProxy.SetVariable($name, $value)
}

function Get-ADObjects($searchpath, $domain, $objectCategory)
{
	if($domain -eq $Null)
	{
	    $searchDomain = ([ADSI]"").distinguishedName
	}
	else
	{
	    $searchDomain = $domain
	}
	$ADsPath = "LDAP://$searchpath" + $searchDomain
	$root = [ADSI]$ADsPath
	$Searcher = new-object DirectoryServices.DirectorySearcher($root)
	$Searcher.filter = "(objectCategory=$objectCategory)"
	$Searcher.Sort = New-Object DirectoryServices.sortoption('Name', 'Ascending')
	$comps = $Searcher.findall()
	return $comps
}



#This is MAIN
#Check if a script was passed in, if not, then show script-chooser
if($ScriptPath -eq '')
{
    $Chooser = Show-ScriptChooser
    if( $Chooser.ScriptPath -eq '')
    {
	
	Write-Host 'You have not selected a script to run...exiting'
	Exit
    }
    else
    {
	$ScriptPath = $Chooser.ScriptPath
	$OU = $Chooser.OU
    }
}
#Get the parameters passed in, if they aren't then we'll set them
. $ScriptPath

$CleanedParameters = Parse-Parameters $ScriptParameters $Parameters

$params = Build-Parameters $OU $CleanedParameters $ADSPath

if($params.Parameters.length -gt 0)
{
    foreach($var in $params.Parameters)
    {
	New-Variable -name $var.Name -value $var.Value
    }
}

$ADSPath = $params.ADSPath
$OU = $params.OU

Write-Host "Results of Executing $ScriptPath `: $ScriptDescription"

if($OU -eq $True -and $ADSPath -ne '')
{
    #Grab objects from AD at the specified location and lower
    #If ADObjectType is not defined, then default to computer
    if($ScriptADSObjectType -eq $Null -or $ScriptADSObjectType -eq '')
    {
	$ADSObjectType = 'computer'
    }
    else
    {
	$ADSObjectType = $ScriptADSObjectType
    }
    $ADSObjects = Get-ADObjects '' $ADSPath $ADSObjectType
    
    #Since this is an OU run, the $ScriptBlock in the specified
    #script is the action that occurs inside the loop
    #We will call it for each object returned with the variable
    #$ADSObject.  If it has $ScriptThreaded = $True then
    #we spawn a thread for each $ADSObject.
    $threads = @();
    foreach( $ADSObject in $ADSObjects )
    {
	if( $ScriptThreaded -eq $True )
	{
	    $thread = New-Thread
	    Set-ThreadVariable $thread 'ADSObject' $ADSObject
	    Set-ThreadVariable $thread 'OU' $OU
	    Set-ThreadVariable $thread 'ADSPath' $ADSPath
	    if( $params.Parameters -ne $Null -and $params.Parameters -ne '')
	    {
		foreach($param in $params.Parameters)
		{
		    Set-ThreadVariable $thread $param.Name $param.Value
		}
	    }
	    $threads += $thread
	    Start-Thread -thread $thread -scriptBlock $ScriptBlock | Out-Null
        }
	else
	{
	    $ScriptBlock.Invoke()
	}
    }
    if( $ScriptThreaded -eq $True )
    {
	foreach( $thread in $threads ) { Join-Thread $thread }
    }
}
else
{
    #The simple case, just run the code
    $ScriptBlock.Invoke()
}
