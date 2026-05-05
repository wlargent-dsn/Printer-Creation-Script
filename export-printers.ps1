# Export Printers Script
Add-Type -AssemblyName System.Windows.Forms

# Confirm export
$result = [System.Windows.Forms.MessageBox]::Show("Do you want to export the list of printers with their IP addresses?", "Export Printers", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
    exit
}

# Get printers
$printers = Get-Printer

# Collect data
$exportData = @()
foreach ($printer in $printers) {
    $port = Get-PrinterPort -Name $printer.PortName
    $exportData += [PSCustomObject]@{
        'Printer Name' = $printer.Name
        'IP Address'   = $port.PrinterHostAddress
    }
}

# Save file dialog
$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
$saveFileDialog.Filter = "CSV files (*.csv)|*.csv"
$saveFileDialog.Title = "Save exported printers"
$saveFileDialog.FileName = "printers_export.csv"
if ($saveFileDialog.ShowDialog() -eq 'OK') {
    $exportPath = $saveFileDialog.FileName
    $exportData | Export-Csv -Path $exportPath -NoTypeInformation
    [System.Windows.Forms.MessageBox]::Show("Printers exported to $exportPath", "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
} else {
    [System.Windows.Forms.MessageBox]::Show("Export cancelled.", "Cancelled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}