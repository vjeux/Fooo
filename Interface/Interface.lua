EVENT_SELECTIONCHANGE = 1;
EVENT_ONMOUSEDOWN = 2;
EVENT_ONMOUSEUP = 3;
EVENT_UNITACTION = 4;
EVENT_UNITSTOPACTION = 5;
EVENT_ONEFFECT = 6;
EVENT_ONSERVERDISCONNECT = 7;
EVENT_BUILDINGQUEUE = 8;
EVENT_WARNING = 9;
EVENT_TRAINING = 10;
EVENT_POPCHANGE = 11;

if AddLine == nil then
	function AddLine(text)
		Log(text);
	end
end

function SetSize(component, width, height)
	if height == nil then
		height = width;
	end
	SetWidth(component, width);
	SetHeight(component, height);
end

function ExtractID(name)
	local id = '';
	local i = 1;
	local len = strlen(name)
		
	while i <= len and (strsub(name, i, i) < '0' or strsub(name, i, i) > '9') do
		i = i + 1;
	end
	
	while i <= len and strsub(name, i, i) >= '0' and strsub(name, i, i) <= '9' do
		id = id .. strsub(name, i, i);
		i = i + 1;
	end
	
	if id == '' then
		id = 0;
	end
	
	return id + 0;
end

