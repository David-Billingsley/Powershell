<#
.SYNOPSIS
    Works with Wifi Profiles on devices
.DESCRIPTION
    Lets the users read and write Wifi profiles to a device
.NOTES
    Author: David Billingsley
    Date:   6/19/2025
    Version: 1.0
#>

# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore

# Define your Wi-Fi profile functions (paste your own or use these):
Function get-Allwifi {
    $WifiObject = @()
    foreach ($profile in (netsh wlan show profiles | Select-String -Pattern "All User Profile")) {
        $name = ($profile -split ":")[1].Trim()
        $keyPresent = netsh wlan show profile name="$name" | Select-String -Pattern "Security key"
        if (($keyPresent -split ":")[1].Trim() -eq "Present") {
            $profilePass = netsh wlan show profile name="$name" key=clear | Select-String -Pattern "Key Content"
            $pass = ($profilePass -split ":")[1].Trim()
        } else {
            $pass = ""
        }
        $WifiObject += [PSCustomObject]@{ 
            SSID = $name
            Key  = $pass
        }
    }
    $WifiObject
}

Function get-singleWifi {
    [CmdletBinding()]
    Param(
        [string]$name,
        [bool]$DisplayOnly = $true
    )
    $keyPresent = netsh wlan show profile name="$name" | Select-String -Pattern "Security key"
    if (($keyPresent -split ":")[1].Trim() -eq "Present") {
        $profilePass = netsh wlan show profile name="$name" key=clear | Select-String -Pattern "Key Content"
        $pass = ($profilePass -split ":")[1].Trim()
    } else {
        $pass = ""
    }
    [PSCustomObject]@{ 
        SSID = $name
        Key  = $pass
    }
}

Function export-AllProfiles {
    [CmdletBinding()]
    Param(
        [string]$fileLocation = "."
    )
    foreach ($profile in (netsh wlan show profiles | Select-String -Pattern "All User Profile")) {
        $name = ($profile -split ":")[1].Trim()
        netsh wlan export profile name="$name" key=clear folder="$fileLocation"
    }
}

Function export-SingleProfiles {
    [CmdletBinding()]
    Param(
        [string]$fileLocation = ".",
        [string]$wifiName
    )
    netsh wlan export profile name="$wifiName" key=clear folder="$fileLocation"
}

Function write-MultiProfiles {
    [CmdletBinding()]
    Param(
        [string]$profilesLocation
    )
    $files = Get-ChildItem -Path "$profilesLocation" -Include "Wi-Fi*.xml" -Recurse
    foreach ($file in $files) {
        netsh wlan add profile filename="$($file.FullName)"
    }
}

Function write-SingleProfiles {
    [CmdletBinding()]
    Param(
        [string]$profilesLocation
    )
    netsh wlan add profile filename="$profilesLocation"
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="Wi-Fi Profile Manager" Height="450" Width="650" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="3*" />
            <ColumnDefinition Width="4*" />
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>
        
        <Label Content="Output:" Grid.Row="0" Grid.Column="0" /> 

        <ListBox x:Name="listBox" Grid.Row="1" Grid.Column="0" Grid.RowSpan="3" Margin="0,5,10,5" />

        <Label Content="SSID:" Grid.Row="0" Grid.Column="1" /> 
        <TextBox x:Name="textBox" Grid.Row="1" Grid.Column="1" Height="25" Margin="0,5,10,5" />

        <Label Content="File Path:" Grid.Row="2" Grid.Column="1" /> 
        <TextBox x:Name="textBoxLocation" Grid.Row="3" Grid.Column="1" Height="25" Margin="0,0,0,5" Text="." />

        <Label Content="Status:" Grid.Row="9" Grid.Column="0" /> 
        <TextBox x:Name="outputBox" Grid.Row="10" Grid.Column="0" Grid.ColumnSpan="2" Height="60" Margin="0,5,0,0" TextWrapping="Wrap" IsReadOnly="True" VerticalScrollBarVisibility="Auto" />

        <Button x:Name="btnGetAll" Grid.Row="4" Grid.Column="1" Height="30" Margin="0,5,0,0" Content="Get All Wi-Fi Profiles" />
        <Button x:Name="btnGetSingle" Grid.Row="5" Grid.Column="1" Height="30" Margin="0,5,0,0" Content="Get Single Wi-Fi Profile" />
        <Button x:Name="btnExportAll" Grid.Row="6" Grid.Column="1" Height="30" Margin="0,5,0,0" Content="Export All Profiles" />
        <Button x:Name="btnExportSingle" Grid.Row="7" Grid.Column="1" Height="30" Margin="0,5,0,0" Content="Export Single Profile" />
        <Button x:Name="btnWriteMulti" Grid.Row="6" Grid.Column="0" Height="30" Margin="0,5,10,0" Content="Write Multiple Profiles" />
        <Button x:Name="btnWriteSingle" Grid.Row="7" Grid.Column="0" Height="30" Margin="0,5,10,0" Content="Write Single Profile" />
        <Button x:Name="btnClear" Grid.Row="4" Grid.Column="0" Height="30" Margin="0,5,10,0" Content="Clear information" />
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$listBox = $window.FindName("listBox")
$textBox = $window.FindName("textBox")
$textBoxLocation = $window.FindName("textBoxLocation")
$outputBox = $window.FindName("outputBox")
$btnGetAll = $window.FindName("btnGetAll")
$btnGetSingle = $window.FindName("btnGetSingle")
$btnExportAll = $window.FindName("btnExportAll")
$btnExportSingle = $window.FindName("btnExportSingle")
$btnWriteMulti = $window.FindName("btnWriteMulti")
$btnWriteSingle = $window.FindName("btnWriteSingle")
$btnClear = $window.FindName("btnClear")

$textBox.Add_TextChanged({
    $textBox.Background = [System.Windows.Media.Brushes]::White
})

$btnClear.Add_Click({
    $outputBox.Text = "Clearing outputs"
    $listBox.Items.Clear()
})

$btnGetAll.Add_Click({
    $outputBox.Text = "Getting all Wi-Fi profiles..."
    $profiles = get-Allwifi
    $listBox.Items.Clear()
    foreach ($p in $profiles) {
        $listBox.Items.Add("$($p.SSID) : $($p.Key)")
    }
    $outputBox.Text = "Retrieved all Wi-Fi profiles."
})

$btnGetSingle.Add_Click({
    $name = $textBox.Text
    if ([string]::IsNullOrWhiteSpace($name)) {
        $outputBox.Text = "Please enter a Wi-Fi name."
        $textBox.BackGround = [System.Windows.Media.Brushes]::Red
        return
    }
    $outputBox.Text = "Getting Wi-Fi profile for $name..."
    $profile = get-singleWifi -name $name -DisplayOnly $true
    $listBox.Items.Clear()
    $listBox.Items.Add("$($profile.SSID) : $($profile.Key)")
    $outputBox.Text = "Retrieved Wi-Fi profile for $name."
})

$btnExportAll.Add_Click({
    $location = $textBoxLocation.Text
    $outputBox.Text = "Exporting all profiles to $location..."
    export-AllProfiles -fileLocation $location
    $outputBox.Text = "Exported all profiles to $location."
})

$btnExportSingle.Add_Click({
    $location = $textBoxLocation.Text
    $name = $textBox.Text
    if ([string]::IsNullOrWhiteSpace($name)) {
        $outputBox.Text = "Please enter a Wi-Fi name."
        return
    }
    $outputBox.Text = "Exporting profile $name to $location..."
    export-SingleProfiles -fileLocation $location -wifiName $name
    $outputBox.Text = "Exported profile $name to $location."
})

$btnWriteMulti.Add_Click({
    $location = $textBoxLocation.Text
    $outputBox.Text = "Writing multiple profiles from $location..."
    write-MultiProfiles -profilesLocation $location
    $outputBox.Text = "Written multiple profiles from $location."
})

$btnWriteSingle.Add_Click({
    $location = $textBoxLocation.Text
    $outputBox.Text = "Writing single profile from $location..."
    write-SingleProfiles -profilesLocation $location
    $outputBox.Text = "Written single profile from $location."
})

$listBox.Add_SelectionChanged({
    param($sender, $e)
    if ($sender.SelectedItem -ne $null) {
        $textBox.Text = $sender.SelectedItem.ToString()
        $textBox.Text = ($sender.SelectedItem -split " : ")[0]
    }
})

$window.ShowDialog() | Out-Null
