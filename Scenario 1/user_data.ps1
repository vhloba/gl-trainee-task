<powershell>
Set-NetFirewallRule -Name “WINRM-HTTP-In-TCP-PUBLIC” -RemoteAddress “Any”
Enable-PSRemoting –force
Install-WindowsFeature -name Web-Server -IncludeManagementTools
</powershell>