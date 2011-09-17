IconPathByButtonID = {
	[1] = 'Textures/Icons/BTN_Move',
	[2] = 'Textures/Icons/BTN_Stop',
	[3] = 'Textures/Icons/BTN_Hold',
	[4] = 'Textures/Icons/BTN_Attack',
	[5] = 'Textures/Icons/BTN_Patrol',
	[6] = 'Textures/Icons/Abilities/BTN_CR_Goblin_Tools',
}

DescriptionByButtonID = {
	[1] = 'The selected units units will make them move toward the intended position ignoring enemy targets. If you target a friendly unit, the selected units will follow it.',
	[2] = 'Stop the selected units. They will attack and defend themselves if necessary.',
	[3] = 'The selected units will hold the position. They will attack enemy units on sight but will not chase them. They will not defend themselves if they are attacked by ranged units.',
	[4] = 'The selected units will move directly to the target in order to attack it, they will ignore other enemy units in sight.',
	[5] = 'The selected units will move back and forth from the current position to the chosen position. They will attack any enemy unit on sight.',
	[6] = 'Repair the target building.',
}

NameByButtonID = {
	[1] = 'Move',
	[2] = 'Stop',
	[3] = 'Hold',
	[4] = 'Attack',
	[5] = 'Patrol',
	[6] = 'Repair',
}

ShortcutByButtonID = {
	[1] = 'V',
	[2] = 'S',
	[3] = 'T',
	[4] = 'A',
	[5] = 'P',
	[6] = 'R',
}


LastClick = nil;
Index = 0;

function CommandButtonOnEvent(name)
	local id = ExtractID(name);
	if Index >= GetNbUnitSelect() then
		Index = 0;
	end
	local UnitID = GetUnitSelectedID(Index);
	if (event == EVENT_ONMOUSEUP) then
		SetSize(self..'Icon', 76);
	elseif (event == EVENT_SELECTIONCHANGE) then
		CommandButtonUpdate(self);
		EffectChange(self);
	elseif (event == EVENT_UNITACTION) and (arg1 == id) and not IsBuilding(UnitID) then
		SetVisible(self..'IconActive', true);
	elseif (event == EVENT_UNITSTOPACTION) and (arg1 == id) and not IsBuilding(UnitID) then
		SetVisible(self..'IconActive', false);
	end
end

function DisplayBuildingQueue(name)
	local UnitID = GetUnitSelectedID(0);
	SetVisible('BuildingQueueButtons', true);
	SetVisible('BuildingPercent', true);
	SetVisible('DamageDefense', false);
	SetVisible('TrainingList', false);
	local QueueCount = GetBuildingQueueLength(UnitID);
	if QueueCount ~= 0 then
		for id = 1, QueueCount, 1 do
			SetVisible('BuildingQueueButton'..id, true);
			SetPath('BuildingQueueButton'..id..'Texture', GetUnitInQueueIcon(UnitID, id));
		end
	else
		SetVisible('BuildingQueueButton1', true);
		SetPath('BuildingQueueButton1Texture', GetUnitIcon(UnitID));
		QueueCount = QueueCount + 1;
	end
	for id = QueueCount + 1, 6, 1 do
		SetVisible('BuildingQueueButton'..id, false);
	end
end

function DisplayTrainingList(name)
	local UnitID = GetUnitSelectedID(0);
	SetVisible('TrainingList', true);
	SetVisible('BuildingQueueButtons', false);
	SetVisible('DamageDefense', false);
	local ListCount = GetTrainingListLength(UnitID);
	if ListCount > 0 then
		for id = 1, ListCount, 1 do
			SetVisible('TrainingListUnit'..id, true);
			SetPath('TrainingListUnit'..id..'Texture', GetUnitInTrainingListIcon(UnitID, id));
		end
		for id = ListCount + 1, 6, 1 do
			SetVisible('TrainingListUnit'..id, false);
		end
	end
end

function CommandButtonUpdate(name)
	local id = ExtractID(name);
	if Index >= GetNbUnitSelect() then
		Index = 0;
	end
	local UnitID = GetUnitSelectedID(Index);
	if ValidUnit(UnitID) and not IsInConstruction(UnitID) then
		local AbilityCount = GetAbilityCount(UnitID);
		local BuildingsCount = GetBuildingsCount(UnitID);
		local UpgradesCount = GetUpgradesCount(UnitID);
		if id > 0 and id <= 5 and not(IsBuilding(UnitID)) then
			SetVisible('CommandButton'..id..'Icon', true);
			if GetOrder(UnitID) == id then
				SetVisible('CommandButton'..id..'IconActive', true);
			else
				SetVisible('CommandButton'..id..'IconActive', false);
			end
			SetPath('CommandButton'..id..'IconTexture', IconPathByButtonID[id]..'.tga');
		elseif id <= 5 and BuildingsCount > id-1 then
			SetVisible('CommandButton'..id..'Icon', true);
			SetVisible('CommandButton'..id..'IconActive', false);
			SetPath('CommandButton'..id..'IconTexture', GetBuildingIcon(UnitID, id-1));
		elseif (id >= 5) and (id <= 8) and (UpgradesCount >= id-4) and IsBuilding(UnitID) then
			SetVisible('CommandButton'..id..'Icon', true);
			SetVisible('CommandButton'..id..'IconActive', false);
			if IsUpgradeAvailable(UnitID, id-5) then
				SetPath('CommandButton'..id..'IconTexture', GetUpgradeIcon(UnitID, id-5))
			else
				SetPath('CommandButton'..id..'IconTexture', 'DIS'..GetUpgradeIcon(UnitID, id-5));
			end
		elseif (id == 6) and IsRepairer(UnitID) then
			SetVisible('CommandButton'..id..'Icon', true);
			if GetOrder(UnitID) == 6 then
				SetVisible('CommandButton'..id..'IconActive', true);
			else
				SetVisible('CommandButton'..id..'IconActive', false);
			end
			SetPath('CommandButton'..id..'IconTexture', IconPathByButtonID[6]..'.tga');
		elseif (id >= 9) and (BuildingsCount > id-9) and not(IsBuilding(UnitID)) then
			SetVisible('CommandButton'..id..'Icon', true);
			SetVisible('CommandButton'..id..'IconActive', false);
			SetPath('CommandButton'..id..'IconTexture', GetBuildingIcon(UnitID, id-9));
		elseif (id >= 9) and (AbilityCount >= id-8) then
			SetVisible('CommandButton'..id..'Icon', true);
			SetVisible('CommandButton'..id..'IconActive', false);
			if GetAbilityCost(UnitID, id - 9) > GetMP(UnitID) then
				SetColor('CommandButton'..id..'IconTexture', 50, 50, 255);
			else
				SetColor('CommandButton'..id..'IconTexture', 255, 255, 255);
			end
			if not GetIsAbilityAvailable(UnitID, id-9) then
				SetColor('CommandButton'..id..'IconTexture', 240, 50, 50);
				SetVisible('Cooldown'..id, true);
			else
				SetVisible('Cooldown'..id, false);
			end
			SetPath('CommandButton'..id..'IconTexture', 'Textures/Icons/Abilities/'..GetAbilityIcon(UnitID, id-9));
	    else
			SetVisible('CommandButton'..id..'Icon', false)
			if id >= 9 then
				SetVisible('Cooldown'..id, false);
			end
		end
	else
		SetVisible('CommandButton'..id..'Icon', false)
	end
end

function CommandButtonAction(name)
	local id = ExtractID(name);
	if Index >= GetNbUnitSelect() then
		Index = 0;
	end
	local UnitID = GetUnitSelectedID(Index);
	if ValidUnit(UnitID) and not IsInConstruction(UnitID) then
		local AbilityCount = GetAbilityCount(UnitID);
		local BuildingsCount = GetBuildingsCount(UnitID);
		local Building =	IsBuilding(UnitID); 
		if id >= 1 and id <= 5 and not(Building) then
			if id == 1 then
				SetMode(1);
			elseif id == 2 then
				StopUnit();
			elseif id == 3 then
				Hold();
			elseif id >= 4 and id <= 5 then
				SetMode(id);
			end
		elseif id <= 5 and BuildingsCount > id-1 then			
			SetBuilding(UnitID, id-1);
		elseif (id >= 5) and (id <= 8) and (GetUpgradesCount(UnitID) >= id-4) and IsBuilding(UnitID) then
			LaunchUpgrade(UnitID, id-5);
		elseif id == 6 and IsRepairer(UnitID) then
			SetMode(6);
		elseif (id >= 9) and not(Building) and (BuildingsCount > id-9) then
			SetBuilding(UnitID, id-9);
		elseif (id >= 9) and (AbilityCount >= id-8) then
			AbilityCast(UnitID, id-9);
		elseif (id >= 9) and (AbilityCount >= id-8) then
			AbilityCast(UnitID, id-9);
		end
	end
end

function EffectChange(name)
	local id = ExtractID(name);
	if Index >= GetNbUnitSelect() then
		Index = 0;
	end
	local UnitID = GetUnitSelectedID(Index);
	if ValidUnit(UnitID) then
		local EffectCount = GetEffectsCount(UnitID);
		for id = 1, EffectCount, 1 do
			SetVisible('UnitEffectIcon'..id, true);
			SetPath('UnitEffectIcon'..id..'Texture', 'Textures/Icons/Abilities/'..GetEffectIcon(UnitID, id));
		end
		for id = EffectCount + 1, 6, 1 do
			SetVisible('UnitEffectIcon'..id, false);
		end
	end
end

function ShowDescription(number)
	SetVisible('UnitDescription', true);
	local id = GetUnitSelectedID(0);
	SetText('DamageValue', GetBaseDamage(id));
	local Bonus = GetDamage(id) - GetBaseDamage(id);
	if IsBuildingQueueEmpty(id) and (GetTrainingListLength(id) < 1) and not(IsInConstruction(id)) then
		SetVisible('BuildingQueueButtons', false);	
		SetVisible('TrainingList', false);
		SetVisible('DamageDefense', true);
		if Bonus > 0 then
			SetColor('DamageBonus', 0, 255, 0);
			SetText('DamageBonus', ' +'..Bonus);
		elseif Bonus < 0 then
			SetColor('DamageBonus', 255, 0, 0);
			SetText('DamageBonus', ' -'..-Bonus);
		else
			SetText('DamageBonus', '');
		end
		SetText('DefenseValue', GetBaseDefense(id));
		Bonus = GetDefense(id) - GetBaseDefense(id);
		if Bonus > 0 then
			SetColor('DefenseBonus', 0, 255, 0);
			SetText('DefenseBonus', ' +'..Bonus);
		elseif Bonus < 0 then
			SetColor('DefenseBonus', 255, 0, 0);
			SetText('DefenseBonus', ' -'..-Bonus);
		else
			SetText('DefenseBonus', '');
		end	
	else
		if (GetTrainingListLength(id) < 1) then
			DisplayBuildingQueue('');
		else
			DisplayTrainingList('');
		end
	end
end

function ShowHPMP(number)
	if Index >= GetNbUnitSelect() then
		Index = 0;
	end
	local id = GetUnitSelectedID(Index);
	SetText('UnitName', GetName(id));
	local ratio = GetHP(id) / GetMaxHP(id);
	if ratio == 0 then ratio = 0.01 end
	SetText('HP', GetHP(id)..' / '..GetMaxHP(id));
	SetColor('HP', 255 * (1 - ratio), 255 * ratio, 0);
	local MP = GetMaxMP(id);
	if MP > 0 then
		SetText('MP', GetMP(id)..' / '..MP);
	else
		SetText('MP','');
	end
end

function ShowToolTip(name)
	local id = ExtractID(name);
	if Index >= GetNbUnitSelect() then
		Index = 0;
	end
	local UnitID = GetUnitSelectedID(Index);
	local name = '';
	local text = '';
	local shortcut = '';
    if not ValidUnit(UnitID) or IsInConstruction(UnitID) then
		return(-1);
	end
	local Cost = 0;
	local res1cost = 0;
	local res2cost = 0;
	if id >= 1 and id <= 5 and not IsBuilding(UnitID) then
		name = NameByButtonID[id];
		text = DescriptionByButtonID[id];
		shortcut = ShortcutByButtonID[id];
	elseif id >= 1 and id <= 5 and GetBuildingsCount(UnitID) > id-1 then
		name = GetBuildingName(UnitID, id-1);
		text = GetBuildingToolTip(UnitID, id-1);
		res1cost = GetBuildingRes1Cost(UnitID, id-1);
		res2cost = GetBuildingRes2Cost(UnitID, id-1);
	elseif (id >= 5) and (id <= 8) and (GetUpgradesCount(UnitID) >= id-4) and IsBuilding(UnitID) then
		name = GetUpgradeName(UnitID, id-5);
		text = GetUpgradeToolTip(UnitID, id-5);
	elseif (id == 6) and IsRepairer(UnitID) then
		name = NameByButtonID[6];
		text = DescriptionByButtonID[6];
        shortcut = ShortcutByButtonID[6];		
	elseif (id >= 9) and not(IsBuilding(UnitID)) and (GetBuildingsCount(UnitID) > id-9) then
		name = GetBuildingName(UnitID, id-9);
		text = GetBuildingToolTip(UnitID, id-9);
		res1cost = GetBuildingRes1Cost(UnitID, id-9);
		res2cost = GetBuildingRes2Cost(UnitID, id-9);
	elseif (id >= 9) and (GetAbilityCount(UnitID) >= id-8) then
		name = GetAbilityName(UnitID, id-9);
		text = GetAbilityToolTip(UnitID, id-9);
		Cost = GetAbilityCost(UnitID, id-9);
		shortcut = GetAbilityShortcut(UnitID, id-9);
	else
		return(-1);
	end	
	SetVisible('ToolTip', true);
	SetText('Name', name);
	if shortcut ~= '' then
		SetText('Shortcut', '('..shortcut..')');
	else
		SetText('Shortcut', '');
	end
	SetX('ToolTip', -2);
	SetY('ToolTip', 200);
	local width = GetWidth('ToolTip');
	local tmp1 = '';
	local tmp2 = '';
	local tmp3 = '';
	local i = 1;
	while GetStringWidth(text) > width and i < 6 do
		local j = 1;
		local k = 1;
		local endline = false;
		while GetStringWidth(tmp1) < width - 50 and not endline do
			tmp2 = strsub(text, j, j);
			tmp1 = tmp1..tmp2
			if tmp2 == ' ' then
				k = j+1;
				tmp2 = strsub(text, k, k); 
				while tmp2 ~= ' ' do
					tmp3 = tmp3..tmp2;
					k = k + 1;
					tmp2 = strsub(text, k, k);
				end
				if GetStringWidth(tmp3) + GetStringWidth(tmp1) < width - 50 then
					tmp1 = tmp1..tmp3;
					j = k - 1;
					tmp3 = '';					
				else
					endline = true;
				end
			end
			j = j + 1;
		end
	    text = strsub(text, j);
		SetText('Description'..i, tmp1);
		tmp1 = '';
		tmp2 = '';
		tmp3 = '';
		i = i + 1;
	end	
	SetText('Description'..i, text);
	for j = i + 1, 6, 1 do
		SetText('Description'..j, '');
	end
	local totalheight = GetHeight('Name');
	if Cost > 0 then
		SetVisible('ManaCost', true);
		SetText('Cost', Cost);
		SetY('Description1', 50);
		SetVisible('ManaIcon', true);
		totalheight = totalheight + GetHeight('ManaIcon');
	else
		SetText('Cost', '');
		SetY('Description1', 25);
		SetVisible('ManaIcon', false);
	end
	SetVisible('ResCost', false);
	if res1cost > 0 then
		SetVisible('ResCost', true);
		SetText('Res1Cost', res1cost);
		SetY('Description1', 50);
		SetVisible('Res1Icon', true);
		totalheight = totalheight + GetHeight('Res1Icon');
		SetText('Res2Cost', '');
		SetVisible('Res2Icon', false);
	else
		SetText('Res1Cost', '');
		SetVisible('Res1Icon', false);
		SetY('Description1', 25);
	end
	if res2cost > 0 then
		SetVisible('ResCost', true);
		SetText('Res2Cost', res2cost);
		SetY('Description1', 50);
		SetVisible('Res2Icon', true);
		if res1cost == 0 then
			totalheight = totalheight + GetHeight('Res2Icon');
			SetX('Res2Icon', -22);
			SetY('Res2Icon', -8);
		end
	else
		SetText('Res2Cost', '');
		SetVisible('Res2Icon', false);
		if res1cost == 0 then
			SetY('Description1', 25);
		end
	end	
	for j = 1, i, 1 do
		totalheight = totalheight + GetHeight('Description'..j);
	end
	SetHeight('ToolTip', totalheight+30-i*5);
end

function ShowSelectedGroup(Select)
	if Index >= GetNbUnitSelect() then
		Index = 0;
	end
	local UnitID = GetUnitSelectedID(Index);
	local name = GetName(UnitID);
	for i = 1, Select, 1 do
		SetVisible('SelectionButton'..i, true);
		UnitID = GetUnitSelectedID(i-1);
		if GetName(UnitID) == name then
			SetVisible('SelectionButton'..i..'Active', true);
		else
			SetVisible('SelectionButton'..i..'Active', false)
		end
		local ratio = GetHP(UnitID) / GetMaxHP(UnitID);
		SetWidth('SelectionButton'..i..'LifeBar', ratio * 52);
		SetColor('SelectionButton'..i..'LifeBar', 255 * (1 - ratio), 255 * ratio, 0);
		SetPath('SelectionButton'..i..'Texture', GetUnitIcon(UnitID));
		for i = 1, 12 do
			CommandButtonUpdate('CommandButton'..i);
		end
	end
	for i = Select+1, 18, 1 do 
		SetVisible('SelectionButton'..i, false);	
	end	
end

function OnSelectionClick(name) 				
	if (arg1 == 1) then -- Left Mouse
		local t = Time();
		local id = ExtractID(self);
		if LastClick ~= nil and t < LastClick + 300 then		
			ChangeSelectedUnit(GetUnitSelectedID(id-1));
			Index = id - 1;
			LastClick = nil;
		else
			Index = id - 1;
			LastClick = t;
		end
	end
end

function OnTabPress(number)
	local name = GetName(GetUnitSelectedID(Index));
	local i = Index+1;
	while i <= 18 and GetName(GetUnitSelectedID(i)) == name do
		i = i + 1;
	end
	if i == 19 then
		i = 0;
	end
	Index = i;
	ShowSelectedGroup(GetNbUnitSelect());
end

