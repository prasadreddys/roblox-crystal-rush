-- Crystal Rush (server): a bright 3D arena coin-collector.
-- This one script builds the whole arena from code, spawns coins, keeps score,
-- runs the round loop and tells every client what is happening.
-- One player or many: everyone collects coins, and the highest score wins the round.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Round settings.
local ROUND_LENGTH = 120
local LOBBY_LENGTH = 10
local END_SCREEN_LENGTH = 8
local MAX_COINS = 24
local CRYSTAL_EVERY = 30
local CRYSTAL_LIFETIME = 15
local COIN_POINTS = 1
local CRYSTAL_POINTS = 10

-- Round state.
local phase = "lobby"
local timeLeft = LOBBY_LENGTH
local scores = {} -- [player] = { points = 0, coins = 0 }
local best = {} -- [player] = best round points so far
local activeCoins = {} -- list of { part, value, basePos, bornAt, isCrystal, spinPhase }

-- Remote events the client listens to.
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "CrystalRush"
remoteFolder.Parent = ReplicatedStorage

local scoreEvent = Instance.new("RemoteEvent")
scoreEvent.Name = "ScoreChanged"
scoreEvent.Parent = remoteFolder

local timerEvent = Instance.new("RemoteEvent")
timerEvent.Name = "TimerChanged"
timerEvent.Parent = remoteFolder

local roundEndedEvent = Instance.new("RemoteEvent")
roundEndedEvent.Name = "RoundEnded"
roundEndedEvent.Parent = remoteFolder

local sparkleEvent = Instance.new("RemoteEvent")
sparkleEvent.Name = "CoinSparkle"
sparkleEvent.Parent = remoteFolder

-- Small helper: one anchored part with the given look.
local function makePart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- The arena: baseplate, border walls, four platforms with ramps,
-- a central crystal tower, trees and rocks. Everything is built here,
-- so the place is reproducible from this file alone.
local arena = Instance.new("Folder")
arena.Name = "Arena"
arena.Parent = workspace

local function buildArena()
	-- Grass baseplate, top surface at y = 0.
	makePart("Baseplate", Vector3.new(120, 2, 120), Vector3.new(0, -1, 0),
		Color3.fromRGB(90, 190, 80), Enum.Material.Grass, arena)
	-- A sandy ring just outside the grass, for contrast.
	makePart("OuterRing", Vector3.new(150, 1, 150), Vector3.new(0, -1.6, 0),
		Color3.fromRGB(220, 200, 140), Enum.Material.Sand, arena)

	-- Low colourful walls around the edge, so players stay in the arena.
	local wallColor = Color3.fromRGB(70, 130, 230)
	for _, side in ipairs({ -1, 1 }) do
		makePart("WallNorth", Vector3.new(108, 3, 2), Vector3.new(0, 1.5, side * 53), wallColor, Enum.Material.SmoothPlastic, arena)
		makePart("WallEast", Vector3.new(2, 3, 108), Vector3.new(side * 53, 1.5, 0), wallColor, Enum.Material.SmoothPlastic, arena)
	end

	-- Four raised platforms, one in each quadrant.
	local platformTops = {
		Vector3.new(30, 5, 30),
		Vector3.new(-30, 5, 30),
		Vector3.new(30, 5, -30),
		Vector3.new(-30, 5, -30),
	}
	local platformColors = {
		Color3.fromRGB(255, 150, 80),
		Color3.fromRGB(80, 200, 255),
		Color3.fromRGB(200, 120, 255),
		Color3.fromRGB(255, 220, 80),
	}
	for i, top in ipairs(platformTops) do
		-- Platform slab, top surface at y = 5.
		makePart("Platform", Vector3.new(18, 1, 18), Vector3.new(top.X, 4.5, top.Z),
			platformColors[i], Enum.Material.SmoothPlastic, arena)
		-- Support pillar under the middle of the slab.
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar"
		pillar.Shape = Enum.PartType.Cylinder
		pillar.Size = Vector3.new(4, 4, 4)
		pillar.Position = Vector3.new(top.X, 2, top.Z)
		pillar.Color = Color3.fromRGB(150, 150, 150)
		pillar.Material = Enum.Material.Concrete
		pillar.Anchored = true
		pillar.Parent = arena

		-- A ramp up to the platform from the arena-centre side.
		-- The ramp spans 14 studs and rises 5, so it tilts about 20 degrees.
		local ramp = makePart("Ramp", Vector3.new(8, 1, 14),
			Vector3.new(top.X, 2.5, top.Z - math.sign(top.Z) * 16),
			Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, arena)
		ramp.CFrame = CFrame.new(ramp.Position) * CFrame.Angles(math.rad(-20 * math.sign(top.Z)), 0, 0)
	end

	-- Central crystal tower: stone base, column, and a big glowing crystal.
	local base = Instance.new("Part")
	base.Name = "TowerBase"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(3, 14, 14)
	base.Position = Vector3.new(0, 1, 0)
	base.Color = Color3.fromRGB(140, 140, 150)
	base.Material = Enum.Material.Concrete
	base.Anchored = true
	base.Parent = arena

	local column = Instance.new("Part")
	column.Name = "TowerColumn"
	column.Shape = Enum.PartType.Cylinder
	column.Size = Vector3.new(10, 4, 4)
	column.Position = Vector3.new(0, 7, 0)
	column.Color = Color3.fromRGB(170, 170, 180)
	column.Material = Enum.Material.Concrete
	column.Anchored = true
	column.Parent = arena

	local crystal = Instance.new("Part")
	crystal.Name = "TowerCrystal"
	crystal.Size = Vector3.new(4, 7, 4)
	crystal.Position = Vector3.new(0, 16, 0)
	crystal.Color = Color3.fromRGB(80, 220, 255)
	crystal.Material = Enum.Material.Neon
	crystal.Anchored = true
	crystal.CFrame = CFrame.new(0, 16, 0) * CFrame.Angles(0, math.rad(45), math.rad(20))
	crystal.Parent = arena

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(80, 220, 255)
	glow.Range = 40
	glow.Brightness = 2
	glow.Parent = crystal

	-- Trees and rocks scattered near the edge, clear of the play area.
	local treeSpots = {
		Vector3.new(-46, 0, -40), Vector3.new(46, 0, -42), Vector3.new(-44, 0, 44),
		Vector3.new(44, 0, 46), Vector3.new(0, 0, -48), Vector3.new(-48, 0, 0),
		Vector3.new(48, 0, 6), Vector3.new(6, 0, 48),
	}
	for _, spot in ipairs(treeSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(6, 1.6, 1.6)
		trunk.Position = spot + Vector3.new(0, 3, 0)
		trunk.Color = Color3.fromRGB(140, 95, 50)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = arena

		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(7, 7, 7)
		leaves.Position = spot + Vector3.new(0, 8.5, 0)
		leaves.Color = Color3.fromRGB(50, 170, 70)
		leaves.Material = Enum.Material.SmoothPlastic
		leaves.Anchored = true
		leaves.Parent = arena
	end

	local rockSpots = {
		Vector3.new(-38, 0, -14), Vector3.new(38, 0, 14), Vector3.new(-14, 0, 40),
		Vector3.new(16, 0, -40), Vector3.new(44, 0, -24), Vector3.new(-44, 0, 24),
	}
	for _, spot in ipairs(rockSpots) do
		local rock = Instance.new("Part")
		rock.Name = "Rock"
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(3, 2.5, 3)
		rock.Position = spot + Vector3.new(0, 1, 0)
		rock.Color = Color3.fromRGB(130, 130, 135)
		rock.Material = Enum.Material.Slate
		rock.Anchored = true
		rock.Parent = arena
	end

	-- Spawn point facing the tower from the south side.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 44)
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CFrame = CFrame.new(0, 0.5, 44) * CFrame.Angles(0, math.rad(180), 0)
	spawn.Parent = arena
end

buildArena()

-- Places a coin can appear: on the grass and on top of the platforms.
local coinSpots = {
	Vector3.new(12, 2, 12), Vector3.new(-12, 2, 12), Vector3.new(12, 2, -12),
	Vector3.new(-12, 2, -12), Vector3.new(25, 2, 0), Vector3.new(-25, 2, 0),
	Vector3.new(0, 2, 25), Vector3.new(0, 2, -25), Vector3.new(40, 2, 20),
	Vector3.new(-40, 2, -20), Vector3.new(20, 2, -40), Vector3.new(-20, 2, 40),
	Vector3.new(38, 2, -36), Vector3.new(-38, 2, 36), Vector3.new(45, 2, -6),
	Vector3.new(-45, 2, 6), Vector3.new(6, 2, -45), Vector3.new(-6, 2, 45),
	Vector3.new(30, 6.5, 30), Vector3.new(-30, 6.5, 30), Vector3.new(30, 6.5, -30),
	Vector3.new(-30, 6.5, -30), Vector3.new(24, 6.5, 30), Vector3.new(-24, 6.5, -30),
	Vector3.new(30, 6.5, 24), Vector3.new(-30, 6.5, -24),
}

local coinFolder = Instance.new("Folder")
coinFolder.Name = "Coins"
coinFolder.Parent = workspace

local function coinNear(position)
	for _, coin in ipairs(activeCoins) do
		if (coin.basePos - position).Magnitude < 4 then
			return true
		end
	end
	return false
end

local function removeCoinAt(index)
	local coin = activeCoins[index]
	if coin then
		table.remove(activeCoins, index)
		if coin.part and coin.part.Parent then
			coin.part:Destroy()
		end
	end
end

local function spawnCoinAt(position, value, isCrystal)
	local part = Instance.new("Part")
	part.Name = isCrystal and "GoldenCrystal" or "Coin"
	part.Anchored = true
	part.CanCollide = false
	part.Parent = coinFolder

	if isCrystal then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(3.5, 3.5, 3.5)
		part.Color = Color3.fromRGB(255, 200, 0)
		part.Material = Enum.Material.Neon
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 0)
		light.Range = 16
		light.Brightness = 2
		light.Parent = part
	else
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.6, 2.4, 2.4)
		part.Color = Color3.fromRGB(255, 210, 60)
		part.Material = Enum.Material.Neon
	end

	part.CFrame = CFrame.new(position)
	local coin = {
		part = part,
		value = value,
		isCrystal = isCrystal,
		basePos = position,
		bornAt = os.clock(),
		spinPhase = math.random() * math.pi * 2,
	}
	table.insert(activeCoins, coin)

	part.Touched:Connect(function(otherPart)
		if coin.collected then
			return
		end
		local character = otherPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		coin.collected = true
		local data = scores[player]
		if data then
			data.points += value
			data.coins += 1
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Points") then
				stats.Points.Value = data.points
			end
			scoreEvent:FireClient(player, data.points, data.coins, best[player] or 0)
		end
		-- Everyone sees the sparkle where the coin was.
		sparkleEvent:FireAllClients(position)
		for i, entry in ipairs(activeCoins) do
			if entry == coin then
				removeCoinAt(i)
				break
			end
		end
	end)

	return coin
end

local function spawnCoin()
	for _ = 1, 8 do
		local spot = coinSpots[math.random(1, #coinSpots)]
		if not coinNear(spot) then
			spawnCoinAt(spot, COIN_POINTS, false)
			return
		end
	end
end

local function spawnGoldenCrystal()
	for _ = 1, 8 do
		local spot = coinSpots[math.random(1, #coinSpots)]
		if not coinNear(spot) then
			spawnCoinAt(spot, CRYSTAL_POINTS, true)
			return
		end
	end
end

local function topUpCoins()
	local count = 0
	for _, coin in ipairs(activeCoins) do
		if not coin.isCrystal then
			count += 1
		end
	end
	while count < MAX_COINS do
		spawnCoin()
		count += 1
	end
end

local function clearCoins()
	for i = #activeCoins, 1, -1 do
		removeCoinAt(i)
	end
end

-- Coins spin and bob; golden crystals fade away if nobody grabs them.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for i = #activeCoins, 1, -1 do
		local coin = activeCoins[i]
		if coin.isCrystal and now - coin.bornAt > CRYSTAL_LIFETIME then
			removeCoinAt(i)
		elseif coin.part and coin.part.Parent then
			local bob = math.sin(now * 2 + coin.spinPhase) * 0.35
			coin.part.CFrame = CFrame.new(coin.basePos + Vector3.new(0, bob, 0))
				* CFrame.Angles(0, now * 2.2, 0)
		end
	end
end)

-- Leaderboard: Points and Best show up in Roblox's own leaderboard.
local function setupPlayer(player)
	scores[player] = { points = 0, coins = 0 }
	best[player] = 0
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Value = 0
	points.Parent = stats
	local bestValue = Instance.new("IntValue")
	bestValue.Name = "Best"
	bestValue.Value = 0
	bestValue.Parent = stats
	stats.Parent = player
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	scores[player] = nil
	best[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

local function broadcastTimer()
	timerEvent:FireAllClients(timeLeft, phase)
end

local function resetScores()
	for player, data in pairs(scores) do
		data.points = 0
		data.coins = 0
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Points") then
			stats.Points.Value = 0
		end
		scoreEvent:FireClient(player, 0, 0, best[player] or 0)
	end
end

local function findWinner()
	local winner = nil
	local winnerScore = 0
	for player, data in pairs(scores) do
		if data.points > winnerScore then
			winner = player
			winnerScore = data.points
		end
	end
	return winner, winnerScore
end

local function recordBest()
	for player, data in pairs(scores) do
		if data.points > (best[player] or 0) then
			best[player] = data.points
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Best") then
				stats.Best.Value = data.points
			end
		end
	end
end

-- The round loop: a short lobby, a 120-second round, then the results.
task.spawn(function()
	while true do
		-- Lobby: coins cleared, players gather at the spawn.
		phase = "lobby"
		clearCoins()
		for count = LOBBY_LENGTH, 1, -1 do
			timeLeft = count
			broadcastTimer()
			task.wait(1)
		end

		-- Round start: scores reset, coins scattered.
		resetScores()
		phase = "playing"
		timeLeft = ROUND_LENGTH
		for _ = 1, 12 do
			spawnCoin()
		end
		broadcastTimer()

		local crystalTimer = CRYSTAL_EVERY
		while timeLeft > 0 do
			task.wait(1)
			timeLeft -= 1
			crystalTimer -= 1
			if crystalTimer <= 0 then
				spawnGoldenCrystal()
				crystalTimer = CRYSTAL_EVERY
			end
			topUpCoins()
			broadcastTimer()
		end

		-- Round end: crown the winner, save everyone's best.
		phase = "ended"
		timeLeft = 0
		broadcastTimer()
		recordBest()
		local winner, winnerScore = findWinner()
		local winnerName = winner and winner.DisplayName or "Nobody yet"
		roundEndedEvent:FireAllClients(winnerName, winnerScore)
		task.wait(END_SCREEN_LENGTH)
	end
end)

print("Crystal Rush is running: collect coins, chase the golden crystal!")
