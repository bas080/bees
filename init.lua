--Bees mod by bas080
local sound = {}

--nodes
minetest.register_node("bees:bees", {
  description = "Wild Bees",
  drawtype = "airlike",
  paramtype = "light",
  damage_per_second = 1,
  walkable = false,
  buildable_to = true,
  on_punch = function(pos, node, puncher)
    local health = puncher:get_hp()
    puncher:set_hp(health-2)
  end,
})

minetest.register_node("bees:hive", {
  description = "Wild Bee Hive",
  tile_images = {"bees_hive_wild_bottom.png","bees_hive_wild_bottom.png", "bees_hive_wild.png","bees_hive_wild_s.png", "bees_hive_wild_s.png", "bees_hive_wild_s.png"},
  drawtype = "nodebox",
  paramtype = "light",
  paramtype2 = 'wallmounted',
  drop = {
    max_items = 6,
    items = {
      { items = {'bees:honey_comb'} },
      { items = {'bees:honey_comb'}, rarity = 2},
      { items = {'bees:honey_comb'}, rarity = 5},
      { items = {'bees:queen'}, rarity = 10 }
    }
  },
  groups = {choppy=2,oddly_breakable_by_hand=2,flammable=3,attached_node=1},
  node_box = { --VanessaE's wild hive nodebox contribution
    type = "fixed",
    fixed = {
      {-0.250000,-0.500000,-0.250000,0.250000,0.375000,0.250000}, --NodeBox 2
      {-0.312500,-0.375000,-0.312500,0.312500,0.250000,0.312500}, --NodeBox 4
      {-0.375000,-0.250000,-0.375000,0.375000,0.125000,0.375000}, --NodeBox 5
      {-0.062500,-0.500000,-0.062500,0.062500,0.500000,0.062500}, --NodeBox 6
    }
  },
  on_destruct = function(pos)
    if sound["x"..pos.x.."y"..pos.y.."z"..pos.z] ~= nil then
      minetest.sound_stop(sound["x"..pos.x.."y"..pos.y.."z"..pos.z])
      sound["x"..pos.x.."y"..pos.y.."z"..pos.z] = nil
    end
  end,
  on_construct = function(pos)
    minetest.get_node(pos).param2 = 0
    local tmr = minetest.env:get_node_timer(pos)
    local meta = minetest.env:get_meta(pos)
    meta:set_string('angry','true')
    tmr:start(300)
  end,
  on_punch = function(pos, node, puncher)
    local health = puncher:get_hp()
    puncher:set_hp(health-2)
  end,
})

minetest.register_node("bees:hive_artificial", {
  description = "Bee Hive",
  tiles = {"default_wood.png","default_wood.png","default_wood.png", "default_wood.png","default_wood.png","bees_hive_artificial.png"},
  drawtype = "nodebox",
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3,wood=1},
  sounds = default.node_sound_wood_defaults(),
  node_box = {
    type = "fixed",
    fixed = {
      {-4/8, 2/8, -4/8, 4/8, 3/8, 4/8},
      {-3/8, -4/8, -2/8, 3/8, 2/8, 3/8},
      {-3/8, 0/8, -3/8, 3/8, 2/8, -2/8},
      {-3/8, -4/8, -3/8, 3/8, -1/8, -2/8},
      {-3/8, -1/8, -3/8, -1/8, 0/8, -2/8},
      {1/8, -1/8, -3/8, 3/8, 0/8, -2/8},
    }
  },
  on_construct = function(pos)
    local tmr = minetest.env:get_node_timer(pos)
    tmr:start(10)
    local meta = minetest.env:get_meta(pos)
    meta:set_string('inhabited','false')
    meta:set_string('infotext','Requires the Queen bee');
  end,
})

minetest.register_node("bees:hive_artificial_inhabited", {
  description = "Bee Hive",
  tiles = {"default_wood.png","default_wood.png","default_wood.png", "default_wood.png","default_wood.png","bees_hive_artificial.png"},
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {
      {-4/8, 2/8, -4/8, 4/8, 3/8, 4/8},
      {-3/8, -4/8, -2/8, 3/8, 2/8, 3/8},
      {-3/8, 0/8, -3/8, 3/8, 2/8, -2/8},
      {-3/8, -4/8, -3/8, 3/8, -1/8, -2/8},
      {-3/8, -1/8, -3/8, -1/8, 0/8, -2/8},
      {1/8, -1/8, -3/8, 3/8, 0/8, -2/8},
    }
  },
  drop = "bees:hive_artificial 1",
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3,wood=1},
  sounds = default.node_sound_wood_defaults(),
  --on_punch = candles.collect,
  on_timer = function(pos,elapsed)
    local rad  = 10
    local minp = {x=pos.x-rad, y=pos.y-rad, z=pos.z-rad}
    local maxp = {x=pos.x+rad, y=pos.y+rad, z=pos.z+rad}
    local flower_in_area = minetest.env:find_nodes_in_area(minp, maxp, "group:flower")
    local flower_number = 0
    for i in ipairs(flower_in_area) do
      flower_number = flower_number + 1
    end
    local meta = minetest.env:get_meta(pos)
    local honey = meta:get_int("honey")
    honey = honey + flower_number/10
    
    if honey < 100 then
      meta:set_string('infotext',honey.."%");
      meta:set_int("honey", honey)
      local tmr = minetest.env:get_node_timer(pos)
      tmr:start(60)
    else
      meta:set_string('infotext',"100% - Time to harvest");
      meta:set_int("honey", 100)
    end
  end,
  on_construct = function(pos)
    local tmr = minetest.env:get_node_timer(pos)
    tmr:start(60)
    local meta = minetest.env:get_meta(pos)
    meta:set_string('inhabited','false')
    meta:set_int("honey", 0)
    meta:set_string('infotext','0%');
  end,
  on_punch = function(pos, node, puncher)
    local health = puncher:get_hp()
    puncher:set_hp(health-2)
  end,
  on_rightclick = function(pos, node, puncher)
    local meta = minetest.env:get_meta(pos)
    local honey = meta:get_int("honey")
    if honey == 100 then
      for i=math.random(1,3), 0, -1  do
        local p = {x=pos.x+math.random()-0.5,y=pos.y+1,z=pos.z+math.random()-0.5}
        minetest.add_item(p, "bees:honey_comb")
      end
      meta:set_int("honey", 0)
      meta:set_string('infotext',"0%");
      local tmr = minetest.env:get_node_timer(pos)
      tmr:start(60)
    end
  end,
})

--abms
minetest.register_abm({ --for particles and sounds
  nodenames = {"bees:hive", "bees:bees", "bees:hive_artificial_inhabited"},
  interval = 1,
  chance = 6,
  action = function(pos, node, _, _)
    if math.random()<0.5 then
      local img = "bees_particle_bee.png"
    else
      local img = "bees_particle_bee_r.png"
    end
    sound["x"..pos.x.."y"..pos.y.."z"..pos.z] = minetest.sound_play({name="bees"},{pos=pos, max_hear_distance=8, gain=0.6})
    local p = {x=pos.x, y=pos.y+math.random()-0.5, z=pos.z}
    minetest.add_particle(p, {x=(math.random()-0.5)*5,y=(math.random()-0.5)*5,z=(math.random()-0.5)*5}, {x=math.random()-0.5,y=math.random()-0.5,z=math.random()-0.5}, math.random(2,5), math.random(3), true, "bees_particle_bee.png")
  end,
})

minetest.register_abm({ --spawn abm
  nodenames = {"group:leafdecay"},
  interval = 1800,
  chance = 500,
  action = function(pos, node, _, _)
    local p = {x=pos.x, y=pos.y-1, z=pos.z}
    if minetest.get_node(p).walkable == false then return end
    if (minetest.find_node_near(p, 5, "group:flora") ~= nil and minetest.find_node_near(p, 20, "bees:hive") == nil) then
      minetest.add_node(p, {name="bees:hive"})
    end
  end,
})

minetest.register_abm({ --spawning bees around bee hive
  nodenames = {"bees:hive"},
  interval = 10,
  chance = 2,
  action = function(pos, node, _, _)
    local p = {x=pos.x+math.random(-5,5), y=pos.y-math.random(0,3), z=pos.z+math.random(-5,5)}
    if minetest.get_node(p).name == "air" then
      minetest.add_node(p, {name="bees:bees"})
    end
  end,
})

minetest.register_abm({ --remove bees
  nodenames = {"bees:bees"},
  interval = 60,
  chance = 4,
  action = function(pos, node, _, _)
    minetest.remove_node(pos)
  end,
})

--items
minetest.register_craftitem("bees:honey_comb", {
  description = "Honey Comb",
  inventory_image = "bees_comb.png",
  on_use = minetest.item_eat(3),
})

minetest.register_craftitem("bees:honey_bottle", {
  description = "Honey Bottle",
  inventory_image = "bees_honey_bottle.png",
  on_use = minetest.item_eat(6),
})

minetest.register_craftitem("bees:queen", {
  description = "Queen Bee",
  inventory_image = "bees_particle_bee.png",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.under == nil then return end
    local node = minetest.get_node(pointed_thing.under)
    local name = minetest.get_node(pointed_thing.under).name
    
    if name == "bees:hive_artificial" then
      local facing = node.param2
      minetest.set_node(pointed_thing.under, {name = "bees:hive_artificial_inhabited", param2=facing})
      itemstack:take_item()
      return itemstack
    end
  end,
})

--crafts
minetest.register_craft({
  output = 'bees:honey_bottle',
  recipe = {
    {'bees:honey_comb'},
    {'vessels:glass_bottle'},
  }
})

minetest.register_craft({
	output = 'bees:hive_artificial',
	recipe = {
		{'group:wood','group:wood','group:wood'},
		{'group:wood','default:stick','group:wood'},
		{'group:wood','default:stick','group:wood'},
	}
})
