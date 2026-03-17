local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ShadowHub   = {}
ShadowHub._version = ""
ShadowHub._author  = "SeRh1O"

local function clamp(x,a,b)   return x<a and a or (x>b and b or x) end
local function lerp(a,b,t)    return a+(b-a)*t end
local function lerpC(c1,c2,t) return Color3.new(lerp(c1.R,c2.R,t),lerp(c1.G,c2.G,t),lerp(c1.B,c2.B,t)) end
local function easeOut(t)     return 1-(1-clamp(t,0,1))^3 end
local function textW(s,sz)    return #(s or "")*(sz or 13)*0.58 end

local function safeWait(t)
    local t0=os.clock(); task.wait(t or 0.016); return os.clock()-t0
end

local function mpos()
    local ok,p=pcall(function() return game:GetService("UserInputService"):GetMouseLocation() end)
    return ok and p or Vector2.new(LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y)
end
local function over(pos,size)
    local m=mpos()
    return m.X>=pos.X and m.X<=pos.X+size.X and m.Y>=pos.Y and m.Y<=pos.Y+size.Y
end

local function rgbToHsv(c)
    local r,g,b=c.R,c.G,c.B
    local max=math.max(r,g,b); local min=math.min(r,g,b)
    local h,s,v=0,0,max; local d=max-min
    if max~=0 then s=d/max end
    if d~=0 then
        if max==r then h=(g-b)/d; if g<b then h=h+6 end
        elseif max==g then h=(b-r)/d+2
        else h=(r-g)/d+4 end
        h=h/6
    end
    return h,s,v
end
local function hsvToRgb(h,s,v) return Color3.fromHSV(clamp(h,0,1),clamp(s,0,1),clamp(v,0,1)) end

local function getScreen()
    local cam=workspace.CurrentCamera
    return (cam and cam.ViewportSize) and cam.ViewportSize or Vector2.new(1920,1080)
end

local function safeWrite(path, data)
    local ok,err=pcall(function()
        pcall(makefolder, path:match("^(.+)/[^/]+$") or "")
        writefile(path, data)
    end)
    return ok, err
end
local function safeRead(path)
    local ok,data=pcall(readfile, path)
    if ok and type(data)=="string" and data~="" then return true,data end
    return false, nil
end
local function safeJson(t)
    local ok,r=pcall(function() return game:GetService("HttpService"):JSONEncode(t) end)
    return ok and r or nil
end
local function safeJsonDecode(s)
    local ok,r=pcall(function() return game:GetService("HttpService"):JSONDecode(s) end)
    return ok and r or nil
end

local Themes={
    Fatality={
        Background=Color3.fromRGB(15,14,22), Surface=Color3.fromRGB(22,21,32),
        Surface2=Color3.fromRGB(28,27,40),   Border=Color3.fromRGB(38,37,55),
        BorderDark=Color3.fromRGB(10,10,15), Accent=Color3.fromRGB(215,30,50),
        Text=Color3.fromRGB(240,240,240),    TextMuted=Color3.fromRGB(110,110,130),
        Widget=Color3.fromRGB(18,17,26),     TopBar=Color3.fromRGB(12,11,18),
    },
    Dracula={
        Background=Color3.fromRGB(40,42,54), Surface=Color3.fromRGB(52,55,70),
        Surface2=Color3.fromRGB(58,62,80),   Border=Color3.fromRGB(68,71,90),
        BorderDark=Color3.fromRGB(30,32,44), Accent=Color3.fromRGB(189,147,249),
        Text=Color3.fromRGB(248,248,242),    TextMuted=Color3.fromRGB(98,114,164),
        Widget=Color3.fromRGB(44,47,65),     TopBar=Color3.fromRGB(32,34,48),
    },
    TokyoNight={
        Background=Color3.fromRGB(26,27,38), Surface=Color3.fromRGB(36,40,59),
        Surface2=Color3.fromRGB(42,46,68),   Border=Color3.fromRGB(65,72,104),
        BorderDark=Color3.fromRGB(20,22,35), Accent=Color3.fromRGB(122,162,247),
        Text=Color3.fromRGB(192,202,245),    TextMuted=Color3.fromRGB(86,95,137),
        Widget=Color3.fromRGB(30,33,55),     TopBar=Color3.fromRGB(20,21,32),
    },
    Gamesense={
        Background=Color3.fromRGB(0,0,0),    Surface=Color3.fromRGB(20,20,20),
        Surface2=Color3.fromRGB(28,28,28),   Border=Color3.fromRGB(45,45,45),
        BorderDark=Color3.fromRGB(8,8,8),    Accent=Color3.fromRGB(114,178,21),
        Text=Color3.fromRGB(180,180,180),    TextMuted=Color3.fromRGB(80,80,80),
        Widget=Color3.fromRGB(15,15,15),     TopBar=Color3.fromRGB(5,5,5),
    },
}
local ThemeNames={}
for k in pairs(Themes) do ThemeNames[#ThemeNames+1]=k end
table.sort(ThemeNames)

local Input={_prev={},click=false,held=false,_scrollDelta=0,_prevScroll=0}
function Input:update()
    local m1=ismouse1pressed()
    self.click=m1 and not(self._prev.m1 or false)
    self.held=m1; self._prev.m1=m1

    local sc=0
    local ok1,up=pcall(iskeypressed,0x26)  
    local ok2,dn=pcall(iskeypressed,0x28)  
    self._scrollUp   = (ok1 and up)  and not (self._prev.scUp or false)
    self._scrollDown = (ok2 and dn) and not (self._prev.scDn or false)
    self._prev.scUp=ok1 and up; self._prev.scDn=ok2 and dn
end
function Input:keyClick(kc)
    local cur=iskeypressed(kc); local prv=self._prev[kc] or false
    self._prev[kc]=cur; return cur and not prv
end
function Input:scrollingUp()   return iskeypressed(0x26) end
function Input:scrollingDown() return iskeypressed(0x28) end

local KeyNames={
    [0x08]="BACK",[0x0D]="ENT",[0x10]="SHFT",[0x11]="CTRL",
    [0x12]="ALT",[0x20]="SPC",[0x1B]="ESC",[0x2E]="DEL",
}
for i=65,90 do KeyNames[i]=string.char(i) end
for i=1,12 do KeyNames[0x6F+i]="F"..i end
for i=0,9  do KeyNames[0x30+i]=tostring(i) end

local KeyNamesCapture={[0x01]="M1",[0x02]="M2"}
for k,v in pairs(KeyNames) do KeyNamesCapture[k]=v end

local _notifList={}
function ShadowHub:Notify(title,text,duration,T)
    T=T or Themes.Fatality; duration=duration or 4
    task.spawn(function()
        local NW,NH=220,58; local id={}
        local dO=Drawing.new("Square"); local dB=Drawing.new("Square")
        local dA=Drawing.new("Square"); local dTi=Drawing.new("Text")
        local dTx=Drawing.new("Text");  local dBB=Drawing.new("Square")
        local dBr=Drawing.new("Square")

        dO.Filled=true;  dO.Corner=5; dO.ZIndex=2000; dO.Color=T.Accent;  dO.Visible=false
        dB.Filled=true;  dB.Corner=5; dB.ZIndex=2001; dB.Color=T.Surface; dB.Visible=false
        dA.Filled=true;               dA.ZIndex=2002; dA.Color=T.Accent;  dA.Visible=false
        dBB.Filled=true;              dBB.ZIndex=2002; dBB.Color=T.Border; dBB.Visible=false
        dBr.Filled=true;              dBr.ZIndex=2003; dBr.Color=T.Accent; dBr.Visible=false
        dTi.Font=Drawing.Fonts.SystemBold; dTi.Size=13; dTi.ZIndex=2003; dTi.Color=T.Accent
        dTi.Outline=true; dTi.Visible=false; dTi.Text=title
        dTx.Font=Drawing.Fonts.System; dTx.Size=12; dTx.ZIndex=2003; dTx.Color=T.Text
        dTx.Outline=true; dTx.Visible=false
        local wr=""; for i=1,#text do wr=wr..text:sub(i,i); if i%34==0 then wr=wr.."\n" end end
        dTx.Text=wr

        table.insert(_notifList,{id=id})
        local elapsed=0; local scr=getScreen()

        local function setPos(sl,ty)
            dO.Size=Vector2.new(NW+2,NH+2); dO.Position=Vector2.new(sl-1,ty-1)
            dB.Size=Vector2.new(NW,NH);     dB.Position=Vector2.new(sl,ty)
            dA.Size=Vector2.new(3,NH);      dA.Position=Vector2.new(sl,ty)
            dTi.Position=Vector2.new(sl+10,ty+6)
            dTx.Position=Vector2.new(sl+10,ty+22)
            dBB.Size=Vector2.new(NW-12,2);  dBB.Position=Vector2.new(sl+6,ty+NH-7)
            dBr.Position=Vector2.new(sl+6,ty+NH-7)
            dO.Visible=true; dB.Visible=true; dA.Visible=true
            dTi.Visible=true; dTx.Visible=true; dBB.Visible=true; dBr.Visible=true
        end

        while elapsed<duration do
            local dt=safeWait(0.016); elapsed=elapsed+dt
            local sl=lerp(scr.X+NW+10, scr.X-NW-12, easeOut(clamp(elapsed/0.35,0,1)))
            local idx=0; for i,v in ipairs(_notifList) do if v.id==id then idx=i; break end end
            setPos(sl, scr.Y-68-((idx-1)*(NH+6)))
            dBr.Size=Vector2.new((NW-12)*(1-clamp(elapsed/duration,0,1)),2)
        end

        local t2=0
        while t2<0.25 do
            local dt=safeWait(0.016); t2=t2+dt
            local sl=lerp(scr.X-NW-12, scr.X+NW+10, easeOut(clamp(t2/0.25,0,1)))
            local idx=0; for i,v in ipairs(_notifList) do if v.id==id then idx=i; break end end
            setPos(sl, scr.Y-68-((idx-1)*(NH+6)))
        end

        for i,v in ipairs(_notifList) do if v.id==id then table.remove(_notifList,i); break end end
        dO:Remove(); dB:Remove(); dA:Remove(); dTi:Remove(); dTx:Remove(); dBB:Remove(); dBr:Remove()
    end)
end

function ShadowHub:CreateWatermark(text, T)
    T = T or Themes.Fatality
    local dB=Drawing.new("Square"); local dA=Drawing.new("Square")
    local dT=Drawing.new("Text");   local dTm=Drawing.new("Text")
    dB.Filled=true;  dB.ZIndex=200; dB.Corner=4; dB.Color=T.Surface; dB.Visible=false
    dA.Filled=true;  dA.ZIndex=201; dA.Color=T.Accent; dA.Visible=false
    dT.Font=Drawing.Fonts.SystemBold; dT.Size=13; dT.ZIndex=202
    dT.Color=T.Accent; dT.Outline=true; dT.Text=text; dT.Visible=false
    dTm.Font=Drawing.Fonts.System; dTm.Size=11; dTm.ZIndex=202
    dTm.Color=T.TextMuted; dTm.Outline=true; dTm.Visible=false

    local wm={_r=true, _visible=true, _T=T}
    task.spawn(function()
        while wm._r do
            local show=wm._visible
            local scr=getScreen(); local tw=textW(text,13)+80
            local CT=wm._T 
            dB.Color=CT.Surface; dA.Color=CT.Accent; dT.Color=CT.Accent; dTm.Color=CT.TextMuted
            dB.Size=Vector2.new(tw,22);  dB.Position=Vector2.new(scr.X-tw-10,10)
            dA.Size=Vector2.new(tw,2);   dA.Position=Vector2.new(scr.X-tw-10,32)
            dT.Position=Vector2.new(scr.X-tw-6,14)
            local ts=os.date("%H:%M:%S"); dTm.Text=ts
            dTm.Position=Vector2.new(scr.X-textW(ts,11)-14,15)
            dB.Visible=show; dA.Visible=show; dT.Visible=show; dTm.Visible=show
            safeWait(0.5)
        end
        dB:Remove(); dA:Remove(); dT:Remove(); dTm:Remove()
    end)
    function wm:SetVisible(v) self._visible=v end
    function wm:SetTheme(nt) self._T=nt end 
    function wm:Destroy() self._r=false end
    return wm
end

function ShadowHub:CreateWindow(opts)
    opts=opts or {}
    local T=Themes[opts.Theme or "Fatality"] or Themes.Fatality
    local FF=Drawing.Fonts.System
    local FB=Drawing.Fonts.SystemBold

    local WIN={
        Title=opts.Title or "SHADOWHUB",
        Size=opts.Size or Vector2.new(860,520),
        MenuKey=opts.MenuKey or 0x70,
        _pos=opts.Pos or Vector2.new(160,120),
        _open=true, _running=true, _T=T,
        _drawings={}, _seen={},
        _tabs={}, _openTab=nil,
        _permTab=nil, _openPermTab=false,
        _drag=nil, _sliderDrag=nil, _activePop=nil,
        _tooltip=nil, _ttTimer=nil,
        _scUp=0, _scDn=0, _scLu=0, _scLd=0,
        _tabClickTime=0,
        _wmRef=nil, 
    }

    function WIN:_Draw(id,dtype,props)
        self._seen[id]=true
        local d=self._drawings[id]
        if not d then d=Drawing.new(dtype); self._drawings[id]=d end
        for k,v in pairs(props) do d[k]=v end
        if dtype=="Text" then d.Outline=true end
        d.Visible=true; return d
    end
    function WIN:_BeginFrame() self._seen={} end
    function WIN:_Flush()
        for id,d in pairs(self._drawings) do if not self._seen[id] then d.Visible=false end end
    end

    function WIN:SetTheme(name)
        local nt=Themes[name]; if not nt then return end
        self._T=nt; T=nt
        if self._wmRef then self._wmRef:SetTheme(nt) end
    end

    function WIN:_collectConfig()
        local data={}
        local allTabs={table.unpack(self._tabs)}
        if self._permTab then table.insert(allTabs, self._permTab) end
        for _,tab in ipairs(allTabs) do
            data[tab._name]={}
            for _,sec in ipairs(tab._sections) do
                data[tab._name][sec._name]={}
                for _,w in ipairs(sec._widgets) do
                    if w.type=="toggle" then
                        data[tab._name][sec._name][w.label]={type="toggle",value=w.value}
                    elseif w.type=="slider" then
                        data[tab._name][sec._name][w.label]={type="slider",value=w.value}
                    elseif w.type=="dropdown" then
                        data[tab._name][sec._name][w.label]={type="dropdown",value=w.value}
                    elseif w.type=="multi" then
                        local sel={}
                        for _,o in ipairs(w.options) do if w.selected[o] then sel[#sel+1]=o end end
                        data[tab._name][sec._name][w.label]={type="multi",value=sel}
                    elseif w.type=="color" then
                        data[tab._name][sec._name][w.label]={type="color",r=w.value.R,g=w.value.G,b=w.value.B}
                    elseif w.type=="keybind" then
                        data[tab._name][sec._name][w.label]={type="keybind",value=w.value}
                    elseif w.type=="textbox" then
                        data[tab._name][sec._name][w.label]={type="textbox",value=w.value}
                    end
                end
            end
        end
        return data
    end

    function WIN:SaveConfig(name)
        name=name or "default"
        local data=self:_collectConfig()
        local json=safeJson(data)
        if not json then self:Notify("Failed to encode config.","Config",3); return end
        local ok=safeWrite("ShadowHub/"..name..".json", json)
        if ok then self:Notify("Config saved!","Config",3)
        else self:Notify("Failed to save (no write access?).","Config",3) end
    end

    function WIN:LoadConfig(name)
        name=name or "default"
        local ok,content=safeRead("ShadowHub/"..name..".json")
        if not ok then self:Notify("No config found.","Config",3); return end
        local data=safeJsonDecode(content)
        if not data then self:Notify("Failed to parse config.","Config",3); return end
        local allTabs={table.unpack(self._tabs)}
        if self._permTab then table.insert(allTabs, self._permTab) end
        for _,tab in ipairs(allTabs) do
            local td=data[tab._name]; if type(td)~="table" then continue end
            for _,sec in ipairs(tab._sections) do
                local sd=td[sec._name]; if type(sd)~="table" then continue end
                for _,w in ipairs(sec._widgets) do
                    local wd=sd[w.label]; if not wd then continue end
                    pcall(function()
                        if w.type=="toggle" and wd.value~=nil then
                            w.value=wd.value; pcall(w.cb,w.value)
                        elseif w.type=="slider" and wd.value then
                            w.value=clamp(wd.value,w.min,w.max); pcall(w.cb,w.value)
                        elseif w.type=="dropdown" and wd.value then
                            w.value=wd.value; pcall(w.cb,w.value)
                        elseif w.type=="multi" and wd.value then
                            w.selected={}
                            for _,v in ipairs(wd.value) do w.selected[v]=true end
                            local out={}
                            for _,o in ipairs(w.options) do if w.selected[o] then out[#out+1]=o end end
                            pcall(w.cb,out)
                        elseif w.type=="color" and wd.r then
                            w.value=Color3.new(wd.r,wd.g,wd.b)
                            w.h,w.s,w.v=rgbToHsv(w.value); pcall(w.cb,w.value)
                        elseif w.type=="keybind" and wd.value then
                            w.value=wd.value
                        elseif w.type=="textbox" and wd.value then
                            w.value=wd.value; pcall(w.cb,w.value)
                        end
                    end)
                end
            end
        end
        self:Notify("Config loaded!","Config",3)
    end

    local function makeTab(name)
        local TAB={_name=name, _sections={}, scroll=0, maxScroll=0}
        function TAB:AddSection(sname,col)
            local SEC={_name=sname,_widgets={},_col=col or 1}
            local function reg(it) table.insert(SEC._widgets,it) end

            function SEC:AddToggle(lbl,def,cb,tip)
                local it={type="toggle",label=lbl,value=def or false,cb=cb or function()end,tip=tip,_db=0}
                reg(it)
                return{Get=function()return it.value end,Set=function(_,v)it.value=v;pcall(it.cb,v)end}
            end
            function SEC:AddSlider(lbl,o,cb)
                o=o or {}
                local it={type="slider",label=lbl,min=o.Min or 0,max=o.Max or 100,
                    value=o.Default or o.Min or 0,suffix=o.Suffix or "",cb=cb or function()end}
                reg(it)
                return{Get=function()return it.value end,
                    Set=function(_,v)it.value=clamp(v,it.min,it.max);pcall(it.cb,it.value)end}
            end
            function SEC:AddButton(lbl,cb,tip)
                reg({type="button",label=lbl,cb=cb or function()end,tip=tip,_db=0})
                return{}
            end
            function SEC:AddDropdown(lbl,opts2,def,cb)
                local it={type="dropdown",label=lbl,options=opts2 or {},
                    value=def or (opts2 and opts2[1]) or "",cb=cb or function()end,scroll=0}
                reg(it)
                return{Get=function()return it.value end,
                    Set=function(_,v)it.value=v;pcall(it.cb,v)end,
                    Refresh=function(_,o,d2)
                        it.options=o or{};it.value=d2 or(o and o[1]) or""
                        it.scroll=0;pcall(it.cb,it.value)
                    end}
            end
            function SEC:AddMultiDropdown(lbl,opts2,def,cb)
                local sel={}; if def then for _,v in ipairs(def) do sel[v]=true end end
                local it={type="multi",label=lbl,options=opts2 or {},
                    selected=sel,cb=cb or function()end,scroll=0}
                reg(it)
                local function gl()
                    local o={}
                    for _,v in ipairs(it.options) do if it.selected[v] then o[#o+1]=v end end
                    return o
                end
                return{Get=gl,
                    Set=function(_,t2)
                        it.selected={}
                        if t2 then for _,v in ipairs(t2) do it.selected[v]=true end end
                        pcall(it.cb,gl())
                    end}
            end
            function SEC:AddColorPicker(lbl,def,cb)
                local h,s,v2=0,1,1; if def then h,s,v2=rgbToHsv(def) end
                local it={type="color",label=lbl,value=def or Color3.new(1,0,0),
                    h=h,s=s,v=v2,cb=cb or function()end}
                reg(it)
                return{Get=function()return it.value end,
                    Set=function(_,c)it.value=c;it.h,it.s,it.v=rgbToHsv(c);pcall(it.cb,c)end}
            end
            function SEC:AddKeybind(lbl,def,mode,cb)
                local it={type="keybind",label=lbl,value=def or 0,mode=mode or "Toggle",
                    active=false,cb=cb or function()end,listening=false,
                    _waitRelease=false,_db=0,_prevHeld=false}
                reg(it)
                return{Get=function()return it.value end,
                    Set=function(_,v)it.value=v end,
                    IsActive=function()return it.active end}
            end
            function SEC:AddTextbox(lbl,def,cb,ph)
                local it={type="textbox",label=lbl,value=def or "",
                    cb=cb or function()end,ph=ph or "...",active=false,_db=0}
                reg(it)
                return{Get=function()return it.value end,
                    Set=function(_,v)it.value=v;pcall(it.cb,v)end}
            end
            function SEC:AddLabel(txt)
                local it={type="label",label=txt or ""}; reg(it)
                return{Set=function(_,v)it.label=v end}
            end
            function SEC:AddSeparator() reg({type="sep"}) end

            table.insert(TAB._sections,SEC); return SEC
        end
        return TAB
    end

    function WIN:AddTab(name)
        local tab=makeTab(name)
        table.insert(self._tabs,tab)
        if not self._openTab then self._openTab=tab end
        return tab
    end

    function WIN:AddPermTab(name)
        local tab=makeTab(name)
        self._permTab=tab
        return tab
    end

    function WIN:_W(item,id,x,y,w2)
        local T2=self._T
        local isPop=self._activePop~=nil
        local now=os.clock()
        local lc=Input.click and not isPop

        local function chkTip(pos,sz,tip)
            if not tip then return end
            if over(pos,sz) then
                if not self._ttTimer then self._ttTimer=now end
                if now-self._ttTimer>0.7 then
                    self._tooltip={text=tip,pos=mpos()+Vector2.new(8,-18)}
                end
            elseif self._ttTimer then
                self._ttTimer=nil; self._tooltip=nil
            end
        end

        if item.type=="label" then
            self:_Draw(id.."l","Text",{Position=Vector2.new(x,y),Text=item.label,
                Size=12,Font=FF,Color=T2.TextMuted,ZIndex=12})
            return 18

        elseif item.type=="sep" then
            self:_Draw(id.."s","Square",{Position=Vector2.new(x,y+5),
                Size=Vector2.new(w2,1),Filled=true,Color=T2.Border,ZIndex=12})
            return 14

        elseif item.type=="toggle" then
            local bW,bH=28,14; local bp=Vector2.new(x+w2-bW,y+1)
            self:_Draw(id.."bg","Square",{Position=bp,Size=Vector2.new(bW,bH),Filled=true,
                Color=item.value and T2.Accent or T2.Widget,ZIndex=12,Corner=7})
            self:_Draw(id.."bo","Square",{Position=bp,Size=Vector2.new(bW,bH),Filled=false,
                Color=item.value and T2.Accent or T2.Border,ZIndex=13,Corner=7})
            local kx=item.value and(bp.X+bW-13) or(bp.X+1)
            self:_Draw(id.."kn","Square",{Position=Vector2.new(kx,bp.Y+1),
                Size=Vector2.new(12,12),Filled=true,Color=Color3.new(1,1,1),ZIndex=14,Corner=6})
            self:_Draw(id.."lb","Text",{Position=Vector2.new(x,y+1),Text=item.label,
                Size=13,Font=FF,Color=item.value and T2.Text or T2.TextMuted,ZIndex=12})
            chkTip(Vector2.new(x,y),Vector2.new(w2,16),item.tip)
            if lc and over(Vector2.new(x,y),Vector2.new(w2,16)) and now-item._db>0.15 then
                item.value=not item.value; pcall(item.cb,item.value); item._db=now
            end
            return 22

        elseif item.type=="slider" then
            self:_Draw(id.."lb","Text",{Position=Vector2.new(x,y),Text=item.label,
                Size=13,Font=FF,Color=T2.TextMuted,ZIndex=12})
            local bX=x+w2/2+4; local bW2=w2/2-4; local bH=10
            local bp=Vector2.new(bX,y+1); local bs=Vector2.new(bW2,bH)
            self:_Draw(id.."sbg","Square",{Position=bp,Size=bs,Filled=true,Color=T2.Widget,ZIndex=12,Corner=5})
            local pct=clamp((item.value-item.min)/(item.max-item.min),0,1)
            self:_Draw(id.."sfi","Square",{Position=bp,Size=Vector2.new(bW2*pct,bH),
                Filled=true,Color=T2.Accent,ZIndex=13,Corner=5})
            self:_Draw(id.."sv","Text",{Position=bp+Vector2.new(bW2/2,bH/2-6),
                Text=tostring(item.value)..item.suffix,Size=11,Center=true,
                Font=FF,Color=Color3.new(1,1,1),ZIndex=14})
            if Input.click and over(bp,bs) and not isPop then self._sliderDrag=item end
            if self._sliderDrag==item then
                if Input.held then
                    local p=clamp((mpos().X-bp.X)/bs.X,0,1)
                    local nv=math.floor(item.min+(item.max-item.min)*p)
                    if nv~=item.value then item.value=nv; pcall(item.cb,item.value) end
                else self._sliderDrag=nil end
            end
            return 24

        elseif item.type=="button" then
            local bp=Vector2.new(x,y); local bs=Vector2.new(w2,18)
            local hov=over(bp,bs) and not isPop
            self:_Draw(id.."bg","Square",{Position=bp,Size=bs,Filled=true,
                Color=hov and lerpC(T2.Widget,T2.Accent,0.3) or T2.Widget,ZIndex=12,Corner=3})
            self:_Draw(id.."bo","Square",{Position=bp,Size=bs,Filled=false,
                Color=hov and T2.Accent or T2.Border,ZIndex=13,Corner=3})
            self:_Draw(id.."tx","Text",{Position=bp+bs/2,Text=item.label,Size=13,
                Font=FF,Center=true,Color=hov and T2.Accent or T2.Text,ZIndex=14})
            chkTip(bp,bs,item.tip)
            if lc and hov and now-item._db>0.15 then pcall(item.cb); item._db=now end
            return 22

        elseif item.type=="dropdown" or item.type=="multi" then
            self:_Draw(id.."lb","Text",{Position=Vector2.new(x,y),Text=item.label,
                Size=13,Font=FF,Color=T2.TextMuted,ZIndex=12})
            local dW=w2/2; local dp=Vector2.new(x+w2-dW,y-1); local ds=Vector2.new(dW,17)
            local isOpen=self._activePop and self._activePop.id==id
            local disp
            if item.type=="dropdown" then
                disp=tostring(item.value or "...")
            else
                local sel={}
                for _,o in ipairs(item.options) do if item.selected[o] then sel[#sel+1]=o end end
                disp=#sel==0 and "None" or(#sel==1 and sel[1] or sel[1].."+"..tostring(#sel-1))
            end
            self:_Draw(id.."bg","Square",{Position=dp,Size=ds,Filled=true,
                Color=isOpen and lerpC(T2.Widget,T2.Accent,0.08) or T2.Widget,ZIndex=12,Corner=3})
            self:_Draw(id.."bo","Square",{Position=dp,Size=ds,Filled=false,
                Color=isOpen and T2.Accent or T2.Border,ZIndex=13,Corner=3})
            self:_Draw(id.."tx","Text",{Position=dp+Vector2.new(5,1),Text=disp,
                Size=12,Font=FF,Color=T2.TextMuted,ZIndex=14})
            self:_Draw(id.."ar","Text",{Position=dp+Vector2.new(dW-13,1),
                Text=isOpen and "▲" or "▼",Size=10,Font=FF,Color=T2.TextMuted,ZIndex=14})
            if Input.click and over(dp,ds) then
                if isOpen then self._activePop=nil
                else self._activePop={type=item.type,id=id,item=item,pos=dp,w=dW,_openTime=os.clock()} end
            end
            return 22

        elseif item.type=="color" then
            self:_Draw(id.."lb","Text",{Position=Vector2.new(x,y),Text=item.label,
                Size=13,Font=FF,Color=T2.TextMuted,ZIndex=12})
            local cs=Vector2.new(26,12); local cp=Vector2.new(x+w2-26,y+2)
            local isOpen=self._activePop and self._activePop.id==id
            self:_Draw(id.."bg","Square",{Position=cp,Size=cs,Filled=true,Color=item.value,ZIndex=12,Corner=3})
            self:_Draw(id.."bo","Square",{Position=cp,Size=cs,Filled=false,
                Color=isOpen and T2.Accent or T2.Border,ZIndex=13,Corner=3})
            if Input.click and over(cp,cs) then
                if isOpen then self._activePop=nil
                else self._activePop={type="color",id=id,item=item,pos=cp,_openTime=os.clock()} end
            end
            return 22

        elseif item.type=="keybind" then
            self:_Draw(id.."lb","Text",{Position=Vector2.new(x,y),Text=item.label,
                Size=13,Font=FF,Color=T2.TextMuted,ZIndex=12})
            local ks=item.listening and "[Press key...]" or
                ("["..(KeyNames[item.value] or "NONE").."]")
            local kp=Vector2.new(x+w2-textW(ks,12)-4,y)
            self:_Draw(id.."kv","Text",{Position=kp,Text=ks,Size=12,Font=FF,
                Color=item.listening and T2.Accent or(item.active and T2.Accent or T2.TextMuted),ZIndex=12})

            if Input.click and over(Vector2.new(x,y),Vector2.new(w2,16)) and not isPop and now-item._db>0.2 then
                item.listening=true; item._waitRelease=true; item._db=now
            end

            if item.listening then
                if item._waitRelease then
                    if not Input.held then item._waitRelease=false end
                else
                    for k in pairs(KeyNamesCapture) do
                        if k~=0x01 and iskeypressed(k) then
                            item.value=(k==0x1B and 0 or k)
                            item.listening=false; break
                        end
                    end
                    if item.listening and ismouse1pressed() then
                        item.value=0x01; item.listening=false
                    end
                end
            end

            if item.value~=0 and not item.listening then
                if item.mode=="Toggle" then
                    if Input:keyClick(item.value) then
                        item.active=not item.active; pcall(item.cb,item.active)
                    end
                else
                    local held=iskeypressed(item.value)
                    if held~=item._prevHeld then
                        item.active=held; item._prevHeld=held; pcall(item.cb,held)
                    end
                end
            end
            return 22

        elseif item.type=="textbox" then
            self:_Draw(id.."lb","Text",{Position=Vector2.new(x,y),Text=item.label,
                Size=13,Font=FF,Color=T2.TextMuted,ZIndex=12})
            local tbW=w2/2; local tp=Vector2.new(x+w2-tbW,y-1); local ts2=Vector2.new(tbW,17)
            local disp=item.active and(item.value.."_") or(item.value=="" and item.ph or item.value)
            self:_Draw(id.."bg","Square",{Position=tp,Size=ts2,Filled=true,
                Color=item.active and lerpC(T2.Widget,T2.Accent,0.06) or T2.Widget,ZIndex=12,Corner=3})
            self:_Draw(id.."bo","Square",{Position=tp,Size=ts2,Filled=false,
                Color=item.active and T2.Accent or T2.Border,ZIndex=13,Corner=3})
            self:_Draw(id.."tx","Text",{Position=tp+Vector2.new(5,1),Text=disp,
                Size=12,Font=FF,Color=item.active and T2.Text or T2.TextMuted,ZIndex=14})
            if Input.click and over(tp,ts2) and not isPop and now-item._db>0.15 then
                item.active=not item.active
                if not item.active then pcall(item.cb,item.value) end
                item._db=now
            elseif Input.click and item.active and not over(tp,ts2) then
                item.active=false; pcall(item.cb,item.value)
            end
            if item.active then
                for k,nm in pairs(KeyNames) do
                    if Input:keyClick(k) then
                        if k==0x08 then item.value=item.value:sub(1,#item.value-1)
                        elseif k==0x0D then item.active=false; pcall(item.cb,item.value)
                        elseif #nm==1 then
                            item.value=item.value..(iskeypressed(0x10) and nm:upper() or nm:lower())
                        elseif k==0x20 then item.value=item.value.." " end
                    end
                end
            end
            return 22
        end
        return 0
    end

    function WIN:_renderTabContent(tab, contX, contY, contW, contH)
        local T2=self._T
        local FB2=Drawing.Fonts.SystemBold
        local pad=8
        local colW=math.floor((contW-(pad*4))/3)
        local colXs={contX+pad, contX+(pad*2)+colW, contX+(pad*3)+(colW*2)}
        local colYs={contY, contY, contY}
        local now2=os.clock()

        local scUp=iskeypressed(0x26) and now2-self._scUp>0.08
        local scDn=iskeypressed(0x28) and now2-self._scDn>0.08

        if over(Vector2.new(contX,contY),Vector2.new(contW,contH)) then
            local ok,scroll=pcall(function()
                return 0
            end)
        end

        if scUp then tab.scroll=math.max(0,tab.scroll-22); self._scUp=now2 end
        if scDn then tab.scroll=math.min(tab.maxScroll,tab.scroll+22); self._scDn=now2 end

        if iskeypressed(0x26) then tab.scroll=math.max(0,tab.scroll-2) end
        if iskeypressed(0x28) then tab.scroll=math.min(tab.maxScroll,tab.scroll+2) end

        local sc=tab.scroll

        local colH={0,0,0}
        for si,sec in ipairs(tab._sections) do
            local c=math.min(sec._col or((si-1)%3+1),3)
            local sH=28; for _ in ipairs(sec._widgets) do sH=sH+26 end
            colH[c]=colH[c]+sH+pad
        end
        tab.maxScroll=math.max(0,math.max(colH[1],colH[2],colH[3])-contH)

        local prefix=tab._name.."_"
        for si,sec in ipairs(tab._sections) do
            local c=math.min(sec._col or((si-1)%3+1),3)
            local sX,sY=colXs[c], colYs[c]-sc
            local sH=28; for _ in ipairs(sec._widgets) do sH=sH+26 end

            if sY+sH>=contY and sY<=contY+contH then
                local sid=prefix.."s"..si
                self:_Draw(sid.."bg","Square",{Position=Vector2.new(sX,sY),Size=Vector2.new(colW,sH),
                    Filled=true,Color=T2.Surface,ZIndex=6,Corner=5})
                self:_Draw(sid.."bo","Square",{Position=Vector2.new(sX,sY),Size=Vector2.new(colW,sH),
                    Filled=false,Color=T2.Border,ZIndex=7,Corner=5})
                self:_Draw(sid.."tt","Text",{Position=Vector2.new(sX+8,sY+6),
                    Text=sec._name:upper(),Size=11,Font=FB2,Color=T2.Text,ZIndex=9})
                self:_Draw(sid.."sl","Square",{Position=Vector2.new(sX+4,sY+20),
                    Size=Vector2.new(colW-8,1),Filled=true,Color=T2.Border,ZIndex=8})
                local wY=sY+26
                for wi,item in ipairs(sec._widgets) do
                    local h=self:_W(item,sid.."w"..wi,sX+8,wY,colW-16)
                    wY=wY+h+2
                end
            end
            colYs[c]=colYs[c]+(sH+pad)
        end

        if tab.maxScroll>0 then
            local sbX=contX+contW-5
            local th2=math.max(16,contH*(contH/(contH+tab.maxScroll)))
            local ty2=contY+(tab.scroll/tab.maxScroll)*(contH-th2)
            self:_Draw(prefix.."scbg","Square",{Position=Vector2.new(sbX,contY),
                Size=Vector2.new(4,contH),Filled=true,Color=T2.Surface,ZIndex=5,Corner=2})
            self:_Draw(prefix.."scth","Square",{Position=Vector2.new(sbX,ty2),
                Size=Vector2.new(4,th2),Filled=true,Color=T2.Accent,ZIndex=6,Corner=2})
        end
    end

    function WIN:_renderPopups()
        local pop=self._activePop; if not pop then return end
        local T2=self._T; local closed=false
        local openAge=os.clock()-(pop._openTime or 0)

        if pop.type=="dropdown" or pop.type=="multi" then
            local maxV=math.min(6,#pop.item.options)
            local optH=20; local h=maxV*optH+4
            local pPos=pop.pos+Vector2.new(0,19); local scr=getScreen()
            if pPos.Y+h>scr.Y-10 then pPos=Vector2.new(pPos.X,pop.pos.Y-h-4) end

            self:_Draw("p_bg","Square",{Position=pPos,Size=Vector2.new(pop.w,h),
                Filled=true,Color=T2.Surface2,ZIndex=200,Corner=4})
            self:_Draw("p_bo","Square",{Position=pPos,Size=Vector2.new(pop.w,h),
                Filled=false,Color=T2.Accent,ZIndex=201,Corner=4})

            local sc=pop.item.scroll or 0
            for i=1,maxV do
                local vi=i+sc; local v=pop.item.options[vi]; if not v then break end
                local op=pPos+Vector2.new(0,(i-1)*optH+2)
                local hov=over(op,Vector2.new(pop.w,optH))
                local isSel=(pop.type=="dropdown" and pop.item.value==v) or
                    (pop.type=="multi" and pop.item.selected[v])
                if hov then
                    self:_Draw("ph"..i,"Square",{Position=op,Size=Vector2.new(pop.w,optH),
                        Filled=true,Color=lerpC(T2.Surface2,T2.Accent,0.18),ZIndex=202})
                end
                if isSel then
                    self:_Draw("pd"..i,"Square",{Position=op+Vector2.new(5,8),
                        Size=Vector2.new(4,4),Filled=true,Color=T2.Accent,ZIndex=204,Corner=2})
                end
                self:_Draw("pv"..i,"Text",{Position=op+Vector2.new(15,3),Text=tostring(v),
                    Size=13,Font=Drawing.Fonts.System,
                    Color=isSel and T2.Accent or(hov and T2.Text or T2.TextMuted),ZIndex=203})
                if Input.click and hov then
                    if pop.type=="dropdown" then
                        pop.item.value=v; pcall(pop.item.cb,v); closed=true
                    else
                        pop.item.selected[v]=not pop.item.selected[v]
                        local out={}
                        for _,o in ipairs(pop.item.options) do
                            if pop.item.selected[o] then out[#out+1]=o end
                        end
                        pcall(pop.item.cb,out)
                    end
                end
            end

            if #pop.item.options>maxV then
                if sc>0 then
                    self:_Draw("psu","Text",{Position=pPos+Vector2.new(pop.w/2-4,0),
                        Text="▲",Size=10,Font=Drawing.Fonts.System,Color=T2.TextMuted,ZIndex=205})
                end
                if sc+maxV<#pop.item.options then
                    self:_Draw("psd","Text",{Position=pPos+Vector2.new(pop.w/2-4,h-13),
                        Text="▼",Size=10,Font=Drawing.Fonts.System,Color=T2.TextMuted,ZIndex=205})
                end
                local n2=os.clock()
                if iskeypressed(0x26) and n2-self._scLu>0.1 then
                    pop.item.scroll=math.max(0,sc-1); self._scLu=n2
                end
                if iskeypressed(0x28) and n2-self._scLd>0.1 then
                    pop.item.scroll=math.min(#pop.item.options-maxV,sc+1); self._scLd=n2
                end
            end

            if Input.click and openAge>0.1 and not over(pop.pos,Vector2.new(pop.w,h+22)) then
                closed=true
            end

        elseif pop.type=="color" then
            local cpW,cpH=210,185
            local cpPos=pop.pos+Vector2.new(-cpW+26,16); local scr=getScreen()
            if cpPos.X<4 then cpPos=Vector2.new(4,cpPos.Y) end
            if cpPos.Y+cpH>scr.Y-4 then cpPos=Vector2.new(cpPos.X,pop.pos.Y-cpH-4) end

            self:_Draw("p_bg","Square",{Position=cpPos,Size=Vector2.new(cpW,cpH),
                Filled=true,Color=T2.Surface2,ZIndex=200,Corner=6})
            self:_Draw("p_bo","Square",{Position=cpPos,Size=Vector2.new(cpW,cpH),
                Filled=false,Color=T2.Accent,ZIndex=201,Corner=6})

            local svP=cpPos+Vector2.new(8,8); local svW,svH=128,128
            local COLS,ROWS=16,16
            local cw=svW/COLS; local rh=svH/ROWS
            for ci=0,COLS-1 do
                for ri=0,ROWS-1 do
                    self:_Draw("sv"..ci.."r"..ri,"Square",{
                        Position=svP+Vector2.new(ci*cw, ri*rh),
                        Size=Vector2.new(cw+0.5, rh+0.5),
                        Filled=true,
                        Color=hsvToRgb(pop.item.h,(ci+0.5)/COLS,1-(ri+0.5)/ROWS),
                        ZIndex=202
                    })
                end
            end
            self:_Draw("svbo","Square",{Position=svP,Size=Vector2.new(svW,svH),
                Filled=false,Color=T2.Border,ZIndex=203})
            self:_Draw("svcr","Square",{
                Position=Vector2.new(svP.X+pop.item.s*svW-3, svP.Y+(1-pop.item.v)*svH-3),
                Size=Vector2.new(6,6),Filled=false,Color=Color3.new(1,1,1),ZIndex=204,Corner=3})

            local hP=cpPos+Vector2.new(144,8); local hW,hH=16,128
            for i=0,23 do
                self:_Draw("hi"..i,"Square",{
                    Position=hP+Vector2.new(0,i*(hH/24)),
                    Size=Vector2.new(hW,hH/24+0.5),
                    Filled=true,Color=hsvToRgb(i/24,1,1),ZIndex=202})
            end
            self:_Draw("hbo","Square",{Position=hP,Size=Vector2.new(hW,hH),
                Filled=false,Color=T2.Border,ZIndex=203})
            self:_Draw("hcr","Square",{
                Position=Vector2.new(hP.X-1,hP.Y+pop.item.h*hH-2),
                Size=Vector2.new(hW+2,4),Filled=false,Color=Color3.new(1,1,1),ZIndex=204})

            local prP=cpPos+Vector2.new(8,144)
            self:_Draw("prv","Square",{Position=prP,Size=Vector2.new(svW,14),
                Filled=true,Color=pop.item.value,ZIndex=202,Corner=3})
            self:_Draw("pbo","Square",{Position=prP,Size=Vector2.new(svW,14),
                Filled=false,Color=T2.Border,ZIndex=203,Corner=3})
            local hex=string.format("#%02X%02X%02X",
                math.floor(pop.item.value.R*255),
                math.floor(pop.item.value.G*255),
                math.floor(pop.item.value.B*255))
            self:_Draw("hex","Text",{Position=cpPos+Vector2.new(8,162),Text=hex,
                Size=11,Font=Drawing.Fonts.Monospace,Color=T2.TextMuted,ZIndex=203})

            if Input.held then
                if over(svP,Vector2.new(svW,svH)) then
                    pop.item.s=clamp((mpos().X-svP.X)/svW,0,1)
                    pop.item.v=clamp(1-(mpos().Y-svP.Y)/svH,0,1)
                    pop.item.value=hsvToRgb(pop.item.h,pop.item.s,pop.item.v)
                    pcall(pop.item.cb,pop.item.value)
                elseif over(hP,Vector2.new(hW,hH)) then
                    pop.item.h=clamp((mpos().Y-hP.Y)/hH,0,1)
                    pop.item.value=hsvToRgb(pop.item.h,pop.item.s,pop.item.v)
                    pcall(pop.item.cb,pop.item.value)
                end
            end

            if Input.click and openAge>0.1 and not over(cpPos,Vector2.new(cpW,cpH)) then
                closed=true
            end
        end

        if closed then self._activePop=nil end
    end

    function WIN:_renderTooltip()
        if not self._tooltip then return end
        local T2=self._T; local tp=self._tooltip; local scr=getScreen()
        local tw=textW(tp.text,12)+14; local px,py=tp.pos.X,tp.pos.Y
        if px+tw>scr.X-4 then px=scr.X-tw-6 end
        self:_Draw("ttb","Square",{Position=Vector2.new(px-2,py-2),Size=Vector2.new(tw,18),
            Filled=true,Color=T2.Surface2,ZIndex=500,Corner=4})
        self:_Draw("tto","Square",{Position=Vector2.new(px-2,py-2),Size=Vector2.new(tw,18),
            Filled=false,Color=T2.Border,ZIndex=501,Corner=4})
        self:_Draw("ttt","Text",{Position=Vector2.new(px+4,py+2),Text=tp.text,
            Size=12,Font=FF,Color=T2.TextMuted,ZIndex=502})
    end

    function WIN:_render()
        self:_BeginFrame()
        local T2=self._T
        if not self._open then self:_Flush(); return end

        local MP=mpos(); local topBarH=38; local now=os.clock()

        if Input.click and over(self._pos,Vector2.new(self.Size.X,topBarH)) then
            local clickedTab=false
            local titleEnd2=self._pos.X+textW(self.Title:upper(),14)+16
            local tX2=titleEnd2+8
            local tabH2=22
            local tabY2=self._pos.Y+(topBarH-tabH2)/2
            for _,tab in ipairs(self._tabs) do
                local tW=textW(tab._name:upper(),12)+18
                if over(Vector2.new(tX2,tabY2),Vector2.new(tW,tabH2)) then
                    clickedTab=true; break
                end
                tX2=tX2+tW+4
            end
            if self._permTab then
                local ptW=textW(self._permTab._name:upper(),12)+18
                if over(Vector2.new(tX2,tabY2),Vector2.new(ptW,tabH2)) then
                    clickedTab=true
                end
            end
            if not clickedTab and not self._drag then
                self._drag=self._pos-MP
            end
        end
        if not Input.held then self._drag=nil end
        if self._drag then self._pos=MP+self._drag end

        local LP=self._pos; local sz=self.Size

        self:_Draw("mbg","Square",{Position=LP,Size=sz,
            Filled=true,Color=T2.Background,ZIndex=2,Corner=8})
        self:_Draw("mbo","Square",{Position=LP-Vector2.new(1,1),Size=sz+Vector2.new(2,2),
            Filled=false,Color=T2.BorderDark,ZIndex=3,Corner=8})

        local topBarH=38
        self:_Draw("tbbg","Square",{Position=LP,Size=Vector2.new(sz.X,topBarH),
            Filled=true,Color=T2.TopBar,ZIndex=3,Corner=8})
        self:_Draw("tbfx","Square",{Position=LP+Vector2.new(0,topBarH-8),Size=Vector2.new(sz.X,8),
            Filled=true,Color=T2.TopBar,ZIndex=3})

        self:_Draw("tbsp","Square",{Position=LP+Vector2.new(0,topBarH),Size=Vector2.new(sz.X,1),
            Filled=true,Color=T2.Accent,ZIndex=10})

        local titleEnd=LP.X+textW(self.Title:upper(),14)+16
        self:_Draw("tbtit","Text",{Position=LP+Vector2.new(10,12),Text=self.Title:upper(),
            Size=14,Font=FB,Color=T2.Accent,ZIndex=5})

        local tX=titleEnd+8
        local tabH=22
        local tabY=LP.Y+(topBarH-tabH)/2
        for i,tab in ipairs(self._tabs) do
            local act=(self._openTab==tab and not self._openPermTab)
            local tW=textW(tab._name:upper(),12)+18
            local tPos=Vector2.new(tX,tabY); local tSz=Vector2.new(tW,tabH)
            local hov=over(tPos,tSz)
            self:_Draw("tact"..i,"Square",{Position=tPos,Size=tSz,Filled=true,
                Color=act and lerpC(T2.Surface,T2.Accent,0.2) or (hov and lerpC(T2.TopBar,T2.Accent,0.1) or T2.Surface),
                ZIndex=4,Corner=4})
            self:_Draw("tbo"..i,"Square",{Position=tPos,Size=tSz,Filled=false,
                Color=act and T2.Accent or (hov and T2.Accent or T2.Border),
                ZIndex=5,Corner=4})
            self:_Draw("ttx"..i,"Text",{
                Position=tPos+tSz/2,
                Text=tab._name:upper(),Size=12,Font=act and FB or FF,
                Center=true,
                Color=act and T2.Text or (hov and T2.Text or T2.TextMuted),ZIndex=6})
            if Input.click and hov and now-self._tabClickTime>0.2 then
                self._openTab=tab; self._openPermTab=false
                self._activePop=nil; self._tabClickTime=now
            end
            tX=tX+tW+4
        end

        if self._permTab then
            local pt=self._permTab
            local ptW=textW(pt._name:upper(),12)+18
            local ptPos=Vector2.new(tX,tabY); local ptSz=Vector2.new(ptW,tabH)
            local ptAct=self._openPermTab
            local ptHov=over(ptPos,ptSz)
            self:_Draw("ptact","Square",{Position=ptPos,Size=ptSz,Filled=true,
                Color=ptAct and lerpC(T2.Surface,T2.Accent,0.2) or (ptHov and lerpC(T2.TopBar,T2.Accent,0.1) or T2.Surface),
                ZIndex=4,Corner=4})
            self:_Draw("ptbo","Square",{Position=ptPos,Size=ptSz,Filled=false,
                Color=ptAct and T2.Accent or (ptHov and T2.Accent or T2.Border),
                ZIndex=5,Corner=4})
            self:_Draw("pttx","Text",{
                Position=ptPos+ptSz/2,
                Text=pt._name:upper(),Size=12,Font=ptAct and FB or FF,
                Center=true,
                Color=ptAct and T2.Text or (ptHov and T2.Text or T2.TextMuted),ZIndex=6})
            if Input.click and ptHov and now-self._tabClickTime>0.2 then
                self._openPermTab=not self._openPermTab
                self._activePop=nil; self._tabClickTime=now
            end
        end

        local un="Hello, "..LocalPlayer.Name
        self:_Draw("tbusr","Text",{Position=Vector2.new(LP.X+sz.X-textW(un,11)-10,LP.Y+13),
            Text=un,Size=11,Font=FF,Color=T2.TextMuted,ZIndex=5})

        local contY=LP.Y+topBarH+8; local contH=sz.Y-topBarH-12
        if self._openPermTab and self._permTab then
            self:_renderTabContent(self._permTab, LP.X, contY, sz.X, contH)
        elseif self._openTab then
            self:_renderTabContent(self._openTab, LP.X, contY, sz.X, contH)
        end

        self:_renderPopups()
        self:_renderTooltip()
        self:_Flush()
    end

    task.spawn(function()
        while WIN._running do
            safeWait(0.005)
            if isrbxactive() then
                Input:update()
                if Input:keyClick(WIN.MenuKey) then
                    WIN._open=not WIN._open
                    pcall(setrobloxinput, not WIN._open)
                end
                WIN:_render()
            else
                for _,d in pairs(WIN._drawings) do d.Visible=false end
            end
        end
    end)

    function WIN:Notify(text,title,dur)
        ShadowHub:Notify(title or self.Title, text, dur, self._T)
    end
    function WIN:Destroy()
        self._running=false; safeWait(0.1)
        for _,d in pairs(self._drawings) do d:Remove() end
    end

    return WIN
end

_G.ShadowHub = ShadowHub
