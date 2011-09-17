
function InterfaceOnUpdate(elapsed)
	SetText('FPS', 'FPS : '..GetFPS());
end

function ProcessKey(key)
end

function InterfaceOnKeyDown(key)
	if not IsVisible('ChatInput') then
		ProcessKey(key);
	end
end
