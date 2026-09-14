--[[
    MasensDev V1.0 Soreya
    Roblox Multi-Feature Teleport & Utility Hub (Fixed Auto TP Loop Freeze)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Clean Up Old GUI
local existingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MasensDevHub_V1")
if existingGui then existingGui:Destroy() end

----------------------------------------------------
-- SYSTEM VARIABLES & VALID KEYS
----------------------------------------------------
local VALID_KEYS = {
	["15092026"] = true,
	["Darmawan123@"] = true
}
local DEFAULT_GET_KEY = "https://link-center.net/9347872/iYyFL35U077Q"

local autoEnabled = false
local noclipEnabled = false
local infJumpEnabled = false
local invisibleEnabled = false
local followEnabled = false
local antiAfkEnabled = false

local tpDelay = 1.5
local walkSpeedValue = 16
local jumpPowerValue = 50
local selectedPlayerTarget = nil
local selectedCoord = nil

-- Data Koordinat Map
local checkpointCoords = {
	["Checkpoint 1"]  = Vector3.new(459.8, 444.7, -8944.2),
	["Checkpoint 2"]  = Vector3.new(453.3, 490.7, -9568.4),
	["Checkpoint 3"]  = Vector3.new(390.5, 630.7, -10109.7),
	["Checkpoint 4"]  = Vector3.new(486.5, 637.1, -10681),
	["Checkpoint 5"]  = Vector3.new(1081.3, 726.7, -11159.3),
	["Checkpoint 6"]  = Vector3.new(972.8, 733.1, -11811.3),
	["Checkpoint 7"]  = Vector3.new(391.2, 885.1, -11839.5),
	["Checkpoint 8"]  = Vector3.new(-326.4, 850.7, -11729.8),
	["Checkpoint 9"]  = Vector3.new(-869, 853.1, -11729),
	["Checkpoint 10"] = Vector3.new(-1283.6, 857.1, -12095.6),
	["Checkpoint 11"] = Vector3.new(-1310.7, 890.7, -12835.4),
	["Checkpoint 12"] = Vector3.new(-2313.9, 914.7, -12670.4),
	["Checkpoint 13"] = Vector3.new(-2303.5, 917.1, -11853.6),
	["Checkpoint 14"] = Vector3.new(-2446.5, 961.1, -11058.3),
	["Checkpoint 15"] = Vector3.new(-3477.2, 980.7, -11012.2),
	["Checkpoint 16"] = Vector3.new(-4227.1, 1002.7, -11015.8),
	["Checkpoint 17"] = Vector3.new(-4651.8, 1081.1, -11670.8),
	["Checkpoint 18"] = Vector3.new(-5544.1, 1101.1, -11648.8),
	["Checkpoint 19"] = Vector3.new(-6759.8, 1097.1, -11511.3),
	["Checkpoint 20"] = Vector3.new(-6744.2, 1102.7, -10801.6),
	["Summit"]        = Vector3.new(-6764.6, 1320.6, -10104.4),
	["BC"]            = Vector3.new(-6700, 1332.1, -10007.5)
}

----------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------
local function copyToClipboardText(text)
	if setclipboard then
		setclipboard(text)
	else
		pcall(function()
			game:GetService("StudioService"):CopyToClipboard(text)
		end)
	end
end

-- Teleport Fungsi Terproteksi (Aman dari Character Reset & Streaming Issue)
local function teleportToPosition(vectorPos)
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 3)
	
	if hrp then
		if LocalPlayer.RequestStreamAroundAsync then
			pcall(function()
				LocalPlayer:RequestStreamAroundAsync(vectorPos)
			end)
		end
		-- Set posisi karakter dengan offset sedikit lebih rendah agar pasti menyentuh part checkpoint
		char:PivotTo(CFrame.new(vectorPos + Vector3.new(0, 1.5, 0)))
	end
end

local function getPlayerStage()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local cpValueObj = leaderstats:FindFirstChild("Checkpoint")
		if cpValueObj then
			local rawVal = tostring(cpValueObj.Value)
			local parsedNumber = tonumber(rawVal:match("%d+"))
			if parsedNumber then return parsedNumber end
		end
	end
	return 0
end

local function makeDraggable(gui)
	local dragging, dragInput, dragStart, startPos
	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

----------------------------------------------------
-- GUI LAYOUT CONTAINER
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MasensDevHub_V1"
ScreenGui.ResetOnSpawn = false

local CoreGui = game:GetService("CoreGui")
if gethui then ScreenGui.Parent = gethui()
elseif CoreGui:FindFirstChild("RobloxGui") then ScreenGui.Parent = CoreGui
else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

----------------------------------------------------
-- KEY SYSTEM GUI (AWAL)
----------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeySystemFrame"
KeyFrame.Size = UDim2.new(0, 320, 0, 210)
KeyFrame.Position = UDim2.new(0.5, -160, 0.4, -105)
KeyFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
KeyFrame.BackgroundTransparency = 0.4
KeyFrame.Parent = ScreenGui
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 12)
makeDraggable(KeyFrame)

local KeyTitleBar = Instance.new("Frame", KeyFrame)
KeyTitleBar.Size = UDim2.new(1, 0, 0, 35)
KeyTitleBar.BackgroundColor3 = Color3.fromRGB(15, 23, 36)
KeyTitleBar.BackgroundTransparency = 0.4
Instance.new("UICorner", KeyTitleBar).CornerRadius = UDim.new(0, 12)

local KeyTitleText = Instance.new("TextLabel", KeyTitleBar)
KeyTitleText.Size = UDim2.new(1, -20, 1, 0)
KeyTitleText.Position = UDim2.new(0, 10, 0, 0)
KeyTitleText.BackgroundTransparency = 1
KeyTitleText.Text = "MasensDev Hub - Key System"
KeyTitleText.TextColor3 = Color3.fromRGB(0, 210, 255)
KeyTitleText.Font = Enum.Font.Gotham
KeyTitleText.TextSize = 13
KeyTitleText.TextXAlignment = Enum.TextXAlignment.Left

local KeyInputBox = Instance.new("TextBox", KeyFrame)
KeyInputBox.Name = "KeyInputBox"
KeyInputBox.Size = UDim2.new(1, -30, 0, 36)
KeyInputBox.Position = UDim2.new(0, 15, 0, 50)
KeyInputBox.BackgroundColor3 = Color3.fromRGB(20, 30, 42)
KeyInputBox.BackgroundTransparency = 0.4
KeyInputBox.PlaceholderText = "Masukkan Key Di Sini..."
KeyInputBox.PlaceholderColor3 = Color3.fromRGB(130, 145, 160)
KeyInputBox.Text = ""
KeyInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInputBox.Font = Enum.Font.Gotham
KeyInputBox.TextSize = 12
Instance.new("UICorner", KeyInputBox).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel", KeyFrame)
StatusLabel.Size = UDim2.new(1, -30, 0, 20)
StatusLabel.Position = UDim2.new(0, 15, 0, 92)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Silakan Masukkan Key"
StatusLabel.TextColor3 = Color3.fromRGB(180, 190, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11

local GetKeyBtn = Instance.new("TextButton", KeyFrame)
GetKeyBtn.Size = UDim2.new(0.46, -5, 0, 35)
GetKeyBtn.Position = UDim2.new(0, 15, 0, 120)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 38, 55)
GetKeyBtn.BackgroundTransparency = 0.4
GetKeyBtn.Text = "Get Key"
GetKeyBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
GetKeyBtn.Font = Enum.Font.Gotham
GetKeyBtn.TextSize = 12
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)

local CheckKeyBtn = Instance.new("TextButton", KeyFrame)
CheckKeyBtn.Size = UDim2.new(0.46, -5, 0, 35)
CheckKeyBtn.Position = UDim2.new(0.54, 0, 0, 120)
CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 210)
CheckKeyBtn.BackgroundTransparency = 0.4
CheckKeyBtn.Text = "Check Key"
CheckKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckKeyBtn.Font = Enum.Font.Gotham
CheckKeyBtn.TextSize = 12
Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 8)

-- Action Get Key
GetKeyBtn.MouseButton1Click:Connect(function()
	copyToClipboardText(DEFAULT_GET_KEY)
	GetKeyBtn.Text = "Copied!"
	StatusLabel.Text = "Key berhasil disalin ke Clipboard!"
	StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 150)
	task.wait(1.5)
	GetKeyBtn.Text = "Get Key"
end)

----------------------------------------------------
-- MAIN HUB GUI & CONTROLS (AWALNYA HIDDEN)
----------------------------------------------------

-- Tombol Open Ringkas "MD"
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenHubButton"
OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Position = UDim2.new(0.01, 0, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
OpenBtn.BackgroundTransparency = 0.4
OpenBtn.Text = "MD"
OpenBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
OpenBtn.Font = Enum.Font.Gotham
OpenBtn.TextSize = 14
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 10)
makeDraggable(OpenBtn)

-- Main Frame Container
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
MainFrame.BackgroundTransparency = 0.6
MainFrame.Parent = ScreenGui
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
makeDraggable(MainFrame)

-- Action Check Key Validation
CheckKeyBtn.MouseButton1Click:Connect(function()
	local inputKey = KeyInputBox.Text
	if VALID_KEYS[inputKey] then
		StatusLabel.Text = "Key Benar! Membuka GUI..."
		StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
		task.wait(0.5)
		KeyFrame:Destroy()
		OpenBtn.Visible = true
		MainFrame.Visible = true
	else
		StatusLabel.Text = "Key Salah! Coba Lagi."
		StatusLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
	end
end)

-- Top Bar Header
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 23, 36)
TopBar.BackgroundTransparency = 0.5
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

local TitleText = Instance.new("TextLabel", TopBar)
TitleText.Size = UDim2.new(1, -40, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "MasensDev V1.0 Soreya"
TitleText.TextColor3 = Color3.fromRGB(0, 210, 255)
TitleText.Font = Enum.Font.Gotham
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
CloseBtn.BackgroundTransparency = 0.4
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.TextSize = 12
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Sidebar Container
local SideBar = Instance.new("Frame", MainFrame)
SideBar.Size = UDim2.new(0, 130, 1, -45)
SideBar.Position = UDim2.new(0, 8, 0, 40)
SideBar.BackgroundColor3 = Color3.fromRGB(14, 20, 30)
SideBar.BackgroundTransparency = 0.6
Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 10)

local SideList = Instance.new("UIListLayout", SideBar)
SideList.Padding = UDim.new(0, 6)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", SideBar).PaddingTop = UDim.new(0, 8)
Instance.new("UIPadding", SideBar).PaddingLeft = UDim.new(0, 6)

-- Content Pages Container
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -154, 1, -45)
ContentFrame.Position = UDim2.new(0, 146, 0, 40)
ContentFrame.BackgroundTransparency = 1

local pages = {}
local function createPage(name)
	local page = Instance.new("ScrollingFrame", ContentFrame)
	page.Name = name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
	page.Visible = false
	
	local layout = Instance.new("UIListLayout", page)
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
	end)
	
	pages[name] = page
	return page
end

local mainPage = createPage("Main")
local miscPage = createPage("Misc")
local settingsPage = createPage("Settings")

-- Navigation Tabs
local tabButtons = {}
local function addTab(name, layoutOrder)
	local btn = Instance.new("TextButton", SideBar)
	btn.Size = UDim2.new(1, -12, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	btn.BackgroundTransparency = 0.5
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(160, 180, 200)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 12
	btn.LayoutOrder = layoutOrder
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	btn.MouseButton1Click:Connect(function()
		for _, p in pairs(pages) do p.Visible = false end
		for _, b in pairs(tabButtons) do
			b.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
			b.TextColor3 = Color3.fromRGB(160, 180, 200)
		end
		pages[name].Visible = true
		btn.BackgroundColor3 = Color3.fromRGB(0, 120, 190)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
	
	table.insert(tabButtons, btn)
end

addTab("Main", 1)
addTab("Misc", 2)
addTab("Settings", 3)

pages["Main"].Visible = true
tabButtons[1].BackgroundColor3 = Color3.fromRGB(0, 120, 190)
tabButtons[1].TextColor3 = Color3.fromRGB(255, 255, 255)

----------------------------------------------------
-- UI COMPONENT BUILDERS
----------------------------------------------------
local function createButton(parent, text, bgColor, callback)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(1, -10, 0, 32)
	btn.BackgroundColor3 = bgColor or Color3.fromRGB(0, 140, 210)
	btn.BackgroundTransparency = 0.4
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 11
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	if callback then btn.MouseButton1Click:Connect(function() callback(btn) end) end
	return btn
end

local function createToggle(parent, text, callback)
	local state = false
	local btn = createButton(parent, text .. ": OFF", Color3.fromRGB(30, 45, 60), function(self)
		state = not state
		self.Text = text .. (state and ": ON" or ": OFF")
		self.BackgroundColor3 = state and Color3.fromRGB(0, 170, 120) or Color3.fromRGB(30, 45, 60)
		callback(state)
	end)
	return btn
end

----------------------------------------------------
-- TAB 1: MAIN
----------------------------------------------------
-- Map Teleport Dropdown
local cpDropBtn = createButton(mainPage, "Pilih Map Target... ▼", Color3.fromRGB(25, 35, 50))
local cpScroll = Instance.new("ScrollingFrame", mainPage)
cpScroll.Size = UDim2.new(1, -10, 0, 100)
cpScroll.BackgroundColor3 = Color3.fromRGB(15, 22, 32)
cpScroll.BackgroundTransparency = 0.4
cpScroll.Visible = false
cpScroll.ScrollBarThickness = 3
Instance.new("UICorner", cpScroll).CornerRadius = UDim.new(0, 8)
local cpList = Instance.new("UIListLayout", cpScroll)
cpList.Padding = UDim.new(0, 2)

cpList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	cpScroll.CanvasSize = UDim2.new(0, 0, 0, cpList.AbsoluteContentSize.Y)
end)

for i = 1, 20 do
	local name = "Checkpoint " .. i
	createButton(cpScroll, name, Color3.fromRGB(25, 38, 55), function()
		selectedCoord = checkpointCoords[name]
		cpDropBtn.Text = name
		cpScroll.Visible = false
	end)
end

for _, item in ipairs({"Summit", "BC"}) do
	createButton(cpScroll, item, Color3.fromRGB(45, 35, 65), function()
		selectedCoord = checkpointCoords[item]
		cpDropBtn.Text = item
		cpScroll.Visible = false
	end)
end

cpDropBtn.MouseButton1Click:Connect(function() cpScroll.Visible = not cpScroll.Visible end)

createButton(mainPage, "Teleport Manual Ke Map", Color3.fromRGB(0, 140, 210), function()
	if selectedCoord then teleportToPosition(selectedCoord) end
end)

createToggle(mainPage, "Auto Teleport Map", function(enabled)
	autoEnabled = enabled
end)

-- Delay Speed Adjuster
local speedFrame = Instance.new("Frame", mainPage)
speedFrame.Size = UDim2.new(1, -10, 0, 32)
speedFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 42)
speedFrame.BackgroundTransparency = 0.5
Instance.new("UICorner", speedFrame).CornerRadius = UDim.new(0, 8)

local speedLabel = Instance.new("TextLabel", speedFrame)
speedLabel.Size = UDim2.new(0.6, 0, 1, 0)
speedLabel.Position = UDim2.new(0, 8, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Jeda Auto TP: " .. string.format("%.1fs", tpDelay)
speedLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left

local minusDelay = createButton(speedFrame, "-", Color3.fromRGB(40, 50, 65), function()
	tpDelay = math.max(0.2, tpDelay - 0.2)
	speedLabel.Text = "Jeda Auto TP: " .. string.format("%.1fs", tpDelay)
end)
minusDelay.Size = UDim2.new(0, 30, 0, 24)
minusDelay.Position = UDim2.new(1, -70, 0, 4)

local plusDelay = createButton(speedFrame, "+", Color3.fromRGB(40, 50, 65), function()
	tpDelay = tpDelay + 0.2
	speedLabel.Text = "Jeda Auto TP: " .. string.format("%.1fs", tpDelay)
end)
plusDelay.Size = UDim2.new(0, 30, 0, 24)
plusDelay.Position = UDim2.new(1, -35, 0, 4)

-- Player Teleport Dropdown
local plDropBtn = createButton(mainPage, "Pilih Pemain Target... ▼", Color3.fromRGB(25, 35, 50))
local plScroll = Instance.new("ScrollingFrame", mainPage)
plScroll.Size = UDim2.new(1, -10, 0, 90)
plScroll.BackgroundColor3 = Color3.fromRGB(15, 22, 32)
plScroll.BackgroundTransparency = 0.4
plScroll.Visible = false
plScroll.ScrollBarThickness = 3
Instance.new("UICorner", plScroll).CornerRadius = UDim.new(0, 8)
local plList = Instance.new("UIListLayout", plScroll)
plList.Padding = UDim.new(0, 2)

local function updatePlayerList()
	for _, child in pairs(plScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			createButton(plScroll, p.DisplayName .. " (@" .. p.Name .. ")", Color3.fromRGB(25, 38, 55), function()
				selectedPlayerTarget = p
				plDropBtn.Text = p.DisplayName
				plScroll.Visible = false
			end)
		end
	end
	plScroll.CanvasSize = UDim2.new(0, 0, 0, plList.AbsoluteContentSize.Y)
end

plDropBtn.MouseButton1Click:Connect(function()
	updatePlayerList()
	plScroll.Visible = not plScroll.Visible
end)

-- TELEPORT KE PEMAIN
createButton(mainPage, "Teleport ke Pemain Target", Color3.fromRGB(0, 160, 150), function()
	if not selectedPlayerTarget then updatePlayerList() end
	
	if selectedPlayerTarget then
		task.spawn(function()
			local myChar = LocalPlayer.Character
			if not myChar then return end
			
			if selectedPlayerTarget.Character and selectedPlayerTarget.Character:FindFirstChild("HumanoidRootPart") then
				local targetCFrame = selectedPlayerTarget.Character:GetPivot()
				if LocalPlayer.RequestStreamAroundAsync then
					LocalPlayer:RequestStreamAroundAsync(targetCFrame.Position)
				end
				myChar:PivotTo(targetCFrame * CFrame.new(0, 0, -3))
			else
				local targetChar = selectedPlayerTarget.Character or selectedPlayerTarget.CharacterAdded:Wait()
				local targetHrp = targetChar:WaitForChild("HumanoidRootPart", 3)
				
				if targetHrp then
					if LocalPlayer.RequestStreamAroundAsync then
						LocalPlayer:RequestStreamAroundAsync(targetHrp.Position)
					end
					myChar:PivotTo(targetHrp.CFrame * CFrame.new(0, 0, -3))
				end
			end
		end)
	end
end)

createToggle(mainPage, "Mode Follow Pemain Target", function(enabled)
	followEnabled = enabled
	if followEnabled then
		if not selectedPlayerTarget then updatePlayerList() end
	end
end)

----------------------------------------------------
-- TAB 2: MISC
----------------------------------------------------
local wsFrame = Instance.new("Frame", miscPage)
wsFrame.Size = UDim2.new(1, -10, 0, 32)
wsFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 42)
wsFrame.BackgroundTransparency = 0.5
Instance.new("UICorner", wsFrame).CornerRadius = UDim.new(0, 8)

local wsLabel = Instance.new("TextLabel", wsFrame)
wsLabel.Size = UDim2.new(0.6, 0, 1, 0)
wsLabel.Position = UDim2.new(0, 8, 0, 0)
wsLabel.BackgroundTransparency = 1
wsLabel.Text = "WalkSpeed: " .. walkSpeedValue
wsLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
wsLabel.Font = Enum.Font.Gotham
wsLabel.TextSize = 11
wsLabel.TextXAlignment = Enum.TextXAlignment.Left

local minusWs = createButton(wsFrame, "-", Color3.fromRGB(40, 50, 65), function()
	walkSpeedValue = math.max(0, walkSpeedValue - 5)
	wsLabel.Text = "WalkSpeed: " .. walkSpeedValue
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeedValue
	end
end)
minusWs.Size = UDim2.new(0, 30, 0, 24)
minusWs.Position = UDim2.new(1, -70, 0, 4)

local plusWs = createButton(wsFrame, "+", Color3.fromRGB(40, 50, 65), function()
	walkSpeedValue = walkSpeedValue + 5
	wsLabel.Text = "WalkSpeed: " .. walkSpeedValue
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeedValue
	end
end)
plusWs.Size = UDim2.new(0, 30, 0, 24)
plusWs.Position = UDim2.new(1, -35, 0, 4)

local jpFrame = Instance.new("Frame", miscPage)
jpFrame.Size = UDim2.new(1, -10, 0, 32)
jpFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 42)
jpFrame.BackgroundTransparency = 0.5
Instance.new("UICorner", jpFrame).CornerRadius = UDim.new(0, 8)

local jpLabel = Instance.new("TextLabel", jpFrame)
jpLabel.Size = UDim2.new(0.6, 0, 1, 0)
jpLabel.Position = UDim2.new(0, 8, 0, 0)
jpLabel.BackgroundTransparency = 1
jpLabel.Text = "JumpPower: " .. jumpPowerValue
jpLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
jpLabel.Font = Enum.Font.Gotham
jpLabel.TextSize = 11
jpLabel.TextXAlignment = Enum.TextXAlignment.Left

local minusJp = createButton(jpFrame, "-", Color3.fromRGB(40, 50, 65), function()
	jumpPowerValue = math.max(0, jumpPowerValue - 10)
	jpLabel.Text = "JumpPower: " .. jumpPowerValue
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		hum.UseJumpPower = true
		hum.JumpPower = jumpPowerValue
	end
end)
minusJp.Size = UDim2.new(0, 30, 0, 24)
minusJp.Position = UDim2.new(1, -70, 0, 4)

local plusJp = createButton(jpFrame, "+", Color3.fromRGB(40, 50, 65), function()
	jumpPowerValue = jumpPowerValue + 10
	jpLabel.Text = "JumpPower: " .. jumpPowerValue
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		hum.UseJumpPower = true
		hum.JumpPower = jumpPowerValue
	end
end)
plusJp.Size = UDim2.new(0, 30, 0, 24)
plusJp.Position = UDim2.new(1, -35, 0, 4)

createToggle(miscPage, "Noclip Mode", function(enabled) noclipEnabled = enabled end)
createToggle(miscPage, "Infinite Jump", function(enabled) infJumpEnabled = enabled end)
createToggle(miscPage, "Invisible (Local)", function(enabled)
	invisibleEnabled = enabled
	local char = LocalPlayer.Character
	if char then
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.Transparency = invisibleEnabled and 1 or 0
			end
		end
	end
end)

----------------------------------------------------
-- TAB 3: SETTINGS
----------------------------------------------------
createToggle(settingsPage, "Anti-AFK System", function(enabled)
	antiAfkEnabled = enabled
end)

createButton(settingsPage, "Rejoin Server Current", Color3.fromRGB(180, 50, 70), function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

----------------------------------------------------
-- BACKGROUND LOOPS (FIXED STUCK & FREEZE ISSUES)
----------------------------------------------------

-- Auto Teleport Map Loop (Diberi Anti-Stuck & Safe Retries)
task.spawn(function()
	while true do
		task.wait(tpDelay)
		if autoEnabled then
			pcall(function()
				local currentStage = getPlayerStage()
				
				if currentStage >= 20 then
					teleportToPosition(checkpointCoords["Summit"])
					task.wait(tpDelay)
					if autoEnabled then
						teleportToPosition(checkpointCoords["BC"])
						task.wait(tpDelay)
						if autoEnabled then
							teleportToPosition(checkpointCoords["Checkpoint 1"])
						end
					end
				else
					local nextStage = currentStage + 1
					local targetKey = "Checkpoint " .. nextStage
					if checkpointCoords[targetKey] then
						teleportToPosition(checkpointCoords[targetKey])
					end
				end
			end)
		end
	end
end)

-- CONTINUOUS LOOP (NOCLIP & FOLLOW WITH STREAMING FETCH)
RunService.Stepped:Connect(function()
	if noclipEnabled and LocalPlayer.Character then
		for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = false end
		end
	end
	
	if followEnabled and selectedPlayerTarget and selectedPlayerTarget.Character then
		local myChar = LocalPlayer.Character
		local targetChar = selectedPlayerTarget.Character
		
		if myChar and targetChar then
			local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
			if targetHrp then
				myChar:PivotTo(targetHrp.CFrame * CFrame.new(0, 0, 1.5))
			end
		end
	end
end)

-- Infinite Jump Action
UserInputService.JumpRequest:Connect(function()
	if infJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- Anti-AFK Simulation
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
	if antiAfkEnabled then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- Respawn Listener
LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.WalkSpeed = walkSpeedValue
		hum.UseJumpPower = true
		hum.JumpPower = jumpPowerValue
	end
end)
