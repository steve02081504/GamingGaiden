function SaveGame(){
    param(
        [string]$GameName,
        [string]$GameExeName,
		[string]$GameIconPath,
		[string]$GamePlayTime,
        [string]$GameIdleTime,
        [string]$GameLastPlayDate,
        [string]$GameCompleteStatus,
        [string]$GamePlatform,
        [string]$GameSessionCount
    )

    $GameIconBytes = (Get-Content -Path $GameIconPath -Encoding byte -Raw);

    $AddGameQuery = "INSERT INTO games (name, exe_name, icon, play_time, idle_time, last_play_date, completed, platform, session_count)" +
						"VALUES (@GameName, @GameExeName, @GameIconBytes, @GamePlayTime, @GameIdleTime, @GameLastPlayDate, @GameCompleteStatus, @GamePlatform, @GameSessionCount)"

	Log "Adding $GameName in Database"
    RunDBQuery $AddGameQuery @{
        GameName = $GameName.Trim()
        GameExeName = $GameExeName.Trim()
		GameIconBytes = $GameIconBytes
        GamePlayTime = $GamePlayTime
        GameIdleTime = $GameIdleTime
        GameLastPlayDate = $GameLastPlayDate
        GameCompleteStatus = $GameCompleteStatus
        GamePlatform = $GamePlatform.Trim()
        GameSessionCount = $GameSessionCount
    }
}

function SavePlatform(){
    param(
        [string]$PlatformName,
        [string]$EmulatorExeList,
		[string]$CoreName,
		[string]$RomExtensions
    )

    $AddPlatformQuery = "INSERT INTO emulated_platforms (name, exe_name, core, rom_extensions)" +
                                    "VALUES (@PlatformName, @EmulatorExeList, @CoreName, @RomExtensions)"

    Log "Adding $PlatformName in database"
    RunDBQuery $AddPlatformQuery @{
        PlatformName = $PlatformName.Trim()
        EmulatorExeList = $EmulatorExeList.Trim()
        CoreName = $CoreName.Trim()
        RomExtensions = $RomExtensions.Trim()
    }
}

function UpdateGameOnSession() {
	param(
        [string]$GameName,
        [string]$GamePlayTime,
        [string]$GameIdleTime,
        [string]$GameLastPlayDate
    )

	$GameNamePattern = SQLEscapedMatchPattern($GameName.Trim())

    $GetSessionCountQuery = "SELECT session_count FROM games WHERE name LIKE '{0}'" -f $GameNamePattern
    $CurrentSessionCount = (RunDBQuery $GetSessionCountQuery).session_count

    $NewSessionCount = $CurrentSessionCount + 1

	$UpdateGamePlayTimeQuery = "UPDATE games SET play_time = @UpdatedPlayTime, idle_time = @UpdatedIdleTime, last_play_date = @UpdatedLastPlayDate, session_count = @GameSessionCount WHERE name LIKE '{0}'" -f $GameNamePattern

    Log "Updating $GameName play time to $GamePlayTime min and idle time to $GameIdleTime min in database"
    Log "Updating session count from $CurrentSessionCount to $NewSessionCount in database"

	RunDBQuery $UpdateGamePlayTimeQuery @{ 
		UpdatedPlayTime = $GamePlayTime
        UpdatedIdleTime = $GameIdleTime
		UpdatedLastPlayDate = $GameLastPlayDate
        GameSessionCount = $NewSessionCount
	}
}

function UpdateGameOnEdit() {
    param(
        [string]$OriginalGameName,
        [string]$GameName,
        [string]$GameExeName,
		[string]$GameIconPath,
		[string]$GamePlayTime,
        [string]$GameCompleteStatus,
        [string]$GamePlatform
    )

    $GameIconBytes = (Get-Content -Path $GameIconPath -Encoding byte -Raw);

	$GameNamePattern = SQLEscapedMatchPattern($OriginalGameName.Trim())

    if ( $OriginalGameName -eq $GameName) {
        $UpdateGameQuery = "UPDATE games SET exe_name = @GameExeName, icon = @GameIconBytes, play_time = @GamePlayTime, completed = @GameCompleteStatus, platform = @GamePlatform WHERE name LIKE '{0}'" -f $GameNamePattern
        
        Log "Editing $GameName in database"
        RunDBQuery $UpdateGameQuery @{
            GameExeName = $GameExeName.Trim()
            GameIconBytes = $GameIconBytes
            GamePlayTime = $GamePlayTime
            GameCompleteStatus = $GameCompleteStatus
            GamePlatform = $GamePlatform.Trim()
        }
    }
    else {
        Log "User changed game's name from $OriginalGameName to $GameName. Need to delete the game and add it again"

        $GetSessionCountQuery = "SELECT session_count FROM games WHERE name LIKE '{0}'" -f $GameNamePattern
        $GameSessionCount = (RunDBQuery $GetSessionCountQuery).session_count

        $GetIdleTimeQuery = "SELECT idle_time FROM games WHERE name LIKE '{0}'" -f $GameNamePattern
        $GameIdleTime = (RunDBQuery $GetIdleTimeQuery).idle_time

        $GetLastPlayDateQuery = "SELECT last_play_date FROM games WHERE name LIKE '{0}'" -f $GameNamePattern
        $GameLastPlayDate = (RunDBQuery $GetLastPlayDateQuery).last_play_date

        RemoveGame($OriginalGameName)
        SaveGame -GameName $GameName -GameExeName $GameExeName -GameIconPath $GameIconPath `
	 			-GamePlayTime $GamePlayTime -GameIdleTime $GameIdleTime -GameLastPlayDate $GameLastPlayDate -GameCompleteStatus $GameCompleteStatus -GamePlatform $GamePlatform -GameSessionCount $GameSessionCount
    }
}
 
function  UpdatePlatformOnEdit() {
    param(
        [string]$OriginalPlatformName,
        [string]$PlatformName,
        [string]$EmulatorExeList,
		[string]$EmulatorCore,
		[string]$PlatformRomExtensions
    )

	$PlatformNamePattern = SQLEscapedMatchPattern($OriginalPlatformName.Trim())

    if ( $OriginalPlatformName -eq $PlatformName) {

        $UpdatePlatformQuery = "UPDATE emulated_platforms set exe_name = @EmulatorExeList, core = @EmulatorCore, rom_extensions = @PlatformRomExtensions WHERE name LIKE '{0}'" -f $PlatformNamePattern

        Log "Editing $PlatformName in database"
        RunDBQuery $UpdatePlatformQuery @{
            EmulatorExeList = $EmulatorExeList
            EmulatorCore = $EmulatorCore
            PlatformRomExtensions = $PlatformRomExtensions.Trim()
        }
    } else {
        Log "User changed platform's name from $OriginalPlatformName to $PlatformName. Need to delete the platform and add it again"
        Log "All games mapped to $OriginalPlatformName will be updated to platform $PlatformName"

        RemovePlatform($OriginalPlatformName)

        SavePlatform -PlatformName $PlatformName -EmulatorExeList $EmulatorExeList -CoreName $EmulatorCore -RomExtensions $PlatformRomExtensions

        $UpdateGamesPlatformQuery = "UPDATE games SET platform = @PlatformName WHERE platform LIKE '{0}'" -f $PlatformNamePattern

        RunDBQuery $UpdateGamesPlatformQuery @{ PlatformName = $PlatformName }
    }
}

function RemoveGame($GameName) {
    $GameNamePattern = SQLEscapedMatchPattern($GameName.Trim())
    $RemoveGameQuery = "DELETE FROM games WHERE name LIKE '{0}'" -f $GameNamePattern

    Log "Removing $GameName from database"
    RunDBQuery $RemoveGameQuery
}

function RemovePlatform($PlatformName) {
    $PlatformNamePattern = SQLEscapedMatchPattern($PlatformName.Trim())
    $RemovePlatformQuery = "DELETE FROM emulated_platforms WHERE name LIKE '{0}'" -f $PlatformNamePattern

    Log "Removing $PlatformName from database"
    RunDBQuery $RemovePlatformQuery
}

function RecordPlaytimOnDate($PlayTime) {
    $ExistingPlayTimeQuery = "SELECT play_time FROM daily_playtime WHERE play_date like DATE('now')"

    $ExistingPlayTime = (RunDBQuery $ExistingPlayTimeQuery).play_time
    
    $RecordPlayTimeQuery = ""
    if ($null -eq $ExistingPlayTime)
    {
        $RecordPlayTimeQuery = "INSERT INTO daily_playtime(play_date, play_time) VALUES (DATE('now'), {0})" -f $PlayTime
    }
    else
    {
        $UpdatedPlayTime = $PlayTime + $ExistingPlayTime

        $RecordPlayTimeQuery = "UPDATE daily_playtime SET play_time = {0} WHERE play_date like DATE('now')" -f $UpdatedPlayTime
    }

    Log "Updating playTime for today in database"
    RunDBQuery $RecordPlayTimeQuery
}