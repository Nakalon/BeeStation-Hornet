/obj/machinery/harvester
	name = "organ harvester"
	desc = "An advanced machine used for harvesting organs and limbs from the deceased."
	density = TRUE
	icon = 'icons/obj/machines/harvester.dmi'
	icon_state = "harvester"
	base_icon_state = "harvester"
	verb_say = "states"
	state_open = FALSE
	idle_power_usage = 50
	circuit = /obj/item/circuitboard/machine/harvester
	light_color = LIGHT_COLOR_BLUE
	var/interval = 20
	var/harvesting = FALSE
	var/warming_up = FALSE
	var/list/operation_order = list() //Order of which we harvest limbs.
	var/allow_clothing = FALSE
	var/allow_living = FALSE

/obj/machinery/harvester/Initialize(mapload)
	. = ..()
	if(prob(1))
		name = "auto-autopsy"

/obj/machinery/harvester/RefreshParts()
	interval = 0
	var/max_time = 40
	for(var/obj/item/stock_parts/micro_laser/L in component_parts)
		max_time -= L.rating
		if(L.rating >= 2)
			allow_clothing = TRUE
	interval = max(max_time,1)

/obj/machinery/harvester/update_icon_state()
	if(state_open)
		icon_state = "[base_icon_state]-open"
		return ..()
	if(warming_up)
		icon_state = "[base_icon_state]-charging"
		return ..()
	if(harvesting)
		icon_state = "[base_icon_state]-active"
		return ..()
	icon_state = base_icon_state
	return ..()

/obj/machinery/harvester/open_machine(drop = TRUE)
	if(panel_open)
		return
	. = ..()
	warming_up = FALSE
	harvesting = FALSE

SCREENTIP_ATTACK_HAND(/obj/machinery/attack_hand, "Toggle Open")

/obj/machinery/harvester/attack_hand(mob/user, list/modifiers)
	if(state_open)
		close_machine()
	else if(!harvesting)
		open_machine()

/obj/machinery/harvester/AltClick(mob/user)
	if(harvesting || !user || !isliving(user) || state_open)
		return
	if(can_harvest())
		start_harvest()

/obj/machinery/harvester/proc/can_harvest()
	if(!powered() || state_open || !occupant || !iscarbon(occupant))
		return
	var/mob/living/carbon/C = occupant
	if(!allow_clothing)
		for(var/A in C.held_items + C.get_equipped_items())
			if(!isitem(A))
				continue
			var/obj/item/I = A
			if(!(HAS_TRAIT(I, TRAIT_NODROP)))
				say("Subject may not have abiotic items on.")
				playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)
				return
	if(!(MOB_ORGANIC in C.mob_biotypes))
		say("Subject is not organic.")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)
		return
	if(!allow_living && !(C.stat == DEAD || HAS_TRAIT(C, TRAIT_FAKEDEATH)))     //I mean, the machines scanners arent advanced enough to tell you're alive
		say("Subject is still alive.")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)
		return
	return TRUE

/obj/machinery/harvester/proc/start_harvest()
	if(!occupant || !iscarbon(occupant))
		return
	var/mob/living/carbon/C = occupant
	operation_order = reverseList(C.bodyparts)   //Chest and head are first in bodyparts, so we invert it to make them suffer more
	warming_up = TRUE
	harvesting = TRUE
	visible_message(span_notice("The [name] begins warming up!"))
	say("Initializing harvest protocol.")
	update_appearance()
	addtimer(CALLBACK(src, PROC_REF(harvest)), interval)

/obj/machinery/harvester/proc/harvest()
	warming_up = FALSE
	update_appearance()
	if(!harvesting || state_open || !powered() || !occupant || !iscarbon(occupant))
		return
	playsound(src, 'sound/machines/beeplaser.ogg', 20, 1)
	var/mob/living/carbon/C = occupant
	if(!LAZYLEN(operation_order)) //The list is empty, so we're done here
		end_harvesting()
		return
	var/turf/target = get_turf(src)

	for(var/obj/item/bodypart/BP in operation_order) //first we do non-essential limbs
		BP.drop_limb()
		C.emote("scream")
		if(BP.body_zone != "chest")
			BP.forceMove(target)    //Move the limbs right next to it, except chest, that's a weird one
			BP.drop_organs()
		else
			for(var/obj/item/organ/O in BP.dismember())
				O.forceMove(target) //Some organs, like chest ones, are different so we need to manually move them
		operation_order.Remove(BP)
		break
	use_power(5000)
	addtimer(CALLBACK(src, PROC_REF(harvest)), interval)

/obj/machinery/harvester/proc/end_harvesting()
	warming_up = FALSE
	harvesting = FALSE
	open_machine()
	say("Subject has been successfully harvested.")
	playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, 0)

/obj/machinery/harvester/screwdriver_act(mob/living/user, obj/item/I)
	. = TRUE
	if(..())
		return
	if(occupant)
		to_chat(user, span_warning("[src] is currently occupied!"))
		return
	if(state_open)
		to_chat(user, span_warning("[src] must be closed to [panel_open ? "close" : "open"] its maintenance hatch!"))
		return
	if(default_deconstruction_screwdriver(user, "[initial(icon_state)]-o", initial(icon_state), I))
		return
	return FALSE

/obj/machinery/harvester/crowbar_act(mob/living/user, obj/item/I)
	if(default_pry_open(I))
		return TRUE
	if(default_deconstruction_crowbar(I))
		return TRUE
	return ..()

/obj/machinery/harvester/wrench_act(mob/living/user, obj/item/I)
	if(default_change_direction_wrench(user, I))
		return TRUE
	return ..()

/obj/machinery/harvester/default_pry_open(obj/item/I) //wew
	. = !(state_open || panel_open || (flags_1 & NODECONSTRUCT_1)) && I.tool_behaviour == TOOL_CROWBAR //We removed is_operational here
	if(.)
		I.play_tool_sound(src, 50)
		visible_message(span_notice("[usr] pries open \the [src]."), span_notice("You pry open [src]."))
		open_machine()

/obj/machinery/harvester/on_emag(mob/user)
	..()
	allow_living = TRUE
	to_chat(user, span_warning("You overload [src]'s lifesign scanners."))

/obj/machinery/harvester/container_resist(mob/living/user)
	if(!harvesting)
		visible_message(span_notice("[occupant] emerges from [src]!"),
			span_notice("You climb out of [src]!"))
		open_machine()
	else
		to_chat(user,span_warning("[src] is active and can't be opened!")) //rip

/obj/machinery/harvester/Exited(atom/movable/gone, direction)
	. = ..()
	if (!state_open && gone == occupant)
		container_resist(gone)

/obj/machinery/harvester/relaymove(mob/living/user, direction)
	if (!state_open)
		container_resist(user)

/obj/machinery/harvester/examine(mob/user)
	. = ..()
	if(machine_stat & BROKEN)
		return
	if(state_open)
		. += span_notice("[src] must be closed before harvesting.")
	else if(!harvesting)
		. += span_notice("Alt-click [src] to start harvesting.")
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Harvest speed at <b>[interval*0.1]</b> seconds per organ.")
	if(allow_clothing)
		. += span_notice("harvester has been upgraded to process inorganic materials.")
