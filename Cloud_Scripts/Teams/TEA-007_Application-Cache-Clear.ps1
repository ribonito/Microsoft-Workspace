<#
.SYNOPSIS
    TEA-007 | Application Cache Clear.

.DESCRIPTION
    Clear Microsoft Teams application cache on endpoints.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-007 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Application%20Cache%20Clear.ps1

.NOTES
    Name: TEA-007_Application-Cache-Clear.ps1
    Integrated from O365scripts upstream repository.
#>

<# a) Close Teams and flush the entire cache folder. #>
Stop-Process -Name "Teams" -Force -Confirm:$false -ErrorAction SilentlyContinue;
#Stop-Process -Name "Outlook" -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\*" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue;

<# b) Close Teams and clear specific cache folders (eg: save the custom backgrounds). #>
$ErrAction = "SilentlyContinue";
Stop-Process -Name "Teams" -Force -Confirm:$false -ErrorAction $ErrAction;
#Stop-Process -Name "Outlook" -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\application cache\cache\*" -Force -Confirm:$false -ErrorAction $ErrAction;
#emove-Item -Path "$env:APPDATA\Microsoft\Teams\backgrounds\*" -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\blob_storage\*" -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\Cache\*" -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\databases\*" -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\GPUcache\*" -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\IndexedDB\*" -Recurse -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\Local Storage\*" -Recurse -Force -Confirm:$false -ErrorAction $ErrAction;
Remove-Item -Path "$env:APPDATA\Microsoft\Teams\tmp\*" -Force -Confirm:$false -ErrorAction $ErrAction;
