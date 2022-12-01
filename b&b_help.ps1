<#
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form;
$form.Text = "B&B Help Tool";
$form.Size = New-Object System.Drawing.Size(330, 210); ;
$form.StartPosition = "CenterScreen";

$okButton = New-Object System.Windows.Forms.Button;
$okButton.Location = New-Object System.Drawing.Point(75, 140);
$okButton.Size = New-Object System.Drawing.Size(75, 23);
$okButton.Text = "OK";
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK;
$form.AcceptButton = $okButton;
$form.Controls.Add($okButton);

$cancelButton = New-Object System.Windows.Forms.Button;
$cancelButton.Location = New-Object System.Drawing.Point(150, 140);
$cancelButton.Size = New-Object System.Drawing.Size(75, 23);
$cancelButton.Text = "Cancel";
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel;
$form.CancelButton = $cancelButton;
$form.Controls.Add($cancelButton);

$label = New-Object System.Windows.Forms.Label;
$label.Location = New-Object System.Drawing.Point(10, 10);
$label.Size = New-Object System.Drawing.Size(280, 30);
$form.Controls.Add($label);

$listBox = New-Object System.Windows.Forms.ListBox;
$listBox.Location = New-Object System.Drawing.Point(10, 50);
$listBox.Size = New-Object System.Drawing.Size(290, 20);
$listBox.Height = 80;
$listBox.Font = [System.Drawing.Font]::new($listBox.Font.FontFamily.Name, 12);
$ListBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawVariable
$ListBox.ItemHeight = 20;

$ListBox.add_DrawItem({
        param([object]$s, [System.Windows.Forms.DrawItemEventArgs]$e)

        if ($e.Index -gt -1) {
            <# If the item is selected set the background color to SystemColors.Highlight
            or else set the color to either WhiteSmoke or White depending if the item index is even or odd #>
            $color = if (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected) {
                [System.Drawing.SystemColors]::Highlight
            }
            else {
                if ($e.Index % 2 -eq 0) {
                    [System.Drawing.Color]::FromArgb(200, 200, 200)
                }
                else {
                    [System.Drawing.Color]::White
                }
            }

            # Background item brush
            $backgroundBrush = New-Object System.Drawing.SolidBrush $color
            # Text color brush
            $textBrush = New-Object System.Drawing.SolidBrush $e.ForeColor

            # Draw the background
            $e.Graphics.FillRectangle($backgroundBrush, $e.Bounds)
            # Draw the text
            $e.Graphics.DrawString($s.Items[$e.Index], $e.Font, $textBrush, $e.Bounds.Left, $e.Bounds.Top, [System.Drawing.StringFormat]::GenericDefault)
            # Clean up
            $backgroundBrush.Dispose()
            $textBrush.Dispose()
        }
        $e.DrawFocusRectangle()
    })

$form.Controls.Add($listBox);
$form.Topmost = $true;

$label.Text = "What would you like to do?:";
[void] $listBox.Items.Add("Generate Bug Report Info");
[void] $listBox.Items.Add("Rollback Save");
[void] $listBox.Items.Add("Nuke User Files");
$listBox.SetSelected(0, $true);

if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::Cancel) {
    exit
}

switch ($listBox.SelectedIndex) {
    #Generate Bug Report Info
    0 {
        $userfiles = Get-Childitem -Path "$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/" -File |
        Where-Object { $_.FullName -match 'Save?' -or $_.FullName -match "Player(-prev)?.log" };

        try {
            Start-Process -Wait msinfo32.exe -ArgumentList "/Report", "msinfo.txt";
            $userfiles += "msinfo.txt";
            $userfiles | Compress-Archive -DestinationPath "b&b_bug_report_info.zip" -Force;
            Remove-Item "msinfo.txt";

            [System.Windows.MessageBox]::Show("Please attach the file named ""b&b_bug_report_info.zip"" to your bug report!", "Done", [System.Windows.MessageBoxButton]::Ok, [System.Windows.MessageBoxImage]::None) | Out-Null;
        }
        catch {
            [System.Windows.MessageBox]::Show("An error has occurred:`n`n$_", "Error", [System.Windows.MessageBoxButton]::Ok, [System.Windows.MessageBoxImage]::Error) | Out-Null;

        }
    }

    #Rollback Save
    1 {
        $label.Text = "Please select a slot:";
        $listBox.Items.Clear();
        [void] $listBox.Items.Add("Top");
        [void] $listBox.Items.Add("Middle");
        [void] $listBox.Items.Add("Bottom");
        $listBox.SetSelected(0, $true);

        if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::Cancel) {
            exit
        }

        $slot = $listBox.SelectedIndex.ToString();

        $label.Text = "Please select a rollback:";
        $listBox.Items.Clear();
        $rollbackFileIndexMap = @{};
        $rollbackIndexFileMap = @{};

        #find and add all rollbacks to list
        if (Test-Path -Path ( -join ("$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/Save", "$slot", "Rollbacks")) -PathType Container) {
            Get-ChildItem -Path ( -join ("$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/Save", "$slot", "Rollbacks")) -File |
            Sort-Object LastWriteTime -Descending |
            ForEach-Object {
                $rollbackFileIndexMap[$_.Name] = $listBox.Items.Count;
                $rollbackIndexFileMap[$listBox.Items.Count] = $_.Name;
                [void] $listBox.Items.Add(( -Join ($_.Name, " - ", $_.LastWriteTime)));
            };
        }

        if ($listBox.Items.Count -lt 1) {
            [System.Windows.MessageBox]::Show("No rollbacks found for slot", "Error", [System.Windows.MessageBoxButton]::Ok, [System.Windows.MessageBoxImage]::Error) | Out-Null;
            exit
        }

        $listBox.SetSelected(0, $true);

        #default selection to older than current save file if found
        if (Test-Path -Path "$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/Save$slot" -PathType Leaf) {
            $lasttime = (Get-Item "$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/Save$slot").LastWriteTime;
            $label.Text = -Join ("Save Date: ", $lasttime.ToString(), "`nPlease select a rollback:");

            $rollbackfile = (Get-ChildItem -Path ( -join ("$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/Save", "$slot", "Rollbacks")) -File |
                Where-Object { $_.LastWriteTime -lt $lasttime } |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1).Name;

            if ($rollbackfile) {
                $listBox.SetSelected($rollbackFileIndexMap[$rollbackfile], $true);
            }
        }

        if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::Cancel) {
            exit
        }

        try {
            Copy-Item -Path ( -join ("$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/Save", "$slot", "Rollbacks/", $rollbackIndexFileMap[$listBox.SelectedIndex])) -Destination "$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/Save$slot" -Force -errorAction stop;
            [System.Windows.MessageBox]::Show("You can now start the game", "Done", [System.Windows.MessageBoxButton]::Ok, [System.Windows.MessageBoxImage]::None) | Out-Null;
        }
        catch {
            [System.Windows.MessageBox]::Show("An error has occurred:`n`n$_", "Error", [System.Windows.MessageBoxButton]::Ok, [System.Windows.MessageBoxImage]::Error) | Out-Null;
        }
    }

    #Nuke User Files
    2 {
        if ([System.Windows.MessageBox]::Show("This will delete all save files and settings, except save rollbacks, continue?", "Are you sure?",
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "Yes") {
            try {
                New-PSDrive -Name Uninstall -PSProvider Registry -Root HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Out-Null;
                $game = Get-ChildItem -Path Uninstall: | Where-Object { $_.GetValue("DisplayName") -eq "Bear and Breakfast" };

                # if game is on steam, we have to do this to workaround steam cloud
                if (($game -ne $null) -And ($game.Name.ToLower().Contains("steam"))) {
                    # we start the game so cloud sync will not redownload the broken files
                    Start-Process "steam://rungameid/1136370"
                    # we then wait for the game to start running to make sure cloud sync is done
                    do { $ProcessActive = Get-Process "BearAndBreakfast" -ErrorAction SilentlyContinue }
                    while ($ProcessActive -eq $null)
                }
            }
            catch {}

            try {
                # we MUST delete all the files, even clearning the size to 0 will break the game
                Get-Childitem -Path "$env:APPDATA/../LocalLow/GummyCat/BearAndBreakfast/" -File | Foreach-Object { Remove-Item -Force $_.FullName };
            }
            catch {
                [System.Windows.MessageBox]::Show("An error has occurred:`n`n$_", "Error", [System.Windows.MessageBoxButton]::Ok, [System.Windows.MessageBoxImage]::Error) | Out-Null;
            }
        }
    }
}
