<#
.SYNOPSIS
    UTL-007 | Download and Automate Daily Bing Wallpaper for Microsoft Teams Backgrounds.

.DESCRIPTION
    PowerShell script that requests daily wallpaper metadata from the Bing.com API, downloads the 
    high-resolution image, and saves it directly to the user's Microsoft Teams background upload folder.

.PRODUCT
    Microsoft Teams / Utilities

.ORIGINAL_AUTHOR
    Martina Grom - atwork.at

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-007 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-007_Get-Daily-Bing-Picture.ps1
    Requires: Active internet connection and Microsoft Teams installed.
#>

#region ── Main Program ───────────────────────────────────────────────────────
# Use the Bing.com API. 
# The idx parameter determines the day: 0 is the current day, 1 is the previous day, etc. This goes back for max. 7 days. 
# The n parameter defines how many pictures you want to load. Usually, n=1 to get the latest picture (of today) only. 
# The mkt parameter defines the culture, like en-US, de-DE, etc.
$uri = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"

# Get the picture metadata
$response = Invoke-WebRequest -Method Get -Uri $uri

# Extract the image content
$body = ConvertFrom-Json -InputObject $response.Content
$fileurl = "https://www.bing.com/" + $body.images[0].url
$filename = $body.images[0].startdate + "-" + $body.images[0].title.Replace(" ", "-").Replace("?", "") + ".jpg"

# Download the picture to %APPDATA%\Microsoft\Teams\Backgrounds\Uploads
$filepath = $env:APPDATA + "\Microsoft\Teams\Backgrounds\Uploads\" + $filename
Invoke-WebRequest -Method Get -Uri $fileurl -OutFile $filepath

# Show the generated picture filepath
$filepath
#endregion
