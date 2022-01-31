#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

/*
This class is used for differences in the user interfaces.
If the resolution and ClientConfiguration.xml are not identical you'll always have to change these settings
*/
class UserInterface
{
    MoveMouseOverMap()
    {
        MouseMove, 1651, 251
    }

    ClickTrackingMap()
    {
        MouseClick, left, 1891, 51
    }

    IsMapTransparent()
    {
        return Utility.GetColor(1377,310) != "0xBCA984"
    }

    MapFixpoint()
    {
        return Utility.GetColor(1518,127) == "0x636437"
    }

    ClickExit()
    {
        MouseClick, left, 1770, 870
    }

    ; start holding mouse right side of the stage number and release it left of the stage number to edit
    EditStage()
    {
        loop, 3 {
            MouseClick, Left, 1636, 740
            sleep 150
        }

        MouseClick, Left, 1738, 476
        click down
        sleep 100
        MouseMove, 1717, 476
        click up
    }

    ClickReady()
    {
        MouseClick, left, 962, 1035
    }

    ClickChat()
    {
        MouseClick, left, 158, 887
    }

    ClickEnterDungeon()
    {
        MouseClick, left, 1032, 1034
    }

    IsDuoReady()
    {
        return Utility.GetColor(984,120) == "0x38D454"
    }

    HasPartyMemberInLobby()
    {
        return Utility.GetColor(965,120) == "0xD4B449" || Utility.GetColor(980,120) == "0xD4B449"
    }

    IsReady()
    {
        return Utility.GetColor(888,123) == "0x52A745" || Utility.GetColor(899,123) == "0x5FC150"
    }

    IsHpBelowCritical()
    {
        return Utility.GetColor(1038,795) != "0xE0280C"
    }

    ; whenever you want to refresh your exp buff food (basically one of the last pixels which will become darker)
    IsBuffFoodIconVisible()
    {
        return Utility.GetColor(21,7) == "0x866C33"
    }

    ; some of the filled out bar in the loading screen on the bottom of the screen
    IsInLoadingScreen()
    {
        return Utility.GetColor(20,1063) == "0xFF7C00"
    }

    ; literally any UI element in lobby and ingame, just used for checking if we're out of the loading screen, I'm using here my unity bar and enter button
    IsOutOfLoadingScreen()
    {
        return Utility.GetColor(68,1055) == "0x000001" || UserInterface.IsInF8Lobby()
    }

    IsInF8Lobby()
    {
        return Utility.GetColor(1043,1025) == "0x214475"
    }

    ; any pixel on the revive skil
    IsReviveVisible()
    {
        return Utility.GetColor(1038,899) == "0x6F542B"
    }

    ; any position on the loot icon
    IsLootIconVisible()
    {
        return Utility.GetColor(1149,729) == "0xFFAA00"
    }

    IsPortalIconVisible()
    {
        return Utility.GetColor(1152,715) == "0xFEAA00"
    }

    IsBossHealthbarVisible()
    {
        return Utility.GetColor(780,107) == "0xF05311"
    }

    ; sprint bar to check if we're out of combat
    IsOutOfCombat()
    {
		col := Utility.GetColor(809,836)
        return col == "0xA6B721" || col == "0xA5B721"
    }
}