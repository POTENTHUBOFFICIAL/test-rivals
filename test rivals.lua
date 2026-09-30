-- ============================================================
-- POTENT HUB - RIVALS (WindUI v2.1 Edition) - FIXED
-- ============================================================

if not shared then
	return warn("No shared, no script.")
end

local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local virtualInputManager = game:GetService("VirtualInputManager")
local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")
local httpService = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

local customGetHui = gethui or function() return coreGui end
local customRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local customSetClipboard = setclipboard or toclipboard or function(...) end

local function customHttpGet(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if ok and res and res ~= "" then return res end
	if customRequest then
		local response = customRequest({ Url = url, Method = "GET" })
		if response and response.Body then return response.Body end
	end
	return ""
end

local Palette = {
	Gold   = Color3.fromRGB(255, 200, 50),
	Purple = Color3.fromRGB(168, 85, 247),
	Blue   = Color3.fromRGB(59, 130, 246),
	Dark   = Color3.fromRGB(14, 14, 18),
}

local BrandGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Palette.Gold),
	ColorSequenceKeypoint.new(0.5, Palette.Purple),
	ColorSequenceKeypoint.new(1.0, Palette.Blue),
})

local BACKGROUND_ID = "72427773287138"
local LOGO_ID = "117299981730743"
local POTENT_DISCORD_URL = "https://discord.gg/X7Y4NzuC67"

local animGradients = {}
local visualApplied = false

-- ============================================================
-- UI UTILITIES
-- ============================================================
local function spinGradient(gradient, speed)
	table.insert(animGradients, { g = gradient, s = speed or 40 })
end

runService.RenderStepped:Connect(function(dt)
	for i = #animGradients, 1, -1 do
		local element = animGradients[i]
		if element.g and element.g.Parent then
			element.g.Rotation = (element.g.Rotation + element.s * dt) % 360
		else
			table.remove(animGradients, i)
		end
	end
end)

local function getGuiContainer()
	local ok, target = pcall(customGetHui)
	if ok and target then return target end
	local lp = playersService.LocalPlayer
	local pg = lp and lp:FindFirstChild("PlayerGui")
	if pg then return pg end
	return coreGui
end

local function findHubGui()
	local pools = {}
	pcall(function() table.insert(pools, customGetHui()) end)
	pcall(function() table.insert(pools, coreGui) end)
	local lp = playersService.LocalPlayer
	local pg = lp and lp:FindFirstChild("PlayerGui")
	if pg then table.insert(pools, pg) end
	for _, pool in ipairs(pools) do
		for _, gui in ipairs(pool:GetChildren()) do
			if gui:IsA("ScreenGui") then
				local n = gui.Name
				if n:find("WindUI") or n:find("POTENTHUB") or n:find("Footagesus") then
					return gui
				end
			end
		end
	end
end

local function findBackground(gui)
	for _, desc in ipairs(gui:GetDescendants()) do
		if desc:IsA("ImageLabel") and tostring(desc.Image):find(BACKGROUND_ID) then
			return desc
		end
	end
end

local function removeStrokes(root)
	if not root then return end
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("UIStroke") then
			local parent = desc.Parent
			if parent and not parent.Name:find("Open") and not parent.Name:find("Float") then
				pcall(function() desc:Destroy() end)
			end
		elseif desc:IsA("Frame") and desc.Name:find("Outline") then
			pcall(function() desc:Destroy() end)
		elseif desc:IsA("ImageLabel") and (desc.Name:find("Outline") or desc.Name:find("Border")) then
			pcall(function() desc.Visible = false end)
		end
	end
end

local function applyVisuals()
	if visualApplied then return end
	local gui = findHubGui()
	if not gui then return end
	local bg = findBackground(gui)
	if not bg then return end
	visualApplied = true

	bg.ImageColor3 = Color3.fromRGB(120, 120, 140)
	bg.ImageTransparency = 0.35
	bg.ZIndex = 0

	local oldOverlay = bg:FindFirstChild("PotentDarkOverlay")
	if oldOverlay then oldOverlay:Destroy() end

	local overlay = Instance.new("Frame")
	overlay.Name = "PotentDarkOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 0
	overlay.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = overlay

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.35),
		NumberSequenceKeypoint.new(1.0, 0.05),
	})
	gradient.Rotation = 90
	gradient.Parent = overlay

	tweenService:Create(overlay, TweenInfo.new(0.6), { BackgroundTransparency = 0.25 }):Play()

	local container = bg.Parent or bg
	for _, desc in ipairs(container:GetDescendants()) do
		if desc ~= overlay and desc:IsA("GuiObject") and desc.ZIndex < 2 then
			pcall(function() desc.ZIndex = 2 end)
		end
	end

	container.DescendantAdded:Connect(function(desc)
		if desc:IsA("GuiObject") and desc ~= overlay and not desc:IsDescendantOf(overlay) then
			task.defer(function()
				if desc.Parent and desc.ZIndex < 2 then
					pcall(function() desc.ZIndex = 2 end)
				end
			end)
		end
	end)

	task.defer(function()
		removeStrokes(container)
	end)
end

local function setupMinimizeAnimation()
	local gui = findHubGui()
	if not gui then return end
	local bg = findBackground(gui)
	if not bg then return end
	local container = bg.Parent or bg
	if not container or not container:IsA("GuiObject") then return end

	local minimizeBtn = nil
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("TextButton") or desc:IsA("ImageButton") then
			local txt = (desc:IsA("TextButton") and desc.Text) or ""
			local name = desc.Name:lower()
			if txt == "–" or txt == "-" or txt == "—" or name:find("minimize") or name:find("min") then
				minimizeBtn = desc
				break
			end
		end
	end

	local openBtn = nil
	for _, desc in ipairs(gui:GetDescendants()) do
		if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and desc.Name:find("Open") then
			openBtn = desc
			break
		end
	end

	local origPos = container.Position
	local origSize = container.Size

	local function minimize()
		local targetPos = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset + 40)
		tweenService:Create(container, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 60, 0, 60),
			Position = targetPos,
			BackgroundTransparency = 0.3,
		}):Play()
		task.wait(0.4)
		tweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 0, 0, 0),
		}):Play()
		task.wait(0.3)
		container.Visible = false
	end

	local function restore()
		container.Visible = true
		container.Size = UDim2.new(0, 60, 0, 60)
		container.Position = origPos
		container.BackgroundTransparency = 0
		tweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 100, 0, 100),
		}):Play()
		task.wait(0.15)
		tweenService:Create(container, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = origSize,
			Position = origPos,
		}):Play()
	end

	if minimizeBtn then
		pcall(function() minimizeBtn.MouseButton1Click:Connect(function() minimize() end) end)
	end
	if openBtn then
		pcall(function()
			openBtn.MouseButton1Click:Connect(function()
				task.wait(0.05)
				restore()
			end)
		end)
	end
end

local function getWindUILibrary()
	local rawCode = customHttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
	if rawCode == "" then
		rawCode = customHttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
	end
	local windUI = loadstring(rawCode)()

	pcall(function()
		windUI:AddTheme({
			Name        = "PotentGold",
			Accent      = Palette.Gold,
			Outline     = Color3.fromRGB(255, 180, 40),
			Text        = Color3.fromRGB(255, 255, 255),
			Placeholder = Color3.fromRGB(175, 175, 190),
			Background  = Palette.Dark,
			Button      = Color3.fromRGB(32, 32, 40),
			Icon        = Color3.fromRGB(255, 205, 70),
		})
		windUI:SetTheme("PotentGold")
	end)

	return windUI
end

local function createPotentWindow(windUI, folder, gameName)
	visualApplied = false

	local window = windUI:CreateWindow({
		Title = "⚡ POTENT HUB",
		Icon = "rbxassetid://" .. LOGO_ID,
		Author = gameName or "👑 MADE BY POTENT HUB",
		Folder = folder,
		Background = "rbxassetid://" .. BACKGROUND_ID,
		Size = UDim2.fromOffset(640, 490),
		MinSize = Vector2.new(440, 340),
		Resizable = true,
		Transparent = false,
		Theme = "PotentGold",
		User = { Enabled = true, Anonymous = false },
		OpenButton = {
			Title = "POTENT HUB",
			Icon = "rbxassetid://" .. LOGO_ID,
			CornerRadius = UDim.new(0, 16),
			StrokeThickness = 2,
			Color = BrandGradient,
			OnlyMobile = false,
			Enabled = true,
			Draggable = true,
		},
	})

	pcall(function()
		window:Tag({ Title = "v2.1", Icon = "terminal", Color = Palette.Gold })
	end)

	task.spawn(function()
		for _ = 1, 20 do
			pcall(applyVisuals)
			if visualApplied then
				task.wait(0.3)
				pcall(setupMinimizeAnimation)
				pcall(removeStrokes, findHubGui())
				break
			end
			task.wait(0.2)
		end
	end)

	task.spawn(function()
		task.wait(1)
		pcall(function()
			local gui = findHubGui()
			if not gui then return end
			for _, desc in ipairs(gui:GetDescendants()) do
				if desc:IsA("UIStroke") then
					local grad = desc:FindFirstChildOfClass("UIGradient")
					if grad then spinGradient(grad, 70) end
				end
			end
		end)
	end)

	return window
end

-- ============================================================
-- RIVALS LOGIC
-- ============================================================
local LocalPlayer = playersService.LocalPlayer
local Camera = workspace.CurrentCamera
local isMobile = userInputService.TouchEnabled and not userInputService.KeyboardEnabled

local CACHE_FILE = "rivals_settings.json"
local ESP_BOX_COLOR = Color3.fromRGB(255, 255, 255)

local DefaultSettings = {
	ESP_Enabled = true,
	ESP_Highlight = true,
	ESP_Name = true,
	ESP_Studs = true,
	ESP_Tracer = false,
	ESP_BoxTransparency = 0.5,
	ESP_MaxDistance = 500,
	Aimbot_Enabled = true,
	Aimbot_FOVRadius = 100,
	Aimbot_WallCheck = false,
	Aimbot_Smoothness = 1,
	Aimbot_HoldKey = "RMB",
	Aimbot_OnlyWhenHeld = true,
	Triggerbot_Enabled = true,
	Triggerbot_MaxDistance = 1000,
	Triggerbot_FOVRadius = 50,
	Triggerbot_OnlyWhenKeyHeld = false,
	Triggerbot_Key = "RMB",
	InfJump_Enabled = false,
	DeviceSpoofer_Active = nil,
}

local SERIALIZABLE_TYPES = { boolean = true, number = true, string = true }

local function loadSettings()
	local ok, result = pcall(function()
		if isfile and isfile(CACHE_FILE) then
			local raw = readfile(CACHE_FILE)
			local decoded = httpService:JSONDecode(raw)
			for k, v in pairs(DefaultSettings) do
				if decoded[k] == nil then decoded[k] = v end
			end
			return decoded
		end
	end)
	if ok and result then return result end
	local t = {}
	for k, v in pairs(DefaultSettings) do t[k] = v end
	return t
end

local function saveSettings(s)
	pcall(function()
		if writefile then
			local clean = {}
			for k, v in pairs(s) do
				if SERIALIZABLE_TYPES[typeof(v)] or v == nil then
					clean[k] = v
				end
			end
			writefile(CACHE_FILE, httpService:JSONEncode(clean))
		end
	end)
end

local Settings = loadSettings()

if Settings.ESP_Tracer == nil and Settings.ESP_Snapline ~= nil then
	Settings.ESP_Tracer = Settings.ESP_Snapline
end
Settings.ESP_Snapline = nil
Settings.Triggerbot_MaxDistance = 1000

local SetControlsRemote = nil
pcall(function()
	SetControlsRemote = replicatedStorage
		:WaitForChild("Remotes", 5)
		:WaitForChild("Replication", 5)
		:WaitForChild("Fighter", 5)
		:WaitForChild("SetControls", 5)
end)

local function spoofDevice(deviceValue)
	if not SetControlsRemote then return end
	pcall(function() SetControlsRemote:FireServer(deviceValue) end)
end

local function reapplySpooferOnLoad()
	if Settings.DeviceSpoofer_Active then
		task.wait(1.5)
		spoofDevice(Settings.DeviceSpoofer_Active)
	end
end

LocalPlayer.CharacterAdded:Connect(function(character)
	character.ChildAdded:Connect(function(child)
		if child.Name == "HumanoidRootPart" then
			reapplySpooferOnLoad()
		end
	end)
end)

if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
	reapplySpooferOnLoad()
end

local function isVoteScreenActive()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	local mainGui = playerGui:FindFirstChild("MainGUI")
	if not mainGui then return false end
	local mainFrame = mainGui:FindFirstChild("MainFrame")
	if not mainFrame then return false end
	local di1 = mainFrame:FindFirstChild("DuelInterface")
	if not di1 then return false end
	local di2 = di1:FindFirstChild("DuelInterface")
	if not di2 then return false end
	local voting = di2:FindFirstChild("Voting")
	if not voting then return false end
	if voting.Visible then return true end
	local maps = voting:FindFirstChild("Maps")
	if not maps then return false end
	if maps.Visible then return true end
	local mapsList = maps:FindFirstChild("MapsList")
	return mapsList ~= nil
end

local function isInActiveRound()
	local character = LocalPlayer.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	if not character:FindFirstChild("HumanoidRootPart") then return false end
	if isVoteScreenActive() then return false end
	return true
end

-- Key holding helper (so triggerbot/aimbot only fire when user wants)
local heldKeys = {}
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then heldKeys.LMB = true end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then heldKeys.RMB = true end
	if input.KeyCode == Enum.KeyCode.E then heldKeys.E = true end
	if input.KeyCode == Enum.KeyCode.Q then heldKeys.Q = true end
	if input.KeyCode == Enum.KeyCode.F then heldKeys.F = true end
end)
userInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then heldKeys.LMB = false end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then heldKeys.RMB = false end
	if input.KeyCode == Enum.KeyCode.E then heldKeys.E = false end
	if input.KeyCode == Enum.KeyCode.Q then heldKeys.Q = false end
	if input.KeyCode == Enum.KeyCode.F then heldKeys.F = false end
end)

local function isAimKeyHeld()
	if not Settings.Aimbot_OnlyWhenHeld then return true end
	return heldKeys[Settings.Aimbot_HoldKey] == true
end

local function isTriggerKeyHeld()
	if not Settings.Triggerbot_OnlyWhenKeyHeld then return true end
	return heldKeys[Settings.Triggerbot_Key] == true
end

-- Team logic
local teamCache     = {}
local teamCacheTime = {}
local TEAM_CACHE_DURATION = 0.15

local function normalizeTeamValue(value)
	if value == nil then return nil end
	local vt = typeof(value)
	if vt == "Instance"   then return value end
	if vt == "Color3"     then return string.format("color:%.4f:%.4f:%.4f", value.R, value.G, value.B) end
	if vt == "BrickColor" then return "brick:" .. value.Name end
	if vt == "string"     then return value == "" and nil or "string:" .. value end
	if vt == "number"     then return "number:" .. tostring(value) end
	if vt == "boolean"    then return "boolean:" .. tostring(value) end
	return nil
end

local function isTeamName(name)
	if typeof(name) ~= "string" then return false end
	local lowered = string.gsub(string.lower(name), "[%s_%-]", "")
	return lowered == "team" or lowered == "teamid" or lowered == "teamidentifier"
		or lowered == "teamindex" or lowered == "teamcolor" or lowered == "teamcolour"
		or string.find(lowered, "teamid", 1, true) ~= nil
end

local function getTeamFromAttributes(container)
	if not container then return nil end
	local ok, attrs = pcall(function() return container:GetAttributes() end)
	if not ok or not attrs then return nil end
	for name, value in pairs(attrs) do
		if isTeamName(name) then
			local n = normalizeTeamValue(value)
			if n ~= nil then return n end
		end
	end
	return nil
end

local function getTeamFromValues(container)
	if not container then return nil end
	local ok, children = pcall(function() return container:GetChildren() end)
	if not ok or not children then return nil end
	for _, object in ipairs(children) do
		if isTeamName(object.Name) then
			local n = normalizeTeamValue(object.Value)
			if n then return n end
		end
	end
	return nil
end

local function getRivalsTeamSignature(player)
	if not player then return nil end
	local now = os.clock()
	if teamCache[player] ~= nil and teamCacheTime[player]
		and now - teamCacheTime[player] < TEAM_CACHE_DURATION then
		return teamCache[player]
	end
	local signature = player.Team
		or getTeamFromAttributes(player)
		or getTeamFromValues(player)
		or (player.Character and getTeamFromAttributes(player.Character))
		or (player.Character and getTeamFromValues(player.Character))
	if not signature then
		local ok, tc = pcall(function() return player.TeamColor end)
		if ok and tc then
			local colorName = tc.Name
			if colorName and colorName ~= "Medium stone grey" then
				signature = "brick:" .. colorName
			end
		end
	end
	teamCache[player]     = signature
	teamCacheTime[player] = now
	return signature
end

local function clearTeamCache(player)
	teamCache[player]     = nil
	teamCacheTime[player] = nil
end

playersService.PlayerAdded:Connect(function(player)
	clearTeamCache(player)
	player:GetPropertyChangedSignal("Team"):Connect(function() clearTeamCache(player) end)
	player:GetPropertyChangedSignal("TeamColor"):Connect(function() clearTeamCache(player) end)
	player.CharacterAdded:Connect(function() clearTeamCache(player) end)
end)

for _, player in ipairs(playersService:GetPlayers()) do
	if player ~= LocalPlayer then
		player:GetPropertyChangedSignal("Team"):Connect(function() clearTeamCache(player) end)
		player:GetPropertyChangedSignal("TeamColor"):Connect(function() clearTeamCache(player) end)
		player.CharacterAdded:Connect(function() clearTeamCache(player) end)
	end
end

playersService.PlayerRemoving:Connect(function(player) clearTeamCache(player) end)

local function isTeammate(player)
	if not player or player == LocalPlayer then return true end
	local ok1, lTeam = pcall(function() return LocalPlayer.Team end)
	local ok2, pTeam = pcall(function() return player.Team end)
	if ok1 and ok2 and lTeam and pTeam then return lTeam == pTeam end
	local ls = getRivalsTeamSignature(LocalPlayer)
	local ts = getRivalsTeamSignature(player)
	if ls ~= nil and ts ~= nil then
		if typeof(ls) == "Instance" and typeof(ts) == "Instance" then return ls == ts end
		return tostring(ls) == tostring(ts)
	end
	local ok3, ltc = pcall(function() return LocalPlayer.TeamColor end)
	local ok4, ptc = pcall(function() return player.TeamColor end)
	if ok3 and ok4 and ltc and ptc then
		local lc = ltc.Name
		local tc = ptc.Name
		if lc ~= "Medium stone grey" and tc ~= "Medium stone grey" then return lc == tc end
	end
	return false
end

local function isEnemy(player)
	if not player or player == LocalPlayer then return false end
	return not isTeammate(player)
end

local cachedEnemies     = {}
local enemyCacheTime    = 0
local ENEMY_CACHE_TTL   = 0.08

local function getEnemies()
	local now = os.clock()
	if now - enemyCacheTime < ENEMY_CACHE_TTL then return cachedEnemies end
	local result = {}
	for _, player in ipairs(playersService:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and isEnemy(player) then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				table.insert(result, player)
			end
		end
	end
	cachedEnemies  = result
	enemyCacheTime = now
	return result
end

playersService.PlayerRemoving:Connect(function() enemyCacheTime = 0 end)
playersService.PlayerAdded:Connect(function() enemyCacheTime = 0 end)

local function getCrosshairPosition()
	if not Camera then return Vector2.new(0, 0) end
	if userInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		local vp = Camera.ViewportSize
		return Vector2.new(vp.X / 2, vp.Y / 2)
	end
	return userInputService:GetMouseLocation()
end

local function worldToScreen(position)
	if not Camera then return nil, false end
	local ok, result = pcall(function() return Camera:WorldToScreenPoint(position) end)
	if not ok or not result then return nil, false end
	return Vector2.new(result.X, result.Y), result.Z > 0
end

local sharedRaycastParams = RaycastParams.new()
sharedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local raycastBlacklistDirty = true
local raycastBlacklistTime  = 0

local function getSharedRaycastParams(targetCharacter)
	local now = os.clock()
	if raycastBlacklistDirty or now - raycastBlacklistTime > 0.5 then
		local blacklist = {}
		if LocalPlayer.Character then table.insert(blacklist, LocalPlayer.Character) end
		for _, player in ipairs(playersService:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character ~= targetCharacter then
				table.insert(blacklist, player.Character)
			end
		end
		sharedRaycastParams.FilterDescendantsInstances = blacklist
		raycastBlacklistDirty = false
		raycastBlacklistTime  = now
	end
	return sharedRaycastParams
end

playersService.PlayerAdded:Connect(function()   raycastBlacklistDirty = true end)
playersService.PlayerRemoving:Connect(function() raycastBlacklistDirty = true end)

local function hasLineOfSight(targetPart)
	if not targetPart or not Camera then return false end
	local partParent = targetPart.Parent
	if not partParent then return false end
	local cameraPos = Camera.CFrame.Position
	local ok_pos, targetPos = pcall(function() return targetPart.Position end)
	if not ok_pos then return false end
	local offset   = targetPos - cameraPos
	local distance = offset.Magnitude
	if distance <= 0 then return false end
	local params = getSharedRaycastParams(partParent)
	local ok, rayResult = pcall(function()
		return workspace:Raycast(cameraPos, offset.Unit * distance, params)
	end)
	if not ok then return true end
	if not rayResult or not rayResult.Instance then return true end
	return rayResult.Instance:IsDescendantOf(partParent)
end

userInputService.JumpRequest:Connect(function()
	if Settings.InfJump_Enabled then
		local character = LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end
end)

local lockedTarget = nil

local function getAimTarget()
	local crosshair  = getCrosshairPosition()
	local localChar  = LocalPlayer.Character
	if not localChar then return nil end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart")
	if not localRoot then return nil end

	if lockedTarget then
		if not isEnemy(lockedTarget) then
			lockedTarget = nil
		else
			local character = lockedTarget.Character
			local head      = character and character:FindFirstChild("Head")
			local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
			if head and humanoid and humanoid.Health > 0 then
				local dist = (localRoot.Position - head.Position).Magnitude
				if dist > Settings.Triggerbot_MaxDistance then
					lockedTarget = nil
				elseif Settings.Aimbot_WallCheck and not hasLineOfSight(head) then
					lockedTarget = nil
				else
					return head
				end
			else
				lockedTarget = nil
			end
		end
	end

	local bestPlayer
	local bestDist = math.huge

	for _, player in ipairs(getEnemies()) do
		local character = player.Character
		if not character then continue end
		local head = character:FindFirstChild("Head")
		if not head then continue end
		local dist3d = (localRoot.Position - head.Position).Magnitude
		if dist3d > Settings.Triggerbot_MaxDistance then continue end
		local screenPos, onScreen = worldToScreen(head.Position)
		if screenPos and onScreen then
			local dist2d = (screenPos - crosshair).Magnitude
			if dist2d <= Settings.Aimbot_FOVRadius then
				if Settings.Aimbot_WallCheck and not hasLineOfSight(head) then continue end
				if dist2d < bestDist then
					bestDist   = dist2d
					bestPlayer = player
				end
			end
		end
	end

	if bestPlayer then
		lockedTarget = bestPlayer
		return bestPlayer.Character:FindFirstChild("Head")
	end

	return nil
end

local function forceAimAtHead(head)
	if not head or not head.Parent or not Camera then return false end
	local character = LocalPlayer.Character
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	local ok, headPos = pcall(function() return head.Position end)
	if not ok then return false end
	local camPos = Camera.CFrame.Position
	Camera.CFrame = CFrame.lookAt(camPos, headPos, Vector3.new(0, 1, 0))
	local rootPos = rootPart.Position
	rootPart.CFrame = CFrame.lookAt(rootPos, Vector3.new(headPos.X, rootPos.Y, headPos.Z), Vector3.new(0, 1, 0))
	return true
end

local function updateLockedBody()
	if not Settings.Aimbot_Enabled or not lockedTarget then return end
	if not isAimKeyHeld() then return end
	if not isEnemy(lockedTarget) then lockedTarget = nil return end

	local character = lockedTarget.Character
	local head      = character and character:FindFirstChild("Head")
	local humanoid  = character and character:FindFirstChildOfClass("Humanoid")

	if not character or not head or not humanoid or humanoid.Health <= 0 then
		lockedTarget = nil return
	end

	local localChar = LocalPlayer.Character
	if localChar then
		local localRoot = localChar:FindFirstChild("HumanoidRootPart")
		if localRoot then
			local ok, headPos = pcall(function() return head.Position end)
			if ok and (localRoot.Position - headPos).Magnitude > Settings.Triggerbot_MaxDistance then
				lockedTarget = nil return
			end
		end
	end

	if Settings.Aimbot_WallCheck and not hasLineOfSight(head) then
		lockedTarget = nil return
	end

	forceAimAtHead(head)
end

local HITBOX_PARTS = {
	"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
	"LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
	"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
}

local function getHitboxScreenBounds(part)
	if not Camera or not part or not part.Parent then return nil end
	local ok, cf, size = pcall(function()
		return part.CFrame, part.Size * 0.5
	end)
	if not ok or not cf or not size then return nil end

	local sx, sy = size.X, size.Y
	local sz = size.Z
	local corners = {
		cf * Vector3.new( sx,  sy,  sz), cf * Vector3.new(-sx,  sy,  sz),
		cf * Vector3.new( sx, -sy,  sz), cf * Vector3.new(-sx, -sy,  sz),
		cf * Vector3.new( sx,  sy, -sz), cf * Vector3.new(-sx,  sy, -sz),
		cf * Vector3.new( sx, -sy, -sz), cf * Vector3.new(-sx, -sy, -sz),
	}

	local minX, minY =  math.huge,  math.huge
	local maxX, maxY = -math.huge, -math.huge
	local anyOnScreen = false

	for _, corner in ipairs(corners) do
		local ok2, result = pcall(function() return Camera:WorldToScreenPoint(corner) end)
		if ok2 and result and result.Z > 0 then
			anyOnScreen = true
			if result.X < minX then minX = result.X end
			if result.Y < minY then minY = result.Y end
			if result.X > maxX then maxX = result.X end
			if result.Y > maxY then maxY = result.Y end
		end
	end

	if not anyOnScreen then return nil end
	return minX, minY, maxX, maxY
end

local function shouldFire()
	if not Camera then return false end
	if not isInActiveRound() then return false end
	if not isTriggerKeyHeld() then return false end

	if Settings.Aimbot_Enabled and lockedTarget and isEnemy(lockedTarget) and isAimKeyHeld() then
		local character = lockedTarget.Character
		local head      = character and character:FindFirstChild("Head")
		local humanoid  = character and character:FindFirstChildOfClass("Humanoid")

		if head and humanoid and humanoid.Health > 0 then
			local los = hasLineOfSight(head)
			if los then
				local aimed = forceAimAtHead(head)
				if aimed then return true end
			else
				lockedTarget = nil
			end
		else
			lockedTarget = nil
		end
	end

	if not Settings.Triggerbot_Enabled then return false end

	local crosshair = getCrosshairPosition()
	local cx, cy    = crosshair.X, crosshair.Y
	local camPos    = Camera.CFrame.Position

	for _, player in ipairs(getEnemies()) do
		local character = player.Character
		if not character then continue end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root.Parent then continue end
		local ok_rp, rootPos = pcall(function() return root.Position end)
		if not ok_rp then continue end
		if (rootPos - camPos).Magnitude > Settings.Triggerbot_MaxDistance then continue end

		for _, partName in ipairs(HITBOX_PARTS) do
			local part = character:FindFirstChild(partName)
			if part then
				if not hasLineOfSight(part) then continue end
				local minX, minY, maxX, maxY = getHitboxScreenBounds(part)
				if minX and cx >= minX and cx <= maxX and cy >= minY and cy <= maxY then
					return true
				end
			end
		end
	end

	return false
end

local tracerLines = {}

local function getTracerLine(player)
	if tracerLines[player] then return tracerLines[player] end
	local ok, result = pcall(function()
		local d = Drawing.new("Line")
		d.Thickness = 1.5
		d.Color = Color3.fromRGB(255, 255, 255)
		d.Transparency = 1
		d.Visible = false
		return d
	end)
	if ok and result then
		tracerLines[player] = result
		return result
	end
	return nil
end

local function removeTracerLine(player)
	local line = tracerLines[player]
	if line then
		pcall(function() line.Visible = false line:Remove() end)
		tracerLines[player] = nil
	end
end

local function hideTracerLines()
	for _, line in pairs(tracerLines) do
		pcall(function() line.Visible = false end)
	end
end

playersService.PlayerRemoving:Connect(function(player)
	removeTracerLine(player)
	clearTeamCache(player)
	enemyCacheTime = 0
	raycastBlacklistDirty = true
end)

local function updateTracer()
	if not Settings.ESP_Enabled or not Settings.ESP_Tracer then
		hideTracerLines() return
	end
	local localCharacter = LocalPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRoot or not Camera then hideTracerLines() return end

	local vp = Camera.ViewportSize
	local origin = Vector2.new(vp.X / 2, vp.Y / 2)
	local seen   = {}

	for _, player in ipairs(getEnemies()) do
		local character = player.Character
		local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
		local root      = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local ok_rp, rootPos = pcall(function() return root.Position end)
			if ok_rp and (rootPos - localRoot.Position).Magnitude <= 1000 then
				local head      = character:FindFirstChild("Head")
				local ok_hp, targetPos = pcall(function()
					return head and head.Position or root.Position
				end)
				if ok_hp then
					local ok_sp, sp = pcall(function() return Camera:WorldToViewportPoint(targetPos) end)
					if ok_sp and sp.Z > 0 then
						local line = getTracerLine(player)
						if line then
							line.From    = origin
							line.To      = Vector2.new(sp.X, sp.Y)
							line.Visible = true
							seen[player] = true
						end
					end
				end
			end
		end
	end

	for player, line in pairs(tracerLines) do
		if not seen[player] then
			pcall(function() line.Visible = false end)
		end
	end
end

local circleDraw = nil
pcall(function()
	if Drawing then
		circleDraw           = Drawing.new("Circle")
		circleDraw.Thickness = 2
		circleDraw.Color     = Color3.fromRGB(255, 0, 0)
		circleDraw.Filled    = false
		circleDraw.Visible   = false
	end
end)

local function updateCircle()
	if not circleDraw then return end
	if Settings.Aimbot_Enabled and isAimKeyHeld() then
		circleDraw.Position = getCrosshairPosition()
		circleDraw.Radius   = Settings.Aimbot_FOVRadius
		circleDraw.Visible  = true
	else
		circleDraw.Visible = false
	end
end

local AutoclickActive = false

local function removeESPObjects(character)
	if not character then return end
	for _, name in ipairs({ "ESP_Highlight", "ESP_Billboard", "ESP_HealthBar", "HealthBackground", "HealthOutline" }) do
		local obj = character:FindFirstChild(name)
		if obj then obj:Destroy() end
	end
end

local ESP_GUI_WIDTH     = 220
local ESP_GUI_HEIGHT    = 58
local HEALTH_BAR_WIDTH  = 120
local HEALTH_BAR_HEIGHT = 7

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function createESPBillboard(character, head)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_Billboard"
	billboard.Adornee = head
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = Settings.ESP_MaxDistance
	billboard.Size = UDim2.fromOffset(ESP_GUI_WIDTH, ESP_GUI_HEIGHT)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.7, 0)
	billboard.ClipsDescendants = false
	billboard.Parent = character

	local healthOutline = Instance.new("Frame")
	healthOutline.Name = "HealthOutline"
	healthOutline.Position = UDim2.fromOffset((ESP_GUI_WIDTH - HEALTH_BAR_WIDTH) / 2 - 1, 1)
	healthOutline.Size = UDim2.fromOffset(HEALTH_BAR_WIDTH + 2, HEALTH_BAR_HEIGHT + 2)
	healthOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	healthOutline.BackgroundTransparency = 0.15
	healthOutline.BorderSizePixel = 0
	healthOutline.ZIndex = 5
	healthOutline.Parent = billboard
	makeCorner(healthOutline, 4)

	local healthBackground = Instance.new("Frame")
	healthBackground.Name = "HealthBackground"
	healthBackground.Position = UDim2.fromOffset(1, 1)
	healthBackground.Size = UDim2.fromOffset(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	healthBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	healthBackground.BorderSizePixel = 0
	healthBackground.ZIndex = 6
	healthBackground.Parent = healthOutline
	makeCorner(healthBackground, 3)

	local healthBar = Instance.new("Frame")
	healthBar.Name = "ESP_HealthBar"
	healthBar.Position = UDim2.fromOffset(0, 0)
	healthBar.Size = UDim2.fromOffset(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
	healthBar.BorderSizePixel = 0
	healthBar.ZIndex = 7
	healthBar.Parent = healthBackground
	makeCorner(healthBar, 3)

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "ESP_Info"
	infoLabel.Position = UDim2.fromOffset(0, 14)
	infoLabel.Size = UDim2.fromOffset(ESP_GUI_WIDTH, 22)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 14
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.TextStrokeTransparency = 0.45
	infoLabel.TextXAlignment = Enum.TextXAlignment.Center
	infoLabel.TextYAlignment = Enum.TextYAlignment.Center
	infoLabel.Text = ""
	infoLabel.ZIndex = 8
	infoLabel.Parent = billboard

	return billboard
end

local function updateESP()
	if not Settings.ESP_Enabled then
		for _, player in ipairs(playersService:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				removeESPObjects(player.Character)
			end
		end
		return
	end

	local localCharacter = LocalPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRoot or not Camera then return end

	for _, player in ipairs(playersService:GetPlayers()) do
		if player == LocalPlayer then continue end
		local character = player.Character
		if not character then continue end

		if not isEnemy(player) then removeESPObjects(character) continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root     = character:FindFirstChild("HumanoidRootPart")
		local head     = character:FindFirstChild("Head")

		if not humanoid or humanoid.Health <= 0 or not root or not head then
			removeESPObjects(character) continue
		end

		local ok_rp, rootPos = pcall(function() return root.Position end)
		if not ok_rp then removeESPObjects(character) continue end

		local distance = (rootPos - localRoot.Position).Magnitude
		if distance > Settings.ESP_MaxDistance then removeESPObjects(character) continue end

		local highlight = character:FindFirstChild("ESP_Highlight")
		if Settings.ESP_Highlight then
			if not highlight then
				highlight = Instance.new("Highlight")
				highlight.Name = "ESP_Highlight"
				highlight.Adornee = character
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = character
			end
			highlight.FillColor           = ESP_BOX_COLOR
			highlight.FillTransparency    = Settings.ESP_BoxTransparency
			highlight.OutlineColor        = ESP_BOX_COLOR
			highlight.OutlineTransparency = 0
			highlight.Enabled             = true
		elseif highlight then
			highlight:Destroy()
		end

		local billboard = character:FindFirstChild("ESP_Billboard")
		if not billboard or not billboard:IsA("BillboardGui") then
			if billboard then billboard:Destroy() end
			billboard = createESPBillboard(character, head)
		end

		billboard.Adornee               = head
		billboard.AlwaysOnTop           = true
		billboard.LightInfluence        = 0
		billboard.MaxDistance           = Settings.ESP_MaxDistance
		billboard.Size                  = UDim2.fromOffset(ESP_GUI_WIDTH, ESP_GUI_HEIGHT)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.7, 0)
		billboard.Enabled               = true

		local healthOutline    = billboard:FindFirstChild("HealthOutline")
		local healthBackground = healthOutline and healthOutline:FindFirstChild("HealthBackground")
		local healthBar        = healthBackground and healthBackground:FindFirstChild("ESP_HealthBar")

		if not healthOutline or not healthBackground or not healthBar then
			billboard:Destroy()
			billboard        = createESPBillboard(character, head)
			healthOutline    = billboard:FindFirstChild("HealthOutline")
			healthBackground = healthOutline and healthOutline:FindFirstChild("HealthBackground")
			healthBar        = healthBackground and healthBackground:FindFirstChild("ESP_HealthBar")
		end

		local healthPercent = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)

		if healthBar then
			healthBar.Size = UDim2.fromOffset(
				math.max(0, math.floor(HEALTH_BAR_WIDTH * healthPercent)),
				HEALTH_BAR_HEIGHT)
			if healthPercent > 0.6 then
				healthBar.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
			elseif healthPercent > 0.3 then
				healthBar.BackgroundColor3 = Color3.fromRGB(255, 190, 0)
			else
				healthBar.BackgroundColor3 = Color3.fromRGB(235, 45, 45)
			end
		end

		local infoLabel = billboard:FindFirstChild("ESP_Info")
		if infoLabel then
			local showName  = Settings.ESP_Name
			local showStuds = Settings.ESP_Studs
			if showName and showStuds then
				infoLabel.Text    = player.Name .. " | " .. string.format("%.1f studs", distance)
				infoLabel.Visible = true
			elseif showName then
				infoLabel.Text    = player.Name
				infoLabel.Visible = true
			elseif showStuds then
				infoLabel.Text    = string.format("%.1f studs", distance)
				infoLabel.Visible = true
			else
				infoLabel.Text    = ""
				infoLabel.Visible = false
			end
		end
	end
end

-- Autoclick loop: only fires if AutoclickActive AND trigger key held (if enabled)
task.spawn(function()
	while true do
		if AutoclickActive and not isVoteScreenActive() and isTriggerKeyHeld() then
			if not Camera then Camera = workspace.CurrentCamera end
			if Camera then
				local vp = Camera.ViewportSize
				if vp then
					local cx = vp.X / 2
					local cy = vp.Y / 2
					virtualInputManager:SendMouseButtonEvent(cx, cy, 0, true,  game, 0)
					virtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
				end
			end
		end
		task.wait()
	end
end)

task.spawn(function()
	runService.RenderStepped:Connect(function()
		if not Camera then Camera = workspace.CurrentCamera end
		if not Camera then return end
		if not LocalPlayer.Character then return end

		updateCircle()
		updateTracer()

		if Settings.Aimbot_Enabled and isAimKeyHeld() then
			if lockedTarget then
				updateLockedBody()
			else
				local targetHead = getAimTarget()
				if targetHead then forceAimAtHead(targetHead) end
			end
		else
			lockedTarget = nil
		end

		if Settings.Triggerbot_Enabled and isTriggerKeyHeld() then
			AutoclickActive = shouldFire()
		else
			AutoclickActive = false
		end
	end)
end)

task.spawn(function()
	while task.wait(0.15) do
		pcall(updateESP)
	end
end)

-- ============================================================
-- BUILD UI
-- ============================================================
local WindUI = getWindUILibrary()
local window = createPotentWindow(WindUI, "POTENTHUB_RIVALS", "Rivals")

local combatTab = window:Tab({ Title = "⚔️ Combat", Icon = "crosshair" })
local visualTab = window:Tab({ Title = "👁️ Visuals", Icon = "eye" })
local playerTab = window:Tab({ Title = "👤 Player", Icon = "user" })
local spoofTab = window:Tab({ Title = "🎭 Spoofer", Icon = "monitor" })
local settingsTab = window:Tab({ Title = "⚙️ Settings", Icon = "settings" })

-- Combat Tab
combatTab:Section({ Title = "🎯 Aimbot" })
combatTab:Toggle({
	Title = "Aimbot",
	Value = Settings.Aimbot_Enabled,
	Callback = function(v) Settings.Aimbot_Enabled = v saveSettings(Settings) end,
})
combatTab:Toggle({
	Title = "Only When Key Held",
	Desc = "Aimbot only activates while holding the aim key",
	Value = Settings.Aimbot_OnlyWhenHeld,
	Callback = function(v) Settings.Aimbot_OnlyWhenHeld = v saveSettings(Settings) end,
})
combatTab:Dropdown({
	Title = "Aim Hold Key",
	Values = { "RMB", "LMB", "E", "Q", "F" },
	Value = Settings.Aimbot_HoldKey,
	Callback = function(v) Settings.Aimbot_HoldKey = v saveSettings(Settings) end,
})
combatTab:Toggle({
	Title = "Wall Check",
	Value = Settings.Aimbot_WallCheck,
	Callback = function(v) Settings.Aimbot_WallCheck = v saveSettings(Settings) end,
})
combatTab:Slider({
	Title = "Aimbot FOV",
	Step = 5,
	Value = { Min = 20, Max = 500, Default = Settings.Aimbot_FOVRadius },
	Callback = function(v) Settings.Aimbot_FOVRadius = v saveSettings(Settings) end,
})

combatTab:Section({ Title = "🔫 Triggerbot" })
combatTab:Toggle({
	Title = "Triggerbot",
	Value = Settings.Triggerbot_Enabled,
	Callback = function(v) Settings.Triggerbot_Enabled = v saveSettings(Settings) end,
})
combatTab:Toggle({
	Title = "Only When Key Held",
	Desc = "Triggerbot only fires while holding the trigger key",
	Value = Settings.Triggerbot_OnlyWhenKeyHeld,
	Callback = function(v) Settings.Triggerbot_OnlyWhenKeyHeld = v saveSettings(Settings) end,
})
combatTab:Dropdown({
	Title = "Trigger Key",
	Values = { "RMB", "LMB", "E", "Q", "F" },
	Value = Settings.Triggerbot_Key,
	Callback = function(v) Settings.Triggerbot_Key = v saveSettings(Settings) end,
})

-- Visuals Tab
visualTab:Section({ Title = "👁️ ESP Master" })
visualTab:Toggle({
	Title = "ESP Enabled",
	Value = Settings.ESP_Enabled,
	Callback = function(v) Settings.ESP_Enabled = v saveSettings(Settings) end,
})
visualTab:Toggle({
	Title = "Highlight",
	Value = Settings.ESP_Highlight,
	Callback = function(v) Settings.ESP_Highlight = v saveSettings(Settings) end,
})
visualTab:Toggle({
	Title = "Name",
	Value = Settings.ESP_Name,
	Callback = function(v) Settings.ESP_Name = v saveSettings(Settings) end,
})
visualTab:Toggle({
	Title = "Studs",
	Value = Settings.ESP_Studs,
	Callback = function(v) Settings.ESP_Studs = v saveSettings(Settings) end,
})
visualTab:Toggle({
	Title = "Tracer",
	Value = Settings.ESP_Tracer,
	Callback = function(v) Settings.ESP_Tracer = v saveSettings(Settings) end,
})
visualTab:Slider({
	Title = "Max Distance",
	Step = 25,
	Value = { Min = 50, Max = 2000, Default = Settings.ESP_MaxDistance },
	Callback = function(v) Settings.ESP_MaxDistance = v saveSettings(Settings) end,
})
visualTab:Slider({
	Title = "Box Transparency",
	Step = 0.05,
	Value = { Min = 0, Max = 1, Default = Settings.ESP_BoxTransparency },
	Callback = function(v) Settings.ESP_BoxTransparency = v saveSettings(Settings) end,
})

-- Player Tab
playerTab:Section({ Title = "🏃 Movement" })
playerTab:Toggle({
	Title = "Infinite Jump",
	Value = Settings.InfJump_Enabled,
	Callback = function(v) Settings.InfJump_Enabled = v saveSettings(Settings) end,
})

-- Spoofer Tab
spoofTab:Section({ Title = "🎭 Device Spoofer" })

local SPOOFER_DEVICES = {
	{ label = "PC  (Mouse & Keyboard)", value = "MouseKeyboard" },
	{ label = "Console  (Gamepad)",      value = "Gamepad"       },
	{ label = "Mobile  (Touch)",         value = "Touch"         },
	{ label = "VR",                      value = "VR"            },
}

for _, device in ipairs(SPOOFER_DEVICES) do
	spoofTab:Button({
		Title = "Spoof as " .. device.label,
		Callback = function()
			Settings.DeviceSpoofer_Active = device.value
			spoofDevice(device.value)
			saveSettings(Settings)
			WindUI:Notify({ Title = "Spoofer", Content = "Spoofed as " .. device.label, Duration = 3 })
		end,
	})
end

spoofTab:Button({
	Title = "Reset Spoofer (PC)",
	Callback = function()
		Settings.DeviceSpoofer_Active = nil
		spoofDevice("MouseKeyboard")
		saveSettings(Settings)
		WindUI:Notify({ Title = "Spoofer", Content = "Spoofer reset", Duration = 3 })
	end,
})

local spooferStatus = spoofTab:Paragraph({
	Title = "Current Spoof",
	Desc = Settings.DeviceSpoofer_Active or "None",
})

task.spawn(function()
	while task.wait(1) do
		pcall(function()
			spooferStatus:SetDesc(Settings.DeviceSpoofer_Active or "None")
		end)
	end
end)

-- Settings Tab
settingsTab:Section({ Title = "⚙️ System" })
settingsTab:Button({
	Title = "🗑️ Unload GUI",
	Callback = function()
		_G.__rivals_loaded = false
		window:Destroy()
	end,
})
settingsTab:Button({
	Title = "📋 Copy POTENT HUB Discord",
	Callback = function()
		customSetClipboard(POTENT_DISCORD_URL)
		WindUI:Notify({ Title = "Copied!", Content = "Discord link copied", Duration = 3 })
	end,
})

WindUI:Notify({ Title = "⚡ POTENT HUB", Content = "✅ Rivals loaded!", Duration = 4 })
