function FilterListBox {
    param(
        [string]$filterText,
        [System.Windows.Forms.ListBox]$listBox,
        [string[]]$originalItems
    )

    $listBox.Items.Clear()

    foreach ($item in $originalItems) {
        if ($item -like "*$filterText*") {
            $listBox.Items.Add($item)
        }
    }
}

function RenderEditGameForm($GamesList) {

    $editGameForm = CreateForm "Gaming Gaiden: Edit Game" 880 265 ".\icons\running.ico"

    $imagePath = "./icons/default.png"
	
    # Hidden fields to save non user editable values
    $pictureBoxImagePath = CreateTextBox $imagePath 879 264 1 1; $pictureBoxImagePath.hide(); $editGameForm.Controls.Add($pictureBoxImagePath)
    $textOriginalGameName = CreateTextBox "" 879 264 1 1; $textOriginalGameName.hide(); $editGameForm.Controls.Add($textOriginalGameName)
    # Hidden fields end
	
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(585, 60)
    $listBox.Size = New-Object System.Drawing.Size(260, 20)
    $listBox.Height = 150
    [void] $listBox.Items.AddRange($GamesList)

    $labelSearch = Createlabel "Search:" 585 20; $editGameForm.Controls.Add($labelSearch)
    $textSearch = CreateTextBox "" 645 20 200 20; $editGameForm.Controls.Add($textSearch)

    $textSearch.Add_TextChanged({
        FilterListBox -filterText $textSearch.Text -listBox $listBox -originalItems $GamesList
    })

    $labelName = Createlabel "Name:" 170 20; $editGameForm.Controls.Add($labelName)
    $textName = CreateTextBox "" 245 20 300 20;	$editGameForm.Controls.Add($textName)

    $labelExe = Createlabel "Exe:" 170 60; $editGameForm.Controls.Add($labelExe)
    $textExe = CreateTextBox "" 245 60 200 20; $textExe.ReadOnly = $true; $editGameForm.Controls.Add($textExe)

    $labelPlatform = Createlabel "Platform:" 170 100; $editGameForm.Controls.Add($labelPlatform)
    $textPlatform = CreateTextBox "" 245 100 200 20; $editGameForm.Controls.Add($textPlatform)

    $labelPlayTime = Createlabel "PlayTime:" 170 140; $editGameForm.Controls.Add($labelPlayTime)
    $textPlayTime = CreateTextBox "" 245 140 200 20; $editGameForm.Controls.Add($textPlayTime)

    $checkboxCompleted = New-Object Windows.Forms.CheckBox
    $checkboxCompleted.Text = "Finished"
    $checkboxCompleted.Top = 140
    $checkboxCompleted.Left = 470
    $editGameForm.Controls.Add($checkboxCompleted)

    $labelPictureBox = Createlabel "Game Icon" 57 165; $editGameForm.Controls.Add($labelPictureBox)
    $pictureBox = CreatePictureBox $imagePath 15 20 140 140
    $editGameForm.Controls.Add($pictureBox)

    $listBox.Add_SelectedIndexChanged({
        $selectedGame = GetGameDetails $listBox.SelectedItem
    
        $textName.Text = $selectedGame.name
        $textOriginalGameName.Text = $selectedGame.name
        $textExe.Text = ($selectedGame.exe_name + ".exe")
        $textPlatform.Text = $selectedGame.platform
        $checkboxCompleted.Checked = ($selectedGame.completed -eq 'TRUE')

        $playTimeString = PlayTimeMinsToString $selectedGame.play_time
        $textPlayTime.Text = $playTimeString

        $iconFileName = ToBase64 $selectedGame.name
        $imagePath = "$env:TEMP\GG-{0}-$iconFileName.png" -f $(Get-Random)
        $iconBitmap = BytesToBitmap $selectedGame.icon
        $iconBitmap.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Png)
        $imagePath = ResizeImage -ImagePath $imagePath -GameName $selectedGame.name
        $iconBitmap.Dispose()

        $pictureBoxImagePath.Text = $imagePath
        $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)

    })
    $editGameForm.Controls.Add($listBox)

    $buttonSearchIcon = CreateButton "Search" 20 185
    $buttonSearchIcon.Size = New-Object System.Drawing.Size(60, 23)
    $buttonSearchIcon.Add_Click({
        $gameName = $textName.Text
        if ($gameName -eq "") { 
            ShowMessage "Please enter a name first." "OK" "Error"
            return
        }
        $gameNameEncoded = $gameName -replace " ", "+"
        Start-Process "https://www.google.com/search?as_q=Cover+Art+$gameNameEncoded+Game&imgar=s&udm=2"
    })
    $editGameForm.Controls.Add($buttonSearchIcon)

    $buttonUpdateIcon = CreateButton "Update" 90 185
    $buttonUpdateIcon.Size = New-Object System.Drawing.Size(60, 23)
    $buttonUpdateIcon.Add_Click({
        $downloadsDirectoryPath = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path
        $openFileDialog = OpenFileDialog "Select Game Icon File" 'Image (*.png, *.jpg, *.jpeg)|*.png;*.jpg;*.jpeg' $downloadsDirectoryPath
        $result = $openFileDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $imagePath = ResizeImage $openFileDialog.FileName $textName.name
            $pictureBoxImagePath.Text = $imagePath
            $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)
        }
    })
    $editGameForm.Controls.Add($buttonUpdateIcon)

    $buttonUpdateExe = CreateButton "Edit Exe" 470 60
    $buttonUpdateExe.Add_Click({
        $openFileDialog = OpenFileDialog "Select Executable" 'Executable (*.exe)|*.exe'
        $result = $openFileDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $textExe.Text = (Get-Item $openFileDialog.FileName).Name
        }
    })
    $editGameForm.Controls.Add($buttonUpdateExe)

    $buttonRemove = CreateButton "Delete" 470 100
    $buttonRemove.Add_Click({
        $gameName = $textName.Text
        $userInput = UserConfirmationDialog "Confirm Game Removal" "All Data about '$gameName' will be lost.`r`nAre you sure?"
        if ($userInput.ToLower() -eq 'yes')	{
            RemoveGame $gameName
            ShowMessage "Removed '$gameName' from Database." "OK" "Asterisk"
            Log "Removed '$gameName' from Database."
        }

        $gamesList = (RunDBQuery "SELECT name FROM games").name
        $listBox.Items.Clear(); $listBox.Items.AddRange($gamesList);
        $listBox.SelectedIndex = 0
    })
    $editGameForm.Controls.Add($buttonRemove)

    $buttonOK = CreateButton "OK" 245 185
    $buttonOK.Add_Click({
        if ($textName.Text -eq "" -Or $textPlatform.Text -eq "" -Or $textPlayTime.Text -eq "")	{
            ShowMessage "Name, Platform, Playtime fields cannot be empty. Try Again." "OK" "Error"
            return
        }

        $gameName = $textName.Text

        $playTimeInMin = PlayTimeStringToMin $textPlayTime.Text
        if ($null -eq $playTimeInMin) {
            ShowMessage "Incorrect Playtime Format. Enter exactly 'x Hr y Min'. Resetting PlayTime" "OK" "Error"
            $textPlayTime.Text = $playTimeString
            return
        }

        $gameExeName = $textExe.Text -replace ".exe"

        $gameCompleteStatus = if ($checkboxCompleted.Checked) { "TRUE" } else { "FALSE" }
    
        UpdateGameOnEdit -OriginalGameName $textOriginalGameName.Text -GameName $gameName -GameExeName $gameExeName -GameIconPath $pictureBoxImagePath.Text -GamePlayTime $playTimeInMin -GameCompleteStatus $gameCompleteStatus -GamePlatform $textPlatform.Text

        ShowMessage "Updated '$gameName' in Database." "OK" "Asterisk"

        $gamesList = (RunDBQuery "SELECT name FROM games").name
        $listBox.Items.Clear(); $listBox.Items.AddRange($gamesList); 
        $listBox.SelectedIndex = $listBox.FindString($gameName)
    })
    $editGameForm.Controls.Add($buttonOK)

    $buttonCancel = CreateButton "Cancel" 370 185; $buttonCancel.Add_Click({ $editGameForm.Close() }); $editGameForm.Controls.Add($buttonCancel)
	
    #Select the first game to populate the form before rendering for first time
    $listBox.SelectedIndex = 0
	
    $editGameForm.ShowDialog()
    $editGameForm.Dispose()
}

function RenderEditPlatformForm($PlatformsList) {

    $editPlatformForm =	CreateForm "Gaming Gaiden: Edit Platform" 655  330 ".\icons\running.ico"

    # Hidden fields to save non user editable values
    $textOriginalPlatformName = CreateTextBox "" 654 329 1 1; $textOriginalPlatformName.hide(); $editPlatformForm.Controls.Add($textOriginalPlatformName)
    # Hidden fields end

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(400, 65)
    $listBox.Size = New-Object System.Drawing.Size(225, 20)
    $listBox.Height = 212
    [void] $listBox.Items.AddRange($PlatformsList)

    $labelSearch = Createlabel "Search:" 400 20; $editPlatformForm.Controls.Add($labelSearch)
    $textSearch = CreateTextBox "" 465 20 160 20; $editPlatformForm.Controls.Add($textSearch)

    $textSearch.Add_TextChanged({
            FilterListBox -filterText $textSearch.Text -listBox $listBox -originalItems $PlatformsList
        })
	
    $labelName = Createlabel "Platorm:" 10 20; $editPlatformForm.Controls.Add($labelName)
    $textName = CreateTextBox "" 75 20 200 20; $editPlatformForm.Controls.Add($textName)

    $labelExe = Createlabel "Emulator`nExe List:" 10 79; $editPlatformForm.Controls.Add($labelExe)
    $textExe = CreateTextBox "" 75 82 200 20; $textExe.ReadOnly = $true; $editPlatformForm.Controls.Add($textExe)

    $labelRomExt = Createlabel "Rom Extns:" 10 146;	$editPlatformForm.Controls.Add($labelRomExt)
    $textRomExt = CreateTextBox "" 75 144 200 20;	$editPlatformForm.Controls.Add($textRomExt)

    $labelCores = Createlabel "Cores:" 10 208; $editPlatformForm.Controls.Add($labelCores)
    $textCore = CreateTextBox "" 75 206 200 20;	$textCore.ReadOnly = $true;	$editPlatformForm.Controls.Add($textCore)

    $listBox.Add_SelectedIndexChanged({
        $selectedPlatform = GetPlatformDetails $listBox.SelectedItem

        $textName.Text = $selectedPlatform.name
        $textOriginalPlatformName.Text = $selectedPlatform.name
        $textRomExt.Text = $selectedPlatform.rom_extensions

        $exeList = ($selectedPlatform.exe_name -replace "," , ".exe,") + ".exe"
        $textExe.Text = $exeList

        $hasCore = -Not ($selectedPlatform.core -eq "")

        if ($hasCore) {
            $textCore.Text = $selectedPlatform.core

            $buttonUpdateCore.show()
            $labelCores.show()
            $textCore.show()

            $editPlatformForm.Size = New-Object System.Drawing.Size(655, 330)
            $listBox.Height = 212
            $buttonOK.Location = New-Object System.Drawing.Point(85, 254)
            $buttonCancel.Location = New-Object System.Drawing.Point(210, 254)
        }
        else {
            $buttonUpdateCore.hide()
            $labelCores.hide()
            $textCore.Text = ""; $textCore.hide()

            $editPlatformForm.Size = New-Object System.Drawing.Size(655, 277)
            $listBox.Height = 166
            $buttonOK.Location = New-Object System.Drawing.Point(85, 201)
            $buttonCancel.Location = New-Object System.Drawing.Point(210, 201)
        }
    })
    $editPlatformForm.Controls.Add($listBox)
	
    $buttonUpdateCore = CreateButton "Edit Core" 300 204
    $buttonUpdateCore.Add_Click({
        $openFileDialog = OpenFileDialog "Select Retroarch Core" 'DLL (*.dll)|*.dll'
        $result = $openFileDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $textCore.Text = (Get-Item $openFileDialog.FileName).Name
        }
    })
    $editPlatformForm.Controls.Add($buttonUpdateCore)

    $buttonUpdateExe = CreateButton "Add Exe" 300 65
    $buttonUpdateExe.Add_Click({
        $openFileDialog = OpenFileDialog "Select Executable" 'Executable (*.exe)|*.exe'
        $result = $openFileDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $existingExes = $textExe.Text
            $selectedExe = (Get-Item $openFileDialog.FileName).Name
            if ($existingExes -eq "") {
                $textExe.Text = $selectedExe
            }
            else {
                $textExe.Text = ("$existingExes,$selectedExe" -split ',' | Select-Object -Unique ) -join ','
            }
        }
    })
    $editPlatformForm.Controls.Add($buttonUpdateExe)

    $buttonClearExe = CreateButton "Clear List" 300 95
    $buttonClearExe.Add_Click({
        $textExe.Text = ""
    })
    $editPlatformForm.Controls.Add($buttonClearExe)

    $buttonRemove = CreateButton "Delete" 300 18
    $buttonRemove.Add_Click({
        $platformName = $textName.Text
        $userInput = UserConfirmationDialog "Confirm Platform Removal" "All Data about '$platformName' will be lost.`r`nAre you sure?"
        if ($userInput.ToLower() -eq 'yes')	{
            RemovePlatform $platformName
            ShowMessage "Removed '$platformName' from Database." "OK" "Asterisk"
            Log "Removed '$platformName' from Database."
        }

        $platformsList = (RunDBQuery "SELECT name FROM emulated_platforms").name
        $listBox.Items.Clear(); $listBox.Items.AddRange($platformsList);
        $listBox.SelectedIndex = 0
    })
    $editPlatformForm.Controls.Add($buttonRemove)

    $buttonOK = CreateButton "OK" 85 254
    $buttonOK.Add_Click({
        if ($textRomExt.Text -eq "" -Or $textExe.Text -eq "") {
            ShowMessage "Exe List or Rom Extensions field cannot be empty.`r`nTry again." "OK" "Error"
            return
        }

        $platformRomExtensions = $textRomExt.Text
        if (-Not ($platformRomExtensions -match '^([a-z]{3},)*([a-z]{3}){1}$')) {
            ShowMessage "Error in rom extensions. Please submit extensions as a ',' separated list without the leading '.'`r`ne.g. zip,iso,chd OR zip,iso OR zip" "OK" "Error"
            return
        }

        $platformName = $textName.Text
        $emulatorExeList = $textExe.Text -replace ".exe"
    
        UpdatePlatformOnEdit -OriginalPlatformName $textOriginalPlatformName.Text -PlatformName $platformName -EmulatorExeList $emulatorExeList -EmulatorCore $textCore.Text -PlatformRomExtensions $platformRomExtensions

        ShowMessage "Updated '$platformName' in Database." "OK" "Asterisk"

        $platformsList = (RunDBQuery "SELECT name FROM emulated_platforms").name
        $listBox.Items.Clear(); $listBox.Items.AddRange($platformsList);
        $listBox.SelectedIndex = $listBox.FindString($platformName)
    })
    $editPlatformForm.Controls.Add($buttonOK)

    $buttonCancel = CreateButton "Cancel" 210 254;	$buttonCancel.Add_Click({ $editPlatformForm.Close() });	$editPlatformForm.Controls.Add($buttonCancel)

    #Select the first platform to populate the form before rendering for first time
    $listBox.SelectedIndex = 0

    $editPlatformForm.ShowDialog()
    $editPlatformForm.Dispose()
}

function RenderAddGameForm() {
    $addGameForm =	CreateForm "Gaming Gaiden: Add Game" 580 265 ".\icons\running.ico"

    $labelName = Createlabel "Name:" 170 20; $addGameForm.Controls.Add($labelName)
    $textName = CreateTextBox "" 245 20 300 20;	$addGameForm.Controls.Add($textName)

    $labelExe = Createlabel "Exe:" 170 60; $addGameForm.Controls.Add($labelExe)
    $textExe = CreateTextBox "" 245 60 200 20; $textExe.ReadOnly = $true; $addGameForm.Controls.Add($textExe)

    $labelPlatform = Createlabel "Platform:" 170 100; $addGameForm.Controls.Add($labelPlatform)
    $textPlatform = CreateTextBox "PC" 245 100 200 20; $textPlatform.ReadOnly = $true; $addGameForm.Controls.Add($textPlatform)

    $labelPlayTime = Createlabel "PlayTime:" 170 140; $addGameForm.Controls.Add($labelPlayTime)
    $textPlayTime = CreateTextBox "0 Hr 0 Min" 245 140 200 20; $textPlayTime.ReadOnly = $true; $addGameForm.Controls.Add($textPlayTime)

    $buttonSearchIcon = CreateButton "Search" 20 185
    $buttonSearchIcon.Size = New-Object System.Drawing.Size(60, 23)
    $buttonSearchIcon.Add_Click({
        $gameName = $textName.Text
        if ($gameName -eq "") { 
            ShowMessage "Please enter a name first." "OK" "Error"
            return
        }
        $gameNameEncoded = $gameName -replace " ", "+"
        Start-Process "https://www.google.com/search?as_q=Cover+Art+$gameNameEncoded+Game&imgar=s&udm=2"
    })
    $addGameForm.Controls.Add($buttonSearchIcon)

    $imagePath = "./icons/default.png"
    $pictureBoxImagePath = CreateTextBox $imagePath 579 254 1 1; $pictureBoxImagePath.hide(); $addGameForm.Controls.Add($pictureBoxImagePath)
	
    $pictureBox = CreatePictureBox $imagePath 15 20 140 140
    $addGameForm.Controls.Add($pictureBox)

    $labelPictureBox = Createlabel "Game Icon" 57 165; $addGameForm.Controls.Add($labelPictureBox)

    $buttonUpdateIcon = CreateButton "Update" 90 185
    $buttonUpdateIcon.Size = New-Object System.Drawing.Size(60, 23)
    $buttonUpdateIcon.Add_Click({
        $downloadsDirectoryPath = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path
        $openFileDialog = OpenFileDialog "Select Game Icon File" 'Image (*.png, *.jpg, *.jpeg)|*.png;*.jpg;*.jpeg' $downloadsDirectoryPath
        $result = $openFileDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $imagePath = ResizeImage $openFileDialog.FileName "GG-NEW_GAME.png"
            $pictureBoxImagePath.Text = $imagePath
            $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)
        }
    })
    $addGameForm.Controls.Add($buttonUpdateIcon)

    $buttonUpdateExe = CreateButton "Add Exe" 470 60
    $buttonUpdateExe.Add_Click({
        $openFileDialog = OpenFileDialog "Select Executable" 'Executable (*.exe)|*.exe'
        $result = $openFileDialog.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {	
            $textExe.Text = $openFileDialog.FileName
            $gameExeFile = Get-Item $textExe.Text
            $gameExeName = $gameExeFile.BaseName

            if ($textName.Text -eq "") { $textName.Text = $gameExeName }
        
            $entityFound = DoesEntityExists "games" "exe_name" $gameExeName
            if ($null -ne $entityFound) {
                ShowMessage "Another Game with Executable $gameExeName.exe already exists`r`nSee Games List." "OK" "Asterisk"
                $textExe.Text = ""
                return
            }

            $gameIconPath = "$env:TEMP\GG-{0}.png" -f $(Get-Random)
            $gameIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($gameExeFile)
            $gameIcon.ToBitmap().save($gameIconPath)
    
            $pictureBoxImagePath.Text = $gameIconPath
            $pictureBox.Image = [System.Drawing.Image]::FromFile($gameIconPath)

        }
    })
    $addGameForm.Controls.Add($buttonUpdateExe)

    $buttonOK = CreateButton "OK" 245 185
    $buttonOK.Add_Click({
        if ($textExe.Text -eq "" -Or $textName.Text -eq "" ) {
            ShowMessage "Name, Exe fields cannot be empty. Try Again." "OK" "Error"
            return
        }
        $gameName = $textName.Text
        $gameExeFile = Get-Item $textExe.Text
        $gameExeName = $gameExeFile.BaseName
        $gameIconPath = $pictureBoxImagePath.Text
        $gameLastPlayDate = (Get-Date -UFormat %s).Split('.').Get(0)

        SaveGame -GameName $gameName -GameExeName $gameExeName -GameIconPath $gameIconPath `
            -GamePlayTime 0 -GameIdleTime 0 -GameLastPlayDate $gameLastPlayDate -GameCompleteStatus 'FALSE' -GamePlatform 'PC' -GameSessionCount 0
        ShowMessage "Registered '$gameName' in Database." "OK" "Asterisk"

        $addGameForm.Close()
    })
    $addGameForm.Controls.Add($buttonOK)

    $buttonCancel = CreateButton "Cancel" 370 185; $buttonCancel.Add_Click({ $addGameForm.Close() }); $addGameForm.Controls.Add($buttonCancel)

    $addGameForm.ShowDialog()
    $addGameForm.Dispose()
}

function RenderAddPlatformForm() {
    $addPlatformForm =	CreateForm "Gaming Gaiden: Add Emulator" 405 275 ".\icons\running.ico"

    $labelName = Createlabel "Platorm:" 10 20; $addPlatformForm.Controls.Add($labelName)
    $textName = CreateTextBox "" 85 20 200 20; $addPlatformForm.Controls.Add($textName)

    $labelExe = Createlabel "Emulator`nExe List:" 10 79; $addPlatformForm.Controls.Add($labelExe)
    $textExe = CreateTextBox "" 85 82 200 20; $textExe.ReadOnly = $true; $addPlatformForm.Controls.Add($textExe)

    $labelRomExt = Createlabel "Rom Extns:" 10 146;	$addPlatformForm.Controls.Add($labelRomExt)
    $textRomExt = CreateTextBox "" 85 144 200 20; $addPlatformForm.Controls.Add($textRomExt)
	
    $labelCores = Createlabel "Core:" 10 208; $labelCores.hide(); $addPlatformForm.Controls.Add($labelCores)
    $textCore = CreateTextBox "" 85 206 200 20;	$textCore.ReadOnly = $true;	$textCore.hide(); $addPlatformForm.Controls.Add($textCore)

    $buttonAddCore = CreateButton "Add Core" 300 204; $buttonAddCore.hide()
    $buttonAddCore.Add_Click({
        $openFileDialog = OpenFileDialog "Select Retroarch Core" 'DLL (*.dll)|*.dll'
        $result = $openFileDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $textCore.Text = (Get-Item $openFileDialog.FileName).Name
        }
    })
    $addPlatformForm.Controls.Add($buttonAddCore)

    $buttonAddExe = CreateButton "Add Exe" 300 65
    $buttonAddExe.Add_Click({
        $openFileDialog = OpenFileDialog "Select Executable" 'Executable (*.exe)|*.exe'
        $result = $openFileDialog.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $existingExes = $textExe.Text

            $selectedExe = (Get-Item $openFileDialog.FileName).Name
            if ($existingExes -eq "") {
                $textExe.Text = $selectedExe
            }
            else {
                $textExe.Text = ("$existingExes,$selectedExe" -split ',' | Select-Object -Unique ) -join ','
            }

            $emulatorExeList = $textExe.Text
            if ($emulatorExeList.ToLower() -like "*retroarch*") {
                $addPlatformForm.Size = New-Object System.Drawing.Size(405, 325)
                $buttonOK.Location = New-Object System.Drawing.Point(85, 250)
                $buttonCancel.Location = New-Object System.Drawing.Point(210, 250)

                $labelCores.show()
                $textCore.show()
                $buttonAddCore.show()
                
                ShowMessage "Retroarch detected. Please Select Core for Platform." "OK" "Asterisk"
            }
        }
    })
    $addPlatformForm.Controls.Add($buttonAddExe)

    $buttonClearExe = CreateButton "Clear List" 300 95
    $buttonClearExe.Add_Click({
        $textExe.Text = ""
    })
    $addPlatformForm.Controls.Add($buttonClearExe)

    $buttonOK = CreateButton "OK" 85 200
    $buttonOK.Add_Click({
        if ($textExe.Text -eq "" -Or $textName.Text -eq "" -Or $textRomExt.Text -eq "")	{
            ShowMessage "Platform, Exe and Extensions fields cannot be empty.`r`nTry again." "OK" "Error"
            return
        }

        $emulatorExeList = $textExe.Text -replace ".exe"
        if ($emulatorExeList.ToLower() -like "*retroarch*") {
            if ($textCore.Text -eq "") {
                ShowMessage "Retroarch detected.`r`nYou must select Core for platform. Try again." "OK" "Error"
                return
            }
        }

        $platformName = $textName.Text
        $platformFound = DoesEntityExists "emulated_platforms" "name"  $platformName
        if ($null -ne $platformFound) {
            ShowMessage "Platform $platformName already exists.`r`nUse Edit Emulator setting to check existing platforms." "OK" "Error"
            return
        }

        $emulatorCore = $textCore.Text

        $exeCoreComboFound = CheckExeCoreCombo $emulatorExeList $emulatorCore
        if ($null -ne $exeCoreComboFound) {
            ShowMessage "Executables in the list '$emulatorExeList' is already registered with core '$emulatorCore'.`r`nCannot register another platform with same Exe and Core Combination.`r`nUse Edit Platform setting to check existing platforms." "OK" "Error"
            return
        }

        $platformRomExtensions = $textRomExt.Text
        if (-Not ($platformRomExtensions -match '^([a-z]{3},)*([a-z]{3}){1}$'))	{
            ShowMessage "Error in rom extensions. Please submit extensions as a ',' separated list without the leading '.'`r`ne.g. zip,iso,chd OR zip,iso OR zip" "OK" "Error"
            return
        }

        SavePlatform -PlatformName $platformName -EmulatorExeList $emulatorExeList -CoreName $emulatorCore -RomExtensions $platformRomExtensions

        ShowMessage "Registered '$platformName' in Database." "OK" "Asterisk"

        $addPlatformForm.Close()
    })
    $addPlatformForm.Controls.Add($buttonOK)

    $buttonCancel = CreateButton "Cancel" 210 200; $buttonCancel.Add_Click({ $addPlatformForm.Close() }); $addPlatformForm.Controls.Add($buttonCancel)

    $addPlatformForm.ShowDialog()
    $addPlatformForm.Dispose()
}