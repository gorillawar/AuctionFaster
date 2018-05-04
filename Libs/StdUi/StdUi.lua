local MAJOR, MINOR = 'StdUi', 1;
--- @class StdUi
local StdUi = LibStub:NewLibrary(MAJOR, MINOR);

if not StdUi then
	return;
end

function StdUi:SetObjSize(obj, width, height)
	if width then
		obj:SetWidth(width);
	end

	if height then
		obj:SetHeight(height);
	end
end

function StdUi:ApplyBackdrop(frame, type, border, insets)
	local backdrop = {
		bgFile = [[Interface\Buttons\WHITE8X8]],
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		edgeSize = 1,
	};
	if insets then
		backdrop.insets = insets;
	end
	frame:SetBackdrop(backdrop);

	type = type or 'button';
	border = border or 'border';

	frame:SetBackdropColor(
		self.config.backdrop[type].r,
		self.config.backdrop[type].g,
		self.config.backdrop[type].b,
		self.config.backdrop[type].a
	);
	frame:SetBackdropBorderColor(
		self.config.backdrop[border].r,
		self.config.backdrop[border].g,
		self.config.backdrop[border].b,
		self.config.backdrop[border].a
	);
end

function StdUi:ClearBackdrop(frame)
	frame:SetBackdrop(nil);
end

function StdUi:MakeDraggable(frame, handle)
	frame:SetMovable(true);
	frame:EnableMouse(true);
	frame:RegisterForDrag('LeftButton');
	frame:SetScript('OnDragStart', frame.StartMoving);
	frame:SetScript('OnDragStop', frame.StopMovingOrSizing);

	if handle then
		handle:EnableMouse(true);
		handle:SetMovable(true);
		handle:RegisterForDrag('LeftButton');
		handle:SetScript('OnDragStart', function(self)
			frame.StartMoving(frame);
		end);
		handle:SetScript('OnDragStop', function(self)
			frame.StopMovingOrSizing(frame);
		end);
	end
end