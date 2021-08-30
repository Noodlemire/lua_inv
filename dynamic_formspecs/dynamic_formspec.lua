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

function lua_inv.dynamic_formspec(input_elems)
	local index = {
		elems = setmetatable(input_elems or {}, {
			__newindex = function(self, key, val)
				error("Error: Attempt to directly set a value in a dynamic formspec's list of elements. Please call one of the provided functions instead.")
			end,

			__metatable = false,
		}),

		size = function(self)
			return #self.elems
		end,

		get = function(self, i)
			return self.elems[i]
		end,

		set = function(self, i, element)
			if not element then
				return self:del(i)
			else
				rawset(self.elems, i, element)
			end
		end,

		add = function(self, element)
			self:set(self:size() + 1, element)
		end,

		del = function(self, i)
			for n = i, self:size() - 1 do
				rawset(self.elems, n, self:get(n + 1))
			end

			rawset(self.elems, self:size(), nil)
		end,

		form = function(self, player, formname, fields)
			local formspec = ""

			for i = 1, self:size() do
				local element = self:get(i):to_string(player, formname, fields)

				formspec = formspec..element
			end

			self.temp_meta:from_table({})

			return formspec
		end,
	}

	index.meta = lua_inv.metadata(index)
	index.temp_meta = lua_inv.metadata(index)

	return setmetatable({}, {
		__index = index,

		__newindex = function(self, key, val)
			error("Error: Attempt to directly set a value in a dynamic formspec object. Please call one of the provided functions instead.")
		end,

		__metatable = false,
	})
end

function lua_inv.get_df_meta(player)
	if lua_inv.open_formspecs[player:get_player_name()] then
		return lua_inv.open_formspecs[player:get_player_name()].meta, lua_inv.open_formspecs[player:get_player_name()].temp_meta
	end
end

function lua_inv.dynamic_formspec_from_string(str)
	local lines = str:split(']')

	for i = 1, #lines do
		lines[i] = lua_inv.formspec_element_from_string(lines[i])
	end

	local df = lua_inv.dynamic_formspec()

	for i = 1, #lines do
		df:add(lines[i])
	end

	return df
end
