function Invoke-SRIntuneBackupAdminRoleAssignment {
    <#
    .SYNOPSIS
    Backup Intune Admin role Assignments
    
    .DESCRIPTION
    Backup Intune Admin role Assignments
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupAdminRoleAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Admin Roles\Assignments")) {
        $null = New-Item -Path "$Path\Admin Roles\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $Uri = "$ApiVersion/deviceManagement/roledefinitions"
    $AdminRoles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
   
    foreach ($AdminRole in $AdminRoles) {
        $Uri = "$ApiVersion/deviceManagement/roledefinitions/$($AdminRole.id)/roleAssignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri
        if ($assignments.value) {
            foreach ($assignment in $assignments) {
                $Uri = "$ApiVersion/deviceManagement/roledefinitions/$($AdminRole.id)/roleAssignments/$($assignment.value.id)"
                $assignmentDetails = Invoke-MgGraphRequest -Uri $Uri
                $fileName = ($assignmentDetails.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
                $assignmentDetails | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Admin Roles\Assignments\$($AdminRole.id)__$($fileName).json"

                [PSCustomObject]@{
                    "Action" = "Backup"
                    "Type"   = "Admin Roles Assignments"
                    "Name"   = $assignmentDetails.displayName
                    "Path"   = "Admin Roles\Assignments\$($AdminRole.id)__$fileName.json"
                }
            }
        }
    }
}

#Invoke-SRIntuneBackupAdminRoleAssignment -Path "C:\temp\IntuneBackup\FunctionTest"