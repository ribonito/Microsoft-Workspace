[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Folder
)

if (-not (Test-Path "$Folder\Merged")) {
    $null = New-Item -Path "$Folder\Merged" -ItemType Directory
}

$OutFile = "$Folder\Merged\ApImport.csv"
Get-ChildItem -Path $Folder -Filter *.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $OutFile -NoTypeInformation -Append