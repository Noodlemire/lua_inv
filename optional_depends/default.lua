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

lua_inv.default = {}

local function can_dig_container(pos, player)
	local inv = lua_inv.fetch_node_inventory(pos, true)

	return inv and inv:is_empty() and default.can_interact_with_node(player, pos)
end

-----------------------------------------------------
--                   Chests                        --
-----------------------------------------------------

local function chest_formspec(pos)
	local df = lua_inv.dynamic_formspec()
	df:page_add("Main")
	df:set_fs_size(8, 10)

	df:add(lua_inv.dynamic_list({k = "nodemeta", v = {pos.x, pos.y, pos.z}}, "main", 0, 0.3, 8, 4))
	df:add(lua_inv.dynamic_list("current_player", "main", 0, 4.85, 8, 1))
	df:add(lua_inv.dynamic_list("current_player", "main", 0, 6.08, 8, 3, 8))
	df:add(lua_inv.stack_mode_selector(0, 9.1))
	
	return df
end

function lua_inv.default.chest_override(name)
	local def = minetest.registered_items[name]

	local override_def = {}

	override_def._lua_inv_inventory = function(pos)
		local inv = lua_inv.inventory(pos)
		inv:set_size("main", 32)

		return inv
	end

	override_def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		minetest.sound_play(def.sound_open, {gain = 0.3, pos = pos,
				max_hear_distance = 10}, true)
		if not default.chest.chest_lid_obstructed(pos) then
			minetest.swap_node(pos, {
					name = name .. "_open",
					param2 = node.param2 })
		end
		minetest.after(0.2, lua_inv.show_formspec,
				clicker, name, chest_formspec(pos))
		default.chest.open_chests[clicker:get_player_name()] = { pos = pos,
				sound = def.sound_close, swap = name }
	end

	override_def.can_dig = can_dig_container

	minetest.override_item(name, override_def)
	minetest.override_item(name.."_open", override_def)
end

lua_inv.default.chest_override("default:chest")
lua_inv.default.chest_override("default:chest_locked")

-----------------------------------------------------
--                  Furnaces                       --
-----------------------------------------------------

local function furnace_formspec(pos)
	local df = lua_inv.dynamic_formspec()
	df:page_add("main")
	df:set_fs_size(8, 10)
	
	df:add(lua_inv.dynamic_list({k = "nodemeta", v = {pos.x, pos.y, pos.z}}, "src", 2.75, 0.5, 1, 1))
	df:add(lua_inv.dynamic_list({k = "nodemeta", v = {pos.x, pos.y, pos.z}}, "fuel", 2.75, 2.5, 1, 1))
	df:add(lua_inv.dynamic_list({k = "nodemeta", v = {pos.x, pos.y, pos.z}}, "dst", 4.75, 0.96, 2, 2))
	df:add(lua_inv.active_indicator(2.75, 1.5, 1, 1, "default_furnace_fire_bg.png", "default_furnace_fire_fg.png", "fuel_percent"))
	df:add(lua_inv.active_indicator(3.75, 1.5, 1, 1, "gui_furnace_arrow_bg.png", "gui_furnace_arrow_fg.png^[transformR270", "item_percent"))
	df:add(lua_inv.dynamic_list("current_player", "main", 0, 4.85, 8, 1))
	df:add(lua_inv.dynamic_list("current_player", "main", 0, 6.08, 8, 3, 8))
	df:add(lua_inv.stack_mode_selector(0, 9.1))
	
	return df
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

function lua_inv.default.furnace_override(name)
	local def = minetest.registered_items[name]

	local override_def = {}

	override_def._lua_inv_inventory = function(pos)
		local inv = lua_inv.inventory(pos,
			--Allow Change
			function(inv, change)
				if not lua_inv.set_list_take_only(inv, change, "dst") then
					return false
				end

				local fuel = lua_inv.change_involves_list(inv, change, "fuel")
				if fuel then
					if change.key == "name" then
						fuel = ItemStack(change.val)
					elseif fuel:get_name() ~= "" then
						fuel = ItemStack(fuel:get_name())
					end

					if minetest.get_craft_result({method = "fuel", width = 1, items = {lua_inv.itemstack_to_userdata(fuel)}}).time ~= 0 then
						return true
					end

					if not lua_inv.set_list_take_only(inv, change, "fuel") then
						return false
					end
				end

				return true
			end,

			nil,

			--After Change
			function(inv, change)
				minetest.get_node_timer(inv.parent):start(1)
			end
		)

		inv:set_size("src", 1)
		inv:set_size("fuel", 1)
		inv:set_size("dst", 4)

		return inv
	end

	override_def.on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)

		local fuel_time = meta:get_float("fuel_time")
		local src_time = meta:get_float("src_time")
		local fuel_totaltime = meta:get_float("fuel_totaltime")

		local inv = lua_inv.fetch_node_inventory(pos)
		local srclist, fuellist
		local dst_full = false

		local timer_elapsed = meta:get_int("timer_elapsed")
		meta:set_int("timer_elapsed", timer_elapsed + 1)

		local cookable, cooked
		local fuel

		local update = true
		while elapsed > 0 and update do
			update = false

			srclist = {lua_inv.itemstack_to_userdata(inv:get_stack("src", 1))}
			fuellist = {lua_inv.itemstack_to_userdata(inv:get_stack("fuel", 1))}

			--
			-- Cooking
			--

			-- Check if we have cookable content
			local aftercooked
			cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
			cookable = cooked.time ~= 0

			cooked.item = lua_inv.itemstack_from_userdata(cooked.item)
			aftercooked.items[1] = lua_inv.itemstack_from_userdata(aftercooked.items[1])

			local el = math.min(elapsed, fuel_totaltime - fuel_time)
			if cookable then -- fuel lasts long enough, adjust el to cooking duration
				el = math.min(el, cooked.time - src_time)
			end

			-- Check if we have enough fuel to burn
			if fuel_time < fuel_totaltime then
				-- The furnace is currently active and has enough fuel
				fuel_time = fuel_time + el
				-- If there is a cookable item then check if it is ready yet
				if cookable then
					src_time = src_time + el
					if src_time >= cooked.time then
						-- Place result in dst list if possible
						if inv:room_for_item("dst", cooked.item) then
							for i = 1, inv:get_size("dst") do
								local stack = inv:get_stack("dst", i)
								if cooked.item:item_fits(stack) then
									rawset(stack, "name", cooked.item:get_name())
									rawset(stack, "count", stack:get_count() + cooked.item:get_count())
									rawset(stack, "wear", stack:get_wear() + cooked.item:get_wear())

									break
								end
							end

							inv:set_stack("src", 1, aftercooked.items[1])
							src_time = src_time - cooked.time
							update = true
						else
							dst_full = true
						end
						-- Play cooling sound
						minetest.sound_play("default_cool_lava",
							{pos = pos, max_hear_distance = 16, gain = 0.1}, true)
					else
						-- Item could not be cooked: probably missing fuel
						update = true
					end
				end
			else
				-- Furnace ran out of fuel
				if cookable then
					-- We need to get new fuel
					local afterfuel
					fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})

					fuel.item = lua_inv.itemstack_from_userdata(fuel.item)
					afterfuel.items[1] = lua_inv.itemstack_from_userdata(afterfuel.items[1])

					if fuel.time == 0 then
						-- No valid fuel in fuel list
						fuel_totaltime = 0
						src_time = 0
					else
						-- Take fuel from fuel list
						inv:set_stack("fuel", 1, afterfuel.items[1])
						-- Put replacements in dst list or drop them on the furnace.
						local replacements = fuel.replacements
						if replacements[1] then
							local leftover = replacements[1]

							for i = 1, inv:get_size("dst") do
								local stack = inv:get_stack("dst", i)
								if replacements[1]:item_fits(stack) then
									rawset(stack, "name", cooked.item:get_name())
									rawset(stack, "count", stack:get_count() + cooked.item:get_count())
									rawset(stack, "count", stack:get_wear() + cooked.item:get_wear())

									replacements[1]:set_count(0)
									break
								end
							end

							if not leftover:is_empty() then
								local above = vector.new(pos.x, pos.y + 1, pos.z)
								local drop_pos = minetest.find_node_near(above, 1, {"air"}) or above
								minetest.item_drop(replacements[1], nil, drop_pos)
							end
						end
						update = true
						fuel_totaltime = fuel.time + (fuel_totaltime - fuel_time)
					end
				else
					-- We don't need to get new fuel since there is no cookable item
					fuel_totaltime = 0
					src_time = 0
				end
				fuel_time = 0
			end

			elapsed = elapsed - el
		end

		if fuel and fuel_totaltime > fuel.time then
			fuel_totaltime = fuel.time
		end
		if srclist and srclist[1]:is_empty() then
			src_time = 0
		end

		--
		-- Update formspec, infotext and node
		--
		local item_state
		local fuel_percent = 0
		local item_percent = 0

		if cookable then
			item_percent = math.floor(src_time / cooked.time * 100)
		end

		local active = false
		local result = false

		if fuel_totaltime ~= 0 then
			active = true
			fuel_percent = 100 - math.floor(fuel_time / fuel_totaltime * 100)
			swap_node(pos, name.."_active")
			-- make sure timer restarts automatically
			result = true

			-- Play sound every 5 seconds while the furnace is active
			if timer_elapsed == 0 or (timer_elapsed+1) % 5 == 0 then
				minetest.sound_play("default_furnace_active",
					{pos = pos, max_hear_distance = 16, gain = 0.5}, true)
			end
		else
			item_percent = 0
			formspec = default.get_furnace_inactive_formspec()
			swap_node(pos, name)
			-- stop timer on the inactive furnace
			minetest.get_node_timer(pos):stop()
			meta:set_int("timer_elapsed", 0)
		end

		--
		-- Set meta values
		--
		meta:set_float("fuel_totaltime", fuel_totaltime)
		meta:set_float("fuel_time", fuel_time)
		meta:set_float("src_time", src_time)
		meta:set_float("fuel_percent", fuel_percent)
		meta:set_float("item_percent", item_percent)

		for playername, formspec in pairs(lua_inv.open_formspecs) do
			if formspec.meta:get_string("formname") == name then
				formspec.meta:set_float("fuel_percent", fuel_percent)
				formspec.meta:set_float("item_percent", item_percent)

				lua_inv.show_formspec(minetest.get_player_by_name(playername), name, formspec)
			end
		end

		return result
	end

	override_def.on_construct = function() end

	override_def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local formspec = furnace_formspec(pos)
		formspec.meta:set_float("fuel_percent", meta:get_float("fuel_percent"))
		formspec.meta:set_float("item_percent", meta:get_float("item_percent"))

		lua_inv.show_formspec(clicker, name, formspec)
	end

	override_def.can_dig = can_dig_container

	minetest.override_item(name, override_def)
	minetest.override_item(name.."_active", override_def)
end

lua_inv.default.furnace_override("default:furnace")

-----------------------------------------------------
--                   Shelves                      --
-----------------------------------------------------

local function shelf_formspec(pos, listname, slot_bg)
	local df = lua_inv.dynamic_formspec()
	df:page_add("Main")

	df:add(lua_inv.dynamic_list({k = "nodemeta", v = {pos.x, pos.y, pos.z}}, listname, 0, 0.3, 8, 2, nil, slot_bg))
	df:add(lua_inv.dynamic_list("current_player", "main", 0, 2.85, 8, 1))
	df:add(lua_inv.dynamic_list("current_player", "main", 0, 4.08, 8, 3, 8))
	df:add(lua_inv.stack_mode_selector(0, 7.1))
	
	return df
end

function lua_inv.default.shelf_override(name, groupname, listname, slot_bg)
	local def = minetest.registered_items[name]

	local override_def = {}

	override_def._lua_inv_inventory = function(pos)
		local inv = lua_inv.inventory(pos,
			--Allow Change
			function(inv, change)
				local stack = lua_inv.change_involves_list(inv, change, listname)
				if not stack then return true end
				
				local stackname = stack:get_name()
				
				if change.key == "name" then
					stackname = change.val
				elseif stack:is_empty() then
					return true
				end
				
				return minetest.get_item_group(stackname, groupname) ~= 0
			end
		)
		
		inv:set_size(listname, 16)
		
		return inv
	end
	
	override_def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		lua_inv.show_formspec(clicker, name, shelf_formspec(pos, listname, slot_bg))
	end

	override_def.can_dig = can_dig_container
	
	minetest.override_item(name, override_def)
end

lua_inv.default.shelf_override("default:bookshelf", "book", "books", "default_bookshelf_slot.png")

if minetest.get_modpath("vessels") then
	lua_inv.default.shelf_override("vessels:shelf", "vessel", "vessels", "vessels_shelf_slot.png")
end
