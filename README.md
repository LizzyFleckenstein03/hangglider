Hang Glider Mod for Minetest
----------------------------
This is a fork of the minetest-hangglider mod by Piezo_ (orderofthefourthwall@gmail.com)

Which is located at:
    <https://notabug.org/Piezo_/minetest-hangglider>

**This version is an experimental version that is not intended for general use.**

It includes the following changes by David G (kestral246@gmail.com):

- Give visual indication that hangglider is equiped.
    - Display simple overlay with blurred struts when equiped.
    - Issue: don't know how to disable overlay when using third person view.

- Also unequip hangglider when landing on water.

- Attempt to linearize parabolic flight path.
    - Start gravity stronger, but gradually reduce it as descent velocity increases.
    - Don't use airstopper when equipped from the ground (descent velocity is low).
    - Slightly increase flight speed to 1.25.

- Unequip/equip cycling mid-flight should not fly farther than continuous flight.
    - When equipping mid-air (descent velocity higher), use airstopper but increase descent slope afterwards.
    - Create airbreak flag so all equips mid-flight use faster descent.
    - Reset airbreak flag only when land (canExist goes false).
    - Issue: it wouldn't reset if land in water, use fly, and launch from air, before I added test for water,
        - Not sure if there are other such cases.

- Did another round of parameter tuning.
    - Commented out hud debug display code with prefix "--debug:".

- For Minetest 5.x the glider's set_attach point needs to be offset by 1 node.
    - Provided alternate commented out version of this line that has the correct offset.

- Discovered that sprint mod interferes with this mod's speed settings.
    - It's likely that other mods that affect player_physics will have this same problem.
    - May need to consider adding player_monoid support to this mod.
