ChatLines = {};
ChatInputCurrent = '';
EnteredMessages = {}
LastEnteredMessage = 0;
MAX_LINES = 29

function ChatInit()
	local i = 1;
	while i <= MAX_LINES do
		ChatLines[i] = '';
		i = i + 1;
	end
	ChatUpdateLines();
end

function ChatUpdateLines()
	for key, val in ipairs(ChatLines) do
		SetText('ChatLine'..key..'Text', val);
	end
end

function ChatOnKeyDown(char)
	if not IsVisible('ChatInput') then
		if char == 13 then
			ChatInputCurrent = '';
			SetVisible('ChatInput', true);
			SetText('ChatInputText', '');
		end
	else
		if char < 0 then
			print(char);
		elseif char == 8 then -- Backspace
			ChatInputCurrent = string.sub(ChatInputCurrent, 0, -2);
		elseif char == 22 then -- Ctrl+V
			ChatInputCurrent = ChatInputCurrent..GetClipBoard();
		elseif char ~= 13 then -- Enter
			ChatInputCurrent = ChatInputCurrent..string.char(char);
		else
			if string.len(ChatInputCurrent) > 0 then
				table.insert(EnteredMessages, ChatInputCurrent);
				LastEnteredMessage = LastEnteredMessage + 1;
				HandleCommand(ChatInputCurrent);
			end
			SetVisible('ChatInput', false);
		end
		SetText('ChatInputText', ChatInputCurrent);
	end
end

function AddLine(msg)
	local i = MAX_LINES - 1;
	while i >= 1 do
		ChatLines[i+1] = ChatLines[i];
		i = i - 1;
	end
	ChatLines[1] = msg;
	ChatUpdateLines();
end

function getArgs(msg)
    args = {}
    string.gsub(msg, "([^%s]+)", function (arg)
      table.insert(args, arg)
    end)
    return args;
end

SlashCmdList = {}

SlashCmdList["S"] = function(msg)
	RunScript(msg);	
end

SlashCmdList["CONNECT"] = function(msg)
	args = getArgs(msg);
	SetServer(args[1]);
end

SlashCmdList["NICK"] = function(msg)
	args = getArgs(msg);
	SetNick(args[1]);
end

function HandleCommand(text)
	local command = string.gsub(text, "^(/[^%s]+).*$", '%1') or "";
	local msg = "";
	if ( command ~= text ) then
		msg = string.sub(text, string.len(command) + 2);
	end
	command = string.upper(string.sub(command, 2));
	
	if (SlashCmdList[command]) then
		SlashCmdList[command](string.trim(msg));
		return;
	end
	
	SendChatMessage(text);
end
