/mob/living/simple_animal/turtle
	name = "Frank"
	desc = "An adorable, slow moving, Texas pal."
	icon = 'icons/mob/pets.dmi'
	icon_state = "yeeslow"
	icon_living = "yeeslow"
	icon_dead = "yeeslow_dead"
	var/icon_hiding = "yeeslow_scared"
	speak_emote = list("yawns")
	emote_hear = list("snores.","yawns.")
	emote_see = list("Stretches out their neck.", "looks around slowly.")
	speak_chance = 1
	turns_per_move = 5
	butcher_results = list(/obj/item/food/meat/slab = 1, /obj/item/clothing/head/franks_hat = 1)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	mob_biotypes = list(MOB_ORGANIC, MOB_BEAST)
	gold_core_spawnable = NO_SPAWN
	melee_damage = 0.5
	health = 2500
	maxHealth = 2500
	speed = 4
	can_be_held = TRUE
	chat_color = "#E7D26F"

	footstep_type = FOOTSTEP_MOB_SHOE

	var/turtle_hide_max = 25 //The time spent hiding in its shell
	var/turtle_hide_dur = 25 //Same as above, this is the var that physically counts down

/mob/living/simple_animal/turtle/handle_automated_movement()
	if(!isturf(src.loc) || !(mobility_flags & MOBILITY_MOVE) || buckled)
		return //If it can't move, dont let it move.

//-----HIDING
	if(icon_state == icon_hiding)
		if(--turtle_hide_dur) //Zzz
			return
		else
			turtle_hide_dur = turtle_hide_max
			icon_state = icon_living
			layer = 4

//-----WANDERING - Time to mosey around
	else
		SSmove_manager.stop_looping(src)

		if(prob(10))
			step(src, pick(GLOB.cardinals))
			return

//Mobs with objects
/mob/living/simple_animal/turtle/attackby(obj/item/O, mob/living/user, params)
	if(!stat && !client && !istype(O, /obj/item/stack/medical))
		if(O.force)
			if(icon_state == icon_hiding)
				turtle_hide_dur = turtle_hide_max //Reset its hiding timer

			icon_state = icon_hiding
	return ..()

//Bullets
/mob/living/simple_animal/turtle/bullet_act(obj/projectile/Proj)
	if(!stat && !client)
		if(icon_state == icon_hiding)
			turtle_hide_dur = turtle_hide_max //Reset its hiding timer
			return BULLET_ACT_FORCE_PIERCE // Shots fly over its shell when hiding

		icon_state = icon_hiding
		layer = 3 // Allows projectiles to go over the shell instead of through it
		return ..()
