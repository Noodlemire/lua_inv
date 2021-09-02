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

local function page_tabs(df)
	--tabheader[<X>,<Y>;<name>;<caption 1>,<caption 2>,...,<caption n>;<current_tab>;<transparent>;<draw_border>]
	
	local elems = {{0, 0}, "page_tabs", {}, df:page_current()}
	
	return lua_inv.formspec_element("tabheader", elems, function(self, player, formname, fields)
		self.args[3] = df.pageTitles
	
		if fields then
			local df = lua_inv.open_formspecs[player:get_player_name()]
			local tab = fields.page_tabs
		
			if tab then
				df:page_switch(tonumber(tab))
				self.args[4] = df:page_current()
			end
		end
		
		return lua_inv.default_formspec_element_to_string(self)
	end)
end

function lua_inv.dynamic_formspec()
	local index = {
		elems = setmetatable({}, {
			__newindex = function(self, key, val)
				error("Error: Attempt to directly set a value in a dynamic formspec's list of elements. Please call one of the provided functions instead.")
			end,

			__metatable = false,
		}),
		
		pageTitles = setmetatable({}, {
			__newindex = function(self, key, val)
				error("Error: Attempt to directly set a value in a dynamic formspec's list of page titles. Please call one of the provided functions instead.")
			end,

			__metatable = false,
		}),
		
		get_fs_size = function(self)
			return (rawget(self, "size_w") or 8), (rawget(self, "size_h") or 8)
		end,

		set_tabs_hidden = function(self, bool)
			rawset(self, "tabs_hidden", bool)
		end,
		
		set_fs_size = function(self, w, h)
			rawset(self, "size_w", tonumber(w))
			rawset(self, "size_h", tonumber(h))
		end,

		size = function(self, n)
			n = n or 1
			return #self.elems[n]
		end,

		get = function(self, i, n)
			n = n or 1
			return self.elems[n][i]
		end,

		set = function(self, i, element, n)
			n = n or 1
			if not element then
				return self:del(i, n)
			else
				rawset(self.elems[n], i, element)
			end
		end,

		add = function(self, element, n)
			n = n or 1
			self:set(self:size(n) + 1, element, n)
		end,

		del = function(self, i, n)
			n = n or 1
			for a = i, self:size(n) - 1 do
				rawset(self.elems[n], a, self:get(a + 1, n))
			end

			rawset(self.elems[n], self:size(n), nil)
		end,
		
		page_add = function(self, title)
			local n = #self.elems + 1
			
			rawset(self.elems, n, setmetatable({}, {
				__newindex = function(self, key, val)
					error("Error: Attempt to directly set a value in a dynamic formspec's list of elements. Please call one of the provided functions instead.")
				end,

				__metatable = false,
			}))
			
			rawset(self.pageTitles, n, title)
			
			self:add(page_tabs(self), n)
			
			return n
		end,
		
		page_count = function(self)
			return #self.elems
		end,
		
		page_get = function(self, n)
			return self.elems[n]
		end,
		
		page_title = function(self, n)
			return self.pageTitles[n]
		end,
		
		page_del = function(self, n)
			for i = n, self:page_count() - 1 do
				rawset(self.elems, i, self:page_get(i+1))
				rawset(self.pageTitles, i, self:page_title(i+1))
			end
			
			local i = self:page_count()
			rawset(self.elems, i, nil)
			rawset(self.pageTitles, i, nil)
		end,
		
		page_current = function(self)
			return self.currentPage or 1
		end,
		
		page_switch = function(self, n)
			n = n and ((n - 1) % self:page_count() + 1) or 1
			rawset(self, "currentPage", n)
			
			return n
		end,

		form = function(self, player, formname, fields)
			self.meta:set_string("formname", formname)

			local w, h = self:get_fs_size()
			local formspec = "size["..w..","..h.."]"
			
			if self:page_count() > 1 and not self.tabs_hidden then
				formspec = formspec..self:get(1, self:page_current()):to_string(player, formname, fields)
			end
			
			local p = self:page_current()

			for i = 2, self:size(p) do
				local element = self:get(i, p):to_string(player, formname, fields)

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
	local open = lua_inv.open_formspecs[player:get_player_name()]
	if open then
		return open.meta, open.temp_meta
	end
end

function lua_inv.dynamic_formspec_from_string(str)
	local lines = str:split(']')

	for i = 1, #lines do
		lines[i] = lua_inv.formspec_element_from_string(lines[i])
	end

	local df = lua_inv.dynamic_formspec()
	df:page_add("Main")

	for i = 1, #lines do
		if lines[i].name == "size" then
			df:set_fs_size(lines[i].args[1], lines[i].args[2])
		else
			df:add(lines[i])
		end
	end

	return df
end
