<#
.SYNOPSIS
    UTL-011 | Connect to Microsoft 365 Commerce.

.DESCRIPTION
    PowerShell utility script that connects to Microsoft Commerce (MSCommerce module) 
    to manage subscription settings, billing, and self-service purchase options.

.PRODUCT
    Microsoft 365 / Commerce

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectCommerce classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectCommerce.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-011 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-011_Connect-Commerce.ps1
    Requires: MSCommerce module.
#>

#region ── Main Program ───────────────────────────────────────────────────────
# Connect to Commerce PowerShell
Install-Module MSCommerce -AllowClobber -Force -Confirm:$false
Import-Module MSCommerce
Connect-MSCommerce
#endregion
