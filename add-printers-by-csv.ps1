# CSV Import Mode
Add-Type -AssemblyName System.Windows.Forms
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Filter = "CSV files (*.csv)|*.csv"
$openFileDialog.Title = "Select CSV file"
if ($openFileDialog.ShowDialog() -eq 'OK') {
    $csvPath = $openFileDialog.FileName
} else {
    Write-Host "No file selected."
    exit
}
$printers = Import-Csv $csvPath

# Sets the template directory to the folder where this script is saved
$TemplateDir = $PSScriptRoot

$TrayConfigs = @{
    "TOP"    = "LexmarkTopDefaults.xml"
    "MIDDLE" = "LexmarkMiddleDefaults.xml"
    "BOTTOM" = "LexmarkBottomDefaults.xml"
}

# Ask for exclude list
$excludeInput = Read-Host "Are there any printers that should not have the TOP MIDDLE BOTTOM lexmark settings applied? (y/n)"
if ($excludeInput -eq 'y') {
    $excludeListInput = Read-Host "Enter comma separated list of printer names to exclude"
    $excludeList = $excludeListInput -split ',' | ForEach-Object { $_.Trim() }
} else {
    $excludeList = @()
}

# 2. Create Printers and Apply Tray Defaults
foreach ($printer in $printers) {
    $FullName = $printer.'Printer Name'
    $PrinterIP = $printer.'IP Address'
    $PortName = $PrinterIP
    $DriverName = "Lexmark Universal v2 PS3"  # Assuming default driver, or add to CSV if needed

    # Create the Port if it doesn't exist
    if (!(Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {
        Write-Host "Creating Port $PortName..." -ForegroundColor Cyan
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
    }

    Write-Host "Processing $FullName..." -ForegroundColor Yellow

    # Add Printer
    Add-Printer -Name $FullName -DriverName $DriverName -PortName $PortName -Shared -ShareName $FullName

    # Apply Tray XML if not excluded
    if ($FullName -notin $excludeList) {
        # Determine tray
        if ($FullName -match '-TOP$') {
            $Tray = 'TOP'
        } elseif ($FullName -match '-MIDDLE$') {
            $Tray = 'MIDDLE'
        } elseif ($FullName -match '-BOTTOM$') {
            $Tray = 'BOTTOM'
        } else {
            Write-Warning "Cannot determine tray for $FullName, skipping settings"
            continue
        }
        $TemplateFile = $TrayConfigs[$Tray]
        $TemplatePath = Join-Path $TemplateDir $TemplateFile
        if (Test-Path $TemplatePath) {
            $xmlContent = Get-Content $TemplatePath -Raw
            Set-PrintConfiguration -PrinterName $FullName -PrintTicketXml $xmlContent
            Write-Host "Successfully applied $TemplateFile to $FullName" -ForegroundColor Green
        } else {
            Write-Warning "Template $TemplatePath not found! Looking in: $TemplateDir"
        }
    } else {
        Write-Host "Skipping settings for $FullName as excluded" -ForegroundColor Yellow
    }
}

Write-Host "`nAll printers have been created." -ForegroundColor Green