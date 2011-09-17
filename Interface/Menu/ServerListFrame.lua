ServerListConnectBottomTime = nil;

function ServerListConnectTop_OnLoad()
	SetText(self..'ButtonText', 'Connect');
	Scripts[self] = function (name, button)
		if GetText('ServerIPText') ~= '' then
			ConnectFromMenu(GetText('ServerIPText'), GetText('NicknameText'));
			DisableButton(self);
			ListBoxClear('PlayerList');
			RefreshPlayerList();
			PlayerListRefreshTime = Time() + 30000;
			EnableButton('JoinButtonButton');
			OpenMenu('PlayerListFrame');
			SetVisible('StartGame', false);
		end
	end
end

function ServerList_OnLoad()
	ListBoxUpdate(self);
	ListBoxClear(self);
	Scripts["ServerList"] = function(name, button, value, display, display2)
		if ListBoxGetSelected(name) ~= -1 then
			EnableButton('ServerListConnectBottomButton');
		end
	end
end

function ServerListRefresh_OnLoad()
	SetText(self..'ButtonText', 'Refresh');
	Scripts[self] = function (name, button)
		ListBoxClear('ServerList');
		Refresh();
		DisableButton(self);
		DisableButton('ServerListConnectBottomButton');
		ServerListConnectBottomTime = Time() + 1000;
	end
end

function ServerListRefresh_OnUpdate()
	if ServerListConnectBottomTime ~= nil then
		if Time() >= ServerListConnectBottomTime then
			Temps = nil;
			EnableButton(self..'Button');
		end
	end
end

function ServerListConnectBottom_OnLoad()
	SetText(self..'ButtonText', 'Connect');
	Scripts[self] = function (name, button)
		if ListBoxGetSelected('ServerList') ~= -1 then
			ConnectFromMenu(ListBoxGetValue('ServerList'), GetText('NicknameText'));
			DisableButton(self);
			ListBoxClear('PlayerList');
			RefreshPlayerList();
			PlayerListRefreshTime = Time() + 30000;
			EnableButton('JoinButtonButton');
			OpenMenu('PlayerListFrame');
			SetVisible('StartGame', false);
		end
	end
	DisableButton(self..'Button');
end
