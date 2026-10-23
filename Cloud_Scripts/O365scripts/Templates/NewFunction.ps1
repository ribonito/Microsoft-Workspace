<#
.SYNOPSIS
    Standard template for creating reusable, production-ready PowerShell Advanced Functions.

.DESCRIPTION
    Provides a standardized scaffold for PowerShell advanced functions with [CmdletBinding()],
    pipeline input support (by value and by property name), robust parameter validation,
    structured begin/process/end blocks, and complete comment-based help documentation.

.PARAMETER InputObject
    Specifies one or more input items to process. Accepts pipeline input by value or property name.

.PARAMETER Force
    Switch to bypass confirmation prompts for actions modifying state.

.EXAMPLE
    Invoke-SampleFunction -InputObject "User01", "User02"
    Executes the function passing explicit string inputs.

.EXAMPLE
    "User01", "User02" | Invoke-SampleFunction
    Processes inputs piped directly through the PowerShell pipeline.

.OUTPUTS
    [PSCustomObject]
    Outputs structured objects with Item, Timestamp, and Status properties.

.NOTES
    Author: Josep Canas - M365 Solutions Architect
    Template: Advanced Function Scaffold
    Version: 2.0

.LINK
    https://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-overview
    https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_advanced
#>
function Invoke-SampleFunction {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = "Specify the items to process."
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage = "Bypass confirmation prompts.")]
        [switch]$Force
    )

    begin {
        Write-Verbose "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Initializing Invoke-SampleFunction execution."
        $ProcessedItems = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        foreach ($item in $InputObject) {
            Write-Verbose "Processing item: $item"

            if ($PSCmdlet.ShouldProcess($item, "Process item")) {
                try {
                    $result = [PSCustomObject]@{
                        Item      = $item
                        Timestamp = (Get-Date)
                        Status    = "Success"
                    }
                    $ProcessedItems.Add($result)
                    
                    # Emit result object to pipeline
                    Write-Output $result
                }
                catch {
                    Write-Error "Failed to process item '$item': $_"
                }
            }
        }
    }

    end {
        Write-Verbose "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Completed Invoke-SampleFunction. Total processed: $($ProcessedItems.Count)"
    }
}
