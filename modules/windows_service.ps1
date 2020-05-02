Add-Type -AssemblyName System.ServiceProcess

Function Create-Service {
    <#
    .Synopsis
        Install a new Windows service.
    .Description
        This function installs a new Windows service.
    .Parameter ServiceName
        The internal name of the service.
    .Parameter DisplayName
        The display name of the service.
    .Parameter Description
        The description of the service.
    .Parameter FilePath
        The full path of the executable file for the service.
    .Parameter StartupType
        The startup type of the service.
        Valid values are: Automatic, Disabled, Manual.
        Default is Automatic.
    .Inputs
        None
    .Outputs
        None
    .Notes
         NAME:      Create-Service
         VERSION:   1.0
         AUTHOR:    Paolo Mazzini
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage="The internal name of the service.")]
        [string]$ServiceName,

        [Parameter(Mandatory=$True,HelpMessage="The display name of the service.")]
        [string]$DisplayName,

        [Parameter(Mandatory=$True,HelpMessage="The description of the service.")]
        [string]$Description,

        [Parameter(Mandatory=$True,HelpMessage="The full path of the executable file for the service.")]
        [string]$FilePath,

        [Parameter(HelpMessage="The startup type of the service.")]
        [System.ServiceProcess.ServiceStartMode]$StartupType=[System.ServiceProcess.ServiceStartMode]::Automatic
    )

    Write-Verbose "Checking if the file exists"
    if (-not (Test-Path $FilePath)) {
        throw New-Object System.IO.FileNotFoundException([String]::Format("File '{0}'does not exist", $FilePath))
    }
    Write-Verbose "Checking if the service already exists"
    if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
#TODO Throw excepion, instead of trying to removed the service
        $svc = Get-WmiObject -Class Win32_Service -Filter "name='$ServiceName'"
        $svc.delete()
        Write-Verbose "Service removed"
    }
    Write-Verbose "Installing service"
    # $secpasswd = ConvertTo-SecureString "MyPassword" -AsPlainText -Force
    # $mycreds = New-Object System.Management.Automation.PSCredential (".\MYUser", $secpasswd)
    # $binaryPath = "c:\servicebinaries\MyService.exe"
    # New-Service -name $ServiceName -binaryPathName $FilePath -displayName $DisplayName -startupType Automatic -credential $mycreds
    New-Service -name $ServiceName -binaryPathName $FilePath -displayName $DisplayName -description $Description -startupType $StartupType
    Write-Verbose "Service installed"
    Write-Verbose ""
}

#TODO Start the service
