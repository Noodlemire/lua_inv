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

lua_inv.open_formspecs = {}
local cooldown = {}

lua_inv.registered_on_formspec_open = {}
lua_inv.registered_on_formspec_close = {}

function lua_inv.register_on_formspec_open(func)
	table.insert(lua_inv.registered_on_formspec_open, func)
end

function lua_inv.register_on_formspec_close(func)
	table.insert(lua_inv.registered_on_formspec_close, func)
end

function lua_inv.show_formspec(player, formname, dynamic_formspec)
	local pname = player:get_player_name()
	
	for i = 1, #lua_inv.registered_on_formspec_open do
		lua_inv.registered_on_formspec_open[i](player, formname, dynamic_formspec)
	end
	
	lua_inv.open_formspecs[pname] = dynamic_formspec

	minetest.show_formspec(pname, formname, dynamic_formspec:form(player, formname))
end

local old_show_formspec = minetest.show_formspec
minetest.show_formspec = function(playername, formname, formspec)
	if not lua_inv.open_formspecs[playername] then
		minetest.log("warning", "Formspec opened outside of lua_inv API. More implementation work is needed.")
	end

	return old_show_formspec(playername, formname, formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pname = player:get_player_name()

	if cooldown[pname] and cooldown[pname] > 0 then
		fields.quit = false
	end

	if fields.quit and formname ~= "" then
		for i = 1, #lua_inv.registered_on_formspec_close do
			lua_inv.registered_on_formspec_close[i](player, formname, lua_inv.open_formspecs[pname], fields)
		end
		
		lua_inv.open_formspecs[pname] = nil
		return
	end

	cooldown[pname] = 0.25

	if formname == "" then
		lua_inv.show_formspec(player, "lua_inv:inventory", lua_inv.player_inventory[pname].form)
	elseif lua_inv.open_formspecs[pname] then
		minetest.show_formspec(pname, formname, lua_inv.open_formspecs[pname]:form(player, formname, fields))
	end
end)

minetest.register_globalstep(function(dtime)
	for pname, c in pairs(cooldown) do
		if c > 0 then
			cooldown[pname] = c - dtime
		end
	end
end)
