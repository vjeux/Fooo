MAX_FLOATINGBARS = 30;
NbFloatingBars = 0;

function FloatingBar_Set(i, ratio, x, y)
	SetVisible('FloatingBar'..i, true);
	SetWidth('FloatingBar'..i..'Bar', ratio * 100);
	SetColor('FloatingBar'..i..'Bar', 255 * (1 - ratio), 255 * ratio, 0);
	SetX('FloatingBar'..i, x - 50);
	SetY('FloatingBar'..i, y - 5);
end

function FloatingBar_OnUpdate()
	local k = 0;
	
	if IsWinKeyDown(18) then -- Alt
		local nb = GetNbUnitVisible();
		if nb > MAX_FLOATINGBARS then
			--AddLine('Too many floating bars! Add more in the xml');
			nb = MAX_FLOATINGBARS + 1;
		end

		for i = 0, nb - 1 do
			local id = GetUnitVisibleID(i);
			local ratio = GetHP(id) / GetMaxHP(id);
			
			if ratio >= 0 then
				FloatingBar_Set(k, ratio, GetInterfacePosX(id), GetInterfacePosY(id));
				k = k + 1;
			end
		end
	else
		local id = GetMouseHoverUnit();
		if id ~= nil then
			local ratio = GetHP(id) / GetMaxHP(id);
			
			if ratio >= 0 then
				FloatingBar_Set(k, ratio, GetInterfacePosX(id), GetInterfacePosY(id));
				k = k + 1;
			end
		end
	end
	
	for i = k, NbFloatingBars do
		SetVisible('FloatingBar'..i, false);		
	end
	
	NbFloatingBars = k;
end