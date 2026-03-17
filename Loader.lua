-- =============================================
--         ShadowLua Loader
--         Red particles + dark theme + Solid Blinking Eye
-- =============================================

local GAMES_URL        = "https://raw.githubusercontent.com/ShadowLuaMatcha/ShadowHub/refs/heads/main/GameID.lua"

local LOADER_TITLE     = "ShadowLua"
local LOADER_SUBTITLE  = "Loading..."
local BAR_DURATION     = 5
local INITIAL_WAIT     = 0.5
local RESULT_HOLD_TIME = 2
local ANIM_DELAY       = 0.016

-- Shadow palette
local C_PANEL   = Color3.fromRGB(16,  16,  20)
local C_SURFACE = Color3.fromRGB(26,  26,  32)
local C_BORDER  = Color3.fromRGB(55,  55,  65)
local C_ACCENT  = Color3.fromRGB(210, 22,  22)
local C_OK      = Color3.fromRGB(48,  209, 88)
local C_FAIL    = Color3.fromRGB(255, 69,  58)
local C_TEXT    = Color3.fromRGB(240, 240, 240)
local C_SUB     = Color3.fromRGB(130, 130, 138)
local C_BLACK   = Color3.new(0, 0, 0)
local C_WHITE   = Color3.new(1, 1, 1)

-- =============================================
-- HELPERS
-- =============================================
local function lerp(a, b, t)   return a + (b-a)*t end
local function clamp(x, a, b)  return x > b and b or (x < a and a or x) end
local function lerpColor(c1, c2, t)
    return Color3.new(lerp(c1.R,c2.R,t), lerp(c1.G,c2.G,t), lerp(c1.B,c2.B,t))
end
local function easeOutExpo(t)  return t == 0 and 0 or 1 - 2^(-10*t) end
local function easeInExpo(t)   return t == 0 and 0 or 2^(10*t-10) end
local function easeOutBack(t)
    local c1 = 1.70158; local c3 = c1+1
    return 1 + c3*(t-1)^3 + c1*(t-1)^2
end
local function easeOutQuad(t) return 1-(1-t)*(1-t) end
local function easeInQuad(t)  return t*t end

local function getScreen()
    local cam = workspace.CurrentCamera
    return (cam and cam.ViewportSize) and cam.ViewportSize or Vector2.new(1920, 1080)
end

local function newSquare(props)
    local d = Drawing.new("Square")
    d.Filled = true; d.Visible = false
    for k, v in pairs(props or {}) do d[k] = v end
    return d
end
local function newText(props)
    local d = Drawing.new("Text")
    d.Visible = false; d.Outline = false; d.Font = Drawing.Fonts.SystemBold
    for k, v in pairs(props or {}) do d[k] = v end
    return d
end
local function newCircle(props)
    local d = Drawing.new("Circle")
    d.Filled = true; d.Visible = false
    for k, v in pairs(props or {}) do d[k] = v end
    return d
end

-- =============================================
-- FETCH GAME LIST
-- =============================================
ShadowLuaGames = nil
pcall(function()
    local urlBypass = GAMES_URL .. "?t=" .. tostring(os.time())
    local raw = game:HttpGet(urlBypass)
    local fn  = loadstring(raw)
    if fn then fn() end
end)
local SupportedGames = ShadowLuaGames or {}

-- =============================================
-- SETUP
-- =============================================
task.wait(INITIAL_WAIT)

local screen = getScreen()
local sw, sh  = screen.X, screen.Y
local cx, cy  = sw/2, sh/2

local PW, PH, CR = 400, 152, 12
local BAR_W, BAR_H = PW - 52, 4

-- Variáveis globais para o olho saber onde piscar
local g_iconCX, g_iconCY, g_scale = 0, 0, 1

-- =============================================
-- PARTICLES SETUP
-- =============================================
local PARTICLE_COUNT = 55
math.randomseed(42)

local pData = {}
local pCircles = {}

local colorPool = {
    Color3.fromRGB(210, 22,  22),   -- blood red
    Color3.fromRGB(180, 10,  10),   -- dark red
    Color3.fromRGB(240, 40,  40),   -- bright red
    Color3.fromRGB(120, 8,   8),    -- deep crimson
    Color3.fromRGB(255, 80,  80),   -- light red
    Color3.fromRGB(90,  0,   0),    -- near black red
    Color3.fromRGB(200, 200, 200),  -- white (few)
}

for i = 1, PARTICLE_COUNT do
    local zone = math.random(1, 4)
    local px, py
    if zone == 1 then px = math.random(10, sw * 0.3); py = math.random(10, sh - 10)
    elseif zone == 2 then px = math.random(sw * 0.7, sw - 10); py = math.random(10, sh - 10)
    elseif zone == 3 then px = math.random(10, sw - 10); py = math.random(10, sh * 0.3)
    else px = math.random(10, sw - 10); py = math.random(sh * 0.7, sh - 10) end

    local r       = 2 + math.random() * 9
    local baseTr  = 0.35 + math.random() * 0.55
    local col     = colorPool[math.random(1, #colorPool)]
    local driftAngle = math.random() * math.pi * 2
    local driftSpeed = 8 + math.random() * 18
    local pulsePhase = math.random() * math.pi * 2
    local pulseSpeed = 0.6 + math.random() * 1.2

    pData[i] = { x = px, y = py, r = r, baseTr = baseTr, col = col, driftAngle = driftAngle, driftSpeed = driftSpeed, pulsePhase = pulsePhase, pulseSpeed = pulseSpeed }
    pCircles[i] = newCircle({ Color = col, Radius = r, Transparency = 1, ZIndex = 91, NumSides = 16, Position = Vector2.new(px, py), Visible = false })
end

-- =============================================
-- UI DRAWINGS
-- =============================================
local overlay = newSquare({ Color=C_BLACK, Position=Vector2.new(0,0), Size=Vector2.new(sw,sh), Transparency=0, ZIndex=90, Visible=true })
local shadows = {}
for i = 1, 3 do shadows[i] = newSquare({ Color = i == 1 and Color3.fromRGB(90,0,0) or C_BLACK, Transparency = 0, ZIndex = 92, Corner = CR + i*2 }) end

local panel         = newSquare({ Color=C_PANEL, Transparency=0, ZIndex=93, Corner=CR })
local panelAccent   = newSquare({ Color=C_ACCENT, Transparency=0, ZIndex=95 })
local panelBorder   = Drawing.new("Square")
panelBorder.Filled=false; panelBorder.Color=C_BORDER; panelBorder.Thickness=1; panelBorder.Transparency=0; panelBorder.ZIndex=94; panelBorder.Corner=CR; panelBorder.Visible=false

local titleBar    = newSquare({ Color=C_SURFACE, Transparency=0, ZIndex=94, Corner=CR })
local titleBarFix = newSquare({ Color=C_SURFACE, Transparency=0, ZIndex=94 })

local iconBg     = newCircle({ Color=C_ACCENT, Radius=14, ZIndex=95, NumSides=32 })
local iconPupil  = newCircle({ Color=C_PANEL,  Radius=6,  ZIndex=96, NumSides=32 })
local iconSlit   = newSquare({ Color=C_BLACK,  ZIndex=97, Corner=1 })
local iconEyelid = newSquare({ Color=C_PANEL,  ZIndex=98 }) -- A pálpebra do olho (mesma cor do fundo)

local titleDraw  = newText({ Text=LOADER_TITLE, Color=C_TEXT, Size=15, Transparency=0, ZIndex=96 })
local statusDraw = newText({ Text=LOADER_SUBTITLE, Color=C_SUB, Size=12, Transparency=0, ZIndex=96 })
local barBg      = newSquare({ Color=C_SURFACE, Transparency=0, ZIndex=95, Corner=2 })
local barFill    = newSquare({ Color=C_ACCENT, Transparency=0, ZIndex=96, Corner=2 })

local function layout(scale, opacity)
    local w, h   = PW*scale, PH*scale
    local px, py = cx - w/2, cy - h/2

    for i, s in ipairs(shadows) do
        local off  = i * 5 * scale
        local glow = i == 1 and 0.65 or (0.45 - (i-1)*0.12)
        s.Position     = Vector2.new(px - off/2, py + off * 0.5)
        s.Size         = Vector2.new(w + off, h + off * 0.2)
        s.Transparency = opacity * glow
        s.Visible      = opacity > 0.05
    end

    panel.Position, panel.Size, panel.Transparency, panel.Visible = Vector2.new(px, py), Vector2.new(w, h), opacity, opacity > 0.05
    panelBorder.Position, panelBorder.Size, panelBorder.Transparency, panelBorder.Visible = Vector2.new(px, py), Vector2.new(w, h), opacity * 0.7, opacity > 0.05

    local tbH = 32 * scale
    titleBar.Position, titleBar.Size, titleBar.Transparency, titleBar.Visible = Vector2.new(px, py), Vector2.new(w, tbH), opacity, opacity > 0.05
    titleBarFix.Position, titleBarFix.Size, titleBarFix.Transparency, titleBarFix.Visible = Vector2.new(px, py + tbH - CR*scale), Vector2.new(w, CR*scale), opacity, opacity > 0.05

    panelAccent.Position     = Vector2.new(px, py + tbH)
    panelAccent.Size         = Vector2.new(w, 2)
    panelAccent.Transparency = opacity
    panelAccent.Visible      = opacity > 0.05

    titleDraw.Position, titleDraw.Transparency, titleDraw.Visible = Vector2.new(px + w/2 - 40*scale, py + tbH/2 - 7), opacity, opacity > 0.05

    -- Posição do olho salva nas variáveis globais
    g_iconCX = px + 20*scale + 14*scale
    g_iconCY = py + tbH + 16*scale + 14*scale
    g_scale = scale

    iconBg.Position, iconBg.Radius, iconBg.Transparency, iconBg.Visible = Vector2.new(g_iconCX, g_iconCY), 14 * scale, opacity, opacity > 0.05
    iconPupil.Position, iconPupil.Radius, iconPupil.Transparency, iconPupil.Visible = Vector2.new(g_iconCX, g_iconCY), 6 * scale, opacity, opacity > 0.05
    iconSlit.Position, iconSlit.Size, iconSlit.Transparency, iconSlit.Visible = Vector2.new(g_iconCX - 1.5*scale, g_iconCY - 8*scale), Vector2.new(3*scale, 16*scale), opacity, opacity > 0.05

    local barY, barX, bw = py + h - 26 * scale, px + 24 * scale, BAR_W * scale
    statusDraw.Position, statusDraw.Transparency, statusDraw.Visible = Vector2.new(barX, barY - 16*scale), opacity, opacity > 0.05
    barBg.Position, barBg.Size, barBg.Transparency, barBg.Visible = Vector2.new(barX, barY), Vector2.new(bw, BAR_H*scale), opacity, opacity > 0.05
    barFill.Position, barFill.Size, barFill.Transparency, barFill.Visible = Vector2.new(barX, barY), Vector2.new(barFill.Size.X, BAR_H*scale), opacity, opacity > 0.05
end

-- =============================================
-- ANIMATION / UPDATE FUNCTION
-- =============================================
local function updateAnimations(t, overlayAlpha)
    -- 1. Partículas
    local show = overlayAlpha > 0.05
    for i, p in ipairs(pCircles) do
        local pd = pData[i]
        pd.x = pd.x + math.cos(pd.driftAngle) * pd.driftSpeed * 0.016
        pd.y = pd.y + math.sin(pd.driftAngle) * pd.driftSpeed * 0.016

        if pd.x < -20 then pd.x = sw + 10 end
        if pd.x > sw+20 then pd.x = -10 end
        if pd.y < -20 then pd.y = sh + 10 end
        if pd.y > sh+20 then pd.y = -10 end

        local pulse = math.sin(t * pd.pulseSpeed + pd.pulsePhase) * 0.18
        p.Position = Vector2.new(pd.x, pd.y)
        p.Transparency = lerp(1, clamp(pd.baseTr + pulse, 0, 1), overlayAlpha)
        p.Visible = show
    end

    -- 2. Lógica da pálpebra corrigida (100% Sólida)
    local blinkCycle = t % 4.0
    local blinkFactor = 0
    if blinkCycle > 3.7 then
        blinkFactor = math.sin(((blinkCycle - 3.7) / 0.3) * math.pi)
        blinkFactor = clamp(blinkFactor, 0, 1)
    end

    if iconEyelid and g_scale > 0 then
        local eyeDiameter = 28 * g_scale
        iconEyelid.Position = Vector2.new(g_iconCX - eyeDiameter/2, g_iconCY - eyeDiameter/2)
        iconEyelid.Size = Vector2.new(eyeDiameter, eyeDiameter * blinkFactor)
        
        -- Agora a pálpebra copia a transparência do painel! (100% sólido quando visível)
        iconEyelid.Transparency = panel.Transparency
        iconEyelid.Visible = panel.Visible and (blinkFactor > 0.01)
    end
end

-- =============================================
-- PHASE 1: Fade in
-- =============================================
local STEPS_FADE  = 22
local STEPS_PANEL = 28
local STEPS_CLOSE = 28
local t0 = os.clock()

overlay.Visible = true
for i = 1, STEPS_FADE do
    local ft = i / STEPS_FADE
    overlay.Transparency = lerp(0, 0.75, easeOutQuad(ft))
    updateAnimations(os.clock() - t0, 1 - overlay.Transparency)
    layout(0, 0)
    task.wait(ANIM_DELAY)
end
overlay.Transparency = 0.75

-- =============================================
-- PHASE 2: Panel enters
-- =============================================
for i = 1, STEPS_PANEL do
    local t = i / STEPS_PANEL
    layout(easeOutBack(t), easeOutQuad(t))
    updateAnimations(os.clock() - t0, 0.25)
    task.wait(ANIM_DELAY)
end
layout(1, 1)
barFill.Size = Vector2.new(0, BAR_H)

-- =============================================
-- PHASE 3: Bar loading
-- =============================================
local currentId, foundScript = tostring(game.PlaceId), nil
for _, gameData in ipairs(SupportedGames) do
    for _, id in ipairs(gameData.ids) do
        if tostring(id) == currentId then foundScript = gameData.script; break end
    end
    if foundScript then break end
end

local elapsed = 0
local dt = 0.033

while elapsed < BAR_DURATION do
    elapsed = elapsed + dt
    local progress = clamp(elapsed / BAR_DURATION, 0, 1)

    updateAnimations(os.clock() - t0, 0.25)

    if progress > 0.85 then
        local t2 = (progress - 0.85) / 0.15
        if foundScript then
            barFill.Color = lerpColor(C_ACCENT, C_OK, t2)
            iconBg.Color  = lerpColor(C_ACCENT, C_OK, t2)
        else
            barFill.Color = lerpColor(C_ACCENT, C_WHITE, t2)
            iconBg.Color  = lerpColor(C_ACCENT, C_WHITE, t2)
        end
    end

    barFill.Size = Vector2.new(BAR_W * progress, BAR_H)
    task.wait(dt)
end
barFill.Size = Vector2.new(BAR_W, BAR_H)

-- =============================================
-- PHASE 4: Result
-- =============================================
if foundScript then
    statusDraw.Text    = "Game Found!"
    statusDraw.Color   = C_OK
    panelAccent.Color  = C_OK
    panelBorder.Color  = C_OK
    iconBg.Color       = C_OK
    barFill.Color      = C_OK
    titleDraw.Color    = C_OK
else
    statusDraw.Text    = "Game Not Found"
    statusDraw.Color   = C_WHITE
    panelAccent.Color  = C_WHITE
    panelBorder.Color  = C_WHITE
    iconBg.Color       = C_WHITE
    iconPupil.Color    = Color3.fromRGB(10,10,13)
    iconSlit.Color     = Color3.fromRGB(10,10,13)
    barFill.Color      = C_WHITE
    titleDraw.Color    = C_WHITE
end

local resultElapsed = 0
while resultElapsed < RESULT_HOLD_TIME do
    resultElapsed = resultElapsed + dt
    updateAnimations(os.clock() - t0, 0.25)
    task.wait(dt)
end

-- =============================================
-- PHASE 5: Panel exits
-- =============================================
for i = 1, STEPS_CLOSE do
    local ease = easeInExpo(i / STEPS_CLOSE)
    layout(1 - ease * 0.15, 1 - ease)
    updateAnimations(os.clock() - t0, 0.25)
    task.wait(ANIM_DELAY)
end
layout(0, 0)

for _, s in ipairs(shadows) do s.Visible = false end
panel.Visible=false; panelBorder.Visible=false
titleBar.Visible=false; titleBarFix.Visible=false; panelAccent.Visible=false
iconBg.Visible=false; iconPupil.Visible=false; iconSlit.Visible=false; iconEyelid.Visible=false
titleDraw.Visible=false; statusDraw.Visible=false
barBg.Visible=false; barFill.Visible=false

-- =============================================
-- PHASE 6: Fade out overlay
-- =============================================
for i = 1, STEPS_FADE do
    local ft = i / STEPS_FADE
    overlay.Transparency = lerp(0.75, 0, easeInExpo(ft))
    for _, p in ipairs(pCircles) do
        p.Transparency = lerp(p.Transparency, 1, ft * 0.15)
        p.Visible = (1 - ft) > 0.05
    end
    task.wait(ANIM_DELAY)
end

overlay.Transparency = 0
overlay.Visible      = false
for _, p in ipairs(pCircles) do p.Visible = false end

-- =============================================
-- CLEANUP
-- =============================================
overlay:Remove()
for _, s in ipairs(shadows) do s:Remove() end
panel:Remove(); panelBorder:Remove()
titleBar:Remove(); titleBarFix:Remove(); panelAccent:Remove()
iconBg:Remove(); iconPupil:Remove(); iconSlit:Remove(); iconEyelid:Remove()
titleDraw:Remove(); statusDraw:Remove()
barBg:Remove(); barFill:Remove()
for _, p in ipairs(pCircles) do p:Remove() end

-- =============================================
-- EXECUTE GAME SCRIPT
-- =============================================
if foundScript then 
    local ok, execErr = pcall(function()
        loadstring(foundScript)()
    end)
    if not ok then
        warn("[ShadowLua] Error loading game script: ", execErr)
    end
end
