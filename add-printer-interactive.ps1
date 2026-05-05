# --- User Prompts ---
$SiteID      = Read-Host "Enter Site Prefix (e.g., 0311)"
$PrinterType = Read-Host "Enter Printer Type [Default: LASER]"
if ([string]::IsNullOrWhiteSpace($PrinterType)) { $PrinterType = "LASER" }

$PrinterNum  = Read-Host "Enter Printer Number (e.g., 50)"
$PrinterIP   = Read-Host "Enter Printer IP Address"

# Sets the template directory to the folder where this script is saved
$TemplateDir = $PSScriptRoot 

# --- Variables ---
$DriverName  = "Lexmark Universal v2 PS3"
$BaseName    = "$SiteID-$($PrinterType.ToUpper())$PrinterNum"
$PortName    = "$PrinterIP"

$TrayConfigs = @{
    "TOP"    = "LexmarkTopDefaults.xml"
    "MIDDLE" = "LexmarkMiddleDefaults.xml"
    "BOTTOM" = "LexmarkBottomDefaults.xml"
}

# 1. Create the Port if it doesn't exist
if (!(Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating Port $PortName..." -ForegroundColor Cyan
    Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
}

# 2. Create Printers and Apply Tray Defaults
foreach ($Tray in "TOP", "MIDDLE", "BOTTOM") {
    $FullName     = "$BaseName-$Tray"
    $TemplateFile = $TrayConfigs[$Tray]
    $TemplatePath = Join-Path $TemplateDir $TemplateFile

    Write-Host "Processing $FullName..." -ForegroundColor Yellow

    # Add Printer
    Add-Printer -Name $FullName -DriverName $DriverName -PortName $PortName -Shared -ShareName $FullName

    # Apply Tray XML
    if (Test-Path $TemplatePath) {
        $xmlContent = Get-Content $TemplatePath -Raw
        Set-PrintConfiguration -PrinterName $FullName -PrintTicketXml $xmlContent
        Write-Host "Successfully applied $TemplateFile to $FullName" -ForegroundColor Green
    } else {
        Write-Warning "Template $TemplatePath not found! Looking in: $TemplateDir"
    }
}

Write-Host "`nAll printers for $BaseName have been created." -ForegroundColor Green
