-- EIGHT placeholder sprite generator (Aseprite batch script).
-- Every sprite produced here is a temporary PLACEHOLDER, drawn by code with the
-- owner's palette, to be replaced by hand-drawn art.
--
-- Usage (from the repository root):
--   Aseprite.exe -b --script-param out=eight/assets/art/placeholder --script tools/placeholder_art.lua

local OUT = app.params["out"]
if OUT == nil or OUT == "" then
	error("Pass --script-param out=<folder>")
end

-- Owner palette, in the order it was supplied.
local ORDER = {
	{ "mint", "caebe0" }, { "sea", "729aa1" }, { "steel", "446077" }, { "navy", "2e3850" },
	{ "night", "1e182e" }, { "abyss", "14081a" }, { "black", "070109" }, { "deep", "091820" },
	{ "teal", "123735" }, { "pine", "2f6b4e" }, { "leaf", "4b974f" }, { "lime", "91b95b" },
	{ "cream", "e6e29e" }, { "sand", "dccd93" }, { "clay", "b7836b" }, { "rust", "995154" },
	{ "wine", "6b2c40" }, { "blood", "310e25" }, { "plum", "3a2140" }, { "mauve", "6e3f5f" },
	{ "rose", "97576c" },
}
local COL = {}
for _, entry in ipairs(ORDER) do
	local hex = entry[2]
	COL[entry[1]] = app.pixelColor.rgba(
		tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255
	)
end

-- Ramps, dark to light.
local COOL = { "night", "navy", "steel", "sea", "mint" }
local GREEN = { "deep", "teal", "pine", "leaf", "lime" }
local OX = { "blood", "wine", "rust", "clay" }
local PURPLE = { "abyss", "plum", "mauve", "rose" }
local ROSE = { "blood", "wine", "mauve", "rose", "clay" }
local FIRE = { "wine", "rust", "clay", "sand", "cream" }
local GOLD = { "rust", "clay", "sand", "cream" }
local SACK = { "blood", "wine", "rust", "clay" }

local BAYER = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }
local function bayer(x, y)
	return (BAYER[(y % 4) + 1][(x % 4) + 1] + 0.5) / 16
end

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

---------------------------------------------------------------------------
-- Canvas: a palette-name pixel buffer with simple shaded primitives.
---------------------------------------------------------------------------
local Canvas = {}
Canvas.__index = Canvas

local function canvas(w, h)
	return setmetatable({ w = w, h = h, px = {} }, Canvas)
end

function Canvas:set(x, y, c)
	x = math.floor(x)
	y = math.floor(y)
	if x >= 0 and y >= 0 and x < self.w and y < self.h then
		self.px[y * self.w + x] = c
	end
end

function Canvas:get(x, y)
	if x < 0 or y < 0 or x >= self.w or y >= self.h then return nil end
	return self.px[y * self.w + x]
end

-- Pick a ramp color for brightness t (0..1) with ordered dithering.
local function shade(ramp, t, x, y)
	local n = #ramp
	local v = clamp(t, 0, 1) * (n - 1) + (bayer(x, y) - 0.5) * 0.85
	return ramp[clamp(math.floor(v + 0.5) + 1, 1, n)]
end

-- Lit ellipsoid. bias brightens (+) or darkens (-).
function Canvas:ball(cx, cy, rx, ry, ramp, bias)
	bias = bias or 0
	for y = math.floor(cy - ry), math.ceil(cy + ry) do
		for x = math.floor(cx - rx), math.ceil(cx + rx) do
			local nx = (x + 0.5 - cx) / rx
			local ny = (y + 0.5 - cy) / ry
			local d = nx * nx + ny * ny
			if d <= 1 then
				local nz = math.sqrt(1 - d)
				local light = -0.45 * nx - 0.55 * ny + 0.7 * nz
				self:set(x, y, shade(ramp, light * 0.95 + 0.05 + bias, x, y))
			end
		end
	end
end

function Canvas:oval(cx, cy, rx, ry, c)
	for y = math.floor(cy - ry), math.ceil(cy + ry) do
		for x = math.floor(cx - rx), math.ceil(cx + rx) do
			local nx = (x + 0.5 - cx) / rx
			local ny = (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1 then self:set(x, y, c) end
		end
	end
end

function Canvas:rect(x, y, w, h, c)
	for yy = y, y + h - 1 do
		for xx = x, x + w - 1 do self:set(xx, yy, c) end
	end
end

function Canvas:line(x0, y0, x1, y1, c)
	x0, y0, x1, y1 = math.floor(x0 + 0.5), math.floor(y0 + 0.5), math.floor(x1 + 0.5), math.floor(y1 + 0.5)
	local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
	local sx = x0 < x1 and 1 or -1
	local sy = y0 < y1 and 1 or -1
	local err = dx + dy
	while true do
		self:set(x0, y0, c)
		if x0 == x1 and y0 == y1 then break end
		local e2 = 2 * err
		if e2 >= dy then err = err + dy; x0 = x0 + sx end
		if e2 <= dx then err = err + dx; y0 = y0 + sy end
	end
end

local function inside(points, px, py)
	local hit = false
	local j = #points
	for i = 1, #points do
		local xi, yi = points[i][1], points[i][2]
		local xj, yj = points[j][1], points[j][2]
		if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
			hit = not hit
		end
		j = i
	end
	return hit
end

-- Polygon filled with a top-lit vertical gradient over a ramp.
function Canvas:poly(points, ramp, bias)
	bias = bias or 0
	local minx, maxx, miny, maxy = 999, -999, 999, -999
	for _, p in ipairs(points) do
		minx = math.min(minx, p[1]); maxx = math.max(maxx, p[1])
		miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2])
	end
	for y = math.floor(miny), math.ceil(maxy) do
		for x = math.floor(minx), math.ceil(maxx) do
			if inside(points, x + 0.5, y + 0.5) then
				local t = 1 - (y - miny) / math.max(1, maxy - miny)
				local side = 0.15 * (1 - 2 * (x - minx) / math.max(1, maxx - minx))
				self:set(x, y, shade(ramp, t * 0.85 + side + bias, x, y))
			end
		end
	end
end

function Canvas:outline(c)
	local add = {}
	for y = 0, self.h - 1 do
		for x = 0, self.w - 1 do
			if self:get(x, y) == nil then
				if self:get(x - 1, y) or self:get(x + 1, y) or self:get(x, y - 1) or self:get(x, y + 1) then
					add[#add + 1] = { x, y }
				end
			end
		end
	end
	for _, p in ipairs(add) do self:set(p[1], p[2], c) end
end

function Canvas:paste(other, ox, oy)
	for y = 0, other.h - 1 do
		for x = 0, other.w - 1 do
			local c = other:get(x, y)
			if c then self:set(x + (ox or 0), y + (oy or 0), c) end
		end
	end
end

function Canvas:image()
	local img = Image(self.w, self.h, ColorMode.RGB)
	for y = 0, self.h - 1 do
		for x = 0, self.w - 1 do
			local c = self:get(x, y)
			if c then img:drawPixel(x, y, COL[c]) end
		end
	end
	return img
end

-- Shadow + outlined figure, the standard sprite composition.
local function compose(w, h, shadow, figure, after)
	local base = canvas(w, h)
	if shadow then base:paste(shadow) end
	figure:outline("black")
	base:paste(figure)
	if after then base:paste(after) end
	return base
end

local function ground_shadow(w, h, cx, cy, rx, ry)
	local s = canvas(w, h)
	s:oval(cx, cy, rx, ry, "black")
	return s
end

---------------------------------------------------------------------------
-- Sprite file builder. anims = { {tag, frames, seconds, fn(frame)} ... }
-- A tag starting with "_" imports as a non-looping animation.
---------------------------------------------------------------------------
local function build(name, w, h, anims)
	local spr = Sprite(w, h, ColorMode.RGB)
	local pal = Palette(#ORDER)
	for i, entry in ipairs(ORDER) do pal:setColor(i - 1, Color(COL[entry[1]])) end
	spr:setPalette(pal)
	local layer = spr.layers[1]
	layer.name = "art"
	local index = 0
	for _, anim in ipairs(anims) do
		local first = index + 1
		for f = 0, anim[2] - 1 do
			index = index + 1
			if index > 1 then spr:newEmptyFrame(index) end
			spr:newCel(layer, index, anim[4](f):image(), Point(0, 0))
			spr.frames[index].duration = anim[3]
		end
		local tag = spr:newTag(first, index)
		tag.name = anim[1]
	end
	spr:saveAs(OUT .. "/placeholder_" .. name .. ".aseprite")
	spr:close()
end

local function pick(list, f) return list[(f % #list) + 1] end

local OX_BLACK = { "black", "abyss", "night", "navy" }
local ROBE = { "abyss", "plum", "mauve", "rose" }
local WING = { "steel", "sea", "mint" }

---------------------------------------------------------------------------
-- Player: angel fully robed in purple, riding a black ox (32x32, faces right).
-- No baked shadow: the game draws it so the sprite can rise for jumps.
---------------------------------------------------------------------------
local function player(anim, f)
	local bob, stride, wing, lean, tuck, spread = 0, 0, 0, 0, false, false
	if anim == "idle" then
		bob = pick({ 0, 0, 1, 1 }, f); wing = pick({ 0, -1, -1, 0 }, f)
	elseif anim == "run" then
		bob = pick({ 0, -1, 0, -1 }, f); stride = pick({ -1, 0, 1, 0 }, f); wing = pick({ 0, -2, 0, -1 }, f)
	elseif anim == "dash" then
		lean = 1; wing = 3
	elseif anim == "jump" then
		tuck = true; wing = pick({ -3, -4 }, f)
	elseif anim == "descend" then
		tuck = true; spread = true; wing = pick({ -3, 0, 2, 0 }, f)
	end
	local under = canvas(32, 32)
	if anim == "dash" then
		under:line(0, 13 + f, 4, 13 + f, "sea")
		under:line(1, 18, 5, 18, "steel")
		under:line(0, 23 - f, 3, 23 - f, "sea")
	end
	local g = canvas(32, 32)
	local b = bob
	-- tail
	g:line(6, 18 + b, 4, 22 + b, "abyss"); g:set(3, 23 + b, "black"); g:set(4, 23 + b, "black")
	-- legs (tucked while airborne)
	local leg = tuck and 2 or 4
	g:rect(11 - stride, 23 + b, 2, leg, "black"); g:rect(20 + stride, 23 + b, 2, leg, "black")
	g:rect(8 + stride, 23 + b, 2, leg, "abyss"); g:rect(18 - stride, 23 + b, 2, leg, "abyss")
	-- black ox body with a cool rim light, and a robe-colored blanket
	g:ball(15, 20 + b, 9, 5, OX_BLACK, -0.05)
	g:rect(11, 15 + b, 7, 3, "plum"); g:line(11, 18 + b, 17, 18 + b, "mauve")
	-- head, snout, horns (all black, navy tips for readability)
	local hx = 24 + lean
	g:ball(hx, 19 + b, 4, 3.5, OX_BLACK)
	g:set(hx + 3, 20 + b, "night"); g:set(hx + 3, 21 + b, "abyss")
	g:line(hx - 2, 16 + b, hx - 3, 14 + b, "abyss"); g:set(hx - 3, 13 + b, "navy")
	g:line(hx + 2, 16 + b, hx + 3, 14 + b, "abyss"); g:set(hx + 4, 13 + b, "navy")
	-- wings
	if spread then
		g:poly({ { 12, 12 + b }, { 3, 3 + b + wing }, { 1, 9 + b + wing }, { 5, 14 + b }, { 10, 15 + b } }, WING, 0.2)
		g:poly({ { 16, 11 + b }, { 25, 2 + b + wing }, { 28, 7 + b + wing }, { 21, 13 + b } }, WING, 0.1)
		g:line(4, 7 + b + wing, 10, 13 + b, "sea"); g:line(25, 5 + b + wing, 19, 12 + b, "sea")
	elseif anim == "dash" then
		g:poly({ { 12, 11 + b }, { 2, 10 + b }, { 1, 13 + b }, { 9, 15 + b } }, WING, 0.2)
	else
		g:poly({ { 12, 12 + b }, { 6, 5 + b + wing }, { 3, 8 + b + wing }, { 4, 12 + b }, { 9, 15 + b } }, WING, 0.2)
		g:line(5, 9 + b + wing, 10, 13 + b, "sea")
	end
	-- fully robed angel: robe, folds, sleeve, hood
	local rx = lean
	g:poly({ { 9 + rx, 18 + b }, { 12 + rx, 10 + b }, { 16 + rx, 10 + b }, { 19 + rx, 18 + b } }, ROBE, 0.1)
	g:line(14 + rx, 12 + b, 13 + rx, 17 + b, "plum")
	g:line(10 + rx, 18 + b, 18 + rx, 18 + b, "rose")
	g:line(16 + rx, 13 + b, 19 + rx, 13 + b, "mauve")
	g:ball(14 + rx, 9 + b, 3.5, 3.5, ROBE, 0.15)
	g:set(12 + rx, 6 + b, "mauve")
	g:rect(16 + rx, 9 + b, 2, 2, "black")
	local after = canvas(32, 32)
	after:set(17 + rx, 9 + b, "mint")
	after:set(hx + 1, 18 + b, "mint")
	after:set(20 + rx, 13 + b, "mint")
	local hy = 3 + b + pick({ 0, 0, -1, -1 }, f)
	after:line(13 + rx, hy, 15 + rx, hy, "cream")
	after:set(12 + rx, hy + 1, "sand"); after:set(16 + rx, hy + 1, "sand")
	after:line(13 + rx, hy + 2, 15 + rx, hy + 2, "sand")
	return compose(32, 32, under, g, after)
end

---------------------------------------------------------------------------
-- Light spear: a trident of blue-white light (48x16, pivot at left middle).
---------------------------------------------------------------------------
local function light_spear(f)
	local c = canvas(48, 16)
	-- dithered glow around the weapon
	for y = 2, 14 do
		for x = 0, 47 do
			local near = (y >= 6 and y <= 10 and x <= 36) or (x >= 33 and y >= 2 and y <= 14)
			if near and bayer(x + f, y) < 0.3 then c:set(x, y, "navy") end
		end
	end
	c:line(0, 7, 34, 7, "sea"); c:line(0, 9, 34, 9, "steel")
	c:line(0, 8, 34, 8, "mint")
	c:line(34, 3, 34, 13, "sea"); c:line(35, 3, 35, 13, "mint")
	c:line(36, 8, 46, 8, "mint"); c:line(36, 7, 44, 7, "sea"); c:set(47, 8, "mint")
	c:line(36, 3, 43, 3, "mint"); c:line(36, 4, 42, 4, "sea"); c:set(44, 4, "sea")
	c:line(36, 13, 43, 13, "mint"); c:line(36, 12, 42, 12, "sea"); c:set(44, 12, "sea")
	-- travelling sparkle and loose motes
	local s = (f * 9) % 34
	c:set(s, 8, "cream"); c:set(s + 1, 8, "cream"); c:set(s, 7, "mint")
	c:set(46 - f % 2, 8, "cream")
	math.randomseed(70 + f)
	for _ = 1, 4 do c:set(math.random(4, 44), math.random(0, 1) == 0 and math.random(3, 5) or math.random(11, 13), "sea") end
	return c
end

---------------------------------------------------------------------------
-- Combo finisher arc of light (128x128, centered, faces right).
---------------------------------------------------------------------------
local function slash(f)
	local c = canvas(128, 128)
	local reach = ({ 0.45, 0.85, 1.0, 1.0, 1.0 })[f + 1]
	local keep = ({ 1.0, 1.0, 1.0, 0.6, 0.25 })[f + 1]
	local half = math.rad(70)
	for y = 0, 127 do
		for x = 0, 127 do
			local dx, dy = x + 0.5 - 64, y + 0.5 - 64
			local d = math.sqrt(dx * dx + dy * dy)
			local a = math.atan(dy, dx)
			if math.abs(a) <= half then
				local along = (a + half) / (2 * half)
				if along <= reach then
					local taper = math.sin(along * math.pi)
					local inner, outer = 56 - 9 * taper, 57
					if d >= inner and d <= outer and bayer(x, y) < keep then
						local t = (d - inner) / math.max(1, outer - inner)
						c:set(x, y, t > 0.7 and "mint" or (t > 0.35 and "sea" or "steel"))
					end
				end
			end
		end
	end
	return c
end

---------------------------------------------------------------------------
-- Horde enemies (32x32, face right).
---------------------------------------------------------------------------
local function husk(f)
	local bob = pick({ 0, 1, 0, 1 }, f)
	local step = pick({ 0, 1, 0, -1 }, f)
	local g = canvas(32, 32)
	g:rect(12 + step, 25, 2, 2, "abyss"); g:rect(18 - step, 25, 2, 2, "abyss")
	g:ball(16, 20 + bob, 7, 6.5, PURPLE)
	g:ball(18, 15 + bob, 4.5, 4, PURPLE, 0.1)
	g:line(21, 20 + bob, 24, 22 + bob + step, "plum")
	g:set(25, 23 + bob + step, "rose"); g:set(24, 24 + bob + step, "rose")
	local glow = canvas(32, 32)
	glow:set(19, 15 + bob, "cream"); glow:set(21, 15 + bob, "cream")
	glow:line(19, 18 + bob, 21, 18 + bob, "black")
	return compose(32, 32, ground_shadow(32, 32, 16, 27, 7, 2), g, glow)
end

local function imp(f)
	local h = pick({ 0, -1, -2, -1 }, f)
	local flap = pick({ 0, 3, 5, 3 }, f)
	local g = canvas(32, 32)
	g:poly({ { 15, 15 + h }, { 7, 8 + h + flap }, { 8, 15 + h + flap // 2 }, { 13, 19 + h } }, { "blood", "wine", "rust" })
	g:line(13, 21 + h, 10, 24 + h, "wine")
	g:set(9, 24 + h, "rust"); g:set(9, 25 + h, "rust"); g:set(10, 25 + h, "rust")
	g:ball(16, 18 + h, 4, 4.5, FIRE, -0.25)
	g:ball(18, 13 + h, 3, 3, FIRE, -0.15)
	g:set(17, 10 + h, "sand"); g:set(16, 9 + h, "cream")
	g:set(20, 10 + h, "sand"); g:set(21, 9 + h, "cream")
	g:poly({ { 17, 15 + h }, { 23, 9 + h + flap }, { 23, 15 + h + flap // 2 }, { 19, 19 + h } }, { "blood", "wine", "rust" }, 0.2)
	local glow = canvas(32, 32)
	glow:set(19, 13 + h, "cream")
	return compose(32, 32, ground_shadow(32, 32, 16, 28, 5, 1.5), g, glow)
end

local function brute(f)
	local bob = pick({ 0, 1, 0, 1 }, f)
	local la = pick({ 0, -1, 0, 0 }, f)
	local lb = pick({ 0, 0, 0, -1 }, f)
	local g = canvas(32, 32)
	g:rect(9, 24 + la, 4, 4, "deep"); g:rect(19, 24 + lb, 4, 4, "deep")
	g:ball(15, 19 + bob, 11, 8, GREEN, -0.1)
	for x = 8, 16, 3 do g:set(x, 11 + bob, "teal"); g:set(x + 1, 10 + bob, "pine") end
	g:ball(23, 14 + bob, 5, 4.5, GREEN)
	g:line(20, 11 + bob, 18, 7 + bob, "sand"); g:set(18, 6 + bob, "cream")
	g:line(26, 11 + bob, 28, 7 + bob, "sand"); g:set(28, 6 + bob, "cream")
	g:ball(25, 21 + bob - la * 2, 3, 3, GREEN, 0.1)
	local glow = canvas(32, 32)
	glow:set(25, 13 + bob, "cream"); glow:set(26, 13 + bob, "cream")
	glow:set(27, 17 + bob, "sand"); glow:set(27, 16 + bob, "cream")
	return compose(32, 32, ground_shadow(32, 32, 16, 28, 12, 2.5), g, glow)
end

---------------------------------------------------------------------------
-- Bosses (64x64). Each: idle (4 frames) and attack (4 frames).
---------------------------------------------------------------------------
local function pride(anim, f)
	local atk = anim == "attack"
	local bob = pick({ 0, -1, -1, 0 }, f)
	local sway = math.sin(f / 4 * math.pi * 2) * 0.06
	local g = canvas(64, 64)
	local length = atk and 26 + (f % 2) or 23
	for i = 0, 12 do
		local a = math.rad(-168 + i * 13) + sway
		local tx, ty = 32 + math.cos(a) * length, 34 + math.sin(a) * length * 0.95
		g:line(32, 34, tx, ty, i % 2 == 0 and "pine" or "teal")
		g:ball(tx, ty, 3, 3, { "teal", "pine", "leaf" })
		g:ball(tx, ty, 1.6, 1.6, { "navy", "steel" })
	end
	g:poly({ { 23, 57 }, { 27, 33 + bob }, { 37, 33 + bob }, { 41, 57 } }, PURPLE, 0.1)
	g:line(23, 57, 41, 57, "sand")
	g:line(32, 36 + bob, 32, 56, "plum")
	g:ball(32, 33 + bob, 8, 4, PURPLE, 0.2)
	g:line(40, 44, 47, 28 + bob, "sand")
	g:ball(47, 26 + bob, 2.5, 2.5, COOL, 0.3)
	g:ball(32, 26 + bob, 5, 5.5, { "steel", "sea", "mint" })
	g:rect(27, 19 + bob, 11, 2, "sand")
	for _, x in ipairs({ 27, 30, 32, 34, 37 }) do
		g:line(x, 18 + bob, x, 16 + bob - (x == 32 and 2 or 0), "sand")
	end
	local after = canvas(64, 64)
	for i = 0, 12 do
		local a = math.rad(-168 + i * 13) + sway
		local tx, ty = 32 + math.cos(a) * length, 34 + math.sin(a) * length * 0.95
		after:set(tx, ty, atk and "cream" or "mint")
	end
	for _, x in ipairs({ 27, 32, 37 }) do after:set(x, 15 + bob - (x == 32 and 1 or 0), "cream") end
	after:set(32, 20 + bob, "rust")
	after:set(30, 26 + bob, atk and "cream" or "black"); after:set(34, 26 + bob, atk and "cream" or "black")
	after:set(47, 25 + bob, atk and "cream" or "mint")
	return compose(64, 64, ground_shadow(64, 64, 32, 58, 16, 3.5), g, after)
end

local function greed(anim, f)
	local atk = anim == "attack"
	local bob = pick({ 0, 1, 1, 0 }, f)
	local reach = pick({ 0, -1, -2, -1 }, f)
	local g = canvas(64, 64)
	math.randomseed(7)
	for _ = 1, 14 do
		local x, y = math.random(10, 54), math.random(53, 59)
		g:oval(x, y, 2.2, 1.2, "clay"); g:set(x, y - 1, "sand")
	end
	g:line(16, 38 + bob, 9, 31 + bob + reach, "rust"); g:ball(8, 30 + bob + reach, 2.5, 2.5, GOLD)
	g:line(48, 38 + bob, 55, 31 + bob - reach, "rust"); g:ball(56, 30 + bob - reach, 2.5, 2.5, GOLD)
	g:ball(32, 39 + bob, 17, 15, SACK)
	g:poly({ { 26, 26 + bob }, { 32, 17 + bob }, { 38, 26 + bob } }, SACK, 0.15)
	g:line(26, 26 + bob, 38, 26 + bob, "sand"); g:line(27, 27 + bob, 37, 27 + bob, "clay")
	g:ball(25, 34 + bob, 3, 3, GOLD); g:ball(39, 34 + bob, 3, 3, GOLD)
	local mouth = atk and 5 or 3
	g:oval(32, 44 + bob, 10, mouth, "black")
	local after = canvas(64, 64)
	for x = 24, 40, 2 do after:set(x, 44 + bob - mouth + 1, "cream") end
	after:set(25, 34 + bob, "black"); after:set(39, 34 + bob, "black")
	after:set(24, 33 + bob, "cream"); after:set(38, 33 + bob, "cream")
	if atk then
		after:oval(32, 45 + bob, 3, 2, "sand")
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2 + f * 0.5
			local x, y = 32 + math.cos(a) * 26, 36 + math.sin(a) * 20
			after:oval(x, y, 2, 2, "sand"); after:set(x - 1, y - 1, "cream")
		end
	end
	return compose(64, 64, ground_shadow(64, 64, 32, 58, 20, 4), g, after)
end

local function lust(anim, f)
	local atk = anim == "attack"
	local bob = pick({ 0, -1, -1, 0 }, f)
	local phase = f / 4 * math.pi * 2
	local g = canvas(64, 64)
	for i = 11, 0, -1 do
		local a = i / 12 * math.pi * 2 + phase * 0.25
		g:ball(32 + math.cos(a) * 12, 49 + math.sin(a) * 5, 4.5, 4, ROSE, -0.1)
	end
	local amp = atk and 5 or 2
	for k = 1, 4 do
		local prev
		for t = 0, 1, 0.04 do
			local x = 28 - t * (12 + k * 2) + math.sin(t * 7 + phase + k) * amp
			local y = 22 + t * (18 + k * 2)
			if prev then g:line(prev[1], prev[2], x, y, k % 2 == 0 and "wine" or "mauve") end
			prev = { x, y }
		end
	end
	g:poly({ { 27, 46 }, { 28, 30 + bob }, { 36, 30 + bob }, { 37, 46 } }, ROSE, 0.1)
	g:line(36, 32 + bob, 43, 26 + bob + (atk and -4 or 0), "rose")
	g:line(28, 32 + bob, 22, 38 + bob, "rose")
	g:ball(32, 24 + bob, 5, 5.5, { "mauve", "rose", "clay", "sand" })
	g:rect(27, 18 + bob, 10, 3, "wine")
	local after = canvas(64, 64)
	after:set(30, 24 + bob, "cream"); after:set(34, 24 + bob, "cream")
	local heart = atk and "cream" or "clay"
	after:set(31, 36 + bob, heart); after:set(33, 36 + bob, heart)
	after:line(31, 37 + bob, 33, 37 + bob, heart); after:set(32, 38 + bob, heart)
	return compose(64, 64, ground_shadow(64, 64, 32, 58, 17, 3.5), g, after)
end

local function envy(anim, f)
	local atk = anim == "attack"
	local bob = pick({ 0, -1, -2, -1 }, f)
	local sway = atk and -6 or pick({ 0, 1, 2, 1 }, f)
	local g = canvas(64, 64)
	g:line(26, 33 + bob, 15, 44 + sway, "pine"); g:line(15, 44 + sway, 12, 48 + sway, "teal")
	g:line(38, 33 + bob, 49, 44 + sway, "pine"); g:line(49, 44 + sway, 52, 48 + sway, "teal")
	local hem = {}
	hem[#hem + 1] = { 26, 30 + bob }; hem[#hem + 1] = { 38, 30 + bob }
	for x = 43, 21, -4 do
		hem[#hem + 1] = { x, 57 }; hem[#hem + 1] = { x - 2, 52 + (x % 3) }
	end
	g:poly(hem, GREEN, -0.05)
	g:ball(32, 24 + bob, 6, 6, GREEN, 0.05)
	local after = canvas(64, 64)
	for _, side in ipairs({ { 12, 48 }, { 52, 48 } }) do
		after:set(side[1] - 1, side[2] + sway + 1, "lime"); after:set(side[1] + 1, side[2] + sway + 1, "lime")
	end
	local eyes = { { 29, 23 }, { 34, 24 }, { 27, 36 }, { 36, 34 }, { 32, 42 }, { 26, 48 }, { 38, 47 }, { 33, 53 } }
	for i, e in ipairs(eyes) do
		local y = e[2] + (i <= 2 and bob or 0)
		local closed = not atk and ((i + f) % 4 == 0)
		if closed then
			after:line(e[1] - 1, y, e[1] + 1, y, "deep")
		else
			after:line(e[1] - 1, y, e[1] + 1, y, "cream")
			after:set(e[1] + 1, y, atk and "lime" or "black")
		end
	end
	return compose(64, 64, ground_shadow(64, 64, 32, 59, 15, 3), g, after)
end

local function gluttony(anim, f)
	local atk = anim == "attack"
	local sq = pick({ 0, 1, 0, -1 }, f)
	local open = atk and pick({ 2, 5, 7, 3 }, f) or 1
	local g = canvas(64, 64)
	g:ball(32, 37 - sq, 27 + sq, 22 - sq, SACK)
	g:ball(32, 45 - sq, 16, 10, { "rust", "clay", "sand" }, -0.2)
	g:ball(22, 18 - sq, 4, 3, SACK, 0.1); g:ball(34, 16 - sq, 4, 3, SACK, 0.1)
	g:oval(36, 37 - sq, 13, 3 + open, "black")
	g:oval(36, 39 - sq + open, 6, 2, "rose")
	local after = canvas(64, 64)
	for x = 25, 47, 3 do
		after:set(x, 37 - sq - 3 - open + 1, "sand"); after:set(x, 37 - sq - 3 - open + 2, "sand")
		after:set(x + 1, 37 - sq + 3 + open - 1, "sand")
	end
	after:set(22, 18 - sq, "cream"); after:set(34, 16 - sq, "cream")
	after:set(23, 18 - sq, "black"); after:set(35, 16 - sq, "black")
	after:line(30, 41 - sq + open, 30, 46 - sq + open, "sea"); after:set(30, 47 - sq + open, "mint")
	return compose(64, 64, ground_shadow(64, 64, 32, 60, 26, 4), g, after)
end

local function wrath(anim, f)
	local atk = anim == "attack"
	local bob = pick({ 0, -1, 0, 1 }, f)
	local fist = atk and -5 or 0
	local g = canvas(64, 64)
	local flames = canvas(64, 64)
	math.randomseed(100 + f)
	for i = 0, 8 do
		local x = 18 + i * 3.5
		local hgt = math.random(7, 12) + (atk and 6 or 0) - math.abs(x - 32) // 5
		local half = 3
		for y = 0, hgt do
			local t = y / hgt
			local w = math.max(0, math.floor(half * (1 - t) + 0.5))
			local col = FIRE[clamp(math.floor(t * #FIRE) + 1, 1, #FIRE)]
			for dx = -w, w do flames:set(x + dx, 30 - y, col) end
		end
	end
	g:paste(flames)
	g:ball(32, 41 + bob, 14, 13, { "blood", "wine", "rust" })
	g:ball(17, 42 + bob + fist, 4, 4, { "blood", "wine", "rust", "clay" })
	g:ball(47, 42 + bob + fist, 4, 4, { "blood", "wine", "rust", "clay" })
	g:ball(32, 27 + bob, 8, 7, { "blood", "wine", "rust", "clay" })
	for _, side in ipairs({ -1, 1 }) do
		local x0 = 32 + side * 6
		g:line(x0, 23 + bob, x0 + side * 6, 18 + bob, "clay")
		g:line(x0, 22 + bob, x0 + side * 6, 17 + bob, "sand")
		g:line(x0 + side * 6, 17 + bob, x0 + side * 7, 10 + bob, "sand")
		g:line(x0 + side * 7, 17 + bob, x0 + side * 8, 11 + bob, "clay")
	end
	local after = canvas(64, 64)
	after:set(19, 10 + bob, "cream"); after:set(45, 10 + bob, "cream")
	after:line(28, 25 + bob, 30, 26 + bob, "black"); after:line(36, 25 + bob, 34, 26 + bob, "black")
	after:set(29, 27 + bob, "cream"); after:set(30, 27 + bob, "cream")
	after:set(34, 27 + bob, "cream"); after:set(35, 27 + bob, "cream")
	after:line(29, 31 + bob, 35, 31 + bob, "black")
	after:set(30, 32 + bob, "cream"); after:set(34, 32 + bob, "cream")
	return compose(64, 64, ground_shadow(64, 64, 32, 58, 18, 4), g, after)
end

local function sloth(anim, f)
	local atk = anim == "attack"
	local bob = pick({ 0, 0, 1, 1 }, f)
	local droop = atk and -3 or pick({ 2, 3, 3, 2 }, f)
	local g = canvas(64, 64)
	g:ball(34, 48, 23, 8, PURPLE, 0.1)
	g:ball(51, 43, 6, 5, PURPLE, 0.2)
	g:line(49, 39, 50, 31 + droop, "mauve"); g:line(54, 39, 57, 32 + droop, "mauve")
	g:ball(50, 30 + droop, 2, 2, { "sand", "cream" }); g:ball(57, 31 + droop, 2, 2, { "sand", "cream" })
	g:ball(28, 33 + bob, 16, 15, COOL, -0.1)
	local after = canvas(64, 64)
	local rot = f * 0.4
	local prev
	for t = 0, 3 * math.pi, 0.15 do
		local r = t * 1.5
		local x, y = 28 + math.cos(t + rot) * r, 33 + bob + math.sin(t + rot) * r
		if prev then after:line(prev[1], prev[2], x, y, atk and "mint" or "night") end
		prev = { x, y }
	end
	if not atk then
		after:line(49, 29 + droop, 51, 29 + droop, "mauve"); after:line(56, 30 + droop, 58, 30 + droop, "mauve")
		local zy = 18 - (f % 4) * 2
		after:line(55, zy, 57, zy, "sea"); after:line(57, zy, 55, zy + 2, "sea"); after:line(55, zy + 2, 57, zy + 2, "sea")
	end
	after:set(50, 31 + droop, "black"); after:set(57, 32 + droop, "black")
	local slime = canvas(64, 64)
	slime:oval(12, 56, 10, 2, "teal"); slime:line(4, 56, 18, 56, "pine")
	slime:paste(ground_shadow(64, 64, 34, 57, 23, 3.5))
	return compose(64, 64, slime, g, after)
end

local function satan(anim, f)
	local atk = anim == "attack"
	local bob = pick({ 0, -1, -1, 0 }, f)
	local flap = atk and pick({ -4, -7, -7, -4 }, f) or pick({ 0, -2, -3, -1 }, f)
	local g = canvas(64, 64)
	for _, side in ipairs({ -1, 1 }) do
		local function wx(x) return 32 + side * (32 - x) end
		local pts = {
			{ wx(26), 30 + bob }, { wx(10), 9 + flap }, { wx(1), 15 + flap }, { wx(5), 25 },
			{ wx(9), 22 }, { wx(12), 31 }, { wx(16), 28 }, { wx(21), 37 },
		}
		g:poly(pts, { "abyss", "blood", "wine" })
		for _, tip in ipairs({ { 10, 9 + flap }, { 5, 25 }, { 12, 31 } }) do
			g:line(wx(26), 30 + bob, wx(tip[1]), tip[2], "rust")
		end
	end
	g:poly({ { 24, 58 }, { 26, 32 + bob }, { 38, 32 + bob }, { 40, 58 } }, { "black", "blood", "wine", "rust" })
	g:line(32, 47, 32, 58, "black")
	g:ball(32, 36 + bob, 8, 6, { "blood", "wine", "rust" })
	g:line(44, 56, 50, 12 + bob, "clay")
	g:line(47, 13 + bob, 53, 13 + bob, "sand")
	g:line(47, 13 + bob, 47, 8 + bob, "sand"); g:line(50, 13 + bob, 50, 6 + bob, "sand"); g:line(53, 13 + bob, 53, 8 + bob, "sand")
	g:ball(32, 23 + bob, 6, 6, { "blood", "wine", "rust", "clay" })
	for _, side in ipairs({ -1, 1 }) do
		local x = 32 + side * 5
		g:line(x, 19 + bob, x + side * 5, 15 + bob, "sand")
		g:line(x + side * 5, 15 + bob, x + side * 7, 9 + bob, "sand")
		g:line(x + side * 7, 9 + bob, x + side * 5, 5 + bob, "clay")
	end
	local after = canvas(64, 64)
	math.randomseed(300 + f)
	for x = 28, 36 do
		local hgt = math.random(2, 5) + (atk and 3 or 0)
		for y = 0, hgt do after:set(x, 15 + bob - y, FIRE[clamp(math.floor(y / hgt * #FIRE) + 1, 1, #FIRE)]) end
	end
	local eye = atk and "mint" or "cream"
	after:set(29, 23 + bob, eye); after:set(30, 23 + bob, eye); after:set(34, 23 + bob, eye); after:set(35, 23 + bob, eye)
	after:line(28, 22 + bob, 30, 21 + bob, "black"); after:line(36, 22 + bob, 34, 21 + bob, "black")
	after:line(29, 27 + bob, 35, 27 + bob, "black"); after:set(30, 28 + bob, "cream"); after:set(34, 28 + bob, "cream")
	for _, x in ipairs({ 47, 50, 53 }) do after:set(x, (x == 50 and 5 or 7) + bob, atk and "cream" or "sand") end
	return compose(64, 64, ground_shadow(64, 64, 32, 60, 20, 3.5), g, after)
end

---------------------------------------------------------------------------
-- Pickups, projectile, effect (16x16 / 32x32).
---------------------------------------------------------------------------
local function gem(f)
	local bob = pick({ 0, -1, -1, 0 }, f)
	local g = canvas(16, 16)
	g:poly({ { 8, 2 + bob }, { 13, 8 + bob }, { 8, 14 + bob }, { 3, 8 + bob } }, { "navy", "steel", "sea", "mint" }, 0.1)
	g:line(8, 3 + bob, 8, 13 + bob, "sea")
	local after = canvas(16, 16)
	after:set(6, 6 + bob, "mint"); after:set(7, 5 + bob, "mint")
	local spot = pick({ { 10, 5 }, { 11, 8 }, { 9, 11 }, { 5, 8 } }, f)
	after:set(spot[1], spot[2] + bob, "cream")
	return compose(16, 16, nil, g, after)
end

local function heart(f)
	local r = pick({ 3, 3.4, 3.6, 3.2 }, f)
	local g = canvas(16, 16)
	g:ball(6, 6, r, r, ROSE, 0.1); g:ball(10, 6, r, r, ROSE, 0.05)
	g:poly({ { 2.6, 7 }, { 13.4, 7 }, { 8, 13 + (r - 3) } }, ROSE, -0.2)
	local after = canvas(16, 16)
	after:set(5, 5, "sand"); after:set(5, 4, "cream")
	return compose(16, 16, nil, g, after)
end

local function relic(f)
	local bob = pick({ 0, -1, -1, 0 }, f)
	local g = canvas(16, 16)
	g:poly({ { 3, 6 + bob }, { 8, 3 + bob }, { 13, 6 + bob }, { 8, 9 + bob } }, { "clay", "sand", "cream" }, 0.2)
	g:poly({ { 3, 6 + bob }, { 8, 9 + bob }, { 8, 14 + bob }, { 3, 11 + bob } }, { "wine", "rust", "clay" })
	g:poly({ { 8, 9 + bob }, { 13, 6 + bob }, { 13, 11 + bob }, { 8, 14 + bob } }, { "blood", "wine", "rust" })
	local after = canvas(16, 16)
	after:set(5, 9 + bob, "mint"); after:set(5, 10 + bob, "sea")
	after:set(10, 9 + bob, "lime")
	local spot = pick({ { 8, 3 }, { 12, 5 }, { 4, 5 }, { 8, 8 } }, f)
	after:set(spot[1], spot[2] + bob - 1, "cream")
	return compose(16, 16, nil, g, after)
end

local function fireball(f)
	local g = canvas(16, 16)
	local r = pick({ 4.5, 5, 4.7 }, f)
	g:ball(8, 8, r, r, FIRE, 0.15)
	g:set(2, 7 + f % 2, "rust"); g:set(1, 9 - f % 2, "wine"); g:set(3, 10, "rust")
	local after = canvas(16, 16)
	after:set(7, 6, "cream"); after:set(8, 6, "cream"); after:set(7, 7, "cream")
	return compose(16, 16, nil, g, after)
end

local function poof(f)
	local c = canvas(32, 32)
	local r = ({ 3, 6, 9, 11, 12 })[f + 1]
	local keep = ({ 1.0, 0.85, 0.6, 0.35, 0.15 })[f + 1]
	for y = 0, 31 do
		for x = 0, 31 do
			local d = math.sqrt((x + 0.5 - 16) ^ 2 + (y + 0.5 - 16) ^ 2)
			if d <= r and d >= r - 3 and bayer(x, y) < keep then
				c:set(x, y, d > r - 1.5 and "mauve" or "rose")
			end
		end
	end
	if f < 2 then c:ball(16, 16, 3 - f, 3 - f, { "rose", "clay", "cream" }) end
	return c
end

---------------------------------------------------------------------------
-- Environment.
---------------------------------------------------------------------------
local function hash(x, y, seed)
	local n = math.sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453
	return n - math.floor(n)
end

-- First map: a corrupted plain. Everything here is static and low-contrast so the
-- ground stays quiet behind the action.
local function floor_tile(f)
	-- Mostly flat; only soft, sparse texture so the ground stays quiet.
	local c = canvas(32, 32)
	c:rect(0, 0, 32, 32, "blood")
	for y = 0, 31 do
		for x = 0, 31 do
			local n = hash(x // 8, y // 8, f) * 0.7 + hash(x, y, f + 10) * 0.3
			if n > 0.78 and bayer(x, y) < 0.18 then c:set(x, y, "abyss") end
		end
	end
	if f == 1 then
		c:line(7, 19, 11, 21, "wine"); c:line(11, 21, 16, 20, "wine"); c:set(11, 20, "rust")
	elseif f == 2 then
		c:line(18, 8, 21, 11, "abyss"); c:line(21, 11, 20, 14, "abyss")
	elseif f == 3 then
		c:set(9, 24, "plum"); c:set(10, 23, "plum"); c:set(23, 9, "plum")
	end
	return c
end

local function pillar(_)
	local c = canvas(80, 80)
	c:oval(40, 73, 34, 6, "black")
	local g = canvas(80, 80)
	g:poly({ { 8, 30 }, { 72, 30 }, { 72, 72 }, { 8, 72 } }, { "abyss", "night", "navy" }, -0.15)
	g:poly({ { 8, 30 }, { 14, 10 }, { 66, 10 }, { 72, 30 } }, { "night", "navy", "steel" }, 0.1)
	for y = 38, 70, 8 do g:line(9, y, 71, y, "abyss") end
	for y = 30, 70, 8 do
		local off = (y // 8) % 2 == 0 and 0 or 8
		for x = 8 + off, 71, 16 do g:line(x, y, x, math.min(y + 7, 71), "abyss") end
	end
	-- corruption veins over the stone
	g:line(18, 31, 24, 44, "wine"); g:line(24, 44, 21, 58, "wine"); g:line(21, 58, 26, 70, "wine")
	g:line(58, 31, 54, 46, "wine"); g:line(54, 46, 60, 62, "wine")
	g:set(24, 44, "rust"); g:set(54, 46, "rust")
	-- flesh growth and ooze spilling from the top
	math.randomseed(9)
	for _ = 1, 7 do
		g:ball(math.random(16, 64), math.random(12, 26), math.random(3, 5), math.random(2, 4), { "blood", "wine", "rust" })
	end
	for _ = 1, 9 do
		local x = math.random(10, 70)
		local len = math.random(3, 12)
		for y = 30, 30 + len do g:set(x, y, y - 30 < len - 2 and "wine" or "blood") end
	end
	g:outline("black")
	c:paste(g)
	c:line(36, 46, 44, 46, "rust"); c:line(40, 42, 40, 54, "rust"); c:set(37, 50, "rust"); c:set(43, 50, "rust")
	c:set(40, 46, "sand")
	return c
end

local function landing(_)
	local c = canvas(64, 64)
	-- scorched crater where the angel lands, with a faint holy sigil
	for y = 0, 63 do
		for x = 0, 63 do
			local nx, ny = (x + 0.5 - 32) / 30, (y + 0.5 - 32) / 15
			local d = nx * nx + ny * ny
			if d <= 1 and bayer(x, y) < (1 - d) * 0.9 then c:set(x, y, "abyss") end
		end
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + 0.3
		c:line(32 + math.cos(a) * 8, 32 + math.sin(a) * 4, 32 + math.cos(a) * 29, 32 + math.sin(a) * 14, "black")
	end
	for i = 0, 47 do
		local a = i / 48 * math.pi * 2
		if i % 3 ~= 0 then c:set(32 + math.cos(a) * 18, 32 + math.sin(a) * 9, "navy") end
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		c:set(32 + math.cos(a) * 18, 32 + math.sin(a) * 9, "steel")
	end
	return c
end

local function mushroom(_)
	local g = canvas(32, 32)
	g:rect(15, 18, 3, 9, "clay"); g:set(15, 26, "rust")
	g:ball(16, 17, 9, 5.5, { "blood", "wine", "rust" }, 0.05)
	g:rect(22, 23, 2, 4, "clay"); g:ball(23, 23, 3.5, 2.5, { "blood", "wine", "rust" })
	local after = canvas(32, 32)
	for _, p in ipairs({ { 12, 15 }, { 17, 13 }, { 20, 16 }, { 23, 22 } }) do after:set(p[1], p[2], "sand") end
	return compose(32, 32, ground_shadow(32, 32, 17, 27, 9, 2), g, after)
end

local function deadgrass(_)
	local c = canvas(32, 32)
	local blades = { { 10, 5, 0 }, { 12, 8, -1 }, { 14, 4, 1 }, { 16, 9, 0 }, { 18, 6, 1 }, { 20, 7, -1 }, { 22, 4, 0 } }
	for i, b in ipairs(blades) do
		c:line(b[1], 27, b[1] + b[3], 27 - b[2], ({ "plum", "mauve", "wine" })[(i % 3) + 1])
	end
	return c
end

local function rock(_)
	local g = canvas(32, 32)
	g:ball(16, 23, 9, 5.5, { "abyss", "night", "navy", "steel" }, -0.2)
	g:ball(21, 24, 5, 3.5, { "abyss", "night", "navy", "steel" }, -0.1)
	for x = 11, 19, 2 do g:set(x, 18, "wine") end
	g:set(13, 19, "wine"); g:set(13, 20, "blood")
	return compose(32, 32, ground_shadow(32, 32, 17, 27, 11, 2), g)
end

local function thorns(_)
	local g = canvas(32, 32)
	local branches = { { 16, 27, 8, 12 }, { 16, 27, 24, 10 }, { 15, 27, 13, 6 }, { 17, 27, 21, 16 }, { 16, 27, 5, 19 }, { 16, 27, 27, 20 } }
	for _, br in ipairs(branches) do
		g:line(br[1], br[2], br[3], br[4], "blood")
		local mx, my = (br[1] + br[3]) / 2, (br[2] + br[4]) / 2
		g:set(mx - 1, my, "wine"); g:set(br[3], br[4], "wine")
	end
	g:outline("black")
	return g
end

local function bones(_)
	local g = canvas(32, 32)
	g:ball(11, 22, 4, 3.5, { "rust", "clay", "sand" })
	for i = 0, 3 do
		g:line(16 + i * 3, 19, 16 + i * 3, 25, "clay"); g:set(16 + i * 3, 19, "sand")
	end
	g:line(15, 22, 27, 22, "clay")
	local after = canvas(32, 32)
	after:set(10, 22, "black"); after:set(12, 22, "black")
	return compose(32, 32, ground_shadow(32, 32, 18, 26, 11, 2), g, after)
end

local function pool(_)
	local c = canvas(32, 32)
	c:oval(16, 23, 13, 5.5, "wine")
	c:oval(16, 23, 11.5, 4.5, "black")
	c:oval(15, 22, 6, 2, "abyss")
	c:set(11, 21, "mauve"); c:set(12, 21, "mauve"); c:set(20, 25, "plum")
	c:set(24, 19, "wine"); c:set(25, 18, "plum")
	return c
end

local function crystal(_)
	local g = canvas(32, 32)
	local ramp = { "blood", "wine", "rust", "clay" }
	g:poly({ { 13, 27 }, { 15, 9 }, { 18, 27 } }, ramp, 0.1)
	g:poly({ { 8, 27 }, { 9, 16 }, { 13, 27 } }, ramp)
	g:poly({ { 18, 27 }, { 23, 14 }, { 23, 27 } }, ramp, -0.05)
	local after = canvas(32, 32)
	after:set(15, 11, "sand"); after:set(15, 12, "clay"); after:set(22, 16, "sand")
	return compose(32, 32, ground_shadow(32, 32, 16, 27, 10, 2), g, after)
end

local function growth(_)
	local g = canvas(32, 32)
	local ramp = { "blood", "wine", "rust" }
	g:ball(13, 23, 6, 4.5, ramp); g:ball(20, 24, 5, 3.5, ramp); g:ball(16, 19, 4, 3.5, ramp, 0.1)
	local after = canvas(32, 32)
	after:set(15, 17, "clay"); after:set(12, 21, "clay"); after:set(19, 22, "clay")
	return compose(32, 32, ground_shadow(32, 32, 16, 27, 11, 2), g, after)
end

local function deadtree(_)
	local g = canvas(32, 32)
	g:line(16, 28, 15, 18, "abyss"); g:line(17, 28, 16, 18, "night")
	g:line(15, 18, 14, 10, "abyss"); g:line(14, 10, 12, 4, "abyss")
	g:line(15, 16, 9, 11, "abyss"); g:line(9, 11, 7, 12, "abyss")
	g:line(16, 14, 22, 9, "abyss"); g:line(22, 9, 24, 5, "abyss"); g:line(22, 9, 26, 10, "abyss")
	g:line(14, 10, 17, 6, "abyss")
	g:outline("black")
	local base = canvas(32, 32)
	base:paste(ground_shadow(32, 32, 16, 28, 7, 1.5))
	base:paste(g)
	return base
end

---------------------------------------------------------------------------
-- Write every file.
---------------------------------------------------------------------------
build("player", 32, 32, {
	{ "idle", 4, 0.16, function(f) return player("idle", f) end },
	{ "run", 4, 0.1, function(f) return player("run", f) end },
	{ "dash", 2, 0.06, function(f) return player("dash", f) end },
	{ "jump", 2, 0.12, function(f) return player("jump", f) end },
	{ "descend", 4, 0.1, function(f) return player("descend", f) end },
})
build("spear_light", 48, 16, { { "idle", 4, 0.08, light_spear } })
build("vfx_slash", 128, 128, { { "_slash", 5, 0.05, slash } })
build("enemy_husk", 32, 32, { { "walk", 4, 0.14, husk } })
build("enemy_imp", 32, 32, { { "walk", 4, 0.08, imp } })
build("enemy_brute", 32, 32, { { "walk", 4, 0.18, brute } })

local bosses = {
	pride = pride, greed = greed, lust = lust, envy = envy,
	gluttony = gluttony, wrath = wrath, sloth = sloth, satan = satan,
}
for name, fn in pairs(bosses) do
	build("boss_" .. name, 64, 64, {
		{ "idle", 4, 0.18, function(f) return fn("idle", f) end },
		{ "attack", 4, 0.1, function(f) return fn("attack", f) end },
	})
end

build("pickup_xp", 16, 16, { { "idle", 4, 0.14, gem } })
build("pickup_life", 16, 16, { { "idle", 4, 0.16, heart } })
build("pickup_item", 16, 16, { { "idle", 4, 0.16, relic } })
build("projectile_fire", 16, 16, { { "fly", 3, 0.08, fireball } })
build("vfx_poof", 32, 32, { { "_poof", 5, 0.06, poof } })
build("env_floor", 32, 32, { { "tiles", 4, 1.0, floor_tile } })
build("env_pillar", 80, 80, { { "idle", 1, 1.0, pillar } })
build("env_landing", 64, 64, { { "idle", 1, 1.0, landing } })
build("env_decor", 32, 32, {
	{ "mushroom", 1, 1.0, mushroom },
	{ "deadgrass", 1, 1.0, deadgrass },
	{ "rock", 1, 1.0, rock },
	{ "thorns", 1, 1.0, thorns },
	{ "bones", 1, 1.0, bones },
	{ "pool", 1, 1.0, pool },
	{ "crystal", 1, 1.0, crystal },
	{ "growth", 1, 1.0, growth },
	{ "deadtree", 1, 1.0, deadtree },
})
