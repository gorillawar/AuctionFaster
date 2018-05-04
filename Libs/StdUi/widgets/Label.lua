--- @type StdUi
local StdUi = LibStub and LibStub('StdUi', true);

function StdUi:SetTextColor(fontString, colorType)
	colorType = colorType or 'color';

	fontString:SetTextColor(
		self.config.font[colorType].r,
		self.config.font[colorType].g,
		self.config.font[colorType].b,
		self.config.font[colorType].a
	);
end

--- @return FontString
function StdUi:Label(parent, text, size, inherit, width, height)
	local fs = parent:CreateFontString(nil, self.config.font.strata, inherit);

	fs:SetFont(self.config.font.familly, size or self.config.font.size, self.config.font.effect);
	fs:SetText(text);
	self:SetTextColor(fs, 'color');
	self:SetObjSize(fs, width, height);

	fs:SetJustifyH('LEFT');
	fs:SetJustifyV('MIDDLE');

	return fs;
end


function StdUi:AddLabel(parent, object, text, labelPosition, labelWidth)
	local labelHeight = (self.config.font.size) + 4;
	local label = self:Label(parent, text, self.config.font.size, nil, labelWidth, labelHeight);

	if labelPosition == 'TOP' or labelPosition == nil then
		self:GlueAbove(label, object, 0, 4, 'LEFT');
	elseif labelPosition == 'RIGHT' then
		self:GlueRight(label, object, 4, 0);
	else -- labelPosition == 'LEFT'
		label:SetWidth(labelWidth or label:GetStringWidth())
		self:GlueLeft(label, object, 4, 0);
	end

	object.label = label;
end