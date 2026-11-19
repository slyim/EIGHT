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
		bob = pick({ 0, 0, 1, 1 }, f); wing = pick({ 0, -1, 0, 1 }, f)
	elseif anim == "run" then
		bob = pick({ 0, -1, 0, -1 }, f); stride = pick({ -1, 1, 1, -1 }, f); wing = pick({ 1, -1, -2, 0 }, f)
	elseif anim == "dash" then
		lean = 1; stride = 1; wing = 2
	elseif anim == "jump" then
		tuck = true; wing = pick({ -3, -1 }, f)
	elseif anim == "descend" then
		tuck = true; spread = true; wing = pick({ -3, -1, 1, 0 }, f)
	end
	local under = canvas(32, 32)
	if anim == "dash" then
		under:line(0, 12 + f, 5, 12 + f, "sea")
		under:line(1, 18, 4, 18, "steel")
		under:line(0, 24 - f, 3, 24 - f, "sea")
	end
	local g = canvas(32, 32)
	local b = bob
	-- A broad, low ox silhouette: switching legs, swishing tail, muzzle and horns.
	g:line(6, 18 + b, 2, 21 + b, "abyss")
	g:set(1, 22 + b, "black"); g:set(2, 22 + b, "black"); g:set(2, 23 + b, "black")
	local leg = tuck and 2 or 4
	g:rect(7 + stride, 24 + b, 3, leg, "black")
	g:rect(12 - stride, 25 + b, 2, leg - 1, "abyss")
	g:rect(19 + stride, 24 + b, 3, leg, "black")
	g:rect(22 - stride, 24 + b, 2, leg, "abyss")
	g:ball(14, 21 + b, 10, 5.5, OX_BLACK, -0.05)
	g:line(6, 19 + b, 10, 17 + b, "navy")
	g:rect(10, 17 + b, 8, 3, "plum")
	g:line(10, 20 + b, 18, 20 + b, "mauve")
	local hx = 24 + lean
	g:ball(hx, 20 + b, 4, 3.5, OX_BLACK, 0.05)
	g:rect(hx + 2, 20 + b, 3, 2, "night")
	g:line(hx - 2, 17 + b, hx - 4, 16 + b, "navy")
	g:line(hx - 2, 17 + b, hx - 3, 14 + b, "clay")
	g:line(hx - 3, 14 + b, hx - 2, 12 + b, "sand"); g:set(hx - 2, 12 + b, "cream")
	g:line(hx + 1, 17 + b, hx + 4, 14 + b, "clay")
	g:line(hx + 4, 14 + b, hx + 5, 12 + b, "sand"); g:set(hx + 5, 12 + b, "cream")
	-- Feathered silver wings sit behind the rider, opening wide for the descent.
	if spread then
		local wy = 5 + b + wing
		g:poly({ { 12, 13 + b }, { 7, 5 + b }, { 3, wy }, { 1, wy + 4 }, { 4, wy + 8 }, { 6, wy + 6 }, { 7, 15 + b }, { 10, 17 + b } }, WING, 0.15)
		g:poly({ { 16, 12 + b }, { 22, 4 + b }, { 27, wy - 1 }, { 29, wy + 3 }, { 26, wy + 7 }, { 24, wy + 5 }, { 22, 14 + b }, { 19, 16 + b } }, WING, 0.1)
		g:line(3, wy + 3, 11, 13 + b, "sea"); g:line(27, wy + 2, 18, 13 + b, "sea")
		g:line(5, wy + 6, 10, 15 + b, "mint"); g:line(25, wy + 5, 20, 14 + b, "mint")
	elseif anim == "dash" then
		g:poly({ { 13, 12 + b }, { 5, 8 + b }, { 1, 10 + b }, { 3, 13 + b }, { 6, 12 + b }, { 8, 16 + b }, { 12, 16 + b } }, WING, 0.15)
		g:line(2, 11 + b, 11, 14 + b, "mint")
	else
		local wy = 5 + b + wing
		g:poly({ { 12, 13 + b }, { 8, 6 + b }, { 4, wy }, { 2, wy + 3 }, { 4, wy + 7 }, { 6, wy + 5 }, { 6, 15 + b }, { 9, 14 + b }, { 10, 17 + b } }, WING, 0.15)
		g:line(4, wy + 3, 11, 13 + b, "sea")
		g:line(5, wy + 6, 9, 15 + b, "mint")
	end
	-- Cinched purple cloak, long hair and a small face keep the rider feminine.
	local rx = lean
	g:poly({ { 12 + rx, 8 + b }, { 16 + rx, 8 + b }, { 18 + rx, 12 + b }, { 21 + rx, 19 + b }, { 14 + rx, 20 + b }, { 8 + rx, 18 + b }, { 10 + rx, 13 + b } }, ROBE, 0.1)
	g:line(13 + rx, 13 + b, 17 + rx, 13 + b, "rose")
	g:line(13 + rx, 14 + b, 12 + rx, 18 + b, "plum")
	g:line(16 + rx, 14 + b, 18 + rx, 18 + b, "mauve")
	g:line(9 + rx, 18 + b, 19 + rx, 19 + b, "rose")
	g:line(17 + rx, 12 + b, 21 + rx, 13 + b, "mauve")
	g:set(21 + rx, 14 + b, "sand")
	g:ball(14 + rx, 8 + b, 3.5, 3.8, ROBE, 0.15)
	g:line(11 + rx, 6 + b, 10 + rx, 10 + b, "rose")
	local after = canvas(32, 32)
	after:rect(15 + rx, 7 + b, 2, 3, "sand")
	after:set(16 + rx, 7 + b, "cream"); after:set(16 + rx, 8 + b, "black")
	after:line(15 + rx, 10 + b, 16 + rx, 13 + b, "sand")
	after:set(17 + rx, 13 + b, "cream"); after:set(16 + rx, 14 + b, "clay")
	after:set(hx + 2, 18 + b, "mint"); after:set(hx + 4, 21 + b, "steel")
	local hy = 1 + b + pick({ 0, 0, -1, 0 }, f)
	after:line(12 + rx, hy, 16 + rx, hy, "cream")
	after:set(11 + rx, hy + 1, "sand"); after:set(17 + rx, hy + 1, "sand")
	after:line(12 + rx, hy + 2, 16 + rx, hy + 2, "sand")
	return compose(32, 32, under, g, after)
end

---------------------------------------------------------------------------
-- Light spear: a trident of blue-white light (48x16, pivot at left middle).
---------------------------------------------------------------------------
local function light_spear(f)
	local c = canvas(48, 16)
	-- Sparse dithered radiance leaves the dark grip quiet at the left-hand pivot.
	for y = 1, 14 do
		for x = 7, 47 do
			local near = (y >= 5 and y <= 11 and x <= 37) or (x >= 33 and y >= 1 and y <= 14)
			if near and bayer(x + f, y) < 0.24 then c:set(x, y, x > 34 and "steel" or "navy") end
		end
	end
	c:line(0, 8, 8, 8, "night"); c:line(0, 7, 7, 7, "steel")
	for _, x in ipairs({ 2, 5, 8 }) do
		c:set(x, 7, "sand"); c:set(x, 8, "clay")
	end
	c:line(8, 8, 36, 8, "cream")
	c:line(9, 7, 35, 7, "mint"); c:line(9, 9, 35, 9, "sea")
	-- A winged, leaf-shaped holy point rather than a mundane metal spearhead.
	c:poly({ { 34, 8 }, { 40, 2 }, { 41, 6 }, { 47, 8 }, { 41, 10 }, { 40, 14 } }, { "steel", "sea", "mint", "cream" }, 0.15)
	c:line(36, 8, 46, 8, "cream"); c:line(40, 4, 40, 12, "mint")
	c:line(32, 4, 35, 6, "sand"); c:line(32, 12, 35, 10, "sand")
	c:set(31, 3, "cream"); c:set(31, 13, "cream")
	local s = 10 + f * 6
	c:set(s, 8, "cream"); c:set(s, 6, "mint"); c:set(s - 1, 8, "mint")
	c:set(46 - f % 2, 7, "cream"); c:set(45, 9 + f % 2, "mint")
	return c
end

---------------------------------------------------------------------------
-- Combo finisher arc of light (128x128, centered, faces right).
---------------------------------------------------------------------------
local function slash(f)
	local c = canvas(128, 128)
	local reach = ({ 0.2, 0.58, 1.0, 1.0, 1.0 })[f + 1]
	local keep = ({ 1.0, 1.0, 1.0, 0.62, 0.28 })[f + 1]
	local half = math.rad(105)
	for y = 0, 127 do
		for x = 0, 127 do
			local dx, dy = x + 0.5 - 64, y + 0.5 - 64
			local d = math.sqrt(dx * dx + dy * dy)
			local a = math.atan(dy, dx)
			if math.abs(a) <= half then
				local along = (a + half) / (2 * half)
				if along <= reach then
					local taper = math.sin(along / reach * math.pi * 0.5)
					if reach >= 1 then taper = math.sin(along * math.pi) end
					local outer = 43 + 17 * taper
					local inner = outer - (3 + 9 * taper)
					if d >= inner and d <= outer and bayer(x + f, y) < keep then
						local t = (d - inner) / math.max(1, outer - inner)
						local col = t > 0.78 and "mint" or (t > 0.35 and "sea" or "steel")
						if along > reach - 0.025 and t > 0.35 then col = "cream" end
						c:set(x, y, col)
					end
					-- A broken inner trail makes the last hit feel broad and forceful.
					if f >= 1 and d >= 35 and d <= 39 + 3 * taper and along < reach - 0.05 and bayer(x, y + f) < keep * 0.58 then
						c:set(x, y, along > reach - 0.12 and "mint" or "steel")
					end
				end
			end
		end
	end
	if f < 4 then
		local a = -half + 2 * half * reach
		local tip_r = reach >= 1 and 43 or 60
		local x, y = 64 + math.cos(a) * tip_r, 64 + math.sin(a) * tip_r
		c:line(x - 3, y, x + 3, y, "mint")
		c:line(x, y - 3, x, y + 3, "mint")
		c:set(x, y, "cream")
	end
	return c
end

---------------------------------------------------------------------------
-- Horde enemies (32x32, face right).
---------------------------------------------------------------------------
local function husk(f)
	local bob = pick({ 0, 1, 0, 1 }, f)
	local step = pick({ -1, 0, 1, 0 }, f)
	local drag = pick({ 0, 1, 1, 0 }, f)
	local g = canvas(32, 32)
	-- Bare feet and an uneven, dragging gait under a colourless winding sheet.
	g:line(13, 24, 11 + step, 28, "navy"); g:set(10 + step, 28, "steel")
	g:line(18, 23, 18 - step, 27 + drag, "abyss"); g:set(19 - step, 27 + drag, "steel")
	g:line(12, 15 + bob, 8, 21 + bob - step, "navy")
	g:line(8, 21 + bob - step, 7, 25 + bob, "steel")
	g:poly({ { 13, 13 + bob }, { 18, 12 + bob }, { 22, 17 + bob }, { 20, 24 }, { 18, 23 }, { 17, 27 }, { 14, 25 }, { 12, 27 }, { 11, 23 }, { 8, 24 }, { 10, 17 + bob } }, { "abyss", "night", "navy", "steel" }, 0.05)
	g:line(12, 16 + bob, 10, 21 + bob, "steel")
	g:line(17, 16 + bob, 18, 22 + bob, "navy")
	-- The bowed skull and one reaching arm sell a soul rather than a beast.
	g:ball(18, 11 + bob, 4.5, 4.5, { "night", "navy", "steel", "sea" }, -0.1)
	g:poly({ { 16, 9 + bob }, { 21, 9 + bob }, { 22, 12 + bob }, { 20, 15 + bob }, { 17, 14 + bob } }, { "navy", "steel", "sea" }, -0.05)
	g:line(20, 16 + bob, 24, 20 + bob + step, "navy")
	g:line(21, 16 + bob, 25, 20 + bob + step, "steel")
	g:line(25, 20 + bob + step, 26, 24 + bob + step, "sea")
	g:set(27, 24 + bob + step, "sea"); g:set(26, 25 + bob + step, "steel")
	local glow = canvas(32, 32)
	glow:line(18, 10 + bob, 20, 10 + bob, "black")
	glow:set(20, 11 + bob, "cream"); glow:set(21, 11 + bob, "sea") -- cream = the eye glow key
	glow:line(19, 14 + bob, 21, 14 + bob, "black")
	glow:oval(15, 18 + bob, 2, 2, "black")
	glow:set(15, 17 + bob, "sea"); glow:set(15, 18 + bob, "mint")
	return compose(32, 32, ground_shadow(32, 32, 16, 28, 7, 1.8), g, glow)
end

local function imp(f)
	local h = pick({ 1, 0, -1, 0 }, f)
	local flap = pick({ 3, 0, -3, 0 }, f)
	local g = canvas(32, 32)
	local wy = 7 + h + flap
	-- Oversized scalloped bat wings around a tiny, forward-leaning body.
	g:poly({ { 14, 16 + h }, { 8, 9 + h }, { 3, wy - 1 }, { 1, wy + 3 }, { 5, wy + 5 }, { 6, wy + 3 }, { 7, 17 + h }, { 10, 15 + h }, { 11, 20 + h } }, { "blood", "wine", "rust" }, -0.05)
	g:poly({ { 19, 15 + h }, { 24, 9 + h }, { 28, wy }, { 30, wy + 4 }, { 26, wy + 5 }, { 25, wy + 3 }, { 24, 17 + h }, { 22, 15 + h }, { 20, 19 + h } }, { "blood", "wine", "rust" }, 0.05)
	g:line(14, 16 + h, 3, wy, "rust"); g:line(14, 16 + h, 6, wy + 4, "wine")
	g:line(19, 15 + h, 28, wy + 1, "rust"); g:line(19, 15 + h, 26, wy + 5, "wine")
	-- A barbed tail and dangling claws leave clearance above the ground shadow.
	g:line(14, 21 + h, 9, 24 + h, "wine"); g:line(9, 24 + h, 5, 22 + h, "rust")
	g:poly({ { 5, 22 + h }, { 2, 20 + h }, { 3, 24 + h } }, { "wine", "rust", "clay" })
	g:line(15, 22 + h, 13, 26 + h, "rust"); g:set(12, 26 + h, "black")
	g:line(19, 21 + h, 21, 25 + h, "rust"); g:set(22, 25 + h, "black")
	g:ball(17, 19 + h, 4, 4.5, FIRE, -0.25)
	g:line(14, 17 + h, 11, 20 + h, "rust")
	g:line(20, 17 + h, 23, 19 + h, "clay"); g:set(24, 19 + h, "sand")
	g:ball(19, 13 + h, 3.5, 3.5, FIRE, -0.05)
	g:poly({ { 16, 12 + h }, { 15, 7 + h }, { 18, 10 + h } }, { "clay", "sand", "cream" })
	g:poly({ { 20, 10 + h }, { 23, 6 + h }, { 22, 12 + h } }, { "clay", "sand", "cream" })
	local glow = canvas(32, 32)
	glow:set(20, 12 + h, "cream"); glow:set(21, 13 + h, "cream")
	glow:set(22, 15 + h, "black"); glow:set(21, 15 + h, "sand")
	return compose(32, 32, ground_shadow(32, 32, 16, 28, 5, 1.5), g, glow)
end

local function brute(f)
	local bob = pick({ 0, 1, 0, 1 }, f)
	local la = pick({ 0, -1, 0, 0 }, f)
	local lb = pick({ 0, 0, 0, -1 }, f)
	local g = canvas(32, 32)
	-- Heavy split hooves and huge knuckles carry most of the silhouette's weight.
	g:rect(10, 24 + la, 5, 4, "night"); g:rect(19, 24 + lb, 5, 4, "night")
	g:set(12, 28 + la, "steel"); g:set(21, 28 + lb, "steel")
	g:ball(8, 20 + bob - la, 4, 6, { "blood", "wine", "rust" }, -0.1)
	g:ball(24, 21 + bob - lb, 4.5, 6, { "blood", "wine", "rust", "clay" }, -0.05)
	g:ball(7, 25 + bob - la, 4, 3, { "blood", "wine", "rust" }, -0.1)
	g:ball(25, 25 + bob - lb, 4, 3, { "blood", "wine", "rust" }, -0.1)
	g:ball(15, 18 + bob, 11, 8, { "blood", "wine", "rust", "clay" }, -0.1)
	g:poly({ { 9, 21 + bob }, { 21, 21 + bob }, { 23, 27 }, { 8, 27 } }, { "black", "night", "navy" })
	g:line(9, 22 + bob, 21, 22 + bob, "steel")
	for _, x in ipairs({ 10, 15, 20 }) do g:set(x, 22 + bob, "sand") end
	-- Forward-thrust bull horns, a low brow and tusks distinguish it from the ox.
	local hx, hy = 23, 13 + bob
	g:ball(hx, hy, 5, 4.5, { "blood", "wine", "rust", "clay" }, 0.05)
	g:line(20, hy - 2, 17, hy - 6, "clay"); g:line(19, hy - 2, 16, hy - 6, "sand")
	g:line(17, hy - 6, 16, hy - 10, "sand"); g:set(16, hy - 10, "cream")
	g:line(25, hy - 3, 28, hy - 7, "clay"); g:line(26, hy - 3, 29, hy - 7, "sand")
	g:line(28, hy - 7, 29, hy - 10, "sand"); g:set(29, hy - 10, "cream")
	g:line(20, hy - 1, 26, hy - 1, "blood")
	g:rect(24, hy + 2, 4, 2, "wine")
	local glow = canvas(32, 32)
	glow:set(25, hy, "cream"); glow:set(26, hy, "cream")
	glow:set(27, hy + 2, "black"); glow:set(26, hy + 3, "black")
	glow:set(25, hy + 4, "sand"); glow:set(27, hy + 4, "sand")
	glow:set(6, 24 + bob - la, "clay"); glow:set(26, 24 + bob - lb, "clay")
	return compose(32, 32, ground_shadow(32, 32, 16, 29, 12, 2), g, glow)
end

---------------------------------------------------------------------------
-- Bosses (64x64, top-down 3/4 view facing right). PLACEHOLDER sprites.
-- Each: idle (4 frames) and attack (4 frames: wind-up -> strike -> recoil).
---------------------------------------------------------------------------
-- Pride = Odin (one-eyed, horned Viking helm, spear Gungnir, two ravens; red).
local function pride(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ 0, -1, 1, 0 }, f) or pick({ 0, -1, -1, 0 }, f)
	local lean = atk and pick({ -2, -3, 3, 1 }, f) or 0
	local cape = atk and pick({ 2, 4, -2, 0 }, f) or pick({ 0, 1, 2, 1 }, f)
	local rflap = atk and pick({ -2, -4, 3, 0 }, f) or pick({ 0, -2, -1, 1 }, f)
	local RED = { "blood", "wine", "rust", "clay" }
	local ARMOR = { "night", "navy", "steel", "sea" }
	local BEARD = { "steel", "sea", "mint" }
	local RAVEN = { "black", "abyss", "night", "navy" }
	local g = canvas(64, 64)
	local cx = 29 + lean
	-- Billowing crimson war-cloak trailing left
	g:poly({
		{ cx - 4, 28 + bob }, { cx - 16 - cape, 38 + bob }, { cx - 18 - cape, 54 },
		{ cx - 10 - cape // 2, 57 }, { cx + 5, 55 }, { cx + 7, 29 + bob },
	}, RED, 0.05)
	g:line(cx - 12 - cape // 2, 39 + bob, cx - 15 - cape, 53, "blood")
	g:line(cx - 6, 36 + bob, cx - 8 - cape // 2, 55, "blood")
	g:line(cx - 17 - cape, 54, cx - 10 - cape // 2, 57, "sand")
	-- Armored legs & boots planted near shadow
	g:rect(cx - 6, 49, 5, 8, "night")
	g:rect(cx - 5, 50, 3, 6, "navy")
	g:rect(cx + 2, 49, 5, 8, "night")
	g:rect(cx + 3, 50, 3, 6, "steel")
	g:line(cx - 6, 56, cx - 1, 56, "steel")
	g:line(cx + 2, 56, cx + 8, 56, "sea")
	-- Broad armored torso & crimson surcoat
	g:poly({
		{ cx - 7, 49 + bob }, { cx - 9, 30 + bob }, { cx + 9, 30 + bob }, { cx + 7, 49 + bob },
	}, ARMOR, 0.05)
	g:poly({
		{ cx - 4, 52 + bob }, { cx - 4, 32 + bob }, { cx + 5, 32 + bob }, { cx + 5, 52 + bob },
	}, RED, 0.1)
	g:rect(cx - 8, 43 + bob, 16, 3, "clay")
	g:line(cx - 7, 44 + bob, cx + 7, 44 + bob, "sand")
	g:rect(cx + 1, 43 + bob, 3, 3, "cream")
	-- Broad pauldrons & cloak brooch
	g:ball(cx - 8, 31 + bob, 5, 4, ARMOR, 0.1)
	g:ball(cx + 8, 31 + bob, 4.5, 4, ARMOR, 0.15)
	g:oval(cx + 2, 33 + bob, 2, 2, "sand")
	-- Back raven (Huginn) perched on Odin's left shoulder
	local rx, ry = cx - 11, 24 + bob
	g:poly({
		{ rx, ry }, { rx - 8, ry - 4 + rflap }, { rx - 9, ry + 1 + rflap }, { rx - 3, ry + 3 },
	}, RAVEN, 0.05)
	g:ball(rx, ry + 1, 3.5, 2.8, RAVEN, 0.1)
	g:ball(rx + 2, ry - 2, 2.2, 2, RAVEN, 0.2)
	g:line(rx + 4, ry - 2, rx + 7, ry - 1, "sand")
	-- Head, flowing silver beard, horned Viking helm (facing 3/4 right)
	local hx, hy = cx + 1, 21 + bob
	g:oval(hx, hy + 2, 6, 6, "black")
	g:ball(hx, hy + 1, 5.2, 5.2, { "rust", "clay", "sand" }, 0.05)
	-- Silver beard sweeping right-down with dark under-edge
	g:poly({
		{ hx - 3, hy + 5 }, { hx + 6, hy + 4 }, { hx + 9, hy + 9 },
		{ hx + 4, hy + 14 }, { hx - 2, hy + 11 },
	}, { "black", "night" })
	g:poly({
		{ hx - 2, hy + 4 }, { hx + 6, hy + 3 }, { hx + 8, hy + 8 },
		{ hx + 4, hy + 13 }, { hx - 1, hy + 10 },
	}, BEARD, 0.15)
	g:line(hx + 2, hy + 5, hx + 4, hy + 11, "sea")
	-- Viking iron helm & sweeping curved horns
	g:poly({
		{ hx - 5, hy - 2 }, { hx - 11, hy - 5 }, { hx - 13, hy - 12 },
		{ hx - 10, hy - 13 }, { hx - 8, hy - 7 }, { hx - 4, hy - 5 },
	}, GOLD, 0.1)
	g:poly({
		{ hx + 3, hy - 3 }, { hx + 9, hy - 6 }, { hx + 11, hy - 13 },
		{ hx + 8, hy - 14 }, { hx + 6, hy - 8 }, { hx + 2, hy - 5 },
	}, GOLD, 0.15)
	g:ball(hx - 0.5, hy - 2.5, 6, 4.2, ARMOR, 0.15)
	g:line(hx - 6, hy - 1, hx + 5, hy - 1, "sand")
	g:line(hx - 6, hy - 2, hx + 5, hy - 2, "clay")
	g:rect(hx + 2, hy - 2, 2, 4, "steel")
	-- Spear Gungnir & right gauntleted arm (clear wind-up -> forward thrust)
	local sx0, sy0, sx1, sy1, ax, ay
	if not atk then
		sx0, sy0 = cx - 4, 48 + bob
		sx1, sy1 = cx + 22, 16 + bob
		ax, ay = cx + 10, 36 + bob
	elseif f == 0 then
		sx0, sy0 = cx - 14, 34 + bob
		sx1, sy1 = cx + 15, 22 + bob
		ax, ay = cx + 3, 31 + bob
	elseif f == 1 then
		sx0, sy0 = cx - 16, 30 + bob
		sx1, sy1 = cx + 13, 19 + bob
		ax, ay = cx + 1, 29 + bob
	elseif f == 2 then
		sx0, sy0 = cx - 9, 36 + bob
		sx1, sy1 = cx + 23, 32 + bob
		ax, ay = cx + 11, 34 + bob
	else
		sx0, sy0 = cx - 6, 40 + bob
		sx1, sy1 = cx + 22, 27 + bob
		ax, ay = cx + 10, 35 + bob
	end
	g:line(cx + 8, 32 + bob, ax, ay, "steel")
	g:line(cx + 8, 33 + bob, ax, ay + 1, "navy")
	g:line(sx0, sy0, sx1, sy1, "clay")
	g:line(sx0, sy0 + 1, sx1, sy1 + 1, "sand")
	g:ball(ax, ay, 2.5, 2.5, ARMOR, 0.2)
	-- Spearhead diamond blade
	local dx, dy = sx1 - sx0, sy1 - sy0
	local len = math.max(1, math.sqrt(dx * dx + dy * dy))
	local ux, uy = dx / len, dy / len
	local px, py = -uy, ux
	g:poly({
		{ sx1 - ux * 2 + px * 2.5, sy1 - uy * 2 + py * 2.5 },
		{ sx1 + ux * 5.5, sy1 + uy * 5.5 },
		{ sx1 - ux * 2 - px * 2.5, sy1 - uy * 2 - py * 2.5 },
		{ sx1 - ux * 5, sy1 - uy * 5 },
	}, { "steel", "sea", "mint" }, 0.2)
	g:line(sx1 - ux * 3 + px * 3, sy1 - uy * 3 + py * 3, sx1 - ux * 3 - px * 3, sy1 - uy * 3 - py * 3, "sand")
	-- Second raven (Muninn) swooping upper-right with clear separation from horn
	local fx = 52 + (atk and pick({ -2, -4, 2, 1 }, f) or pick({ 0, 1, 0, -1 }, f))
	local fy = 10 + (atk and pick({ -1, -2, 5, 2 }, f) or pick({ 0, -1, -2, -1 }, f))
	g:poly({
		{ fx - 5, fy - 3 + rflap // 2 }, { fx, fy }, { fx - 4, fy + 2 }, { fx - 8, fy - 1 },
	}, RAVEN, 0.1)
	g:poly({
		{ fx, fy - 1 }, { fx + 4, fy - 4 - rflap // 2 }, { fx + 6, fy - 1 }, { fx + 2, fy + 1 },
	}, RAVEN, 0.15)
	g:oval(fx, fy, 3, 2, "abyss")
	g:line(fx + 3, fy, fx + 5, fy + 1, "sand")
	-- Focal details: eyepatch, single glowing eye, horn & spear glints
	local after = canvas(64, 64)
	after:line(hx - 4, hy - 1, hx + 1, hy + 2, "black")
	after:rect(hx - 1, hy, 3, 2, "black")
	after:set(hx + 3, hy + 1, (atk and (f == 1 or f == 2)) and "mint" or "cream")
	if atk and (f == 1 or f == 2) then after:set(hx + 4, hy + 1, "sea") end
	after:set(hx - 11, hy - 12, "cream")
	after:set(hx + 10, hy - 13, "cream")
	after:set(rx + 3, ry - 2, "cream")
	after:set(fx + 2, fy, "cream")
	after:set(sx1 + ux * 5, sy1 + uy * 5, "cream")
	if atk and f == 1 then
		after:set(sx1 + ux * 5.5, sy1 + uy * 5.5, "mint")
		after:set(sx1 + ux * 4, sy1 + uy * 4 - 2, "cream")
	elseif atk and f == 2 then
		after:line(sx1 - 6, sy1 - 3, clamp(sx1 + 5, 2, 61), sy1 - 2, "mint")
		after:line(sx1 - 4, sy1 + 3, clamp(sx1 + 4, 2, 61), sy1 + 2, "cream")
	end
	return compose(64, 64, ground_shadow(64, 64, 30, 58, 16, 3.5), g, after)
end

-- Greed = Midas (tall gold crown, gilded royal robe, golden hands, coin mound; yellow).
local function greed(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ 1, -1, 0, 1 }, f) or pick({ 0, 1, 1, 0 }, f)
	local lean = atk and pick({ -2, -1, 3, 1 }, f) or 0
	local rub = pick({ 0, -1, 0, 1 }, f)
	local ROBE_LINING = { "blood", "wine", "rust", "clay" }
	local g = canvas(64, 64)
	local cx = 30 + lean
	-- Heaped mound of gold coins around Midas's feet
	g:poly({ { 11, 58 }, { 17, 51 }, { 45, 51 }, { 53, 58 } }, { "rust", "clay", "sand" }, -0.05)
	local pile = {
		{ 15, 56 }, { 21, 54 }, { 27, 56 }, { 34, 55 }, { 41, 56 }, { 48, 56 },
		{ 19, 57 }, { 29, 58 }, { 38, 57 }, { 45, 53 }, { 24, 52 }, { 37, 53 },
	}
	for i, c in ipairs(pile) do
		g:oval(c[1], c[2], 2.5, 1.3, i % 2 == 0 and "sand" or "clay")
		g:set(c[1] - 1, c[2] - 1, "cream")
	end
	-- Heavy crimson-and-gold royal cape sweeping left
	g:poly({
		{ cx - 6, 28 + bob }, { cx - 18, 40 + bob }, { cx - 19, 54 },
		{ cx - 8, 55 }, { cx + 2, 31 + bob },
	}, ROBE_LINING, 0.05)
	g:line(cx - 18, 54, cx - 8, 55, "sand")
	-- Opulent gilded royal robe
	g:poly({
		{ cx - 11, 55 }, { cx - 9, 28 + bob }, { cx + 11, 28 + bob }, { cx + 13, 55 },
	}, GOLD, -0.05)
	-- Deep crimson center stole & heavy gold chains
	g:poly({
		{ cx - 2, 54 }, { cx - 1, 30 + bob }, { cx + 6, 30 + bob }, { cx + 7, 54 },
	}, ROBE_LINING, 0.05)
	g:line(cx - 2, 30 + bob, cx - 2, 54, "sand")
	g:line(cx + 6, 30 + bob, cx + 6, 54, "sand")
	-- Plush gilded collar / mantle across broad shoulders
	g:ball(cx, 30 + bob, 11.5, 5, GOLD, 0.18)
	for x = cx - 8, cx + 8, 4 do g:set(x, 31 + bob, "blood") end
	-- Gold chains & chest medallion
	g:line(cx - 5, 34 + bob, cx + 2, 39 + bob, "cream")
	g:line(cx + 7, 34 + bob, cx + 2, 39 + bob, "cream")
	g:ball(cx + 2, 40 + bob, 2.5, 2.5, GOLD, 0.25)
	-- Midas's head (hunched 3/4 right) & pointed beard
	local hx, hy = cx + 2, 21 + bob
	g:oval(hx, hy + 1, 6.1, 6, "black")
	g:ball(hx, hy + 1, 5.5, 5.5, { "rust", "clay", "sand" }, 0.1)
	g:poly({
		{ hx - 1, hy + 5 }, { hx + 6, hy + 4 }, { hx + 8, hy + 8 }, { hx + 2, hy + 10 },
	}, { "rust", "clay", "sand" }, 0.05)
	-- Tall jagged GOLD CROWN with crisp dark rim below band
	g:line(hx - 6, hy - 2, hx + 6, hy - 2, "black")
	g:rect(hx - 6, hy - 6, 13, 4, "clay")
	g:line(hx - 6, hy - 5, hx + 6, hy - 5, "sand")
	local spikes = {
		{ hx - 6, hy - 11 }, { hx - 3, hy - 10 }, { hx, hy - 13 },
		{ hx + 3, hy - 10 }, { hx + 6, hy - 11 },
	}
	for _, sp in ipairs(spikes) do
		g:poly({ { sp[1] - 1.5, hy - 6 }, { sp[1], sp[2] }, { sp[1] + 1.5, hy - 6 } }, GOLD, 0.2)
	end
	g:set(hx, hy - 4, "wine")
	-- Left golden hand clutching overflowing coin pouch / raising on attack
	local lhx, lhy = cx - 7, 39 + bob + rub
	if atk then
		lhx = cx + pick({ -5, -7, -2, -6 }, f)
		lhy = 34 + bob + pick({ 2, -6, 0, 3 }, f)
	end
	g:ball(lhx, lhy, 3.2, 3, GOLD, 0.25)
	-- Right golden hand reaching greedily forward-right (Midas touch / coin fling)
	local rhx, rhy
	if not atk then
		rhx, rhy = cx + 15, 36 + bob - rub
	elseif f == 0 then
		rhx, rhy = cx + 8, 38 + bob
	elseif f == 1 then
		rhx, rhy = cx + 11, 27 + bob
	elseif f == 2 then
		rhx, rhy = cx + 20, 34 + bob
	else
		rhx, rhy = cx + 16, 39 + bob
	end
	g:line(cx + 8, 32 + bob, rhx - 2, rhy, "clay")
	g:line(cx + 8, 33 + bob, rhx - 2, rhy + 1, "sand")
	g:ball(rhx, rhy, 3.5, 3.2, GOLD, 0.3)
	-- Splayed golden fingers pointing right
	g:line(rhx + 2, rhy - 2, rhx + 5, rhy - 3, "cream")
	g:line(rhx + 3, rhy, rhx + 6, rhy, "cream")
	g:line(rhx + 2, rhy + 2, rhx + 5, rhy + 3, "sand")
	-- Eyes, crown glints, dripping / flying gold coins
	local after = canvas(64, 64)
	after:line(hx, hy - 1, hx + 5, hy - 1, "black")
	after:set(hx + 1, hy, "cream"); after:set(hx + 4, hy, "cream")
	after:line(hx + 1, hy + 3, hx + 4, hy + 3, "black")
	after:set(hx + 2, hy + 3, "cream")
	after:set(hx, hy - 13, "cream")
	after:set(hx - 6, hy - 11, "cream")
	after:set(hx + 6, hy - 11, "cream")
	after:set(cx + 2, 40 + bob, "wine")
	-- Rotating sparkles on coin mound
	local sp1 = pile[(f * 3) % #pile + 1]
	local sp2 = pile[(f * 3 + 5) % #pile + 1]
	after:set(sp1[1], sp1[2] - 1, "cream")
	after:set(sp2[1], sp2[2] - 1, "cream")
	if not atk then
		-- Coins trickling from his golden hand
		local dy = (f % 4) * 3
		after:oval(rhx + 2, rhy + 5 + dy, 1.5, 1, "sand")
		after:set(rhx + 2, rhy + 5 + dy, "cream")
	elseif f == 1 then
		-- Gathering golden aura sparks before fling
		for _, off in ipairs({ { -3, -5 }, { 4, -4 }, { 6, 1 }, { -2, 5 } }) do
			after:set(rhx + off[1], rhy + off[2], "cream")
		end
	elseif f == 2 or f == 3 then
		-- Fan of spinning gold coins spraying right
		local spread = f == 2 and 1 or 1.25
		for i = -2, 2 do
			local a = i * 0.34
			local dist = (f == 2 and 10 or 13) * spread
			local gx = clamp(rhx + math.cos(a) * dist, 3, 59)
			local gy = clamp(rhy + math.sin(a) * dist * 1.1 + (f == 3 and 4 or 0), 4, 57)
			after:oval(gx, gy, 2, 1.5, "rust")
			after:oval(gx, gy, 1.4, 1, "sand")
			after:set(gx - 0.5, gy - 0.5, "cream")
		end
	end
	return compose(64, 64, ground_shadow(64, 64, 32, 58, 21, 4), g, after)
end

-- Lust = Lilith (winged temptress, long flowing hair, coiled serpent motif; pink/rose).
local function lust(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ 0, -2, -1, 0 }, f) or pick({ 0, -1, -1, 0 }, f)
	local lean = atk and pick({ -2, -2, 3, 1 }, f) or 0
	local wflap = atk and pick({ -2, -4, 3, 0 }, f) or pick({ 0, -2, -3, -1 }, f)
	local phase = f / 4 * math.pi * 2
	local WING_MEM = { "abyss", "blood", "wine", "mauve" }
	local HAIR = { "abyss", "plum", "mauve", "rose" }
	local SKIN = { "mauve", "rose", "clay", "sand" }
	local SERP = { "abyss", "plum", "rose", "clay" }
	local g = canvas(64, 64)
	local cx = 30 + lean
	-- Sweeping gothic demoness wings
	g:poly({
		{ cx - 3, 29 + bob }, { cx - 18, 10 + bob + wflap }, { cx - 24, 17 + bob + wflap },
		{ cx - 20, 27 + bob + wflap // 2 }, { cx - 16, 24 + bob }, { cx - 14, 33 + bob },
		{ cx - 9, 30 + bob }, { cx - 5, 38 + bob },
	}, WING_MEM, 0.05)
	g:line(cx - 3, 29 + bob, cx - 18, 10 + bob + wflap, "rose")
	g:line(cx - 3, 29 + bob, cx - 20, 27 + bob + wflap // 2, "mauve")
	g:line(cx - 3, 29 + bob, cx - 14, 33 + bob, "mauve")
	-- Far right wing tucked behind shoulder
	g:poly({
		{ cx + 3, 28 + bob }, { cx + 14, 12 + bob + wflap }, { cx + 19, 18 + bob + wflap },
		{ cx + 15, 27 + bob + wflap // 2 }, { cx + 10, 25 + bob }, { cx + 6, 33 + bob },
	}, { "blood", "wine", "mauve", "rose" }, 0.1)
	g:line(cx + 3, 28 + bob, cx + 14, 12 + bob + wflap, "clay")
	-- Long flowing dark-plum & rose hair streaming back-left
	local hw = math.sin(phase) * 2
	g:poly({
		{ cx - 1, 16 + bob }, { cx - 10, 21 + bob }, { cx - 16 + hw, 33 + bob },
		{ cx - 14 - hw, 45 + bob }, { cx - 7 + hw, 47 + bob }, { cx - 4, 34 + bob },
		{ cx + 3, 20 + bob },
	}, HAIR, 0.05)
	for k = 1, 3 do
		local sx = cx - 4 - k * 3
		g:line(sx + 3, 22 + bob + k * 2, sx + math.sin(phase + k) * 2, 38 + bob + k * 2, k == 2 and "rose" or "mauve")
	end
	-- Slender hourglass rose-pink gothic gown
	g:poly({
		{ cx - 9, 57 }, { cx - 4, 38 + bob }, { cx + 6, 38 + bob }, { cx + 10, 57 },
	}, ROSE, 0.05)
	g:line(cx + 2, 40 + bob, cx + 4, 56, "blood")
	g:line(cx - 9, 57, cx + 10, 57, "clay")
	g:poly({
		{ cx - 4, 39 + bob }, { cx - 5, 27 + bob }, { cx + 6, 27 + bob }, { cx + 4, 39 + bob },
	}, ROSE, 0.18)
	g:ball(cx + 1, 27 + bob, 4.5, 2.8, SKIN, 0.1)
	-- Temptress head, swept bangs & small curved demoness horns
	local hx, hy = cx + 1, 20 + bob
	g:line(hx - 2, hy - 4, hx - 6, hy - 10, "rose")
	g:line(hx - 3, hy - 4, hx - 7, hy - 9, "wine")
	g:line(hx + 2, hy - 4, hx + 6, hy - 10, "sand")
	g:line(hx + 3, hy - 4, hx + 7, hy - 9, "rose")
	g:ball(hx, hy, 4.8, 5.2, SKIN, 0.15)
	g:poly({ { hx - 5, hy - 1 }, { hx - 3, hy - 5 }, { hx + 4, hy - 4 }, { hx - 1, hy - 2 } }, HAIR, 0.1)
	-- Graceful left & right arms
	g:line(cx - 4, 30 + bob, cx - 9, 37 + bob, "rose")
	g:line(cx - 4, 31 + bob, cx - 8, 38 + bob, "clay")
	local handx = cx + (atk and pick({ 8, 6, 16, 12 }, f) or 13)
	local handy = 29 + bob + (atk and pick({ 1, -3, -2, 1 }, f) or math.floor(math.sin(phase) * 1.5))
	g:line(cx + 5, 29 + bob, handx, handy, "clay")
	g:line(cx + 5, 30 + bob, handx, handy + 1, "rose")
	-- Coiled serpent wrapping her skirt and striking forward-right along her arm
	for i = 0, 7 do
		local t = i / 7
		local sx = cx - 8 + t * 18 + math.sin(t * 4 + phase) * 1.5
		local sy = 55 - t * 16 + math.cos(t * 5) * 1.5
		g:ball(sx, sy, 2.6, 2.2, SERP, 0.1)
		if i % 2 == 0 then g:set(sx, sy + 1, "sand") end
	end
	local snx, sny
	if not atk then
		snx, sny = cx + 18, 27 + bob + math.floor(math.cos(phase) * 1.5)
	elseif f == 0 then
		snx, sny = cx + 12, 24 + bob
	elseif f == 1 then
		snx, sny = cx + 10, 21 + bob
	elseif f == 2 then
		snx, sny = cx + 22, 26 + bob
	else
		snx, sny = cx + 19, 29 + bob
	end
	-- Serpent neck & rising head with crisp black separator
	for i = 1, 6 do
		local t = i / 6
		local sx = (cx + 10) * (1 - t) + snx * t
		local sy = (39 + bob) * (1 - t) + sny * t - math.sin(t * math.pi) * (atk and f == 1 and 5 or 3)
		g:ball(sx, sy, 2.4, 2.1, SERP, 0.15)
		if i % 2 == 1 then g:set(sx, sy + 1, "sand") end
	end
	g:oval(snx, sny, 3.8, 3.1, "black")
	g:ball(snx, sny, 3.2, 2.5, SERP, 0.2)
	if atk and (f == 1 or f == 2) then
		g:line(snx + 2, sny - 1, snx + 5, sny - 2, "rose")
		g:line(snx + 2, sny + 2, snx + 5, sny + 3, "clay")
		g:oval(snx + 3, sny + 0.5, 2, 1.5, "black")
	end
	-- Eyes, heart crest, serpent eye/fangs/tongue, charm motes
	local after = canvas(64, 64)
	after:set(hx + 1, hy, "cream"); after:set(hx + 3, hy, "cream")
	after:line(hx + 1, hy - 1, hx + 2, hy - 1, "wine")
	after:line(hx + 3, hy - 1, hx + 4, hy - 1, "wine")
	after:line(hx + 1, hy + 3, hx + 3, hy + 3, "wine")
	-- Glowing rose heart sigil on bodice
	local hc = (atk and (f == 1 or f == 2)) and "cream" or "sand"
	after:set(cx, 32 + bob, hc); after:set(cx + 2, 32 + bob, hc)
	after:line(cx, 33 + bob, cx + 2, 33 + bob, hc); after:set(cx + 1, 34 + bob, hc)
	-- Serpent glowing eye, fangs & flickering forked tongue
	after:set(snx + 1, sny - 1, "cream")
	if atk and (f == 1 or f == 2) then
		after:set(snx + 4, sny - 1, "cream"); after:set(snx + 4, sny + 2, "cream")
	end
	if f % 2 == 0 or atk then
		after:line(snx + 3, sny + 1, clamp(snx + 5, 2, 60), sny + 1, "rose")
		after:set(clamp(snx + 6, 2, 61), sny, "cream"); after:set(clamp(snx + 6, 2, 61), sny + 2, "cream")
	end
	if atk and f == 2 then
		for _, m in ipairs({ { 3, -6 }, { 6, -2 }, { 5, 5 }, { 1, 7 } }) do
			after:set(clamp(snx + m[1], 2, 61), clamp(sny + m[2], 2, 61), "cream")
			after:set(clamp(snx + m[1] - 1, 2, 61), clamp(sny + m[2], 2, 61), "rose")
		end
	end
	return compose(64, 64, ground_shadow(64, 64, 31, 58, 17, 3.5), g, after)
end

-- Envy = Loki (green-cloaked trickster, curved horned headdress, shifting afterimage; green).
local function envy(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ 2, 0, -1, 1 }, f) or pick({ 0, -1, 0, 1 }, f)
	local lean = atk and pick({ -3, -2, 5, 2 }, f) or 0
	local shift = atk and pick({ -7, -10, -14, -9 }, f) or pick({ -8, -10, -7, -9 }, f)
	local cx = 33 + lean
	-- Ground shadow + dithered shifting phantom afterimage behind Loki
	local under = ground_shadow(64, 64, 33, 59, 16, 3.5)
	local ghost = canvas(64, 64)
	local gx = cx + shift
	ghost:poly({ { gx - 5, 55 }, { gx - 9, 30 + bob }, { gx + 5, 30 + bob }, { gx + 7, 55 } }, { "teal", "pine" })
	ghost:oval(gx + 1, 22 + bob, 4.5, 5, "pine")
	ghost:line(gx + 2, 18 + bob, gx + 10, 9 + bob, "lime")
	ghost:line(gx - 2, 18 + bob, gx + 4, 7 + bob, "lime")
	for y = 0, 63 do
		for x = 0, 63 do
			local c = ghost:get(x, y)
			if c and bayer(x + f, y) < 0.52 then under:set(x, y, c) end
		end
	end
	local g = canvas(64, 64)
	-- Agile prowling dark boots
	g:poly({ { cx - 8, 58 }, { cx - 5, 47 + bob }, { cx - 1, 47 + bob }, { cx - 4, 58 } }, { "black", "deep", "teal" })
	g:poly({ { cx + 3, 58 }, { cx + 1, 47 + bob }, { cx + 5, 47 + bob }, { cx + 8, 58 } }, { "black", "deep", "teal" })
	g:line(cx - 8, 58, cx - 4, 58, "pine")
	g:line(cx + 3, 58, cx + 9, 58, "leaf")
	-- Flowing jagged emerald-green trickster cloak sweeping left
	g:poly({
		{ cx - 4, 26 + bob }, { cx - 18, 39 + bob }, { cx - 20, 54 },
		{ cx - 14, 50 }, { cx - 11, 57 }, { cx - 5, 51 },
		{ cx - 1, 56 }, { cx + 6, 48 + bob }, { cx + 5, 28 + bob },
	}, GREEN, 0.05)
	g:line(cx - 12, 37 + bob, cx - 16, 52, "deep")
	g:line(cx - 6, 35 + bob, cx - 8, 52, "teal")
	-- Lean trickster tunic, high upturned collar & gold trim
	g:poly({
		{ cx - 5, 48 + bob }, { cx - 6, 28 + bob }, { cx + 6, 28 + bob }, { cx + 5, 48 + bob },
	}, { "deep", "teal", "pine", "leaf" }, 0.05)
	g:poly({ { cx - 6, 29 + bob }, { cx - 10, 20 + bob }, { cx - 2, 24 + bob } }, GREEN, 0.2)
	g:line(cx - 5, 31 + bob, cx + 5, 42 + bob, "sand")
	g:line(cx - 5, 32 + bob, cx + 5, 43 + bob, "clay")
	g:rect(cx - 5, 43 + bob, 11, 2, "sand")
	-- Sly trickster head & ICONIC swept curved golden horns
	local hx, hy = cx + 1, 21 + bob
	g:ball(hx, hy + 1, 4.5, 5, { "steel", "clay", "sand" }, 0.1)
	g:poly({ { hx - 5, hy }, { hx - 4, hy - 5 }, { hx + 3, hy - 4 }, { hx - 2, hy - 1 } }, { "black", "deep", "teal" })
	-- Golden circlet & sweeping curved Loki horns
	g:line(hx - 4, hy - 3, hx + 5, hy - 3, "sand")
	g:poly({
		{ hx - 2, hy - 4 }, { hx + 2, hy - 10 }, { hx + 5, hy - 16 },
		{ hx + 3, hy - 16 }, { hx - 1, hy - 10 }, { hx - 4, hy - 4 },
	}, GOLD, 0.15)
	g:poly({
		{ hx + 2, hy - 4 }, { hx + 8, hy - 8 }, { hx + 12, hy - 15 },
		{ hx + 10, hy - 16 }, { hx + 6, hy - 9 }, { hx, hy - 4 },
	}, GOLD, 0.2)
	-- Back dagger held low-left
	g:line(cx - 6, 35 + bob, cx - 12, 41 + bob, "pine")
	g:line(cx - 12, 41 + bob, cx - 16, 44 + bob, "sea")
	-- Front arm & curved emerald-glinting trickster dagger (wind-up -> blink-slash)
	local dx0, dy0, dx1, dy1
	if not atk then
		dx0, dy0 = cx + 9, 36 + bob
		dx1, dy1 = cx + 17, 32 + bob
	elseif f == 0 then
		dx0, dy0 = cx + 4, 41 + bob
		dx1, dy1 = cx - 2, 44 + bob
	elseif f == 1 then
		dx0, dy0 = cx + 7, 29 + bob
		dx1, dy1 = cx + 12, 20 + bob
	elseif f == 2 then
		dx0, dy0 = cx + 11, 34 + bob
		dx1, dy1 = cx + 21, 32 + bob
	else
		dx0, dy0 = cx + 11, 41 + bob
		dx1, dy1 = cx + 18, 45 + bob
	end
	g:line(cx + 5, 31 + bob, dx0, dy0, "pine")
	g:line(cx + 5, 32 + bob, dx0, dy0 + 1, "leaf")
	g:ball(dx0, dy0, 2, 2, { "deep", "teal", "pine" }, 0.2)
	g:line(dx0, dy0, dx1, dy1, "sea")
	g:line(dx0, dy0 - 1, dx1, dy1 - 1, "lime")
	-- Sly eyes, wicked grin, shifting sparks & slash arc
	local after = canvas(64, 64)
	after:line(hx, hy - 1, hx + 2, hy, "black")
	after:line(hx + 4, hy - 1, hx + 3, hy, "black")
	after:set(hx + 1, hy + 1, "lime"); after:set(hx + 3, hy + 1, "lime")
	if atk and (f == 1 or f == 2) then after:set(hx + 1, hy + 1, "cream"); after:set(hx + 3, hy + 1, "cream") end
	after:line(hx + 1, hy + 4, hx + 4, hy + 3, "black")
	after:set(hx + 2, hy + 4, "cream")
	after:set(hx + 4, hy - 16, "cream")
	after:set(hx + 11, hy - 15, "cream")
	after:set(dx1, dy1, "cream")
	-- Shifting illusion motes
	after:set(gx - 3, 24 + bob + (f % 3), "lime")
	after:set(gx + 2, 39 + bob - (f % 3), "lime")
	if atk and f == 1 then
		after:set(dx1 + 1, dy1 - 1, "mint"); after:set(dx1 - 1, dy1 - 2, "lime")
	elseif atk and f == 2 then
		for i = -5, 5 do
			local a = i * 0.17
			local sx = clamp(cx + 11 + math.cos(a) * 13, 2, 61)
			local sy = clamp(34 + bob + math.sin(a) * 12, 4, 60)
			after:set(sx, sy, math.abs(i) <= 2 and "mint" or "lime")
			after:set(sx - 1, sy, "leaf")
		end
	end
	return compose(64, 64, under, g, after)
end

-- Gluttony = Wendigo (gaunt hunched antlered skull beast, exposed ribs, huge maw; orange).
local function gluttony(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ 1, -1, 1, 0 }, f) or pick({ 0, 1, 0, -1 }, f)
	local lean = atk and pick({ -3, -2, 3, 1 }, f) or 0
	local jaw = atk and pick({ 3, 7, 9, 2 }, f) or pick({ 2, 3, 4, 3 }, f)
	local HIDE = { "abyss", "blood", "wine", "rust", "clay" }
	local BONE = { "rust", "clay", "sand", "cream" }
	local g = canvas(64, 64)
	local cx = 28 + lean
	-- Gaunt digitigrade predator legs ending in dark hooves
	g:line(cx - 5, 43 + bob, cx - 10, 50, "wine")
	g:line(cx - 4, 43 + bob, cx - 9, 50, "rust")
	g:line(cx - 10, 50, cx - 6, 58, "blood")
	g:line(cx - 9, 50, cx - 5, 58, "wine")
	g:rect(cx - 7, 57, 4, 2, "abyss")
	g:line(cx + 2, 44 + bob, cx - 1, 51, "wine")
	g:line(cx + 3, 44 + bob, cx, 51, "rust")
	g:line(cx - 1, 51, cx + 4, 58, "blood")
	g:line(cx, 51, cx + 5, 58, "rust")
	g:rect(cx + 3, 57, 4, 2, "abyss")
	-- Emaciated hunched torso & ragged fiery-orange shoulder mane
	g:poly({
		{ cx - 6, 44 + bob }, { cx - 9, 34 + bob }, { cx - 4, 24 + bob },
		{ cx + 7, 25 + bob }, { cx + 6, 38 + bob }, { cx + 2, 45 + bob },
	}, HIDE, -0.05)
	-- Ragged orange fur tufts along arched hunched spine
	g:poly({
		{ cx - 10, 34 + bob }, { cx - 13, 27 + bob }, { cx - 7, 23 + bob },
		{ cx - 1, 21 + bob }, { cx + 5, 24 + bob }, { cx - 4, 29 + bob },
	}, FIRE, -0.2)
	-- Sunken chest hollow with exposed pale ribs
	g:oval(cx + 1, 37 + bob, 4.5, 5.5, "black")
	for ry = 33, 41, 3 do
		g:line(cx - 3, ry + bob, cx + 4, ry + 1 + bob, "clay")
		g:line(cx - 2, ry + bob, cx + 2, ry + bob, "sand")
	end
	-- Massive branching deer antlers crowning the silhouette
	local ax, ay = cx + 6, 20 + bob
	-- Back/left antler
	g:line(ax - 1, ay, ax - 9, ay - 7, "clay"); g:line(ax - 2, ay, ax - 10, ay - 7, "rust")
	g:line(ax - 9, ay - 7, ax - 16, ay - 12, "sand"); g:line(ax - 9, ay - 8, ax - 15, ay - 13, "clay")
	g:line(ax - 7, ay - 6, ax - 7, ay - 13, "sand")
	g:line(ax - 13, ay - 10, ax - 13, ay - 15, "cream")
	g:line(ax - 15, ay - 11, ax - 19, ay - 8, "clay")
	-- Front/right antler
	g:line(ax + 2, ay - 1, ax + 9, ay - 8, "sand"); g:line(ax + 3, ay - 1, ax + 10, ay - 8, "clay")
	g:line(ax + 9, ay - 8, ax + 15, ay - 13, "cream"); g:line(ax + 9, ay - 9, ax + 14, ay - 14, "sand")
	g:line(ax + 6, ay - 6, ax + 6, ay - 14, "sand")
	g:line(ax + 12, ay - 10, ax + 12, ay - 15, "cream")
	g:line(ax + 14, ay - 11, ax + 18, ay - 8, "sand")
	-- Bleached deer skull facing RIGHT & huge hinged gaping maw
	local sx, sy = cx + 7, 23 + bob
	-- Dark gaping throat behind jaws
	g:poly({
		{ sx, sy + 2 }, { sx + 14, sy + 2 }, { sx + 13, sy + 5 + jaw }, { sx + 1, sy + 6 + jaw // 2 },
	}, { "black", "blood", "wine" })
	g:oval(sx + 7, sy + 4 + jaw // 2, 4, 1.8, "rust")
	-- Upper bleached skull & elongated snout
	g:poly({
		{ sx - 3, sy - 2 }, { sx + 7, sy - 4 }, { sx + 16, sy + 1 },
		{ sx + 15, sy + 4 }, { sx + 2, sy + 4 }, { sx - 3, sy + 2 },
	}, BONE, 0.15)
	-- Hinged lower jaw dropping wide open
	g:poly({
		{ sx - 1, sy + 4 }, { sx + 14, sy + 5 + jaw }, { sx + 12, sy + 8 + jaw },
		{ sx, sy + 7 + jaw // 2 },
	}, { "rust", "clay", "sand" }, 0.05)
	-- Long spindly clawed arms reaching hungrily forward-right
	local clawx = cx + (atk and pick({ 11, 13, 21, 17 }, f) or 16)
	local clawy = 43 + bob + (atk and pick({ 2, -4, -3, 2 }, f) or 0)
	-- Far arm
	g:line(cx + 5, 30 + bob, cx + 11, 39 + bob, "blood")
	g:line(cx + 11, 39 + bob, clawx - 2, clawy + 3, "wine")
	g:line(clawx - 2, clawy + 3, clawx + 2, clawy + 5, "clay")
	-- Near arm + 3 huge claws
	g:line(cx - 2, 29 + bob, cx + 5, 39 + bob, "wine")
	g:line(cx - 1, 29 + bob, cx + 6, 39 + bob, "rust")
	g:line(cx + 5, 39 + bob, clawx, clawy, "rust")
	g:line(cx + 5, 40 + bob, clawx, clawy + 1, "clay")
	g:line(clawx, clawy - 1, clawx + 5, clawy - 3, "sand")
	g:line(clawx, clawy, clawx + 6, clawy + 1, "cream")
	g:line(clawx, clawy + 1, clawx + 4, clawy + 4, "sand")
	-- Skull eye hollow, glowing hunger eye, jagged teeth, orange embers
	local after = canvas(64, 64)
	after:oval(sx + 4, sy, 2.3, 1.8, "black")
	after:set(sx + 5, sy, "cream")
	if atk and (f == 1 or f == 2) then after:set(sx + 6, sy, "sand") end
	after:set(sx + 13, sy + 1, "black")
	-- Upper & lower rows of sharp teeth
	for tx = sx + 4, sx + 14, 3 do
		after:set(tx, sy + 4, "cream")
		after:set(tx, sy + 5, "sand")
		after:set(tx + 1, sy + 4 + jaw, "sand")
	end
	-- Dripping fiery orange embers / devour wind lines
	local drop = (f % 4) * 2
	after:set(sx + 11, clamp(sy + 7 + jaw + drop, 4, 59), "rust")
	after:set(sx + 11, clamp(sy + 8 + jaw + drop, 4, 60), "cream")
	if atk and (f == 1 or f == 2) then
		for i = -1, 1 do
			local ly = sy + 4 + jaw // 2 + i * 4
			local lx0 = clamp(sx + 15, 2, 57)
			local lx1 = clamp(sx + (f == 2 and 22 or 19), 2, 60)
			after:line(lx0, ly, lx1, ly + i * 2, i == 0 and "cream" or "clay")
		end
	end
	return compose(64, 64, ground_shadow(64, 64, 31, 59, 19, 3.5), g, after)
end

-- Wrath = Cerberus (muscular three-headed hellhound with fiery hackles; red).
local function wrath(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ 2, 0, -1, 1 }, f) or pick({ 0, 1, 0, -1 }, f)
	local lean = atk and pick({ -1, -1, 3, 1 }, f) or 0
	local snap = atk and pick({ 1, 3, 4, 0 }, f) or 1
	local FUR = { "abyss", "blood", "wine", "rust", "clay" }
	local g = canvas(64, 64)
	local after = canvas(64, 64)
	local cx = 25 + lean
	-- Whipping fiery barbed tail on left (stays cleanly inside x >= 2)
	local tw = pick({ 0, -2, -1, 2 }, f)
	g:line(cx - 12, 41 + bob, cx - 17, 34 + bob + tw, "wine")
	g:line(cx - 12, 42 + bob, cx - 17, 35 + bob + tw, "rust")
	g:poly({
		{ cx - 17, 34 + bob + tw }, { cx - 20, 29 + bob + tw },
		{ cx - 15, 30 + bob + tw }, { cx - 15, 35 + bob + tw },
	}, FIRE, 0.1)
	-- Four heavy muscular beast legs & claws
	local lift = (atk and f == 1) and -3 or 0
	g:poly({ { cx - 13, 57 }, { cx - 14, 44 + bob }, { cx - 9, 44 + bob }, { cx - 9, 57 } }, { "abyss", "blood", "wine" })
	g:poly({ { cx - 7, 58 }, { cx - 8, 43 + bob }, { cx - 2, 43 + bob }, { cx - 2, 58 } }, FUR, -0.1)
	g:poly({ { cx + 8, 57 + lift }, { cx + 6, 43 + bob }, { cx + 11, 43 + bob }, { cx + 13, 57 + lift } }, { "abyss", "blood", "wine" })
	g:poly({ { cx + 2, 58 + lift }, { cx + 1, 42 + bob }, { cx + 7, 42 + bob }, { cx + 8, 58 + lift } }, FUR, 0.05)
	for _, px in ipairs({ cx - 10, cx - 3, cx + 7, cx + 12 }) do
		g:set(px + 1, 57 + (px > cx and lift or 0), "sand")
		g:set(px + 2, 58 + (px > cx and lift or 0), "clay")
	end
	-- Muscular hellhound haunches & barrel chest
	g:ball(cx - 6, 42 + bob, 9, 7, FUR, -0.12)
	g:ball(cx + 5, 38 + bob, 10.5, 9, FUR, 0.05)
	-- Blazing fiery mane / hackles along spine
	math.randomseed(120 + f)
	for i = 0, 6 do
		local fx = cx - 9 + i * 3.5
		local fh = math.random(5, 9) + (atk and 4 or 0)
		for y = 0, fh do
			local t = y / fh
			local w = math.max(0, math.floor(2.4 * (1 - t) + 0.5))
			local col = FIRE[clamp(math.floor(t * #FIRE) + 1, 1, #FIRE)]
			for dx = -w, w do g:set(fx + dx, 31 + bob - y, col) end
		end
	end
	-- Local helper to draw one distinct snarling hound head facing RIGHT
	local function hound_head(nx, ny, hx, hy, open, tilt, sc)
		-- Neck + dark spiked iron collar
		g:poly({
			{ nx - 2, ny - 3 }, { hx - 3, hy - 3 * sc }, { hx - 3, hy + 3 * sc }, { nx - 2, ny + 4 },
		}, FUR, 0.0)
		local mx, my = (nx + hx - 3) / 2, (ny + hy) / 2
		g:line(mx - 1, my - 4 * sc, mx + 1, my + 4 * sc, "night")
		g:line(mx, my - 4 * sc, mx + 2, my + 4 * sc, "steel")
		g:set(mx + 2, my - 3 * sc, "mint"); g:set(mx + 2, my + 3 * sc, "mint")
		-- Dark outline separator so overlapping heads stay crisp
		g:oval(hx - 1, hy, 5.8 * sc, 4.8 * sc, "black")
		-- Pointed swept wolf ears
		g:poly({
			{ hx - 3 * sc, hy - 3 * sc }, { hx - 7 * sc, hy - 8 * sc }, { hx + 1 * sc, hy - 4 * sc },
		}, FUR, 0.05)
		g:poly({
			{ hx, hy - 3 * sc }, { hx - 3 * sc, hy - 8 * sc }, { hx + 3 * sc, hy - 3 * sc },
		}, FUR, 0.12)
		-- Cranium
		g:ball(hx, hy, 5 * sc, 4.2 * sc, FUR, 0.12)
		-- Open fanged muzzle facing RIGHT
		g:poly({
			{ hx + 2 * sc, hy - 2 * sc }, { hx + 10 * sc, hy - 1 * sc + tilt },
			{ hx + 9 * sc, hy + 1.5 * sc + tilt }, { hx + 2 * sc, hy + 1 * sc },
		}, FUR, 0.18)
		g:poly({
			{ hx + 2 * sc, hy + 1 * sc }, { hx + 9 * sc, hy + 1.5 * sc + tilt },
			{ hx + 8 * sc, hy + 3 * sc + open + tilt }, { hx + 2 * sc, hy + 3 * sc + open // 2 },
		}, { "black", "blood" })
		g:poly({
			{ hx + 1 * sc, hy + 2.5 * sc }, { hx + 9 * sc, hy + 3 * sc + open + tilt },
			{ hx + 7 * sc, hy + 5 * sc + open + tilt }, { hx, hy + 4 * sc },
		}, FUR, 0.0)
		-- Glowing angry eye & sharp white fangs in after
		after:line(hx + 1 * sc, hy - 2 * sc, hx + 4 * sc, hy - 1 * sc, "black")
		after:set(hx + 2 * sc, hy - 1 * sc, "cream")
		after:set(hx + 3 * sc, hy - 1 * sc, atk and "mint" or "sand")
		after:set(hx + 8 * sc, hy + 2 * sc + tilt, "cream")
		after:set(hx + 5 * sc, hy + 2 * sc + tilt, "sand")
		after:set(hx + 7 * sc, hy + 2.5 * sc + open + tilt, "cream")
		if atk and f == 2 then
			after:line(hx + 10 * sc, hy + 1 + tilt, clamp(hx + 13 * sc, 2, 60), hy + 1 + tilt, "cream")
			after:set(clamp(hx + 12 * sc, 2, 60), hy - 1 + tilt, "sand")
		end
	end
	-- Three clearly separated snarling heads (upper, lower, then foreground center alpha)
	local h1 = pick({ 0, -1, 0, 1 }, f)
	local h2 = pick({ 0, 0, -1, 1 }, f)
	local h3 = pick({ 1, 0, 0, -1 }, f)
	hound_head(cx + 8, 31 + bob, cx + 14, 15 + bob + h1, snap + (f == 1 and 1 or 0), -1, 0.92)
	hound_head(cx + 10, 42 + bob, cx + 17, 43 + bob + h3, snap + (f == 3 and 1 or 0), 1, 0.92)
	hound_head(cx + 11, 35 + bob, cx + 21, 29 + bob + h2, snap + (atk and 1 or 0), 0, 1.05)
	return compose(64, 64, ground_shadow(64, 64, 30, 58, 22, 4), g, after)
end

-- Sloth = Edward (slumped heavy-lidded sleeper huddled in a blue blanket on a throne; blue).
local function sloth(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ -1, -2, 0, 2 }, f) or pick({ 0, 0, 1, 1 }, f)
	local nod = atk and pick({ -1, -2, -1, 3 }, f) or pick({ 0, 1, 2, 1 }, f)
	local yawn = atk and pick({ 1, 4, 6, 0 }, f) or 0
	local THRONE = { "abyss", "night", "navy", "steel" }
	local SKIN = { "steel", "clay", "sand" }
	local g = canvas(64, 64)
	-- High-backed gothic throne (3/4 view facing right)
	g:poly({
		{ 9, 57 }, { 9, 17 }, { 14, 12 }, { 26, 12 }, { 31, 17 }, { 31, 57 },
	}, THRONE, -0.05)
	g:line(14, 12, 26, 12, "sea")
	g:line(12, 18, 12, 53, "navy")
	g:line(28, 18, 28, 53, "steel")
	-- Throne seat base & legs
	g:poly({ { 11, 57 }, { 11, 44 }, { 47, 44 }, { 47, 57 } }, THRONE, -0.1)
	g:rect(11, 51, 5, 6, "abyss")
	g:rect(42, 51, 5, 6, "abyss")
	-- Plump blue pillow behind Edward's hunched shoulders
	g:ball(22, 31 + bob, 6.5, 5.5, { "navy", "steel", "sea" }, 0.1)
	-- Slumped Edward wrapped cocoon-like in a thick blue quilted blanket
	g:poly({
		{ 14, 56 }, { 15, 33 + bob }, { 25, 28 + bob }, { 42, 30 + bob },
		{ 48, 41 + bob }, { 50, 55 }, { 34, 57 }, { 19, 57 },
	}, { "black", "abyss" })
	g:poly({
		{ 15, 56 }, { 16, 34 + bob }, { 25, 29 + bob }, { 41, 31 + bob },
		{ 47, 41 + bob }, { 49, 55 }, { 34, 57 }, { 19, 57 },
	}, COOL, -0.05)
	-- Folded blanket rim & quilted stitch folds
	g:line(24, 32 + bob, 40, 34 + bob, "mint")
	g:line(24, 33 + bob, 40, 35 + bob, "sea")
	g:line(22, 42 + bob, 42, 43 + bob, "navy")
	g:line(20, 49, 44, 50, "navy")
	g:line(28, 36 + bob, 26, 55, "navy")
	g:line(37, 37 + bob, 38, 55, "navy")
	-- Throne front-right armrest & Edward's limply dangling arm
	g:poly({ { 32, 41 }, { 48, 41 }, { 48, 46 }, { 32, 46 } }, THRONE, 0.1)
	local handx = 48 + (atk and pick({ 0, -2, 5, 2 }, f) or 0)
	local handy = 45 + bob + (atk and pick({ -1, -3, -2, 2 }, f) or 0)
	g:line(38, 37 + bob, handx, handy, "steel")
	g:line(38, 38 + bob, handx, handy + 1, "sea")
	g:ball(handx, handy + 1, 2.5, 2.2, SKIN, 0.1)
	-- Sleepy slumped head & droopy blue nightcap with dark collar separator
	local hx, hy = 35, 25 + bob + nod
	g:oval(hx, hy, 6.5, 6.5, "black")
	g:ball(hx, hy, 5.8, 5.8, SKIN, 0.12)
	-- Droopy blue sleeping cap slouching back-left
	g:poly({
		{ hx - 5, hy - 2 }, { hx - 3, hy - 8 }, { hx + 5, hy - 6 },
		{ hx + 6, hy - 2 }, { hx - 4, hy - 1 },
	}, COOL, 0.1)
	g:poly({
		{ hx - 5, hy - 5 }, { hx - 12, hy - 2 }, { hx - 14, hy + 4 + bob },
		{ hx - 10, hy + 4 + bob }, { hx - 8, hy }, { hx - 4, hy - 2 },
	}, COOL, 0.05)
	g:line(hx - 5, hy - 2, hx + 6, hy - 2, "mint")
	g:ball(hx - 13, hy + 5 + bob, 2.3, 2.3, { "sea", "mint" }, 0.2)
	-- Giant yawning mouth during attack
	if yawn > 0 then
		g:oval(hx + 2.5, hy + 3, 3.2, math.max(1.2, yawn * 0.6), "black")
		if yawn >= 4 then g:oval(hx + 2.5, hy + 4, 2, 1.2, "mauve") end
	end
	-- Heavy drooping eyelids, slack mouth, floating blue Zs & yawn shockwaves
	local after = canvas(64, 64)
	-- Heavy-lidded eyes (droopy blue lids covering upper half of eyes)
	after:rect(hx, hy - 1, 3, 2, "steel")
	after:rect(hx + 4, hy - 1, 2, 2, "steel")
	after:line(hx, hy - 1, hx + 2, hy - 1, "navy")
	after:line(hx + 4, hy - 1, hx + 5, hy - 1, "navy")
	if atk and f == 2 then
		-- Eyes squeezed shut mid-yawn
		after:line(hx, hy + 1, hx + 2, hy + 1, "black")
		after:line(hx + 4, hy + 1, hx + 5, hy + 1, "black")
		after:set(hx + 2, hy + 3, "cream") -- a tooth keeps the eye glow key in this frame
	else
		-- Thin drowsy eye slit peeking under heavy lid
		after:set(hx + 1, hy + 1, "cream"); after:set(hx + 4, hy + 1, "cream")
		after:set(hx + 2, hy + 1, "black")
	end
	if yawn == 0 then
		after:line(hx + 1, hy + 4, hx + 3, hy + 4, "navy")
		if f >= 2 then after:set(hx + 3, hy + 5, "sea") end
	end
	-- Floating blue Zs in idle (and nap recoil f=3)
	if not atk or f == 3 then
		local z1y = 18 - (f % 4) * 2
		after:line(46, z1y, 49, z1y, "mint")
		after:line(49, z1y, 46, z1y + 3, "sea")
		after:line(46, z1y + 3, 49, z1y + 3, "mint")
		local z2y = 11 - ((f + 2) % 4) * 2
		after:line(53, z2y, 55, z2y, "sea")
		after:line(55, z2y, 53, z2y + 2, "steel")
		after:line(53, z2y + 2, 55, z2y + 2, "sea")
	elseif f == 1 then
		after:set(hx + 7, hy + 2, "sea"); after:set(hx + 8, hy + 4, "mint")
	elseif f == 2 then
		-- Expanding drowsy blue-mint yawn wave arcs to the right
		for _, r in ipairs({ 8, 13, 18 }) do
			for i = -4, 4 do
				local a = i * 0.2
				local wx = clamp(hx + 4 + math.cos(a) * r, 2, 61)
				local wy = clamp(hy + 3 + math.sin(a) * r * 1.1, 4, 58)
				after:set(wx, wy, r == 8 and "mint" or (r == 13 and "sea" or "steel"))
			end
		end
	end
	return compose(64, 64, ground_shadow(64, 64, 31, 58, 22, 4), g, after)
end

-- Satan = final boss (towering horned demon lord, massive bat wings, blazing crown of fire).
local function satan(anim, f)
	local atk = anim == "attack"
	local bob = atk and pick({ 0, -1, -1, 0 }, f) or pick({ 0, -1, -1, 0 }, f)
	local lean = atk and pick({ -2, -2, 2, 1 }, f) or 0
	local flap = atk and pick({ -2, -4, 3, -1 }, f) or pick({ 0, -1, -2, -1 }, f)
	local DEMON = { "abyss", "blood", "wine", "rust" }
	local WING_L = { "black", "abyss", "blood", "wine" }
	local WING_R = { "abyss", "blood", "wine", "rust" }
	local g = canvas(64, 64)
	local cx = 31 + lean
	-- Massive arched gothic bat wings spanning the frame (edge-safe x in [4..60])
	g:poly({
		{ cx - 4, 30 + bob }, { cx - 17, 10 + flap }, { cx - 24, 16 + flap },
		{ cx - 23, 30 + flap // 2 }, { cx - 18, 26 }, { cx - 15, 37 },
		{ cx - 10, 33 }, { cx - 6, 43 },
	}, WING_L, 0.05)
	g:line(cx - 4, 30 + bob, cx - 17, 10 + flap, "rust")
	g:line(cx - 4, 30 + bob, cx - 23, 30 + flap // 2, "rust")
	g:line(cx - 4, 30 + bob, cx - 15, 37, "wine")
	g:set(cx - 17, 9 + flap, "sand")
	-- Far right wing arcing high-right
	g:poly({
		{ cx + 5, 29 + bob }, { cx + 17, 11 + flap }, { cx + 24, 17 + flap },
		{ cx + 22, 30 + flap // 2 }, { cx + 17, 26 }, { cx + 13, 35 }, { cx + 9, 32 },
	}, WING_R, 0.08)
	g:line(cx + 5, 29 + bob, cx + 17, 11 + flap, "clay")
	g:line(cx + 5, 29 + bob, cx + 22, 30 + flap // 2, "rust")
	g:set(cx + 17, 10 + flap, "sand")
	-- Barbed devil tail curving behind lower-left
	g:line(cx - 7, 46, cx - 16, 51, "blood")
	g:line(cx - 7, 47, cx - 16, 52, "wine")
	g:line(cx - 16, 51, cx - 21, 46, "rust")
	g:poly({ { cx - 21, 46 }, { cx - 23, 43 }, { cx - 19, 44 }, { cx - 20, 48 } }, { "wine", "rust", "clay" })
	-- Towering armored demon legs & cloven hooves planted wide
	g:poly({ { cx - 8, 59 }, { cx - 7, 44 + bob }, { cx - 2, 44 + bob }, { cx - 3, 59 } }, DEMON, -0.05)
	g:poly({ { cx + 3, 59 }, { cx + 2, 44 + bob }, { cx + 8, 44 + bob }, { cx + 9, 59 } }, DEMON, 0.05)
	g:rect(cx - 8, 57, 5, 2, "black"); g:rect(cx + 4, 57, 5, 2, "black")
	g:line(cx - 6, 49, cx - 3, 49, "clay"); g:line(cx + 4, 49, cx + 7, 49, "sand")
	-- Tattered dark royal waist-cloth & broad muscular chestplate
	g:poly({
		{ cx - 4, 56 }, { cx - 5, 41 + bob }, { cx + 6, 41 + bob }, { cx + 5, 56 },
	}, { "black", "abyss", "blood", "wine" })
	g:line(cx + 1, 44 + bob, cx + 1, 55, "rust")
	g:ball(cx + 1, 34 + bob, 9.5, 8, DEMON, 0.08)
	-- Obsidian-gold spiked pauldrons & rib chest-trim
	g:ball(cx - 9, 30 + bob, 5, 4.5, { "black", "abyss", "wine", "rust" }, 0.1)
	g:ball(cx + 10, 30 + bob, 5, 4.5, { "black", "abyss", "wine", "rust" }, 0.15)
	g:line(cx - 12, 27 + bob, cx - 15, 23 + bob, "sand")
	g:line(cx + 12, 27 + bob, cx + 15, 23 + bob, "sand")
	g:line(cx - 4, 33 + bob, cx + 6, 33 + bob, "clay")
	g:line(cx - 3, 37 + bob, cx + 5, 37 + bob, "sand")
	-- Hellfire obsidian trident (wind-up -> forward-right hellfire thrust)
	local tx0, ty0, tx1, ty1
	if not atk then
		tx0, ty0 = cx + 12, 56
		tx1, ty1 = cx + 20, 16 + bob
	elseif f == 0 then
		tx0, ty0 = cx + 5, 52
		tx1, ty1 = cx + 14, 14 + bob
	elseif f == 1 then
		tx0, ty0 = cx + 2, 48
		tx1, ty1 = cx + 11, 13 + bob
	elseif f == 2 then
		tx0, ty0 = cx + 4, 42 + bob
		tx1, ty1 = cx + 21, 29 + bob
	else
		tx0, ty0 = cx + 8, 48
		tx1, ty1 = cx + 20, 23 + bob
	end
	g:line(tx0, ty0, tx1, ty1, "clay")
	g:line(tx0 + 1, ty0, tx1 + 1, ty1, "sand")
	local tdx, tdy = tx1 - tx0, ty1 - ty0
	local tlen = math.max(1, math.sqrt(tdx * tdx + tdy * tdy))
	local tux, tuy = tdx / tlen, tdy / tlen
	local tpx, tpy = -tuy, tux
	g:line(tx1 - tpx * 4, ty1 - tpy * 4, tx1 + tpx * 4, ty1 + tpy * 4, "sand")
	g:line(tx1 - tpx * 4, ty1 - tpy * 4, tx1 - tpx * 4 + tux * 5.5, ty1 - tpy * 4 + tuy * 5.5, "sand")
	g:line(tx1, ty1, tx1 + tux * 7, ty1 + tuy * 7, "cream")
	g:line(tx1 + tpx * 4, ty1 + tpy * 4, tx1 + tpx * 4 + tux * 5.5, ty1 + tpy * 4 + tuy * 5.5, "sand")
	-- Fierce horned Demon Lord head facing 3/4 right with dark separator
	local hx, hy = cx + 1, 22 + bob
	g:oval(hx, hy + 1, 6.5, 6.5, "black")
	g:ball(hx, hy + 1, 5.8, 5.8, { "blood", "wine", "rust", "clay" }, 0.08)
	-- Enormous sweeping twin demon horns
	g:poly({
		{ hx - 4, hy - 2 }, { hx - 12, hy - 6 }, { hx - 14, hy - 13 },
		{ hx - 10, hy - 16 }, { hx - 10, hy - 11 }, { hx - 8, hy - 8 }, { hx - 3, hy - 4 },
	}, { "abyss", "rust", "clay", "sand" }, 0.1)
	g:poly({
		{ hx + 4, hy - 2 }, { hx + 11, hy - 6 }, { hx + 13, hy - 13 },
		{ hx + 9, hy - 16 }, { hx + 9, hy - 11 }, { hx + 7, hy - 8 }, { hx + 3, hy - 4 },
	}, GOLD, 0.15)
	-- Blazing CROWN OF FIRE, fierce demon eyes, fangs & hellfire attack burst
	local after = canvas(64, 64)
	-- Fiery diadem base & roaring animated flame spires between his horns
	after:line(hx - 6, hy - 5, hx + 6, hy - 5, "wine")
	after:line(hx - 5, hy - 6, hx + 5, hy - 6, "rust")
	math.randomseed(310 + f)
	local spire_h = { 5, 8, 10, 8, 5 }
	for i = 1, 5 do
		local fx = hx - 6 + (i - 1) * 3
		local hgt = spire_h[i] + math.random(0, 2) + (atk and (f == 1 or f == 2) and 3 or 0)
		for y = 0, hgt do
			local py = hy - 6 - y
			if py >= 2 then
				local t = y / hgt
				local w = math.max(0, math.floor(1.5 * (1 - t) + 0.5))
				local col = FIRE[clamp(math.floor((1 - t * 0.75) * #FIRE) + 1, 1, #FIRE)]
				for dx = -w, w do after:set(fx + dx, py, col) end
			end
		end
		after:set(fx, hy - 6, "cream")
	end
	-- Glowing demon eyes, angry brows & fanged snarl
	local eye = (atk and (f == 1 or f == 2)) and "mint" or "cream"
	after:line(hx - 1, hy - 1, hx + 2, hy, "black")
	after:line(hx + 5, hy - 1, hx + 3, hy, "black")
	after:set(hx, hy + 1, eye); after:set(hx + 1, hy + 1, eye)
	after:set(hx + 3, hy + 1, eye); after:set(hx + 4, hy + 1, eye)
	after:line(hx, hy + 4, hx + 4, hy + 4, "black")
	after:set(hx + 1, hy + 5, "cream"); after:set(hx + 3, hy + 5, "cream")
	-- Trident prong fire tips & hellfire strike burst
	after:set(clamp(tx1 + tux * 7, 2, 61), clamp(ty1 + tuy * 7, 2, 61), "cream")
	after:set(clamp(tx1 - tpx * 4 + tux * 5.5, 2, 61), clamp(ty1 - tpy * 4 + tuy * 5.5, 2, 61), "cream")
	after:set(clamp(tx1 + tpx * 4 + tux * 5.5, 2, 61), clamp(ty1 + tpy * 4 + tuy * 5.5, 2, 61), "cream")
	if atk and f == 1 then
		after:oval(tx1 + tux * 4, ty1 + tuy * 4, 2.5, 2.5, "sand")
		after:set(tx1 + tux * 4, ty1 + tuy * 4, "cream")
	elseif atk and f == 2 then
		for i = -3, 3 do
			local a = i * 0.25
			local fx = clamp(tx1 + tux * 5 + math.cos(a) * 6, 3, 59)
			local fy = clamp(ty1 + tuy * 5 + math.sin(a) * 6, 4, 59)
			after:oval(fx, fy, 1.8, 1.8, i % 2 == 0 and "sand" or "rust")
			after:set(fx, fy, "cream")
		end
	end
	return compose(64, 64, ground_shadow(64, 64, 32, 59, 21, 3.5), g, after)
end

---------------------------------------------------------------------------
-- Pickups, projectile, effect (16x16 / 32x32).
---------------------------------------------------------------------------
local function gem(f)
	local bob = pick({ 0, -1, -1, 0 }, f)
	local g = canvas(16, 16)
	-- A many-faceted vessel with a tiny soul flame visibly trapped inside.
	g:poly({ { 8, 1 + bob }, { 12, 4 + bob }, { 14, 8 + bob }, { 11, 13 + bob }, { 8, 15 + bob }, { 5, 13 + bob }, { 2, 8 + bob }, { 4, 4 + bob } }, { "night", "navy", "steel", "sea", "mint" }, 0.05)
	g:poly({ { 8, 3 + bob }, { 11, 5 + bob }, { 12, 8 + bob }, { 9, 12 + bob }, { 6, 11 + bob }, { 4, 8 + bob }, { 5, 5 + bob } }, { "night", "navy", "steel", "sea" }, -0.1)
	g:line(4, 4 + bob, 8, 6 + bob, "sea"); g:line(12, 4 + bob, 8, 6 + bob, "mint")
	g:line(2, 8 + bob, 6, 8 + bob, "steel"); g:line(11, 8 + bob, 14, 8 + bob, "sea")
	local after = canvas(16, 16)
	after:set(8, 4 + bob, "cream")
	after:line(7, 5 + bob, 7, 8 + bob, "mint")
	after:set(8, 6 + bob, "cream"); after:set(9, 7 + bob, "cream")
	after:set(8, 8 + bob, "mint"); after:set(7, 9 + bob, "sea"); after:set(9, 9 + bob, "sea")
	after:set(7, 10 + bob, "mint"); after:set(9, 10 + bob, "sea")
	local spot = pick({ { 11, 3 }, { 14, 6 }, { 12, 12 }, { 3, 5 } }, f)
	after:set(spot[1], spot[2] + bob, "cream")
	return compose(16, 16, nil, g, after)
end

-- Feather: the shop's currency, a pale-gold angel feather (16x16, quill at the bottom left).
local function feather(f)
	local sway = pick({ 0, 0, 0.6, 0 }, f)
	local g = canvas(16, 16)
	-- Sampled along the shaft: u runs quill (0) to tip (1), d is the side distance.
	local ax, ay, bx, by = 2.5, 14.5, 13.5 + sway, 1.5
	local dx, dy = bx - ax, by - ay
	local len2 = dx * dx + dy * dy
	local len = math.sqrt(len2)
	for y = 0, 15 do
		for x = 0, 15 do
			local vx, vy = x + 0.5 - ax, y + 0.5 - ay
			local u = (vx * dx + vy * dy) / len2
			local d = (dx * vy - dy * vx) / len
			local w = u > 0.18 and 3.1 * math.sin(math.pi * math.min(1, (u - 0.18) / 0.84) ^ 0.75) or 0
			-- Two notches split the barbs, the way a real feather parts.
			local notch = (math.abs(u - 0.48) < 0.04 and d > 0.5) or (math.abs(u - 0.7) < 0.04 and d < -0.5)
			if u >= 0 and u <= 1.02 then
				if math.abs(d) < 0.55 then
					g:set(x, y, u < 0.2 and "sand" or "cream")
				elseif math.abs(d) <= w and not notch then
					if d > 0 then
						g:set(x, y, math.abs(d) > w - 1 and "cream" or "sand")
					else
						g:set(x, y, math.abs(d) > w - 1 and "rust" or "clay")
					end
				end
			end
		end
	end
	local after = canvas(16, 16)
	local spot = pick({ { 11, 3 }, { 9, 5 }, { 7, 8 }, { 9, 5 } }, f)
	after:set(spot[1], spot[2], "cream")
	return compose(16, 16, nil, g, after)
end

local function heart(f)
	local beat = pick({ 0, 0.4, 0.7, 0.2 }, f)
	local g = canvas(16, 16)
	local ramp = { "blood", "wine", "rust", "rose" }
	-- Glossy blood-red lobes, a deep cleft and one falling drop.
	g:ball(5.5, 6, 3.1 + beat, 3 + beat, ramp, 0.05)
	g:ball(10.5, 6, 3.1 + beat, 3 + beat, ramp, 0)
	g:poly({ { 2.5 - beat, 6.5 }, { 8, 8.5 }, { 13.5 + beat, 6.5 }, { 8, 14 + beat } }, ramp, -0.15)
	g:line(7, 3, 8, 5, "blood"); g:line(9, 3, 8, 5, "blood")
	g:line(3, 7, 6, 10, "wine"); g:line(13, 7, 10, 10, "blood")
	local after = canvas(16, 16)
	after:set(4, 4, "rose"); after:set(5, 3, "clay"); after:set(4, 5, "clay")
	after:set(6, 4, "rose")
	local drop = pick({ 0, 1, 1, 0 }, f)
	after:set(8, 15 - drop, "wine")
	if drop == 1 then after:set(8, 14, "rust") end
	return compose(16, 16, nil, g, after)
end

local function relic(f)
	local bob = pick({ 0, -1, -1, 0 }, f)
	local g = canvas(16, 16)
	-- A tiny monstrance: sunburst reliquary, holy cross and a stepped gold foot.
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		g:line(8 + math.cos(a) * 4, 6 + bob + math.sin(a) * 4, 8 + math.cos(a) * 6, 6 + bob + math.sin(a) * 6, i % 2 == 0 and "sand" or "clay")
	end
	g:ball(8, 6 + bob, 5, 5, GOLD, 0.05)
	g:oval(8, 6 + bob, 3, 3, "night")
	g:line(8, 10 + bob, 8, 13 + bob, "clay")
	g:line(7, 10 + bob, 7, 13 + bob, "rust")
	g:rect(5, 12 + bob, 7, 2, "clay")
	g:rect(3, 14 + bob, 11, 1, "sand")
	local after = canvas(16, 16)
	after:line(8, 3 + bob, 8, 9 + bob, "cream")
	after:line(5, 6 + bob, 11, 6 + bob, "cream")
	after:set(8, 6 + bob, "mint")
	after:line(5, 4 + bob, 6, 3 + bob, "sand")
	local spot = pick({ { 8, 0 }, { 14, 5 }, { 12, 10 }, { 2, 4 } }, f)
	after:set(spot[1], spot[2] + bob, "cream")
	return compose(16, 16, nil, g, after)
end

local function fireball(f)
	local g = canvas(16, 16)
	local lick = pick({ -1, 0, 1 }, f)
	-- A right-facing hellfire bolt with a ragged red tail, not a neutral orb.
	g:poly({ { 0, 7 + lick }, { 5, 5 }, { 4, 2 + lick }, { 8, 5 }, { 10, 3 }, { 13, 5 }, { 15, 8 }, { 12, 11 }, { 9, 13 }, { 8, 10 }, { 4, 13 - lick }, { 5, 9 }, { 0, 10 - lick }, { 2, 8 } }, { "blood", "wine", "rust", "clay" }, 0.05)
	g:ball(10, 8, 3.5, 3, { "wine", "rust", "clay", "sand" }, 0.05)
	g:line(4, 8, 12, 8, "sand"); g:line(6, 7, 12, 7, "clay")
	g:set(1, 5 - lick, "wine"); g:set(2, 12 + lick, "rust")
	local after = canvas(16, 16)
	after:line(8, 8, 13, 8, "cream")
	after:set(11, 6, "sand"); after:set(12, 7, "cream")
	after:set(14, 8, "sand")
	after:set(4 - f, 8 + lick, "clay")
	return compose(16, 16, nil, g, after)
end

local function poof(f)
	local c = canvas(32, 32)
	local spread = ({ 1, 4, 7, 10, 12 })[f + 1]
	local size = ({ 5, 6, 5, 4, 3 })[f + 1]
	local keep = ({ 1.0, 0.9, 0.7, 0.45, 0.22 })[f + 1]
	-- Six soft ash lobes expand, rise and dissolve through ordered dithering.
	for y = 0, 31 do
		for x = 0, 31 do
			local d = 99
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2 + f * 0.12
				local cx = 16 + math.cos(a) * spread
				local cy = 16 + math.sin(a) * spread * 0.7 - f * 0.5
				local r = size * (0.85 + (i % 3) * 0.08)
				d = math.min(d, math.sqrt((x + 0.5 - cx) ^ 2 + (y + 0.5 - cy) ^ 2) / r)
			end
			if d <= 1 and bayer(x + f, y) < keep then
				local col = d > 0.74 and "mauve" or (d > 0.34 and "rose" or "plum")
				if f < 2 and d < 0.3 then col = "clay" end
				c:set(x, y, col)
			end
		end
	end
	if f < 2 then c:ball(16, 16 - f, 2.5 - f, 2.5 - f, { "rose", "clay", "sand" }) end
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
	local g = canvas(80, 80)
	local stone = { "black", "abyss", "night", "navy", "steel" }
	-- Stepped plinth, tapered gothic shaft and side buttresses.
	g:poly({ { 9, 64 }, { 71, 64 }, { 76, 70 }, { 68, 76 }, { 12, 76 }, { 4, 70 } }, stone, -0.15)
	g:poly({ { 14, 59 }, { 66, 59 }, { 71, 64 }, { 66, 69 }, { 14, 69 }, { 9, 64 } }, stone, 0)
	g:poly({ { 25, 20 }, { 55, 20 }, { 59, 61 }, { 21, 61 } }, stone, -0.05)
	g:poly({ { 17, 32 }, { 27, 23 }, { 25, 60 }, { 15, 65 }, { 20, 47 } }, stone, -0.15)
	g:poly({ { 53, 23 }, { 63, 32 }, { 60, 47 }, { 65, 65 }, { 55, 60 } }, stone, -0.2)
	for y = 34, 59, 8 do
		g:line(24, y, 56, y, "black")
		local off = (y // 8) % 2 == 0 and 0 or 8
		for x = 28 + off, 54, 16 do g:line(x, y - 7, x, y, "abyss") end
	end
	g:poly({ { 27, 20 }, { 29, 10 }, { 35, 10 }, { 40, 3 }, { 45, 10 }, { 51, 10 }, { 53, 20 } }, stone, 0.05)
	g:poly({ { 20, 18 }, { 60, 18 }, { 64, 24 }, { 56, 29 }, { 24, 29 }, { 16, 24 } }, stone, 0.05)
	g:line(17, 24, 63, 24, "navy")
	-- A horned skull crowns the shrine above a blood-lit pointed niche.
	g:line(35, 13, 29, 7, "clay"); g:line(34, 12, 28, 6, "sand")
	g:line(29, 7, 26, 2, "sand"); g:set(26, 2, "cream")
	g:line(45, 13, 51, 7, "clay"); g:line(46, 12, 52, 6, "sand")
	g:line(51, 7, 54, 2, "sand"); g:set(54, 2, "cream")
	g:ball(40, 14, 8, 7, { "blood", "wine", "rust", "clay" }, 0.05)
	g:poly({ { 31, 56 }, { 31, 38 }, { 40, 29 }, { 49, 38 }, { 49, 56 } }, { "black", "blood" })
	g:line(30, 56, 30, 38, "navy"); g:line(30, 38, 40, 28, "navy")
	g:line(40, 28, 50, 38, "night"); g:line(50, 38, 50, 56, "night")
	-- Twin hellfire cups and veins staining the old stone.
	for _, x in ipairs({ 23, 57 }) do
		g:ball(x, 51, 3, 2, { "blood", "wine", "rust" })
		g:line(x, 49, x - 1, 44, "rust"); g:set(x, 43, "sand")
		g:set(x + 1, 46, "clay")
	end
	g:line(20, 57, 17, 63, "wine"); g:line(17, 63, 24, 70, "wine")
	g:line(59, 55, 62, 64, "wine"); g:line(62, 64, 57, 72, "blood")
	g:line(14, 69, 66, 69, "black"); g:line(10, 73, 70, 73, "abyss")
	local after = canvas(80, 80)
	after:line(35, 13, 38, 13, "black"); after:line(42, 13, 45, 13, "black")
	after:set(37, 13, "rust"); after:set(43, 13, "rust")
	after:set(40, 16, "black"); after:set(36, 19, "sand"); after:set(44, 19, "sand")
	-- The low crossbar makes the shrine's inverted cross unmistakable.
	after:line(40, 34, 40, 52, "rust")
	after:line(35, 47, 45, 47, "clay")
	after:set(40, 34, "clay"); after:set(40, 52, "sand"); after:set(40, 47, "sand")
	after:set(23, 43, "cream"); after:set(57, 43, "cream")
	return compose(80, 80, ground_shadow(80, 80, 40, 73, 34, 5), g, after)
end

local function landing(_)
	local c = canvas(64, 64)
	-- A luminous, top-down ellipse: concentric holy rings, runes and a cross.
	for y = 0, 63 do
		for x = 0, 63 do
			local nx, ny = (x + 0.5 - 32) / 28, (y + 0.5 - 32) / 14
			local d = math.sqrt(nx * nx + ny * ny)
			if d > 1 and d < 1.12 and bayer(x, y) < 0.22 then
				c:set(x, y, "navy")
			elseif d <= 1 then
				if d < 0.86 and bayer(x, y) < (1 - d) * 0.15 then c:set(x, y, "steel") end
				if d >= 0.88 and d <= 0.98 then
					local col = d > 0.95 and bayer(x, y) < 0.45 and "cream" or "mint"
					c:set(x, y, col)
				elseif d > 0.80 and d < 0.88 and bayer(x, y) < 0.5 then
					c:set(x, y, "sea")
				end
				if d >= 0.47 and d <= 0.55 and bayer(x + 1, y) < 0.88 then c:set(x, y, "sea") end
			end
		end
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		c:line(32 + math.cos(a) * 29, 32 + math.sin(a) * 14.5, 32 + math.cos(a) * 31, 32 + math.sin(a) * 16, i % 2 == 0 and "mint" or "sea")
		c:set(32 + math.cos(a) * 20, 32 + math.sin(a) * 10, "sand")
		c:set(32 + math.cos(a + 0.08) * 20, 32 + math.sin(a + 0.08) * 10, "cream")
	end
	c:line(32, 25, 32, 39, "sand"); c:line(25, 32, 39, 32, "sand")
	c:line(32, 27, 32, 37, "cream"); c:line(27, 32, 37, 32, "cream")
	c:line(28, 28, 36, 36, "sea"); c:line(36, 28, 28, 36, "sea")
	c:set(32, 32, "mint")
	-- Three rising motes connect the ground seal to the descending angel.
	c:set(30, 14, "sea"); c:set(34, 9, "mint"); c:set(31, 4, "sand")
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
build("pickup_feather", 16, 16, { { "idle", 4, 0.16, feather } })
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
