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

local function replace(self, replacement)
	local self_name = self:get_name()
	local self_count = self:get_count()
	local self_wear = self:get_wear()
	local self_tool_capabilities = self:has_custom_tool_capabilities() and self:get_tool_capabilities()
	local self_meta = self:get_meta():to_table()

	rawset(self, "name", replacement:get_name())
	rawset(self, "count", replacement:get_count())
	rawset(self, "wear", replacement:get_wear())
	rawset(self, "tool_capabilities", replacement:has_custom_tool_capabilities() and replacement:get_tool_capabilities())
	self:get_meta():from_table(replacement:get_meta():to_table())

	rawset(replacement, "name", self_name)
	rawset(replacement, "count", self_count)
	rawset(replacement, "wear", self_wear)
	rawset(replacement, "tool_capabilities", self_tool_capabilities)
	replacement:get_meta():from_table(self_meta)
end



lua_inv.registered_inventory_allow_changes = {}
lua_inv.registered_inventory_on_changes = {}
lua_inv.registered_inventory_after_changes = {}

function lua_inv.register_inventory_allow_change(func)
	table.insert(lua_inv.registered_inventory_allow_changes, func)
end

function lua_inv.register_inventory_on_change(func)
	table.insert(lua_inv.registered_inventory_on_changes, func)
end

function lua_inv.register_inventory_after_change(func)
	table.insert(lua_inv.registered_inventory_after_changes, func)
end

local static = {
	get_allow_change = function(self)
		return self.callbacks.allow_change or function() return true end
	end,

	get_on_change = function(self)
		return self.callbacks.on_change or function() end
	end,

	get_after_change = function(self)
		return self.callbacks.after_change or function() end
	end,

	allow_change = function(self, change)
		for _, func in ipairs(lua_inv.registered_inventory_allow_changes) do
			if not func(self, change) then
				return false
			end
		end

		if not self:get_allow_change()(self, change) then
			return false
		end
	
		return true
	end,

	on_change = function(self, change)
		for _, func in ipairs(lua_inv.registered_inventory_on_changes) do
			func(self, change)
		end
	
		self:get_on_change()(self, change)
	end,

	after_change = function(self, change)
		for _, func in ipairs(lua_inv.registered_inventory_after_changes) do
			func(self, change)
		end
	
		self:get_after_change()(self, change)
	end,

	is_empty = function(self, listname)
		if listname then
			for i = 1, self:get_size(listname) do
				if not self:get_stack(listname, i):is_empty() then
					return false
				end
			end

			return true
		else
			for list in pairs(self.data) do
				if not self:is_empty(list) then
					return false
				end
			end

			return true
		end
	end,

	get_size = function(self, listname)
		return #(self.data[listname] or {})
	end,

	set_size = function(self, listname, size)
		if size < 0 then
			return self
		elseif size == 0 then
			rawset(self.data, listname, nil)
			return self
		end

		local newlist = {}
		rawset(self.data, listname, {})

		for i = 1, size do
			newlist[i] = self.data[listname][i] or lua_inv.itemstack(nil, nil, nil, nil, {inv = self, list = listname, index = i})
		end

		newlist = setmetatable(newlist, {
			--__index = newlist,

			__newindex = function(self, key, val)
				error("Error: Attempt to directly set a value in an inventory list object. Please call one of the provided functions instead.")
			end,

			__metatable = false,
		})

		rawset(self.data, listname, newlist)

		return self
	end,

	get_width = function(self, listname)
		return self.width[listname] or 1
	end,

	set_width = function(self, listname, width)
		width = tonumber(width)

		if width then
			width = math.floor(width)
			rawset(self.width, listname, width)
			return width
		else
			return false
		end
	end,

	get_stack = function(self, listname, i)
		i = tonumber(i)

		return self.data[listname][i]
	end,

	set_stack = function(self, listname, i, itemstack)
		i = tonumber(i)

		if i >= 1 and i <= self:get_size(listname) and self:allow_change({type = "swap", stack1 = self:get_stack(listname, i), stack2 = itemstack})
				and (itemstack.parent.orphaned or itemstack.parent.inv:allow_change({type = "swap", stack1 = itemstack, stack2 = self:get_stack(listname, i)})) then

			self:on_change({type = "swap", stack1 = self:get_stack(listname, i), stack2 = itemstack})

			if not itemstack.parent.orphaned then
				itemstack.parent.inv:on_change({type = "swap", stack1 = itemstack, stack2 = self:get_stack(listname, i)})
			end

			if itemstack then
				replace(self.data[listname][i], itemstack)
			else
				self.data[listname][i]:set_name("")
			end

			self:after_change({type = "swap", stack1 = self:get_stack(listname, i), stack2 = itemstack})

			if not itemstack.parent.orphaned then
				itemstack.parent.inv:after_change({type = "swap", stack1 = itemstack, stack2 = self:get_stack(listname, i)})
			end
		else
			return false
		end

		return self:get_stack(listname, i)
	end,

	get_list = function(self, listname)
		return self.data[listname]
	end,

	set_list = function(self, listname, list)
		for i = 1, self:get_size(listname) do
			self:set_stack(listname, i, list[i])
		end
	end,

	get_lists = function(self)
		return self.data
	end,

	set_lists = function(self, lists)
		for listname in pairs(self.data) do
			self:set_size(listname, 0)
		end

		for listname, list in pairs(lists) do
			self:set_size(listname, #list)
			self:set_list(listname, list)
		end
	end,

	add_item = function(self, listname, stack)
		local first_empty = false

		for i = 1, self:get_size(listname) do
			if not first_empty and self:get_stack(listname, i):is_empty() then
				first_empty = i
			end

			if self:get_stack(listname, i):is_similar(stack) then
				self:get_stack(listname, i):add_item(stack)

				if stack:is_empty() then
					return stack
				end
			end
		end

		if first_empty then
			for i = first_empty, self:get_size(listname) do
				if self:get_stack(listname, i):is_empty() then
					self:get_stack(listname, i):add_item(stack)

					if stack:is_empty() then
						return stack
					end
				end
			end
		end

		return stack
	end,

	room_for_item = function(self, listname, stack)
		for i = 1, self:get_size(listname) do
			if self:get_stack(listname, i):item_fits(stack) then
				return true
			end
		end

		return false
	end,

	contains_item = function(self, listname, stack, match_meta)
		for i = 1, self:get_size(listname) do
			local cur_stack = self:get_stack(listname, i)

			if cur_stack:get_name() == stack:get_name() and cur_stack:get_total_size() <= stack:get_total_size() and
					(not match_meta or cur_stack:is_similar(stack)) then
				return true
			end
		end

		return false
	end,

	remove_item = function(self, listname, stack, match_meta)
		local removed = lua_inv.itemstack(stack:get_name())

		if match_meta then
			removed:get_meta():from_table(stack:get_meta():to_table())
		end

		for i = 1, self:get_size(listname) do
			local cur_stack = self:get_stack(listname, i)

			if cur_stack:get_name() == stack:get_name() and (not match_meta or cur_stack:get_meta() == stack:get_meta()) then
				local needed = stack:get_total_size() - removed:get_total_size()

				removed:add_item(cur_stack:take_item(needed))

				if removed:get_total_size() >= stack:get_total_size() then
					break
				end
			end
		end

		return removed
	end,

	serialize = function(self)
		local ser = "{"

		for listname in pairs(self:get_lists()) do
			ser = ser.."[\""..listname.."\"] = {"

			for i = 1, self:get_size(listname) do
				ser = ser.."["..i.."] = "..self:get_stack(listname, i):serialize()..","
			end

			ser = ser:sub(1, ser:len()-1).."},"
		end

		return ser:sub(1, math.max(1, ser:len()-1)).."}"
	end,
}

function lua_inv.inventory(input_parent, allow_change_func, on_change_func, after_change_func)
	return setmetatable({}, {
		__index = {
			data = setmetatable({}, {
				__newindex = function(self, key, val)
					error("Error: Attempt to directly set a value in an inventory's data object. Please call one of the provided functions instead.")
				end,

				__metatable = false,
			}),

			width = setmetatable({}, {
				__newindex = function(self, key, val)
					error("Error: Attempt to directly set a value in an inventory's width list. Please call one of the provided functions instead.")
				end,

				__metatable = false,
			}),

			callbacks = setmetatable({}, {
				__index = {
					allow_change = allow_change_func,
					on_change = on_change_func,
					after_change = after_change_func,
				},

				__newindex = function(self, key, val)
					error("Error: Attempt to directly set a value in an inventory's callback list. Please call one of the provided functions instead.")
				end,

				__metatable = false,
			}),

			parent = setmetatable({}, {
				__index = input_parent or {orphaned = true},

				__newindex = function(self, key, val)
					error("Error: Attempt to directly set an inventory's parent. This can only be done in the constructor.")
				end,

				__metatable = false
			}),

			get_allow_change = static.get_allow_change,
			get_on_change = static.get_on_change,
			get_after_change = static.get_after_change,
			allow_change = static.allow_change,
			on_change = static.on_change,
			after_change = static.after_change,
			is_empty = static.is_empty,
			get_size = static.get_size,
			set_size = static.set_size,
			get_width = static.get_width,
			set_width = static.set_width,
			get_stack = static.get_stack,
			set_stack = static.set_stack,
			get_list = static.get_list,
			set_list = static.set_list,
			get_lists = static.get_lists,
			set_lists = static.set_lists,
			add_item = static.add_item,
			room_for_item = static.room_for_item,
			contains_item = static.contains_item,
			remove_item = static.remove_item,
			serialize = static.serialize,
		},

		__newindex = function(self, key, val)
			error("Error: Attempt to directly set a value in an inventory object. Please call one of the provided functions instead.")
		end,

		__metatable = false,
	})
end

function lua_inv.inventory_from_serialized_string(serial, new_inv)
	local stored_inv = minetest.deserialize(serial)

	for listname, list in pairs(stored_inv or {}) do
		new_inv:set_size(listname, #list)

		for i = 1, #list do
			new_inv:set_stack(listname, i, lua_inv.itemstack(list[i].name, list[i].count, list[i].wear, list[i].meta))
		end
	end
end
