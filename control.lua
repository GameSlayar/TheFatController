if not defines then
  require "defines"
  defines.train_state = defines.trainstate
end

require "util"
require "TickTable"
require "Alerts"
require "TrainList"
require "GUI"

MOD_NAME = "TheFatController"

update_rate = 60
update_rate_manual = 90

-- myevent = game.generateeventname()
-- the name and tick are filled for the event automatically
-- this event is raised with extra parameter foo with value "bar"
--game.raiseevent(myevent, {foo="bar"})
events = {}
events["on_player_opened"] = script.generate_event_name()
events["on_player_closed"] = script.generate_event_name()

local on_player_switched_from_train = nil

function getOrLoadSwitchedEvent()
  if on_player_switched_from_train == nil then
    on_player_switched_from_train = script.generate_event_name()
  end
  return on_player_switched_from_train
end

function generateEvents()
  getOrLoadSwitchedEvent()
end

defaults = {stationDuration=10,signalDuration=2}

defaultGuiSettings = {
  alarm={noPath=true,noFuel=true,timeAtSignal=true,timeToStation=true},
  displayCount=10,
  fatControllerButtons = {},
  fatControllerGui = {},
  page = 1,
  pageCount = 5,
  filter_page = 1,
  filter_pageCount = 1,
  filtered_trains = false,
  filter_alarms = false,
  automatedCount = 0,
  stopButton_state = false,
  displayed_trains = {},
  renameTrains = false,
  show_names = false,
  renameTrain = {},
}

-- character_blacklist = { ["orbital-uplink"] = true, ["yarm-remote-viewer"] = true, }

function debugDump(var, force)
  if false or force then
    local msg
    if type(var) == "string" then
      msg = var
    else
      msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
    end
    for _,player in pairs(game.players) do
      player.print(msg)
    end
  end
end

function pauseError(err)
  if game then
    debugDump("Error in FatController " .. serpent.line(global.version, {comment=false}), true)
    debugDump(err,true)
  else
    log("Error in FatController " .. serpent.line(global.version, {comment=false}))
    log(serpent.line(global.version, {comment=false}) .. " " .. err)
  end
end

local function init_global()
  global = global or {}
  global.gui = global.gui or {}
  global.trainsByForce = global.trainsByForce or {}
  global.character = global.character or {}
  global.unlocked = global.unlocked or false
  global.unlockedByForce = global.unlockedByForce or {}
  global.updateEntities = global.updateEntities or false
  global.updateTrains = global.updateTrains or {}
  global.updateManual = global.updateManual or {}
  global.updateAlarms = global.updateAlarms or {}
  global.automatedCount = global.automatedCount or {}
  global.PAGE_SIZE = global.PAGE_SIZE or 60
  global.station_count = global.station_count or {}
  global.player_opened = global.player_opened or {}
  global.opened_name = global.opened_name or {}
  global.items = global.items or {}
  global.force_settings = global.force_settings or {}
end

local function init_player(player)
  global.gui[player.index] = global.gui[player.index] or util.table.deepcopy(defaultGuiSettings)
  if global.unlockedByForce[player.force.name] then
    GUI.init_gui(player)
  end
end

local function init_players()
  for _,player in pairs(game.players) do
    init_player(player)
  end
end

local function init_force(force)
  init_global()
  global.trainsByForce[force.name] = global.trainsByForce[force.name] or {}
  global.station_count[force.name] = global.station_count[force.name] or {}
  global.automatedCount[force.name] = global.automatedCount[force.name] or 0
  global.force_settings[force.name] = global.force_settings[force.name] or {signalDuration=defaults.signalDuration*3600,stationDuration=defaults.stationDuration*3600}
  if force.technologies["rail-signals"].researched then
    global.unlockedByForce[force.name] = true
    global.unlocked = true
    register_events()
    for _,p in pairs(force.players) do
      init_player(p)
    end
  end
end

local function init_forces()
  for _, force in pairs(game.forces) do
    init_force(force)
  end
end

local function on_init()
  generateEvents()
  init_global()
  init_forces()
  init_players()
end

local function on_load()
  generateEvents()
  if global.unlocked then
    register_events()
  end
end

-- run once
local function on_configuration_changed(data)
  if not data or not data.mod_changes then
    return
  end
  local newVersion
  local oldVersion
  if data.mod_changes[MOD_NAME] then
    newVersion = data.mod_changes[MOD_NAME].new_version
    oldVersion = data.mod_changes[MOD_NAME].old_version
    if oldVersion then
      debugDump("Updating TheFatController from "..oldVersion.." to "..newVersion,true)
      if oldVersion < "0.4.0" then
        debugDump("Resetting FatController settings",true)
        local tmp = {}
        for i, _ in pairs(game.players) do
          tmp[i] = {}
          tmp[i].fatControllerGui = global.guiSettings[i].fatControllerGui
          tmp[i].fatControllerButtons = global.guiSettings[i].fatControllerButtons
        end
        local tmpCharacter = global.character or {}
        global = {}
        global.character = tmpCharacter
        on_init()
        for i, _ in pairs(game.players) do
          global.gui[i].fatControllerGui = tmp[i].fatControllerGui
          global.gui[i].fatControllerButtons = tmp[i].fatControllerButtons
        end
      end
      on_init()
      if oldVersion > "0.4.0" then
        if oldVersion < "0.4.12" then
          init_forces()
          for _, force in pairs(game.forces) do
            TrainList.remove_invalid(force,true)
            for _, ti in pairs(global.trainsByForce[force.name]) do
              ti.automated = ti.train.state ~= defines.train_state.manual_control and ti.train.state ~= defines.train_state.stop_for_auto_control
              if ti.automated then
                global.automatedCount[force.name] = global.automatedCount[force.name] + 1
              end
            end
          end
          for i, _ in pairs(game.players) do
            global.gui[i].filterModeOr = false
            global.gui[i].automatedCount = 0
            global.gui[i].filteredIndex = {}
            if global.gui[i].filtered_trains then
              for _, ti in pairs(global.gui[i].filtered_trains) do
                global.gui[i].filteredIndex[ti.mainIndex] = true
                if ti.automated then
                  global.gui[i].automatedCount = global.gui[i].automatedCount + 1
                end
              end
            end
          end
        end
        if oldVersion < "0.4.14" then
          for _, guiSetting in pairs(global.gui) do
            if guiSetting.renameTrains == nil then
              guiSetting.renameTrains = false
              guiSetting.renameTrain = {}
            end
          end
        end
        if oldVersion < "0.4.15" then
          for _, guiSetting in pairs(global.gui) do
            if guiSetting.show_names == nil then
              guiSetting.show_names = false
            end
          end
          for _, trains in pairs(global.trainsByForce) do
            for _, ti in pairs(trains) do
              if #ti.train.locomotives.front_movers > 0 then
                ti.name = ti.train.locomotives.front_movers[1].backer_name
              else
                ti.name = ti.train.locomotives.back_movers[1].backer_name
              end
              if ti.name:len() > 20 then
                ti.name = ti.name:sub(1, 20) .. "..."
              end
            end
          end
        end

        if oldVersion < "0.4.17" then
          findTrains(true)
          for _, force in pairs(game.forces) do
            TrainList.remove_invalid(force,true)
            for _, ti in pairs(global.trainsByForce[force.name]) do
              ti.automated = (ti.train.state ~= defines.train_state.manual_control and ti.train.state ~= defines.train_state.stop_for_auto_control)
              if ti.automated then
                global.automatedCount[force.name] = global.automatedCount[force.name] + 1
              end
            end
          end
          for i, _ in pairs(game.players) do
            global.gui[i].automatedCount = 0
            if global.gui[i].filtered_trains then
              for _, ti in pairs(global.gui[i].filtered_trains) do
                global.gui[i].filteredIndex[ti.mainIndex] = true
                if ti.automated then
                  global.gui[i].automatedCount = global.gui[i].automatedCount + 1
                end
              end
            end
          end
        end

        if oldVersion < "0.4.19" then
          for _, gui in pairs(global.gui) do
            GUI.refresh_gui(gui)
          end
        end
      end
    end
    if not oldVersion or oldVersion < "0.4.0" then
      findTrains(true)
    end
    global.version = newVersion
  end
  --reset item cache if a mod has changed
  global.items = {}
  --check for other mods
end

local function on_player_created(event)
  init_player(game.players[event.player_index])
end

local function on_force_created(event)
  init_force(event.force)
end

function on_research_finished(event)
  if event.research.name == "rail-signals" then
    global.unlockedByForce[event.research.force.name] = true
    global.unlocked = true
    register_events() ;
    for _, p in pairs(event.research.force.players) do
      init_player(p)
    end
  end
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_force_created, on_force_created)
--script.on_event(defines.events.on_forces_merging, on_forces_merging)

script.on_event(defines.events.on_research_finished, function(event)
  local _, err = pcall(on_research_finished, event)
  if err then pauseError(err,true) end
end)

function register_events()
  script.on_event(defines.events.on_gui_click, GUI.onguiclick)
end

function addInventoryContents(invA, invB)
  local res = {}
  for item, c in pairs(invA) do
    invB[item] = invB[item] or 0
    res[item] = c + invB[item]
    invB[item] = nil
    if res[item] == 0 then res[item] = nil end
  end
  for item,c in pairs(invB) do
    res[item] = c
    if res[item] == 0 then res[item] = nil end
  end
  return res
end

function getHighestInventoryStack(trainInfo)
  if trainInfo and trainInfo.train and trainInfo.train.valid and trainInfo.train.cargo_wagons then
    local itemsCount = 0
    local largestItem = {}
    local items = {}
    for i, carriage in pairs(trainInfo.train.cargo_wagons) do
      if carriage.name == "rail-tanker" then
        local _, liquid = pcall(remote.call, "railtanker","getLiquidByWagon",carriage)
        if liquid and liquid.amount then
          local name = liquid.type
          if name then
            local count = math.floor(liquid.amount)
            if not items[name] then
              items[name] = 0
            end
            items[name] = items[name] + count
          end
        end
      else
        if trainInfo.proxy_chests and trainInfo.proxy_chests[i] then
          --wagon is used by logistics railway
          local contents = trainInfo.proxy_chests[i].get_inventory(defines.inventory.chest).get_contents()
          items = addInventoryContents(items, contents)
        else
          items = addInventoryContents(items,carriage.get_inventory(1).get_contents())
        end
      end
    end
    for name, count in pairs(items) do
      if largestItem.count == nil or largestItem.count < count then
        largestItem.name = name
        largestItem.count = items[name]
      end
      itemsCount = itemsCount + 1
    end
    return largestItem, itemsCount
  end
end

function getHighestInventoryCount(trainInfo)
  local inventory = ""
  local largestItem, itemsCount = getHighestInventoryStack(trainInfo)
  if largestItem.name ~= nil then
    local isItem = game.item_prototypes[largestItem.name] or game.fluid_prototypes[largestItem.name]
    local displayName = isItem and isItem.localised_name or largestItem.name
    local suffix = itemsCount > 1 and "..." or ""
    inventory = {"", displayName,": ",largestItem.count, suffix}
  end
  return inventory
end

function on_player_driving_changed_state(event)
  local _, err = pcall(function()
    local player = game.players[event.player_index]
    if player.vehicle and (player.vehicle.type == "locomotive" or player.vehicle.type == "cargo-wagon") then
      local ti = TrainList.get_traininfo(player.force, player.vehicle.train)
      if ti and ti.train.state == defines.train_state.manual_control then
        TrainList.add_manual(ti, player)
        global.gui[player.index].vehicle = ti.train
      end
    end
    if player.vehicle == nil then
      if global.gui[player.index].followEntity then
        local guiSettings = global.gui[player.index]
        if player.connected then
          swapPlayer(game.players[player.index], global.character[player.index])
          global.character[player.index] = nil
          stop_following(guiSettings, player)
          if player.vehicle and player.vehicle.name == "farl" then
            game.raise_event(defines.events.on_player_driving_changed_state, {tick=game.tick, player_index = player.index, name=defines.events.on_player_driving_changed_state})
          end
        else
          if not global.to_swap then global.to_swap = {} end
          table.insert(global.to_swap, {index=player.index, character=global.character[player.index]})
        end
      end
      TrainList.remove_invalid(player.force, true)
      TrainList.reset_manual(global.gui[player.index].vehicle)
      global.gui[player.index].vehicle = false
    end
  end)
  if err then pauseError(err) end
end
script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)

function on_tick(event)
  local _, err = pcall(function()
    local tick = event.tick
    if global.updateEntities then
      for _, ent in pairs(global.updateEntities) do
        --debugDump("updateEnt"..i,true)
        if ent == true then
          TrainList.removeAlarms()
        elseif ent.valid then
          TrainList.add_train(ent.train)
        end
      end
      global.updateEntities = false
      --script.on_event(defines.events.on_tick, nil)
    end

    if global.dead_players then
      for i, character in pairs(global.dead_players) do
        if not character.valid then
          debugDump(game.players[i].name.." died while remote controlling",true)
          debugDump("Killing "..game.players[i].name.." softly",true)
          game.players[i].character.die()
          global.gui[i].followEntity = nil
        end
      end
      global.dead_players = nil
    end

    if global.updateManual[tick] then
      for _, ti in pairs(global.updateManual[tick]) do
        if ti and ti.train.valid then
          Alerts.check_noFuel(ti)
          --debugDump("updateManual",true)
          GUI.update_single_traininfo(ti, true)
          if (ti.passenger and (ti.train.state == defines.train_state.manual_control or
            ti.train.state == defines.train_state.manual_control_stop or
            ti.train.state == defines.train_state.no_path)) or
            (ti.train.state == defines.train_state.manual_control and ti.train.speed == 0) then
            TickTable.insert(tick + update_rate_manual,"updateManual",ti)
          end
        end
      end
      global.updateManual[tick] = nil
    end

    if global.updateTrains[tick] then
      for _, ti in pairs(global.updateTrains[tick]) do
        if ti.train and ti.train.valid then
          Alerts.check_noFuel(ti)
          GUI.update_single_traininfo(ti, true)
          if ti.last_state == defines.train_state.wait_station then
            TickTable.insert(tick + update_rate,"updateTrains",ti)
          else
            ti.depart_at = false
          end
        end
      end
      global.updateTrains[tick] = nil
    end

    if global.updateAlarms[tick] then
      for _, ti in pairs(global.updateAlarms[tick]) do
        if ti.train and ti.train.valid then
          if Alerts.check_alerts(ti) then
            GUI.update_single_traininfo(ti)
          end
        end
      end
      global.updateAlarms[tick] = nil
    end

    if tick%10==7  then
      for pi, player in pairs(game.players) do
        if player.connected then
          if player.opened ~= nil and not global.player_opened[pi] then
            game.raise_event(events["on_player_opened"], {entity=player.opened, player_index=pi})
            global.player_opened[pi] = player.opened
          end
          if global.player_opened[pi] and player.opened == nil then
            game.raise_event(events["on_player_closed"], {entity=global.player_opened[pi], player_index=pi})
            global.player_opened[pi] = nil
          end
        end
      end
    end
  end)
  if err then pauseError(err) end
end

script.on_event(defines.events.on_tick, on_tick)

function on_built_entity(event)
  local status, err = pcall(function()
    local ent = event.created_entity
    local ctype = ent.type
    if ctype == "locomotive" or ctype == "cargo-wagon" then
      -- can be a new train or added to an existing one
      if #ent.train.carriages == 1 and ctype == "locomotive" then
        local ti = TrainList.add_train(ent.train, true)
        if ent.type == "locomotive" then
          Alerts.check_noFuel(ti)
        end
      else
        local added = false
        if ctype == "locomotive" then
          local train = ent.train
          local c = #train.locomotives.front_movers + #train.locomotives.back_movers
          if c == 1 then
            TrainList.add_train(ent.train, true)
            added = true
          end
        end
        if not added then
          --added to existing one: revalidate
          --debugDump("add to existing",true)
          TrainList.remove_invalid(ent.force, true)
        end
      end
    elseif ctype == "train-stop" then
      increaseStationCount(ent)
    end
  end)
  if not status then
    pauseError(err, "on_built_entity")
  end
end

function on_preplayer_mined_item(event)
  local status, err = pcall(function()
    local ent = event.entity
    local ctype = ent.type
    if ctype == "locomotive" or ctype == "cargo-wagon" then
      local oldTrain = ent.train
      -- an existing train can be shortened or split in two trains or be removed completely
      local length = #oldTrain.carriages
      if not global.updateEntities then global.updateEntities = {} end
      if length == 1 then
        --debugDump("removing train", true)
        TrainList.remove_train(ent.train)
        table.insert(global.updateEntities, true)
        return
      end
      local ownPos
      for i,carriage in pairs(ent.train.carriages) do
        if ent == carriage then
          ownPos = i
          break
        end
      end
      local before = ownPos > 1 and ent.train.carriages[ownPos-1] or false
      local after = ownPos < length and ent.train.carriages[ownPos+1] or false
      if before then
        --debugDump("before",true)
        table.insert(global.updateEntities, before)
      end
      if after then
        --debugDump("after",true)
        table.insert(global.updateEntities, after)
      end
    elseif ctype == "train-stop" then
      decreaseStationCount(ent,ent.backer_name)
    end
  end)
  if not status then
    pauseError(err, "on_pre_player_mined_item")
  end
end

function on_robot_built_entity(event)
  if event.created_entity.type == "train-stop" then
    increaseStationCount(event.created_entity)
  end
end

function on_robot_pre_mined(event)
  if event.entity.type == "train-stop" then
    decreaseStationCount(event.entity, event.entity.backer_name)
  end
end

script.on_event(defines.events.on_robot_pre_mined, on_robot_pre_mined)
script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity)
script.on_event(defines.events.on_preplayer_mined_item, on_preplayer_mined_item)
script.on_event(defines.events.on_built_entity, on_built_entity)

function getKeyByValue(tableA, value)
  for i,c in pairs(tableA) do
    if c == value then
      return i
    end
  end
end

function on_train_changed_state(event)
  --debugDump("state:"..event.train.state,true)
  --debugDump(game.tick .. getKeyByValue(defines.train_state, event.train.state),true)
  local _, err = pcall(function()
    local train = event.train
    local force = train.carriages[1].force
    --debugDump(game.tick.." state:"..train.state,true)
    local trainInfo = TrainList.get_traininfo(force, train)
    if not trainInfo then
      debugDump("no traininfo",true)
      TrainList.remove_invalid(force)
      if not TrainList.get_traininfo(force, train) then
        trainInfo = TrainList.add_train(train)
      end
    end
    if trainInfo then
      local unf = {}
      unf.previous_state = trainInfo.unfiltered_state.last_state
      unf.previous_tick = trainInfo.unfiltered_state.last_tick
      unf.last_state = train.state
      unf.last_tick = game.tick
      trainInfo.unfiltered_state = unf
      -- skip update if:
      --  going from wait_signal to on_the_path after 300 ticks
      --  going from on_the_path to wait_signal after 1 tick
      --  arrive_signal
      local diff = game.tick - unf.previous_tick
      if  train.state == defines.train_state.arrive_signal or
        (unf.previous_state == defines.train_state.wait_signal and train.state == defines.train_state.on_the_path
        and diff == 300)
        or (unf.previous_state == defines.train_state.on_the_path and train.state == defines.train_state.wait_signal
        and diff == 1) then
        --debugDump(game.tick.." Skipped",true)
        return
      end
      trainInfo.previous_state = trainInfo.last_state
      trainInfo.previous_state_tick = trainInfo.last_state_tick
      trainInfo.last_state = train.state
      trainInfo.last_state_tick = game.tick

      local old_auto = trainInfo.automated
      trainInfo.automated = (train.state ~= defines.train_state.manual_control and train.state ~= defines.train_state.stop_for_auto_control)
      if old_auto ~= trainInfo.automated then
        local change = trainInfo.automated and 1 or -1
        global.automatedCount[force.name] = global.automatedCount[force.name] + change
        for i, player in pairs(game.players) do
          local guiSettings = global.gui[i]
          if player.connected and guiSettings.activeFilterList and guiSettings.filteredIndex[trainInfo.mainIndex] then
            guiSettings.automatedCount = guiSettings.automatedCount + change
            if guiSettings.automatedCount < 0 then
              guiSettings.automatedCount = 0
            end
            if guiSettings.automatedCount == 0 or guiSettings.automatedCount == #guiSettings.filtered_trains then
              GUI.set_toggleButtonCaption(guiSettings,player)
            end
          end
        end
        --log("count:"..global.automatedCount[force.name])
        if global.automatedCount[force.name] < 0 then
          global.automatedCount[force.name] = 0
        end
        if global.automatedCount[force.name] == 0 or global.automatedCount[force.name] == #global.trainsByForce[force.name] then
          GUI.refreshAllTrainInfoGuis(force)
        end
      end

      if trainInfo.alarm.active and trainInfo.alarm.type == "noPath" then
        Alerts.reset_alarm(trainInfo)
      end
      local update_cargo = false
      if train.state == defines.train_state.wait_signal then
        trainInfo.alarm.arrived_at_signal = game.tick
        local nextUpdate = game.tick + global.force_settings[force.name].signalDuration
        TickTable.insert(nextUpdate,"updateAlarms",trainInfo)
      elseif train.state == defines.train_state.on_the_path then
        if trainInfo.previous_state == defines.train_state.wait_station then
          trainInfo.alarm.left_station = game.tick
          local nextUpdate = game.tick + global.force_settings[force.name].stationDuration
          TickTable.insert(nextUpdate,"updateAlarms",trainInfo)
        elseif trainInfo.previous_state == defines.train_state.wait_signal then
          if trainInfo.alarm.type and trainInfo.alarm.type == "timeAtSignal" then
            trainInfo.alarm.active = false
            trainInfo.alarm.type = false
          end
          if trainInfo.alarm.arrived_at_signal then
            TickTable.remove_from_tick(trainInfo.alarm.arrived_at_signal+global.force_settings[force.name].signalDuration, "updateAlarms", trainInfo.train)
            trainInfo.alarm.arrived_at_signal = false
          end
        end
      elseif train.state == defines.train_state.wait_station then
        local depart_at = false;
        local conditions = train.schedule.records[train.schedule.current].wait_conditions
        if conditions then
          for _, condition in pairs(conditions) do
            if condition.type == "time" then
              depart_at = game.tick + condition.ticks
              break
            end
          end
        end

        trainInfo.depart_at = depart_at
        if train.schedule and #train.schedule.records < 2 then
          trainInfo.depart_at = false
        end
        update_cargo = true
        TickTable.insert(game.tick + update_rate,"updateTrains",trainInfo)
      elseif train.state == defines.train_state.arrive_station then
        if trainInfo.alarm.left_station then
          local stationDuration = global.force_settings[force.name].stationDuration
          if trainInfo.alarm.left_station+stationDuration < game.tick then
            Alerts.set_alert(trainInfo,"timeToStation",stationDuration/3600)
          else
            TrainList.removeAlarms(train)
          end
        end
      elseif train.state == defines.train_state.path_lost or train.state == defines.train_state.no_path then
        Alerts.set_alert(trainInfo,"noPath")
      elseif train.state == defines.train_state.manual_control then
        Alerts.reset_alarm(trainInfo)
        TrainList.removeAlarms(train)
        TrainList.add_manual(trainInfo)
      else
        trainInfo.depart_at = false
      end
      Alerts.check_noFuel(trainInfo)
      local station = (train.schedule.records and #train.schedule.records > 0) and train.schedule.records[train.schedule.current].station or false
      trainInfo.current_station = station
      GUI.update_single_traininfo(trainInfo, update_cargo)
    else
      --debugDump("You should never ever see this! Look away!",true)
      --debugDump("no traininfo",true)
      TrainList.remove_invalid(force)
      if not TrainList.get_traininfo(force, train) then
        TrainList.add_train(train)
      end
    end
  end)
  if err then pauseError(err) end
end

script.on_event(defines.events.on_train_changed_state, on_train_changed_state)

function decreaseStationCount(station, name)
  local force = station.force.name
  if not global.station_count[force][name] then
    global.station_count[force][name] = 1
  end
  global.station_count[force][name] = global.station_count[force][name] - 1
  return global.station_count[force][name]
end

function increaseStationCount(station)
  local name = station.backer_name
  local force = station.force.name
  if not global.station_count[force][name] or global.station_count[force][name] < 0 then
    global.station_count[force][name] = 0
  end
  global.station_count[force][name] = global.station_count[force][name] + 1
  return global.station_count[force][name]
end

function on_station_rename(station, oldName)
  --log(game.tick.." renamed "..event.old_name.." to "..event.new_name)
  --if not event.entity.type == "train-stop" then return end
  --local station, oldName, newName = event.entity, event.old_name, event.new_name
  local oldc = decreaseStationCount(station, oldName)
  increaseStationCount(station)
  if oldc == 0 then
    global.station_count[station.force.name][oldName] = nil
  end
end

function on_player_opened(event)
  if event.entity.valid and game.players[event.player_index].valid then
    if event.entity.type == "locomotive" and event.entity.train then
      --TODO do something here?
      return
    elseif event.entity.type == "cargo-wagon" and event.entity.train then
      --TODO do something here?
      return
    elseif event.entity.type == "train-stop" then
      global.opened_name[event.player_index] = event.entity.backer_name
    end
  end
end

function on_player_closed(event)
  if event.entity.valid and game.players[event.player_index].valid then
    if event.entity.type == "locomotive" and event.entity.train then
      local ti = TrainList.get_traininfo(event.entity.force, event.entity.train)
      if not ti then
        ti = TrainList.add_train(event.entity.train)
      end
      TrainList.update_stations(ti)
      Alerts.check_noFuel(ti)
      GUI.update_single_traininfo(ti)
    elseif event.entity.type == "cargo-wagon" and event.entity.train then
      local ti = TrainList.get_traininfo(event.entity.force, event.entity.train)
      if not ti then
        TrainList.add_train(event.entity.train)
      else
        GUI.update_single_traininfo(ti, true)
      end
    elseif event.entity.type == "train-stop" then
      if event.entity.backer_name ~= global.opened_name[event.player_index] then
        on_station_rename(event.entity, global.opened_name[event.player_index])
        global.opened_name[event.player_index] = nil
      end
    end
  end
end

--alternative for script.on_event/game.raise_event ??
--remote.call("EventsPlus", "on_event", "on_player_closed", {name="fat", callback="on_player_closed"})

--script.on_event(remote.call("EventsPlus", "getEvent", "on_player_opened"), on_player_opened)
--script.on_event(remote.call("EventsPlus", "getEvent", "on_player_closed"), on_player_closed)
--script.on_event(remote.call("EventsPlus", "getEvent", "on_entity_renamed"), on_station_rename)

script.on_event(events.on_player_opened, on_player_opened)
script.on_event(events.on_player_closed, on_player_closed)

if remote.interfaces.logistics_railway then
  script.on_event(remote.call("logistics_railway", "get_chest_created_event"), function(event)
    local status, err = pcall(function()
      local chest = event.chest
      local wagon_index = event.wagon_index
      local train = event.train
      --debugDump("Chest: "..util.positiontostr(chest.position),true)
      local ti = TrainList.get_traininfo(train.carriages[1].force,train)
      if ti then
        if not ti.proxy_chests then ti.proxy_chests = {} end
        ti.proxy_chests[wagon_index] = chest
      end
    end)
    if not status then
      pauseError(err)
    end
  end)

  script.on_event(remote.call("logistics_railway", "get_chest_destroyed_event"), function(event)
    local status, err = pcall(function()
      local wagon_index = event.wagon_index
      local train = event.train
      --debugDump("destroyed a chest",true)
      local ti = TrainList.get_traininfo(train.carriages[1].force,train)
      if ti then
        if not ti.proxy_chests then return end
        ti.proxy_chests[wagon_index] = nil
        if #ti.proxy_chests == 0 then ti.proxy_chests = nil end
      end
    end)
    if not status then
      pauseError(err)
    end
  end)
end

function getPageCount(guiSettings, player)
  local trains = (guiSettings.activeFilterList or guiSettings.filter_alarms) and guiSettings.filtered_trains or global.trainsByForce[player.force.name]
  if not trains then error("no trains", 2) end
  local trainCount
  trainCount = #trains or 0
  local p = math.floor((trainCount - 1) / guiSettings.displayCount) + 1
  p = p > 0 and p or 1
  guiSettings.page = guiSettings.page > p and p or guiSettings.page
  return p
end

function update_pageCount(force)
  for _, p in pairs(force.players) do
    local guiSettings = global.gui[p.index]
    guiSettings.pageCount = getPageCount(guiSettings,p)
  end
end

function get_filter_PageCount(force)
  local stationCount = 0
  for _, _ in pairs(global.station_count[force.name]) do
    stationCount = stationCount + 1
  end
  local p = math.floor((stationCount - 1) / (global.PAGE_SIZE)) + 1
  p = p > 0 and p or 1
  return p
end

on_entity_died = function (event)
  local entities = {locomotive=true, ["cargo-wagon"]=true, player=true}
  if not entities[event.entity.type] then
    return
  end
  if event.entity.type == "locomotive" or event.entity.type == "cargo-wagon" then
    local ent = event.entity
    local oldTrain = ent.train
    -- an existing train can be shortened or split in two trains or be removed completely
    local length = #oldTrain.carriages
    if length == 1 then
      TrainList.remove_train(oldTrain)
      return
    end
    local ownPos
    for i,carriage in pairs(ent.train.carriages) do
      if ent == carriage then
        ownPos = i
        break
      end
    end
    if ent.train.carriages[ownPos-1] ~= nil then
      if not global.updateEntities then global.updateEntities = {} end
      table.insert(global.updateEntities, ent.train.carriages[ownPos-1])
      --script.on_event(defines.events.on_tick, on_tick)
    end
    if ent.train.carriages[ownPos+1] ~= nil then
      if not global.updateEntities then global.updateEntities = {} end
      table.insert(global.updateEntities, ent.train.carriages[ownPos+1])
      --script.on_event(defines.events.on_tick, on_tick)
    end
    return
  end
  if event.entity.name ~= "fatcontroller" then
    -- player died
    for i,guiSettings in pairs(global.gui) do
      -- check if character is still valid next tick for players remote controlling a train
      if guiSettings.followEntity then
        global.dead_players = global.dead_players or {}
        global.dead_players[i] = global.character[i]
      end
    end
  end
end

script.on_event(defines.events.on_entity_died, on_entity_died)

function swapPlayer(player, character)
  --player.teleport(character.position)
  if not player.connected then return end
  if player.character ~= nil and player.character.valid and player.character.name == "fatcontroller" then
    player.character.destroy()
  end
  if character.valid and character ~= player.character then
    player.character = character
  end
end

function newFatControllerEntity(player)
  return player.surface.create_entity({name="fatcontroller", position=player.position, force=player.force})
end

function tableIsEmpty(tableA)
  if tableA ~= nil then
    return next(tableA) == nil
  end
  return true
end

function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function saveVar(var, name, varname)
  local n = name or ""
  game.write_file("FAT"..n..".lua", serpent.block(var or global, {name=varname or "global"}))
end

function map_bounds(surface)
  -- determine map size
  local min_x, min_y, max_x, max_y = 0, 0, 0, 0
  for c in surface.get_chunks() do
    if c.x < min_x then
      min_x = c.x
    elseif c.x > max_x then
      max_x = c.x
    end
    if c.y < min_y then
      min_y = c.y
    elseif c.y > max_y then
      max_y = c.y
    end
  end
  -- create bounding box covering entire generated map
  return {{min_x*32,min_y*32},{max_x*32,max_y*32}}
end

function findStations(show)
  local surface = game.surfaces['nauvis']
  local bounds = map_bounds(surface)

  if show then
    debugDump("Searching stations..",true)
  end

  local count = 0
  for _, station in pairs(surface.find_entities_filtered{area=bounds, type="train-stop"}) do
    count = count + 1
    increaseStationCount(station)
  end

  if show then
    debugDump("Found "..count.." stations", true)
  end
end

function findTrains(show)
  local surface = game.surfaces['nauvis']
  local bounds = map_bounds(surface)

  if show then
    debugDump("Searching trains..",true)
  end

  for _, loco in pairs(surface.find_entities_filtered{area=bounds, type="locomotive"}) do
    if not TrainList.get_traininfo(loco.force, loco.train) then
      local trainInfo = TrainList.add_train(loco.train)
      if loco.train.state == defines.train_state.wait_station then
        TickTable.insert(game.tick+update_rate,"updateTrains",trainInfo)
      end
    end
  end
  TrainList.reset_manual()
  if show then
    debugDump("Found "..TrainList.count().." trains",true)
  end
  findStations(show)
end

interface = {
  get_player_switched_event = function()
    return getOrLoadSwitchedEvent()
  end,

  saveVar = function(name)
    saveVar(global, name)
  end,

  remove_invalid_players = function()
    local delete = {}
    for i,_ in pairs(global.gui) do
      if not game.players[i] then
        delete[i] = true
      end
    end
    for j,_ in pairs(delete) do
      global.gui[j] = nil
    end
  end,

  init = function()
    global.PAGE_SIZE = 60
    for pi, g in pairs(global.gui) do
      g.filter_page = 1
      g.filter_pageCount = get_filter_PageCount(game.players[pi].force)
      g.stopButton_state = false
      GUI.refresh_gui(g)
    end
    init_forces()
  end,

  rescan_trains = function()
    for i, guiSettings in pairs(global.gui) do
      if guiSettings.fatControllerGui.trainInfo ~= nil then
        guiSettings.fatControllerGui.trainInfo.destroy()
        if global.character[i] then
          swapPlayer(game.players[i], global.character[i])
        end
      end
    end
    for _, trains in pairs(global.trainsByForce) do
      local c = #trains
      for i=c,1,-1 do
        if not trains[i].train.valid then
          trains[i] = nil
        end
      end
    end
    findTrains()
  end,

  page_size = function(size)
    global.PAGE_SIZE = tonumber(size)
  end,

  find_trains = function()
    global.station_count = nil
    on_init()
    findTrains(true)
  end,

  find_stations = function()
    global.station_count = nil
    on_init()
    findStations(true)
  end
}
remote.add_interface("fat", interface)
