<#
.SYNOPSIS
    UTL-020 | Generate a Random Alphanumeric String.

.DESCRIPTION
    PowerShell helper function that dynamically constructs a random alphanumeric string (A-Z, a-z, 0-9) 
    of a specified length.

.PRODUCT
    Microsoft 365 / Common Functions

.ORIGINAL_AUTHOR
    Marcus Gelderman (Get-RandomAlphaNumString classification)
    Reference: https://gist.github.com/marcgeld/4891bbb6e72d7fdb577920a6420c1dfb

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-020 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-020_Get-RandomAlphaNumString.ps1

.PARAMETER Length
    The length of the generated random string (default: 16).
#>

#region ── Main Program ───────────────────────────────────────────────────────
function Get-RandomAlphaNumString {
    [CmdletBinding()]
    param (
        [int]$Length = 16
    )
    begin {}
    process {
        $Out = (-join ((0x30..0x39) + (0x41..0x5A) + (0x61..0x7A) | Get-Random -Count $Length | ForEach-Object { [char]$_ }))
        return $Out
    }
}
#endregion
