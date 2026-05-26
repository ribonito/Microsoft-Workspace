function Add-IntuneWin32App {
    <#
    .SYNOPSIS
        Create a new Win32 application in Microsoft Intune.

    .DESCRIPTION
        Create a new Win32 application in Microsoft Intune.

    .PARAMETER FilePath
        Specify a local path to where the win32 app .intunewin file is located.

    .PARAMETER Win32AppBody
        Specify a body object required to create a Win32 app.
    
    .PARAMETER UseAzCopy
        Specify the UseAzCopy parameter switch when adding an application with source files larger than 500MB.

    .PARAMETER AzCopyWindowStyle
        Specify whether the AzCopy content transfer progress should use -WindowStyle Hidden or -NoNewWindow parameters for Start-Process. NoNewWindow will show transfer output, Hidden will not show progress but will support multi-threaded jobs.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            # Check if file name contains any invalid characters
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                throw "File name '$(Split-Path -Path $_ -Leaf)' contains invalid characters"
            }
            else {
                # Check if full path exist
                if (Test-Path -Path $_) {
                    # Check if file extension is intunewin
                    if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".intunewin") {
                        return $true
                    }
                    else {
                        throw "Given file name '$(Split-Path -Path $_ -Leaf)' contains an unsupported file extension. Supported extension is '.intunewin'"
                    }
                }
                else {
                    throw "File or folder does not exist"
                }
            }
        })]
        [string]$FilePath,

        [parameter(Mandatory = $true)]
        $Win32AppBody,

        [parameter(Mandatory = $false)]
        [switch]$UseAzCopy,

        [parameter(Mandatory = $false)]
        [ValidateSet("Hidden", "NoNewWindow")]
        [string]$AzCopyWindowStyle = "NoNewWindow"
    )
    Begin {
        # Ensure required authentication header variable exists
        if ($Global:AuthenticationHeader -eq $null) {
            Write-Warning -Message "Authentication token was not found, use Connect-MSIntuneGraph before using this function"; break
        }
        else {
            if ((Test-AccessToken) -eq $false) {
                Write-Warning -Message "Existing token found but has expired, use Connect-MSIntuneGraph to request a new authentication token"; break
            }
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"
    }
    Process {
#        try {
            # Attempt to gather all possible meta data from specified .intunewin file
            Write-Verbose -Message "Attempting to gather additional meta data from .intunewin file: $($FilePath)"
            $IntuneWinXMLMetaData = Get-IntuneWin32AppMetaData -FilePath $FilePath -ErrorAction Stop

            if ($IntuneWinXMLMetaData -ne $null) {
                Write-Verbose -Message "Successfully gathered additional meta data from .intunewin file"

                $CategoryList = New-Object -TypeName "System.Collections.ArrayList"
                foreach ($CategoryNameItem in $CategoryName) {
                    # Ensure category exist by given name from parameter input
                    Write-Verbose -Message "Querying for specified Category: $($CategoryNameItem)"
                    $Category = (Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileAppCategories?`$filter=displayName eq '$([System.Web.HttpUtility]::UrlEncode($CategoryNameItem))'" -Method "GET" -ErrorAction "Stop").value
                    if ($Category -ne $null) {
                        $PSObject = [PSCustomObject]@{
                            id = $Category.id
                            displayName = $Category.displayName
                        }
                        $CategoryList.Add($PSObject) | Out-Null
                    }
                    else {
                        Write-Warning -Message "Could not find category with name '$($CategoryNameItem)' or provided name resulted in multiple matches which is not supported"
                    }
                }
                
                # Create the Win32 app
                Write-Verbose -Message "Attempting to create Win32 app using constructed body converted to JSON content"
                $Win32MobileAppRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps" -Method "POST" -Body ($Win32AppBody | ConvertTo-Json -Depth 10)
                if ($Win32MobileAppRequest.'@odata.type' -notlike "#microsoft.graph.win32LobApp") {
                    Write-Warning -Message "Failed to create Win32 app using constructed body. Passing converted body as JSON to output."
                    Write-Warning -Message ($Win32AppBody | ConvertTo-Json); break
                }
                else {
                    Write-Verbose -Message "Successfully created Win32 app with ID: $($Win32MobileAppRequest.id)"

                    # Invoke request to setup the reference pointers of each category added to the Win32 app
                    if ($PSBoundParameters["CategoryName"]) {
                        if ($CategoryList.Count -ge 1) {
                            foreach ($CategoryItem in $CategoryList) {
                                $CategoryBodyTable = @{
                                    "@odata.id" = "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppCategories/$($CategoryItem.id)"
                                }
                                Write-Verbose -Message "Adding '$($CategoryItem.DisplayName)' reference to Win32 app with category ID: $($CategoryItem.id)"
                                $Win32AppCategoryReference = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)/categories/`$ref" -Method "POST" -Body ($CategoryBodyTable | ConvertTo-Json)
                            }
                        }
                    }

                    # Create Content Version for the Win32 app
                    Write-Verbose -Message "Attempting to create contentVersions resource for the Win32 app"
                    $Win32MobileAppContentVersionRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions" -Method "POST" -Body "{}"
                    if ([string]::IsNullOrEmpty($Win32MobileAppContentVersionRequest.id)) {
                        Write-Warning -Message "Failed to create contentVersions resource for Win32 app"
                    }
                    else {
                        Write-Verbose -Message "Successfully created contentVersions resource with ID: $($Win32MobileAppContentVersionRequest.id)"

                        # Extract compressed .intunewin file to subfolder
                        $IntuneWinFilePath = Expand-IntuneWin32AppCompressedFile -FilePath $FilePath -FileName $IntuneWinXMLMetaData.ApplicationInfo.FileName -FolderName "Expand"
                        if ($IntuneWinFilePath -ne $null) {
                            # Create a new file entry in Intune for the upload of the .intunewin file
                            Write-Verbose -Message "Constructing Win32 app content file body for uploading of .intunewin file"
                            $Win32AppFileBody = [ordered]@{
                                "@odata.type" = "#microsoft.graph.mobileAppContentFile"
                                #"name" = $IntuneWinXMLMetaData.ApplicationInfo.FileName
                                "name" = [System.IO.Path]::GetFileName($FilePath)
                                "size" = [int64]$IntuneWinXMLMetaData.ApplicationInfo.UnencryptedContentSize
                                "sizeEncrypted" = (Get-Item -Path $IntuneWinFilePath).Length
                                "manifest" = $null
                                "isDependency" = $false
                            }

                            # Create the contentVersions files resource
                            $Win32MobileAppFileContentRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32MobileAppContentVersionRequest.id)/files" -Method "POST" -Body ($Win32AppFileBody | ConvertTo-Json)
                            if ([string]::IsNullOrEmpty($Win32MobileAppFileContentRequest.id)) {
                                Write-Warning -Message "Failed to create Azure Storage blob for contentVersions/files resource for Win32 app"
                            }
                            else {
                                # Wait for the Win32 app file content URI to be created
                                Write-Verbose -Message "Waiting for Intune service to process contentVersions/files request"
                                $FilesUri = "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32MobileAppContentVersionRequest.id)/files/$($Win32MobileAppFileContentRequest.id)"
                                $ContentVersionsFiles = Wait-IntuneWin32AppFileProcessing -Stage "AzureStorageUriRequest" -Resource $FilesUri

                                # Upload .intunewin file to Azure Storage blob
                                if ($PSBoundParameters["UseAzCopy"]) {
                                    $ContentSize = [System.Math]::Round($Win32AppFileBody.size / 1MB, 2)
                                    if ($ContentSize -lt 100) {
                                        Write-Verbose -Message "Content size is less than 100MB, falling back to using native method for file transfer"
                                        Invoke-AzureStorageBlobUpload -StorageUri $ContentVersionsFiles.azureStorageUri -FilePath $IntuneWinFilePath -Resource $FilesUri
                                    }
                                    else {
                                        try {
                                            Write-Verbose -Message "Using AzCopy.exe method for file transfer"
                                            $SplatArgs = @{
                                                StorageUri = $ContentVersionsFiles.azureStorageUri
                                                FilePath = $IntuneWinFilePath
                                                Resource = $FilesUri
                                                WindowStyle = $AzCopyWindowStyle
                                                ErrorAction = "Stop"
                                            }
                                            Invoke-AzureCopyUtility @SplatArgs
                                        }
                                        catch [System.Exception] {
                                            Write-Verbose -Message "AzCopy.exe transfer method failed with exception message: $($_.Exception.Message)"
                                            Write-Verbose -Message "Falling back to native method"
                                            Invoke-AzureStorageBlobUpload -StorageUri $ContentVersionsFiles.azureStorageUri -FilePath $IntuneWinFilePath -Resource $FilesUri
                                        }
                                    }
                                }
                                else {
                                    Write-Verbose -Message "Using native method for file transfer"
                                    $ContentVersionsFiles
                                    $IntuneWinFilePath
                                    $FilesUri
                                    Invoke-AzureStorageBlobUpload -StorageUri $ContentVersionsFiles.azureStorageUri -FilePath $IntuneWinFilePath -Resource $FilesUri
                                }

                                # Retrieve encryption meta data from .intunewin file
                                $IntuneWinEncryptionInfo = [ordered]@{
                                    "encryptionKey" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.EncryptionKey
                                    "macKey" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.macKey
                                    "initializationVector" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.initializationVector
                                    "mac" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.mac
                                    "profileIdentifier" = "ProfileVersion1"
                                    "fileDigest" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.fileDigest
                                    "fileDigestAlgorithm" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.fileDigestAlgorithm
                                }
                                $IntuneWinFileEncryptionInfo = @{
                                    "fileEncryptionInfo" = $IntuneWinEncryptionInfo
                                }

                                # Create file commit request
                                $CommitResource = "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32MobileAppContentVersionRequest.id)/files/$($Win32MobileAppFileContentRequest.id)/commit"
                                $Win32AppFileCommitRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource $CommitResource -Method "POST" -Body ($IntuneWinFileEncryptionInfo | ConvertTo-Json)

                                # Wait for Intune service to process the commit file request
                                Write-Verbose -Message "Waiting for Intune service to process the commit file request"
                                $CommitFileRequest = Wait-IntuneWin32AppFileProcessing -Stage "CommitFile" -Resource $FilesUri

                                switch ($CommitFileRequest.uploadState) {
                                    "commitFileFailed" {
                                        Write-Warning -Message "Failed to create Win32 app, commit file request operation failed"
                                    }
                                    "commitFileTimedOut" {
                                        Write-Warning -Message "Failed to create Win32 app, commit file request operation timed out"
                                    }
                                    default {
                                        # Update committedContentVersion property for Win32 app
                                        Write-Verbose -Message "Updating committedContentVersion property with ID '$($Win32MobileAppContentVersionRequest.id)' for Win32 app with ID: $($Win32MobileAppRequest.id)"
                                        $Win32AppFileCommitBody = [ordered]@{
                                            "@odata.type" = "#microsoft.graph.win32LobApp"
                                            "committedContentVersion" = $Win32MobileAppContentVersionRequest.id
                                        }
                                        $Win32AppFileCommitBodyRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)" -Method "PATCH" -Body ($Win32AppFileCommitBody | ConvertTo-Json)

                                        # Handle return output
                                        Write-Verbose -Message "Successfully created Win32 app and committed file content to Azure Storage blob"
                                        $Win32MobileAppRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)" -Method "GET"
                                        #Write-Output -InputObject $Win32MobileAppRequest
                                    }
                                }                                
                            }

                            try {
                                # Cleanup extracted .intunewin file in Extract folder
                                Remove-Item -Path (Split-Path -Path $IntuneWinFilePath -Parent) -Recurse -Force -Confirm:$false | Out-Null
                            }
                            catch [System.Exception] {
                                # Fallback method if OneDrive's Files On Demand feature is blocking access
                                $FileItems = Get-ChildItem -LiteralPath $IntuneWinFilePath -Recurse
                                foreach ($FileItem in $FileItems) {
                                    $FileItem.Delete()
                                }
                                $ParentItem = Get-Item -LiteralPath $IntuneWinFilePath
                                $ParentItem.Delete($true)
                            }
                        }
                    }
                }
            }
#        }
#        catch [System.Exception] {
#            Write-Warning -Message "An error occurred while creating the Win32 application. Error message: $($_.Exception.Message)"
#        }
    }
}