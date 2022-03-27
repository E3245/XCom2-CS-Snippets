//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_GetMultiPawnsFromSaveData.uc
//  AUTHOR:  E3245
//  PURPOSE: Retrieves a unit from the player's most recent saved game to show on the main
//			 menu. In the absence of an appropriate unit, auto-generates one.
//           
//---------------------------------------------------------------------------------------
class SeqAct_GetMultiPawnsFromSaveData extends SeqAct_GetPawnFromSaveData;

// List of variable names to insert soldiers into
var() array<name>	SoldierVariableNames;

// List of spawned character templates, in order of the list
var array<string> CharacterTemplateStrings;

// List of character templates to exclude from getting picked
var() array<name> ExcludeCharacterTemplates;

event Activated()
{
	local XComGameState SearchState;
	local array<XComGameState_Unit> UnitStates;
	local XComGameState_Unit UnitState;
	local XComUnitPawn UnitPawn;
	local array<XComUnitPawn> arrUnitPawns;

	local Vector Location;
	local Rotator Rotation;

	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;
	local XComGameStateHistory TempHistory;

	local int i;

	local string SoldierName;

	local XComGameStateHistory OriginalHistory;
	
	`LOG("=== BEGIN SeqAct Parameters ===", true, 'ShellTest');
	`LOG("SoldierVariableNames Length: " $ SoldierVariableNames.Length, true, 'ShellTest');
	
	for (i = 0; i < SoldierVariableNames.Length; ++i)
	{
		`LOG("[" $ i $ "]: " $ SoldierVariableNames[i], true, 'ShellTest');
	}

	`LOG("ExcludeCharacterTemplates Length: " $ ExcludeCharacterTemplates.Length, true, 'ShellTest');
	
	for (i = 0; i < ExcludeCharacterTemplates.Length; ++i)
	{
		`LOG("[" $ i $ "]: " $ ExcludeCharacterTemplates[i], true, 'ShellTest');
	}
	
	`LOG("=== END SeqAct Parameters ===", true, 'ShellTest');

	//See if there is a game state from the saved data we can use.	
	SearchState = `ONLINEEVENTMGR.LatestSaveState(TempHistory);

	if(SearchState != none && ChosenCharacterTemplate == '')
	{		
		//This is a special case. Ordinarily terrible and scary.		
		OriginalHistory = `ONLINEEVENTMGR.SwapHistory(TempHistory);

		foreach SearchState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if (UnitState.IsSoldier() && UnitState.IsAlive()) //Only soldiers... that are alive
			{
				//Skip over this soldier if we are looking for a specific one
				if (ChosenSoldierName != "")
				{
					SoldierName = UnitState.GetFirstName() @ UnitState.GetLastName();
					if (ChosenSoldierName != SoldierName)
					{
						continue;
					}
				}
				
				// Skip over excluded character templates
				if (ExcludeCharacterTemplates.Length > 0 && ExcludeCharacterTemplates.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
					continue;

				UnitStates.AddItem(UnitState);
			}
		}
	}
		
	// Sort by whatever criteria
	UnitStates.Sort(SortRandomly);
	
	`LOG("Unit Count: " $ UnitStates.Length, true, 'ShellTest');
	
	for (i = 0; i < SoldierVariableNames.Length; ++i)
	{
		if (i < UnitStates.Length)
		{
			UnitState = UnitStates[i];
			
			if (UnitState.ObjectID <= 0)
			{
				`LOG("Unit State at index [" $ i $ "] is invalid", true, 'ShellTest');			
				continue;
			}
			
			UnitPawn = UnitState.CreatePawn(none, Location, Rotation);
			
			if (UnitPawn == none)
			{
				`LOG("Could not create pawn for Unit: " $ UnitState.GetName(eNameType_FullNick), true, 'ShellTest');	
				continue;
			}				
			
			UnitPawn.CreateVisualInventoryAttachments(none, UnitState, SearchState, true);		
			
			CharacterTemplateStrings.AddItem(string(UnitState.GetMyTemplateName()));
		}
		// Exceeds bounds, start creating new units
		else
		{
			UnitPawn = GenerateNewSoldier(CharacterTemplateString);
			CharacterTemplateStrings.AddItem(CharacterTemplateString);
		}
		
		arrUnitPawns.AddItem(UnitPawn);
		
		`LOG("Created Pawn for Unit " $ UnitState.GetName(eNameType_FullNick) $ ". Size: " $ arrUnitPawns.Length,  true, 'ShellTest');	
	}
	
	`LOG("Created Pawn Count: " $ arrUnitPawns.Length, true, 'ShellTest');
	
	// Before submitting, reset history to original
	if (OriginalHistory != none)
	{
		`ONLINEEVENTMGR.SwapHistory(OriginalHistory);
	}
	
	// Iterate through each pawn and assign them to the Kismet Variables
	if(arrUnitPawns.Length > 0)
	{		
		foreach arrUnitPawns(UnitPawn, i)
		{
			UnitPawn.ObjectID = -1;
			UnitPawn.SetVisible(true);
			UnitPawn.SetupForMatinee(none, true, false);
			UnitPawn.StopTurning();
			UnitPawn.UpdateAnimations();	
			
			// Only do this once
			if (i == 0)
				UnitPawn.WorldInfo.MyKismetVariableMgr.RebuildVariableMap();

			UnitPawn.WorldInfo.MyKismetVariableMgr.GetVariable(SoldierVariableNames[i], OutVariables);

			foreach OutVariables(SeqVar)
			{
				SeqVarPawn = SeqVar_Object(SeqVar);
				if(SeqVarPawn != none)
				{
					SeqVarPawn.SetObjectValue(None);
					SeqVarPawn.SetObjectValue(UnitPawn);
				}
			}
			
			// Note, this will execute for every spawned soldier
			// Start Issue #239
			DLCInfoMatineeGetPawnFromSaveData(UnitPawn, UnitState, SearchState);
			// End Issue #239
		}
	
	}
}

// Start Issue #239
private static function DLCInfoMatineeGetPawnFromSaveData(XComUnitPawn UnitPawn, XComGameState_Unit UnitState, XComGameState SearchState)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.MatineeGetPawnFromSaveData(UnitPawn, UnitState, SearchState);
	}
}
// End Issue #239

// Coin flip
private static function int SortRandomly(XComGameState_Unit UnitA, XComGameState_Unit UnitB)
{
	local int Rand;
	
	Rand = `SYNC_RAND_STATIC(3);
	
	switch (Rand)
	{
		case 0:
			return -1;
		case 1:
			return 1;
		default:
			break;
	}
	
	return 0;
}

private function XComUnitPawn GenerateNewSoldier(out string SpawnedCharTemplateName)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit NewUnitState, UnitState;
	local XComGameState_Item BuildItem;
	local XGCharacterGenerator CharGen;
	local TSoldier CharacterGeneratorResult;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;	
	local XComGameStateHistory History;
	local XComGameState AddToGameState;
	
	local XComUnitPawn UnitPawn;
	local Vector Location;
	local Rotator Rotation;
		
	History = `XCOMHISTORY;

	AddToGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TempGameState");

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	if(ChosenCharacterTemplate == '')
	{
		ChosenCharacterTemplate = 'LostAndAbandonedElena';
	}
	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate(ChosenCharacterTemplate);

	//Make the unit from a template
	//*************************
	NewUnitState = CharacterTemplate.CreateInstanceFromTemplate(AddToGameState);

	//Fill in the unit's stats and appearance
	NewUnitState.RandomizeStats();

	if(CharacterTemplate.bAppearanceDefinesPawn)
	{
		CharGen = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);

		CharacterGeneratorResult = CharGen.CreateTSoldier('Soldier');
		NewUnitState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		NewUnitState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
		NewUnitState.SetCountry(CharacterGeneratorResult.nmCountry);
	}

	//*************************

	//If we added a soldier, give the soldier default items. Eventually we will want to be pulling items from the armory...
	//***************		
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('KevlarArmor'));
	BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);
	BuildItem.ItemLocation = eSlot_None;
	NewUnitState.AddItemToInventory(BuildItem, eInvSlot_Armor, AddToGameState);

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('VektorRifle_CV'));
	BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);
	BuildItem.ItemLocation = eSlot_RightHand;
	NewUnitState.AddItemToInventory(BuildItem, eInvSlot_PrimaryWeapon, AddToGameState);

	UnitPawn = NewUnitState.CreatePawn(none, Location, Rotation);
	UnitState = NewUnitState;

	UnitPawn.CreateVisualInventoryAttachments(none, UnitState, AddToGameState, true);

	History.CleanupPendingGameState(AddToGameState);
	
	SpawnedCharTemplateName = string(UnitState.GetMyTemplateName());
	
	return UnitPawn;
}

defaultproperties
{
	ObjName = "(Shell) Get Multiple Pawns From Save Data"
	ObjCategory = "Kismet"
	bCallHandler = false	
	
	ExcludeCharacterTemplates(0) = "SparkSoldier"

	VariableLinks(1) = (ExpectedType = class'SeqVar_StringList', LinkDesc = "TemplateStrings", PropertyName = CharacterTemplateStrings, bWriteable = true)
}
