<#
.SYNOPSIS
    M365-004 | M365 Assessment - SharePoint Online Site List Inventory (CSOM).

.DESCRIPTION
    Uses SharePoint Client-Side Object Model (CSOM) assemblies to enumerate
    all lists and libraries within a specific SharePoint Online site.

    Output columns per list:
        - Title
        - ItemCount
        - BaseTemplate (numeric SP template code)
        - Created
        - LastItemModifiedDate

    Exports to CSV for inventory and governance purposes.

    NOTE: This script uses the legacy CSOM/SharePoint Client DLL approach.
    For modern environments, prefer PnP.PowerShell (Get-PnPList).

.PRODUCT
    SharePoint Online

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\M365-004_SPO-List-Inventory-CSOM.ps1
    (You will be prompted for credentials)

.NOTES
    - Requires SharePoint Client DLLs installed locally (SharePoint Online Management Shell)
    - Source reference: https://www.sharepointdiary.com/2018/03/sharepoint-online-get-all-lists-using-powershell.html
    - Alternatively, use: Connect-PnPOnline + Get-PnPList
#>

#region ── Load CSOM Assemblies ───────────────────────────────────────────────
# Reference: https://www.sharepointdiary.com/2018/03/sharepoint-online-get-all-lists-using-powershell.html
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
#endregion

#region ── Helper Function: Get-SPOList ──────────────────────────────────────
function Get-SPOList {
    <#
    .SYNOPSIS
        Returns all lists (or a specific list by name) from a SharePoint Online web.
    .PARAMETER Web
        The SharePoint Client Web object.
    .PARAMETER ListName
        Optional. If provided, returns only the list with this title.
    #>
    Param (
        [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.Web] $Web,
        [Parameter(Mandatory = $false)][string] $ListName
    )

    $Ctx = $Web.Context

    if ($ListName) {
        # Retrieve a specific list by title
        $List = $Web.Lists.GetByTitle($ListName)
        $Ctx.Load($List)
        $Ctx.ExecuteQuery()
        return $List
    } else {
        # Retrieve all lists in the web
        $Lists = $Web.Lists
        $Ctx.Load($Lists)
        $Ctx.ExecuteQuery()
        return $Lists
    }
}
#endregion

#region ── Connection ─────────────────────────────────────────────────────────
# Update with the target site URL
$SiteURL = "https://<your-tenant>.sharepoint.com/sites/<site-name>"

$Cred        = Get-Credential
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)

$Ctx              = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Ctx.Credentials  = $Credentials
#endregion

#region ── Enumerate Lists ────────────────────────────────────────────────────
$Lists          = Get-SPOList -Web $Ctx.Web
$ListCollection = @()

foreach ($List in $Lists) {
    $ListCollection += [PSCustomObject]@{
        Title                = $List.Title
        ItemCount            = $List.ItemCount
        BaseTemplate         = $List.BaseTemplate
        Created              = $List.Created
        LastItemModifiedDate = $List.LastItemModifiedDate
    }
}
#endregion

#region ── Export ─────────────────────────────────────────────────────────────
$OutputPath = "C:\Temp\SPO-ListInventory_$(Get-Date -Format 'yyyyMMdd').csv"
$ListCollection | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "List inventory exported: $($ListCollection.Count) lists → $OutputPath" -ForegroundColor Green
#endregion
