require ("prototypes.fatcontroller_annimation")
function copyPrototype(type, name, newName, change_results)
  if not data.raw[type][name] then error("type "..type.." "..name.." doesn't exist") end
  local p = table.deepcopy(data.raw[type][name])
  p.name = newName
  if p.minable and p.minable.result then
    p.minable.result = newName
  end
  if change_results then
    if p.place_result then
      p.place_result = newName
    end
    if p.result then
      p.result = newName
    end
  end
  return p
end

data:extend({

{
    type = "player",
    name = "fatcontroller",
    icon = "__base__/graphics/icons/player.png",
    flags = {"pushable", "placeable-player", "placeable-off-grid", "not-repairable", "not-on-map"},
    max_health = 100,
    healing_per_tick = 100,
    collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
   collision_mask = {"ghost-layer"},
    --selection_box = {{-0.4, -1.4}, {0.4, 0.2}},
    crafting_categories = {"crafting"},
    mining_categories = {"basic-solid"},
    damage_hit_tint = {r = 1, g = 0, b = 0, a = 0},
    inventory_size = 0,
    build_distance = 0,
    drop_item_distance = 0,
    reach_distance = 0,
    reach_resource_distance = 0,
    ticks_to_keep_gun = 0,
    ticks_to_keep_aiming_direction = 0,
    running_speed = 0,
    distance_per_frame = 0,
    maximum_corner_sliding_distance = 0,
    item_pickup_distance = 0,
    loot_pickup_distance = 0,

    subgroup = "creatures",
    order="z",
    eat =
    {
      {
        filename = "__TheFatController__/sound/empty.ogg",
        volume = 1
      }
    },
    heartbeat =
    {
      {
        filename = "__TheFatController__/sound/empty.ogg"
      }
    },
    animations = fcanimations,
   mining_speed = 0,
   mining_with_hands_particles_animation_positions = {0, 0},
    mining_with_tool_particles_animation_positions = {0},
    running_sound_animation_positions = {0, 0}
  }
 
 })