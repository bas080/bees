--Bees
------
--Author	Bas080
--Version	2.0
--License	WTFPL

--[[TODO
  smoker 	maybe
  Spreading bee colonies
  x Grafting Tool - to remove queen bees from wild hives
  x Make flowers reproduce when near a hive
  x Add formspec to twild hive when using grafting tool
]]
--VARIABLES
  local sound = {}
  local particles = {}
  local bees = {}
  local formspecs = {}

--FUNCTIONS
  function formspecs.hive_wild(pos, grafting)
    local spos = pos.x .. ',' .. pos.y .. ',' ..pos.z
    local formspec =
      'size[8,9]'..
      'list[nodemeta:'.. spos .. ';combs;1.5,3;5,1;]'..
      'list[current_player;main;0,5;8,4;]'
    if grafting then
      formspec = formspec..'list[nodemeta:'.. spos .. ';queen;3.5,1;1,1;]'
    end
    return formspec
  end

  function formspecs.hive_artificial(pos)
    local spos = pos.x..','..pos.y..','..pos.z
    local formspec =
      'size[8,9]'..
      'list[nodemeta:'..spos..';queen;3.5,1;1,1;]'..
      'list[nodemeta:'..spos..';frames;0,3;8,1;]'..
      'list[current_player;main;0,5;8,4;]'
    return formspec
  end

  function bees.polinate_flower(pos, flower)
    local spawn_pos = { x=pos.x+math.random(-3,3) , y=pos.y+math.random(-3,3) , z=pos.z+math.random(-3,3) }
    local floor_pos = { x=spawn_pos.x , y=spawn_pos.y-1 , z=spawn_pos.z }
    local spawn = minetest.get_node(spawn_pos).name
    local floor = minetest.get_node(floor_pos).name
    if floor == 'default:dirt_with_grass' and spawn == 'air' then
      minetest.set_node(spawn_pos, {name=flower})
    end
  end

--NODES
  minetest.register_node('bees:bees', {
    description = 'Flying Bees',
    drawtype = 'plantlike',
    paramtype = 'light',
    tiles = {
      {
        name='bees_strip.png', 
        animation={type='vertical_frames', aspect_w=16,aspect_h=16, length=2.0}
      }
    },
    damage_per_second = 1,
    walkable = false,
    buildable_to = true,
    pointable = false,
    on_punch = function(pos, node, puncher)
      local health = puncher:get_hp()
      puncher:set_hp(health-2)
    end,
  })

  minetest.register_node('bees:hive_wild', {
    description = 'wild bee hive',
    tile_images = {'bees_hive_wild.png','bees_hive_wild.png','bees_hive_wild.png', 'bees_hive_wild.png', 'bees_hive_wild_bottom.png'}, --Neuromancer's base texture
    drawtype = 'nodebox',
    paramtype = 'light',
    paramtype2 = 'wallmounted',
    drop = {
      max_items = 6,
      items = {
        { items = {'bees:honey_comb'}, rarity = 5}
      }
    },
    groups = {choppy=2,oddly_breakable_by_hand=2,flammable=3,attached_node=1},
    node_box = { --VanessaE's wild hive nodebox contribution
      type = 'fixed',
      fixed = {
        {-0.250000,-0.500000,-0.250000,0.250000,0.375000,0.250000}, --NodeBox 2
        {-0.312500,-0.375000,-0.312500,0.312500,0.250000,0.312500}, --NodeBox 4
        {-0.375000,-0.250000,-0.375000,0.375000,0.125000,0.375000}, --NodeBox 5
        {-0.062500,-0.500000,-0.062500,0.062500,0.500000,0.062500}, --NodeBox 6
      }
    },
    on_timer = function(pos)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      local timer= minetest.get_node_timer(pos)
      local rad  = 10
      local minp = {x=pos.x-rad, y=pos.y-rad, z=pos.z-rad}
      local maxp = {x=pos.x+rad, y=pos.y+rad, z=pos.z+rad}
      local flowers = minetest.find_nodes_in_area(minp, maxp, 'group:flower')
      if #flowers == 0 then 
        inv:set_stack('queen', 1, '')
        meta:set_string('infotext', 'this colony died, not enough flowers in area')
        return 
      end --not any flowers nearby The queen dies!
      if #flowers < 3 then return end --requires 2 or more flowers before can make honey
      local flower = flowers[math.random(#flowers)] 
      bees.polinate_flower(flower, minetest.get_node(flower).name)
      local stacks = inv:get_list('combs')
      for k, v in pairs(stacks) do
        if inv:get_stack('combs', k):is_empty() then --then replace that with a full one and reset pro..
          inv:set_stack('combs',k,'bees:honey_comb')
          timer:start(1000/#flowers)
          return
        end
      end
      --what to do if all combs are filled
    end,
    on_construct = function(pos)
      minetest.get_node(pos).param2 = 0
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      timer:start(100+math.random(100))
      inv:set_size('queen', 1)
      inv:set_size('combs', 5)
      inv:set_stack('queen', 1, 'bees:queen')
      for i=1,math.random(3) do
        inv:set_stack('combs', i, 'bees:honey_comb')
      end
    end,
    on_punch = function(pos, node, puncher)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      if inv:contains_item('queen','bees:queen') then
        local health = puncher:get_hp()
        puncher:set_hp(health-4)
      end
    end,
    on_metadata_inventory_take = function(pos, listname, index, stack, taker)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      local timer= minetest.get_node_timer(pos)
      if listname == 'combs' and inv:contains_item('queen', 'bees:queen') then
        local health = taker:get_hp()
        timer:start(10)
        taker:set_hp(health-2)
      end
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, taker) --restart the colony by adding a queen
      local timer = minetest.get_node_timer(pos)
      if not timer:is_started() then
        timer:start(10)
      end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      if listname == 'queen' and stack:get_name() == 'bees:queen' then
        return 1
      else
        return 0
      end
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
      minetest.show_formspec(
        clicker:get_player_name(),
        'bees:hive_artificial',
        formspecs.hive_wild(pos, (itemstack:get_name() == 'bees:grafting_tool'))
      )
    end,
    can_dig = function(pos,player)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      if inv:is_empty('queen') and inv:is_empty('combs') then
        return true
      else
        return false
      end
    end,
    after_dig_node = function(pos, oldnode, oldmetadata, user)
      local wielded if user:get_wielded_item() ~= nil then wielded = user:get_wielded_item() else return end
      if 'bees:grafting_tool' == wielded:get_name() then 
        local inv = user:get_inventory()
        if inv then
          inv:add_item('main', ItemStack('bees:queen'))
        end
      end
    end
  })

  minetest.register_node('bees:hive_artificial', {
    description = 'Bee Hive',
    tiles = {'default_wood.png','default_wood.png','default_wood.png', 'default_wood.png','default_wood.png','bees_hive_artificial.png'},
    drawtype = 'nodebox',
    paramtype = 'light',
    paramtype2 = 'facedir',
    groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3,wood=1},
    sounds = default.node_sound_wood_defaults(),
    node_box = {
      type = 'fixed',
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
      local timer = minetest.get_node_timer(pos)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      inv:set_size('queen', 1)
      inv:set_size('frames', 8)
      meta:set_string('infotext','requires queen bee to function')
    end,
    on_rightclick = function(pos, node, clicker, itemstack)
      minetest.show_formspec(
        clicker:get_player_name(),
        'bees:hive_artificial',
        formspecs.hive_artificial(pos)
      )
    end,
    on_timer = function(pos,elapsed)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      if inv:contains_item('queen', 'bees:queen') then
        if inv:contains_item('frames', 'bees:frame_empty') then
          timer:start(30)
          local rad  = 10
          local minp = {x=pos.x-rad, y=pos.y-rad, z=pos.z-rad}
          local maxp = {x=pos.x+rad, y=pos.y+rad, z=pos.z+rad}
          local flowers = minetest.find_nodes_in_area(minp, maxp, 'group:flower')
          local progress = meta:get_int('progress')
          progress = progress + #flowers
          meta:set_int('progress', progress)
          if progress > 1000 then
            local flower = flowers[math.random(#flowers)] 
            bees.polinate_flower(flower, minetest.get_node(flower).name)
            local stacks = inv:get_list('frames')
            for k, v in pairs(stacks) do
              if inv:get_stack('frames', k):get_name() == 'bees:frame_empty' then --then replace that with a full one and reset pro..
                meta:set_int('progress', 0)
                inv:set_stack('frames',k,'bees:frame_full')
                return
              end
            end
          else
            meta:set_string('infotext', 'progress: '..progress..'+'..#flowers..'/1000')
          end
        else
          meta:set_string('infotext', 'does not have empty frame(s)')
          timer:stop()
        end
      end
    end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
      if listname == 'queen' then
        local timer = minetest.get_node_timer(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('infotext','requires queen bee to function')
        timer:stop()
      end
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
      if from_list ~= to_list then 
        return 1 
      else
        return 0
      end
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      if listname == 'queen' or listname == 'frames' then
        meta:set_string('queen', stack:get_name())
        meta:set_string('infotext','queen is inserted, now for the empty frames');
        if inv:contains_item('frames', 'bees:frame_empty') then
          timer:start(30)
          meta:set_string('infotext','bees are aclimating');
        end
      end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      if listname == 'queen' then
        if stack:get_name():match('bees:queen*') then
          return 1
        end
      elseif listname == 'frames' then
        if stack:get_name() == ('bees:frame_empty') then
          return 1
        end
      end
      return 0
    end,
  })

--ABMS
  minetest.register_abm({ --spawn abm. This should be changed to a more realistic type of spawning
    nodenames = {'group:leaves'},
    neighbors = {''},
    interval = 1600,
    chance = 20,
    action = function(pos, node, _, _)
      local p = {x=pos.x, y=pos.y-1, z=pos.z}
      if minetest.get_node(p).walkable == false then return end
      if (minetest.find_node_near(p, 5, 'group:flora') ~= nil and minetest.find_node_near(p, 40, 'bees:hive_wild') == nil) then
        minetest.add_node(p, {name='bees:hive_wild'})
      end
    end,
  })

  minetest.register_abm({ --spawning bees around bee hive
    nodenames = {'bees:hive_wild', 'bees:hive_artificial'},
    neighbors = {'group:flowers', 'group:leaves'},
    interval = 30,
    chance = 4,
    action = function(pos, node, _, _)
      local p = {x=pos.x+math.random(-5,5), y=pos.y-math.random(0,3), z=pos.z+math.random(-5,5)}
      if minetest.get_node(p).name == 'air' then
        minetest.add_node(p, {name='bees:bees'})
      end
    end,
  })

  minetest.register_abm({ --remove bees
    nodenames = {'bees:bees'},
    interval = 30,
    chance = 5,
    action = function(pos, node, _, _)
      minetest.remove_node(pos)
    end,
  })

--ITEMS
  minetest.register_craftitem('bees:frame_empty', {
    description = 'empty hive frame',
    inventory_image = 'bees_frame_empty.png',
    stack_max = 20,
  })

  minetest.register_craftitem('bees:frame_full', {
    description = 'filled hive frame',
    inventory_image = 'bees_frame_full.png',
    stack_max = 4,
  })

  minetest.register_craftitem('bees:honey_comb', {
    description = 'Honey Comb',
    inventory_image = 'bees_comb.png',
    on_use = minetest.item_eat(2),
    stack_max = 8,
  })

  minetest.register_craftitem('bees:queen', {
    description = 'Queen Bee',
    inventory_image = 'bees_particle_bee.png',
    stack_max = 1,
  })

--CRAFTS
  minetest.register_craft({
    output = 'bees:hive_artificial',
    recipe = {
      {'group:wood','group:wood','group:wood'},
      {'group:wood','default:stick','group:wood'},
      {'group:wood','default:stick','group:wood'},
    }
  })

  minetest.register_craft({
    output = 'bees:grafting_tool',
    recipe = {
      {'', '', 'default:steel_ingot'},
      {'', 'default:stick', ''},
      {'', '', ''},
    }
  })
  
  minetest.register_craft({
    output = 'bees:frame_empty',
    recipe = {
      {'default:wood',  'default:wood',  'default:wood'},
      {'default:stick', 'default:stick', 'default:stick'},
      {'default:stick', 'default:stick', 'default:stick'},
    }
  })

--TOOLS
  minetest.register_tool('bees:grafting_tool', {
    description = 'Grafting Tool',
    inventory_image = 'bees_grafting_tool.png',
    tool_capabilities = {
      full_punch_interval = 3.0,
      max_drop_level=0,
      groupcaps={
        choppy = {times={[2]=3.00, [3]=2.00}, uses=10, maxlevel=1},
      },
      damage_groups = {fleshy=2},
    },
  })

--ALIASES (enable once old nodes have been changed to the new versions)
  --minetest.register_alias('bees:hive', 'bees:hive_wild')
  --minetest.register_alias('bees:hive_artificial_inhabited', 'bees:hive_artificial')

--COMPATIBILTY --remove after all has been updated
  minetest.register_abm({
    nodenames = {'bees:hive', 'bees:hive_artificial_inhabited'},
    interval = 0,
    chance = 1,
    action = function(pos, node)
      if node.name == 'bees:hive' then
        minetest.set_node(pos, { name = 'bees:hive_wild' })
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()
        inv:set_stack('queen', 1, 'bees:queen')
      end
      if node.name == 'bees:hive_artificial_inhabited' then
        minetest.set_node(pos, { name = 'bees:hive_artificial_inhabited' })
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()
        inv:set_stack('queen', 1, 'bees:queen')
        local timer = minetest.get_node_timer(pos)
        timer:start(60)
      end
    end,
  })

print('[Mod]Bees Loaded!')
