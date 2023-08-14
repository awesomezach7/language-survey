-- load namespace
local socket = require("socket")
-- create a TCP socket and bind it to the local host, at any port
local server = assert(socket.bind("*", 6000))
server:settimeout(0.001)
-- find out which port the OS chose for us
local ip, port = server:getsockname()
-- print a message informing what's up
print("Please telnet to localhost on port " .. port)
-- loop forever waiting for clients
local players = {}
function multiple(x, string)
  local group = {}
  for i = 1, x do table.insert(group, string) end
  return group
end
local rooms = {
Death = {description = "You are dead and are staring straight at a console on a wall.  It asks for a password.  Enter by typing \"enter\" and then an integer passcode.", exits = {}, players = {}, items = {}},

Start = {description = "This enclosure has a skylight of rippled glass, that is currently giving out a blurry blue glow, feeling warm, unlike your surroundings.  You hear many loud beeps coming from an pile of odd devices on the ground.  On the wall is a note that says, \"If you do not know the password, always try 12345!  I am not sure why I wrote that.\"  Exits are North, East, South, and West.", exits = {North = "Middleup1", East = "Eastcenter", South = "Middledown1", West = "Westcenter"}, players = {}, items = {"Beeper Thing"}},

Middleup1 = {name = "Middleup1", description = "This is simpily a tight passageway, without space to do anything.  However, as you head north, you feel like it holds great danger, but perhaps it is only the temperature, as it gets warmer.  Exits are North, a dangerous part of the passageway, and South.", exits = {North = "Death", South = "Start"}, players = {}, items = {}},

Middledown1 = {description = "This area is colder than the last, with no refuges of heat.  As you look south through the empty expanse, you find that it seems to get colder ahead.  The floor is cold and metallic.  A large cliff awaits you at the east, south and west exits.  Exits are North, East, South, and West.", exits = {North = "Start", East = "Death", South = "Death", West = "Death"}, players = {}, items = {"Dirty Used Handwarmer"}},

Eastcenter = {description = "This appears to be a place once lived in, but not willingly.  There is a hard, metallic floor, a coat rack, no beds, and a small, uncharged, console.  There are several sticky notes on the wall, including one that simply says, \"I wonder if any million-page books exist?\" Exits are North, a cliff and West.", exits = {North = "Death", West = "Start"}, players = {}, items = {"Coat"}},

Westcenter = {description = "The curve of the roof here makes you realize that you are in a large enclosure enclosing all areas you have been so far.  There is a hole here, but is very melted, and you decide not to get close.  Looking around you, there is a small rover-like vehicle that you are unable to activate in any way, but it seems perfectly suited to go through the hole.  Perhaps it made the hole?  Exits are East and South, which seems to have a cliff.", exits = {East = "Start", South = "Death"}, players = {}, items = {"Paper Note"}}
}

function useinput(line, player)
  if line == "help" then
    if math.random(1, 100) > 1 then
      player.client:send("You can interact with the small world of this text adventure by entering commands.  Right now, you should type \"look\" to learn more about the area you are in.  Other commands are move, to move between rooms; get, to take items from the room; drop, to put items in the room; inventory, to see your inventory; say, to talk to other players in your room; quit, to leave the game; and help, which in most cases displays this message.  There are also some other commands that are explained when they can be used.\n")
    else
      player.client:send("youcaninteractwiththesmallworldofthistextadventurebyenteringcommandsrightnowyoushouldtypelooktolearnmoreabouttheareayouarein othercommandsaremovetomovebetweenroomsgettotakeitemsfromtheroomdroptoputitemsintheroominventorytoseeyourinventorysaytotalktootherplayersinyourroomquittoleavethegame and help, which (almost) never displays this message.  Type help again if this is all you have seen.\n")
    end
  elseif line == "look" then
    player.client:send(player.room.description .. "\nItems in the room: " .. table.concat(player.room.items, ", ") .. "\nPlayers in the room: " .. table.concat(player.room.players, ", ") .. "\n")
  elseif line == "enter 12345" and player.room == rooms.Death then
    player.client:send("You have entered the code correctly, by \"pure chance.\"  You have power over all of existence now, according to the screen in front of you.  You restore your items, but then realize a grue is behind you, likely also sent here by dying.  It gets aggravated, and tries to attack you, but you quickly change the room you are in to the room you started at on the console.  You find yourself in a very different area, and are stunned for a suprisingly long period as you teleport to the starting area.  You are safe.\n")
    player.room = rooms.Start
  elseif string.find(line, "^enter ") and player.room == rooms.Death then
    player.client:send("You entered the code incorrectly.  You swivel your head to find a grue behind you, and it quickly eats you.  You find yourself in an infinite blackness, and are no longer in death.  You are in what death is to dead people.  It is relaxing yet boring.\n")
    player.client:close()
  elseif line == "die" then
    player.client:send("Easter Egg Found!  You are dead.\n")
    player.room = rooms.Death
  elseif string.find(line, "^move ") then
    local direction = string.sub(line, 6)
    local newroom
    if direction == "north" then newroom = player.room.exits.North
    elseif direction == "east" then newroom = player.room.exits.East
    elseif direction == "south" then newroom = player.room.exits.South
    elseif direction == "west" then newroom = player.room.exits.West end
    if newroom then
      for i, character in ipairs(player.room.players) do
        if character == player.name then
          table.remove(player.room.players, i)
        end
      end
      player.room = assert(rooms[newroom], "room not found " .. newroom)
      table.insert(player.room.players, player.name)
    else -- No exit that way
      player.client:send("You cannot go that way.  Sorry!\n")
    end
  elseif string.find(line, "^say ") then
    local statement = string.sub(line, 5)
    for a, competitor in ipairs(players) do
      if competitor.name ~= player.name then
        competitor.client:send(player.name .. " says: " .. statement .. "\n")
      end
    end
  elseif string.find(line, "^get ") then
    local item = string.sub(line, 5)
    local acquired = false
    for i, name in ipairs(player.room.items) do
      if (name == item) and not acquired then
        acquired = true
        table.remove(player.room.items, i)
        table.insert(player.inventory, item)
        player.client:send("Item acquired!\n")
      end
    end
    if acquired == false then
      player.client:send("That item does not exist in this room.  Try using look again.  Perhaps another player took it?\n")
    end
  elseif string.find(line, "^drop ") then
    local item = string.sub(line, 6)
    local dropped = false
    for i, name in ipairs(player.inventory) do
      if (name == item) and not dropped then
        dropped = true
        table.remove(player.inventory, i)
        table.insert(player.room.items, item)
        player.client:send("Item dropped.\n")
      end
    end
    if dropped == false then
      player.client:send("You do not have that item.\n")
    end
  elseif line == "inventory" then
    player.client:send("You have these items: " .. table.concat(player.inventory, ", ") .. "\n")
  else
    print(line)
  end
end

function uniquenameprompt(client)
  -- receive the line
  local line, err = client:receive()
  -- if there was no error, and the name is unique, add player to table, if not unique, rerun the function
  if not err then
    for i=1, #players do
      if line == players[i].name then
        client:send("Player name already in use.\n")
        uniquenameprompt(client)
        return
      end
    end
    local player = {}
    player.name = line
    player.room = rooms.Start
    table.insert(rooms.Start.players, player.name)
    player.inventory = {}
    player.client = client
    table.insert(players, player)
    client:send("Welcome to the game!\n")
  end
end

while true do
  -- check for client connections
  local client = server:accept()
  if client then
    client:settimeout(10)
    client:send("Enter player name within 10 seconds\n")
    uniquenameprompt(client)
    client:settimeout(0.01)
  else
    for i,player in ipairs(players) do
      local line, err = player.client:receive()
      if err == "closed" then table.remove(players, i) end
      if line then
        -- We have our input.
        useinput(line, player)
      end
    end
  end
end