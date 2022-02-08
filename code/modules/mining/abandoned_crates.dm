//Originally coded by ISaidNo, later modified by Kelenius. Ported from Baystation12.

/obj/structure/closet/crate/secure/loot
	name = "abandoned crate"
	desc = "What could be inside?"
	icon_state = "securecrate"
	integrity_failure = 0 //no breaking open the crate
	var/code = null
	var/lastattempt = null
	var/attempts = 10
	var/codelen = 4
	var/qdel_on_open = FALSE
	var/spawned_loot = FALSE
	tamperproof = 90

/obj/structure/closet/crate/secure/loot/Initialize()
	. = ..()
	var/list/digits = list("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
	code = ""
	for(var/i = 0, i < codelen, i++)
		var/dig = pick(digits)
		code += dig
		digits -= dig  //there are never matching digits in the answer

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/structure/closet/crate/secure/loot/attack_hand(mob/user)
	if(locked)
		to_chat(user, "<span class='notice'>The crate is locked with a Deca-code lock.</span>")
		var/input = input(usr, "Enter [codelen] digits. All digits must be unique.", "Deca-Code Lock", "") as text|null
		if(user.canUseTopic(src, BE_CLOSE))
			var/list/sanitised = list()
			var/sanitycheck = TRUE
			var/char = ""
			var/length_input = length(input)
			for(var/i = 1, i <= length_input, i += length(char)) //put the guess into a list
				char = input[i]
				sanitised += text2num(char)
			for(var/i = 1, i <= length(sanitised) - 1, i++) //compare each digit in the guess to all those following it
				for(var/j = i + 1, j <= length(sanitised), j++)
					if(sanitised[i] == sanitised[j])
						sanitycheck = FALSE //if a digit is repeated, reject the input
			if(input == code)
				to_chat(user, "<span class='notice'>The crate unlocks!</span>")
				locked = FALSE
				cut_overlays()
				add_overlay("securecrateg")
				tamperproof = 0 // set explosion chance to zero, so we dont accidently hit it with a multitool and instantly die
				if(!spawned_loot)
					spawn_loot()
			else if(!input || !sanitycheck || length(sanitised) != codelen)
				to_chat(user, "<span class='notice'>You leave the crate alone.</span>")
			else
				to_chat(user, "<span class='warning'>A red light flashes.</span>")
				lastattempt = input
				attempts--
				if(attempts == 0)
					boom(user)
	else
		return ..()

/obj/structure/closet/crate/secure/loot/AltClick(mob/living/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	return attack_hand(user) //this helps you not blow up so easily by overriding unlocking which results in an immediate boom.

/obj/structure/closet/crate/secure/loot/attackby(obj/item/W, mob/user)
	if(locked)
		if(W.tool_behaviour == TOOL_MULTITOOL)
			to_chat(user, "<span class='notice'>DECA-CODE LOCK REPORT:</span>")
			if(attempts == 1)
				to_chat(user, "<span class='warning'>* Anti-Tamper Bomb will activate on next failed access attempt.</span>")
			else
				to_chat(user, "<span class='notice'>* Anti-Tamper Bomb will activate after [attempts] failed access attempts.</span>")
			if(lastattempt != null)
				var/bulls = 0 //right position, right number
				var/cows = 0 //wrong position but in the puzzle

				var/lastattempt_char = ""
				var/length_lastattempt = length(lastattempt)
				var/lastattempt_it = 1

				var/code_char = ""
				var/length_code = length(code)
				var/code_it = 1

				while(lastattempt_it <= length_lastattempt && code_it <= length_code) // Go through list and count matches
					lastattempt_char = lastattempt[lastattempt_it]
					code_char = code[code_it]
					if(lastattempt_char == code_char)
						++bulls
					else if(findtext(code, lastattempt_char))
						++cows

					lastattempt_it += length(lastattempt_char)
					code_it += length(code_char)

				to_chat(user, "<span class='notice'>Last code attempt, [lastattempt], had [bulls] correct digits at correct positions and [cows] correct digits at incorrect positions.</span>")
			return
	return ..()

/obj/structure/closet/secure/loot/dive_into(mob/living/user)
	if(!locked)
		return ..()
	to_chat(user, "<span class='notice'>That seems like a stupid idea.</span>")
	return FALSE

/obj/structure/closet/crate/secure/loot/emag_act(mob/user)
	if(locked)
		boom(user)

/obj/structure/closet/crate/secure/loot/togglelock(mob/user)
	if(locked)
		boom(user)
	else
		if (qdel_on_open)
			qdel(src)
		..()

/obj/structure/closet/crate/secure/loot/deconstruct(disassembled = TRUE)
	if(locked)
		boom()
	else
		if (qdel_on_open)
			qdel(src)
		..()

/obj/structure/closet/crate/secure/loot/proc/spawn_loot()
	var/loot = rand(1,100) //100 different crates with varying chances of spawning
	//Voidcrew edit
	//Completly refactored the lootdrops of the crates, highest chance to lowest chance
	switch(loot)
		if(1 to 100)
			new /obj/item/slimecross/recurring/grey(src)
			new /obj/item/stack/ore/mineral/plasma(1,3)
	spawned_loot = TRUE
