--[[
Complete and Total Lua-Only Inventory Rewrite
Copyright (C) 2021 Noodlemire

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
--]]

local function clear(self)
	rawset(self, "name", "")
	rawset(self, "count", 0)
	rawset(self, "wear", 0)
	rawset(self, "tool_capabilities", nil)
	self:get_meta():from_table({})
end

lua_inv.registered_itemstack_allow_changes = {}
lua_inv.registered_itemstack_on_changes = {}
lua_inv.registered_itemstack_after_changes = {}

function lua_inv.register_itemstack_allow_change(func)
	table.insert(lua_inv.registered_itemstack_allow_changes, func)
end

function lua_inv.register_itemstack_on_change(func)
	table.insert(lua_inv.registered_itemstack_on_changes, func)
end

function lua_inv.register_itemstack_after_change(func)
	table.insert(lua_inv.registered_itemstack_after_changes, func)
end

local function tileToString(tile)
	if not tile then return end

	if type(tile) == "string" then
		return tile
	else
		return tile.name
	end
end

local static = {
	allow_change = function(self, k, v)
		for _, func in ipairs(lua_inv.registered_itemstack_allow_changes) do
			if not func(self, k, v) then
				return false
			end
		end
	
		if self:is_known() and self:get_definition()._lua_inv_allow_change and not self:get_definition()._lua_inv_allow_change(self, k, v) then
			return false
		end

		if self.parent and self.parent.inv and self.parent.inv.allow_change and not self.parent.inv:allow_change({type = "set", stack = self, key = k, val = v}) then
			return false
		end
	
		return true
	end,

	on_change = function(self, k, v)
		for _, func in ipairs(lua_inv.registered_itemstack_on_changes) do
			v = func(self, k, v) or v
		end
	
		if self:is_known() and self:get_definition()._lua_inv_on_change then
			v = self:get_definition()._lua_inv_on_change(self, k, v) or v
		end

		if self.parent and self.parent.inv and self.parent.inv.on_change then
			v = self.parent.inv:on_change({type = "set", stack = self, key = k, val = v}) or v
		end
	
		return v
	end,

	after_change = function(self, k, init_v, final_v)
		for _, func in ipairs(lua_inv.registered_itemstack_after_changes) do
			func(self, k, init_v, final_v)
		end
	
		if self:is_known() and self:get_definition()._lua_inv_after_change then
			self:get_definition()._lua_inv_after_change(self, k, init_v, final_v)
		end

		if self.parent and self.parent.inv and self.parent.inv.after_change then
			self.parent.inv:after_change({type = "set", stack = self, key = k, init_val = init_v, final_val = final_v})
		end
	end,

	metadata_allow_change = function(self, meta, k, v)
		if self:is_known() and self:get_definition()._lua_inv_metadata_allow_change and self:get_definition()._lua_inv_metadata_allow_change(self, meta, k, v) then
			return false
		end

		return true
	end,

	metadata_on_change = function(self, meta, k, v)
		return self:is_known() and self:get_definition()._lua_inv_metadata_on_change and
			self:get_definition()._lua_inv_metadata_on_change(self, meta, k, v)
	end,
	
	is_empty = function(self)
		return self:get_name() == "" or self:get_count() == 0
	end,

	is_full = function(self)
		return self:get_count() == self:get_stack_max()
	end,

	get_name = function(self)
		return tostring(rawget(self, "name"))
	end,

	set_name = function(self, n)
		local init_name = n

		if not self:allow_change("name", n) then
			return self:get_name()
		end
	
		n = self:on_change("name", n)

		if n ~= "" then
			rawset(self, "name", tostring(n))
		else
			clear(self)
		end

		self:after_change("name", init_name, self:get_name())

		return self:get_name()
	end,

	get_count = function(self)
		return tonumber(rawget(self, "count"))
	end,

	set_count = function(self, c)
		local init_count = c

		if not self:allow_change("count", c) then
			return self:get_count()
		end
	
		c = self:on_change("count", c)

		c = tonumber(c)
	
		if c > 0 then
			rawset(self, "count", math.min(c, self:get_stack_max()))
		else
			clear(self)
		end

		self:after_change("count", init_count, self:get_count())

		return self:get_count()
	end,

	get_wear = function(self)
		return tonumber(rawget(self, "wear"))
	end,

	set_wear = function(self, w)
		local init_wear = w

		if not self:allow_change("wear", w) then
			return self:get_wear()
		end
	
		w = self:on_change("wear", w)

		w = tonumber(w)
	
		if w >= 100 then
			local taken = math.floor(w / 100)
			self:take_item(taken)
			w = w - taken * 100
		end

		if not self:is_empty() then
			rawset(self, "wear", w)
		end

		self:after_change("wear", init_wear, self:get_wear())

		return self:get_wear()
	end,

	get_meta = function(self)
		return self.meta
	end,

	get_total_size = function(self)
		return self:get_count() + (100 - self:get_wear()) / 100 - 1
	end,

	get_description = function(self)
		return self:get_meta():get("description") or
			self:is_known() and self:get_definition().description or
			minetest.registered_items["unknown"].description
	end,

	get_inventory_image = function(self, nil_if_tiles)
		if not self:is_known() then
			return "unknown_item.png"
		end

		local def = self:get_definition()
		local image = self:get_meta():get("inventory_image") or def.inventory_image
		local tiles = def.tiles

		if (not image or image == "") then
			if tiles then
				if nil_if_tiles then return end

				local t2 = tileToString(tiles[3]) or tileToString(tiles[2]) or tileToString(tiles[1])
				local t3 = tileToString(tiles[6]) or t2
				image = minetest.inventorycube(tileToString(tiles[1]), t3, t2)
			else
				image = "lua_inv_INV_IMG_NIL.png"
			end
		end

		return image
	end,

	get_animation = function(self, frame)
		local def = self:get_definition()
		local meta = self:get_meta()

		local anim = nil

		if def and def._lua_inv_animation then
			anim = def._lua_inv_animation(self, frame)
			anim.speed = anim.speed or (1000 / anim.frames)
		end

		if anim and false then
			anim.frames = meta:contains("frames") and meta:get_int("frames") or anim.frames
			anim.speed = meta:contains("speed") and meta:get_int("speed") or anim.speed
			anim.frame_template = meta:contains("frame_template") and meta:get_string("frame_template") or anim.frames
		elseif meta:contains("frames") and meta:contains("frame_template") then
			anim = {}

			anim.frames = meta:get_int("frames")
			anim.speed = meta:contains("speed") and meta:get_float("speed") or (1000 / anim.frames)
			anim.frame_template = meta:get_string("frame_template")
		end

		return anim
	end,

	get_wear_visual = function(self)
		local wear_percent = math.floor(100 - self:get_wear())

		local r = string.format("%x", math.min(255, 500 - 5 * wear_percent))
		local g = string.format("%x", math.min(255, 5 * wear_percent))

		if r:len() == 1 then r = '0'..r end
		if g:len() == 1 then g = '0'..g end

		return "lua_inv_bar_bg.png^[lowpart:"..wear_percent..":lua_inv_bar.png^[multiply:#"..r..g.."00^[transformR270]"
	end,

	to_string = function(self)
		local str = self:get_name()

		if self:get_count() > 1 or self:get_wear() > 0 or #self:get_meta() > 0 then
			str = str..' '..self:get_count()
		end

		if self:get_wear() > 0 or #self:get_meta() > 0 then
			str = str..' '..self:get_wear()
		end

		local metatable = self:get_meta():to_table()
		if next(metatable) then
			str = str..' '..minetest.serialize(metatable)
		end

		return str
	end,

	get_stack_max = function(self)
		return self:is_known() and self:get_definition().stack_max or minetest.settings:get("default_stack_max") or 99
	end,

	get_free_space = function(self)
		return self:get_stack_max() - self:get_count()
	end,

	is_known = function(self)
		return self:get_definition() ~= nil
	end,

	get_definition = function(self)
		return minetest.registered_items[self:get_name()]
	end,

	has_custom_tool_capabilities = function(self)
		return rawget(self, "tool_capabilities") ~= nil
	end,

	get_tool_capabilities = function(self)
		return rawget(self, "tool_capabilities") or
			self:is_known() and self:get_definition().tool_capabilities or
			minetest.registered_items[""].tool_capabilities
	end,

	set_tool_capabilities = function(self, tool_caps)
		rawset(self, "tool_capabilities", tool_caps)
	end,

	add_wear = function(self, amount)
		return self:set_wear(self:get_wear() + amount)
	end,

	is_similar = function(self, other)
		if self:is_known() and self:get_definition()._lua_inv_is_similar then
			return self:get_definition()._lua_inv_is_similar(self, other)
		else
			return self:get_name() == other:get_name() and self:get_meta() == other:get_meta()
		end
	end,

	add_item = function(self, other)
		return self + other
	end,

	item_fits = function(self, other)
		return (self:is_similar(other) or self:is_empty() or other:is_empty()) and self:get_total_size() + other:get_total_size() <= self:get_stack_max()
	end,

	take_item = function(self, n)
		n = n or 1
		local taken = math.min(self:get_count(), n)

		local old_name, old_wear, old_meta = self:get_name(), self:get_wear(), self:get_meta():to_table()

		taken = self:get_count() - self:set_count(self:get_count() - taken)

		if taken > 0 then
			local wear = old_wear - self:set_wear(0)

			return lua_inv.itemstack(old_name, taken, wear, old_meta)
		else
			return lua_inv.itemstack()
		end
	end,

	peek_item = function(self, n)
		n = n or 1

		return lua_inv.itemstack(self:get_name(), n, self:get_wear(), self:get_meta():to_table())
	end,

	serialize = function(self)
		return "{[\"name\"] = \""..self:get_name().."\","
				.."[\"count\"] = "..self:get_count()..","
				.."[\"wear\"] = "..self:get_wear()..","
				.."[\"meta\"] = "..self:get_meta():serialize().."}"
	end,

	add = function(self, other)
		if self:is_empty() then
			self:set_name(other:get_name())
		end

		if other:is_empty() then
			return self
		end

		if self:is_similar(other) then
			if self:is_known() and self:get_definition()._lua_inv_add then
				self:get_definition()._lua_inv_add(self, other)
			else
				local max = self:get_stack_max()
				local total_count = self:get_count() + other:get_count()
				local total_wear = self:get_wear() + other:get_wear()
				self:get_meta():from_table(other:get_meta():to_table())
			
				if total_count > max then
					local c = self:set_count(max)
					other:set_count(total_count - c)

					if total_wear / 100 > other:get_count() then
						local w = self:set_wear(total_wear - other:get_count() * 100)

						other:set_wear(total_wear - (w + other:get_count() * 100))
					else
						local w = total_wear - self:set_wear(0)
						other:set_wear(w)
					end
				else
					local c = total_count - self:set_count(total_count)
					local w = total_wear - self:set_wear(total_wear)

					if other:set_count(c) > 0 then
						other:set_wear(w)
					end
				end
			end
		end

		return self
	end,

	eq = function(self, other)
		return self:get_name() == other:get_name() and self:get_count() == other:get_count() and self:get_wear() == other:get_wear() and self:get_meta() == other:get_meta()
	end,

	lt = function(self, other)
		return self:get_total_size() < other:get_total_size()
	end,

	le = function(self, other)
		return self:get_total_size() <= other:get_total_size()
	end,
}

function lua_inv.itemstack(input_name, input_count, input_wear, input_meta, input_parent)
	input_name = (not input_count or input_count > 0) and input_name
	input_count = input_name and input_name ~= "" and input_count

	local itemstack = {
		name = input_name or "",
		count = input_count or (input_name and 1) or 0,
		wear = input_wear or 0,
		tool_capabilities = nil,
	}
	
	local return_stack = setmetatable(itemstack, {
		__index = {
			parent = setmetatable({}, {
				__index = input_parent or {orphaned = true},

				__newindex = function(self, key, val)
					error("Error: Attempt to directly set an itemstack's parent. This can only be done in the constructor.")
				end,

				__metatable = false
			}),

			allow_change = static.allow_change,
			on_change = static.on_change,
			after_change = static.after_change,
			metadata_allow_change = static.metadata_allow_change,
			metadata_on_change = static.metadata_on_change,
			is_empty = static.is_empty,
			is_full = static.is_full,
			get_name = static.get_name,
			set_name = static.set_name,
			get_count = static.get_count,
			set_count = static.set_count,
			get_wear = static.get_wear,
			set_wear = static.set_wear,
			get_meta = static.get_meta,
			get_total_size = static.get_total_size,
			get_description = static.get_description,
			get_inventory_image = static.get_inventory_image,
			get_animation = static.get_animation,
			get_wear_visual = static.get_wear_visual,
			to_string = static.to_string,
			get_stack_max = static.get_stack_max,
			get_free_space = static.get_free_space,
			is_known = static.is_known,
			get_definition = static.get_definition,
			has_custom_tool_capabilities = static.has_custom_tool_capabilities,
			get_tool_capabilities = static.get_tool_capabilities,
			set_tool_capabilities = static.set_tool_capabilities,
			add_wear = static.add_wear,
			is_similar = static.is_similar,
			add_item = static.add_item,
			item_fits = static.item_fits,
			take_item = static.take_item,
			peek_item = static.peek_item,
			serialize = static.serialize,
		},

		__newindex = function(self, key, val)
			error("Error: Attempt to directly set a value in an itemstack object. Please call one of the provided functions instead.")
		end,

		__add = static.add,
		__eq = static.eq,
		__lt = static.lt,
		__le = static.le,
	})

	getmetatable(return_stack).__index.meta = lua_inv.metadata(itemstack)
	getmetatable(return_stack).__metatable = false

	if input_meta then
		return_stack:get_meta():from_table(input_meta)
	end

	return return_stack
end

function lua_inv.itemstack_from_string(str)
	local splits = str:split("return", false, 1)
	if not splits[1] then return lua_inv.itemstack() end

	local stats = splits[1]:split(' ')

	local meta = nil

	if splits[2] then
		meta = minetest.deserialize("return"..splits[2])
	end

	return lua_inv.itemstack(stats[1], stats[2] or 1, stats[3], meta)
end

function lua_inv.itemstack_from_userdata(itemstack)
	if type(itemstack) ~= "userdata" then return itemstack end

	return lua_inv.itemstack(itemstack:get_name(), itemstack:get_count(), itemstack:get_wear() / 655.35, itemstack:get_meta():to_table().fields)
end

function lua_inv.itemstack_to_userdata(itemstack)
	if type(itemstack) ~= "table" then return itemstack end

	local stack = ItemStack({
		name = itemstack:get_name(),
		count = itemstack:get_count(),
		wear = math.floor(itemstack:get_wear() * 655.35),
		meta = itemstack:get_meta():to_table()
	})

	return stack
end
