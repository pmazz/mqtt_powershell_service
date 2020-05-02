$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Add-Type -Path (Join-Path $ScriptDirectory "bin\M2Mqtt.Net.dll")

Function Initialize-MqttClient {
    <#
    .Synopsis
        Initialize the MQTT client.
    .Description
        This function initializes, connects and returns the MQTT client to be used for publishing and subscribing.
    .Parameter BrokerAddress
        The MQTT broker host address.
    .Parameter BrokerPort
        The MQTT broker host port number.
        Default is 1883.
    .Parameter Secure
        Indicates whether to use a secure connection.
        Default is false.
    .Parameter SslProtocol
        The SSL protocol to be used in case of secure connection.
        Valid values are: None, SSLv3, TLSv1_0, TLSv1_1, TLSv1_2.
        Default is None.
    .Parameter Username
        Username for connecting to the broker.
    .Parameter Password
        Password for connecting to the broker.
    .Inputs
        None
    .Outputs
        None
    .Notes
         NAME:      Initialize-MqttClient
         VERSION:   1.0
         AUTHOR:    Paolo Mazzini
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage="The MQTT broker host address.")]
        [string]$BrokerAddress,

        [Parameter(HelpMessage="The MQTT broker host port number.")]
        [int]$BrokerPort=1883,

        [Parameter(HelpMessage="Indicates whether to use a secure connection.")]
        [bool]$Secure=$false,

        [Parameter(HelpMessage="The SSL protocol to be used in case of secure connection.")]
        [uPLibrary.Networking.M2Mqtt.MqttSslProtocols]$SslProtocol=[uPLibrary.Networking.M2Mqtt.MqttSslProtocols]::None,

        [Parameter(Mandatory=$True,HelpMessage="Username for connecting to the broker.")]
        [string]$Username,

        [Parameter(Mandatory=$True,HelpMessage="Password for connecting to the broker.")]
        [string]$Password
    )

    Write-Verbose "Initializing the client"
    # Instantiate the client
    $mqttClient = New-Object uPLibrary.Networking.M2Mqtt.MqttClient($BrokerAddress, $BrokerPort, $Secure, $SslProtocol, $null, $null)
    # Connect the client
    Write-Verbose "Connecting the client"
    $mqttclient.Connect([guid]::NewGuid(), $Username, $Password) | Out-Null #This Out-Null is necessary to prevent invalid casting of returned object
    Write-Verbose "Client Connected"
    Write-Verbose ""
    return $mqttClient
}

Function Publish-Mqtt {
    <#
    .Synopsis
        Publish a message to a MQTT topic.
    .Description
        This function publishes a message to the specified MQTT topic.
    .Parameter MqttClient
        The MQTT client object to be used.
    .Parameter Topic
        The MQTT topic to publish to.
    .Parameter Message
        The message to be published.
    .Parameter QoS
        Quality of Service level.
        Valid values are: 0, 1, 2.
        Default is 0.
    .Parameter Retain
        Indicates whether publish the message as retained.
    .Inputs
        None
    .Outputs
        None
    .Notes
         NAME:      Publish-Mqtt
         VERSION:   1.0
         AUTHOR:    Paolo Mazzini
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage="The MQTT client object.")]
        [uPLibrary.Networking.M2Mqtt.MqttClient]$MqttClient,

        [Parameter(Mandatory=$True,HelpMessage="The MQTT topic to publish to.")]
        [string]$Topic,

        [Parameter(Mandatory=$True,HelpMessage="The message to be published.")]
        [string]$Message,

        [Parameter(HelpMessage="Quality of Service level.")]
        [ValidateRange(0,2)]
        [byte]$QoS=0,

        [Parameter(HelpMessage="Indicates whether publish the message as retained.")]
        [bool]$Retain=$false
    )

    if ($MqttClient -eq $null) {
        throw New-Object System.NullReferenceException("MQTT client is null")
    }
    if ($MqttClient -isnot [uPLibrary.Networking.M2Mqtt.MqttClient]) {
        throw New-Object System.InvalidCastException("MQTT client is an invalid object type")
    }
    if (-not $MqttClient.IsConnected) {
        throw "MQTT client not connected"
    }
    Write-Verbose ([String]::Format("Publishing '{0}' to '{1}'", $Message, $Topic))
    # Publish to the MQTT topic
#TODO $QoS>0 doesn't seem to work (messages are always published with QoS=0)
#TODO $Retain=$true doesn't seem to work (messages are always published as not retained)
    $MqttClient.Publish($Topic, [System.Text.Encoding]::UTF8.GetBytes($Message), $QoS, $Retain)
    Write-Verbose "Published"
    Write-Verbose ""
}

Function Subscribe-Mqtt {
    <#
    .Synopsis
        Subscribe to a MQTT topic.
    .Description
        This function subscribes to a MQTT topic and execute the given function delegate.
    .Parameter MqttClient
        The MQTT client object to be used.
    .Parameter Topic
        The MQTT topic to subscribe to.
    .Parameter QoS
        Quality of Service level.
        Valid values are: 0, 1, 2.
        Default is 0.
    .Parameter Action
        The action to be executed for each new message in topic.
    .Inputs
        None
    .Outputs
        None
    .Notes
            NAME:      Subscribe-Mqtt
            VERSION:   1.0
            AUTHOR:    Paolo Mazzini
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage="The MQTT client object.")]
        [uPLibrary.Networking.M2Mqtt.MqttClient]$MqttClient,

        [Parameter(Mandatory=$True,HelpMessage="The MQTT topic to subscribe to.")]
        [string]$Topic,

        [Parameter(HelpMessage="Quality of Service level.")]
        [ValidateRange(0,2)]
        [byte]$QoS=0,

        [Parameter(Mandatory=$True,HelpMessage="The action to be executed for each new message in topic.")]
        [Action[string,string]]$Action
    )

    if ($MqttClient -eq $null) {
        throw New-Object System.NullReferenceException("MQTT client is null")
    }
    if ($MqttClient -isnot [uPLibrary.Networking.M2Mqtt.MqttClient]) {
        throw New-Object System.InvalidCastException("MQTT client is an invalid object type")
    }
    if (-not $MqttClient.IsConnected) {
        throw "MQTT client not connected"
    }
    Write-Verbose ([String]::Format("Subscribing to topic '{0}'", $Topic))
    # Register the event 'MqttMsgPublishReceived' for showing topic changes
    $regInfo = Register-ObjectEvent -inputObject $cli -EventName MqttMsgPublishReceived -Action {
        $Action.Invoke($args[1].topic, [System.Text.Encoding]::ASCII.GetString($args[1].message))
    }
    Write-Verbose ([String]::Format("Registered to event '{0}'", $regInfo.Name))
    # Subscribe to the MQTT topic
    $mqttClient.Subscribe($Topic, $QoS)
    Write-Verbose "Subscribed"
    Write-Verbose ""
}

Function Unsubscribe-Mqtt {
    <#
    .Synopsis
        Unsubscribe from a MQTT topic.
    .Description
        This function unsubscribes from a subscribed MQTT topic.
    .Parameter MqttClient
        The MQTT client object to be used.
    .Parameter Topic
        The MQTT topic to unsubscribe from.
    .Inputs
        None
    .Outputs
        None
    .Notes
            NAME:      Unsubscribe-Mqtt
            VERSION:   1.0
            AUTHOR:    Paolo Mazzini
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage="The MQTT client object.")]
        [uPLibrary.Networking.M2Mqtt.MqttClient]$MqttClient,

        [Parameter(Mandatory=$True,HelpMessage="The MQTT topic to subscribe to.")]
        [string]$Topic
    )

    if ($MqttClient -eq $null) {
        throw New-Object System.NullReferenceException("MQTT client is null")
    }
    if ($MqttClient -isnot [uPLibrary.Networking.M2Mqtt.MqttClient]) {
        throw New-Object System.InvalidCastException("MQTT client is an invalid object type")
    }
    if (-not $MqttClient.IsConnected) {
        throw "MQTT client not connected"
    }
    Write-Verbose ([String]::Format("Unsubscribing from topic '{0}'", $Topic))
    # Unsubscribe from the MQTT topic
    $MqttClient.Unsubscribe($Topic)
    # Unregister all the events
    Get-EventSubscriber -Force | Unregister-Event -Force
    Write-Verbose "Unsubscribed"
    Write-Verbose ""
}
