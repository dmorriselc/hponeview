# Import HPE OneView PowerShell module if necessary
# Import-Module HPOneView.####

# Get all servers
$servers = Get-OVServer

# Initialize an array to collect drive data
$driveData = @()

# Loop through each server
foreach ($server in $servers) {
    # Retrieve the server's URI
    $serverUri = $server.uri

    # Check if the server model is Gen10 or Gen11
    if ($server.Model -like "*Gen1*") {
        # Fetch disk drive data for Gen10/Gen11 server
        $drives = (Send-OVRequest -uri "$serverUri/localStorageV2").Data.Drives
    } elseif ($server.Model -match "Gen9") {
        # Fetch disk drive data for Gen9 server
        $drives = (Send-OVRequest -uri "$serverUri/localStorage").Data.PhysicalDrives
    } else {
        Write-Output "Server $($server.ServerName) has an unsupported model: $($server.Model)"
        continue
    }

    # Collect drive details for each drive
    foreach ($drive in $drives) {
        if ($server.Model -like "*Gen1*") {
            # Gen10/Gen11 drive details, including Revision
            $driveData += [PSCustomObject]@{
                ServerName                   = $server.ServerName
                Id                            = $drive.Id
                Name                          = $drive.Name
                Model                         = $drive.Model
                CapacityGB                    = [math]::round($drive.CapacityBytes / 1GB, 2)
                MediaType                     = $drive.MediaType
                SerialNumber                  = $drive.SerialNumber
                Status                        = $drive.Status.State
                Health                        = $drive.Status.Health
                PredictedMediaLifeLeftPercent = $drive.PredictedMediaLifeLeftPercent
                Protocol                      = $drive.Protocol
                CapableSpeedGbs               = $drive.CapableSpeedGbs
                NegotiatedSpeedGbs            = $drive.NegotiatedSpeedGbs
                Revision                      = $drive.Revision  # Added Revision for Gen10/11
            }
        } elseif ($server.Model -match "Gen9") {
            # Gen9 drive details with FirmwareVersion simplified
            $firmwareVersion = if ($drive.FirmwareVersion.Current -and $drive.FirmwareVersion.Current.VersionString) {
                $drive.FirmwareVersion.Current.VersionString
            } else {
                "N/A"
            }

            $driveData += [PSCustomObject]@{
                ServerName                   = $server.ServerName
                Location                      = $drive.Location
                Model                         = $drive.Model
                CapacityGB                    = [math]::round($drive.CapacityMiB / 1024, 2)
                MediaType                     = $drive.MediaType
                SerialNumber                  = $drive.SerialNumber
                Status                        = $drive.Status.State
                Health                        = $drive.Status.Health
                EncryptedDrive                = $drive.EncryptedDrive
                FirmwareVersion               = $firmwareVersion
                DiskDriveUse                  = $drive.DiskDriveUse
            }
        }
    }
}

# Display data in an interactive grid view
$driveData | Out-GridView -Title "Server Drive Information"

# Export data to CSV
$csvFilePath = "C:\Scripts\ServerDriveInfo.csv"
$driveData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force
Write-Output "Data exported to CSV at $csvFilePath"
