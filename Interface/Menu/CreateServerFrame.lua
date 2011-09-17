PlayerListRefreshTime = nil;

function MapList_OnLoad()
	ListBoxUpdate(self);
	ListBoxClear(self);	
	Scripts[self] = function(name, button, value, display)
		
	end
	
	ListBoxAdd1('MapList', 'Unknown_map', 'Maze TD 1.23');
	ListBoxAdd1('MapList', 'Unknown_map', 'DoTA All Stars v5.63');
	ListBoxAdd1('MapList', 'Unknown_map', 'Unkwown Soldier');
	ListBoxAdd1('MapList', 'Unknown_map', 'Carentan');
	ListBoxAdd1('MapList', 'Unknown_map', 'WorldEditTestMap');
	ListBoxAdd1('MapList', 'Unknown_map', 'de_dust2');
	ListBoxAdd1('MapList', 'Unknown_map', 'Karazhan');
	ListBoxOnClick('MapListCapsuleElement1');
	
end

CreateServerFrameLastUpdate = 0;

function CreateServerFrame_OnUpdate()
	if Time() >= CreateServerFrameLastUpdate + 100 then
		if 		ListBoxGetSelected('MapList') ~= -1
			and GetText('ServerNameText') 	  ~= ''
			and GetText('NicknameServerText') 	  ~= '' then
			EnableButton('CreateServerButton');
		else
			DisableButton('CreateServerButton');
		end
		CreateServerFrameLastUpdate = Time();
	end
end

function CreateServer_OnLoad() --Buttun 'Create server'
	DisableButton('CreateServerButton');
	SetText(self..'ButtonText', 'Create server');
	Scripts[self] = function (name, button)
		CreateServerFromMenu(GetText('ServerNameText'), ListBoxGetValue('MapList'));
		SetNickFromMenu(GetText('NicknameServerText'));
		ListBoxClear('PlayerList');
		RefreshPlayerList();
		PlayerListRefreshTime = Time() + 30000;
		SetVisible('StartGame', true);
		OpenMenu('PlayerListFrame');
		--LaunchGame();		
	end
end
