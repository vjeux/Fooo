Scripts = {};

Form = {
	isEnabled = true;
	FocusList = {};
	Focus = 0;
	Validate = '';
}

function HandleFormKey(key)
	if key == -9 then
		
	end
end

-- Buttons

function ToggleButton(name, state)
	SetVisible(name..'Pushed', state);
	SetVisible(name..'Enabled', not state);
end

function DisableButton(name)
	SetVisible(name..'Disabled', true);
	SetVisible(name..'Pushed', false);
	SetVisible(name..'Enabled', true);
	SetVisible(name..'Highlight', false);
end

function EnableButton(name)
	SetVisible(name..'Disabled', false);
	SetVisible(name..'Pushed', false);
	SetVisible(name..'Enabled', true);
end

-- ListBox

ListBoxElements = {};
local ListBoxElementsCount = {};
local ListBoxElementsSelected = {};
local MAX_LISTBOX = 16;

function ListBoxOnEnter(name)
	local parent = GetParent(name);
	local list = GetParent(parent);
	local id = ExtractID(name);
	
	if id <= ListBoxElementsCount[list] then
		SetVisible(self..'BackgroundLight', true);
	end
end

function ListBoxOnMouseDown()
	Focus = self;
end

function ListBoxClear(name)
	ListBoxElements[name] = {};
	ListBoxElementsCount[name] = 0;
	ListBoxElementsSelected[name] = -1;
	for i = 1, MAX_LISTBOX do
		SetText(name..'CapsuleElement'..i..'IP', '');
		SetText(name..'CapsuleElement'..i..'Name', '');
		SetText(name..'CapsuleElement'..i..'Count', '');
		SetText(name..'CapsuleElement'..i..'Map', '');
		
		SetText(name..'CapsuleElement'..i..'Map2', '');
		
		SetText(name..'CapsuleElement'..i..'Nick', '');
		SetText(name..'CapsuleElement'..i..'PlayerIP', '');
		SetText(name..'CapsuleElement'..i..'Race', '');
		SetVisible(name..'CapsuleElement'..i..'Texture', false);
		SetVisible(name..'CapsuleElement'..i..'Background', false);
		SetText(name..'CapsuleElement'..i..'Team', '');
	end
end

function ListBoxAdd5(name, value, display, display2, display3, display4, display5)
	if (ListBoxElementsCount[name] < MAX_LISTBOX) then
		table.insert(ListBoxElements[name], {value = value, display = display});
		ListBoxElementsCount[name] = ListBoxElementsCount[name] + 1;
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Nick', display);
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'PlayerIP', display2);
		if display3 == 1 then
			SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Race', 'Rat');
		else
			SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Race', 'Treant');
		end
		SetPath(name..'CapsuleElement'..ListBoxElementsCount[name]..'Texture', 'Textures/TeamColor/TeamColor'..display4..'.tga')
		SetVisible(name..'CapsuleElement'..ListBoxElementsCount[name]..'Texture', true);
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Team', display5);
	else
		AddLine(name..' listbox capacity reached');
	end
end

function ListBoxAdd4(name, value, display, display2, display3, display4)
	if (ListBoxElementsCount[name] < MAX_LISTBOX) then
		table.insert(ListBoxElements[name], {value = value, display = display});
		ListBoxElementsCount[name] = ListBoxElementsCount[name] + 1;
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'IP', display);
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Name', display2);
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Count', display3);
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Map', display4);
	else
		AddLine(name..' listbox capacity reached');
	end
end

function ListBoxAdd1(name, value, display)
	if (ListBoxElementsCount[name] < MAX_LISTBOX) then
		table.insert(ListBoxElements[name], {value = value, display = display});
		ListBoxElementsCount[name] = ListBoxElementsCount[name] + 1;
		SetText(name..'CapsuleElement'..ListBoxElementsCount[name]..'Map2', display);
	else
		AddLine(name..' listbox capacity reached');
	end
end

function ListBoxUpdate(name)
	SetSize(name..'Capsule', GetWidth(name) - 18, GetHeight(name) - 18);
end

function ListBoxOnClick(name)
	local parent = GetParent(name);
	local list = GetParent(parent);
	local id = ExtractID(name);
	if id <= ListBoxElementsCount[list] then
		for i = 1, ListBoxElementsCount[list] do
			if i == id then
				SetVisible(parent..'Element'..i..'Background', true);
			else
				SetVisible(parent..'Element'..i..'Background', false);
			end
		end
		ListBoxElementsSelected[list] = id;
		Scripts[list](name, arg1, ListBoxElements[list][id].value, ListBoxElements[list][id].display);
	end
end

function ListBoxOnKeyDown()
	if self == Focus then
		if arg1 == -40 then
			local list = GetParent(self);
			if ListBoxElementsSelected[list] < ListBoxElementsCount[list] and ListBoxElementsSelected[list] >= 0 then
				ListBoxOnClick(self..'Element'..(ListBoxElementsSelected[list]+1));
			end
		elseif arg1 == -38 then
			local list = GetParent(self);
			if ListBoxElementsSelected[list] > 1 then
				ListBoxOnClick(self..'Element'..(ListBoxElementsSelected[list]-1));
			end
		end
	end
end

function ListBoxGetValue(list)
	return ListBoxElements[list][ListBoxElementsSelected[list]].value;
end

function ListBoxGetSelected(list)
	return ListBoxElementsSelected[list];
end


-- TextBox

TextBoxPosition = 0;

function TextBox_UpdatePipePosition()
	local x, w = GetX(self..'Text'), GetStringWidth(strsub(GetText(self..'Text'), 0, TextBoxPosition), GetFont(self..'Text'));
	SetX(self..'Pipe', x + w);
end

function TextBox_OnKeyDown(name, char)
	local currentText = GetText(self..'Text');
	local len = strlen(currentText);

	if char == -39 and TextBoxPosition <= len then -- right
		TextBoxPosition = TextBoxPosition + 1;
	elseif char == -37 and TextBoxPosition > 0 then -- left
		TextBoxPosition = TextBoxPosition - 1;
	elseif char == -36 then -- Debut
		TextBoxPosition = 0;
	elseif char == -35 then -- Fin
		TextBoxPosition = len;
	elseif char == 8 then -- Backspace
		if TextBoxPosition >= 1 then
			currentText = strsub(currentText, 1, TextBoxPosition - 1)..strsub(currentText, TextBoxPosition + 1, len);
			TextBoxPosition = TextBoxPosition - 1;
		end
	elseif char == -46 then -- Suppr
		if TextBoxPosition < len then
			currentText = strsub(currentText, 1, TextBoxPosition)..strsub(currentText, TextBoxPosition + 2, len);
		end
	elseif char == 22 then -- Ctrl+V
		local clip = GetClipBoard();
		currentText = strsub(currentText, 1, TextBoxPosition)..clip..strsub(currentText, TextBoxPosition + 1, len);
		TextBoxPosition = TextBoxPosition + strlen(clip);
	elseif char > 31 then
		currentText = strsub(currentText, 1, TextBoxPosition)..string.char(char)..strsub(currentText, TextBoxPosition + 1, len);
		TextBoxPosition = TextBoxPosition + strlen(string.char(char));
	end
	
	SetText(self..'Text', currentText);
	TextBox_UpdatePipePosition();
end
