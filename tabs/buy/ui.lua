--- @type StdUi
local StdUi = LibStub('StdUi');

AuctionFaster.itemFramePool = {};
AuctionFaster.itemFrames = {};

function AuctionFaster:AddBuyAuctionHouseTab()
	if self.buyTabAdded then
		return ;
	end

	local buyTab = StdUi:PanelWithTitle(AuctionFrame, nil, nil, 'Auction Faster - Buy', 160);
	buyTab:Hide();
	buyTab:SetAllPoints();

	self.buyTab = buyTab;

	local n = AuctionFrame.numTabs + 1;

	local tab = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionFrame, 'AuctionTabTemplate');
	tab:StripTextures();
	tab.backdrop = CreateFrame('Frame', nil, tab);
	tab.backdrop:SetTemplate('Default');
	tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1);
	StdUi:GlueAcross(tab.backdrop, tab, 10, -3, -10, 3);
	StdUi:ApplyBackdrop(tab.backdrop);

	tab:Hide();
	tab:SetID(n);
	tab:SetText('Buy Items');
	tab:SetNormalFontObject(GameFontHighlightSmall);
	tab:SetPoint('LEFT', _G['AuctionFrameTab' .. n - 1], 'RIGHT', -8, 0);
	tab:Show();
	-- reference the actual tab
	tab.auctionFasterTab = buyTab;

	PanelTemplates_SetNumTabs(AuctionFrame, n);
	PanelTemplates_EnableTab(AuctionFrame, n);

	self.buyTabAdded = true;

	self:DrawSearchPane();
	self:DrawFavoritesPane();
	self:DrawFavorites(20);
	self:DrawSearchResultsTable();
	self:DrawSearchButtons();
	self:InterceptLinkClick();
end

function AuctionFaster:DrawSearchPane()
	local buyTab = self.buyTab;

	local searchBox = StdUi:SearchEditBox(buyTab, 400, 30, 'Search');
	searchBox:SetFontSize(16);
	StdUi:GlueTop(searchBox, buyTab, 10, -30, 'LEFT');

	local searchButton = StdUi:Button(buyTab, 80, 30, 'Search');
	StdUi:GlueRight(searchButton, searchBox, 5, 0);

	local addFavoritesButton = StdUi:Button(buyTab, 30, 30, '');
	addFavoritesButton.texture = StdUi:Texture(addFavoritesButton, 17, 17, [[Interface\Common\ReputationStar]]);
	addFavoritesButton.texture:SetPoint('CENTER');
	addFavoritesButton.texture:SetBlendMode('ADD');
	addFavoritesButton.texture:SetTexCoord(0, 0.5, 0, 0.5);
	StdUi:GlueRight(addFavoritesButton, searchButton, 5, 0);

	addFavoritesButton:SetScript('OnClick', function()
		AuctionFaster:AddToFavorites();
	end);

	searchButton:SetScript('OnClick', function()
		AuctionFaster:SearchAuctions(searchBox:GetText(), false, 0);
	end);

	buyTab.searchBox = searchBox;
end

function AuctionFaster:DrawSearchButtons()
	local buyTab = self.buyTab;

	local buyButton = StdUi:Button(buyTab, 80, 20, 'Buy');
	StdUi:GlueBottom(buyButton, buyTab, 300, 30, 'LEFT');

	buyButton:SetScript('OnClick', function ()
		AuctionFaster:BuySelectedItem(0, true);
	end);
end

function AuctionFaster:DrawFavoritesPane()
	local buyTab = self.buyTab;

	local favorites = StdUi:ScrollFrame(buyTab, 200, 400);
	StdUi:GlueTop(favorites, buyTab, -10, -30, 'RIGHT');
	StdUi:AddLabel(buyTab, favorites, 'Favorite Searches', 'TOP');

	buyTab.favorites = favorites;
end

local favoriteItemFrames = {};
function AuctionFaster:DrawFavorites()
	local scrollChild = self.buyTab.favorites.scrollChild;
	local lineHeight = 20;

	if not self.db.global.favorites then
		self.db.global.favorites = {};
	end

	local favorites = self.db.global.favorites;

	scrollChild:SetHeight(2 * 2 + lineHeight * #favorites);

	for i = 1, #favoriteItemFrames do
		favoriteItemFrames[i]:Hide();
	end

	for i = 1, #favorites do
		local fav = favorites[i];
		if not favoriteItemFrames[i] then
			favoriteItemFrames[i] = self:CreateFavoriteFrame(scrollChild, lineHeight);
		end

		local favoriteFrame = favoriteItemFrames[i];
		self:UpdateFavoriteFrame(favoriteFrame, fav, i, lineHeight);
	end
end

function AuctionFaster:CreateFavoriteFrame(scrollChild, lineHeight)
	local favoriteFrame = StdUi:HighlightButton(scrollChild, scrollChild:GetWidth() - 22, lineHeight, 'aaaa');
	local removeFav = StdUi:Button(favoriteFrame, 20, lineHeight, 'X');
	StdUi:GlueRight(removeFav, favoriteFrame, 0, 0);

	removeFav:SetScript('OnClick', function(self)
		AuctionFaster:RemoveFromFavorites(self:GetParent().itemIndex);
	end);

	favoriteFrame:SetScript('OnClick', function (self)
		AuctionFaster:SetFavoriteAsSearch(self.itemIndex);
	end);

	return favoriteFrame;
end

function AuctionFaster:UpdateFavoriteFrame(favoriteFrame, fav, i, lineHeight)
	local margin = 2;
	favoriteFrame:SetText(fav.text);
	favoriteFrame:ClearAllPoints();
	favoriteFrame:SetPoint('TOPLEFT', margin, -(i - 1) * lineHeight - margin);
	favoriteFrame.itemIndex = i;
	favoriteFrame:Show();
end

local function FxHighlightScrollingTableRow(table, realrow, column, rowFrame, cols)
	local rowdata = table:GetRow(realrow);
	local celldata = table:GetCell(rowdata, column);
	local highlight;

	if type(celldata) == 'table' then
		highlight = celldata.highlight;
	end

	if table.fSelect then
		if table.selected == realrow then
			table:SetHighLightColor(
				rowFrame,
				highlight or cols[column].highlight or rowdata.highlight or table:GetDefaultHighlight()
			);
		else
			table:SetHighLightColor(rowFrame, table:GetDefaultHighlightBlank());
		end
	end
end

local function FxDoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table)
	if fShow then
		local idx = cols[column].index;
		local format = cols[column].format;

		local val = data[realrow][idx];
		if (format == 'money') then
			val = StdUi.Util.formatMoney(val);
			cellFrame.text:SetText(val);
		elseif (format == 'number') then
			val = tostring(val);
			cellFrame.text:SetText(val);
		elseif (format == 'icon') then
			if cellFrame.texture then
				cellFrame.texture:SetTexture(val);
				cellFrame.texture.itemLink = data[realrow].itemLink;
			else
				cellFrame.texture = StdUi:Texture(cellFrame, cols[column].width, cols[column].width, val);
				cellFrame.texture:SetPoint('CENTER', 0, 0);
				cellFrame.texture.itemLink = data[realrow].itemLink;

				cellFrame:SetScript('OnEnter', function(self)
					AuctionFaster:ShowTooltip(self, self.texture.itemLink, true);
				end);
				cellFrame:SetScript('OnLeave', function(self)
					AuctionFaster:ShowTooltip(self, nil, false);
				end);
			end
		else
			cellFrame.text:SetText(val);
		end

		FxHighlightScrollingTableRow(table, realrow, column, rowFrame, cols);
	end
end

local function FxCompareSort(table, rowA, rowB, sortBy)
	local a = table:GetRow(rowA);
	local b = table:GetRow(rowB);
	local column = table.cols[sortBy];
	local idx = column.index;

	local direction = column.sort or column.defaultsort or 'asc';

	if direction:lower() == 'asc' then
		return a[idx] > b[idx];
	else
		return a[idx] < b[idx];
	end
end

function AuctionFaster:DrawSearchResultsTable()
	local buyTab = self.buyTab;

	local cols = {
		{
			name         = 'Item',
			width        = 32,
			align        = 'LEFT',
			index        = 'icon',
			format       = 'icon',
			DoCellUpdate = FxDoCellUpdate,
			comparesort  = FxCompareSort
		},
		{
			name         = 'Name',
			width        = 150,
			align        = 'LEFT',
			index        = 'itemLink',
			format       = 'string',
			DoCellUpdate = FxDoCellUpdate,
			comparesort  = FxCompareSort
		},
		{
			name         = 'Seller',
			width        = 100,
			align        = 'LEFT',
			index        = 'owner',
			format       = 'string',
			DoCellUpdate = FxDoCellUpdate,
			comparesort  = FxCompareSort
		},
		{
			name         = 'Qty',
			width        = 40,
			align        = 'LEFT',
			index        = 'count',
			format       = 'number',
			DoCellUpdate = FxDoCellUpdate,
			comparesort  = FxCompareSort
		},
		{
			name         = 'Bid / Item',
			width        = 120,
			align        = 'RIGHT',
			index        = 'bid',
			format       = 'money',
			DoCellUpdate = FxDoCellUpdate,
			comparesort  = FxCompareSort
		},
		{
			name         = 'Buy / Item',
			width        = 120,
			align        = 'RIGHT',
			index        = 'buy',
			format       = 'money',
			DoCellUpdate = FxDoCellUpdate,
			comparesort  = FxCompareSort
		},
	}

	buyTab.searchResults = StdUi:ScrollTable(buyTab, cols, 9, 32);
	buyTab.searchResults:EnableSelection(true);
	StdUi:GlueAcross(buyTab.searchResults.frame, buyTab, 10, -100, -220, 50);
end