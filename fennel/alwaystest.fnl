(local t (require :faith))
(local socket (require :socket))

(fn sendreceive1 [client input1 input2]
  (client:send input1)
  (client:receive)
  (client:send input2)
  (client:receive))
  
(fn sendreceive2 [client input1 input2]
  (client:send input1)
  (client:send input2)
  (client:receive))
  
(fn test-getinvdrop []
  (local client (socket.connect :localhost 6000))
  (client:receive)
  (client:send "Tester\n");;Probably sent this username in 0.1 seconds, not a whole 10.
  (client:receive)
  (client:settimeout 0.1)
  (t.match "You have these items: Beeper Thing" (sendreceive1 client "get Beeper Thing\n" "inventory\n"))
  (t.not-match "Beeper" (sendreceive1 client "drop Beeper Thing\n" "inventory\n"))
  (client:close))
  
(fn test-movelook []
  (local client (socket.connect :localhost 6000))
  (client:receive)
  (client:send "Tester2\n");;Probably sent this username in 0.1 seconds, not a whole 10.
  (client:receive)
  (client:settimeout 0.1)
;;  (client:send "move north\n")
  (client:send "look\n")
  (t.match "enclosure" (assert (client:receive)))
  ;(t.= "This is simpily a tight passageway, without space to do anything.  However, as you head north, you feel like it holds great danger, but perhaps it is only the temperature, as it gets warmer.  Exits are North, a dangerous part of the passageway, and South." (sendreceive2 client "move north\n" "look\n"))
  (t.match "Beeper" (client:receive))
  (t.match "in the room" (client:receive))
  (client:send "move north\n")
  (t.= nil (client:receive))
  (client:send "look\n")
  (t.match "passageway" (assert (client:receive)))
  ;(t.= "This enclosure has a skylight of rippled glass, that is currently giving out a blurry blue glow, feeling warm, unlike your surroundings.  You hear many loud beeps coming from an pile of odd devices on the ground.  On the wall is a note that says, \"If you do not know the password, always try 12345!  I am not sure why I wrote that.\"  Exits are North, East, South, and West." (sendreceive2 client "move south\n" "look\n"))
  (client:receive)
  (client:receive)
  (client:close))

(fn test-say []
  (local client (socket.connect :localhost 6000))
  (client:receive)
  (client:send "Tester3\n");;Probably sent this username in 0.1 seconds, not a whole 10.
  (client:receive)
  (client:settimeout 0.1)
  (local client2 (socket.connect :localhost 6000))
  (client2:receive)
  (client2:send "Tester4\n");;Probably sent this username in 0.1 seconds, not a whole 10.
  (client2:receive)
  (client2:settimeout 0.1)
  (client:send "say a\n")
  (t.= (client2:receive) "Tester3 says: a"))

{: test-getinvdrop ;;Just checks get, inventory, and drop with Beeper Thing in first area, to avoid erroring if the real problem is in move
 : test-movelook ;;I see no way to check these independently, without adding text after you move to a new area without looking.
 : test-say
 }