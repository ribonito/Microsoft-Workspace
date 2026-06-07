#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
 
#Function to Get all/specific list from site
Function Get-SPOList()
{
    Param
    (
        [Parameter(Mandatory=$true)] [Microsoft.SharePoint.Client.Web] $Web,
        [Parameter(Mandatory=$false)] [string] $ListName
    )
    #Get the Context
    $Ctx = $Web.Context
     
    #Get a single list or All Lists
    If($ListName)
    {
        #sharepoint online get list powershell
        $List = $Web.Lists.GetByTitle($ListName)
        $Ctx.Load($List)
        $Ctx.ExecuteQuery()
        Return $List
    }
    Else
    {
        #sharepoint online get all lists powershell
        $Lists = $Web.Lists
        $Ctx.Load($Lists)
        $Ctx.ExecuteQuery()
        Return $Lists
    }
}
 
#Parameters
$SiteURL="https://Crescent.sharepoint.com"
 
#Setup Credentials to connect
$Cred= Get-Credential
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
 
#Setup the context
$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Ctx.Credentials = $Credentials
 
#sharepoint online powershell get all lists
$Lists = Get-SPOList -Web $Ctx.Web
 
#Extract List data
$ListCollection = @()
ForEach($List in $Lists)
{
    $ListData = New-Object -TypeName PSObject
    $ListData | Add-Member -MemberType NoteProperty -Name "Title" -Value $List.Title
    $ListData | Add-Member -MemberType NoteProperty -Name "Itemcount" -Value $List.Itemcount
    $ListData | Add-Member -MemberType NoteProperty -Name "BaseTemplate" -Value $List.BaseTemplate
    $ListData | Add-Member -MemberType NoteProperty -Name "Created" -Value $List.Created
    $ListData | Add-Member -MemberType NoteProperty -Name "LastItemModifiedDate" -Value $List.LastItemModifiedDate
    $ListCollection += $ListData
}
#Export List Inventory to CSV
$ListCollection | Export-csv -Path "C:\Temp\list-inventory.csv" -NoTypeInformation


#Read more: https://www.sharepointdiary.com/2018/03/sharepoint-online-get-all-lists-using-powershell.html#ixzz8nOeFE7EB