#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

/*
This class is used for differences in the user interfaces.
If the resolution and ClientConfiguration.xml are not identical you'll always have to change these settings
*/
class UserInterface
{
    ClickEscape()
    {
        MouseClick, left, 1546, 841
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

    ; literally any UI element, just used for checking if we're out of the loading screen, I'm using here my unity bar
    IsOutOfLoadingScreen()
    {
        return Utility.GetColor(75,1049) == "0x000001"
    }

    ; any pixel on the revive skil
    IsReviveVisible()
    {
        return Utility.GetColor(1038,899) == "0x6F542B"
    }

    ; sprint bar to check if we're out of combat
    IsOutOfCombat()
    {
        return Utility.GetColor(809,836) == "0xA5B721"
    }
}