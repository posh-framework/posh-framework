
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
   [boolean] $CSV = $False,
   $Parameters = $Null,
   [string] $ADSPath = $Null,
   [string] $CSVPath = $Null
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
        $CSV = $False,
        $Parameters = $Null,
        $ADSPath = '',
        $CSVPath = ''
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

    $getCSVPath = $False
    if($CSV -eq $True -and $CSVPath -ne '')
    {
	$CleanCSVPath = $CSVPath
    }
    if($CSV -eq $True -and $CSVPath -eq '')
    {
	$getCSVPath = $True
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
    $return_object | add-member noteproperty CSV $CSV
    $return_object | add-member noteproperty ADSPath $CleanADSPath
    $return_object | add-member noteproperty CSVPath $CleanCSVPath

    #Create and display the GUI for picking OU, and Parameters
    if( $getParams -eq $True -or $getADSPath -eq $True -or $getCSVPath -eq $True)
    {
	$new_param_object = Show-ParamGUI $getADSPath $getCSVPath $getParams $Parameters
        if( $getParams -eq $True )
	{
	    $return_object.Parameters = $new_param_object.Parameters
	}
	if( $getADSPath -eq $True )
	{
	    $return_object.ADSPath = $new_param_object.ADSPath
	}
	if ( $getCSVPath -eq $True )
	{
	    $return_object.CSVPath = $new_param_object.CSVPath
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
	if( (Test-Path -path $FileText.Text) -ne $True)
	{
	    return $Null
	}
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
    $fileText.add_TextChanged({Populate-Scripts})
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
    $ouLabel.Size = New-Object Drawing.Point 130, 20
    $ouLabel.Text = "Run script against OU?"
    $form.controls.add($ouLabel)

    $ouCheckBox = New-Object Windows.Forms.CheckBox
    $ouCheckBox.Location = New-Object Drawing.Point 140,$yOffset
    $ouCheckBox.Size = New-Object Drawing.Point 40, 20    
    $ouCheckBox.checked = $OU
    $ouCheckBox.add_click({$csvCheckBox.checked = $False})
    $form.controls.add($ouCheckBox)

    #CSV Flag
    $csvLabel = New-Object Windows.Forms.Label
    $csvLabel.Location = New-Object Drawing.Point 180,$yOffset
    $csvLabel.Size = New-Object Drawing.Point 130, 20
    $csvLabel.Text = "Run script against CSV?"
    $form.controls.add($csvLabel)

    $csvCheckBox = New-Object Windows.Forms.CheckBox
    $csvCheckBox.Location = New-Object Drawing.Point 320,$yOffset
    $csvCheckBox.Size = New-Object Drawing.Point 40, 20    
    $csvCheckBox.checked = $CSV
    $csvCheckBox.add_click({$ouCheckBox.checked = $False})
    $form.controls.add($csvCheckBox)

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
    $form.add_shown({$form.Activate()})
    $kill = $form.ShowDialog()
    if( $ScriptList.SelectedItems[0].Text -eq $Null )
    {
	$return_object = New-Object PSObject
	$return_object | Add-Member NoteProperty ScriptPath ''
	return $return_object
    }
    $ScriptPath = $FileText.Text + '\' + $ScriptList.SelectedItems[0].Text
    #Return ScriptPath and OU
    $return_object = New-Object PSObject
    $return_object | Add-Member NoteProperty OU $OUCheckBox.Checked
    $return_object | Add-Member NoteProperty CSV $CSVCheckBox.Checked
    $return_object | Add-Member NoteProperty ScriptPath $ScriptPath
    return $return_object
}

function Show-ParamGUI($getOU, $getCSV, $getParams, $parameters)
{

    function go
    {
	$kill = $form.close()
    }
    
    $kill = [reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
    $form = New-Object Windows.Forms.Form
    $form.text = "$ScriptDescription - Select Parameters"
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
	$domainCombo.Size = New-Object Drawing.Point 235, 20
	$domainCombo.TabIndex = 1
	$currentDN = [ADSI]""
	if($currentDN.distinguishedName -ne $Null)
	{
	    $currentDN = $currentDN.distinguishedName[0]
	    $kill = $domainCombo.Items.Add($currentDN)
	    $domainCombo.SelectedIndex = 0
	}
	
	$getOUsButton = New-Object Windows.Forms.Button
	$getOUsButton.Location = New-Object Drawing.Point 249, 37
	$getOUsButton.Size = New-Object Drawing.Point 150, 20
	$getOUsButton.Text = "Get OUs"
	$getOUsButton.add_click({populateTree $OUTree})

	$OULabel = New-Object Windows.Forms.Label
	$OULabel.Location = New-Object Drawing.Point 10, 70
	$OULabel.Size = New-Object Drawing.Point 190, 20
	$OULabel.Text = "Select an Organizational Unit:"
	
	$OUTree = New-Object Windows.Forms.TreeView
	$OUTree.Location = New-Object Drawing.Point 10, 90
	$OUTree.Size = New-Object Drawing.Point 390, 250
	$yOffset = 350
	   
	$form.controls.add($domainLabel)
	$form.controls.add($domainCombo)
	$form.controls.add($getOUsButton)
	$form.controls.add($OULabel)
	$form.controls.add($OUTree)
    }

    if($getCSV -eq $True)
    {
	$csvLabel = New-Object Windows.Forms.Label
	$csvLabel.Location = New-Object Drawing.Point 10,20
	$csvLabel.Size = New-Object Drawing.Point 150, 20
	$csvLabel.Text = "CSV Path:"

	$csvText = New-Object Windows.Forms.TextBox
	$csvText.Location = New-Object Drawing.Point 165, 20
	$csvText.Size = New-Object Drawing.Point 150, 20
	
	$fileButton = New-Object Windows.Forms.Button
	$fileButton.Location = New-Object Drawing.Point 315,20
	$fileButton.Size = New-Object Drawing.Point 85, 20
	$fileButton.Text = 'Browse...'
	$yOffset = 45
	$fileButton.add_click(
	{
	    $fileDlg = New-Object Windows.Forms.OpenFileDialog
	    #ShowHelp flag required for proper showing in PoSH
	    $fileDlg.ShowHelp = $True
	    $fileDlg.CheckFileExists = $True
	    $fileDlg.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
	    $fileDlg.ShowDialog()
	    $csvText.Text = $fileDlg.FileName
	})
	$form.controls.add($csvLabel)
	$form.controls.add($csvText)
	$form.controls.add($fileButton)
	
    }
    if($getParams -eq $True)
    {
	$paramFields = @();
	foreach($param in $parameters)
	{
   	    $paramLabel = New-Object Windows.Forms.Label
	    $paramLabel.Location = New-Object Drawing.Point 10, $yOffset
	    $paramLabel.Size = New-Object Drawing.Point 150, 20
	    if( $param.Display -eq '' -or $param.Display -eq $Null)
	    {
		$paramLabel.Text = $param.Name
	    }
	    else
	    {
		$paramLabel.Text = $param.Display
	    }
	    
	    #Look for parameter type field
	    #If set, show an appropriate input type
	    if( $param.Type -eq $Null -or $param.Type -eq '')
	    {
		$paramType = 'String'
	    }
	    else
	    {
		$paramType = $param.Type
	    }
	    $paramIsFSChooser = $False
	    switch -regex ($paramType.toLower())
	    {
		"bool.*"
		{
		    $paramInput = New-Object Windows.Forms.CheckBox
		    $paramInput.Location = New-Object Drawing.Point 165, $yOffset
		    $ParamInput.Size = New-Object Drawing.Point 40, 20 
		    if($param.Value -ne $Null -and $param.Value -ne '')
		    {   
			$paramInput.checked = [System.Convert]::ToBoolean($param.Value)
		    }
		    break
		}
		"number"
		{
		    $paramInput = New-Object Windows.Forms.NumericUpDown
		    $paramInput.Location = New-Object Drawing.Point 165, $yOffset
		    $paramInput.Size = New-Object Drawing.Point 80, 20
		    if($param.Value -ne $Null -and $param.Value -ne '')
		    {
			$paramInput.Value = [System.Convert]::ToDouble($param.Value)
		    }
		    break
		}
		"file.*"
		{
		    $paramInput = New-Object Windows.Forms.TextBox
		    $paramInput.Location = New-Object Drawing.Point 165, $yOffset
		    $paramInput.Size = New-Object Drawing.Point 150, 20
		    $paramInput.Text = $param.Value

		    $fileButton = New-Object Windows.Forms.Button
		    $fileButton.Location = New-Object Drawing.Point 315,$yOffset
		    $fileButton.Size = New-Object Drawing.Point 85, 20
		    $fileButton.Text = 'Browse...'
		    $fileButton | Add-Member NoteProperty Box $paramInput
		    $fileButton.add_click(
		    {
			$fileDlg = New-Object Windows.Forms.OpenFileDialog
			#ShowHelp flag required for proper showing in PoSH
			$fileDlg.ShowHelp = $True
			$fileDlg.CheckFileExists = $True
			$fileDlg.Filter = "All files (*.*)|*.*"
			$fileDlg.ShowDialog()
			#Dirty, Dirty hack, but only way I could think
			#of finding the right text box to fill in
			#was using the tabindex of the button pushed
			#and finding the right textbox based on it's
			#tabindex offset from the browse button
			$fileText = ($form.controls | Where-Object {$_.TabIndex -eq ($this.TabIndex-1)})
			$fileText.Text = $fileDlg.FileName
		    })
		    #$form.controls.add($fileButton)
		    $paramIsFSChooser = $True
		    break
		}
		"(folder)|(dir.*)"
		{
		    $paramInput = New-Object Windows.Forms.TextBox
		    $paramInput.Location = New-Object Drawing.Point 165, $yOffset
		    $paramInput.Size = New-Object Drawing.Point 150, 20
		    $paramInput.Text = $param.Value

		    $fileButton = New-Object Windows.Forms.Button
		    $fileButton.Location = New-Object Drawing.Point 315,$yOffset
		    $fileButton.Size = New-Object Drawing.Point 85, 20
		    $fileButton.Text = 'Browse...'
		    $fileButton | Add-Member NoteProperty Box $paramInput
		    $fileButton.add_click(
		    {
			$app = New-Object -com Shell.Application
			$path = (Get-Location).path
			$folder = $app.BrowseForFolder(0, "Select a folder to look for framework scripts in.", 0,'Desktop') 
			if($folder.Self.Path -ne '')
			{
			    $fileText = ($form.controls | Where-Object {$_.TabIndex -eq ($this.TabIndex-1)})
			    $fileText.Text = $folder.Self.Path
			}
		    })
		    #$form.controls.add($fileButton)
		    $paramIsFSChooser = $True
		    break
		    
		}
		"(list)|(choice)"
		{
		    $paramInput = New-Object Windows.Forms.ComboBox
		    $paramInput.Location = New-Object Drawing.Point 165, $yOffset
		    $paramInput.Size = New-Object Drawing.Point 150, 20
		    if($param.Value -ne $Null -and $param.Value -ne '')
		    {
			$items = ($param.Value).split('|')
			foreach($item in $items)
			{
			    $kill = $paramInput.items.add($item)
			}
			$paramInput.SelectedIndex = 0
		    }
		    break
		}
		default
		{
		    $paramInput = New-Object Windows.Forms.TextBox
		    $paramInput.Location = New-Object Drawing.Point 165, $yOffset
		    $paramInput.Size = New-Object Drawing.Point 235, 20
		    $paramInput.Text = $param.Value
		}
	    }

	    $toolTip = New-Object Windows.Forms.ToolTip
	    $toolTip.SetToolTip($paramInput, $param.Prompt)
	    $toolTip.active = $True
	    $paramField = New-Object PSObject
	    $paramField | add-member NoteProperty Name $param.Name
	    $paramField | add-member NoteProperty Box $paramInput
	    $paramFields+=$paramField
	    $yOffset+= 25
	    $form.controls.add($paramLabel)
	    $form.controls.add($paramInput)
	    if($paramIsFSChooser -eq $True)
	    {
		$form.controls.add($fileButton)
	    }
	}
    }

    $finishButton = New-Object Windows.Forms.Button
    $finishButton.Location = New-Object Drawing.Point 265,$yOffset
    $finishButton.Size = New-Object Drawing.Point 140,20
    $finishButton.Text = "Go"
    $kill = $finishButton.add_click({go})
    $form.controls.add($finishButton)	

    #Show the form

    $form.Size = New-Object Drawing.Point 410, ($yOffset+50)
    $form.add_Shown({ $form.activate(); if($getOU -eq $True) {$kill = populateTree $OUTree }})
    $kill = $form.ShowDialog()
    #Return PSObject with ADSPath and parameter array
    $return_val = New-Object PSObject
    if($getOU -eq $True)
    {
	$return_val | add-member NoteProperty ADSPath ($OUTree.SelectedNode.Text + $domainCombo.Text)
    }
    if($getCSV -eq $True)
    {
	$return_val | add-member NoteProperty CSVPath $CSVText.Text
    }
    if($getParams -eq $True)
    {
	$return_params = @();
	foreach($field in $paramFields)
	{
	    $return_param = New-Object PSObject
	    $return_param | add-member NoteProperty Name $field.Name

	    $type = $field.Box.getType()
	    $type = $type.Name

	    switch ($type)
	    {
		"CheckBox"
		{
		    $return_param | add-member NoteProperty Value $field.Box.Checked
		}
		"NumericUpDown"
		{
		    $return_param | add-member NoteProperty Value $field.Box.Value
		}
		default
		{
		    $return_param | add-member NoteProperty Value $field.Box.Text
		}
		    
	    }

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
	if( $root.distinguishedName -eq $null )
	{
	    return $Null
	}
	$Searcher = new-object DirectoryServices.DirectorySearcher($root)
	$Searcher.Sort = New-Object DirectoryServices.sortoption('Name', 'Ascending')
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
if( $OU -eq $True -and $CSV -eq $True )
{
    Write-Host "You cannot specify both -OU and -CSV as true"
    exit
}


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
	$CSV = $Chooser.CSV
    }
}
if( $OU -eq $True -and $CSV -eq $True )
{
    Write-Host "You cannot specify both -OU and -CSV as true"
    exit
}

#Get the parameters passed in, if they aren't then we'll set them
. $ScriptPath

$ScriptAbsPath = (Get-Item $ScriptPath).fullName
$CleanedParameters = Parse-Parameters $ScriptParameters $Parameters
$params = Build-Parameters $OU $CSV $CleanedParameters $ADSPath $CSVPath

if($params.Parameters.length -gt 0)
{
    foreach($var in $params.Parameters)
    {
	New-Variable -name $var.Name -value $var.Value
    }
}
$ADSPath = $params.ADSPath
$OU = $params.OU
$CSV = $params.CSV
$CSVPath = $params.CSVPath

Write-Host "Results of Executing $ScriptPath `: $ScriptDescription"

if( ($OU -eq $True -and $ADSPath -ne '') -or ($CSV -eq $True -and $CSVPath -ne '') )
{
    if( $OU -eq $True )
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
	$Objects = Get-ADObjects '' $ADSPath $ADSObjectType
    }
    elseif( $CSV -eq $True )
    {
	$Objects = Import-CSV $CSVPath
    }
    
    # Since this is an OU/CSV run, the $ScriptBlock in the specified
    # script is the action that occurs inside the loop
    # We will call it for each object returned with the variable
    # $ADSObject or $CSVObject (depending on the type).  If it has
    # $ScriptThreaded = $True then we spawn a thread for each $ADSObject.
    $ObjectCount = 0
    $threads = @();
    foreach( $Object in $Objects )
    {
	if( $ScriptThreaded -eq $True )
	{
	    if( ($ObjectCount % 64) -eq 0 )
	    {
		#Limit number of threads to 32 to prevent out
		#of memory problems
		foreach( $thread in $threads ) { Join-Thread $thread }
		$threads = @();
	    }

	    $thread = New-Thread
	    if($OU -eq $True)
	    {
		Set-ThreadVariable $thread 'ADSObject' $Object
	    }
	    elseif($CSV -eq $True)
	    {
		Set-ThreadVariable $thread 'CSVObject' $Object
	    }
	    Set-ThreadVariable $thread 'OU' $OU
	    Set-ThreadVariable $thread 'ADSPath' $ADSPath
	    Set-ThreadVariable $thread 'CSV' $CSV
	    Set-ThreadVariable $thread 'CSVPath' $CSVPath
	    Set-ThreadVariable $thread 'ScriptPath' $ScriptPath
	    Set-ThreadVariable $thread 'ScriptAbsPath' $ScriptAbsPath
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
	    if($OU -eq $True)
	    {
		$ADSObject = $Object
	    }
	    elseif($CSV -eq $True)
	    {
		$CSVObject = $Object
	    }
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
