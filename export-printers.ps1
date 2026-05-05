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
    # Skip shared printers from other servers
    if ($printer.ComputerName -and $printer.ComputerName -ne $env:COMPUTERNAME) {
        continue
    }
    try {
        $port = Get-PrinterPort -Name $printer.PortName -ErrorAction Stop
        $ip = $port.PrinterHostAddress
        if (-not $ip) {
            $ip = "N/A"
        }
    } catch {
        $ip = "Port not found"
    }
    if ($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        # Valid IP, include
        $exportData += [PSCustomObject]@{
            'Printer Name' = $printer.Name
            'IP Address'   = $ip
        }
    } elseif ($ip -eq "N/A" -or $ip -eq "Port not found") {
        # No IP, prompt user
        $promptResult = [System.Windows.Forms.MessageBox]::Show("Printer '$($printer.Name)' has no IP address. Do you want to enter an IP address to include it?", "Enter IP", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($promptResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            $inputBox = New-Object System.Windows.Forms.Form
            $inputBox.Text = "Enter IP Address for $($printer.Name)"
            $inputBox.Size = New-Object System.Drawing.Size(300,150)
            $inputBox.StartPosition = "CenterScreen"
            
            $label = New-Object System.Windows.Forms.Label
            $label.Text = "IP Address:"
            $label.Location = New-Object System.Drawing.Point(10,20)
            $label.Size = New-Object System.Drawing.Size(100,20)
            $inputBox.Controls.Add($label)
            
            $textBox = New-Object System.Windows.Forms.TextBox
            $textBox.Location = New-Object System.Drawing.Point(10,40)
            $textBox.Size = New-Object System.Drawing.Size(260,20)
            $inputBox.Controls.Add($textBox)
            
            $okButton = New-Object System.Windows.Forms.Button
            $okButton.Text = "OK"
            $okButton.Location = New-Object System.Drawing.Point(75,70)
            $okButton.Size = New-Object System.Drawing.Size(75,23)
            $okButton.Add_Click({ $inputBox.Tag = $textBox.Text; $inputBox.Close() })
            $inputBox.Controls.Add($okButton)
            
            $cancelButton = New-Object System.Windows.Forms.Button
            $cancelButton.Text = "Cancel"
            $cancelButton.Location = New-Object System.Drawing.Point(150,70)
            $cancelButton.Size = New-Object System.Drawing.Size(75,23)
            $cancelButton.Add_Click({ $inputBox.Tag = $null; $inputBox.Close() })
            $inputBox.Controls.Add($cancelButton)
            
            $inputBox.ShowDialog()
            $enteredIP = $inputBox.Tag
            if ($enteredIP -and $enteredIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                $exportData += [PSCustomObject]@{
                    'Printer Name' = $printer.Name
                    'IP Address'   = $enteredIP
                }
            }
        }
        # If no, skip
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