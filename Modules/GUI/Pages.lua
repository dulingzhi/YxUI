local YxUI, Language = select(2, ...):get()
local GUI = YxUI:GetModule("GUI")
local tinsert = table.insert

-- Compatibility map for plugin pages registered with translated labels.
local PageKeys = {
	"General", "Info", "Action Bars", "Unit Frames", "Name Plates", "Chat",
	"Auras", "Profiles", "Styles", "Minimap", "Tooltips", "Colors",
	"Objectives", "Experience", "Reputation", "Data Texts", "Player",
	"Target", "Target of Target", "Focus", "Bosses", "Party", "Raid",
	"Pet", "Party Pets", "Raid Pets", "Left", "Right", "Credits",
	"Supporters", "Debug", "Plugins", "Totem Bar", "Pet Bar", "Stance Bar",
	"Extra Action", "Micro Menu", "Bags", "Key Binding",
}
local Canonical = {}
for i = 1, #PageKeys do
	local key = PageKeys[i]
	Canonical[Language[key]] = key
end
for i = 1, 8 do
	local key = "Action Bar " .. i
	Canonical[Language[key]] = key
end

function GUI:GetPageID(name)
	return Canonical[name] or name
end

function GUI:GetCategoryDescriptor(name, stableID)
	local Category
	if stableID then
		Category = self.CategoriesByID and self.CategoriesByID[stableID]
	else
		Category = self.Categories[name]
	end

	if not Category then
		Category = {Name = name, ID = stableID or self:GetPageID(name), Pages = {}, PageLookup = {}, IDLookup = {}}
		if not self.Categories[name] then self.Categories[name] = Category end
		self.CategoriesByID = self.CategoriesByID or {}
		self.CategoriesByID[Category.ID] = Category
		tinsert(self.CategoryOrder, Category)
		if not self.Pages[name] then self.Pages[name] = Category.PageLookup end
	end

	return Category
end

local NewPage = function(category, name, stableID)
	return {
		Category = category,
		Name = name,
		ID = stableID or GUI:GetPageID(name),
		Parent = nil,
		Children = {},
		ChildLookup = {},
		Callbacks = {},
		Expanded = false,
		Button = nil,
		Window = nil,
	}
end

function GUI:GetOrCreatePage(categoryName, name, parentName, categoryID, pageID, parentID)
	local Category = self:GetCategoryDescriptor(categoryName, categoryID)
	local Page = pageID and Category.IDLookup[pageID]
	if not pageID then Page = Category.IDLookup[self:GetPageID(name)] or Category.PageLookup[name] end
	local ParentPage

	if parentName then
		if name == parentName then
			error(format("GUI page '%s/%s' cannot be its own parent", categoryName, name), 3)
		end

		if parentID then
			ParentPage = Category.IDLookup[parentID]
		else
			ParentPage = Category.IDLookup[self:GetPageID(parentName)] or Category.PageLookup[parentName]
		end

		if not ParentPage then
			ParentPage = NewPage(Category, parentName, parentID)
			if not Category.PageLookup[parentName] then Category.PageLookup[parentName] = ParentPage end
			Category.IDLookup[ParentPage.ID] = ParentPage
			tinsert(Category.Pages, ParentPage)
		end
	end

	if Page then
		if Page.Parent ~= ParentPage then
			error(format("Duplicate GUI page identity '%s/%s' registered with different parents", categoryName, name), 3)
		end
	else
		Page = NewPage(Category, name, pageID)
		Page.Parent = ParentPage
		if not Category.PageLookup[name] then Category.PageLookup[name] = Page end
		assert(not Category.IDLookup[Page.ID], "Duplicate GUI page ID: " .. tostring(Page.ID))
		Category.IDLookup[Page.ID] = Page

		if ParentPage then
			ParentPage.ChildLookup[name] = Page
			tinsert(ParentPage.Children, Page)
		else
			tinsert(Category.Pages, Page)
		end
	end

	Page.Defined = true

	return Page
end

function GUI:ValidatePages()
	local self = self
	for i = 1, #self.CategoryOrder do
		local Category = self.CategoryOrder[i]

		for _, Page in next, Category.IDLookup do
			if not Page.Defined then
				error(format("GUI category '%s' references missing parent page '%s'", Category.Name, Page.Name), 3)
			elseif Page.Parent and Page.Parent.Parent then
				error(format("GUI page '%s/%s' has nested parent '%s'; only one child level is supported", Category.Name, Page.Name, Page.Parent.Name), 3)
			end
		end
	end
end

-- Page descriptors are the source of truth for both lookup and construction.
-- Walking them directly avoids maintaining a second registration queue and its
-- associated per-page state.
function GUI:CreatePageButtons()
	for i = 1, #self.CategoryOrder do
		local Category = self.CategoryOrder[i]

		for j = 1, #Category.Pages do
			local Page = Category.Pages[j]
			self:CreateWindow(Page)

			for k = 1, #Page.Children do
				self:CreateWindow(Page.Children[k])
			end
		end
	end
end


function GUI:HasButton(category, name, parent)
	local Category = (self.CategoriesByID and self.CategoriesByID[category]) or self.Categories[category]
	local Page = Category and (Category.IDLookup[name] or Category.PageLookup[name])

	if Page and ((not parent and not Page.Parent) or (Page.Parent and (Page.Parent.Name == parent or Page.Parent.ID == parent))) then
		return Page
	end
end


-- Stable IDs are English localization keys; labels remain translated.
function GUI:AddWidgetsID(categoryID, pageID, arg1, arg2)
	local category = Language[categoryID] or categoryID
	local name = Language[pageID] or pageID
	local parentID = type(arg1) == "string" and arg1 or nil
	local parent = parentID and (Language[parentID] or parentID)
	local Page = self:GetOrCreatePage(category, name, parent, categoryID, pageID, parentID)
	local builder = type(arg1) == "function" and arg1 or arg2
	assert(type(builder) == "function", "Invalid GUI page callback: " .. tostring(pageID))
	tinsert(Page.Callbacks, builder)
	self:InvalidateSettingsSearchIndex()
	if self.Loaded then
		if Page.Window then Page.WindowNeedsRebuild = true end
		self:CreatePageButtons()
		self:SortMenuButtons()
		self:ScrollSelections()
	end
	return Page
end

function GUI:AddWidgets(category, name, arg1, arg2)
	local Page
	if type(arg1) == "function" then
		Page = self:GetOrCreatePage(category, name)
		tinsert(Page.Callbacks, arg1)
	else
		Page = self:GetOrCreatePage(category, name, arg1)
		tinsert(Page.Callbacks, arg2)
	end

	self:InvalidateSettingsSearchIndex()
	if self.Loaded then
		if Page.Window then Page.WindowNeedsRebuild = true end
		self:CreatePageButtons()
		self:SortMenuButtons()
		self:ScrollSelections()
	end
end
