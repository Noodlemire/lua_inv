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

function lua_inv.formspec_element(in_name, in_args, in_to_string)
	return setmetatable({}, {
		__index = {
			name = in_name,
			args = in_args or {},

			to_string = in_to_string or lua_inv.default_formspec_element_to_string,
		},

		__newindex = function(self, key, val)
			error("Error: Attempt to directly set a value in an formspec element object. Please alter only values in the 'args' and 'meta' subtables.")
		end,

		__metatable = false,
	})
end

function lua_inv.default_formspec_element_to_string(self)
	local str = self.name..'['

	for n, arg in ipairs(self.args) do
		if type(arg) ~= "table" then
			str = str..tostring(arg)
		else
			if arg.k then
				str = str..arg.k..':'

				if type(arg.v) ~= "table" then
					str = str..tostring(arg.v)
				else
					for t, subarg in ipairs(arg.v) do
						str = str..subarg

						if t ~= #arg.v then
							str = str..','
						end
					end
				end
			else
				for t, subarg in ipairs(arg) do
					str = str..subarg

					if t ~= #arg then
						str = str..','
					end
				end
			end
		end

		if type(arg) == "table" or n ~= #self.args then
			str = str..';'
		end
	end

	return str..']'
end

function lua_inv.formspec_element_from_string(line)
	if line:sub(line:len()) == ']' then
		line = line:sub(1, line:len() - 1)
	end

	local splits = line:split('[', true, 1)

	local elem = {
		name = splits[1]:trim(),
		args = splits[2]:split(';', true)
	}

	for n, arg in ipairs(elem.args) do
		if arg:find(':') and not arg:find('%[') and elem.name ~= "item_image" and elem.name ~= "item_image_button" then
			local argsplits = arg:split(':')
			local subargsplits = argsplits[2]:split(',')

			if #subargsplits == 1 then
				subargsplits = subargsplits[1]
			end

			elem.args[n] = {k = argsplits[1], v = subargsplits}
		elseif elem.name ~= "label" and elem.name ~= "tooltip" then
			local argsplits = arg:split(',')

			if #argsplits > 1 then
				elem.args[n] = argsplits
			end
		end
	end

	return lua_inv.formspec_element(elem.name, elem.args)
end
