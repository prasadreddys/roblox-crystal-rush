-- Crystal Rush (client): start screen, HUD, round-end screen and coin sparkles.
-- The HUD keeps clear of the top-left corner, where Roblox puts its own menu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("CrystalRush")
local scoreEvent = remotes:WaitForChild("ScoreChanged")
local timerEvent = remotes:WaitForChild("TimerChanged")
local roundEndedEvent = remotes:WaitForChild("RoundEnded")
local sparkleEvent = remotes:WaitForChild("CoinSparkle")

local GOLD = Color3.fromRGB(255, 210, 60)
local DARK = Color3.fromRGB(25, 20, 60)
local WHITE = Color3.fromRGB(245, 245, 245)

local myScore = 0
local myCoins = 0
local myBest = 0

local gui = Instance.new("ScreenGui")
gui.Name = "CrystalRushGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent, name, text, textSize, position, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = WHITE
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(400, 50)
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0.5, 0)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = parent
	return label
end

-- Start screen: title, a one-line how-to, and a Play button.
local startFrame = Instance.new("Frame")
startFrame.Name = "StartScreen"
startFrame.Size = UDim2.fromScale(1, 1)
startFrame.BackgroundColor3 = DARK
startFrame.BorderSizePixel = 0
startFrame.Parent = gui

local title = makeLabel(startFrame, "Title", "CRYSTAL RUSH", 64, UDim2.new(0.5, 0, 0.28, 0))
title.TextColor3 = GOLD
title.Size = UDim2.fromOffset(600, 80)

local subtitle = makeLabel(startFrame, "Subtitle",
	"Collect coins, chase the golden crystal worth 10x, and beat the 120-second clock.",
	24, UDim2.new(0.5, 0, 0.42, 0))
subtitle.Size = UDim2.fromOffset(700, 40)
subtitle.Font = Enum.Font.SourceSans

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.Text = "PLAY"
playButton.TextSize = 32
playButton.Font = Enum.Font.SourceSansBold
playButton.TextColor3 = DARK
playButton.BackgroundColor3 = GOLD
playButton.AnchorPoint = Vector2.new(0.5, 0)
playButton.Position = UDim2.new(0.5, 0, 0.55, 0)
playButton.Size = UDim2.fromOffset(220, 64)
playButton.Parent = startFrame

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 12)
playCorner.Parent = playButton

-- HUD: timer top-centre, score top-right (clear of Roblox's own menu, top-left).
local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.fromScale(1, 1)
hud.BackgroundTransparency = 1
hud.Visible = false
hud.Parent = gui

local timerLabel = makeLabel(hud, "Timer", "2:00", 32, UDim2.new(0.5, 0, 0, 12))
timerLabel.Size = UDim2.fromOffset(220, 44)

local scoreLabel = makeLabel(hud, "Score", "Score: 0", 28, UDim2.new(1, -16, 0, 12), Vector2.new(1, 0))
scoreLabel.Size = UDim2.fromOffset(240, 40)
scoreLabel.TextXAlignment = Enum.TextXAlignment.Right

local coinsLabel = makeLabel(hud, "Coins", "Coins: 0", 22, UDim2.new(1, -16, 0, 52), Vector2.new(1, 0))
coinsLabel.Size = UDim2.fromOffset(240, 32)
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.Font = Enum.Font.SourceSans

local bestLabel = makeLabel(hud, "Best", "Best: 0", 22, UDim2.new(1, -16, 0, 84), Vector2.new(1, 0))
bestLabel.Size = UDim2.fromOffset(240, 32)
bestLabel.TextXAlignment = Enum.TextXAlignment.Right
bestLabel.Font = Enum.Font.SourceSans

-- Round-end screen: winner, your score and your best.
local endFrame = Instance.new("Frame")
endFrame.Name = "RoundEnd"
endFrame.AnchorPoint = Vector2.new(0.5, 0.5)
endFrame.Position = UDim2.fromScale(0.5, 0.5)
endFrame.Size = UDim2.fromOffset(460, 280)
endFrame.BackgroundColor3 = DARK
endFrame.BorderSizePixel = 0
endFrame.Visible = false
endFrame.Parent = gui

local endCorner = Instance.new("UICorner")
endCorner.CornerRadius = UDim.new(0, 16)
endCorner.Parent = endFrame

local endTitle = makeLabel(endFrame, "EndTitle", "ROUND OVER!", 40, UDim2.new(0.5, 0, 0.08, 0))
endTitle.TextColor3 = GOLD
endTitle.Size = UDim2.fromOffset(420, 56)

local winnerLabel = makeLabel(endFrame, "Winner", "Winner: Nobody yet", 26, UDim2.new(0.5, 0, 0.34, 0))
winnerLabel.Size = UDim2.fromOffset(420, 40)

local yourScoreLabel = makeLabel(endFrame, "YourScore", "Your score: 0", 26, UDim2.new(0.5, 0, 0.52, 0))
yourScoreLabel.Size = UDim2.fromOffset(420, 40)

local yourBestLabel = makeLabel(endFrame, "YourBest", "Your best: 0", 22, UDim2.new(0.5, 0, 0.70, 0))
yourBestLabel.Size = UDim2.fromOffset(420, 36)
yourBestLabel.Font = Enum.Font.SourceSans

playButton.MouseButton1Click:Connect(function()
	startFrame.Visible = false
	hud.Visible = true
end)

local function formatTime(seconds)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

scoreEvent.OnClientEvent:Connect(function(score, coins, best)
	myScore = score
	myCoins = coins
	myBest = best
	scoreLabel.Text = "Score: " .. tostring(score)
	coinsLabel.Text = "Coins: " .. tostring(coins)
	bestLabel.Text = "Best: " .. tostring(best)
	-- A quick pulse on the score so a pickup reads at a glance.
	scoreLabel.TextSize = 36
	task.delay(0.15, function()
		scoreLabel.TextSize = 28
	end)
end)

timerEvent.OnClientEvent:Connect(function(secondsLeft, roundPhase)
	if roundPhase == "playing" then
		timerLabel.Text = formatTime(secondsLeft)
		endFrame.Visible = false
	elseif roundPhase == "lobby" then
		timerLabel.Text = "Next round in " .. tostring(secondsLeft) .. "s"
		endFrame.Visible = false
	else
		timerLabel.Text = "Round over!"
	end
end)

roundEndedEvent.OnClientEvent:Connect(function(winnerName, winnerScore)
	winnerLabel.Text = "Winner: " .. winnerName .. "  -  " .. tostring(winnerScore) .. " pts"
	yourScoreLabel.Text = "Your score: " .. tostring(myScore)
	yourBestLabel.Text = "Your best: " .. tostring(myBest)
	endFrame.Visible = true
end)

-- A coin sparkle: a small gold part that flashes and fades where the coin was.
sparkleEvent.OnClientEvent:Connect(function(position)
	local flash = Instance.new("Part")
	flash.Name = "CoinSparkle"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(1.5, 1.5, 1.5)
	flash.CFrame = CFrame.new(position)
	flash.Color = GOLD
	flash.Material = Enum.Material.Neon
	flash.Anchored = true
	flash.CanCollide = false
	flash.Parent = workspace

	local tween = TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(4, 4, 4),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		flash:Destroy()
	end)
end)
