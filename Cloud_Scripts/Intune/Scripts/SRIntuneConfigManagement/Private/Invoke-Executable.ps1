<#
.SYNOPSIS
    Invokes an external binary executable with structured process management and error handling.

.DESCRIPTION
    Launches an external executable process using System.Diagnostics.ProcessStartInfo.
    Supports argument passing, stream redirection (stdout/stderr), window creation flags,
    and returns a structured PSCustomObject containing the process exit code.

.PARAMETER FilePath
    The absolute path or executable name to invoke.

.PARAMETER Arguments
    Command-line arguments to pass to the process.

.PARAMETER RedirectStandardOutput
    Whether to redirect standard output. Defaults to true.

.PARAMETER RedirectStandardError
    Whether to redirect standard error. Defaults to true.

.PARAMETER CreateNoWindow
    Whether to launch the process hidden without creating a visible window. Defaults to true.

.PARAMETER UseShellExecute
    Whether to use operating system shell execute. Defaults to false.

.OUTPUTS
    [PSCustomObject]
    Object containing the process ExitCode.

.NOTES
    Module: SRIntuneConfigManagement
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    Invoke-Executable -FilePath "cmd.exe" -Arguments "/c echo Hello"
    Runs cmd.exe silently and returns exit code 0.
#>
function Invoke-Executable {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Specify the file name or path of the executable to be invoked, including the extension.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false, HelpMessage = "Specify arguments that will be passed to the executable.")]
        [ValidateNotNull()]
        [string]$Arguments,

        [Parameter(Mandatory = $false, HelpMessage = "Specify whether standard output should be redirected.")]
        [ValidateNotNull()]
        [bool]$RedirectStandardOutput = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Specify whether standard error output should be redirected.")]
        [ValidateNotNull()]
        [bool]$RedirectStandardError = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Specify whether to create a new window for the executable.")]
        [ValidateNotNull()]
        [bool]$CreateNoWindow = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Specify whether to create a new window for the executable.")]
        [ValidateNotNull()]
        [bool]$UseShellExecute = $false
    )

    try {
        # Create the Process Info object which contains details about the process
        $ProcessStartInfoObject = New-Object -TypeName "System.Diagnostics.ProcessStartInfo"
        $ProcessStartInfoObject.FileName = $FilePath
        $ProcessStartInfoObject.CreateNoWindow = $CreateNoWindow
        $ProcessStartInfoObject.UseShellExecute = $UseShellExecute
        $ProcessStartInfoObject.RedirectStandardOutput = $RedirectStandardOutput
        $ProcessStartInfoObject.RedirectStandardError = $RedirectStandardError 
        
        # Add the arguments to the process info object
        if (-not [string]::IsNullOrWhiteSpace($Arguments)) {
            $ProcessStartInfoObject.Arguments = $Arguments
        }

        # Create the object that will represent the process
        $Process = New-Object -TypeName "System.Diagnostics.Process"
        $Process.StartInfo = $ProcessStartInfoObject

        # Start process
        [void]$Process.Start()
        
        # Wait for the process to exit
        $Process.WaitForExit()

        # Return an object that contains the exit code
        return [PSCustomObject]@{
            ExitCode = $Process.ExitCode
        }
    }
    catch [System.Exception] {
        throw "$($MyInvocation.MyCommand): Error message: $($_.Exception.Message)"
    }
}