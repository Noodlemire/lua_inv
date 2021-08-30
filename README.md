-------------------------------------------------------------------------------------------------------------
Complete and Total Lua-Only Inventory Rewrite
[lua_inv]
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
About
-------------------------------------------------------------------------------------------------------------
**!Warning!**: This is an abonination.

**!Warning!**: There is no way to automatically make this mod compatible with others. Support for any other mod that uses inventories or formspecs will probably need to be manually created in the near (or far) future.

**!Warning!**: This mod will replace and delete players' previous inventories, if they existed. It will attempt to import old items to the new system, but there is currently no way to put them back. USE THIS MOD IN A FRESH WORLD unless you either never remove lua_inv, or you're fine with an inventory wipe.

This mod attempts to create a total replacement for Minetest's entire inventory system. This does *not* just provide polishing or workarounds for the various shortcomings of Minetest's inventories. Instead, absolutely everything is custom-made in Lua. MetaData, ItemStacks, and Inventory objects are all created from scratch in this system, granting it total control over the very nature of these objects.

So why was this made in the first place? As mentioned previously, Minetest's regular inventory system has a variety of shortcomings and missing features. Some have somewhat decent workarounds, but others are virtually impossible, and there are times where a workaround just doesn't provide a proper solution. Below this is a list of some, but not all of the particular shortcomings that inspired lua_inv.
* Items that can change their appearances. The common workaround is to create an entire registration for every single possible visual state that the item can have. This can work on a small or medium scale, but it has the potential to either be excessive, or unworkable if you don't know every possible visual at the time of registration.
* Items that have animated sprites. There is normally no true workaround for this, except to give up and just use a still image.
* Stackable items that can have durability applied to them. In normal Minetest, count and wear are mutually exclusive, and there is no true, bug-free way to implement having them both be together.
* Inventory callbacks that apply to Lua functions. By default, move/put/take callbacks are completely bypassed by Lua code, or by just *picking up an item off of the ground*, unless the programmer of each inventory-related mod goes out of their way to try to respect these. In some cases, they might as well not exist.

By creating lua_inventory, the above features and more are finally possible. Every object that this new system uses is built from the ground-up to be more configurable and feature-rich than anything in Minetest's inventories.
* You can use ItemStack's MetaData to set the "inventory_image" field to any image file, allowing item images to be changed at any time.
* You can set _lua_inv_animation() in any item's definition, and this will allow it to be animated in inventory, hotbar, wielded_item, and item entity forms. There are even Meta fields to change the item's animation parameters at any time.
* Setting count and wear on an object is supported natively. Just give tool_capabilities to a craftitem's definition, and it will be provided automatically.
* *Everything* has a callback you can set to allow changes, or make things happen upon changes, even including the MetaData. These callbacks apply to all Lua functions as one would expect. Methods to bypass them *do* exist and aren't even that complicated. However, programmers now have to go out of their way to bypass the callbacks- not the other way around.
* Full circular parent/child relationships. Wherever applicable, each object is given a read-only "parent" field, which can be used to check its owner. From just a MetaData object, you can fetch the ItemStack that owns it, the Inventory that owns the ItemStack and even the player/node that owns the Inventory.
* In a similar manner, all ItemStacks are passed via reference, rather than copy, unless specified otherwise. You don't need to "commit" changes to an ItemStack, the same way you need to in regular Minetest.
* The on_use function on an item's definition will no longer replace the usual digging behavior.
* There is a "Dynamic Formspec" system in place. You can create essentially custom formspec elements by using pre-existing ones as building blocks. You can easily change the very layout of a formspec as needed, and create semi-persistent data with the help of a single MetaData object owned by the formspec as a whole, usable by every individual FormspecElement.
* And more! Check the provided api.txt document for details about how everything is used.

-------------------------------------------------------------------------------------------------------------
Dependencies and Support
-------------------------------------------------------------------------------------------------------------
Required mods:
* controls: https://github.com/mt-mods/controls (This fork is necessary for updated support)
* entitycontrol: https://content.minetest.net/packages/Noodlemire/entitycontrol/
* smart_vector_table: https://content.minetest.net/packages/Noodlemire/smart_vector_table/

Supported mods:
* default: Chests work with this system properly.

-------------------------------------------------------------------------------------------------------------
License
-------------------------------------------------------------------------------------------------------------
The LGPL v2.1 License is used with this mod. See https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html or LICENSE.txt for more details.

-------------------------------------------------------------------------------------------------------------
Installation
-------------------------------------------------------------------------------------------------------------
Download, unzip, and place within the usual minetest/current/mods folder, and it will behave in relation to the Minetest engine like any other mod.
