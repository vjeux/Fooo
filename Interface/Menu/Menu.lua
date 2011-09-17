serverConnectionLost = 0;

PanelList = {
	"ServerListFrame", 
	"PlayerListFrame",
	"CreateServerFrame", "CreditsFrame"
}

-- Right Buttons

function CreateButton_OnLoad()
	SetText(self..'ButtonText', 'Create Game');
	Scripts[self] = function (name, button)
		DisconnectFromMenu();
		OpenMenu('CreateServerFrame');
		DisableButton(self);
		SetText('NicknameServerText', getNickFromMenu());
		SetText('ServerNameText', getServerNameFromMenu());
		DisableButton(self);
		EnableButton('JoinButtonButton');
		EnableButton('CreditsButtonButton');
	end
end

function JoinButton_OnLoad()
	SetText(self..'ButtonText', 'Join Game');
	Scripts[self] = function (name, button)	
		UndoCreateServerFromMenu();
		DisconnectFromMenu();
		OpenMenu('ServerListFrame');
		ListBoxClear('ServerList');
		Refresh();
		SetText('NicknameText', getNickFromMenu());
		DisableButton(self);
		EnableButton('CreateButtonButton');
		EnableButton('CreditsButtonButton');
		--ListBoxAdd4('ServerList', '127.0.0.1', '192.168.0.1', 'Fooo server', '2', 'Mystery forest');
		--ListBoxAdd4('ServerList', '127.0.0.3', '192.168.0.42', 'Fooo server #2', '1', 'Map #3');
		--ListBoxAdd4('ServerList', '127.0.0.2', '192.168.0.69', 'Banban server', '1', 'Carentan');
	end
end

function OptionButton_OnLoad()
	SetText(self..'ButtonText', 'Options');
	Scripts[self] = function (name, button)
		UndoCreateServerFromMenu();
	end
	DisableButton(self..'Button');
end

function CreditButton_OnLoad()
	SetText(self..'ButtonText', 'Credits');
	Scripts[self] = function (name, button)
		UndoCreateServerFromMenu();
		OpenMenu('CreditsFrame');
		DisableButton(self);
		EnableButton('CreateButtonButton');
		EnableButton('JoinButtonButton');
	end
end

function QuitButton_OnLoad()
	SetText(self..'ButtonText', 'Quit');
	Scripts[self] = function (name, button)
		UndoCreateServerFromMenu();
		Quit();
	end
end


-- MenuFrame

Temps = 0;
Temps2 = 9999999999999999;
MenuState = 0; -- 0 : Nothing
               -- 1 : Coming
			   -- 2 : Leaving
MenuNextFrame = '';

function OpenMenu(panel)
	if IsVisible('MenuFrame') then
		MenuNextFrame = panel;
		MenuState = 2;
	else
		MenuState = 1;
		SetX('MenuFrame', -1088);
		SetVisible('MenuFrame', true);
		for key, val in ipairs(PanelList) do
			if val == panel then
				SetVisible(val, true);
			else
				SetVisible(val, false);
			end
		end
	end
end

function CloseMenu()
	MenuNextFrame = '';
	MenuState = 2;
end

function Menu_OnUpdate()
	if MenuState == 1 then -- Coming
		local x = GetX(self);
		if x < 40 then
			x = min(40, x + GetElapsed() * 2);
			SetX(self, x);
		else
			MenuState = 0;
		end
	elseif MenuState == 2 then -- Leaving
		local x = GetX(self);
		if x > -1088 then
			x = max(-1088, x - GetElapsed() * 2);
			SetX(self, x);
		else
			SetVisible('MenuFrame', false);
			if MenuNextFrame ~= '' then
				OpenMenu(MenuNextFrame);
			else
				MenuState = 0;
			end
		end
	end
end


function AddServerList4(ip, serverName, player_count, map) --Server list
	ListBoxAdd4('ServerList', ip, ip, serverName, player_count, map); 
end

function AddServerList5(nick, ip, race, color, team) --Player list
	ListBoxAdd5('PlayerList', ip, nick, ip, race, color, team); 
end

function AddServerList1(map) --Map list
	ListBoxAdd1('ServerList', map, map);	
end