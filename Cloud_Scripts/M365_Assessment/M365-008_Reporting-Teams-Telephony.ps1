<#
.SYNOPSIS
    M365-008 | M365 Assessment - Export Teams Telephony Numbers by Type.

.DESCRIPTION
    Connects to Microsoft Teams and exports phone number assignments by telephony type
    into three separate CSV files:
        - OperatorConnectNumbers.csv     → Operator Connect (OC) numbers
        - CallingPlanTelephoneNumbers.csv → Microsoft Calling Plan numbers
        - DirectRoutingNumbers.csv       → Direct Routing (DR) numbers

    A folder selection dialog is shown to choose the output directory.
    User is prompted to confirm before overwriting existing files.

    Columns exported: DisplayName, LineUri, OnlineDialOutPolicy, UsageLocation.

.PRODUCT
    Microsoft Teams Phone / Teams Telephony

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: MicrosoftTeams
    - Requires Teams Administrator or Global Reader role
    - Run on Windows PowerShell (WinForms GUI dialog used for folder selection)

.EXAMPLE
    .\M365-008_Reporting-Teams-Telephony.ps1
    (A folder browser dialog will appear to select the output directory)
#>

Try {
#region ── Parameters ─────────────────────────────────────────────────────────
    $includeFields = "DisplayName","LineUri","OnlineDialOutPolicy","UsageLocation"
    $OCFile = "OperatorConnectNumbers.csv"
    $CPFile = "CallingPlanTelephoneNumbers.csv"
    $DRFile = "DirectRoutingNumbers.csv"
#endregion

#region ── Helper Functions ───────────────────────────────────────────────────
    Function Select-FolderDialog
    {
        param([string]$Description="Select Folder",[string]$RootFolder="Desktop")
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null     

        $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
        $objForm.Rootfolder = $RootFolder
        $objForm.Description = $Description
        $Show = $objForm.ShowDialog()

        $loop = $true
        while($loop)
        {
            If ($Show -eq "OK")
            {
                $loop = $false
                Return $objForm.SelectedPath
            } Else {
                return
            }
        }
    }

    Function ConnectToTeams
    {
        if (Get-Module -ListAvailable -Name MicrosoftTeams){
		    try { $null = Get-CsTenant } catch { Connect-MicrosoftTeams }
		    Return 1
	    } else {
		    Return 0
	    }
    }
    Function Get-OC-Numbers($errorcount)
    {
        Get-CsOnlineUser | where-object {$_.LineUri -ne $nul } | where-object {$_.FeatureTypes -notcontains "CallingPlan"}  | where-object {$_.OnlineVoiceRoutingPolicy -eq $null} | Select DisplayName, LineUri, OnlineDialOutPolicy, UsageLocation | Export-Csv -path $folder\$OCFile -NoTypeInformation
        if($error.count -ne $errorcount){ Return 0} else {return 1}
    }

    Function Get-CP-Numbers($errorcount)
    {
        Get-CsOnlineUser | where-object {$_.LineUri -ne $nul } | where-object {$_.FeatureTypes -contains "CallingPlan"}  | Select $includeFields | Export-Csv -path $folder\$CPFile -NoTypeInformation
        if($error.count -ne $errorcount){ Return 0} else {return 1}
    }

    Function Get-DR-Numbers($errorcount)
    {
        Get-CsOnlineUser | where-object {$_.LineUri -ne $nul } | where-object {$_.FeatureTypes -notcontains "CallingPlan"}  | where-object {$_.OnlineVoiceRoutingPolicy -ne $null} | Select DisplayName, LineUri, OnlineDialOutPolicy, UsageLocation | Export-Csv -path $folder\$DRFile -NoTypeInformation
        if($error.count -ne $errorcount){ Return 0} else {return 1}
    }

    Function CreateFiles
    {
	if ((gi -ErrorAction Ignore $folder\$OCFile).IsReadOnly) {Return 2}
	if ((gi -ErrorAction Ignore $folder\$CPFile).IsReadOnly) {Return 2}
	if ((gi -ErrorAction Ignore $folder\$DRFile).IsReadOnly) {Return 2}

	Add-Type -AssemblyName PresentationFramework
        $msgBoxInput =  [System.Windows.MessageBox]::Show('Would you like to proceed, existing Telephone Files in '+$folder+' will be deleted?', 'Confirmation', 'YesNoCancel','Error')

        switch  ($msgBoxInput) {
            'Yes' {
		$state = Get-OC-Numbers($error.count)
		$state = Get-CP-Numbers($error.count)
		$state = Get-DR-Numbers($error.count)
		Return 1
            }
            'No' {
    	        Exit
            }
            'Cancel' {
    	        Exit
            }

        }
    }
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
    echo "Connecting to Teams. If you are not already connected you will receive a pop up or web browser prompt."
    cmd /c pause 
    $connected = ConnectToTeams
    if ($connected -eq 0)
    {
	echo "Microsoft Connection failed, eiter the module was not installed or the connection failed"
	Exit
    }

    if ($folder = Select-FolderDialog) {
	$CreationStatus = CreateFiles
	if($CreationStatus -eq 1) {echo "Files created" }
	if($CreationStatus -eq 2) {echo "Read Only File found, terminating."}
    }
#endregion
}

catch
{
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
Echo "Failed to create the files: $ErrorMessage"
}