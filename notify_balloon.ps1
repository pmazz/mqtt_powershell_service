Add-Type -AssemblyName System.Windows.Forms

Function Invoke-BalloonTip {
    <#
    .Synopsis
        Display a balloon tip message in the system tray.
        Original implementation by Boe Prox (https://github.com/proxb/PowerShell_Scripts/blob/master/Invoke-BalloonTip.ps1).
    .Description
        This function displays a user-defined message as a balloon popup in the system tray. Works on Windows Vista or later.
    .Parameter Message
        The message text you want to display. Recommended to keep it short and simple.
    .Parameter Title
        The title for the message balloon.
    .Parameter MessageType
        The type of message. This value determines what type of icon to display.
        Valid values are: Info, Error, Warning, None.
        Default is Info.
    .Parameter SysTrayIcon
        The path to a file that you will use as the system tray icon.
        Default is the PowerShell ISE icon.
    .Parameter Duration
        The number of milliseconds to display the balloon popup.
        Default is 2000.
    .Inputs
        None
    .Outputs
        None
    .Notes
         NAME:      Invoke-BalloonTip
         VERSION:   1.1
         AUTHOR:    Boe Prox (reviewed by Paolo Mazzini)
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage="The message text to display. Keep it short and simple.")]
        [string]$Message,

        [Parameter(HelpMessage="The message title.")]
        [string]$Title="Attention $env:username",

        [Parameter(HelpMessage="The message type: Info,Error,Warning,None.")]
        [System.Windows.Forms.ToolTipIcon]$MessageType="Info",

        [Parameter(HelpMessage="The path to a file to use its icon in the system tray.")]
        [string]$SysTrayIconPath="",

        [Parameter(HelpMessage="The number of milliseconds to display the message.")]
        [int]$Duration=2000
    )

    if (-not $global:balloon) {
        $global:balloon = New-Object System.Windows.Forms.NotifyIcon

        # #Mouse double click on icon to dispose
        # [void](Register-ObjectEvent -InputObject $balloon -EventName MouseDoubleClick -SourceIdentifier IconClicked -Action {
        #    #Perform cleanup actions on balloon tip
        #    $global:balloon.dispose()
        #    Unregister-Event -SourceIdentifier IconClicked
        #    Remove-Job -Name IconClicked
        #    Remove-Variable -Name balloon -Scope Global
        # })
    }

    # Need an icon for the tray
    if ($SysTrayIconPath -eq "") {
        $SysTrayIconPath = Get-Process -id $pid | Select-Object -ExpandProperty Path
    }

    # Extract the icon from the file
    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($SysTrayIconPath)

    # Can only use certain TipIcons: [System.Windows.Forms.ToolTipIcon] | Get-Member -Static -Type Property
    $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]$MessageType
    $balloon.BalloonTipText = $Message
    $balloon.BalloonTipTitle = $Title
    $balloon.Visible = $true

    # Display the tip and specify in milliseconds on how long balloon will stay visible
    $balloon.ShowBalloonTip($Duration)
}
