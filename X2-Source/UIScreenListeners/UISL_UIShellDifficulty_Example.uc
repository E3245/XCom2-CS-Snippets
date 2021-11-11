//---------------------------------------------------------------------------------------
// FILE:	UISL_UIShellDifficulty_Example
// AUTHOR:	E3245
// DESC:	This file demostrates how to utilize screen listeners to change elements 
//			within a screen.
//
//			Modders can autoset difficulty to Legend and SecondWaveOptions while the 
//			UIShellDifficulty is opened during campaign start or in the middle of.
//			
//---------------------------------------------------------------------------------------

class UISL_UIShellDifficulty_Example extends UIScreenListener config (UI);

struct SecondWavePreset
{
	var name SecondWaveID;
	var bool bIsRequired;
};

// If set, disables the ability to select [Index] difficulty.
// At least one must be set to true or else the player will not be able to 
// proceed as the options are disabled.
// [0]: Rookie
// [1]: Veteran
// [2]: Commander
// [3]: Legend
var config array<bool>				bDisableDifficulty;

//	Modders can set required SecondWaveIDs via `SecondWavePresets` array in XComUI.ini.
//  If bIsRequired is set to true, players cannot disable the SWO when starting a new game.
var config array<SecondWavePreset>	SecondWavePresets;

// Newly declared localization strings will need their own .int file. 
// XComGame.int will not work, it must be MyModSafeName.int for them to properly localize.
var localized string m_strDifficultyDisabledGenMessage;
var localized string m_strTutorialOnImpossible;
var localized string m_arrDifficultyTypeStrings_Impossible;
var localized string m_arrDifficultyDescString_Impossible;

// This event is triggered after a screen is initialized
// Note: This will trigger on every screen, beware!
event OnInit(UIScreen Screen) 
{
	local UIShellDifficulty DifficultyMenu;

	// Grab the screen we want, in this case it is `UIShellDifficulty.uc`
	DifficultyMenu = UIShellDifficulty(Screen);

	// Prevent modifying the wrong screen
	if( DifficultyMenu == none ) 
		return;

    // Update elements within our screen
	UpdateData(DifficultyMenu);
}

// In this function, we got the screen so we will begin modifying it to suit our needs, including access to some methods within the screen.
simulated function UpdateData(UIShellDifficulty DiffMenu)
{
	local int			OptionIndex, PresetIdx; 
	local array<bool>	DiffDisableSettings;

	DiffDisableSettings = default.bDisableDifficulty;

	// Force disable the checkbox based off bDisableDifficulty[Index]
	DiffMenu.m_DifficultyRookieMechaItem.Checkbox.SetChecked(false);
	DiffMenu.m_DifficultyRookieMechaItem.SetDisabled(DiffDisableSettings[0], default.m_strDifficultyDisabledGenMessage);
	DiffMenu.m_DifficultyVeteranMechaItem.Checkbox.SetChecked(false);
	DiffMenu.m_DifficultyVeteranMechaItem.SetDisabled(DiffDisableSettings[1], default.m_strDifficultyDisabledGenMessage);
	DiffMenu.m_DifficultyCommanderMechaItem.Checkbox.SetChecked(false);
	DiffMenu.m_DifficultyCommanderMechaItem.SetDisabled(DiffDisableSettings[2], default.m_strDifficultyDisabledGenMessage);
	DiffMenu.m_DifficultyLegendMechaItem.Checkbox.SetChecked(true, true);	// Force the difficulty to properly change
	DiffMenu.m_DifficultyLegendMechaItem.SetDisabled(DiffDisableSettings[3], default.m_strDifficultyDisabledGenMessage);
	DiffMenu.m_DifficultyLegendMechaItem.Desc.SetHTMLText(default.m_arrDifficultyTypeStrings_Impossible);
	DiffMenu.m_DifficultyLegendMechaItem.BG.SetTooltipText(default.m_arrDifficultyDescString_Impossible, , , 10, , , , 0.0f);

	// Change the Loc variable
	DiffMenu.m_strTutorialOnImpossible		= default.m_strTutorialOnImpossible;
	DiffMenu.m_arrDifficultyDescStrings[3]	= default.m_arrDifficultyDescString_Impossible;
	DiffMenu.RefreshDescInfo();	// Force refresh the info again

	// Double check if we're on legend difficulty
	if (DiffMenu.m_iSelectedDifficulty != 3)
		DiffMenu.m_iSelectedDifficulty = 3;	// Force the difficulty selection to Legend
		
	// Some UIPanel elements have interfaces for setting tooltips. See `UIMechaListItem.uc` for more details.
	// Disable First Time VO and Tutorial
	DiffMenu.m_FirstTimeVOMechaItem.Checkbox.SetChecked(false);
	DiffMenu.m_FirstTimeVOMechaItem.SetDisabled(true, "My custom tooltip text");	// You can also use regular strings, but it will be hardcoded.

	DiffMenu.m_TutorialMechaItem.Checkbox.SetChecked(false);
	DiffMenu.m_TutorialMechaItem.SetDisabled(true, "My custom tooltip text");

	// Iterate through all of the second wave options and toggle/disable as needed
	for( OptionIndex = 0; OptionIndex < DiffMenu.SecondWaveOptions.Length; ++OptionIndex )
	{
		PresetIdx = default.SecondWavePresets.Find('SecondWaveID', DiffMenu.SecondWaveOptions[OptionIndex].ID);
		if ( PresetIdx != INDEX_NONE )
		{
			UIMechaListItem(DiffMenu.m_SecondWaveList.GetItem(OptionIndex)).Checkbox.SetChecked(true);

			// Force disable this item to prevent players from toggling the option
			if ( default.SecondWavePresets[PresetIdx].bIsRequired )
			{
				UIMechaListItem(DiffMenu.m_SecondWaveList.GetItem(OptionIndex)).Checkbox.SetDisabled(true);		// BUG: The player can just uncheck the box even if the Mechalist is disabled!
				UIMechaListItem(DiffMenu.m_SecondWaveList.GetItem(OptionIndex)).SetDisabled(true, "My custom tooltip text");
			}
		}
	}
}