local GuiLibrary = shared.GuiLibrary
local playersService = game:GetService("Players")
local textService = game:GetService("TextService")
local lightingService = game:GetService("Lighting")
local textChatService = game:GetService("TextChatService")
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vapeConnections = {}
local vapeCachedAssets = {}
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new("BindableEvent")
		return self[index]
	end
})
local vapeTargetInfo = shared.VapeTargetInfo
local vapeInjected = true

local bedwars = {}
local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	blocks = {},
	blockPlacer = {},
	blockPlace = tick(),
	blockRaycast = RaycastParams.new(),
	equippedKit = "none",
	forgeMasteryPoints = 0,
	forgeUpgrades = {},
	grapple = tick(),
	inventories = {},
	localInventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	localHand = {},
	matchState = 0,
	matchStateChanged = tick(),
	pots = {},
	queueType = "bedwars_test",
	scythe = tick(),
	statistics = {
		beds = 0,
		kills = 0,
		lagbacks = 0,
		lagbackEvent = Instance.new("BindableEvent"),
		reported = 0,
		universalLagbacks = 0
	},
	whitelist = {
		chatStrings1 = {helloimusinginhaler = "vape"},
		chatStrings2 = {vape = "helloimusinginhaler"},
		clientUsers = {},
		oldChatFunctions = {}
	},
	zephyrOrb = 0
}
store.blockRaycast.FilterType = Enum.RaycastFilterType.Include
local AutoLeave = {Enabled = false}

table.insert(vapeConnections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA("Camera")
end))
local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil
end
local networkownerswitch = tick()
--ME WHEN THE MOBILE EXPLOITS ADD A DISFUNCTIONAL ISNETWORKOWNER (its for compatability I swear!!)
local isnetworkowner = function(part)
	local suc, res = pcall(function() return gethiddenproperty(part, "NetworkOwnershipRule") end)
	if suc and res == Enum.NetworkOwnership.Manual then
		sethiddenproperty(part, "NetworkOwnershipRule", Enum.NetworkOwnership.Automatic)
		networkownerswitch = tick() + 8
	end
	return networkownerswitch <= tick()
end
local getcustomasset = getsynasset or getcustomasset or function(location) return "rbxasset://"..location end
local queueonteleport = syn and syn.queue_on_teleport or queue_on_teleport or function() end
local synapsev3 = syn and syn.toast_notification and "V3" or ""
local worldtoscreenpoint = function(pos)
	if synapsev3 == "V3" then
		local scr = worldtoscreen({pos})
		return scr[1] - Vector3.new(0, 36, 0), scr[1].Z > 0
	end
	return gameCamera.WorldToScreenPoint(gameCamera, pos)
end
local worldtoviewportpoint = function(pos)
	if synapsev3 == "V3" then
		local scr = worldtoscreen({pos})
		return scr[1], scr[1].Z > 0
	end
	return gameCamera.WorldToViewportPoint(gameCamera, pos)
end

local function vapeGithubRequest(scripturl)
	if not isfile("vape/"..scripturl) then
		local suc, res = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/V1per-Dev/Lunar-Client/"..readfile("vape/commithash.txt").."/"..scripturl, true) end)
		assert(suc, res)
		assert(res ~= "404: Not Found", res)
		if scripturl:find(".lua") then res = "--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.\n"..res end
		writefile("vape/"..scripturl, res)
	end
	return readfile("vape/"..scripturl)
end

local function downloadVapeAsset(path)
	if not isfile(path) then
		task.spawn(function()
			local textlabel = Instance.new("TextLabel")
			textlabel.Size = UDim2.new(1, 0, 0, 36)
			textlabel.Text = "Downloading "..path
			textlabel.BackgroundTransparency = 1
			textlabel.TextStrokeTransparency = 0
			textlabel.TextSize = 30
			textlabel.Font = Enum.Font.SourceSans
			textlabel.TextColor3 = Color3.new(1, 1, 1)
			textlabel.Position = UDim2.new(0, 0, 0, -36)
			textlabel.Parent = GuiLibrary.MainGui
			repeat task.wait() until isfile(path)
			textlabel:Destroy()
		end)
		local suc, req = pcall(function() return vapeGithubRequest(path:gsub("vape/assets", "assets")) end)
		if suc and req then
			writefile(path, req)
		else
			return ""
		end
	end
	if not vapeCachedAssets[path] then vapeCachedAssets[path] = getcustomasset(path) end
	return vapeCachedAssets[path]
end

local function warningNotification(title, text, delay)
	local suc, res = pcall(function()
		local frame = GuiLibrary.CreateNotification(title, text, delay, "assets/WarningNotification.png")
		frame.Frame.Frame.ImageColor3 = Color3.fromRGB(236, 129, 44)
		return frame
	end)
	return (suc and res)
end

local function run(func) func() end

local function isFriend(plr, recolor)
	if GuiLibrary.ObjectsThatCanBeSaved["Use FriendsToggle"].Api.Enabled then
		local friend = table.find(GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectList, plr.Name)
		friend = friend and GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectListEnabled[friend]
		if recolor then
			friend = friend and GuiLibrary.ObjectsThatCanBeSaved["Recolor visualsToggle"].Api.Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	local friend = table.find(GuiLibrary.ObjectsThatCanBeSaved.TargetsListTextCircleList.Api.ObjectList, plr.Name)
	friend = friend and GuiLibrary.ObjectsThatCanBeSaved.TargetsListTextCircleList.Api.ObjectListEnabled[friend]
	return friend
end

local function isVulnerable(plr)
	return plr.Humanoid.Health > 0 and not plr.Character.FindFirstChildWhichIsA(plr.Character, "ForceField")
end

local function getPlayerColor(plr)
	if isFriend(plr, true) then
		return Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Value)
	end
	return tostring(plr.TeamColor) ~= "White" and plr.TeamColor.Color
end

local function LaunchAngle(v, g, d, h, higherArc)
	local v2 = v * v
	local v4 = v2 * v2
	local root = -math.sqrt(v4 - g*(g*d*d + 2*h*v2))
	return math.atan((v2 + root) / (g * d))
end

local function LaunchDirection(start, target, v, g)
	local horizontal = Vector3.new(target.X - start.X, 0, target.Z - start.Z)
	local h = target.Y - start.Y
	local d = horizontal.Magnitude
	local a = LaunchAngle(v, g, d, h)

	if a ~= a then
		return g == 0 and (target - start).Unit * v
	end

	local vec = horizontal.Unit * v
	local rotAxis = Vector3.new(-horizontal.Z, 0, horizontal.X)
	return CFrame.fromAxisAngle(rotAxis, a) * vec
end

local physicsUpdate = 1 / 60

local function predictGravity(playerPosition, vel, bulletTime, targetPart, Gravity)
	local estimatedVelocity = vel.Y
	local rootSize = (targetPart.Humanoid.HipHeight + (targetPart.RootPart.Size.Y / 2))
	local velocityCheck = (tick() - targetPart.JumpTick) < 0.2
	vel = vel * physicsUpdate

	for i = 1, math.ceil(bulletTime / physicsUpdate) do
		if velocityCheck then
			estimatedVelocity = estimatedVelocity - (Gravity * physicsUpdate)
		else
			estimatedVelocity = 0
			playerPosition = playerPosition + Vector3.new(0, -0.03, 0) -- bw hitreg is so bad that I have to add this LOL
			rootSize = rootSize - 0.03
		end

		local floorDetection = workspace:Raycast(playerPosition, Vector3.new(vel.X, (estimatedVelocity * physicsUpdate) - rootSize, vel.Z), store.blockRaycast)
		if floorDetection then
			playerPosition = Vector3.new(playerPosition.X, floorDetection.Position.Y + rootSize, playerPosition.Z)
			local bouncepad = floorDetection.Instance:FindFirstAncestor("gumdrop_bounce_pad")
			if bouncepad and bouncepad:GetAttribute("PlacedByUserId") == targetPart.Player.UserId then
				estimatedVelocity = 130 - (Gravity * physicsUpdate)
				velocityCheck = true
			else
				estimatedVelocity = targetPart.Humanoid.JumpPower - (Gravity * physicsUpdate)
				velocityCheck = targetPart.Jumping
			end
		end

		playerPosition = playerPosition + Vector3.new(vel.X, velocityCheck and estimatedVelocity * physicsUpdate or 0, vel.Z)
	end

	return playerPosition, Vector3.new(0, 0, 0)
end

local entityLibrary = shared.vapeentity
local whitelist = shared.vapewhitelist
local RunLoops = {RenderStepTable = {}, StepTable = {}, HeartTable = {}}
do
	function RunLoops:BindToRenderStep(name, func)
		if RunLoops.RenderStepTable[name] == nil then
			RunLoops.RenderStepTable[name] = runService.RenderStepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromRenderStep(name)
		if RunLoops.RenderStepTable[name] then
			RunLoops.RenderStepTable[name]:Disconnect()
			RunLoops.RenderStepTable[name] = nil
		end
	end

	function RunLoops:BindToStepped(name, func)
		if RunLoops.StepTable[name] == nil then
			RunLoops.StepTable[name] = runService.Stepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromStepped(name)
		if RunLoops.StepTable[name] then
			RunLoops.StepTable[name]:Disconnect()
			RunLoops.StepTable[name] = nil
		end
	end

	function RunLoops:BindToHeartbeat(name, func)
		if RunLoops.HeartTable[name] == nil then
			RunLoops.HeartTable[name] = runService.Heartbeat:Connect(func)
		end
	end

	function RunLoops:UnbindFromHeartbeat(name)
		if RunLoops.HeartTable[name] then
			RunLoops.HeartTable[name]:Disconnect()
			RunLoops.HeartTable[name] = nil
		end
	end
end

GuiLibrary.SelfDestructEvent.Event:Connect(function()
	vapeInjected = false
	for i, v in pairs(vapeConnections) do
		if v.Disconnect then pcall(function() v:Disconnect() end) continue end
		if v.disconnect then pcall(function() v:disconnect() end) continue end
	end
end)

local function getItem(itemName, inv)
	for slot, item in pairs(inv or store.localInventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
end

local function getItemNear(itemName, inv)
	for slot, item in pairs(inv or store.localInventory.inventory.items) do
		if item.itemType == itemName or item.itemType:find(itemName) then
			return item, slot
		end
	end
	return nil
end

local function getHotbarSlot(itemName)
	for slotNumber, slotTable in pairs(store.localInventory.hotbar) do
		if slotTable.item and slotTable.item.itemType == itemName then
			return slotNumber - 1
		end
	end
	return nil
end

local function getShieldAttribute(char)
	local returnedShield = 0
	for attributeName, attributeValue in pairs(char:GetAttributes()) do
		if attributeName:find("Shield") and type(attributeValue) == "number" then
			returnedShield = returnedShield + attributeValue
		end
	end
	return returnedShield
end

local function getPickaxe()
	return getItemNear("pick")
end

local function getAxe()
	local bestAxe, bestAxeSlot = nil, nil
	for slot, item in pairs(store.localInventory.inventory.items) do
		if item.itemType:find("axe") and item.itemType:find("pickaxe") == nil and item.itemType:find("void") == nil then
			bextAxe, bextAxeSlot = item, slot
		end
	end
	return bestAxe, bestAxeSlot
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in pairs(store.localInventory.inventory.items) do
		local swordMeta = bedwars.ItemTable[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end

local function getBow()
	local bestBow, bestBowSlot, bestBowStrength = nil, nil, 0
	for slot, item in pairs(store.localInventory.inventory.items) do
		if item.itemType:find("bow") then
			local tab = bedwars.ItemTable[item.itemType].projectileSource
			local ammo = tab.projectileType("arrow")
			local dmg = bedwars.ProjectileMeta[ammo].combat.damage
			if dmg > bestBowStrength then
				bestBow, bestBowSlot, bestBowStrength = item, slot, dmg
			end
		end
	end
	return bestBow, bestBowSlot
end

local function getWool()
	local wool = getItemNear("wool")
	return wool and wool.itemType, wool and wool.amount
end

local function getBlock()
	for slot, item in pairs(store.localInventory.inventory.items) do
		if bedwars.ItemTable[item.itemType].block then
			return item.itemType, item.amount
		end
	end
end

local function attackValue(vec)
	return {value = vec}
end

local function getSpeed()
	local speed = 0
	if lplr.Character then
		local SpeedDamageBoost = lplr.Character:GetAttribute("SpeedBoost")
		if SpeedDamageBoost and SpeedDamageBoost > 1 then
			speed = speed + (8 * (SpeedDamageBoost - 1))
		end
		if store.grapple > tick() then
			speed = speed + 90
		end
		if store.scythe > tick() then
			speed = speed + 5
		end
		if lplr.Character:GetAttribute("GrimReaperChannel") then
			speed = speed + 20
		end
		local armor = store.localInventory.inventory.armor[3]
		if type(armor) ~= "table" then armor = {itemType = ""} end
		if armor.itemType == "speed_boots" then
			speed = speed + 12
		end
		if store.zephyrOrb ~= 0 then
			speed = speed + 12
		end
	end
	return speed
end

local Reach = {Enabled = false}
local blacklistedblocks = {
	bed = true,
	ceramic = true
}
local cachedNormalSides = {}
for i,v in pairs(Enum.NormalId:GetEnumItems()) do if v.Name ~= "Bottom" then table.insert(cachedNormalSides, v) end end
local updateitem = Instance.new("BindableEvent")
table.insert(vapeConnections, updateitem.Event:Connect(function(inputObj)
	if inputService:IsMouseButtonPressed(0) then
		game:GetService("ContextActionService"):CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
	end
end))

local function getPlacedBlock(pos)
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end

local oldpos = Vector3.zero

local function getScaffold(vec, diagonaltoggle)
	local realvec = Vector3.new(math.floor((vec.X / 3) + 0.5) * 3, math.floor((vec.Y / 3) + 0.5) * 3, math.floor((vec.Z / 3) + 0.5) * 3)
	local speedCFrame = (oldpos - realvec)
	local returedpos = realvec
	if entityLibrary.isAlive then
		local angle = math.deg(math.atan2(-entityLibrary.character.Humanoid.MoveDirection.X, -entityLibrary.character.Humanoid.MoveDirection.Z))
		local goingdiagonal = (angle >= 130 and angle <= 150) or (angle <= -35 and angle >= -50) or (angle >= 35 and angle <= 50) or (angle <= -130 and angle >= -150)
		if goingdiagonal and ((speedCFrame.X == 0 and speedCFrame.Z ~= 0) or (speedCFrame.X ~= 0 and speedCFrame.Z == 0)) and diagonaltoggle then
			return oldpos
		end
	end
	return realvec
end

local function getBestTool(block)
	local tool = nil
	local blockmeta = bedwars.ItemTable[block]
	local blockType = blockmeta.block and blockmeta.block.breakType
	if blockType then
		local best = 0
		for i,v in pairs(store.localInventory.inventory.items) do
			local meta = bedwars.ItemTable[v.itemType]
			if meta.breakBlock and meta.breakBlock[blockType] and meta.breakBlock[blockType] >= best then
				best = meta.breakBlock[blockType]
				tool = v
			end
		end
	end
	return tool
end

local function switchItem(tool)
	if lplr.Character.HandInvItem.Value ~= tool then
		bedwars.Client:Get(bedwars.EquipItemRemote):CallServerAsync({
			hand = tool
		})
		local started = tick()
		repeat task.wait() until (tick() - started) > 0.3 or lplr.Character.HandInvItem.Value == tool
	end
end

local function switchToAndUseTool(block, legit)
	local tool = getBestTool(block.Name)
	if tool and (entityLibrary.isAlive and lplr.Character:FindFirstChild("HandInvItem") and lplr.Character.HandInvItem.Value ~= tool.tool) then
		if legit then
			if getHotbarSlot(tool.itemType) then
				bedwars.ClientStoreHandler:dispatch({
					type = "InventorySelectHotbarSlot",
					slot = getHotbarSlot(tool.itemType)
				})
				vapeEvents.InventoryChanged.Event:Wait()
				updateitem:Fire(inputobj)
				return true
			else
				return false
			end
		end
		switchItem(tool.tool)
	end
end

local function isBlockCovered(pos)
	local coveredsides = 0
	for i, v in pairs(cachedNormalSides) do
		local blockpos = (pos + (Vector3.FromNormalId(v) * 3))
		local block = getPlacedBlock(blockpos)
		if block then
			coveredsides = coveredsides + 1
		end
	end
	return coveredsides == #cachedNormalSides
end

local function GetPlacedBlocksNear(pos, normal)
	local blocks = {}
	local lastfound = nil
	for i = 1, 20 do
		local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
		local extrablock = getPlacedBlock(blockpos)
		local covered = isBlockCovered(blockpos)
		if extrablock then
			if bedwars.BlockController:isBlockBreakable({blockPosition = blockpos}, lplr) and (not blacklistedblocks[extrablock.Name]) then
				table.insert(blocks, extrablock.Name)
			end
			lastfound = extrablock
			if not covered then
				break
			end
		else
			break
		end
	end
	return blocks
end

local function getLastCovered(pos, normal)
	local lastfound, lastpos = nil, nil
	for i = 1, 20 do
		local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
		local extrablock, extrablockpos = getPlacedBlock(blockpos)
		local covered = isBlockCovered(blockpos)
		if extrablock then
			lastfound, lastpos = extrablock, extrablockpos
			if not covered then
				break
			end
		else
			break
		end
	end
	return lastfound, lastpos
end

local function getBestBreakSide(pos)
	local softest, softestside = 9e9, Enum.NormalId.Top
	for i,v in pairs(cachedNormalSides) do
		local sidehardness = 0
		for i2,v2 in pairs(GetPlacedBlocksNear(pos, v)) do
			local blockmeta = bedwars.ItemTable[v2].block
			sidehardness = sidehardness + (blockmeta and blockmeta.health or 10)
			if blockmeta then
				local tool = getBestTool(v2)
				if tool then
					sidehardness = sidehardness - bedwars.ItemTable[tool.itemType].breakBlock[blockmeta.breakType]
				end
			end
		end
		if sidehardness <= softest then
			softest = sidehardness
			softestside = v
		end
	end
	return softestside, softest
end

local function EntityNearPosition(distance, ignore, overridepos)
	local closestEntity, closestMagnitude = nil, distance
	if entityLibrary.isAlive then
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.RootPart.Position).magnitude
				if overridepos and mag > distance then
					mag = (overridepos - v.RootPart.Position).magnitude
				end
				if mag <= closestMagnitude then
					closestEntity, closestMagnitude = v, mag
				end
			end
		end
		if not ignore then
			for i, v in pairs(collectionService:GetTagged("Monster")) do
				if v.PrimaryPart and v:GetAttribute("Team") ~= lplr:GetAttribute("Team") then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = v.Name, UserId = (v.Name == "Duck" and 2020831224 or 1443379645)}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("DiamondGuardian")) do
				if v.PrimaryPart then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = "DiamondGuardian", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("GolemBoss")) do
				if v.PrimaryPart then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = "GolemBoss", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("Drone")) do
				if v.PrimaryPart and tonumber(v:GetAttribute("PlayerUserId")) ~= lplr.UserId then
					local droneplr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
					if droneplr and droneplr.Team == lplr.Team then continue end
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then -- magcheck
						closestEntity, closestMagnitude = {Player = {Name = "Drone", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
		end
	end
	return closestEntity
end

local function EntityNearMouse(distance)
	local closestEntity, closestMagnitude = nil, distance
	if entityLibrary.isAlive then
		local mousepos = inputService.GetMouseLocation(inputService)
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local vec, vis = worldtoscreenpoint(v.RootPart.Position)
				local mag = (mousepos - Vector2.new(vec.X, vec.Y)).magnitude
				if vis and mag <= closestMagnitude then
					closestEntity, closestMagnitude = v, v.Target and -1 or mag
				end
			end
		end
	end
	return closestEntity
end

local function AllNearPosition(distance, amount, sortfunction, prediction)
	local returnedplayer = {}
	local currentamount = 0
	if entityLibrary.isAlive then
		local sortedentities = {}
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local playerPosition = v.RootPart.Position
				local mag = (entityLibrary.character.HumanoidRootPart.Position - playerPosition).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - playerPosition).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, v)
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("Monster")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					if v:GetAttribute("Team") == lplr:GetAttribute("Team") then continue end
					table.insert(sortedentities, {Player = {Name = v.Name, UserId = (v.Name == "Duck" and 2020831224 or 1443379645), GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("DiamondGuardian")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "DiamondGuardian", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("GolemBoss")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "GolemBoss", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("Drone")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					if tonumber(v:GetAttribute("PlayerUserId")) == lplr.UserId then continue end
					local droneplr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
					if droneplr and droneplr.Team == lplr.Team then continue end
					table.insert(sortedentities, {Player = {Name = "Drone", UserId = 1443379645}, GetAttribute = function() return "none" end, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(store.pots) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "Pot", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = {Health = 100, MaxHealth = 100}})
				end
			end
		end
		if sortfunction then
			table.sort(sortedentities, sortfunction)
		end
		for i,v in pairs(sortedentities) do
			table.insert(returnedplayer, v)
			currentamount = currentamount + 1
			if currentamount >= amount then break end
		end
	end
	return returnedplayer
end

--pasted from old source since gui code is hard
local function CreateAutoHotbarGUI(children2, argstable)
	local buttonapi = {}
	buttonapi["Hotbars"] = {}
	buttonapi["CurrentlySelected"] = 1
	local currentanim
	local amount = #children2:GetChildren()
	local sortableitems = {
		{itemType = "swords", itemDisplayType = "diamond_sword"},
		{itemType = "pickaxes", itemDisplayType = "diamond_pickaxe"},
		{itemType = "axes", itemDisplayType = "diamond_axe"},
		{itemType = "shears", itemDisplayType = "shears"},
		{itemType = "wool", itemDisplayType = "wool_white"},
		{itemType = "iron", itemDisplayType = "iron"},
		{itemType = "diamond", itemDisplayType = "diamond"},
		{itemType = "emerald", itemDisplayType = "emerald"},
		{itemType = "bows", itemDisplayType = "wood_bow"},
	}
	local items = bedwars.ItemTable
	if items then
		for i2,v2 in pairs(items) do
			if (i2:find("axe") == nil or i2:find("void")) and i2:find("bow") == nil and i2:find("shears") == nil and i2:find("wool") == nil and v2.sword == nil and v2.armor == nil and v2["dontGiveItem"] == nil and bedwars.ItemTable[i2] and bedwars.ItemTable[i2].image then
				table.insert(sortableitems, {itemType = i2, itemDisplayType = i2})
			end
		end
	end
	local buttontext = Instance.new("TextButton")
	buttontext.AutoButtonColor = false
	buttontext.BackgroundTransparency = 1
	buttontext.Name = "ButtonText"
	buttontext.Text = ""
	buttontext.Name = argstable["Name"]
	buttontext.LayoutOrder = 1
	buttontext.Size = UDim2.new(1, 0, 0, 40)
	buttontext.Active = false
	buttontext.TextColor3 = Color3.fromRGB(162, 162, 162)
	buttontext.TextSize = 17
	buttontext.Font = Enum.Font.SourceSans
	buttontext.Position = UDim2.new(0, 0, 0, 0)
	buttontext.Parent = children2
	local toggleframe2 = Instance.new("Frame")
	toggleframe2.Size = UDim2.new(0, 200, 0, 31)
	toggleframe2.Position = UDim2.new(0, 10, 0, 4)
	toggleframe2.BackgroundColor3 = Color3.fromRGB(38, 37, 38)
	toggleframe2.Name = "ToggleFrame2"
	toggleframe2.Parent = buttontext
	local toggleframe1 = Instance.new("Frame")
	toggleframe1.Size = UDim2.new(0, 198, 0, 29)
	toggleframe1.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	toggleframe1.BorderSizePixel = 0
	toggleframe1.Name = "ToggleFrame1"
	toggleframe1.Position = UDim2.new(0, 1, 0, 1)
	toggleframe1.Parent = toggleframe2
	local addbutton = Instance.new("ImageLabel")
	addbutton.BackgroundTransparency = 1
	addbutton.Name = "AddButton"
	addbutton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	addbutton.Position = UDim2.new(0, 93, 0, 9)
	addbutton.Size = UDim2.new(0, 12, 0, 12)
	addbutton.ImageColor3 = Color3.fromRGB(5, 133, 104)
	addbutton.Image = downloadVapeAsset("vape/assets/AddItem.png")
	addbutton.Parent = toggleframe1
	local children3 = Instance.new("Frame")
	children3.Name = argstable["Name"].."Children"
	children3.BackgroundTransparency = 1
	children3.LayoutOrder = amount
	children3.Size = UDim2.new(0, 220, 0, 0)
	children3.Parent = children2
	local uilistlayout = Instance.new("UIListLayout")
	uilistlayout.Parent = children3
	uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		children3.Size = UDim2.new(1, 0, 0, uilistlayout.AbsoluteContentSize.Y)
	end)
	local uicorner = Instance.new("UICorner")
	uicorner.CornerRadius = UDim.new(0, 5)
	uicorner.Parent = toggleframe1
	local uicorner2 = Instance.new("UICorner")
	uicorner2.CornerRadius = UDim.new(0, 5)
	uicorner2.Parent = toggleframe2
	buttontext.MouseEnter:Connect(function()
		tweenService:Create(toggleframe2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(79, 78, 79)}):Play()
	end)
	buttontext.MouseLeave:Connect(function()
		tweenService:Create(toggleframe2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(38, 37, 38)}):Play()
	end)
	local ItemListBigFrame = Instance.new("Frame")
	ItemListBigFrame.Size = UDim2.new(1, 0, 1, 0)
	ItemListBigFrame.Name = "ItemList"
	ItemListBigFrame.BackgroundTransparency = 1
	ItemListBigFrame.Visible = false
	ItemListBigFrame.Parent = GuiLibrary.MainGui
	local ItemListFrame = Instance.new("Frame")
	ItemListFrame.Size = UDim2.new(0, 660, 0, 445)
	ItemListFrame.Position = UDim2.new(0.5, -330, 0.5, -223)
	ItemListFrame.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	ItemListFrame.Parent = ItemListBigFrame
	local ItemListExitButton = Instance.new("ImageButton")
	ItemListExitButton.Name = "ItemListExitButton"
	ItemListExitButton.ImageColor3 = Color3.fromRGB(121, 121, 121)
	ItemListExitButton.Size = UDim2.new(0, 24, 0, 24)
	ItemListExitButton.AutoButtonColor = false
	ItemListExitButton.Image = downloadVapeAsset("vape/assets/ExitIcon1.png")
	ItemListExitButton.Visible = true
	ItemListExitButton.Position = UDim2.new(1, -31, 0, 8)
	ItemListExitButton.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	ItemListExitButton.Parent = ItemListFrame
	local ItemListExitButtonround = Instance.new("UICorner")
	ItemListExitButtonround.CornerRadius = UDim.new(0, 16)
	ItemListExitButtonround.Parent = ItemListExitButton
	ItemListExitButton.MouseEnter:Connect(function()
		tweenService:Create(ItemListExitButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(60, 60, 60), ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
	ItemListExitButton.MouseLeave:Connect(function()
		tweenService:Create(ItemListExitButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(26, 25, 26), ImageColor3 = Color3.fromRGB(121, 121, 121)}):Play()
	end)
	ItemListExitButton.MouseButton1Click:Connect(function()
		ItemListBigFrame.Visible = false
		GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = true
	end)
	local ItemListFrameShadow = Instance.new("ImageLabel")
	ItemListFrameShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	ItemListFrameShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	ItemListFrameShadow.Image = downloadVapeAsset("vape/assets/WindowBlur.png")
	ItemListFrameShadow.BackgroundTransparency = 1
	ItemListFrameShadow.ZIndex = -1
	ItemListFrameShadow.Size = UDim2.new(1, 6, 1, 6)
	ItemListFrameShadow.ImageColor3 = Color3.new(0, 0, 0)
	ItemListFrameShadow.ScaleType = Enum.ScaleType.Slice
	ItemListFrameShadow.SliceCenter = Rect.new(10, 10, 118, 118)
	ItemListFrameShadow.Parent = ItemListFrame
	local ItemListFrameText = Instance.new("TextLabel")
	ItemListFrameText.Size = UDim2.new(1, 0, 0, 41)
	ItemListFrameText.BackgroundTransparency = 1
	ItemListFrameText.Name = "WindowTitle"
	ItemListFrameText.Position = UDim2.new(0, 0, 0, 0)
	ItemListFrameText.TextXAlignment = Enum.TextXAlignment.Left
	ItemListFrameText.Font = Enum.Font.SourceSans
	ItemListFrameText.TextSize = 17
	ItemListFrameText.Text = "	New AutoHotbar"
	ItemListFrameText.TextColor3 = Color3.fromRGB(201, 201, 201)
	ItemListFrameText.Parent = ItemListFrame
	local ItemListBorder1 = Instance.new("Frame")
	ItemListBorder1.BackgroundColor3 = Color3.fromRGB(40, 39, 40)
	ItemListBorder1.BorderSizePixel = 0
	ItemListBorder1.Size = UDim2.new(1, 0, 0, 1)
	ItemListBorder1.Position = UDim2.new(0, 0, 0, 41)
	ItemListBorder1.Parent = ItemListFrame
	local ItemListFrameCorner = Instance.new("UICorner")
	ItemListFrameCorner.CornerRadius = UDim.new(0, 4)
	ItemListFrameCorner.Parent = ItemListFrame
	local ItemListFrame1 = Instance.new("Frame")
	ItemListFrame1.Size = UDim2.new(0, 112, 0, 113)
	ItemListFrame1.Position = UDim2.new(0, 10, 0, 71)
	ItemListFrame1.BackgroundColor3 = Color3.fromRGB(38, 37, 38)
	ItemListFrame1.Name = "ItemListFrame1"
	ItemListFrame1.Parent = ItemListFrame
	local ItemListFrame2 = Instance.new("Frame")
	ItemListFrame2.Size = UDim2.new(0, 110, 0, 111)
	ItemListFrame2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ItemListFrame2.BorderSizePixel = 0
	ItemListFrame2.Name = "ItemListFrame2"
	ItemListFrame2.Position = UDim2.new(0, 1, 0, 1)
	ItemListFrame2.Parent = ItemListFrame1
	local ItemListFramePicker = Instance.new("ScrollingFrame")
	ItemListFramePicker.Size = UDim2.new(0, 495, 0, 220)
	ItemListFramePicker.Position = UDim2.new(0, 144, 0, 122)
	ItemListFramePicker.BorderSizePixel = 0
	ItemListFramePicker.ScrollBarThickness = 3
	ItemListFramePicker.ScrollBarImageTransparency = 0.8
	ItemListFramePicker.VerticalScrollBarInset = Enum.ScrollBarInset.None
	ItemListFramePicker.BackgroundTransparency = 1
	ItemListFramePicker.Parent = ItemListFrame
	local ItemListFramePickerGrid = Instance.new("UIGridLayout")
	ItemListFramePickerGrid.CellPadding = UDim2.new(0, 4, 0, 3)
	ItemListFramePickerGrid.CellSize = UDim2.new(0, 51, 0, 52)
	ItemListFramePickerGrid.Parent = ItemListFramePicker
	ItemListFramePickerGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ItemListFramePicker.CanvasSize = UDim2.new(0, 0, 0, ItemListFramePickerGrid.AbsoluteContentSize.Y * (1 / GuiLibrary["MainRescale"].Scale))
	end)
	local ItemListcorner = Instance.new("UICorner")
	ItemListcorner.CornerRadius = UDim.new(0, 5)
	ItemListcorner.Parent = ItemListFrame1
	local ItemListcorner2 = Instance.new("UICorner")
	ItemListcorner2.CornerRadius = UDim.new(0, 5)
	ItemListcorner2.Parent = ItemListFrame2
	local selectedslot = 1
	local hoveredslot = 0

	local refreshslots
	local refreshList
	refreshslots = function()
		local startnum = 144
		local oldhovered = hoveredslot
		for i2,v2 in pairs(ItemListFrame:GetChildren()) do
			if v2.Name:find("ItemSlot") then
				v2:Remove()
			end
		end
		for i3,v3 in pairs(ItemListFramePicker:GetChildren()) do
			if v3:IsA("TextButton") then
				v3:Remove()
			end
		end
		for i4,v4 in pairs(sortableitems) do
			local ItemFrame = Instance.new("TextButton")
			ItemFrame.Text = ""
			ItemFrame.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
			ItemFrame.Parent = ItemListFramePicker
			ItemFrame.AutoButtonColor = false
			local ItemFrameIcon = Instance.new("ImageLabel")
			ItemFrameIcon.Size = UDim2.new(0, 32, 0, 32)
			ItemFrameIcon.Image = bedwars.getIcon({itemType = v4.itemDisplayType}, true)
			ItemFrameIcon.ResampleMode = (bedwars.getIcon({itemType = v4.itemDisplayType}, true):find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			ItemFrameIcon.Position = UDim2.new(0, 10, 0, 10)
			ItemFrameIcon.BackgroundTransparency = 1
			ItemFrameIcon.Parent = ItemFrame
			local ItemFramecorner = Instance.new("UICorner")
			ItemFramecorner.CornerRadius = UDim.new(0, 5)
			ItemFramecorner.Parent = ItemFrame
			ItemFrame.MouseButton1Click:Connect(function()
				for i5,v5 in pairs(buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"]) do
					if v5.itemType == v4.itemType then
						buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i5)] = nil
					end
				end
				buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(selectedslot)] = v4
				refreshslots()
				refreshList()
			end)
		end
		for i = 1, 9 do
			local item = buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i)]
			local ItemListFrame3 = Instance.new("Frame")
			ItemListFrame3.Size = UDim2.new(0, 55, 0, 56)
			ItemListFrame3.Position = UDim2.new(0, startnum - 2, 0, 380)
			ItemListFrame3.BackgroundTransparency = (selectedslot == i and 0 or 1)
			ItemListFrame3.BackgroundColor3 = Color3.fromRGB(35, 34, 35)
			ItemListFrame3.Name = "ItemSlot"
			ItemListFrame3.Parent = ItemListFrame
			local ItemListFrame4 = Instance.new("TextButton")
			ItemListFrame4.Size = UDim2.new(0, 51, 0, 52)
			ItemListFrame4.BackgroundColor3 = (oldhovered == i and Color3.fromRGB(31, 30, 31) or Color3.fromRGB(20, 20, 20))
			ItemListFrame4.BorderSizePixel = 0
			ItemListFrame4.AutoButtonColor = false
			ItemListFrame4.Text = ""
			ItemListFrame4.Name = "ItemListFrame4"
			ItemListFrame4.Position = UDim2.new(0, 2, 0, 2)
			ItemListFrame4.Parent = ItemListFrame3
			local ItemListImage = Instance.new("ImageLabel")
			ItemListImage.Size = UDim2.new(0, 32, 0, 32)
			ItemListImage.BackgroundTransparency = 1
			local img = (item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or "")
			ItemListImage.Image = img
			ItemListImage.ResampleMode = (img:find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			ItemListImage.Position = UDim2.new(0, 10, 0, 10)
			ItemListImage.Parent = ItemListFrame4
			local ItemListcorner3 = Instance.new("UICorner")
			ItemListcorner3.CornerRadius = UDim.new(0, 5)
			ItemListcorner3.Parent = ItemListFrame3
			local ItemListcorner4 = Instance.new("UICorner")
			ItemListcorner4.CornerRadius = UDim.new(0, 5)
			ItemListcorner4.Parent = ItemListFrame4
			ItemListFrame4.MouseEnter:Connect(function()
				ItemListFrame4.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
				hoveredslot = i
			end)
			ItemListFrame4.MouseLeave:Connect(function()
				ItemListFrame4.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				hoveredslot = 0
			end)
			ItemListFrame4.MouseButton1Click:Connect(function()
				selectedslot = i
				refreshslots()
			end)
			ItemListFrame4.MouseButton2Click:Connect(function()
				buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i)] = nil
				refreshslots()
				refreshList()
			end)
			startnum = startnum + 55
		end
	end

	local function createHotbarButton(num, items)
		num = tonumber(num) or #buttonapi["Hotbars"] + 1
		local hotbarbutton = Instance.new("TextButton")
		hotbarbutton.Size = UDim2.new(1, 0, 0, 30)
		hotbarbutton.BackgroundTransparency = 1
		hotbarbutton.LayoutOrder = num
		hotbarbutton.AutoButtonColor = false
		hotbarbutton.Text = ""
		hotbarbutton.Parent = children3
		buttonapi["Hotbars"][num] = {["Items"] = items or {}, Object = hotbarbutton, ["Number"] = num}
		local hotbarframe = Instance.new("Frame")
		hotbarframe.BackgroundColor3 = (num == buttonapi["CurrentlySelected"] and Color3.fromRGB(54, 53, 54) or Color3.fromRGB(31, 30, 31))
		hotbarframe.Size = UDim2.new(0, 200, 0, 27)
		hotbarframe.Position = UDim2.new(0, 10, 0, 1)
		hotbarframe.Parent = hotbarbutton
		local uicorner3 = Instance.new("UICorner")
		uicorner3.CornerRadius = UDim.new(0, 5)
		uicorner3.Parent = hotbarframe
		local startpos = 11
		for i = 1, 9 do
			local item = buttonapi["Hotbars"][num]["Items"][tostring(i)]
			local hotbarbox = Instance.new("ImageLabel")
			hotbarbox.Name = i
			hotbarbox.Size = UDim2.new(0, 17, 0, 18)
			hotbarbox.Position = UDim2.new(0, startpos, 0, 5)
			hotbarbox.BorderSizePixel = 0
			hotbarbox.Image = (item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or "")
			hotbarbox.ResampleMode = ((item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or ""):find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			hotbarbox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			hotbarbox.Parent = hotbarframe
			startpos = startpos + 18
		end
		hotbarbutton.MouseButton1Click:Connect(function()
			if buttonapi["CurrentlySelected"] == num then
				ItemListBigFrame.Visible = true
				GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = false
				refreshslots()
			end
			buttonapi["CurrentlySelected"] = num
			refreshList()
		end)
		hotbarbutton.MouseButton2Click:Connect(function()
			if buttonapi["CurrentlySelected"] == num then
				buttonapi["CurrentlySelected"] = (num == 2 and 0 or 1)
			end
			table.remove(buttonapi["Hotbars"], num)
			refreshList()
		end)
	end

	refreshList = function()
		local newnum = 0
		local newtab = {}
		for i3,v3 in pairs(buttonapi["Hotbars"]) do
			newnum = newnum + 1
			newtab[newnum] = v3
		end
		buttonapi["Hotbars"] = newtab
		for i,v in pairs(children3:GetChildren()) do
			if v:IsA("TextButton") then
				v:Remove()
			end
		end
		for i2,v2 in pairs(buttonapi["Hotbars"]) do
			createHotbarButton(i2, v2["Items"])
		end
		GuiLibrary["Settings"][children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["CurrentlySelected"] = buttonapi["CurrentlySelected"]}
	end
	buttonapi["RefreshList"] = refreshList

	buttontext.MouseButton1Click:Connect(function()
		createHotbarButton()
	end)

	GuiLibrary["Settings"][children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["CurrentlySelected"] = buttonapi["CurrentlySelected"]}
	GuiLibrary.ObjectsThatCanBeSaved[children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["Api"] = buttonapi, Object = buttontext}

	return buttonapi
end

GuiLibrary.LoadSettingsEvent.Event:Connect(function(res)
	for i,v in pairs(res) do
		local obj = GuiLibrary.ObjectsThatCanBeSaved[i]
		if obj and v.Type == "ItemList" and obj.Api then
			obj.Api.Hotbars = v.Items
			obj.Api.CurrentlySelected = v.CurrentlySelected
			obj.Api.RefreshList()
		end
	end
end)

run(function()
	local function isWhitelistedBed(bed)
		if bed and bed.Name == 'bed' then
			for i, v in pairs(playersService:GetPlayers()) do
				if bed:GetAttribute("Team"..(v:GetAttribute("Team") or 0).."NoBreak") and not ({whitelist:get(v)})[2] then
					return true
				end
			end
		end
		return false
	end

	local function dumpRemote(tab)
		for i,v in pairs(tab) do
			if v == "Client" then
				return tab[i + 1]
			end
		end
		return ""
	end

	local KnitGotten, KnitClient
	repeat
		KnitGotten, KnitClient = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 6)
		end)
		if KnitGotten then break end
		task.wait()
	until KnitGotten
	repeat task.wait() until debug.getupvalue(KnitClient.Start, 1)
	local Flamework = require(replicatedStorage["rbxts_include"]["node_modules"]["@flamework"].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local InventoryUtil = require(replicatedStorage.TS.inventory["inventory-util"]).InventoryUtil
	local OldGet = getmetatable(Client).Get
	local OldBreak

	bedwars = setmetatable({
		AnimationType = require(replicatedStorage.TS.animation["animation-type"]).AnimationType,
		AnimationUtil = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out["shared"].util["animation-util"]).AnimationUtil,
		AppController = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.client.controllers["app-controller"]).AppController,
		AbilityController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController"),
		AbilityUIController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/ability/ability-ui-controller@AbilityUIController"),
		AttackRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.SwordController.sendServerRequest)),
		BalanceFile = require(replicatedStorage.TS.balance["balance-file"]).BalanceFile,
		BatteryRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.BatteryController.KnitStart, 1), 1))),
		BlockBreaker = KnitClient.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out).BlockEngine,
		BlockPlacer = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.client.placement["block-placer"]).BlockPlacer,
		BlockEngine = require(lplr.PlayerScripts.TS.lib["block-engine"]["client-block-engine"]).ClientBlockEngine,
		BlockEngineClientEvents = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.client["block-engine-client-events"]).BlockEngineClientEvents,
		BowConstantsTable = debug.getupvalue(KnitClient.Controllers.ProjectileController.enableBeam, 7),
		CannonAimRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.CannonController.startAiming, 5))),
		CannonLaunchRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.CannonHandController.launchSelf)),
		ClickHold = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.client.ui.lib.util["click-hold"]).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage["rbxts_include"]["node_modules"]["@rbxts"].net.out.client),
		ClientDamageBlock = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.shared.remotes).BlockEngineRemotes.Client,
		ClientStoreHandler = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		CombatConstant = require(replicatedStorage.TS.combat["combat-constant"]).CombatConstant,
		ConstantManager = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out["shared"].constant["constant-manager"]).ConstantManager,
		ConsumeSoulRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.GrimReaperController.consumeSoul)),
		CooldownController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/cooldown/cooldown-controller@CooldownController"),
		DamageIndicator = KnitClient.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.game.locker["kill-effect"].effects["default-kill-effect"]),
		DropItem = KnitClient.Controllers.ItemDropController.dropItemInHand,
		DropItemRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.ItemDropController.dropItemInHand)),
		DragonRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.DragonSlayerController.KnitStart, 2), 1))),
		EatRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.ConsumeController.onEnable, 1))),
		EquipItemRemote = dumpRemote(debug.getconstants(debug.getproto(require(replicatedStorage.TS.entity.entities["inventory-entity"]).InventoryEntity.equipItem, 3))),
		EmoteMeta = require(replicatedStorage.TS.locker.emote["emote-meta"]).EmoteMeta,
		ForgeConstants = debug.getupvalue(KnitClient.Controllers.ForgeController.getPurchaseableForgeUpgrades, 2),
		ForgeUtil = debug.getupvalue(KnitClient.Controllers.ForgeController.getPurchaseableForgeUpgrades, 5),
		GameAnimationUtil = require(replicatedStorage.TS.animation["animation-util"]).GameAnimationUtil,
		EntityUtil = require(replicatedStorage.TS.entity["entity-util"]).EntityUtil,
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemTable[item.itemType]
			if itemmeta and showinv then
				return itemmeta.image or ""
			end
			return ""
		end,
		getInventory = function(plr)
			local suc, result = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return (suc and result or {
				items = {},
				armor = {},
				hand = nil
			})
		end,
		GuitarHealRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.GuitarController.performHeal)),
		ItemTable = debug.getupvalue(require(replicatedStorage.TS.item["item-meta"]).getItemMeta, 1),
		KillEffectMeta = require(replicatedStorage.TS.locker["kill-effect"]["kill-effect-meta"]).KillEffectMeta,
		KnockbackUtil = require(replicatedStorage.TS.damage["knockback-util"]).KnockbackUtil,
		MatchEndScreenController = Flamework.resolveDependency("client/controllers/game/match/match-end-screen-controller@MatchEndScreenController"),
--		MinerRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.MinerController.onKitEnabled, 1))),
		MageRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.MageController.registerTomeInteraction, 1))),
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage["mage-kit-util"]).MageKitUtil,
		PickupMetalRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.MetalDetectorController.KnitStart, 1), 2))),
		PickupRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.ItemDropController.checkForPickup)),
		--PinataRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.PiggyBankController.KnitStart, 2), 5))),
		PinataRemote = '',
		ProjectileMeta = require(replicatedStorage.TS.projectile["projectile-meta"]).ProjectileMeta,
		ProjectileRemote = dumpRemote(debug.getconstants(debug.getupvalue(KnitClient.Controllers.ProjectileController.launchProjectileWithValues, 2))),
		QueryUtil = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui["queue-card"]).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game["queue-meta"]).QueueMeta,
		ReportRemote = dumpRemote(debug.getconstants(require(lplr.PlayerScripts.TS.controllers.global.report["report-controller"]).default.reportPlayer)),
		ResetRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.ResetController.createBindable, 1))),
		Roact = require(replicatedStorage["rbxts_include"]["node_modules"]["@rbxts"]["roact"].src),
		RuntimeLib = require(replicatedStorage["rbxts_include"].RuntimeLib),
		Shop = require(replicatedStorage.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop,
		ShopItems = debug.getupvalue(debug.getupvalue(require(replicatedStorage.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop.getShopItem, 1), 3),
		SoundList = require(replicatedStorage.TS.sound["game-sound"]).GameSound,
		SoundManager = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).SoundManager,
		SpawnRavenRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.RavenController.spawnRaven)),
		TreeRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.BigmanController.KnitStart, 1), 2))),
		TrinityRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.AngelController.onKitEnabled, 1))),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		WeldTable = require(replicatedStorage.TS.util["weld-util"]).WeldUtil
	}, {
		__index = function(self, ind)
			rawset(self, ind, KnitClient.Controllers[ind])
			return rawget(self, ind)
		end
	})
	OldBreak = bedwars.BlockController.isBlockBreakable

	getmetatable(Client).Get = function(self, remoteName)
		if not vapeInjected then return OldGet(self, remoteName) end
		local originalRemote = OldGet(self, remoteName)
		if remoteName == bedwars.AttackRemote then
			return {
				instance = originalRemote.instance,
				SendToServer = function(self, attackTable, ...)
					local suc, plr = pcall(function() return playersService:GetPlayerFromCharacter(attackTable.entityInstance) end)
					if suc and plr then
						if not ({whitelist:get(plr)})[2] then return end
						if Reach.Enabled then
							local attackMagnitude = ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - attackTable.validate.targetPosition.value).magnitude
							if attackMagnitude > 18 then
								return nil
							end
							attackTable.validate.selfPosition = attackValue(attackTable.validate.selfPosition.value + (attackMagnitude > 14.4 and (CFrame.lookAt(attackTable.validate.selfPosition.value, attackTable.validate.targetPosition.value).lookVector * 4) or Vector3.zero))
						end
						store.attackReach = math.floor((attackTable.validate.selfPosition.value - attackTable.validate.targetPosition.value).magnitude * 100) / 100
						store.attackReachUpdate = tick() + 1
					end
					return originalRemote:SendToServer(attackTable, ...)
				end
			}
		end
		return originalRemote
	end

	bedwars.BlockController.isBlockBreakable = function(self, breakTable, plr)
		local obj = bedwars.BlockController:getStore():getBlockAt(breakTable.blockPosition)
		if isWhitelistedBed(obj) then return false end
		return OldBreak(self, breakTable, plr)
	end

	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, "wool_white")
	bedwars.placeBlock = function(speedCFrame, customblock)
		if getItem(customblock) then
			store.blockPlacer.blockType = customblock
			return store.blockPlacer:placeBlock(Vector3.new(speedCFrame.X / 3, speedCFrame.Y / 3, speedCFrame.Z / 3))
		end
	end

	local healthbarblocktable = {
		blockHealth = -1,
		breakingBlockPosition = Vector3.zero
	}

	local failedBreak = 0
	bedwars.breakBlock = function(pos, effects, normal, bypass, anim)
		if GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled then
			return
		end
		if lplr:GetAttribute("DenyBlockBreak") then
			return
		end
		local block, blockpos = nil, nil
		if not bypass then block, blockpos = getLastCovered(pos, normal) end
		if not block then block, blockpos = getPlacedBlock(pos) end
		if blockpos and block then
			if bedwars.BlockEngineClientEvents.DamageBlock:fire(block.Name, blockpos, block):isCancelled() then
				return
			end
			local blockhealthbarpos = {blockPosition = Vector3.zero}
			local blockdmg = 0
			if block and block.Parent ~= nil then
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - (blockpos * 3)).magnitude > 30 then return end
				store.blockPlace = tick() + 0.1
				switchToAndUseTool(block)
				blockhealthbarpos = {
					blockPosition = blockpos
				}
				task.spawn(function()
					bedwars.ClientDamageBlock:Get("DamageBlock"):CallServerAsync({
						blockRef = blockhealthbarpos,
						hitPosition = blockpos * 3,
						hitNormal = Vector3.FromNormalId(normal)
					}):andThen(function(result)
						if result ~= "failed" then
							failedBreak = 0
							if healthbarblocktable.blockHealth == -1 or blockhealthbarpos.blockPosition ~= healthbarblocktable.breakingBlockPosition then
								local blockdata = bedwars.BlockController:getStore():getBlockData(blockhealthbarpos.blockPosition)
								local blockhealth = blockdata and (blockdata:GetAttribute("Health") or blockdata:GetAttribute(lplr.Name .. "_Health")) or block:GetAttribute("Health")
								healthbarblocktable.blockHealth = blockhealth
								healthbarblocktable.breakingBlockPosition = blockhealthbarpos.blockPosition
							end
							healthbarblocktable.blockHealth = result == "destroyed" and 0 or healthbarblocktable.blockHealth
							blockdmg = bedwars.BlockController:calculateBlockDamage(lplr, blockhealthbarpos)
							healthbarblocktable.blockHealth = math.max(healthbarblocktable.blockHealth - blockdmg, 0)
							if effects then
								bedwars.BlockBreaker:updateHealthbar(blockhealthbarpos, healthbarblocktable.blockHealth, block:GetAttribute("MaxHealth"), blockdmg, block)
								if healthbarblocktable.blockHealth <= 0 then
									bedwars.BlockBreaker.breakEffect:playBreak(block.Name, blockhealthbarpos.blockPosition, lplr)
									bedwars.BlockBreaker.healthbarMaid:DoCleaning()
									healthbarblocktable.breakingBlockPosition = Vector3.zero
								else
									bedwars.BlockBreaker.breakEffect:playHit(block.Name, blockhealthbarpos.blockPosition, lplr)
								end
							end
							local animation
							if anim then
								animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
								bedwars.ViewmodelController:playAnimation(15)
							end
							task.wait(0.3)
							if animation ~= nil then
								animation:Stop()
								animation:Destroy()
							end
						else
							failedBreak = failedBreak + 1
						end
					end)
				end)
				task.wait(physicsUpdate)
			end
		end
	end

	local function updateStore(newStore, oldStore)
		if newStore.Game ~= oldStore.Game then
			store.matchState = newStore.Game.matchState
			store.queueType = newStore.Game.queueType or "bedwars_test"
			store.forgeMasteryPoints = newStore.Game.forgeMasteryPoints
			store.forgeUpgrades = newStore.Game.forgeUpgrades
		end
		if newStore.Bedwars ~= oldStore.Bedwars then
			store.equippedKit = newStore.Bedwars.kit ~= "none" and newStore.Bedwars.kit or ""
		end
		if newStore.Inventory ~= oldStore.Inventory then
			local newInventory = (newStore.Inventory and newStore.Inventory.observedInventory or {inventory = {}})
			local oldInventory = (oldStore.Inventory and oldStore.Inventory.observedInventory or {inventory = {}})
			store.localInventory = newStore.Inventory.observedInventory
			if newInventory ~= oldInventory then
				vapeEvents.InventoryChanged:Fire()
			end
			if newInventory.inventory.items ~= oldInventory.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
			end
			if newInventory.inventory.hand ~= oldInventory.inventory.hand then
				local currentHand = newStore.Inventory.observedInventory.inventory.hand
				local handType = ""
				if currentHand then
					local handData = bedwars.ItemTable[currentHand.itemType]
					handType = handData.sword and "sword" or handData.block and "block" or currentHand.itemType:find("bow") and "bow"
				end
				store.localHand = {tool = currentHand and currentHand.tool, Type = handType, amount = currentHand and currentHand.amount or 0}
			end
		end
	end

	table.insert(vapeConnections, bedwars.ClientStoreHandler.changed:connect(updateStore))
	updateStore(bedwars.ClientStoreHandler:getState(), {})

	for i, v in pairs({"MatchEndEvent", "EntityDeathEvent", "EntityDamageEvent", "BedwarsBedBreak", "BalloonPopped", "AngelProgress"}) do
		bedwars.Client:WaitFor(v):andThen(function(connection)
			table.insert(vapeConnections, connection:Connect(function(...)
				vapeEvents[v]:Fire(...)
			end))
		end)
	end
	for i, v in pairs({"PlaceBlockEvent", "BreakBlockEvent"}) do
		bedwars.ClientDamageBlock:WaitFor(v):andThen(function(connection)
			table.insert(vapeConnections, connection:Connect(function(...)
				vapeEvents[v]:Fire(...)
			end))
		end)
	end

	store.blocks = collectionService:GetTagged("block")
	store.blockRaycast.FilterDescendantsInstances = {store.blocks}
	table.insert(vapeConnections, collectionService:GetInstanceAddedSignal("block"):Connect(function(block)
		table.insert(store.blocks, block)
		store.blockRaycast.FilterDescendantsInstances = {store.blocks}
	end))
	table.insert(vapeConnections, collectionService:GetInstanceRemovedSignal("block"):Connect(function(block)
		block = table.find(store.blocks, block)
		if block then
			table.remove(store.blocks, block)
			store.blockRaycast.FilterDescendantsInstances = {store.blocks}
		end
	end))
	for _, ent in pairs(collectionService:GetTagged("entity")) do
		if ent.Name == "DesertPotEntity" then
			table.insert(store.pots, ent)
		end
	end
	table.insert(vapeConnections, collectionService:GetInstanceAddedSignal("entity"):Connect(function(ent)
		if ent.Name == "DesertPotEntity" then
			table.insert(store.pots, ent)
		end
	end))
	table.insert(vapeConnections, collectionService:GetInstanceRemovedSignal("entity"):Connect(function(ent)
		ent = table.find(store.pots, ent)
		if ent then
			table.remove(store.pots, ent)
		end
	end))

	local oldZephyrUpdate = bedwars.WindWalkerController.updateJump
	bedwars.WindWalkerController.updateJump = function(self, orb, ...)
		store.zephyrOrb = lplr.Character and lplr.Character:GetAttribute("Health") > 0 and orb or 0
		return oldZephyrUpdate(self, orb, ...)
	end

	GuiLibrary.SelfDestructEvent.Event:Connect(function()
		bedwars.WindWalkerController.updateJump = oldZephyrUpdate
		getmetatable(bedwars.Client).Get = OldGet
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
	end)

	local teleportedServers = false
	table.insert(vapeConnections, lplr.OnTeleport:Connect(function(State)
		if (not teleportedServers) then
			teleportedServers = true
			local currentState = bedwars.ClientStoreHandler and bedwars.ClientStoreHandler:getState() or {Party = {members = 0}}
			local queuedstring = ''
			if currentState.Party and currentState.Party.members and #currentState.Party.members > 0 then
				queuedstring = queuedstring..'shared.vapeteammembers = '..#currentState.Party.members..'\n'
			end
			if store.TPString then
				queuedstring = queuedstring..'shared.vapeoverlay = "'..store.TPString..'"\n'
			end
			queueonteleport(queuedstring)
		end
	end))
end)

do
	entityLibrary.animationCache = {}
	entityLibrary.groundTick = tick()
	entityLibrary.selfDestruct()
	entityLibrary.isPlayerTargetable = function(plr)
		return lplr:GetAttribute("Team") ~= plr:GetAttribute("Team") and not isFriend(plr) and ({whitelist:get(plr)})[2]
	end
	entityLibrary.characterAdded = function(plr, char, localcheck)
		local id = game:GetService("HttpService"):GenerateGUID(true)
		entityLibrary.entityIds[plr.Name] = id
		if char then
			task.spawn(function()
				local humrootpart = char:WaitForChild("HumanoidRootPart", 10)
				local head = char:WaitForChild("Head", 10)
				local hum = char:WaitForChild("Humanoid", 10)
				if entityLibrary.entityIds[plr.Name] ~= id then return end
				if humrootpart and hum and head then
					local childremoved
					local newent
					if localcheck then
						entityLibrary.isAlive = true
						entityLibrary.character.Head = head
						entityLibrary.character.Humanoid = hum
						entityLibrary.character.HumanoidRootPart = humrootpart
						table.insert(entityLibrary.entityConnections, char.AttributeChanged:Connect(function(...)
							vapeEvents.AttributeChanged:Fire(...)
						end))
					else
						newent = {
							Player = plr,
							Character = char,
							HumanoidRootPart = humrootpart,
							RootPart = humrootpart,
							Head = head,
							Humanoid = hum,
							Targetable = entityLibrary.isPlayerTargetable(plr),
							Team = plr.Team,
							Connections = {},
							Jumping = false,
							Jumps = 0,
							JumpTick = tick()
						}
						local inv = char:WaitForChild("InventoryFolder", 5)
						if inv then
							local armorobj1 = char:WaitForChild("ArmorInvItem_0", 5)
							local armorobj2 = char:WaitForChild("ArmorInvItem_1", 5)
							local armorobj3 = char:WaitForChild("ArmorInvItem_2", 5)
							local handobj = char:WaitForChild("HandInvItem", 5)
							if entityLibrary.entityIds[plr.Name] ~= id then return end
							if armorobj1 then
								table.insert(newent.Connections, armorobj1.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if armorobj2 then
								table.insert(newent.Connections, armorobj2.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if armorobj3 then
								table.insert(newent.Connections, armorobj3.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if handobj then
								table.insert(newent.Connections, handobj.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
						end
						if entityLibrary.entityIds[plr.Name] ~= id then return end
						task.delay(0.3, function()
							if entityLibrary.entityIds[plr.Name] ~= id then return end
							store.inventories[plr] = bedwars.getInventory(plr)
							entityLibrary.entityUpdatedEvent:Fire(newent)
						end)
						table.insert(newent.Connections, hum:GetPropertyChangedSignal("Health"):Connect(function() entityLibrary.entityUpdatedEvent:Fire(newent) end))
						table.insert(newent.Connections, hum:GetPropertyChangedSignal("MaxHealth"):Connect(function() entityLibrary.entityUpdatedEvent:Fire(newent) end))
						table.insert(newent.Connections, hum.AnimationPlayed:Connect(function(state)
							local animnum = tonumber(({state.Animation.AnimationId:gsub("%D+", "")})[1])
							if animnum then
								if not entityLibrary.animationCache[state.Animation.AnimationId] then
									entityLibrary.animationCache[state.Animation.AnimationId] = game:GetService("MarketplaceService"):GetProductInfo(animnum)
								end
								if entityLibrary.animationCache[state.Animation.AnimationId].Name:lower():find("jump") then
									newent.Jumps = newent.Jumps + 1
								end
							end
						end))
						table.insert(newent.Connections, char.AttributeChanged:Connect(function(attr) if attr:find("Shield") then entityLibrary.entityUpdatedEvent:Fire(newent) end end))
						table.insert(entityLibrary.entityList, newent)
						entityLibrary.entityAddedEvent:Fire(newent)
					end
					if entityLibrary.entityIds[plr.Name] ~= id then return end
					childremoved = char.ChildRemoved:Connect(function(part)
						if part.Name == "HumanoidRootPart" or part.Name == "Head" or part.Name == "Humanoid" then
							if localcheck then
								if char == lplr.Character then
									if part.Name == "HumanoidRootPart" then
										entityLibrary.isAlive = false
										local root = char:FindFirstChild("HumanoidRootPart")
										if not root then
											root = char:WaitForChild("HumanoidRootPart", 3)
										end
										if root then
											entityLibrary.character.HumanoidRootPart = root
											entityLibrary.isAlive = true
										end
									else
										entityLibrary.isAlive = false
									end
								end
							else
								childremoved:Disconnect()
								entityLibrary.removeEntity(plr)
							end
						end
					end)
					if newent then
						table.insert(newent.Connections, childremoved)
					end
					table.insert(entityLibrary.entityConnections, childremoved)
				end
			end)
		end
	end
	entityLibrary.entityAdded = function(plr, localcheck, custom)
		table.insert(entityLibrary.entityConnections, plr:GetPropertyChangedSignal("Character"):Connect(function()
			if plr.Character then
				entityLibrary.refreshEntity(plr, localcheck)
			else
				if localcheck then
					entityLibrary.isAlive = false
				else
					entityLibrary.removeEntity(plr)
				end
			end
		end))
		table.insert(entityLibrary.entityConnections, plr:GetAttributeChangedSignal("Team"):Connect(function()
			local tab = {}
			for i,v in next, entityLibrary.entityList do
				if v.Targetable ~= entityLibrary.isPlayerTargetable(v.Player) then
					table.insert(tab, v)
				end
			end
			for i,v in next, tab do
				entityLibrary.refreshEntity(v.Player)
			end
			if localcheck then
				entityLibrary.fullEntityRefresh()
			else
				entityLibrary.refreshEntity(plr, localcheck)
			end
		end))
		if plr.Character then
			task.spawn(entityLibrary.refreshEntity, plr, localcheck)
		end
	end
	entityLibrary.fullEntityRefresh()
	task.spawn(function()
		repeat
			task.wait()
			if entityLibrary.isAlive then
				entityLibrary.groundTick = entityLibrary.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entityLibrary.groundTick
			end
			for i,v in pairs(entityLibrary.entityList) do
				local state = v.Humanoid:GetState()
				v.JumpTick = (state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.Landed) and tick() or v.JumpTick
				v.Jumping = (tick() - v.JumpTick) < 0.2 and v.Jumps > 1
				if (tick() - v.JumpTick) > 0.2 then
					v.Jumps = 0
				end
			end
		until not vapeInjected
	end)
	local textlabel = Instance.new("TextLabel")
	textlabel.Size = UDim2.new(1, 0, 0, 36)
	textlabel.Text = "The current version of vape is no longer being maintained, join the discord (click the discord icon) to get updates on the latest release."
	textlabel.BackgroundTransparency = 1
	textlabel.ZIndex = 10
	textlabel.TextStrokeTransparency = 0
	textlabel.TextScaled = true
	textlabel.Font = Enum.Font.SourceSans
	textlabel.TextColor3 = Color3.new(1, 1, 1)
	textlabel.Position = UDim2.new(0, 0, 1, -36)
	textlabel.Parent = GuiLibrary.MainGui.ScaledGui.ClickGui
end

run(function()
	local handsquare = Instance.new("ImageLabel")
	handsquare.Size = UDim2.new(0, 26, 0, 27)
	handsquare.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	handsquare.Position = UDim2.new(0, 72, 0, 44)
	handsquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local handround = Instance.new("UICorner")
	handround.CornerRadius = UDim.new(0, 4)
	handround.Parent = handsquare
	local helmetsquare = handsquare:Clone()
	helmetsquare.Position = UDim2.new(0, 100, 0, 44)
	helmetsquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local chestplatesquare = handsquare:Clone()
	chestplatesquare.Position = UDim2.new(0, 127, 0, 44)
	chestplatesquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local bootssquare = handsquare:Clone()
	bootssquare.Position = UDim2.new(0, 155, 0, 44)
	bootssquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local uselesssquare = handsquare:Clone()
	uselesssquare.Position = UDim2.new(0, 182, 0, 44)
	uselesssquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local oldupdate = vapeTargetInfo.UpdateInfo
	vapeTargetInfo.UpdateInfo = function(tab, targetsize)
		local bkgcheck = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo.BackgroundTransparency == 1
		handsquare.BackgroundTransparency = bkgcheck and 1 or 0
		helmetsquare.BackgroundTransparency = bkgcheck and 1 or 0
		chestplatesquare.BackgroundTransparency = bkgcheck and 1 or 0
		bootssquare.BackgroundTransparency = bkgcheck and 1 or 0
		uselesssquare.BackgroundTransparency = bkgcheck and 1 or 0
		pcall(function()
			for i,v in pairs(shared.VapeTargetInfo.Targets) do
				local inventory = store.inventories[v.Player] or {}
					if inventory.hand then
						handsquare.Image = bedwars.getIcon(inventory.hand, true)
					else
						handsquare.Image = ""
					end
					if inventory.armor[4] then
						helmetsquare.Image = bedwars.getIcon(inventory.armor[4], true)
					else
						helmetsquare.Image = ""
					end
					if inventory.armor[5] then
						chestplatesquare.Image = bedwars.getIcon(inventory.armor[5], true)
					else
						chestplatesquare.Image = ""
					end
					if inventory.armor[6] then
						bootssquare.Image = bedwars.getIcon(inventory.armor[6], true)
					else
						bootssquare.Image = ""
					end
				break
			end
		end)
		return oldupdate(tab, targetsize)
	end
end)

GuiLibrary.RemoveObject("SilentAimOptionsButton")
GuiLibrary.RemoveObject("ReachOptionsButton")
GuiLibrary.RemoveObject("MouseTPOptionsButton")
GuiLibrary.RemoveObject("PhaseOptionsButton")
GuiLibrary.RemoveObject("AutoClickerOptionsButton")
GuiLibrary.RemoveObject("SpiderOptionsButton")
GuiLibrary.RemoveObject("LongJumpOptionsButton")
GuiLibrary.RemoveObject("HitBoxesOptionsButton")
GuiLibrary.RemoveObject("KillauraOptionsButton")
GuiLibrary.RemoveObject("TriggerBotOptionsButton")
GuiLibrary.RemoveObject("AutoLeaveOptionsButton")
GuiLibrary.RemoveObject("SpeedOptionsButton")
GuiLibrary.RemoveObject("FlyOptionsButton")
GuiLibrary.RemoveObject("ClientKickDisablerOptionsButton")
GuiLibrary.RemoveObject("NameTagsOptionsButton")
GuiLibrary.RemoveObject("SafeWalkOptionsButton")
GuiLibrary.RemoveObject("BlinkOptionsButton")
GuiLibrary.RemoveObject("FOVChangerOptionsButton")
GuiLibrary.RemoveObject("AntiVoidOptionsButton")
GuiLibrary.RemoveObject("SongBeatsOptionsButton")
GuiLibrary.RemoveObject("TargetStrafeOptionsButton")

run(function()
	local AimAssist = {Enabled = false}
	local AimAssistClickAim = {Enabled = false}
	local AimAssistStrafe = {Enabled = false}
	local AimSpeed = {Value = 1}
	local AimAssistTargetFrame = {Players = {Enabled = false}}
	AimAssist = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "AimAssist",
		Function = function(callback)
			if callback then
				RunLoops:BindToRenderStep("AimAssist", function(dt)
					vapeTargetInfo.Targets.AimAssist = nil
					if ((not AimAssistClickAim.Enabled) or (tick() - bedwars.SwordController.lastSwing) < 0.4) then
						local plr = EntityNearPosition(18)
						if plr then
							vapeTargetInfo.Targets.AimAssist = {
								Humanoid = {
									Health = (plr.Character:GetAttribute("Health") or plr.Humanoid.Health) + getShieldAttribute(plr.Character),
									MaxHealth = plr.Character:GetAttribute("MaxHealth") or plr.Humanoid.MaxHealth
								},
								Player = plr.Player
							}
							if store.localHand.Type == "sword" then
								if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
									if store.matchState == 0 then return end
								end
								if AimAssistTargetFrame.Walls.Enabled then
									if not bedwars.SwordController:canSee({instance = plr.Character, player = plr.Player, getInstance = function() return plr.Character end}) then return end
								end
								gameCamera.CFrame = gameCamera.CFrame:lerp(CFrame.new(gameCamera.CFrame.p, plr.Character.HumanoidRootPart.Position), ((1 / AimSpeed.Value) + (AimAssistStrafe.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 0.01 or 0)))
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromRenderStep("AimAssist")
				vapeTargetInfo.Targets.AimAssist = nil
			end
		end,
		HoverText = "Smoothly aims to closest valid target with sword"
	})
	AimAssistTargetFrame = AimAssist.CreateTargetWindow({Default3 = true})
	AimAssistClickAim = AimAssist.CreateToggle({
		Name = "Click Aim",
		Function = function() end,
		Default = true,
		HoverText = "Only aim while mouse is down"
	})
	AimAssistStrafe = AimAssist.CreateToggle({
		Name = "Strafe increase",
		Function = function() end,
		HoverText = "Increase speed while strafing away from target"
	})
	AimSpeed = AimAssist.CreateSlider({
		Name = "Smoothness",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 50
	})
end)

run(function()
	local autoclicker = {Enabled = false}
	local noclickdelay = {Enabled = false}
	local autoclickercps = {GetRandomValue = function() return 1 end}
	local autoclickerblocks = {Enabled = false}
	local AutoClickerThread

	local function isNotHoveringOverGui()
		local mousepos = inputService:GetMouseLocation() - Vector2.new(0, 36)
		for i,v in pairs(lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y)) do
			if v.Active then
				return false
			end
		end
		for i,v in pairs(game:GetService("CoreGui"):GetGuiObjectsAtPosition(mousepos.X, mousepos.Y)) do
			if v.Parent:IsA("ScreenGui") and v.Parent.Enabled then
				if v.Active then
					return false
				end
			end
		end
		return true
	end

	local function AutoClick()
		local firstClick = tick() + 0.1
		AutoClickerThread = task.spawn(function()
			repeat
				task.wait()
				if entityLibrary.isAlive then
					if not autoclicker.Enabled then break end
					if not isNotHoveringOverGui() then continue end
					if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then continue end
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then continue end
					end
					if store.localHand.Type == "sword" then
						if bedwars.DaoController.chargingMaid == nil then
							task.spawn(function()
								if firstClick <= tick() then
									bedwars.SwordController:swingSwordAtMouse()
								else
									firstClick = tick()
								end
							end)
							task.wait(math.max((1 / autoclickercps.GetRandomValue()), noclickdelay.Enabled and 0 or 0.142))
						end
					elseif store.localHand.Type == "block" then
						if autoclickerblocks.Enabled and bedwars.BlockPlacementController.blockPlacer and firstClick <= tick() then
							if (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) > ((1 / 12) * 0.5) then
								local mouseinfo = bedwars.BlockPlacementController.blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
								if mouseinfo then
									task.spawn(function()
										if mouseinfo.placementPosition == mouseinfo.placementPosition then
											bedwars.BlockPlacementController.blockPlacer:placeBlock(mouseinfo.placementPosition)
										end
									end)
								end
								task.wait((1 / autoclickercps.GetRandomValue()))
							end
						end
					end
				end
			until not autoclicker.Enabled
		end)
	end

	autoclicker = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "AutoClicker",
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						table.insert(autoclicker.Connections, lplr.PlayerGui.MobileUI['2'].MouseButton1Down:Connect(AutoClick))
						table.insert(autoclicker.Connections, lplr.PlayerGui.MobileUI['2'].MouseButton1Up:Connect(function()
							if AutoClickerThread then
								task.cancel(AutoClickerThread)
								AutoClickerThread = nil
							end
						end))
					end)
				end
				table.insert(autoclicker.Connections, inputService.InputBegan:Connect(function(input, gameProcessed)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then AutoClick() end
				end))
				table.insert(autoclicker.Connections, inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and AutoClickerThread then
						task.cancel(AutoClickerThread)
						AutoClickerThread = nil
					end
				end))
			end
		end,
		HoverText = "Hold attack button to automatically click"
	})
	autoclickercps = autoclicker.CreateTwoSlider({
		Name = "CPS",
		Min = 1,
		Max = 20,
		Function = function(val) end,
		Default = 8,
		Default2 = 12
	})
	autoclickerblocks = autoclicker.CreateToggle({
		Name = "Place Blocks",
		Function = function() end,
		Default = true,
		HoverText = "Automatically places blocks when left click is held."
	})

	local noclickfunc
	noclickdelay = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "NoClickDelay",
		Function = function(callback)
			if callback then
				noclickfunc = bedwars.SwordController.isClickingTooFast
				bedwars.SwordController.isClickingTooFast = function(self)
					self.lastSwing = tick()
					return false
				end
			else
				bedwars.SwordController.isClickingTooFast = noclickfunc
			end
		end,
		HoverText = "Remove the CPS cap"
	})
end)

run(function()
	local ReachValue = {Value = 14}

	Reach = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Reach",
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and ReachValue.Value + 2 or 14.4
		end,
		HoverText = "Extends attack reach"
	})
	ReachValue = Reach.CreateSlider({
		Name = "Reach",
		Min = 0,
		Max = 18,
		Function = function(val)
			if Reach.Enabled then
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end
		end,
		Default = 18
	})
end)

run(function()
	local Sprint = {Enabled = false}
	local oldSprintFunction
	Sprint = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Sprint",
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function() lplr.PlayerGui.MobileUI["4"].Visible = false end)
				end
				oldSprintFunction = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local originalCall = oldSprintFunction(...)
					bedwars.SprintController:startSprinting()
					return originalCall
				end
				table.insert(Sprint.Connections, lplr.CharacterAdded:Connect(function(char)
					char:WaitForChild("Humanoid", 9e9)
					task.wait(0.5)
					bedwars.SprintController:stopSprinting()
				end))
				task.spawn(function()
					bedwars.SprintController:startSprinting()
				end)
			else
				if inputService.TouchEnabled then
					pcall(function() lplr.PlayerGui.MobileUI["4"].Visible = true end)
				end
				bedwars.SprintController.stopSprinting = oldSprintFunction
				bedwars.SprintController:stopSprinting()
			end
		end,
		HoverText = "Sets your sprinting to true."
	})
end)

run(function()
	local Velocity = {Enabled = false}
	local VelocityHorizontal = {Value = 100}
	local VelocityVertical = {Value = 100}
	local applyKnockback
	Velocity = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Velocity",
		Function = function(callback)
			if callback then
				applyKnockback = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
					knockback = knockback or {}
					if VelocityHorizontal.Value == 0 and VelocityVertical.Value == 0 then return end
					knockback.horizontal = (knockback.horizontal or 1) * (VelocityHorizontal.Value / 100)
					knockback.vertical = (knockback.vertical or 1) * (VelocityVertical.Value / 100)
					return applyKnockback(root, mass, dir, knockback, ...)
				end
			else
				bedwars.KnockbackUtil.applyKnockback = applyKnockback
			end
		end,
		HoverText = "Reduces knockback taken"
	})
	VelocityHorizontal = Velocity.CreateSlider({
		Name = "Horizontal",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function(val) end,
		Default = 0
	})
	VelocityVertical = Velocity.CreateSlider({
		Name = "Vertical",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function(val) end,
		Default = 0
	})
end)

run(function()
	local AutoLeaveDelay = {Value = 1}
	local AutoPlayAgain = {Enabled = false}
	local AutoLeaveStaff = {Enabled = true}
	local AutoLeaveStaff2 = {Enabled = true}
	local AutoLeaveRandom = {Enabled = false}
	local leaveAttempted = false

	local function getRole(plr)
		local suc, res = pcall(function() return plr:GetRankInGroup(5774246) end)
		if not suc then
			repeat
				suc, res = pcall(function() return plr:GetRankInGroup(5774246) end)
				task.wait()
			until suc
		end
		if plr.UserId == 1774814725 then
			return 200
		end
		return res
	end

	local flyAllowedmodules = {"Sprint", "AutoClicker", "AutoReport", "AutoReportV2", "AutoRelic", "AimAssist", "AutoLeave", "Reach"}
	local function autoLeaveAdded(plr)
		task.spawn(function()
			if not shared.VapeFullyLoaded then
				repeat task.wait() until shared.VapeFullyLoaded
			end
			if getRole(plr) >= 100 then
				if AutoLeaveStaff.Enabled then
					if #bedwars.ClientStoreHandler:getState().Party.members > 0 then
						bedwars.QueueController.leaveParty()
					end
					if AutoLeaveStaff2.Enabled then
						warningNotification("Vape", "Staff Detected : "..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name).." : Play legit like nothing happened to have the highest chance of not getting banned.", 60)
						GuiLibrary.SaveSettings = function() end
						for i,v in pairs(GuiLibrary.ObjectsThatCanBeSaved) do
							if v.Type == "OptionsButton" then
								if table.find(flyAllowedmodules, i:gsub("OptionsButton", "")) == nil and tostring(v.Object.Parent.Parent):find("Render") == nil then
									if v.Api.Enabled then
										v.Api.ToggleButton(false)
									end
									v.Api.SetKeybind("")
									v.Object.TextButton.Visible = false
								end
							end
						end
					else
						GuiLibrary.SelfDestruct()
						game:GetService("StarterGui"):SetCore("SendNotification", {
							Title = "Vape",
							Text = "Staff Detected\n"..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name),
							Duration = 60,
						})
					end
					return
				else
					warningNotification("Vape", "Staff Detected : "..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name), 60)
				end
			end
		end)
	end

	local function isEveryoneDead()
		if #bedwars.ClientStoreHandler:getState().Party.members > 0 then
			for i,v in pairs(bedwars.ClientStoreHandler:getState().Party.members) do
				local plr = playersService:FindFirstChild(v.name)
				if plr and isAlive(plr, true) then
					return false
				end
			end
			return true
		else
			return true
		end
	end

	AutoLeave = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "AutoLeave",
		Function = function(callback)
			if callback then
				table.insert(AutoLeave.Connections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if (not leaveAttempted) and deathTable.finalKill and deathTable.entityInstance == lplr.Character then
						leaveAttempted = true
						if isEveryoneDead() and store.matchState ~= 2 then
							task.wait(1 + (AutoLeaveDelay.Value / 10))
							if bedwars.ClientStoreHandler:getState().Game.customMatch == nil and bedwars.ClientStoreHandler:getState().Party.leader.userId == lplr.UserId then
								if not AutoPlayAgain.Enabled then
									bedwars.Client:Get("TeleportToLobby"):SendToServer()
								else
									if AutoLeaveRandom.Enabled then
										local listofmodes = {}
										for i,v in pairs(bedwars.QueueMeta) do
											if not v.disabled and not v.voiceChatOnly and not v.rankCategory then table.insert(listofmodes, i) end
										end
										bedwars.QueueController:joinQueue(listofmodes[math.random(1, #listofmodes)])
									else
										bedwars.QueueController:joinQueue(store.queueType)
									end
								end
							end
						end
					end
				end))
				table.insert(AutoLeave.Connections, vapeEvents.MatchEndEvent.Event:Connect(function(deathTable)
					task.wait(AutoLeaveDelay.Value / 10)
					if not AutoLeave.Enabled then return end
					if leaveAttempted then return end
					leaveAttempted = true
					if bedwars.ClientStoreHandler:getState().Game.customMatch == nil and bedwars.ClientStoreHandler:getState().Party.leader.userId == lplr.UserId then
						if not AutoPlayAgain.Enabled then
							bedwars.Client:Get("TeleportToLobby"):SendToServer()
						else
							if bedwars.ClientStoreHandler:getState().Party.queueState == 0 then
								if AutoLeaveRandom.Enabled then
									local listofmodes = {}
									for i,v in pairs(bedwars.QueueMeta) do
										if not v.disabled and not v.voiceChatOnly and not v.rankCategory then table.insert(listofmodes, i) end
									end
									bedwars.QueueController:joinQueue(listofmodes[math.random(1, #listofmodes)])
								else
									bedwars.QueueController:joinQueue(store.queueType)
								end
							end
						end
					end
				end))
				table.insert(AutoLeave.Connections, playersService.PlayerAdded:Connect(autoLeaveAdded))
				for i, plr in pairs(playersService:GetPlayers()) do
					autoLeaveAdded(plr)
				end
			end
		end,
		HoverText = "Leaves if a staff member joins your game or when the match ends."
	})
	AutoLeaveDelay = AutoLeave.CreateSlider({
		Name = "Delay",
		Min = 0,
		Max = 50,
		Default = 0,
		Function = function() end,
		HoverText = "Delay before going back to the hub."
	})
	AutoPlayAgain = AutoLeave.CreateToggle({
		Name = "Play Again",
		Function = function() end,
		HoverText = "Automatically queues a new game.",
		Default = true
	})
	AutoLeaveStaff = AutoLeave.CreateToggle({
		Name = "Staff",
		Function = function(callback)
			if AutoLeaveStaff2.Object then
				AutoLeaveStaff2.Object.Visible = callback
			end
		end,
		HoverText = "Automatically uninjects when staff joins",
		Default = true
	})
	AutoLeaveStaff2 = AutoLeave.CreateToggle({
		Name = "Staff AutoConfig",
		Function = function() end,
		HoverText = "Instead of uninjecting, It will now reconfig vape temporarily to a more legit config.",
		Default = true
	})
	AutoLeaveRandom = AutoLeave.CreateToggle({
		Name = "Random",
		Function = function(callback) end,
		HoverText = "Chooses a random mode"
	})
	AutoLeaveStaff2.Object.Visible = false
end)

run(function()
	local oldclickhold
	local oldclickhold2
	local roact
	local FastConsume = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "FastConsume",
		Function = function(callback)
			if callback then
				oldclickhold = bedwars.ClickHold.startClick
				oldclickhold2 = bedwars.ClickHold.showProgress
				bedwars.ClickHold.showProgress = function(p5)
					local roact = debug.getupvalue(oldclickhold2, 1)
					local countdown = roact.mount(roact.createElement("ScreenGui", {}, { roact.createElement("Frame", {
						[roact.Ref] = p5.wrapperRef,
						Size = UDim2.new(0, 0, 0, 0),
						Position = UDim2.new(0.5, 0, 0.55, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.8
					}, { roact.createElement("Frame", {
							[roact.Ref] = p5.progressRef,
							Size = UDim2.new(0, 0, 1, 0),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 0.5
						}) }) }), lplr:FindFirstChild("PlayerGui"))
					p5.handle = countdown
					local sizetween = tweenService:Create(p5.wrapperRef:getValue(), TweenInfo.new(0.1), {
						Size = UDim2.new(0.11, 0, 0.005, 0)
					})
					table.insert(p5.tweens, sizetween)
					sizetween:Play()
					local countdowntween = tweenService:Create(p5.progressRef:getValue(), TweenInfo.new(p5.durationSeconds * (FastConsumeVal.Value / 40), Enum.EasingStyle.Linear), {
						Size = UDim2.new(1, 0, 1, 0)
					})
					table.insert(p5.tweens, countdowntween)
					countdowntween:Play()
					return countdown
				end
				bedwars.ClickHold.startClick = function(p4)
					p4.startedClickTime = tick()
					local u2 = p4:showProgress()
					local clicktime = p4.startedClickTime
					bedwars.RuntimeLib.Promise.defer(function()
						task.wait(p4.durationSeconds * (FastConsumeVal.Value / 40))
						if u2 == p4.handle and clicktime == p4.startedClickTime and p4.closeOnComplete then
							p4:hideProgress()
							if p4.onComplete ~= nil then
								p4.onComplete()
							end
							if p4.onPartialComplete ~= nil then
								p4.onPartialComplete(1)
							end
							p4.startedClickTime = -1
						end
					end)
				end
			else
				bedwars.ClickHold.startClick = oldclickhold
				bedwars.ClickHold.showProgress = oldclickhold2
				oldclickhold = nil
				oldclickhold2 = nil
			end
		end,
		HoverText = "Use/Consume items quicker."
	})
	FastConsumeVal = FastConsume.CreateSlider({
		Name = "Ticks",
		Min = 0,
		Max = 40,
		Default = 0,
		Function = function() end
	})
end)

local autobankballoon = false
run(function()
	local Fly = {Enabled = false}
	local FlyMode = {Value = "CFrame"}
	local FlyVerticalSpeed = {Value = 40}
	local FlyVertical = {Enabled = true}
	local FlyAutoPop = {Enabled = true}
	local FlyAnyway = {Enabled = false}
	local FlyAnywayProgressBar = {Enabled = false}
	local FlyDamageAnimation = {Enabled = false}
	local FlyTP = {Enabled = false}
	local FlyAnywayProgressBarFrame
	local olddeflate
	local FlyUp = false
	local FlyDown = false
	local FlyCoroutine
	local groundtime = tick()
	local onground = false
	local lastonground = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}

	local function inflateBalloon()
		if not Fly.Enabled then return end
		if entityLibrary.isAlive and (lplr.Character:GetAttribute("InflatedBalloons") or 0) < 1 then
			autobankballoon = true
			if getItem("balloon") then
				bedwars.BalloonController:inflateBalloon()
				return true
			end
		end
		return false
	end

	Fly = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Fly",
		Function = function(callback)
			if callback then
				olddeflate = bedwars.BalloonController.deflateBalloon
				bedwars.BalloonController.deflateBalloon = function() end

				table.insert(Fly.Connections, inputService.InputBegan:Connect(function(input1)
					if FlyVertical.Enabled and inputService:GetFocusedTextBox() == nil then
						if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
							FlyUp = true
						end
						if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
							FlyDown = true
						end
					end
				end))
				table.insert(Fly.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
						FlyUp = false
					end
					if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
						FlyDown = false
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						table.insert(Fly.Connections, jumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
							FlyUp = jumpButton.ImageRectOffset.X == 146
						end))
						FlyUp = jumpButton.ImageRectOffset.X == 146
					end)
				end
				table.insert(Fly.Connections, vapeEvents.BalloonPopped.Event:Connect(function(poppedTable)
					if poppedTable.inflatedBalloon and poppedTable.inflatedBalloon:GetAttribute("BalloonOwner") == lplr.UserId then
						lastonground = not onground
						repeat task.wait() until (lplr.Character:GetAttribute("InflatedBalloons") or 0) <= 0 or not Fly.Enabled
						inflateBalloon()
					end
				end))
				table.insert(Fly.Connections, vapeEvents.AutoBankBalloon.Event:Connect(function()
					repeat task.wait() until getItem("balloon")
					inflateBalloon()
				end))

				local balloons
				if entityLibrary.isAlive and (not store.queueType:find("mega")) then
					balloons = inflateBalloon()
				end
				local megacheck = store.queueType:find("mega") or store.queueType == "winter_event"

				task.spawn(function()
					repeat task.wait() until store.queueType ~= "bedwars_test" or (not Fly.Enabled)
					if not Fly.Enabled then return end
					megacheck = store.queueType:find("mega") or store.queueType == "winter_event"
				end)

				local flyAllowed = entityLibrary.isAlive and ((lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
				if flyAllowed <= 0 and shared.damageanim and (not balloons) then
					shared.damageanim()
					bedwars.SoundManager:playSound(bedwars.SoundList["DAMAGE_"..math.random(1, 3)])
				end

				if FlyAnywayProgressBarFrame and flyAllowed <= 0 and (not balloons) then
					FlyAnywayProgressBarFrame.Visible = true
					FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
				end

				groundtime = tick() + (2.6 + (entityLibrary.groundTick - tick()))
				FlyCoroutine = coroutine.create(function()
					repeat
						repeat task.wait() until (groundtime - tick()) < 0.6 and not onground
						flyAllowed = ((lplr.Character and lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
						if (not Fly.Enabled) then break end
						local Flytppos = -99999
						if flyAllowed <= 0 and FlyTP.Enabled and entityLibrary.isAlive then
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -1000, 0), store.blockRaycast)
							if ray then
								Flytppos = entityLibrary.character.HumanoidRootPart.Position.Y
								local args = {entityLibrary.character.HumanoidRootPart.CFrame:GetComponents()}
								args[2] = ray.Position.Y + (entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight
								entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(unpack(args))
								task.wait(0.12)
								if (not Fly.Enabled) then break end
								flyAllowed = ((lplr.Character and lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
								if flyAllowed <= 0 and Flytppos ~= -99999 and entityLibrary.isAlive then
									local args = {entityLibrary.character.HumanoidRootPart.CFrame:GetComponents()}
									args[2] = Flytppos
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(unpack(args))
								end
							end
						end
					until (not Fly.Enabled)
				end)
				coroutine.resume(FlyCoroutine)

				RunLoops:BindToHeartbeat("Fly", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if bedwars.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						local playerMass = (entityLibrary.character.HumanoidRootPart:GetMass() - 1.4) * (delta * 100)
						flyAllowed = ((lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
						playerMass = playerMass + (flyAllowed > 0 and 4 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)

						if FlyAnywayProgressBarFrame then
							FlyAnywayProgressBarFrame.Visible = flyAllowed <= 0
							FlyAnywayProgressBarFrame.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
							FlyAnywayProgressBarFrame.Frame.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
						end

						if flyAllowed <= 0 then
							local newray = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + Vector3.new(0, (entityLibrary.character.Humanoid.HipHeight * -2) - 1, 0))
							onground = newray and true or false
							if lastonground ~= onground then
								if (not onground) then
									groundtime = tick() + (2.6 + (entityLibrary.groundTick - tick()))
									if FlyAnywayProgressBarFrame then
										FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(0, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, groundtime - tick(), true)
									end
								else
									if FlyAnywayProgressBarFrame then
										FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
									end
								end
							end
							if FlyAnywayProgressBarFrame then
								FlyAnywayProgressBarFrame.TextLabel.Text = math.max(onground and 2.5 or math.floor((groundtime - tick()) * 10) / 10, 0).."s"
							end
							lastonground = onground
						else
							onground = true
							lastonground = true
						end

						local flyVelocity = entityLibrary.character.Humanoid.MoveDirection * (FlyMode.Value == "Normal" and FlySpeed.Value or 20)
						entityLibrary.character.HumanoidRootPart.Velocity = flyVelocity + (Vector3.new(0, playerMass + (FlyUp and FlyVerticalSpeed.Value or 0) + (FlyDown and -FlyVerticalSpeed.Value or 0), 0))
						if FlyMode.Value ~= "Normal" then
							entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + (entityLibrary.character.Humanoid.MoveDirection * ((FlySpeed.Value + getSpeed()) - 20)) * delta
						end
					end
				end)
			else
				pcall(function() coroutine.close(FlyCoroutine) end)
				autobankballoon = false
				waitingforballoon = false
				lastonground = nil
				FlyUp = false
				FlyDown = false
				RunLoops:UnbindFromHeartbeat("Fly")
				if FlyAnywayProgressBarFrame then
					FlyAnywayProgressBarFrame.Visible = false
				end
				if FlyAutoPop.Enabled then
					if entityLibrary.isAlive and lplr.Character:GetAttribute("InflatedBalloons") then
						for i = 1, lplr.Character:GetAttribute("InflatedBalloons") do
							olddeflate()
						end
					end
				end
				bedwars.BalloonController.deflateBalloon = olddeflate
				olddeflate = nil
			end
		end,
		HoverText = "Makes you go zoom (longer Fly discovered by exelys and Cqded)",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	FlySpeed = Fly.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	FlyVerticalSpeed = Fly.CreateSlider({
		Name = "Vertical Speed",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 44
	})
	FlyVertical = Fly.CreateToggle({
		Name = "Y Level",
		Function = function() end,
		Default = true
	})
	FlyAutoPop = Fly.CreateToggle({
		Name = "Pop Balloon",
		Function = function() end,
		HoverText = "Pops balloons when Fly is disabled."
	})
	local oldcamupdate
	local camcontrol
	local Flydamagecamera = {Enabled = false}
	FlyDamageAnimation = Fly.CreateToggle({
		Name = "Damage Animation",
		Function = function(callback)
			if Flydamagecamera.Object then
				Flydamagecamera.Object.Visible = callback
			end
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.1)
						for i,v in pairs(getconnections(gameCamera:GetPropertyChangedSignal("CameraType"))) do
							if v.Function then
								camcontrol = debug.getupvalue(v.Function, 1)
							end
						end
					until camcontrol
					local caminput = require(lplr.PlayerScripts.PlayerModule.CameraModule.CameraInput)
					local num = Instance.new("IntValue")
					local numanim
					shared.damageanim = function()
						if numanim then numanim:Cancel() end
						if Flydamagecamera.Enabled then
							num.Value = 1000
							numanim = tweenService:Create(num, TweenInfo.new(0.5), {Value = 0})
							numanim:Play()
						end
					end
					oldcamupdate = camcontrol.Update
					camcontrol.Update = function(self, dt)
						if camcontrol.activeCameraController then
							camcontrol.activeCameraController:UpdateMouseBehavior()
							local newCameraCFrame, newCameraFocus = camcontrol.activeCameraController:Update(dt)
							gameCamera.CFrame = newCameraCFrame * CFrame.Angles(0, 0, math.rad(num.Value / 100))
							gameCamera.Focus = newCameraFocus
							if camcontrol.activeTransparencyController then
								camcontrol.activeTransparencyController:Update(dt)
							end
							if caminput.getInputEnabled() then
								caminput.resetInputForFrameEnd()
							end
						end
					end
				end)
			else
				shared.damageanim = nil
				if camcontrol then
					camcontrol.Update = oldcamupdate
				end
			end
		end
	})
	Flydamagecamera = Fly.CreateToggle({
		Name = "Camera Animation",
		Function = function() end,
		Default = true
	})
	Flydamagecamera.Object.BorderSizePixel = 0
	Flydamagecamera.Object.BackgroundTransparency = 0
	Flydamagecamera.Object.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	Flydamagecamera.Object.Visible = false
	FlyAnywayProgressBar = Fly.CreateToggle({
		Name = "Progress Bar",
		Function = function(callback)
			if callback then
				FlyAnywayProgressBarFrame = Instance.new("Frame")
				FlyAnywayProgressBarFrame.AnchorPoint = Vector2.new(0.5, 0)
				FlyAnywayProgressBarFrame.Position = UDim2.new(0.5, 0, 1, -200)
				FlyAnywayProgressBarFrame.Size = UDim2.new(0.2, 0, 0, 20)
				FlyAnywayProgressBarFrame.BackgroundTransparency = 0.5
				FlyAnywayProgressBarFrame.BorderSizePixel = 0
				FlyAnywayProgressBarFrame.BackgroundColor3 = Color3.new(0, 0, 0)
				FlyAnywayProgressBarFrame.Visible = Fly.Enabled
				FlyAnywayProgressBarFrame.Parent = GuiLibrary.MainGui
				local FlyAnywayProgressBarFrame2 = FlyAnywayProgressBarFrame:Clone()
				FlyAnywayProgressBarFrame2.AnchorPoint = Vector2.new(0, 0)
				FlyAnywayProgressBarFrame2.Position = UDim2.new(0, 0, 0, 0)
				FlyAnywayProgressBarFrame2.Size = UDim2.new(1, 0, 0, 20)
				FlyAnywayProgressBarFrame2.BackgroundTransparency = 0
				FlyAnywayProgressBarFrame2.Visible = true
				FlyAnywayProgressBarFrame2.Parent = FlyAnywayProgressBarFrame
				local FlyAnywayProgressBartext = Instance.new("TextLabel")
				FlyAnywayProgressBartext.Text = "5s"
				FlyAnywayProgressBartext.Font = Enum.Font.Gotham
				FlyAnywayProgressBartext.TextStrokeTransparency = 0
				FlyAnywayProgressBartext.TextColor3 =  Color3.new(0.9, 0.9, 0.9)
				FlyAnywayProgressBartext.TextSize = 20
				FlyAnywayProgressBartext.Size = UDim2.new(1, 0, 1, 0)
				FlyAnywayProgressBartext.BackgroundTransparency = 1
				FlyAnywayProgressBartext.Position = UDim2.new(0, 0, -1, 0)
				FlyAnywayProgressBartext.Parent = FlyAnywayProgressBarFrame
			else
				if FlyAnywayProgressBarFrame then FlyAnywayProgressBarFrame:Destroy() FlyAnywayProgressBarFrame = nil end
			end
		end,
		HoverText = "show amount of Fly time",
		Default = true
	})
	FlyTP = Fly.CreateToggle({
		Name = "TP Down",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local GrappleExploit = {Enabled = false}
	local GrappleExploitMode = {Value = "Normal"}
	local GrappleExploitVerticalSpeed = {Value = 40}
	local GrappleExploitVertical = {Enabled = true}
	local GrappleExploitUp = false
	local GrappleExploitDown = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	local projectileRemote = bedwars.Client:Get(bedwars.ProjectileRemote)

	--me when I have to fix bw code omegalol
	bedwars.Client:Get("GrapplingHookFunctions"):Connect(function(p4)
		if p4.hookFunction == "PLAYER_IN_TRANSIT" then
			bedwars.CooldownController:setOnCooldown("grappling_hook", 3.5)
		end
	end)

	GrappleExploit = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "GrappleExploit",
		Function = function(callback)
			if callback then
				local grappleHooked = false
				table.insert(GrappleExploit.Connections, bedwars.Client:Get("GrapplingHookFunctions"):Connect(function(p4)
					if p4.hookFunction == "PLAYER_IN_TRANSIT" then
						store.grapple = tick() + 1.8
						grappleHooked = true
						GrappleExploit.ToggleButton(false)
					end
				end))

				local fireball = getItem("grappling_hook")
				if fireball then
					task.spawn(function()
						repeat task.wait() until bedwars.CooldownController:getRemainingCooldown("grappling_hook") == 0 or (not GrappleExploit.Enabled)
						if (not GrappleExploit.Enabled) then return end
						switchItem(fireball.tool)
						local pos = entityLibrary.character.HumanoidRootPart.CFrame.p
						local offsetshootpos = (CFrame.new(pos, pos + Vector3.new(0, -60, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).p
						projectileRemote:CallServerAsync(fireball["tool"], nil, "grappling_hook_projectile", offsetshootpos, pos, Vector3.new(0, -60, 0), game:GetService("HttpService"):GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045)
					end)
				else
					warningNotification("GrappleExploit", "missing grapple hook", 3)
					GrappleExploit.ToggleButton(false)
					return
				end

				local startCFrame = entityLibrary.isAlive and entityLibrary.character.HumanoidRootPart.CFrame
				RunLoops:BindToHeartbeat("GrappleExploit", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if bedwars.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						entityLibrary.character.HumanoidRootPart.Velocity = Vector3.zero
						entityLibrary.character.HumanoidRootPart.CFrame = startCFrame
					end
				end)
			else
				GrappleExploitUp = false
				GrappleExploitDown = false
				RunLoops:UnbindFromHeartbeat("GrappleExploit")
			end
		end,
		HoverText = "Makes you go zoom (longer GrappleExploit discovered by exelys and Cqded)",
		ExtraText = function()
			if GuiLibrary.ObjectsThatCanBeSaved["Text GUIAlternate TextToggle"]["Api"].Enabled then
				return alternatelist[table.find(GrappleExploitMode["List"], GrappleExploitMode.Value)]
			end
			return GrappleExploitMode.Value
		end
	})
end)

run(function()
	local InfiniteFly = {Enabled = false}
	local InfiniteFlyMode = {Value = "CFrame"}
	local InfiniteFlySpeed = {Value = 23}
	local InfiniteFlyVerticalSpeed = {Value = 40}
	local InfiniteFlyVertical = {Enabled = true}
	local InfiniteFlyUp = false
	local InfiniteFlyDown = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	local clonesuccess = false
	local disabledproper = true
	local oldcloneroot
	local cloned
	local clone
	local bodyvelo
	local FlyOverlap = OverlapParams.new()
	FlyOverlap.MaxParts = 9e9
	FlyOverlap.FilterDescendantsInstances = {}
	FlyOverlap.RespectCanCollide = true

	local function disablefunc()
		if bodyvelo then bodyvelo:Destroy() end
		RunLoops:UnbindFromHeartbeat("InfiniteFlyOff")
		disabledproper = true
		if not oldcloneroot or not oldcloneroot.Parent then return end
		lplr.Character.Parent = game
		oldcloneroot.Parent = lplr.Character
		lplr.Character.PrimaryPart = oldcloneroot
		lplr.Character.Parent = workspace
		oldcloneroot.CanCollide = true
		for i,v in pairs(lplr.Character:GetDescendants()) do
			if v:IsA("Weld") or v:IsA("Motor6D") then
				if v.Part0 == clone then v.Part0 = oldcloneroot end
				if v.Part1 == clone then v.Part1 = oldcloneroot end
			end
			if v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
		for i,v in pairs(oldcloneroot:GetChildren()) do
			if v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
		local oldclonepos = clone.Position.Y
		if clone then
			clone:Destroy()
			clone = nil
		end
		lplr.Character.Humanoid.HipHeight = hip or 2
		local origcf = {oldcloneroot.CFrame:GetComponents()}
		origcf[2] = oldclonepos
		oldcloneroot.CFrame = CFrame.new(unpack(origcf))
		oldcloneroot = nil
		warningNotification("InfiniteFly", "Landed!", 3)
	end

	InfiniteFly = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "InfiniteFly",
		Function = function(callback)
			if callback then
				if not entityLibrary.isAlive then
					disabledproper = true
				end
				if not disabledproper then
					warningNotification("InfiniteFly", "Wait for the last fly to finish", 3)
					InfiniteFly.ToggleButton(false)
					return
				end
				table.insert(InfiniteFly.Connections, inputService.InputBegan:Connect(function(input1)
					if InfiniteFlyVertical.Enabled and inputService:GetFocusedTextBox() == nil then
						if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
							InfiniteFlyUp = true
						end
						if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
							InfiniteFlyDown = true
						end
					end
				end))
				table.insert(InfiniteFly.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
						InfiniteFlyUp = false
					end
					if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
						InfiniteFlyDown = false
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						table.insert(InfiniteFly.Connections, jumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
							InfiniteFlyUp = jumpButton.ImageRectOffset.X == 146
						end))
						InfiniteFlyUp = jumpButton.ImageRectOffset.X == 146
					end)
				end
				clonesuccess = false
				if entityLibrary.isAlive and entityLibrary.character.Humanoid.Health > 0 and isnetworkowner(entityLibrary.character.HumanoidRootPart) then
					cloned = lplr.Character
					oldcloneroot = entityLibrary.character.HumanoidRootPart
					if not lplr.Character.Parent then
						InfiniteFly.ToggleButton(false)
						return
					end
					lplr.Character.Parent = game
					clone = oldcloneroot:Clone()
					clone.Parent = lplr.Character
					oldcloneroot.Parent = gameCamera
					bedwars.QueryUtil:setQueryIgnored(oldcloneroot, true)
					clone.CFrame = oldcloneroot.CFrame
					lplr.Character.PrimaryPart = clone
					lplr.Character.Parent = workspace
					for i,v in pairs(lplr.Character:GetDescendants()) do
						if v:IsA("Weld") or v:IsA("Motor6D") then
							if v.Part0 == oldcloneroot then v.Part0 = clone end
							if v.Part1 == oldcloneroot then v.Part1 = clone end
						end
						if v:IsA("BodyVelocity") then
							v:Destroy()
						end
					end
					for i,v in pairs(oldcloneroot:GetChildren()) do
						if v:IsA("BodyVelocity") then
							v:Destroy()
						end
					end
					if hip then
						lplr.Character.Humanoid.HipHeight = hip
					end
					hip = lplr.Character.Humanoid.HipHeight
					clonesuccess = true
				end
				if not clonesuccess then
					warningNotification("InfiniteFly", "Character missing", 3)
					InfiniteFly.ToggleButton(false)
					return
				end
				local goneup = false
				RunLoops:BindToHeartbeat("InfiniteFly", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						if isnetworkowner(oldcloneroot) then
							local playerMass = (entityLibrary.character.HumanoidRootPart:GetMass() - 1.4) * (delta * 100)

							local flyVelocity = entityLibrary.character.Humanoid.MoveDirection * (InfiniteFlyMode.Value == "Normal" and InfiniteFlySpeed.Value or 20)
							entityLibrary.character.HumanoidRootPart.Velocity = flyVelocity + (Vector3.new(0, playerMass + (InfiniteFlyUp and InfiniteFlyVerticalSpeed.Value or 0) + (InfiniteFlyDown and -InfiniteFlyVerticalSpeed.Value or 0), 0))
							if InfiniteFlyMode.Value ~= "Normal" then
								entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + (entityLibrary.character.Humanoid.MoveDirection * ((InfiniteFlySpeed.Value + getSpeed()) - 20)) * delta
							end

							local speedCFrame = {oldcloneroot.CFrame:GetComponents()}
							speedCFrame[1] = clone.CFrame.X
							if speedCFrame[2] < 1000 or (not goneup) then
								task.spawn(warningNotification, "InfiniteFly", "Teleported Up", 3)
								speedCFrame[2] = 100000
								goneup = true
							end
							speedCFrame[3] = clone.CFrame.Z
							oldcloneroot.CFrame = CFrame.new(unpack(speedCFrame))
							oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, oldcloneroot.Velocity.Y, clone.Velocity.Z)
						else
							InfiniteFly.ToggleButton(false)
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("InfiniteFly")
				if clonesuccess and oldcloneroot and clone and lplr.Character.Parent == workspace and oldcloneroot.Parent ~= nil and disabledproper and cloned == lplr.Character then
					local rayparams = RaycastParams.new()
					rayparams.FilterDescendantsInstances = {lplr.Character, gameCamera}
					rayparams.RespectCanCollide = true
					local ray = workspace:Raycast(Vector3.new(oldcloneroot.Position.X, clone.CFrame.p.Y, oldcloneroot.Position.Z), Vector3.new(0, -1000, 0), rayparams)
					local origcf = {clone.CFrame:GetComponents()}
					origcf[1] = oldcloneroot.Position.X
					origcf[2] = ray and ray.Position.Y + (entityLibrary.character.Humanoid.HipHeight + (oldcloneroot.Size.Y / 2)) or clone.CFrame.p.Y
					origcf[3] = oldcloneroot.Position.Z
					oldcloneroot.CanCollide = true
					bodyvelo = Instance.new("BodyVelocity")
					bodyvelo.MaxForce = Vector3.new(0, 9e9, 0)
					bodyvelo.Velocity = Vector3.new(0, -1, 0)
					bodyvelo.Parent = oldcloneroot
					oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, -1, clone.Velocity.Z)
					RunLoops:BindToHeartbeat("InfiniteFlyOff", function(dt)
						if oldcloneroot then
							oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, -1, clone.Velocity.Z)
							local bruh = {clone.CFrame:GetComponents()}
							bruh[2] = oldcloneroot.CFrame.Y
							local newcf = CFrame.new(unpack(bruh))
							FlyOverlap.FilterDescendantsInstances = {lplr.Character, gameCamera}
							local allowed = true
							for i,v in pairs(workspace:GetPartBoundsInRadius(newcf.p, 2, FlyOverlap)) do
								if (v.Position.Y + (v.Size.Y / 2)) > (newcf.p.Y + 0.5) then
									allowed = false
									break
								end
							end
							if allowed then
								oldcloneroot.CFrame = newcf
							end
						end
					end)
					oldcloneroot.CFrame = CFrame.new(unpack(origcf))
					entityLibrary.character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
					disabledproper = false
					if isnetworkowner(oldcloneroot) then
						warningNotification("InfiniteFly", "Waiting 1.1s to not flag", 3)
						task.delay(1.1, disablefunc)
					else
						disablefunc()
					end
				end
				InfiniteFlyUp = false
				InfiniteFlyDown = false
			end
		end,
		HoverText = "Makes you go zoom",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	InfiniteFlySpeed = InfiniteFly.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	InfiniteFlyVerticalSpeed = InfiniteFly.CreateSlider({
		Name = "Vertical Speed",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 44
	})
	InfiniteFlyVertical = InfiniteFly.CreateToggle({
		Name = "Y Level",
		Function = function() end,
		Default = true
	})
end)

local killauraNearPlayer
run(function()
	local killauraboxes = {}
	local killauratargetframe = {Players = {Enabled = false}}
	local killaurasortmethod = {Value = "Distance"}
	local killaurarealremote = bedwars.Client:Get(bedwars.AttackRemote).instance
	local killauramethod = {Value = "Normal"}
	local killauraothermethod = {Value = "Normal"}
	local killauraanimmethod = {Value = "Normal"}
	local killaurarange = {Value = 14}
	local killauraangle = {Value = 360}
	local killauratargets = {Value = 10}
	local killauraautoblock = {Enabled = false}
	local killauramouse = {Enabled = false}
	local killauracframe = {Enabled = false}
	local killauragui = {Enabled = false}
	local killauratarget = {Enabled = false}
	local killaurasound = {Enabled = false}
	local killauraswing = {Enabled = false}
	local killaurasync = {Enabled = false}
	local killaurahandcheck = {Enabled = false}
	local killauraanimation = {Enabled = false}
	local killauraanimationtween = {Enabled = false}
	local killauracolor = {Value = 0.44}
	local killauranovape = {Enabled = false}
	local killauratargethighlight = {Enabled = false}
	local killaurarangecircle = {Enabled = false}
	local killaurarangecirclepart
	local killauraaimcircle = {Enabled = false}
	local killauraaimcirclepart
	local killauraparticle = {Enabled = false}
	local killauraparticlepart
	local Killauranear = false
	local killauraplaying = false
	local oldViewmodelAnimation = function() end
	local oldPlaySound = function() end
	local originalArmC0 = nil
	local killauracurrentanim
	local animationdelay = tick()

	local function getStrength(plr)
		local inv = store.inventories[plr.Player]
		local strength = 0
		local strongestsword = 0
		if inv then
			for i,v in pairs(inv.items) do
				local itemmeta = bedwars.ItemTable[v.itemType]
				if itemmeta and itemmeta.sword and itemmeta.sword.damage > strongestsword then
					strongestsword = itemmeta.sword.damage / 100
				end
			end
			strength = strength + strongestsword
			for i,v in pairs(inv.armor) do
				local itemmeta = bedwars.ItemTable[v.itemType]
				if itemmeta and itemmeta.armor then
					strength = strength + (itemmeta.armor.damageReductionMultiplier or 0)
				end
			end
			strength = strength
		end
		return strength
	end

	local kitpriolist = {
		hannah = 5,
		spirit_assassin = 4,
		dasher = 3,
		jade = 2,
		regent = 1
	}

	local killaurasortmethods = {
		Distance = function(a, b)
			return (a.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).Magnitude < (b.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).Magnitude
		end,
		Health = function(a, b)
			return a.Humanoid.Health < b.Humanoid.Health
		end,
		Threat = function(a, b)
			return getStrength(a) > getStrength(b)
		end,
		Kit = function(a, b)
			return (kitpriolist[a.Player:GetAttribute("PlayingAsKit")] or 0) > (kitpriolist[b.Player:GetAttribute("PlayingAsKit")] or 0)
		end
	}

	local originalNeckC0
	local originalRootC0
	local anims = {
		Normal = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.05},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.05}
		},
		Slow = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.15}
		},
		New = {
			{CFrame = CFrame.new(0.69, -0.77, 1.47) * CFrame.Angles(math.rad(-33), math.rad(57), math.rad(-81)), Time = 0.12},
			{CFrame = CFrame.new(0.74, -0.92, 0.88) * CFrame.Angles(math.rad(147), math.rad(71), math.rad(53)), Time = 0.12}
		},
		Latest = {
			{CFrame = CFrame.new(0.69, -0.7, 0.1) * CFrame.Angles(math.rad(-65), math.rad(55), math.rad(-51)), Time = 0.1},
			{CFrame = CFrame.new(0.16, -1.16, 0.5) * CFrame.Angles(math.rad(-179), math.rad(54), math.rad(33)), Time = 0.1}
		},
		["Vertical Spin"] = {
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), math.rad(8), math.rad(5)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(180), math.rad(3), math.rad(13)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(90), math.rad(-5), math.rad(8)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-0), math.rad(-0)), Time = 0.1}
		},
		Exhibition = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.2}
		},
		["Exhibition Old"] = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.05},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.05},
			{CFrame = CFrame.new(0.63, -0.1, 1.37) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.15}
		}
	}

	local function closestpos(block, pos)
		local blockpos = block:GetRenderCFrame()
		local startpos = (blockpos * CFrame.new(-(block.Size / 2))).p
		local endpos = (blockpos * CFrame.new((block.Size / 2))).p
		local speedCFrame = block.Position + (pos - block.Position)
		local x = startpos.X > endpos.X and endpos.X or startpos.X
		local y = startpos.Y > endpos.Y and endpos.Y or startpos.Y
		local z = startpos.Z > endpos.Z and endpos.Z or startpos.Z
		local x2 = startpos.X < endpos.X and endpos.X or startpos.X
		local y2 = startpos.Y < endpos.Y and endpos.Y or startpos.Y
		local z2 = startpos.Z < endpos.Z and endpos.Z or startpos.Z
		return Vector3.new(math.clamp(speedCFrame.X, x, x2), math.clamp(speedCFrame.Y, y, y2), math.clamp(speedCFrame.Z, z, z2))
	end

	local function getAttackData()
		if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
			if store.matchState == 0 then return false end
		end
		if killauramouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end
		if killauragui.Enabled then
			if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end
		local sword = killaurahandcheck.Enabled and store.localHand or getSword()
		if not sword or not sword.tool then return false end
		local swordmeta = bedwars.ItemTable[sword.tool.Name]
		if killaurahandcheck.Enabled then
			if store.localHand.Type ~= "sword" or bedwars.DaoController.chargingMaid then return false end
		end
		return sword, swordmeta
	end

	local function autoBlockLoop()
		if not killauraautoblock.Enabled or not Killaura.Enabled then return end
		repeat
			if store.blockPlace < tick() and entityLibrary.isAlive then
				local shield = getItem("infernal_shield")
				if shield then
					switchItem(shield.tool)
					if not lplr.Character:GetAttribute("InfernalShieldRaised") then
						bedwars.InfernalShieldController:raiseShield()
					end
				end
			end
			task.wait()
		until (not Killaura.Enabled) or (not killauraautoblock.Enabled)
	end

	Killaura = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Killaura",
		Function = function(callback)
			if callback then
				if killauraaimcirclepart then killauraaimcirclepart.Parent = gameCamera end
				if killaurarangecirclepart then killaurarangecirclepart.Parent = gameCamera end
				if killauraparticlepart then killauraparticlepart.Parent = gameCamera end

				task.spawn(function()
					local oldNearPlayer
					repeat
						task.wait()
						if (killauraanimation.Enabled and not killauraswing.Enabled) then
							if killauraNearPlayer then
								pcall(function()
									if originalArmC0 == nil then
										originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
									end
									if killauraplaying == false then
										killauraplaying = true
										for i,v in pairs(anims[killauraanimmethod.Value]) do
											if (not Killaura.Enabled) or (not killauraNearPlayer) then break end
											if not oldNearPlayer and killauraanimationtween.Enabled then
												gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0 * v.CFrame
												continue
											end
											killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(v.Time), {C0 = originalArmC0 * v.CFrame})
											killauracurrentanim:Play()
											task.wait(v.Time - 0.01)
										end
										killauraplaying = false
									end
								end)
							end
							oldNearPlayer = killauraNearPlayer
						end
					until Killaura.Enabled == false
				end)

				oldViewmodelAnimation = bedwars.ViewmodelController.playAnimation
				oldPlaySound = bedwars.SoundManager.playSound
				bedwars.SoundManager.playSound = function(tab, soundid, ...)
					if (soundid == bedwars.SoundList.SWORD_SWING_1 or soundid == bedwars.SoundList.SWORD_SWING_2) and Killaura.Enabled and killaurasound.Enabled and killauraNearPlayer then
						return nil
					end
					return oldPlaySound(tab, soundid, ...)
				end
				bedwars.ViewmodelController.playAnimation = function(Self, id, ...)
					if id == 15 and killauraNearPlayer and killauraswing.Enabled and entityLibrary.isAlive then
						return nil
					end
					if id == 15 and killauraNearPlayer and killauraanimation.Enabled and entityLibrary.isAlive then
						return nil
					end
					return oldViewmodelAnimation(Self, id, ...)
				end

				local targetedPlayer
				RunLoops:BindToHeartbeat("Killaura", function()
					for i,v in pairs(killauraboxes) do
						if v:IsA("BoxHandleAdornment") and v.Adornee then
							local cf = v.Adornee and v.Adornee.CFrame
							local onex, oney, onez = cf:ToEulerAnglesXYZ()
							v.CFrame = CFrame.new() * CFrame.Angles(-onex, -oney, -onez)
						end
					end
					if entityLibrary.isAlive then
						if killauraaimcirclepart then
							killauraaimcirclepart.Position = targetedPlayer and closestpos(targetedPlayer.RootPart, entityLibrary.character.HumanoidRootPart.Position) or Vector3.new(99999, 99999, 99999)
						end
						if killauraparticlepart then
							killauraparticlepart.Position = targetedPlayer and targetedPlayer.RootPart.Position or Vector3.new(99999, 99999, 99999)
						end
						local Root = entityLibrary.character.HumanoidRootPart
						if Root then
							if killaurarangecirclepart then
								killaurarangecirclepart.Position = Root.Position - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)
							end
							local Neck = entityLibrary.character.Head:FindFirstChild("Neck")
							local LowerTorso = Root.Parent and Root.Parent:FindFirstChild("LowerTorso")
							local RootC0 = LowerTorso and LowerTorso:FindFirstChild("Root")
							if Neck and RootC0 then
								if originalNeckC0 == nil then
									originalNeckC0 = Neck.C0.p
								end
								if originalRootC0 == nil then
									originalRootC0 = RootC0.C0.p
								end
								if originalRootC0 and killauracframe.Enabled then
									if targetedPlayer ~= nil then
										local targetPos = targetedPlayer.RootPart.Position + Vector3.new(0, 2, 0)
										local direction = (Vector3.new(targetPos.X, targetPos.Y, targetPos.Z) - entityLibrary.character.Head.Position).Unit
										local direction2 = (Vector3.new(targetPos.X, Root.Position.Y, targetPos.Z) - Root.Position).Unit
										local lookCFrame = (CFrame.new(Vector3.zero, (Root.CFrame):VectorToObjectSpace(direction)))
										local lookCFrame2 = (CFrame.new(Vector3.zero, (Root.CFrame):VectorToObjectSpace(direction2)))
										Neck.C0 = CFrame.new(originalNeckC0) * CFrame.Angles(lookCFrame.LookVector.Unit.y, 0, 0)
										RootC0.C0 = lookCFrame2 + originalRootC0
									else
										Neck.C0 = CFrame.new(originalNeckC0)
										RootC0.C0 = CFrame.new(originalRootC0)
									end
								end
							end
						end
					end
				end)
				if killauraautoblock.Enabled then
					task.spawn(autoBlockLoop)
				end
				task.spawn(function()
					repeat
						task.wait()
						if not Killaura.Enabled then break end
						vapeTargetInfo.Targets.Killaura = nil
						local plrs = AllNearPosition(killaurarange.Value, 10, killaurasortmethods[killaurasortmethod.Value], true)
						local firstPlayerNear
						if #plrs > 0 then
							local sword, swordmeta = getAttackData()
							if sword then
								switchItem(sword.tool)
								for i, plr in pairs(plrs) do
									local root = plr.RootPart
									if not root then
										continue
									end
									local localfacing = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
									local vec = (plr.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).unit
									local angle = math.acos(localfacing:Dot(vec))
									if angle >= (math.rad(killauraangle.Value) / 2) then
										continue
									end
									local selfrootpos = entityLibrary.character.HumanoidRootPart.Position
									if killauratargetframe.Walls.Enabled then
										if not bedwars.SwordController:canSee({player = plr.Player, getInstance = function() return plr.Character end}) then continue end
									end
									if killauranovape.Enabled and store.whitelist.clientUsers[plr.Player.Name] then
										continue
									end
									if not firstPlayerNear then
										firstPlayerNear = true
										killauraNearPlayer = true
										targetedPlayer = plr
										vapeTargetInfo.Targets.Killaura = {
											Humanoid = {
												Health = (plr.Character:GetAttribute("Health") or plr.Humanoid.Health) + getShieldAttribute(plr.Character),
												MaxHealth = plr.Character:GetAttribute("MaxHealth") or plr.Humanoid.MaxHealth
											},
											Player = plr.Player
										}
										if animationdelay <= tick() then
											animationdelay = tick() + (swordmeta.sword.respectAttackSpeedForEffects and swordmeta.sword.attackSpeed or (killaurasync.Enabled and 0.24 or 0.14))
											if not killauraswing.Enabled then
												bedwars.SwordController:playSwordEffect(swordmeta, false)
											end
											if swordmeta.displayName:find(" Scythe") then
												bedwars.ScytheController:playLocalAnimation()
											end
										end
									end
									if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) < 0.02 then
										break
									end
									local selfpos = selfrootpos + (killaurarange.Value > 14 and (selfrootpos - root.Position).magnitude > 14.4 and (CFrame.lookAt(selfrootpos, root.Position).lookVector * ((selfrootpos - root.Position).magnitude - 14)) or Vector3.zero)
									bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
									store.attackReach = math.floor((selfrootpos - root.Position).magnitude * 100) / 100
									store.attackReachUpdate = tick() + 1
									killaurarealremote:FireServer({
										weapon = sword.tool,
										chargedAttack = {chargeRatio = swordmeta.sword.chargedAttack and not swordmeta.sword.chargedAttack.disableOnGrounded and 0.999 or 0},
										entityInstance = plr.Character,
										validate = {
											raycast = {
												cameraPosition = attackValue(root.Position),
												cursorDirection = attackValue(CFrame.new(selfpos, root.Position).lookVector)
											},
											targetPosition = attackValue(root.Position),
											selfPosition = attackValue(selfpos)
										}
									})
									break
								end
							end
						end
						if not firstPlayerNear then
							targetedPlayer = nil
							killauraNearPlayer = false
							pcall(function()
								if originalArmC0 == nil then
									originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
								end
								if gameCamera.Viewmodel.RightHand.RightWrist.C0 ~= originalArmC0 then
									pcall(function()
										killauracurrentanim:Cancel()
									end)
									if killauraanimationtween.Enabled then
										gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0
									else
										killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.1), {C0 = originalArmC0})
										killauracurrentanim:Play()
									end
								end
							end)
						end
						for i,v in pairs(killauraboxes) do
							local attacked = killauratarget.Enabled and plrs[i] or nil
							v.Adornee = attacked and ((not killauratargethighlight.Enabled) and attacked.RootPart or (not GuiLibrary.ObjectsThatCanBeSaved.ChamsOptionsButton.Api.Enabled) and attacked.Character or nil)
						end
					until (not Killaura.Enabled)
				end)
			else
				vapeTargetInfo.Targets.Killaura = nil
				RunLoops:UnbindFromHeartbeat("Killaura")
				killauraNearPlayer = false
				for i,v in pairs(killauraboxes) do v.Adornee = nil end
				if killauraaimcirclepart then killauraaimcirclepart.Parent = nil end
				if killaurarangecirclepart then killaurarangecirclepart.Parent = nil end
				if killauraparticlepart then killauraparticlepart.Parent = nil end
				bedwars.ViewmodelController.playAnimation = oldViewmodelAnimation
				bedwars.SoundManager.playSound = oldPlaySound
				oldViewmodelAnimation = nil
				pcall(function()
					if entityLibrary.isAlive then
						local Root = entityLibrary.character.HumanoidRootPart
						if Root then
							local Neck = Root.Parent.Head.Neck
							if originalNeckC0 and originalRootC0 then
								Neck.C0 = CFrame.new(originalNeckC0)
								Root.Parent.LowerTorso.Root.C0 = CFrame.new(originalRootC0)
							end
						end
					end
					if originalArmC0 == nil then
						originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
					end
					if gameCamera.Viewmodel.RightHand.RightWrist.C0 ~= originalArmC0 then
						pcall(function()
							killauracurrentanim:Cancel()
						end)
						if killauraanimationtween.Enabled then
							gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0
						else
							killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.1), {C0 = originalArmC0})
							killauracurrentanim:Play()
						end
					end
				end)
			end
		end,
		HoverText = "Attack players around you\nwithout aiming at them."
	})
	killauratargetframe = Killaura.CreateTargetWindow({})
	local sortmethods = {"Distance"}
	for i,v in pairs(killaurasortmethods) do if i ~= "Distance" then table.insert(sortmethods, i) end end
	killaurasortmethod = Killaura.CreateDropdown({
		Name = "Sort",
		Function = function() end,
		List = sortmethods
	})
	killaurarange = Killaura.CreateSlider({
		Name = "Attack range",
		Min = 1,
		Max = 18,
		Function = function(val)
			if killaurarangecirclepart then
				killaurarangecirclepart.Size = Vector3.new(val * 0.7, 0.01, val * 0.7)
			end
		end,
		Default = 18
	})
	killauraangle = Killaura.CreateSlider({
		Name = "Max angle",
		Min = 1,
		Max = 360,
		Function = function(val) end,
		Default = 360
	})
	local animmethods = {}
	for i,v in pairs(anims) do table.insert(animmethods, i) end
	killauraanimmethod = Killaura.CreateDropdown({
		Name = "Animation",
		List = animmethods,
		Function = function(val) end
	})
	local oldviewmodel
	local oldraise
	local oldeffect
	killauraautoblock = Killaura.CreateToggle({
		Name = "AutoBlock",
		Function = function(callback)
			if callback then
				oldviewmodel = bedwars.ViewmodelController.setHeldItem
				bedwars.ViewmodelController.setHeldItem = function(self, newItem, ...)
					if newItem and newItem.Name == "infernal_shield" then
						return
					end
					return oldviewmodel(self, newItem)
				end
				oldraise = bedwars.InfernalShieldController.raiseShield
				bedwars.InfernalShieldController.raiseShield = function(self)
					if os.clock() - self.lastShieldRaised < 0.4 then
						return
					end
					self.lastShieldRaised = os.clock()
					self.infernalShieldState:SendToServer({raised = true})
					self.raisedMaid:GiveTask(function()
						self.infernalShieldState:SendToServer({raised = false})
					end)
				end
				oldeffect = bedwars.InfernalShieldController.playEffect
				bedwars.InfernalShieldController.playEffect = function()
					return
				end
				if bedwars.ViewmodelController.heldItem and bedwars.ViewmodelController.heldItem.Name == "infernal_shield" then
					local sword, swordmeta = getSword()
					if sword then
						bedwars.ViewmodelController:setHeldItem(sword.tool)
					end
				end
				task.spawn(autoBlockLoop)
			else
				bedwars.ViewmodelController.setHeldItem = oldviewmodel
				bedwars.InfernalShieldController.raiseShield = oldraise
				bedwars.InfernalShieldController.playEffect = oldeffect
			end
		end,
		Default = true
	})
	killauramouse = Killaura.CreateToggle({
		Name = "Require mouse down",
		Function = function() end,
		HoverText = "Only attacks when left click is held.",
		Default = false
	})
	killauragui = Killaura.CreateToggle({
		Name = "GUI Check",
		Function = function() end,
		HoverText = "Attacks when you are not in a GUI."
	})
	killauratarget = Killaura.CreateToggle({
		Name = "Show target",
		Function = function(callback)
			if killauratargethighlight.Object then
				killauratargethighlight.Object.Visible = callback
			end
		end,
		HoverText = "Shows a red box over the opponent."
	})
	killauratargethighlight = Killaura.CreateToggle({
		Name = "Use New Highlight",
		Function = function(callback)
			for i, v in pairs(killauraboxes) do
				v:Remove()
			end
			for i = 1, 10 do
				local killaurabox
				if callback then
					killaurabox = Instance.new("Highlight")
					killaurabox.FillTransparency = 0.39
					killaurabox.FillColor = Color3.fromHSV(killauracolor.Hue, killauracolor.Sat, killauracolor.Value)
					killaurabox.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					killaurabox.OutlineTransparency = 1
					killaurabox.Parent = GuiLibrary.MainGui
				else
					killaurabox = Instance.new("BoxHandleAdornment")
					killaurabox.Transparency = 0.39
					killaurabox.Color3 = Color3.fromHSV(killauracolor.Hue, killauracolor.Sat, killauracolor.Value)
					killaurabox.Adornee = nil
					killaurabox.AlwaysOnTop = true
					killaurabox.Size = Vector3.new(3, 6, 3)
					killaurabox.ZIndex = 11
					killaurabox.Parent = GuiLibrary.MainGui
				end
				killauraboxes[i] = killaurabox
			end
		end
	})
	killauratargethighlight.Object.BorderSizePixel = 0
	killauratargethighlight.Object.BackgroundTransparency = 0
	killauratargethighlight.Object.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	killauratargethighlight.Object.Visible = false
	killauracolor = Killaura.CreateColorSlider({
		Name = "Target Color",
		Function = function(hue, sat, val)
			for i,v in pairs(killauraboxes) do
				v[(killauratargethighlight.Enabled and "FillColor" or "Color3")] = Color3.fromHSV(hue, sat, val)
			end
			if killauraaimcirclepart then
				killauraaimcirclepart.Color = Color3.fromHSV(hue, sat, val)
			end
			if killaurarangecirclepart then
				killaurarangecirclepart.Color = Color3.fromHSV(hue, sat, val)
			end
		end,
		Default = 1
	})
	for i = 1, 10 do
		local killaurabox = Instance.new("BoxHandleAdornment")
		killaurabox.Transparency = 0.5
		killaurabox.Color3 = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
		killaurabox.Adornee = nil
		killaurabox.AlwaysOnTop = true
		killaurabox.Size = Vector3.new(3, 6, 3)
		killaurabox.ZIndex = 11
		killaurabox.Parent = GuiLibrary.MainGui
		killauraboxes[i] = killaurabox
	end
	killauracframe = Killaura.CreateToggle({
		Name = "Face target",
		Function = function() end,
		HoverText = "Makes your character face the opponent."
	})
	killaurarangecircle = Killaura.CreateToggle({
		Name = "Range Visualizer",
		Function = function(callback)
			if callback then
				--context issues moment
			--[[	killaurarangecirclepart = Instance.new("MeshPart")
				killaurarangecirclepart.MeshId = "rbxassetid://3726303797"
				killaurarangecirclepart.Color = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
				killaurarangecirclepart.CanCollide = false
				killaurarangecirclepart.Anchored = true
				killaurarangecirclepart.Material = Enum.Material.Neon
				killaurarangecirclepart.Size = Vector3.new(killaurarange.Value * 0.7, 0.01, killaurarange.Value * 0.7)
				if Killaura.Enabled then
					killaurarangecirclepart.Parent = gameCamera
				end
				bedwars.QueryUtil:setQueryIgnored(killaurarangecirclepart, true)]]
			else
				if killaurarangecirclepart then
					killaurarangecirclepart:Destroy()
					killaurarangecirclepart = nil
				end
			end
		end
	})
	killauraaimcircle = Killaura.CreateToggle({
		Name = "Aim Visualizer",
		Function = function(callback)
			if callback then
				killauraaimcirclepart = Instance.new("Part")
				killauraaimcirclepart.Shape = Enum.PartType.Ball
				killauraaimcirclepart.Color = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
				killauraaimcirclepart.CanCollide = false
				killauraaimcirclepart.Anchored = true
				killauraaimcirclepart.Material = Enum.Material.Neon
				killauraaimcirclepart.Size = Vector3.new(0.5, 0.5, 0.5)
				if Killaura.Enabled then
					killauraaimcirclepart.Parent = gameCamera
				end
				bedwars.QueryUtil:setQueryIgnored(killauraaimcirclepart, true)
			else
				if killauraaimcirclepart then
					killauraaimcirclepart:Destroy()
					killauraaimcirclepart = nil
				end
			end
		end
	})
	killauraparticle = Killaura.CreateToggle({
		Name = "Crit Particle",
		Function = function(callback)
			if callback then
				killauraparticlepart = Instance.new("Part")
				killauraparticlepart.Transparency = 1
				killauraparticlepart.CanCollide = false
				killauraparticlepart.Anchored = true
				killauraparticlepart.Size = Vector3.new(3, 6, 3)
				killauraparticlepart.Parent = cam
				bedwars.QueryUtil:setQueryIgnored(killauraparticlepart, true)
				local particle = Instance.new("ParticleEmitter")
				particle.Lifetime = NumberRange.new(0.5)
				particle.Rate = 500
				particle.Speed = NumberRange.new(0)
				particle.RotSpeed = NumberRange.new(180)
				particle.Enabled = true
				particle.Size = NumberSequence.new(0.3)
				particle.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(67, 10, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 98, 255))})
				particle.Parent = killauraparticlepart
			else
				if killauraparticlepart then
					killauraparticlepart:Destroy()
					killauraparticlepart = nil
				end
			end
		end
	})
	killaurasound = Killaura.CreateToggle({
		Name = "No Swing Sound",
		Function = function() end,
		HoverText = "Removes the swinging sound."
	})
	killauraswing = Killaura.CreateToggle({
		Name = "No Swing",
		Function = function() end,
		HoverText = "Removes the swinging animation."
	})
	killaurahandcheck = Killaura.CreateToggle({
		Name = "Limit to items",
		Function = function() end,
		HoverText = "Only attacks when your sword is held."
	})
	killauraanimation = Killaura.CreateToggle({
		Name = "Custom Animation",
		Function = function(callback)
			if killauraanimationtween.Object then killauraanimationtween.Object.Visible = callback end
		end,
		HoverText = "Uses a custom animation for swinging"
	})
	killauraanimationtween = Killaura.CreateToggle({
		Name = "No Tween",
		Function = function() end,
		HoverText = "Disable's the in and out ease"
	})
	killauraanimationtween.Object.Visible = false
	killaurasync = Killaura.CreateToggle({
		Name = "Synced Animation",
		Function = function() end,
		HoverText = "Times animation with hit attempt"
	})
	killauranovape = Killaura.CreateToggle({
		Name = "No Vape",
		Function = function() end,
		HoverText = "no hit vape user"
	})
	killauranovape.Object.Visible = false
end)

local LongJump = {Enabled = false}
run(function()
	local damagetimer = 0
	local damagetimertick = 0
	local directionvec
	local LongJumpSpeed = {Value = 1.5}
	local projectileRemote = bedwars.Client:Get(bedwars.ProjectileRemote)

	local function calculatepos(vec)
		local returned = vec
		if entityLibrary.isAlive then
			local newray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, returned, store.blockRaycast)
			if newray then returned = (newray.Position - entityLibrary.character.HumanoidRootPart.Position) end
		end
		return returned
	end

	local damagemethods = {
		fireball = function(fireball, pos)
			if not LongJump.Enabled then return end
			pos = pos - (entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 0.2)
			if not (getPlacedBlock(pos - Vector3.new(0, 3, 0)) or getPlacedBlock(pos - Vector3.new(0, 6, 0))) then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://4809574295"
				sound.Parent = workspace
				sound.Ended:Connect(function()
					sound:Destroy()
				end)
				sound:Play()
			end
			local origpos = pos
			local offsetshootpos = (CFrame.new(pos, pos + Vector3.new(0, -60, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).p
			local ray = workspace:Raycast(pos, Vector3.new(0, -30, 0), store.blockRaycast)
			if ray then
				pos = ray.Position
				offsetshootpos = pos
			end
			task.spawn(function()
				switchItem(fireball.tool)
				bedwars.ProjectileController:createLocalProjectile(bedwars.ProjectileMeta.fireball, "fireball", "fireball", offsetshootpos, "", Vector3.new(0, -60, 0), {drawDurationSeconds = 1})
				projectileRemote:CallServerAsync(fireball.tool, "fireball", "fireball", offsetshootpos, pos, Vector3.new(0, -60, 0), game:GetService("HttpService"):GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045)
			end)
		end,
		tnt = function(tnt, pos2)
			if not LongJump.Enabled then return end
			local pos = Vector3.new(pos2.X, getScaffold(Vector3.new(0, pos2.Y - (((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight) - 1.5), 0)).Y, pos2.Z)
			local block = bedwars.placeBlock(pos, "tnt")
		end,
		cannon = function(tnt, pos2)
			task.spawn(function()
				local pos = Vector3.new(pos2.X, getScaffold(Vector3.new(0, pos2.Y - (((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight) - 1.5), 0)).Y, pos2.Z)
				local block = bedwars.placeBlock(pos, "cannon")
				task.delay(0.1, function()
					local block, pos2 = getPlacedBlock(pos)
					if block and block.Name == "cannon" and (entityLibrary.character.HumanoidRootPart.CFrame.p - block.Position).Magnitude < 20 then
						switchToAndUseTool(block)
						local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
						local damage = bedwars.BlockController:calculateBlockDamage(lplr, {
							blockPosition = pos2
						})
						bedwars.Client:Get(bedwars.CannonAimRemote):SendToServer({
							cannonBlockPos = pos2,
							lookVector = vec
						})
						local broken = 0.1
						if damage < block:GetAttribute("Health") then
							task.spawn(function()
								broken = 0.4
								bedwars.breakBlock(block.Position, true, getBestBreakSide(block.Position), true, true)
							end)
						end
						task.delay(broken, function()
							for i = 1, 3 do
								local call = bedwars.Client:Get(bedwars.CannonLaunchRemote):CallServer({cannonBlockPos = bedwars.BlockController:getBlockPosition(block.Position)})
								if call then
									bedwars.breakBlock(block.Position, true, getBestBreakSide(block.Position), true, true)
									task.delay(0.1, function()
										damagetimer = LongJumpSpeed.Value * 5
										damagetimertick = tick() + 2.5
										directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
									end)
									break
								end
								task.wait(0.1)
							end
						end)
					end
				end)
			end)
		end,
		wood_dao = function(tnt, pos2)
			task.spawn(function()
				switchItem(tnt.tool)
				if not (not lplr.Character:GetAttribute("CanDashNext") or lplr.Character:GetAttribute("CanDashNext") < workspace:GetServerTimeNow()) then
					repeat task.wait() until (not lplr.Character:GetAttribute("CanDashNext") or lplr.Character:GetAttribute("CanDashNext") < workspace:GetServerTimeNow()) or not LongJump.Enabled
				end
				if LongJump.Enabled then
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					replicatedStorage["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"].useAbility:FireServer("dash", {
						direction = vec,
						origin = entityLibrary.character.HumanoidRootPart.CFrame.p,
						weapon = tnt.itemType
					})
					damagetimer = LongJumpSpeed.Value * 3.5
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end,
		jade_hammer = function(tnt, pos2)
			task.spawn(function()
				if not bedwars.AbilityController:canUseAbility("jade_hammer_jump") then
					repeat task.wait() until bedwars.AbilityController:canUseAbility("jade_hammer_jump") or not LongJump.Enabled
					task.wait(0.1)
				end
				if bedwars.AbilityController:canUseAbility("jade_hammer_jump") and LongJump.Enabled then
					bedwars.AbilityController:useAbility("jade_hammer_jump")
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					damagetimer = LongJumpSpeed.Value * 2.75
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end,
		void_axe = function(tnt, pos2)
			task.spawn(function()
				if not bedwars.AbilityController:canUseAbility("void_axe_jump") then
					repeat task.wait() until bedwars.AbilityController:canUseAbility("void_axe_jump") or not LongJump.Enabled
					task.wait(0.1)
				end
				if bedwars.AbilityController:canUseAbility("void_axe_jump") and LongJump.Enabled then
					bedwars.AbilityController:useAbility("void_axe_jump")
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					damagetimer = LongJumpSpeed.Value * 2.75
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end
	}
	damagemethods.stone_dao = damagemethods.wood_dao
	damagemethods.iron_dao = damagemethods.wood_dao
	damagemethods.diamond_dao = damagemethods.wood_dao
	damagemethods.emerald_dao = damagemethods.wood_dao

	local oldgrav
	local LongJumpacprogressbarframe = Instance.new("Frame")
	LongJumpacprogressbarframe.AnchorPoint = Vector2.new(0.5, 0)
	LongJumpacprogressbarframe.Position = UDim2.new(0.5, 0, 1, -200)
	LongJumpacprogressbarframe.Size = UDim2.new(0.2, 0, 0, 20)
	LongJumpacprogressbarframe.BackgroundTransparency = 0.5
	LongJumpacprogressbarframe.BorderSizePixel = 0
	LongJumpacprogressbarframe.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
	LongJumpacprogressbarframe.Visible = LongJump.Enabled
	LongJumpacprogressbarframe.Parent = GuiLibrary.MainGui
	local LongJumpacprogressbarframe2 = LongJumpacprogressbarframe:Clone()
	LongJumpacprogressbarframe2.AnchorPoint = Vector2.new(0, 0)
	LongJumpacprogressbarframe2.Position = UDim2.new(0, 0, 0, 0)
	LongJumpacprogressbarframe2.Size = UDim2.new(1, 0, 0, 20)
	LongJumpacprogressbarframe2.BackgroundTransparency = 0
	LongJumpacprogressbarframe2.Visible = true
	LongJumpacprogressbarframe2.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
	LongJumpacprogressbarframe2.Parent = LongJumpacprogressbarframe
	local LongJumpacprogressbartext = Instance.new("TextLabel")
	LongJumpacprogressbartext.Text = "2.5s"
	LongJumpacprogressbartext.Font = Enum.Font.Gotham
	LongJumpacprogressbartext.TextStrokeTransparency = 0
	LongJumpacprogressbartext.TextColor3 =  Color3.new(0.9, 0.9, 0.9)
	LongJumpacprogressbartext.TextSize = 20
	LongJumpacprogressbartext.Size = UDim2.new(1, 0, 1, 0)
	LongJumpacprogressbartext.BackgroundTransparency = 1
	LongJumpacprogressbartext.Position = UDim2.new(0, 0, -1, 0)
	LongJumpacprogressbartext.Parent = LongJumpacprogressbarframe
	LongJump = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "LongJump",
		Function = function(callback)
			if callback then
				table.insert(LongJump.Connections, vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.entityInstance == lplr.Character and (not damageTable.knockbackMultiplier or not damageTable.knockbackMultiplier.disabled) then
						local knockbackBoost = damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal and damageTable.knockbackMultiplier.horizontal * LongJumpSpeed.Value or LongJumpSpeed.Value
						if damagetimertick < tick() or knockbackBoost >= damagetimer then
							damagetimer = knockbackBoost
							damagetimertick = tick() + 2.5
							local newDirection = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
							directionvec = Vector3.new(newDirection.X, 0, newDirection.Z).Unit
						end
					end
				end))
				task.spawn(function()
					task.spawn(function()
						repeat
							task.wait()
							if LongJumpacprogressbarframe then
								LongJumpacprogressbarframe.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
								LongJumpacprogressbarframe2.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
							end
						until (not LongJump.Enabled)
					end)
					local LongJumpOrigin = entityLibrary.isAlive and entityLibrary.character.HumanoidRootPart.Position
					local tntcheck
					for i,v in pairs(damagemethods) do
						local item = getItem(i)
						if item then
							if i == "tnt" then
								local pos = getScaffold(LongJumpOrigin)
								tntcheck = Vector3.new(pos.X, LongJumpOrigin.Y, pos.Z)
								v(item, pos)
							else
								v(item, LongJumpOrigin)
							end
							break
						end
					end
					local changecheck
					LongJumpacprogressbarframe.Visible = true
					RunLoops:BindToHeartbeat("LongJump", function(dt)
						if entityLibrary.isAlive then
							if entityLibrary.character.Humanoid.Health <= 0 then
								LongJump.ToggleButton(false)
								return
							end
							if not LongJumpOrigin then
								LongJumpOrigin = entityLibrary.character.HumanoidRootPart.Position
							end
							local newval = damagetimer ~= 0
							if changecheck ~= newval then
								if newval then
									LongJumpacprogressbarframe2:TweenSize(UDim2.new(0, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 2.5, true)
								else
									LongJumpacprogressbarframe2:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
								end
								changecheck = newval
							end
							if newval then
								local newnum = math.max(math.floor((damagetimertick - tick()) * 10) / 10, 0)
								if LongJumpacprogressbartext then
									LongJumpacprogressbartext.Text = newnum.."s"
								end
								if directionvec == nil then
									directionvec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
								end
								local longJumpCFrame = Vector3.new(directionvec.X, 0, directionvec.Z)
								local newvelo = longJumpCFrame.Unit == longJumpCFrame.Unit and longJumpCFrame.Unit * (newnum > 1 and damagetimer or 20) or Vector3.zero
								newvelo = Vector3.new(newvelo.X, 0, newvelo.Z)
								longJumpCFrame = longJumpCFrame * (getSpeed() + 3) * dt
								local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, longJumpCFrame, store.blockRaycast)
								if ray then
									longJumpCFrame = Vector3.zero
									newvelo = Vector3.zero
								end

								entityLibrary.character.HumanoidRootPart.Velocity = newvelo
								entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + longJumpCFrame
							else
								LongJumpacprogressbartext.Text = "2.5s"
								entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(LongJumpOrigin, LongJumpOrigin + entityLibrary.character.HumanoidRootPart.CFrame.lookVector)
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
								if tntcheck then
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(tntcheck + entityLibrary.character.HumanoidRootPart.CFrame.lookVector, tntcheck + (entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 2))
								end
							end
						else
							if LongJumpacprogressbartext then
								LongJumpacprogressbartext.Text = "2.5s"
							end
							LongJumpOrigin = nil
							tntcheck = nil
						end
					end)
				end)
			else
				LongJumpacprogressbarframe.Visible = false
				RunLoops:UnbindFromHeartbeat("LongJump")
				directionvec = nil
				tntcheck = nil
				LongJumpOrigin = nil
				damagetimer = 0
				damagetimertick = 0
			end
		end,
		HoverText = "Lets you jump farther (Not landing on same level & Spamming can lead to lagbacks)"
	})
	LongJumpSpeed = LongJump.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 52,
		Function = function() end,
		Default = 52
	})
end)

run(function()
	local NoFall = {Enabled = false}
	local oldfall
	NoFall = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "NoFall",
		Function = function(callback)
			if callback then
				bedwars.Client:Get("GroundHit"):SendToServer()
			end
		end,
		HoverText = "Prevents taking fall damage."
	})
end)

run(function()
	local NoSlowdown = {Enabled = false}
	local OldSetSpeedFunc
	NoSlowdown = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "NoSlowdown",
		Function = function(callback)
			if callback then
				OldSetSpeedFunc = bedwars.SprintController.setSpeed
				bedwars.SprintController.setSpeed = function(tab1, val1)
					local hum = entityLibrary.character.Humanoid
					if hum then
						hum.WalkSpeed = math.max(20 * tab1.moveSpeedMultiplier, 20)
					end
				end
				bedwars.SprintController:setSpeed(20)
			else
				bedwars.SprintController.setSpeed = OldSetSpeedFunc
				bedwars.SprintController:setSpeed(20)
				OldSetSpeedFunc = nil
			end
		end,
		HoverText = "Prevents slowing down when using items."
	})
end)

local spiderActive = false
local holdingshift = false
run(function()
	local activatePhase = false
	local oldActivatePhase = false
	local PhaseDelay = tick()
	local Phase = {Enabled = false}
	local PhaseStudLimit = {Value = 1}
	local PhaseModifiedParts = {}
	local raycastparameters = RaycastParams.new()
	raycastparameters.RespectCanCollide = true
	raycastparameters.FilterType = Enum.RaycastFilterType.Whitelist
	local overlapparams = OverlapParams.new()
	overlapparams.RespectCanCollide = true

	local function isPointInMapOccupied(p)
		overlapparams.FilterDescendantsInstances = {lplr.Character, gameCamera}
		local possible = workspace:GetPartBoundsInBox(CFrame.new(p), Vector3.new(1, 2, 1), overlapparams)
		return (#possible == 0)
	end

	Phase = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Phase",
		Function = function(callback)
			if callback then
				RunLoops:BindToHeartbeat("Phase", function()
					if entityLibrary.isAlive and entityLibrary.character.Humanoid.MoveDirection ~= Vector3.zero and (not GuiLibrary.ObjectsThatCanBeSaved.SpiderOptionsButton.Api.Enabled or holdingshift) then
						if PhaseDelay <= tick() then
							raycastparameters.FilterDescendantsInstances = {store.blocks, collectionService:GetTagged("spawn-cage"), workspace.SpectatorPlatform}
							local PhaseRayCheck = workspace:Raycast(entityLibrary.character.Head.CFrame.p, entityLibrary.character.Humanoid.MoveDirection * 1.15, raycastparameters)
							if PhaseRayCheck then
								local PhaseDirection = (PhaseRayCheck.Normal.Z ~= 0 or not PhaseRayCheck.Instance:GetAttribute("GreedyBlock")) and "Z" or "X"
								if PhaseRayCheck.Instance.Size[PhaseDirection] <= PhaseStudLimit.Value * 3 and PhaseRayCheck.Instance.CanCollide and PhaseRayCheck.Normal.Y == 0 then
									local PhaseDestination = entityLibrary.character.HumanoidRootPart.CFrame + (PhaseRayCheck.Normal * (-(PhaseRayCheck.Instance.Size[PhaseDirection]) - (entityLibrary.character.HumanoidRootPart.Size.X / 1.5)))
									if isPointInMapOccupied(PhaseDestination.p) then
										PhaseDelay = tick() + 1
										entityLibrary.character.HumanoidRootPart.CFrame = PhaseDestination
									end
								end
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("Phase")
			end
		end,
		HoverText = "Lets you Phase/Clip through walls. (Hold shift to use Phase over spider)"
	})
	PhaseStudLimit = Phase.CreateSlider({
		Name = "Blocks",
		Min = 1,
		Max = 3,
		Function = function() end
	})
end)

run(function()
	local oldCalculateAim
	local BowAimbotProjectiles = {Enabled = false}
	local BowAimbotPart = {Value = "HumanoidRootPart"}
	local BowAimbotFOV = {Value = 1000}
	local BowAimbot = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "ProjectileAimbot",
		Function = function(callback)
			if callback then
				oldCalculateAim = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(self, projmeta, worldmeta, shootpospart, ...)
					local plr = EntityNearMouse(BowAimbotFOV.Value)
					if plr then
						local startPos = self:getLaunchPosition(shootpospart)
						if not startPos then
							return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
						end

						if (not BowAimbotProjectiles.Enabled) and projmeta.projectile:find("arrow") == nil then
							return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
						end

						local projmetatab = projmeta:getProjectileMeta()
						local projectilePrediction = (worldmeta and projmetatab.predictionLifetimeSec or projmetatab.lifetimeSec or 3)
						local projectileSpeed = (projmetatab.launchVelocity or 100)
						local gravity = (projmetatab.gravitationalAcceleration or 196.2)
						local projectileGravity = gravity * projmeta.gravityMultiplier
						local offsetStartPos = startPos + projmeta.fromPositionOffset
						local pos = plr.Character[BowAimbotPart.Value].Position
						local playerGravity = workspace.Gravity
						local balloons = plr.Character:GetAttribute("InflatedBalloons")

						if balloons and balloons > 0 then
							playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
						end

						if plr.Character.PrimaryPart:FindFirstChild("rbxassetid://8200754399") then
							playerGravity = (workspace.Gravity * 0.3)
						end

						local shootpos, shootvelo = predictGravity(pos, plr.Character.HumanoidRootPart.Velocity, (pos - offsetStartPos).Magnitude / projectileSpeed, plr, playerGravity)
						if projmeta.projectile == "telepearl" then
							shootpos = pos
							shootvelo = Vector3.zero
						end

						local newlook = CFrame.new(offsetStartPos, shootpos) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, 0))
						shootpos = newlook.p + (newlook.lookVector * (offsetStartPos - shootpos).magnitude)
						local calculated = LaunchDirection(offsetStartPos, shootpos, projectileSpeed, projectileGravity, false)
						oldmove = plr.Character.Humanoid.MoveDirection
						if calculated then
							return {
								initialVelocity = calculated,
								positionFrom = offsetStartPos,
								deltaT = projectilePrediction,
								gravitationalAcceleration = projectileGravity,
								drawDurationSeconds = 5
							}
						end
					end
					return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
				end
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = oldCalculateAim
			end
		end
	})
	BowAimbotPart = BowAimbot.CreateDropdown({
		Name = "Part",
		List = {"HumanoidRootPart", "Head"},
		Function = function() end
	})
	BowAimbotFOV = BowAimbot.CreateSlider({
		Name = "FOV",
		Function = function() end,
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	BowAimbotProjectiles = BowAimbot.CreateToggle({
		Name = "Other Projectiles",
		Function = function() end,
		Default = true
	})
end)

--until I find a way to make the spam switch item thing not bad I'll just get rid of it, sorry.
local Scaffold = {Enabled = false}
run(function()
	local scaffoldtext = Instance.new("TextLabel")
	scaffoldtext.Font = Enum.Font.SourceSans
	scaffoldtext.TextSize = 20
	scaffoldtext.BackgroundTransparency = 1
	scaffoldtext.TextColor3 = Color3.fromRGB(255, 0, 0)
	scaffoldtext.Size = UDim2.new(0, 0, 0, 0)
	scaffoldtext.Position = UDim2.new(0.5, 0, 0.5, 30)
	scaffoldtext.Text = "0"
	scaffoldtext.Visible = false
	scaffoldtext.Parent = GuiLibrary.MainGui
	local ScaffoldExpand = {Value = 1}
	local ScaffoldDiagonal = {Enabled = false}
	local ScaffoldTower = {Enabled = false}
	local ScaffoldDownwards = {Enabled = false}
	local ScaffoldStopMotion = {Enabled = false}
	local ScaffoldBlockCount = {Enabled = false}
	local ScaffoldHandCheck = {Enabled = false}
	local ScaffoldMouseCheck = {Enabled = false}
	local ScaffoldAnimation = {Enabled = false}
	local scaffoldstopmotionval = false
	local scaffoldposcheck = tick()
	local scaffoldstopmotionpos = Vector3.zero
	local scaffoldposchecklist = {}
	task.spawn(function()
		for x = -3, 3, 3 do
			for y = -3, 3, 3 do
				for z = -3, 3, 3 do
					if Vector3.new(x, y, z) ~= Vector3.new(0, 0, 0) then
						table.insert(scaffoldposchecklist, Vector3.new(x, y, z))
					end
				end
			end
		end
	end)

	local function checkblocks(pos)
		for i,v in pairs(scaffoldposchecklist) do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end

	local function closestpos(block, pos)
		local startpos = block.Position - (block.Size / 2) - Vector3.new(1.5, 1.5, 1.5)
		local endpos = block.Position + (block.Size / 2) + Vector3.new(1.5, 1.5, 1.5)
		local speedCFrame = block.Position + (pos - block.Position)
		return Vector3.new(math.clamp(speedCFrame.X, startpos.X, endpos.X), math.clamp(speedCFrame.Y, startpos.Y, endpos.Y), math.clamp(speedCFrame.Z, startpos.Z, endpos.Z))
	end

	local function getclosesttop(newmag, pos)
		local closest, closestmag = pos, newmag * 3
		if entityLibrary.isAlive then
			for i,v in pairs(store.blocks) do
				local close = closestpos(v, pos)
				local mag = (close - pos).magnitude
				if mag <= closestmag then
					closest = close
					closestmag = mag
				end
			end
		end
		return closest
	end

	local oldspeed
	Scaffold = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Scaffold",
		Function = function(callback)
			if callback then
				scaffoldtext.Visible = ScaffoldBlockCount.Enabled
				if entityLibrary.isAlive then
					scaffoldstopmotionpos = entityLibrary.character.HumanoidRootPart.CFrame.p
				end
				task.spawn(function()
					repeat
						task.wait()
						if ScaffoldHandCheck.Enabled then
							if store.localHand.Type ~= "block" then continue end
						end
						if ScaffoldMouseCheck.Enabled then
							if not inputService:IsMouseButtonPressed(0) then continue end
						end
						if entityLibrary.isAlive then
							local wool, woolamount = getWool()
							if store.localHand.Type == "block" then
								wool = store.localHand.tool.Name
								woolamount = getItem(store.localHand.tool.Name).amount or 0
							elseif (not wool) then
								wool, woolamount = getBlock()
							end

							scaffoldtext.Text = (woolamount and tostring(woolamount) or "0")
							scaffoldtext.TextColor3 = woolamount and (woolamount >= 128 and Color3.fromRGB(9, 255, 198) or woolamount >= 64 and Color3.fromRGB(255, 249, 18)) or Color3.fromRGB(255, 0, 0)
							if not wool then continue end

							local towering = ScaffoldTower.Enabled and inputService:IsKeyDown(Enum.KeyCode.Space) and game:GetService("UserInputService"):GetFocusedTextBox() == nil
							if towering then
								if (not scaffoldstopmotionval) and ScaffoldStopMotion.Enabled then
									scaffoldstopmotionval = true
									scaffoldstopmotionpos = entityLibrary.character.HumanoidRootPart.CFrame.p
								end
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 28, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								if ScaffoldStopMotion.Enabled and scaffoldstopmotionval then
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(scaffoldstopmotionpos.X, entityLibrary.character.HumanoidRootPart.CFrame.p.Y, scaffoldstopmotionpos.Z))
								end
							else
								scaffoldstopmotionval = false
							end

							for i = 1, ScaffoldExpand.Value do
								local speedCFrame = getScaffold((entityLibrary.character.HumanoidRootPart.Position + ((scaffoldstopmotionval and Vector3.zero or entityLibrary.character.Humanoid.MoveDirection) * (i * 3.5))) + Vector3.new(0, -((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight + (inputService:IsKeyDown(Enum.KeyCode.LeftShift) and ScaffoldDownwards.Enabled and 4.5 or 1.5))), 0)
								speedCFrame = Vector3.new(speedCFrame.X, speedCFrame.Y - (towering and 4 or 0), speedCFrame.Z)
								if speedCFrame ~= oldpos then
									if not checkblocks(speedCFrame) then
										local oldspeedCFrame = speedCFrame
										speedCFrame = getScaffold(getclosesttop(20, speedCFrame))
										if getPlacedBlock(speedCFrame) then speedCFrame = oldspeedCFrame end
									end
									if ScaffoldAnimation.Enabled then
										if not getPlacedBlock(speedCFrame) then
										bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
										end
									end
									task.spawn(bedwars.placeBlock, speedCFrame, wool, ScaffoldAnimation.Enabled)
									if ScaffoldExpand.Value > 1 then
										task.wait()
									end
									oldpos = speedCFrame
								end
							end
						end
					until (not Scaffold.Enabled)
				end)
			else
				scaffoldtext.Visible = false
				oldpos = Vector3.zero
				oldpos2 = Vector3.zero
			end
		end,
		HoverText = "Helps you make bridges/scaffold walk."
	})
	ScaffoldExpand = Scaffold.CreateSlider({
		Name = "Expand",
		Min = 1,
		Max = 8,
		Function = function(val) end,
		Default = 1,
		HoverText = "Build range"
	})
	ScaffoldDiagonal = Scaffold.CreateToggle({
		Name = "Diagonal",
		Function = function(callback) end,
		Default = true
	})
	ScaffoldTower = Scaffold.CreateToggle({
		Name = "Tower",
		Function = function(callback)
			if ScaffoldStopMotion.Object then
				ScaffoldTower.Object.ToggleArrow.Visible = callback
				ScaffoldStopMotion.Object.Visible = callback
			end
		end
	})
	ScaffoldMouseCheck = Scaffold.CreateToggle({
		Name = "Require mouse down",
		Function = function(callback) end,
		HoverText = "Only places when left click is held.",
	})
	ScaffoldDownwards  = Scaffold.CreateToggle({
		Name = "Downwards",
		Function = function(callback) end,
		HoverText = "Goes down when left shift is held."
	})
	ScaffoldStopMotion = Scaffold.CreateToggle({
		Name = "Stop Motion",
		Function = function() end,
		HoverText = "Stops your movement when going up"
	})
	ScaffoldStopMotion.Object.BackgroundTransparency = 0
	ScaffoldStopMotion.Object.BorderSizePixel = 0
	ScaffoldStopMotion.Object.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ScaffoldStopMotion.Object.Visible = ScaffoldTower.Enabled
	ScaffoldBlockCount = Scaffold.CreateToggle({
		Name = "Block Count",
		Function = function(callback)
			if Scaffold.Enabled then
				scaffoldtext.Visible = callback
			end
		end,
		HoverText = "Shows the amount of blocks in the middle."
	})
	ScaffoldHandCheck = Scaffold.CreateToggle({
		Name = "Whitelist Only",
		Function = function() end,
		HoverText = "Only builds with blocks in your hand."
	})
	ScaffoldAnimation = Scaffold.CreateToggle({
		Name = "Animation",
		Function = function() end
	})
end)

local antivoidvelo
run(function()
	local Speed = {Enabled = false}
	local SpeedMode = {Value = "CFrame"}
	local SpeedValue = {Value = 1}
	local SpeedValueLarge = {Value = 1}
	local SpeedJump = {Enabled = false}
	local SpeedJumpHeight = {Value = 20}
	local SpeedJumpAlways = {Enabled = false}
	local SpeedJumpSound = {Enabled = false}
	local SpeedJumpVanilla = {Enabled = false}
	local SpeedAnimation = {Enabled = false}
	local raycastparameters = RaycastParams.new()

	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	Speed = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Speed",
		Function = function(callback)
			if callback then
				RunLoops:BindToHeartbeat("Speed", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						if not (isnetworkowner(entityLibrary.character.HumanoidRootPart) and entityLibrary.character.Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing and (not spiderActive) and (not GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled)) then return end
						if GuiLibrary.ObjectsThatCanBeSaved.GrappleExploitOptionsButton and GuiLibrary.ObjectsThatCanBeSaved.GrappleExploitOptionsButton.Api.Enabled then return end
						if LongJump.Enabled then return end
						if SpeedAnimation.Enabled then
							for i, v in pairs(entityLibrary.character.Humanoid:GetPlayingAnimationTracks()) do
								if v.Name == "WalkAnim" or v.Name == "RunAnim" then
									v:AdjustSpeed(entityLibrary.character.Humanoid.WalkSpeed / 16)
								end
							end
						end

						local speedValue = SpeedValue.Value + getSpeed()
						local speedVelocity = entityLibrary.character.Humanoid.MoveDirection * (SpeedMode.Value == "Normal" and SpeedValue.Value or 20)
						entityLibrary.character.HumanoidRootPart.Velocity = antivoidvelo or Vector3.new(speedVelocity.X, entityLibrary.character.HumanoidRootPart.Velocity.Y, speedVelocity.Z)
						if SpeedMode.Value ~= "Normal" then
							local speedCFrame = entityLibrary.character.Humanoid.MoveDirection * (speedValue - 20) * delta
							raycastparameters.FilterDescendantsInstances = {lplr.Character}
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, speedCFrame, raycastparameters)
							if ray then speedCFrame = (ray.Position - entityLibrary.character.HumanoidRootPart.Position) end
							entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + speedCFrame
						end

						if SpeedJump.Enabled and (not Scaffold.Enabled) and (SpeedJumpAlways.Enabled or killauraNearPlayer) then
							if (entityLibrary.character.Humanoid.FloorMaterial ~= Enum.Material.Air) and entityLibrary.character.Humanoid.MoveDirection ~= Vector3.zero then
								if SpeedJumpSound.Enabled then
									pcall(function() entityLibrary.character.HumanoidRootPart.Jumping:Play() end)
								end
								if SpeedJumpVanilla.Enabled then
									entityLibrary.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								else
									entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, SpeedJumpHeight.Value, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								end
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("Speed")
			end
		end,
		HoverText = "Increases your movement.",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	SpeedValue = Speed.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	SpeedValueLarge = Speed.CreateSlider({
		Name = "Big Mode Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	SpeedJump = Speed.CreateToggle({
		Name = "AutoJump",
		Function = function(callback)
			if SpeedJumpHeight.Object then SpeedJumpHeight.Object.Visible = callback end
			if SpeedJumpAlways.Object then
				SpeedJump.Object.ToggleArrow.Visible = callback
				SpeedJumpAlways.Object.Visible = callback
			end
			if SpeedJumpSound.Object then SpeedJumpSound.Object.Visible = callback end
			if SpeedJumpVanilla.Object then SpeedJumpVanilla.Object.Visible = callback end
		end,
		Default = true
	})
	SpeedJumpHeight = Speed.CreateSlider({
		Name = "Jump Height",
		Min = 0,
		Max = 30,
		Default = 25,
		Function = function() end
	})
	SpeedJumpAlways = Speed.CreateToggle({
		Name = "Always Jump",
		Function = function() end
	})
	SpeedJumpSound = Speed.CreateToggle({
		Name = "Jump Sound",
		Function = function() end
	})
	SpeedJumpVanilla = Speed.CreateToggle({
		Name = "Real Jump",
		Function = function() end
	})
	SpeedAnimation = Speed.CreateToggle({
		Name = "Slowdown Anim",
		Function = function() end
	})
end)

run(function()
	local function roundpos(dir, pos, size)
		local suc, res = pcall(function() return Vector3.new(math.clamp(dir.X, pos.X - (size.X / 2), pos.X + (size.X / 2)), math.clamp(dir.Y, pos.Y - (size.Y / 2), pos.Y + (size.Y / 2)), math.clamp(dir.Z, pos.Z - (size.Z / 2), pos.Z + (size.Z / 2))) end)
		return suc and res or Vector3.zero
	end

	local Spider = {Enabled = false}
	local SpiderSpeed = {Value = 0}
	local SpiderMode = {Value = "Normal"}
	local SpiderPart
	Spider = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Spider",
		Function = function(callback)
			if callback then
				table.insert(Spider.Connections, inputService.InputBegan:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.LeftShift then
						holdingshift = true
					end
				end))
				table.insert(Spider.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.LeftShift then
						holdingshift = false
					end
				end))
				RunLoops:BindToHeartbeat("Spider", function()
					if entityLibrary.isAlive and (GuiLibrary.ObjectsThatCanBeSaved.PhaseOptionsButton.Api.Enabled == false or holdingshift == false) then
						if SpiderMode.Value == "Normal" then
							local vec = entityLibrary.character.Humanoid.MoveDirection * 2
							local newray = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + (vec + Vector3.new(0, 0.1, 0)))
							local newray2 = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + (vec - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)))
							if newray and (not newray.CanCollide) then newray = nil end
							if newray2 and (not newray2.CanCollide) then newray2 = nil end
							if spiderActive and (not newray) and (not newray2) then
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 0, entityLibrary.character.HumanoidRootPart.Velocity.Z)
							end
							spiderActive = ((newray or newray2) and true or false)
							if (newray or newray2) then
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(newray2 and newray == nil and entityLibrary.character.HumanoidRootPart.Velocity.X or 0, SpiderSpeed.Value, newray2 and newray == nil and entityLibrary.character.HumanoidRootPart.Velocity.Z or 0)
							end
						else
							if not SpiderPart then
								SpiderPart = Instance.new("TrussPart")
								SpiderPart.Size = Vector3.new(2, 2, 2)
								SpiderPart.Transparency = 1
								SpiderPart.Anchored = true
								SpiderPart.Parent = gameCamera
							end
							local newray2, newray2pos = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + ((entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 1.5) - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)))
							if newray2 and (not newray2.CanCollide) then newray2 = nil end
							spiderActive = (newray2 and true or false)
							if newray2 then
								newray2pos = newray2pos * 3
								local newpos = roundpos(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(newray2pos.X, math.min(entityLibrary.character.HumanoidRootPart.Position.Y, newray2pos.Y), newray2pos.Z), Vector3.new(1.1, 1.1, 1.1))
								SpiderPart.Position = newpos
							else
								SpiderPart.Position = Vector3.zero
							end
						end
					end
				end)
			else
				if SpiderPart then SpiderPart:Destroy() end
				RunLoops:UnbindFromHeartbeat("Spider")
				holdingshift = false
			end
		end,
		HoverText = "Lets you climb up walls"
	})
	SpiderMode = Spider.CreateDropdown({
		Name = "Mode",
		List = {"Normal", "Classic"},
		Function = function()
			if SpiderPart then SpiderPart:Destroy() end
		end
	})
	SpiderSpeed = Spider.CreateSlider({
		Name = "Speed",
		Min = 0,
		Max = 40,
		Function = function() end,
		Default = 40
	})
end)

run(function()
	local TargetStrafe = {Enabled = false}
	local TargetStrafeRange = {Value = 18}
	local oldmove
	local controlmodule
	local block
	TargetStrafe = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "TargetStrafe",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if not controlmodule then
						local suc = pcall(function() controlmodule = require(lplr.PlayerScripts.PlayerModule).controls end)
						if not suc then controlmodule = {} end
					end
					oldmove = controlmodule.moveFunction
					local ang = 0
					local oldplr
					block = Instance.new("Part")
					block.Anchored = true
					block.CanCollide = false
					block.Parent = gameCamera
					controlmodule.moveFunction = function(Self, vec, facecam, ...)
						if entityLibrary.isAlive then
							local plr = AllNearPosition(TargetStrafeRange.Value + 5, 10)[1]
							plr = plr and (not workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, (plr.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position), store.blockRaycast)) and workspace:Raycast(plr.RootPart.Position, Vector3.new(0, -70, 0), store.blockRaycast) and plr or nil
							if plr ~= oldplr then
								if plr then
									local x, y, z = CFrame.new(plr.RootPart.Position, entityLibrary.character.HumanoidRootPart.Position):ToEulerAnglesXYZ()
									ang = math.deg(z)
								end
								oldplr = plr
							end
							if plr then
								facecam = false
								local localPos = CFrame.new(plr.RootPart.Position)
								local ray = workspace:Blockcast(localPos, Vector3.new(3, 3, 3), CFrame.Angles(0, math.rad(ang), 0).lookVector * TargetStrafeRange.Value, store.blockRaycast)
								local newPos = localPos + (CFrame.Angles(0, math.rad(ang), 0).lookVector * (ray and ray.Distance - 1 or TargetStrafeRange.Value))
								local factor = getSpeed() > 0 and 6 or 4
								if not workspace:Raycast(newPos.p, Vector3.new(0, -70, 0), store.blockRaycast) then
									newPos = localPos
									factor = 40
								end
								if ((entityLibrary.character.HumanoidRootPart.Position * Vector3.new(1, 0, 1)) - (newPos.p * Vector3.new(1, 0, 1))).Magnitude < 4 or ray then
									ang = ang + factor % 360
								end
								block.Position = newPos.p
								vec = (newPos.p - entityLibrary.character.HumanoidRootPart.Position) * Vector3.new(1, 0, 1)
							end
						end
						return oldmove(Self, vec, facecam, ...)
					end
				end)
			else
				block:Destroy()
				controlmodule.moveFunction = oldmove
			end
		end
	})
	TargetStrafeRange = TargetStrafe.CreateSlider({
		Name = "Range",
		Min = 0,
		Max = 18,
		Function = function() end
	})
end)

run(function()
	local BedESP = {Enabled = false}
	local BedESPFolder = Instance.new("Folder")
	BedESPFolder.Name = "BedESPFolder"
	BedESPFolder.Parent = GuiLibrary.MainGui
	local BedESPTable = {}
	local BedESPColor = {Value = 0.44}
	local BedESPTransparency = {Value = 1}
	local BedESPOnTop = {Enabled = true}
	BedESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "BedESP",
		Function = function(callback)
			if callback then
				table.insert(BedESP.Connections, collectionService:GetInstanceAddedSignal("bed"):Connect(function(bed)
					task.wait(0.2)
					if not BedESP.Enabled then return end
					local BedFolder = Instance.new("Folder")
					BedFolder.Parent = BedESPFolder
					BedESPTable[bed] = BedFolder
					for bedespnumber, bedesppart in pairs(bed:GetChildren()) do
						if bedesppart.Name ~= 'Bed' then continue end
						local boxhandle = Instance.new("BoxHandleAdornment")
						boxhandle.Size = bedesppart.Size + Vector3.new(.01, .01, .01)
						boxhandle.AlwaysOnTop = true
						boxhandle.ZIndex = (bedesppart.Name == "Covers" and 10 or 0)
						boxhandle.Visible = true
						boxhandle.Adornee = bedesppart
						boxhandle.Color3 = bedesppart.Color
						boxhandle.Name = bedespnumber
						boxhandle.Parent = BedFolder
					end
				end))
				table.insert(BedESP.Connections, collectionService:GetInstanceRemovedSignal("bed"):Connect(function(bed)
					if BedESPTable[bed] then
						BedESPTable[bed]:Destroy()
						BedESPTable[bed] = nil
					end
				end))
				for i, bed in pairs(collectionService:GetTagged("bed")) do
					local BedFolder = Instance.new("Folder")
					BedFolder.Parent = BedESPFolder
					BedESPTable[bed] = BedFolder
					for bedespnumber, bedesppart in pairs(bed:GetChildren()) do
						if bedesppart:IsA("BasePart") then
							local boxhandle = Instance.new("BoxHandleAdornment")
							boxhandle.Size = bedesppart.Size + Vector3.new(.01, .01, .01)
							boxhandle.AlwaysOnTop = true
							boxhandle.ZIndex = (bedesppart.Name == "Covers" and 10 or 0)
							boxhandle.Visible = true
							boxhandle.Adornee = bedesppart
							boxhandle.Color3 = bedesppart.Color
							boxhandle.Parent = BedFolder
						end
					end
				end
			else
				BedESPFolder:ClearAllChildren()
				table.clear(BedESPTable)
			end
		end,
		HoverText = "Render Beds through walls"
	})
end)

run(function()
	local function getallblocks2(pos, normal)
		local blocks = {}
		local lastfound = nil
		for i = 1, 20 do
			local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
			local extrablock = getPlacedBlock(blockpos)
			local covered = true
			if extrablock and extrablock.Parent ~= nil then
				if bedwars.BlockController:isBlockBreakable({blockPosition = blockpos}, lplr) then
					table.insert(blocks, extrablock:GetAttribute("NoBreak") and "unbreakable" or extrablock.Name)
				else
					table.insert(blocks, "unbreakable")
					break
				end
				lastfound = extrablock
				if covered == false then
					break
				end
			else
				break
			end
		end
		return blocks
	end

	local function getallbedblocks(pos)
		local blocks = {}
		for i,v in pairs(cachedNormalSides) do
			for i2,v2 in pairs(getallblocks2(pos, v)) do
				if table.find(blocks, v2) == nil and v2 ~= "bed" then
					table.insert(blocks, v2)
				end
			end
			for i2,v2 in pairs(getallblocks2(pos + Vector3.new(0, 0, 3), v)) do
				if table.find(blocks, v2) == nil and v2 ~= "bed" then
					table.insert(blocks, v2)
				end
			end
		end
		return blocks
	end

	local function refreshAdornee(v)
		local bedblocks = getallbedblocks(v.Adornee.Position)
		for i2,v2 in pairs(v.Frame:GetChildren()) do
			if v2:IsA("ImageLabel") then
				v2:Remove()
			end
		end
		for i3,v3 in pairs(bedblocks) do
			local blockimage = Instance.new("ImageLabel")
			blockimage.Size = UDim2.new(0, 32, 0, 32)
			blockimage.BackgroundTransparency = 1
			blockimage.Image = bedwars.getIcon({itemType = v3}, true)
			blockimage.Parent = v.Frame
		end
	end

	local BedPlatesFolder = Instance.new("Folder")
	BedPlatesFolder.Name = "BedPlatesFolder"
	BedPlatesFolder.Parent = GuiLibrary.MainGui
	local BedPlatesTable = {}
	local BedPlates = {Enabled = false}

	local function addBed(v)
		local billboard = Instance.new("BillboardGui")
		billboard.Parent = BedPlatesFolder
		billboard.Name = "bed"
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
		billboard.Size = UDim2.new(0, 42, 0, 42)
		billboard.AlwaysOnTop = true
		billboard.Adornee = v
		BedPlatesTable[v] = billboard
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0.5
		frame.Parent = billboard
		local uilistlayout = Instance.new("UIListLayout")
		uilistlayout.FillDirection = Enum.FillDirection.Horizontal
		uilistlayout.Padding = UDim.new(0, 4)
		uilistlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uilistlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			billboard.Size = UDim2.new(0, math.max(uilistlayout.AbsoluteContentSize.X + 12, 42), 0, 42)
		end)
		uilistlayout.Parent = frame
		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = frame
		refreshAdornee(billboard)
	end

	BedPlates = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "BedPlates",
		Function = function(callback)
			if callback then
				table.insert(BedPlates.Connections, vapeEvents.PlaceBlockEvent.Event:Connect(function(p5)
					for i, v in pairs(BedPlatesFolder:GetChildren()) do
						if v.Adornee then
							if ((p5.blockRef.blockPosition * 3) - v.Adornee.Position).magnitude <= 20 then
								refreshAdornee(v)
							end
						end
					end
				end))
				table.insert(BedPlates.Connections, vapeEvents.BreakBlockEvent.Event:Connect(function(p5)
					for i, v in pairs(BedPlatesFolder:GetChildren()) do
						if v.Adornee then
							if ((p5.blockRef.blockPosition * 3) - v.Adornee.Position).magnitude <= 20 then
								refreshAdornee(v)
							end
						end
					end
				end))
				table.insert(BedPlates.Connections, collectionService:GetInstanceAddedSignal("bed"):Connect(function(v)
					addBed(v)
				end))
				table.insert(BedPlates.Connections, collectionService:GetInstanceRemovedSignal("bed"):Connect(function(v)
					if BedPlatesTable[v] then
						BedPlatesTable[v]:Destroy()
						BedPlatesTable[v] = nil
					end
				end))
				for i, v in pairs(collectionService:GetTagged("bed")) do
					addBed(v)
				end
			else
				BedPlatesFolder:ClearAllChildren()
			end
		end
	})
end)

run(function()
	local ChestESPList = {ObjectList = {}, RefreshList = function() end}
	local function nearchestitem(item)
		for i,v in pairs(ChestESPList.ObjectList) do
			if item:find(v) then return v end
		end
	end
	local function refreshAdornee(v)
		local chest = v:FindFirstChild("ChestFolderValue")
		chest = chest and chest.Value or nil
		if not chest then return end
		local chestitems = chest and chest:GetChildren() or {}
		for i2,v2 in pairs(v.Frame:GetChildren()) do
			if v2:IsA("ImageLabel") then
				v2:Remove()
			end
		end
		v.Enabled = false
		local alreadygot = {}
		for itemNumber, item in pairs(chestitems) do
			if alreadygot[item.Name] == nil and (table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name)) then
				alreadygot[item.Name] = true
				v.Enabled = true
				local blockimage = Instance.new("ImageLabel")
				blockimage.Size = UDim2.new(0, 32, 0, 32)
				blockimage.BackgroundTransparency = 1
				blockimage.Image = bedwars.getIcon({itemType = item.Name}, true)
				blockimage.Parent = v.Frame
			end
		end
	end

	local ChestESPFolder = Instance.new("Folder")
	ChestESPFolder.Name = "ChestESPFolder"
	ChestESPFolder.Parent = GuiLibrary.MainGui
	local ChestESP = {Enabled = false}
	local ChestESPBackground = {Enabled = true}

	local function chestfunc(v)
		task.spawn(function()
			local chest = v:FindFirstChild("ChestFolderValue")
			chest = chest and chest.Value or nil
			if not chest then return end
			local billboard = Instance.new("BillboardGui")
			billboard.Parent = ChestESPFolder
			billboard.Name = "chest"
			billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
			billboard.Size = UDim2.new(0, 42, 0, 42)
			billboard.AlwaysOnTop = true
			billboard.Adornee = v
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.new(0, 0, 0)
			frame.BackgroundTransparency = ChestESPBackground.Enabled and 0.5 or 1
			frame.Parent = billboard
			local uilistlayout = Instance.new("UIListLayout")
			uilistlayout.FillDirection = Enum.FillDirection.Horizontal
			uilistlayout.Padding = UDim.new(0, 4)
			uilistlayout.VerticalAlignment = Enum.VerticalAlignment.Center
			uilistlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				billboard.Size = UDim2.new(0, math.max(uilistlayout.AbsoluteContentSize.X + 12, 42), 0, 42)
			end)
			uilistlayout.Parent = frame
			local uicorner = Instance.new("UICorner")
			uicorner.CornerRadius = UDim.new(0, 4)
			uicorner.Parent = frame
			if chest then
				table.insert(ChestESP.Connections, chest.ChildAdded:Connect(function(item)
					if table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name) then
						refreshAdornee(billboard)
					end
				end))
				table.insert(ChestESP.Connections, chest.ChildRemoved:Connect(function(item)
					if table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name) then
						refreshAdornee(billboard)
					end
				end))
				refreshAdornee(billboard)
			end
		end)
	end

	ChestESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "ChestESP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					table.insert(ChestESP.Connections, collectionService:GetInstanceAddedSignal("chest"):Connect(chestfunc))
					for i,v in pairs(collectionService:GetTagged("chest")) do chestfunc(v) end
				end)
			else
				ChestESPFolder:ClearAllChildren()
			end
		end
	})
	ChestESPList = ChestESP.CreateTextList({
		Name = "ItemList",
		TempText = "item or part of item",
		AddFunction = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end,
		RemoveFunction = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end
	})
	ChestESPBackground = ChestESP.CreateToggle({
		Name = "Background",
		Function = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end,
		Default = true
	})
end)

run(function()
	local FieldOfViewValue = {Value = 70}
	local oldfov
	local oldfov2
	local FieldOfView = {Enabled = false}
	local FieldOfViewZoom = {Enabled = false}
	FieldOfView = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "FOVChanger",
		Function = function(callback)
			if callback then
				if FieldOfViewZoom.Enabled then
					task.spawn(function()
						repeat
							task.wait()
						until not inputService:IsKeyDown(Enum.KeyCode[FieldOfView.Keybind ~= "" and FieldOfView.Keybind or "C"])
						if FieldOfView.Enabled then
							FieldOfView.ToggleButton(false)
						end
					end)
				end
				oldfov = bedwars.FovController.setFOV
				oldfov2 = bedwars.FovController.getFOV
				bedwars.FovController.setFOV = function(self, fov) return oldfov(self, FieldOfViewValue.Value) end
				bedwars.FovController.getFOV = function(self, fov) return FieldOfViewValue.Value end
			else
				bedwars.FovController.setFOV = oldfov
				bedwars.FovController.getFOV = oldfov2
			end
			bedwars.FovController:setFOV(bedwars.ClientStoreHandler:getState().Settings.fov)
		end
	})
	FieldOfViewValue = FieldOfView.CreateSlider({
		Name = "FOV",
		Min = 30,
		Max = 120,
		Function = function(val)
			if FieldOfView.Enabled then
				bedwars.FovController:setFOV(bedwars.ClientStoreHandler:getState().Settings.fov)
			end
		end
	})
	FieldOfViewZoom = FieldOfView.CreateToggle({
		Name = "Zoom",
		Function = function() end,
		HoverText = "optifine zoom lol"
	})
end)

run(function()
	local old
	local old2
	local oldhitpart
	local FPSBoost = {Enabled = false}
	local removetextures = {Enabled = false}
	local removetexturessmooth = {Enabled = false}
	local fpsboostdamageindicator = {Enabled = false}
	local fpsboostdamageeffect = {Enabled = false}
	local fpsboostkilleffect = {Enabled = false}
	local originaltextures = {}
	local originaleffects = {}

	local function fpsboosttextures()
		task.spawn(function()
			repeat task.wait() until store.matchState ~= 0
			for i,v in pairs(store.blocks) do
				if v:GetAttribute("PlacedByUserId") == 0 then
					v.Material = FPSBoost.Enabled and removetextures.Enabled and Enum.Material.SmoothPlastic or (v.Name:find("glass") and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
					originaltextures[v] = originaltextures[v] or v.MaterialVariant
					v.MaterialVariant = FPSBoost.Enabled and removetextures.Enabled and "" or originaltextures[v]
					for i2,v2 in pairs(v:GetChildren()) do
						pcall(function()
							v2.Material = FPSBoost.Enabled and removetextures.Enabled and Enum.Material.SmoothPlastic or (v.Name:find("glass") and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
							originaltextures[v2] = originaltextures[v2] or v2.MaterialVariant
							v2.MaterialVariant = FPSBoost.Enabled and removetextures.Enabled and "" or originaltextures[v2]
						end)
					end
				end
			end
		end)
	end

	FPSBoost = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "FPSBoost",
		Function = function(callback)
			local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
			if callback then
				wasenabled = true
				fpsboosttextures()
				if fpsboostdamageindicator.Enabled then
					damagetab.strokeThickness = 0
					damagetab.textSize = 0
					damagetab.blowUpDuration = 0
					damagetab.blowUpSize = 0
				end
				if fpsboostkilleffect.Enabled then
					for i,v in pairs(bedwars.KillEffectController.killEffects) do
						originaleffects[i] = v
						bedwars.KillEffectController.killEffects[i] = {new = function(char) return {onKill = function() end, isPlayDefaultKillEffect = function() return char == lplr.Character end} end}
					end
				end
				if fpsboostdamageeffect.Enabled then
					oldhitpart = bedwars.DamageIndicatorController.hitEffectPart
					bedwars.DamageIndicatorController.hitEffectPart = nil
				end
				old = bedwars.EntityHighlightController.highlight
				old2 = getmetatable(bedwars.StopwatchController).tweenOutGhost
				local highlighttable = {}
				getmetatable(bedwars.StopwatchController).tweenOutGhost = function(p17, p18)
					p18:Destroy()
				end
				bedwars.EntityHighlightController.highlight = function() end
			else
				for i,v in pairs(originaleffects) do
					bedwars.KillEffectController.killEffects[i] = v
				end
				fpsboosttextures()
				if oldhitpart then
					bedwars.DamageIndicatorController.hitEffectPart = oldhitpart
				end
				debug.setupvalue(bedwars.KillEffectController.KnitStart, 2, require(lplr.PlayerScripts.TS["client-sync-events"]).ClientSyncEvents)
				damagetab.strokeThickness = 1.5
				damagetab.textSize = 28
				damagetab.blowUpDuration = 0.125
				damagetab.blowUpSize = 76
				debug.setupvalue(bedwars.DamageIndicator, 10, tweenService)
				if bedwars.DamageIndicatorController.hitEffectPart then
					bedwars.DamageIndicatorController.hitEffectPart.Attachment.Cubes.Enabled = true
					bedwars.DamageIndicatorController.hitEffectPart.Attachment.Shards.Enabled = true
				end
				bedwars.EntityHighlightController.highlight = old
				getmetatable(bedwars.StopwatchController).tweenOutGhost = old2
				old = nil
				old2 = nil
			end
		end
	})
	removetextures = FPSBoost.CreateToggle({
		Name = "Remove Textures",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostdamageindicator = FPSBoost.CreateToggle({
		Name = "Remove Damage Indicator",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostdamageeffect = FPSBoost.CreateToggle({
		Name = "Remove Damage Effect",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostkilleffect = FPSBoost.CreateToggle({
		Name = "Remove Kill Effect",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
end)

run(function()
	local GameFixer = {Enabled = false}
	local GameFixerHit = {Enabled = false}
	GameFixer = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "GameFixer",
		Function = function(callback)
			debug.setconstant(bedwars.SwordController.swingSwordAtMouse, 23, callback and 'raycast' or 'Raycast')
			debug.setupvalue(bedwars.SwordController.swingSwordAtMouse, 4, callback and bedwars.QueryUtil or workspace)
		end,
		HoverText = "Fixes game bugs"
	})
end)

run(function()
	local transformed = false
	local GameTheme = {Enabled = false}
	local GameThemeMode = {Value = "GameTheme"}

	local themefunctions = {
		Old = function()
			task.spawn(function()
				local oldbedwarstabofimages = '{"clay_orange":"rbxassetid://7017703219","iron":"rbxassetid://6850537969","glass":"rbxassetid://6909521321","log_spruce":"rbxassetid://6874161124","ice":"rbxassetid://6874651262","marble":"rbxassetid://6594536339","zipline_base":"rbxassetid://7051148904","iron_helmet":"rbxassetid://6874272559","marble_pillar":"rbxassetid://6909323822","clay_dark_green":"rbxassetid://6763635916","wood_plank_birch":"rbxassetid://6768647328","watering_can":"rbxassetid://6915423754","emerald_helmet":"rbxassetid://6931675766","pie":"rbxassetid://6985761399","wood_plank_spruce":"rbxassetid://6768615964","diamond_chestplate":"rbxassetid://6874272898","wool_pink":"rbxassetid://6910479863","wool_blue":"rbxassetid://6910480234","wood_plank_oak":"rbxassetid://6910418127","diamond_boots":"rbxassetid://6874272964","clay_yellow":"rbxassetid://4991097283","tnt":"rbxassetid://6856168996","lasso":"rbxassetid://7192710930","clay_purple":"rbxassetid://6856099740","melon_seeds":"rbxassetid://6956387796","apple":"rbxassetid://6985765179","carrot_seeds":"rbxassetid://6956387835","log_oak":"rbxassetid://6763678414","emerald_chestplate":"rbxassetid://6931675868","wool_yellow":"rbxassetid://6910479606","emerald_boots":"rbxassetid://6931675942","clay_light_brown":"rbxassetid://6874651634","balloon":"rbxassetid://7122143895","cannon":"rbxassetid://7121221753","leather_boots":"rbxassetid://6855466456","melon":"rbxassetid://6915428682","wool_white":"rbxassetid://6910387332","log_birch":"rbxassetid://6763678414","clay_pink":"rbxassetid://6856283410","grass":"rbxassetid://6773447725","obsidian":"rbxassetid://6910443317","shield":"rbxassetid://7051149149","red_sandstone":"rbxassetid://6708703895","diamond_helmet":"rbxassetid://6874272793","wool_orange":"rbxassetid://6910479956","log_hickory":"rbxassetid://7017706899","guitar":"rbxassetid://7085044606","wool_purple":"rbxassetid://6910479777","diamond":"rbxassetid://6850538161","iron_chestplate":"rbxassetid://6874272631","slime_block":"rbxassetid://6869284566","stone_brick":"rbxassetid://6910394475","hammer":"rbxassetid://6955848801","ceramic":"rbxassetid://6910426690","wood_plank_maple":"rbxassetid://6768632085","leather_helmet":"rbxassetid://6855466216","stone":"rbxassetid://6763635916","slate_brick":"rbxassetid://6708836267","sandstone":"rbxassetid://6708657090","snow":"rbxassetid://6874651192","wool_red":"rbxassetid://6910479695","leather_chestplate":"rbxassetid://6876833204","clay_red":"rbxassetid://6856283323","wool_green":"rbxassetid://6910480050","clay_white":"rbxassetid://7017705325","wool_cyan":"rbxassetid://6910480152","clay_black":"rbxassetid://5890435474","sand":"rbxassetid://6187018940","clay_light_green":"rbxassetid://6856099550","clay_dark_brown":"rbxassetid://6874651325","carrot":"rbxassetid://3677675280","clay":"rbxassetid://6856190168","iron_boots":"rbxassetid://6874272718","emerald":"rbxassetid://6850538075","zipline":"rbxassetid://7051148904"}'
				local oldbedwarsicontab = game:GetService("HttpService"):JSONDecode(oldbedwarstabofimages)
				local oldbedwarssoundtable = {
					["QUEUE_JOIN"] = "rbxassetid://6691735519",
					["QUEUE_MATCH_FOUND"] = "rbxassetid://6768247187",
					["UI_CLICK"] = "rbxassetid://6732690176",
					["UI_OPEN"] = "rbxassetid://6732607930",
					["BEDWARS_UPGRADE_SUCCESS"] = "rbxassetid://6760677364",
					["BEDWARS_PURCHASE_ITEM"] = "rbxassetid://6760677364",
					["SWORD_SWING_1"] = "rbxassetid://6760544639",
					["SWORD_SWING_2"] = "rbxassetid://6760544595",
					["DAMAGE_1"] = "rbxassetid://6765457325",
					["DAMAGE_2"] = "rbxassetid://6765470975",
					["DAMAGE_3"] = "rbxassetid://6765470941",
					["CROP_HARVEST"] = "rbxassetid://4864122196",
					["CROP_PLANT_1"] = "rbxassetid://5483943277",
					["CROP_PLANT_2"] = "rbxassetid://5483943479",
					["CROP_PLANT_3"] = "rbxassetid://5483943723",
					["ARMOR_EQUIP"] = "rbxassetid://6760627839",
					["ARMOR_UNEQUIP"] = "rbxassetid://6760625788",
					["PICKUP_ITEM_DROP"] = "rbxassetid://6768578304",
					["PARTY_INCOMING_INVITE"] = "rbxassetid://6732495464",
					["ERROR_NOTIFICATION"] = "rbxassetid://6732495464",
					["INFO_NOTIFICATION"] = "rbxassetid://6732495464",
					["END_GAME"] = "rbxassetid://6246476959",
					["GENERIC_BLOCK_PLACE"] = "rbxassetid://4842910664",
					["GENERIC_BLOCK_BREAK"] = "rbxassetid://4819966893",
					["GRASS_BREAK"] = "rbxassetid://5282847153",
					["WOOD_BREAK"] = "rbxassetid://4819966893",
					["STONE_BREAK"] = "rbxassetid://6328287211",
					["WOOL_BREAK"] = "rbxassetid://4842910664",
					["TNT_EXPLODE_1"] = "rbxassetid://7192313632",
					["TNT_HISS_1"] = "rbxassetid://7192313423",
					["FIREBALL_EXPLODE"] = "rbxassetid://6855723746",
					["SLIME_BLOCK_BOUNCE"] = "rbxassetid://6857999096",
					["SLIME_BLOCK_BREAK"] = "rbxassetid://6857999170",
					["SLIME_BLOCK_HIT"] = "rbxassetid://6857999148",
					["SLIME_BLOCK_PLACE"] = "rbxassetid://6857999119",
					["BOW_DRAW"] = "rbxassetid://6866062236",
					["BOW_FIRE"] = "rbxassetid://6866062104",
					["ARROW_HIT"] = "rbxassetid://6866062188",
					["ARROW_IMPACT"] = "rbxassetid://6866062148",
					["TELEPEARL_THROW"] = "rbxassetid://6866223756",
					["TELEPEARL_LAND"] = "rbxassetid://6866223798",
					["CROSSBOW_RELOAD"] = "rbxassetid://6869254094",
					["VOICE_1"] = "rbxassetid://5283866929",
					["VOICE_2"] = "rbxassetid://5283867710",
					["VOICE_HONK"] = "rbxassetid://5283872555",
					["FORTIFY_BLOCK"] = "rbxassetid://6955762535",
					["EAT_FOOD_1"] = "rbxassetid://4968170636",
					["KILL"] = "rbxassetid://7013482008",
					["ZIPLINE_TRAVEL"] = "rbxassetid://7047882304",
					["ZIPLINE_LATCH"] = "rbxassetid://7047882233",
					["ZIPLINE_UNLATCH"] = "rbxassetid://7047882265",
					["SHIELD_BLOCKED"] = "rbxassetid://6955762535",
					["GUITAR_LOOP"] = "rbxassetid://7084168540",
					["GUITAR_HEAL_1"] = "rbxassetid://7084168458",
					["CANNON_MOVE"] = "rbxassetid://7118668472",
					["CANNON_FIRE"] = "rbxassetid://7121064180",
					["BALLOON_INFLATE"] = "rbxassetid://7118657911",
					["BALLOON_POP"] = "rbxassetid://7118657873",
					["FIREBALL_THROW"] = "rbxassetid://7192289445",
					["LASSO_HIT"] = "rbxassetid://7192289603",
					["LASSO_SWING"] = "rbxassetid://7192289504",
					["LASSO_THROW"] = "rbxassetid://7192289548",
					["GRIM_REAPER_CONSUME"] = "rbxassetid://7225389554",
					["GRIM_REAPER_CHANNEL"] = "rbxassetid://7225389512",
					["TV_STATIC"] = "rbxassetid://7256209920",
					["TURRET_ON"] = "rbxassetid://7290176291",
					["TURRET_OFF"] = "rbxassetid://7290176380",
					["TURRET_ROTATE"] = "rbxassetid://7290176421",
					["TURRET_SHOOT"] = "rbxassetid://7290187805",
					["WIZARD_LIGHTNING_CAST"] = "rbxassetid://7262989886",
					["WIZARD_LIGHTNING_LAND"] = "rbxassetid://7263165647",
					["WIZARD_LIGHTNING_STRIKE"] = "rbxassetid://7263165347",
					["WIZARD_ORB_CAST"] = "rbxassetid://7263165448",
					["WIZARD_ORB_TRAVEL_LOOP"] = "rbxassetid://7263165579",
					["WIZARD_ORB_CONTACT_LOOP"] = "rbxassetid://7263165647",
					["BATTLE_PASS_PROGRESS_LEVEL_UP"] = "rbxassetid://7331597283",
					["BATTLE_PASS_PROGRESS_EXP_GAIN"] = "rbxassetid://7331597220",
					["FLAMETHROWER_UPGRADE"] = "rbxassetid://7310273053",
					["FLAMETHROWER_USE"] = "rbxassetid://7310273125",
					["BRITTLE_HIT"] = "rbxassetid://7310273179",
					["EXTINGUISH"] = "rbxassetid://7310273015",
					["RAVEN_SPACE_AMBIENT"] = "rbxassetid://7341443286",
					["RAVEN_WING_FLAP"] = "rbxassetid://7341443378",
					["RAVEN_CAW"] = "rbxassetid://7341443447",
					["JADE_HAMMER_THUD"] = "rbxassetid://7342299402",
					["STATUE"] = "rbxassetid://7344166851",
					["CONFETTI"] = "rbxassetid://7344278405",
					["HEART"] = "rbxassetid://7345120916",
					["SPRAY"] = "rbxassetid://7361499529",
					["BEEHIVE_PRODUCE"] = "rbxassetid://7378100183",
					["DEPOSIT_BEE"] = "rbxassetid://7378100250",
					["CATCH_BEE"] = "rbxassetid://7378100305",
					["BEE_NET_SWING"] = "rbxassetid://7378100350",
					["ASCEND"] = "rbxassetid://7378387334",
					["BED_ALARM"] = "rbxassetid://7396762708",
					["BOUNTY_CLAIMED"] = "rbxassetid://7396751941",
					["BOUNTY_ASSIGNED"] = "rbxassetid://7396752155",
					["BAGUETTE_HIT"] = "rbxassetid://7396760547",
					["BAGUETTE_SWING"] = "rbxassetid://7396760496",
					["TESLA_ZAP"] = "rbxassetid://7497477336",
					["SPIRIT_TRIGGERED"] = "rbxassetid://7498107251",
					["SPIRIT_EXPLODE"] = "rbxassetid://7498107327",
					["ANGEL_LIGHT_ORB_CREATE"] = "rbxassetid://7552134231",
					["ANGEL_LIGHT_ORB_HEAL"] = "rbxassetid://7552134868",
					["ANGEL_VOID_ORB_CREATE"] = "rbxassetid://7552135942",
					["ANGEL_VOID_ORB_HEAL"] = "rbxassetid://7552136927",
					["DODO_BIRD_JUMP"] = "rbxassetid://7618085391",
					["DODO_BIRD_DOUBLE_JUMP"] = "rbxassetid://7618085771",
					["DODO_BIRD_MOUNT"] = "rbxassetid://7618085486",
					["DODO_BIRD_DISMOUNT"] = "rbxassetid://7618085571",
					["DODO_BIRD_SQUAWK_1"] = "rbxassetid://7618085870",
					["DODO_BIRD_SQUAWK_2"] = "rbxassetid://7618085657",
					["SHIELD_CHARGE_START"] = "rbxassetid://7730842884",
					["SHIELD_CHARGE_LOOP"] = "rbxassetid://7730843006",
					["SHIELD_CHARGE_BASH"] = "rbxassetid://7730843142",
					["ROCKET_LAUNCHER_FIRE"] = "rbxassetid://7681584765",
					["ROCKET_LAUNCHER_FLYING_LOOP"] = "rbxassetid://7681584906",
					["SMOKE_GRENADE_POP"] = "rbxassetid://7681276062",
					["SMOKE_GRENADE_EMIT_LOOP"] = "rbxassetid://7681276135",
					["GOO_SPIT"] = "rbxassetid://7807271610",
					["GOO_SPLAT"] = "rbxassetid://7807272724",
					["GOO_EAT"] = "rbxassetid://7813484049",
					["LUCKY_BLOCK_BREAK"] = "rbxassetid://7682005357",
					["AXOLOTL_SWITCH_TARGETS"] = "rbxassetid://7344278405",
					["HALLOWEEN_MUSIC"] = "rbxassetid://7775602786",
					["SNAP_TRAP_SETUP"] = "rbxassetid://7796078515",
					["SNAP_TRAP_CLOSE"] = "rbxassetid://7796078695",
					["SNAP_TRAP_CONSUME_MARK"] = "rbxassetid://7796078825",
					["GHOST_VACUUM_SUCKING_LOOP"] = "rbxassetid://7814995865",
					["GHOST_VACUUM_SHOOT"] = "rbxassetid://7806060367",
					["GHOST_VACUUM_CATCH"] = "rbxassetid://7815151688",
					["FISHERMAN_GAME_START"] = "rbxassetid://7806060544",
					["FISHERMAN_GAME_PULLING_LOOP"] = "rbxassetid://7806060638",
					["FISHERMAN_GAME_PROGRESS_INCREASE"] = "rbxassetid://7806060745",
					["FISHERMAN_GAME_FISH_MOVE"] = "rbxassetid://7806060863",
					["FISHERMAN_GAME_LOOP"] = "rbxassetid://7806061057",
					["FISHING_ROD_CAST"] = "rbxassetid://7806060976",
					["FISHING_ROD_SPLASH"] = "rbxassetid://7806061193",
					["SPEAR_HIT"] = "rbxassetid://7807270398",
					["SPEAR_THROW"] = "rbxassetid://7813485044",
				}
				for i,v in pairs(bedwars.CombatController.killSounds) do
					bedwars.CombatController.killSounds[i] = oldbedwarssoundtable.KILL
				end
				for i,v in pairs(bedwars.CombatController.multiKillLoops) do
					bedwars.CombatController.multiKillLoops[i] = ""
				end
				for i,v in pairs(bedwars.ItemTable) do
					if oldbedwarsicontab[i] then
						v.image = oldbedwarsicontab[i]
					end
				end
				for i,v in pairs(oldbedwarssoundtable) do
					local item = bedwars.SoundList[i]
					if item then
						bedwars.SoundList[i] = v
					end
				end
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(214, 0, 0)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.ViewmodelController.show, 37, "")
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				sethiddenproperty(lightingService, "Technology", "ShadowMap")
				lightingService.Ambient = Color3.fromRGB(69, 69, 69)
				lightingService.Brightness = 3
				lightingService.EnvironmentDiffuseScale = 1
				lightingService.EnvironmentSpecularScale = 1
				lightingService.OutdoorAmbient = Color3.fromRGB(69, 69, 69)
				lightingService.Atmosphere.Density = 0.1
				lightingService.Atmosphere.Offset = 0.25
				lightingService.Atmosphere.Color = Color3.fromRGB(198, 198, 198)
				lightingService.Atmosphere.Decay = Color3.fromRGB(104, 112, 124)
				lightingService.Atmosphere.Glare = 0
				lightingService.Atmosphere.Haze = 0
				lightingService.ClockTime = 13
				lightingService.GeographicLatitude = 0
				lightingService.GlobalShadows = false
				lightingService.TimeOfDay = "13:00:00"
				lightingService.Sky.SkyboxBk = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxDn = "rbxassetid://6334928194"
				lightingService.Sky.SkyboxFt = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxLf = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxRt = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxUp = "rbxassetid://7018689553"
			end)
		end,
		Winter = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				local sky = Instance.new("Sky")
				sky.StarCount = 5000
				sky.SkyboxUp = "rbxassetid://8139676647"
				sky.SkyboxLf = "rbxassetid://8139676988"
				sky.SkyboxFt = "rbxassetid://8139677111"
				sky.SkyboxBk = "rbxassetid://8139677359"
				sky.SkyboxDn = "rbxassetid://8139677253"
				sky.SkyboxRt = "rbxassetid://8139676842"
				sky.SunTextureId = "rbxassetid://6196665106"
				sky.SunAngularSize = 11
				sky.MoonTextureId = "rbxassetid://8139665943"
				sky.MoonAngularSize = 30
				sky.Parent = lightingService
				local sunray = Instance.new("SunRaysEffect")
				sunray.Intensity = 0.03
				sunray.Parent = lightingService
				local bloom = Instance.new("BloomEffect")
				bloom.Threshold = 2
				bloom.Intensity = 1
				bloom.Size = 2
				bloom.Parent = lightingService
				local atmosphere = Instance.new("Atmosphere")
				atmosphere.Density = 0.3
				atmosphere.Offset = 0.25
				atmosphere.Color = Color3.fromRGB(198, 198, 198)
				atmosphere.Decay = Color3.fromRGB(104, 112, 124)
				atmosphere.Glare = 0
				atmosphere.Haze = 0
				atmosphere.Parent = lightingService
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(70, 255, 255)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 4653055)
			end)
			task.spawn(function()
				local snowpart = Instance.new("Part")
				snowpart.Size = Vector3.new(240, 0.5, 240)
				snowpart.Name = "SnowParticle"
				snowpart.Transparency = 1
				snowpart.CanCollide = false
				snowpart.Position = Vector3.new(0, 120, 286)
				snowpart.Anchored = true
				snowpart.Parent = workspace
				local snow = Instance.new("ParticleEmitter")
				snow.RotSpeed = NumberRange.new(300)
				snow.VelocitySpread = 35
				snow.Rate = 28
				snow.Texture = "rbxassetid://8158344433"
				snow.Rotation = NumberRange.new(110)
				snow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.16939899325371,0),NumberSequenceKeypoint.new(0.23365999758244,0.62841498851776,0.37158501148224),NumberSequenceKeypoint.new(0.56209099292755,0.38797798752785,0.2771390080452),NumberSequenceKeypoint.new(0.90577298402786,0.51912599802017,0),NumberSequenceKeypoint.new(1,1,0)})
				snow.Lifetime = NumberRange.new(8,14)
				snow.Speed = NumberRange.new(8,18)
				snow.EmissionDirection = Enum.NormalId.Bottom
				snow.SpreadAngle = Vector2.new(35,35)
				snow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.039760299026966,1.3114800453186,0.32786899805069),NumberSequenceKeypoint.new(0.7554469704628,0.98360699415207,0.44038599729538),NumberSequenceKeypoint.new(1,0,0)})
				snow.Parent = snowpart
				local windsnow = Instance.new("ParticleEmitter")
				windsnow.Acceleration = Vector3.new(0,0,1)
				windsnow.RotSpeed = NumberRange.new(100)
				windsnow.VelocitySpread = 35
				windsnow.Rate = 28
				windsnow.Texture = "rbxassetid://8158344433"
				windsnow.EmissionDirection = Enum.NormalId.Bottom
				windsnow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.16939899325371,0),NumberSequenceKeypoint.new(0.23365999758244,0.62841498851776,0.37158501148224),NumberSequenceKeypoint.new(0.56209099292755,0.38797798752785,0.2771390080452),NumberSequenceKeypoint.new(0.90577298402786,0.51912599802017,0),NumberSequenceKeypoint.new(1,1,0)})
				windsnow.Lifetime = NumberRange.new(8,14)
				windsnow.Speed = NumberRange.new(8,18)
				windsnow.Rotation = NumberRange.new(110)
				windsnow.SpreadAngle = Vector2.new(35,35)
				windsnow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.039760299026966,1.3114800453186,0.32786899805069),NumberSequenceKeypoint.new(0.7554469704628,0.98360699415207,0.44038599729538),NumberSequenceKeypoint.new(1,0,0)})
				windsnow.Parent = snowpart
				repeat
					task.wait()
					if entityLibrary.isAlive then
						snowpart.Position = entityLibrary.character.HumanoidRootPart.Position + Vector3.new(0, 100, 0)
					end
				until not vapeInjected
			end)
		end,
		Halloween = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				lightingService.TimeOfDay = "00:00:00"
				pcall(function() workspace.Clouds:Destroy() end)
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(255, 100, 0)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				local colorcorrection = Instance.new("ColorCorrectionEffect")
				colorcorrection.TintColor = Color3.fromRGB(255, 185, 81)
				colorcorrection.Brightness = 0.05
				colorcorrection.Parent = lightingService
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 16737280)
			end)
		end,
		Valentines = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				local sky = Instance.new("Sky")
				sky.SkyboxBk = "rbxassetid://1546230803"
				sky.SkyboxDn = "rbxassetid://1546231143"
				sky.SkyboxFt = "rbxassetid://1546230803"
				sky.SkyboxLf = "rbxassetid://1546230803"
				sky.SkyboxRt = "rbxassetid://1546230803"
				sky.SkyboxUp = "rbxassetid://1546230451"
				sky.Parent = lightingService
				pcall(function() workspace.Clouds:Destroy() end)
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(255, 132, 178)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				local colorcorrection = Instance.new("ColorCorrectionEffect")
				colorcorrection.TintColor = Color3.fromRGB(255, 199, 220)
				colorcorrection.Brightness = 0.05
				colorcorrection.Parent = lightingService
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 16745650)
			end)
		end
	}

	GameTheme = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "GameTheme",
		Function = function(callback)
			if callback then
				if not transformed then
					transformed = true
					themefunctions[GameThemeMode.Value]()
				else
					GameTheme.ToggleButton(false)
				end
			else
				warningNotification("GameTheme", "Disabled Next Game", 10)
			end
		end,
		ExtraText = function()
			return GameThemeMode.Value
		end
	})
	GameThemeMode = GameTheme.CreateDropdown({
		Name = "Theme",
		Function = function() end,
		List = {"Old", "Winter", "Halloween", "Valentines"}
	})
end)

run(function()
	local oldkilleffect
	local KillEffectMode = {Value = "Gravity"}
	local KillEffectList = {Value = "None"}
	local KillEffectName2 = {}
	local killeffects = {
		Gravity = function(p3, p4, p5, p6)
			p5:BreakJoints()
			task.spawn(function()
				local partvelo = {}
				for i,v in pairs(p5:GetDescendants()) do
					if v:IsA("BasePart") then
						partvelo[v.Name] = v.Velocity * 3
					end
				end
				p5.Archivable = true
				local clone = p5:Clone()
				clone.Humanoid.Health = 100
				clone.Parent = workspace
				local nametag = clone:FindFirstChild("Nametag", true)
				if nametag then nametag:Destroy() end
				game:GetService("Debris"):AddItem(clone, 30)
				p5:Destroy()
				task.wait(0.01)
				clone.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				clone:BreakJoints()
				task.wait(0.01)
				for i,v in pairs(clone:GetDescendants()) do
					if v:IsA("BasePart") then
						local bodyforce = Instance.new("BodyForce")
						bodyforce.Force = Vector3.new(0, (workspace.Gravity - 10) * v:GetMass(), 0)
						bodyforce.Parent = v
						v.CanCollide = true
						v.Velocity = partvelo[v.Name] or Vector3.zero
					end
				end
			end)
		end,
		Lightning = function(p3, p4, p5, p6)
			p5:BreakJoints()
			local startpos = 1125
			local startcf = p5.PrimaryPart.CFrame.p - Vector3.new(0, 8, 0)
			local newpos = Vector3.new((math.random(1, 10) - 5) * 2, startpos, (math.random(1, 10) - 5) * 2)
			for i = startpos - 75, 0, -75 do
				local newpos2 = Vector3.new((math.random(1, 10) - 5) * 2, i, (math.random(1, 10) - 5) * 2)
				if i == 0 then
					newpos2 = Vector3.zero
				end
				local part = Instance.new("Part")
				part.Size = Vector3.new(1.5, 1.5, 77)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.Material = Enum.Material.Neon
				part.CanCollide = false
				part.CFrame = CFrame.new(startcf + newpos + ((newpos2 - newpos) * 0.5), startcf + newpos2)
				part.Parent = workspace
				local part2 = part:Clone()
				part2.Size = Vector3.new(3, 3, 78)
				part2.Color = Color3.new(0.7, 0.7, 0.7)
				part2.Transparency = 0.7
				part2.Material = Enum.Material.SmoothPlastic
				part2.Parent = workspace
				game:GetService("Debris"):AddItem(part, 0.5)
				game:GetService("Debris"):AddItem(part2, 0.5)
				bedwars.QueryUtil:setQueryIgnored(part, true)
				bedwars.QueryUtil:setQueryIgnored(part2, true)
				if i == 0 then
					local soundpart = Instance.new("Part")
					soundpart.Transparency = 1
					soundpart.Anchored = true
					soundpart.Size = Vector3.zero
					soundpart.Position = startcf
					soundpart.Parent = workspace
					bedwars.QueryUtil:setQueryIgnored(soundpart, true)
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://6993372814"
					sound.Volume = 2
					sound.Pitch = 0.5 + (math.random(1, 3) / 10)
					sound.Parent = soundpart
					sound:Play()
					sound.Ended:Connect(function()
						soundpart:Destroy()
					end)
				end
				newpos = newpos2
			end
		end
	}
	local KillEffectName = {}
	for i,v in pairs(bedwars.KillEffectMeta) do
		table.insert(KillEffectName, v.name)
		KillEffectName[v.name] = i
	end
	table.sort(KillEffectName, function(a, b) return a:lower() < b:lower() end)
	local KillEffect = {Enabled = false}
	KillEffect = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "KillEffect",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or not KillEffect.Enabled
					if KillEffect.Enabled then
						lplr:SetAttribute("KillEffectType", "none")
						if KillEffectMode.Value == "Bedwars" then
							lplr:SetAttribute("KillEffectType", KillEffectName[KillEffectList.Value])
						end
					end
				end)
				oldkilleffect = bedwars.DefaultKillEffect.onKill
				bedwars.DefaultKillEffect.onKill = function(p3, p4, p5, p6)
					killeffects[KillEffectMode.Value](p3, p4, p5, p6)
				end
			else
				bedwars.DefaultKillEffect.onKill = oldkilleffect
			end
		end
	})
	local modes = {"Bedwars"}
	for i,v in pairs(killeffects) do
		table.insert(modes, i)
	end
	KillEffectMode = KillEffect.CreateDropdown({
		Name = "Mode",
		Function = function()
			if KillEffect.Enabled then
				KillEffect.ToggleButton(false)
				KillEffect.ToggleButton(false)
			end
		end,
		List = modes
	})
	KillEffectList = KillEffect.CreateDropdown({
		Name = "Bedwars",
		Function = function()
			if KillEffect.Enabled then
				KillEffect.ToggleButton(false)
				KillEffect.ToggleButton(false)
			end
		end,
		List = KillEffectName
	})
end)

run(function()
	local KitESP = {Enabled = false}
	local espobjs = {}
	local espfold = Instance.new("Folder")
	espfold.Parent = GuiLibrary.MainGui

	local function espadd(v, icon)
		local billboard = Instance.new("BillboardGui")
		billboard.Parent = espfold
		billboard.Name = "iron"
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
		billboard.Size = UDim2.new(0, 32, 0, 32)
		billboard.AlwaysOnTop = true
		billboard.Adornee = v
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 0.5
		image.BorderSizePixel = 0
		image.Image = bedwars.getIcon({itemType = icon}, true)
		image.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		image.Size = UDim2.new(0, 32, 0, 32)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Parent = billboard
		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = image
		espobjs[v] = billboard
	end

	local function addKit(tag, icon)
		table.insert(KitESP.Connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			espadd(v.PrimaryPart, icon)
		end))
		table.insert(KitESP.Connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if espobjs[v.PrimaryPart] then
				espobjs[v.PrimaryPart]:Destroy()
				espobjs[v.PrimaryPart] = nil
			end
		end))
		for i,v in pairs(collectionService:GetTagged(tag)) do
			espadd(v.PrimaryPart, icon)
		end
	end

	KitESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "KitESP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.equippedKit ~= ""
					if KitESP.Enabled then
						if store.equippedKit == "metal_detector" then
							addKit("hidden-metal", "iron")
						elseif store.equippedKit == "beekeeper" then
							addKit("bee", "bee")
						elseif store.equippedKit == "bigman" then
							addKit("treeOrb", "natures_essence_1")
						end
					end
				end)
			else
				espfold:ClearAllChildren()
				table.clear(espobjs)
			end
		end
	})
end)

run(function()
	local function floorNameTagPosition(pos)
		return Vector2.new(math.floor(pos.X), math.floor(pos.Y))
	end

	local function removeTags(str)
		str = str:gsub("<br%s*/>", "\n")
		return (str:gsub("<[^<>]->", ""))
	end

	local NameTagsFolder = Instance.new("Folder")
	NameTagsFolder.Name = "NameTagsFolder"
	NameTagsFolder.Parent = GuiLibrary.MainGui
	local nametagsfolderdrawing = {}
	local NameTagsColor = {Value = 0.44}
	local NameTagsDisplayName = {Enabled = false}
	local NameTagsHealth = {Enabled = false}
	local NameTagsDistance = {Enabled = false}
	local NameTagsBackground = {Enabled = true}
	local NameTagsScale = {Value = 10}
	local NameTagsFont = {Value = "SourceSans"}
	local NameTagsTeammates = {Enabled = true}
	local NameTagsShowInventory = {Enabled = false}
	local NameTagsRangeLimit = {Value = 0}
	local fontitems = {"SourceSans"}
	local nametagstrs = {}
	local nametagsizes = {}
	local kititems = {
		jade = "jade_hammer",
		archer = "tactical_crossbow",
		angel = "",
		cowgirl = "lasso",
		dasher = "wood_dao",
		axolotl = "axolotl",
		yeti = "snowball",
		smoke = "smoke_block",
		trapper = "snap_trap",
		pyro = "flamethrower",
		davey = "cannon",
		regent = "void_axe",
		baker = "apple",
		builder = "builder_hammer",
		farmer_cletus = "carrot_seeds",
		melody = "guitar",
		barbarian = "rageblade",
		gingerbread_man = "gumdrop_bounce_pad",
		spirit_catcher = "spirit",
		fisherman = "fishing_rod",
		oil_man = "oil_consumable",
		santa = "tnt",
		miner = "miner_pickaxe",
		sheep_herder = "crook",
		beast = "speed_potion",
		metal_detector = "metal_detector",
		cyber = "drone",
		vesta = "damage_banner",
		lumen = "light_sword",
		ember = "infernal_saber",
		queen_bee = "bee"
	}

	local nametagfuncs1 = {
		Normal = function(plr)
			if NameTagsTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
			local thing = Instance.new("TextLabel")
			thing.BackgroundColor3 = Color3.new()
			thing.BorderSizePixel = 0
			thing.Visible = false
			thing.RichText = true
			thing.AnchorPoint = Vector2.new(0.5, 1)
			thing.Name = plr.Player.Name
			thing.Font = Enum.Font[NameTagsFont.Value]
			thing.TextSize = 14 * (NameTagsScale.Value / 10)
			thing.BackgroundTransparency = NameTagsBackground.Enabled and 0.5 or 1
			nametagstrs[plr.Player] = whitelist:tag(plr.Player, true)..(NameTagsDisplayName.Enabled and plr.Player.DisplayName or plr.Player.Name)
			if NameTagsHealth.Enabled then
				local color = Color3.fromHSV(math.clamp(plr.Humanoid.Health / plr.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
				nametagstrs[plr.Player] = nametagstrs[plr.Player]..' <font color="rgb('..tostring(math.floor(color.R * 255))..','..tostring(math.floor(color.G * 255))..','..tostring(math.floor(color.B * 255))..')">'..math.round(plr.Humanoid.Health).."</font>"
			end
			if NameTagsDistance.Enabled then
				nametagstrs[plr.Player] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..nametagstrs[plr.Player]
			end
			local nametagSize = textService:GetTextSize(removeTags(nametagstrs[plr.Player]), thing.TextSize, thing.Font, Vector2.new(100000, 100000))
			thing.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
			thing.Text = nametagstrs[plr.Player]
			thing.TextColor3 = getPlayerColor(plr.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			thing.Parent = NameTagsFolder
			local hand = Instance.new("ImageLabel")
			hand.Size = UDim2.new(0, 30, 0, 30)
			hand.Name = "Hand"
			hand.BackgroundTransparency = 1
			hand.Position = UDim2.new(0, -30, 0, -30)
			hand.Image = ""
			hand.Parent = thing
			local helmet = hand:Clone()
			helmet.Name = "Helmet"
			helmet.Position = UDim2.new(0, 5, 0, -30)
			helmet.Parent = thing
			local chest = hand:Clone()
			chest.Name = "Chestplate"
			chest.Position = UDim2.new(0, 35, 0, -30)
			chest.Parent = thing
			local boots = hand:Clone()
			boots.Name = "Boots"
			boots.Position = UDim2.new(0, 65, 0, -30)
			boots.Parent = thing
			local kit = hand:Clone()
			kit.Name = "Kit"
			task.spawn(function()
				repeat task.wait() until plr.Player:GetAttribute("PlayingAsKit") ~= ""
				if kit then
					kit.Image = kititems[plr.Player:GetAttribute("PlayingAsKit")] and bedwars.getIcon({itemType = kititems[plr.Player:GetAttribute("PlayingAsKit")]}, NameTagsShowInventory.Enabled) or ""
				end
			end)
			kit.Position = UDim2.new(0, -30, 0, -65)
			kit.Parent = thing
			nametagsfolderdrawing[plr.Player] = {entity = plr, Main = thing}
		end,
		Drawing = function(plr)
			if NameTagsTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
			local thing = {Main = {}, entity = plr}
			thing.Main.Text = Drawing.new("Text")
			thing.Main.Text.Size = 17 * (NameTagsScale.Value / 10)
			thing.Main.Text.Font = (math.clamp((table.find(fontitems, NameTagsFont.Value) or 1) - 1, 0, 3))
			thing.Main.Text.ZIndex = 2
			thing.Main.BG = Drawing.new("Square")
			thing.Main.BG.Filled = true
			thing.Main.BG.Transparency = 0.5
			thing.Main.BG.Visible = NameTagsBackground.Enabled
			thing.Main.BG.Color = Color3.new()
			thing.Main.BG.ZIndex = 1
			nametagstrs[plr.Player] = whitelist:tag(plr.Player, true)..(NameTagsDisplayName.Enabled and plr.Player.DisplayName or plr.Player.Name)
			if NameTagsHealth.Enabled then
				local color = Color3.fromHSV(math.clamp(plr.Humanoid.Health / plr.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
				nametagstrs[plr.Player] = nametagstrs[plr.Player]..' '..math.round(plr.Humanoid.Health)
			end
			if NameTagsDistance.Enabled then
				nametagstrs[plr.Player] = '[%s] '..nametagstrs[plr.Player]
			end
			thing.Main.Text.Text = nametagstrs[plr.Player]
			thing.Main.BG.Size = Vector2.new(thing.Main.Text.TextBounds.X + 4, thing.Main.Text.TextBounds.Y)
			thing.Main.Text.Color = getPlayerColor(plr.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			nametagsfolderdrawing[plr.Player] = thing
		end
	}

	local nametagfuncs2 = {
		Normal = function(ent)
			local v = nametagsfolderdrawing[ent]
			nametagsfolderdrawing[ent] = nil
			if v then
				v.Main:Destroy()
			end
		end,
		Drawing = function(ent)
			local v = nametagsfolderdrawing[ent]
			nametagsfolderdrawing[ent] = nil
			if v then
				for i2,v2 in pairs(v.Main) do
					pcall(function() v2.Visible = false v2:Remove() end)
				end
			end
		end
	}

	local nametagupdatefuncs = {
		Normal = function(ent)
			local v = nametagsfolderdrawing[ent.Player]
			if v then
				nametagstrs[ent.Player] = whitelist:tag(ent.Player, true)..(NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name)
				if NameTagsHealth.Enabled then
					local color = Color3.fromHSV(math.clamp(ent.Humanoid.Health / ent.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
					nametagstrs[ent.Player] = nametagstrs[ent.Player]..' <font color="rgb('..tostring(math.floor(color.R * 255))..','..tostring(math.floor(color.G * 255))..','..tostring(math.floor(color.B * 255))..')">'..math.round(ent.Humanoid.Health).."</font>"
				end
				if NameTagsDistance.Enabled then
					nametagstrs[ent.Player] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..nametagstrs[ent.Player]
				end
				if NameTagsShowInventory.Enabled then
					local inventory = store.inventories[ent.Player] or {armor = {}}
					if inventory.hand then
						v.Main.Hand.Image = bedwars.getIcon(inventory.hand, NameTagsShowInventory.Enabled)
						if v.Main.Hand.Image:find("rbxasset://") then
							v.Main.Hand.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Hand.Image = ""
					end
					if inventory.armor[4] then
						v.Main.Helmet.Image = bedwars.getIcon(inventory.armor[4], NameTagsShowInventory.Enabled)
						if v.Main.Helmet.Image:find("rbxasset://") then
							v.Main.Helmet.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Helmet.Image = ""
					end
					if inventory.armor[5] then
						v.Main.Chestplate.Image = bedwars.getIcon(inventory.armor[5], NameTagsShowInventory.Enabled)
						if v.Main.Chestplate.Image:find("rbxasset://") then
							v.Main.Chestplate.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Chestplate.Image = ""
					end
					if inventory.armor[6] then
						v.Main.Boots.Image = bedwars.getIcon(inventory.armor[6], NameTagsShowInventory.Enabled)
						if v.Main.Boots.Image:find("rbxasset://") then
							v.Main.Boots.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Boots.Image = ""
					end
				end
				local nametagSize = textService:GetTextSize(removeTags(nametagstrs[ent.Player]), v.Main.TextSize, v.Main.Font, Vector2.new(100000, 100000))
				v.Main.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
				v.Main.Text = nametagstrs[ent.Player]
			end
		end,
		Drawing = function(ent)
			local v = nametagsfolderdrawing[ent.Player]
			if v then
				nametagstrs[ent.Player] = whitelist:tag(ent.Player, true)..(NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name)
				if NameTagsHealth.Enabled then
					nametagstrs[ent.Player] = nametagstrs[ent.Player]..' '..math.round(ent.Humanoid.Health)
				end
				if NameTagsDistance.Enabled then
					nametagstrs[ent.Player] = '[%s] '..nametagstrs[ent.Player]
					v.Main.Text.Text = entityLibrary.isAlive and string.format(nametagstrs[ent.Player], math.floor((entityLibrary.character.HumanoidRootPart.Position - ent.RootPart.Position).Magnitude)) or nametagstrs[ent.Player]
				else
					v.Main.Text.Text = nametagstrs[ent.Player]
				end
				v.Main.BG.Size = Vector2.new(v.Main.Text.TextBounds.X + 4, v.Main.Text.TextBounds.Y)
				v.Main.Text.Color = getPlayerColor(ent.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			end
		end
	}

	local nametagcolorfuncs = {
		Normal = function(hue, sat, value)
			local color = Color3.fromHSV(hue, sat, value)
			for i,v in pairs(nametagsfolderdrawing) do
				v.Main.TextColor3 = getPlayerColor(v.entity.Player) or color
			end
		end,
		Drawing = function(hue, sat, value)
			local color = Color3.fromHSV(hue, sat, value)
			for i,v in pairs(nametagsfolderdrawing) do
				v.Main.Text.Color = getPlayerColor(v.entity.Player) or color
			end
		end
	}

	local nametagloop = {
		Normal = function()
			for i,v in pairs(nametagsfolderdrawing) do
				local headPos, headVis = worldtoscreenpoint((v.entity.RootPart:GetRenderCFrame() * CFrame.new(0, v.entity.Head.Size.Y + v.entity.RootPart.Size.Y, 0)).Position)
				if not headVis then
					v.Main.Visible = false
					continue
				end
				local mag = entityLibrary.isAlive and math.floor((entityLibrary.character.HumanoidRootPart.Position - v.entity.RootPart.Position).Magnitude) or 0
				if NameTagsRangeLimit.Value ~= 0 and mag > NameTagsRangeLimit.Value then
					v.Main.Visible = false
					continue
				end
				if NameTagsDistance.Enabled then
					local stringsize = tostring(mag):len()
					if nametagsizes[v.entity.Player] ~= stringsize then
						local nametagSize = textService:GetTextSize(removeTags(string.format(nametagstrs[v.entity.Player], mag)), v.Main.TextSize, v.Main.Font, Vector2.new(100000, 100000))
						v.Main.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
					end
					nametagsizes[v.entity.Player] = stringsize
					v.Main.Text = string.format(nametagstrs[v.entity.Player], mag)
				end
				v.Main.Position = UDim2.new(0, headPos.X, 0, headPos.Y)
				v.Main.Visible = true
			end
		end,
		Drawing = function()
			for i,v in pairs(nametagsfolderdrawing) do
				local headPos, headVis = worldtoscreenpoint((v.entity.RootPart:GetRenderCFrame() * CFrame.new(0, v.entity.Head.Size.Y + v.entity.RootPart.Size.Y, 0)).Position)
				if not headVis then
					v.Main.Text.Visible = false
					v.Main.BG.Visible = false
					continue
				end
				local mag = entityLibrary.isAlive and math.floor((entityLibrary.character.HumanoidRootPart.Position - v.entity.RootPart.Position).Magnitude) or 0
				if NameTagsRangeLimit.Value ~= 0 and mag > NameTagsRangeLimit.Value then
					v.Main.Text.Visible = false
					v.Main.BG.Visible = false
					continue
				end
				if NameTagsDistance.Enabled then
					local stringsize = tostring(mag):len()
					v.Main.Text.Text = string.format(nametagstrs[v.entity.Player], mag)
					if nametagsizes[v.entity.Player] ~= stringsize then
						v.Main.BG.Size = Vector2.new(v.Main.Text.TextBounds.X + 4, v.Main.Text.TextBounds.Y)
					end
					nametagsizes[v.entity.Player] = stringsize
				end
				v.Main.BG.Position = Vector2.new(headPos.X - (v.Main.BG.Size.X / 2), (headPos.Y + v.Main.BG.Size.Y))
				v.Main.Text.Position = v.Main.BG.Position + Vector2.new(2, 0)
				v.Main.Text.Visible = true
				v.Main.BG.Visible = NameTagsBackground.Enabled
			end
		end
	}

	local methodused

	local NameTags = {Enabled = false}
	NameTags = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "NameTags",
		Function = function(callback)
			if callback then
				methodused = NameTagsDrawing.Enabled and "Drawing" or "Normal"
				if nametagfuncs2[methodused] then
					table.insert(NameTags.Connections, entityLibrary.entityRemovedEvent:Connect(nametagfuncs2[methodused]))
				end
				if nametagfuncs1[methodused] then
					local addfunc = nametagfuncs1[methodused]
					for i,v in pairs(entityLibrary.entityList) do
						if nametagsfolderdrawing[v.Player] then nametagfuncs2[methodused](v.Player) end
						addfunc(v)
					end
					table.insert(NameTags.Connections, entityLibrary.entityAddedEvent:Connect(function(ent)
						if nametagsfolderdrawing[ent.Player] then nametagfuncs2[methodused](ent.Player) end
						addfunc(ent)
					end))
				end
				if nametagupdatefuncs[methodused] then
					table.insert(NameTags.Connections, entityLibrary.entityUpdatedEvent:Connect(nametagupdatefuncs[methodused]))
					for i,v in pairs(entityLibrary.entityList) do
						nametagupdatefuncs[methodused](v)
					end
				end
				if nametagcolorfuncs[methodused] then
					table.insert(NameTags.Connections, GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.FriendColorRefresh.Event:Connect(function()
						nametagcolorfuncs[methodused](NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
					end))
				end
				if nametagloop[methodused] then
					RunLoops:BindToRenderStep("NameTags", nametagloop[methodused])
				end
			else
				RunLoops:UnbindFromRenderStep("NameTags")
				if nametagfuncs2[methodused] then
					for i,v in pairs(nametagsfolderdrawing) do
						nametagfuncs2[methodused](i)
					end
				end
			end
		end,
		HoverText = "Renders nametags on entities through walls."
	})
	for i,v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name ~= "SourceSans" then
			table.insert(fontitems, v.Name)
		end
	end
	NameTagsFont = NameTags.CreateDropdown({
		Name = "Font",
		List = fontitems,
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
	})
	NameTagsColor = NameTags.CreateColorSlider({
		Name = "Player Color",
		Function = function(hue, sat, val)
			if NameTags.Enabled and nametagcolorfuncs[methodused] then
				nametagcolorfuncs[methodused](hue, sat, val)
			end
		end
	})
	NameTagsScale = NameTags.CreateSlider({
		Name = "Scale",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = 10,
		Min = 1,
		Max = 50
	})
	NameTagsRangeLimit = NameTags.CreateSlider({
		Name = "Range",
		Function = function() end,
		Min = 0,
		Max = 1000,
		Default = 0
	})
	NameTagsBackground = NameTags.CreateToggle({
		Name = "Background",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsDisplayName = NameTags.CreateToggle({
		Name = "Use Display Name",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsHealth = NameTags.CreateToggle({
		Name = "Health",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end
	})
	NameTagsDistance = NameTags.CreateToggle({
		Name = "Distance",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end
	})
	NameTagsShowInventory = NameTags.CreateToggle({
		Name = "Equipment",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsTeammates = NameTags.CreateToggle({
		Name = "Teammates",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsDrawing = NameTags.CreateToggle({
		Name = "Drawing",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
	})
end)

run(function()
	local nobobdepth = {Value = 8}
	local nobobhorizontal = {Value = 8}
	local nobobvertical = {Value = -2}
	local rotationx = {Value = 0}
	local rotationy = {Value = 0}
	local rotationz = {Value = 0}
	local oldc1
	local oldfunc
	local nobob = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "NoBob",
		Function = function(callback)
			local viewmodel = gameCamera:FindFirstChild("Viewmodel")
			if viewmodel then
				if callback then
					oldfunc = bedwars.ViewmodelController.playAnimation
					bedwars.ViewmodelController.playAnimation = function(self, animid, details)
						if animid == bedwars.AnimationType.FP_WALK then
							return
						end
						return oldfunc(self, animid, details)
					end
					bedwars.ViewmodelController:setHeldItem(lplr.Character and lplr.Character:FindFirstChild("HandInvItem") and lplr.Character.HandInvItem.Value and lplr.Character.HandInvItem.Value:Clone())
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(nobobdepth.Value / 10))
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (nobobhorizontal.Value / 10))
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (nobobvertical.Value / 10))
					oldc1 = viewmodel.RightHand.RightWrist.C1
					viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
				else
					bedwars.ViewmodelController.playAnimation = oldfunc
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", 0)
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", 0)
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", 0)
					viewmodel.RightHand.RightWrist.C1 = oldc1
				end
			end
		end,
		HoverText = "Removes the ugly bobbing when you move and makes sword farther"
	})
	nobobdepth = nobob.CreateSlider({
		Name = "Depth",
		Min = 0,
		Max = 24,
		Default = 8,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(val / 10))
			end
		end
	})
	nobobhorizontal = nobob.CreateSlider({
		Name = "Horizontal",
		Min = 0,
		Max = 24,
		Default = 8,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (val / 10))
			end
		end
	})
	nobobvertical= nobob.CreateSlider({
		Name = "Vertical",
		Min = 0,
		Max = 24,
		Default = -2,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (val / 10))
			end
		end
	})
	rotationx = nobob.CreateSlider({
		Name = "RotX",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
	rotationy = nobob.CreateSlider({
		Name = "RotY",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
	rotationz = nobob.CreateSlider({
		Name = "RotZ",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
end)

run(function()
	local SongBeats = {Enabled = false}
	local SongBeatsList = {ObjectList = {}}
	local SongBeatsIntensity = {Value = 5}
	local SongTween
	local SongAudio

	local function PlaySong(arg)
		local args = arg:split(":")
		local song = isfile(args[1]) and getcustomasset(args[1]) or tonumber(args[1]) and "rbxassetid://"..args[1]
		if not song then
			warningNotification("SongBeats", "missing music file "..args[1], 5)
			SongBeats.ToggleButton(false)
			return
		end
		local bpm = 1 / (args[2] / 60)
		SongAudio = Instance.new("Sound")
		SongAudio.SoundId = song
		SongAudio.Parent = workspace
		SongAudio:Play()
		repeat
			repeat task.wait() until SongAudio.IsLoaded or (not SongBeats.Enabled)
			if (not SongBeats.Enabled) then break end
			local newfov = math.min(bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1), 120)
			gameCamera.FieldOfView = newfov - SongBeatsIntensity.Value
			if SongTween then SongTween:Cancel() end
			SongTween = game:GetService("TweenService"):Create(gameCamera, TweenInfo.new(0.2), {FieldOfView = newfov})
			SongTween:Play()
			task.wait(bpm)
		until (not SongBeats.Enabled) or SongAudio.IsPaused
	end

	SongBeats = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "SongBeats",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if #SongBeatsList.ObjectList <= 0 then
						warningNotification("SongBeats", "no songs", 5)
						SongBeats.ToggleButton(false)
						return
					end
					local lastChosen
					repeat
						local newSong
						repeat newSong = SongBeatsList.ObjectList[Random.new():NextInteger(1, #SongBeatsList.ObjectList)] task.wait() until newSong ~= lastChosen or #SongBeatsList.ObjectList <= 1
						lastChosen = newSong
						PlaySong(newSong)
						if not SongBeats.Enabled then break end
						task.wait(2)
					until (not SongBeats.Enabled)
				end)
			else
				if SongAudio then SongAudio:Destroy() end
				if SongTween then SongTween:Cancel() end
				gameCamera.FieldOfView = bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1)
			end
		end
	})
	SongBeatsList = SongBeats.CreateTextList({
		Name = "SongList",
		TempText = "songpath:bpm"
	})
	SongBeatsIntensity = SongBeats.CreateSlider({
		Name = "Intensity",
		Function = function() end,
		Min = 1,
		Max = 10,
		Default = 5
	})
end)

run(function()
	local performed = false
	GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "UICleanup",
		Function = function(callback)
			if callback and not performed then
				performed = true
				task.spawn(function()
					local hotbar = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-app"]).HotbarApp
					local hotbaropeninv = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-open-inventory"]).HotbarOpenInventory
					local topbarbutton = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).TopBarButton
					local gametheme = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.shared.ui["game-theme"]).GameTheme
					bedwars.AppController:closeApp("TopBarApp")
					local oldrender = topbarbutton.render
					topbarbutton.render = function(self)
						local res = oldrender(self)
						if not self.props.Text then
							return bedwars.Roact.createElement("TextButton", {Visible = false}, {})
						end
						return res
					end
					hotbaropeninv.render = function(self)
						return bedwars.Roact.createElement("TextButton", {Visible = false}, {})
					end
					--[[debug.setconstant(hotbar.render, 52, 0.9975)
					debug.setconstant(hotbar.render, 73, 100)
					debug.setconstant(hotbar.render, 89, 1)
					debug.setconstant(hotbar.render, 90, 0.04)
					debug.setconstant(hotbar.render, 91, -0.03)
					debug.setconstant(hotbar.render, 109, 1.35)
					debug.setconstant(hotbar.render, 110, 0)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 30, 1)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 31, 0.175)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 33, -0.101)
					debug.setconstant(debug.getupvalue(hotbar.render, 18).render, 71, 0)
					debug.setconstant(debug.getupvalue(hotbar.render, 18).tweenPosition, 16, 0)]]
					gametheme.topBarBGTransparency = 0.5
					bedwars.TopBarController:mountHud()
					game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
					bedwars.AbilityUIController.abilityButtonsScreenGui.Visible = false
					bedwars.MatchEndScreenController.waitUntilDisplay = function() return false end
					task.spawn(function()
						repeat
							task.wait()
							local gui = lplr.PlayerGui:FindFirstChild("StatusEffectHudScreen")
							if gui then gui.Enabled = false break end
						until false
					end)
					task.spawn(function()
						repeat task.wait() until store.matchState ~= 0
						if bedwars.ClientStoreHandler:getState().Game.customMatch == nil then
							debug.setconstant(bedwars.QueueCard.render, 15, 0.1)
						end
					end)
					local slot = bedwars.ClientStoreHandler:getState().Inventory.observedInventory.hotbarSlot
					bedwars.ClientStoreHandler:dispatch({
						type = "InventorySelectHotbarSlot",
						slot = slot + 1 % 8
					})
					bedwars.ClientStoreHandler:dispatch({
						type = "InventorySelectHotbarSlot",
						slot = slot
					})
				end)
			end
		end
	})
end)

run(function()
	local AntiAFK = {Enabled = false}
	AntiAFK = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AntiAFK",
		Function = function(callback)
			if callback then
				bedwars.Client:Get("AfkInfo"):SendToServer({
					afk = false
				})
			end
		end
	})
end)

run(function()
	local AutoBalloonPart
	local AutoBalloonConnection
	local AutoBalloonDelay = {Value = 10}
	local AutoBalloonLegit = {Enabled = false}
	local AutoBalloonypos = 0
	local balloondebounce = false
	local AutoBalloon = {Enabled = false}
	AutoBalloon = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoBalloon",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or  not vapeInjected
					if vapeInjected and AutoBalloonypos == 0 and AutoBalloon.Enabled then
						local lowestypos = 99999
						for i,v in pairs(store.blocks) do
							local newray = workspace:Raycast(v.Position + Vector3.new(0, 800, 0), Vector3.new(0, -1000, 0), store.blockRaycast)
							if i % 200 == 0 then
								task.wait(0.06)
							end
							if newray and newray.Position.Y <= lowestypos then
								lowestypos = newray.Position.Y
							end
						end
						AutoBalloonypos = lowestypos - 8
					end
				end)
				task.spawn(function()
					repeat task.wait() until AutoBalloonypos ~= 0
					if AutoBalloon.Enabled then
						AutoBalloonPart = Instance.new("Part")
						AutoBalloonPart.CanCollide = false
						AutoBalloonPart.Size = Vector3.new(10000, 1, 10000)
						AutoBalloonPart.Anchored = true
						AutoBalloonPart.Transparency = 1
						AutoBalloonPart.Material = Enum.Material.Neon
						AutoBalloonPart.Color = Color3.fromRGB(135, 29, 139)
						AutoBalloonPart.Position = Vector3.new(0, AutoBalloonypos - 50, 0)
						AutoBalloonConnection = AutoBalloonPart.Touched:Connect(function(touchedpart)
							if entityLibrary.isAlive and touchedpart:IsDescendantOf(lplr.Character) and balloondebounce == false then
								autobankballoon = true
								balloondebounce = true
								local oldtool = store.localHand.tool
								for i = 1, 3 do
									if getItem("balloon") and (AutoBalloonLegit.Enabled and getHotbarSlot("balloon") or AutoBalloonLegit.Enabled == false) and (lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") < 3 or lplr.Character:GetAttribute("InflatedBalloons") == nil) then
										if AutoBalloonLegit.Enabled then
											if getHotbarSlot("balloon") then
												bedwars.ClientStoreHandler:dispatch({
													type = "InventorySelectHotbarSlot",
													slot = getHotbarSlot("balloon")
												})
												task.wait(AutoBalloonDelay.Value / 100)
												bedwars.BalloonController:inflateBalloon()
											end
										else
											task.wait(AutoBalloonDelay.Value / 100)
											bedwars.BalloonController:inflateBalloon()
										end
									end
								end
								if AutoBalloonLegit.Enabled and oldtool and getHotbarSlot(oldtool.Name) then
									task.wait(0.2)
									bedwars.ClientStoreHandler:dispatch({
										type = "InventorySelectHotbarSlot",
										slot = (getHotbarSlot(oldtool.Name) or 0)
									})
								end
								balloondebounce = false
								autobankballoon = false
							end
						end)
						AutoBalloonPart.Parent = workspace
					end
				end)
			else
				if AutoBalloonConnection then AutoBalloonConnection:Disconnect() end
				if AutoBalloonPart then
					AutoBalloonPart:Remove()
				end
			end
		end,
		HoverText = "Automatically Inflates Balloons"
	})
	AutoBalloonDelay = AutoBalloon.CreateSlider({
		Name = "Delay",
		Min = 1,
		Max = 50,
		Default = 20,
		Function = function() end,
		HoverText = "Delay to inflate balloons."
	})
	AutoBalloonLegit = AutoBalloon.CreateToggle({
		Name = "Legit Mode",
		Function = function() end,
		HoverText = "Switches to balloons in hotbar and inflates them."
	})
end)

local autobankapple = false
run(function()
	local AutoBuy = {Enabled = false}
	local AutoBuyArmor = {Enabled = false}
	local AutoBuySword = {Enabled = false}
	local AutoBuyGen = {Enabled = false}
	local AutoBuyProt = {Enabled = false}
	local AutoBuySharp = {Enabled = false}
	local AutoBuyDestruction = {Enabled = false}
	local AutoBuyDiamond = {Enabled = false}
	local AutoBuyAlarm = {Enabled = false}
	local AutoBuyGui = {Enabled = false}
	local AutoBuyTierSkip = {Enabled = true}
	local AutoBuyRange = {Value = 20}
	local AutoBuyCustom = {ObjectList = {}, RefreshList = function() end}
	local AutoBankUIToggle = {Enabled = false}
	local AutoBankDeath = {Enabled = false}
	local AutoBankStay = {Enabled = false}
	local buyingthing = false
	local shoothook
	local bedwarsshopnpcs = {}
	local id
	local armors = {
		[1] = "leather_chestplate",
		[2] = "iron_chestplate",
		[3] = "diamond_chestplate",
		[4] = "emerald_chestplate"
	}

	local swords = {
		[1] = "wood_sword",
		[2] = "stone_sword",
		[3] = "iron_sword",
		[4] = "diamond_sword",
		[5] = "emerald_sword"
	}

	local axes = {
		[1] = "wood_axe",
		[2] = "stone_axe",
		[3] = "iron_axe",
		[4] = "diamond_axe"
	}

	local pickaxes = {
		[1] = "wood_pickaxe",
		[2] = "stone_pickaxe",
		[3] = "iron_pickaxe",
		[4] = "diamond_pickaxe"
	}

	task.spawn(function()
		repeat task.wait() until store.matchState ~= 0 or not vapeInjected
		for i,v in pairs(collectionService:GetTagged("BedwarsItemShop")) do
			table.insert(bedwarsshopnpcs, {Position = v.Position, TeamUpgradeNPC = true, Id = v.Name})
		end
		for i,v in pairs(collectionService:GetTagged("TeamUpgradeShopkeeper")) do
			table.insert(bedwarsshopnpcs, {Position = v.Position, TeamUpgradeNPC = false, Id = v.Name})
		end
	end)

	local function nearNPC(range)
		local npc, npccheck, enchant, newid = nil, false, false, nil
		if entityLibrary.isAlive then
			local enchanttab = {}
			for i,v in pairs(collectionService:GetTagged("broken-enchant-table")) do
				table.insert(enchanttab, v)
			end
			for i,v in pairs(collectionService:GetTagged("enchant-table")) do
				table.insert(enchanttab, v)
			end
			for i,v in pairs(enchanttab) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= 6 then
					if ((not v:GetAttribute("Team")) or v:GetAttribute("Team") == lplr:GetAttribute("Team")) then
						npc, npccheck, enchant = true, true, true
					end
				end
			end
			for i, v in pairs(bedwarsshopnpcs) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= (range or 20) then
					npc, npccheck, enchant = true, (v.TeamUpgradeNPC or npccheck), false
					newid = v.TeamUpgradeNPC and v.Id or newid
				end
			end
			local suc, res = pcall(function() return lplr.leaderstats.Bed.Value == "✅"  end)
			if AutoBankDeath.Enabled and (workspace:GetServerTimeNow() - lplr.Character:GetAttribute("LastDamageTakenTime")) < 2 and suc and res then
				return nil, false, false
			end
			if AutoBankStay.Enabled then
				return nil, false, false
			end
		end
		return npc, not npccheck, enchant, newid
	end

	local function buyItem(itemtab, waitdelay)
		if not id then return end
		local res
		bedwars.Client:Get("BedwarsPurchaseItem"):CallServerAsync({
			shopItem = itemtab,
			shopId = id
		}):andThen(function(p11)
			if p11 then
				bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
				bedwars.ClientStoreHandler:dispatch({
					type = "BedwarsAddItemPurchased",
					itemType = itemtab.itemType
				})
			end
			res = p11
		end)
		if waitdelay then
			repeat task.wait() until res ~= nil
		end
	end

	local function getAxeNear(inv)
		for i5, v5 in pairs(inv or store.localInventory.inventory.items) do
			if v5.itemType:find("axe") and v5.itemType:find("pickaxe") == nil then
				return v5.itemType
			end
		end
		return nil
	end

	local function getPickaxeNear(inv)
		for i5, v5 in pairs(inv or store.localInventory.inventory.items) do
			if v5.itemType:find("pickaxe") then
				return v5.itemType
			end
		end
		return nil
	end

	local function getShopItem(itemType)
		if itemType == "axe" then
			itemType = getAxeNear() or "wood_axe"
			itemType = axes[table.find(axes, itemType) + 1] or itemType
		end
		if itemType == "pickaxe" then
			itemType = getPickaxeNear() or "wood_pickaxe"
			itemType = pickaxes[table.find(pickaxes, itemType) + 1] or itemType
		end
		for i,v in pairs(bedwars.ShopItems) do
			if v.itemType == itemType then return v end
		end
		return nil
	end

	local buyfunctions = {
		Armor = function(inv, upgrades, shoptype)
			if AutoBuyArmor.Enabled == false or shoptype ~= "item" then return end
			local currentarmor = (inv.armor[2] ~= "empty" and inv.armor[2].itemType:find("chestplate") ~= nil) and inv.armor[2] or nil
			local armorindex = (currentarmor and table.find(armors, currentarmor.itemType) or 0) + 1
			if armors[armorindex] == nil then return end
			local highestbuyable = nil
			for i = armorindex, #armors, 1 do
				local shopitem = getShopItem(armors[i])
				if shopitem and i == armorindex then
					local currency = getItem(shopitem.currency, inv.items)
					if currency and currency.amount >= shopitem.price then
						highestbuyable = shopitem
						bedwars.ClientStoreHandler:dispatch({
							type = "BedwarsAddItemPurchased",
							itemType = shopitem.itemType
						})
					end
				end
			end
			if highestbuyable and (highestbuyable.ignoredByKit == nil or table.find(highestbuyable.ignoredByKit, store.equippedKit) == nil) then
				buyItem(highestbuyable)
			end
		end,
		Sword = function(inv, upgrades, shoptype)
			if AutoBuySword.Enabled == false or shoptype ~= "item" then return end
			local currentsword = getItemNear("sword", inv.items)
			local swordindex = (currentsword and table.find(swords, currentsword.itemType) or 0) + 1
			if currentsword ~= nil and table.find(swords, currentsword.itemType) == nil then return end
			local highestbuyable = nil
			for i = swordindex, #swords, 1 do
				local shopitem = getShopItem(swords[i])
				if shopitem and i == swordindex then
					local currency = getItem(shopitem.currency, inv.items)
					if currency and currency.amount >= shopitem.price and (shopitem.category ~= "Armory" or upgrades.armory) then
						highestbuyable = shopitem
						bedwars.ClientStoreHandler:dispatch({
							type = "BedwarsAddItemPurchased",
							itemType = shopitem.itemType
						})
					end
				end
			end
			if highestbuyable and (highestbuyable.ignoredByKit == nil or table.find(highestbuyable.ignoredByKit, store.equippedKit) == nil) then
				buyItem(highestbuyable)
			end
		end
	}

	AutoBuy = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoBuy",
		Function = function(callback)
			if callback then
				buyingthing = false
				task.spawn(function()
					repeat
						task.wait()
						local found, npctype, enchant, newid = nearNPC(AutoBuyRange.Value)
						id = newid
						if found then
							local inv = store.localInventory.inventory
							local currentupgrades = bedwars.ClientStoreHandler:getState().Bedwars.teamUpgrades
							if store.equippedKit == "dasher" then
								swords = {
									[1] = "wood_dao",
									[2] = "stone_dao",
									[3] = "iron_dao",
									[4] = "diamond_dao",
									[5] = "emerald_dao"
								}
							elseif store.equippedKit == "ice_queen" then
								swords[5] = "ice_sword"
							elseif store.equippedKit == "ember" then
								swords[5] = "infernal_saber"
							elseif store.equippedKit == "lumen" then
								swords[5] = "light_sword"
							end
							if (AutoBuyGui.Enabled == false or (bedwars.AppController:isAppOpen("BedwarsItemShopApp") or bedwars.AppController:isAppOpen("BedwarsTeamUpgradeApp"))) and (not enchant) then
								for i,v in pairs(AutoBuyCustom.ObjectList) do
									local autobuyitem = v:split("/")
									if #autobuyitem >= 3 and autobuyitem[4] ~= "true" then
										local shopitem = getShopItem(autobuyitem[1])
										if shopitem then
											local currency = getItem(shopitem.currency, inv.items)
											local actualitem = getItem(shopitem.itemType == "wool_white" and getWool() or shopitem.itemType, inv.items)
											if currency and currency.amount >= shopitem.price and (actualitem == nil or actualitem.amount < tonumber(autobuyitem[2])) then
												buyItem(shopitem, tonumber(autobuyitem[2]) > 1)
											end
										end
									end
								end
								for i,v in pairs(buyfunctions) do v(inv, currentupgrades, npctype and "upgrade" or "item") end
								for i,v in pairs(AutoBuyCustom.ObjectList) do
									local autobuyitem = v:split("/")
									if #autobuyitem >= 3 and autobuyitem[4] == "true" then
										local shopitem = getShopItem(autobuyitem[1])
										if shopitem then
											local currency = getItem(shopitem.currency, inv.items)
											local actualitem = getItem(shopitem.itemType == "wool_white" and getWool() or shopitem.itemType, inv.items)
											if currency and currency.amount >= shopitem.price and (actualitem == nil or actualitem.amount < tonumber(autobuyitem[2])) then
												buyItem(shopitem, tonumber(autobuyitem[2]) > 1)
											end
										end
									end
								end
							end
						end
					until (not AutoBuy.Enabled)
				end)
			end
		end,
		HoverText = "Automatically Buys Swords, Armor, and Team Upgrades\nwhen you walk near the NPC"
	})
	AutoBuyRange = AutoBuy.CreateSlider({
		Name = "Range",
		Function = function() end,
		Min = 1,
		Max = 20,
		Default = 20
	})
	AutoBuyArmor = AutoBuy.CreateToggle({
		Name = "Buy Armor",
		Function = function() end,
		Default = true
	})
	AutoBuySword = AutoBuy.CreateToggle({
		Name = "Buy Sword",
		Function = function() end,
		Default = true
	})
	AutoBuyGui = AutoBuy.CreateToggle({
		Name = "Shop GUI Check",
		Function = function() end,
	})
	AutoBuyTierSkip = AutoBuy.CreateToggle({
		Name = "Tier Skip",
		Function = function() end,
		Default = true
	})
	AutoBuyCustom = AutoBuy.CreateTextList({
		Name = "BuyList",
		TempText = "item/amount/priority/after",
		SortFunction = function(a, b)
			local amount1 = a:split("/")
			local amount2 = b:split("/")
			amount1 = #amount1 and tonumber(amount1[3]) or 1
			amount2 = #amount2 and tonumber(amount2[3]) or 1
			return amount1 < amount2
		end
	})
	AutoBuyCustom.Object.AddBoxBKG.AddBox.TextSize = 14
end)

run(function()
	local AutoConsume = {Enabled = false}
	local AutoConsumeHealth = {Value = 100}
	local AutoConsumeSpeed = {Enabled = true}
	local AutoConsumeDelay = tick()

	local function AutoConsumeFunc()
		if entityLibrary.isAlive then
			local speedpotion = getItem("speed_potion")
			if lplr.Character:GetAttribute("Health") <= (lplr.Character:GetAttribute("MaxHealth") - (100 - AutoConsumeHealth.Value)) then
				autobankapple = true
				local item = getItem("apple")
				local pot = getItem("heal_splash_potion")
				if (item or pot) and AutoConsumeDelay <= tick() then
					if item then
						bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
							item = item.tool
						})
						AutoConsumeDelay = tick() + 0.6
					else
						local newray = workspace:Raycast((oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, Vector3.new(0, -76, 0), store.blockRaycast)
						if newray ~= nil then
							bedwars.Client:Get(bedwars.ProjectileRemote):CallServerAsync(pot.tool, "heal_splash_potion", "heal_splash_potion", (oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, (oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, Vector3.new(0, -70, 0), game:GetService("HttpService"):GenerateGUID(), {drawDurationSeconds = 1})
						end
					end
				end
			else
				autobankapple = false
			end
			if speedpotion and (not lplr.Character:GetAttribute("StatusEffect_speed")) and AutoConsumeSpeed.Enabled then
				bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
					item = speedpotion.tool
				})
			end
			if lplr.Character:GetAttribute("Shield_POTION") and ((not lplr.Character:GetAttribute("Shield_POTION")) or lplr.Character:GetAttribute("Shield_POTION") == 0) then
				local shield = getItem("big_shield") or getItem("mini_shield")
				if shield then
					bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
						item = shield.tool
					})
				end
			end
		end
	end

	AutoConsume = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoConsume",
		Function = function(callback)
			if callback then
				table.insert(AutoConsume.Connections, vapeEvents.InventoryAmountChanged.Event:Connect(AutoConsumeFunc))
				table.insert(AutoConsume.Connections, vapeEvents.AttributeChanged.Event:Connect(function(changed)
					if changed:find("Shield") or changed:find("Health") or changed:find("speed") then
						AutoConsumeFunc()
					end
				end))
				AutoConsumeFunc()
			end
		end,
		HoverText = "Automatically heals for you when health or shield is under threshold."
	})
	AutoConsumeHealth = AutoConsume.CreateSlider({
		Name = "Health",
		Min = 1,
		Max = 99,
		Default = 70,
		Function = function() end
	})
	AutoConsumeSpeed = AutoConsume.CreateToggle({
		Name = "Speed Potions",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local AutoHotbarList = {Hotbars = {}, CurrentlySelected = 1}
	local AutoHotbarMode = {Value = "Toggle"}
	local AutoHotbarClear = {Enabled = false}
	local AutoHotbar = {Enabled = false}
	local AutoHotbarActive = false

	local function getCustomItem(v2)
		local realitem = v2.itemType
		if realitem == "swords" then
			local sword = getSword()
			realitem = sword and sword.itemType or "wood_sword"
		elseif realitem == "pickaxes" then
			local pickaxe = getPickaxe()
			realitem = pickaxe and pickaxe.itemType or "wood_pickaxe"
		elseif realitem == "axes" then
			local axe = getAxe()
			realitem = axe and axe.itemType or "wood_axe"
		elseif realitem == "bows" then
			local bow = getBow()
			realitem = bow and bow.itemType or "wood_bow"
		elseif realitem == "wool" then
			realitem = getWool() or "wool_white"
		end
		return realitem
	end

	local function findItemInTable(tab, item)
		for i, v in pairs(tab) do
			if v and v.itemType then
				if item.itemType == getCustomItem(v) then
					return i
				end
			end
		end
		return nil
	end

	local function findinhotbar(item)
		for i,v in pairs(store.localInventory.hotbar) do
			if v.item and v.item.itemType == item.itemType then
				return i, v.item
			end
		end
	end

	local function findininventory(item)
		for i,v in pairs(store.localInventory.inventory.items) do
			if v.itemType == item.itemType then
				return v
			end
		end
	end

	local function AutoHotbarSort()
		task.spawn(function()
			if AutoHotbarActive then return end
			AutoHotbarActive = true
			local items = (AutoHotbarList.Hotbars[AutoHotbarList.CurrentlySelected] and AutoHotbarList.Hotbars[AutoHotbarList.CurrentlySelected].Items or {})
			for i, v in pairs(store.localInventory.inventory.items) do
				local customItem
				local hotbarslot = findItemInTable(items, v)
				if hotbarslot then
					local oldhotbaritem = store.localInventory.hotbar[tonumber(hotbarslot)]
					if oldhotbaritem.item and oldhotbaritem.item.itemType == v.itemType then continue end
					if oldhotbaritem.item then
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryRemoveFromHotbar",
							slot = tonumber(hotbarslot) - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					local newhotbaritemslot, newhotbaritem = findinhotbar(v)
					if newhotbaritemslot then
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryRemoveFromHotbar",
							slot = newhotbaritemslot - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					if oldhotbaritem.item and newhotbaritemslot then
						local nextitem1, nextitem1num = findininventory(oldhotbaritem.item)
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryAddToHotbar",
							item = nextitem1,
							slot = newhotbaritemslot - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					local nextitem2, nextitem2num = findininventory(v)
					bedwars.ClientStoreHandler:dispatch({
						type = "InventoryAddToHotbar",
						item = nextitem2,
						slot = tonumber(hotbarslot) - 1
					})
					vapeEvents.InventoryChanged.Event:Wait()
				else
					if AutoHotbarClear.Enabled then
						local newhotbaritemslot, newhotbaritem = findinhotbar(v)
						if newhotbaritemslot then
							bedwars.ClientStoreHandler:dispatch({
								type = "InventoryRemoveFromHotbar",
								slot = newhotbaritemslot - 1
							})
							vapeEvents.InventoryChanged.Event:Wait()
						end
					end
				end
			end
			AutoHotbarActive = false
		end)
	end

	AutoHotbar = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoHotbar",
		Function = function(callback)
			if callback then
				AutoHotbarSort()
				if AutoHotbarMode.Value == "On Key" then
					if AutoHotbar.Enabled then
						AutoHotbar.ToggleButton(false)
					end
				else
					table.insert(AutoHotbar.Connections, vapeEvents.InventoryAmountChanged.Event:Connect(function()
						if not AutoHotbar.Enabled then return end
						AutoHotbarSort()
					end))
				end
			end
		end,
		HoverText = "Automatically arranges hotbar to your liking."
	})
	AutoHotbarMode = AutoHotbar.CreateDropdown({
		Name = "Activation",
		List = {"On Key", "Toggle"},
		Function = function(val)
			if AutoHotbar.Enabled then
				AutoHotbar.ToggleButton(false)
				AutoHotbar.ToggleButton(false)
			end
		end
	})
	AutoHotbarList = CreateAutoHotbarGUI(AutoHotbar.Children, {
		Name = "lol"
	})
	AutoHotbarClear = AutoHotbar.CreateToggle({
		Name = "Clear Hotbar",
		Function = function() end
	})
end)

run(function()
	local AutoKit = {Enabled = false}
	local AutoKitTrinity = {Value = "Void"}
	local oldfish
	local function GetTeammateThatNeedsMost()
		local plrs = GetAllNearestHumanoidToPosition(true, 30, 1000, true)
		local lowest, lowestplayer = 10000, nil
		for i,v in pairs(plrs) do
			if not v.Targetable then
				if v.Character:GetAttribute("Health") <= lowest and v.Character:GetAttribute("Health") < v.Character:GetAttribute("MaxHealth") then
					lowest = v.Character:GetAttribute("Health")
					lowestplayer = v
				end
			end
		end
		return lowestplayer
	end

	AutoKit = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoKit",
		Function = function(callback)
			if callback then
				oldfish = bedwars.FishermanController.startMinigame
				bedwars.FishermanController.startMinigame = function(Self, dropdata, func) func({win = true}) end
				task.spawn(function()
					repeat task.wait() until store.equippedKit ~= ""
					if AutoKit.Enabled then
						if store.equippedKit == "melody" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if getItem("guitar") then
										local plr = GetTeammateThatNeedsMost()
										if plr and healtick <= tick() then
											bedwars.Client:Get(bedwars.GuitarHealRemote):SendToServer({
												healTarget = plr.Character
											})
											healtick = tick() + 2
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "bigman" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("treeOrb")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and v:FindFirstChild("Spirit") and (entityLibrary.character.HumanoidRootPart.Position - v.Spirit.Position).magnitude <= 20 then
											if bedwars.Client:Get(bedwars.TreeRemote):CallServer({
												treeOrbSecret = v:GetAttribute("TreeOrbSecret")
											}) then
												v:Destroy()
												collectionService:RemoveTag(v, "treeOrb")
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "metal_detector" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("hidden-metal")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and v.PrimaryPart and (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude <= 20 then
											bedwars.Client:Get(bedwars.PickupMetalRemote):SendToServer({
												id = v:GetAttribute("Id")
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "battery" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = bedwars.BatteryEffectsController.liveBatteries
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - v.position).magnitude <= 10 then
											bedwars.Client:Get(bedwars.BatteryRemote):SendToServer({
												batteryId = i
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "grim_reaper" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = bedwars.GrimReaperController.soulsByPosition
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and lplr.Character:GetAttribute("Health") <= (lplr.Character:GetAttribute("MaxHealth") / 4) and v.PrimaryPart and (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude <= 120 and (not lplr.Character:GetAttribute("GrimReaperChannel")) then
											bedwars.Client:Get(bedwars.ConsumeSoulRemote):CallServer({
												secret = v:GetAttribute("GrimReaperSoulSecret")
											})
											v:Destroy()
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "farmer_cletus" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("HarvestableCrop")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - v.Position).magnitude <= 10 then
											bedwars.Client:Get("CropHarvest"):CallServerAsync({
												position = bedwars.BlockController:getBlockPosition(v.Position)
											}):andThen(function(suc)
												if suc then
													bedwars.GameAnimationUtil.playAnimation(lplr.Character, 1)
													bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
												end
											end)
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "pinata" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged(lplr.Name..':pinata')
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and getItem('candy') then
											bedwars.Client:Get(bedwars.PinataRemote):CallServer(v)
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "dragon_slayer" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i,v in pairs(bedwars.DragonSlayerController.dragonEmblems) do
											if v.stackCount >= 3 then
												bedwars.DragonSlayerController:deleteEmblem(i)
												local localPos = lplr.Character:GetPrimaryPartCFrame().Position
												local punchCFrame = CFrame.new(localPos, (i:GetPrimaryPartCFrame().Position * Vector3.new(1, 0, 1)) + Vector3.new(0, localPos.Y, 0))
												lplr.Character:SetPrimaryPartCFrame(punchCFrame)
												bedwars.DragonSlayerController:playPunchAnimation(punchCFrame - punchCFrame.Position)
												bedwars.Client:Get(bedwars.DragonRemote):SendToServer({
													target = i
												})
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "mage" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i, v in pairs(collectionService:GetTagged("TomeGuidingBeam")) do
											local obj = v.Parent and v.Parent.Parent and v.Parent.Parent.Parent
											if obj and (entityLibrary.character.HumanoidRootPart.Position - obj.PrimaryPart.Position).Magnitude < 5 and obj:GetAttribute("TomeSecret") then
												local res = bedwars.Client:Get(bedwars.MageRemote):CallServer({
													secret = obj:GetAttribute("TomeSecret")
												})
												if res.success and res.element then
													bedwars.GameAnimationUtil.playAnimation(lplr, bedwars.AnimationType.PUNCH)
													bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
													bedwars.MageController:destroyTomeGuidingBeam()
													bedwars.MageController:playLearnLightBeamEffect(lplr, obj)
													local sound = bedwars.MageKitUtil.MageElementVisualizations[res.element].learnSound
													if sound and sound ~= "" then
														bedwars.SoundManager:playSound(sound)
													end
													task.delay(bedwars.BalanceFile.LEARN_TOME_DURATION, function()
														bedwars.MageController:fadeOutTome(obj)
														if lplr.Character and res.element then
															bedwars.MageKitUtil.changeMageKitAppearance(lplr, lplr.Character, res.element)
														end
													end)
												end
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "angel" then
							table.insert(AutoKit.Connections, vapeEvents.AngelProgress.Event:Connect(function(angelTable)
								task.wait(0.5)
								if not AutoKit.Enabled then return end
								if bedwars.ClientStoreHandler:getState().Kit.angelProgress >= 1 and lplr.Character:GetAttribute("AngelType") == nil then
									bedwars.Client:Get(bedwars.TrinityRemote):SendToServer({
										angel = AutoKitTrinity.Value
									})
								end
							end))
						elseif store.equippedKit == "miner" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i,v in pairs(collectionService:GetTagged("petrified-player")) do
											bedwars.Client:Get(bedwars.MinerRemote):SendToServer({
												petrifyId = v:GetAttribute("PetrifyId")
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						end
					end
				end)
			else
				bedwars.FishermanController.startMinigame = oldfish
				oldfish = nil
			end
		end,
		HoverText = "Automatically uses a kits ability"
	})
	AutoKitTrinity = AutoKit.CreateDropdown({
		Name = "Angel",
		List = {"Void", "Light"},
		Function = function() end
	})
end)

run(function()
	local AutoForge = {Enabled = false}
	local AutoForgeWeapon = {Value = "Sword"}
	local AutoForgeBow = {Enabled = false}
	local AutoForgeArmor = {Enabled = false}
	local AutoForgeSword = {Enabled = false}
	local AutoForgeBuyAfter = {Enabled = false}
	local AutoForgeNotification = {Enabled = true}

	local function buyForge(i)
		if not store.forgeUpgrades[i] or store.forgeUpgrades[i] < 6 then
			local cost = bedwars.ForgeUtil:getUpgradeCost(1, store.forgeUpgrades[i] or 0)
			if store.forgeMasteryPoints >= cost then
				if AutoForgeNotification.Enabled then
					local forgeType = "none"
					for name,v in pairs(bedwars.ForgeConstants) do
						if v == i then forgeType = name:lower() end
					end
					warningNotification("AutoForge", "Purchasing "..forgeType..".", bedwars.ForgeUtil.FORGE_DURATION_SEC)
				end
				bedwars.Client:Get("ForgePurchaseUpgrade"):SendToServer(i)
				task.wait(bedwars.ForgeUtil.FORGE_DURATION_SEC + 0.2)
			end
		end
	end

	AutoForge = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoForge",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						if store.matchState == 1 and entityLibrary.isAlive then
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeArmor.Enabled then buyForge(bedwars.ForgeConstants.ARMOR) end
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeBow.Enabled then buyForge(bedwars.ForgeConstants.RANGED) end
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeSword.Enabled then
								if AutoForgeBuyAfter.Enabled then
									if not store.forgeUpgrades[bedwars.ForgeConstants.ARMOR] or store.forgeUpgrades[bedwars.ForgeConstants.ARMOR] < 6 then continue end
								end
								local weapon = bedwars.ForgeConstants[AutoForgeWeapon.Value:upper()]
								if weapon then buyForge(weapon) end
							end
						end
					until (not AutoForge.Enabled)
				end)
			end
		end
	})
	AutoForgeWeapon = AutoForge.CreateDropdown({
		Name = "Weapon",
		Function = function() end,
		List = {"Sword", "Dagger", "Scythe", "Great_Hammer", "Gauntlets"}
	})
	AutoForgeArmor = AutoForge.CreateToggle({
		Name = "Armor",
		Function = function() end,
		Default = true
	})
	AutoForgeSword = AutoForge.CreateToggle({
		Name = "Weapon",
		Function = function() end
	})
	AutoForgeBow = AutoForge.CreateToggle({
		Name = "Bow",
		Function = function() end
	})
	AutoForgeBuyAfter = AutoForge.CreateToggle({
		Name = "Buy After",
		Function = function() end,
		HoverText = "buy a weapon after armor is maxed"
	})
	AutoForgeNotification = AutoForge.CreateToggle({
		Name = "Notification",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local alreadyreportedlist = {}
	local AutoReportV2 = {Enabled = false}
	local AutoReportV2Notify = {Enabled = false}
	AutoReportV2 = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoReportV2",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						for i,v in pairs(playersService:GetPlayers()) do
							if v ~= lplr and alreadyreportedlist[v] == nil and v:GetAttribute("PlayerConnected") and whitelist:get(v) == 0 then
								task.wait(1)
								alreadyreportedlist[v] = true
								bedwars.Client:Get(bedwars.ReportRemote):SendToServer(v.UserId)
								store.statistics.reported = store.statistics.reported + 1
								if AutoReportV2Notify.Enabled then
									warningNotification("AutoReportV2", "Reported "..v.Name, 15)
								end
							end
						end
					until (not AutoReportV2.Enabled)
				end)
			end
		end,
		HoverText = "dv mald"
	})
	AutoReportV2Notify = AutoReportV2.CreateToggle({
		Name = "Notify",
		Function = function() end
	})
end)

run(function()
	local justsaid = ""
	local leavesaid = false
	local alreadyreported = {}

	local function removerepeat(str)
		local newstr = ""
		local lastlet = ""
		for i,v in pairs(str:split("")) do
			if v ~= lastlet then
				newstr = newstr..v
				lastlet = v
			end
		end
		return newstr
	end

	local reporttable = {
		gay = "Bullying",
		gae = "Bullying",
		gey = "Bullying",
		hack = "Scamming",
		exploit = "Scamming",
		cheat = "Scamming",
		hecker = "Scamming",
		haxker = "Scamming",
		hacer = "Scamming",
		report = "Bullying",
		fat = "Bullying",
		black = "Bullying",
		getalife = "Bullying",
		fatherless = "Bullying",
		report = "Bullying",
		fatherless = "Bullying",
		disco = "Offsite Links",
		yt = "Offsite Links",
		dizcourde = "Offsite Links",
		retard = "Swearing",
		bad = "Bullying",
		trash = "Bullying",
		nolife = "Bullying",
		nolife = "Bullying",
		loser = "Bullying",
		killyour = "Bullying",
		kys = "Bullying",
		hacktowin = "Bullying",
		bozo = "Bullying",
		kid = "Bullying",
		adopted = "Bullying",
		linlife = "Bullying",
		commitnotalive = "Bullying",
		vape = "Offsite Links",
		futureclient = "Offsite Links",
		download = "Offsite Links",
		youtube = "Offsite Links",
		die = "Bullying",
		lobby = "Bullying",
		ban = "Bullying",
		wizard = "Bullying",
		wisard = "Bullying",
		witch = "Bullying",
		magic = "Bullying",
	}
	local reporttableexact = {
		L = "Bullying",
	}


	local function findreport(msg)
		local checkstr = removerepeat(msg:gsub("%W+", ""):lower())
		for i,v in pairs(reporttable) do
			if checkstr:find(i) then
				return v, i
			end
		end
		for i,v in pairs(reporttableexact) do
			if checkstr == i then
				return v, i
			end
		end
		for i,v in pairs(AutoToxicPhrases5.ObjectList) do
			if checkstr:find(v) then
				return "Bullying", v
			end
		end
		return nil
	end

	AutoToxic = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoToxic",
		Function = function(callback)
			if callback then
				table.insert(AutoToxic.Connections, vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if AutoToxicBedDestroyed.Enabled and bedTable.brokenBedTeam.id == lplr:GetAttribute("Team") then
						local custommsg = #AutoToxicPhrases6.ObjectList > 0 and AutoToxicPhrases6.ObjectList[math.random(1, #AutoToxicPhrases6.ObjectList)] or "How dare you break my bed >:( <name> | vxpe on top"
						if custommsg then
							custommsg = custommsg:gsub("<name>", (bedTable.player.DisplayName or bedTable.player.Name))
						end
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
						end
					elseif AutoToxicBedBreak.Enabled and bedTable.player.UserId == lplr.UserId then
						local custommsg = #AutoToxicPhrases7.ObjectList > 0 and AutoToxicPhrases7.ObjectList[math.random(1, #AutoToxicPhrases7.ObjectList)] or "nice bed <teamname> | vxpe on top"
						if custommsg then
							local team = bedwars.QueueMeta[store.queueType].teams[tonumber(bedTable.brokenBedTeam.id)]
							local teamname = team and team.displayName:lower() or "white"
							custommsg = custommsg:gsub("<teamname>", teamname)
						end
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed == lplr then
							if (not leavesaid) and killer ~= lplr and AutoToxicDeath.Enabled then
								leavesaid = true
								local custommsg = #AutoToxicPhrases3.ObjectList > 0 and AutoToxicPhrases3.ObjectList[math.random(1, #AutoToxicPhrases3.ObjectList)] or "My gaming chair expired midfight, thats why you won <name> | vxpe on top"
								if custommsg then
									custommsg = custommsg:gsub("<name>", (killer.DisplayName or killer.Name))
								end
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
								end
							end
						else
							if killer == lplr and AutoToxicFinalKill.Enabled then
								local custommsg = #AutoToxicPhrases2.ObjectList > 0 and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)] or "L <name> | vxpe on top"
								if custommsg == lastsaid then
									custommsg = #AutoToxicPhrases2.ObjectList > 0 and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)] or "L <name> | vxpe on top"
								else
									lastsaid = custommsg
								end
								if custommsg then
									custommsg = custommsg:gsub("<name>", (killed.DisplayName or killed.Name))
								end
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
								end
							end
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					local myTeam = bedwars.ClientStoreHandler:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						if AutoToxicGG.Enabled then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("gg")
							if shared.ggfunction then
								shared.ggfunction()
							end
						end
						if AutoToxicWin.Enabled then
							local custommsg = #AutoToxicPhrases.ObjectList > 0 and AutoToxicPhrases.ObjectList[math.random(1, #AutoToxicPhrases.ObjectList)] or "EZ L TRASH KIDS | vxpe on top"
							if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
								textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
							else
								replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
							end
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.LagbackEvent.Event:Connect(function(plr)
					if AutoToxicLagback.Enabled then
						local custommsg = #AutoToxicPhrases8.ObjectList > 0 and AutoToxicPhrases8.ObjectList[math.random(1, #AutoToxicPhrases8.ObjectList)]
						if custommsg then
							custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
						end
						local msg = custommsg or "Imagine lagbacking L "..(plr.DisplayName or plr.Name).." | vxpe on top"
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, 'All')
						end
					end
				end))
				table.insert(AutoToxic.Connections, textChatService.MessageReceived:Connect(function(tab)
					if AutoToxicRespond.Enabled then
						local plr = playersService:GetPlayerByUserId(tab.TextSource.UserId)
						local args = tab.Text:split(" ")
						if plr and plr ~= lplr and not alreadyreported[plr] then
							local reportreason, reportedmatch = findreport(tab.Text)
							if reportreason then
								alreadyreported[plr] = true
								local custommsg = #AutoToxicPhrases4.ObjectList > 0 and AutoToxicPhrases4.ObjectList[math.random(1, #AutoToxicPhrases4.ObjectList)]
								if custommsg then
									custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
								end
								local msg = custommsg or "I don't care about the fact that I'm hacking, I care about you dying in a block game. L "..(plr.DisplayName or plr.Name).." | vxpe on top"
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, 'All')
								end
							end
						end
					end
				end))
			end
		end
	})
	AutoToxicGG = AutoToxic.CreateToggle({
		Name = "AutoGG",
		Function = function() end,
		Default = true
	})
	AutoToxicWin = AutoToxic.CreateToggle({
		Name = "Win",
		Function = function() end,
		Default = true
	})
	AutoToxicDeath = AutoToxic.CreateToggle({
		Name = "Death",
		Function = function() end,
		Default = true
	})
	AutoToxicBedBreak = AutoToxic.CreateToggle({
		Name = "Bed Break",
		Function = function() end,
		Default = true
	})
	AutoToxicBedDestroyed = AutoToxic.CreateToggle({
		Name = "Bed Destroyed",
		Function = function() end,
		Default = true
	})
	AutoToxicRespond = AutoToxic.CreateToggle({
		Name = "Respond",
		Function = function() end,
		Default = true
	})
	AutoToxicFinalKill = AutoToxic.CreateToggle({
		Name = "Final Kill",
		Function = function() end,
		Default = true
	})
	AutoToxicTeam = AutoToxic.CreateToggle({
		Name = "Teammates",
		Function = function() end,
	})
	AutoToxicLagback = AutoToxic.CreateToggle({
		Name = "Lagback",
		Function = function() end,
		Default = true
	})
	AutoToxicPhrases = AutoToxic.CreateTextList({
		Name = "ToxicList",
		TempText = "phrase (win)",
	})
	AutoToxicPhrases2 = AutoToxic.CreateTextList({
		Name = "ToxicList2",
		TempText = "phrase (kill) <name>",
	})
	AutoToxicPhrases3 = AutoToxic.CreateTextList({
		Name = "ToxicList3",
		TempText = "phrase (death) <name>",
	})
	AutoToxicPhrases7 = AutoToxic.CreateTextList({
		Name = "ToxicList7",
		TempText = "phrase (bed break) <teamname>",
	})
	AutoToxicPhrases7.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases6 = AutoToxic.CreateTextList({
		Name = "ToxicList6",
		TempText = "phrase (bed destroyed) <name>",
	})
	AutoToxicPhrases6.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases4 = AutoToxic.CreateTextList({
		Name = "ToxicList4",
		TempText = "phrase (text to respond with) <name>",
	})
	AutoToxicPhrases4.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases5 = AutoToxic.CreateTextList({
		Name = "ToxicList5",
		TempText = "phrase (text to respond to)",
	})
	AutoToxicPhrases5.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases8 = AutoToxic.CreateTextList({
		Name = "ToxicList8",
		TempText = "phrase (lagback) <name>",
	})
	AutoToxicPhrases8.Object.AddBoxBKG.AddBox.TextSize = 12
end)

run(function()
	local ChestStealer = {Enabled = false}
	local ChestStealerDistance = {Value = 1}
	local ChestStealerDelay = {Value = 1}
	local ChestStealerOpen = {Enabled = false}
	local ChestStealerSkywars = {Enabled = true}
	local cheststealerdelays = {}
	local cheststealerfuncs = {
		Open = function()
			if bedwars.AppController:isAppOpen("ChestApp") then
				local chest = lplr.Character:FindFirstChild("ObservedChestFolder")
				local chestitems = chest and chest.Value and chest.Value:GetChildren() or {}
				if #chestitems > 0 then
					for i3,v3 in pairs(chestitems) do
						if v3:IsA("Accessory") and (cheststealerdelays[v3] == nil or cheststealerdelays[v3] < tick()) then
							task.spawn(function()
								pcall(function()
									cheststealerdelays[v3] = tick() + 0.2
									bedwars.Client:GetNamespace("Inventory"):Get("ChestGetItem"):CallServer(chest.Value, v3)
								end)
							end)
							task.wait(ChestStealerDelay.Value / 100)
						end
					end
				end
			end
		end,
		Closed = function()
			for i, v in pairs(collectionService:GetTagged("chest")) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= ChestStealerDistance.Value then
					local chest = v:FindFirstChild("ChestFolderValue")
					chest = chest and chest.Value or nil
					local chestitems = chest and chest:GetChildren() or {}
					if #chestitems > 0 then
						bedwars.Client:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer(chest)
						for i3,v3 in pairs(chestitems) do
							if v3:IsA("Accessory") then
								task.spawn(function()
									pcall(function()
										bedwars.Client:GetNamespace("Inventory"):Get("ChestGetItem"):CallServer(v.ChestFolderValue.Value, v3)
									end)
								end)
								task.wait(ChestStealerDelay.Value / 100)
							end
						end
						bedwars.Client:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer(nil)
					end
				end
			end
		end
	}

	ChestStealer = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "ChestStealer",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.queueType ~= "bedwars_test"
					if (not ChestStealerSkywars.Enabled) or store.queueType:find("skywars") then
						repeat
							task.wait(0.1)
							if entityLibrary.isAlive then
								cheststealerfuncs[ChestStealerOpen.Enabled and "Open" or "Closed"]()
							end
						until (not ChestStealer.Enabled)
					end
				end)
			end
		end,
		HoverText = "Grabs items from near chests."
	})
	ChestStealerDistance = ChestStealer.CreateSlider({
		Name = "Range",
		Min = 0,
		Max = 18,
		Function = function() end,
		Default = 18
	})
	ChestStealerDelay = ChestStealer.CreateSlider({
		Name = "Delay",
		Min = 1,
		Max = 50,
		Function = function() end,
		Default = 1,
		Double = 100
	})
	ChestStealerOpen = ChestStealer.CreateToggle({
		Name = "GUI Check",
		Function = function() end
	})
	ChestStealerSkywars = ChestStealer.CreateToggle({
		Name = "Only Skywars",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local FastDrop = {Enabled = false}
	FastDrop = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "FastDrop",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						if entityLibrary.isAlive and (not store.localInventory.opened) and (inputService:IsKeyDown(Enum.KeyCode.Q) or inputService:IsKeyDown(Enum.KeyCode.Backspace)) and inputService:GetFocusedTextBox() == nil then
							task.spawn(bedwars.DropItem)
						end
					until (not FastDrop.Enabled)
				end)
			end
		end,
		HoverText = "Drops items fast when you hold Q"
	})
end)

run(function()
	local MissileTP = {Enabled = false}
	local MissileTeleportDelaySlider = {Value = 30}
	MissileTP = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "MissileTP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if getItem("guided_missile") then
						local plr = EntityNearMouse(1000)
						if plr then
							local projectile = bedwars.RuntimeLib.await(bedwars.GuidedProjectileController.fireGuidedProjectile:CallServerAsync("guided_missile"))
							if projectile then
								local projectilemodel = projectile.model
								if not projectilemodel.PrimaryPart then
									projectilemodel:GetPropertyChangedSignal("PrimaryPart"):Wait()
								end;
								local bodyforce = Instance.new("BodyForce")
								bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
								bodyforce.Name = "AntiGravity"
								bodyforce.Parent = projectilemodel.PrimaryPart

								repeat
									task.wait()
									if projectile.model then
										if plr then
											projectile.model:SetPrimaryPartCFrame(CFrame.new(plr.RootPart.CFrame.p, plr.RootPart.CFrame.p + gameCamera.CFrame.lookVector))
										else
											warningNotification("MissileTP", "Player died before it could TP.", 3)
											break
										end
									end
								until projectile.model.Parent == nil
							else
								warningNotification("MissileTP", "Missile on cooldown.", 3)
							end
						else
							warningNotification("MissileTP", "Player not found.", 3)
						end
					else
						warningNotification("MissileTP", "Missile not found.", 3)
					end
				end)
				MissileTP.ToggleButton(true)
			end
		end,
		HoverText = "Spawns and teleports a missile to a player\nnear your mouse."
	})
end)

run(function()
	local PickupRangeRange = {Value = 1}
	local PickupRange = {Enabled = false}
	PickupRange = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "PickupRange",
		Function = function(callback)
			if callback then
				local pickedup = {}
				task.spawn(function()
					repeat
						local itemdrops = collectionService:GetTagged("ItemDrop")
						for i,v in pairs(itemdrops) do
							if entityLibrary.isAlive and (v:GetAttribute("ClientDropTime") and tick() - v:GetAttribute("ClientDropTime") > 2 or v:GetAttribute("ClientDropTime") == nil) then
								if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= PickupRangeRange.Value and (pickedup[v] == nil or pickedup[v] <= tick()) then
									task.spawn(function()
										pickedup[v] = tick() + 0.2
										bedwars.Client:Get(bedwars.PickupRemote):CallServerAsync({
											itemDrop = v
										}):andThen(function(suc)
											if suc then
												bedwars.SoundManager:playSound(bedwars.SoundList.PICKUP_ITEM_DROP)
											end
										end)
									end)
								end
							end
						end
						task.wait()
					until (not PickupRange.Enabled)
				end)
			end
		end
	})
	PickupRangeRange = PickupRange.CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 10,
		Function = function() end,
		Default = 10
	})
end)

run(function()
	local RavenTP = {Enabled = false}
	RavenTP = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "RavenTP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if getItem("raven") then
						local plr = EntityNearMouse(1000)
						if plr then
							local projectile = bedwars.Client:Get(bedwars.SpawnRavenRemote):CallServerAsync():andThen(function(projectile)
								if projectile then
									local projectilemodel = projectile
									if not projectilemodel then
										projectilemodel:GetPropertyChangedSignal("PrimaryPart"):Wait()
									end
									local bodyforce = Instance.new("BodyForce")
									bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
									bodyforce.Name = "AntiGravity"
									bodyforce.Parent = projectilemodel.PrimaryPart

									if plr then
										projectilemodel:SetPrimaryPartCFrame(CFrame.new(plr.RootPart.CFrame.p, plr.RootPart.CFrame.p + gameCamera.CFrame.lookVector))
										task.wait(0.3)
										bedwars.RavenController:detonateRaven()
									else
										warningNotification("RavenTP", "Player died before it could TP.", 3)
									end
								else
									warningNotification("RavenTP", "Raven on cooldown.", 3)
								end
							end)
						else
							warningNotification("RavenTP", "Player not found.", 3)
						end
					else
						warningNotification("RavenTP", "Raven not found.", 3)
					end
				end)
				RavenTP.ToggleButton(true)
			end
		end,
		HoverText = "Spawns and teleports a raven to a player\nnear your mouse."
	})
end)

run(function()
	local tiered = {}
	local nexttier = {}

	for i,v in pairs(bedwars.ShopItems) do
		if type(v) == "table" then
			if v.tiered then
				tiered[v.itemType] = v.tiered
			end
			if v.nextTier then
				nexttier[v.itemType] = v.nextTier
			end
		end
	end

	GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "ShopTierBypass",
		Function = function(callback)
			if callback then
				for i,v in pairs(bedwars.ShopItems) do
					if type(v) == "table" then
						v.tiered = nil
						v.nextTier = nil
					end
				end
			else
				for i,v in pairs(bedwars.ShopItems) do
					if type(v) == "table" then
						if tiered[v.itemType] then
							v.tiered = tiered[v.itemType]
						end
						if nexttier[v.itemType] then
							v.nextTier = nexttier[v.itemType]
						end
					end
				end
			end
		end,
		HoverText = "Allows you to access tiered items early."
	})
end)

local lagbackedaftertouch = false
run(function()
	local AntiVoidPart
	local AntiVoidConnection
	local AntiVoidMode = {Value = "Normal"}
	local AntiVoidMoveMode = {Value = "Normal"}
	local AntiVoid = {Enabled = false}
	local AntiVoidTransparent = {Value = 50}
	local AntiVoidColor = {Hue = 1, Sat = 1, Value = 0.55}
	local lastvalidpos

	local function closestpos(block)
		local startpos = block.Position - (block.Size / 2) + Vector3.new(1.5, 1.5, 1.5)
		local endpos = block.Position + (block.Size / 2) - Vector3.new(1.5, 1.5, 1.5)
		local newpos = block.Position + (entityLibrary.character.HumanoidRootPart.Position - block.Position)
		return Vector3.new(math.clamp(newpos.X, startpos.X, endpos.X), endpos.Y + 3, math.clamp(newpos.Z, startpos.Z, endpos.Z))
	end

	local function getclosesttop(newmag)
		local closest, closestmag = nil, newmag * 3
		if entityLibrary.isAlive then
			local tops = {}
			for i,v in pairs(store.blocks) do
				local close = getScaffold(closestpos(v), false)
				if getPlacedBlock(close) then continue end
				if close.Y < entityLibrary.character.HumanoidRootPart.Position.Y then continue end
				if (close - entityLibrary.character.HumanoidRootPart.Position).magnitude <= newmag * 3 then
					table.insert(tops, close)
				end
			end
			for i,v in pairs(tops) do
				local mag = (v - entityLibrary.character.HumanoidRootPart.Position).magnitude
				if mag <= closestmag then
					closest = v
					closestmag = mag
				end
			end
		end
		return closest
	end

	local antivoidypos = 0
	local antivoiding = false
	AntiVoid = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "AntiVoid",
		Function = function(callback)
			if callback then
				task.spawn(function()
					AntiVoidPart = Instance.new("Part")
					AntiVoidPart.CanCollide = AntiVoidMode.Value == "Collide"
					AntiVoidPart.Size = Vector3.new(10000, 1, 10000)
					AntiVoidPart.Anchored = true
					AntiVoidPart.Material = Enum.Material.Neon
					AntiVoidPart.Color = Color3.fromHSV(AntiVoidColor.Hue, AntiVoidColor.Sat, AntiVoidColor.Value)
					AntiVoidPart.Transparency = 1 - (AntiVoidTransparent.Value / 100)
					AntiVoidPart.Position = Vector3.new(0, antivoidypos, 0)
					AntiVoidPart.Parent = workspace
					if AntiVoidMoveMode.Value == "Classic" and antivoidypos == 0 then
						AntiVoidPart.Parent = nil
					end
					AntiVoidConnection = AntiVoidPart.Touched:Connect(function(touchedpart)
						if touchedpart.Parent == lplr.Character and entityLibrary.isAlive then
							if (not antivoiding) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) and entityLibrary.character.Humanoid.Health > 0 and AntiVoidMode.Value ~= "Collide" then
								if AntiVoidMode.Value == "Velocity" then
									entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 100, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								else
									antivoiding = true
									local pos = getclosesttop(1000)
									if pos then
										local lastTeleport = lplr:GetAttribute("LastTeleported")
										RunLoops:BindToHeartbeat("AntiVoid", function(dt)
											if entityLibrary.isAlive and entityLibrary.character.Humanoid.Health > 0 and isnetworkowner(entityLibrary.character.HumanoidRootPart) and (entityLibrary.character.HumanoidRootPart.Position - pos).Magnitude > 1 and AntiVoid.Enabled and lplr:GetAttribute("LastTeleported") == lastTeleport then
												local hori1 = Vector3.new(entityLibrary.character.HumanoidRootPart.Position.X, 0, entityLibrary.character.HumanoidRootPart.Position.Z)
												local hori2 = Vector3.new(pos.X, 0, pos.Z)
												local newpos = (hori2 - hori1).Unit
												local realnewpos = CFrame.new(newpos == newpos and entityLibrary.character.HumanoidRootPart.CFrame.p + (newpos * ((3 + getSpeed()) * dt)) or Vector3.zero)
												entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(realnewpos.p.X, pos.Y, realnewpos.p.Z)
												antivoidvelo = newpos == newpos and newpos * 20 or Vector3.zero
												entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(antivoidvelo.X, entityLibrary.character.HumanoidRootPart.Velocity.Y, antivoidvelo.Z)
												if getPlacedBlock((entityLibrary.character.HumanoidRootPart.CFrame.p - Vector3.new(0, 1, 0)) + entityLibrary.character.HumanoidRootPart.Velocity.Unit) or getPlacedBlock(entityLibrary.character.HumanoidRootPart.CFrame.p + Vector3.new(0, 3)) then
													pos = pos + Vector3.new(0, 1, 0)
												end
											else
												RunLoops:UnbindFromHeartbeat("AntiVoid")
												antivoidvelo = nil
												antivoiding = false
											end
										end)
									else
										entityLibrary.character.HumanoidRootPart.CFrame += Vector3.new(0, 100000, 0)
										antivoiding = false
									end
								end
							end
						end
					end)
					repeat
						if entityLibrary.isAlive and AntiVoidMoveMode.Value == "Normal" then
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -1000, 0), store.blockRaycast)
							if ray or GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled or GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled then
								AntiVoidPart.Position = entityLibrary.character.HumanoidRootPart.Position - Vector3.new(0, 21, 0)
							end
						end
						task.wait()
					until (not AntiVoid.Enabled)
				end)
			else
				if AntiVoidConnection then AntiVoidConnection:Disconnect() end
				if AntiVoidPart then
					AntiVoidPart:Destroy()
				end
			end
		end,
		HoverText = "Gives you a chance to get on land (Bouncing Twice, abusing, or bad luck will lead to lagbacks)"
	})
	AntiVoidMoveMode = AntiVoid.CreateDropdown({
		Name = "Position Mode",
		Function = function(val)
			if val == "Classic" then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or not vapeInjected
					if vapeInjected and AntiVoidMoveMode.Value == "Classic" and antivoidypos == 0 and AntiVoid.Enabled then
						local lowestypos = 99999
						for i,v in pairs(store.blocks) do
							local newray = workspace:Raycast(v.Position + Vector3.new(0, 800, 0), Vector3.new(0, -1000, 0), store.blockRaycast)
							if i % 200 == 0 then
								task.wait(0.06)
							end
							if newray and newray.Position.Y <= lowestypos then
								lowestypos = newray.Position.Y
							end
						end
						antivoidypos = lowestypos - 8
					end
					if AntiVoidPart then
						AntiVoidPart.Position = Vector3.new(0, antivoidypos, 0)
						AntiVoidPart.Parent = workspace
					end
				end)
			end
		end,
		List = {"Normal", "Classic"}
	})
	AntiVoidMode = AntiVoid.CreateDropdown({
		Name = "Move Mode",
		Function = function(val)
			if AntiVoidPart then
				AntiVoidPart.CanCollide = val == "Collide"
			end
		end,
		List = {"Normal", "Collide", "Velocity"}
	})
	AntiVoidTransparent = AntiVoid.CreateSlider({
		Name = "Invisible",
		Min = 1,
		Max = 100,
		Default = 50,
		Function = function(val)
			if AntiVoidPart then
				AntiVoidPart.Transparency = 1 - (val / 100)
			end
		end,
	})
	AntiVoidColor = AntiVoid.CreateColorSlider({
		Name = "Color",
		Function = function(h, s, v)
			if AntiVoidPart then
				AntiVoidPart.Color = Color3.fromHSV(h, s, v)
			end
		end
	})
end)

run(function()
	local oldhitblock

	local AutoTool = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "AutoTool",
		Function = function(callback)
			if callback then
				oldhitblock = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
					if (GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled == false or store.matchState ~= 0) then
						local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
						if block and block.target and not block.target.blockInstance:GetAttribute("NoBreak") and not block.target.blockInstance:GetAttribute("Team"..(lplr:GetAttribute("Team") or 0).."NoBreak") then
							if switchToAndUseTool(block.target.blockInstance, true) then return end
						end
					end
					return oldhitblock(self, maid, raycastparams, ...)
				end
			else
				bedwars.BlockBreaker.hitBlock = oldhitblock
				oldhitblock = nil
			end
		end,
		HoverText = "Automatically swaps your hand to the appropriate tool."
	})
end)

run(function()
	local BedProtector = {Enabled = false}
	local bedprotector1stlayer = {
		Vector3.new(0, 3, 0),
		Vector3.new(0, 3, 3),
		Vector3.new(3, 0, 0),
		Vector3.new(3, 0, 3),
		Vector3.new(-3, 0, 0),
		Vector3.new(-3, 0, 3),
		Vector3.new(0, 0, 6),
		Vector3.new(0, 0, -3)
	}
	local bedprotector2ndlayer = {
		Vector3.new(0, 6, 0),
		Vector3.new(0, 6, 3),
		Vector3.new(0, 3, 6),
		Vector3.new(0, 3, -3),
		Vector3.new(0, 0, -6),
		Vector3.new(0, 0, 9),
		Vector3.new(3, 3, 0),
		Vector3.new(3, 3, 3),
		Vector3.new(3, 0, 6),
		Vector3.new(3, 0, -3),
		Vector3.new(6, 0, 3),
		Vector3.new(6, 0, 0),
		Vector3.new(-3, 3, 3),
		Vector3.new(-3, 3, 0),
		Vector3.new(-6, 0, 3),
		Vector3.new(-6, 0, 0),
		Vector3.new(-3, 0, 6),
		Vector3.new(-3, 0, -3),
	}

	local function getItemFromList(list)
		local selecteditem
		for i3,v3 in pairs(list) do
			local item = getItem(v3)
			if item then
				selecteditem = item
				break
			end
		end
		return selecteditem
	end

	local function placelayer(layertab, obj, selecteditems)
		for i2,v2 in pairs(layertab) do
			local selecteditem = getItemFromList(selecteditems)
			if selecteditem then
				bedwars.placeBlock(obj.Position + v2, selecteditem.itemType)
			else
				return false
			end
		end
		return true
	end

	local bedprotectorrange = {Value = 1}
	BedProtector = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "BedProtector",
		Function = function(callback)
			if callback then
				task.spawn(function()
					for i, obj in pairs(collectionService:GetTagged("bed")) do
						if entityLibrary.isAlive and obj:GetAttribute("Team"..(lplr:GetAttribute("Team") or 0).."NoBreak") and obj.Parent ~= nil then
							if (entityLibrary.character.HumanoidRootPart.Position - obj.Position).magnitude <= bedprotectorrange.Value then
								local firstlayerplaced = placelayer(bedprotector1stlayer, obj, {"obsidian", "stone_brick", "plank_oak", getWool()})
								if firstlayerplaced then
									placelayer(bedprotector2ndlayer, obj, {getWool()})
								end
							end
							break
						end
					end
					BedProtector.ToggleButton(false)
				end)
			end
		end,
		HoverText = "Automatically places a bed defense (Toggle)"
	})
	bedprotectorrange = BedProtector.CreateSlider({
		Name = "Place range",
		Min = 1,
		Max = 20,
		Function = function(val) end,
		Default = 20
	})
end)

run(function()
	local Nuker = {Enabled = false}
	local nukerrange = {Value = 1}
	local nukereffects = {Enabled = false}
	local nukeranimation = {Enabled = false}
	local nukernofly = {Enabled = false}
	local nukerlegit = {Enabled = false}
	local nukerown = {Enabled = false}
	local nukerluckyblock = {Enabled = false}
	local nukerironore = {Enabled = false}
	local nukerbeds = {Enabled = false}
	local nukercustom = {RefreshValues = function() end, ObjectList = {}}
	local luckyblocktable = {}

	Nuker = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "Nuker",
		Function = function(callback)
			if callback then
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
				table.insert(Nuker.Connections, collectionService:GetInstanceAddedSignal("block"):Connect(function(v)
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end))
				table.insert(Nuker.Connections, collectionService:GetInstanceRemovedSignal("block"):Connect(function(v)
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.remove(luckyblocktable, table.find(luckyblocktable, v))
					end
				end))
				task.spawn(function()
					repeat
						if (not nukernofly.Enabled or not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) then
							local broke = not entityLibrary.isAlive
							local tool = (not nukerlegit.Enabled) and {Name = "wood_axe"} or store.localHand.tool
							if nukerbeds.Enabled then
								for i, obj in pairs(collectionService:GetTagged("bed")) do
									if broke then break end
									if obj.Parent ~= nil then
										if obj:GetAttribute("BedShieldEndTime") then
											if obj:GetAttribute("BedShieldEndTime") > workspace:GetServerTimeNow() then continue end
										end
										if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - obj.Position).magnitude <= nukerrange.Value then
											if tool and bedwars.ItemTable[tool.Name].breakBlock and bedwars.BlockController:isBlockBreakable({blockPosition = obj.Position / 3}, lplr) then
												local res, amount = getBestBreakSide(obj.Position)
												local res2, amount2 = getBestBreakSide(obj.Position + Vector3.new(0, 0, 3))
												broke = true
												bedwars.breakBlock((amount < amount2 and obj.Position or obj.Position + Vector3.new(0, 0, 3)), nukereffects.Enabled, (amount < amount2 and res or res2), false, nukeranimation.Enabled)
												break
											end
										end
									end
								end
							end
							broke = broke and not entityLibrary.isAlive
							for i, obj in pairs(luckyblocktable) do
								if broke then break end
								if entityLibrary.isAlive then
									if obj and obj.Parent ~= nil then
										if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - obj.Position).magnitude <= nukerrange.Value and (nukerown.Enabled or obj:GetAttribute("PlacedByUserId") ~= lplr.UserId) then
											if tool and bedwars.ItemTable[tool.Name].breakBlock and bedwars.BlockController:isBlockBreakable({blockPosition = obj.Position / 3}, lplr) then
												bedwars.breakBlock(obj.Position, nukereffects.Enabled, getBestBreakSide(obj.Position), true, nukeranimation.Enabled)
												break
											end
										end
									end
								end
							end
						end
						task.wait()
					until (not Nuker.Enabled)
				end)
			else
				luckyblocktable = {}
			end
		end,
		HoverText = "Automatically destroys beds & luckyblocks around you."
	})
	nukerrange = Nuker.CreateSlider({
		Name = "Break range",
		Min = 1,
		Max = 30,
		Function = function(val) end,
		Default = 30
	})
	nukerlegit = Nuker.CreateToggle({
		Name = "Hand Check",
		Function = function() end
	})
	nukereffects = Nuker.CreateToggle({
		Name = "Show HealthBar & Effects",
		Function = function(callback)
			if not callback then
				bedwars.BlockBreaker.healthbarMaid:DoCleaning()
			end
		 end,
		Default = true
	})
	nukeranimation = Nuker.CreateToggle({
		Name = "Break Animation",
		Function = function() end
	})
	nukerown = Nuker.CreateToggle({
		Name = "Self Break",
		Function = function() end,
	})
	nukerbeds = Nuker.CreateToggle({
		Name = "Break Beds",
		Function = function(callback) end,
		Default = true
	})
	nukernofly = Nuker.CreateToggle({
		Name = "Fly Disable",
		Function = function() end
	})
	nukerluckyblock = Nuker.CreateToggle({
		Name = "Break LuckyBlocks",
		Function = function(callback)
			if callback then
				luckyblocktable = {}
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
			else
				luckyblocktable = {}
			end
		 end,
		Default = true
	})
	nukerironore = Nuker.CreateToggle({
		Name = "Break IronOre",
		Function = function(callback)
			if callback then
				luckyblocktable = {}
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
			else
				luckyblocktable = {}
			end
		end
	})
	nukercustom = Nuker.CreateTextList({
		Name = "NukerList",
		TempText = "block (tesla_trap)",
		AddFunction = function()
			luckyblocktable = {}
			for i,v in pairs(store.blocks) do
				if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) then
					table.insert(luckyblocktable, v)
				end
			end
		end
	})
end)


run(function()
	local controlmodule = require(lplr.PlayerScripts.PlayerModule).controls
	local oldmove
	local SafeWalk = {Enabled = false}
	local SafeWalkMode = {Value = "Optimized"}
	SafeWalk = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "SafeWalk",
		Function = function(callback)
			if callback then
				oldmove = controlmodule.moveFunction
				controlmodule.moveFunction = function(Self, vec, facecam)
					if entityLibrary.isAlive and (not Scaffold.Enabled) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) then
						if SafeWalkMode.Value == "Optimized" then
							local newpos = (entityLibrary.character.HumanoidRootPart.Position - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight * 2, 0))
							local ray = getPlacedBlock(newpos + Vector3.new(0, -6, 0) + vec)
							for i = 1, 50 do
								if ray then break end
								ray = getPlacedBlock(newpos + Vector3.new(0, -i * 6, 0) + vec)
							end
							local ray2 = getPlacedBlock(newpos)
							if ray == nil and ray2 then
								local ray3 = getPlacedBlock(newpos + vec) or getPlacedBlock(newpos + (vec * 1.5))
								if ray3 == nil then
									vec = Vector3.zero
								end
							end
						else
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position + vec, Vector3.new(0, -1000, 0), store.blockRaycast)
							local ray2 = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -entityLibrary.character.Humanoid.HipHeight * 2, 0), store.blockRaycast)
							if ray == nil and ray2 then
								local ray3 = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position + (vec * 1.8), Vector3.new(0, -1000, 0), store.blockRaycast)
								if ray3 == nil then
									vec = Vector3.zero
								end
							end
						end
					end
					return oldmove(Self, vec, facecam)
				end
			else
				controlmodule.moveFunction = oldmove
			end
		end,
		HoverText = "lets you not walk off because you are bad"
	})
	SafeWalkMode = SafeWalk.CreateDropdown({
		Name = "Mode",
		List = {"Optimized", "Accurate"},
		Function = function() end
	})
end)

run(function()
	local Schematica = {Enabled = false}
	local SchematicaBox = {Value = ""}
	local SchematicaTransparency = {Value = 30}
	local positions = {}
	local tempfolder
	local tempgui
	local aroundpos = {
		[1] = Vector3.new(0, 3, 0),
		[2] = Vector3.new(-3, 3, 0),
		[3] = Vector3.new(-3, -0, 0),
		[4] = Vector3.new(-3, -3, 0),
		[5] = Vector3.new(0, -3, 0),
		[6] = Vector3.new(3, -3, 0),
		[7] = Vector3.new(3, -0, 0),
		[8] = Vector3.new(3, 3, 0),
		[9] = Vector3.new(0, 3, -3),
		[10] = Vector3.new(-3, 3, -3),
		[11] = Vector3.new(-3, -0, -3),
		[12] = Vector3.new(-3, -3, -3),
		[13] = Vector3.new(0, -3, -3),
		[14] = Vector3.new(3, -3, -3),
		[15] = Vector3.new(3, -0, -3),
		[16] = Vector3.new(3, 3, -3),
		[17] = Vector3.new(0, 3, 3),
		[18] = Vector3.new(-3, 3, 3),
		[19] = Vector3.new(-3, -0, 3),
		[20] = Vector3.new(-3, -3, 3),
		[21] = Vector3.new(0, -3, 3),
		[22] = Vector3.new(3, -3, 3),
		[23] = Vector3.new(3, -0, 3),
		[24] = Vector3.new(3, 3, 3),
		[25] = Vector3.new(0, -0, 3),
		[26] = Vector3.new(0, -0, -3)
	}

	local function isNearBlock(pos)
		for i,v in pairs(aroundpos) do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end

	local function gethighlightboxatpos(pos)
		if tempfolder then
			for i,v in pairs(tempfolder:GetChildren()) do
				if v.Position == pos then
					return v
				end
			end
		end
		return nil
	end

	local function removeduplicates(tab)
		local actualpositions = {}
		for i,v in pairs(tab) do
			if table.find(actualpositions, Vector3.new(v.X, v.Y, v.Z)) == nil then
				table.insert(actualpositions, Vector3.new(v.X, v.Y, v.Z))
			else
				table.remove(tab, i)
			end
			if v.blockType == "start_block" then
				table.remove(tab, i)
			end
		end
	end

	local function rotate(tab)
		for i,v in pairs(tab) do
			local radvec, radius = entityLibrary.character.HumanoidRootPart.CFrame:ToAxisAngle()
			radius = (radius * 57.2957795)
			radius = math.round(radius / 90) * 90
			if radvec == Vector3.new(0, -1, 0) and radius == 90 then
				radius = 270
			end
			local rot = CFrame.new() * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(radius))
			local newpos = CFrame.new(0, 0, 0) * rot * CFrame.new(Vector3.new(v.X, v.Y, v.Z))
			v.X = math.round(newpos.p.X)
			v.Y = math.round(newpos.p.Y)
			v.Z = math.round(newpos.p.Z)
		end
	end

	local function getmaterials(tab)
		local materials = {}
		for i,v in pairs(tab) do
			materials[v.blockType] = (materials[v.blockType] and materials[v.blockType] + 1 or 1)
		end
		return materials
	end

	local function schemplaceblock(pos, blocktype, removefunc)
		local fail = false
		local ok = bedwars.RuntimeLib.try(function()
			bedwars.ClientDamageBlock:Get("PlaceBlock"):CallServer({
				blockType = blocktype or getWool(),
				position = bedwars.BlockController:getBlockPosition(pos)
			})
		end, function(thing)
			fail = true
		end)
		if (not fail) and bedwars.BlockController:getStore():getBlockAt(bedwars.BlockController:getBlockPosition(pos)) then
			removefunc()
		end
	end

	Schematica = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "Schematica",
		Function = function(callback)
			if callback then
				local mouseinfo = bedwars.BlockEngine:getBlockSelector():getMouseInfo(0)
				if mouseinfo and isfile(SchematicaBox.Value) then
					tempfolder = Instance.new("Folder")
					tempfolder.Parent = workspace
					local newpos = mouseinfo.placementPosition * 3
					positions = game:GetService("HttpService"):JSONDecode(readfile(SchematicaBox.Value))
					if positions.blocks == nil then
						positions = {blocks = positions}
					end
					rotate(positions.blocks)
					removeduplicates(positions.blocks)
					if positions["start_block"] == nil then
						bedwars.placeBlock(newpos)
					end
					for i2,v2 in pairs(positions.blocks) do
						local texturetxt = bedwars.ItemTable[(v2.blockType == "wool_white" and getWool() or v2.blockType)].block.greedyMesh.textures[1]
						local newerpos = (newpos + Vector3.new(v2.X, v2.Y, v2.Z))
						local block = Instance.new("Part")
						block.Position = newerpos
						block.Size = Vector3.new(3, 3, 3)
						block.CanCollide = false
						block.Transparency = (SchematicaTransparency.Value == 10 and 0 or 1)
						block.Anchored = true
						block.Parent = tempfolder
						for i3,v3 in pairs(Enum.NormalId:GetEnumItems()) do
							local texture = Instance.new("Texture")
							texture.Face = v3
							texture.Texture = texturetxt
							texture.Name = tostring(v3)
							texture.Transparency = (SchematicaTransparency.Value == 10 and 0 or (1 / SchematicaTransparency.Value))
							texture.Parent = block
						end
					end
					task.spawn(function()
						repeat
							task.wait(.1)
							if not Schematica.Enabled then break end
							for i,v in pairs(positions.blocks) do
								local newerpos = (newpos + Vector3.new(v.X, v.Y, v.Z))
								if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - newerpos).magnitude <= 30 and isNearBlock(newerpos) and bedwars.BlockController:isAllowedPlacement(lplr, getWool(), newerpos / 3, 0) then
									schemplaceblock(newerpos, (v.blockType == "wool_white" and getWool() or v.blockType), function()
										table.remove(positions.blocks, i)
										if gethighlightboxatpos(newerpos) then
											gethighlightboxatpos(newerpos):Remove()
										end
									end)
								end
							end
						until #positions.blocks == 0 or (not Schematica.Enabled)
						if Schematica.Enabled then
							Schematica.ToggleButton(false)
							warningNotification("Schematica", "Finished Placing Blocks", 4)
						end
					end)
				end
			else
				positions = {}
				if tempfolder then
					tempfolder:Remove()
				end
			end
		end,
		HoverText = "Automatically places structure at mouse position."
	})
	SchematicaBox = Schematica.CreateTextBox({
		Name = "File",
		TempText = "File (location in workspace)",
		FocusLost = function(enter)
			local suc, res = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(SchematicaBox.Value)) end)
			if tempgui then
				tempgui:Remove()
			end
			if suc then
				if res.blocks == nil then
					res = {blocks = res}
				end
				removeduplicates(res.blocks)
				tempgui = Instance.new("Frame")
				tempgui.Name = "SchematicListOfBlocks"
				tempgui.BackgroundTransparency = 1
				tempgui.LayoutOrder = 9999
				tempgui.Parent = SchematicaBox.Object.Parent
				local uilistlayoutschmatica = Instance.new("UIListLayout")
				uilistlayoutschmatica.Parent = tempgui
				uilistlayoutschmatica:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					tempgui.Size = UDim2.new(0, 220, 0, uilistlayoutschmatica.AbsoluteContentSize.Y)
				end)
				for i4,v4 in pairs(getmaterials(res.blocks)) do
					local testframe = Instance.new("Frame")
					testframe.Size = UDim2.new(0, 220, 0, 40)
					testframe.BackgroundTransparency = 1
					testframe.Parent = tempgui
					local testimage = Instance.new("ImageLabel")
					testimage.Size = UDim2.new(0, 40, 0, 40)
					testimage.Position = UDim2.new(0, 3, 0, 0)
					testimage.BackgroundTransparency = 1
					testimage.Image = bedwars.getIcon({itemType = i4}, true)
					testimage.Parent = testframe
					local testtext = Instance.new("TextLabel")
					testtext.Size = UDim2.new(1, -50, 0, 40)
					testtext.Position = UDim2.new(0, 50, 0, 0)
					testtext.TextSize = 20
					testtext.Text = v4
					testtext.Font = Enum.Font.SourceSans
					testtext.TextXAlignment = Enum.TextXAlignment.Left
					testtext.TextColor3 = Color3.new(1, 1, 1)
					testtext.BackgroundTransparency = 1
					testtext.Parent = testframe
				end
			end
		end
	})
	SchematicaTransparency = Schematica.CreateSlider({
		Name = "Transparency",
		Min = 0,
		Max = 10,
		Default = 7,
		Function = function()
			if tempfolder then
				for i2,v2 in pairs(tempfolder:GetChildren()) do
					v2.Transparency = (SchematicaTransparency.Value == 10 and 0 or 1)
					for i3,v3 in pairs(v2:GetChildren()) do
						v3.Transparency = (SchematicaTransparency.Value == 10 and 0 or (1 / SchematicaTransparency.Value))
					end
				end
			end
		end
	})
end)

run(function()
	local Disabler = {Enabled = false}
	Disabler = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "FirewallBypass",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						local item = getItemNear("scythe")
						if item and lplr.Character.HandInvItem.Value == item.tool and bedwars.CombatController then
							bedwars.Client:Get("ScytheDash"):SendToServer({direction = Vector3.new(9e9, 9e9, 9e9)})
							if entityLibrary.isAlive and entityLibrary.character.Head.Transparency ~= 0 then
								store.scythe = tick() + 1
							end
						end
					until (not Disabler.Enabled)
				end)
			end
		end,
		HoverText = "Float disabler with scythe"
	})
end)

run(function()
	store.TPString = shared.vapeoverlay or nil
	local origtpstring = store.TPString
	local Overlay = GuiLibrary.CreateCustomWindow({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		IconSize = 16
	})
	local overlayframe = Instance.new("Frame")
	overlayframe.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayframe.Size = UDim2.new(0, 200, 0, 120)
	overlayframe.Position = UDim2.new(0, 0, 0, 5)
	overlayframe.Parent = Overlay.GetCustomChildren()
	local overlayframe2 = Instance.new("Frame")
	overlayframe2.Size = UDim2.new(1, 0, 0, 10)
	overlayframe2.Position = UDim2.new(0, 0, 0, -5)
	overlayframe2.Parent = overlayframe
	local overlayframe3 = Instance.new("Frame")
	overlayframe3.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayframe3.Size = UDim2.new(1, 0, 0, 6)
	overlayframe3.Position = UDim2.new(0, 0, 0, 6)
	overlayframe3.BorderSizePixel = 0
	overlayframe3.Parent = overlayframe2
	local oldguiupdate = GuiLibrary.UpdateUI
	GuiLibrary.UpdateUI = function(h, s, v, ...)
		overlayframe2.BackgroundColor3 = Color3.fromHSV(h, s, v)
		return oldguiupdate(h, s, v, ...)
	end
	local framecorner1 = Instance.new("UICorner")
	framecorner1.CornerRadius = UDim.new(0, 5)
	framecorner1.Parent = overlayframe
	local framecorner2 = Instance.new("UICorner")
	framecorner2.CornerRadius = UDim.new(0, 5)
	framecorner2.Parent = overlayframe2
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -7, 1, -5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = Enum.Font.Arial
	label.LineHeight = 1.2
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextSize = 16
	label.Text = ""
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Position = UDim2.new(0, 7, 0, 5)
	label.Parent = overlayframe
	local OverlayFonts = {"Arial"}
	for i,v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name ~= "Arial" then
			table.insert(OverlayFonts, v.Name)
		end
	end
	local OverlayFont = Overlay.CreateDropdown({
		Name = "Font",
		List = OverlayFonts,
		Function = function(val)
			label.Font = Enum.Font[val]
		end
	})
	OverlayFont.Bypass = true
	Overlay.Bypass = true
	local overlayconnections = {}
	local oldnetworkowner
	local teleported = {}
	local teleported2 = {}
	local teleportedability = {}
	local teleportconnections = {}
	local pinglist = {}
	local fpslist = {}
	local matchstatechanged = 0
	local mapname = "Unknown"
	local overlayenabled = false

	task.spawn(function()
		pcall(function()
			mapname = workspace:WaitForChild("Map"):WaitForChild("Worlds"):GetChildren()[1].Name
			mapname = string.gsub(string.split(mapname, "_")[2] or mapname, "-", "") or "Blank"
		end)
	end)

	local function didpingspike()
		local currentpingcheck = pinglist[1] or math.floor(tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue()))
		for i,v in pairs(pinglist) do
			if v ~= currentpingcheck and math.abs(v - currentpingcheck) >= 100 then
				return currentpingcheck.." => "..v.." ping"
			else
				currentpingcheck = v
			end
		end
		return nil
	end

	local function notlasso()
		for i,v in pairs(collectionService:GetTagged("LassoHooked")) do
			if v == lplr.Character then
				return false
			end
		end
		return true
	end
	local matchstatetick = tick()

	GuiLibrary.ObjectsThatCanBeSaved.GUIWindow.Api.CreateCustomToggle({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		Function = function(callback)
			overlayenabled = callback
			Overlay.SetVisible(callback)
			if callback then
				table.insert(overlayconnections, bedwars.Client:OnEvent("ProjectileImpact", function(p3)
					if not vapeInjected then return end
					if p3.projectile == "telepearl" then
						teleported[p3.shooterPlayer] = true
					elseif p3.projectile == "swap_ball" then
						if p3.hitEntity then
							teleported[p3.shooterPlayer] = true
							local plr = playersService:GetPlayerFromCharacter(p3.hitEntity)
							if plr then teleported[plr] = true end
						end
					end
				end))

				table.insert(overlayconnections, replicatedStorage["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"].abilityUsed.OnClientEvent:Connect(function(char, ability)
					if ability == "recall" or ability == "hatter_teleport" or ability == "spirit_assassin_teleport" or ability == "hannah_execute" then
						local plr = playersService:GetPlayerFromCharacter(char)
						if plr then
							teleportedability[plr] = tick() + (ability == "recall" and 12 or 1)
						end
					end
				end))

				table.insert(overlayconnections, vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if bedTable.player.UserId == lplr.UserId then
						store.statistics.beds = store.statistics.beds + 1
					end
				end))

				local victorysaid = false
				table.insert(overlayconnections, vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					local myTeam = bedwars.ClientStoreHandler:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						victorysaid = true
					end
				end))

				table.insert(overlayconnections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed ~= lplr and killer == lplr then
							store.statistics.kills = store.statistics.kills + 1
						end
					end
				end))

				task.spawn(function()
					repeat
						local ping = math.floor(tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue()))
						if #pinglist >= 10 then
							table.remove(pinglist, 1)
						end
						table.insert(pinglist, ping)
						task.wait(1)
						if store.matchState ~= matchstatechanged then
							if store.matchState == 1 then
								matchstatetick = tick() + 3
							end
							matchstatechanged = store.matchState
						end
						if not store.TPString then
							store.TPString = tick().."/"..store.statistics.kills.."/"..store.statistics.beds.."/"..(victorysaid and 1 or 0).."/"..(1).."/"..(0).."/"..(0).."/"..(0)
							origtpstring = store.TPString
						end
						if entityLibrary.isAlive and (not oldcloneroot) then
							local newnetworkowner = isnetworkowner(entityLibrary.character.HumanoidRootPart)
							if oldnetworkowner ~= nil and oldnetworkowner ~= newnetworkowner and newnetworkowner == false and notlasso() then
								local respawnflag = math.abs(lplr:GetAttribute("SpawnTime") - lplr:GetAttribute("LastTeleported")) > 3
								if (not teleported[lplr]) and respawnflag then
									task.delay(1, function()
										local falseflag = didpingspike()
										if not falseflag then
											store.statistics.lagbacks = store.statistics.lagbacks + 1
										end
									end)
								end
							end
							oldnetworkowner = newnetworkowner
						else
							oldnetworkowner = nil
						end
						teleported[lplr] = nil
						for i, v in pairs(entityLibrary.entityList) do
							if teleportconnections[v.Player.Name.."1"] then continue end
							teleportconnections[v.Player.Name.."1"] = v.Player:GetAttributeChangedSignal("LastTeleported"):Connect(function()
								if not vapeInjected then return end
								for i = 1, 15 do
									task.wait(0.1)
									if teleported[v.Player] or teleported2[v.Player] or matchstatetick > tick() or math.abs(v.Player:GetAttribute("SpawnTime") - v.Player:GetAttribute("LastTeleported")) < 3 or (teleportedability[v.Player] or tick() - 1) > tick() then break end
								end
								if v.Player ~= nil and (not v.Player.Neutral) and teleported[v.Player] == nil and teleported2[v.Player] == nil and (teleportedability[v.Player] or tick() - 1) < tick() and math.abs(v.Player:GetAttribute("SpawnTime") - v.Player:GetAttribute("LastTeleported")) > 3 and matchstatetick <= tick() then
									store.statistics.universalLagbacks = store.statistics.universalLagbacks + 1
									vapeEvents.LagbackEvent:Fire(v.Player)
								end
								teleported[v.Player] = nil
							end)
							teleportconnections[v.Player.Name.."2"] = v.Player:GetAttributeChangedSignal("PlayerConnected"):Connect(function()
								teleported2[v.Player] = true
								task.delay(5, function()
									teleported2[v.Player] = nil
								end)
							end)
						end
						local splitted = origtpstring:split("/")
						label.Text = "Session Info\nTime Played : "..os.date("!%X",math.floor(tick() - splitted[1])).."\nKills : "..(splitted[2] + store.statistics.kills).."\nBeds : "..(splitted[3] + store.statistics.beds).."\nWins : "..(splitted[4] + (victorysaid and 1 or 0)).."\nGames : "..splitted[5].."\nLagbacks : "..(splitted[6] + store.statistics.lagbacks).."\nUniversal Lagbacks : "..(splitted[7] + store.statistics.universalLagbacks).."\nReported : "..(splitted[8] + store.statistics.reported).."\nMap : "..mapname
						local textsize = textService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(9e9, 9e9))
						overlayframe.Size = UDim2.new(0, math.max(textsize.X + 19, 200), 0, (textsize.Y * 1.2) + 6)
						store.TPString = splitted[1].."/"..(splitted[2] + store.statistics.kills).."/"..(splitted[3] + store.statistics.beds).."/"..(splitted[4] + (victorysaid and 1 or 0)).."/"..(splitted[5] + 1).."/"..(splitted[6] + store.statistics.lagbacks).."/"..(splitted[7] + store.statistics.universalLagbacks).."/"..(splitted[8] + store.statistics.reported)
					until not overlayenabled
				end)
			else
				for i, v in pairs(overlayconnections) do
					if v.Disconnect then pcall(function() v:Disconnect() end) continue end
					if v.disconnect then pcall(function() v:disconnect() end) continue end
				end
				table.clear(overlayconnections)
			end
		end,
		Priority = 2
	})
end)

run(function()
	local ReachDisplay = {}
	local ReachLabel
	ReachDisplay = GuiLibrary.CreateLegitModule({
		Name = "Reach Display",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.4)
						ReachLabel.Text = store.attackReachUpdate > tick() and store.attackReach.." studs" or "0.00 studs"
					until (not ReachDisplay.Enabled)
				end)
			end
		end
	})
	ReachLabel = Instance.new("TextLabel")
	ReachLabel.Size = UDim2.new(0, 100, 0, 41)
	ReachLabel.BackgroundTransparency = 0.5
	ReachLabel.TextSize = 15
	ReachLabel.Font = Enum.Font.Gotham
	ReachLabel.Text = "0.00 studs"
	ReachLabel.TextColor3 = Color3.new(1, 1, 1)
	ReachLabel.BackgroundColor3 = Color3.new()
	ReachLabel.Parent = ReachDisplay.GetCustomChildren()
	local ReachCorner = Instance.new("UICorner")
	ReachCorner.CornerRadius = UDim.new(0, 4)
	ReachCorner.Parent = ReachLabel
end)

task.spawn(function()
	repeat task.wait() until shared.VapeFullyLoaded
	if not AutoLeave.Enabled then
		AutoLeave.ToggleButton(false)
	end
end)

-- obfuscated by viper.devv

return(function(i,a,l,U,I,z,B,G,C,r,j,J,Z,H,T,A,n,x,w,e,g,D,M,c,v,E,t,d,f,K,X)K=({});local p,_,S=0B110__100;while true do if p==52 then _=unpack;if not K[25019]then p=0X1ac454E8+(w.j((w.L((w.f(X[0x8])))),X[0B1],X[0X4])-X[0B10]);K[25019]=p;else p=K[0X61bb];end;else if p==0B11 then S={};break;end;end;end;local Y,W,Q;p=120;repeat if p>0X77 then Y=9.007199254740992E15;if not not K[27614]then p=K[27614];else p=-0x24ABfF99+w.j((w.L((w.n((w.v(X[8],K[0X0061Bb])))))),X[0b1001],X[0X4]);K[0X6BDE]=(p);end;continue;elseif p<119 then Q=(1);break;else if not(p<0X78 and p>0X6a)then else W=tostring;if not not K[24997]then p=K[24997];else p=(0X2A+w.j(w.v(X[0X2]-X[0x6],K[0X61b_b])-X[3],K[0X6bDE],X[0B101]));(K)[0X61a5]=p;end;continue;end;end;until false;local N,F,u;p=(0x24);while true do if p==0X24 then if not not K[0X2_6c0]then p=(K[9920]);else(K)[27423]=(-3553285024+(w.n((w.n((w.L(X[0X9])))))+X[0x6]));p=-0x64eC099E+w.L((X[0x001_]+X[0x6]==K[0X6bdE]and K[24997]or K[0x61A5])-X[0X4]);K[0X26c0]=(p);end;elseif p==0x33 then N=({});if not K[0X3dF__2]then K[0X4a9]=(-4028733122+w.L((w.v(w.E(X[0B1000],K[0X61bb])-X[0B10],K[25019]))));p=(86+w.n((w.n(w.F(X[4])-K[0X61B_b]))));K[0X03dF2__]=(p);else p=(K[15858]);end;elseif p==0B1110110 then F=(g.bxor);if not not K[1524]then p=(K[0X5F4]);else p=(-3569268853+w.i((w.i(w.L(X[0X9__])+p,K[0X61Bb])),K[0X61BB]));K[0X5F4]=p;end;elseif p==0X5d then if not K[30915]then p=-0x1c+(w.f(w.L(K[24997])-X[0B10_01])+K[9920]);(K)[30915]=p;else p=K[30915];end;continue;else if p==24 then u=w.V;break;end;end;end;local b=(w.Q);local L=setfenv;local function O(l,I,z)local G,C=100;while true do if G<0X73 then G=(0B1__1100_11);if not(z>l)then else return;end;continue;else if G>0x64 then C=l-z+U;break;end;end;end;if C>=8 then return I[z],I[z+0X1],I[z+i],I[z+0B011],I[z+0B100],I[z+0X5],I[z+0b110],I[z+0x007],O(l,I,z+8);elseif C>=a then return I[z],I[z+0X1],I[z+2],I[z+0X3],I[z+0X4],I[z+5],I[z+B],O(l,I,z+0B11__1);elseif C>=0B110 then return I[z],I[z+1],I[z+i],I[z+0b11],I[z+0B100],I[z+Z],O(l,I,z+0X6);elseif C>=0X005 then return I[z],I[z+1],I[z+2],I[z+3],I[z+4],O(l,I,z+Z);elseif C>=0x4 then return I[z],I[z+0X1],I[z+i],I[z+0B11],O(l,I,z+0B100);else if C>=0x3 then return I[z],I[z+0x1],I[z+2],O(l,I,z+3);else if not(C>=0B10)then return I[z],O(l,I,z+0B01);else return I[z],I[z+0X1],O(l,I,z+2);end;end;end;end;local a,B,Z,k;p=0X5A;repeat if p==0B1011010 then B=(function(i,a,l)for U=0B1__111__,143,29 do if U==73 then if a-l+0X001>0X1F3d then return O(a,i,l);else return _(i,l,a);end;break;else if U==0XF then l=l or 0X1;continue;else if U~=0X2C then else a=(a or#i);end;end;end;end;end);if not not K[0X4746]then p=(K[0X4746]);else(K)[30189]=-4002540270+((X[0X4]-K[0X61Bb]-X[0B11]>K[0X7__8c3]and p or X[0B11])+K[0X3Df2]);(K)[0X5e68]=33+w.n((w.n(X[0B110])<=X[0X1]and K[9920]or p)>p and X[0x9]or p);p=-3792260849+w.E((X[0X2__]>=K[24997]and K[1193]or K[27423])-K[0X5F4]<=K[0X78c3]and X[5]or K[9920],K[30915]);(K)[0x4746]=(p);end;continue;else if p==0B001110001 then Z=E.gsub;if not not K[11943]then p=K[0X2Ea7];else p=-0x3C00dA63+w.U(w.i((w.U(K[27423],K[30915])),K[30915])+K[0X6b1F__],X[0x1],K[9920]);(K)[0X2eA7]=(p);end;continue;else if p==0B11100 then k={[0x2]=nil,[0B110__]=j,[0B1000]=nil,[l]=9,[v]=0B11__0,[D]=nil,[0B1]=nil,[8]=0X8,[0x4]=nil,[0X2]=nil,[0X6]=0X7,[0X8]=0x4,[0B10]=0X007,[1]=0B0,[0X4]=0X1,[9]=0B11};break;end;end;end;until false;local _,O=getfenv,(4.503599627370496E15);l=nil;local V,y,P;p=(0x1E);repeat if p==0x1e then if not K[0X5bdA__]then K[31089]=-0B11111+((X[0x5]>X[0X8]and X[0b10]or K[18246])-K[0X78__c3]+X[0X6]-X[6]);(K)[0X241c]=-0X3242C92A+w.L(w.F(K[0X4746]-K[27614])>=X[4]and X[8]or K[27423]);p=(-0X189D1d92+w.i(w.U(K[24997])-K[25019]-X[0x5],K[0X78C3]));K[0X5bDA]=p;else p=K[0X5bda];end;else if p~=0X65 then if p==0B0 then y={};for i=0,255 do(l)[i]=x(i);end;if not not K[4014]then p=(K[4014]);else p=2160191723+(w.v((w.f((w.L(X[0X3])))),K[0X61b_b])-X[7]);K[0Xfae]=(p);end;else if p==0x5f then P=(function(i)i=Z(i,'z','!\33\!!\u{21}');return Z(i,'\x2E\x2E\z  \46\x2E\u{002E}',b({},{__index=function(i,a)local l,U,I,z,B=C(a,0B1__,0X5);local G=(B-0x2__1+(z-0X21)*0X55+(I-0B1000__01)*7225+(U-0X21)*614125+(l-0B1000__01)*52200625);z=M(">\0734",G);(i)[a]=(z);return z;end}));end)(u("LPH)X+:HTK`D)Q!$K)=5X#NkDdd0tFE2)5B0HK.Bll-d4pt_)D.RftFCAWpAVC*a!!(pdk!2*7F*)G:DJ)-6+?fp8?Yjh<z!!\"i@K`D)Q!+7&;5X#<\\BOPq8!!&\\%P9]!O4odbOB4Z0sASu[Fzz+9@\"AJ,fQKs#pX)F_tT!EeOJnz0LJ#-FCAWpAKY@\\z!!#1i?XInnF*)G:DJ+Y'!.^T#[,aN,z!!!!aK`D)Q!!!!Z5X#HcF`(]2Bl@lQ#%qd]FCSuJ!CVVAzpl@[(!HgR1F(K0!@s!D)!!\"\\j!,t4f!\\Q]$\"D2@cA0?F'z!!\",Iz!!!!_#BOHuAn>k'4pkY(DIn$+DId='+EIM_z!'UU-@<Zd(F?Tk8?Ys^l5&_WbATW'8DBO\"3FCo*%FspsFDI[d&Df-sU/hSRqEb0?8Ec*!GF!rXn/h%oSDIb:@F(KH1ATV@&@:F%a.!m(@+sh:S>p)9Q/hSb!I4QLf+CAJiDId='+?^i[ATVNqDK[EV/hSb*.3O$f.3LeZ?XIMbA7^\">zJ<@r=K`D)Q!8o-k5Tg./z!!%]Qzr1?4s'`\\46zK`D)Q!!!!15X#?g@<?!m4p55\"AT9m=@W-1$ARTI?%!-!%D.RftFCAWpAKV0Wz!!#1eBl8!'EcdcO4pYM&@rH6p@<=[=FDl&>D.7's54fQs+<VdL+<VdL/M112$47mu+<VdL+<VdL+<VdL+<VdL+<VdL+<VdZ5U@g3.P*2)/hSb//g)8Z+<VdZ/hS\\+.PE1p,pklB/d`^D+<VdL+<VdL+<VdL+<VdL+<VdT.NfiV/2&Cr,palb5X7S\"-7(&g0/\"t3-n$Jg,:+QZ,:Frn.Olu#/g)8Z+<W3g0.8/\"$6UH6+<VdL+<VdL+<VdL+<VdL0.J(s,sX^\\5X7S\"5U@s(+>,&h5X7R]-71&d-9sg]5X7R],:G#m/hSb//hSb/.O@>F5U\\6-+=n`i$6UH6+<VdL+<VdL+<VdL+<W-e+>,!+5X7S\"5X6eA+=JNe+<VdV-mg9+5X7S\"-7(&i/1r%f+<VdL+<VdL+<VdZ/1N%m,q(6.5UIs'+=\\oL+<VdL+<VdL+<VdL+<VdL,:jrj5X7S\"5X6eA.OHPd/1)\\s/hAY#,pjs(5X6YE-9sg]5X7S\"5X7S\"5U.a0/hSb//hAY&5X7S\"5X7S\"-m1,g$6UH6+<VdL+<VdL+<VdL,9S*R5X7S\"5UnEP,p4fb,q^i!/1rJ,.P*5+.P*2'0.8;85X7S\"5X7S\"5X7R\\5X7S\"5X7S\"5U.m+5X7S\"5X6YK+=.@;+<VdL+<VdL+<VdL+>4i[-9sg]5X7S\"5U[pD,9SH_-7U?-5X7RZ0.&qL5X6tK,q^_p5X7S\"5X7R\\00hcL-nHJ`/1`>)/hS7h.O@>F5U.C$$6UH6+<VdL+<VdL+<r!O/g`hK5X7S\"5X7S\"5V+<3,sX^\\5X6PH+<VdL/1*VI,=\"L@.Ng>j5X7S\"5UJ$7,=\"LZ5VFHL5U@gD5X6YE0.\\Lu/0HSs$6UH6+<VdL+<W'c+<VdT5UIg),pklB5UJ-8+=oc&-pU$_5V+$#+<VdL+<Vmo5VFZ85UIU,5X7S\"5V+3+,sX^\\5X6_?+<VdL.R66a5X6YI,pb/d/d`^D+<VdL+<W<[+<rNj,=\"LZ-6jol0-`_I5VF6+5X7R]5X7R_/g)8Z+=nj)5U\\670.J(e,sX^F+<VdQ5X7S\"5X6V<+<VdL+<W't5UIm//hSb&-8#WJ+<VdL+<VdL0/\"tD5UJ$)+=JR%5U.g&+<W=&0-Deq-9sg]5U.U@5U@X$-n$B,-7U,k5X7S\"5X6YK+<s-:5U.U@5X6YB,sX^\\5X7R]/2&D$5VF>h+<VdL+<VdL,pb/j5U.C(-9sg],9SX)5X7R\\-9sg]-8-to+<W3g-n$_u/0H&f0.&qL5X7S\"5X7S\"/1Mtp/h\\M95U.a*5X7R_,:G/s/hS\\%,:Yr3$6UH6+<VdL+@%5*-70if-9sg]-7U,\\+<W<a5X7S\"5X7S\"5X7S\"5X7S\"-9sg@0.8,35X7S\"5X7S\"5UJ$)+=KK?5X7S\"5X7S\"5X6tR5X7S\"5U.m..LI:@+<VdL+<W!X/0uSb/g`%j+<Vd[5X7R_/g)8f-pU$_5X6YL-nd5,0-_kf0.&qL5X7S\"5X7S\"5X7S\"5U[`t/1*VI5X7S\"5X6YI+=KK?-7UZ6-nboM+<VdL+<VdZ,q:-)-m10.5X7R_+=]WA5X7S\"0-DA[+<W-[5X7S\"5X7R]/hB77+=n`g+>,!+5X7S\"5U.C(,:Xud0.\\>55X7Ra+<VdV5X6YL.OHVP+<VdL+<VdL+>+uo/gEVH5X7S\"5V+$#+=\\^'5UA$6-9sgC-nHJ`+<W3`,sWb'5X7S\"5X7S\"5U\\67/0H&g5X7S\"5X7S\"5UJ$)+<VdL+=09<5X6qS$6UH6+<VdL+@%D!/gWbJ5X7S\"5X6_?+<VdL+<W9Z+<W't5X7S\"5X7R_+<VdL+<VdZ.OZSi5X7S\"5X7S\"5X7S\"-7CDf+>,<\".R5:&+<W=&5U@O*0+&gE+<VdL+<VdL5Umm/-9sg]5X7R]/g)8Z+<VdL+<VdL+<W9i-9sg].P<&55X7S\"5X6YI+=nul/1r%f+<W9f.OZVl/gWbJ,9S9t.Nfib5X6V</0bKE+<VdL+<VdL+<VdR/0HT25X7S\"5Umm!+<VdL+<VdL+<VdL+<VdL+<W9]5X7S\"5X7S\".P<#45X7S\"-nIVK5X7S\"-6Oic-nZVb+<VdL/g`h0+=n`E+<VdL+<VdL+<VdL+<W<[.R66a5X6P:+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vsq-8$ho$6UH6+<VdL+<VdL+<VdT-m1,h5X7S\".NfiV+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdO5UJ*7,75P9+<VdL+<VdL+<VdL+>+un+=nj)5X6kC+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL-pT+3/0bKE+<VdL+<VdL+<VdL+<VdL+<rK]/gWbJ.NgB05VF6&+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+>5u,/hACX+<VdL+<VdL+<VdL+<VdL+<VdL/h\\=i,=!P-+=09\"/1`\"s+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<W=&5V+N@$6UH6+<VdL+<VdL+<VdL+<VdL+<VdV-m0WW5UA$*/g)Q-5X7S\",qgel+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vd[5X6kQ.LI:@+<VdL+<VdL+<VdL+<VdL+<VdL+<W<j+<Vsq-7g8h5X7S\"5X7S\"-m0p',qgkn+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL,=\"LF+=IR>+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<r?Y/g`hK,;()e5X7S\"-8$c55X7S\"5X7R\\/g)Vs/g)8Z+<VdL+<VdL+<VdL+<VdV/hSG\"/g`hK/0HSQ+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL5Umm/,sX^\\,qL/i0-Dl45X7S\"5X7S\"5V+N65X7S\"5U@O*-9sg].Nfs$-8$nt5Un<7+=09<-8$Dj$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL0-DAe-9sg]5U@s(+<W-^-9sg]5UJ*+,=\"LZ5X6eA,=\"LZ,p4U$5Umm-/g)8Z00hcf5Umm)$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Woo/g)bk5X7S\"5X6YE/1r%f+<VdL+<VdL+<VdL+<VdL+<VdL/hAJ#,pklB5X7R]/hSOZ+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+=8Kh+<VdZ0-rkK5X7S\"5X7S\"5X7S\"5X7S\"5X7S\"5X7S\"5X7S\"5X7S\"-nZVj-jh(>+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL/0cet/g)8Z+<VdL/hS\\+/1`>'/1`D+/hS7h+<VdL+<VdL/2&4T$6UH6+<VdL+C/8)/IDh-+<VdL+<Vdj#t[[#=$g^uAo9d:AoD^,@<@2'!'h%6[cp(A\"_D^pDfRC_z!!#h\\+9VZEz!'UU3E+<<mC`j8hz!!#1d?XIbjG<Q:SDf^#@Bl7QI\"^bVXF^g%)z!'`_4\"Cc7eFG0\\pz8O,HC?XI5PA;(!`!%kp=lp6=*z!:W3:\"*8To+:eGPz!'UX(Ec6&.FCdW>?XIYmCd&&5Df0&nFG0\\pz0L.f03[c:b.k+[`%16A`\"TSN&z+O'ldz!'UO'AU&;\\!AQb=C4uWfz+@&*nD..O\"4p5>>DfS#E@UX.b+;Y\"Xz!'UT\\F`Lo0BU\\uc$tj-nD.RftFCAWpANg60F*1rGz!!)LRK`D)Q!!!!a5_T1<zn3K5A?XI>XG!6+PH#R>5Aq^3bzE'Z[7=`8G'+A?od+D#G6Bl\\-0D.RU,+CoD%F!,@=F<GXIE,]`9F<GC<@:UL!EZf1:@:XG$EbTE(/0K%JATD?oDfTD3H#IgJ@<,p%F`(VsCh4`2D]j1DAKXZhEa`p#-Z^CX9Me8e:/>4s:f]kU<CKh6+DkOsEc3Ra!!!#@jgF/84pGA$@ps1i4pH.IE+*6lK`D)Q!!!!V5X#Bm@<Z?qF<CSaz!!%]Q!!!!aW7=.ez!!$t'4p5>?FCcR#!5k!\"s8W*A#64`(z+:/#Jz!'UR*@ps1i+9DNCz!$LX$46?MBs8P7f@rHL-FDQ7e\"E\\p.ANg3:AT0g6,9Z:Os8W-!s8P7c?XIV\\K`D)Q!!(qq5e46'&/Sn=@rld:H$asJIt7WQ!F9&FBl,t+K`Qr0ELFWD'a%P?'a%P?ecN)ZB>Xoa$V(Fr\"'>X1&./M>\"'>XA!u+NA)a4A3\"9Va.%g*LV%gtl4%g*LZ%gtl4%g*L^%gtl4_$'pC!u!1K\"18.3=9B'9'JH!X\"'>X-\"'#_s\"9Va.'/MfSXT\\f/!uD%R:CeC.!tub?\"!\\I8'?(\"T=9B3m4p016\"'>X-\"*+JW+$KcO'FFre\"Tqj/(BY@Q(BY@UT`bI\"!tPc0#7gnN1Cjj`#DiTd=9B?Q7iRQk\"'>X9,<Z,2)f,Tu!u+7n!s;X-'/FM['-fXB!ul%Y*s33I(B[;4AHQ$:(B[;4(BY@IOTYbg!uD%R:CeC.!tub?\"0DV,=9AX-2_u++4p)H[4p)H_4p)<S4Tbd24Tbd*C]adn!APZ4\"%ra0!WuO,%i[\\7',+Xnq#ge%!tunC\"2tBF=9Bcq>U/>6\"'>XA!u+Q,!WuO,',([\"-RTQ@T`YC!!s8Wa03nZ^!s8X()]o.r7fril(D@HP(Dd/f:S@gl=9B'A7gCIF=9B'Q4p)H?4p)HC4p0I>\"'>X9$V(F4!u)sj$V(HP\"Tqj/(B[;4[0$M5\"\"P$:'.YFV-aa!X=9AX-;\\tu.\"'>XA!u+ZI(L7u^!<ZF+%gtl4OTbhh!tub?!tunC\"4[JU=9B3M740T@//,u'\"'>X9!u*s5!u+*5$V(j@=:,/\\\"9Va.!s8QW'/MfS'/r)Wq#LS\"!tPc0'+Y0Z$h49#=9B'Q4p/n/\"'>X9!u(k-\"9Va.;@=WaJH5jT!tPc0#7gnN.h)S_!tub?\"5O(^=9B'9'H`/6\"'>X=-U%VG.m=%K00TJ`\"'>X=!u+Da\"Tqj/'-f[C'.5sG'.Z6K'/)NOo`G:u!ttbN#DE9_=9B3]4p(lh;]?e\\'M#8-\"'>X9!u*]1!s;X-%g*M-%gtl4i<'0a!tu><(Dd/f:CeC.\",-aX=9Ada4Tbd24Tbd*C]ba]'M$s[\"'>X9!u)[b$V(H8\"9Va.'.5sG70?Wo%g*LnW<<<*!s8X*(\\Iq6=9AX-;]?e\\'LrrA9*61:=9ApM4p(lh;\\SBr\"'>X?\"'>X*z#m[F1<EV^VEF/FT!<W^:!tPJJ!t/Bo%s7tV!s8XG!uD%R$P=1X$XEj:!uh=V(HDS\"!s]3>)bC-6!uh=V)aOR.!tPW,)_hFs!uE%C\"'#G*!s8WP)]'01'-RH[!s9K1\"\"==S!tPc^%qPiF!s]?B',(H_&PW@0\"-j5[%m?Tp'*ApR$XG_*'a%P?z!\"/f+^B#>W=9BQG=9AX-EWb2/Op5sN\"p5WK$O[>HjoZn3=9AX-(]uJp=9ApE4p(m*0c*+X=9AX@?jC*B=9AX-;\\NjI=9AZb!\\kWS\"'>XE$jm(Y8.#H!\"'>XM1^X=43!obI!<ZF+#7\"JM!tbW;!uFc@\"%`Ss\"\",T_!s:&c\"-!<`=9C&U'a^-+\"'>X-!s'p#\"'>XQ.m=&h!<ZF+E<B;Fz!!iR[^]>#L=9B-;=9AX--5VL>\"'>X-%poDL!u7d9;$0o&FTY_J&$>so(F]Gg!t2753?'[T=9B?Y>Sfs6=9B3A',)Mk=9D_C&f4gU=9B?UCT[_)\"'>X5Xo^Ts=q_M^3<N@c(DA).',LkU!Z)YX'*A=`(Dd0T$%W*Z=9AZ.!\\kL.\"'>[\"#cn4ST+1ra0c(,u=9AX-EW[*k1D:Q@,mU+E\"'>XA!u5[`!<ZF+(DBX^R/mCl!t2753>8Xu\"'>Y/'+tt<!<ZF+*<TCGz!!E;\\^B\"cG=9B!7=9AX-EWZCG(]tKT=9AX-)[c`M+:AV\\=9Fini!UU>$ig8-!!!3(#iNGu!s^[c#m493!s:Xr'*ApN%hB3R!s<QGp'?T`25LEV\"'>X*z!s2r^!T1Wm#6PYB$Nh(J!s_3r&Hc,;!s<QG!<ZF+Z3&JX\"1Jd@z!s%r-!BgNe\"$H`g!s8oV&S2&H!uD&0#71K7!so>b!s92?$_tH>\"'PdU\"'>X-Xo^<_!s`*6;$0o&!t,87*<TCG#7(Y=!s`E?2$6q_\"0M\\[',^mS!s8X*#6R\"A$P*>,\"%`Ss!s8XG\"(_R:\"0)X0%W[pDz!\"&i59PJA=^B$=s=9CPc=9AdU4p)B!=9AX-;]fiY=9BWI'F,F!4p))n=9BWI'l@Xe=9BWI'F,9r4p,3q=9AX52$4Ko'E\\^Z4p+@Y=9AX-)]Jkm4V&J6'F-2l=9AX-;]d:f=9BoQ'FS%G=9BEC=9BcM'Ft9V0H8IEJIGq^\"ZZZe!s8XG!rr<$!!%$>Qb`]j!WuO,R0!Im\"1S[)$$3NY!s<QG!u>:B\"+^IT=9AZF!AToB\"/Z,SRf\\]R\"'>X-;DI25m0!Mn!s<^S(B]6i0cL4`!\\ke-\"Tqj/!tI'#!<Yr%_Z9k\"!\\q^r\".B6ub5o-S\"'>X-L&tb8!JL[Z=9AZ\"!\\sENN<B>c!s:;5Y6+4p\"'>Yd!KR7c\\cU[g\"'>X-mK#&s!<_lp1#E!6ecK7>!N?5)=9AXH0rkBYaoX<$!s@Zf0s^ti!s;X-\"3ppTWrc]3=9AZ*!\\oT7o`PA!!s8X*$NpA0?k;)q$R$#_$=FAT%pPV,jT5Nd!s?CB1!]k&(,=8=\"24jlf)]jn=9AZJ!ASp'NWEO;;$0o&\"7cIIP67?Y\"'>X-\\cFOL!<ZpgQN=>p\"'>X-Xo^=^Ylk/2!s?CA0s^o`aoaB-!hf\\u=9AYk!AWmAh#mg^!sA5u1%t\\N\\cX\\a!S%5R=9AXX0qSN4\"Tqj/!s9AB]`J:<!s=\\f?pb%9\"#3=E!WuO,\",6h2lN%*N\"#96F\"$SI2!JLRW=9Adr$3Qt&\"'>X-g&j(1!<[X&Y5n_4@']lj!s;X-\"!TK\"!<]2\"0nTN0Oo[:m!gs&k=9E:G+V+Y^?k:Wf\"'>X-WWQW>\"6'>h'.j;g!s=Pc0hVUT0i.$9\"'>Z3!ODf2h?*kC!\\q.b\"6onA])b%s=9AZ\"\"#5Q5W<36)!s@Ze@(QKf!s;X-\"#aPF!s=,W0olFe!<ZF+\"$/0G!s@rn0tRMi.P\\[?\",[+6_ZKuC)oi$_#AaJE#;cMbp&SR9!X#\"r0uF%pScLRd!rW6(=9AZ&\"#6PQ&Hc,;\"%\"_@!u`mqklClg!s>7u0dd)\"!\\l2-$=GLhZ2ua:\"\"#`]_$'pC!s=D^1&D\"SdK)*&!X%Ea@\"SQL!s;X-\"-s$sQNI>=0q/7I$=KJ.T*(\\f>Nu:K!s;X-\"4@9Z?N[G30k1=2!\\n<i#%23KecRXF\"4@6*EruIuGKBjf=9B'E>ODQ5$R$&N!WuO,\"6KV=mfMSR\"'>X-<\\a1I=T_b.\"53f2k5tS_\"'>X-c3#e^!hfc\"=9AYk!\\qk\"i<9<c!s@*T0o#c3h>o?h!<W[:Nr`qs=9AZ2\"(7l*\"1A:dVZMt]\"'>X-^&g$Q!Z;)B!s@6X1$8S>!WuO,\"+gS/RfUn?\"'>X-q>i;qo`G:u!s9/j3s,gt5<hA:mK0'`\"'>X-p&d%A!<]V.0r\"aO:,/XI`<$-D!s;^]cN43c!AW%)\"%k<\"!X$.;1\"ua3[K82@![RqN\".92m=9AO'!!!!&$=,]\"@:Nk]Bg,+>^]B]$\"'>X5%l4Ru,BO:u$U+Xp\"\"\"B`!u)+R!u(tJ#=f;A\"'>X5!u)D#\"'>X9!u(tJ#=f;U!<ZF+$Nh(fFTY_J%g*LN$O904$Nh(^%g*Lf<<H>*$O9043<N@c$Nh(F%g*LN$O904'a%P?$Nh(RM#d]\\!t,K(!tPJJ-NsTS!t,2F(I8.*!tPJJ#7Cc,%j_<[!s8X*#@.F6\"3^qc$=&,g!s<QGz!\"KN25r-C[`rQg,!E<1;!?B2^(drAf^]CP=\"'>Z-!WuO,$Ptu/*<TCG(BY?b_#kKV'Cc,+=9B?I4p*59=9HtZm03UD%2T*\\1GJu6!tQ>7\"$$Hc!s8X<+.3-G3s.,<'H\\tE#qp]/=9AX-;_Kd?5VHgR=9C2Y'Gll4\"'>XU2a.=<\"'>XY06Jcu)at]3\"'>XY(Hqr3!s;X-1BS=90/GC;1BS==1G:%-FTY_J$SssK@09U6!uDs=!O2Y-=9BuS=9AX1.g$^u4p.JZ\"'>X-#:flY\"*+Jk!u)!V!<ZF++\"(>A.joHublIoK\"\",<`$SMSr45Bo>=9Frl\"'>XU,=aE?!<ZF+,6JV^m/[;k\"!8an,ImgW=9B'9'F+jR>n7SN'FP9b4p.V_\"'>XA!u)7X(KhEZ!WuO,$Nh(FSH8mq!s]3>$hXN&=9AX-2\\V#L\"'>X-#@@Ru!WuO,Ylb)1\"!\\m6+8Gs?=9ApM4p.&P\"'>XM$UY!uXo^=*JHH!V\"!7UZ#K[#L=9BW]#p1Ao'I+\\E1ERhD'IUEm\"'>XA!u)Qf!WuO,*u@*CeH,hT\"1\\LU.K^>#A-3bQ'H8+r'Hc-4\"'>X-Xo^=\",6JV^K`_EZ!uD%K$QT=O!uD>/\"\"==S!s9?V$`O41=9AXI,[$rE\"'>XA!u*C;(KhD4$OEF.#m493z!'k<:/C4E,g]=b_*b<1iNWF#5C;p:+!O`$=!Pe^]!X_I\\V?$h:!S@Fe!NH1O!T3u,U]Gkc!=UH@!K7%Y+uHq50TZ<-IXhHT!R:_K!F-6CE2WdIM?0FPL&lCh!FX=VCdO?eYQ<_aj8nBDe,`\\>!E'o]!T!j1!SRQT6q0q=!U'Q-l2`$=!NZ=g!B+u(!DmH'3bB_/!AY3iGb+ri`;u5,\"'>Yj\"9Va.GJ=/B!tbW;!s?:=AcojZ\"'>Z3!ODfLVZJ\"D=9Gl1Y5q4u!@\\+Q\"0V_-($Q&c\"'>Z3!<X%B!>tuA\"2P]S=9AX-2m36V\"'>Z/!LX-OZN4J:=9Gl1!u0br70?Wo8$;qW\"/>n'!BpTK\"'>Z]#6S'1\"/c/FV$#ZW\"'>Z1%Kff8\"1J;C\")S-B\"1J:5'\\<D+\"'>YX!ODf4[fNr=!u9o+_$gEJ\"0V_-'u:@d\"'>Z9$3OB4[fHRF[fX#>[fLWL!gNcg=9GH%!u-q\"WrW;:irZCb!u/cWZN1.B`r`^N!u02c]`A4;\"1J<?!Hk:A`;p'C\"1nR9'^#N\"\"&lN,[fHRFZN7N9[fLWL!qcQr=9H#5!u0&_r;d\"&!s8cY\"/Q##=9H#5ZN3Y(!ODe/(\"E\\W!WuO,ZN7N9>dFIa!<ZF+[fNr=Ff,;I!Oi(cZN7N9!u.X6N<02a\"1J<?!Hk:AklClg\"6fjh=9FH^QN9@@!N?,&=9G/r!u.L2\\H2k8\".oSr'V>Dq!M9B!RfT2a\"'>Yf#Qn02T)kD^-(=q)!K-tB\"1814=9C8[=9G`-!u/?KY5tg-Ff,;[!WuO,h$X<e\"1nR9's.f(&Hc,;ZN7B5Ff,<2!WuO,ZN1.BZN9\"d\"'>ZU$NjK5!s^=Yr;m('\"/c/%'W2#1!<X(q']BT*=9AYT*;pEH#6S'1VZGBM4p.2T\"'>X-\"\")V#\"4I9bPGeVH!s;X-[fHRFhZ<nh!G2G=!s;X-AHQ$:'2Mn0;Zd_<`<??G\"$Zl%1D;uY56D!f6Uq4m2a^(f?:P)34,j@F=9BoQ'HcuM\"'>XY!u*,Z\"Tqj/?\\8AC\"-!Hd=9B3a>ph-)'I+8A>q>\"=\"'>YL<!i`X\"9Va.6Urc'!mLiM=9Ap5'E\\jJ'F,9R'FVSW\"'>Y@!u,fp!u,t(\"Tqj/'3AI@>6>RLPm%7l!uD%R%iYTb',)<j)smb1=9D%q'L0,3\"'>YP!u.(&1OhRjm/mGm\",R,03s,QeB86NH\"9Va.*s32nm0*So\"%P^K91McYh?$=P'N5Z<>t[rq'N_[E\"'>X-!s+#TjTGZf\"()-EB4D#XCM*_`Dl!R==9C>]'J&8K\"'>X=2dJ?E\"'%G!!s;X-9*5kq7mfd>f`_I[\"'5R=?a0_9=9B4T?#Od($3Ptb\"'>Xq!u+6u!u+E$\"9Va.2ZjaIXT\\f/\"![m^)r1Su=9AX-EW`3?\"%r`k!<<H/eHQ+X!tVjA4p/Ct!u.4+XTel0!t2:54V*5N\"'>YPVZAs`UB.Cr4p0%6\"'>Z'!<X'r!VHX!=9Ar?!Bgsi\"p7s0&#TFl\"2+m@=9GT)!u-q#`<HEH!t2\"-4V-KU\"'>Z/!<X%r!Vlm$=9G<!VZAs`\"/c03\"18=8=9B);!BpUl!<X%&!g*Zh=9AZ?!G2Fn!<ZF+GJ=/B\"769p=9HkM!u7@;aThoM\"60Ca'VbaDf)]Caf)Zs^f)aV,!u.X8_$:'E!uK8a4V.Jq\"'>X-#:flecN-33b5p&m4p/%p\"'>Xif)\\&;gAqBjT**sO!u.L4Ka.]^\"5a+]']T4^#6S'1eH,hT\"3h#1%<'JpR0Eaq!s>G%AcpEc\"'>YLVZAs`eHZ1Y!s8X*K)pZ3\"'>X-\"''j4#6S'1A+9gqLB3A?\"'>X-#:foD#6S'1LB.Jk6hLZd=9J4'\"'>X-Nr^5g!eCja=9FTb!u.X6Ym:G6\".oT:$3R3f\"JZ!$\"/>l!(#9,j#Qn02aodP&+ccYb!<X%:!PJa@=9F`f!u.p>Nrb.>8!<t7!<X%B!L!Nd'Xn+(!K-tKP6'JF\"'>X-\"'(6[R0Wms\"-3I2$3QIm!u0>fQN9>Y\".K<R$3Qt-\"'>Y\\!<YgCR01tF\"'>Z-'E_G>\"5a,I\"2P9G=9I:YirM=Gr<NL-\"2=lo!BpU>#m493UBZYcB[d85Yl[KoW!h)]5ElGW!<X%J!j;X.!Hk:A`=E&Q!s>G%,hWp[%Kff8hZ;U8#/12s!P8@r\"/QM1=9GT)])`5q!T*pa!AiU6[0Zq;!s8X<lN*7cirM4DhZ3fnK)s^-hZ7$?!T==e=9CA>!BpVC!TsJI\"3h,S=9Fft\"'>X-\")$3dXUi_Y3s.:b!BpU8dfDW7nHf;\"!s?jMC\"JaTq$@.*\"3U]I'Uo3N!<X%r!JLj_=9AX1.g(b<\"'>Z?!P\\YXVZNh)\"'>X=ZN4S=[fHRFY5u*5[fLWL!mq>W=9H/9!u.d:])fMEFf,;U!<X%>!MKi&=9G`-ZN3\\%!T=@f=9AX-;m-5.!<X%6!ODg5!Hk:AaU/,P\"0V_-(!-sY'E_G>Y5n`,`=JXK\"'>Zq#Qn02GD?2_!s=;ZAcqQ1\"'>ZS!<X$g\"/-))=9HkM])b(t]aFpE\"4%\"S!Ai%&JI;Q^\"1nT;!C4s3W=&f1\"4I:s!@?%mM$jDf!uo\\i4p/Ctf)\\&;!s:L2!RCd.8(.LT$NjK5\\J53K\"02I7!=@'QOUD7n\"-WbH!Ae5L!Fn:qM$!i^\"1&\"1=7m-D'E_G>dfBOcSIbN(\"'>YX!P8A<^B*j4\"'>Z-#m493ZN5[Z8&#)l$NjK5B@d/J\"4I;*!BpSf\"#ng4@\\!T(f)_EQ\"'>Ze$j0T6!u#+X!K@Ki=9B)K!BpTa_Z;q'ZN8)I4p/Ctb5jd/!u#+X!>iKO4p/2$\"'>Z;!Q+q%\"31EE'Vb`O$j0T6[fO)A>H.^l$j0T6[fHkBb5m_6\"'>X]gAsJ?f)ab04p0UL\"'>X-\")$WpSJBl[3s,S_!@33so`>4t\"5a.:!@>>YirK5rCP<3\"=9F<Zf)]13!T*n['Q`XM\"'>ZU$0)%hhZ8]C\"'>Z7!Oi)PVZP6[\"'>Z7!<X%:!K@Nj=9H#5!u/'CKan2e\"2b-A'[m,[%Kff8_Z9iR[fXGJ_Z=nX!lk<D'[$O[\"&lr8_Z9iRVZF[9_Z=nX!m(lR=9AX-;nE'i%Kff8WrW;:^B1S>!u/WSZN1.B_ZHA<\"'>Z?!P\\YXVZN\\(\"'>Z?!<X%V!j)n6=9AZ.!\\pkZYn!Z4.K]bT2m37_!NuM[Wr_`\"\"'>Z;!Dca:km[_s\"2=j='[Hj>%0K]7!s:Kg!Vm0,=9AZ.!\\pSRd1$1[\"2b/W!Hk:A'=S!Q\"-j>u=9AZ'!@2re'*D>=!s^=YXUbM9\"1J:5'nI%+%g,o9Y5n`,1!'J!=9AX1.g)OIVZAs`h$sNh!s>G%Acq-)\"'>Z'!<X$Om1'5#\")Fq<4p(ni!\\pkZjUA$f.Kb_4!u6XpN=Q+n!s8cY\"%.tI?&o$^%Kff8aU82Q\".]Mr=9I.UdfDW7OUhOr\"4mPj$3QP(\"'>X-b5ima%%.G)=9AZO!?BJqTa([%\"*_K\\4p(o%!G2GM%g,o9JJ/,f\"02I+!AgbWVZE=u33*)='E_G>K)qSF4p-WQ\"'>Yt!<X%\"!T=Ok=9G<!!u-q\"UB(H+UB0`m\"'>X=QN95O!s9s8!<WF:QN<3SNr_<EMZEnoRfP=+!BpUZ&-H#:!s:KO!SItc=9Be;!BpV5%g,o9-^Oit\"-F,s=9AX-<KdHO&-H#:Y5n_>Y6(s?\"'>Z3!<X%B!l5EM=9GH%VZB-ekn!r!\"1J:5'WV8D!Oi)PVZP*S\"'>Z;!<X%:!P8BE!Hk:A[fO)A;7?S8!<X(a'_)_:=9GH%!u.X7\\I\\jF\"02G)'WV;7&-H#:m0Nks\"1J:5'^Gf&\"&lB(Wr]C)1TLNYXo^>]!M'n%!@e3;!Ug%pmfE\"\\!u-@gPn=+#\"7$!Z!F>9teI_mc\"7H6m'U&QS&Hc,;PnaC'\"+0bC4p16SqZ/k__ZBc<4p0%A\"'>Zs!Ug%ZpAq6*\"'>[\"!Ug%Zf)bUH!u0br\\IepG\"8;fu9*;\"&\"'>Y`!V6=tpAr)B\"'>Z;!Q+q%\"76[&=9E3N!BpVA&Hc,;!s:Ks!Q+p?']/re&Hc,;XU2lG=hb\"%'E_G>!s:L*!L4<#=9HGAdfDW7`rXcm4p0+3\"%r`u&d)5<XU1m+.Kc^P`rS@+!s:L\"!P\\ZU!BpUr&d)5<RfUh94p/h+dfDW7ob%@/\"1&$O!BpSf\"#n7$d1QO`!s:S=VZCS6!BpVQ&d)5<^B)LY4p/CtcN-33JJ&&e\".K>;!BpV/!Rh'5\"2b/k!BpUF'*D>=\"0M\\[Y5t%(\"'>ZK!S7?9\"4$uM9*<u_\"'>Z?!F,s6^B)4Q4p.>g\"'>ZO!<Yss`=`8T\".K>;!BpUB&d)5<\"/c/FV%prc\"'>X-#:fo8'*D>=[fO)A1UdAencCPX!<WF&ZN7N9VZKo)!ODg9!F2r3[fHRFdfQuZ[fLWL!ne4h=9E-4!@e0RXo^>]!R28[=9AX-;m-4]'E_G>VZ?l6P6%]b!u0JkY5n_>Y6)$2!u/cWPnX=&\"1nR9'WV8H!P8ATVZHr&2n&h\"!<X%6!P8BE!Hk:AXV1e=\"02I+!AgbWd1ZUa\"1J;,<bh:@\"'>Z#!NQ5b!s8WaVZEh!!u0Vn[1i^F\")\"M44p.>i\"'>Z]#HIl.VZBd\"=9AX1.g*To\"'>Z3!<X%F!j_p6!Hk:Aoah4-\"1J:5=1J[+!<ZF+\"/c03\".]o(=9EcF!BpV='E_G>K)rRb?,$ET!<ZEb$\\]B!=9G`-!u/'Br=f?9\"0Va/!Hk:AaUSDT\"60Ca']T5O!S7?BirP8W\"'>Yr'a%P?\"60D%SIrOL\"'>X-gAr:J'tFeV=9H#5!u12*XVCq?!s?\"5AcoFU\"'>Yr'*D>=\"2=j^R1$,4\"'>Z/!<X%6!NuO-!Hk:AbnU=_\"6g-p=9H#5!u7pEnJ)..!tVjA4p0aY\"'>Y4])b(tZN7fA4p)>)!Bgt@'a%P?f`D7X\"2=jf$3LA4<Pnj&('@Y@V%:`M.K]dU!\\r.)JJJ>i\"4%\"'!CHsC('@Y@`rQ8V])g(U\":>7O!Q+q.b5oWa!u.((b5h\\ZP6$XY\"'>X-#:foL'a%P?$bl^4_Z:Rk!BpUf(B[bA_ZA3e4p0UV\"'>XY_Z;q'])fqQ4p/t/!u.L3!s;K>!OW[F=9AX=@E/DN#m493ZN5[Z8&#)H('@Y@b5h\\ZUB:*(\"'>YLcN-33!u#+\\!LEi)!BpUZ(B[bA!s;Q<!NH18!?o&U])dNb8&#)d('@Y@;p,2*\"1&$S!BpV%('@Y@!s8SA!Q+qj!Csm*[2/pI\"1nTS!BpVQ('@Y@&'\"]7\"-jZ)=9GH%!u-+4(B[bA!s^=Y]b^cQ\"2=j='S?M\\(B[bA!s8S%!NQ5''_;C0!<X&1!j_n0'`.s@!<X&9!il@2!=?@=])f5=1V3\\4(B[bA^B(qI-+a2m!<X$O_Z9iRLB@X]!\\q^r\\J;j[.K]YN!!!!+!Y,X<^]Bu,\"'>Yr!<ZF+4Tedg3Zh6A#m493)`ecW%0K]7)m05Y+$(KA+\"7:o\"$m#k\"02rp%1\\$q!s<QG3YMdQ!L3Zf=9AX--6F<3=$79#=9BX+1(t`3'gWiB=9B@W3?MEH&g&&7#p4!d=9BWi#p06O-6G]%;A40T=9Bcm1Cn%!=9Gu4(C4$O!WuO,\"0M\\[(QAFt=9AXd0b;)%\"'>XE3Yrk?\"\"#)p!u(h>!s&W7!u(j>!<ZF+!s8Q3\"0M\\[%hf$Z#GhJ(=9B4s!uDUa#;[$Y!WuO,)ZpNgSH8mq!tuJ]\"8)Zs=9AXL0d!M!\"'>X-XogC#\".B9G,LHMo=9ApM4p0aE\"'>XE!u(tJ+$Kc/M?>RX!s;I@Xo]OT)p&*_=9AZ.!\\kYI!<ZF+(BY?Vm/[;k\"$.5(IC0+Y=9ApI4p-cG\"'>X='4_3Y!<ZF+2$6q_8HW&s_#a^@\"'#G*!rr<$!!!W7%LNaUkeI4U!<ZF+M#d]\\!s:&!blPcc\"'>X-Xo^=&>oP6q\"82gO*t\\TW!s8X*(BZ]Q)]8`[\"$7;h5<Ar]\"$$Hc!s8W+4$Nf]$NgJ35=krZ\"$Zl&SHATh\"'>X-#:(J;!s;X-h@&TY9;_mp)^L[NXTS`.\"$6T!!s8W+4+RM:=9AZ.!\\lJ;.k1W'3\\`,ep&d$&E<B;F;$SQQ\"0M\\[#7CVJ!s8W+$NmO50b8s=\"'>Xm!u)-V!<ZF+7fsG5#=goZ\"$^T(/H])W56DT)SH/gp!s8W+6_sec=9AX1.g$ps=9CVe'FP!F!BW@F'nHL!\"'>X-\"*+JG)^K^J!<ZF+7fsG-q#LS\"!s8W+5D]FD=9Adu4Tbcg-pKd07mEgO\"'>Xm!u(hB6TkMR4)>!(56:ql!WuO,3u:CO]`J:<!so'3\"$Zl%$h46\"=9Cnm'FP!F!CQ)P\"'>Xe!u)9F!WuO,!s8QW1BS<n#;\\LF\"\"S0i0*;mn1BS<n!s8Q[2Zj`r#<+dJ\"#\"Hm.i1]/.g$Ijq#UY#\"\"s`j!s8W+0;/IM=9Ade4Tbd>C]c1(7k\\-M=9C&U'F-8n'Ec;U\"'>X]!u(j:!s;X-#;\\LF\"\"S0i0*;mn1BS<n!s8Q[2Zj`rK`_EZ!s8cY\"5s7_=9AX1.g$\"Y'F,!J'FP!F!=KD?'EdG!\"'>X1%m:\"\"\"&oAn!WuO,!s8Qgm/mGm\"$Zl%$h4<$=9Cbi'FTa#\"'>X-!s(V&5@$K<\"'7(^!<ZF+!s8QG\"0M\\[,J=3^=9BWI'Eaa+\"'>X-#:fna\"9Va.\"0M\\[)l3Z>=9IL_)_(piz$3Njj3qg;h&Hc,;&Hc,;\"53c1,6J#p,6J0.\"#U0_!uD%R#6X5n0cL2s)]o.uC]adB!\\kWK\"'>Xs'.O(d\"'#j6!uhmU\"\"4Zn!u(hT\"'>X-'-qEt\"'>X=!u),O\"'>X-#:fmR\"'>X-'4q=K\"*+Ku%\\jI5OUD[A>pDoc=U,68=9AO'!!!!'!^&s;^B#bc=9BuS=9AX-EWa8kN<Ek3#m190$Q0%K!tPJJ!ttbN#6P&/'/9Sk!s\\oB!tbW;!uD%R#<;lg!s]W*!s9&s!s\\p-\"\"==S!rr<$!!%BHhnK0ok6#&nlN8gJ!t>?7!s8WPlN?_dcjE.=$j-TP!s&L+!rr<$!!!<-!XK-i^]Bi(\"'>X-\"&g.i!<ZF+\"3(Bs,6J$H)gMNf!s8X()mKDG=9AX--5QdD!\\ko;\"'>X5+$Kc9\"'>X1+$KcQ\"'>XE!u)+R+$Kc/M?>RX\"Tqj/',s+;OT>Pd!uDn4(E3Gj$T/#g!s?7<0bY3*4Vt'u\"'>X-\"&g!PRKF?B4Tedg)nlCj)cZuB!ulss(E4/01D^u4'FQJp=9A[)!AP[5\"'>X1!u(hF!u(tBXo^<g@09U6(BY?Z9`nK\"(E5.H+TkgK!s<QGa9R>-8!3qA!<ZF+z!!<61iP,C2\"'>XC\"'>XC\"'>[)$\\JRLM@KjnDZ_-b=9AX1?NUlB=9AX-EWZ:A!!!!/!0b2!`;p'C\"2t9C=9C\\g=9BKY>R(uG=9D_G;B$-M(F((*=9BKI4p*#?4p,L$=9Ap94p,L$=9F0^bR7S;$NgKO\"!8%0'-@lO\"%`Ss\"*juN\"$-f`]`Hpi\"'>X7\"'>XE'0ZLu\"'>XE%l4l%\"'>Xd#>D)tYlOr/\"\"+I?\"/,_t=9BW]>R-5h\"'>ZU!<ZF+*sXt3E<B;F=s$Wa-Q?:u=sm2q%pBc&K`M9X\"\"t0K\"+^IT=9B3Q4p(lh-5Qn'#$O&(9FYD4=9AqF('cDn=9AX5?N\\OR\"'>X-Xo^<g\"$/.M3X8?l!DNYu!s]VH=pl8R=r2HD)[QUK!rr<$!!!?84ZEWk2EsJp74^;d8Vk._AHQ$:!s^Xb$Nh(R8HW&s,6JW%OT>Pd!s8X*%hf$Z.i/:%)]Jkn03JBZ!tu2U\"+:8R!uh=V)]o.r+*@Zf!s\\oB$OHo;!tPJJ$PNUV',L`b(Gu:s!uDb*)]Jkn1T:BW=9Ad1'F/IW=9Ad1DZ`9-=9BK]/KZPH=9B3='FP]Z'GDDf'I+\\%'H7Vd=9BWe/L(oB4Tbcg.0g(['FP9N'IOb#=9B?Y>SdJY@0[#>'F+dD=9AX-EW`QT_?E!b#QOi)!!!3)+X?-a!>P]=!u1o?!s8XG!ttbN#:TaW!s8p<!s8X*%hf$Z!s]?,'+G%G!t,W0'+Y=R%g)n\\&#one$R,-Fz!\"fYiNr^RQEB5\"0$ka739_Z=';$0o&'*ApZ,m.6O'*ApR!s;I070?Wo(BY?V!s;I44Tedg#8]Q+)ZpcZ%hh):)Zpcf'*D=p\"CVC7!s8W+%g<&;!tPJJ$O7>/!uV2C!s8d8!t,2F!s]?#!t>?7\"8)d!=9BoQ'GkTg=9AXQAcm/X=9HYH\"'>XI!u)Q*!<ZF+JH>pU!s9WW\"+^IT=9AXQAcpun\"'>XQ!u)Q2!<ZF+T*<=>47`t9!u)OR04k<g!<ZF+M$*o_!s^>?\"\"s`j#;]$\\\"-EWe=9AdY4p*G?'H\\t]1D:S-!]`%M-TqP6,A[H0!u*8j!<ZF+.g$J-.k=j@'-C`e,6JW)-Nb&1_#XX?!t,34d/o^;\"'>XI!u)[Z,<c2W'5O`Pi;j$_!s93F-i!cF=9BoQ'Ggj!Acnk2\"'>ZQ!WuO,.k<D#YlY#0!uh>DM$1Wr\"'>XU!u*Df!WuO,T`G6t!s8XG\"!7VHi<#8F\"'>X9\"'<SGAHQ$:,6M#X!pp$k=9BoQ'JCg]1CMk;\"'>XU!u)RE!WuO,\"\"Rscr;m('\"1\\I8=9CVe'Jh[44p*<&4p*kK9*:F]\"'>Xe!u*QA\"9Va.+%&3o[0$M5!t.=W!tRa_\"$6TX\"472Q=9CVe9*>+p\"'>Xe!u*OE5<]0.6TtT6\"%r`I!s;X-3s-0Q%mN5[SHAsr\"!^#o!ujTk\"$6TX\"$6T!1FGCN\"#!#*\"$6TX\"2+d==9CVe'Jggq4p/b,\"'>XY!u*Dr\"9Va.1G^g+V$$m&\"$6TX\"\"-/o!s8WP4#[6U0/kgG+$0Q=1Sk0U=9C301Cq/%\"'>X]!u*DN\"9Va.,==Ws3s/+X3s-0Qh#da]\"\"QT\"\"#E;.\".98o=9B?A=+LEu\"'>Za\"9Va.\"!;+Wkl_)j\"!7UZ([V>-=9AO'!!!!*.2V8YQH\\DS^Al870hBk[d&U2^#OptB*8&L9N6B(&(6;]9pSQV..#E]Oc2l*QQn4?Z<C=nn:dG&H4DE5.IoP/'\\&[PoPkkTlH'&Po)<h%0<\"<@K%Cem&(%h!JClMm>3gEM,9Glo\"$';;E-b>EEkro4+\\tt)\\z!.DY:z!)R[NK`D)Q!!)M3^kDag!!!\"lA\\a!\"z5\\7`bz!.]=04qSqg-\\eEeaZqqYJ)-Z6@M4oZz!'jf)K`D)Q!!(B)^kDag!!!#_K><0@zTQ.b2#`,+drD1<$oS!8F!!!#'H,)TF:,.G&z!&;8Q#C&Tf5BOJGK`D)Q!!\":3^kDag!!!\"DJA<;7s8W-!s8W+Qz!!%D^K`D)Q!!!!)^kDag!!!#-TYQ6]zn:AB/z!(<*f4pWF0Xp!iN+YABJz5ZY[Sz!;rM*4p67_Nm`U]zOF+csz!'kJ<4q(l`r(VSiNuRJ)(5b9X_:i@Pz!+93MK`D)Q!!#9%^kDag!!!#_OMHPMz!0Y-Oz!!n+jK`D)Q!!#QD^kDag!!!#9TYQ6]z0Ufd\"KDtoNs8W-!K`D)Q!!!_1^kDag!!!!IM84fFzOE\\K((?=is0[l0Z>sIlH.<d3.iDV)X&Es\"Fz!.[ANK`D)Q!!%D4^chr@[m>;A?%i7Y!!!\"<Qb\\:Tzm$kd5K`D)Ps8W-!K`D)Q!!\".*^kDag!!!!MYX!mBzfRUb$!l,\"(!sDZE4t81X*R7#AU7m)BL5^u4pR4od=6Zf[Z9RufA-SjQbbFZ3^2%4,T,Jk#K`D)Q!!\"F=^cif'glQe*/oeLF@,RQ)*C_Y2M1,5soh:D,oB<XSTfs\"Z'mCNGMniF3bU,`3[h\"/m!!!\"L1u(>[&4KHGXBBni#)I@4G*U#/:5&ZJz,f#*6zFK3-1z!+:]\"K`D)Q!!#K]^kDag!!!!QE57/-zrOtONz!8*=IK`D)Q!!\"]t^`^,cs8W-!s8P7oG?]&(kH(ER!V`R&)=!0r4p6p@qXK7>zW._s?z!.\\q%+DCcSs8W-!s+LFQzF23J0z>aW;j\"UCihD#8ndzcDA=1z!+99OK`D)Q!!'*o^kDag!;'P-WBl4<zOE83$.s/MkN2]V^K8N6^NY=R4\\8'k$.u%,qSUPu\"KO,Z35U\\pZWPL]DFXZQ4K`D)Q!!!!U^`[1es8W-!s8RcQzr/ncY\"gtaNIG>t0s8W-!s8W+Qz!$I'44pN5E1PN&JbCoor!!!#(`'?Kijc[S8b(Tfq!!!#7J\\Zs>z<0P*]\"W=:O+uP&Sz\\u!2rz!+:;lK`D)Q!!$D=^kDag!!!#OO2-GLz5bu2Lz!7[p^K`D)Q!!'fe^kDag!!!!1I)(F9z,a,r,$T!cJQXa:F]Bo5DK`D)Q!!&+.^kDag!!#9'd(hgTY=)c;05+n:o.nqb:QQ]3rr<#us8W*AHiO-Gs8W-!K`D)Q!!#-Z^kDag!!!!;Ttl?^z5[M5i%eoqlQYmTa:9%bWnX\"0Jz!!#^.K`D)Q!!\"pW^chq\\@,q?'K`D)Q!!'g/^`_A2s8W-!s8RcQz^f8*5'9\\.iMmC(e@'j\\R,!Qr%L\"8Qs4plqWD$MkE$o!C[4t:!_k$MYKa[#l4%Gac'/DFOR9\\9_4R@^HO0DD5NG9afj#(MV5\\%3W/K`D)Q!!%&=^kDag!!!#_K#!'?z+0\\!o\"$uFhK`D)Q!!$i\"^kDag!!%Ph`^#4Xz:oV5o$_CIGL;4cnJk$j:K`D)Q!!%>Q5X#FP/ULm4#b6SKz5\\n/!\"ZamtM?nn9z&u!*)/\"\"0iQq]sScdq2_3]Dm)j@04,?Qp_^;8Nq%&:02!]EEJa\\8<m@Zh+KLK`D)Q!!'fA^kDag!!!#OK#!'?z+CN!=z!/R;`K`D)Q!'lCj5_T1<!!!!a?bh?q!+;Srs6i5r=oSI$s8W-!K`D)Q!!)Y\\^ci\"pj,qQZV]:BjzEn.sZz!;`HU4oodi#Um4a`P/oag`ZXss8W-!s8RcQzOEA8\\`rH)=s8W-!K`D)Q!!%P#^chguY_<&W!!!\"4KYW9Az+Cr8O#eSKT@:Bk$6\\PL?!!!!iV8.cbzd\"&ocz!#U7%K`D)Q!!%OA^ci:*>nc)eNFHB7Dms+%jFDpa!!!\"LZcYOez!.Li]K`D)Q!!%hL^`Z)Fs8W-!s8RcQz!):6m.k.1[k:G4NGUFj2FnV92o9Z.=5f8ZqL=6boTDL[q96JkrJB9f25fQA,K`D)Q!!&sL^`\\X9s8W-!s8RcQzi./Usz!&/K0+R&h)s8W-!s+LFQ!!!!QR(tm$LL&0#p#S3*:*V_TU+ku&]\"aiL%nAeuW'6YF-nW>>h@,l4-.A<q)$fNl3/%>4z6GPbh,p+!B9@ALoz3.o##z!8qq6K`D)Q!!!R^^kDag!!!!]VSIlczY]7I4z!'m/AK`D)Qd\"oR>_B8mYs8W-!s8P866\"pQ'KV.Me+9!j?DSf(oIq`_D/(hBrbN_li6\\:ZB>nABTV\"[gE31IcWK`D)Q!!\"-U^kDag!!!!cWBc.;zE/D@o#3VUm^k_uEz!\"a[rK`D)Q!!%P(^kDagzn@q-qR,S1!=Z8p<kiPWcK`D)Q!!'fV^ciVl\\Q586I+tajqDd(mG[Y<nBX>tPX3^-:4pjfL%Ho_^F2:.R+G'Ols8W-!s+LFQ!!!\"4Mnk#Hz8<puEz!)RmTK`D)Q!.b*k5Tj81s8W-!s8RcQz8:\\K>%1.FqQ;K%>hbi87hA1eFzOK$#Z*Gp65<0Y].6>dp2:[pmbJK,OXcU>\\_hD@(>PcKK<zWh[@`z!76#,K`D)Q!!(r*^kDag!!!\"lBtun;gBViQ6YA+r0E2\"Os8W-!K`D)Q!!\":>^kDag!!!\"<K#!'?z^hUZ=z!7IUW+S>^6s8W-!ruc%Ts8W-!s8RcQzY]mm:z!+_5-K`D)Q!!&+2^kDag!!!\"(P/&2Bs8W-!s8W*A7/m5ds8W-!K`D)Q!!!\"F^kDag!!!#_T\"p$[z<1gri%5E$f>*?Nb\"qK:_G%lX1z8?kF6z!(`p$K`D)Q!!)M8^cjQ>$],h]:D9$iD)^*9OVQ=G4-kW19PWYK.6]'HY!G;\"!K?e>4`W?N/\"F&]Zm)qo&MkQ+rr<#us8W*_\"db9ODMp[cl2!\"pEl_R9F*`N?z*hgA5%fP8ONWbcjW7:Hj;1/g9&/;WNC_5sEm*7]aZtLHGLH[8Q_r.d8eL-*2\"O#i<=OLK76cui?&pN!=E+u;Vph;%8q?#8&4e)JQUM\\b>zJ9KC,K`D)Q!!#iH^kDag!!!!GUVK%tM@rK0+I[uaz?td>>.si5V\\\\8NF*gKE_qa:uVeYRU:^@A3V+MkQbOXW!#Xf&\"2g/_WnBs_BZ4p;Xm9m7Br:]LIps8W-!4plO$/38$W;^M6oK`D)Q!!!RQ^kDag!!!\"fTYQ6]!!!!a/_E<P#u<La1#b:UeX_Boz,-eq;z^nK8nK`D)Q!!(r+^``UUs8W-!s8P8%A4L=Xl0eIsM$kOc1A6(VRA.Ha\\d;'`P=h'nz!\"an#K`D)Q!!%h5^kDag!!!!qV8.cbzBS!r_#H^,8!)/'>K`D)Q!!&O[^kDag!!'f!e%d(\\s8W-!s8W+Qz!'#ME4p`<r@49p:B9%I*#gSfK];k[6h1Yh/!!!#7>/5glz.$)/tz!.\\Xr4p#KLK`D)Q!!'s2^`]TTs8W-!s8RcQ!!!\"L\\C\\NMz!$H?uK`D)Q!.Y0n^`X'bs8W-!s8RcQzTQn79\"lJ73C_o8>,l>&Mb@cM/!!!\"L)qi#\\z!2tIaK`D)Q!!#96^kDag!!!#5UqhZaz_9'KHz!2?=*4s)DK%+\\Z*jSFm5\\]^Mehh+g?F31l*kqVJ&HP>Y2^kDag!!%Ol`^#4XzN0D%@\"@WWHkCim9!!!#GIDA#RE@46m96ME#iQHoTz%%tC\"#do5%DT/LFpHA^V/:Cr\\z!#V]NK`D)Q!!()t^`Z2Is8W-!s8RcQzcDeU5z!$Hd,4q\\]^N=OI\"_^8<1`lG=dT6SSO+=$pds8W-!s#qro++seq5mo^SaR@`*/1tqIIr=8:Am7Y\\4H4d^m.Er6Tr4daXmcE=km2tCz9U3CW\"sfM;)Z=H*z!1;V.K`D)Q!!(r'^kDag!!!#GL;4qsrr<#us8W+Qz!(s'&K`D)Q!!%,8^cj8%s5`:IU$EV*W)#A)%$\"0s?d?Oe7QVl\\*:7$3bZ-*5JHLL)JlZ`D`pABZzE.u)]z!,.>,K`D)Q!!!jj^kDag!!!!AI_\\,[50BCA0-u(^F!]qAIiDH:.#gD/=5&tM#Z&Ru=,DG?2kQaZa@JD7:>FWLI1h56zn9;[%z!'kP>4tNUmTc0@r'^5\"<)5\"n&dH7&uIp(Ht[HTU/KP1DOQH>o87]CD.Crf7j.PZVWzTRst5z!:YKRK`D)Qz!'UQukQE]&K`D)Q!!#8]^kDag!!!\"L?bde(rr<#us8W+QzJ2Ye?K`D)Q!!(Z-^kDag!!!\"8WPF2fzi+Tni'T`?0+k5L4pZZ\"A\"4N7k'iekaqLnnLz0YiABz0S7)oz!;r;$K`D)Q!!'a3^ci0Y>d==CAM`q]:k3#/z!'H[bK`D)Q!!(N6^`\\a=s8W-!s8RcQz(lH*m$fPrN`;c#'N-rX$4pca(mYBAkW\"&TWz!#U@(K`D)Q!!'g5^cj5K\\>=AL5$E5F%kbfJ6Qa_^=O45T3N>U)]*ut)6fdOT6H554PG6A1+GBdq!!!#U\\j1rLz^k0@Uz!3h'jK`D)Q!!%\\9^kDag!!!\"\\K><0@z6DVDNzJ1T?g4pc#n72j_j8WU8C#p\"K6mdg@gf:ms!zE,e-,%gUir/:W*G.@[0=V/*GQ4rM!o6BoFY?Y<r'\"6j)1SOdTLhc8#=hA.F\\G5qUBs8W-!K`D)Q^k;Q#6%o:=!!!!aMnk#HzFK!!/z!$Gmh+R]:0s8W-!s+LFQ!!!\",MngJ2s8W-!s8W+Qz!-\"UHK`D)Q!!()p^kDag!!!#]WPF2fzUntjj#Jfi77\"f]1K`D)Q!!!RM^kDag!!!#ON51,Izi,ZVez!76tGL!@icbfn<'^P)Xf!!!!MT>6-\\zg7lB:z!;qqoK`D)Q!!)km^kDag!!!!IJ\\Zs>z,cAG3z!&CRi+MIgTs8W-!s+LFQ!!!#?KYTb\\0\"W.S>oD)hPR3&dSj!p,INM19e+70o4hLdX6p@&83A9&ae:dl&!!!\"dL;5tZgDakB:O.G7-A;F\"!!!\"PUqhZa!!!#7=PH)pz!+:Gp4p_^--Y[5,\"-'TM!g^'Ez!#r\\gK`D)Q!!#8m^kDag!!!!1HGG47zJ9J^Ni;`iWs8W-!K`D)Q!!%,2^kDag!!!#?R)\"CUz^iR:T#Qi^>I5C>u!/1CQ!!!!AW5+)ezi+]u\\z!%aSSK`D)Q!!'fZ5_T1<!!!!=Wka;gzTVfLg$AoQk1+%of^U!&e#5J&\"V>`P?#5SHQ9#mem%#\"1R/W<Ym^1(LRKS9C+zKtrBBzZD>9iz!9g;q+Dh)Xs8W-!s+LFQ!!!\"tMSOoGz3ha?Cz!:6#eK`D)Q!!%,6^kDag!!!\"6Ttl?^zjJfqKzJEFj:K`D)Q!!'fg^ci'J)26+snEbm54qi8se\"WR8haWQLMn;:b2q=d;IY@b%!!!#;R)\"CUzUo(q]z!.]I44t>UA&0]'4pD,paqf?R%iiQKBRKi$9#:O:o\\J`6I\\[=Ze4@3I/9Pi@IK`D)Q!!!\"6^kDag!!#:;h8\"^Ez317R9z!3W$24t=L2)uNi(g_2_/^`LB&fa'XadCWF,XR.WW,4t:4,1'H$]+KNE.dLHsK`D)Q!!!Rh^kL`n'Wssb+i&d3z^mMo$#?'GdbP(#h4pAGEqY3%(z!$H0pK`D)Q!!%r!5X#\\$_;IFj-LS9Q,2*(^pk8\\Jz8&0fY!!!#7A'r(7kPkM]s8W-!K`D)Q!!#Wa^kDag!!!!@a1skD-6u?!anVN_z!\"aLm4pp!<Uj$CAp7btQ+TMH@s8W-!s+LFQ!!#:+dQfu&XrDs[d?A]W#9`L8s8W-!s8P7oB.i=P'9H0A0>hhO'&\"-K4t5mLMUN+U4bVk$&]&e5Qljebi)JT=c!$I2;[[f(ULu=JXS4VqKD>[7$Pe7,L.&hE!StN\"K`D)Q!!!Rj^kDagzCVW+8keDfOz3iToKz!'l4QK`D)Q!!!\"E^`]r_s8W-!s8RcQz!i3Uq\"B\"W'iun!ns8W-!s8P7g2H%m3f)[7Q+E7>[s8W-!s#p`Z_.\\[/;]MnlK`D)Q!!!!i^ci-dl)ORW.>&NS2`-3gzTQIt5$(G,($\\u:'V.Vt0;57NoAHjH,$o!^0\"&b1e(=M;CA[E#<qLnnL!!!#gFhi\\2z1m5Y.z!$8)S4q3Wd/T`-#ju1ub9:H6Az!*FceK`D)Q!!(fQ^kDag!!!\"L8&.;-4hn$e`E84.Xh0&p0&37HA$>'ZD\\_$07^.&iz!76S<K`D)Q!!&gd^cj;c\"sYB:\\9+d'U$1(.\"[Tqe7`iOX5K'sQeOhsD\"ko=t5=3=T&5Erc7#.Fhz!!%J`K`D)Q!!$o9^kDag!!!#3WPF2fzi,?Cp#i=>0?]>oMKK_&:D1^7MEeCuEL-RA^?esL_AeNH'8fgKO\"eY(=A7K.pVIV\"CL+=rC-TciaMY`#,zPbu6Mz!32a.K`D)Q!!'f@^chlVaZVhAz!+:St4tF8\"Lj=GDhd0:k;`b-/qNYVR@XbRsDr?1k&Q*7]JSjT3Wu@:tV4mX`rIk4O!!!#GGef\"5zd!EK]z!:Y9LK`D)Q!'o)k5Ti8is8W-!s8RcQ!!!\"LLrdAcz!18GTK`D)Q!!'f2^kDag!!!#/KYTbhqGqP>e+&lB2^s$3F\"d-KC_:h84e?&l[Y4\\]!!'etgVALCzBSsTZz!<9[HK`D)Q!.[Pa^kDag!!!\",Cqr4<Q]kKog-,]*3;#o\"4pD8\\IJ_NWK`D)Q!!!!f^ci&o6o;]Z5`BDcK`D)Q!._>t^kDag!!!!Q^;(inrr<#us8W+Qz!$GadK`D)Q!!#91^kDag!!!!ACqr4a,d+a!q-\\S+g0%fI@kDsSg?rt8p.*=9cAf[T%P>QepfH*1S^0]\\r:bmFz8;b3:z!*GK$+DCfTs8W-!s#pc_:1LU!MeONl^P)Xf!!!!YMSMCa*D+<FrVinuRoF::+NON^s8W-!ruerRs8W-!s8P86;Y4,GkGl8`m'B#<X]Kkh%$VDG8<&Z$=D&b>5ds!\"c4,#FLB<-,K2?'4K`D)Q!!(6.^chlVfjDuf-PL6'0o5tr>n`<*+X52C_%>H90\\D;a))LXTI<[X<X:d22%-ZmZ4plq$CBm\"=#WR[\\K`D)Q!!!\"X^cj;k^?^`W:^hu68W\\rG4c-[`h>o-]=.Gh1I1h3>*>1Uc7u=7l3,j0smPf3@z!'k\\BK`D)Q!!\"-p^kDag!!!#7MSMCd1;@C5)k8'Q#ul0`m.5a]z!+9BR4pPq?(K?[8r]UJ;+6r3Hz!;`\\1K`D)Q!!$?&^kDag!!!\"\\E57/-z.#>Zmz!&/N1K`D)Q!!!\"A^kDag!!!\"lI)(F9!!!!ap=d;G!e<Rjz!5PSLK`D)Q!!!\"=^kDag!!!#'IDCO:zOFb22#_&7D,kpOLC4uWf!!!#oMnk#Hz/=sX@#b6][,P@UQ7tgpCz7)4KVz^hgf?z!,S4A4tFC/e.j1Tq^Tuq5K?=MSmc%<h@`Nu$ZlQrrJ`+N-$eN,FL]@I64e0`claY7s8W-!s8RcQzntj-Uz!8qh3K`D)Q!!&[1^kDag!!!\"lMSOoGz32+-Az!.[DOK`D)Q!!\"F+^kDag!!!!1J\\Zs>z:jp-5z!&0JLK`D)Q!!!S'^chpOa^#m$5#9F%Z#_AWRr/H759QLGXh4BrNnrgpZIu9^AZL6'b5m,q)@),IZ;#HjPmXGj*h#kU/DF1T9<eX^dbhZ=,c(3`CGb/3GWsdq`8F-HDM8&j!!!\"tT\"lIarr<#us8W*_/#@XqbNQhiCccC2.5L=QB,b,i/;Id/ZL;,Cj1hats7l[>jp`K(=4@CFK`D)Q!!\"R3^kDag!!!\"LH,,+6zBRmmPz!03tmK`D)Q!!#8n^cj5@CNuiHr@`'-]L0ka@*5>=lZ/!d3e&jR.,faQTTQoh&t?uMd[+!DfcZses8W-!s8RcQz@\"?$8HN4$Fs8W-!4q+rEkHYgI';4;jFc(kQz^gb)C\"nT]uaJ4Fhz!,TG7$,SZCW`V4<J9X6]DmQ^CC-E3&V7-XjlZL+E&Doc)m-U<szJDK$HK`D)Q!!\"^!^kDag!!!#_KYTblLn:L39\\TLGs5N[F'k4XX3Q)>n<#AA_^udt1.tms'!!!#R]tf=%zR\"E*r9E+tks8W-!K`D)Q!!(Z.^kDag5d',Hf0P)jz7$PJN$2FJ#U\\QP1UM>J_z.]'q7z!*lD:K`D)Q!!!R`^kDag!!!\"*UVMQ`zJ53n6z!/o2h4q+1p96q6/l^DlR,^:GYrr<#us8W+Qz!-!(rK`D)Q!!&+;^kDag!!#:Of0DM+1tOM=m6[6`aZ^IC(#>r_b#T#OiL*N0et1!kOAKd1mY(W@!!!\",B>B3$zE-T/^.uG<D1-a26oq^nWJE?h&Y4T@GFg+k(b7L:J$4,P1p(erpeQTX(9#:a]4tA?jQ;<b6),N!3]e+]=r2X`rS>]YJ.;mnOs6\"IO#;^4,Y]$nejf->d;hY2O!!!!IKtokYb`oRjZ!t=U<J:DQ!!!!)K\"rLRrr<#us8W*_%HQ%(7P0*uMZeR:^SX0t`VBHfK`D)Q!!'f;^kDag!!!#/Lqn]Ez#_g'Jz!.[VU+OU5hs8W-!s#pXU%DhWkb<?:r\\\\]&$GM1uW\"c>JJaqddn%d8THz&:M?Jz!$I-6K`D)Q!!(qi^kDag!!%Pkb<Ua]zi.Aauz!$Hj.4pQnSZLUc6qh5\"M!!%O;dQiKdz+G.Bm%&']5#<9Ugb,d5A>(lqVz!5O9gz!*m<nz!!\"sn4q51C/'gW%&Df6#eWd+gz!/QHHK`D)Q!!\"F\"^kDag!!!#CPe\\F)s8W-!s8W+Qz!.]^;K`D)Q!!$c,^ci\")P,nD\\XJS/bWN.u5i.V.2!!!\",FMNS1zJ5O*G%ua%#SeYcK<b;F2n;q60K`D)Q!!!RN^kDag!!!!-W5+)ezJ:t]\\J,fQKs8W-!K`D)Q!.^<T5_T1<!!!#+Uqf/$_bD`0iA0$`:QI[i0FH,;-&g4F:-J6D06&<)Y\"E9W$L=?V3b`c96IENSlo+;q5]/#HD:4\\5\".;)V4pf8gkm?(mS1Um-'ZIr`/_9DZKHej%c3?gZb2B?-JV=((!!!#7I)%oW)NS-LZ[R;J#JO:R8=%3PK`D)Q!!%OU^kDagz'YoD&z5]FMmz!5N`mK`D)Q!!\"+V^ci-hi).eoS@q%q3(nr*zTYE`U$AV?tWq\"+^N\"%n'z!!$EB4t>$6TQ/NtB?!ZaM^*TdOr[7!$?d<8\\!VFp.;A<3.HSl:6P4?bh`U8eK`D)Q!!(3N5_T1<!!!#_WPF2fzd#,V&#MS^;VZ*'jK`D)Q!!\"F&^kDag!!!\"lLqn]Ez,K`7o:&b1ms8W-!K`D)Q!!'fG^kDag!!!\"LCVYW(z5_m./z!%=\\ZK`D)Q!!!jf^kDag!!!#WD88=E4drQ\\`-724VnHFN4G<b8!!!!3\\%k05DGT#V\"kC/mK`D)Q!!$ts^kDag!!!#7D8:i*z]V<2qz!5NfoK`D)Q!!'fb^kDag!!!\"XR)\"CUz!)^Nq\"ktb[_b,U_z9[UY0z!\"aduK`D)Q!!!!9^chqq]cKWaK`D)Q!!(Z+^kDag!!!!YOha-sbQHKse3_IhFiKES:G;,1I<m*r[9@-qz!$H-oK`D)Q!!(qh^kDag!!!#gSA7;q&E:=\"\">8mA-^Hq$/X0(r`=jSPz!-!J(4p$2:4q?uIP/\\A-@/0K*&\"e7'4tB\"lYX)m_(H1(`RhH3$K$F6m3[T[bVaq,E=ZKoH=k-l9<aga.lO8$C^4cOe!!!#AVndudz\\%f_4z!$I<;K`D)Q!!)M0^kDag!!!#gK#!'?z5ZtmVz!49g44tG^^qcl-(4S'JZT`1^'\\S)m60cN$+N(jf,!`[J4!\\h+sS+0a8\"\\Q;5_`eJ,rp>^KRE(K;n=)TK?;#.S%>eO9?\\O16z^i.#Bz!$H6r4pNj6?ss,.\"X##gs8W-!s8P7g96#EdlDAYK4q8@Ys.fCg:f4>tDo3BVK`D)Q!!(TC^kDag!!!#;Oha-`:BXS#+RoC1s8W-!s+LFQz4MZXNzjIs@3'EA+4s8W-!4pEHR)Qp$&K`D)Q!!)5G^ci'FH6Og1?el15K`D)Q!!%hB^kDag!!!!YUHjM5z6JK;0z!/.Gh4r,+Mjf2i's+g-IXrPSG4^Q3XG%PhCK`D)Q!!$tc^kDag!!!!mUVMQ`z?uEbD$h[p]4H!gY^%kFWK`D)Q!!$tW^kDag!!!\"LCqr4ChYZh9N=4C@dfEHmK`D)Q!!#iK^ci>jdpJ+Ts,kA9<E@E9U_AB.4rSqC'hj+qqOeP(AB9`caLSKRgLH\"2Og%7^K`D)Q!!&[2^kDag!!!!aFMNS1z'WJm%z!:7in4p[2`T*.gu<c:/>cC/OCZL;,Cj8&BC[-IiIkmK,,<SRmV+!@K\\s8W-!s8P7h^u;n*L1=K+Y_<&W!!!#7@).Hrz+Gdgez!!$HCK`D)Q!!#i@^ci(K4l9V_/'e5UK`D)Q!!&+Y^ciH`!qa$'Lgr*\\VY/jqbmuj\",j[1<z!/SP.K`D)Q!!#-\\^ci(K-cKHM4k^l0K`D)Q!!!\"L^ciBX-/\"uc<7s^0)n3@\\#X$\\OD*A6!X/?.Ilq#3Oz!$\\AWK`D)Q!!#8_^cj7oY.G\\L@!jca=^XF'/U8bumW%\"T8'DFfNPZA>/].#P;r'X*_Es1\\p()iWzi,lbgz!.\\auK`D)Q!!!\"5^ci'Ip8tb1jrsh>4p_Z>+%Ljt1/#!.z!!#:\"4q\\,;4F\"pW@t-3UF=YAjJ&1hcK`D)Q!!!!W^kDag!!!\",Gef\"5z=GFVFz!3Da,4t85cjQ3\\@lPa31:H-o7N_pBqcGKNL4!^(2m9N`9<@N!D#_l?:=([!)K`D)Q!!#Qi^kDag!!!#mWPF2fz!2[Ip.`(A(Ifpj-@%VnMrU*\"rqu>pIpo@LW^.W4e(W-:j6f!j\"&gh_O?Fq,0z!2*c94q*p&\\J_<?[Cf2IAHtCS:fk&<)DuUEH(N2N?/5]ZKV/ZokXX7g'@g>\"Xm2J[Ku91rnGIZN$N@-#oH`RnD&7m+z+G7I`z!!&J'K`D)Q!!%O7^ci/f%4BhkLIs#lpbdC^'$c/B\\[^Hgg@F7>\\*9erGH>)(z!!$*9K`D)Q!!%Oi^ciJ$&2?<1)X<Quk)?MN;\"'NJK$G*bz!0X7q4t>0.$n[p9\"&d5P=3mNB2X*fbjpKXF;saI9'nqXcc1/se+ATW@s/Kk?K`D)Q!!'6D^kDag!!!\",R)\"CU!!!!akM*e+!!!!k_uItI4pgf(U:jmO=H-=7z!(`Ek4q48?<cf2&ka6TA,(?GDz!/S6P4tFi(_aM=CPY34:M\"XIfiSZJ'C#c@'ACVIgl<IpIHFQf/i8`lVm5%7?080B+!!!\"LGJJn4!!!#7o@ZB_z!+9`\\K`D)Q!5SEX^ci?+(YTJX=iBM269^+t4]p[;K`D)Q!!!!K^ci!a)hT#$*DhFizn<1RN$/na&aT&[ZQ#.Z2s8W-!s8W*A$3'u)s8W-!K`D)Q!!\"F2^kDag!!!!a<PX:gz=H^H`#MR4KV<aJT4qDUa`U1(U!Ici)j+*h2VhG*N!!!!qI)(F9zY][`F'?^:cli0[23cb-9JYTK`,.(fZ4p]K$&G]Rc0P_fVrr<#us8W+Qz!-j14K`D)Q!!(qf^ci3a^k`uYP.k8O>(]1nK`D)Q!!%OO^kDag@(#_.mm2X-z!,fT+z!3h?rK`D)Q!'mUA^chqL4QA*]K`D)Q!!$Dh^chrC?-W*@rIk4O!!!#CT>2T9s8W-!s8W+Qz!.:<P4pbmkZht7BGOTU+z!8qb1K`D)Q!!&[@^kDag!!!!qMSOoGzkaT@O#]]qH-C51$?A/@ZzpqK!!1PSnl@su1lp)ok(s8W-!s8RcQzG,W2?%O,<oa9#n.TFNpN:V`i]z^qS=6K`D)Q!!'f\\^kDagz=MR*9hpJ9;*U''A^[DNl2'?Rl:O7M$/8p4B!5RIis6i7-c-4DUbfp\"\"K`D)Q!!(HH^cj754Rl>,nj\\m4$i6NM+-Y!7gq/hJF]Rh4^\\B:Ws(E1V`fg)r?bU2d080B+!!!#7M815ls8W-!s8W+Qz!,SIHK`D)Q!!&+6^kDag!!!#WPe_tQz3.er\"z!!%,VK`D)Q!!'.65X$aYKLlMPg5`jO@ku+Gk=ZS\\6t7h$?(M/>(GN_Qk>3eF]kAp?ZLe6FNE!B@z!3ha(4t7)8\"GP:?Mn4I1Dcc_8Y447HmU@4!gVgM4%K1EcFib:D,UdacI=n2)K`D)Q!.\\Iq^kDag!!!!IQb\\:TzcDSI3z!'k;74q()'Gd?h5?S]Tr7Y-6nzd!rhp/,rD0e`%0&C69A5#7-i++X,/QdLFc#1rYEe9kD!!3?rRMpB#Dh<PH*b4s-m)qu>fUoWqa[]j5L2#)Q8bA>[iI7WDn&:ZOt[K-8bEs8W-!s8RcQz!+3N*%3rCBkEf(p=id\\>mOEnjz!*$afz!77.L+:8)Js8W-!s#pUFGo3.gK`D)Q!!$tn^kDag!!#7qf\"ct>z!.VdJ%I+N!8'%S5fKgDAqO]qYhUVBqN<RF^_Zb_oz^k]]Jo)A[hs8W-!4p6\"mpA]gHz5\\Ildz^oGhuK`D)Q!!#QS^kDag!!!#7I_^X;zLm,W.z!-\"aLK`D)Q!!%Ou^kDag!!!!jd_HtUrr<#us8W+Qz!2[t+K`D)Q!!\"pN^ci+*;*C'_l$XY38;.$D!!!#7<PX:gzTV]GXz!$%NE4q>ktAA=i:6-@:/k,mm@4qc:@`(F0XFt.DE^uR/ur-=)5K`D)Q!!$2u^kDag!!#9*dQiKdz8:eR1z!&MGVK`D)Q!!&[=^kDag!!!#3UVMQ`z!)(+]z!!#d04qF&9l_(0N/An<,([-Cl[\"SJ[!!!\",I_^X;z#,K%gz!77RX+9MTCs8W-!s#p`ZcY//=;]MmB4pglc\"!NM:[^Psbz!(s*'4ppMp;B+idRh:q+K`D)Q!!\".&^kDag!!!\"6Wk^e))MMC<[o[@k#DE-X!!!\"lS\\RE\"RP`^l-JdujYR/X3c3$Igz!;*,'4q7pSa1f/)eh]I=_-:u'K`D)Q!!%OW^ci*;n-q1:Z$5/1+b]mr!!!!UUVMQ`z#cYUnz!+_>0K`D)Q!!#ck^ci/>%%dbc0dHQ'jbKRaz!\"b[9K`D)Q!!\"7Q5Tot(s8W-!s8RcQ!!!#7528DWz!&C=bRfS3Cz!$]44z!:Y6K4ph*_4\\\\\\\\0X5)@z!#UF*K`D)Q!!'s+^kDag!!!#UTYN_r<CXc0.>2%l#nSAO`&/=f3#Nj*rr<#us8W+Qz!5M[OK`D)Q!!%5p^kDag!!!!qKtrBBz4JBQEz!!o13+JAc7s8W-!s+LFQ!!!\"n]Kh/Nz!+`m!z!\"aCjK`D)Q!!$u\"5_T1<!!!#'KYS_brr<#us8W+Qz!!#j24p=Dt0&<FZz!/AP0+Sl$:s8W-!s+LFQ!!!#oO2-GL!!!\"LJ([(0&-)\\0s8W-!4pI5<k+iBB4pEU(!lpl\\K`D)Q!!%Gp^cj2Aod]R;4'eY7d]qaLju>SHeGs]@Hu40g`q(^IVF-,9N6IVh'dK0@K`D)Q!!$\\f^ci/`d5oM*6AbcrN5?&I5l^las8W-!4pJ$,.\"hs(K`D)Q!.`bU5_T1<!!!\",T\"mMoK%ZlQ;JnZ\"6Bm0(z9U<I:X8i5\"s8W-!K`D)Q!.`MK^chq\"gSl+=4pf3iq(0q\\6];(1\"R\\\"G8VI-E!!!!=QG=V>s8W-!s8W+Qz!'lR[4ouk7K`D)Q!!%7t^kDag!!!#/O2*p_n9,jX@6Q6aJPO7E2^):Y#$\"Z(H5+j&JKu?_E:INrns=i1)D<Vk3:,V(+.]+#WV*3Dz!'jN!4pQj:ae\\sq4bWk9!!!!sTtihrZT6bOkj*p&z!%u'@z!/QNJK`D)Q!!(60^kDag!!!#aUVMQ`z^7rDsz!$I$3K`D)Q!!$DQ^kDag!!!\"L6bkkiZ1S@R\"Y;h?RL.L3K`D)Q!!%8\"^kDag!!!#cP/)bOz+I0`rz!.]4-K`D)Q!!))U^ci/ZKa,k/#jg`B,F[A@!!&[us8VORK`D)Q!!$,s^cj:A9enet1\\L\\3>1pIGrh0\"d9fTdeFG0dg:)d-XT)2;4E7A%#&P0qLH[e3iq%&P46QXhm=i$1&48)Q9.^BcaqM.]\"NJu?GfM-Q/k,bqr4m9\"#'DR?uZJ\\gB5&N!A+\"&<YE@Q'az!+96NK`D)Q!!\"F1^kDag!!!!AN51,Iz0Rpllz!!&h1K`D)Q!!!RU^kDag!!!#WTtl?^z!'%cJz!76>5K`D)Q!!'U)^`Z)Gs8W-!s8O4%s8W-!s8W+Qz!!$]JK`D)Q!!)qr^kDag!!!!sc9R'`z^i$rAz!$HI#4q9?/H!qSU/lE<PIM^''+S#L3s8W-!s#pb7]4.P?o2Y)O+Me!Vs8W-!s+LFQ!!!#WJ\\Zs>z3/,/%z!(s9,K`D)Q!!'ff^kDag!!#9;cp39bzfU9O/z!,.,&4q\"XW#K%)gform<H%c4u!!!#sUqhZaze=\"++z!5O#u4s<%jb7@Ws`8dmfNG[L2(>5JN@F\\YC=H0\"M==]f:Ch'S2$!M9d-#3iAKZ$%d\\1I11/nu6eTO0%n(YRk84bWk9!!!#7EkmA/zFI'^+#>Q,t4\">O54pi)=fC)Lq$.Fct+?fc)s8W-!s#pr.N!P8Ka--b]m>,*#=dFaA!!!\"L-/QF$#5b2q/0gI7z!2+YR4u.uXPm>j?Vc(DERoGOC5o2]9l?Zs=^7]C%P,VZCFaMB8OQ89e#'U1sk<A1]]C;?'4q:^f5P++mG:<$<7P<@04qU&+51p)&i'AqcI'X^)[\\BUPz!5NTiK`D)Q!!#9#^kDag!!!#qTYN_nhNX^fz!;P<aK`D)Q!!!^u^ci4P4lT4blcqCJ(^tK8K`D)Q!!\"-V^chrh\\GSJTV1emL!!!\"\\GecKI`l\"c[-eLTl[kThdULeTHg7i\"5g4]M,!!!!aI)(F9zOG:P7$Yln^a$M//?IFL?K`D)Q!!)M:^kDag!!!\"HUd.*O-[[G+:>;1.DZlG]z!!n.kK`D)Q!!&+1^kDag!!!#qUqf/#B-Q_H&u/_s3e[P6!!!\"<EPR8.zVPV'l#ZPCO2U\\\",FZp8`^Umsk6S5?7a,\"24K`D)Q!!$\\b^kDag!!!#-V8.cb!!!\"Lc.5.6z!$%]J4q!'&2fUo;L<i:+gE8`\\s8W-!s8RcQzTOYc$.r5D7,U'[>X+I&/euJs?^lh1/_[\\oL[<C(m4N7QYQnUWk`'G&-(*c/)K`D)Q!!&[l^``COs8W-!s8RcQz+OWN/z!0jCsK`D)Q!!%&4^ci1.n_*TsO8>kUEOoD/z!:Y$E4q'T,TgRL7RiA<;=V$2d!!!!af[<#-bl@_Cs8W-!K`D)Q!!$Q%^ci6\\[XA0?FrLXR^f:]l!^6plP4c&\\QLjqfK`D)Q!!'g(^ciAEC3D.c#5h:XS5M@0fNd5;ab9]p!!!!a=27!2U^/*5@(`MPHcu<dnuM5m4pJPhb7U*N4pg0a'<@A:B($!h.TB^^/BRB4,HC\"4/i2=_=GhPNbGP$H4e<ZL,_!E^i5k)[bjAaOR)fbkz!8qY.K`D)Q!!(r9^kDagzE57/-zLlB+lc2[hDs8W-!K`D)Q!!(fB^ci'2HZm=DM+%ad4p_e*n#KZ6^-I(\"z!\">mC4q6&n6c#ieeR09pplY\\B.U]h0+S?_)k8ql9;ZG^@*1km7a828:GmaAE\\?]Q2Uc_#W^le6`?G('-z!'ji*4pL/6Wu-!W4sPNG;(M&\"3,N=#WE3lT!9*cB-tkEE\",ah!Y]dBs<?c_h/VO0)!!!!AIDCO:z0T*Z\"z!)S$XK`D)Q!!#'X^kDagz<PX:gz5[(sWz!,.M1K`D)Q!!%O<^kDag!!!#WC;<\";HQ(>3X%to:^/c$KWiG\\Qo\\as7rm]B!WWoFI4DBdHG[rNOF=YAj3o#p)MAXn#nHDX8aSi@ccXk+f(52_g!!!#uUVK%p2JRpGz=GjnJz!5MIIK`D)Q!.ZQ9^kDag!!!!JeA+6t8FkplSQ'i`-M8piLUmAJ[Ls%qP#KH<&g<:..[`aWe-h&Q1d+=I64uHgZ@%XlpMfYsc@l5u!!!#&]\"j\"\"z5]/hN.Otmo8IcceNoaMUCQnha72:^n/g8pjck4>\"+dp-N?$ETaA12r4p]Y\\lz!!$ZIK`D)Q!!$o0^`^i#s8W-!s8RcQzTPM>,#i2Hf2C(<6$U+i^;LU320[TBEz!(*EqK`D)Q!.[u'5Tir(s8W-!s8P7nnYX?n^t+oNCCU'5V=Q0jz!&05EK`D)Q!!'6p^kDag!!!\"RWk]bNrr<#us8W*_#e_]<_cP=rbruTG*Al?HBO8@7UgZ$uK`D)Q!!(qd^ci(qlDUFZdo_o&4pu%*dYMdQ,_Q_0*eaRo!!!!AB>B3$!!$ILs/SFL#+J,n+.Tcnz!%=5M4pDA&`2KV+4q.ST3cHM<UfIfH0(8[$%=eZ\\Ohdoc%Jq\\;J&jeXW^7tg)XT]u3S-]d\"l\"ff,A1E,q4NEAza50(8z!6B`,K`D)Q!!(<<^kDag!!!\"$Qb\\:Tz8:nX2z!6C5:K`D)Q!5P;X5X#b\"*JnFC]^ZHkpu_4Pri/8<z!'#PF4q^[WZtfji;&:g:`C1j*'1n4sK`D)Q!!!!I^chtFf*UL*>(lqV!!!!7Ttl?^z!*6mhz!5NQhK`D)Q!!\"R;^`_n@s8W-!s8O5#s8W-!s8W*_#jVTMM+`KM:PAcK!!!!9Q,&(Rz4H[F5z!+:Do4pZ7nqOY2=:Y:@$zoT?qCz!&gLcK`D)Q!!(qn^kDag!!!\"DMnhL`lYaUu>DgB1-J4\"Pz2TNTs$<:`Z>q1Y$g7;_;$!hE9f?hnHg0]O6z0RLSXL&V,Ps8W-!K`D)Q!!'6B^kDag!!!\">d6K7:z!(_j[K`D)Q!!(r<^kDag!!!!EPJDkPzG_3^p%D4AcPfWJ`G9i=Uk=;!A4qAR1>'[JMI)ukd;$p'QdtIc%!!!#GFhi\\2z!8tVGz!'k/3K`D)Q!!'s(^kDag!!!\"lD8:i*zOHI>4z!-\"pQK`D)Q!!\"-`^kDag!!!#?R_V)m:%U$WXCqb)K`D)Q!!\"jI^kDag!!)LgrBNOV(<,C9pT6`\"Lf&BA%%BE_7R0O/.Hdd?aHRCl^@\"A@<5M^p\\m8Yqgo5L-YJ.#Z/]OMQM/R._l0RspQjZ(fCf>*tD5)CBaQhrYj[t4,zJ5<t7z!-j.3K`D)Q!!)5T^kDag!!!!QWka;gz&;@nB@K6B-s8W-!4pu?!Ra(_jEH*&Z[tOe^!!!\"\\K\"sQ#8#I@*.VU\\j=^Yl,0Q\\Ypq'VL)7?0ajNRS,34d>o=>M;-1b\"I`lrW%R7$D:>:i2e,[C#+ppXT&8\"s8W-!+RT1.s8W-!s#p\\OLCZYj`5t1OHVN5`nd1CUcjA+mK`D)Q!!'[!^ciW7,!+a[_4_n,FV+2]LBO!hQ.OW?95GC)4pAaWY\"Xs#E<#t<s8W-!4ou(3K`D)Q!!))A^chq,g^W-BK`D)Q!!$u&^chn6:.qWO#:h<]>S9tkK`D)Q!!'a.^kDag!!!!/eNc;J)uD%O*c6CUodo^hV!sh\\\"^?SM;2UD7+dfNSM%Chi#D1#R3'bST&jh9Pz^f\\B9$bRKQM8]=!5V.g#+>Nlqs8W-!s+LFQ!1ic^mm2X-zaG@Vq!X[4;#rNt!iCc=TI'SG+zm%;'W.;HM8dU.%7'uZ#V+9eAN:)$qp(!uX)CG7ttW[NA\\Q8V/JG'Vk&l/IBszoUN^NzJ6'NPK`D)Q!!&++^kDag!!!!aKtrBBzilJohz!-!D&K`D)Q!!&[k^kDag!!!\"`S%q3:,d+a!q-\\S+g0%fI@kDsSg?rt8p.*=9cAf[T%P>QepfH92T?]c^qLqCEC[Y2%e\\<57rr<#us8W*A>Q4[&s8W-!K`D)Q!!&sg^kDag!!!#9W5+)ezA=gSjz!2+AJ+P-Sms8W-!s+LFQ!!!!9RD:uj3;,RGi1Pc(zOE&'iz!0DZFK`D)Q!!!![^kDag!!!!oWka;gzaHXJoz!8r\"8K`D)Q!!!!_^`[Ops8W-!s8RcQz+FCmH=o\\O%s8W-!K`D)Q!!)MI^ci+d]<MVd,W!/5c@l5uz;S[tdzk^^H4.cs9eVAjEQ$/!!6PX,uOig:#/_3E'QQV;07rp97K3kFi?9=`$,p\\S0Kz!:8H*K`D)Q!!\"(<^kDag!!!\",GJJn4zn8Q0sz!'jArK`D)Q!!#!K^kDag!!!#oVSGA%\\UDd?M-^NUKS9C+!!!!1FMK\"]s8W-!s8W*_!hNsGAcD`0s8W-!+EIJ]s8W-!s#pM7Z64c!s8W-!s8O4Js8W-!s8W*_#n8M&.daBD0#iSFz&>-alzJEYS\"K`D)Q!!%P-^kDag!!!!OU;2H_zOEJ>]+o_NAs8W-!4t78<95Fp=m,R@[nEt?<l'TW-i=\"d,I!sjWEb%@^EZg16BSi]0d92:HKpnEtR@0JR^P)Xf!!!\"lBYYa>rr<#us8W+Qz!2R]OK`D)Q!!#9/^kDag!!!!9KYS]Irr<#us8W*_#EJ,2kjgHa4p\",Q+M[pUs8W-!s#plEN#UMN'B@;j'p.\"1K`D)Q!!%OB^ci\"rFt52'@f(iZzOG1J6'PMaBR!NZSK-=;&7su2trNL_t+b]mr!!!#7AAEm!z+CW&L%U)aA3cH#lT%\\&pd1fP&h>[HSs8W-!K`D)Q!!#iZ^kDag!!!!iKYW9Az!/&(@z!-!A%4q,I^JS;O*nk%^;oD4.@z@!f[3li7\"bs8W-!+><cps8W-!s#pWlb-#h<f00mEF4\"6F>_/DI)_p'IG@Ri%VK+PJz!7%=SK`D)Q!!%P$^kDag!!!#7;S[td!!!\"L<ldNi#,rV`G-M=,z!$I38+=mKls8W-!s+LFQ!!!#+S%s^Xz7%D&Hz!+9QWK`D)Q!!#90^kDag!!!\"s[(nj1[lH:lX_W/F#&9H=a[0\\aP5bL]s8W-!+Ed_as8W-!s+LFQ!!!!aBu#E&zLk3?qz!4\\3-5!Eh)&Q=P,qbCd8T)efr%@^KFDU)V-6JMqlQCYKc3VVbu'JSaL?7qHOkP7CkI5?rdJZ&!kD7j?r1Hu[7K`D)Q!!(Ae^kDag!!!#WLqn]Ez!&MEEz!+9f^K`D)Q!!)MA^kDag!!!!QGJJn4zTRFU>&D@#_DJcu^Nc$/tW)\\soI6JAs8TJ?/-[$fkpbp_&BoE/AR`H:@4puMW[%IWS.3rul8j3E+8V5.iK`D)Q!!%8!^kDag!!!\"lAAEm!z7FJt8)*<!Sm-L2VdFFGsqpn5\\%'?e6]g(h^G8EFJK^(fONF1:k!!!#TnGhrCK`D)Q!!(qg^kDag!!!!qFhg0K:+trd\")uIcEaiL3z!(_aX4p$KdK`D)Q!!(r,^kDag!!!!aMSOoGzJ:PFhz!\"RMo4pUljM:u&HgP#V-!!!\"pWPF2fz!0P'N!!'g=o`+AG+FsIks8W-!s#peJ(nS9\\j?P)]:5&ZJ!!!!AGecKodt=<5eeMi;9uMr7Hl/\"e9`k`G):H!]Gq^[]nMhuZcT4?'G(&1,j5?aKK`D)Q!!!.u^kDag!!%P&0#<5Az7&7VP!!'gmj8\\\"&K`D)Q!.a1d^kDagz4huaOz!(t$j.kgq`jg(TG)I]R?2qSP!;%[0\\_Ylqc,aBA:>uf*K.<C+ELf]4,@=lYc+B&7>s8W-!s#psc#4f*!1AD:NqZn*\\I&hr$z/<dl'z!\"a@iK`D)Q!!#3[^ci+3+2\\*=iF+*]Hp.f&qiSZ?:NhElz%%=tcz!5NBc+=.!es8W-!s#pbSR\"QfiaD&4A4q+Zo:5PfX)C`n6E-OPK-m?*Sz!!\".W4pdt0S4\\CR%Nppgz!.[YVK`D)Q!!$tr^kDag!!!\"l@_b/8E7L2rnYo3#(AOdk&NSQ6NXjj%j:>$ug&%`UML'sVz#`?D]&%E)2p_eE8j.op5eI1sGK`D)Q!!&sP^kDag!!!#o[D7Irz\\uEJ/\"Y=qBH\"D[0z+HXBmz!2+PO4qVf9F\"N+IKNs454c5a(>BZcqz^d6F74p-%4d\"MH\"!!!\"$LVSTDzJ4@>.z!/QBFK`D)Q!.`b<5X$^Un$I3=Z.k/@\\0%Us4FY+4Da&1nG&,Uh/D][sg]cBKQ<+\\HStu$cehDdXzd\"fDjz!3DI$K`D)Q!!%OI^`[\"as8W-!s8P7h$#13G816C6\",-^T!!!\"L@_b/2H*.NIfS';*!!!\",F23J0z%][<.%0(F6cJV0/$]bSO?%i7Y!.\\p9M*X<,h/J&Jz@\"lB[\"DKpr'SQMezA&*cuz8>EtSz!0P&^K`D)Q!!'0t^cj7'Fu/cq#\\9D;nb<;MF`FVeQMIl$DtITF-$fuCe]LEJO&HbFiE0^)+,'[p!!!!aGJJn4z&?!<-.qrFpVsG4N\\EE\"^[C07\\ZWCRg!/\"*F7[)9p?TWRp$agsF`=-m<Nrau8K`D)Q!!$t[^kDag!!!\"tPe]HiUH1b]<rDHWBdc.K)4P.f3'J,1XNEjIp^U2bVC4Rn9$;u#q-P0ArIk4O!!!!IKYW9AzXJ<Rbz!.\\[s+FO4hs8W-!s+LFQ!!!#W@DIQsz!,oZ,z!;Y<`K`D)Q!!#8l^kDag!!!!aIDCO:zfV$$6z^mNciK`D)Q!!%h.^chlVP%],pz!-jI<4tDL1;)1Aa-M=2#>(G`7o<._u)g/Ab2TlZ(=:,>kaS$AqEn+@++&'T\\It[k&!!!#gM82:[M[M+X\\n`UGz!'#_KK`D)Q!!#iq^kDag!!!#/L;5tUo$b+[K`D)Q!._B'5_T1<!!!!1Mnk#HzFNqUTz!!nLuK`D)Q!!$D]^kDag!!!#WUqhZaz32aQGz!//>,K`D)Q!!%VF^ci+ir\\YjChHkAHFG0\\pzGJJn4zJ8`5Wz!:Z;i4q>,O_ZGBe&4=4\\j[<](K`D)Q!.`/85_T1<!!!\"lT\"mMr?UH\".R:Qt222)#1!!!!QM84fFz>a)sWzJ?RHfK`D)Q!!!Fm^cho\\Mm6G/K`D)Q!!&g]^cj6R'`%T\\9&>Pde)K\"SG8o\\G['MpZXY(:^LVU4R=5Z8[/X[Cu-m<XUI>%Y$!!!!+Wk^e/W?#i!\\HC-1]Y8O'CB?JLz!75i'4sdZ:?C\"K@]Mf5`^nl3*WqN0)@JIQ>Psf$#]'cmfNZ()G5Nb7bz!8r%94tFR3)uNi(g_2_/^`LB&fa'XadCWF,XR.WW,4t:4,1'H!]c;;J+RE:`kCim9!!!\"lB#$S9E6\"6_pR5954pZi86Re+(_2gbhHSO'EU/g)IOC+cU?\\JI[!!!\"L7)4KVz@!oaR#qFK+%t\\ZpOU<5rs8W-!s8W+Qz^fB5V4p_CjU[b_\"\"]O<4z!.[bY4p:OY.6N:azI\\ab%irB&Ys8W-!4t+1Qa:9M`oM<q&33-'7O*N/Wcl>b%5rBb3\\;arECg=&a+o&c\\#>p0TzaGdogz!:ZVr4q^DtZN[<5,To8138p72nVlL#4uO.6$(GALP8;L3[ogT]PuE7G('Z_Am;Zk=qP%CE\\>i_`->^f%^#sd1*AVRQpGVZQ\\aYNZK`D)Q!!&+:^kDag!!!\"*Uqf/F\"#KFtVPVo<*E:eB9SgOp4d5_Sa[0Wr8\\ga>+\\8\"9+%d+f7ZFOl4aMN&Kn\\hi\\/p@q^HMjP!WSY4UP/[J!!!#'QU$6)zE0e:nz!!$6=4tH'Z>n2Jk@U[&B`_=J^2qj@d(Fe_0Edoq;UdemQ%-\"Q5HRpE,=P_p\"ie7@4!!!!QI_^X;zLloK,z!&0&@K`D)Q!!&CZ^kDag!!!\",CVYW(z#bSndz!)S9_Kj9\\UodF)&^P)Xf!!!\"LDSUr+z^h:GH%u3ioXSMX=XoULE2=2s[K`D)Q!5S6W^chscT)jMR[6=f.+ZnCXh]UGJs8W-!s8RcQ!!!\"L%a.+$#m0!BB-m#WE$0i7z9W#UZz!,.)%4p58E!%im)z,b`#-z!!Jb+K`D)Q!!(r2^kDag!!!!qTtl?^zL8)J;z!*Z/5K`D)Q!!%Oq^`Zt`s8W-!s8RcQz@!TPAz!2+/D4q-l$=q6*^,V&Ieh%k\\EzLkEKsz!4(-?4t6\\1gUnDS*)l_0J6mlQRE55b&UP;Vm&f\\-ij:=4ifKQ%pKtXM@3hE]K`D)Q!!&1Z^kDagz&AUI3ll:8(z!5+f:K`D)Q!!'f5^kDag!!!#7>JPpmzJ5sC=z!.\\:hK`D)Q!!%MS5_T1<!!!#7UVMQ`z5\\%T`zJ7@(p+9_`Es8W-!s+LFQ!!!#KS\\TpZz#_^!Iz!2I%hK`D)Q!.]dQ5_T1<!!!!uQb\\:Tz5\\.YQ>lOd's8W-!K`D)Q!!'fZ^kDag!!!\"B[D4s/]%Q:BK`D)Q!!!RO^ci.'KZN+CHRjmZlWl[_4MT;Y:0,6pU]c<e4qIf5_M>VkSbY9A_hqWRf+3Q8zBS+$R>u=3\"<`S7r4pXr+hd;=KLS9D%z!-l;51G^gC1GdLpK`D)Q!!#i[^ci$5+juh-$q+NXz!'6mjK`D)Q!!\"^,^kDag!!!#CV8.cbzSuTS[z!.^l\\4p-IUTfs\"CXrK2O-0HBDR\\otKXosFYzr2.7n-mXJS)!ECkH/9$@G][Cu.`)-)d/6P'9ZW4=%Rr52r1HNLCXA(\\fnBD+!!!!%OhcYNz5,,iHz!!$lO4r+93^o&*r5[<s?Jl%iYgX,n_+*eFmK`D)Q!!(Ab^cj8d@,6hFL>q/Wa%\"9EMmlk$+IB'D@IjH*F!Scd$]JOMSGf4[AD:4!@q:8nz+E,%Z/,h6I^2l4'Z*8F1S@MjZC1,EOq>;ta%jWAVp2mp:ZD,M-?5&mT$Ib,84pX0F(>]+F^kX%rrr<#us8W+Qz!.\\@jK`D)Q!!'6U^ci8U1.6W1i1LgdB?-5PhmnF@z(lZ7a!!%ORoDe8F4qE_kFY2>B&BOcOJf*\"\"ab9]p!!!!-OhcYNzaGI\\r$s5/Wc(@mcj9.Z(XZd#^7PTFb84.o]z!3gX^4t@EDjgOLS)EF`lDM/US?P5nsO7>V`C53f+9Ffh[,V\"ZVJQ%2!D1^*t#pB6Is8W-!s8RcQzG_X!VM?!VUs8W-!K`D)Q!!\"-T^kDag!!!!mPe_tQzY^4*=z!3W?;4t;($s+&Yti(*bu,Vn7CFaSX!2(.,TE7sMZL)?)ic3,+0S>GmVh*%.LK`D)Q!!(r;^ci3D4>JWSlR;7m[EOi-4pf)\"*Sq#dJb/V\"\"HLF%oH<Z's8W-!s8P7bO%Mipz!#2!>K`D)Q!!\"-q^``FPs8W-!s8RcQz!*R*$%kap`gKkQRlDOfJgQ0SJ4pmQ%NXknV)2D?ZK`D)Q!!#99^`YE4s8W-!s8P7hH>Af>58\\['_hA'j!!!\",P/'6iHKFsSH[Q@lTXaPD4q'X@RWCD5Gdh`?m(beQgeoQhYsE1)&F9@2-?W^p9q/\\h\\8M1\\!HDpX4bM*U+4:3Yl^e5(i)Gc/#hDH_riVh.dG'o5Z@lC@%/HotqL7k>K`D)Q!!)5A^chl-7j!M?z!)RdQ4pMa:Aga/hqh5\"M!!!\"$V8.cb!!!\"L,hPA9z!2Q$uK`D)Q!!'f?^kDag!!!#'L;4qLs8W-!s8W+Qz!!\"\"SK`D)Q!!(r$^kDag!!!!QKYTbq(9mS=];JqU^.`La\"O'IS;i$\"Z7</Kf(8_C9Wb`kBN=[3Drr<#us8W+Qz!.\\+c4paYYA$&@N_uQ&Fci=%Fs8W-!4tN9:/Y:E,;NVMlQM_U^k=WOo8(h,ZU@3a;Ph+?Rr/q+1:Up)sY%tfA1IQoszE-oBSz!+:5j+G]srs8W-!s+LFQ!!!!Z[6TEGz:ia@*z!#1j:K`D)Q!!)i%^kDag!!'efdQiKdzn:SN1z!+Xj#4q!E0JeCZg;KNW%rB:HCeM,PN9:(>4z]ViQ!z!.\\RpK`D)Q!!'6P^kDag!!#8Ogd$Pnz&9bi3X8`/!s8W-!K`D)Q!!(Z2^ci9DVfg$^-GEF!PXKg1SH=KF!!!#7SCg)\\z!)T<'4t81X*R7#AU7m)BL5^u4pR4od=6Zf[Z9RufA-SjQbbFZ2]l%R<SfAmt4t5aT/gkJ%!B=_(2)R;GoJ>+X\"FpU$dDchtGMg%/%uW<4a?tjapCDq2z!'l@UK`D)Q!!(U#^chu>*7sjPO^EeBz$E1aoz!)ME9K`D)Q!!$8q^chp\\D%`6WK`D)Q!!&O_^kDag!!!\"dP/)bO!!!!a^!siOz!.\\=i+IW6/s8W-!s+LFQ!!!\"nZ+rOA^T5Zj3PD\\0dQfk8GK,_iB*XqD7gT<.(Xn'<zE.>ZWz!8rOG4q2^UG7ET/[Clq:V.:R\"z!\"u0E4ppPs1,<ak9k/<U4p;,#^[-o5z!$GjgK`D)Q!!&I]^kDagzLqn]Ez^lQ8R8cShjs8W-!K`D)Q!!%OX^kDag!!'fphS:8Ls8W-!s8W+Qz!)ScmK`D)Q!!%O[^kDag!!!\",Fhf+brr<#us8W*_$Km.ZbbYB_W2j'Tz!$%QFK`D)Q!!\"RG^kDag!!!#CUqhZazi,QPdz!.]sBK`D)Q!!$o1^kDag!!!\"4W5(S&Pno5]lq@\\84pddt95e?0.t0C1z!-\"IDK`D)Q!!!!G^kDag!!!#gS%s^Xz[%P3gz!:Y`Y4pe5e.Y0_[8-k!)z!2d!9K`D)Q!!&)$^kDag!!!#/JA<97s8W-!s8W*_.SQ^,`'N#ibG%9.G0?^j@'\\qZ@kQ[\"<L.cBgubI037)#BBkOh_ZHVHbz!9U/oK`D)Q!!\"jJ^`\\a<s8W-!s8RcQzJ6KaBz!2*`8K`D)Q!!'fK^kDag!!!#/TYQ6]zeu6A,/H5\\Ls8W-!K`D)Q!!%Og^ci't>M.T.#E*HD+=I3hs8W-!ruh%8s8W-!s8RcQz(mi$lz!6B]+K`D)Q!!'O)^kDag!!!!)N5.U`?;YLW%@gB<9KjrneV_fe)a/l7Z4Xp!`g@js[GY$A>g6H=VGdkHL8/B9m&KY;Ee3ujh1Yh/!!!!'V8.cbzrh[Co\"9>cT*JFIn!!!\"LC;<\"A\\N-!^d9At4XIZL/K`D)Q!!%Ok^kDagzA\\a!\"z@!9=L#sJCb$:@K-h?S`7zYarQP@K-<,s8W-!K`D)Q!!!M%^chtBn?Z=F^kDagz?,2-oz5ZkfEdJj1Gs8W-!K`D)Q!!!5&^kDag!!!#W@).Hrz5]+;jz!1':nK`D)Q!!'m2^kDag!!!#!U;2H_z#_p,Y)8ZDp\\mf(?SLX_6.NjXYqPWsVNpZlGYI-P\"(H0G07\"Q-*K`D)Q!!(BA^kDag!!!\"lG//e3zJ5F%8z!9f!L4r5bXG[u%E@V!mH/_TMYMuoQBaq%I!hh;%1!!FdtRR)W-z^fJ7)z!!#L(K`D)Q!!%VQ^cj5,Q`NnB\\YF1Z0_b$$,h<:dpBE*iIe*u=Up[$NjD>KE/l#g,OrR/Q?A/@Z!!!!QFhi\\2!!!\"L!S0M\"#O3](8`,(.4pVbmYPtt0HFnk2z+Ci2N#r;Df%X7D^,5[&ozJ9/Li/G`%K!mdUl,r@\\un9$DESn&6;,p7mg]:eU`g:4?]VPa\"g,j>XcT2jPO7YLgBz:V\\)0rr<#us8W+QzJ-Fdp4p4RLIVOQ:z#_ToV#P\"Y@T#(<BK`D)Q!!$\\h^chmgit/>Hz!;M)[4qR\\1iI`#7gY:ZEKO/I+jfL]r&\"`uYd_UjQJOj]\\poLXg1&pZN*Tl+p[CctIF_l3B'.,(QFtRifU1]/[z!+s\"hec,UKs8W-!K`D)Q!!#-O^kDag!!!!9Nkg>Kz!1:QUz!!#s5+Cb?Ms8W-!s#peS`&/id^e8r`,D?*t!!!!ACVYW(!!!#/:EVrWz!'k55K`D)Q!!!>9^kDag!!!!1I_[)Es8W-!s8W+Qz!;M>b4seOA=i*MX$o$:kYu`NPmNat>m'p7Gdn?R9Hm!WVr!S+^Vs>O\\z!5,,CK`D)Q!!%OK^kDag!!!#?KtrBBzLkid\"z!!\"RcK`D)Q!!%Oh^cj1nrIR[U6`'.]l7&^<D@l!#h<:pFjE34rhFh?C/h;EsKVWOHXW,htK`D)Q!!$-X^kDag!!%Pud_LP:z.%7r*z!90]f4pc/Zd*VpL\"EhtCz!.[eZK`D)Q!!)5>^ci-rj#IOAc7;$qG]Gu?@(..2lVcO\".Gn#6oV7K[SB$GDns<7&<9^Kupgj#q?i]VVMP70Vlut.)hb-\"ZF>dqca8IpIrb@)mah,q(:M/7jJ.RTMh2+<G57^_YU/?9;;:rWRaBTeFiK%<.c'F:[KhQn(V>R1cA$Pbd9\"i'3p%_jHz!,AIJ4qUsq\"uC*N2k&<\"0&%+ALp7F4V>pSqs8W-!4t+V$kp^I^oVko-f*(F)=suF\\]bShp^V4X`?lUJ.))mDl$k(r#<J6&+z!'.hY$(%SlG0W4072pp\\z0VcF;z!!#*r4pS_O6B0:O:-Je,pR+_u*rc3>s8W-!4p^/OHONB'`1T:)I[aFek5IJ9.I=37+OLuh%Kda8R^qgn\\/n,rP[B?&z!18DS4q71$-om&l^OZ,ef^e#c%HTOtS$,pRnD>[72<BMlzd!!3Yz!.]R74q&jJ*8dilBA?=Q?C$9Fz+H!sgz!$H9sK`D)Q!!%VN^chm;.5E0&z!76;44p,@fO<Befs8W-!s8RcQz<iNlgz!.^HPK`D)Q!!#-U^ci\"400.4ZD0Ua7!'jiis6i7-z!8*\"@4p;Xb7s>>pzJDA%-K`D)Q!!&so^kDag!!'h'eNefgz+FLsg.S<s.Eds87[H&j,5UAWNmPOjr[IBIT$W,`J9$!V12V-tQOViAu%Y;P^.qrFpVsG4N\\EE\"^[C07\\ZWCRg!/\"*F7[)9p?TWRp$ah'N_utF5NWF`2K`D)Q!!#9-^kDag!!!\",AACA6qg`$13o<q$$fP&ncIJg'K43SgK`D)Q!!&Oh^kDag!!!#gFML'H@lrc%2Lei>@tam_!!%Pob<Ua]z5[2#f$89<il*f3?=*(^%z!\"bF24pSj/f*\"$dk<8rdb<?@c+J)[W;hafA6?\"'34q(mLgl9Sh7R>r!W<5<j2l<]E,KK1(G(fnr!!%P&eA-b<zk`<M%U]1;ns8W-!+J&N3s8W-!ruf)Vs8W-!s8RcQzI&OhE!rrn[+B/:>s8W-!s#p[t#3t2-Il0D!O[LaE/(XZKcM0kp#sJK.*$RR1#rhn:3D+p_?,hQuzfRpt'#f!d`(bpoGEJ4Am!!!\",A&'2mrr<#us8W*_.U$Wh,&]ek`RJ*!O;1QD^'$!f7DP`hgHZ;5qUeT2`l=:G_$DJ_]CPoSz!)SEc+F=%es8W-!rugq5s8W-!s8RcQz^g+Z=$0(;7IOF'IP9iC!%2j@HiM0^3`e=Bmz8\\g#[zk,#kIz!;r%r4pd$Ed[VnlQ]R>`z!#UL,K`D)Q!!(Wi5_T1<!!!\"<K><0@ze'5Zl#4:Z3_?E_hz!76).K`D)Q!!#4>5_T1<z1;JSDz8<CW@z!#EAcK`D)Q!!'6F^``RTs8W-!s8RcQz5]XYoz!76P;K`D)Q!!#iF^kDag!!!\"^WPC\\+m>Raa'L[HCkH,&_4tHY/Ph\"b*4)0lprs&h\"?6LK<*mtMK9/OVH]hN(NjZ+Q/\\+0cRJmGgu+!@0Ss8W-!s8RcQz+EbJRc-4DUbfnj,4pW?:'%$eIRC@kMzjI3l<z^u!R+4p5SH]=0s,0)A_.K`D)Q!!!!d^chp3IYse&4p;_;rj'+!#RqYu2\"\\+[15,].!!!!aO2-GLzN2==Dz!18VY4pJX7N,3bWK`D)Q!!'[1^kDag!!!\"XOh`)gs8W-!s8W*_#m]6Q0R.u@/\"/X07u.WQ'esmQ9k.[ez!4J]=K`D)Q!!'fJ^kDag!!!!-Zp9<Fzb`]b*.O%7eaqkuAr>['Q#i2Bdem&?Qm?epN_hcq6Je0:@mf*0cB=77a6b10iz!,egP4pRYd.Y>f8$&&?Z!!!#OLVSTDzJ8)e_,s`[npsd<dWX8V[4aW/mA9iYN3rmY%/'uOebtOD)f*+QcOgKfBzd#Ghpz!(<-gK`D)Q!!#i=^kDagz5JVsQz0QOrm.S<s.Eds87[H&j,5UAWNmPOjr[IBIT$W,`J9$!V12V-tGT,i41$B!%k#sUo[K&^!A]*:G?=3Qo;*Cn#):rgEU-Ch>Ka:B8^?e1AiI92p[9acXTz<5?;'z!'lsfK`D)Q!!#iA^`ZDOs8W-!s8P7e)7sH25A>fO!!!!ap!LR/z!,S[NK`D)Q!!!S-^ci5De,??HW^0t*<dhslSj!9RHCKjW%1B;5q)d62DAN5=^pQ?-rb[>hzW5$-%z!;M\\lK`D)Q!!#cj^kDag!!!!EQb\\:Tz7%h>Lz^o#sR4pBiiWHD-'/$\"RFac;of%V=GUlP+ka`K^goY+]$k:m\";\"Tc$*Mh=icglDF).H%Pf#+MRmUs8W-!s#pl33:Hf/$FS\"\"po@H&4tN<ZoX.#*RnE5G?Y=&\"^&`egrj$CL.hj:G*A,7#72^_Y(=V>IB<rACr_Pch[aJ-09SKB5+?//BG@Tlkz!'jGtK`D)Q!!!\"*^kDag!!!##W5(S$hmW#/6G#DjBj$pVaE6smhnbK4QA#;=!!!#/S%q2pg:>>kq6IS6&X%hJzE,raJzJC;4u+K5>?s8W-!s#q<c\"H\".s9co-t3@iPiciMc,+P;VI==r[DK`D)Q!!&+(^kDag!!!!YLVSTDz,d9OfzJ8<:mK`D)Q!!\".A^ci!g-Ai#p7h14QzJ60NM)al*)I))6jhlOCqhd=6-Of)7g1\"N-FGdR(:4pu469GZFNXql&)gHH7mjoG/P5s'R(r$IK=['3--E'>c(K%F*6KLcW>V&XgU8^4%8_As`Xj4Frqd@S^ra]<dW]D))rD7&jk7YLgB!!!!+VnbJ)FnMZG*:O:tF59K#K`D)Q!!\":8^kDag!!!!^^-IAPz^h1AG$]>!1FL#BWjd'cqK`D)Q!!(*6^kDag!!!!=OMHPMz!&_QGz!0ES`K`D)Q!!#]l^kDag!!!#/K><0@zXId4]z!,Re5K`D)Q!!$t]^`^5gs8W-!s8P84Z.To='Q9DdY>.6_r\\AjOn$sDdgBaeH><77Ho2:@MmGKh\\2FM.087@2Pz\\:q^^#:<bI16o5IK`D)Q!!#92^ci#<PZiGEl`n3Yz!!$KDK`D)Q!!(B\"^kDag!!!\"lF20sD+q[+k1EM5Mzi.Jh!z!6h\"LK`D)Q!!'f[^ci7RNG#E*kZ$R@o&HM0]nHFd!!!\"<Wka;gz9UEPKz!&/i:K`D)Q!!'fh^kDag!!!!qE54XHaf7n_SU\"uqT,'j36%o:=!!!\"<Ttl?^z=gLAIz!-j@9K`D)Q!!\"^-^ci,(_#'T(R,a4XoKEYam+^FGM8YI&<Kr1;z^gY#B#?T]FYRaI\\4p[\"aL`FL;\\l(]s&@V/0??<6&z!/.#\\K`D)Q!!\"F!^kDagz>/3<1`1dV#7MMLl/2u!DK`D)Qk5>8J5s>b%#ME/1%+5\\@r/.mR4pa`aBo-\"l*3ChW#V+B'\"GUd6NeIH5!!!#KW5'P5rr<#us8W+Qz!$IWDK`D)Q!!$&n^q6uU#R:A4\"U>>A%HG5)Plh+j\"-irj=9Ffj\"'>X-\"'#j6[Lcg[',+TY3#r*'!tu>Pjruqj=9AZ\"6XU-(#@\"c*#KAoA#6V+R0b4?g;[6/%=9B3M>J_m('3k;?ncKCG'*eV4\"/,i\"=9Afj,\\dPn\"'>X9%pQJ%%hDm9\"qM5K\\gDD!=9AZ6&7?#O\"'>X-\\i*q0',+Tm+1VIe=V(H4\"'>X1r;nqdW<!*'!s]'8\\g@Nn(LRUY$X:aqJH5jT!s>tC?j?oA>IHKr#@!c(M#d]\\\",R*^=9HJCo`P]X%g0N^?j?o='o<$\\!<ZF+#6S#<-LMfX#b_AI\"'>X1\"';/tq#UY#!s>\\F?l-'L\"'>XA'3;[k_#a^@\"!8=[\\g@q(4TbcoC]ftM#9aH[$WahcaT2KG!s8d?!s>tC?jEY4\"'>X=%p$7g'*A[W(CsQX-3F?K&+K]'=9B3M>OhjK!<ZF+\"1g-n#PeB&=9Ad5>IHNE!WuO,(Dg<H!ZMqV\\gA?u%3+7,\"'>XA!t?%c'3;[k!s;I8d/a>O!tPoHncFLH\"'>X1#@$=7\"8WU;$fqEl=9Ap=>J;cnXrCaZd/jDP!s>\\F?k\\q0\"'>Z9!s;X-#6S#<-Me&S#e^8X!s;X-\"1gBu%hAaW\\H?OJ=9AYs+CGGV!s;X-!s`E?\"/8\"f#6t>G\\HB5A\"'>X1#@\"bmSHAsr\"0hk/=9AdI<\\am^=-Wji\"*+JGU-i;n#7\"JE5mPCmC'OjD,;B^g\"9Va.(C+!P-5.1%'Cl59+VU+D\"'>X1js4[H!s;O6\"1AbK',)$`[Q\"p6>NR+C'3i=(K`hK[!tu>Pq?kmX\"'>X-\"&fHh!s;X-#6RU$SHK$s\"/,i\"=9Ad9<k9U_!u8?KT`P<u\"\"aKQzzz!!rW*!#>P7!;?Np!&\"<P!%S$L!:p6l!4W\"/!9OFb!9OFb!9OFb!:0jh!:0jh!:0jh!;Zj!!;Zj!!,DQ7!'C5]!;llu!;Zj!!;Zj!!;6Qr!.b+M!([(i!;llu!;6Qr!;6Qr!1*Zc!+#X*!;llu!;Zj!!9aRd!9aRd!9aRd!9OFb!9OFb!9OFb!9+.^!9+.^!9+.^!9=:`!9=:`!9=:`!9+.^!9+.^!9=:`!!3?)!!3?)!8n\"\\!9F1\\!/COS!;-Bn!9aRd!:g9n!:g9n!!!*$hnK1,\"'>X?\"'>X?\"'>X?\"'>X-X:K\"?%g*&D!s8XG!sS`*zzzz!'1)[!!3-#!!!6*!<\\=s!M'5n=9G)p\"'>Yr!<ZF+%hDn8!f[3_=9AX-;\\'BLFU)U_=9B3='E]!^6N]IR=9AYo\"u-W3\"'>XA(IJ9>\"'>X-\"&fR8$ZuQ*!<ZF+',+U0*to;lY!.79=9AZ.)dj$]$X<0'/H])W#8:>(0hDIL!s]KDjtRM_>N-_<'3hV'_B9L8$Xj->\".g\\M+V2Nm\"'>X-XrCaZ%0K]7\".BEK',L`b#;lTc\"1JQn$Nel[!s`08$e@CS#I+:3=9Ap5'u^3e!<ZF+\"6KY>'*A>8$`O./=9HYG\"'>Y*\"'>X-\"*+JK$X<TCQ7NCL`<!dU\"'>XCzzz!!!!*!!!!)!!!\"+!rr<7!!!!.!!!\"*!rr>8\"onY;\"onY9\"onY9\"onY9\"onYA\"onYA\"onYA\"onY9\"onY9\"onY9\"onYA\"onYA\"onW^!!!!@!!!\"-!rr>>\"onYA\"onWl!!!!G!!!\"+!rr>h!!!!#!!!!t!!!!U!!!\")!rr<$!s%Ds!>tuA!uV2C!uV2C\"1&HJ\"](rs)$<tC!s<QG\".gWC#6tK<\\j-Y9!=AoX\"'>X-#=JY/\"'>X5zzz!!!#az!!!\"X#QOj`#QOj`#QOjb#QOjb#QOj`#QOi)%KOSe!K@Bf=9FNh\"'>Yb#m493'tjVP_[[C`=9J#b!]+!^1H/P'-9'KjF05j+2d=iJ2qBd+l6ZTl\"Z),E\"'F:Y2$6q_n\"9_<=p$Q>>Ok*>eh_AJ2cb!g5;P6&c5JXm1NW+R\"#gB>ZNdufNWE2&!WuO,>m\"12n\"9_<=p$Q>>P8pn<ca]o1H/OH))pOhF05j+2d>P]2qBd+[M]0+\"Z$7i\"B?B[rXs(N2<=i@=9FN`\"'>ZoTE6oQ\"#Dl?N]T2N'm%q@1H/O(%QEA]F05j+2d<io2qBd+N]R>%\"Z$5_2jXO]%mC*[#gWZV\"2+^;=9J#b!]+!^1H/Ni1,i6Tp*MRS>Lim8eh_B9\"uA2BZ4AnF1NV+L\"#gB>+#7p**m\"TgblIq2!<ZF+n\"9_<=p$Q>>Lk8_<ca]o1H/O@\"ZP!gF4MfC2[(uVq?I28\"/,r%=9FNa\"'>ZoTE6oQ\"#Dl?qE$Xe1NV+^2rYNmRKb_%'m$Mb1H/O$&3&/rF8@s#2[(ur^B6Zd#,q\\,=9BNA&p*=R_#sjB!umO?F.*:PrZH:]!P&R?=9HeL\"'>ZoTE6oQ\"#Dl?ME<cJ1NV,'1H/P'\"#ndeF8e'\"2[(u>\"'$!f\\gDKQ*U*n5=9J3t\"'>ZoTE6oQ\"#Dl?c8diC'Q^Da1H/Nu6oS.frW+f6>E1!giY6Ir(,ImRXs>sW1NSRE\"#gB>+2e4\\\"0sAr![/YB!K..a\"0DY-=9J#b!]+!^1H/O82)jM/F4M'b<ca-[2qBd+RKbQ,>Q-oIeeN8/$8XVFc3QA[1NTEN\"#gB>`s1Q-C@X1`\"'$;J!WuPW#3>ph=9J#b!]+!^1H/Nm!B8REF05j+2d<:92cb!g5;P6&c3$#V1NTQM\"#gB>$SpN=mN/nE\"'C0\\OTYbg\"7Mla1Kjl:2d;k-2qBd+RKb_1'Q_h?1H/O86T8%ep*M`X'Q^Da1H/OP*]MY+F.P&f2[)\"P\"iggO^-7ei$iU//`<69F\"7Mla1Kjl:2d:ku2qA^bXpQsD>P^-7iY6J!2D[9rdL\\@g1NWCK\"#gB>%lXOl]a4dC_ZfQ5\"'>ZoTE6oQ\"#Dl?OrH>\\F7pq:2d>8l2rYNmeeL-p1NV+^1H/OT2`K;DF5e\\P2[)\"0\"d]HuQ5IjO\"2k3BT`kO#\"7Mla1Kjl:2d;S%2qBd+l8CFW>M:ejeeN8/$9)\",p*MRS>GaG?eh_C@-Nc:21E6<+F2g'VRO<1=-i4%2!t#.\\\"TomN!nd_Z=9J#b!]+!^1H/O8))p+]F4M'^2d=iu2rYNmXpQsD>H024eeN8/$8XVFl3B9-'Q`CP1H/Ot69!IOF6Wu42[)\"C.E_o=*s2U(rrs8I5*#`(\"A;i!SH]0u\"7Mla1Kjl:2d;\"]2qBd+jq]a3>KRpEeeN8/$9-rYF05j+2d=Q72qBd+L*HdZ\"Z-/_rXs;K+M@jN\"Bb*obm\"8P\"7Mla1Kjl:2d<R?2cb\"n-8RSbhBb*]F6XZ&iY6I:$8XVF^+;4o1NVD!\"#gB>\"9/JJ!=Rig\"8)Zsr<<@+\"7Mla1Kjl:2d:kH2qBd+XpQsD>J_XEeh_B!&d(&r1VX\"o2]!8D4p-oS\"'>Z%#6S'1n\"9_<=p$Q>>D`G?iY6I:$8XVFqA)$@1NT90\"#gB>+34Kj\"0s?p+WgfQ\"#h$Q!WuO,d0BbU\"7Mla1Kjl:2d=EM2cb!W4#b_HF4M'^2d;:D2qA^bXpQsD>KRa@eh_Bu'f.dQl7t<L1NU\\a\"#gB>Wrs5KSgYBk>F%=:!Z,(h$<[I5VZ`+f\"'>ZoTE6oQ\"#Dl?Q4c.-'m$Mb1H/Nu2)eQWp),YF>M9fNeh_B-2$5c@1V,Ob&0JFi\"'G!p]a+^B\"7Mla1Kjl:2d7mniY6I:$8XVFMCLR9'm!D7<cdOE1H/Od.Q>p7F,DFL2[(u>\"6fiM\"u5QI=9Ipr\"'>ZoTE6oQ\"#Dl?MEs2\\'Q^Da2cb!c3&<KtmKGQ#1NSF>\"#gB>\"5<p;!<\\Gj\"'>ZoTE6oQ\"#Dl?MBk.?'Q^Da2qA^bXpQsD>P\\^diY6I:$8XVFk!(fU1NWC#\"#gB>\"2b1?#Isl-!a*nU_$L3G\"7Mla1Kjl:2d=E:2qA^bl8CS%F&k(U>K.L=<cds]1H/Nq-oY1JVA(gF>H/Z%eh_BM$8XVFjsi=@'m&pe1H/OH!]S[dF/g2^2[)!m#1c*q,6Q4A1%tbPVC)6B.g$;Y09$5>+Tmu:\"'>ZoTE6oQ\"#Dl?U)>oL'Q^Da1H/O\\2E02CF.rj@2[(uB(L,T\\!s;OBSHZ>(=9H5D\"'>ZoTE6oQ\"#Dl?RO^<tF7pJ-2d;:c2qBd+l8CFW>Fn#;eh_B-+TjY,1H.]/\"0s?p,Tlgd\"'>Zm$3OB4n\"9_<=p$Q>>DbU'<ce*V1H/Ni5r[d;F05j+2d?8\"2qBd+MEV,$\"Z$8+%OW([\"QK\\g\".9N!=9J#b!]+!^1H/Od0fS)+F05j+2d<:C2qBd+XuukG\"Z$5_<?%>1[fTY6)k&-qg(EiV\"'>X]zzz!!!#[!!!!,!!!!-z!!!!<!!!!7!!!#R\"98ET!!!!A!!!#T\"98G7#ljt<#ljrq!!!!O!!!!$\"TSO0!!!!Z!!!#P\"98FE!!!!c!!!#V\"98FW!!!!n!!!#T\"98Gg#ljtl#ljr4$31&7$31&7$31((!!!\"(!!!#S\"98G6!!!\"6!!!!)\"TSPS!!!\"D!!!#l\"98Gn!!!\"O!!!#Q\"98E.!<<+]!!!!$\"TSNI!<<+h!!!#n\"98E^!<<+t!!!#T\"98F!!<<,*!!!$!\"98E%$31'?!<<,;!!!!\"\"TSQ##lju'#lju'#ljsd!<<,J!!!!%\"TSP#!<<,V!!!#Q\"98G:!<<,`!!!#l\"98GN!<<,h!!!#X\"98G;#ljte!<<*%!<<,U\"98E.!WW31!<<,o\"98ED!WW3=!<<,S\"98E\\!WW3F!<<**\"TSNo!WW3R!<<,Q\"98F1!WW3c!<<,p\"98Gm#ljtt#ljtn#ljtn#ljs`!WW3q!<<-!\"98Fo!WW4(!<<,t\"98G2!WW43!<<,U\"98GH!WW4<!<<*%\"TSN4$31&+(BB*(!JpgZ=9FB\\\"'>Y^!<ZF+dfPmG1m\\>DRO<1=-WbBs\"/u>(=9DM$&p(K>&Hc,;;uRn\\VE\\\"J-Zf7f[0$M5\"&kX9F64jD\"Tqj/Z7/]q=02T-=9D>H4p.2U\"'>Xe9F:kdJ-62]JHQ'W!s8Wa:JVWf!s_V+g-`[Y\"'>Y(rXs;3,u^6[F64k+!WuO,!s:JX5m(3k;jo(TjsQQ#\"'>Y(rXs;C1:75e=9AX-<<iaaF7(*#!WuO,:CfVk#>\\R<503j.=9DKj-ZcEt=,6ka\"$$Hc!s8X*-RUZjmN20,\"'>X9\\gDLP+9M^G'Cc)*=9GiX;^#3E\"#j\"O(Hqp+:KuO?!s;P%AHQ$:=1AA?\"47/P=9D>D4p)$c>M;HL!WuO,'=oN3rW**'<>QH,F7(*o!s;X-!s;O2$b@[+XpP75<=cV@\"'>Z2.8qBk!s:JX:EMb&#>\\RX6N[Ej;iq1b=9GiX;^#4^\"'>X-\"'&8?\"'>Y(Q5\"DC$<-pHF.,!cWXa*=2PC-R=9AX-<E&Pm\"'>Z2.8qBk!s:JXPlUth\"'9\"?\"0s@S+]eaJ2c!3g4p)$c>M;FH\"'&8urXs:p/A2/g=9AX-<?Ib7\"'>Y(Q5\"DC$7,dV\"&o%$F.O%DQ5\"DC$<-pHF8?nURO<11+Pd&#=9D>,4p)$c>J<9'\"'&8urXs:h&<-bo=9DWd!X]%8.8qBk<<H>*!s;P%;uRDNU-C@7=9AX-<>ul4F7(+J!WuO,;uRDNrZ1A.\"'>Y,ZiUR:Z7/]q=5a8a=9DLu#BRHai<'0a\"&o13F+Q)Eq?M)5#_`?_=9CqG!=Ao2\"'%trc445XaTM]J\"&o13F3YtT\"'>X-\"*+Jc13;k)!s;OJ,;O?.*j#GF=9AX-2c$+L\"'>Y(q?M)q&%M`D=9DKj-ZeDt=+CA[\"-EWe=9D>p>F$+%:KsD=:JY2\\3_rOUdL$'Y<E%QQ\"'>X-\"#j\"O#<i7W\"9Va.#>\\R<4p(me;h4rO=9AX-<A+H_&7@:M1L'hk2t-hT\"%`Ss\"0s@S+]eaJ2c&N9\"'>Y,e,]mYN<KDd\"';Q,$3S6J\"'>Y^!<ZF+U&Y/nzzziW&rYfE;0Sg&qBUg&qBUecYsQecYsQU]^YtV??l!V??l!YQOq+YQOq+L]d\\XL]d\\Xe-#aOe-#aOF9;LCKED2SKED2SS-/flS-/flX98M'X98M'\\-)d3\\c`!5\\c`!5e-#aOe-#aOc3++Ic3++IHisELHisEL*WlBB*WlBB*WlBBN!'+\\S-/flS-/flL'.JVL]d\\XL]d\\X/cu(R/cu(R/cu(R+p.fF,Qe#H,Qe#HZ31.-X98M'X98M'[KHR1[KHR1[KHR1QimBhQimBhaoh\\Ee-#aOe-#aO,Qe#H-3F5J-3F5J-3F5J+9MTD+9MTD+p.fF+p.fF`WQ8A^]XW;^]XW;aoh\\Eaoh\\Eaoh\\Eg&qBUg&qBUe-#aOe-#aOJ-5iPJcl&RKEM8TKEM8TS-/flS-/flQimBhN!'+\\N!'+\\]EA37]EA37[KHR1[KHR1^]XW;^]XW;_?9i=_?9i=.K]YN.K]YNU'(GrU'(GrO9>O`OotabPQUsdQ370fQ370fH3=3JN!'+\\N!'+\\NW]=^NW]=^W!!)#W!!)#W!!)#X98M'Xon_)Xon_)-j'GL-j'GL-j'GLciX7JciX7JecPmPe,o[Ne,o[NdK9ILdK9ILScf#nTEG5pTEG5pRKENibQ@hFc3\"%Hc3\"%HbQInGbQInGg&qBU.K]YN/->kP/->kP/->kPH3=3JH3=3JIKTWNIKTWN_up&?`WQ8A`WQ8A-NO2IRfEEgk5bP_H3=3JH3=3JH3=3J1'7LV1]m^X1]m^X3!0-\\3!0-\\cia=Kaoh\\Eaoh\\Ecia=Kcia=KZ31.-Z31.-!!!#R^B\"E=EWZ=E=9In\"a9OA8!WW3#!WW3#z!!<6)iP,C6\"'>XG\"'>XG\"'>XG\"'>Z\\%tk5pZj-gk:'1S#EWZCK?NV#F=9Ag/zzzz!!!3'!!(pW!!(pW!!!'#!!!!$!9(Zn\".gWC#6tK<\\j-Wc$3M\"F=9AX-EWZCK6j\"#'=9IRlRL17=#QY$0!sel,!\"9,5!\"9,5!\"K87!\"K87!\"9,5!\"9,5!\"9,5!7CiI!!!6*#R7TM!@7hM\"!n%O\"!n%O!s8pC!u1o?\"6BRd=9Ap9<k9Uc$ZuO\\\"'>X-#@@Q<!u3O.\"'>X-q?UI:$O^1=$[DhV!t,K@WXIV`\"'>X-q?UI:$O^1=$dA\\S=9Ap=>H/(M!<ZF+\"8W:2$O[>HWXFpj\"'>YW(^hJt[/pG4!t2gQF4LBpq?UI:;$0o&$O^1)1CK'rF4)qN!<ZF+\".BEK)\\W`m\"(_R:\"6BRd=9B'E>J;cnRKbJ[W<!*'!sAB*?jf+\"=9AYo\"u-pJ!<ZF+\"8W:2$`sI4=9Ap=>F%&QqB9qZ$!@@4!sA6U?k8M'\"'>X5$X8oQ$a'kYdPV.'#[e%.!WuO,\"84Z]%hB1T^+]Yl$8E1rXpQm\"\"0Mtc)\\W`m\"/80k+V0\\9\"'>X5$X9V=$O^1)1Mm4r!t2+]F,!#t!WuO,$O^1)1W]\\#=9Ap=>H/&=$X8oQ$a(@gdPV.'#[e&=!<ZF+$O^1=$b69?=9A[%#[e#J$X9V=M#mc]!sAB*?jk?`\"'>X5b!:$r2+7UL!t,K@WXB373HN1jT`G6t\"0iC0#Bd0Q,m.6O!s<QG:&k7ozzz$jcn6$jcn6$4-\\4$jcn6$jcn6$jcn6!WW3#$4-\\4$4-\\4&.&=:&.&=:&.&=:+pe5L+pe5L('ss@('ss@('ss@*!lTF*!lTF'F=a>'F=a>'F=a>*!lTF*!lTF)@6BD*!lTF*!lTF&.&=:&.&=:&.&=:*!lTF*!lTF*!lTF+pe5L*!lTF*!lTF*!lTF+pe5L+pe5L*!lTF*!lTF>6\"X'0`V1RM$*eY*!lTF*!lTF('ss@('ss@(^U0B(^U0BE<#t=56(Z`OTYXa)@6BD)@6BD)@6BD*XMfH*XMfH'F=a>'F=a>(^U0B(^U0B(^U0B)@6BD)@6BD&d\\O<&d\\O<*XMfH*XMfH*XMfH+:/#J+:/#J'F=a>'F=a>+:/#J+:/#J+:/#JGQ7^Dz!!E<.ikGL7\"'>XG\"'>XG\"'>ZV!t#U2#m[amC'OhG6j!MnEWZOK'E\\pL=9BQG=9Aj0zzz!!&Gf!!$I2!!$I2z!!$I2!!$I2!!!!$!._ic+TkgK+TkgK+TkgK+TkgK#7\"J!1C(&jF-\\6Wq?UI6/H])W\"8W:2#6tK<WXEMC=9Ad5>H/'n!<ZF+#7\"J!1C(W(F1s@2\"*+JGq?UI6E<B;F\"8W:2#6tK<WXCZd=9A[%#[dlB#@\"29&Hc,;#Dt<Y\\f=!<=9Ad5>F%'R\"'>X1#@\"29#7\"J!1C*b\"F3Z'6q?UI6#7\"J5$O6o@Q88cg5]aY\"<<H>*#7\"J!1C('#F7Kc3\"'>Z;%%.A&a9<dgzzzz!!)'c!!)'c!!)-e!!)-e!!(j]!!(j]!!(j]!!)-e!!)-e!!)3g!!)3g!!)3g!!(p_!!(p_!!)3g!!)3g!!)3g!!)'c!!)'c!!)'c!!(j]!!(j]!!(j]!!(j]!!(p_!!(p_!!(p_!!#:b!!\"8E!!%!A!!)-e!!)-e!!)-e!!!!$!9:fp*<TCG*<TCG*<TCG*<TCG$^_&(!s8cr!s8XG!s>,;?j?oA>Im'3\"'>Z`#OM\\3LBn(azzzz!!(RT!!!H.!!!?+!!)9d!!!!'!9V#s/H])W/H])W/H])W/H])W$O^1q'E\\k_#;QZ1%g)oS!s>tC?jd>M>J_En\"'>X-#@@QV\"'>Yg\"Si6=Wsf45zzzz!!!B,!!!B,!!$+)!!!'#!!!'#z!8G6h!s<QGWs\\Y*+Qik.\"'>X,!!!!#!!!#7z\"otU;!M'8o=9G)q\"'>Yr!WuO,QO\\TX2tdUa#@\"29#7\"J!1VEek=9A[%#[dmg!WuO,!s<QG\"0Mtc'1E\"*!sAB*?j?oA>H/)$!<ZF+#7\"J5$`O./=9AYo\"u-o-$Y0@66jFkC,m.6O#7\"J5$Np)]?jd>M>J;eZ!<ZF+#Kf;Qc81:X\"'>X1^(,4A5ICLo=9Ad5>H/&9#@!KMq#LS\"!sA*A0b5]8=9A[%#[dnn!<ZF+\"8W:2#B^,N!s>\\-0b4B[-8?/9M@M?W`;p'C!sA6U?jd>M>J;eB!<ZF+\"8W:2#?:k.!sbtHF5@?\\\"'>X=$Y0@9!WuO,#7\"J5$O<[lF2f^4q?UI64Tedg#7\"J5$O6o@Q88cK$ZhIL\"8W:2#8%&?!s]'8Q8<@[=9Ag)+`i6!*<TCG#7\"J5$O6o@Q8<(S=9Ad5>H/&9#@!KM#Dt<Yc5D`F\"'>X-q?UI6N<02a\"+h?p+U\\DK#[dlB#@\"29#HBCtRQpuO#[dn^!<ZF+SH8mq\"%<1izzz!7h,M!#>h?!#>h?!#>h?!\"oP;!\"oP;!$DOI!$DOI!$DOI!#PtA!#PtA!#PtA!$M=B!#5J6!\"]85!#c+C!#c+C!#c+C!#c+C!\"oP;!\"oP;!#PtA!#PtA!\"]D9!\"]D9!\"]D9!$DOI!$DOI!#,\\=!#,\\=!\"]D9!\"]D9!#c+C!#c+C!#c+C!#c+C!$DOI!$DOI!$DOI!#c+C!#c+C!#>h?!#>h?!#c+C!#c+C!$2CG!$2CG!$DOI!$DOI!#,\\=!#,\\=!#,\\=!#>h?!#>h?!#PtA!#PtA!\"]D9!\"]D9!\"oP;!\"oP;!\"oP;!/U[U!(d.j!!`W,!#c+C!#u7E!#u7E!#u7E!$2CG!$2CG!!!'%,V7uj!>,E9!tbW;!tbW;\"3gr9#tWqZ#6S!^#6P\\i#6PYF+TkgK!s`E?.0EZS!s<QG$31&+zzzEW?(>EWH.?EWH.?F9)@AF9)@AF9)@AF9)@A!!3/f^B\"oK=9B-;=9B-;=9GT-nde7B%i#1K\"7Mla\"'Pd/#@#Il#M'W2XpPEb1NT]+!s`&]'aN;GF3Y[+#6b4)\"9W\\6\"ZZZe\"7Mla\"'Pd/#@$ac#?Gp>-3FKW[QFfG1NW+R!s\\u3&Hf$6!sS`*zzz!$D7A!\"/c,!\"Ao.!!*'\"!$)%>!#,D5z!!!-,\":bhE#RUXr^B$%k=9C8[=9C8[=9AYs+CGQb$X:2-)$<tC%fcq=!t.L!,m.6O/H])WkluqGF,^;)\"*+JG#@@Q<!u3Bs\"'>X8zzz!!!#U\"TSPZ\"TSPZ\"TSP\\\"TSPZ\"TSPZ\"TSPZ\"TSN@!!!#S\"TSN(!!!#S\"TSN&#QbbGNPGQP\"'>X_\"'>X_\"'>Zf-Ue.G+TkgK\"6(e<$O[2F$Om2?\"&T/&!t,?V!t,K@L,',E><4nL=9AX1?NVSV=9FEe$VWu(\"'>X-\"*+JS!u475\"'>X9#B^,O\"'>X9%pP2F8HW&sB`hH>oa^j/Acn_-\"'>X-rZ*^(\"0s+Y'*GBV?l+4n=9B?U>Ljo9#B^-f!<ZF+$Ptr.!u#JQ'>?%L'?pO[=9Ap90'4NM\"'>X-`YDkhD$*lB'*gr>(C+!P-3Foi$NoB<?jiA'\"'>XE)d>@[!<ZF+)]N\"91;*\\j=9B612K0>/!<ZF+(B=F8zzz#ljr*#ljr*])_m3F9;LCF9;LCF9;LCF9;LC!WW3#!WW3#F9;LCF9;LCF9;LC-NF,H)#sX:])_m3iW&rYFoq^E3<0$Z-3+#G]E&!4H34-IH34-I;ZHdt/H>bN]E&!4H34-IH34-I@/p9-1]RLU]E&!4!!<6/ikGL;\"'>XK\"'>XK\"'>XK\"'>ZB#,Vnmrso@G-;FX`\"'>X-\"*+JG#@@QJ\"'>X3zzzz!!!#%!!!\"D\"onXJ\"onXJ\"onW)z!s&\\d^B#&O=9B9?=9B9?=9G].o)r7+#6P'K!s8d8!scCa:'2(1=9B9?=9Ag/zzz!!\"PM!!$U8!!!'#!!$U8!!$U8!!!!$!=%Ap!<WR6!scCa:'1S#EW]\"1%2R%i!<ZF+\"98E%!WW3#<!E=&<!E=&KE(uP!!EE,\"U>A2^B&`b=9EsR=9EsR=9Ad=<\\am^=+,o+\"'>X-[LcgO#7\"JA3$eZ/!s]'8[L<BG>Daj;\"'2u[$OmjV5m(3k!s_3r%0K]7\"1B.V#>kS*!t,KZ#<;lg!t,K;\\gBuN=9JC(_?q9t%gN>DOskGT=9Ad5>IlHi#A+&?_F%]9>m\"12#6P\\MK`M9X!s>,;?jC6F=9BEC=9AX-EW[!Uzzz!!#+b!!#+b!!#+b!!!N0!!!K/!!&Ji!!\")@!!!c7!!&Mj!!$O0!!\"n\\!!\"n\\!!\"hZ!!\"hZ!!\"n\\!!\"n\\!!\"n\\!!\"n\\!!\"hZ!!\"hZ!!\"n\\!!!!(!8G9iXTAT,!so'3\"7Mla(KpnW)dE:B)r_QQXpQ+KF7pps)dD;9)qHfdrW**?\"W+9BrrfG)\"\"aUW\"7Mla(KpnW)dC`T)r_QQXpPsa>FIPkeh_Bq56Di.(TdbF\"BYcM$dT8Jj9AH`=9J#b!Z,#B(E6TH(E:p]F05ihiY6I:$5XXcg&`5E1NVt#!uhC[Wr\\7c<=A0p\"'>YN\"'>ZoTE5p5!uDn\\^(;771NT]+(E6S=3u_4AME;Un>F#a<iY6I:$5XXcU+.,51NVh9!uhC[#I5%Y#?1%Q0b4?g;[3O4#ehnr`\\_E8\\H2:'=9H5;\"'>ZoTE5p5!uDn\\eiXo&'m$Mb(E6S]\"WQG8F05iheh_B9\"rA4_Z4@o*1NS.'!uhC[&#]L9\"&npr9*57uEgm+\"!<ZF+n\"9^u=p#Q[>H0=qeeN7p\"rl,LF05id)dB$f)r_QQXpQ-!'m$Mb(E6TT*?3QcF0[(o)[.#crXs:@6kAVd$3RR_$R$%!\"#n[0h#bb(=I0,p!WuO,n\"9^u=p#Q[>O\"!`iY6I&\"rA4_l5CVm1NT]+(E6TT3uca,F6XYG)[.&@!R;0_#7',h>F$,.!s;X-i;s*`\"7Mla(KpnW)dAaM)ch%R-5RV*`]>'u'Q^Da(E6TP-6(MlF2g6C)[.#_7m`Y4M$!hu\"-!Bb=9J#b!Z,#B(E6T(3?-NaF.*:L)dAa[)qHfdc8btG\"W%:;#[l6fFTY_JYlb)1\"7Mla(KpnW)dDG8)ch%R-6(qYF05id)dC`*)ch$;3u8i?c3#\"dF,E$q)dC07)qHfdr]pW*\"W%CK>ETI$#76\\W#7')ddL&^t#)iQbnH/kq\"7Mla(KpnW)dA$t)qGaFXpPsa>N-VAeh_B%!<X8E(Td`@=Mk4N!!!!$!!!!3z!!!\".!!!!J!!!!>!!!!7!!!!^!!!!O!!!!?!!!\"+!!!!Z!!!!@!!!!]!!!!]!!!\"E!!!!h!!!!8!!!!S!!!!Q!!!\"a!!!\".!!!!7!!!#>!!!\"7!!!!?!!!#P!!!\"G!!!!7!!!#p!!!\"Nzz!s%,k!<WR6!s8XG!s&L+\"/6,%$\"C[\\!rr<$!WW3#!WW3#z!!!#U^B\"oK=9B-;=9B-;=9F*Vo`H,S!s8XG!tbW;!sJZ)zzz!!iQ)!!3-#!!!B6!<WK1#n%1Q&JM^l!VHNs=9J3u\"'>Zu!s;X-#6PYR!s`E?)$<tCN=#bi\"-!<`=9Ad5>NR+7$X:Iu\"8WU;%hB1T^+_DH=9AZ.$8E21$W`9JAHQ$:\"2[E5#@.F6!tPnu$c4D!+V+e['Ft9NAcm;\\=9Ad5>G=#!\"'>XA(L+a,D$*lB\"0Mtc)\\W`m\"%`Ss!s\\oB'7g/d=9AX1Acj%U=9FNi\"'>Yr$3OB4#6S#<-C-!<#QtBh\"p7s0#7\"9b#6P]t#5ni1=9Ad5<\\am^'o;sB\"9Va.N=#bi!s]cG1=ZF.=9A[%&RZ\\&+'ZH5\"0Mtc,E2a,=9AZB6XUG4!WuO,(C+IQ#DN=q#6P3!!s\\oB(BXnS!s>,;?jF@H\"'>X5$X:&'blRuL!tPoHjs&U_\"'>X=+(PKP!WuO,-OWt83@?1Y`]s+t\"'>X5$W`9Jo`5.s!s]'8\\h=-jAci.D-=@&`JduN#d/a>O!tPoHU,MrN\"'>X1#@\"bmR0!Im!s>,;?jEA,\"'>X-#=J[)!<ZF+#6P]t!MKSt=9AZ&/mo>+'3i1)(CO9(3>WK9c8u+12\\V#M\"'>X-XpQm6K`V?Y!ui=<)o=*A+WK)8\"'>X-\"'$->_F%]M)]N\"U2B*T>jrt``>J_o,!<ZF+q$$q'!s\\p/\\gG9E`<cYPN<',`!s]'31'[n_`<eg4=9B!7=9B'A<rNHJ!s;X-%hDmu,SLPdN]@ad>J^pR'4D-Z!s;X-\"3)'`#OMTq=9Ap=>EUPR!s;X-$O^#7$KV?l=9Ad1<k9WD-3jg=$Mb#2=9AZB6XU-(#@!?>N<B>c!s\\oCM#ikH\"'>X1!u)iV\"9Va.[/gA3!s8d?\".]Ps=9AX1Aci8?'GI/C\"'>X1!u92jaTM]J!s?D-?j?oA>EUDB\"9Va.Ylb)1!tPoHjs$2s\"'>X=+(PK0\"9Va.)]pjT_CHEG)]&`i!saP_C'OhG6j!Yr'G&.d\"'>X9%pPbdble,N!saDfC'OjX6XUH#\"9Va.-RW-<56J%q0e:cW\"'>X-VCl6i',+Ta0Gb*tN]FWR\"'>XQ$W`9JN<KDd!s8X*(X3*c=9B?U>L#;4\"#gmu\"Tqj/!s`E?m0*So!s?D-?lL%(>G=%O\"Tqj/+!4_$0E\\Hb0dEY$\"'>X-[O,AeJHZ-X!s\\oB'*AJO\",R$\\=9BK]>NR+K)dC00\"8WU;+5$f\"=9Gr3\"'>X1#?ESb\"'<GCjTP`g!s8d?\",R3a=9Ad1'GHl=\"'>X-q@R*G%hDmY0[0e(=9AZB6XU-(#@!o\\_$1!D!s]'8jrt$<>F$V8\"p7s0\"0Mtc',M$WN]@ml>F$T<XpQm&i<BBd!tu2U!tPnu$^N+E+V+e['Ft9NAcn_2\"'>Z)!<ZF+#7\"9b#6S%e#djj==9AdQ<\\am^'b.h`\"'>X1\"'2u[`]qED\":'ba\"'>X1#?ESb!u6drYmLS8!s8d?!s?D-?jDr&\"'>XA(L*1P\"0Mtc)\\W`m!tPnu$i(#0=9Ad5>IlJi#6S'1\".gWC#6tK<\\hBlc\"'>XA$W`9J\\H`4=!sAB3?k3bY>J;cnXpQlsi<KHe\"-t8=+V+e['GmkW\"'>X5$X9b?[0Qk:!s>,;?jFp]\"'>X1#@!o\\#7\"Jq+pSK[Q6ti$\"'>X5$W`9JKa7c_!s8d?\"4[VY=9AX16j!Z5<\\am^'o<-c!<ZF+T*QekN!'\"bVZ\\HC$Nn75?jG?k\"'>X-#A+(_#Qn02#7\"Jq+pSK[_CMkt\"'>X5$X8o[!s_3r#9-]!#6P^#!T==e=9Ad5>IlK<#Qn02!s`E?\".gWC#L*PW=9B3IA-3>Q1CM&M#9aT_!u)Q*#m493(Dg;m.g)p]0cQ5]\"'>X-q@R*G%hDmY0E\\Hb0bY?2<fT2:#m493\".gWC#Q4o1=9Ad5>IlHq$W`9Jkm.An!s]'8U,Lg5\"'>Z!#6S'1#7\"Ir..mlK=9AZB6XU/\\#m493#6P]t#E8oi=9AZB6XU-(#@!?>#6P]t#*Aog=9AX-EWZOK<k9Wp.gH@=$G?QE=9FNi\"'>X1!u6dr\\I&F@!s]'8Osm\"2\"'>X-_F%]9W<r`0\"/Q)%=9AdU<\\am^'b/t$\"'>X-#A+(/$3OB4#6PY^!s`E?#6PYRaU/,P!s\\p/\\gGE]#7-:rm0Nks!s]'8OsgP;'pSoQ$NjK5\"2[E5#OMj#=9JL+\"'>Z`zzz!!!#k!<<,l!<<,l!<<,l!<<,$!<<*5!!!!5!!!#N!!!#'!<<,(!<<,(!<<*S!!!!?!!!#N!!!#)!<<,*!<<,*!<<,*!<<,D!<<,\"!<<*m!!!!K!!!#E!!!#_!<<,`!<<,`!<<+S!<<,`!<<,`!<<,X!<<,X!<<,X!<<,X!<<,V!<<,V!<<,V!<<,Z!<<,Z!<<,\\!<<,\\!<<,^!<<,^!<<,^!<<,^!<<,V!<<,V!<<+R!!!!g!!!#g!!!#]!<<,^!<<,T!<<,T!<<+d!!!!p!!!#f!!!#]!<<,^!<<,T!<<,T!<<,^!<<,^!<<,`!<<,`!<<,)!!!\")!!!#f!!!#4!!!\".!!!#g!!!#U!<<,A!!!\"4!!!#g!!!#_!<<,6!<<,6!<<,6!<<,$!<<,$!<<,$!<<,Y!!!\"I!!!#o!!!\"R!<<+S!<<+S!<<*%!<<+R!!!#k!!!\"n!<<+o!<<+q!<<+q!<<+q!<<+o!<<+q!<<+q!<<*?!<<+`!!!#L!!!#G!<<,H!<<,J!<<,J!<<,J!<<,J!<<,H!<<,L!<<,L!<<,N!<<,N!<<*a!<<+p!!!#_!!!#I!<<,J!<<,J!<<,H!<<,H!<<,H!<<,H!<<,J!<<,J!<<+(!<<,)!!!#_!!!#M!<<,N!<<+6!<<,1!!!#`!!!#G!<<,H!<<,P!<<,P!<<,F!<<,J!<<,J!<<,J!<<,J!<<+U!<<,F!<<,F!<<,F!<<+]!<<+W!<<+]!<<+]!<<+d!<<,S!!!#=!!!\"Z!<<+[!<<+[!<<,`!<<+W!<<+W!<<+W!<<,f!<<,f!<<,f!<<,`!<<,`!<<,`!<<,6!<<,6!<<,6!<<+a!<<,S!<<,k!!!#B!!!\"`!<<+a!<<+g!<<+g!<<+g!<<,k!<<-\"!!!#B!!!\"d!<<+e!<<+g!<<+g!<<+a!<<+a!<<+c!<<+c!<<+c!<<+c!<<+g!<<+g!<<+e!<<+e!<<+g!<<+i!<<+i!<<+i!<<,4!!!\".!!!#/!<<,0!<<,.!<<,.!<<,0!<<,0!<<,0!<<,4!<<,4!<<,6!<<,6!<<,6!<<,.!<<,.!<<,2!<<,4!<<,4!<<,0!<<,0!<<,0!<<,2!<<,2!<<+\"!WW3T!<<,T!!!#-!<<,.!<<,4!<<,4!<<,4!<<,0!<<,0!<<,6!<<+B!WW3b!<<,^!!!\"h!<<+i!<<+i!<<+i!<<,B!<<+u!<<+u!<<+u!<<+u!<<+`!WW3r!<<,W!!!#e!<<,f!<<,f!<<,>!<<,>!<<,<!<<,<!<<,>!<<,>!<<,B!<<,B!<<,B!<<,1!WW4.!<<,<z!s&>8!AO[Y\"#0m[!sAB*?j?oA>H/'N\"'>X1#@\"29#7\"J!1C)&fF,CS4q?UI6#7\"J5$O6o@Q8=?u\"'>X-q?UI6#7\"J5$O6o@Q8;5;=9A[%#[dlB#@\"29AHQ$:#Dt<YN\\4<6=9A[%#[dlB#@\"29#7\"J!1OT@-!s]'8Q88c[%Wf2r!s<QG#7\"J!1C('#F1N/R\"'>X1qB9q*&d.t9?j@DK=9Af2$ZhIg#m4930`tM[Y6U0j7&1;=zz!!!#I#QOkQ#QOkQ#QOkM#QOkM#QOkM#QOkO#QOkO#QOkO#QOkO#QOkI#QOkI#QOkI#QOkI#QOkS#QOkS#QOkS#QOkI#QOkI#QOkK#QOkK#QOkK#QOkK#QOkS#QOkS#QOkS#QOkQ#QOkQ#QOkQ#QOkK#QOkM#QOkM#QOkO#QOkO#QOi)z!s%5n!>,E9!tbW;!tbW;\"47@_\"sq4l!s`08!s<QG&Hc,;\"onW'zzzdJs7I!WW3#!WW3#!!!#U^B\"oK=9B-;=9B-;=9I^kTE\\N^\"9SaH!tbW;!sJZ)zzz!/(=P!!3-#!!!3(!PlJOOTP\\f\"-EZf=9FZf\"'>X-VCOA3M#mc]!s8X*',-f=F+t@e!WuO,!s;I0$O^1M*i/l>=9B5f'm#*[R0!Im!s8X*',-f=F1*G0iY6I*\";=gW[N`fo\"'>X9at@bH2`1\\>!t,K@`\\u'C\"'>X-L)+/1JH>pU!s8X*'>4GL=9AX-<=dIX\"'>Z2-4_75'a%P?$aLI]$NlP!0bY]4=9B)B%s-k\\f`D7X!t1P4C't-h2DGl]!<ZF+!s;O.!s;O2B`hH>$O^1U6&bmI=9ApE4Tbcg.166L+CGQb$X:1q%0K]7!s;I0;$0o&'@ns\\Jj_0m=9B*5)0=pfo`>4t!u&[,F8dp.nfDk,.rbYn!tUD$F.*;e!<ZF+$O^1q.gr4;C(\"/H=9B6%2KSj>f`;1W!s]W+\"0DS+=9AX56j!f!<\\b$b=.'*f!WuO,'BU'OmPt\"C\"'>ZZ2\\.&F&'bu4RKi=\"$R$#gU-!Gi5FMc]+U\\DK#[e$c\"'>X=RKdj0)<)hN+VPB<2fnNp8HW&s$O^1q0FJ7mL*Z-e\"'>X9Ou[T`$t06?!u'Z.F7qor!=p=e!s;O:':K,Hee=_Y\"'>X9apiFC'BK5s=9FB^\"'>Yf!s;X-h%*0^j8oDcEW_^1\"'>X-[MrTZ$\\/9c!s8cr\"-!Bb=9Cqkzzz!!$m:!!$m:!!$a6!!$a6!!$a6!!$g8!!$g8!!$g8!!!l:!!!]5!!\"kV!!$g8!!$g8!!$g8!!$g8!!\"eT!!\"&?!!\"kV!!$g8!!$g8!!$g8!!$a6!!$a6!!$g8!!$g8!!$g8!!$a6!!$a6!!$a6!!$g8!!$g8!!$g8!!$g8!!$m:!!$m:!!$m:!!$g8!!$g8!!$X3!!#(\\!!\"kV!!$g8!!$g8!!$g8!!$a6!!$a6!!$g8!!$g8!!$m:!!$s<!!$s<!!$s<!!&&[!!#^n!!\"kV!!$g8!!$g8!!$a6!!$a6!!$a6!!$a6!!$g8!!$g8!!$g8!!'2&!!$@+!!\"kV!!$s<z!!&Sj!!$[4!!$7(!!$7(!!$=*!!$7(!!!!.!4KZD70?Wo70?Wo70?Wo$O^19/IV8)C't+O6j'+a\"'>X-q?UI:%0K]7#;UAg*]X=)!s8Wa$O[&<T`Rpj=9A[%#[e#Jl8`Se/H])W!s;O.,m.6O*<TCGkR*sj2rb>\\'3gV6',+T93jetj=9AYo\"u.?R!<ZF+Z7-S5)s%,'=9B3M>F$++\"'>X-i[HT$o`5.s!s@O30dl>h\"'>X-p,?@u)]N\"q0E]0K0d#oe\"'>X--Na_e%fuj$!WuO,'-B@>!s9q^\"3qBa'6++V!tu>PdL$'Y<>XHl\"'>X=(M!W)!<ZF+\"4etW)o2RX=9AZB1bg'SXpQm._#XX?!uLqLF+u7_q?M*8,TFZ($3OuE=9AYo\"u.X)!<ZF+\".BEK*to;u!sA6U?l'Uq>J;cnRKbJcd/a>O!tu>P^+]Z+1bfel\"'>X-p,?@mN<02a\"\"+HX!s@Zi0b4A`5VWoSXsPk>aT2KG!s@*u0e3@O/28fG!<ZF+\"6)U$*s9@b0d?e'-8?mU!WuO,\"0Mtc-PIG0!sA6U?lpI4>J;e\"\"'>X-\"#gl,#<i4l\"*+JGRKbJkd/jDP\"%rUozzz!!rW*!!rW*!(6nh!/:[X!/:[X!#Yb:!\"f22!(6nh!/:[X!/:[X!/LgZ!7UuK!3?A)!3?A)!3?A)!2p)%!2p)%!3ue/!3ue/!3?A)!3?A)!29Yt!29Yt!2p)%!2p)%!2]r#!2]r#!2]r#!2]r#!/^s\\!2'Mr!2'Mr!2p)%!2'Mr!*K:%!&+BQ!*01%!2Kf!!2Kf!!0RNd!0RNd!2Kf!!2Kf!!2Kf!!3QM+!3cY-!42q1!42q1!2p)%!2p)%!29Yt!29Yt!2Kf!!2Kf!!2Kf!!2Kf!!/U[U!([(i!)Wgu!/^s\\!/q*^!0.6`!0@Bb!0@Bb!1F)l!1X5n!1X5n!0dZf!1!fh!13rj!13rj!2]r#!2]r#!2p)%!2p)%!2p)%!3?A)!3?A)!3ue/!2]r#!!!*$jhCg.\"'>X;\"'>X;\"'>Y7OoYaQ!X##:?j@t[=9AX-EWZCK6j\";/=9Ad5>Im'-S,s$\"*<TCG&Hc,;#64`(zzz%KHJ/$NL/,$31&+49PWaH3aKNH3aKN!!!#R^B\"E=EWZ=E=9HDJgB0pE$j$D/!!3-#zzhS0('\"'>X;\"'>X;\"'>X;\"'>X-\"*+M1$`4AS`<QPHzzzz!!!'#!!!!%!W`Db^B\"oK=9B-;=9B-;=9B-;=9AY[0jk58\"'>X1`\\_E8%gWLE#6RU$!s<QG#7\"Jq65]l-\"/cCm\"VLV@$ig8-zzzz\\-;p5\\-;p5\\-;p5\\cr-7\\-;p5\\-;p5\\-;p5\\-;p5!!<5Y^B#&O=9B9?=9B9?=9I1WU's)=#o*PE!s8d8!s8XG!sS`*zzz!%IsKz!!3-#!!!*$jM(^A\"'>XO\"'>XO\"'>XO\"'>X1#@\"c)$ZHFT!s_3r+TkgK!s<QG\".gWC#8%&?\"5F!d\"_6]t#64`(zzzza9VbGap7tI%fcS0$NL/,A-;l4!!<4P^]@.3=9D8\"=9D8\"=9D8\"=9A[%#[dlB#@\"29#7\"J!1RS7G=9Af2$Zk/B\"8W:2#;lTc!sAB*?jC6F=9Ad5>H/'6\"'>X1#@!KM#Dt<YN^3dD#[dmW\"'>X-q?UI6#7\"J5$U\"So!s]'8Q88cK)0<YEM#d]\\!s]'8WXB%:>F%&g\"'>X1#@\"29#7\"J!1C*b\"F-8m&\"'>X1^(,4M3s,S*!sAB*?j?oA>H/&9#@!KMJH5jT!sct6F5fG:\"'>ZK$Gd-`p')`Azzzz!!\"VW!!\"VW!!\"VW!!\"VW!!\"\\Y!!\"b[!!\"b[!!\"\\Y!!\"\\Y!!\"b[!!\"b[!!\"JS!!\"JS!!\"PU!!\"PU!!\"JS!!\"JS!!\"JS!!\"b[!!\"b[!!\"b[!!\"\\Y!!\"\\Y!!\"\\Y!!\"PU!!\"PU!!\"PU!!\"PU!!#@d!!\">G!!!o?!!\"VW!!\"VW!!!!'!u`.-mCrZj\"'>Xo\"'>Xo\"'>X1#?ESb!u4Z8`YDkd$O^#7$4@5GOt7+O<rNF:%pSH6'+7j$3>3'1_@SR,=9AX=@0]X3=9Cto=9DL[\"Y3UY\"'./^!u4ZB\"'>X-\"*+JOzzz!!!\"*!<<++!<<*/!!!!0!!!#'z!!!\"\"!!!\"*!<<++!<<++!<<*\"!!(lj!>,E9!tbW;!tbW;\".0Dk#!h&K!s<QG&Hc,;\"TSN&zzzXoJG%!WW3#!!`Mm^]Es+\"'>Zq!<ZF+%0K]7n\"9^u=p#Q[>Q+XBeeN8/$5XXc<ZBUGF8c1B)[.&J!<ZH!\">'^X\"7Mla(KpnW)dC`T)ch%R-5RV*RQ2><1NUu/!uhC[nGr`b!<Z$u=9J#b!Z,#B(E6SA.N?qpF.*:L)dDka)qHfdOt$PQ\"W,nr#@\"VrT`G6t\"*\"EF\"7Mla(KpnW)dE\"Y)qHfdXpQ+KF8?gl)dE:R)r_QQXpQ-!'m$Mb(E6TH(E:p]F7p^Y)[.&$#.>*3!=)3F!EcN/#6P^C\"3CTH=9GZ+\"'>ZoTE5p5!uDn\\VEZ##F,E$q)dAUS)qHfdVEY/%\"W%CK7l&<i\"'>ZQ!<ZF+n\"9^u=p#Q[>LknU<ccD((E6S9/fW@tF4NGU)[.#_\"&Wp#!WuO,o`5.s\"7Mla(KpnW)dB`X)ch%R-5RV*c4_/J1NV+_!uhC[\".DVc#H7_+^]=N>\"*+Xj#0-g9ciO<X$o&7p\"&fF0!u7p?XTAT,\"7Mla(KpnW)dB=))ch%R-5RV*U+@871NTQY!uhC[N<99r!<^RJ\"'>ZoTE5p5!uDn\\ROK1VF7pq\"eeN8/$6.t=F05id)dE.X)ch%V)]'Gt`]>&>F,E$q)dDS0)qHfdqATMU\"W%9L&4Zs1#EAhn3!Y<pC'U:2mf>l?!g*Qe=9J#b!Z,#B(E6T(#TMb;F05id)dAah)qHfdc3OLk\"W,hoNs/Vf!s<QG[0$M5\"7Mla(KpnW)dC0?)r_QQXpPsa>H0k+eh_Ba3Wg<)(Tddt!E]F+Or5tfeH>tV\"5O%]=9J#b!Z,#B(E6T,3?)\"?qAU4i>NRFTeeN7p\"rA4_dL7'qF7pps)dC`O)qHfdRKa_^'m#fJ(E6T82B14'F4*&N)[.#[[Lc%9#7\"JA326M30P]VO\"1AUm%g)o4hZKh\\\"9/B(XTS`.\"7Mla(KpnW)dBa()qGaFRKaQI>LkDGeeN8/$5XXcXs\"b81NTuX!uhC[$aLUalN>N:\"'D`3$Nj$(Ylb)1!sel,!!<3$!\"o83z!%.aH!%IsK!$D7A!*9.#!(Hqg!$;1@!8%8O!0I6]!,MW8!$D7A!8@JR!-S>B!$VCC!:Kmf!/^aV!$M=B!#GY9!1!Tb!$VCCzhS0('\"'>X;\"'>X;\"'>ZX$PaJd!s8XG!tbW;!sJZ)zzz!.Y%L!!3-#!!!f8`P;Mb!<ZF+\\H)e7\"1\\F7=9FEjQ3'L9\"-t)D+Vtrf!t#.)0bY]H(ZYT(\"7ZEp=9HPr'-S.oc444u(Dg;A(`*umOqcFI\"'>X-`[EQ;@09U6!s;OBjT5Nd\"7?^6+VtsY!X]%H1D:oJr;d\"&!uq4PF/gdN!<ZF+\"2ZiK;ZlG!0inH=\"!>*6)^-;k!<ZF+(\\e\"<\"!n%O!s8X*',N>0\"0)qH+W%rq\"'>XIKEMVaZ7-_9+/K#@=9AX-2]!8@4p(lhEWZEt*AK&HqDBu\\K`V?Y!uE'e\"47/P=9AX-<<oc1\"'>XAfDu<]hA?nL(U3uC=9B?U>LEjE\"'>XA(L*1dblIoK\"!?;\"$3Ph]\"'>XA$U+Y#(L-Ge!s;OB=T_b.\"5XkL-`$hG=9BA,!=Aq&!s;X-\"/7M)1BWpd0fK2t,;D7^`X\":`\"7e0$6Nb=]0h2>g,;DhO\"'>Xe*s)NHWY$s1o`5.s!s^T&mN)H4<=90iF7((O\"'#jB\\gDKu&Uaa`!uJ<F$3Nj%=9I7t'-S/.Muj=gOs:V`(Dl]G$3LkB=9BNA&p)2\"+!_0qR0*On\"8Xkg+VtrJ!=Ar\"0bY]HN<98b\"3)?#+Wgdg2](QV\"'>XA$jm*Z,824:aT;QH\"0s?p+WoM@\"'>ZF#SS?t(UsPS\"3)`&+W#8'=9H)7\"'>Y3zzz!!!#Y!!!![#QOj$#QOj\"#QOj8#QOj8#QOkm#QOi-#ljr.#ljr.#ljr.#ljr`#ljr`#ljr.#ljr.#ljss#QOk3#QOk1#QOk1#QOi[#ljr\\#ljr]!!!!>!!!\"g\"98Gk#QOko#QOkO#64bR#64bP#64bP#64`\\#ljr^#ljr^#ljrZ#ljrZ#ljr`#ljr`#ljr`#ljr`#ljr6#QOi5#QOkI#64bH#64bn#64bl#64bl#64`,#ljr.#ljr.#ljr.#ljrT#ljrT#ljr.#ljrZ#ljrZ#ljrZ#ljr`#ljr`#ljtH#QOkG#QOjY!!!!m!!!\"g\"98GE#64bJ#64bJ#64bL#64bL#64bL#64as#QOjt#QOi3#QOiQ#QOiO#QOie#QOie#QOi/#ljr4#ljr4#ljs7#QOjL#QOjJ#QOjJ#QOiQ#ljr.#ljr.#ljsa#QOj^#QOj^#QOi1#ljr2#ljtF#QOk[#QOkY#QOkY#QOi)!s%Gt!?hPI\"!IbK\"!IbK\"!IbK!s8XG!s]'8\\j-Xf!X]#Y\"'>X-SfhDG'a%P?!s_3r&Hc,;JcUE+?`=8=zzzz!!!\"l#QOjt#QOk!#QOk!#QOjt#QOjt#QOjt#QOjt#QOi)#Qt/0!sO4j!F5e0\"'l\"2\"'l\"2\"'l\"2\"6Ls_\":lp`=9AZb.UWc#!u(tN'3u+\\\"'>X[\"'>X-\"*+JW!u(tR'6OZr'3gVJ'*At$OT>Pd\"31So!>N3V%g,kD-4_[D$Y9EB!s]3<M@W8\\=9AX1?NX:1=9BEC=9Ar*6?!k_(I]-c\"'>XW\"'>XE%p$7g!u#)R\"6(e<%hf$Z#7hJ#jsP9R=9AZF'jqOSrZ*^,(BY?VB`hH>*<6'>zzzz$NL/,$NL/,`;or=L][VW)ZTj<&HDe2`;or=g].<SL][VWL][VWL][VWL'%DUL'%DU!WW3#!WW3#L][VWMus%[Mus%[Mus%[NWT7]Mus%[Mus%[NWT7]NWT7]NWT7]NWT7]Mus%[Mus%[Mus%[!!<6$^B'#h\"'>YZ!<ZF+\"8W:2#AjQF!s]'8WXB%:>F%&MXp]<N+TqQH?jBg:=9Ad5>H/&_\"'>X1#@!KM#Dt<YnhgOG#[dlB#@\"29#7\"J!1C*b\"F,h5c\"'>X1#@!KM#Kf;QU+6?B#[dlL\"'>X1#@\"29@09U6#7\"J!1C('#F63K0\"'>X1#@\"29#7\"J!1Q;D;=9A[%#[dlB#@\"298HW&s\"8W:2#:0IS!scOMF,C>-\"*+Kt!<ZF+])mNiEi'9ezz!!!\"d#QOjl#QOjh#QOjh#QOjh#QOjj#QOjj#QOjb#QOjb#QOjb#QOjb#QOiF!!!!3!!!!i\"98Fb#QOjf#QOjh#QOjh#QOiX!!!!<!!!!l\"98Fh#QOjl#QOjl#QOjf#QOjf#QOjf#QOjb#QOjb#QOjl#QOjl#QOi)z\"T]%r^B#ng=9C,W=9C,W=9AZn*\\e$C\"'>X-jsMkk,m.6O$b@Z[!s8XG!t,34*=W*Q!s8d8!s]2t\"$$Hc!t,2G,o$Ma\"-Erh\"9>;+#ljr*zzz#ljr*$NL/,*s2KC!WW3#4pCue4pCue4pCue4pCue!!<6)ikGL7\"'>XG\"'>XG\"'>Xg[1>!n\"p4sJ!scCa:'2(1=9AX1?NV#F=9BQG=9Aj0zzz!!\"VO!!\"8K!!\"8K!!\"8K!!!'#!!!'#!!!!)!X&__^]DCU\"'>ZE!WuO,`<$-D!s8XG!u1o?\"7Mla)d3=_+'[#/+'*I&/fPm:eeK:X1NVh.\"!7[c$NjG@-B\\lI`rUHG\"'>ZoTE6'9!ui=dnj4GL'm$Mb)]r:m4<N-1F7MX\"*sEUK!WuO`=T_b.n\"9_$=p#]c>D=aPeeN8/$6('k^)8$D1NS:'\"!7[cjT>TeNs:pU`s#\\'\"FUAS\"7Mla)d3=_+'\\^V+'*IJ1E.E?l7jC?'Q`7J)]r:=5p+Z6F8caR*sESk!t`$jneuu`m/j6f\"'>ZoTE6'9!ui=dVA(+QF7pq\"+'ZGj+4`5hVA'+S\"WLGDblIpg!<ZF+n\"9_$=p#]c>HS,OiY6I:$6('kVEZ0R1NS.'\"!7[c$a'nZp&too\"'>Zm!<ZF+n\"9_$=p#]c>IFk\\iY6I:$6('keeT@Y1NVOi)]r;84<N-1F4M*/*sEU!$X:&&`<!.I=9Frm\"'>ZoTE6'9!ui=dl5Uo*'Q`7J)]r;,+<TSWF05ih+'Y$G+4`5hi\\LZY\"WIR?#[e#JDd23UklJg-=9HYH\"'>ZoTE6'9!ui=dC*2\"AF05ih+'Ya-+4`5hC',O])Zp=PY65(4'b(`W=9A[%#[e#J$X;UF$O^1I4oGEa=9Ar6%!0]4%0K]7M$!i^\"7Mla)d3=_+'[kA+'*IV-6\"%2W]hNU1NVOi)]r;P1EY1(F&j5%>FHKQeh_BI4p)l1)rh/2>IH\\9#?JD_Xpb[]%h/W7!<^:C\"'>ZoTE6'9!ui=dc3#0J'Q^Da)]r9.+4`5hr]pW.\"WIgW>N.Ak\"1&)3\"6fmi=9J#b!ZP;F)]r:=!?]lKF05ih+'ZH#+'*IV-6\"%2dM3kT1NS9O\"!7[c'D_uB$c)oIe,]Xazzz!!!!I$31&6!!!!6!!!!6\"TSNS!!!!>!!!!8\"TSNF!!!!`!!!!R!!!!8\"TSO6!!!!Z!!!!7\"TSNP$31'M!!!!r!!!!7\"TSP!!!!\"%!!!!\"!!!!I$31&S$31(:!!!\"-!!!!;\"TSPA!!!\";!!!!9\"TSNT$31(d!!!\"O!!!!9\"TSN&!!(lj!>,E9!tbW;!tbW;\"9/X(0DGtY\"*+JU\"'>X/zzz!!!#k!!!!#z\"9ASd^B\"EA?NUN8'ep^2=9C8[=9B(]$3LA<6j!l#=9AYs+CGR'\"'>X5$X:2-&Hc,;!<ZF+!s<QGo*F=b-aO3e!!!!#!!!\"$!!!\"$!!!\"&!!!\"(!!!!.!!!!,!!!!Nz!!!\"$z!s%5n!>,E9!tbW;!tbW;\"4@5n-2e>V#@@Q8\"*+JU\"'>X0zzz!!!!O!!!!#!!!!#z!s%5n!<\\o9?j?oA>Im'-U]Ll*!s_3r!s<QG!<ZF+Pn)%@%(?`O!!!#g#64bn#64bp#64bn#64bn#64`(z%g!LNm_AiH\"'>XK\"'>XK\"'>X-i[S=X'a%P?*sZ'njsPud\"<Wa,\"'>X-#@@Q8XpQlk/H])W'*iX^E<B;F+!4^U-CP,\\#djeh!<ZF+)[CKf)]N\"91)h0:NZ_1$=9BWMFTW^->D=mT+'Y`k!s;I<\"0+Ll+#O.&!uDbX^+_hT=9B3M>D=nY\"'>X='3dL\"mL3J>B`hH>T`bI\"\"5Xt)9VDTs\"9Va.,6r>n,9pEU.%LA@=9BcM'o;t!!s;X-\"7?S*0/\"t_^+_>JFTXEU>D=oD!<ZF+1G`6q+?'OJ\"#i/CL,-jO\"'>Xa2d<:.!s;IT0,IkH0/$Oe*Sg_u=9JO'02.3'%0K]7$O^aQ$4D[k,D$?k!s;X-!s<QcP6];5.Js2gjT.=cSH8mq!s>8_?m?m@>N-SH,?o3a!<ZF+*sZoj+!4_L#CupY=9GZ.\"'>XU.pLRI$^rsi0?!tp=9A[)*AJf;!WuO,$SOXF\"\"S0i/&!Sd/\"HbE=9AX-2_4P&\"'>XU#?JD_!u#)bK`_EZ\",R$\\=9BoU746=]\"'>X]#B^-.!s;X-\"0NSN/\"m\"H=9G!M.oIn2!s;X-\"0s+Y-g^s;=9AZb.UX@#!s;X-1G`6i1,C^j3\\qFS1UR8d=9C(F12n`o-UfC1U-*BBh#[[\\\"!7b#jsSg`\"'>X-`YDl'XTAT,!s8Wa-NgXu?n9>$\"'>X-XrCb%0/$P\\+QWY,=9HYJ\"'>X-\"*,J*M#eA:JHQ'W!u(MO-R7FL\"'>XI#B^.A!s;X-+!4^A1*7TB3opGG=9I(U\"'>XI#B^+j+'XmVmN*GUOTMKb\"'>XI+'Z<0\"!;+WK`hK[!s>,;?ltX:\"'>Zq!<ZF+Z8)e*jT4$:\"'>X-\"*+Jk-X2<\\-RW+Z.hc]q5LBT9=9BoUFT]/W\"'>XUM#eA>V#^[#\"#g2[zzz!!rW*!!iQ)!8RYU!!3-#!1Eui!1Eui!1j8m!1j8m!2K\\s!2K\\s!2K\\s!$_ID!#P\\9!71`H!2K\\s!2K\\s!2'Do!2'Do!1j8m!1j8m!1j8m!2'Do!2'Do!2K\\s!5ns>!5ns>!)!:l!%@mJ!8RYU!*'\"!!'(#Z!8IST!4Dt0!4W+2!4W+2!3?8&!#>P7!.OtK!([(i!8%;P!0[B_!*0(\"!8[_V!58O8!3lM(!+>j-!8[_V!58O8!58O8!6G3@!,DQ7!8[_V!58O8!58O8!8RVT!-J8A!8[_V!4W+2!3u\\,!:^$h!.b+M!8IST!3-,$!3-,$!3-,$!3-,$!\"Ar/!/^aV!7V#L!3-,$!3cP*!3cP*!2K\\s!$;4A!0mNa!8IST!!!*%%cY5('a%P?'a%P?'a%P?h#b+q,cM7g\"'>X-#@@QR\"'>X1\\gC/S,m.6O!s<QG#ljr*zzzO8o7\\z!WW3#!WW3#0EqLW0EqLW!!<5^^B#J[=9B]K=9B]K=9B]K=9FZrKEtN:%h#09$3LA86j!MnEWZE8+CGF'\"'>X1#@\"c)'a%P?#64`(zzzzaoDDAAdAA:%fcS0$NL/,1'@RW!!WH0lb<HH\"'>XO\"'>XO\"'>XO\"'>XDbQ:c=$NmO=0b4p\"<k9U[XpQm\"4Tedg\"1AbK#6tK<[Q\"Ks>Ljhtq@R*C$O^1Q0GO[l!tu&Q\"%<;o\"-t8=+U\\ASEWZLGzzzz!!'S1!!!H.!!!W3!!%HL!!!!/!:%?#`;p'C\"2t9C=9HMC\"'>X-\"*+J_,?loJ!u2:4!WuO,\"7@*_1Kaf^!t-U\\\"8Ms\"=9GiX-Qsufq?M)=-j'Q1,9m:Wl6cf]>M;FH\"'$]rrXs;/-J8G&=9BYV-?Jl4\"3qBa,OGL6=9AX5\"\"UrB-Qt\"2!<ZF+)nIA;mN)H4<?Fp;=9Bcm>F%>/!<ZF+!s;ON\\H2k8!s8X*)eB+R\"\"USW$3T5g\"'>XQrXs:l%O_)XF8@`8!WuO,-i+'hdKM/>!=Aq7.468h!s:J,,7?[;#:!I,6N[Ej-R\\m+F.tWEhuO/e/H])W!s;O.#;UAg*WlLE$OaNmF8?6[!WuO,&%X*/g&cg,\"'>XM,?rS'!s;ONOT>Pd\"!]$pQ5Chk>Fm6_\"'>X-q?er1*<TCG!s;O:'=oN3g&_?Y<>V2-\"'>XM#<i4p,?s^qGlq.N(V1r7g&cg+\"'>Z2.468h-^lE(jsL652^9Od4p)B!=9BrM&p*=R,m.6O!s;O6f`;1W\"\"QnL\"0s@'+Y+q/-Ze\\sM#d]\\\"\"V.f$3R++\"'>ZF*@E!\\!s:J,OTGVe\"1845=9JR+R0>^9\":$/U^-2W$<@90n&p&Xe]`\\F>\".CSb+Y,'B$3RR_-QsuB\"#hGL\"%%_GOTYbg\"![n7B(Z3-=9G!>-Qsuj:^R<1.468hi<'0a!s^&T^-:'L\"'>XM\"%)ho`<-3E!t>?7\"\"4'jF.,!#.pKS3K`_EZ!s8X*-R\\m+F2fDT\"9Va.!s:J,]`S@=\"\"4'jF.,#_!s;X--^GHfRKi!Y\"'>XA.pKS3V#pg%\"\"0BKF.*<$\"9Va.!s:J,SHAsr!s^&T^-8e)\"'>XQrZH9N2@h<B\\gEjn-Qsuj=:,/9.468hM$*o_!s8X*-R\\m+F06n\\!s;X--^GHfRKgk9\"'>ZE!<ZF+MuWhXzzz7Krhm7Krhm7Krhm7Krhm*!QBC*!QBC(^9s?(^9s?/d;:U1^3p[.L#kQ.L#kQ3!K?_3!K?_3X,Qa3X,QadKKUNe-,gPe-,gP(^9s?(^9s?(^9s?cijCLdKKUNdKKUNe-,gPe-,gP'F\"O;'F\"O;cijCLcijCL%L)n5%L)n5ecc$RfED6TfED6T+9hfG,R+5K+pJ#I'F\"O;'F\"O;.L#kQ.L#kQ/-Z(S0EqLW0EqLW`WZ>B`WZ>Ba9;PDa9;PDa9;PDaoqbFaoqbFErZ1?4obQ_l2gqc)?p0A)?p0AbQRtHbQRtHc341Jc341Je-,gP'F\"O;'F\"O;c341Jc341J49bcc63[Di3!K?_3!K?_3!K?_('Xa=('Xa=aoqbFaoqbFg][ZXg'%HV$3gJ1$3gJ14pCue4pCue$jH\\3e-,gPe-,gP7Krhmg&M*Q=p=s,=p=s,>Qt0.>Qt0.@Klf4Ad/58A-N#6=p=s,=p=s,=p=s,8-T%o8-T%oF9V^FGQn-JFp7pHFp7pH8-T%o8-T%oC^'k>C^'k>C^'k>?j6T2@Klf4@Klf48-T%o8d57q8d57qC^'k>C^'k>EWuLDEWuLDE!?:BE!?:BF9V^FF9V^F9EkIs9EkIs8-T%o8-T%oC^'k>C^'k>:'L[u:^-n\":^-n\"<!E=&;?d+$;?d+$C^'k>D?^(@D?^(@?3UB0?3UB0!\"AuF#04L[M$!i^\",R*^=9FB^\"'>XA(MfHD(Qe_CqE0<2\"'>X-Z6E[,5m(3k.gJKn0*bOh-=m9]\"!\\%'jsN\"g=9F6X\"'>XUU'bii+TkgK\"0NSN0/\"t_efZ(6!>dOh\"'>X-\"#hn4!A@>(!s:J4/&!Sd.ld]6!s93F,6QpT?m@6*=9A[)*AJoZ\"'>X-`YDl+E<B;F!s<Qg!s<QG)]NR]\"q:Z:!s?gr0cpMC-SZ,6c6k=[T`G6t\"!\\%n\"!]$pOshOW=5<n.!<ZF+\"6(e<,ImgW=9BcQ>pJJZK`M<$XTJZ-\"\"Pm+W[.`L;^3M#>U/J7\"'>XQ#B^.-!WuO,,6r>nSH8mq!tQndW[7HA\"'>XQ-X2TR.gL2!XTAT,!s8X(,E2a,=9AYs+CHE=,?q`4[/pG4\"!\\IC\"+^LU=9BWS,J!pS!WuO,,9pEI1@YDJ=9B']>E0if!<ZF+.k=hY1;s7r=9AZ&.krCR,=DXa!WuO,,9pF,0VngQ=9BfE%2U66+$Kdl!WuO,\"7?S*,9nF;^+e(<\"'>XQ-X2<\\m/[;k\"!]$pMB0e?\"'>XM%mC'tmL3JJ_#a^@\",R$\\=9BLr!@,;rYlOr/!s8d8!s92?&![5!=9AZ.$8E>!XpQm&T`YC!!s8W*+-?R+=9Gr?Ws:hQ$7?($\"\",I#Osh[['nl[6\"'>Y\"zzz!!!\",!rr=1!rr=1!rr<3!!!!,!!!#+!<<+7!rr=9!rr=9!rr<C!!!!;!!!#+!<<+7!rr=9!rr=7!rr=7!rr=7!rr=7!rr<r!rr=3!rr=+!rr=+!rr<j!rr<l!rr<n!rr<n!rr<p!rr<p!rr<p!rr<p!rr=*!!!!R!!!#*!<<+2!!!!X!!!##!<<*t!rr=!!rr=#!rr=#!rr='!rr='!rr='!rr=#!rr=#!rr=%!rr=%!rr=%!rr=#!rr=#!rr=)!rr=)!rr=!!rr=!!rr=#!rr=#!rr='!rr='!rr=%!rr=%!rr=%!rr=#!rr=#!rr>!!!!\"(!!!##!<<*t!rr=#!rr=#!rr=)!rr=3!rr=3!rr<&!!!![!rr<^!rr<b!rr<d!rr<d!rr<f!rr<f!rr<B!!!\"2!rr=5!rr=5!rr<$\"p#.u^B$b*=9Cto=9Cto=9FKiSI>Se!_!2n!s?Cj?jd>M>J;cnXpQlo'*D:H-3LCX0c)hP=9Ad5>IHKr#@#b#'a%P?'+8=Q_CGj7$NgKO!s>tC?jA7c=9Aa-zzz!!\">Gz!!!H.!!!W3!!%QO!!!!$!9:fp*<TCG*<TCG*<TCG*<TCG$a9^?!s8cr!s8XG!s>,;?j?oA>Im'3\"'>Zp%eTl=rrWH*zzzz!!)Qq!!!H.!!!?+!!%6H!!!!#!;+#,;$0o&#m493n\"9^a=p\"j3>Q+X.<cds]#M'W2XpP79>N->%eh_CH!<WQ1\"&T/i!KR:6\"'>ZoTE54!!s8d4dQ[ur'Q^Da!s`&!3=\"+kF4*8T#6b3,^BI^A;$0o&^BTo0;hYW[\"'>ZoTE54!!s8d4mM?+/F-\\cf#@$ac#M(\\PmM>s1\"Tni/6j!Mk!!!*$!!!Z4z!!'q;!!\"ML!!!r<!!!$\"!!!!$!9q6!2$6q_2$6q_2$6q_2$6q_h?Ac@A*=+!#=JXr\"*+JG#=JY?\"'>X-SfhDG#7\"JE5RWMO$3M\"F=9AYs+CGEZ#@\"c)$]\"ll\"!%JG!tYG4zzzz!/(=P!+Gp.!+Gp.!+#X*!+#X*!+Gp.!+Gp.!+Z'0!+Z'0!+#X*!+#X*!+5d,!!!3'n\\5)j\"'>Xk\"'>X5$X8oX$O^1e$8hof!u'#^$3RR_%j;Sg\"#gT>\"'>X113;k)<<H>*$O8it!s<QG!s;O6&,m2_c3G'd=9AX-<<jfP=9Ap=>F$*6$X92N#m493\"3qBa$V:G&\"3CnY%!9#^5m(3k'EA+5zz;?-[s;?-[s;?-[s=9&=$<WE+\";?-[s;?-[s:]LIq:]LIq;?-[s<WE+\";?-[s;ucmu;ucmu:]LIq:]LIq-NF,H(B=F8.0'>J8cShk!\"o;)`W>0)\"'>Ze\"Tqj/jTP`g!tbW;\"7Mla-X$U\".pJH&/)h7aXpQO,>LkS\\eh_B93<Lc8-fkN\\!a#OZ\"'>ZoTE6KE\"\",U'ngl:lF1OF\\.pM9c/(QLtngjkn\"XaZgZ2k(#('@Y@<<H>*n\"9_8=p$E6>P9'r\"%K3e\"#i/CN]dKa5VY>&i[llL!s;I\\2`GO3#WL$X*]H#:CQ]H61Ee\\11L%FP2ZlOIr<\"u;>OFX9\"%K'[!BWAIjp+*Q7\\f\\Y5<iB3!<WE_4$1#6*]lRg7\\f\\Y5<iA,3(!d;U\\=dV6X/ON!s:JH!s;I\\2k!#R2`E[2RR5R]1Ee\\11L'E:1Y+@'p)O5k\"Y\\O0!tYS'TE6KE\"\",U'XsbgO1NT]+-S&Et3\\02(F6YY2.pM]f/(QLtXshHp.g7:2+%-25nigG',H(_P!s8p!\"5+%a=9FZe\"'>ZoTE6cM\"\"uH7l5DS`7\\f\\Y2`Frq3'.43U\\=dN4'U\\F!s:J@2r5Vt2`E[2iYjbq)BLgr2f%D,iY40l2_QskeeU'm1NSF\"\"#C*6d/jDP\"7Mlamg!\"u-S&DY4\"Jl<F6YY2.pIlW/(QLtME:nj\"XgVXYQ5(5eJ\\Nl\"8)]t=9J#b!\\[^Z0/Hh$5;r[6U\\=dJ2d?803s.sIpAm?;>N,Yc\"#i.t2f#E82`GNh%QCfu*]H#:CXNmI'f.!l0/Hh8,W\"\"-F/hD+1BfG>!s;X-n\"9_0=p$-&>OEaeeh_BM$7@?.W]hra1NUDo\"\"OP5!<^Ue0b`^SWXLTufa\\*d\"5O%]=9J#b![h.R-S&E4\"=r%<F645c.pK#-.op`b-7dX^F05it.pLjg/(QLt\\c`*c\"XaEC5%),/aVFtWrre;a\"'>ZoTE6KE\"\",U'iYa7IF7pq..pLF].op`j!@KC%L&igU1NUu(\"\"OO&+7'$Q!<]_4\"-<Nc\\HE\":\"7Mla-X$U\".pJ/`.op`B(+\\AYF645geh_BM$7@?.p-U@]1NS^+\"\"OO&VZMn`\\,c]^#m493jTGZf\"7Mla-X$U\".pIT/.op`b-7:<JW]M`^1NTiD\"\"OO&$P,E'SIG[\"\",R0`=9J#b![h.R-S&EP#V4I^F05j#eeN8W'dkM9&hDNhF05it.pJH!/(QLted)@.\"XhIuMC)_PiroMc(V'\\O=9H5?\"'>ZoTE6KE\"\",U'SgGsgF7pq..pLFJ.op_[5:7scXt;0T1NUtj\"\"OO&(ETj_jsTC1\"2P!?klh/k\"7Mla03SH21L#SYV?&UcRQNY67dkR`4'R:p\"/Z,S56D!H4#]5W2`JT9*]H#:CVhFL1G^150/Hh$*Ac8&F+OSu1BfG.\"p7s0n\"9_0=p$-&>J;X=<cds]-S&ED*%TSTF05it.pIT0/(QLtarL-V.g7:&!uR4*q%!SG!<^^R\"'>ZoTE6KE\"\",U'JeKZc'm$Mb/)h7aXpQO,>J_X9<ce6@/(QLtl8C\"?>FIT'eh_Ba,QfP#-`[E$!>>R#'Aippb63M(\"'>ZoTE6cM\"\"uH7ejD@u7dkR\\2d=uS\"0*b(3s,RD2`EZ(dQTSl't\"9*\"%Ma(2`Fsp)?Z9.0foI>2`EYt=1nh@niSWc3s.t@GWRukg):(e)DOGY\"#i;#2\\.u/!u9o&2ZlP<GW.Qcg):'V5qtG'\"#i.t\"'>:'2ZlP<GW.QcJi3^g&MZ?L\"#i.tSh2!B2`GNP2c_^X2_Qskg(6'k1NV,7\"#C*6Pm@JH!<_e`![h.R-S&E\\&M)EIF05it.pLFO/(QLtjq]<p>Ll.leh_B5&d'Wf-Nb;U\"8;k]\":>79)?X*R#/piM=9J#b!\\[^Z0/Hge)E.afms$cM>D<mqnd[B9\"4B:d56D!d2`H<n-TCl*2`<TR!u:b?2ZlP<GW.QcJi3_j\">Mt?\"#i.t\"':0_\"6qs&2`L.W*]H#:CYg,`'f.!l0/Hi'$T$?iF+tS81BfG*#m4;Q!UlZ_-X$U\".pM9E/(QLtXpQO,>J^OoeeN8/$7@?.L)MSn1NT]U\"\"OO&!ujW1[g2If?lOq*\"'Clo+.NE?\"+^[Z=9I4_\"'>ZoTE6cM\"\"uH7U,k487]61e2`Ft?6TYB>Vu6]Z4'V\\O\"5Y+S56HWf0gc$F;`b*P3AE`#\"&h-;ROB492`GN,#1aMF+ZD&1>J;aHeh_BA3Wh/A0;/^T=K_tuTE6KE\"\",U'Jj:jG'Q^Da-S&F##:ihrqAUe4>G=//eh_CH#6QI[-Nip'e,^N5#)`Ob\"3h/T=9J#b!\\[^Z0/Hhd%$D\\kEQU=(\"%Ma(4$-[#)?\\tI0g>aB2`ir[>W4U1%N[Pf2f$8;iY40l2_QskRQE=V1NVt-\"#C*6M$jDf\"7Mla-X$U\".pJl;/(PGVXpQO,>OEXbeh_BE63C!e-Qh+G$EF?H#Qn02XU>55\"7Mla-X$U\".pKRh/(PGVeeK^d1NT]+-S&EH.P\"P@p*M.;>L#)Veh_BY\"p6@Z-gLl+2DOq2bn:+1!s8XG\"5sUi=9J#b![h.R-S&ED1b7,lF05it.pKS'/(QLtRL0-I\"XaEC5%#<Oe,p%:R2#g+\",REg=9J#b![h.R-S&Dq1b7-5F05j#iY6H7-S&Ep%kH3GF05it.pM9j/(QLtU,2s&\"XiU?qZT@i&$,g>mfB6p\"'>Z=$j0T6n\"9_0=p$-&>K/*Beh_BM$7@?.ee0K6F6XYk.pM]g/(QLtee/'8\"XaBSOT?DV\"H\"O6+2&<i=9Iq!\"'>ZoTE6KE\"\",U'eds?4F.t35.pJ`6/)h7a<[TD%2Cm?7F4Lm).g7:2\"/,_t$c`93!s=iD0b^Mo\"'>Z!%0K]7n\"9_0=p$-&>J;I8eeN8W'e@ikF05it.pJT4.op`b-7:<JZ84#^1NTQG\"\"OO&\"-+rf'9<=n))7T`kmR[l!<^j]\"'>ZoTE6KE\"\",U'b!.CWF8c1jeeN8/$7@?.JgDqu1NU]'\"\"OO&,M3'7[fZ^S6j&to\"'>YV%Kff8n\"9_0=p$-&>M9N:<cb,P/(QLtXpQO,>>d!&1NV7Z\"\"OO&QNrZ\\57bjM\"'>Z)%Kff8n\"9_0=p$-&>I\"kl<ce6@-S&EH6S%.1F4N,p.pLF6/(QLtc9h[a\"Xai4\"[3\"j'4q=[YQTCWK`qQ\\\"5OFh=9J#b![h.R-S&D]$7k*MF05j#<cds]-S&De4=eu=F&jY=>Q--'eh_B549I);-]8$.9*=,UmfVkV\"-!fn=9J#b![h.R-S&E4+Y-T7rW+As>L!O*iY6Ir(+WF,\\iV8i>CmkGeeN8k2ChgLp),5.>KS]Oeh_B!*<Req-^lD%+SPt)(Ej_2k67LZ\"!=lPa8lD5&d)5<eIMaa\"7Mla-X$U\".pKkB.op`b-7e'iF05it.pMF+/(QLtdMr?>\"XbB'$3Pto&)dNkr=9!4\"7Mla03SH21L%:J2ZlOIr<\"u;>E1iK^'?AS\",8-W56D!d2`EZi_B1]='tFl7\"%Ma(2`Frq%Kl,U0foKg2).;teho0L'/sG(2Zm-t&-K?N0fM&\"*?I-u2f%Cn<\\kmX0/Hh4$8^6hF1+(21BfGf&-Lqn\"7Mla-X$U\".pK;(/)h7aXpQ]1'm$Mb-S&E03@iZ:F4r\\X.g7:&q?UI6#I5%Y#Q5+(\"^(L#M%Khl\"7Mla03SH21L$jp2ZlOIr<\"u;>OFZ&+6FeD4$*NZV%Ef)0fqH!=03&:^'ZSV\"1C!?5=5NBms%2e>Cna8c7^nB!s:JL'/sG(2kgs,2`E[2OojVW1Ee\\11L%!p1Y+@'rW30X\"Y\\gH\"'>ZoTE6KE\"\",U'MF8sqF8?h'.pL^A/)h7ajq]<p>M9E7iY6I:$7f.up*M.;>Q+[Seh_C$'Ec)T\"XaCr6j!P^5%,DT#t%/aSIu$,\"7Mla-X$U\".pJka/)h7aXpQ]1'm$Mb-S&ED-nA>>qAUs9'm&LQ-S&Du*%TSrF35m5.g7:&nig-I\"-!Ao#?[;qd1QO`\"7Mla-X$U\".pKFb/)h7aXpQO,>G_`Xeh_BU\"9U.X-P+6#9*6aJ=9J4/\"'>ZoTE6KE\"\",U'p(T%:'Q^Da-S&F#\"\"VqYF7'nJ.g7:&)ajdf(3`j_R1f[)\"7Mla-X$U\".pK;-/)h7aXpQ]1'm$Mb-S&EL1+Up3F1sj@.g7:&)ajea$\\ngdgB58*\"'>ZoTE6KE\"\",U'.P''bF05it.pMj6.op_[\"t(p*[R2Rr1NVh>-S&DQ'e@ikF8A'&.g7:&\",-at7itsH(l8b*=Jl>u'*D>=n\"9_0=p$-&>Oj[&<cbi6-S&E(2_3H8F,hpV.g7:2\"%r_(%rqdB!WuO,TbIT2\"7Mla-X$U\".pKS=/(PGVXpQ[[F8c1f.pM!C/(QLtVA01`\"XaEC5%#HWhuWoE\"Ao8'\"3hM^=9J#b![h.R-S&Da2Cm>nF4N,t<cb,P-S&DQ'J!4*VA(C.>G;f^eeN7p\"t(p*rZ3TL'Q[;&.pJ#F/(QLtU(d\\[\"XaBS;mui:j8oYj$bla,!s@709:#kcee>k#(\\JFD=9G*/\"'>ZoTE6cM\"\"uH7juPF'7dkR\\2d=uS\"83?^3s,RD2`E[2[Q6JP7dkR`4'RFT\"/ZAZ56HKJ0gc$F;`cp\"1H.844<?F?2f\".$iY40l2_QskL*AG)1NVhE\"#C*6m1f_*\"7Mla-X$U\".pIl</)h7aXpQO,>O\"@%eh_BA#QqgE\"XaBk6j&hiB357u('@Y@n\"9_0=p$-&>F$omeeN8/$7@?.Q3Jj?F8?h'.pJSi/)h7aXpQ]1'm$Mb-S&Eh+=l#!F-[\"4.g7:&nie$4*u#(6#JhAV\"B]Te('@Y@n\"9_0=p$-&>OE7W<cch--S&E,$nKmbF7'>:.g7:BbQ8+R!ukAF\"7eW`)po/u=9J@7\"'>ZoTE6cM\"\"uH7`],mZ7]61e2`Fsl%m'k_ms$oU>D<Ui[Lk5Y\".BKM6N`b_0h2m=A-2o92`EZSCT99OSi@cM2`GOC1ZB*)+ZD&1>Fmr9\"%Ma(2`Fsp)?[\\d0foI>2`E[i2.AL+\"%Ma(4$-[#)?Y^10g>aB2`ir[>W4V,0HN/32f\"j:iY40l2_QskVE$H`1NT-M\"#C*6r>1@o=9J#b!que#\"\",U'l9?fY'Q^Da/(PGVXpQO,>FlNZeh_BM$7f.ueeTde'm$Mb-S&Du1+QCHVA(Q31NT]+-S&E$.4`t*F4N,p.pJ#L/)h7aXpQO,>Fmr-eh_BE1'9$1-^t.f*PMOf\".gbm(CuQ.9*5:e5%\"m7?j[\"N\"qS9Gb6%k;5%\"nNKE;J_KadPV=GmCN(^!kBn\"9_8=p$E6>P8C_\"%K3e\"#i/CN]fH+7]61e4$-Zt%mL.cU\\=dR5?ik%6N]fQpAmWK>N,Yc\"#iFH\"#i:D\"#i.tSf/Y/2`GNl.cM-u+ZD&1>K.\"+eh_C06N]+J0>/5*=9J#b![h.R-S&F#,V)o:RQi/M>IlsJeh_BM$7j[BF4M'R.pK/&/)h7aeeKP_>K/6F<cdOE-S&EL)_9JqF645c.pMQU/(PGVeeKP_>D<20<cds]/(PGVXpQO,>NS:'eh_BY4Tg<;\"XiI8MC)`/#6P&/(DjY\"i;r?f!s;Pq\"p4tS!?3!W&p*1e[flO4F,Di\\&YB1L)n?@Z2`J,_\"'>ZoTE6KE\"\",U'WXUIZF7pq..pJ_Z/(QLtSe;,U\"XaEC5%#J[%0MRj\"5+Rp=9J#b!\\[^Z0/HhP$TA/WVu6]V2d>]5ShrM=W^K&R7dkRd5?lh[\",[gJ6N[EL56IVg0gcU5A-4cr2]an:2f$8liY40l2_QskVAh>B1NUPD\"#C*6Tc:`K=9J#b![h.R-S&E$-S+0jF645c.pL\"$/(QLtW[@m!\"XaDM#\"/RH!s;X-`>\\n]\"7Mla03SH21L$/#2ZlP<GW.QcJi3_j\">Mt?\"#i.t2^5OY2ZjfZ)[\"AF0fM#n=7I43N\\W=J3s.t@GWRukL(4<C+>H(_RKtW8\"6)O\"7h[sp\"#i;-2`CgRPoKnC\"u/%q\"';HA2ZlP<GW.Qcg):(U'eqcP\"#i.t^)S1Q2`GOG!`h*#2_QskV?f!/1NUhe\"#C*6`>et^\"7Mla-X$U\".pF>Neh_BM$7@?.p'WD%'m&LQ-S&EH,V.G%F!^u>?RPFK)ajc1nigI%#0@2S=9I4ZS-`r@#\\<u9!!<3$!\"/c,z!#Yb:!#,D5!##>4!%S$L!'^G`!)`t#!4iL;!5&X=!4iL;!4iL;!/U[U!*fL(!9F:_!4r42!-S>B!\"],1!:Kmf!.k1N!1sAo!!`N)!0$sY!94+\\!$)(?!13`d!9+%[!&FWU!20Am!\"f22!(?ng!4`(0!-nPE!-J;B!7LoJ!!*'\"!3#u!!8mhW!(-hg!5eg;!\"K#0!\"9#2!+lQ<!+lQ<!$_OF!&4KS!-&&?!5o$@!5o$@!#c1E!#c1E!,Vc;!)`gt!($bf!2fku!,;N7!-/,@!7q8P!-SAC!\"o83!4iL;!:^*j!.P\"L!,DZ:!8%JU!8%JU!!NH)!/ppY!%.aH!.Y%L!.Y%L!$;:C!1Eog!.b+M!&ju[!2KVq!\"f22!$hOE!$hOE!$hOE!)Wgu!42b,!\"f22!,DZ:!5/C5!':>a!-APJ!-APJ!.b4P!6G6A!!*'\"!0mWd!7V#L!-J8A!:Bge!:Bge!3ZJ)!9+\"Z!\"],1!650A!:^'i!.b+M!!iT*!\"&`,!\"&`,!:'^e!<*!!!8.JT!<3-$!$MCD!!*'\"!(@\"j!(6kg!8%DS!#Q%C!#Q%C!076_!)iq!!9=4^!3$)$!*fR*!\"o83!4r@6!+c33!/(=P!6kWH!,ho=!($bf!9\"%\\!.=nK!.b+M!<!$#!/1IS!\"T&0!$D7A!$D7A!\"fA7!0@6^!)`t#!2^)'!2^)'!%.pM!20Go!!*'\"!!iQ)!$2+?!$2+?!$2+?!$2+?!)Eau!5ej<!,DZ:!/UjZ!71cI!0.'[!$24B!$24B!2fu#!87JS!2'Gp!'U\\h!3cb0!3cb0!5/O9!#,M8!##>4!%IsK!%\\*M!%IsK!)<Lo!)NXq!)NXq!&k)^!(I%j!.\"VF!;HNo!;ZZq!;lfs!<)ru!;ZZq!;ZZq!1O/m!*'+$!'18`!3HG*!,r#?!9=4^!947`!1Eui!0.'[!9++]!9++]!!!*$jhCg6\"'>XC\"'>XC\"'>Zu#K7/\\J.EM\"=9AX-EWZE8+CGF'\"'>X-#=JY/\"'>X1#@\"c)$_.5)\"!IbK!s\\f+zzz!'1)[z!\"Ao.!\"/c,!#,P9!%J6SzhS0('\"'>X;\"'>X;\"'>X;\"'>X-\"*+L:!fmC&N<9=azzzz!!!'#!!!!$!/82h@09U6@09U6@09U6@09U6o*_8r):&`oq?UI6*<TCG#7\"J5$WR:2!sbt:F6Y\\!\"'>X-q?UI6SH/gp!sAB*?j?oA>H/&9#@!KM#JL[h\\g^JY=9Ad5>F%&k\"'>X-\"*+JK#@!KM#HeqcmN4:g=9A[%#[dn6!<ZF+#7\"J!1N<M!!sct6F34spq?UI6#7\"J5$V:G&!seZGF1sag\"'>X1MDK>1.0KDP?j?oA>H/&9#@!KMJH5jT!s]'8WXEMC=9Ad5>H/(5!<ZF+#7\"J!1Pl,7=9BrOzzzz!!(pW!!'#)!!'#)!!'#)!!'#)!!&r'!!&r'!!&l%!!&l%!!\"#>!!!W3!!$%&!!&r'!!&r'!!')+!!'#)!!'#)!!'#)!!&`!!!&`!!!&l%!!&l%!!&l%!!&r'!!&r'!!&r'!!&f#!!&f#!!&`!!!&f#!!&f#!!&f#!!&f#!!&l%!!&l%!!&`!!!&`!!!&`!!!!!#!:.B#\"Tqj/n\"9^a=p\"j3>Q+X.<caQd#M'W2XpPEn'Q^Da!s`&!\"p`^8F8c1B#6b23VZtQMP6Jl.`=!9b#VcE`\"7Mla\"'Pd/#@$aM#M'W2XpP79>O!O?eh_C</-?+\\!s&L+K)l&S!!!*$!!!?+!!!$\"!!\"8E!!!l:!!!W3z!!!!$!.hod4Tedg4Tedg#7\"J5$O6o@Q8=d,\"'>X-q?UI6#7\"J5$O6o@Q88c[%Wgbp!s<QG#Kf;Qk!9+G#[dm+\"'>X1#@\"29D$*lB\"8W:2#71K7!s]'8WXFde\"'>X1#@\"29#7\"J!1C*b\"F7'9E\"'>X-q?UI69`nK\"\"8W:2#;lTc!s]'8Q89rl=9Af2$Zh%d\"8W:2#6tK<WXB%:>F%&MXr2<O%i#1K!s]'8Q8<Xc=9Aec1NV7V>m\"12o*<SH(#0*Y\"'>XEzz!!!\"F#QOjN#QOjN#QOi6!!!!+!!!!c\"98FN#QOjT#QOjT#QOjR#QOjR#QOjN#QOjN#QOjT#QOjT#QOiR!!!!:!!!!_\"98FN#QOjR#QOjR#QOjR#QOjT#QOih!!!!D!!!!b\"98FP#QOjT#QOjN#QOjN#QOkuz!!(lj!>,E9!tbW;!tbW;!tbW;!s8XG\",IGO\"\\ZQ8\"TSN&zzzz!WW3#!!WG'^]CD8\"'>Z)!<ZF+W<!*'!s.*aA).Bh!<ZF+#7\"J!1FWE.!sAB*?j?oA>H/(%!<ZF+#Heqc`\\7Mk#[dlB#@\"29I03RR#HBCtRQpuO#[dm[\"'>X1#@\"29'a%P?#HeGUZ3@oB\"'>X-p,?@e$O^1Q0XUra=9Ad5>H/&5p,?@eK`M9X!s]'8WXDf/=9Ad5>H/'^!WuO,#7\"J!1SFjP=9Ap=>J;cnng?.&\"0Mtc'*F[-0c(K2A-:ck\"'>X1#@!KM#Kf;Q[Mmg\"\"'>X-q?UI6Pl_%i!s]'8Q88dB+`mJn*<TCG\"8W:2#=S_s!s=Dj0c-qn\"'>X1#@\"29#7\"J!1JIsR!sAB*?jFpW\"'>Z\"6jFkC!s<QG#7\"J5$TS;k!sa]>F8A*'q?UI6#7\"J5$aB^7=9Af.3HN1j\"8W:2#@R^:!sA6D0b_M,\"'>X1#@\"29#7\"J!1[tJJ=9AfB%We3p\"8W:2#AjQF!tu&Q\"2+a<=9AZ.!\\k4F!WuO,Jf\"_9$Np52?jGos\"'>Xlzzz!!!!)z!!!#q#64c##64bt#64bt#64bt#64c##64c%#64c%#64c%#64`(#QOi+#QOi+#QOl$#64c##64c!#64c!#64c'#64c'#64c'#64`,#QOi-#QOi-#QOl(#64c'#64`*#QOi+#QOl&#64c%#64`m!!!!H!!!!#\"98Gq#64bt#64bt#64bp#64bp#64br#64br#64br#64c##64c##64c'#64c'#64a<!!!!Y!!!#s!rr<(#QOi-#QOi)#QOi)#QOkq#64br#64br#64br#64`*#QOi-#QOi-#QOl(#64c'#64bp#64bp#64bp#64c%#64ah!!!!q!!!$!!rr<$#QOi)#m(;BY.t(G!WuO,[/pG4\"1814=9Ad9>;?Qg'r_6d\"'>[(!<ZF+\"0+Ll)^PSg!ui1`N[>VG=9AY[0jkAT\"'>X='3hn)',+U$*a&SI!t5)lC't-P&7?//\"'>X-W]a`/)ZpiR!IY&P!tu>PU*'R7&RZCk(L+U-\"0Mtc)[#X70ctB;=9AZ.$8Eb=(M!VB\"'>XG\"'>X-_?\"$`)]N\"A-B/$.=9G)p\"'>X1$X:n$!t/]CR0!Im!uD>U!t,2GW<1HJ\"'>X-[LcgS$O^1I34/bh=9Ap=>IFqJ$X8K;%g,kD-J8D1*t.02\"'>X-$YBL?!WuO,#7Fb],KTrg=9Ap9<\\b$b'r_6D\"'>X-_F%]Em/[;k!tu>POsgtG=.'-C!<ZF+ZO>e'8BqY`\"';#oJH5jT!s8pC!s?D-?jd>M>EUBB!u9nuV#ga$!s>,;?jd>M>IlJA!WuO,W<!*'!s8XG!t,34R0(n?\"'>X-c444e]`J:<!s]'8Q5Bi3>O!UA#@!KTblRuL!s]3<19CT[=9FZd\"'>XGzzz!!!!*!!!!E!!!\"Z!WW39\"TSN<\"TSN<\"TSNB\"TSNB\"TSNB\"TSO(!!!!S!!!\"Y!WW3A\"TSND\"TSND\"TSND\"TSNB\"TSNB\"TSNB\"TSOF!!!!_!!!\"Y!WW55!!!!=\"TSNB\"TSOV!!!!k!!!\"Y!WW3?\"TSN:\"TSN:\"TSOn!!!!t!!!\"U!WW37\"TSN:\"TSN&#QTRo!Drr$\"&T/&\"&T/&\"-a>e%6DiB;$0o&'+6u+I03RR`Z5^9(BXau%p]9>!ui3e\"/,_t=9BA`\":>5O\"'>X9%pPVR%hDm13Y)a*dL&PJ=9AX-<>1c$\"'>X-\"'#R213;k)B`hH>%hi1$6N[Ej(P)Sh=9AX-<=90iF7((Oc444m%hDm1(c_\\#!s8XG!uLqLF4)YB!<ZF+(Vg.\\\"0s?h+Vtgg#BT;60`tM['E/VcZ4;]l\"'>Z2.2O-H!s:Iq'a%P?(Rc^mjsMS[=9BoNzzz!!%lVz!!(XO!!(XO!!(\"=!!%`R!!%`R!!(pW!!(pW!!((?!!((?!!\")@!!!]5!!#@d!!%NL!!%NL!!%NL!!(XO!!(XO!!(XO!!%TN!!%TN!!%`R!!%`R!!%`R!!(jU!!(^Q!!(^Q!!%rX!!%lV!!'q;!!'q;!!%fT!!%fT!!(jU!!(XO!!(XO!!(dS!!!!$!<h>q!>tuA!uV2C!uV2C!s8XG!uV2C\"/H4g$UTaY#6S#<-3F>s#6t5/zzz!\"K25zz!\"K25!!!67\";hm])A!ku+;,^s$jIuE^]CD8\"'>Z)!<ZF+W<!*'!tuJTZ8<@\"(#]15\"'>X=(L*aR(BYB]R/mCl!s8p!\"8r6&=9B)T!t#,V\"'>X9n,j\"\"!t.L!;$0o&$O^1M5W&XG!s>,;?jf7&=9AYs+CGR[\"'>X5$X:2-/H])W!t-(d`;p'C!s8p-\"(;:6!s>tN?l'b1$3P\\Y=9AXA6j%-*=9AX5:]mBl\"'>XEj9,el!uF?-K`M9X!s>tN?l+e'\"'>Y6\"'>[)%atPpdg6*]?NUN8($P`j\"'>X-$Ub*I!<ZF+%g*M-[/gA3!s8cY\"3giK=9AY_,@Co4!<ZF+r;d\"&!t,K@mO#UJ\"'>X-$W$q6\"'>X-mO2HNnGr_o!tPJJ3s,Qb'4D81!s8XG\"#']Tzzz!+#d.!+#d.!+#d.!)`q\"!)`q\"!)`q\"!#Ph=!7h5P!#bt?!#bt?!87MT!$;1@!#,D5!:0^d!#Ph=!#Ph=!#Ph=!#Ph=!)Ndu!)Ndu!+l?6!+l?6!+5p0!+H'2!+H'2!+5p0!+5p0!*TL*!*TL*!*04&!)s($!)s($!)s($!)s($!*TL*!#bh;!!3-#!7h5P!7h5P!,Mc<!,Mc<!,Mc<!,Mc<!)Ndu!)Ndu!,2E5!&srY!&alY!-8,?!'^G`!%7mK!!!*$K\"qCm\"'>Y2\"'>Y2\"'>Ye$'PB6_$40I=9Ad5>H/(!!<ZF+#JL[hRMQ&.EWZQL)0>3j\"8W:2#6tK<WXB%:>F%&c\"'>X1#@\"29JH5jT!s]'8Q88cK$ZiHR\"8W:2#<;lg!seZGF8cgTq?UI6'a%P?\"8W:2#6tK<WXB%:>F%'f\"'>X1#@!KM;$0o&#Dt<YRPb3D#[dn\"!<ZF+#7\"J!1F3-*!s]'8WXD)p=9Ad5>H/'J\"'>X1#@!KM#Kf;QehI:'#[dmo!<ZF+.0'>JzzzPQ1[`z<X8[*<X8[*>R1<0>R1<0=pP*.>R1<0>R1<0>R1<0>R1<0=pP*.=pP*.=9nm,=9nm,=pP*.=pP*.<!WI(<X8[*<X8[*;@!7&;@!7&;@!7&;@!7&<!WI(<!WI(;@!7&<!WI(<!WI(=pP*.=pP*.=9nm,=9nm,<!WI(<!WI(<X8[*<X8[*=9nm,!!WND*%:En!>,E9!tbW;!tbW;\"\"aUW!s\\p/1'[mr.0g)Y1'[mr.1HA]\"3LfI#!op5!s<QG\"3)'`#>G;&!t,K@Ot9T8=9B'E>OE)3\"'>X-'4D,O\"'>X5$Wd662$6q_%guG;$9\\Jn\"\"==S!tu&CN]@ad>J^q?\"'>X1zzz!!!!*!!!!*!!!#+!!!#e!!!\"4!<<*;!!!!;!!!#,z!!(cg!<WFE\".BaO\"E^aQ!<ZF+!WW3#!WW3#KE(uP!!3/\\^B\"K?=9J#b!WuU.!s`'$*XC[=F05iTeh_BM$3LN;RKa#J1NW+.!s\\u3b6.bHEWZ=E=9G&unH]L!!s/H&!!<3$!!rW*!!*'\"z!!!?/\"9o,5bJXFX'*D>=#m493n\"9_,=p#us>Oig_iY6I:$6pp&iY3ck1NW+.\"\"+6sV%_Se=9BuS=9J#b![CkN,:?^D5:>\"sF05it<cds],:?^p!@QGSF4*8T-Nt`k'*C:V#MKEq$6&mH;$0o&n\"9_,=p#us>D>9geh_BM$6pp&g&`YQ1NS:6\"\"+6sUBfd@0b^Yj\"'>YJ\"'>ZoTE6?A\"!]0trXgO/'m$Mb,:?^h+=H._F05iteeN8/$6pp&L+Xk)1NW74\"\"+6s$b$73lNceb\"'G!sV#^[#\"7Mla,?b0o-X6Ef-e:(pXpQOWF/BWr-X4/D-e9#RiY3Ub>Lkna<ccPH,:?]u-n!R\\F05it<cds],:?^@'.;cRF05iteeN8c'I+u0l7j[;1NV,0\"\"+6s$aLI\\$dSs=$>C.U.oVW6$^qfFcNd/H0Y7I=!WuO,n\"9_,=p#us>P^W5iY6I:$6pp&`ZHSZ1NTiJ\"\"+6s$O^1)4q\"LqC($j>;cj,(MA%]XE<B;FYlY#0\"7Mla,?b0o-X4_6-e9#RiY3d\"'Q^Da-e:(pXpQC$>P9BkeeN8/$6pp&qE$(U1NU\\Z\"\"+6sdfh*t]*/'5\"'C'7!WuO,n\"9_,=p#us>P]9d<ce*V,:?]1-e:(pqATMa\"X=-G#Vuj^!<ZF+M$!i^\"7Mla,?b0o-X4GC-fPh]iY3Ub>L!L%<cdO^,:?]a)^j2mF3Y$n-Nt_&$cN.X-Di,R!sn9%[0$M5\"7Mla,?b0o-X4GK-e9#RXpQC$>H0k7eh_Ba3Wg`5,Cp=,=;03e\"'>ZoTE6?A\"!]0tZ32Q+'m$Mb-WY<^-7@deF05ip-X6!a-e:(p\\dANe\"XBHo%oNq[\"BUWbgAuj.\"'>ZoTE6?A\"!]0tdQ/aVF6YP+-X6-V-e:(pdQ.IX\"X=N_A\\'59!s;X-V$$m&\"7Mla,?b0o-X5RC-e9#RXpQC$>NRF`eh_BE6N\\\\>,6OM[?jd>M>IlKd!s;[*#0d8Q=9J#b![CkN,:?]I5:9KQp*M\"3>K-^leh_CD1BT!.,6J<A\"7Zj'QN70j\"*+M:\"9Va.n\"9_,=p#us>J<'EeeN8c'IQq&c8d9'1NVOi,:?\\2-e9#RXpQC$>O!F\\eh_BE3Wg`5,6J$H$i:(4(45'Eh$=*bQNXDo\"'>ZoTE6?A\"!]0tg+au+'m%q^,:?]]0IPF-F5dlY-X3_c-e:(pQ7rCg\"X>P#\")82G\"')B,XU##2\"5O+_=9J#b![CkN,:?^4'IVlSF05ip-X6Qc-e:(pmP4kl\"X=,d5qs&'$I8fV\"+^XY=9J#b![CkN,:?^d5UTTRVA(E/'m&Xu,:?^T\"t.tXF05ip-X5.^-e9#RXpQC$>M^MNeh_C<5Q`A;,6Qp[PQ@NaLBRcY(PrM%=ORDd\"p7s0n\"9_,=p#us>Lj93<cds]-fPh]XpQC$>P8IQeh_B9,m,Lu,7=TH\"76Jo!Q+p?jTYfh\"7Mla,?b0o-X6!_-WY<R\"!]0tXq2u?'Q^Da,:?]M4=A]9F7(4S-Nt^s\"/Gr*N<b(@=9FZj\"'>ZoTE6?A\"!]0tXqiD9'm&@K-e:(piY3Ub>G<&a<cds]-fPh]XpQC$>HSejeh_BM('>of,GtUK(2?M<#K$a_\"2tKI=9J#b![CkN,:?]a&gu6FF5dlY-X4S,-e9#RXpQC$>E1Ec<cdO.,:?]Q%O]g`F,hsW-Nt^s\"(VcIZ5.2]\"5*h[=OREO#6S'1n\"9_,=p#us>J^t\"iY6I:$6pp&juFeiF/BWr-X5\"0-e:(pjuEMk\"X=,(,j#+@nHl)u=9AYg$8E41$NjK5\"8W:2(S(j7=9H)>\"'>ZoTE6?A\"!]0tp+.TB1NT]+-WY;c'I+u0Q4bRr1NW7@\"\"+6sUB9:+`;pY2\"p7s0i<TNf\"7Mla,?b0o-X5^t-e9#Reh\\Nu>F%T'iY6I:$6pp&Si8%J'm&@K-e:(pXpQC$>IlpEeh_C056E8:,6PqD1$8_@\"9VU&!Xl:LC(%ETmfQYoTa:g'\"7Mla,?b0o-X5jA-WY<^-6jmBXu%NW'm%q@,:?]M)CO)lF07>%-Nt_2Z4q'*\"T8K+ZiL9R#m493n\"9_,=p#us>HU=@eh_C,'I+u0_?D=<1NT]d\"\"+6shZpG&C't-h.kq^\"$NjK5!s;I0aU&&O\"8rN.=9J#b![CkN,:?^l0.0eAp*M\"3>H/Jeeh_B1'a#fe,JkW<+W%Zn!sJe#$3OB4n\"9_,=p#us>FlES<ccPH-e:(piY3Ub>I#h.eeN8/$7FgIF05ip-X3<+-e:(pRQCU!\"X=-G#[e$EZ5!<>$`+-T!a*nVfa7g`\"7Mla,?b0o-X6!^-WY<^-6jmBRL^cHF6WiP-X5^m-e:(pRL]KJ\"X=*O;@<l<(2=3Zc8IBjnH8rn!<X,S>IH]j#m493Pm[[r\"7Mla,?b0o-X.'.eh_BM$7FC>F5dlY-X2H_-fPh]XpQC$>Co-geh_@W\"\"+6sir]B^?`=4\\#?V)I$NjK5n\"9_,=p#us>Q-6&eeN8W1F\"8OSh;DA1NU,G\"\"+6s!s;I0$aLO_$Nms]1#E5P#6S'1nI#G$\"7Mla,?b0o-X4G*-e:(piY3Ub>P8^XiY6I:$7FC\\F5dlY-X4_/-e:(p_ANG'\"XE15%otI/#,;B(\\J\"94\"'>Z%$j0T6n\"9_,=p#us>J_p=<cds]-fPh]XpQC$>E0pUeh_Ba+Tj(q,7=l`W[%t<5&(H-nj>,Fq$`Sje,][%$j0T6n\"9_,=p#us>M99/eh_BM$7FC>F5dlY-X6!U-e:(pg'.X,\"XAX&U-i=D!hg#)=9JL1\"'>ZoTE6?A\"!]0tnfT;\\F.t31-X6Q\\-e:(pnfS#^\"X=BW7g&,d\"'>X5$Wahc`]ab9K`g98\"'>Z-%0K]7n\"9_,=p#us>D=[VeeN8/$7FgIF05ip-X20K-fPh]XpQC$>O\"'neh_B!,m,Lu,6RrL;[_7f'3MFBh$jHg\"7Mla,?b0o-X4\"a-WY<./goWmF5dlY-X2Ti-e:(p[Kcm^\"XC/WcN7&4$dfFd=9F6e\"'>ZoTE6?A\"!]0t\"t.t:F5dlY-X3`--e9#RXpQC$>IkLreh_C,'I+u0c9iu1'm%q^,:?^l,U_.XF5dlY-X3GM-e:(p\"p64V,6OZ-@#G/[!=N,W%1A%FC7bV2nj>.p#,r%6=;03p\"'>ZoTE6?A\"!]0tWZihM'Q^Da,:?^$&gu6dF/gDd-NtaB%*&HP\"8*-+=9J#b![CkN,:?^$*@Fm/`\\&J`>LFrJiY6In'IQq&l8'Y4>H.uWeh_Bq.0Cq$,7Cs_7(O_r64<5_V%:NV\"'>Z)%g,o9n\"9_,=p#us>D`_7iY6In'IQq&l8'Y4>OF^'iY6In'I+u0c5S.^1NSE[\"\"+6s$^1gI!P0W'.rP]a%G;6o=9J#b![CkN,:?^4/LTNlF05iteeN8/$6pp&NWUZ[1NUDb\"\"+6sSI1hk=R-(f%g,o9n\"9_,=p#us>J^XniY6In'IQq&ME<%1>H/#Xeh_Ba#QlFX,7C[WhuT--kn!r!\"/QP2=9J#b![CkN,:?^</LOS?ME<%1>K-jpeh_Bi/H[@(,7=mo!TH6;%g,o9aUePV\"7Mla,?b0o-X6F--e:(pXpQC$>E/q9eh_CD3<LW4,PM;/&7>m>&-H#:m19A%\"7Mla,?b0o-X3_d-e9#RiY3Ub>M9**eh_BM&d'Kb,7CXVC81t8MF'$2OV%[t\"-jH#=9J#b![CkN,:?^h\"=Mb8F05iteh_C,'IVlSF05ip-X5FY-e9#RXpQC$>F#[Feh_C@\"9U\"T,HCq8\"&#6km0a\"uQNbJC\"'>ZoTE6?A\"!]0t`[3(a1NVOi,:?^\\&LZ-cF2fO/-Nt_N!u:>9kn+#\"\"7Mla,?b0o-X2HB-WY<^-6jmBauq-'1NSEf\"\"+6sKbFP:\",RWm=9J#b![CkN,:?^01agj1F5dl]<cdO^,:?^d\"t/CEF05ip-X5^:-e:(pQ6ub^\"X=*WAci8?7l&$qRg)ss]b1EL\"7Mla,?b0o-X2lE-WY<b)^?_7hBs]%1NSii\"\"+6s\".gVp$f)Et=9ILp\"'>ZoTE6?A\"!]0tau_!1'Q^Da-e9#RXpQC$>ET@Aeh_CD.g%.&,7=l`\\hAaM^B.MIM%]tn\"7Mla,?b0o-X4/6-e9#RXpQC$>N-DGeh_BY/H[@(,G>5B=ORKW#@@Q<!u:2+YnI4A\"7Mla,?b0o-X3<.-WY<^-6jmB_@.gC1NT9R\"\"+6s\\Io\"(!<X>B!!!*$!!!W3z!!)Wk!!\"GJ!!\"AH!!)<f!!(LT!!#pt!!$F-!!)<f!!'t<!!%*@!!)?g!!)<b!!&Jg!!)'_!!'kB!!#(]!!(UN!!)6d!!(@P!!'>+!!%?H!!)6d!!)fr!!%fU!!)Nl!!!Z7!!&nt!!)Ei!!(LT!!(LT!!(LT!!$(&!!(dT!!)Bh!!'V5!!)6a!!)-a!!(OO!!*!!!!)3c!!*$$!!\"\\S!!)0b!!(4L!!$R5!!#:d!!)$^!!%]U!!#[o!!)!]!!(\"F!!(\"F!!&Vo!!$F/!!)!]!!'t@!!$^7!!)$^!!!'#!!(UR!!%$@!!(s\\!!!!,!5uYRjT5Nd\"6BRd=9IXd\"'>Ze!WuO,#;UAg*i/o?=9BfI+EOCtPl_%i!s]oPg-YrE<?mb2\"'>X-\"#h;D$U+Xt+'ZHCeH#bS\"!ddXF5Au'Q5\"D/\"sa*iF8c1bRO<11&LZ'0$3SBO\"'>XMq?M)1#q)YR$3RR_,9\\FS\"'>X=\\gDKe2?O%](Vp+S=9AX-2]nRm\"'>X5\\gDKU$&nug=9AdM>J<:T!s;X--NjbYZ7.\"A-NaH0+!2Fc\"/,bu=9AdM>M;FH\"'$QjrXs;+(F,@rF64htkQ;.oZ7.\"A-NaH0+!2\"W\"!IbK!uJNqF&iAF<>ul4F7((Oc445(XTAT,!s8X*,<Z-2\"\"1/N$3R+,\"'>XMRO<1=-]%j+=9AX-<?iaf&p('=,F0$bRKi-\\\"'>X913;k)K`V?Y!s8X*'4h8J!s8X*&,cM2=9Be:-ZbRo-hIHI\"8N!#=9AX-EWZCG<=='S=9BWe>F$*J+'Y<b+!4^Q3ZfGJdL$'Y<?iaf&p*=g<<H>*Z7.\"A-NaH0+!2:_\".]Gp=9BWY4p)$3>J<;g!<ZF+!s;O.&Hc,;,Q8g,Op`M'-ZeP`h#RU[\"0s@#+X[?o2]p]S\"'>X-\"'$QjrXs:P#:#NKF.*:N\"'>XMrXs;7-KP71=9BWM4p-?:\"'>Z2.3fu`/H])W`!<1E(=*8!zzzz!!!!a#ljrj#ljsI#ljsI#ljt\"#ljt\"#ljt\"#ljsQ#ljsQ#ljs_#ljs_#ljsa#ljsc#ljse#ljsg#ljsi#ljsi#ljs%#ljs)#ljs'#ljs'#ljrp#ljrr#ljrr#ljs!#ljs!#ljrl#ljrl#ljsC#ljsC#ljt(#ljt(#ljt\"#ljt\"#ljt\"#ljsm#ljsm#ljso#ljsq#ljss#ljss#ljsm#ljsm#ljsm#ljrr#ljrt#ljrt#ljs!#ljs!#ljs_#ljs_#ljs[#ljs[#ljt&#ljt&#ljsQ#ljsS#ljsU#ljsU#ljrn#ljrn#ljrp#ljrp#ljrn#ljrn#ljsK#ljsM#ljsM#ljt(#ljrl#ljrl#ljsn!!!!q!!!\"r\"98Es#ljs##ljsi#ljs_#ljs_#ljs_#ljsC#ljsQ#ljsQ#ljrj#ljrj#ljsW#ljsY#ljsY#ljsM#ljsC#ljsC#ljsC#ljsE#ljsG#ljsG#ljt$#ljt$#ljs!#ljs!#ljs[#ljs[#ljr*!!(lj!>P]=!u1o?!u1o?!u1o?\"7u]2\"C[c0!s<QG\"TSN&zzzz('\"=7!!!#R^B\"E=EWZ=E=9G9*mLBZL$j$D/!!3-#z!!!N1%%b99d00VS!so'3\"7Mla)d3=_+'\\:W+6!uUXpQ*i>N->=eh_C<*WmJf)pnhY!E]HO\"Tqj//H])Wn\"9_,=p#us>IGD\"\"%K3e\"\"Pm+N]f#t7dkRT03a/@\"53o51BZW$0fK3o5;>5504Y/<g(PM\\\".BKM1BR_X.k?cF*\\/`kCQ8e^'IP%S,:?]a3@EB6F+us_-Nt`C\"'>ZoTE=]i=p#]c>Fn)%eeN8/$6('kL-Zp41NT-Q\"!7[cd00VSRg+TPOTm.b$)%A%=9J#b![CkN,:?]Y&1[iPVu6]J.pL^C0*=]4GV:^Sg):'^6SUA!\"#hk8\"#h_\\.r3!M/,h4D.k<,c\\j'4C+Y+cb>Q,3^eh_B!1'8m-,NSq.=9J#b!ZP;F)]r;8(*?Rup)+t3'Q[:o+'Z/\\+6!uUXpQ7OF7pq\"+'X=P+4`5heeS?0!?8<nRfpG+':f4%#\"et*$X;$dXTJZ-\"/,bu=9J#b![CkN,:?^l)_2\"[Vu6]J.pLR80*=]4GV:^SL(4=.$o'O?l3&h#\"6p\"D3tj8X\"\"u;ON^GH%(\"E?frZO!L0*>;3!X\"090eWV22_-E@%3@#M.r1:]iY3a`.jHEG\\gf)Y1NSj(\"\"+6sr;m('\"7MlaLBLc_)]r;0#Tm)gQ8fuG'Q^Da)]r;03?R5pF.*:P+'Y$Q+4`5hN[4cL\"WIOG2[^#R\"$Qeh/#E=LYlb)1\"7Mla)d3=_+'Y0u+'*IJ)B0c&_D34a1NT!L\"!7[c!s:+cd/sJQ\"4[JU=9J#b!ZP;F)]r;(\"<UZcp*L_#>OEaYeh_C,*!78d)\\;o\\F7'e9!s@]e\"8N$$=9J#b!ZP;F)]r;43Zm>qF05ih+'Z;`+4`5hdQ%CO\"WJ!K#BT;J'>+DS\".]JE\"]tl#\"9Va.n\"9_,=p#us>FIB!\"%Ma(.k=hY%KhG70eWX[2)-lhc6k>*'.[Sq0*=]4GV:^SL)'lg#r+4<`Z$Wk!s;IT.kb-X.k>N\"\"\"OHgjTG[W689u@\"'=jm\"6pLR.kA%S*\\/`kCVhO['IP%S,:?^\\(amljF.+of-Nt`O\"^b@6n\"9_$=p#]c>8A=3'm$Mb)]r:Q1`t:)F1sU9*sESk$X8c.W<EB+T)l%t\"'>ZoTE6'9!ui=dOole,F,E%$iY6In'H8,uXq;c,1NS]]\"!7[c$c<1O!L>d3!WuO,eHH%W\"7Mla)d3=_+'YT[+'*IZ)]Kl'W[f/lF,E$u+'\\\"8+4_0JRKa]Q>Ll%]iY6I:$6N;ip*L_#>M:eReh_C4#6Q%O)Zp1B_ZU(e%MT9Y$VZj'SHQP*hZ3fh!!!!$!!!!Gz!!!!W!!!!r!!!!f!!!!`\"TSO^!!!\"6!!!!]\"TSOO$31(Z!!!\"@!!!!]\"TSPg!!!\"I!!!!^\"TSQ$!!!\"Q!!!!_\"TSOQ$31'V$31&<!<<,,!!!!]\"TSO<!<<,;!!!!\\\"TSOI$31'N$31&+!s&V]^B\"QA<k9U[\"\"\"8B!V[%!d1-6\\EWZCD!!\"JT!!\"JT!!!Q1!!!!'!:df)&Hc,;&Hc,;&Hc,;<9aTfE!$2B#6W6]?jd>M>F$*T\"'>Z2.1[R870?Wo$O^11-ntg+!t,K@Q9#B]>LEi\\\"'#jBrXs:t'ib?<!s8Wa$O[2'\"&T/&!s8XG!tY55F3Xq&1^X=.\"'>X;\"'>X>zzz!!!\"T!!!\"r$31()$31()$31()$31(/$31(/$31&B!!!!0!!!!u\"TSP&$31(+$31()$31()$31()$31(/$31(-$31(1$31(1$31&+#lt,(^B\"EE?N\\S$K`M;]Glq.N(F*/D4W=Jr!s8XG!tPK7XqVBO>n84`=9B3=<j!,g\"'>X=$XFE_\"'>X-\"#h$%\"'>[)&f2]1',t084lSU@+WDAX4_bX-\"'>X-)ajc1^,fX@AHQ$:',t0T&j6>!!uE%C!t>?7!tVh!F64hdqD)dr2$6q_c6iu*)2/(n=9HqU[fn.^\"TnjI%j:oQ!!3-#!!iQ)!!iQ)!#P\\9!#P\\9!#P\\9!\"&]+!\"&]+!\"&]+!\"8i-!\"8i-!\"8i-!\"8i-!\"],1!\"],1!\"o83!#,D5!#,D5!#>P7!#>P7!#>P7!#P\\9!#P\\9!\"o83!\"o83!#P\\9!#P\\9!\"Ju/!\"],1!\"],1!!iQ)!!iQ)!8%8O!!!*$j1bU4\"'>XC\"'>XC\"'>XC\"'>X-#=JXr\"*+JGSfhDG#7\"JE5RYp@$3LkB=9G`4k78Zb\"UY50zzzz!43\"3!43\"3!43\"3!43\"3!4E.5!4E.5!!!B,lbEPs!<ZF+q#LS\"!t>?7\"7Mla-X$U\".pMuR/(PGVXpQO,>?39*1NWNr\"\"OO&q#LS\"_Zqaq=9J#b![h.R-S&EL5:]cUmM@6$>FIQ&eh_Bq56ED>-NabA!GP71=9J#b![h.R-S&Da.P'KmF05it.pMQq/(QLtOt$Pa\"XfiBlN()i(Y1Z_'6++V!s@Ze0cpK\";\\p5P'e+\\7\"'>ZoTE6KE\"\",U'p)kmF'Q^Da-S&E0)(X8oF7p^Y.g7<N!quh\"\"/,_t=9J#b![h.R-S&Du5:b;\"F4N,p.pL:O/)h7aiY3aj>Q,3beh_BE'E]ih-OUGJ!s8ooT*Hh*\"$6V4!<ZF+n\"9_0=p$-&>IlmHeeN8/$7k*MF05it.pIl`/(QLtqAfYg\"XaD4#%.fLjt:BRSH6n9=RQCk!<ZF+n\"9_0=p$-&>I#P*<cds]-S&E(-nEk)F-[OC.g7:&#@@SX!<]k5\"/,bu=9J#b![h.R-S&DY,qIO]F05j#<caQd-S&Ed\"\"RDnQ6e'@'Q]]I-S&E4.P'(+F6Wi0.g7:&rrsMH!s:I!#HA9Z#U]?Jf`D7X\"7Mla-X$U\".pK/%.op`b-7:<Jl8'sA1NT]E\"\"OO&_#sk*!<`-!\"'>ZoTE6KE\"\",U'_D3Xm'm&LQ-S&E$4tG2?F.*:\\.pM-M/(PGVXpQ]='Q^Da-S&E`1FlLIqDouS>J<ESeh_Ba1'9$1-Nj&g0nTRh\"Woo1!s;I<(BaU:OtH&'ZNF=A!lY6D=9J#b![h.R-S&F#5qCMBF4N,p.pF2Jeh_CH5m&V@-`70K*cp`jjT>Te!u'Z=F7((u\"'>Zq!s;X-n\"9_0=p$-&>J;./<ca-[-S&E\\*%TSrF+s\\t.g7:&OtC&X#90$2efM7F(Ej`c\"9Va.SHK$s\"7Mla-X$U\".pM^7/(PGVeeKP_>LGP_eh_C@6N\\hB-NfM`@+,;=#o=`u_#jdA!s?OO?l'Uq>J;fa!WuO,&-)\\1!rr<$$31&+z(B=F8)?9a;J-,cO2ZNgX-NF,HJHGlP;#gRr4obQ_J-,cOIfKHK7fWMh!<<*\"OT5@];ucmuJ-,cO=o\\O&XT/>$>lXj)JHGlP]`8$4Du]k<JcbuQirB&ZGlRgEK`_;T$jQb4$jQb4q#CBpL&_2RK*))R%flY1O8o7\\KED2S\":\"o,\":\"o,!!NN?\"r7=Co\"P32\"'>Y2\"'>Y2\"'>Y2\"'>Z)&&AQpi!0@U+CG^#\"'>X9%pRHr0`tM[=T_b.\"1B.V$P`bG!ttbN!t,3(\"!n%O!s>,;?jfC*=9Ap=>Im'1>RCQ8\"#gSq\")e9E\"'>X-\"*+JG#@@Q<!u37J\"'>X:zzzz!!!#;!!!!.!!!!0!!!\"m!WW3S\"TSNV\"TSNV\"TSNX\"TSNV\"TSNV\"TSNT\"TSNT\"TSN(!!!!O\"TSN&!!(cg!<WFE!s&L+\"6^!P$m>6G!WW3#!WW3#z!!<6&j1bU0\"'>X?\"'>X?\"'>X-\"*+L]\"R-1LU'(]'<jjt6\"'>X1#@!oF!s9kT#7\"Ja*ZY>b!sS`*zzz!&+NU!'C5]!\"Ao.!\"&]+!#Pb;zhS0('\"'>X;\"'>X;\"'>[*!mCgMp&P6tEWZmU=9A^,zzz!!\"VO!!!'#!!!!$!8P<i!s`08!s<QG!<ZF+4K8o#bQJ\"J!!!'#!!!'#z!!!!$!.hodPlUth\"-ilh=9Aec1NU8UN<',`!sAB*?jAt\"=9Ad5>H/&9#@!KM#m493\"8W:2#6tK<WXB%:>F%&M^(,5D3s,S*!sbtHF64)]\"'>X1#@\"29=T_b.#7\"J!1PGi3=9Ad5>H/'&\"'>X1#@!KM#HeGUl6HK.#[dlB#@\"29#7\"J!1H>P>!sAB*?j?oA>H/&9#@!KM#Kf;Qp(\\/A=9Ag)+`lKOE<B;F\"8W:2#>kS*!sAB*?j@PO=9G)u79bTYPlUth\"!@RDzz!'UYg!'UYg!(7(m!(7(m!'UYg!'UYg!'UYg!#5J6!\"Ju/!$h[I!(I4o!(I4o!(7(m!(7(m!'gei!'gei!'gei!'gei!(7(m!(7(m!(I4o!(I4o!(I4o!(I4o!':/\\!$M=B!$MIF!'gei!'gei!'gei!'gei!'UYg!'UYg!)`dszgV3ak\"*+L1%(-<dSc\\uq=9AU)!!!'#!!)osz!8bHk&Hc,;&Hc,;&Hc,;&Hc,;!s<QG`X:]1EM<L<zzzz!!!!#z#6=kq^]BQ#\"'>Yf\"9Va.OTYbg!s]'8Q59c2>LkV9#@!&p#HC%(#6P3!\"/uD*=9AZ6&7>_P\"'>X-[LcgS$O^1I3\"$*uSd#Q1>Il-d%pR0ueH?Cc$]P/h=9Ad5>LkV9RMBQB\",[OB%p9!:!s8X(#@R^:!sbhkC'T.h=9A[%#[dlBZ4q$Y\"-O!G%g)o4#>##\"!s8cr\".]Ps=9B3=(\"EHG!<ZF+\"/8.j',)$`hCaK_\"'>XA(L+=-(Dg<<+r;&\"_CNS+\"'>X5`]\\&Ef`;1W!s8X*'*GZS?l,43\"'>X-_F%]=blIoK!uDbXq?llr\"'>X5$X8cB$Nh-o\"H<Hb=9AZ.,;Bkr!<ZF+\"/8.j$\\\\Wa=9AX-;[Wuq,\\d^l!<ZF+(\\S\"K(\\.YA+VtLg9*;j.\"'>X5$X<HpW<!*'\"-ioi=9J3u\"'>X-_F%]=$O^152PC0S=9Ap=>I\"SD$X9bPXpW\\^\":M%.\"'>X-OpWoS!s;I,d/jDP!sb80C'Oiu%5ACP!WuO,\"8W:2#MB.\\=9Ad5>LkXE!WuO,#I5%Y#I+=4=9AX-;[;Og\"'>X1!u7@0B`hH>#6P^k\"H<Kc=9AX-2[AjS\"'>X-jr%P3\"-Pi&$i'i+=9C,W=9F]nkQ_?S%FkR`=9B'ECRPHj4prMEPlh+j!s?C@?jd(F0jkLo!s&q#!s;X-#7\"J!(Yo/q=9AZ6&7>aN!s;X-#FZBB#6Thm0b;Y6\"'>X-\"&fF0!u7d<jT>Te!s]'8ehk>J\"'>XO\"'>X1W^(;(!s_3rr<!.(!s>tC?jD5c\"'>ZI!WuO,#7\"J!(Pr7s=9Ad5>Da?`!s;X-#6S!^#6P^k\"G$XW=9AX-EWZOO>F$)9\"9Va.\"1AbK#GD8&=9Ad1(!-O!\"9Va.#FZBB#6Ti%0b4?g;[9Q1\"'>Yf!WuO,#6P^3\"Q9Ic=9AZ:6=:$'#?rt.\"9Va.]`S@=\"!R^Fzzz!!rW*!\"/c,!)ijt!#Yb:!\"o83!(m4k!%.aH!$M=B!*K:%!(?kf!%%[G!(m4k!)ERp!&\"<P!)!:l!13`d!13`d!1!Tb!1!Tb!13`d!13`d!13`d!,hi;!(-_d!)!:l!13`d!3-#!!0$sY!)*@m!)*@m!1Nrg!*fL(!*B4$!0dH`!0dH`!5AL6!+Q!/!(d.j!0dH`!)`ds!6kKD!,V]9!)3Fn!8RVT!.\"VF!)`ds!;?Hn!/(=P!*0(\"!0@0\\!0@0\\!0@0\\!29Gn!##A5!0[B_!*'\"!!%@pK!13`d!)W^r!!!0&pqHi(\"'>X3\"'>ZoTE5X-!tQ&LnfAIq'm$Mb%hi1,'GK%RF7L@S'*Sn@\"'C0Z9`nK\"g'+_k<1OOS\"'>ZoTE5X-!tQ&LngkI*'m$Mb%hi14-54rdF7Lja'*Sn@\"'E/<;$0o&n\"9^m=p#9K>D>EWeh_BM$5;D5F.*:HeeN8/$4deS[M]`ZF-\\cr'3j/l'@ns\\L-YnT\"V6@ipB+dG!s8X)!sAT(!!<3$!\"&]+z!*0(\"!#Yb:!##>4z!%@mJ!$;1@!!*'\"!!!B-%YMOtGlq.NGlq.NGlq.NGlq.NbR^]T#K?fMJduN#9`nK\"-NdD\\-3LCX0e3nZA-3bm1E41](Ej_6#@moAL')/q!s_3r!s<QG\"8WU;+!2S/^+`[l=9AZ\"2II%+%pS0?R/mCl!s>\\50d@\\@=9B3M>J;cnjt\\Y-\"/8%g)]K`#_EJnX>O\"DG!<ZF+\"1BOa#8I>C!s>tC?lL%(>IHL1)dCl7OT>Pd!ui1`_CInS=9AZ&/mo?$\"'>X-\"&fj8\"'$.g!<ZF+)?9a;zzzzPQ1[`#R(2.#R(2.&HDe2$ig8-K`V5S#R(2.$j?V2$j?V2z$3^D0$3^D0$3^D0#R(2.#R(2.#R(2.$3^D0$3^D01B7CT+92BAKE;,R6N@)d-3+#GK`V5S#R(2.#R(2.#R(2.#R(2.!\"8k5_#_pb\"'>ZQ!WuO,%0K]7n\"9_4=p$9.>Q+XVeeN8/$7dc6<\\N#[F8c1B0*NlR!WuQR\"f_rn#u/GH0`tM[n\"9_4=p$9.>Ok*6iY6I:$89sFF05j#03d]g0@hq#g&_@0\"Y1Dg&p*=RJHGEF=H`kj\"'>ZoTE6WI\"\"Q$/OtSK>'m$Mb.kb+u5VH/ZME<=A>O!preh_Bu'e`U/RQi;U>F$Qg<ce6@.kb-#+>;;%F4N,t03c..0@hq#Sj3B2\"Y16\"V?)uDdfpIidL$'Y<>Ui#rXt7mRQVJ`#BT/J)or%C\"0s?l+WKYJ\"'BWT!<ZF+n\"9_4=p$9.>IlmLiY6I:$7dc6Xsbs_'Q[;.eh_Bu1G@;oF05j#03c^80@hq#eeKi=F.,<D03a_P0@hq#qAfYk\"Y6l-(EjaL#F[$\"!NI\">K*!tFK*R/45)035\"p7s0K`V?Y\"7Mla.p<$*03cRA0@gkZjq]I#>Nu;DeeN8/$85G$rW+N&>O!1]iY6In'Ith@eg`?(1NT!&\"\"sg.$QB-L\"-O0L*s;'P0d?e\\\"9TUS3#<b<!>kS;F6Ye*Qi`cYNs3W.\"'>ZU!WuO,n\"9_4=p$9.>J`-KeeN8/$8:BQF05j#03aG_0@hq#XpQ[4>I#%uiY6I:$7dc6c3Q((F8?h+03akZ0@hq#XpQ[4>O!+[eh_BQ(BZ;o.g*6c<<iaaF7(*q\"p7j5$b@[+Oq6:J\"'#jB\\gDKu)$A.or;dS*\"Q'AbT*;V)\"'>ZoTE6WI\"\"Q$/r]r3g1NSuh0B*[eeh\\g0>LF6>eeN8/$8:BQF05j#03bG?0@hq#r]pW>\"Y71fY6/#\"1]mh[(G36'=H`mT!s;X-n\"9_4=p$9.>LGPceeN8/$7dc6l522*'m$Mb.kb,d(baGrF05j#03dQL0@hq#iYVbN\"Y5o?\"#gl,#<pH=Ylb)1Nrl-\\\"'>ZoTE6WI\"\"Q$/VF*\";F,E%003dQh0@hq#VF(G=\"Y16\"ScP,o',+T5'NG6;\"3grN=9J#b!\\7FV.kb,d3%s8*F05j#03aH#0B*[eeeKjh'm&LQ033/f)(R@Ei[Z\\5'm$Mb.kb+q/MH)tF5dleeeN8/$7dc6`W@gE1NSR?\"\"sg.Z71-_!T+(`Y6$Wr'/Mi(\"ORAT=L/7'\"Tqj/n\"9_4=p$9.>P9Eteh_Bu'e:qAQ7suC'm$Mb.kb+i\"#&4?F05j#03aSY0@hq#p*Tqq\"Y6bYq?M*84<)oT$L7l'!<ZH9!S%>U=9J#b!\\7FV.kb,())'PsF05j#03d!m033._5:\\BkW[f`'F.,<D03bFo0B*[eXpQg_F7pq203d-b0@hq#l3@DE\"Y0fk>J<;u!WuF=(]G%nmQMGQ'RZ>R(]GOurYV%,rrXMKV$7$(\"7Mla.p<$*03dEF0@hq#XpQ[4>Cm&4eh_C,%0J6e/$B*YEWa8b\"'>ZoTE6WI\"\"Q$/U'*,MF7pq6eeN8/$8:BQF05j#03a/U0@hq#U'(QO\"Y7t%qZi5a_ZVOk!!!*$!!!?+z!!)!Y!!!l:!!!`6!!\",F!!\"SN!!\"DI!!!Q6!!\"2M!!\"8O!!\"DS!!\">Q!!\">Q!!$:)!!#+]!!\"SS!!$72!!#h&!!#h&!!#h&!!%WO!!#^n!!\"/G!!#Co!!#Iq!!#=m!!#=m!!#Uu!!#\\\"!!#\\\"!!'&\"!!$U2!!!H3!!!uG!!!uG!!\"&I!!\"&I!!\",K!!\",K!!(aR!!%<F!!\")E!!)`n!!&/^!!!Q6!!\"AI!!&bo!!\">L!!#1i!!#1i!!#1i!!#dq!!';)!!\"PR!!$10!!$10!!$d8!!'q;!!\"DN!!#n(!!#t*!!$%,!!$%,!!&2`!!(@G!!\"VT!!&bp!!([Pz!!!!$!9V#s,m.6O,m.6O,m.6OK++1S!lP?P\\,m!>/H])W!s<QG#7\"JE5S4*#!s>,;?j@\\S=9AX16j\";/=9BiO=9Ad.zzz!!)co!!#n&!!#n&!!!N0!!!H.!!\"DMz!8bHk&Hc,;&Hc,;&Hc,;&Hc,;!s<QGTF6$)_[cnNzzzz!!!'#!!!!(\"p+u7\":PX)^]Eg'\"'>Zm!<ZF+m/[;k!s@*W?kX32-S,oEJfAYB(Dg,`-3Foi$b69?=9AZj.kqPD\"'>X-`YDkh,m.6O!s;I0$O^1I4^eFp!sAB*?jd@J'P\\#$\"'>X5$X;1'\"8WU;%p9!:!tPoH^+bfQ\"'>X5$X:&!9`nK\"$Ni`H\":GlD1(+1!\\H0)=\"'>X-i\\</$2$6q_\"0Mtc)kd97=9B'A<k9Uc%l4T-\"'>X-XpQls(CsQX-@l1\"=9B3IA-8,E$R$%_!<ZF+$P-:L-A_a*=9C,W=9AX-EWZCOAciDG<o,RQ!<ZF+$Nh,0i;j$_!t,33c6L\"'\"'>Z:((28r5m(3k\",8O<$P*VG\\gH)2\"'>X-#@@Q<!u8?Ir;d\"&\"+p`g!>>).d/a>O\"!IXEzzz!!rW*!\"Ao.!3u_-!$)%>!#bh;!3ZM*!+6*5!+H67!+H67!+H67!+#s3!+#s3!+#s3!+#s3!+6*5!+6*5!+6*5!)3Fn!%S$L!3ZM*!+6*5!+6*5!+H67!)s7)!*0C+!*BO-!*BO-!*BO-!*BO-!*0C+!*0C+!,hi;!':/\\!3HA(!!3-#!)s7)!)s7)!(Hqg!!!*%!oq#r'a%P?'a%P?'a%P?'a%P?!s<QK#6S#P,6R?T0ae'g6j\"#'=9HGB+[EUA!s<QG$31&+zzzz=9/C%<WN1#<WN1#<WN1#<WN1#4obQ_!!<4Q^]>_`=9BiO=9BiO=9BiO=9FNdPR04'!=&j6WXG3q\"'>X-q?UI6Glq.N\"8W:2#6tK<WXB%:>F%&MMDK=j&\"s\"+=9A[%#[dlB#@\"29;$0o&#7\"J5$O6o@Q8<(S=9Ad5>F%(%!<ZF+#7\"J!1C(W(F0Zbf\"*+JKqB9p3&Hhk8?j@DK=9AfN5]co.*<TCG#7\"J5$O6o@Q88cK$ZiI+3<N@c#HeqcmO\\P;#[dlB#@\"29=T_b.#7\"J!1N<M!!sAB*?jB+&=9BiLzzzz!!!i9!!)]u!!)]u!!)d\"!!)d\"!!!`6!!!K/!!%9I!!)j$!!)j$!!)j$!!)Ws!!)Ws!!)Ws!!)j$!!)j$!!)p&!!)p&!!)p&!!)Ws!!)]u!!)]u!!)]u!!)]u!!)d\"!!)d\"!!)d\"!!)d\"!!)j$!!)p&!!)p&!!)p&!!)]u!!)]u!!)Ws!!!!C!=G78!Po'E=9HAG\"'>X7\"'>ZoTE9`H=p'BXLB1VJ3JRW9F7pr5!J^\\[<eg_,1NWNr\",?m\\K)oUt>ETKX(B[520`tM[n\"9`7!EoSX!J^\\[l4f!SiY6I:$ASZ5'm$MbK)p`.>J:u1!S0&JnfEDaLB1WE-AMWQ1NU8J\",?m\\K)rRh>?eZc\\JSgY#@R^:\"7MlaK)o-XK)p`.>P91p!S/!,L-:.iLB1Vj!J^^,1NS^/K)p`.>Lit5!S0&JOt)(bLB1W%+bp*L1NU,.\",?m\\K)tuQQ5\"D/#*T;k+ERM_C\\e9WXs.f>\":>7:.;L*)!N@%@=9GB#\"'>ZoTE9`H=p'BXLB1WQ*JX[H1NTueLB1FsRQlE*LB1W-.u+/V'm$MbK)p`.>F#GJ!TFf7XpTd^LB1WE0o#e\\1NSic\",?m\\K)l&j<BHNP12,etXV_.BLBlc=\"'>ZoTE9`H=p'BXLB1Vf$ASZA'Q`h3LB1Fsp)/J`LB1Vj.Ye&U'm$MbK)p`.>F$\"Z!EO9!4+dQh!F++WLB5s^F4M*/LB.R2!=rC=\\gE^iVZA)J)dE.>\\gICW>>e\\1'E_Hi!i5r#=9J#b!eUMW\"+pW0!F+gkLB5s@F05k&!J^\\[W]Z%;iY6I:$A/A7!F,CdLB5s^F/h>)LB.R2!<^LK<GSuO\"'Dl3d/jDP\"7MlaK)o-XK)p`.>K/^Z!EO9Q4+dQh!F,C>LB5s@F8A\"O!J^\\[RN%\"_eeN8/$A/A7!F(F-LB5s^F-[mMLB.R2!Ge,OF,C8+\"#lDFB,<]5Tc+#8`s7S+\"'>ZoTE9`H=p'BXLB1Vr15>m2F7pr5!J^\\[ROO!meh_Bm3<P$;\"bQgX%g-a]3,9[UjUD;p\"1845=9J#b!eUMW\"+pW0!F,OhLB6BKF05k&!J^\\[c3&h&iY6I:$ASX_F7pr9!S/!,XpTd^LB1VZ5)00i1NWO]\",?m\\K)l(P!`_nP(u#7.cN<>5\"'>ZoTE9`H=p'BXLB1W-3JRXp'Q^DaK)p`.>D<06!TFf7XpTd^LB1W-'o)h@1NS9O\",?m\\K)l(T\"BB5QrXs;7*;pYf\"'>Yn\"9Va.n\"9`7!EoSX!J^\\[iYdLPeh_C42M2$c!F+P#LB5s^F5e&>LB.R2!P8KG-?GU[PoTs/\"2+g>=9J#b!eUMW\"+pW0!F)QcLB1FsRQlE*LB1WU1PZ!3F7pr9!S/!,XpTd^LB1VN0S]\\[1NTQX\",?m\\K)oce+KbaV!P'*N>2';L\"9Va.n\"9`7!EoSX!J^\\[ROs9q<ca-[K)p`.>N.Vt!S/!,^);P(LB1V25DK9j1NVP8\",?m\\K)rDE=!8qA>PeH4-E.d`=9G)t\"'>ZoTE9`H=p'BXLB1WA4,3i;F.,=G!J^\\[OrK/Weh_B9('B<m\"bQhkrXs:4,\\rhrF7()bq?Nkujt(Fq$3Ss#\"'>ZM\"Tqj/n\"9`7!EoSX!J^\\[VAY-ieeN8/$A/A7!F+D(LB1FsRQlE*LB1WE#DW?21NS:6K)p`.>N.Mq!S0&JOt)(bLB1VB\",?p.1NVCr\",?m\\K)oce''0.s37e8$-ZeDtC\\e9WhBJEiTEGT(d1-7\\cNKL;\"'>ZoTE9`H=p'BXLB1Vn/;F8W'm#*mLB6BKF-8#*!J^\\[RQ?3)iY6I:$ASZ5'm'46K)p`.>P88V!TFf7XpTpbeh_BM$A/A7!F)QSLB5s^F1s1-LB.R2!O=/`\"X1&Q\"5<l9f)oY]4p/7qNs9V,h$*s`\"7MlaK)o-XK)p`.>HSfu!EO:8-AMW]'Q^DaK)p`.>OE\\j!S0&JOt)(bLB1VJ-&2NP1NV7]\",?m\\K)obV-ZeDtb6RkKF2AQ.S-00$OTri2CBKh,\"'>ZoTE9`H=p'BXLB1VR)i\"IF'm$MbK)p`.>J_/2!EO:8)1qsF!F*8oLB5s^F2A[pLB.R2!KK0=9ikDt!t#-i*!9<4#K6oM=9J#b!eUMW\"+pW0!F'l*!S/!,XpTd^LB1V:%Yk)91NT9E\",?m\\K)traCE[V7\"'2]>Tbdf5M[&PR\"'>ZoTE9`H=p'BXLB1W5'o)h@'m$MbLB1Fsp*PCmLB1Vr)M\\@E1NSQX\",?m\\K)r8,CE[Vq)$>5<!gO#n=9J#b!eUMW\"+pW0!F)-&LB1Fsp*POqeeN8/$A/A7!F,+&LB5s^F+ui1!J^\\[^-.5P<cdsPK)p`.>Ll/s!S0&Jnd>PT!<n)VLBEV@$3RR_CTRVU!s:JpOU_KN!ODiCRO<1=-hS>Z=9I@b\"'>ZoTE9`H=p'BXLB1V:6&,Kl1NS^/K)p`.>FlRb!TFf7XpTpbeh_BM$A/A7!F*DcLB5s^F.O*KLB.R2!QtSo!`a#OrXs:`1lDU)'Q]]I\\JkWQ\"-j/p=9J#b!eUMW\"+pW0!F(F,LB6BKF05k*!S/!,Ot)(bLB1Vf!f$g-'m$MbK)p`.>Fmd/!S0&JMBi:Z!<n)V\"2b.>Rf_7]\"'D/u`<cWK\"7MlaK)o-XK)p`.>LES.!S0&JXpTpbiY6I:$A/A7!F)]`LB5s^F4(*lLB.R2!M9GB\"B>[313;k)V$dB-\")IlKF5B!0*<TCGq$@.*\"7MlaK)o-XK)p`.>KSjZ!TFf7XpTd^LB1W=\"c!-01NU\\s\",?m\\K)l)S#?;<1)Zs1ESI,I$\"7MlaK)o-XK)p`.>E0k^!S0&JXpTd^LB1W9'8HV>1NSuhK)p`.>FI't!EO:8-AMW]'Q^DaLB5s@F05k&!J^\\[juA+siY6J)*eOKK!F,CRLB5s^F65FaLB.R2!G@/j4p/+qB3W)6_Z^-BC[DEU6$!9D>M;HL(B[bAnHoA#\"7MlaK)o-XK)p`.>M9L@!EO915D&ul!F(FKLB1FsRQlE*LB1W9'o)h@1NS.6\",?m\\K)oce&p(JhCR,ZURKdR,+FO.hC\\e:-!O`$\"*<TCGW=&f1\"7MlaK)o-XK)p`.>Q-71!TFf7XpTpb<cds]K)p`.>Ik`.!EO:,)M\\@E1NT]+LB6BKF05k&!J^\\[Z2o^]<ca]oK)p`.>P:+5!S0&J\\f([+!<n)VqZUV:$OaNmquN*1oa.Z'SH/i[$NjK5n\"9`7!EoSX!J^\\[RKA6FeeN8/$A/A7!F(9`LB5s^F6Y=ZLB.R2!GhZIF2frZ*<TF0#E]Ds=9J#b!eUMW\"+pW0!F,7=LB1Fsl5G9ULB1WA%Yk)9'm$MbLB6BKF05k*!EO:8-A)>S!F)u_LB5s^F7pXWLB.R2!<WE2;iMg@!QP68\"2tZN=9J#b!eUMW\"+pW0!F%I;!TFf7qE0B2LB1Vn6\\b]n'm$MbLB1Fsp*PCmLB1Vr+bp*L1NPGVLB.R2!=,)!>J<;S#QlYgoaCq)\"7MlaK)o-XK)p`.>P\\kc!S/!,XpTd^LB1WQ)i\"IR'Q^DaK)p`.>O\")$!EO:8)1qsF!F+7^LB5s^F0[S(LB.R2!Ge,OF64icq?M)9-#\\_F$3RR_CVp0k\",dCCB8%9,=PEqg%0K]7n\"9`7!EoSX!J^\\[G)$+L'm$MbK)p`.>E1Xt!S0&JOt)(bLB1WE$&8Q41NSR8\",?m\\K)r:`rXs:d->T%tF64kC('@[b!pL-r=9J#b!eUMW\"+pW0!F)!;LB1Fsp*POqeeN8/$A/A7!F+t4LB5s^F8e<)LB.R2!GhN:F1N6-qu[9.km%;.UB-Vi\"'>ZoTE9`H=p'BXLB1W)6\\b^%'Qa+5K)p`.>P]V#!S0&JqE0N6eeN8/$ASZA'Q_P<K)p`.>HTZ8!S/!,XpTd^LB1WU)M\\@E1NWC<\",?m\\K)nKO\"$XI$#E&^hg-_,B\"'G!qeID[`\"7MlaK)o-XK)p`.>G`X#!EO:8-A)>S!F+CbLB6BKF-8#*!J^\\[Z4_oneh_C(\"p9V]\"bQi].IRHaDoiq#h#RV/%g,o9n\"9`7!EoSX!J^\\[`]&YR<cds]LB6BKF05k&!J^\\[c5VN>eh_Be/qX1[!F*PSLB5s^F3Y^,LB.R2!Rh7a-?K#GOW)gQXoSX0%g,o9n\"9`7!EoSX!J^\\[Z9<sD<cds]LB5s@F05k&!J^\\[VDs>3iY6J!2MV<6F1OGc!J^\\[VB(Emeh_BE3!4p:\"bQhg_Z@.G\"0ELE.ZXhr%g,o9n\"9`7!EoSX!J^\\[Op6[BeeN8/$ASX_F7pr5!J^\\[[NgP.eh_B5!<\\)X\"bQhg)a4A?$j5#\\ZNcC#\"'>ZoTE9`H=p'BXLB1V>(P`%N'Q^DaK)p`.>M9^F!S/!,XpTd^LB1VB\"c!-01NVss\",?m\\K)l&V2eQbn519aj)@KXL]at9J\"7MlaK)o-XK)p`.>P^@8!S0&JL-::m<ce6@K)p`.>=sYOeh_BU3<P$;\"bQhkRO<1=-YrP`F.tF^\"NU]r\".9o,=9AX-2eUqe\"'>Zu&-H#:n\"9`7!EoSX!J^\\[i[0E]<cdsPLB5s@F+ui1!J^\\[jrK3X<cds]K)p`.>J;SB!S0&Ji[+b_!<n)VZ70S%!S7Qp\"'.ar*!<bQ\"/uk7=9J#b!eUMW\"+pW0!F+h$LB5s@F05k&!J^\\[h?Sf:eh_C(/-CY.\"bQhkrXs;##MB:`=RQI\".;L)FeJnZn\"4[tc=9J#b!eUMW\"+pW0!F(.\"LB1FsRQlE*LB1V6$&8Q41NS-l\",?m\\K)oce'$UHC,In?f=9J@2\"'>ZoTE9`H=p'BXLB1W5$ASZA'Q^DaK)p`.>@*'ceh_B)6j&2F\"bQhkrXs:<%IFo1#?V)!&d)5<n\"9`7!EoSX!J^\\[hC\"'ZeeN8/$A/A7!F)E@LB5s^F7KM;LB.R2!<WF(+-cs2=N:N[&d)5<n\"9`7!EoSX!J^\\[c67rDeeN8/$A/A7!F)u8LB5s@F05k*!EO:8-A)>S!F)-HLB5s^F3Yp2LB.R2!H5mZ$GQ`6*<S*m\"7[!+=9J#b!eUMW\"+pW0!F,73LB1FsME?FkLB1W-15>m2F7pr5!J^\\[aqTU3eh_C@'Ea*k\"bQgh>@+lf_&NR+!<\\l+\"'>ZoTE9`H=p'BXLB1V2'o)fjF.,=G!J^\\[`\\WAN<cds]K)p`.>M]O=!S0&JJe\\BC!<n)V=->*Xjt5[0\")%eY'*D>=n\"9`7!EoSX!J^\\[[R5fN<cdO^K)p`.>P^O=!EO:,)M8'G!F)-'LB5s^F8A'&LB.R2!<WFe!GcTU*jQC\")$<tCq%Ej4\"7MlaK)o-XK)p`.>P9S&!S/!,qE0N6<cc\\>LB5s^F05k&!J^\\[[MXc#iY6I:$A/A7!F)]cLB5s^F7q*dLB.R2!V6?p\"nMl5(W-8U\"#huVjsQi'\"'>Z5'E_G>n\"9`7!EoSX!J^\\[^)r+2iY6J)6A#;o!F(j$LB6BKF05k&!J^\\[rWIuWeh_B]*s79!\"bQiY$(h8B>O<'X!a#Q`'E_G>n\"9`7!EoSX!J^\\[^*na;iY6I:$ASZ5'm$MbK)p`.>E0n_!S0&JRLK@S!<n)VCRQVleh[C12eSNcdfijS#)s?\"=9J#b!eUMW\"+pW0!F*u*LB6BKF05k&!J^\\[Ou%joiY6I:$A/A7!F,OELB5s^F4)]DLB.R2!<\\Mi2eV@nWs2Z.\\J53K\"7MlaK)o-XK)p`.>K.,-!TFf7XpTd^LB1V^4GNr<F7pr5!J^\\[JdR86eh_B56N`)E\"bQg\\B3W)6\"31FBC[DH2M#d][mLaO&-+t<$=9J(.\"'>ZoTE9`H=p'BXLB1WE6\\b]n'm$MbK)p`.>G<p/!S0&JM@'H@!<n)VCR,ZURKdR,+ENDHC\\e9WmK:uT\"'FjlSJD<0\"7MlaK)o-XK)p`.>M:ri!TFf7Ot)4f<cdsPK)p`.>LG3\\!S0&Jg,/tf!<n)VZ7/:`Di##-=9B(P!WrOj-8BQD_CI?b\"3*P[H\\hh,=9EKc!=AqZ(B[bACRQVl\\cDm82eQb:4p)%&>J<9'\"''.0&Hc,;C\\e9W\\d.aB\"'>Y@Q5\"D/#&F2\\F1MBfq?M*<(iQba$3RR_CE[WP('@Y@!s;OB)nIA;eeOSc\"'>YDDd3&Cq%j-8\"2YUN+^:'6\"'>X-\"''-Y\"Tqj/7l#/J-a<aU=9E1d4p)%&>M;H,#m493`]mNJ>:fqZ\"0s@k+`GU,\"'>X-\"'&FY!<ZF+B4kG73bN)0dL*r,\"'>X-\"#jkp%g,o9q?LdZDf=\\=$3Tf0\"'>X-\"#jk*1HkmGB3X(WnJVL3!s8X*CMWn^F0[(]$j0T6!s;Oj6S``F-^bhS=9AX-<Bi]'F64jD(^!kBrW-5$>L#<3+^60q>Il0\\!F&H+kl_)j\"#D]RjsL65<B$lk\"'>YD(^^B,*<TCG9/:SV*WlLE:JW`ejsQ,s\"'>YD3!obn.;L)FM%p+p!uJNqF07cn(B[bADi=c*\"47tg=9Ae@>M;FH\"''-5&Hc,;!s;On\\JG?M\")hi[\"3D,W=9AX-2eTfA\"'>Z2.;L)FCRQVlRKi9u\"'>Y<$U+XtB3W)6jW\"A)\")i*^rY!$P\"'>Z2.;L)F!s:JpW>Yk@!s8WaB4hH5!s`ICnh^FN<GQCL&p*=R_%m,T\")I`<F-8:sTE5H&Z70Q4DhT#1=9Ae@>M;FH\"''-)\"Tqj/!s;ONOW+C)\"(u7NQ5Bo1=9Ae@>J<:l*!9:FB.lFN#A78p6N[EjCZuc?=9E@8#BTk`DkmC@\"0s@k+`D.b-Zcj\"!s:JpB+I0.#A78T532kK=9E@<&p(>iCRQVlmN-0?#BRU;Kc'tp\"(sh^\"6Bjl=9AX-<GQCL&p*%[CRQVljsOs@#BS0FOU)%k\"(s\\Z!s`ICg-_P8\"'>XQ\\gDLL1BR_Z.kA1XF&iAF<A-!\\F7((O\"'%/%(^!kB#A78T4p(meCZu3/=9E@<+ERM_C\\e9Wg)P%,!t#.8)$<tC!s:JpB1\"ib#A78p6\\QK^=9GiXCE[Wh*!9:F!s;O>r>5W=\")IlKF-\\H+#Qn02'=oN3VEa#Y\"'>X9\\gDL,(]sk?'Cd\"D=9AX-<GTto\"'>Y0TE,B%?b?FI\"(OS'\"0ERG=9AX-<GQCL&p''N>m\"12CRQVleeJ8h2eV([\"'>YDDd/YXRO;koDnQbc=9HDj=!:ci>?eZcrW-5$>F%ER+^:c`\"'>Y@RO</Wob.F0\")I`<F+QKI)$<tC!s;P=C]4rfVBK`@'Q]]I\\HE\":!s8WaB4jk$\"-\"0#=9E?)'Q]]IC]5GtrW1gp\"'>X-\"'&Ej'*D>=!s;OJr=/p3\")lNh$3R[V\"'>XA>?eZcbngIa!s?gY?tYlG\"'>Z2.;L)Fh%Trn\"'=2%F.t6fZ7g9b$N:B2+]mJ9\"'>Y@Q5\"D/#&F2\\F/D0;q?M)-6.m(W=9E1\\4p/2-\"'>Z2.;L)FCRQVlqE4!R\"'>ZF*GZg:h&-;s\"53p8\")lKfrWCLK@uLH)#m493I/s<Jzz#64`($NL/,]`8$4)#sX:(B=F8V#UJq0`V1R,6.]D0ED.R@KHN0A-)`2Ac_r4Ac_r4Ac_r4;ZHdt2ZNgXOoPI^E<#t=70!;fTE\"rl63.&d63.&d63.&dP5kR_;ZHdtD?0_;W;lnu?N:'+/-,_N9EG1o9EG1o9EG1o`rH)>C]FG8%KQP0gAh3RGlRgEQ2gmbo`+slK)blO*WZ6@4ot]a4ot]a%06G/NW9%ZMZ<_W*ru?ARK*<f)$'^;2ZWmYU]:ApV>pSr:&t=p:&t=p:B:FqXoJG%JH5`N\"9SW(\"p4i*#Qk&,#Qk&,B)qu4^]4?7FTDIBliI.emK*@gn,`Rin,`RiMZEeXdf9@JM?*\\W$j-J0$j-J0'E\\=8Y5nV'i;`iXL]IJU&d&+6'E\\=8'E\\=8b5hSCmJm4eT)\\ik<WN1#<WN1#irK,[p](9o^&S-5IK9EKIK9EKpAk6o\"9AK&'EJ16$N^;.&cht4AcVl3_u]o=_u]o=]E/'5]E/'50*2+R+TVQC2?<dXD?9e<Dup\">Dup\">9*,(n0ED.R<WN1#@fcW13ro<]K`D)QScSllScSllI0'BK7KEJhLB%;SNrf:]<WN1#7KEJhS,rZjS,rZjS,rZjkQ1_akQ1_a\\H2a2AH;c27f`SiO9,C^OobU`PQCgbPQCgbeH,^NH3\"!GL&_2RpAt<pK)krP561`a#m1/-O9#=]QiI*d,6IoGS,iTi2?<dX3s,H_VuZkuC&n;7ecGgOfE)$QfE)$QciO1IciO1I>lt',[fHI/DZKh<huWlYhuWlYFTVUD_>sW:'*/(5-isAK-isAKMZWqZdK'=J@K?H/ciO1IciO1IWri>%hZ3]WGQ@dE_#jZ;lN$tcMuWhXf`M3Sp]1?p2?<dXo)esm!Wi?%/cbqP#6Y#,%KZV1H3\"!G*s;QD(BOR:HiX3Iq>pWsquQiuquQiuHia9JHia9J3s5N`-NX8J^]4?7$3C2-$3C2-<<N:%1'.FULB.ATV?-_tV?-_tCBOV;4TYT`HN=*HI09NM7KNPi-NO2INs#F_:BCLrMZ<_WT`b>q>64d)#6=f)\\HDm4Ac_r4U&Y/ncNF4JE<6+?RK*<fjTGP`HNF0I]`8$4HiX3IHiX3Ir<**#M?3bX:&t=p+oqZD+oqZD)[-3AQN@-eT`>&m0a.OWTE5)n9E>+nMuitZMuitZ7g/kmXTAJ&D?0_;>m13.\\H2a27KEJh2?<dX2?<dXGm+0J_ZBf<-ij;J;??gu<!!%\"<!!%\"Ns,L`ciO1IIK9EK*!-*?*Wc<A+9DNC+p%`E+p%`E<WW7$<WW7$8-/bk49>K_49>K_9EG1o9EG1o9EG1oiW9)[iW9)[5QUoc637,e6im>g7KNPi7KNPi7KNPi'EJ16'EJ16'EJ16IK9EKIK9EK:&t=p:&t=pkQ1_akQ1_a.KKML.KKMLS,rZjX9&A%X9&A%8-&\\j8-&\\j<WW7$<WW7$4okW`4okW`H3\"!GH3\"!GH3\"!GC]XS:C]XS:IK9EKJcPiOJcPiO\\,lX1\\,lX1_u]o=_u]o=ciO1IdK0CKdK0CK-ij;J-ij;J-ij;J-34)H-34)H-34)H8c\\nl8c\\nl9E>+n9E>+n9E>+n+9;HB+oqZD+oqZDL&q>TL&q>T/-,_N/cbqP/cbqP/cbqPj8o;]j8o;]j8o;]&cht4&cht4ZiU4-ZiU4-$j-J0$j-J0$j-J0.KKML.KKMLV?-_tV?-_t(]j[;(]j[;FohXDGQIjFGQIjF(]j[;/-5eO/-5eOHiX3IHiX3IZiU4-X9&A%X9&A%H3\"!GH3\"!G(]j[;(]j[;)?Km=)?Km=^&e97^]FK9^]FK9^]FK9!!<3$!!<3$!!<3$)?Bg<)?Bg<H3\"!GH3\"!G>QOm*>QOm*X9&A%\\,lX1\\,lX1\\,lX11]dXW2?EjY2?EjY3!''[/-5eO/-5eO49>K_49>K_Xo\\S'YQ=e)Z2t\"+Z2t\"+g]@HUg]@HU_u]o=`W?,?a8u>AaoVPCaoVPCciO1Ig]@HUg]@HU)?Bg<*!$$>*!$$>*WZ6@*WZ6@+9;HB+9;HBHia9JHia9JHia9JEWQ4@F92FBFohXDFohXDkQ1_akQ1_aoE#!moE#!m#Qk&,#Qk&,&cht4&cht4\\cMj3\\cMj3&-2b2&-2b2%KQP0&-2b2&-2b2oE#!moE#!m?3($+BE8)5EWH.?EWH.?>QOm*?31*,?31*,BEA/6>QOm*>QOm*$3C2-$3C2-$3C2-6id8f7KEJh7KEJh7KEJh7KEJhVucr!Vucr!U]LMrU]LMr/-5eO/cl\"Q0EM4S0EM4S!!<3$!!<3$!!<3$TE5)nU&k;pU&k;p1'%@T1'%@T(]aU:(]aU:Q3%$dQ3%$d8-&\\j8-&\\jH3\"!GH3\"!GQ3%$dQ3%$d2us!Z3WT3\\1'%@T1'%@TJ-#]NJcYoPKE;,RKE;,RHia9JHia9JL&q>TL]RPVL]RPV$j$D/$j$D/#QOi)jo>A]!!<5^^B\"oK=9B-;=9B-;=9B-;=9AYs+CGEZ#@\"c)$S2Ve,m.6O!s<QG!s_3r+TkgKcj-`[*N0;Qzzzz!!!#S#QOk[#QOk]#QOk]#QOk[#QOk[#QOk[#QOi)&-;k6jM:jK\"'>XW\"'>X7\"'>ZoTE63=\"!8alrW+6EF7pq&,?n1neh_CH!<XPM+\"[S$!s8XG!s8d8!s\\oC.6.K4\"7Mla-X$U\".pM]b0*=\\Ar<\"]+>Q-uG\"%Ma(1G`6e2?W(X0fK1:2`!6GC\\B4[hAS+-!s;IT0?sV?0/\"toSdEt(.j6Pn.pKGE/(QLt[M]/t\"Xej%\"'>ZC\"<UeL+!Y\"`+=#k[F05il,?qSo,M\"Ylp)jG^\"Wuh/WrcB*T`G6t\"7Mla+'Jag,?rGG,?AlC4!,\\OVEZ<V'm%q@,M\"YlXpQ6q>Q,3Zeh_BE56E,6+(Llb@.sjA(Ke7%d/a>O\"4[DS=9J#b!ZtSJ+!Y!Q&0oa^F4M'J,?t\"*,M\"YlXpQCSF4M*K,?r_K,M\"YlXpQ6q>F#F;eh_Bu.K^n!+4g_\"$8EL_#8_Xf>6e1a(B[a@\"-ioi=9J#b!ZtSJ+!Y\"d4!RdIp*Lk+>IFk`eh_CD3s-]2+8Gs?#6V@8\"'>ZoTE63=\"!8alME<%`F4p[?iY6I:$6LKsXs>7O'Q_h?+!Y\"(66k%rF05il,?oa<,?Al_'H\\Q(RMd@$1NSF8\"![sk(QS]Y!<WGl*nUK4\",?qG\".]Gp=K;TS\"'>XA$X=@j1`&ij!f7!]=9J#b!ZtSJ+!Y!M,pQH3p*Lk+>FHKUeh_B-,m,@q+4UGq]E&*:!s')6!WuO,Ylb)1\"7Mla+'Jag,?sR],N9DYXpQCSF7pq&,?r#?,M\"Yl_E%cD\"WmiT0jkZk\".KP=!<_!W\"'>ZoTE6KE\"\",U'iY!mH7dkRT03d-K\"5Z-p1BR_<0/E]\"U\\=dF1L#Sn2ZlOEpAm33>N,Yc\"#i\"l01dfM!u7L40*=\\=pAlp#>NQ/H\"%K'[!AcN9iW0,`2_Qfd=/c<)RP6HL0<,^60/)T4*\\T0\"CW\\$a'It=[-S&Du2(R66F5df7.g7<B\"S2au\"7Mla+'Jag,?q00,N9DYXpQ6q>N-8?eh_BI3s-]2+/&qS#$:ul\"9Va.n\"9_(=p#ik>E1lleeN8c'H\\Q(i]&/`F7pq&,?t\"#,M\"YlN]mOi\"WmiT0jpaZOTbjZ!<\\Sj\"'>ZoTE63=\"!8aljuXegF7pq*iY6I:$6LKsXt:mL'm&@K+!Y!Y/L/h&F07(s,6].k!s+;]XTRSd&d-)V\"'>ZoTE63=\"!8aldNp-t'Q^Da+!Y\"8$R=4YF4)?:,6]0o!ri=(\"6B[g=9J#b!ZtSJ+!Y\"H+X:$/eeT>P>Fm/deh_C(+Tiqm*s3=.\"2P-C=9FBa\"'>ZoTE63=\"!8aliXI,5F1OFT,?sjM,?Am:(*hBFF05il,?r;1,N9DYXpQE)'m$Mb+!Y!M4<rE5F7p\"E,6].k(ZYVc\"qqA)!s>,;?l-ohV[$>!\"O.,Q=9J#b!ZtSJ+!Y!q/gFD<p*Lk+>M^YN<cb,P+!Y\"(/0i_%F.O-L,6]/*(L+I(\"3r_0)rUr&/HbqU\"'>ZoTE63=\"!8alVC*V>1NT]+,?Al_'H\\Q(_B^AW1NTE@\"![skWs.W5#oeR&\"'>Z%#6S'1n\"9_0=p$-&>J^t*\"%K3e\"\"u<3L+kCc7dkRX1L&QO\"0+142Zj.@1G^g2XroM&(\"!6gp'rf51BU_G#;ZHOms$WE>D<Uii]](U\"6p\"D3s4aN0g?=-A-2o92_Qh9*$-ad05H.BiY3md0./8SqA(U41NSQX\"\"OO&N<fVg\"7Mla+'Jag,?r#%,M\"YleeK8O>E/b0eh_Ba(^'@4\"X!=<!u(k5\"p7s0UC?c!=/#g2!!!!$!!!!+z!!!\"L$31&-!!!!<!!!!H!!!!a\"TSO\"!!!!c!!!!l\"TSOX!!!!m!!!!m\"TSOl!!!\"*!!!!k\"TSOi$31(B!!!\"5!!!!f\"TSPQ!!!\"A!!!!e\"TSPi!!!\"e!!!!f\"TSN[!<<,(!!!!b\"TSO4!<<,9!!!!i\"TSOV!<<,G!!!!g\"TSO_$31($!<<,T!!!!i\"TSOU$31'Z$31(@!<<*-!<<*h\"TSN&'*8:;]#FcQ#Qn02#m493n\"9_P=p%8f>Oih.iY6I:$:d`niY5&:1NW+.\"%refXU(6q=9BuS=9J#b!_6Dr7n[&M93----:^^5rW,[C1NP_^9*Ihf#Qm!f8HW&sn\"9_P=p%8f>OE;#iY6I:$:d`nL-82\\'m#g(7n[(75>0Q`F+ug[9*Iff\"&l6%08fs7_&B9R\"'>YN\"'>ZoTE7Ve\"%Q!gl7kr_'m%Y=7n[(#&52!sF05jC<cds]7n['\\.SJ>KF8caR9*Ig=eiRUs\"1g?E#=[)C6j'Ol\"'>ZoTE7Ve\"%Q!gVE[`5'Q^Da7n['P,tlfFF/D/(9*IhB&G$$,\"3giK=9J#b!_6Dr7n['h\"\\[hhF.*;'93][o9@bn?Xp\"o#\"\\/[<#:fnY#6S'1KbG+]\"8)Zs=9J#b!_6Dr7n['d02(:=F4N-;93_6Y93--1)b3P*U+Asg'm$Mb7n[(3'2-n4F1Nh'9*IffNWrl)\".gfU(CSOk4VR2`\"'>f5!WuO,n\"9_P=p%8f>O!,\"<ce*V7n[(O1J?:6F05j?93_6S9@bn?l5Bat\"\\/[k#T+rB!WuQ>#2K=_=9J#b!_6Dr7n['T.8*]_ME==$>FHL(<ca-[7n['T2G;UWF7LAB93]OZ9@bn?RMu?%\"\\0pf$K<cf-VLm2P6<7;[Q#Y''l#+]\"p7s0SHAsr\"7Mla7p6!b93[]A9@ai!XpRg&F7pqN93WT5eeN8/$:d`nRM8EG1NO`B9*Ig!.qJYbf`M=-mfqbX,9\\G:!WuO,%jtT,0ZaD!=9Bp$#q*S?,9\\E:`XH6\",9pF,0`;1X=9J'q\"'>ZoTE7Ve\"%Q!gL&jru1NVh>7n[(G*)\"j=F+s\\t9*Ig)-X5.Co`PA!\"-iuk=9J#b!_6Dr7n[(_&kh3uF2fh&93_6K9@bn?rW,YmF,E%L93[Q+93-+k4%nQIF7LAB93^+'93-+k4%DqJJj2oZ'm#g(7n[(73D7pZF8?LO9*Ig-mf?YD*Y4G8`<\"7<-R\\*Y_CG`*.psmb!\\<U<Z3UQ8$8LiO\"0NSN1U.)c=9GuW,9\\G^!s;X-JHZ-X\"7Mla7p6!b93]sQ9B$Y,XpRhQ'm$Mb7n['h&PL\\2F05jCiY6I&#\"M<jZ6)`j1NT]2\"%refpBO2=\"3h&)\"B`,9[06Y7\"7Mla7p6!b93_B293-,2'Ltf#dNqOeF7pqN93W$%eh_C,63Bja7l)r*Q9YQO2C^ZE\"U!Z`\"6B[g=9J#b!_6Dr7n['d.nek9F05jC<cds]7n['`),&NqF3Y[o93[u79@bn?l3@Da\"\\/Xs2_tQ=$8Kj2R02UTblIp7\"p7s0n\"9_P=p%8f>D=@qiY6I:$;8r+F05j?93^Bb9@bn?<_#eeej)mZ1NVOb\"%ref_Z;DprY\"Aq^B7C^-Nb*;'<)3==9HqT\"'>ZoTE7Ve\"%Q!g_B_cTF7pqN93\\\\S93---),&NqF&ke(>FITGeh_BQ/d\"`M8)cZR\"5='C\"9W'7JHl9Z\"7Mla7p6!b93]t.9B$Y,XpRZl>CmM]eh_BE-Nd!F7g&H20ddJ^4p(lh;^:Z3gB(IZjV@r#\"0i(5=9J#b!_6Dr7n['\\(e`j&F.*;'93\\P#9@bn?U)3u*\"\\/Zm\"!$h3d0BbU\"7Mla7p6!b93[E29@ai!XpRh]'Q^Da7n[(O1/$1SF,hsW9*IhN(lnf%gB7*R\"'>ZoTE7Ve\"%Q!g`[=D[F4NHD93]7F9@bn?iY5$dF3YFliY6In'Ltf#RM&9E1NV\\=\"%ref$hbZW$g.`;\"q^q>#<`a&#7!$eYm:G6\"7Mla7p6!b93V`r<ce*V7n[(',>7#1F05j?93_6>9@bn?$3Np)7g\"bU&-iRF'Edk1ZNOA4!s;ITV$mH.\"6g'n=9J#b!_6Dr7n[(K5>0QBF05j?93[9>9@bn?XpRZl>:rS\"1NSF>\"%refY5uKj?oQI@\"'FjkPmIOp\"7Mla7p6!b93[9!93----:^^5q?oqsF7LAB93[uH9@bn?q?mBu\"\\1@-3&?*o!s\\qE#m493n\"9_P=p%8f>HU=deh_C4-:^^5l3p>F'Q_P<93-+k4%DqJ[K9+Q1NT]d\"%refirh:I1BYKE?oL$>!e%?[\"0Mtc4.uu`=9JL.\"'>ZoTE7Ve\"%Q!gqCbLm1NV,'93-,&2FgDEWY\\=Z1NWCG\"%refMZYmT\"-Ell=9GB,\"'>ZoTE7Ve\"%Q!gJj;u['m$Mb7n[(S\"A@<%F3Y@\"9*IffXrCb55<iA<5h-;G=O.5s$3OB4n\"9_P=p%8f>OEk3iY6I&3Cc_HSgmB6F7pqReeN8/$:d`nRQF0n1NVt3\"%refiX%sq1PHJER/p@kL-RIXh$aBf\",.*b=9J#b!_6Dr7n[([3_NLpp*NGl'Q^Da7n[(32bV^XF/D8+9*IiF4Y%['V%0[6]`A5;$NjK5n\"9_P=p%8f>OF.;iY6I:$;8qbF05j?93]\\!9@bn?r[\\.E\"\\/Y\".g(>1Ws)Vc!n@Y\\=9J#b!_6Dr7n['T$;8r+F05j?93^gB93-+k4%DqJ\\ctgY1NVtB\"%ref2`IZ9^+d\"uXpQmFq$I4+\",.-c=9J#b!_6Dr7n[&)93---)+R>([NA/n1NOH:9*Ii&.k`J1M%'Ph\"/u\\2=9J#b!_6Dr7n['t1J:biME==$>J_paiY6J!-;.B\\ME==$>P8=qeh_Ba/-ANK7k:nHdfJ#@[NmLL1FFuq!R<C@$3OB4i=#fj\"7Mla7p6!b93]sU9B$Y,c5K@,1NV,'7n[(;&kge3F.NU=9*IffXpQmN]*@j.A-9LO\"'>Yb%0K]7n\"9_P=p%8f>Cn.oeeN8/$:d`nW[^Zm1NT!F7n['h%SKiDqAW)Y'm#g(7n['X6VHDQF3Y[o93[\\q9@bn?XptP,\"\\/[7%.\"\"9UB3)Q^+]Z_,r%2+`s4d1h$=*bY6<Mf\"'>ZoTE7Ve\"%Q!gZ3*bN'm$Mb9B$Y,XpRZl>M9NZeh_BM$:d`nRM\\[uF4)R3iY6I:$:d`nmP.Ac'm%q593-,2'Ltf#L+H!K1NVt=\"%ref\"9(4A!V6<oLB9M$]*5>E0gkaCcNdRA\"=l-0efLq'\"'>Z1%Kff8n\"9_P=p%8f>I\"l7iY6I:$:d`naq[S#1NUi/\"%ref-SnuP0JbLh_CO^RT*AC\"fa\\*d\"7Mla7p6!b93^6W9@bn?[QI2`F35Ln93[Q<9@bn?h?F'T\"\\0L6JH=jNr=/p3\"7Mla7p6!b93Zuh9B$Y,XpRZl>G`W<eh_B!*Wo%=8)4]r\"BYbs%g,o9n\"9_P=p%8f>D`_[eeN8O)G=+Pc8eBf>E/eYeeN874A/^rl2sOL>OF^K<cb,P7n[(7.8/5JF,C8+9*IgIeiUYJP6(jK!Z49,!tY85eID[`\"5sam=9J#b!_6Dr7n['D),\"\"Op*NG`'m$Mb7n['l4\\O?^F,Ch;9*Ihr'E^Aq\"p6LuR1H8)\"'>Yb&-H#:n\"9_P=p%8f>OE+siY6I:$;8qbF05j?93[P_9@bn?WXf2)\"\\15s4)-:N&?>q9Ns2p&\"'>ZoTE7Ve\"%Q!g^'./1F7MXjiY6I:$:d`nNWi),1NT]+7n[(?!DCuYF.,*^<cdO.7n[(?&kge3F,gD+9*IiS#JME;2Zj.4F\"c8N0V''R&-H#:n\"9_P=p%8f>L!pUiY6I:$:d`n^+)e,1NUhU\"%ref_&BW]=9Fg#\"'>ZoTE7Ve\"%Q!gXp@[$F,E%PiY6J!2FgDEQ4-F;1NT])\"%ref)l!V[!TFe8qD)e-!s:J(oaq:.\"2tiS=9J#b!_6Dr7n['<,\"pKCF6YYR93_BV9@ai!XpRg&F7pqRiY6I:$:d`nhCM=N1NS-l\"%refZN_d@\"/-?Sb5mq5q%3^2\"7Mla7p6!b93\\8O9B$Y,XpRZl>G`B5eh_Be/k8Q=?;&j*F/BoZ9*IhT#6PYF_%Fil=9GB4\"'>ZoTE7Ve\"%Q!gSh*N8F4M*s93]gk9@bn?Sh't:\"\\/Y>:BL]Z#%/[t&d)5<bn:+\\\"7Mla7p6!b93\\P89@ai!<_M\"\"F7LAF<ccPH7n[(_.neGLF05j?93\\8,9@bn?Xqq15\"\\60*jt7%\"#7DnB\"02JJ4VOA',<Gu0'-+h*N=uCr\"7Mla7p6!b93]7A9B$Y,XpRhQ'm$Mb93----:^^5JdY6&1NUDA\"%ref[1oYBC9%QH'*D>=n\"9_P=p%8f>Q-r^eeN8/$:d`nW\\mFMF/BXA93]gh9@bn?W\\jlO\"\\/[/,?dHo'E_J3\"lU*s=9J#b!_6Dr7n[(+'2-n4F1+2(eeN8O)FmG)\\gpESF7pqN93\\+m9@bn?`Y/GI\"\\7#CeiRW5\"gJ^Cn,WUn\"&h9C!u6@uR1oa*\"7Mla7p6!b93_Au9B$Y,XpRZl>Oj[Feh_CH\"9V:#8*(ZD!a#QH!<ZF+]bCQN\"7Mla7p6!b93[E#93----;2o)F05j?93[Dq9@bn?Q4O-k\"\\1Z*4)-_5'E]i2\"m$F#=9J#b!_6Dr7n[(#-qdT^l2s]1'm$fG7n['`$qo/-F.s?N9*Iff\\hu30!s:R8\"?Q]ejVlqg\"'>ZO%Y+[?apa[Q\"'>ZoTE7Ve\"%Q!gJdP01'Q^Da7n[(C1eZCUF-8<]9*Ifr1L'hkknVAF=9H5O\"'>ZoTE7Ve\"%Q!gXuoA.'m&pe93-,Z3Cc_HW^BG='Q^Da7n['t+A:9AF07V-9*IgAjt;MlVZsOFqZ9k%m1f_*\"7Mla7p6!b93\\+r93-,./4W?;l9.ek1NT8r\"%ref.g%g7N>;Uu\"-F?$=9J#b!_6Dr7n[(O/kb1<F05jCeh_BM$:d`ng+Z1N1NWNr7n[(76VCI$eeUbK>N.P6iY6I:$;4E@g&ac;>OEV,eh_BQ$j0-+7iNs_iY3p>128?>#+#KP.kf?S,R:dZ1HkmC0<tT\\OV\\+%\"6gR'=9J#b!_6Dr7n[(S!__)ZF05j?93\\hh93--1)b3P*mKlP;1NTuh\"%ref\"26fD/*RiP=L/$n(B[bAn\"9_P=p%8f>Oik/eeN8/$:d`nMAAk91NVsp\"%ref\"-*Rn0=_f\"=I06&(B[bAn\"9_P=p%8f>E0^seeN8/$:d`nU+]0j'm$Mb93-,b4@`%KqA`/Z1NSQs\"%ref$SsrL!s:2>'7g]JXo[8^m2#k,\"7Mla7p6!b93]CJ9@ai!XpRZl>NQbqeeN7p3Cc_HmQaFr1NV[q\"%ref\"7?gWF-RIB=E=QL.g#kUEW`!P\"'>ZoTE7Ve\"%Q!gJg!eH'Q_8H7n[(S2bV^XF+PP;9*Iffdf^Yu)>s[?=9HMZ\"'>ZoTE7Ve\"%Q!gl9@r$'Q`Ot7n[(+$;8qbF05j?93^s$9@bn?l9>AD\"\\0ND\"'_2um2,q-Y6+52\"'>ZoTE7Ve\"%Q!gXoV2H'm&Xu93-+K7n[(S/5+PMF1r=j9*Ifr,?t-[KbG[C^B0f@\"'>ZoTE7Ve\"%Q!gdQ:*&F7pqN93\\8J9@bn?dQ7P(\"\\4[e\"(MGD)$<tCn\"9_P=p%8f>ETt!eeN9*!D?I7c8eBf>J`6jiY6I:$:d`nM?Z`)1NS^!\"%ref0@i3WRfqgj>?D!l)$<tCn\"9_P=p%8f>K/6fiY6I:$:d`nrZk.f'm%Y=9@bn?XpRZl>Oi=u<cdO.7n['t%nkJ0F8dEe9*IiG#3GtApBC^%:G4@G=2>fO)?X(Dn\"9_P=p%8f>Cnk.<cds]7n[(G&51S1F+QCS9*Ih.\"53bX`>Sh\\\"7Mla7p6!b93]7>9B$Y,XpRZl>M^Jqeh_BE&HbZ07k:_\\F.*<((`ui^ko'Y+\"7Mla7p6!b93^O493----:^^5Jeh#11NVt<\"%ref2m+'?RKe<S\")n?5!!!!$!!!!2z!!!!F!!!!S!!!#4!rr=6!!!!l!!!#/!rr=h!!!\"2!!!#=!rr>I!!!\">!!!#9!rr=Y#64a]#64a]#64a]#64aW#64aW#64aY#64aY#64aY#64c\"!!!\"P!!!#;!rr</!<<+j!!!#9!rr=W#64a[#64`i!<<,$!!!#3!rr=*!<<,=!!!#9!rr=\\!<<,I!!!#=!rr=]#64aa#64b'!<<,W!!!#8!rr>;!<<,b!!!#:!rr=]#64bW!<<*9!<<,/!rr=s#64b\"#64`]!WW3u!<<,I!rr>!!WW4,!<<,L!rr=q#64au#64bA!WW48!<<,H!rr>Q!WW4B!<<,C!rr>e!WW4W!<<,I!rr<9!rr=d!<<,K!rr>\"#64b&#64`Y!rr=q!<<,I!rr<k!rr>/!<<,J!rr=<!rr>O!<<,I!rr>'!rr<$!WW5E!rr=e#64ai#64`/\"98EI!WW56!rr<o\"98EU!WW53!rr=2\"98Eu!WW54!rr=r\"98F1!WW55!rr>?\"98F<!WW51!rr>U\"98F]!WW5E!rr=?#64`G\"TSOu!WW5E!rr<&!!!!n\"TSP*!WW5A!rr=.\"TSP6!WW5D!rr=F\"TSP?!WW5A!rr=X\"TSPQ!WW5B!rr=c#64ag#64ag#64ag#64b3\"TSP`!WW5A!rr>E\"TSQ!!WW5D!rr>q\"TSN+!rr>B!rr==#64aA#64`9\"onW7!rr>6!rr<G\"onWT!rr>3!rr=,\"onX\"!rr>7!rr=r\"onX+!rr>8!rr>/\"onX3!rr>G!rr<$\"9J]1jhCg:\"'>XG\"'>XG\"'>X-[MrT^&!-f!!s8p!\"\"aUW!s8d8!s\\oC/MR?0\"7$!/!cjn<!s<QG%0K]7$ig8-zzz[KZ^3\\-;p5[KZ^3[KZ^3!WW3#Zj$L1Zj$L1VuQetZj$L1!!iZE)]aIE!JLOV=9F6X\"'>YZ!<ZF+!s]f/8HW&s!s_X)%0K]7l3t`@,g69&\"'./j!u2PJ\"'>X-[Lcg_(Dg<T&ec!>(I\\F.!tQ&LrXpdb=9B]K=9AX1.g#kUEWZgc>Ohe.`\\_ED)u'LB\"(;:6!s8X('6OCZ!tub?!uD&4!u1o?!s=E*?l'Uq>Da49!u),W\"'>X-mO2HJPlUth!t,K\"%h/b*!s>hM?jd@N/SYZQ!<ZF+('\"=7zzz)?^$?)?^$?)?^$?)?^$?H2mpF*WuHC*WuHC*WuHC)#sX:&c_n3%KZV1)?^$?)?^$?+9VZE+9VZE+p7lG+p7lG+9VZE+9VZE2ZNgX+TMKB+p%`E70!;f-NF,H%0?M0!!rZ-^VU$!$3OB4#m493n\"9_(=p#ik>Oig[eeN8/$6LKsiY3Wg1NW+.\"![skd0]tXpBE&K=9J#b!ZtSJ+!XuR,?AmZ-6FI:rW+7p1NP_^,6]1:$3T>i\"%`Ss\"7Mla+'Jag,?qSo,M!TNXpQ6q>D>Egeh_AJ+!Y!a.O3peF05ip<cdO.+!Y\"<59n`8F.t,d,6].k^BLY=&!$gu(2=An#Qn1i\"VVPRi\\?Q\"\"'>Yb!<ZF+n\"9_(=p#ik>F$Q[iY6I:$6LKs\\cF&,1NU8A\"![sk',+Te/*R2s\"]tl3!<ZF+n\"9_(=p#ik>Lim$eeN8/$6LKsp)PC/'m!D#eh_BM$6LKsN]SK:1NW71\"![skdf]FP@$:d*Z4q$aklh/kdf^2e(2=AN\"Tqj/&$csc&'Y:\\=9J3s\"'>ZoTE63=\"!8alZ6^aT'Q_h],?AlC4!,\\O\\gera'Q^Da+!Y\"8'-l'aF0[(o,6]/&VZT&i4m`M\"=9AY[,V^+'!s;X-XTAT,\"7Mla+'Jag,?nn-eeN7,+!Y\"h2C$cfF05ipiY6I:$6LKsp*M\"bF6WiL,?pln,M\"YlarLR/\"Wmi\\(blg/\"%Ee3XoiF^!Q>/=!EeLcm/dAl\"7Mla+'Jag,?qGi,M!TN<Z`PjRPlDA'm%q@+!Y!I4!W<4F.+uh,6].khCp\\U!<WF&`s&jR\"'>Yr!s;X-n\"9_(=p#ik>NQVEeeN7,+!Xu6,N9DYXpQ6q>FH6Neh_C0'E]Q`*s2UDK*$`4_Z<jAaTDWI\"7Mla+'Jag,?s.I,M!TNXpQ6q>NQG@eh_BM$6LKsQ8g,?1NV[h\"![skZNc.\"?l,pN\"'E#5VA]sg':K+5+V1[U\"'>YV\"9Va.n\"9_(=p#ik>HT+oiY6Ib1F(I,F4N,h,?rSU,M\"Yleh\\Q1'Q_h]+!Y\"\\'dM9cF06Yg,6]1\\#F>NsefM-umg!'k+RoO9=9H):\"'>ZoTE63=\"!8alqD0AU'Q^Da,?AmZ-6FI:W]MG+F3ZcjeeN7,+!Y\"`6R1/<F/h;(,6]/\"Z51.TP6@Q\\cN9O9!tu>Pq?m0-\"'>Zu\"9Va.n\"9_(=p#ik>FI,g<ce*V+!Y\"T,9tbqF5f.],6].k\"'#j6[P?A7'*A=;'=A,K=9G6#\"'>ZoTE63=\"!8ali^+m@1NT]++!Y\"h(*hfQF05ipeh_BM$6LKsSgG]5'm%q@+!Y\"<,pUtsF&jA->GaG+eh_C,63AG9+7f`S5qs1F!=Mg:qZF,>C(CEl2DLg+70?Wom0*So\"7Mla+'Jag,?p0j,M\"YlXpQ6q>OiFPeh_B-49Hf3+27rA$8E>!\"&f`p!<ZF+Pm.=m\"7Mla+'Jag,?s.:,M\"Yleh\\OOF,E%$,?omI,?AmZ-6q(VF05il,?q/u,M\"YliXGu7\"Wun1'6CTFi<KJ^!L!U!'3j$/M#d]\\\"47;T=9J#b!ZtSJ+!Y!](*hBdF05il,?pTt,M\"Ylg+iaT\"WmiX*\\eJO\"9VR5i;j$_\"8N-'=9J#b!ZtSJ+!Y\"h-R2Z5l7jO7'm!Ct,?r##,N9DYXpQCSF6YP+eh_AJ+!Y!m![H82F05il,?qH+,M\"YlXo\\\\M\"Wn*g4j+'4\"0qrg#-S9t\",Ht5%g,n@#f-`J=9J#b!ZtSJ+!Y!a0I'V>p*M$8'm$Mb+!Y!a)^EoiF.t>j,6]0o$3Rg>LB?QB\"'>ZoTE63=\"!8alas834F,E%$,?pHk,M\"Ylas7'6\"WnBk'Xg\"\"!s;X-M$O2c\"7Mla+'Jag,?r/8,M!TNXpQE5'Q^Da+!Y\"4(F.KeF2Aar,6]/\"Z5.0cW</t%=N^dS)a4As\"p7s0\".gWC$hXc-=9HAF\"'>ZoTE63=\"!8almKFid'm$Mb,?AmZ-6FI:iXmEd1NU,i\"![sk\"3*5R(BXb<%hGr]C(KP1\"+pWP\"VVPR[Q)51\"'>[$#Qn02n\"9_(=p#ik>P]cn<ca-[+!Y!U)C*fhF05il,?q`',?AmN)C+5UF05il,?t.,,M\"YlqC)Lk\"Wn*[%(\\*M\"UeoE\"/c9>$h4?%=9H)?\"'>ZoTE63=\"!8alWYZo>'Q^Da+!Y\"L\"XE\"@F4N,leh_Bu1ERiGl3nn<F7pIn,?sFa,M\"YlXpQ6q>P\\^Peh_C4$j.^X+.anl+qp\"?q?UIB^B]Yu>N.C-!Q+t@\"+^d]=9J#b!ZtSJ+!Y\"H59j3MqAU[1'm%q^+!Y!a\"s_\\6F05il,?q/f,M\"YlNXl4:\"X!:;%j;Sgq?TL@#(ZdW=T8W6$3OB4n\"9_(=p#ik>FlEOiY6I:$6LKsatY-l1NT-\"\"![skoa:-l=9I(\\\"'>ZoTE63=\"!8almO'7='Q^Da+!Y!q/L/h&F5@W6,6].k#@@S@#gWQS\"8N9+=9J#b!ZtSJ+!Y!i3[<33F05ipiY6I:$6LKsSgku91NTQW\"![skWrfI*EWa#XpB\"=k#V#fS!!<3$!\"f22z!$qUF!$D7A!,Mf=!7D2S!7D2S!(R\"h!%S$L!,)N9!*K:%!'C5]!,Mf=!.+\\G!([(i!,)N9!0[B_!.4bH!,Mf=!7D2S!6bcM!6bcM!!**#!0$sY!,2T:!$)(?!1Elf!,Mf=!72&Q!72&Q!':2]!2KSp!+lB7!6toO!6toO!6toO!)Was!5nj;!,Mf=!/gjX!7:cH!,2T:!72&Q!72&Q!3#u!!:9ad!,Mf=!8RYU!;HNo!,Vl>!:p3k!!**#!,2T:!!NE(!\"Ar/!,Mf=!6>KI!6>KI!$MCD!#kq=!,Mf=!72&Q!72&Q!'LA`!%S'M!+Z65!6PWK!6PWK!*oX+!'C8^!+uH8!.+bI!(m7l!,)N9!7D2S!7D2S!1O#i!)rt!!,Vl>!36/$!*oU*!!*'\"!5/F6!+l63!+Q04!!!*$J\\V:D\"'>X_\"'>X_\"'>[\"%J1#Co*@2U=9Ad5>F%&Mb!:%=6$WQ7!s]'8WXB%:>F%(5!<ZF+#Heqc`ZS7`=9A[%#[dlB#@\"29#7\"J!1C&dnF1+.4q?UI6@09U6#7\"J!1G&]2!sAB*?j?oA>H/'n!<ZF+#7\"J5$O6o@Q88dB+`iN\"\"8W:2#6tK<WXBOD=9A[%#[dl\\\"'>X1^(,58#6P'K!s]'8WXDN'=9Ad5>F%'r!<ZF+#HeGURLoYu#[dmo!<ZF+-ia5Izzz$31&+z\\d/99\\d/99\\d/99]EeK;]EeK;]EeK;^'F]=^'F]=[Klj5[Klj5[Klj5[Klj5\\-N'7\\-N'7^'F]=^'F]=^^'o?^^'o?^^'o?\\-N'7\\-N'7\\-N'7\\d/99\\d/99\\d/99]EeK;]EeK;^^'o?^^'o?^'F]=^'F]=^^'o?^^'o?]EeK;^'F]=!$D9Ig&^_E\"'>Zq<WcG+%0K]7n\"9_`=p%i1>Q+Y-iY6I:$<LG9<a4-2F8c1B>6S*u<jr-4\"\"aUW\"7Mla?WmP=@p=ZuB*1W$r<$\\F>OFXi\"%K3e\")D[VmQGIj7dkS?Dd1p6\",89[EruM'DfZ\"Mms&np>D<mqV?nu$\"8X&nHNO@KEruMCCMs;Ems&bh>D<Ui^&g$1\"6p\"DG6?hh0maRPA-6lT7dkSCF'FA/\"8W'RG6=9>0ma\"k#VgfBF(>@dB4M*WhA./FB4l#F*S*#V+_P.l>FIQ^eh_BQ%g-;F?bHIB=9G`/='>]->?geA>LjO1XpS67>I\"cDeh_C@*<TLL=.KQu=R-#E2d<j?l4Z)^iFV*O\"'>ZoTE81u\"'8]2egan`'Q^Da>LjO1XpS67>CnV7eh_Bu.K`lY=,A,F=RQBL!WuO,n\"9_h=p&,A>FHLD\"%Ma(B4kH&)?[Dt0l$jn2eQd3/dH$%!u8KNB*1VupAno>>NQ0+\"%K'[!GcITiW0,`2eQb*=4%(^\"%Ma(B4kH&)?\\\\40l$jn2eQn.7dkS;CKlN'\"1B=,DZf8-0lmH^\">P*6CLdN[CGTU9WYljjB4l#&-.Wf@+_P.l>P^Bjeh_B9)ZsRR?\\nje=T8HkTE81u\"'8]2jtg4BF7pq^>?e*k>N-?<[QIdF1NVOi='Jmt)dClLF2B[7>6S(1Sg@c'MZJ_@!WrOr*\\fmM\"p9eb\"2P'A=9J#b!af+5?Xm<C+_LmHms&JX>D<UiMDd2)\"4f=aDZeQJ0ln\"@A-6TL7dkS;CKoL2\"9&Q\\DZ^)#CM.EfB57T=U\\=e)CKpcdDZ`J(pAo2N>N,Yc\"#k\".CGTU9SfJkbB4l\"C,h<]?+_P.l>NQW0eh_Bq$j0uC?`=/1=9J#b!`rRO\"'8]2eh11X'm$fG>N-?<iY5Hu>P^-[<cds]='JnW$sV:=F1*_(>6S(q6X0*d\"/>o\"^BX662^(6bSg@c'$TeCl\"-tYr5HtY\"TE,/^\"9Va.n\"9_h=p&,A>J_*.-tdPV*,>XGms&V`>Cna8iWLuS!s:JtB59;9B<jN=B4kjmVCYbX+_P.l>G`:@04tcH1i!1_ms&V`>D<mqnd[Bm\".h_3EruMCCMRQSB4h;]eHKRf7dkS7B3U*#\"/71uCBNi)0lI0>-S]ZUB4M*W\"'=:^\"5X)6B4n)#*bT+uCRR351LhS@?Xm;l5@`8#F7(dc@g-68\"Tqj/n\"9_`i;j$^>?fA[>LjO1XpS67>OF7Neh_BI/'A'\"\"]n&Y>GaIa$NiKh$NjN&#9-$7RKf_s\"'>Z)\"p7s0n\"9_h=p&,A>M^Z=\"%K3e\"(u7NL+i_p%P_`$\"#jk*_C.0PB*/mn\"p=E&0kY,$=4IKWOtJJ%B;Q4]B4kjmXrQ\"-@j,Jl@p@Y<A(EGWSe_E<\"^gd(\"'>ZoTE81u6W[JrJeD9gF&l@H>G`cP<cds]>N-?<XpS67>FlU7eh_B!&d)>A<s&gA47*</!TjCbTa([%\"7Mla='>]->?dgU>?5gB'O0-'F4qa<>?gA9>?5hA)cp6Jar=R91NVOi='Jmp2-\\WHF05jO>?ch>>LkTOl6-76\"]ket,n;kl!]pGc\"55Bg!RCf*%0K^>km%;m\"7Mla='>]->?e*E>N-?<ed>J_>J_4]iY6I:$<LG9_@^#3'Q_P<='Jnk3EoO*<``L0H<\\rVF/g&Z>6S(q03bk?!t0e`416or\"!Ka_%BBM3\"0Dh2=9J#b!`rP-='Jmd.U1I=F05jO>?e[$>LjO1[QIVq>J_Uh<c_;C>?f)p>LkTOp+-;M\"]n&Y>Fll<$bQL%SfTg6Nrn9O\"'FF])adhu#3c6m=9J(!\"'>ZoTE8J(\"(,PBq?pp<7]61eB4kGs(^'aI0l$jn2eQn.7dkS;CKoL2\"3*Y^DZ^)#CM.E=B4odT*bT+uCZYr_'Or;!?Xm=*,%K1[F8?7H@g-5M$%iIb\"7Mla='>]->?fMW>?5hA)dClLF05jO>?gA$>N-?<XpS67>P\\_3eh_BQ3s/[j=1/Do+ZnuoSg>+1$TeCl\"4eJI5NN0c\"'>Zu#m493n\"9_h=p&,A>KS[5\"%K3e\"(u7NmQK,LCC\\3/\"5YmiDZcRt0ln\"@A-6K82]cUEB5<5Xeh^eZB4#.Ql7?Gr1NT8p\"(MLAYmLS8\"-Wgg=p%i1>NRnLiY6Ib$<LG9h@j,Q'Q^Da='Jn'#$]Y7F0[A\">6S(1N\\)tM)iFc%RKgG-T*&0ti<fZh\"7Mla?WmP=@p@A9B*1W$r<$\\F>E1j^\"%K3e\")D[Vg(jeA+Ydm;ScUWf!s;J;DZ`JtG].M)L)'lg#r-K'L(l@d!s;J?!s;J7B=\\?iB4kjmg'?UO@j,Jl@p=s:A(EGWdP1i6\"^eeJ_Zj3Fn\"9_`=p%i1>D<AeiY6In'O0-EF05jO>?gMR>LjO1XpSCa1NVOi='JnO(0fc4F3Y\\*>?fN1>LkTOL'Ifb\"]qT'NroJGp)L[H+Zfdt-\"&Ze\"$6Rn#E]Ju=9F*_\"'>ZoTE8J(\"(,PB`[PO&7dkS7B3U*#\"7d]lCBN-F0lI0F2)0.cB4M*WB4^W@B*/m^$tfZ3U\\=e%B3U*MCBI&$pAo&F>N,Yc\"#jk*\"'<GM\"4@Q3B4kjmg)+Ic4!&$IB5?'!iY5lGB4#.Qau!VZ1NUPb\"(MLAjU@I\\=9J#b!`rP-='Jn[$sV^*F3Y\\.<cdsP='JnK.9k@ZF4La%>6S**46HYV4,!_<=9FNl\"'>ZoTE81u\"'8]2l8;dHF5dm8>?dC,>LkTOg*-W'\"]ket-\"&Y>4&H+M#m493[1*4?\"7Mla='>]->?ch5>N-?<ed>J_>E1XH<ca-[='Jo*%pRU@F+u4J>6S(IM[!CS#\"(cS!O`<2\"p7s0jUD;o\"7Mla='>]->?dO@>N-?<XpS67>Q-cieh_C0(0=^EG$ENRF8e<)>6S*S!CL([#\"(a^p)Mlq+'8W1%Kff8n\"9_h=p&,A>NQN1\"%K'[!G?%Lr[;Oa7\\f\\YCMR/6!<WE_B4meG*bT6j7dkS;CKlN/\"/ZAZDZc\"A0lmF!;ep#]>\\@]@&0>IsB5?'4eh^eZB4#.QqANkp1NS.\"\"(MLAkmdet\".KBo=p%i1>LFs)eeN8[+BqlfVA**9>I#8RiY6Ib$<u(;F646>>?d+;>N-?<XpS67>CnG2eh_Bq.0EcX<s-_f50!fL\"0Vr6RKhjY[g-\";L_%]7(r6R^Q8(*Y,=>\\(#3c[$=9H)E\"'>ZoTE81u\"'8]2VDqf>'Q_h4='Jn74^6JPF05jO>?dC!>LkTOVDnZ^\"]lrG\"C%<!d45<$gBQaM\"'>ZoTE8J(\"(,PBc5($p7]61eB4kH\"%r28:ms&V`>Cna8\\iqie!s:JtC[rc9CMO\"eOUqW/.ktgT\"';H5CBI&pG\\_)!L)'lg#r-?#SjY;S!s;J;!s:JpB;uLaB4kjmjrr;3@j,Jl@p?AdA(EGWNX#Yr\"^f@_\"'>ZoTE81u\"'8]2qDhb\\F&l@H>E/qmeh_CD3PP]$\"]kd6F?@SY\"'>Zm&-H#:n\"9_h=p&,A>Nuf5\"%K3e\"(u7NdMgOsCG4*PCBG<.&Hi\"o0l(P,=.p4A\"%Ma(CMR./('CE?0lI0\"))617\"&it;rY.)*!s;J7B;-:cB4kjmqD$tD@j,Jl@p@XfA(EGWhCJb=\"^f4\\\"'>ZoTE<FC=p%i1>K/!oeeN8/$<LG9hCMm^1NWNs\"'Yq16UP(d$/$X-=B\"Gr\"'>ZoTE81u\"'8]2Q7#m;F,E%\\>?g)B>LjO1XpS67>FmBM<ce*V='Jnc-X0Vmp).)c'm$fG='Jo\"#$]Y7F05jO>?f65>LkTOi\\CU?\"]l'n!oF4bc5\\Q',=D)(RKc,H>IH<Y!t,2m[PBe&!Fl5'-0YFh$TeCl\"-+rf59iO\"RKh\"Z\"'>ZU&d)5<n\"9_`=p%i1>P]jSiY6I:$<LG9Xqt<n1NT]+='Jn;\"^BP6F06;]>6S)t#DO*N59iO\"RKi\"#@orhe'*D>=n\"9_h=p&,A>Db7M\"%K'[!G?%LL,`rN7\\f\\YCMR/6!<WE_B4oL$-YI(),.\\e-!u8K_B*1WlG\\:Yng):'b2)/kK\"#jk*\"'<k`B*1WlG\\:Yng):(!6SW?Y\"#jk*b!$kZB4l\"C1tFHm+_P.l>KT$;eh_CD4p,9u?gSL/=9J#b!`rP-='Jn'&R3g$F05jO>?gqf>LkTO`Y4O=>6S*b,W?l.\".gfH2[_\\KlNY`L\"'>Yn'E_G>n\"9_`=p%i1>Flg=iY6I:$<pPPp*NjF>IlLm<c_;C>?gYV>LkTOVA02;\"]n&Y>P9$=$e#,<q&,e/e,]Zr'E_G>n\"9_`=p%i1>H0YeeeN874BG`kRM/n+F7pq^>?d+!>LkTOW]1)b\"]pRH2^-oXYo3`4!<`-3\"'>ZoTE81u\"'8]2RK6XP'Q^Da='JnO.9kdGF3Y\\.eeN874BG`kqCGk%1NU\\f\"'Yq1Jh6Ku+hn89,.@YV\"0!\";=9J#b!af+5?Xm<g-YKFo)S-)b!u8Ka\"3(L!B4h<JeJ2^!7dkS7B3U*+\"7cpVCBL:p0lI-r;eKkJ7dkS;CKlBK!s12q!s:JtB5:abBA*J0B4kjmatr#k@j,Jl@p>NHA(EGWjuNTS\"^cs!\"'>ZoTE81u\"'8]2nh=;!'m$Mb='JnK)-^-_p)-q9>NRtNeh_B-56L'N\"]kd6\"$<5%2c)Sm-NdJK!OW[F=9J#b!`rP-='JnW6X/OaF5dm8>?g(p>N-?<XpSB6F7pq^>?dO?>LkTOg+WV5\"]n&Y>M^V-irK6DJJ5?n\"p=**\"'>ZoTE8J(\"(,PBU)%AD7]61eB4kG/4dI4+%cSB/\"#jk*NX-\\=B4l#>6fJei+_P.l>ODf-eh_BI63C^$?_%u8=9J#b!hTU!\"'8]2Q7Z<AF,E%`eh_Be/lu7]W^9q@1NSj6\"'Yq12aa8>RKf<(\"'>ZE(B[bAn\"9_`=p%i1>E0_.eh_BM$<LG9Z92@B1NSQs\"'Yq1k6@X^0gE&V\"'>Zi(B[bAn\"9_`=p%i1>P]XMeh_BM$<pPPqAWL?>K.7Z<cdsP>N-?<c5Kbg>G<cTeh_Be&Hc5@=1/FY!dZs\"\"J-pN!B7P/\"'>Z!(^!kBn\"9_h=p&,A>N-</\"%K3e\"(u7NL+mBF7dkS;CKoL2\"-O*JDZ^)#CMs;Ems&bh>D<Ui\\e$T;\"4f=aG6?DR0maRPA-6U_%rZ4c($-87i]/`/CBIZ*(^$3d0l$jn2eQcp)]iX)B5@>geeM[<B4#.Q[QnI-7]61eB4kGs)?\\D(0l$lO1,3\\L\"&iiJ\"%Ma(CMR./('F+;0lI0f4u%*\\\"&iuJCGTU9r[f1(B4l#B*`cboB4#.QmPeY,1NVOh\"(MLAaVb1_MZN:>!`od4='Jn_4BpAOF05jO>?f6(>?5h=-<FDUiY,PI1NT]4\"'Yq1L,q7:3s2'#?oJHT!riD>(BYlap)H\"748gB+=9F6q\"'>ZoTE81u\"'8]2XsI<''m&(O='JnW)dClLF5dm8>?g)>>LkTOdMi9m\"]rkM3s#KdQ5_QF\"77B:=9GrL\"'>ZoTE8J(\"(,PBedH*m7]61eB4kG/4_k-hVu6^5CKp3i\"24jlDfZ\"Mms&np>D<Ui[M1H?\"6p\"DHNW7K0n0jXA-2r)-o#oZCLdML\"#jk*JhA*WB4l#Z2caE3B4#.QU(Chc1NT]M\"(MLAOW+C)\"7Mla='>]->?eB;>LkTOXpS67>LG-.eeN8/$<LG9Xt3f.1NTi+\"'[lhRfT*,?oJHT!j;d`,Qh-N_&EJY\"7Mla='>]->?c\\?>LjO1c5Kbg>IG\\ZeeN8/$<LG9p'k6c'Q^]F='Jn72-X+&VA**9>F#k*eeN874BG`kOt0bf1NW+!\"'Yq1!t,2mVE6^[2ZoWt@(QRMY6=t0\".gRp!C,*`\"'D<!PoKm.\"7Mla='>]->?efW>?5h=-<oIDF05jO>?e*?>LkTOL'e#e\"]kd6\"$?/idfaRk]c7,V\"7Mla='>]->?ge/>N-?<[QIVq>J`:&<cds]>N-?<XpS67>K.pmeeN8[+BMcO_D#3F1NW6t\"'Yq1$i^A3!s@*p1&h<S-N=7h!<`-;\"'>ZoTE8J(\"(,PBei.4D7]61eB4kH65gBCGEL&KbrY.)*!s;J7B9ENAB4kjmg*YAc@j,Jl@p@@kB*1W$r<$\\F>LFDljutM8\"4@Q3DZ^)?B57T=ms&V`>Cna8JcRTE!s:JtB5:abB8/JhB4kjmSd\"*f@j,Jl@p?5gA(EGWqEP-m\"^gL7\"'>ZoTE81uF&uRMniL(,'m$Mb='Jn+(L,HHF05jO>?gqh>LkTOniHqD\"]l'n!g<]+!VR'Z59iO\"RKc,H>G<@='a%P?TcO;<\"7Mla?WmP=@pAXaB*1W$r<$\\F>D=hI\"%Ma(CMR./%KkPi0lI0F2)0.Sc6k>j'5M+\\!s:JpBBhc1B4p?i*bT+uCZ6)[1LhS@?Xm<G+CitYF-Zk0@g-6,*WoLH-WaIR='Jn'*a@2OF4L\\\">?fM]>LjO1XpS67>F#=peh_BA*WoUM=0D`o>Db])%g,qk!LY#3=9J#b!`rP-='Jmp\"'a>4F05jO>?f60>LkTOed>X@'Q_h4='Jn[-X5REF05jO>?efa>?5g&4',Wjeg=V\\'Q`7J>?5fG='Jn;&mNpCF1rb!>6S(Q6Sk/8#KI$Q`WlV;\"-!=C`WnFG45U45-\"&Z_)Uedj\"8*`<=9J#b!`rP-='Jns6<iF`F5dm8>?gqV>?5h=-<o%9F05jO>?fB:>LkTOmQq\"[\"]kdF\"$==F\"*39#!t,2mN?\\O-\"0E[J=9J#b!`rP-='Jn[5?l\\pF05jO>?fMg>LkTOeis7@\"]sRa$NiKH.0EZSd3&Nn\"7Mla?WmP=@p=roB*1W$r<$\\F>Lj=#\"%K'[!GcITr[;[e7\\f\\YDf8k>!<WE_CMR^$p(mf52eQd#$Q`qnB5<5-iY5lGB4#.QNXTP&7dkS7B3U*+\"/ZAZCBL^t0lI-r;eKkJ7dkS;CKlBK\"54#8DZ^)#CM.E=B57T=ms&V`>Cna8\\d:*0!s:JtB59;9BBBI@B4kjmjqH<%@j,Jl@p@eLA(EGWqBuGU\"^g@7\"'>ZoTE=!S=p%i1>Q-H`<cds]='Jo*-sP7YF4r4t!a>h06UP)K#Orl<2?VoL\"'>Yb+p1pLn\"9_h=p&,A>EUA62J3Nr\"_VI`_?4G&#p*_lB5<)A<b!:c?Xm<S2.P2nF7L(K@g-5M+p1pLn\"9_`IfibV>EU::<cds]='Jmd#@#b8F5dm<iY6IB4BG`knePH\\1NTi@\"'Yq1\".gfH2sUMm!X%g<\"/,_tm32X7\"7Mla='>]->?es0>LjO1XpS67>D>LLeh_Bm1':_a=$o>ZmQ.$a\"'GR*OWss1\"7Mla?WmP=@p@q/B*1W$r<$\\F>D=is.;KF-#6P&eB4n(j*bT+uC\\g1p@j,Jl@p=O5A(EGWiYM],\"^f4n\"0)A(n\"9_`=p%i1>Fm3HiY6IZ)HU-Ic9YZ8F8?hW>?g(g>N-?<XpSB6F7pq^>?g)'>LkTOSgOVE\"]t+Q`s3bL\".gg\\!B9ZkLBA%hJKt>\"\"7Mla='>]->?e*0>LkTOXpS67>I#DViY6I:$<LG9Oo\\e<1NTPu\"'Yq1hZ]St?oR0ZMZHo^!t,2mSJVH2\"19BV=9J#b!`rP-='Jml#@$1%F05jO>?gM6>?5h)'N\\LCSe#&V1NVt&\"'Yq1$Tj\"B\"/ug#!E]H_,Qh-Nn\"9_h=p&,A>E1[U\"%K3e\"(u7Ng(je5.ktfA\"#jk*B5?c^B@7tFB4kjmhEg-8@j,Jl@p?5sA(EGWN]7,N\"^dZDk64rin\"9_`=p%i1>N.2<eeN8[+BqlfVA**9>E1[Ieh_C,/-B)[<s-;U0_5Mo6X,u`YndFD\"7c[U+Zmdq\"'>ZM,m.6On\"9_`=p%i1>D=;*eeN8/$<LG9hEY;r1NWO3\"'Yq1\"7dTi5F!;m=M\"h.,m.6On\"9_`=p%i1>M:H/eh_Bu$<LG9jr.I`'Q^Da='JnW!F&TGME>&%'Q_h4='Jn[)I(cKF4('k>6S(QWs)Fj#,;;g>D>2<,gQ]t\"0EmP=9J#b!`rP-='Jm\\\"'ab!F4L\\\">?gYK>LkTO`\\(=s>FI0Keh_C<.g&uZ=!'e6RKc.N\"C%`b]c.&U\"5P:+=9J#b!`rP-='Jn/*F%M;F05jO>?dO(>?5fG>N-?<iY5Hu>H0D^eh_B9$NjT:<s,3%00A83dfNVRN@+g1\"7Mla?WmP=@p?ATB*1W$r<$\\F>O\"HU^'cZ2\"6)O\"DZ^)?B4m5U-YI);$m'%oB5??jeeM[<B4#.QY!6P$7]61eB4kGs)VR19&3=TB!u932\"-+EWCMO#Rfd?m).PY]@i]f/9!s;J7B=]i>B4kjmMATB(+_P.l>G;F6eh_BM56GC!?i;>SI08r2!`rP-='Jmd\"C\"oJp*NjF>G<-BeeN8O)I$6`qAWL?>L\"9oeh_BM$<LG9jq(bJ1NV+S>?5g&4',WjdPP1Z'm&(O='Jnk2-]&SF1+24>?e6p>LkTOU)a>?\"hOg<SgECtWr`[h!s/Q,V@PEQ\"sZK>RKer\\6TDXj!t,2m\\e@\"G4,X96-\"&Y>3s#N+,m2-f\"7[cA=9J#b!af+5?Xm</.VAiQVu6^1B3Xde\"6)<qCBFYtB4kjmnf2;2+!,'-B5?'VeeM[<B4#.QJgk3\\1NWOK\"(MLAW@7pO\"7Mla='>]->?h(7>?5g&4',Wjq@m.7F/BXQ>?h([>LkTOq@j$9\"nr'#g+FL4,=?O@#*fl)=9Bd8>FGbe.K`cTi@+k2\"7Mla='>]->?h(N>LjO1XpS67>E1(8eh_BM$<LG9Z9DJnF8?hW>?dgA>LkTOZ7uGc\"]q9:2^(6bSgAV?$TeD/QNmFO0gFb8\"'>Z!.K`cTn\"9_`=p%i1>IF`?eeN8/$<LG9@U%h+F4L\\\">?ct.>LkTO@KTg<=$t^F>Fln8+9P`$\"O/Cu=9J#b!af+5?Xm<K*+o@Cms&JX>M9ttL)Vj_!s:Jpc3.ciB4h;]nL=X`+u*_C\"':I4B*1WlG\\:YnL(4=^\">OZol3&h[\"6p\"DEt`1s\")$0k-YI(p1`g:BB5=d\\eeM[<B4#.Qh?d]C1NTEH\"(MLAXXaKU\"7Mla='D'q='Jm`&R/:WqAWYi'm%Y=='Jn+03d!`F+t8/>6S(1Sg@q-!jO!Q=9I)(\"'>ZoTE8J(\"(,PBWZ^R.B+C@and&kdB4h;]q($([7dkS7B3X(.\"-Pu*CBFYtB4h<JJLgoW'/=-4qB?tnB4l#&2caE3B4#.QmL!IT1NTQ=\"(MLASLakj\"7Mla='>]->?h(l>N-?<ed>V^F,E%\\>?e*G>?5h=-<FDUWZYNs1NWO\\\"'Yq16Q<<3Jh3$(\"!%Kg/-AuVn\"9_`=p%i1>J;js<ca-[='JnC,$X%@F3Y\\*>?d75>LkTO^+odp\"]mK=ScQDLV?Gc\\#h]6`4p+mhr@A%Q\"7Mla?WmP=@p?5JB*1W$r<$\\F>D=hI\"%Ma(CMR.+2?UZZ0lI-r2erKt2eQn.7dkS;CKlN/\"/ZAZDZdQr0lmF!;ep#]1M:@/2'-CCB5?3C<b!:c?Xm<'1#<=OETS]_B5@JVB=9K8B4kjmhDa\"#@j,Jl@p?YJA(EGWZ4-nG\"^gXK\"8Dm!n\"9_`>*B+k>?e6u>LkTOl8D^J>P:']eeN8/$<LG9ej3M@F7pq^>?eBB>LkTOp,N4Z\"]l'n!XAg^))4?G6X,u`\\O-Hk\"0!mT=9J#b!`rP-='Jmp1g=\"%p*NjF>KT<;<cd77='JnG**^uMF36iP>6S(94#-m?U&m&6WC6n1\"5,:/=9J#b!af+5?Xm<O0kUSXVu6^1B3WptCBI&pG\\_)!L(4=*4#(XUl3&h_\"3r8KG8\"b&\")D[fWZM<F2eQc\\&0>IsB5=XbeeM[<B4#.Qc6d&P1NU,^\"(MLAV(VpQMZN:>!`rP-='Jo*-X0VmqAWYi'm%Y=='Jn?0jE3bF8@6d>6S(1SgEe*1T`eB=9Hf$\"'>ZoTE8J(\"(,PB7V;fmVu6^1B3U*Eg*(6OXt'SV2eQdk#TdVkB5<M;eh^eZB4#.QiZMa^1NW7O\"(MLAJM71.\"7Mla='>]->?h(R>LjO1XpS67>H0#S<cd77>LkTOiY5Hu>P:-_eh_BI-7<\"$=$&K0\"-GkO=Mk<I0EYDZn\"9_h=p&,A>FHJi/S>Rm#&!3*-YI(t-QZo5B5>?n<b!:c?Xm<_\"_6+>F1MDT@g-5q0EYDZn\"9_`VZ?m$>?ch!>LjO1[QIVq>LF9k<cds]='Jn?!aF53F4rbZ>6S(q6X07(!t,2mp)H\"7QNE.5\"8Dm!OYHr?\"7Mla='>]->?g5<>N-?<ed>J_>Q,(9iY6In'N\\LCdLBD]F7pq^>?gef>LkTOjsU=9\"]n'l\"C&;i\"-W`f42\"#aKE21s0`tM[n\"9_h=p&,A>Cn>;\"%K3e\"(u7NedlNu7]61eCMR/*%rVP>ms&bh>Cna8MD$]*!s:K#!s:Jt!s:JpB;Q.[B4kjmW[$(N@j,Jl@pA((A(EGWU,N0a\"^dNM\"'>Yt!EWG,='Jno$<uL(F05jO>?gA%>?5hA)cp6JU,Q<-1NVgj\"'Yq1\".geC2u,#j\"BYcB1':V\\n\"9_h=p&,A>M;!h'D`eHB4h;]eM76P!AS5\"\"'=;6\"/ZM^B57T=ms&V`>D<UiNYO9e\".BKMEs%j:0m=:HA-6I[;.jMD'nJ.CJgW9cB*24l1BX4!0kY.Q59=HMB5<qh<b!:c?Xm<36\"AJ%F4rMS@g-591BTQ<n\"9_`=p%i1>OEJ8eeN8/$<LG9Q6KPa'm$Mb='Jn+,$WV5F4qa<>?ff>>LkTOmMl=5\"]l'n!Y5D44>FkW`C'f1>MV(;=9J#b!`rP-='Jo\")-bZJF4L\\\">?d[T>LkTOXpS67>Lk'(eh_C<)$=(H=-!JO>D>2&#7CVqYri+j\"-#,>=9J#b!`rP-='Jo*$sQbRp*NjF>HTS_eh_Bi49Jdk<s,$??oQ1\\\")7qC1]ph^n\"9_h=p&,A>Cmr0\"%Ma(B4kG'('CE?0l$lo3\\bOT\"&iiFl4P.NB4js((M<gbkqm#T7dkS7B3TsG\",6q5CBFYtB4h<JnMC?&&2@g1g++4WB4l\"k+')kpB4#.QN[SOp2I;P0B*/m.2$9.'0kY,$=-YWFp*qe0BA+X:B4h;]Teuq,5;?e`\"';HZ\",80XB4q2`*bT+uCS!Ug@j,Jl@p>Z.A(EGWJfb))\"^f5+\"'>ZoTE81S\"'8]2N^-h\"1NVOi>N-?<[QIVq>Cmr$eh_B-5Qb3o=7615\"9JZ-p(/rC+%'8$#2q`J=9Apm!X$h3\"'>[(2$6q_n\"9_h=p&,A>M:N=\"%K3e\"(u7Nee`*(7dkS;CKlN'\"4f+[DZf8-0lmGc#VgN:CLdMLRKtWd!s;J7CBI&$pAo&F>NQ0/\"%K'[!H2m\\iW0,`2f!&A>\\@]T'-:e!B5?o]eeM[<B4#.Q[Oc%n7]61eB4kG/4Tj+k0l$jn2eQn.7dkS;CKlBK\"6'G<DZ^)#CM.EfB4mA6*bT+uCU-:X1LhS@?Xm<s$=hXCF4r&F@g-5)2Zm0_#4J2d='>]->?d+S>LjO1[QIVq>M_/?<cds]='Jn_.9k@ZF,iTU#$V74\\e@\"GP608e\"8i0%_)DHu\"7Mla='>]->?d[Z>N-?<XpSB6F7pq^>?f5N>?5h=)-:$HVBfBs1NV+d\"'Yq1!t,2mhBY%042iqT!@%^>2Zm.an\"9_`=p%i1>M:-&<c_;C>?fMY>LkTOg)^?#\"]kd6RfPU&/2n_6iFN*n\"._CR=9J#b!`rP-='Jns4'U8lF5dm8>?fMr>LkTOg+!2/\"]ket-\"&ZA3s#Mh63C<l`Ads%\"7Mla='>]->?g(q>N-?<iY5VJ1NT]+='Jmp3EoO*ME>%n1NV+S='Jn?/6g[]F-\\fg>6S+&!CO?t`Wt)rf)Yt8rCR/o\"8t1]=9J#b!af+5?Xm<S.;&`PVu6^1B3UBZ\"/75!CBFYtB57T=ms&V`>Cna8_CdQ]!s:JtB58N#B*/mR3<Ssk0kY,$=1L<nVCF<5B>tK(B4kjmVES$j+_PEi7]61eB4kGs(t'sNEIotK\"#jk*RNNYaB4l#6,N9DI+_P.l>J_=heh_B!(B\\.N?h$,Y=9J#b!fmRc\"'8]2N](*BF,E%\\>?gYX>?5h=)-:$HJeqYB1NSR7\"'Yq16UQS/[L!$D\"$<pt2[):23!37bV)e]\\\"7Mla?WmP=@p=[#B*1W$r<$\\F>LjUj2Te&mCMO\"e_)_\\t.PY^S\"'<T*\"4A8GCBKGF0lI-r;eKa#4<A-JB5=Y:eeM[<B4#.Qg-T<#1NS9`\"(MLAm5b>O`rtk(!`rP-='JnO)-c)7F05jO>?e6O>LkTOXpSCm'Q`7J='Jns.9k@ZF05jO>?cgp>LkTO[Klt>\"]n&Y>GaKK#Hn744/P(u+ZmjJSg@c']e\\%A=9Gfi\"'>ZoTE81u\"'8]2\\jK\\&F&l@H>I$:oeh_BY6N^Nr<s&gA48C`9=9I)8\"'>ZoTE8J(\"(,PBVB9FQ7]61eB4kG'0]k9/%ba)K\"#jk*RNW_bB4l#Z$s$j]B4#.QL,<Dk1NTE8\"(MLAM*(k\\\"7Mla='>]->?ge5>?5g&4'U\\YF4L\\\">?dsH>LkTOl2^uk\"]kfO*&0Z\"-OQ:HNA1N;\"1:5n=9J#b!`rP-='Jm\\3*YAVF3Y\\.eeN874BG`kL*0]$F7pq^>?dCA>LkTOJiEj:\"]pF>WraHN#2M]M@KY^S\"'>ZoTE81u\"'8]2ShXI#'m$Mb='JnC%pRU@F05jS<cb,P='Jm\\6X/+VF05jO>?f)[>LkTOl8DjIF,E%\\>?geM>LkTOShU=O\"]l'n!k/8m#F7*8!C&)%;jmpd3!39$Yrr1k\"7Mla?WmP=@p>Z4B*1W$r<$\\F>D=g6g*e[k!s:JpB4l#63+pA:*bT+uCQ]mm'k8D\"?Xm=>-\"GL^F.rmA@g-6(4Tefe\"n/)c='>]->?fr>>N-?<[QIbpF5dm8>?dg,>LkTOhD,1;\"]l)t#N5[c`CC#4\"-GbL=9J#b!`rP-='Jm`$sV:=F05jO>?ct8>LkTOL(\"/g\"]pTcSg@c'iB.3E\"1:;p=9J#b!`rP-='Jn+#@#b8F5dm8>?f*->LkTOi\\psD\"]ket-\"&\\/\"?QYe\"55@^59E6sRKflJ\"'>Ze4p+mhn\"9_h=p&,A>Ikbdp'r\"(*G5HhM*GVT7\\f\\YB4kH2#AXE2U\\=e)CKod!!s:JpB*25+5A('fms&JX>M9ttJg3!c!s:JpB?E4iB4h;]WBUL!#Vft)\"';`l\"-s0HB4n4`*bT+uCP!,W'Or;!?Xm</,\\,C]F1N:m@g-5a5PG@a\"7Mla='>]->?eNb>LjO1XpS67>IkbXeh_BU-j*ZW=$o>ZU*G4\\\"'C<]nNR+X\"7Mla='>]->?eB>>?5g&4',Wj\\iO%rF7pqbeeN8/$<LG9RPJ*u1NTi.\"'Yq16UU&<\\eD2-\"8;if\"/.s^=9J#b!af+5?Xm<o6\"^9hms&JX>Cna8c93mt!s:JpB9j<BB57T=ms&V`>M9ttar3!Q!s:JtB5:abB>QkSB4kjm^)bc\\@j,Jl@p?MWA(EGWU*g%Q\"^gX^\"'>ZoTE81u\"'8]2M?7#51NVh>>?5g&4',WjU*j0r1NSETRfQ^s=,R8M4dlT.1BU_]PsGLS\"7Mla='>]->?fZ)>LkTOed>X@'Q_h4='Jnc$X;0sF1+28iY6In'N\\LCL)!qD1NT]+='Jm\\,[97BF05jS<cds]='Jn'%U7L?F+tD3>6S(AN\\)tM+%'8$#1itK!aG4#\"6T[eWr\\VYo)UoTks5DR\"7Mla='>]->?chM>?5g&4'U8lF6YYb>?eNF>LkTOL-u,J\"]pH\\6P,[j_)MO!\"-GnP=9J#b!`rP-='Jn[10``PF05jO>?efE>LkTOg,]=?\"]ket-\"&\\%2<P3H\"1:Gt=9J#b!`rP-='Jm4>LkTOl8DjIF,E%`iY6Ib$<LG9g,WA<F7pq^>?dg^>LjO1g)sI$>Cm,beh_BA3<NIh<s.\"o0tRI]\"K)@D!La4d3WnmQ!s?CV0g?aI>FGa`6X/Cm]f-$q\",0)E=9J#b!`rP-='Jnc(L'p]p).)c'm$fG='Jn70O%S!qAWL?>Fkk\"eh_C((B[kF=,K7%\\cIEe\".gg?!B1BJ!X%sZ\"'>Z=6N^Emn\"9_h=p&,A>Ae'U7]61eB4kH\"(VVtHEW-LOg']WR!s;J7B;-^oB4kjmp&W_Z@j,Jl@p=[0A(EGWnfe0G\"^gpi\"'>ZoTE81ub5k[K>KR%PiY6IZ)HU-Ing7T#'Q_h4>?5g&4',Wjap2/1'Q^Da='Jnc,?n2iqAWL?>OitBeh_C<-3IHU=$t.6])h=\\!t,2mmQ*QU3s2'#eH%V22!5*G\"1BsD+ZkN;\"'>ZI6j$Nnn\"9_`=p%i1>HSE>iY6I:$<LG9U(U\\]1NV+S='Jmt1L&EdF2Aq\">6S(M6X,u`QNKTZMEm.nRfQUnq*Y<e\"7Mla='>]->?fMu>LjO1g)sI$>Ga2\\eeN8/$<uL(F1+24>?dgD>LkTOVDA<Y\"]l)$\"TlF>\"-sl\\^BC)m\"'>Z-70?Won\"9_`=p%i1>Ik8JiY6Ib$<LG9L,iJh'm$Mb>?5h=-<FDUZ:%pJ1NU,:\"'Yq1+/8sCRKc,H>CnEr2Zr.BY6!TN\"'>ZoTE8J(\"(,PBME#5N7]61eB4kH\"(Ma+BVu6^5CKo@+DZ`JtG].M)g):'f,Va?B\"#k-#Q9R*F!s;J;\"-,,kDZ^)?B4o'h*bT+uCU+jZ@j,Jl@p@eWA(EGW_DhX-\"^eZ,\"'>ZoTE82%\"'8]2aoYeu'm$Mb>N-?<XpS67>J`@(eh_C,%g-#><s,$??oOo7k5e]b!Sp3I=9J#b!`rP-='Jnc#[>k9F05jS<ce*V>LjO1c5Kbg>O\"OZ<cb,P='Jns%9qC>F5@0)>6S(QSg@S3!Xh'k!s>D2\"@!tq>FGc`56G!iSOWca\"7Mla='>]->?f)j>N-?<c5Kbg>L#?8<cds]='JnO-<o%WF2f@*>6S+!#Bq=QNBRFd\"3F%8=9J#b!af+5?Xm<s4_FjdVu6^1B3X(*CBI&(r<$hN>E1jb\"%Ma(Df8j32?U*20lmF!2fAea2DK7Tr]`,]'5M+\\!s:JpB;RL,B4kjmqA&!(@j,Jt\"%K3e\"(u7NmQC[O.5>T?\"#jk*WWb.jB*/mZ87r#oms&JX>D<mqnd[Bi\"0O^?DZ^)?B4h<J_+4Z_5;?e``[)[=B4l\"_+')kpB4#.QneYfe1NSj4\"(MLAh+.WM\"7Mla='>]->?c\\:>LjO1g)sU#F/BXQ>?dCD>LkTOJi*X_![^tNnf\\*f#N\\5R=9F7K\"'>ZoTE8J(\"(,PBq?^d:7dkS7B3U*#\"8WfgCBN-F0lI0>-S]ZUB4M*Wp'2sXB4iF>5%as4[7LJ3\"YjY&\"'<`=B*1WlG\\:YnL)'lg#r-2t\\h5^U!s;J7B;u(UB4kjmh?6kh+_P.l>O!MEeh_CD#m4Z@?g1,a=Te,c!`rP-='Jn/1L&iQF05jO>?gq1>LkTOJh[@3\"]kd6\"$<5%2^(997Y_\"H\"-H1X=9J#b!af+5?Xm<g+_LmHms&JX>D<UiOr#ig\"6p\"DDZf8-0ln\"@A-6Ir.ir>9q@G#eB9G4qB4kjmP!E&X+_P.l>G_R6eh_C,3Wijq?e%aN=9J#b!`rP-='JnK(0fc4F5dm8>?gA8>N-?<XpS67>N.\\Jeh_Be('@e7!ETAi\"p6r<6Pii,JP-)I\"7Mla='>]->?gq.>?5h=-<FDUiWEE91NT!9\"'Yq1`WnFG3s2'#?oRaH\"5<hY!s;I<\"8W:2)l6jC=9Gs(\"'>ZoTE8J(\"(,PBJj!c/)d^MjB*/n%94n>rms&JX>D<mqV?ntm\"0t-GDZ^)?B4h<JnOmKs7\\f\\YB4kG'3,8UcU\\=e)CKod!!s:JpB4iEO5A('5rC[7P#Vft)\"':1M\".BHLB4pon*bT+uC]6+j@j,Jl@p@ptB*1WlG\\:YnJi3_b1GNYI\"#jk*iZ9I[B4l#R+_Qfc*bT+uCW7(>1LhS@?Xm;t$tIjEF7'57@g-5]9ESB!MZd*b\"'8]2`ZA@D'Q^Da='Jns#$]Y7F6XeK>Q+Y)!s;I4SQsVJ=9IPG.j6R29`nK\"oh5Hi\"7Mla='>]->?fr;>?5g65?D&ng,*$b1NVD+\"'Yq1#;V,:mN.3a\"'>Yn9`nK\"n\"9_`=p%i1>HTbdiY6J5!EWK0Set\\_1NT]T\"'Yq1,F8X>RKg;s\"'>Z=9`nK\"n\"9_h=p&,A>EU[Q\"%K3e\"(u7NL+i_(2)/kK\"#jk.\"%Ma(CMR.+2?VYC0lI-r2f!2A8S;Z<(%G!#NYF3\\B*2629`qs10kY-Z0-4b=B5>XUeh^eZB4#.Qnf;?F7]61eB4kG'0P^b[Vu6^5CKo@#DZ`JtG].M)L(4=^.PYuHl3&hc\"3r8KHP:=.!s8WaCBFYtB4n4r*bT+uCX,.F@j,Jl@p@(hA(EGWecl4d\"^feT\"'>XM='>]->?geW>?5h=-<FDUN[\\2`1NT]+>?5hA)cp6Jeco@01NSR*\"']A=Rg/]p5;.Rt\"47,OKhheQ\"7Mla?WmP=@p>fVB*1W$r<$\\F>LjU+\"%K3e\")D[VmQGIj7dkS?Dd1p6\"6L[[EruM'DZ^)#CBKGF0lI-r;eKao+!,'-B5>3ceh^eZB4#.QhE#/t1NV\\$\"(MLAeP?9L\"7Mla='>]->?gM*>?5g&4'U\\YF8c2A>?efb>LkTOXpSCa'm&pe='Jnk+C!DQF1rgd!F#_/K*MKWK*N4Y\"YH/I`DZk@\"-$+Z=9J#b!af+5?Xm</\")%0S?EOKF!u8(;B*1VupAno>>Q-$d\"%K'[!GcITiW0,`2eQb*=1M-0l8UM2BCZ0QB4o?u*bT+uC[)Yo'Or;!?Xm;p*b3bWF7qQq@g-5m:]jf%n\"9_`=p%i1>I\"K<iY6I:$<u'rF05jO>?gqU>LkTO`\\(IrF3ZdI>?ge\\>LkTOU'h(t\"U.s0q?UIRgB,Yco)U'<Q4G]#X];P*=GHpB;$0o&n\"9_`=p%i1>M^B)<cb,P='Jo&$!Yt:F.ONW>6S(Mc9Q+d\"/Z9(-hU^H=9H66\"'>ZoTE81u\"'8]2RN,P_'m%Y=='Jn/10`<cF.+'N>6S(1OpWoSSQ>nq\"6!)Z=9J#b!`rP-='Jno1g=\"%VA**9>HSuNeh_B)1':_a<u9.IC)7!'(kD]0V+Unm\",TnX=9J#b!`rP-='Jnk03d!`F05jO>?d[.>LjO1jq_$&>GaMeiY6I:$<pPPp*NjF>I\"uJ<cdsP='Jo.3Et&LF05jSeh_B93EKEhdQh$r'Qa6S>?5h=)-bZ,F2fh6>?eZI>LkTOjt?g@\"]p`f\"'$k76n9Dsjod1XK*.tR/*?pTl4\\pV^]CbElN->R$J,=]\"'%/M@CHFr\"8u+\"=9J#b!`rP-='Jo*3*TF)VA**9>E0\"oeh_CD3!3@g<s+Tmg&X.C=T_b.Ti2%q\"7Mla='>]->?geT>LkTOXpSB6F/BXQ>?gYZ>LkTOp+QSQ\"]kql$MFK>_-d@I\"3FID=9J#b!`rP-='Jn',$WV5F.,*j>?ff!>N-?<XpS67>Oj@M<cds]='Jml+^<MRF1NRu>6S(1q?UI^0<u:,P5tcK$8FIALB:C-i]Se80?mN\"-Nf?-\"'>ZoTE8J(\"(,PB^(Y,]7]61eB4kGs)J]FEVu6^5CKo@#\"8Xo1DZ^)#CBNQ;0lI-r;eKag/KSP;B5=Y)<b!:c?Xm<#3b-_sF/B]T@g-5e<!-5)n\"9_`PlUtg>?csg>?5h1)HU-IdQq*g1NQT$<ccPH='Jmt*a;ZdRQk$-1NVOi='Jn/#[:>NVA*7c1NT]+='Jn+(0f?GF,C,'>6S(1\"/Q#+F1N\\,NY;Nk#[e2C#-ns-!>!Wai\\<#$YtG1$\"\"1AgC+#ib\"'>Z1<<H>*n\"9_h=p&,A>L\"8_,A2#a3GS^dms&V`>M9tthC(*s!s:JtCM-4OB*/n5<G)D'ms&JX>D<mqnd[Bi\"-O][DZ^)?B4h<JrDdJ47dkS7B3TsG\"25L)CBFYtB4mqT*bT+uCZ7#,'Or;!?Xm<g2Ik;oF0\\%5@g-5-<WcG+n\"9_`=p%i1>NuT#eh_BM$<LG9Q3gbrF6Wj/>?f)l>?5h=-<FDUZ9VXF1NSig\",?m\\<s&QU!@*p8q?UIVV,[U4\"4:-O=9J#b!`rP-='Jn[,?s.AF8c2A>?gea>LkTOeft9$\"]lYH!F(usoihN#\"8,[s=9J#b!`rP-='JnG!aA]Hp*NjF>N.JDeeN7p#$5#5M?@)61NVP4\"'Yq1!s;Pi#4Y@hBEOr0\"'>ZoTE8J(\"(,PBOqR15B5se7B9!TPB4oL3*bT+uCQ8PK'k8D\"?Xm;t*b3bWF/hG,@g-5a<s)P,n\"9_`=p%i1>IGSWiY6I:$<LG9W]s_=1NTuG\"'Yr$#6X8o;_R,n.j6Pf.pJGH\"8W:20?%/u=9JM'\"'>ZoTE81u\"'8]2[R\"-K1NT]+='Jn73*XrKF05jO>?d7O>LkTO[Qt\"\"\"]s^c\"&gkl=p%n$\"0#B)=9J#b!af+5?Xm<7/nY8UVu6^1B3Wq'CBI&pG\\_)!L(4<_+>Id:RKtWh\"3r8KG8\"b&!sAN,0lI-r;eK`UCRPK@atFfKB4l#65h6Z[+_P.l>H.^6eh_C4\"Tr6<?hme+=9J#b!`rS*\"]no4N\\ao!'Q_P<>?5gb/lu7]l31DC1NSR4\"'Yq1joh:X[K4K$SQQ%s\"7Mla='>]->?erX>?5h=-<FDUdN2WD1NUDH\"'Yq1Z\"!m\\!<^#<\"'>ZoTE8J(\"(,PBh@F6$7]61eB4kH\"(B`5>0l$mF$ScQ%\"&iiJ\"%Ma(CMR/.)?ZQl0lI-r2f!&A*G9!e(%k]3l4PgaB*24l>%[q,ms&JX>Cna8iWLuO!s:JpB;R@(B4kjm^)GuF@j,Jl@p?YZA(EGWdPCu8\"^e*0\"'>ZoTE<RD=p%i1>D<Sk<cdO.='JnW1L&EdF+t,+>6S(1\".TBFktD1]\"3F^K=9J#b!af+5?Xm<W3G/F`Vu6^1B3XXd\"26iOCBM9i0lI-r;eKaK![hVn[MBosB4l\"K\"QC,*+_P.l>G;R>\"%K3e\"(u7Nl9K+e7dkS;CKlBK\"7@WnDZ^)#CMs;Ems&bh>D<mqV?ntu\"2Yd-G67qGDej8rCBO8b0lI-r;eKaG5osZOB5@'$eh^eZB4#.QedZ-?1NUDn\"(MLAc!/'j=9EJC=p%i1>M^i6<cdsP='Jml$sV9tF05jO>?es)>LkTOhC8V3\"]s\\H/#<8\"Ki/\"To)\\Yk\"'>ZoTE81u\"'8]2dR%/=F8?hW>?geX>LkTOdR\"%?\"]kg&#\\YkEZ4q%,\\PWH2\"//s%=9J#b!`rP-='JnO.U1I=F4N-K>?gYO>LkTOasmKt\"]kg&#[e/VZ4q$eSPoVm\"3FdM=9J#b!`rP-='Jm`-!Sq8F05jSiY6I:$<LG9qCl.)'m#g(='Jmt$sV:=F8@Qm>6S(]Z4q&7\"Skrn\"'F\"Vq-4#(\"7Mla?WmP=@p@e&B*1W$r<$\\F>OFXi\"%Ma(CMR./('F+;0lI02,r'HC\"&it;OtJJ-\"4AGLEt`1s\")A!.ms&V`>D<mqnd[Bm\"1fj7EruMCCM.EKB4h;]fj/4m7dkS7B3U*+\"7cpVCBKG\"0lI-r;eK_F=5dEeP!:[6B=]B1B4kjm_?<nL+_P.l>K-bTeh_BA\"Tr6<?i=74=9J#b!`rP-='Jo&(gC$^l2t*l>E0V+iY6I:$<LG9U'4cP1NW7,\"'Z[F!s<ikM,5^)\"0#T/=9J#b!af+5?Xm<S2eN4^Vu6^1B3UBZCBI&(r<$hN>OFXm\"%Ma(Df8j32?WY$0lmF!2fAd#2erN<&i\";,\"&iiFnf&W_B4l\"C.99q%B4#.QrZbq(1NU8h\"(MLAq-F/n!<_e`!`rP-='JnK**ZHbl2t*l>J<%#eh_B=(B[kF<u]FMC)[9+(bm6;\".]H3\"8W:2+-BD&=9GO0\"'>ZoTE8J(\"(,PBU(q;C7]61eB4kH:4TgQ\\0l$jn2eQn.7dkS;CKoL2\"7AH0DZ^)#CM.EKB4h;]nR#o27dkS7B3U*#\"3*V]CBNi)0lI0>-S]ZUB4M*W\"'>;*\"0*\"hB4nM#*bT+uCUP&='Or;!?Xm<3\"(Tn<F8@ft@g-5)?isL5n\"9^a=p%i1>Oi2,eeN8/$<LG9U(:JZ'm#g(>?5gB'N\\LCqDVX01NT9$\"'Yq1\"-O7S!LF\"A:BO^k!l\\OL=9J#b!af+5?Xm=*4D+acVu6^1B3X(*CBI&pG\\_)!L)'m^%P_l(r\\ZEO!s;J;CR,qfCBFYtB4o48*bT+uCQ]Oc1LhS@?Xm<_$YKQ2Vu6^1B3U*E\"9(A:CBFYtB57T=ms&V`>M9ttau(nl!s:JtB58N#B*/mN@0?'?0kY,$=1)H=^'ZT-B@[Y9B4kjm^'n%P+_P.l>F$.:eh_B)3<Nap?dW9a=9EVG=p%i1>O!/3eeN8W1KRdbME+nl1NVh#\"'b*m<s&P'VZ[+u#[eJ);$0o&q-aA-\"7Mla?WmP=@p?Z4B*1W$r<$\\F>OFXi\"%Ma(CMR./%KkPg0lI0Z\">Os\"c6k>j'5M+\\\".BKMDZ^)?B57T=ms&V`>Cna8iWLuS!s:JtB59;9B<F69B4kjmXp<Mm@j,Jl@p@eRA(EGWJjKQL\"^fql\"'>ZoTE81u\"'8]2L'q5F'Q^Da='Jng$<uL(F3Y\\*>?c\\G>LkTOiX,cl\"k*T1iriSt-DahF!a#PY@fog8n\"9_`=p%i1>Gaemeh_B93EKEhhDnfk1NT]+='Jo\".9k@ZF/D>->6S+.#I5%Y0;el7$8FL8<s)P,.0EZS\\RP_D\"7Mla?WmP=@p@(sB*1W$r<$\\F>OFXi\"%K3e\")D[VL+mNJ7dkS?Dd.r+\"83onEs(\\10m<`N2)0FkDe&qP\"#jut\"#jk*Q:)d,B4l\"?1tECO+_P.l>HSKHeh_Bm3Wijq?]ARu=9J#b!`rRg#?P,6ar\"@61NUh[='JnS3a:/kF35=%>6S*O!B45G']j$2=9Gg=\"'>ZoTE8J(\"(,PBJf/2'7]61eB4kG'0P^b[ms&V`>Cna8iWLuS!s:Jt!s:JpBCZZ_B4p'Q*bT+uCX*dJ1LhS@?Xm<S$\"MOBF5@B/@g-64A-5p9P64li\"'8]2Op#\"K'Q^Da='Jo*6<dK3<``L0h@<c@1NWCZ\"'Yq1!u%7,5Irg9+[;r;lN:5k48ok6l5%?N\"'>Z-AHQ$:n\"9_`=p%i1>KR:W<ce6@='Jm`-sK_np*NjF>KRI\\eeN8[+BMcOeid6g1NU\\G\"'Yq15PtPN!<]VV4!Bdlc\"@+r\"6F(r=9J#b!af+5?Xm=25A('fms&JX>M9ttJhJio!s:JpB9jeaB4kjmP!<T>(`m=&B5>'geh^eZB4#.Qq?(6Y1NUhG\"(MLATk4C/!t/16\"'8]2egXg(F8?h[eeN8O)HU-Ic3@M(1NV+r\"'Yq1\"3qB(P6?_W\"'>ZIAcl-;n\"9_`=p%i1>OjCNeh_Bu1L&EFF05jS<cd77='JnS%pRU\"F4L\\\">?fZ1>LkTOnh(#K\"]q#o5M6'1\"-Q&,pBCM-\"'>YVB*26<n\"9_`=p%i1>KR7Veh_BM$<LG9h@WuC1NU\\F\"'Yq1'BTEP8\"\"#m=9GC4\"'>ZoTE81u\"'8]2^(\"<+'Q_P<='Jnk$X;U)F05jO>?ct)>LkTO^'t0K\"]mY[\"'a1\\]kX#>=9Hr`\"'>ZoTE81u\"'8]2\\e//t'm$Mb='Jo.'jK6FF4M32>6S(1\"#i.t1Hkp&BEMA+\"8QR3=9J#b!`rP-='Jng,[97BF05jO>?g)1>LkTO_D)-s\"]kd.<BHmc_Zs9GSS/+-\"7Mla='>]->?c[g>LkTOXpS67>J`$teh_B!%0Kf<=76Bk\">NQ_BEM?=_.WpQ\"7Mla='>]->?d[->N-?<XpSCa'm$Mb='Jn;6<i\"sF1Nb%>6S(1l4YmJX^je$mf`dqEWb]B\"'>ZoTE81u\"'8]2Q7?+i'm$Mb='Jmd,$WVSF1+24>?fe`>LkTOdMW-k\"]meb&p*ITT*G,sF4(7WhujAhSS81.]*4mB\"'>ZoTE81u\"'8]2k!3/%'m$Mb='JnK6X/OaF3Y\\*>?dsG>LjO1g)sI$>I$P!iY6I:$<LG9ehC=Z1NTE7\"'Yq1Z7.jYlNRG92`EZ#55PBdWrZGq2\"bJ`=9If%\"'>ZoTE81u\"'8]2_ED,S1NUh[='Jm\\!aF53F2C'B>6S*K\"ZKYO3h^0g=9FOt\"'>ZoTE81u\"'8]2RQas8'Q_P<>?5g&4',Wjjtp;n'm$Mb>N-?<XpS67>Cn2+eh_B94p,!m=#]RO!gX\\2A((K][faH]\"'>ZoTE81u\"'8]2mPS5.'Q^Da='Jo\",?r_TF7(mf>6S(1VZg'^l\"C0$\"54*Z#7QUtWsQWK-IW5#!<<*%!!!!+z!!!!8!!!!W!!!\"W!rr=>!!!!b!!!\"l!rr=T!!!\";!!!\"]!rr>[!!!\"b!!!\"Z!rr<B#64`F#64`F#64`F#64`_!<<,?!!!\"\\!rr<F#64`J#64ah!<<,_!!!\"[!rr>K!<<,q!!!\"X!rr>o!<<*,!<<+Z!rr<;!WW3;!<<+^!rr<:#64`H#64`H#64`a!WW3[!<<+\\!rr<D#64`H#64`H#64`H#64aN!WW4%!<<+[!rr>+!WW4J!<<+Y!rr<>#64`B#64`B#64`)!rr=q!<<+]!rr<k!rr>&!<<+[!rr=*!rr>2!<<+\\!rr=B!rr>>!<<+Y!rr=Z!rr>c!<<+Z!rr>P!!!!i#64`p#64`p#64b[!rr>r!<<,&!rr>m!rr<>!WW4u!rr<[\"98E^!WW4r!rr=D\"98Et!WW4p!rr=p\"98F$!WW4q!rr>%\"98F0!WW5\"!rr>=\"98FR!WW5!!rr=!#64a%#64a%#64`5\"TSOc!WW4o!rr<K\"TSOn!WW4u!rr<a\"TSP%!WW5'!rr=$\"TSPH!WW5#!rr=j\"TSPU!WW5!!rr>/\"TSPl!WW4u!rr>]\"TSPu!WW5'!rr>o\"TSN+!rr=s!rr<n#64`r#64`9\"onWb!rr>'!rr=+#64a/#64a/#64`j#64`j#64aV\"onWs!rr>'!rr=j\"onXA!rr>\"!rr>[\"onXR!rr=t!rr<p#64`t#64`t#64`t#64`3#64aa!rr>(!rr<C#64ap!rr=t!rr<a#64bE!rr>$!rr=`#64bc!rr>!!rr>G#64c#!rr>&!rr=)#64a-#64c$#64`0\"98Fs!rr=!#64a%#64`?#QOi<\"98G!!rr<M#QOij\"98Fs!rr=+#64aZ#QOj.\"98Fq!rr>1#QOjQ\"98G$!rr=##64a'#64`)#ljs_\"98Fr!rr=)#64a-#64`C#ljsl\"98Ft!rr<U#ljt0\"98G#!rr<j#64`n#64a:#ljt;\"98G'!rr=H#ljtJ\"98G(!rr=f#ljtV\"98Fu!rr>)#ljtb\"98Ft!rr>A#ljrB\"TSP'!rr='#64a+#64a+#64`a$31&`\"TSOr!rr=<$31&n\"TSP\"!rr<r#64a!#64a!#64a!#64ad$31'(\"TSP\"!rr>!$31'J\"TSOu!rr>e$31'h\"TSP*!rr<K$NL0u\"TSOc!rr<c$NL1K\"TSOk!rr=d$NL1W\"TSOp!rr>'$NL1t\"TSOn!rr>a$NL/7\"onXg!rr<=$ig8P\"onXe!rr<m$ig8^\"onXf!rr=4$ig9'\"onXl!rr=p$ig9N\"onXj!rr>i$ig9Z\"onXp!rr<+%0-Bd\"onXg!rr<=%0-C@\"onXm!rr<L#64`P#64aR%0-Cs\"onXn!rr>[%0-D+\"onXk!rr>u%0-A3#64ar!rr<H#64`7%KHJ?#64aj!rr<G%KHJM#64ap!rr<c%KHK\"#64ai!rr=b%KHKC#64aj!rr<T#64`X#64bW%KHKN#64ao!rr>e%KHKf#64ag!rr<?%fcTs#64aq!rr<W%fcU1#64ai!rr=(%fcUI#64ap!rr=X%fcUR#64ai!rr=j%fcU^#64af!rr>-%fcV,#64an!rr>s%fcS7#QOjp!rr<5&-)\\U#QOjr!rr<o&-)\\j#QOji!rr=D&-)\\t#QOjq!rr=X&-)](#QOjh!rr=j&-)]8#QOjk!rr<V#64`Z#64`Z#64`Z#64bA&-)]G#QOjl!rr<V#64`Z#64`Z#64b]&-)]i#QOjn!rr<Z#64`^#64`P#64`P#64`M&HDg%#QOjl!rr<a&HDg2#QOjr!rr=&&HDg^#QOjs!rr>)&HDgn#QOjp!rr>I&HDh$#QOji!rr>_&HDeR#ljsr!rr<g&c_o!#ljsp!rr=X&c_o=#ljsm!rr>;&c_oE#ljsr!rr<`#64`d#64b^\"onY_\"onY_\"onYX&c_p##ljsC!rr>h\"onYk\"onWb'*&$/#ljsA!rr<q'*&$j#ljsM!rr>='*&\"4$31'J!rr>d\"onYg\"onW.'EA+Y$31'I!rr<o'EA+c$31'H!rr=.'EA+l$31'L!rr=@'EA,!$31'F!rr=T'EA,7$31'O!rr>n\"onYs\"onYu\"onZ\"\"onW'#64`<#64`<#64b='EA,G$31'M!rr>K'EA,Q$31'E!rr>_'EA,b$31'K!rr<+'`\\61$31'C!rr>V\"onYY\"onYY\"onYY\"onYe\"onYe\"onX+'`\\6]$31'I!rr>b\"onYe\"onY&'`\\6h$31'L!rr>5'`\\6s$31'B!rr>K'`\\72$31'L!rr>h\"onYk\"onYk\"onZ''`\\4?$NL0O!rr<9('\"=e$NL0b!rr=.('\">3$NL0N!rr=t('\">_$NL0O!rr?\"('\">i$NL0M!rr<5(B=Gt$NL0F!rr<I(B=H+$NL0N!rr<a(B=HW$NL0I!rr=d(B=Hu$NL0H!rr>^\"onYa\"onYR(B=FH$ig9L!rr<G(]XOt$ig9G!rr>Z\"onY]\"onXO(]XPD$ig9c!rr>=(]XPP$ig9P!rr<:#64b[(]XPo$ig:3!rr<=)#sZ8$ig:b!rr>6#64b:#64a*)#sZH$ig:c!rr=B)#sZa$ig:3!rr=t)#s[#$ig:b!rr>M)#s[.$ig:3!rr>c)#sX@%0-Ca!rr<3)?9aT%0-Cc!rr>:#64`_)?9a_%0-C5!rr=3#64a;#64a;#64a$)?9ap%0-C7!rr=/#64a3#64b8#64b8#64aH)?9b>%0-C4!rr>Rz!W_K\"!<iR-\"7Mla\"'Pd/#@#2##M(\\PXpP79>FGa$eh_Be/cu=^\"7$!jEW[Ti=9J#b!WuU.!s`&]$3sUQp*KkH>Oig?eh_Bu$3LM:!s&LH\"6flm\"(^$n!WW3#!rr<$#QOi)!<<*\"'*&\"4&-)\\1z!#,F!_#`3k\"'>ZY!s;X-f`M=Y\"7?>e%Tq'ef`M=Y\"#p2lF6XMS3s#N[!WuO,!s:J<`<$-D\"#KQM$3S-q0-N,-QidZt`]l+\"1[P8H=9AX-<>T'G=9Ada>J<9'\"'%9=rXs:\\1cL^7F8c3>!<ZF+!s;O^'a%P?(V1r7eeP^s\"'>Xen,`q!Z7.^U3s,RD1G]8\"\"5s:`=9AX-<Aul9&p&pP2jP/!RKb_M+EPO'44jZC\"-!Hd=9CMY#BTSSh#mg^\"#p2lF4)Hqq?M)%&SV>L\"#p3%F.,#_!<ZF+Z7.^U3s,RD1G^CB!s^Vd^-2W$<B'\"C\"'>X-\"#i\"l+$Kc31L&R#OTP\\f\"$=-u$3RR_2^(7ARO<0f!?hPI\"#p3%F.,!KquR3-Z7.^U40\\hh=9CY#!X]%?\"9Va.!s;O^2uXG2RKYX9'Qa6SklClg!s8Wa1T^f_=9Ada>J<:L\"'>X-IPFIt'*C>-3&`!BPlUth\"#lYrF/D0u\"Tqj/!s;OB)nIA;\\cL=_\"'>X]'0ZMd!WuO,Q6n7.1FWE.!s8X*+!8'@F1MCO\"9Va.#;]TT1g'o_!t2[eF-\\/@\"9Va.!s:J<T`bI\"!s=i90g>cW.ksEe\"9Va.!s:J<1CHAKnHB\"s!s8X*2`L^KF5eQ+RO<1=-TdOn$3RO6\"'>XaQ5\"D/\"ulN(F8c2%ciOOV_#sjB!s8X*0/Mem$3SNS\"'>X-!rsjZ!s;X-2ju+8VE^1E\"'>XaRO<0f!R1`L=9AX-<<qIb\"'>X113;k)!s;O2klLrh\"#HkW$3P`1+Ys5G%U_(K1L$.^1G`7,-o3Y`Q9$fX>LEi\\\"'%:N!<ZF+'=oN3\\cFqr=9AX-<=dad\"'>X](Hqp'\"*+JG\"'$T1\"9Va.!s;O^aTVcK\"0s@7+ZmdJ\"'>Z2.5rD32ju+8eeR]V\"'>X-\"#i\"l)a4?/1L%RWYlk/2\"$>EC$3RR_2^(8:!s;X-,;O?&-NaHN-RUZjjsRtI\"'>X-`]l1JT`P<u\"0s@7+ZhWO-ZcFUaT2KG\"0s@7+Zn'R\"'>Xee-$*\\JHZ-X\"#CHO\"%<;o!s8Wa1S\"[O=9C?(4p)$G>J<9'\"'%9=rXs:<-9%5)F.*:lrZH9^!ndSV=9CM]&p)&W2jP/!RKb_M+EPO'Pm%7l!tVsiF/D/(\"'$\"s\"9Va.2uXG2_@S[&#BRaKV#pg%!s^Vd^-7)L\"'>Z7zzz!!!#kz!!!!m\"TSNt\"TSNt\"TSOM\"TSOM\"TSN(\"TSN&\"TSN.\"TSN,\"TSN,\"TSPh\"98Gg\"98F>\"TSO?\"TSOA\"TSOC\"TSOC\"TSNp\"TSNp\"TSPh\"98Gg\"98ES\"TSNR\"TSNL\"TSNL\"TSNL\"TSO[\"TSO]\"TSO_\"TSOa\"TSOc\"TSOc\"TSO+\"TSO+\"TSNN\"TSNP\"TSNP\"TSOE\"TSOE\"TSP(\"TSP\"\"TSP\"\"TSP,\"TSP,\"TSP,\"TSOi\"TSOi\"TSP\"\"TSP\"\"TSOU\"TSOU\"TSOW\"TSOW\"TSO7\"TSO9\"TSO9\"TSO9\"TSOG\"TSOG\"TSO1\"TSO3\"TSO5\"TSO5\"TSO?\"TSO?\"TSO[\"TSO[\"TSO'\"TSNt\"TSNt\"TSNt\"TSO;\"TSO;\"TSPj\"98Gi\"98Gi\"98FL\"TSOM\"TSQ!\"98Gu\"98Gk\"98Gk\"98Gk\"98Eo\"TSNp\"TSPb\"98Ga\"98G+\"TSP,\"TSO!\"TSO#\"TSO#\"TSNp\"TSNp\"TSNp\"TSP\"\"TSP$\"TSP&\"TSP(\"TSP(\"TSP2\"TSP4\"TSP6\"TSP6\"TSPt\"98H\"\"98H\"\"98Gq\"98Gq\"98FH\"TSOI\"TSOe\"TSOe\"TSP`\"98G_\"98G_\"98Ga\"98Ga\"98E7\"TSN6\"TSQ$!!!\"P!!!\"_!WW5c\"98Ge\"98Gc\"98Gc\"98G+\"TSP8\"TSPn\"98Gm\"98Fh\"TSOi\"TSOG\"TSOG\"TSP6\"TSP8\"TSP8\"TSO[\"TSO[\"TSOi\"TSOi\"TSO-\"TSO-\"TSO-\"TSPn\"98Go\"98Go\"98Go\"98F$\"TSO%\"TSOq\"TSOs\"TSOs\"TSOc\"TSOc\"TSOq\"TSOq\"TSO1\"TSO1\"TSO1\"TSO1\"TSO?\"TSOM\"TSOM\"TSOO\"TSOQ\"TSOS\"TSOS\"TSOk\"TSOm\"TSOo\"TSOo\"TSPd\"98Ge\"98Ge\"98G-\"TSP0\"TSP0\"TSO1\"TSN&!!(lj!>P]=!u1o?!u1o?!u1o?\"7HT5#<:rN!s<QG\"TSN&zzzz(]XO9!!`l7(+:^`0ENjF+srDe!D*Aq\"%`Ss\"%`Ss!s\\oC'o`4r=9AX-EWa#d_?*ZG!>P]=!s>,;?je[k=9AX56j\"G3=9Ap=>Im'1C^L7n\"'>X5.onD5!u8'Ah#RU[!s8d8!s\\oC%D;cE=9AZF'jqDh\"'>X='3haq(CO9(3>WK9_@Qe_@10=@\"'>X9$Wd66%hDm-//&ClrX)p5=9ApU<\\b$b'sRd&\"'>X-MC)^=PlUth!s8W+$_7;#=9Ap=>99UA\"'>X5\"'64g!<ZF+'a%P?$Nh(V!t/]CXT8N+!s=E-?jk?_\"'>X5$X4Y[!u29u!<ZF+!s8Q3`;p'C\"!IbK\"'#G*!uh4?zzz!;lit!;lit!;lit!*fL(!.k4O!##>4!\"Ao.!5\\^9!/:LS!/:LS!<*!!!<*!!!<*!!!!3-#!.k4O!.k4O!%e0N!$D7A!!!$\"!<*!!!<*!!!<*!!!(d.j!%S$L!<)ru!!E?'!!E?'!!E?'!!E?'!+>j-!&jlX!5SX8!!!*$hnK1,\"'>X?\"'>X?\"'>Yp\"K;nuecZ]i=9AX1?NUB4EWZLGzzz!!(4Cz!!!'#!!!!&!;F5/9`nK\"#m493n\"9^m=p#9K>OigK<cds]%hi1,'GK%RF7L@S'*Sn@\")J&g\"'>ZoTE5X-!tQ&L4qloiF05i\\'3kG:'@ns\\4p)H%%o(pd=9EgN=9I1ciX'G*##PJ)\"7Mla%pB&G'3jl@'B0^IRKaF+F-[mY'3j/l'@ns\\mM>s=\"V1_4\"_.W>!u5rI\"'>X-\"*+JJ!!!!$!!!!2z!!!!S!!!#7!!!!J!!!!=!!!!\"!!!!S!!!!Sz$k*.=\"U>>A%1a$a'c5cC!OW\"3=9Gr5\"'>Z5!s;X-'.6g9'*Au;!j)M+=9B3I<\\cf?=9BK]>G<6/\"'>XAOskD6-SY^*!tQ>T[Q#3F>Lji=\"'>X=!u6XqE<B;FL,'Pg)d*8F!tQ&LrXo;8<>R(d=9B'Q>IHL1)dB`Z)]N\"Q4lutc+WD4*F;#Mo=9G)r\"'>Z!\"dfE\"YR(sF'H;T(\"'>X9(L-kO!u\"')i;s*`!tQb`[Q#W:($,IM!s;X-!s<QG\"1AbK,9nF;WWoF'\"'>XIjT.=c\\H)e7!tQJXWWo!p\"'>Yb!<ZF+#6S&8\"4[DS=9AX1.g+#s\"'>X1030jA!<ZF+R/mCl\"-iuk=9B?IF;*=.\"'>X9'3kGK!s;O>(Qp1fmN*1!13:_g(ZksDc6qEK\"'>X-'1;qf!WuO,'*ApnN<02a!tQ2PrY#/1\"'>X7\"'>Yj\"9Va.\"0+Ll',)$`RO4I-'+!\\#o`>4t!ttbN.h<G#rXo;H6j&hY\"'>XQ-X2HW`<$-D\"0MtY9]Z<2!WuO,%jtSi37S'4=9Bou>IFsR!WuO,9`nK\"'-C71'*AsYK`V?Y!uh=V#Q4]+=9B'M>Q,9&!WuO,(ZbZW)mKDG=9B']>IHL=-X5.C-Nb+F!V$6o=9AX=6j'Cj\"'>X=!u)CZ(L-kOPlh+j\",R-_=9Ap5<k9Wo!s;X-\".gWC#6tK<\\hC/f\"'>Yo2@ECjaTDWI!s8cr\"472Q=9AZn-t!8^Z6!B]$hbZW$O[>*&![8&3s,Sn$o'C;\"&gRu\"9Va.%jtSi3;EXY=9Bq>'l#,X!s;X--Nb+F!R1ZJ=9B3Q<\\b<j(#]4>\"'>X-#9999`;p'C\"%*%gzzz!<*'#!<*'#!<*'#!:0df!:0df!9O@`!9O@`!9=4^!9=4^!9O@`!9O@`!9O@`!:0df!:0df!9O@`!9O@`!9+(\\!9+(\\!9+(\\!9aLb!9aLb!9aLb!9aLb!9+(\\!9+(\\!:0df!5&:3!'^G`!$_ID!;Z]r!8mqZ!8mqZ!8mqZ!87MT!)W^r!&\"<P!:U!h!#,P9!#,P9!8[eX!8[eX!#,P9!#,P9!#,P9!,hi;!':/\\!!<9&!!i]-!\"&i/!\"8u1!\"8u1!.b+M!(Hqg!;uou!07*[!)!:l!:U!h!!!-%!!!-%!!!-%!!!-%!20Am!*B4$!:U!h!;HWr!;HWr!;HWr!4`(0!+c-1!:U!h!6kKD!,DQ7!;?Ko!8.>P!-A2@!:Bjf!:'Ub!-nPE!:Kpg!;-<l!.k1N!:U!h!:g3l!:g3l!:g3l!8[eX!!!*$jhCg2\"'>X?\"'>X?\"'>ZT\"O.3>SdZ>9=9AYs+CGF'\"'>X-#=JY?\"'>X-\"*+JK#@\"c)$\\STh\"!%JG!s\\f+zzz!\"&]+z!\"Ao.!\"/c,!$27C!'UYg!!!K1\"p;BN!<\\o9?j@\\S=9Ad1<jjsm!u1h_\"'>X-#A+&E\"'>X1#@\"bm'a%P?T`G6t!s93F,6QpT?m@$$<rN^V-SFO/4Tedgh#[[\\!sANC0deIR<rN^6Z6E[0I03RR\"3)'`,=)E6\"!@LC(H2Eu2`(F61K$\"2\"#hkd^+Clh0D7YM0/\"hE.k_-.\\gAj.=9AZ.)dkHX1L&EQ=T_b.#6S#830=4D=9Ad5>Lji#!u1jY!<ZF+])g(Z0'<K0!WuO,*tMTq+!4^E*T7#$=9AX-;]DP6\"'>X5'3gJ>$Q!$I,m+6J&\"s%,=9AYs+CGEZ#@\"bmeH#bS!s=8t0ae'g6j*5c\"'>XIh#\\hd*6eNe=9Ap94V%Y_$t'SV%pQb%\\H)e7!s>tN?j@'q\":>7q!<ZF+(EZkA+;Z8,W[4nN\"'>X5'0Qj.mL3JB)]N\"q0SKQ1=9AYs+CGir'3i%$\",7dM(BY==!s>tN?kX@O!X]$l!WuO,,:?bA`<$-D\"6Lue!X'b$!WuO,\"6(e<,:<RorXumG\"'>Y&\"'>X-\"*+JKRMBQB\"1AUm%g)o4#PeE'=9Ad1<jk!H!WuO,#6P\\AM#d]\\\"#KuX!$h[I!$h[I!%%gK!%%gK!%%gK!$h[I!$h[I!$h[I!$h[I!%%gK!'15_!#Yb:!\"],1!$21A!$_ID!$VCC!$)+@!(R\"h!%.aH!##D6!&OZU!%%gK!&OfY!&OfY!&OfY!&=ZW!&=ZW!%\\6Q!%\\6Q!%\\6Q!%\\6Q!+u93!&srY!#,J7!&ar[!&ar[!%J*O!%\\6Q!%\\6Q!%\\6Q!%J*O!%J*O!%J*O!&=ZW!&=ZW!&=ZW!&+NU!&=ZW!&=ZW!&=ZW!%nBS!%nBS!%nBS!%nBS!&+NU!&+NU!&+NU!20Am!*9.#!#u%?!&ar[!4)Y*!+,^+!##D6zgV3ak\"*+M'!N6&0X9en0=9AU)!!!'#!!\"tY!!!!&!sfYHk.^p/\"'>X;\"'>X5\"%r^u\"*+JG#@@Q8q?UI:*<TCG$O^1u0ae@njpDL91hmC3\\,cp=#m493&Hc,;apHl+..n#Uzz!!!\"P!rr=S!rr<&!!!!.!!!!+!!!#9!<<+S!rr=U!rr<$z!!(lj!>,E9!tbW;!tbW;!smBYB?CA[\"*+JU\"'>X/zzz!!!\"*!!!!#z!s&G^^B#&O=9B9?=9B9?=9Gu9K+&11!WrOF!s\\p/[Q\"Ks>Lji##@!oF,m.6O!s9kT\"TSN&zzzF8u:@$NL/,#ljr*'`n@8!!!#R^B\"E=EWaVmXpAd_\"p\"g.!s/H&!!3-#!;$6kzhS0('\"'>X;\"'>X;\"'>X;\"'>X-\"*+K]aTsu+#6b)-zzzz!!3-#!!!9)p:gW\"\"'>Xs\"'>Xs\"'>YB\"'>X-[Lcg_'.GmW%0K]7',Ol]3#<B8efLh4(Ej\"c$QK`\\#:flY\"*+Lu$b?g%JdN$s/SYe(%m:!s$U#.P$TeFm#@@Q8NWrl!\"3LmW%lj_o!tub?!s8Wa)eB+R!uh=W.<P_p!s=]7?lN5N=9BQG=9B?>zzz!!$[>!!$[>!!$[>!!$[>!!$a@!!$a@!!$a@!!$U<!!$U<!!$U<!!!W3!!$U<!!$U<!!$U<!!$U<!!!'#!!$U<!!$U<!!$U<!!\"YP!!\"#>!!\"hZ!!!!'!3*a7\\H)e7\"1\\F7=9H)7\"'>Z9!<ZF+\"8W:2#6tK<WXB'3/p!IH\"8W:2#6tK<WXB'33HN1j\"8W:2#GD2$=9AfN5]`M7nGr_o!s]'8WXB%:>F%'\"\"'>X5$X:>!\"7dfo%uC>i=9AY_%P\\b5$Y0?k(^D2l&Hc,;!s<QG#7\"J5$O6o@Q88c'1NW7Ci;j$_!sAB*?j?oA>H/(Y!<ZF+#HeGUef8f7=9AfB%We?f\"8W:2#O)6k=9Ap=>J;e^!<ZF+\"0M\\[%g2MP0b[Cd=9Ad5>H/'^!WuO,\"8W:2#<;lg!sAB*?jC6F=9Af2)0=(O\"8W:2#6tK<WXGp1\"'>X1#@!KM_#XX?!sA6U?ji5#\"'>X-q?UI6[/pG4!s]'8WXIJ\\\"'>X-q?UI6W<!*'!seZGF2fu?!<ZF+#7\"J!1P#Q/=9AZ.$8E1rRKbJ_Pl_%i!tu&Q\"/80g+U_]\\=9Ad5>H/&5p,?@e70?Wo#7\"J!1Pl,7=9Ad5>H/&9#@!KMq#LS\"\"76BW$!`r.4obQ_zzzzj9GYbj9GYbj9GYbjp(kdjp(kdjp(kdkQ_(fkQ_(f)ZTj<&HDe2m/m=gkQ_(fkQ_(fkQ_(fiWfG`iWfG`iWfG`iWfG`kQ_(fecu0Tecu0Tecu0Tecu0Th?O#\\h?O#\\h?O#\\g]mfZg]mfZi!05^8H8_j.KBGKnH/akg]mfZg]mfZg'7TXg'7TXecu0Tecu0Th?O#\\i!05^i!05^i!05^h?O#\\h?O#\\iWfG`iWfG`fEVBVfEVBViWfG`iWfG`g]mfZg]mfZfEVBVfEVBVg]mfZg]mfZLB%;S9)nqloE,'ni!05^i!05^fEVBVfEVBVfEVBV!!!#U^B\"oK=9B-;=9B-;=9I7fo*&O'!s8XG!tbW;!sJZ)zzz!9sOa!!3-#zgV3ak\"*+Lb$/Ph-W\"/n2=9AU)!!!'#!!)Wk!!!!$!.queSH/gp\".]Gp=9G)p\"'>Yr!<ZF+N!6!e%epG;^(,5X!s8XG!s]'8WXB%:>F%&[\"'>X-q?UI68HW&s#Dt<YME1k9#[dmO\"'>X1#@!KM#HeGUc9`r^=9Ad5>H/&9#@!KM#Heqcl7W89#[dlX\"'>X1#@!KM#Kf;Qju7tp\"'>X1#@\"29#7\"J!1N`e%!seZGF1rq&q?UI6#7\"J5$XEj:!sAB*?jDqt\"'>X1#@!KM0`tM[#7\"J5$U\"So!sAB*?j?oA>H/'j!<ZF+,ldoFzzzzc2[hE%0-A.$31&+3!93]D?p4BD?p4BAdAA:BF\"S<BF\"S<C^:\"@C^:\"@C^:\"@D?p4BD?p4BD?p4BE!QFDE!QFDC'Xe>C'Xe>C'Xe>BF\"S<BF\"S<BF\"S<BF\"S<C'Xe>C'Xe>C'Xe>C^:\"@C^:\"@AdAA:AdAA:C^:\"@C^:\"@AdAA:AdAA:!!iS2^]Bi(\"'>X3\"'>ZoTE6'9!ui=dnfAlRF7pq\"+'[_=+4`5hnf@lT\"WNj1\"!@[p\"'>ZoTE6'9!ui=d4s*gHp*L_#>Q+XFeh_A2\"!7[cR/mC8\".9/l=9AX-EW]/@=9J#b!ZP;F)]r:]&g(.qRQh`5>Fn)%iY6I:$6('k\\cEo4'Q`7J+'*H?3u]8Gecd/H'm!CtiY6I:$6('kg&`AI1NU,.\"!7[c$`aD#dL$)G#?CL&&,m3m!U`=C!k/A9!s8X*#GD2$=9GB#\"'>ZoTE6'9!ui=dXp#p,'Q^Da+'*I2.iTR7JheG-'Q[:o+'[:u+4_0JXpQ9%1NV,')]r;84<IUFp*L_#>O!pbeh_Bu!s9VK)t*gO!t,&4Z71\\7+VOtP!W<$,i;s,<!<W];>F%<E\"'>[$!<ZF+n\"9_$=p#]c>F$!G<cds])]r:q4!3$0F1)DX*sESk$X92Nm/[=?!<Wl/#BS$ST`G6t\"/Q&$=9J#b!ZP;F)]r;,*?X8TF5dlUeh_C,'H8,ul8'O5'm&@K+'*IZ)]Kl'p*Lm4'm$Mb)]r;\\5p+Z6F6YO`*sEScc45<$\"`pRB>F$-!!<ZG^!t,>t\"%`Ss\"/uTc!Z%X6%0-A.!rr<$&c_n3z`!QJE.0'>J,QIfE?NgE0^^:&A^^:&A]F\"W=]F\"W=;ZHdt2uipY@g)i4`!QJEFT;CA7K<Dg?NgE0_?p8C_?p8CP5kR_=o\\O&?NgE0!!<5Y^B#&O=9B9?=9B9?=9B9?=9Gi9[fcnr$j-`A!s8XG!sS`*zzzz!)rpu!!3-#!!!*$jM(^9\"'>XG\"'>XG\"'>Z!#.\"_?OTum/=9Ad94p*)5=9AX1?NV#F=9AX5AcjUe=9AX-EWZ[Lzzz!!'A+z!!)Ee!!)Ee!!!'#!!!'#!!)Ee!!)Eez!8bHk'a%P?'a%P?'a%P?i=F<;\"IfZ3\"'>X-\"*+JIzzz!!!#;zz!!(lj!>P]=!u1o?!u1o?\"7HMS%h?AU'a%P?!s<QG\"TSN&zzz,QIfEz!!!#R^B\"E=EWar)Y6S4r\"9AU,!s/H&!!3-#z!!!3(\"S0;.2$6q_2$6q_2$6q_\"9(#_$P`bG!t3NZC't-<5;<fp\"'>XAO95gl.0EZS!u#)N0`tM[!s<QG!s`08#6P]L%0K]7bRUQ]-li]D$#0iB\"'>X-mL(`_$Nj$(XpP8Ec50ag=9C8[=9A[)0jkAX\"'>X?zzz!!!!*!!!!)!!!!h!!!\"\\!!!\"\\!!!\"Z!!!\"X!!!\"X!!!!#!!!\"X!!!\"X!!!\"P!!!#3!!!#3!!!#3!!!#3!!!#5!!!#5!!!#5!!!#3z!s0;BikGL3\"'>XC\"'>XC\"'>Z8#4E'A]FP5P<k9U[\"\"\"6X\"'./^!u3*o\"'>X-\"*+JMzzz!!!\"l!!!!1!WW33!WW31!WW31!WW31!WW3#!!(cg!<WFE\"0VdB%gM;$!<ZF+!WW3#!WW3#5QCca!!NB+l+[6:\"'>XC\"'>XC\"'>X-\"*+KRN<Tg)$9\\Jn!s>\\50aA'g<\\b$b'e'k\"=9Aqs*\\7Nu\"\"\"C)\"'>X5#<i5E\"'>X5#A]b42$6q_&-)\\1zzzci=%Gq>^KqaoDDAa8c2?aoDDAaoDDAaoDDAci=%Gci=%GbQ%VCbQ%VCbQ%VCbQ%VC!!!#R^B\"E=EWZQ(%R5RL!<ZF+!WW3#!WW3#\"onW'!!!#U^B#&O=9B9?=9B9?=9FWeLCI5J$5EYF!s8XG!sJZ)zzz!3uS)zzhS0('\"'>X;\"'>X;\"'>Zs$CqGUf`M<YEWZmU=9A^,zzz!!(RM!!!'#z!8G6h!s<QGRgGG`,jYm>\"'>X,!!!!#!!!!#z#QY^;^]=T@=9J#b!ZP;F)]r:Q3?R5pF05ih+'\\^F+4`5hXpQ*i>FGa<eh_CH!<XDI)nQ4X?NUP:!Yph!0`tM[n\"9_$=p#]c>Oj<eeeN8/$6('kl6[V(1NW+<\"!7[cjT,Hcb6LlH=9J#b!ZP;F)]r:=/g''eF05ileh_AJ+'*HW//o[8g&`AI1NS:'\"!7[cVZG*F)Zp0M:]lg]\"'>YV!<ZF+n\"9_$=p#]c>EUW]<ca-[)]r:M,p-0/ME;b!>E1ceiY6In'H8,u[M^1<1NSj.\"!7[c$O^:d+:F).>IG7S&&nY464_'mC(IuY\"'>ZA!<ZF+n\"9_$=p#]c>CnUP<cds]+6!uUXpQ*i>D<Y1eh_Bu!s9VK)]-9l$3O\"`!j;V,klClg\"7Mla)d3=_+'[;3+4_0JXpQ*i>ETO>eeN8c'H8,uXp#ou1NS]j\"!7[c\",8O<^BAre=PEkA!WuO,n\"9_$=p#]c>P^E'eh_BM$6('k[L+,-1NWCS\"!7[cZNC;M\"2>6D#Vb*G$ig8-!rr<$$31&+!<<*\"(B=F8'*&\"4Zi^:..0'>J*<6'>[K?L0BEnM;BEnM;5l^lb/-#YM[0$C/C^0q?C^0q?C^0q?@/p9-3<0$Z[fZU1FT;CA6i[2e[0$C/MZ<_W9E5%mZi^:.!!E<.j1bU0\"'>X?\"'>X?\"'>ZM&#]k!V$mG.EWZOK'E\\T;(hs:!\"'>X-#=JY+\"'>X?\"'>X0zzz!!!\"@z!!!!.!!!!+!!!!L!WW3#63$uc",0x005));if not not K[4917]then p=K[4917];else p=(-419430514+(w.i((w.f(K[0x4A9])),K[30915])+K[0X61a5]+K[0X797__1]));K[4917]=(p);end;continue;else if p~=0B110010 then else break;end;end;end;else l={};V=(w.o);if not K[0X70__C_B]then p=(-0X39e4E543+(w.v(X[4],K[11943])+X[0X3__]+K[9920]-X[9]));(K)[0X70__cb]=p;else p=(K[0X70cb]);end;end;end;until false;g=nil;p=(10);while true do if not(p>0XA and p<0b1100001)then if not(p>0X4c)then if p<0x4C then g=(function(i)P=i;Q=(U);end);if not not K[0xB10]then p=K[0XB10];else K[0X632f]=(102+w.U((w.n((K[31089]>=K[0X3Df2]and K[1193]or K[1524])-K[30915]))));(K)[14018]=-3451729549+((w.i(X[2],K[0X61bb])-K[0X4746__]~=K[0X6B1f]and K[4014]or X[0x1])~=K[24997]and X[0X008]or K[23514]);p=-550810461+w.U((X[0b101]>=K[0X6bde]and X[0X3]or X[4])-X[0X8]-K[4917],K[11943],K[24168]);(K)[0XB10]=p;end;end;else if not K[1849]then p=(3451699712+(w.E(K[0X1335]+K[0X61A5]-K[14018],K[30915])-X[0x8]));K[1849]=(p);else p=(K[0X739]);end;end;else break;end;end;local Z,M;p=0X5c;while true do if not(p<110 and p>0B1011)then if p>92 then break;elseif not(p<0x5c_)then else M=(E.unpack);if not K[0x69D3]then(K)[25878]=(-3553285037+(w.U((w.L(K[25391])))-K[31089]<X[0X5]and K[14018]or X[0X6]));(K)[0X597__d]=(-1658980615+(w.j(K[0X632f_])-K[14018]+X[5]-K[1524]));p=-1370244490+w.i(w.F(K[11943])+X[0b10]+K[1849],K[11943]);K[27091]=(p);else p=(K[27091]);end;end;else Z=(w.K);if not K[0X07_4_4]then p=(-0X64EC0AE__f+(((K[0X73_9]<p and K[27614]or X[0X1])~=X[0X1]and X[0X4]or K[1524])+K[0X0FaE]+K[4014]));(K)[0x744]=p;else p=K[1860];end;end;end;local h,q;p=(112);while true do if p<0B100010 then q=0X1;if not not K[0x28b__7]then p=K[10423];else p=-3845890241+w.i(w.n(K[4014])+K[0X70Cb]-X[0b10_],K[28875]);(K)[10423]=p;end;continue;elseif p>0X22 then if not K[0x4cb8]then p=(-0x3242C93c+w.L(w.j(K[4014],X[9])-K[0X5BdA]<=K[1193]and X[0X8__]or K[0X2ea7]));K[19640]=(p);else p=K[0x4cB8];end;else if not(p<0b1110000 and p>0Xf)then else break;end;end;end;local R,o,s;p=(0X47);repeat if p<0b11__11010_ then R={5,0b10,0X4};o=(function()local i,a=0X62;while true do if i==0X62 then i=0X59;a=C(P,Q,Q);else if i==89 then Q+=1;i=100;continue;else if i~=0X64 then else return a;end;end;end;end;end);if not K[0X6EaA]then p=0X40+w.U(w.F(K[27423],K[30915],K[0X004cB8])+K[19640]+K[0X70cb]);K[0X6eaA]=(p);else p=K[28330];end;else if p>0X4_7 then s=(function()local i,a,l=(0X55);repeat if not(i<0X55)then if i>0B11_0000 then a,l=M("<I4",P,Q);i=(0x30);Q=l;continue;end;else return a;end;until false;end);break;end;end;until false;local m,i9;x=(nil);local a9;p=(0X76);repeat if not(p>0X18)then x=function(...)return(...)[...];end;a9=(function()local i,a=0x1,0b0;repeat local l=C(P,Q,Q);a+=(l>0x7F and l-0X80 or l)*i;i=(i*0x80);Q=(Q+0X1);until(l<128);return a;end);break;else if p<=0X5d then i9=(function()local i,a=M('<\zd',P,Q);for l=32,0X42_,7 do if l~=32 then if l==39 then return i;end;else Q=(a);end;end;end);if not K[0X4f6C]then p=3819172108+(K[1860]-X[0X5]-X[0X7]+K[27091]+K[0X69d3]);K[0X4F6__c]=(p);else p=(K[20332]);end;else m=(function()local i,a=M('<\z  i\56',P,Q);Q=(a);return i;end);if not not K[0X4e01]then p=(K[0X4E01]);else p=0x3D+w.n((w.j(w.j(p,K[24997])<=K[0X2_eA7]and K[0X744]or X[0x9],K[1860],X[2])));(K)[0x4E01]=p;end;end;end;until false;local C,M,l9,U9,I9,z9=(function()local i,a=0X3c;while true do if i==0X3c then i=(0X6B);a=a9();else if not(a>=O)then else return a-Y;end;return a;end;end;end);p=14;repeat if p==0B111__0 then M=(function()local i,a=(0b0);while true do if i==0X0 then i=(0X5f);a=a9();continue;else if i~=0B101__1111 then else Q=(Q+a);return u(P,Q-a,Q-0B1);end;end;end;end);if not K[0X3Db]then p=(-0x3__+w.F((w.U(X[0X07]-X[0X5]<p and K[19969]or K[20332]))));(K)[0X03_Db]=(p);else p=(K[0X3Db]);end;else if p==0x15 then l9=j;if not not K[0x00677e_]then p=(K[26494]);else p=(-0x3bFf90+w.N((w.i(w.v(K[0X00__4cB__8],K[11943])+K[0X6516],K[19640])),K[25019]));K[0X677e]=p;end;continue;else if p~=0X70 then if p~=0xf then if p~=0X2_2 then if p==0x19 then I9=function(i,a)local l,U,I=i[0X1],i[5],(i[0X3]);local C;C=(function(...)local C=n(U);local U,j=U9(...);local H,T,A,x,e,g,D,M,c,v=0X1,{},0X1,0x1,0x0,{},(_()),(0B1);local E=({[0x24b2]=a,[0X565d__]=g,[18408]=i,[0X7e0C]=D,[0X24__1B]=l,[0X4cA9]=C});local i;local d,f,K,X=t(function()repeat local I=(l[M]);local l=(I[0X3]);M+=1;if not(l<59)then if not(l<88)then if l>=103 then if l<110 then if l<106 then if l<0X6__8 then C[I[0X5]]=(nil);else if l~=0X069 then(D)[I[0X6]]=I[0X1];else y[I[0x5]]=C[I[0x2]];end;end;else if l>=108 then if l==0X6D_ then(C)[I[2]]=not C[I[0X5]];else local i=(I[2]);for i in C do if not(i>A)then else(C)[i]=(nil);end;end;C[i]=C[i](B(C,A,i+1));A=i;for i in C do if i>A then(C)[i]=(nil);end;end;end;else if l~=0B1__101011 then local i,a=I[4],(C[I[0X05]]);(C)[i+0x1]=(a);C[i]=a[I[0X7__]];else(C)[I[0X4]]=C[I[0B10]]+I[6];end;end;end;else if l>=114 then if not(l>=116)then if l==0B11__10011 then(C[I[0X4]])[I[0X7]]=I[0X6];else repeat for i,a in g do if i>=0X1 then(a)[0X2]={C[i]};a[0x1]=0B1;(g)[i]=nil;end;end;until true;return;end;else if l==117 then local i=(a[I[0X5]]);(C)[I[0x4]]=i[0X2][i[0X1]][C[I[0X2]]];else local i=(a[I[0X2]]);(i[2][i[0x1]])[C[I[0x5]]]=(C[I[0b1_00]]);end;end;else if not(l<0x70)then if l==113 then(C)[I[0X2]]=I[0X1]-I[6];else C[I[0b101]]=(I[7]..C[I[4]]);end;else if l~=0X6f then(C)[I[0x4]]=(C[I[0B10]]~=I[0B110__]);else local i=(a[I[0b10_1]]);i[2][i[1]]=C[I[0X4]];end;end;end;end;else if not(l>=0X5f)then if l>=0X5B then if not(l<93)then if l~=0X5e then C[I[0X5]]=(C[I[0b1__00]][C[I[0B10]]]);else(C)[I[0B100]]=(I[0B111]==I[0X6]);end;else if l~=92 then(C)[I[0X2]]=C[I[0B100]][I[6]];else(C)[I[0x4]]=C[I[0X5]]-C[I[0X2]];end;end;else if l>=89 then if l==0X5a then(C)[I[0X2]]=(E[I[4]]);else if C[I[5]]==C[I[0X2]]then else M=(I[0X4]);end;end;else M=I[4];end;end;else if l<0X63 then if not(l>=97)then if l~=0x0060 then for i=1,I[0X2]do C[i]=j[i];end;else(C)[I[0b101]]=(D[I[0B111]]);end;else if l==0X62 then C[I[4]]=(I[0X7]-C[I[0B101]]);else local i=I[0x5];A=i+I[0x2]-0X1;for i in C do if i>A then C[i]=nil;end;end;(C[i])(B(C,A,i+1));A=(i-0b1);for i in C do if not(i>A)then else(C)[i]=nil;end;end;end;end;else if l<0X65 then if l==0b001100100 then local i=I[0X2];A=i+I[0X4]-0X1;for i in C do if i>A then(C)[i]=(nil);end;end;C[i]=C[i](B(C,A,i+0X1));A=(i);for i in C do if not(i>A)then else C[i]=(nil);end;end;else(C)[I[0x05]]=(I[1]>C[I[2]]);end;else if l~=0x66 then C[I[4]]=(I[6]<C[I[0X2]]);else A=(I[2]);for i in C do if not(i>A)then else(C)[i]=(nil);end;end;C[A]();A-=0X1;for i in C do if not(i>A)then else C[i]=(nil);end;end;end;end;end;end;end;else if not(l<0X49)then if not(l<0X50)then if not(l<0X54)then if l>=0B1010110 then if l~=87 then local i=(a[I[0X2]]);(C)[I[0B100]]=i[0X2_][i[0B1]][I[0X6]];else if C[I[4]]then M=I[0X5];end;end;else if l~=0X55 then repeat for i,a in g do if not(i>=0x1)then else(a)[0X2]={C[i]};(a)[0X1__]=(1);g[i]=nil;end;end;until true;return true,I[0B100],0x0;else(C)[I[0x5]]={};end;end;else if l<0B1010010 then if l==0B1010001__ then(C)[I[0x5]]=C[I[0x4]]>=C[I[0x2]];else repeat local i=I[0X2];for a,l in g do if not(a>=i)then else l[2]=({C[a]});l[0X001]=0b1;g[a]=(nil);end;end;until true;end;else if l~=83 then(C)[I[2]]=(C[I[0B101]]/I[0B1]);else local i=(I[0x5]);A=(i+0X2);for i in C do if not(i>A)then else(C)[i]=(nil);end;end;(C)[i]=C[i](C[i+0X1],C[i+0B10]);A=i;for i in C do if i>A then(C)[i]=(nil);end;end;end;end;end;else if l<0b1001100 then if l>=0X4A then if l~=75 then C[I[0X4]]=C[I[0x5]]<C[I[0b10__]];else local i=I[4];A=i+0b1_0;for i in C do if i>A then C[i]=nil;end;end;(C[i])(C[i+0X1],C[i+0X2]);A=(i-1);for i in C do if i>A then C[i]=nil;end;end;end;else C[I[0X005]]=(C[I[0X2]]~=C[I[0B100]]);end;else if l<0X4E then if l==0X4_D then(C)[I[0x4]]=C[I[2]]<=I[0b110];else if not not(I[0X1]<C[I[0B10]])then else M=(I[5]);end;end;else if l==0X4F then(C)[I[0X5]]=I[0X7]>=I[0X1];else local i=(a[I[0X5]]);(i[2][i[0b1]])[I[0x07]]=C[I[4]];end;end;end;end;else if l>=0x42 then if not(l>=0B1000101)then if l>=67 then if l==0B1000100 then local i=I[2];A=(i+0X1);for i in C do if not(i>A)then else C[i]=(nil);end;end;C[i](C[i+0X1]);A=i-0x1;for i in C do if i>A then C[i]=(nil);end;end;else C[I[0B100]]=#C[I[2]];end;else D[I[0B110]]=C[I[0X4]];end;else if l<0B1000_111 then if l==0X046 then C[I[0X004]]=y[I[0x5]];else C[I[0b101]]=C[I[0B1__0__]]..C[I[0X004__]];end;else if l~=0X48__ then C[I[0b10]][C[I[4]]]=C[I[0X5]];else if not(C[I[5]]<=C[I[0x04]])then M=(I[2]);end;end;end;end;else if not(l<0B111110)then if l<0x40 then if l==63 then(C)[I[0x4]]=I[0x07]~=C[I[0x5]];else(C)[I[0B10]]=C[I[0X4]];end;else if l==0X41 then C[I[0x5]]=(C[I[0X4]]>C[I[0X2]]);else C[I[5]]=(F(C[I[0B100]],C[I[0B10]]));end;end;else if l>=60 then if l~=0B111101 then C[I[5]]=j[H];else local i,a,l=I[0X2],I[0x4],(I[0X05_]);if a==0X0_ then else A=i+a-0b001;for i in C do if not(i>A)then else(C)[i]=nil;end;end;end;local U,I;if a==1 then U,I=U9(C[i]());else U,I=U9(C[i](B(C,A,i+0X1__)));end;if l==1 then A=i-0b001;else if l==0x0 then U=U+i-0B1;A=U;else U=i+l-2;A=U+0X1;end;a=(0x0);for i=i,U do a+=1;C[i]=I[a];end;end;for i in C do if i>A then(C)[i]=(nil);end;end;end;else(T)[x]={[0X4]=i,[0x3]=c,[1]=v};x+=0X1;A=(I[0X2]);local a=G(function(...)(r)();for i,a in...do(r)(true,i,a);end;end);a(C[A],C[A+0b1],C[A+0B10]);for i in C do if i>A then C[i]=(nil);end;end;i=(a);M=I[0B100];end;end;end;end;end;else if not(l<29)then if l>=44 then if not(l<51)then if l<55 then if not(l<0X35)then if l~=54 then e=(I[0x2]);for i=0B1,e do C[i]=j[i];end;H=e+0B1;else C[I[0X02]]=(C[I[0b101]]>I[1]);end;else if l~=0X34 then C[I[4]]=(C[I[0x5]]+C[I[0x2]]);else repeat for i,a in g do if i>=0X1 then(a)[0x2]=({C[i]});(a)[0X1]=(0B1);(g)[i]=nil;end;end;until true;return true,I[2],0B1;end;end;else if l>=0X3_9 then if l==58 then C[I[0X5__]]=(I[1]<I[0B11__1]);else(C)[I[5]]=C[I[0B10__0]]-I[7];end;else if l~=0X38 then local i=I[0X5];A=i+0x1;for i in C do if not(i>A)then else(C)[i]=nil;end;end;C[i]=C[i](C[i+0B1]);A=i;for i in C do if not(i>A)then else(C)[i]=nil;end;end;else if C[I[4]]~=C[I[0B101__]]then else M=(I[0x2]);end;end;end;end;else if not(l>=0X2F)then if l<45 then(C)[I[0x4]]=C[I[0X5__]]..I[0X7__];else if l~=46 then(C)[I[0X4__]]=C[I[0B10]]^C[I[0B101__]];else(C[I[4]])[C[I[0X002]]]=(I[0B1_10]);end;end;else if not(l<49)then if l==0X32 then C[I[0X4]]=C[I[5]]==I[0X7];else C[I[0B1__01]]=I[0X7__];end;else if l~=0B110000 then C[I[0X2]]=(I[6]>I[0X1]);else local i,a=I[0X5],(I[0x2]);A=i+a-0X1;for i in C do if i>A then(C)[i]=nil;end;end;repeat for i,a in g do if i>=0B1 then(a)[0X2]={C[i]};(a)[0b1_]=(0B1);(g)[i]=nil;end;end;until true;return true,i,a;end;end;end;end;else if l<0X24 then if l<0b0100000 then if l>=0b11110 then if l==0X1F then if C[I[0B10]]<=C[I[0B101]]then M=(I[0B1__00]);end;else C[I[0X5]]=I[0B111]+C[I[0X4]];end;else local i,a,U,z,B,G,r,j=y[16297],0B0_1__1__00000;while true do if not(a>0X12)then B=48;break;else if a==0X3f then r=3;a=-4294967219+w.L((a+a<=a and l or l)+l);continue;else U=(I);a=(0x26+((w.F(l)~=I[0b1_01]and a or I[0X5])+a<=I[0b10]and I[0X4]or I[0b100_]));continue;end;end;end;local J=(y[0X3f__a9]);i=(i.countrz);a=0x79;local Z=(0X4);while true do if a==121 then J=J.countrz;a=-2147483741+(w.i(a-I[0X5],I[2])-I[0X4]+a);elseif a==0B100 then j=y[0x3FA9];j=(j.bor);a=0xF+w.j(w.U(a-I[0B101],a)==a and I[0B100_]or a);elseif a~=0B10011 then else G=(I);break;end;end;G=(G[Z]);a=88;while true do if a==88 then Z=(I);a=0b11011110+(w.n(a)-a-I[0X4]-I[0X4]);continue;elseif a==0x57 then z=(0B101);a=(0X4a+((w.i(I[5]+l,I[0X4])<l and a or a)-a));continue;elseif a==0b100__1010_ then Z=(Z[z]);a=-0x73+(((w.f(a)==l and a or I[0X5])<=I[0X2]and a or I[0X2__])+a);elseif a==0B10000__1 then G=(G>=Z);if G then local i,a;for l=56,0b10100100_,0x5D do if l>56 then G=i[a];break;elseif l<0x95_ then i=(I);a=(4);end;end;end;a=(0B1100+w.f((w.L(w.v(I[0B101],l)<I[0X5]and l or I[0b10]))));elseif a==0B110__0 then if not G then local i,a,l=0X2d;while true do if i<45 then l=(0X2);G=(a[l]);break;elseif i>0B101000 then a=I;i=(0x28);end;end;end;a=(0X7c+((w.i((w.j(I[0X2])),I[0B10_1])>=a and I[0b10_0]or I[0x02__])-I[2]));elseif a==123 then Z=(I);a=(153+(w.n(w.L(l)+I[0B1__00])-a));elseif a~=30 then else z=5;break;end;end;Z=Z[z];a=0B1001010;while true do if a~=0X4a then if not G then else z=(0X3);G=(I[z]);end;break;else G=(G>=Z);a=(-2483027935+(w.i(I[0x2]<=a and a or I[0X2],I[0X5])-a+a));end;end;if not G then z=nil;local i;for a=100,0x11c,0X26 do if not(a>100)then z=(I);continue;else if a<0B10110000 then i=(0X2);continue;else G=z[i];break;end;end;end;end;a=0X6A;while true do if a==0x6A then Z=l;G+=Z;a=-0b101_001+(w.f((w.U(I[0X2]-a,a,a)))>I[0X2]and a or a);continue;elseif a==65 then Z=l;a=(0x13+(w.N((w.n(a+a)),I[2])<=a and a or I[0X5]));continue;elseif a==0X2c then j=j(G,Z);a=(0X001C+(((w.L(a)<=l and I[0X5]or I[0X4])>l and I[0X5]or I[0X5])-I[0B10]));continue;elseif a==0x1B then J=J(j);a=(0b11110+w.f((w.j((w.N(a~=I[0X4]and I[0B100]or I[0X2],I[2])),I[0X5]))));continue;elseif a==0B11_1110 then j=I;break;end;end;a=102;while true do if a<0X66 then j=j[G];break;else G=(0X2);a=(-191+(w.E((w.i((w.F(a,a,a)),I[4])),I[0X4])+a));continue;end;end;J+=j;a=0x8;while true do if a==0x8 then i=i(J);a=-4294967157+w.L(w.E(a,l)+l-I[0X2]);elseif a==0X47 then J=(I);break;end;end;j=0x3__;a=111;while true do if a>0x4 and a<0b1111001 then J=(J[j]);a=(-3221225365+(w.i(w.j(l,I[0X5])+l,l)-a));elseif a<0B1101111 and a>2 then B+=i;break;elseif a>0b1101111 then if i then i=l;end;if not i then z=0B111_0101;Z=(nil);while true do if z==117 then z=0B0010__10000;Z=(0x2);continue;else i=I[Z];break;end;end;end;a=-67108860+w.i(I[0B10_]+a-a-I[0b101],I[0b10]);continue;elseif not(a<4)then else i=i>=J;a=(-4294967149+w.L(w.U(I[5]-a)+a));continue;end;end;a=(0B1101);while true do if not(a>0XD)then if not(a>=0xD)then r=I;a=71+(w.v((w.U(a,a,a)),a)+a-a);else U[r]=B;U=(C);a=-31+(a+a+a-I[0B100]+I[0b101]);continue;end;else if not(a<=0X47)then r=r[B];break;else B=0X4;a=(0B1011010_+w.f((w.L(a)<=a and a or l)-l));end;end;end;a=(0X0__0B);while true do if a==0B001011 then B=(C);a=(0B11_00010+w.F(w.L(I[0B100])-I[0x5]~=a and l or I[2],a,I[0b10]));elseif a==0X6E then i=(I);a=-3690987512+(w.U(w.N(a,I[0B100])-l,I[0X2],a)+a);continue;elseif a~=117 then else J=0B0101;break;end;end;i=(i[J]);a=0x19;while true do if a>25 and a<0X33 then J=(I);a=-4294967208+(w.L((w.F((w.v(a,I[4])))))-a);continue;elseif a<36 then B=(B[i]);i=(C);a=0B10_0001+(w.f((w.i((w.F(I[0B101],a)),a)))-l);continue;else if a>0B100100 then j=0B10;break;end;end;end;J=(J[j]);a=0X24;while true do if a<0b110011 then i=(i[J]);B=(B<i);a=(26+(w.i((w.E(a<a and I[0b10]or l,l)),I[5])<I[0X4]and I[0X4]or I[4]));elseif not(a>0X24_)then else(U)[r]=(B);break;end;end;end;else if not(l>=0b100010_)then if l~=33 then repeat for i,a in g do if i>=0B1 then a[0X2]=({C[i]});(a)[0x1]=0x1;g[i]=(nil);end;end;until true;return false,I[0B101],A;else(C[I[0X2]])[I[0X1]]=C[I[5]];end;else if l==0X0023 then if not not(I[6]<=C[I[0x4]])then else M=I[2];end;else(C)[I[4]]=C[I[2]]>=I[6];end;end;end;else if not(l<0B10_1000)then if not(l<42)then if l==0b101011 then local a=I[0X2];local l=(x-a);a=(T[l]);for i=l,x do(T)[i]=(nil);end;i=a[0X4];v=(a[1]);c=a[0X3];x=(l);else(T)[x]=({[0X4]=i,[0X3]=c,[1]=v});x=(x+0X1);local a=I[0B10];c=C[a+0b10]+0X0;v=(C[a+0X1]+0x0);i=C[a]-c;M=(I[0b100]);end;else if l~=41 then local i,a=I[0X5],(I[0b10]*0X64);local l=(C[i]);V(C,i+0B1,A,a+1,l);else local i=I[5];for i in C do if i>A then(C)[i]=(nil);end;end;C[i](B(C,A,i+1));A=(i-0x01);for i in C do if i>A then C[i]=nil;end;end;end;end;else if not(l<38)then if l==0x27 then local i,a,U,z,B,G,r=y[16297],y[16297],(0x24_);while true do if U~=0x24 then B=0X12;break;else z=(I);r=0b1__1;U=(-40894377+(w.E(l-l>=U and l or l,0Xc)-U));end;end;i=(i.rshift);local j,J;U=(0X7C);local Z=I;while true do if not(U>0b001010__1_ and U<0X007c)then if not(U>0X2B)then if U<0X15 then G=G.band;U=-4285530090+w.E(w.n(U+U)-l,U);elseif not(U>0XE and U<0X02b_)then else j=(l);break;end;else a=(a.countrz);U=-84+w.U((w.j(l+U-l,U)),U,l);continue;end;else G=y[0x3FA9];U=-0B11_001+(w.N((w.v((w.F(l,U,U)),0B11111)),6)+l);end;end;U=116;while true do if U>0B1000011 then J=0X03;U=(-0B110001+((U+U==U and l or U)-l<=l and l or U));elseif U<116 then Z=Z[J];break;end;end;G=G(j,Z);U=(0X4a);while true do if U==0X4A_ then j=(l);U=0x4__4+(w.i((w.n(l)),8)-U+l);else if U==0X21 then G=(G-j);break;end;end;end;j=I;U=0X2d;while true do if not(U>0B1010_00)then if not(U<40)then j=j[Z];U=(0X3f+(w.j(l-l)+l<U and U or l));continue;else a=a(G);U=(0Xa+(w.i(U+l,U)-U==U and U or l));end;else if not(U>0X2d)then Z=(0X3);U=(-50+(w.U((w.j(l+U,U)),U)+U));continue;else if U<0X67 then G=I;break;else G-=j;U=1+w.f(w.E(U-l,6)==U and U or U);end;end;end;end;U=(101);while true do if not(U>0X0)then if not(U<0B11__00101)then else G=(G[j]);break;end;else j=(3);U=-116+w.F((w.n((w.i((w.j(U,U)),0X11)))),U);continue;end;end;a=(a+G);G=l;a+=G;U=(0X7d);while true do if U>56 then G=(0X1B);U=-0X45+w.U(l+U+l~=U and U or U);elseif U<0X7__d then i=i(a,G);break;end;end;a=(I);U=0X3E;while true do if U<0X20 then a=(a[G]);U=(0X20+w.i((w.n(l+l>U and l or l)),U));continue;elseif U>0X3E then if i then i=l;end;break;elseif not(U>0X5 and U<0X3E)then if U<0X52 and U>0X20 then G=(0X3);U=-0X69+(w.f((w.F(l,l)))+l+l);continue;end;else i=i>a;U=0x2B+(((U-l<l and U or U)~=U and l or U)>l and l or l);end;end;U=(0B10);while true do if not(U>2)then if not(U<0X79)then else if not not i then else Z=(nil);G=30;J=(nil);while true do if G==30 then G=(101);J=I;continue;elseif G==0X65 then Z=0X3;break;end;end;i=(J[Z]);end;B+=i;z[r]=B;U=(0X44+(w.U(w.v(l,U)+l,U,l)-U));continue;end;else z=C;break;end;end;r=(I);U=(0X6a);while true do if U<106 then r=(r[B]);break;elseif not(U>0X4_1)then else B=(5);U=-0b1_0011110+(w.F(l)+l+U+l);end;end;B=C;i=(I);U=(0B0);while true do if not(U>0)then a=(0X4);i=i[a];U=0B100001_10+(((U~=U and U or U)>=U and U or U)-l-U);continue;else B=B[i];break;end;end;i=I;a=(7);i=i[a];U=0X4b;while true do if U==0X2e then(z)[r]=B;break;else B=(B-i);U=-1073741778+w.F((w.N(w.v(l,0b111)-l,30)));continue;end;end;else repeat for i,a in g do if not(i>=0B1)then else a[0X2]=({C[i]});(a)[0B1]=0X1;g[i]=(nil);end;end;until true;local i=(I[0X5]);return false,i,i;end;else if l==37 then(C)[I[0X2]]=(C[I[0X5]]%C[I[0X4__]]);else local a=(false);i=(i+c);if not(c<=0X0)then a=(i<=v);else a=i>=v;end;if not a then else M=I[0X5];C[I[0X2]+0X3_]=i;end;end;end;end;end;end;else if not(l>=0B1110)then if not(l<0x07)then if l>=0XA then if not(l>=0XC)then if l~=0xb then local i=I[7];local l=i[0X2__];local U,z=(#l);if not(U>0)then else z={};for i=1,U do local U=l[i];local l=U[0X2];local I=(U[0X1]);if l==0X0 then U=g[I];if not not U then else U=({[0X1]=I,[0x2_]=C});(g)[I]=U;end;(z)[i-1]=U;else z[i-0b1]=(a[I]);end;end;end;l=I9(i,z);(L)(l,D);C[I[0X4]]=l;else(C)[I[0X4]]=(C[I[0B101]]<I[0X7]);end;else if l==0X0D then(C)[I[4]]=-C[I[5]];else C[I[2]]=(I[6]==C[I[0X4]]);end;end;else if l>=0x8 then if l==0B100__1 then C[I[5]]=C[I[0B100]]*C[I[0B0010_]];else if C[I[2]]==I[0x1__]then else M=(I[0X5]);end;end;else local i,a,U,z,B,G,r=0,y[0X3__Fa9];while true do if i>0B0 then if not(i<0X5F)then U=0x3;i=(0X5d+(w.f(I[0X4]<I[4]and i or I[0x4])+I[0B00100]-i));else B=-0X16;break;end;else G=I;i=(0b1011__1_11+((w.v((w.f(I[0x4])),i)<l and I[0X4_]or i)==l and I[0B100]or i));continue;end;end;local j,J,Z;i=84;while true do if i<0X54 and i>0b100011 then j=j.bor;z=y[0X3FA9];break;elseif not(i<0X26)then if i>0b100110 then a=a.bxor;i=(0B10__11+w.f((w.j(i+i+i))));continue;end;else j=y[0X3fA9];i=(0Xd+(w.n(i-I[0X005]-i)+I[5]));continue;end;end;i=0X035;while true do if i==0x35 then z=z.bor;i=(-2483027952+w.N((w.L(w.E(i,l)>I[0x4]and i or i)),I[0B100__]));elseif i==0B10000 then Z=y[0X3fA9];i=-0xe+w.F(w.n((w.i(i,I[0B10__1])))+i,i);elseif i==47 then Z=(Z.countlz);J=(I);r=0X5;i=(0B10011+(w.F(i-i+i)>=l and i or i));elseif i==0B100__0010 then J=(J[r]);break;end;end;local H=(0x3);r=(I);i=(0B1011100);while true do if i<110 and i>0Xb then r=r[H];i=(103+(w.v((w.F((w.n(l)),I[5],I[0X5])),I[0X4])-i));elseif i>92 then r=I;break;elseif i<0B1011__100 then J=(J-r);i=(0B1100011+(w.n(I[5]+i-I[0B100])<=i and i or i));end;end;H=5;i=0X7__C;while true do if i<0x15 then r=r[H];J+=r;i=(21+(w.U(i-i>=I[0x5]and i or i,i)-i));continue;elseif not(i<0X7c and i>0X2B)then if i>0XE and i<43 then Z=Z(J);i=(-704642960+w.F((w.i(w.U(i)<i and l or i,I[0x4]))));elseif i>0X70 then r=(r[H]);J+=r;i=-0X31FfFfbC+(w.i((w.U((w.f(i)))),I[0X4])-I[0x4]);else if not(i<0X0070 and i>0B1__0101)then else r=I;H=(0X5_);i=(-838860786+w.i(w.v(i-I[0B100__],I[0x4])+I[4],I[0b100]));continue;end;end;else z=z(Z);break;end;end;i=(3);while true do if i==0B11 then Z=l;i=(-0X11+(w.f((w.N(I[0X5]-i,l)))+i));elseif i==0x6__ then J=I;r=5;i=0B10011+(I[0X5]-i-I[4]+l+I[5]);elseif i==0B101101 then J=(J[r]);break;end;end;i=(0x6c);while true do if i==0B110110__0 then j=j(z,Z,J);i=(-0Xb+(w.n((w.n(i)))+i-l));elseif i==0X5B then z=(I);break;end;end;Z=(3);i=(90);while true do if i==0X5A then z=z[Z];i=0X69+w.n((w.N((w.L(i<I[0x004]and i or I[0x4])),l)));elseif i==113 then j+=z;i=(0x3+(w.U(I[4]+i,I[0X5],I[0X005])+i<i and i or I[0X5]));continue;elseif i==0B1__1100 then z=(I);break;end;end;i=(6);while true do if i<=6 then Z=(0X3);i=0b101__00+(w.f(l+I[5])+I[0X5]~=i and I[0B100]or i);continue;else if not(i<0X2d__)then z=z[Z];i=(-0x17fFFFd8+w.N(w.L(i)-i-I[0x5],I[0X4]));continue;else a=a(j,z);break;end;end;end;i=(0X3_D);while true do if i~=61 then if i~=0B1111000 then else G[U]=(B);break;end;else B+=a;i=(34+((w.E((w.N(i,l)),I[0X4])>i and i or I[0X5])+I[0X4]));end;end;G=C;i=(86);while true do if i<=0B111101 then B=0B100;i=(0X71_+(I[0x5]+I[0B100__]-I[0X5]+i<i and i or l));else if not(i>=0B1111000__)then U=I;i=-0X79ffFF_D1+(w.i(i-I[0b100],I[4])+l+l);continue;else U=U[B];break;end;end;end;i=0B1101001;while true do if i>52 then B=(C);i=(27+w.f(w.N((w.n(I[0x04])),I[0X5])>=I[0X4__]and I[0b10_1]or i));continue;elseif i<0B11010__0 then j=0X5;break;elseif not(i>3 and i<0x69__)then else a=I;i=-0X31+(w.f((w.n(i)))+i<i and i or i);end;end;a=a[j];B=(B[a]);a=I;j=(7);i=0X25;while true do if not(i>0b11111)then G[U]=B;break;else if i>37 then B=(B<a);i=(0X6+(w.j((w.i((w.N(i,I[5])),I[0B1__00])),i)>i and i or I[0X4]));else a=(a[j]);i=62+(w.F((w.f(l==I[0b100_]and I[0B101]or I[0X5])))-I[0B101]);continue;end;end;end;end;end;else if not(l<0X3)then if not(l<0X5)then if l==0X6 then(C)[I[0X2]]=C[I[0X4]]%I[0B110_];else for i=I[0B101],I[0B10]do(C)[i]=nil;end;end;else if l~=0x4 then local i=I[5];local a=(C[i]);local l=I[0B100]*0B11001__00;V(C,i+1,i+I[2],l+0X1,a);else if C[I[0X5]]==I[1]then M=(I[0B10]);end;end;end;else if l>=0B1 then if l~=0b10 then A=(I[5]);for i in C do if i>A then C[i]=(nil);end;end;(C)[A]=C[A]();for i in C do if not(i>A)then else C[i]=(nil);end;end;else C[I[0B10]]=n(I[0X4]);end;else local i,a,U,z,B,G=0X71_;while true do if i==0B0111000__1 then a=I;U=(0x3);i=0B11011_01+(w.U((w.n(I[0X2]-l)),I[0B100],l)-i);else if i==0b11100 then z=103;B=y[16297];i=63+w.E(w.N((w.N(i,i)),l)+I[0X2],i);continue;elseif i~=75 then else B=(B.lshift);break;end;end;end;local r,j,J=y[0X3__FA9];i=0B1_011000;while true do if i<0b10__10111 then j=j.countrz;G=(l);break;elseif i>0B10_10__111 then r=r.lrotate;i=-0X1+((I[4]~=i and i or I[0X4])+i-l~=i and i or I[0X2]);else if i>0X4a and i<88 then j=(y[0X3fA9]);i=-132+(w.F((w.n(i>l and I[0X2__]or I[4])),i)+i);continue;end;end;end;local Z=I;i=126;while true do if i<0B1000101 then j=j(G);break;elseif not(i>0b1100000)then if i<0B1111110 and i>0B1000101 then G-=Z;i=(-33+((w.n(I[0X2])-i~=I[0b10]and i or l)~=l and i or i));continue;elseif i>63 and i<0B1100000 then Z=(Z[J]);i=0x1b+(w.v((w.E(i+l,I[0x2])),l)-I[0X2]);continue;end;else J=0B10;i=(-0B111001+w.v(w.U(I[4]+i,i)-I[0x4],I[0X2]));continue;end;end;i=0x78;while true do if i>0B1110111 then G=l;j+=G;i=(-0X79+(w.U(i-I[0X2_])+i+l));continue;else G=(l);break;end;end;j=(j+G);G=(l);i=(52);while true do if i==0B110100 then r=r(j,G);i=0B110111+(I[0X4]+I[4]-l-i-I[0x2]);elseif i==3 then j=I;break;end;end;G=2;i=0X14;while true do if i<0B10100 then G=(0x3);break;else if not(i>99)then if i<0x63 and i>0Xd then j=(j[G]);i=(0X4f+((w.f((w.L(i)))<I[0B100]and I[0b100]or i)-I[2]));continue;elseif not(i>0X14 and i<0b1100110)then else r-=j;i=0x6_6+(l-I[4]+I[4]-I[0X4]-l);continue;end;else j=(I);i=(0X73+(w.f(I[0B100]-i-I[0X2])-i));end;end;end;i=0B1100011;while true do if i>13 and i<102 then j=(j[G]);r=(r<=j);i=0X66+((w.E((w.U(I[2],i,I[0X4])),l)~=i and i or I[0x4])+I[0X4]);continue;elseif i<0x63 then if not r then J=(nil);Z=nil;for i=0X4B,0xC4,83 do if i>0X4B then Z=(0b11);r=J[Z];break;elseif i<0X9_E then J=I;end;end;end;break;elseif not(i>0X063)then else if r then local i,a;for l=11,248,116 do if l~=0B1011 then if l~=0X7F then else a=2;r=i[a];break;end;else i=(I);continue;end;end;end;i=0XD+w.j(l+i-i>=l and I[0X4]or I[4],i,I[4]);end;end;j=(I);i=(0B1110000);while true do if not(i<0X70 and i>0XF)then if not(i<34)then if i>34 then G=0b10;i=(0B1_111+(w.v(I[0x4]-I[2],l)+i-i));end;else j=(j[G]);i=34+(w.E(i-i+l,l)+l);continue;end;else B=B(r,j);break;end;end;z+=B;i=23;while true do if i~=0x17 then if i==0XA then U=(I);i=(-4294967189+w.U(w.i((w.v(I[0X4],i)),i)-i));elseif i==0B1100001 then z=(0B1_01);i=(-0x76+(w.N((i>=l and i or i)+I[0X2],I[0b100])+i));continue;elseif i~=0X4c__ then else U=U[z];break;end;else a[U]=z;a=(C);i=(0XA+w.n(w.F((w.N(i,i)),i,I[0B100])+I[0B1__00]));continue;end;end;i=(0X39);while true do if i==57 then z=(nil);i=(42+(w.f(i+i-i)-I[0x4]));elseif i~=0B10__00100 then else a[U]=(z);break;end;end;end;end;end;else if l<21 then if not(l>=0x11)then if not(l>=0XF)then C[I[2]]=(I[0X6]+I[0b1]);else if l~=16 then C[I[4]]=(C[I[0X2]]<=C[I[0B101]]);else repeat for i,a in g do if not(i>=0X1)then else(a)[0X2]=({C[i]});(a)[1]=0X1;(g)[i]=nil;end;end;until true;local i=I[4];return false,i,i+I[0x2]-0X2;end;end;else if l>=0B010011 then if l~=0x14 then(C)[I[4]]=C[I[0X2]]/C[I[0B1_01]];else local i=(a[I[0B101]]);C[I[0X4]]=(i[2][i[1]]);end;else if l==0X12 then C[I[0X5]]=(I[0X1]^C[I[0B10]]);else C[I[5]]=I[0X7]<=I[0B1__];end;end;end;else if l>=25 then if not(l<0B11011)then if l==0X1C then local a=(I[2]);local l,U,z=i();if not l then else(C)[a+0X1]=U;C[a+0X2]=(z);M=I[0B101];end;else local i,a,l=U-e-0X1,0X0,I[0X5];if not(i<0x0__)then else i=-0B1;end;for i=l,l+i do(C)[i]=(j[H+a]);a+=0b1;end;A=l+i;for i in C do if i>A then C[i]=nil;end;end;end;else if l~=0b11010 then if not(C[I[2]]<I[0X1])then M=(I[0X5]);end;else(C)[I[4]]=I[0x7]~=I[6];end;end;else if l>=0x17 then if l==24 then else(C)[I[0B101]]=(C[I[0X4]]*I[0B00111]);end;else if l~=0x16 then if not not C[I[0B100]]then else M=(I[0X5]);end;else if not(C[I[0x5]]<C[I[0X4]])then M=(I[0X2]);end;end;end;end;end;end;end;end;until false;end);if not d then repeat for i,a in g do if i>=0X1 then a[0x2]={C[i]};(a)[0x1]=0B1;g[i]=(nil);end;end;until true;if z(f)~="st\z ring"then J(f,0X0);else if not Z(f,":(%d\43)\[\z \58\r\x0A]")then J(f,0);else J('\u{4C}\117r\97ph\32\83c\114\zi\z\112\x74:'..(I[M-1]or'\z(\u{069}\110t\101\x72na\108\)')..":\ "..W(f),0B000);end;end;else if f then if X~=1 then return C[K](B(C,A,K+0X1));else return C[K]();end;else if K then return B(C,X,K);end;end;end;end);return C;end;if not K[0x6DC9]then(K)[7316]=(-0X1F1dcdBb+(w.n(K[0X7971]-K[0x2392])+X[0X6]-X[0X9]));K[24291]=(-0X00__31+(((w.L(K[0X69d3])~=K[24168]and X[7]or K[0X1__335])~=K[0X6516]and K[26494]or K[10423])+K[28875]));p=(-0X6__2e208dd+((X[3]>=X[7]and X[0X5]or K[28330])-K[0X6eAA]+K[0X241c]+K[1860]));(K)[28105]=p;else p=(K[0X6DC9]);end;continue;else if p==0x24 then z9=(nil);break;end;end;else y[0X3335]=S;if not not K[0X2392]then p=(K[9106]);else p=(0B101110+(w.v((w.U(K[31089]<K[0x24__1c]and K[0X1f3f]or K[1193],K[17248])),K[19640])-K[0x3dB]));(K)[0x2392]=(p);end;end;else if not K[7999]then p=(-0X55+(K[0X4f6c]+K[0X4e01]-K[30915]+K[0X68__c5]==X[0x2]and K[24168]or K[27614]));(K)[7999]=p;else p=K[7999];end;continue;end;else U9=(function(...)return I('#',...),{...};end);if not K[26821]then(K)[17248]=-3031238034+w.F(w.E(K[0x78C3]~=X[0X5]and K[0x61Bb]or K[0x6bDE],K[28875])+X[0x9__]);p=(-4294836209+w.N(w.j(K[0X241C]-K[0x3D_b])-K[0X739],K[0X0__0744]));(K)[0x68C5]=(p);else p=(K[0X68c5]);end;end;end;end;until false;v=(nil);l=nil;p=(86);repeat if p<0X56 then v=(nil);if not K[0X6_10D]then p=-0B10110110+(w.U(K[24997]+K[0x6bdE]-K[0X28b7],K[0X70cB])+K[0X1c94]);K[24845]=p;else p=K[24845];end;elseif p>86 and p<0x78 then l=(function(...)return(...)();end);break;else if not(p>0X77)then if p<0b1110111 and p>0b111101 then z9=function()local l,U;for i=26,292,0b10__11__000 do if i<0X72 then l=({{},nil,{},nil,nil});elseif i<0xCa and i>0x1A then(l)[0B1_01]=a9();continue;elseif i>114 and i<0X122 then U={};else if not(i>0XCa)then else l[0B10]=U;break;end;end;end;local I,z,B,G=0b110111__0;while true do if I>0X50 and I<0X75 then I=0X75;for a=0B1,a9()do local l=a9();local I=(l/i);(U)[a]={[0X1]=I-I%1,[c]=l%0x2};end;z=(l[0X1]);elseif I>0B1101110 then B=(a9()-0X5FD_8);I=(0X5__0);continue;else if not(I<0X6e)then else for i=0X1,B do local a,l,U,I,B,G,r,J=(0X74);while true do if a<0X4__6 then G,r,J=U%0X004,l%0X4,(B%4);a=(0b1000110);else if a>0X43 and a<0X74 then z[i]={[0X7]=nil,[3]=j,[0B1]=j,[0X3]=nil,[0X2]=nil,[6]=j,[0x005]=(B-J)/0x4__,[A]=nil,[H]=r,[6]=J,[0b11]=j,[D]=(l-r)/0X4,[T]=G,[3]=I,[2]=(U-G)/0B100};break;else if not(a>0X4__6)then else a=(0X43);l,U,I,B=C(),C(),C(),C();continue;end;end;end;end;end;G=(0B1);break;end;end;end;for i=0X1,B do U=(nil);for B=91,0X78,7 do if B>91 then for i,l in R do I=(k[l]);i=U[l];z=(U[I]);if z==2 then local l=(h[i]);local i=a[l];if i then(U)[I]=i[0B1];l=(i[2]);(l)[#l+1]={U,I};end;else if z==0X1 then(U)[l]=(i+0x1_);else if z==0 then local a;for l=0B010__0__1111,0B11000001,0B111001 do if l~=0X88 then if l==0X4f then a=l9[i];elseif l==193 then a[#a+1]=({U,I});end;elseif not not a then else local l=0B0011;while true do if l==0X3 then l=(6);a={};elseif l~=0X6 then else(l9)[i]=(a);break;end;end;end;end;end;end;end;end;break;else if B<98 then U=(l[0X1][i]);continue;end;end;end;end;U=(l[3]);for a=0X20,0b10111000__,0x42 do if a<=0B100000 then for a=0b1,s()do z=nil;I=nil;for a=0x57_,365,0x57 do if a<=174 then if a==0xae__ then I=(z/i);continue;else z=s();continue;end;else if a<=261 then if z%2~=0X0 then B=(nil);for i=91,0XB8,0X00_24 do if i<0Xa3 and i>0X5B then B=s();continue;elseif i<0X7F then G=s();continue;else if i>0B1_111111 then for i=I-I%0X01,G do(U)[i]=B;end;break;end;end;end;else(U)[G]=(I-I%1);end;else G+=0X1;break;end;end;end;end;(l)[0X4]=a9();else return l;end;end;end;if not not K[14054]then p=K[0X36E6__];else p=(-3451729465+(X[0B1000]-K[7999]-K[25019]-K[9106]+K[0x0070cB]));(K)[14054]=p;end;continue;end;else v=(function()h=({});a={};local i,l,I,z;for B=113,258,0b11010__1 do if B==0b101__00110 then l=0X1__;elseif B==219 then I=(a9()-e);z=o()~=0B0;for i=U,I do local U,I,B=126;repeat if U>0X45 then I=j;U=(0X45);B=o();continue;else if not(U<126)then else if B==0B10000101 then I=i9();elseif B==0X00C8 then I=u(M(),i9()+s());else if B==0b1110100 then I=s();elseif B==0x67 then I=(i9()+s());elseif B==0X20 then I=m();else if B==0B111110 then I=M();else if B~=155 then else I=o()==0x1;end;end;end;end;break;end;end;until false;U=(nil);for z=7,0x129,97 do if not(z>0X7)then U=({I,{}});else if z~=104 then(a)[l]=U;break;else(h)[i-1]=(l);end;end;end;l=(l+0B1);if not z then else for i=0B1000010,0B11100_11,0X31__ do if i>0B100001__0 then q=(q+0X1);else S[q]=(U);end;end;end;end;break;else if B==113 then i={};l9=({});end;end;end;I=a9()-39457;l=nil;z=0B1011110;repeat if z<0X72 and z>0B1000000 then z=(0X25);for a=0,I-1 do(i)[a]=z9();end;else if not(z<0X25)then if z>41 and z<0X5E then l=(i[a9()]);z=(0X1_f);continue;elseif z>0B11111 and z<0x29 then for a,l in l9 do local U;for I=0x2B,0B100__01011,0X3__9 do if I==100 then if not U then else for i,i in l do i[1][i[2]]=(U);end;end;break;else U=i[a];end;end;end;z=0B1000000;else if z<0B1000000 and z>0X25 then l9=(nil);break;else if not(z>0B001011110_)then else z=(0X29);a=(nil);end;end;end;else z=0x72;h=j;end;end;until false;return l;end);if not not K[3848]then p=(K[0xF08]);else(K)[0X66c7]=0B100+w.U((w.F(w.v(K[7999],K[28875])+K[0X1F3f])));p=(0X55+(w.L(K[0X3db]>K[0X4e01]and K[0x677e]or K[0X2392])-K[14054]<=K[7316]and K[24997]or K[0X5e68]));K[0XF08]=p;end;end;end;until false;local i,a,U=v(),function(i)if z(i)=='\x74\97\z \98l\x65'then local a=b({},{[d]=i});for l=0b10101,220,0X006E do if l>0X15 then return a;else if not(l<0B1000_001_1)then else for i,l in i do a[i]=(l);end;end;end;end;end;return i;end;p=0X44;while true do if p<83 then U=next;if not K[30074]then p=(0B111__1__+w.F(w.j((w.F(K[0x2e__A7],K[19969],K[0X739])))>K[0XFaE]and X[0B10__01]or K[0X5f4],K[0X2392]));(K)[0X757a__]=(p);else p=(K[30074]);end;continue;else if not(p>0x4_4)then else(y)[0XF1B]=a(E);y[0x1EE8]=a(w.q);break;end;end;end;y[16297]=a(w.C);p=0b1011111;while true do if p==0X5f then i=I9(i,N)(v,f,x,l,i9,o,s,X,g,I9);if not not K[1681]then p=K[1681];else(K)[0XEBC]=0X5a+((w.L((w.L(K[20332])))>K[26311]and K[30074]or K[0X75ED])-K[28330]);p=(-4294967213+w.L((w.f((w.v(K[0X004e01]+K[0x4A9],K[1860]))))));(K)[1681]=p;end;else if p~=50 then else return I9(i,N);end;end;end;end)(0X2,7,8,0b1,select,type,6,coroutine.wrap,string.byte,coroutine.yield,nil,error,0X5,0X1,7,3,table.create,string.char,{j=bit32.band,f=bit32.countlz,E=bit32.rrotate,Q=setmetatable,N=bit32.lshift,C=bit32,F=bit32.bxor,L=bit32.bnot,n=bit32.countrz,q=math,v=bit32.rshift,U=bit32.bor,o=table.move,V=string.sub,K=string.match,i=bit32.lrotate},0X1802D,bit32,4,string.pack,2,0x5,string,pcall,"\_\x5Find\u{0065}\z  \120",function(...)(...)[...]=nil;end,{},{0xdA7a,0X1ac45f1d,4002540188,1693190716,0X62E2094F,3553285052,2160191628,3451729588,3031238034})(...);
