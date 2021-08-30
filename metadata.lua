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

lua_inv.registered_metadata_allow_changes = {}
lua_inv.registered_metadata_on_changes = {}

function lua_inv.register_metadata_allow_change(func)
	table.insert(lua_inv.registered_itemstack_allow_changes, func)
end

function lua_inv.register_metadata_on_change(func)
	table.insert(lua_inv.registered_itemstack_on_changes, func)
end

local static = {
	allow_change = function(self, k, v)
		for _, func in ipairs(lua_inv.registered_metadata_allow_changes) do
			if not func(self, k, v) then
				return false
			end
		end
	
		if self.parent and self.parent.metadata_allow_change and not self.parent.metadata_allow_change(self.parent, self, k, v) then
			return false
		end

		return true
	end,

	on_change = function(self, k, v)
		for _, func in ipairs(lua_inv.registered_metadata_on_changes) do
			v = func(self, k, v) or v
		end
	
		if self.parent and self.parent.metadata_on_change then
			v = self.parent.metadata_on_change(self.parent, self, k, v) or v
		end
	
		return v
	end,

	contains = function(self, key)
		return self:get(key) ~= nil
	end,

	get = function(self, key)
		return self.data[key]
	end,

	remove = function(self, key)
		if not self:allow_change(key, nil) then
			return false
		end

		local v = nil

		v = self:on_change(key, v)

		rawset(self.data, key, v)

		return v or true
	end,

	set_string = function(self, key, str)
		if not self:allow_change(key, str) then
			return false
		end

		str = self:on_change(key, str)

		if (not str or str == "") then
			str = self:remove(key)

			if str == true then
				return nil
			end
		end

		rawset(self.data, key, tostring(str))
		return self:get(key)
	end,

	get_string = function(self, key)
		return tostring(self:get(key) or "")
	end,

	set_int = function(self, key, int)
		if not self:allow_change(key, int) then
			return false
		end

		int = self:on_change(key, int)

		int = tonumber(int)

		if int then
			rawset(self.data, key, math.floor(int + 0.5))
			return self:get(key)
		else
			return false
		end
	end,

	get_int = function(self, key)
		return math.floor((tonumber(self:get(key)) or 0) + 0.5)
	end,

	set_float = function(self, key, flt)
		if not self:allow_change(key, flt) then
			return false
		end

		flt = self:on_change(key, flt)

		flt = tonumber(flt)

		if flt then
			rawset(self.data, key, flt)
			return self:get(key)
		else
			return false
		end
	end,

	get_float = function(self, key)
		return tonumber(self:get(key) or 0.0)
	end,

	to_table = function(self)
		local tbl = {}

		for k, v in pairs(self.data) do
			tbl[k] = v
		end

		return tbl
	end,

	from_table = function(self, tbl)
		for k in pairs(self.data) do
			self:remove(k)
		end

		for k, v in pairs(tbl) do
			if type(v) == "string" then
				self:set_string(k, v)
			elseif type(v) == "number" then
				self:set_float(k, v)
			end
		end

		return self
	end,

	equals = function(self, other)
		return self == other
	end,

	serialize = function(self)
		local ser = "{"

		for k, v in pairs(self:to_table()) do
			if type(v) == "string" then
				v = "\""..v.."\""
			end

			ser = ser.."[\""..k.."\"] = "..v..","
		end

		if ser == "{" then
			return "{}"
		end

		return ser:sub(1, ser:len()-1).."}"
	end,

	eq = function(self, other)
		local selft = self:to_table()
		local othert = other:to_table()

		for k, v in pairs(selft) do
			if v ~= othert[k] then
				return false
			end
		end

		for k, v in pairs(othert) do
			if v ~= selft[k] then
				return false
			end
		end

		return true
	end,
}

function lua_inv.metadata(p)
	return setmetatable({}, {
		__index = {
			data = setmetatable({}, {
				__newindex = function(self, key, val)
					error("Error: Attempt to directly set a value in a metadata's internal storage. Please call one of the provided functions instead.")
				end,

				__metatable = false,
			}),
			
			parent = setmetatable({}, {
				__index = p or {orphaned = true},

				__newindex = function(self, key, val)
					error("Error: Attempt to directly set a metadata's parent. This can only be done in the constructor.")
				end,

				__metatable = false
			}),

			allow_change = static.allow_change,
			on_change = static.on_change,
			contains = static.contains,
			get = static.get,
			remove = static.remove,
			set_string = static.set_string,
			get_string = static.get_string,
			set_int = static.set_int,
			get_int = static.get_int,
			set_float = static.set_float,
			get_float = static.get_float,
			to_table = static.to_table,
			from_table = static.from_table,
			equals = static.equals,
			serialize = static.serialize,
		},

		__newindex = function(self, key, val)
			error("Error: Attempt to directly set a value in a metadata object. Please call one of the provided functions instead.")
		end,

		__eq = static.eq,

		__metatable = {},
	})
end
