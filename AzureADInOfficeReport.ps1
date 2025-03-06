#Install the AzureADPreview module if not already installed
if (-not (Get-Module -ListAvailable -Name AzureADPreview)) {
    Install-Module -Name AzureADPreview -Force
}

Import-Module AzureADPreview

# Connect to Azure AD
if ($context -eq $null) { $context = Connect-AzureAD}

if($signInLogs -eq $null) {

    # Get the current user's ID as a GUID
    $userId = (Get-AzureADUser -ObjectId "$($context.Account.Id)").ObjectId

    # Get the sign-in logs for the past 30 days
    $signInLogs = Get-AzureADAuditSignInLogs -Filter "userId eq '$userId'"

}

# Function to get vacation dates
function Get-VacationDates {
    param (
        [string[]]$dateEntries
    )
    $timeOffDays = @()
    foreach ($entry in $dateEntries) {
        if ($entry -match "-") {
            $dates = $entry -split "-"
            $start = [datetime]::Parse($dates[0].Trim())
            $end = [datetime]::Parse($dates[1].Trim())

            if ($start -gt $end) {
                Write-Host "End date must be after start date."
                continue
            }

            $currentDate = $start
            while ($currentDate -le $end) {
                $timeOffDays += $currentDate.ToString("yyyy-MM-dd")
                $currentDate = $currentDate.AddDays(1)
            }
        } else {
            $date = [datetime]::Parse($entry.Trim())
            $timeOffDays += $date.ToString("yyyy-MM-dd")
        }
    }
    return $timeOffDays
}

# Prompt user for vacation dates and single days off
$dateEntries = Read-Host "Enter your vacation dates and single days off (e.g., MM/DD/YYYY-MM/DD/YYYY, MM/DD/YYYY) separated by commas"

if ($dateEntries -ne "") {

    # Split the input into an array and get the vacation dates
    $dateEntriesArray = $dateEntries -split ","

    $timeOffDays = @()
    $timeOffDays = Get-VacationDates -dateEntries $dateEntriesArray
} else {
    #Set this to empty if dateEntries also empty
    $timeOffDays = @()
}

$report = @{}
$locationMap = @{}

# Get all possible location values
foreach ($log in $signInLogs) {
    $city = $log.Location.City
    $IpAddress = $log.IpAddress
    if ($locationMap.ContainsKey($city)){}
    else {
        $locationMap[$city] = $IpAddress
    }

}

# Define the office Location
$officeLocation = $locationMap.Keys | Out-GridView -Title "Select an Office Location" -PassThru

# Since locations contain the same IP's we can filter on IP address now

$officeIp = $locationMap[$officeLocation]

# Process each sign-in log
foreach ($log in $signInLogs) {
    $datetime = [datetime]::Parse($log.CreatedDateTime)
    # Check if day of week is not Saturday or Sunday
    if ($datetime.DayOfWeek -ne [System.DayOfWeek]::Saturday -and -$datetime.DayOfWeek -ne [System.DayOfWeek]::Sunday){
        $date = $datetime.ToString("yyyy-MM-dd")
        # Check if day of week is in known time off
        if ($date -notin $timeOffDays ){
            # Check if the IP address is within the office IP range
            if ($log.IpAddress -eq $officeIp) {
                if ($report.ContainsKey($date)) {
                    $report[$date][0] += 1
                } else {
                    $report[$date] = @()
                    $report[$date] = (1,0)
                }
            }
            else {
                if ($report.ContainsKey($date)) {
                    $report[$date][1] += 1
                } else {
                    $report[$date] = @()
                    $report[$date] = (0,1)
                }
            }
        }
    }
}

# Output the report
$daysInOffice = 0
$remoteDays = 0
$report.GetEnumerator() | Sort-Object Key | ForEach-Object {
    $inOffice = $null
    if ($_.Value[0] -ge 1){
        $inOffice = "Worked in the Office"
        $daysInOffice += 1
    }
    else{
        $remoteDays += 1
    }

    [PSCustomObject]@{
        Date         = $_.Key
        OfficeLogins = $_.Value[0]
        RemoteLogins = $_.Value[1]
        InTheOffice = $inOffice
    }

    $inOfficePercentage = [math]::Round(($daysInOffice/($daysInOffice+$remoteDays))*100)
}
Write-Output "`nYou have worked ${inOfficePercentage}% in the office in the past 30 days"
