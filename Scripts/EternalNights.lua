local src = game:HttpGet("https://pastebin.com/raw/cGLXkfhZ")
local fn, err = loadstring(src)
if not fn then error("Failed to load lib: "..(err or "?")) end
fn()

local workspace = game:GetService("Workspace")
local players   = game:GetService("Players")
local player    = players.LocalPlayer

local CFG = {
    animEnable     = false,
    animBox        = true,
    animName       = true,
    animDistance   = true,
    animTraceline  = false,
    animMaxDist    = 300,
    animBoxColor   = Color3.fromRGB(255, 50,  50),

    itemEnable    = false,
    itemBox       = true,
    itemName      = true,
    itemDistance  = true,
    itemTraceline = false,
    itemMaxDist   = 300,
    itemBoxColor  = Color3.fromRGB(80, 200, 120),

    coinEnable    = false,
    coinBox       = true,
    coinName      = true,
    coinDistance  = true,
    coinTraceline = false,
    coinMaxDist   = 300,
    coinBoxColor  = Color3.fromRGB(255, 215, 0),

    chestEnable    = false,
    chestBox       = true,
    chestName      = true,
    chestDistance  = true,
    chestTraceline = false,
    chestMaxDist   = 300,
    chestBoxColor  = Color3.fromRGB(200, 140, 50),

    fontSize    = 13,
    renderWait  = 0.03,
}

-- Static box sizes (screen pixels)
local ITEM_HW,  ITEM_HH  = 22,  22
local ANIM_HW,  ANIM_HH  = 60,  80
local COIN_HW,  COIN_HH  = 12,  12
local CHEST_HW, CHEST_HH = 25,  25
local CORNER_LEN = 8  -- corner bracket length

local ITEM_NAMES = {
    ["OldFlashlight"]=true,["Battery"]=true,["Pliers"]=true,
    ["Phillips screwdriver"]=true,["Photo Camera"]=true,["Fuse"]=true,
    ["Mask"]=true,["Lantern Lamp"]=true,["Head Light"]=true,
    ["Battery Pack"]=true,["Flashlight"]=true,["Wristwatch"]=true,
    ["Super Flashlight"]=true,["Megaphone"]=true,["Vitamin"]=true,
    ["Bucket"]=true,["Music Box"]=true,["Walkie Talkie"]=true,
}

local ANIM_COLORS = {
    Puppet=Color3.fromRGB(255,255,255), Bonnie=Color3.fromRGB(0,162,255),
    Cupcake=Color3.fromRGB(255,105,180), Chica=Color3.fromRGB(255,215,0),
    Freddy=Color3.fromRGB(255,165,0), Foxy=Color3.fromRGB(255,50,50),
    Goldenfreddy=Color3.fromRGB(255,215,0),
}
local ANIM_SIZES = {
    Puppet={w=6.2,h=7.8}, Bonnie={w=3.8,h=10.2}, Cupcake={w=0.9,h=2.6},
    Chica={w=7.6,h=8.6}, Freddy={w=5.6,h=9.3}, Foxy={w=6.2,h=9.1},
    Goldenfreddy={w=5.9,h=9.8},
}
local DEFAULT_ANIM_SIZE = {w=5.4,h=9.0}

local animFolder  = workspace:WaitForChild("Game").Animatronics.Animatronics
local coinsFolder = workspace:WaitForChild("Map"):WaitForChild("CoinsMap")
local bausFolder  = workspace:WaitForChild("Map"):WaitForChild("Baus")

-- ── Drawing helpers ───────────────────────────────────────────────
local function newLine(col, thick)
    local l = Drawing.new("Line")
    l.Color=col; l.Thickness=thick or 1.5; l.Visible=false; return l
end
local function newText(col, sz)
    local t = Drawing.new("Text")
    t.Font=Drawing.Fonts.UI; t.Size=sz or CFG.fontSize
    t.Color=col; t.Outline=true; t.Center=true
    t.ZIndex=10; t.Visible=false; return t
end

-- Corner-bracket box: 8 lines (2 per corner)
local function newBox(col, thick)
    local lines = {}
    for i=1,8 do lines[i]=newLine(col, thick or 1.5) end
    return lines
end

local function setBoxColor(lines, col)
    for i=1,8 do lines[i].Color=col end
end

local function drawCornerBox(lines, x, y, hw, hh, len)
    -- top-left
    lines[1].From=Vector2.new(x-hw,y-hh); lines[1].To=Vector2.new(x-hw+len,y-hh)
    lines[2].From=Vector2.new(x-hw,y-hh); lines[2].To=Vector2.new(x-hw,y-hh+len)
    -- top-right
    lines[3].From=Vector2.new(x+hw,y-hh); lines[3].To=Vector2.new(x+hw-len,y-hh)
    lines[4].From=Vector2.new(x+hw,y-hh); lines[4].To=Vector2.new(x+hw,y-hh+len)
    -- bottom-right
    lines[5].From=Vector2.new(x+hw,y+hh); lines[5].To=Vector2.new(x+hw-len,y+hh)
    lines[6].From=Vector2.new(x+hw,y+hh); lines[6].To=Vector2.new(x+hw,y+hh-len)
    -- bottom-left
    lines[7].From=Vector2.new(x-hw,y+hh); lines[7].To=Vector2.new(x-hw+len,y+hh)
    lines[8].From=Vector2.new(x-hw,y+hh); lines[8].To=Vector2.new(x-hw,y+hh-len)
    for i=1,8 do lines[i].Visible=true end
end

local function hideBox(lines)
    for i=1,8 do lines[i].Visible=false end
end

local function drawTracer(line, col, sx, sy, show)
    if not show then line.Visible=false; return end
    local scr = workspace.CurrentCamera.ViewportSize
    line.From=Vector2.new(scr.X/2, scr.Y)
    line.To=Vector2.new(sx, sy)
    line.Color=col; line.Visible=true
end

-- ── ESP table: inst -> {box, label, tracer, statusLabel, ...} ────
local espObjects = {}

local function getDist(a, b)
    if not a or not b then return 9999 end
    local dx,dy,dz=a.X-b.X,a.Y-b.Y,a.Z-b.Z
    return math.floor(math.sqrt(dx*dx+dy*dy+dz*dz))
end

local function playerPos()
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return root and root.Position or nil
end

local function getItemRoot(obj)
    local cn=obj.ClassName
    if cn=="MeshPart" or cn=="Part" then return obj end
    if cn=="Model" or cn=="Tool" or cn=="Accessory" then
        return obj:FindFirstChild("Handle")
    end
end

local function getAnimRoot(model)
    return model.PrimaryPart
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Root")
        or model:FindFirstChild("Torso")
        or model:FindFirstChildWhichIsA("BasePart")
end

local function createESP(inst, kind)
    if espObjects[inst] then return end
    local col = Color3.new(1,1,1)
    local d = {
        kind        = kind,
        box         = newBox(col, kind=="anim" and 1.5 or 1),
        label       = newText(col),
        distLabel   = newText(Color3.new(1,1,1)),
        tracer      = newLine(col, 1),
    }
    if kind=="anim" then
        d.statusLabel = newText(col)
        d.lastPos     = nil
        d.isMoving    = false
        d.notified    = false
        d.stableCount = 0
    end
    espObjects[inst] = d
end

local function destroyESP(inst)
    local d = espObjects[inst]; if not d then return end
    hideBox(d.box)
    for _,l in ipairs(d.box) do l:Remove() end
    d.label:Remove(); d.distLabel:Remove(); d.tracer:Remove()
    if d.statusLabel then d.statusLabel:Remove() end
    espObjects[inst] = nil
end

local function hideESP(d)
    hideBox(d.box)
    d.label.Visible=false
    d.distLabel.Visible=false
    d.tracer.Visible=false
    if d.statusLabel then d.statusLabel.Visible=false end
end

-- ── SCAN LOOP ─────────────────────────────────────────────────────
-- Matcha has no ChildAdded events, so we use snapshot diffing.
-- We store what we found last time and only act on changes.
-- This avoids hammering createESP/destroyESP every frame.
local known = {}  -- inst -> true, tracks what we already registered

local function scanAll()
    local found = {}

    if CFG.animEnable then
        for _,m in pairs(animFolder:GetChildren()) do
            if m:IsA("Model") and getAnimRoot(m) then
                found[m] = "anim"
            end
        end
    end

    if CFG.itemEnable then
        for _,obj in pairs(workspace:GetChildren()) do
            if ITEM_NAMES[obj.Name] and getItemRoot(obj) then
                found[obj] = "item"
            end
        end
    end

    if CFG.coinEnable then
        for _,coin in pairs(coinsFolder:GetChildren()) do
            if coin:IsA("MeshPart") or coin:IsA("BasePart") then
                found[coin] = "coin"
            end
        end
    end

    if CFG.chestEnable then
        for _,child in pairs(bausFolder:GetChildren()) do
            if child.Name=="Bau" then
                for _,bau in pairs(child:GetChildren()) do
                    if bau:IsA("Model") and bau:FindFirstChild("Cadeado") then
                        found[bau] = "chest"
                    end
                end
            end
        end
    end

    -- Create ESP for new objects
    for inst, kind in pairs(found) do
        if not known[inst] then
            known[inst] = true
            createESP(inst, kind)
        end
    end

    -- Remove ESP for objects that disappeared
    for inst in pairs(known) do
        if not found[inst] then
            known[inst] = nil
            destroyESP(inst)
        end
    end
end

-- Initial scan immediately
scanAll()

-- Rescan periodically — cheap because it only acts on diffs
task.spawn(function()
    while true do
        task.wait(2)
        scanAll()
    end
end)

-- ── RENDER: runs at ~30fps to stay smooth ───────────────────────
task.spawn(function()
    while true do
        task.wait(CFG.renderWait)

        local pPos = playerPos()

        for inst, d in pairs(espObjects) do
            local kind = d.kind

            -- Lazy destroy
            local ok, alive = pcall(function() return inst.Parent ~= nil end)
            if not ok or not alive then destroyESP(inst); continue end

            -- Feature toggle
            local enabled =
                (kind=="anim"  and CFG.animEnable)  or
                (kind=="item"  and CFG.itemEnable)   or
                (kind=="coin"  and CFG.coinEnable)   or
                (kind=="chest" and CFG.chestEnable)
            if not enabled then hideESP(d); continue end

            -- Root part
            local root
            if     kind=="anim"  then root=getAnimRoot(inst)
            elseif kind=="item"  then root=getItemRoot(inst)
            elseif kind=="coin"  then root=inst:IsA("MeshPart") and inst or inst:FindFirstChildWhichIsA("BasePart")
            elseif kind=="chest" then root=inst:FindFirstChild("Cadeado")
            end
            if not root then hideESP(d); continue end

            -- Position
            local okP, rPos = pcall(function() return root.Position end)
            if not okP or not rPos then hideESP(d); continue end

            -- Movement detection runs every frame regardless of onScreen
            if kind=="anim" and pPos and d.lastPos then
                local okM, mag = pcall(function() return (rPos-d.lastPos).Magnitude end)
                if okM and mag then
                    if mag > 0.08 then
                        d.stableCount = 0
                        if not d.isMoving then
                            d.isMoving = true
                            if CFG.animNotifyMove and not d.notified then
                                d.notified = true
                                pcall(notify, inst.Name.." is moving!", inst.Name, 4)
                            end
                        end
                    else
                        d.stableCount = d.stableCount + 1
                        if d.stableCount > 45 and d.isMoving then
                            d.isMoving = false; d.notified = false
                        end
                    end
                end
            end
            if kind=="anim" then d.lastPos = rPos end

            -- Distance
            if not pPos then hideESP(d); continue end
            local dToObj = getDist(pPos, rPos)
            local maxD =
                (kind=="anim"  and CFG.animMaxDist)  or
                (kind=="item"  and CFG.itemMaxDist)   or
                (kind=="coin"  and CFG.coinMaxDist)   or
                (kind=="chest" and CFG.chestMaxDist)  or 9999
            if dToObj > maxD then hideESP(d); continue end

            -- WorldToScreen
            local wPos = rPos
            if kind=="anim" then
                local sz=ANIM_SIZES[inst.Name] or DEFAULT_ANIM_SIZE
                wPos=Vector3.new(rPos.X, rPos.Y+sz.h*0.5, rPos.Z)
            end
            local okW, sp, onScreen = pcall(WorldToScreen, wPos)
            -- KEY: hide immediately when offscreen — zero trail
            if not okW or not sp or not onScreen then
                hideESP(d); continue
            end

            local x, y = sp.X, sp.Y
            local distStr = "["..dToObj.."m]"

            local function drawInlineLabel(col, name, topY, showName, showDist)
                if not showName and not showDist then
                    d.label.Visible=false; d.distLabel.Visible=false; return
                end
                local GAP = 14  -- space between name and [dist]
                if showName and name~="" then
                    d.label.Text=name; d.label.Color=col
                    local nameW  = #name * 6
                    local distW  = showDist and (#distStr * 6 + GAP) or 0
                    local totalW = nameW + distW
                    d.label.Position=Vector2.new(x - totalW/2 + nameW/2, topY)
                    d.label.Visible=true
                else
                    d.label.Visible=false
                end
                if showDist then
                    local nameW  = showName and (#name * 6) or 0
                    local distW  = #distStr * 6
                    local totalW = nameW + (showName and GAP or 0) + distW
                    d.distLabel.Text=distStr; d.distLabel.Color=Color3.new(1,1,1)
                    d.distLabel.Position=Vector2.new(x - totalW/2 + nameW + (showName and GAP or 0) + distW/2, topY)
                    d.distLabel.Visible=true
                else
                    d.distLabel.Visible=false
                end
            end

            if kind=="item" then
                local col = CFG.itemBoxColor
                setBoxColor(d.box, col)
                if CFG.itemBox then drawCornerBox(d.box,x,y,ITEM_HW,ITEM_HH,CORNER_LEN) else hideBox(d.box) end
                drawInlineLabel(col, inst.Name, y-ITEM_HH-14, CFG.itemName, CFG.itemDistance)
                drawTracer(d.tracer, col, x, y, CFG.itemTraceline)

            elseif kind=="coin" then
                local col = CFG.coinBoxColor
                setBoxColor(d.box, col)
                if CFG.coinBox then drawCornerBox(d.box,x,y,COIN_HW,COIN_HH,5) else hideBox(d.box) end
                drawInlineLabel(col, "Coin", y-COIN_HH-14, CFG.coinName, CFG.coinDistance)
                drawTracer(d.tracer, col, x, y, CFG.coinTraceline)

            elseif kind=="chest" then
                local col = CFG.chestBoxColor
                setBoxColor(d.box, col)
                if CFG.chestBox then drawCornerBox(d.box,x,y,CHEST_HW,CHEST_HH,CORNER_LEN) else hideBox(d.box) end
                drawInlineLabel(col, "Chest", y-CHEST_HH-14, CFG.chestName, CFG.chestDistance)
                drawTracer(d.tracer, col, x, y, CFG.chestTraceline)

            elseif kind=="anim" then
                local col = ANIM_COLORS[inst.Name] or CFG.animBoxColor
                setBoxColor(d.box, col)
                if CFG.animBox then drawCornerBox(d.box,x,y,ANIM_HW,ANIM_HH,CORNER_LEN+6) else hideBox(d.box) end
                -- name above box, distance below box
                if CFG.animName and d.label then
                    d.label.Text=inst.Name; d.label.Color=col
                    d.label.Position=Vector2.new(x, y-ANIM_HH-14); d.label.Visible=true
                elseif d.label then d.label.Visible=false end
                if CFG.animDistance and d.distLabel then
                    d.distLabel.Text=distStr; d.distLabel.Color=Color3.new(1,1,1)
                    d.distLabel.Position=Vector2.new(x, y+ANIM_HH+8); d.distLabel.Visible=true
                elseif d.distLabel then d.distLabel.Visible=false end
                drawTracer(d.tracer, col, x, y, CFG.animTraceline)

                -- Status below distance
                if CFG.animStatus and d.statusLabel then
                    local statusStr = d.isMoving and "Moving" or "Standing"
                    d.statusLabel.Text=statusStr; d.statusLabel.Color=col
                    local statusY = CFG.animDistance and (y+ANIM_HH+24) or (y+ANIM_HH+8)
                    d.statusLabel.Position=Vector2.new(x, statusY); d.statusLabel.Visible=true
                elseif d.statusLabel then
                    d.statusLabel.Visible=false
                end
            end
        end
    end
end)

-- ── UI ────────────────────────────────────────────────────────────
local Hub = ShadowHub:CreateWindow({
    Title="SHADOWHUB", Theme="Fatality",
    MenuKey=0x70, Size=Vector2.new(860,520), Pos=Vector2.new(160,120),
})
local wm = ShadowHub:CreateWatermark("ShadowHub", Hub._T)
Hub._wmRef = wm

local ESP      = Hub:AddTab("ESP")
local Settings = Hub:AddPermTab("SETTINGS")

local Ani   = ESP:AddSection("ANIMATRONICS", 1)
local Items = ESP:AddSection("ITEMS", 2)
local World = ESP:AddSection("WORLD", 3)

Ani:AddToggle("Enable",           false, function(v) CFG.animEnable=v     end)
Ani:AddToggle("Box",              true,  function(v) CFG.animBox=v        end)
Ani:AddToggle("Name",             true,  function(v) CFG.animName=v       end)
Ani:AddToggle("Distance",         true,  function(v) CFG.animDistance=v   end)
Ani:AddToggle("Traceline",        false, function(v) CFG.animTraceline=v  end)
Ani:AddSlider("Max Distance", {Min=50,Max=1000,Default=300,Suffix="m"}, function(v) CFG.animMaxDist=v end)
Ani:AddColorPicker("Box Color", Color3.fromRGB(255,50,50), function(c) CFG.animBoxColor=c end)

Items:AddToggle("Enable",    false, function(v) CFG.itemEnable=v    end)
Items:AddToggle("Box",       true,  function(v) CFG.itemBox=v       end)
Items:AddToggle("Name",      true,  function(v) CFG.itemName=v      end)
Items:AddToggle("Distance",  true,  function(v) CFG.itemDistance=v  end)
Items:AddToggle("Traceline", false, function(v) CFG.itemTraceline=v end)
Items:AddSlider("Max Distance", {Min=50,Max=1000,Default=300,Suffix="m"}, function(v) CFG.itemMaxDist=v end)
Items:AddColorPicker("Box Color", Color3.fromRGB(80,200,120), function(c) CFG.itemBoxColor=c end)

World:AddToggle("Coins Enable",    false, function(v) CFG.coinEnable=v    end)
World:AddToggle("Coins Box",       true,  function(v) CFG.coinBox=v       end)
World:AddToggle("Coins Name",      true,  function(v) CFG.coinName=v      end)
World:AddToggle("Coins Distance",  true,  function(v) CFG.coinDistance=v  end)
World:AddToggle("Coins Traceline", false, function(v) CFG.coinTraceline=v end)
World:AddSlider("Coins Max Dist",  {Min=50,Max=1000,Default=300,Suffix="m"}, function(v) CFG.coinMaxDist=v end)
World:AddColorPicker("Coin Color", Color3.fromRGB(255,215,0), function(c) CFG.coinBoxColor=c end)
World:AddSeparator()
World:AddToggle("Chests Enable",    false, function(v) CFG.chestEnable=v    end)
World:AddToggle("Chests Box",       true,  function(v) CFG.chestBox=v       end)
World:AddToggle("Chests Name",      true,  function(v) CFG.chestName=v      end)
World:AddToggle("Chests Distance",  true,  function(v) CFG.chestDistance=v  end)
World:AddToggle("Chests Traceline", false, function(v) CFG.chestTraceline=v end)
World:AddSlider("Chests Max Dist",  {Min=50,Max=1000,Default=300,Suffix="m"}, function(v) CFG.chestMaxDist=v end)
World:AddColorPicker("Chest Color", Color3.fromRGB(200,140,50), function(c) CFG.chestBoxColor=c end)

local ThemeNames = {"Dracula","Fatality","Gamesense","TokyoNight"}
local Set = Settings:AddSection("MENU", 1)
Set:AddDropdown("Theme", ThemeNames, "Fatality", function(v) Hub:SetTheme(v) end)
Set:AddToggle("Watermark", true, function(v) wm:SetVisible(v) end)
local menuKeyRef = Set:AddKeybind("Menu Key", 0x70, "Hold", function(v) end)

-- Watch for keybind changes and sync to Hub.MenuKey
task.spawn(function()
    local last = 0x70
    while Hub._running do
        local cur = menuKeyRef:Get()
        if cur ~= last and cur ~= 0 then
            Hub.MenuKey = cur
            last = cur
        end
        task.wait(0.1)
    end
end)
Set:AddDropdown("ESP FPS", {"30","60","120","144","240"}, "30", function(v)
    CFG.renderWait = 1 / tonumber(v)
end)

local Cfg = Settings:AddSection("CONFIG", 2)
Cfg:AddTextbox("Config Name", "default", function(v) end, "config name")
Cfg:AddButton("Save Config", function()
    local name="default"
    for _,w in ipairs(Settings._sections[2]._widgets) do
        if w.type=="textbox" then name=w.value~="" and w.value or "default"; break end
    end
    Hub:SaveConfig(name)
end)
Cfg:AddButton("Load Config", function()
    local name="default"
    for _,w in ipairs(Settings._sections[2]._widgets) do
        if w.type=="textbox" then name=w.value~="" and w.value or "default"; break end
    end
    Hub:LoadConfig(name)
end)

local Inf = Settings:AddSection("INFO", 3)
Inf:AddLabel("ShadowHub")
Inf:AddLabel("by "..ShadowHub._author)
Inf:AddSeparator()
Inf:AddLabel("Player: "..player.Name)
Inf:AddLabel("PlaceId: "..tostring(game.PlaceId))
Inf:AddSeparator()
Inf:AddButton("Destroy", function()
    CFG.animEnable=false; CFG.itemEnable=false
    CFG.coinEnable=false; CFG.chestEnable=false

    local toRemove={}
    for inst in pairs(espObjects) do toRemove[#toRemove+1]=inst end
    for _,inst in ipairs(toRemove) do destroyESP(inst) end

    -- Re-enable roblox input before destroying
    pcall(setrobloxinput, true)

    Hub:Destroy()
    wm:Destroy()
end)

print("Eternal Nights ESP loaded")
