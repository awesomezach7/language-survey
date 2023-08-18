(local socket (require :socket))
(local lume (require :lume))
(local server (assert (socket.bind "*" 6000)))
(server:settimeout 0.001)
(local (ip port) (server:getsockname))
(print (.. "Please telnet to localhost on port " port))
(local players {})
(local rooms {:Death {:description "You are dead and are staring straight at a console on a wall.  It asks for a password.  Enter by typing \"enter\" and then an integer passcode."
                      :exits {}
                      :items {}
                      :players {}}
              :Eastcenter {:description "This appears to be a place once lived in, but not willingly.  There is a hard, metallic floor, a coat rack, no beds, and a small, uncharged, console.  There are several sticky notes on the wall, including one that simply says, \"I wonder if any million-page books exist?\" Exits are North, a cliff and West."
                           :exits {:North :Death :West :Start}
                           :items [:Coat]
                           :players {}}
              :Middledown1 {:description "This area is colder than the last, with no refuges of heat.  As you look south through the empty expanse, you find that it seems to get colder ahead.  The floor is cold and metallic.  A large cliff awaits you at the east, south and west exits.  Exits are North, East, South, and West."
                            :exits {:East :Death
                                    :North :Start
                                    :South :Death
                                    :West :Death}
                            :items ["Dirty Used Handwarmer"]
                            :players {}}
              :Middleup1 {:description "This is simpily a tight passageway, without space to do anything.  However, as you head north, you feel like it holds great danger, but perhaps it is only the temperature, as it gets warmer.  Exits are North, a dangerous part of the passageway, and South."
                          :exits {:North :Death :South :Start}
                          :items {}
                          :name :Middleup1
                          :players {}}
              :Start {:description "This enclosure has a skylight of rippled glass, that is currently giving out a blurry blue glow, feeling warm, unlike your surroundings.  You hear many loud beeps coming from an pile of odd devices on the ground.  On the wall is a note that says, \"If you do not know the password, always try 12345!  I am not sure why I wrote that.\"  Exits are North, East, South, and West."
                      :exits {:East :Eastcenter
                              :North :Middleup1
                              :South :Middledown1
                              :West :Westcenter}
                      :items ["Beeper Thing"]
                      :players {}}
              :Westcenter {:description "The curve of the roof here makes you realize that you are in a large enclosure enclosing all areas you have been so far.  There is a hole here, but is very melted, and you decide not to get close.  Looking around you, there is a small rover-like vehicle that you are unable to activate in any way, but it seems perfectly suited to go through the hole.  Perhaps it made the hole?  Exits are East and South, which seems to have a cliff."
                           :exits {:East :Start :South :Death}
                           :items ["Paper Note"]
                           :players {}}})

(fn useinput [line player]
  (if (= line :help)
      (case (math.random 1 100)
       1 (player.client:send "You can interact with the small world of this text adventure by entering commands.  Right now, you should type \"look\" to learn more about the area you are in.  Other commands are move, to move between rooms; get, to take items from the room; drop, to put items in the room; inventory, to see your inventory; say, to talk to other players in your room; quit, to leave the game; and help, which in most cases displays this message.  There are also some other commands that are explained when they can be used.
")
       a (player.client:send "youcaninteractwiththesmallworldofthistextadventurebyenteringcommandsrightnowyoushouldtypelooktolearnmoreabouttheareayouarein othercommandsaremovetomovebetweenroomsgettotakeitemsfromtheroomdroptoputitemsintheroominventorytoseeyourinventorysaytotalktootherplayersinyourroomquittoleavethegame and help, which (almost) never displays this message.  Type help again if this is all you have seen.
"))
      (= line :look)
      (player.client:send (.. player.room.description "\nItems in the room: "
                              (table.concat player.room.items ", ")
                              "\nPlayers in the room: "
                              (table.concat player.room.players ", ") "\n"))
      (and (= line "enter 12345") (= player.room rooms.Death))
      (do
        (player.client:send "You have entered the code correctly, by \"pure chance.\"  You have power over all of existence now, according to the screen in front of you.  You restore your items, but then realize a grue is behind you, likely also sent here by dying.  It gets aggravated, and tries to attack you, but you quickly change the room you are in to the room you started at on the console.  You find yourself in a very different area, and are stunned for a suprisingly long period as you teleport to the starting area.  You are safe.
")
        (set player.room rooms.Start))
      (and (string.find line "^enter ") (= player.room rooms.Death))
      (do
        (player.client:send "You entered the code incorrectly.  You swivel your head to find a grue behind you, and it quickly eats you.  You find yourself in an infinite blackness, and are no longer in death.  You are in what death is to dead people.  It is relaxing yet boring.
")
        (player.client:close))
      (= line :die)
      (do
        (player.client:send "Easter Egg Found!  You are dead.\n")
        (set player.room rooms.Death))
      (string.find line "^move ")
      (let [direction (string.sub line 6)
            newroom (case direction
                      :north player.room.exits.North
                      :east player.room.exits.East
                      :south player.room.exits.South
                      :west player.room.exits.West)]
        (case newroom
            aroom (do
                    (lume.remove player.room.players player.name) ;; remove player
                    (set player.room
                      (assert (. rooms aroom) (.. "room not found " aroom))) ;; move player
                    (table.insert player.room.players player.name)) ;; add player
            nil (player.client:send "You cannot go that way.  Sorry!\n")))
      (string.find line "^say ")
      (let [statement (string.sub line 5)]
        (each [a competitor (ipairs players)]
          (when (not= competitor.name player.name)
            (competitor.client:send (.. player.name " says: " statement "\n")))))
      (string.find line "^get ")
      (let [item (string.sub line 5)]
        (case (lume.find player.room.items item)
          i (do
              (table.remove player.room.items i)
              (table.insert player.inventory item)
              (player.client:send "Item acquired!\n"))
          nil
          (player.client:send "That item does not exist in this room.  Try using look again.  Perhaps another player took it?\n")))
      (string.find line "^drop ")
      (let [item (string.sub line 6)]
        (case (lume.find player.room.items item)
          i (do
              (table.remove player.inventory i)
              (table.insert player.room.items item)
              (player.client:send "Item dropped\n"))
          nil
          (player.client:send "You do not have that item.\n")))
      (= line :inventory)
      (player.client:send (.. "You have these items: "
                              (table.concat player.inventory ", ") "\n"))
      (print line)))

(fn uniquenameprompt [client]
  (let [(line err) (client:receive)]
    (when (not err)
      (for [i 1 (length players)]
        (when (= line (. (. players i) :name))
          (client:send "Player name already in use.\n")
          (uniquenameprompt client)
          (lua "return ")))
      (local player {})
      (set player.name line)
      (set player.room rooms.Start)
      (table.insert rooms.Start.players player.name)
      (set player.inventory {})
      (set player.client client)
      (table.insert players player)
      (client:send "Welcome to the game!\n"))))

(while true
  (local client (server:accept))
  (case client 
   a (do
       (a:settimeout 10)
       (a:send "Enter player name within 10 seconds\n")
       (uniquenameprompt a)
       (a:settimeout 0.01))
   nil (do
        (each [i player (ipairs players)]
        (local (line err) (player.client:receive))
        (when (= err :closed) (table.remove players i))
        (when line (useinput line player))))))
