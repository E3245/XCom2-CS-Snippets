//---------------------------------------------------------------------------------------
// FILE:	X2Helpers_PostTemplateModifications_Example
// AUTHOR:	E3245
// DESC:	This is a sample file showcasing how to modify certain templates within the game to hide them using OnPostTemplatesCreated().
//			These same methods can be applied to Chimera Squad's templates as well.
//			
//			Please rename X2Helpers_PostTemplateModifications_Example to something more relevant to your project.
//
//---------------------------------------------------------------------------------------

class X2Helpers_PostTemplateModifications_Example extends Object config(GameData);

///			To call these functions, go to your `X2DownloadableContentInfo_*.uc` class and add this in `static event OnPostTemplatesCreated()`:
///			```
///			class'X2Helpers_PostTemplateModifications_Example'.static.DisableWeaponTemplates();
///			class'X2Helpers_PostTemplateModifications_Example'.static.DisableAcademyUnlocks();
///			class'X2Helpers_PostTemplateModifications_Example'.static.DisableTechsAndProvingGroundProjects();
///			class'X2Helpers_PostTemplateModifications_Example'.static.DisableAllClassTemplates();
///			```

// Declare global dynamic arrays or other variables here.
var config array<name>	BlacklistWeapons;
var config array<name>	BlacklistAcademyUnlocks;
var config array<name>	BlacklistTechs;
var config array<name>	BlacklistSoldierClasses;

//
// Given a set of weapon templates, removes the templates from being shown in the game.
//
static function DisableWeaponTemplates()
{
	local X2ItemTemplateManager TemplateManager;
	local X2WeaponTemplate WeaponTemplate;
	local array<X2DataTemplate> DataTemplates;
	local name ItemTemplateName;
	local int idx;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.BlacklistWeapons(ItemTemplateName)
	{
		TemplateManager.FindDataTemplateAllDifficulties(ItemTemplateName, DataTemplates);
		for (idx = 0; idx < DataTemplates.Length; ++idx)
		{	
			WeaponTemplate = X2WeaponTemplate(DataTemplates[idx]);
			if (WeaponTemplate != none)
			{
				//Disable tech requirements
				WeaponTemplate.Requirements.RequiredTechs.Length = 0;

				WeaponTemplate.Requirements.SpecialRequirementsFn = DisableFn;
				WeaponTemplate.Requirements.RequiredScienceScore = 999999999;
				WeaponTemplate.Requirements.RequiredHighestSoldierRank = 999999999;
				WeaponTemplate.Requirements.bVisibleIfPersonnelGatesNotMet = false;
				WeaponTemplate.Requirements.bVisibleIfSoldierRankGatesNotMet = false;

				//Disallow building
				WeaponTemplate.CanBeBuilt = false;
			}
		}

	}
}

//
// Given a set of academy unlock templates, removes the templates from being shown in the game.
// Now this one is unique, the set of templates that are purchasable are in the GTS facility, so we will need to get that template and edit the array within.
//
static function DisableAcademyUnlocks()
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local X2FacilityTemplate GTSTemplate;
	local name TemplateName;

	StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();;
	GTSTemplate = X2FacilityTemplate(StrategyTemplateManager.FindStrategyElementTemplate('OfficerTrainingSchool'));

	if (GTSTemplate == none)
		return;

	foreach default.BlacklistAcademyUnlocks(TemplateName)
		GTSTemplate.SoldierUnlockTemplates.RemoveItem(TemplateName);
}

//
// Given a set of tech templates, hides them from the research and proving grounds.
//
static function DisableTechsAndProvingGroundProjects()
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local X2TechTemplate TechTemplate;
	local array<X2DataTemplate> DataTemplates;
	local name TemplateName;
	local int idx;

	StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();;

	foreach default.BlacklistTechs(TemplateName)
	{
		StrategyTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
		for (idx = 0; idx < DataTemplates.Length; ++idx)
		{
			TechTemplate = X2TechTemplate(DataTemplates[idx]);
			if (TechTemplate != none)
			{
				//Disable tech requirements
				// Requirements
				TechTemplate.Requirements.SpecialRequirementsFn = DisableFn;
				TechTemplate.Requirements.RequiredScienceScore = 999999999;
				TechTemplate.Requirements.RequiredHighestSoldierRank = 999999999;
				TechTemplate.Requirements.bVisibleIfPersonnelGatesNotMet = false;
				TechTemplate.Requirements.bVisibleIfSoldierRankGatesNotMet = false;
			}
		}
	}
}

//
// Blacklist Soldier Classes from appearing in a singleplayer campaign while this mod is active
// Set the bMultiplayerOnly flag to prevent the singleplayer campaign from picking these up as valid soldier classes
// However, disabling all classes will cause issues with the game, so I strongly suggest setting a specific X2SoldierClassTemplate's NumInForcedDeck value to 9999.
//
static function DisableAllClassTemplates()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate		SoldierClassTemplate;
	local name							TemplateName;
	local array<X2DataTemplate>			DataTemplates;
	local X2DataTemplate				DataTemplate;
	local int							idx;

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach default.BlacklistSoldierClasses(TemplateName)
	{
		SoldierClassTemplateMan.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
		foreach DataTemplates(DataTemplate)
		{
			SoldierClassTemplate = X2SoldierClassTemplate(DataTemplate);
			if (SoldierClassTemplate != none && !SoldierClassTemplate.bMultiplayerOnly)
			{
				SoldierClassTemplate.bMultiplayerOnly = true;
				SoldierClassTemplate.NumInForcedDeck = 0;
				SoldierClassTemplate.NumInDeck = 0;

			}
		}
	}
}

// This will always fail the requirements, thereby hiding the template or other object forever.
static function bool DisableFn()
{
	return false;
}
