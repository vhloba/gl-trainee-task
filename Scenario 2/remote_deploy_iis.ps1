# Script to connect to the remote computer (EC2 instance)
# Execution of this script requires administrative privileges and credentials of the EC2 instance Administrative account
#-----------------------------------------------------------------------------------------------------------------------

# Starting WinRM Service on local machine
Start-Service -Name Winrm

# Entering the server's IP-address or DNS-name to connect with
$server = Read-Host "Enter the server's IP-address or DNS-name"

# Setting the entered server as a trusted host
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$server" -Force

# Creating a connection(session) to a remote computer
$session = New-PSSession -ComputerName "$server" -Credential $(Get-Credential)

$DeployScript = {

# Script to deploy a website on IIS Server

Import-Module WebAdministration

# Unbinding a port "80" from the Default IIS Web Site
Get-WebBinding -Port 80 -Name "Default Web Site" | Remove-WebBinding

# Checking the existence of such website, application pool and site folder, and remove them if exist
if ((Test-Path "IIS:\Sites\My AWS WebSite") -eq $True) {
    Remove-WebSite -Name "My AWS WebSite"
}

if ((Test-Path "IIS:\AppPools\My AWS WebSite AppPool") -eq $True) {
    Remove-WebAppPool -Name "My AWS WebSite AppPool"
}

if ((Test-Path "$env:systemdrive\Sites\My AWS WebSite") -eq $True) {
    Remove-Item "$env:systemdrive\Sites\My AWS WebSite" -Recurse
}

# Creating a site folder for a new WebSite
New-Item -ItemType directory -Path "$env:systemdrive\Sites\My AWS WebSite"

# Creating a new WebSite
New-Website -Name "My AWS WebSite" -Port 80 -IPAddress "*" -HostHeader "" -PhysicalPath "$env:systemdrive\Sites\My AWS WebSite"

# Creating an Application Pool and associate it with the created WebSite
New-Item -Path "IIS:\AppPools" -Name "My AWS WebSite AppPool" -Type AppPool

Set-ItemProperty -Path "IIS:\Sites\My AWS WebSite" -name "applicationPool" -value "My AWS WebSite AppPool"

# Creating a simple test web-page
New-Item -Path "$env:systemdrive\Sites\My AWS WebSite" -Name "Default.htm" -ItemType "file" -Value "Hello! This is the test page of My AWS WebSite."

# Starting WebSite
Start-Website -Name "My AWS WebSite"

}

# Running a ps-script on a remote computer
Invoke-Command -Session $session -ScriptBlock $DeployScript

# Removing the connection(session)
Remove-PSSession -Session $session