PlayerListRefreshTime = nil;
PingClientsTime = nil;
AllPlayerAreSynchronised = 0;
local MaxWaitTime = 0;

function PlayerList_OnLoad()
	ListBoxUpdate(self);
	ListBoxClear(self);	
	Scripts[self] = function(name, button, value, display, display2, display3, display4, display5)
		
	end
end

function PlayerList_OnUpdate()
	if PingClientsTime == nil then
		PingClientsTime = Time() + 1000;
	elseif Time() > PingClientsTime then		
		if SynchroniseClients() ~= 1 then
			AllPlayerAreSynchronised = 0;
		else
			AllPlayerAreSynchronised = 1;
		end
		PingClientsTime = Time() + 100;
	end
	
	if PlayerListRefreshTime ~= nil then
		if Time() > PlayerListRefreshTime then
			ListBoxClear('PlayerList');
			RefreshPlayerList();
			Log('Refreshing player list from PlayerListFrame.lua l.30');
			PlayerListRefreshTime = Time() + 30000;
		end
	end
	
	if AllPlayerAreSynchronised == 1 then
		EnableButton('StartGameButton');
	else
		DisableButton('StartGameButton');
	end
	
	if serverConnectionLost == 1 then
		CloseMenu('PlayerListFrame');
		serverConnectionLost = 0;
	end
	
	MaxWaitTime = MaxWaitingTime();
	--Log(MaxWaitTime);
	if MaxWaitTime  ~= 0 then
		SetText('StartGameButtonText', 'Synchronising '..MaxWaitTime);
	else
		SetText('StartGameButtonText', 'Start game');
	end
end

function StartGame_OnLoad()
	SetText(self..'ButtonText', 'Start game');
	Scripts[self] = function (name, button)
		BroadCastLaunchGame_();
	end
end
