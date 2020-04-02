#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/_demo;
#include maps/mp/zombies/_zm_audio;
#include maps/mp/zombies/_zm_pers_upgrades_functions;
#include maps/mp/zombies/_zm_power;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/zombies/_zm_magicbox;

init() //checked
{
	level.additionalprimaryweapon_limit = 3;
	level.perk_purchase_limit = 4;
	if ( !level.createfx_enabled )
	{
		perks_register_clientfield(); //fixed
	}
	if ( !level.enable_magic )
	{
		return;
	}
	initialize_custom_perk_arrays();
	perk_machine_spawn_init();
	
	//not broken
	vending_weapon_upgrade_trigger = [];
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	i = 0;
	while ( i < vending_triggers.size )
	{
		if ( isDefined( vending_triggers[ i ].script_noteworthy ) && vending_triggers[ i ].script_noteworthy == "specialty_weapupgrade" )
		{
			vending_weapon_upgrade_trigger[ vending_weapon_upgrade_trigger.size ] = vending_triggers[ i ];
			arrayremovevalue( vending_triggers, vending_triggers[ i ] );
		}
		i++;
	}
	old_packs = getentarray( "zombie_vending_upgrade", "targetname" );
	i = 0;
	while ( i < old_packs.size )
	{
		vending_weapon_upgrade_trigger[ vending_weapon_upgrade_trigger.size ] = old_packs[ i ];
		i++;
	}
	flag_init( "pack_machine_in_use" );
	if ( vending_triggers.size < 1 )
	{
		return;
	}
	if ( vending_weapon_upgrade_trigger.size >= 1 )
	{
		array_thread( vending_weapon_upgrade_trigger, ::vending_weapon_upgrade );
	}
	level.machine_assets = [];
	if ( !isDefined( level.custom_vending_precaching ) )
	{
		level.custom_vending_precaching = ::default_vending_precaching;
	}
	[[ level.custom_vending_precaching ]]();
	if ( !isDefined( level.packapunch_timeout ) )
	{
		level.packapunch_timeout = 15;
	}
	set_zombie_var( "zombie_perk_cost", 2000 );
	set_zombie_var( "zombie_perk_juggernaut_health", 160 );
	set_zombie_var( "zombie_perk_juggernaut_health_upgrade", 190 );
	array_thread( vending_triggers, ::vending_trigger_think );
	array_thread( vending_triggers, ::electric_perks_dialog );
	
	
	
	if ( isDefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
	{
		level thread turn_doubletap_on();
	}
	if ( isDefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
	{
		level thread turn_marathon_on();
	}
	if ( isDefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
	{
		level thread turn_jugger_on();
	}
	if ( isDefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
	{
		level thread turn_revive_on();
	}
	if ( isDefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
	{
		level thread turn_sleight_on();
	}
	if ( isDefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
	{
		level thread turn_deadshot_on();
	}
	if ( isDefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
	{
		level thread turn_tombstone_on();
	}
	if ( isDefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
	{
		level thread turn_additionalprimaryweapon_on();
	}
	if ( isDefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
	{
		level thread turn_chugabud_on();
	}
	if(level._custom_perks.size > 0)
	{
		a_keys = getarraykeys(level._custom_perks);
		for(i = 0; i < a_keys.size; i++)
		{
			if(isdefined(level._custom_perks[ a_keys[ i ] ].perk_machine_thread))
			{
				level thread [[level._custom_perks[ a_keys[ i ] ].perk_machine_thread]]();
			}
		}
	}
	if ( isDefined( level._custom_turn_packapunch_on ) )
	{
		level thread [[ level._custom_turn_packapunch_on ]]();
	}
	else
	{
		level thread turn_packapunch_on();
	}
	if ( isDefined( level.quantum_bomb_register_result_func ) )
	{
		[[ level.quantum_bomb_register_result_func ]]( "give_nearest_perk", ::quantum_bomb_give_nearest_perk_result, 10, ::quantum_bomb_give_nearest_perk_validation );
	}
	level thread perk_hostmigration();

}

default_vending_precaching() //checked
{
	if ( isDefined( level.zombiemode_using_pack_a_punch ) && level.zombiemode_using_pack_a_punch )
	{
		precacheitem( "zombie_knuckle_crack" );
		precachemodel( "p6_anim_zm_buildable_pap" );
		precachemodel( "p6_anim_zm_buildable_pap_on" );
		precachestring( &"ZOMBIE_PERK_PACKAPUNCH" );
		precachestring( &"ZOMBIE_PERK_PACKAPUNCH_ATT" );
		level._effect[ "packapunch_fx" ] = loadfx( "maps/zombie/fx_zombie_packapunch" );
		level.machine_assets[ "packapunch" ] = spawnstruct();
		level.machine_assets[ "packapunch" ].weapon = "zombie_knuckle_crack";
		level.machine_assets[ "packapunch" ].off_model = "p6_anim_zm_buildable_pap";
		level.machine_assets[ "packapunch" ].on_model = "p6_anim_zm_buildable_pap_on";
	}
	if ( isDefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
	{
		precacheitem( "zombie_perk_bottle_additionalprimaryweapon" );
		precacheshader( "specialty_additionalprimaryweapon_zombies" );
		precachemodel( "zombie_vending_three_gun" );
		precachemodel( "zombie_vending_three_gun_on" );
		precachestring( &"ZOMBIE_PERK_ADDITIONALWEAPONPERK" );
		level._effect[ "additionalprimaryweapon_light" ] = loadfx( "misc/fx_zombie_cola_arsenal_on" );
		level.machine_assets[ "additionalprimaryweapon" ] = spawnstruct();
		level.machine_assets[ "additionalprimaryweapon" ].weapon = "zombie_perk_bottle_additionalprimaryweapon";
		level.machine_assets[ "additionalprimaryweapon" ].off_model = "zombie_vending_three_gun";
		level.machine_assets[ "additionalprimaryweapon" ].on_model = "zombie_vending_three_gun_on";
	}
	if ( isDefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
	{
		precacheitem( "zombie_perk_bottle_deadshot" );
		precacheshader( "specialty_ads_zombies" );
		precachemodel( "zombie_vending_ads" );
		precachemodel( "zombie_vending_ads_on" );
		precachestring( &"ZOMBIE_PERK_DEADSHOT" );
		level._effect[ "deadshot_light" ] = loadfx( "misc/fx_zombie_cola_dtap_on" );
		level.machine_assets[ "deadshot" ] = spawnstruct();
		level.machine_assets[ "deadshot" ].weapon = "zombie_perk_bottle_deadshot";
		level.machine_assets[ "deadshot" ].off_model = "zombie_vending_ads";
		level.machine_assets[ "deadshot" ].on_model = "zombie_vending_ads_on";
	}
	if ( isDefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
	{
		precacheitem( "zombie_perk_bottle_doubletap" );
		precacheshader( "specialty_doubletap_zombies" );
		precachemodel( "zombie_vending_doubletap2" );
		precachemodel( "zombie_vending_doubletap2_on" );
		precachestring( &"ZOMBIE_PERK_DOUBLETAP" );
		level._effect[ "doubletap_light" ] = loadfx( "misc/fx_zombie_cola_dtap_on" );
		level.machine_assets[ "doubletap" ] = spawnstruct();
		level.machine_assets[ "doubletap" ].weapon = "zombie_perk_bottle_doubletap";
		level.machine_assets[ "doubletap" ].off_model = "zombie_vending_doubletap2";
		level.machine_assets[ "doubletap" ].on_model = "zombie_vending_doubletap2_on";
	}
	if ( isDefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
	{
		precacheitem( "zombie_perk_bottle_jugg" );
		precacheshader( "specialty_juggernaut_zombies" );
		precachemodel( "zombie_vending_jugg" );
		precachemodel( "zombie_vending_jugg_on" );
		precachestring( &"ZOMBIE_PERK_JUGGERNAUT" );
		level._effect[ "jugger_light" ] = loadfx( "misc/fx_zombie_cola_jugg_on" );
		level.machine_assets[ "juggernog" ] = spawnstruct();
		level.machine_assets[ "juggernog" ].weapon = "zombie_perk_bottle_jugg";
		level.machine_assets[ "juggernog" ].off_model = "zombie_vending_jugg";
		level.machine_assets[ "juggernog" ].on_model = "zombie_vending_jugg_on";
	}
	if ( isDefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
	{
		precacheitem( "zombie_perk_bottle_marathon" );
		precacheshader( "specialty_marathon_zombies" );
		precachemodel( "zombie_vending_marathon" );
		precachemodel( "zombie_vending_marathon_on" );
		precachestring( &"ZOMBIE_PERK_MARATHON" );
		level._effect[ "marathon_light" ] = loadfx( "maps/zombie/fx_zmb_cola_staminup_on" );
		level.machine_assets[ "marathon" ] = spawnstruct();
		level.machine_assets[ "marathon" ].weapon = "zombie_perk_bottle_marathon";
		level.machine_assets[ "marathon" ].off_model = "zombie_vending_marathon";
		level.machine_assets[ "marathon" ].on_model = "zombie_vending_marathon_on";
	}
	if ( isDefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
	{
		precacheitem( "zombie_perk_bottle_revive" );
		precacheshader( "specialty_quickrevive_zombies" );
		precachemodel( "zombie_vending_revive" );
		precachemodel( "zombie_vending_revive_on" );
		precachestring( &"ZOMBIE_PERK_QUICKREVIVE" );
		level._effect[ "revive_light" ] = loadfx( "misc/fx_zombie_cola_revive_on" );
		level._effect[ "revive_light_flicker" ] = loadfx( "maps/zombie/fx_zmb_cola_revive_flicker" );
		level.machine_assets[ "revive" ] = spawnstruct();
		level.machine_assets[ "revive" ].weapon = "zombie_perk_bottle_revive";
		level.machine_assets[ "revive" ].off_model = "zombie_vending_revive";
		level.machine_assets[ "revive" ].on_model = "zombie_vending_revive_on";
	}
	if ( isDefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
	{
		precacheitem( "zombie_perk_bottle_sleight" );
		precacheshader( "specialty_fastreload_zombies" );
		precachemodel( "zombie_vending_sleight" );
		precachemodel( "zombie_vending_sleight_on" );
		precachestring( &"ZOMBIE_PERK_FASTRELOAD" );
		level._effect[ "sleight_light" ] = loadfx( "misc/fx_zombie_cola_on" );
		level.machine_assets[ "speedcola" ] = spawnstruct();
		level.machine_assets[ "speedcola" ].weapon = "zombie_perk_bottle_sleight";
		level.machine_assets[ "speedcola" ].off_model = "zombie_vending_sleight";
		level.machine_assets[ "speedcola" ].on_model = "zombie_vending_sleight_on";
	}
	if ( isDefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
	{
		precacheitem( "zombie_perk_bottle_tombstone" );
		precacheshader( "specialty_tombstone_zombies" );
		precachemodel( "zombie_vending_tombstone" );
		precachemodel( "zombie_vending_tombstone_on" );
		precachemodel( "ch_tombstone1" );
		precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
		level._effect[ "tombstone_light" ] = loadfx( "misc/fx_zombie_cola_on" );
		level.machine_assets[ "tombstone" ] = spawnstruct();
		level.machine_assets[ "tombstone" ].weapon = "zombie_perk_bottle_tombstone";
		level.machine_assets[ "tombstone" ].off_model = "zombie_vending_tombstone";
		level.machine_assets[ "tombstone" ].on_model = "zombie_vending_tombstone_on";
	}
	if ( isDefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
	{
		precacheitem( "zombie_perk_bottle_whoswho" );
		precacheshader( "specialty_quickrevive_zombies" );
		precachemodel( "p6_zm_vending_chugabud" );
		precachemodel( "p6_zm_vending_chugabud_on" );
		precachemodel( "ch_tombstone1" );
		precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
		level._effect[ "tombstone_light" ] = loadfx( "misc/fx_zombie_cola_on" );
		level.machine_assets[ "whoswho" ] = spawnstruct();
		level.machine_assets[ "whoswho" ].weapon = "zombie_perk_bottle_whoswho";
		level.machine_assets[ "whoswho" ].off_model = "p6_zm_vending_chugabud";
		level.machine_assets[ "whoswho" ].on_model = "p6_zm_vending_chugabud_on";
	}
	if(level._custom_perks.size > 0) //changed
	{
		a_keys = getarraykeys(level._custom_perks);
		for(i = 0; i < a_keys.size; i++)
		{
			if(isdefined(level._custom_perks[ a_keys[ i ] ].precache_func))
			{
				level [[level._custom_perks[ a_keys[ i ] ].precache_func]]();
			}
		}
	}
}

pap_weapon_move_in( trigger, origin_offset, angles_offset ) //changed
{
	level endon( "Pack_A_Punch_off" );
	trigger endon( "pap_player_disconnected" );
	trigger.worldgun rotateto( self.angles + angles_offset + vectorScale( ( 0, 1, 0 ), 90 ), 0.35, 0, 0 );
	offsetdw = vectorScale( ( 1, 1, 1 ), 3 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw rotateto( self.angles + angles_offset + vectorScale( ( 0, 1, 0 ), 90 ), 0.35, 0, 0 );
	}
	wait 0.5;
	trigger.worldgun moveto( self.origin + origin_offset, 0.5, 0, 0 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw moveto( self.origin + origin_offset + offsetdw, 0.5, 0, 0 );
	}
}

pap_weapon_move_out( trigger, origin_offset, interact_offset ) //changed
{
	level endon( "Pack_A_Punch_off" );
	trigger endon( "pap_player_disconnected" );
	offsetdw = vectorScale( ( 1, 1, 1 ), 3 );
	if ( !isDefined( trigger.worldgun ) )
	{
		return;
	}
	trigger.worldgun moveto( self.origin + interact_offset, 0.5, 0, 0 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw moveto( self.origin + interact_offset + offsetdw, 0.5, 0, 0 );
	}
	wait 0.5;
	if ( !isDefined( trigger.worldgun ) )
	{
		return;
	}
	trigger.worldgun moveto( self.origin + origin_offset, level.packapunch_timeout, 0, 0 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw moveto( self.origin + origin_offset + offsetdw, level.packapunch_timeout, 0, 0 );
	}
}

fx_ent_failsafe()
{
	wait 25;
	self delete();
}

third_person_weapon_upgrade( current_weapon, upgrade_weapon, packa_rollers, perk_machine, trigger ) //changed
{
	level endon( "Pack_A_Punch_off" );
	trigger endon( "pap_player_disconnected" );
	rel_entity = trigger.perk_machine;
	origin_offset = ( 0, 0, 0 );
	angles_offset = ( 0, 0, 0 );
	origin_base = self.origin;
	angles_base = self.angles;
	if ( isDefined( rel_entity ) )
	{
		if ( isDefined( level.pap_interaction_height ) )
		{
			origin_offset = ( 0, 0, level.pap_interaction_height );
		}
		else
		{
			origin_offset = vectorScale( ( 0, 0, 1 ), 35 );
		}
		angles_offset = vectorScale( ( 0, 1, 0 ), 90 );
		origin_base = rel_entity.origin;
		angles_base = rel_entity.angles;
	}
	else
	{
		rel_entity = self;
	}
	forward = anglesToForward( angles_base + angles_offset );
	interact_offset = origin_offset + ( forward * -25 );
	if ( !isDefined( perk_machine.fx_ent ) )
	{
		perk_machine.fx_ent = spawn( "script_model", origin_base + origin_offset + ( 0, 1, -34 ) );
		perk_machine.fx_ent.angles = angles_base + angles_offset;
		perk_machine.fx_ent setmodel( "tag_origin" );
		perk_machine.fx_ent linkto( perk_machine );
	}
	if ( isDefined( level._effect[ "packapunch_fx" ] ) )
	{
		fx = playfxontag( level._effect[ "packapunch_fx" ], perk_machine.fx_ent, "tag_origin" );
	}
	offsetdw = vectorScale( ( 1, 1, 1 ), 3 );
	weoptions = self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( current_weapon );
	trigger.worldgun = spawn_weapon_model( current_weapon, undefined, origin_base + interact_offset, self.angles, weoptions );
	worldgundw = undefined;
	if ( maps/mp/zombies/_zm_magicbox::weapon_is_dual_wield( current_weapon ) )
	{
		worldgundw = spawn_weapon_model( current_weapon, maps/mp/zombies/_zm_magicbox::get_left_hand_weapon_model_name( current_weapon ), origin_base + interact_offset + offsetdw, self.angles, weoptions );
	}
	trigger.worldgun.worldgundw = worldgundw;
	if ( isDefined( level.custom_pap_move_in ) )
	{
		perk_machine [[ level.custom_pap_move_in ]]( trigger, origin_offset, angles_offset, perk_machine );
	}
	else
	{
		perk_machine pap_weapon_move_in( trigger, origin_offset, angles_offset );
	}
	self playsound( "zmb_perks_packa_upgrade" );
	if ( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles + vectorScale( ( 1, 0, 0 ), 179 ), 0.25, 0, 0 );
	}
	wait 0.35;
	trigger.worldgun delete();
	if ( isDefined( worldgundw ) )
	{
		worldgundw delete();
	}
	wait 3;
	if ( isDefined( self ) )
	{
		self playsound( "zmb_perks_packa_ready" );
	}
	else
	{
		return;
	}
	upoptions = self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( upgrade_weapon );
	trigger.current_weapon = current_weapon;
	trigger.upgrade_name = upgrade_weapon;
	trigger.worldgun = spawn_weapon_model( upgrade_weapon, undefined, origin_base + origin_offset, angles_base + angles_offset + vectorScale( ( 0, 1, 0 ), 90 ), upoptions );
	worldgundw = undefined;
	if ( maps/mp/zombies/_zm_magicbox::weapon_is_dual_wield( upgrade_weapon ) )
	{
		worldgundw = spawn_weapon_model( upgrade_weapon, maps/mp/zombies/_zm_magicbox::get_left_hand_weapon_model_name( upgrade_weapon ), origin_base + origin_offset + offsetdw, angles_base + angles_offset + vectorScale( ( 0, -1, 0 ), 90 ), upoptions );
	}
	trigger.worldgun.worldgundw = worldgundw;
	if ( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles - vectorScale( ( 1, 0, 0 ), 179 ), 0.25, 0, 0 );
	}
	if ( isDefined( level.custom_pap_move_out ) )
	{
		rel_entity thread [[ level.custom_pap_move_out ]]( trigger, origin_offset, interact_offset );
	}
	else
	{
		rel_entity thread pap_weapon_move_out( trigger, origin_offset, interact_offset );
	}
	return trigger.worldgun;
}

can_pack_weapon( weaponname ) //checked
{
	if ( weaponname == "riotshield_zm" )
	{
		return 0;
	}
	if ( flag( "pack_machine_in_use" ) )
	{
		return 1;
	}
	weaponname = self get_nonalternate_weapon( weaponname );
	if ( !maps/mp/zombies/_zm_weapons::is_weapon_or_base_included( weaponname ) )
	{
		return 0;
	}
	if ( !self maps/mp/zombies/_zm_weapons::can_upgrade_weapon( weaponname ) )
	{
		return 0;
	}
	return 1;
}

player_use_can_pack_now() //checked
{
	if ( !self maps/mp/zombies/_zm_laststand::player_is_in_laststand() && isDefined( self.intermission ) || self.intermission && self isthrowinggrenade() )
	{
		return 0;
	}
	if ( !self can_buy_weapon() )
	{
		return 0;
	}
	if ( self hacker_active() )
	{
		return 0;
	}
	if ( !self can_pack_weapon( self getcurrentweapon() ) )
	{
		return 0;
	}
	return 1;
}

vending_machine_trigger_think() //changed 3/30/20 4:17 pm
{
	self endon("death");
	self endon("Pack_A_Punch_off");
	while(1)
	{
		players = get_players();
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(self.pack_player) && self.pack_player != players[i] || !players[i] player_use_can_pack_now())
			{
				self setinvisibletoplayer(players[i], 1);
				continue;
			}
			self setinvisibletoplayer(players[i], 0);
		}
		wait(0.1);
	}
}

vending_weapon_upgrade() //changed
{
	level endon( "Pack_A_Punch_off" );
	wait 0.01;
	perk_machine = getent( self.target, "targetname" );
	self.perk_machine = perk_machine;
	perk_machine_sound = getentarray( "perksacola", "targetname" );
	packa_rollers = spawn( "script_origin", self.origin );
	packa_timer = spawn( "script_origin", self.origin );
	packa_rollers linkto( self );
	packa_timer linkto( self );
	if ( isDefined( perk_machine.target ) )
	{
		perk_machine.wait_flag = getent( perk_machine.target, "targetname" );
	}
	pap_is_buildable = self is_buildable();
	if ( pap_is_buildable )
	{
		self trigger_off();
		perk_machine hide();
		if ( isDefined( perk_machine.wait_flag ) )
		{
			perk_machine.wait_flag hide();
		}
		wait_for_buildable( "pap" );
		self trigger_on();
		perk_machine show();
		if ( isDefined( perk_machine.wait_flag ) )
		{
			perk_machine.wait_flag show();
		}
	}
	self usetriggerrequirelookat();
	self sethintstring( &"ZOMBIE_NEED_POWER" );
	self setcursorhint( "HINT_NOICON" );
	power_off = !self maps/mp/zombies/_zm_power::pap_is_on();
	if ( power_off )
	{
		pap_array = [];
		pap_array[ 0 ] = perk_machine;
		level thread do_initial_power_off_callback( pap_array, "packapunch" );
		level waittill( "Pack_A_Punch_on" );
	}
	self enable_trigger();
	if ( isDefined( level.machine_assets[ "packapunch" ].power_on_callback ) )
	{
		perk_machine thread [[ level.machine_assets[ "packapunch" ].power_on_callback ]]();
	}
	self thread vending_machine_trigger_think();
	perk_machine playloopsound( "zmb_perks_packa_loop" );
	self thread shutoffpapsounds( perk_machine, packa_rollers, packa_timer );
	self thread vending_weapon_upgrade_cost();
	for ( ;; )
	{
		self.pack_player = undefined;
		self waittill( "trigger", player );
		index = maps/mp/zombies/_zm_weapons::get_player_index( player );
		current_weapon = player getcurrentweapon();
		current_weapon = player maps/mp/zombies/_zm_weapons::switch_from_alt_weapon( current_weapon );
		if ( isDefined( level.custom_pap_validation ) )
		{
			valid = self [[ level.custom_pap_validation ]]( player );
			if ( !valid )
			{
				continue;
			}
		}
		if ( player maps/mp/zombies/_zm_magicbox::can_buy_weapon() && !player maps/mp/zombies/_zm_laststand::player_is_in_laststand() && isDefined( player.intermission ) && !player.intermission || player isthrowinggrenade() && !player maps/mp/zombies/_zm_weapons::can_upgrade_weapon( current_weapon ) )
		{
			wait 0.1;
			continue;
		}
		if ( isDefined( level.pap_moving ) && level.pap_moving )
		{
			continue;
		}
		if ( player isswitchingweapons() )
		{
			wait 0.1;
			if ( player isswitchingweapons() )
			{
				continue;
			}
		}
		if ( !maps/mp/zombies/_zm_weapons::is_weapon_or_base_included( current_weapon ) )
		{
			continue;
		}
		
		current_cost = self.cost;
		player.restore_ammo = undefined;
		player.restore_clip = undefined;
		player.restore_stock = undefined;
		player_restore_clip_size = undefined;
		player.restore_max = undefined;
		upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
		if ( upgrade_as_attachment )
		{
			current_cost = self.attachment_cost;
			player.restore_ammo = 1;
			player.restore_clip = player getweaponammoclip( current_weapon );
			player.restore_clip_size = weaponclipsize( current_weapon );
			player.restore_stock = player getweaponammostock( current_weapon );
			player.restore_max = weaponmaxammo( current_weapon );
		}
		if ( player maps/mp/zombies/_zm_pers_upgrades_functions::is_pers_double_points_active() )
		{
			current_cost = player maps/mp/zombies/_zm_pers_upgrades_functions::pers_upgrade_double_points_cost( current_cost );
		}
		if ( player.score < current_cost ) 
		{
			self playsound( "deny" );
			if ( isDefined( level.custom_pap_deny_vo_func ) )
			{
				player [[ level.custom_pap_deny_vo_func ]]();
			}
			else
			{
				player maps/mp/zombies/_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
			}
			continue;
		}
		
		self.pack_player = player;
		flag_set( "pack_machine_in_use" );
		maps/mp/_demo::bookmark( "zm_player_use_packapunch", getTime(), player );
		player maps/mp/zombies/_zm_stats::increment_client_stat( "use_pap" );
		player maps/mp/zombies/_zm_stats::increment_player_stat( "use_pap" );
		self thread destroy_weapon_in_blackout( player );
		self thread destroy_weapon_on_disconnect( player );
		player maps/mp/zombies/_zm_score::minus_to_player_score( current_cost, 1 );
		sound = "evt_bottle_dispense";
		playsoundatposition( sound, self.origin );
		self thread maps/mp/zombies/_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
		player maps/mp/zombies/_zm_audio::create_and_play_dialog( "weapon_pickup", "upgrade_wait" );
		self disable_trigger();
		if ( isDefined( upgrade_as_attachment ) && !upgrade_as_attachment )
		{
			player thread do_player_general_vox( "general", "pap_wait", 10, 100 );
		}
		else
		{
			player thread do_player_general_vox( "general", "pap_wait2", 10, 100 );
		}
		player thread do_knuckle_crack();
		self.current_weapon = current_weapon;
		upgrade_name = maps/mp/zombies/_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
		player third_person_weapon_upgrade( current_weapon, upgrade_name, packa_rollers, perk_machine, self );
		self enable_trigger();
		self sethintstring( &"ZOMBIE_GET_UPGRADED" );
		if ( isDefined( player ) )
		{
			self setinvisibletoall();
			self setvisibletoplayer( player );
			self thread wait_for_player_to_take( player, current_weapon, packa_timer, upgrade_as_attachment );
		}
		self thread wait_for_timeout( current_weapon, packa_timer, player );
		self waittill_any( "pap_timeout", "pap_taken", "pap_player_disconnected" );
		self.current_weapon = "";
		if ( isDefined( self.worldgun ) && isDefined( self.worldgun.worldgundw ) )
		{
			self.worldgun.worldgundw delete();
		}
		if ( isDefined( self.worldgun ) )
		{
			self.worldgun delete();
		}
		if ( isDefined( level.zombiemode_reusing_pack_a_punch ) && level.zombiemode_reusing_pack_a_punch )
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
		}
		else
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		}
		self setvisibletoall();
		self.pack_player = undefined;
		flag_clear( "pack_machine_in_use" );	
	}
}

shutoffpapsounds( ent1, ent2, ent3 ) //checked 3/30/20 4:18 pm
{
	while ( 1 )
	{
		level waittill( "Pack_A_Punch_off" );
		level thread turnonpapsounds( ent1 );
		ent1 stoploopsound( 0.1 );
		ent2 stoploopsound( 0.1 );
		ent3 stoploopsound( 0.1 );
	}
}

turnonpapsounds( ent ) //checked 3/30/20 4:18 pm
{
	level waittill( "Pack_A_Punch_on" );
	ent playloopsound( "zmb_perks_packa_loop" );
}

vending_weapon_upgrade_cost() //checked 3/30/20 4:19 pm
{
	level endon( "Pack_A_Punch_off" );
	while ( 1 )
	{
		self.cost = 5000;
		self.attachment_cost = 2000;
		if ( isDefined( level.zombiemode_reusing_pack_a_punch ) && level.zombiemode_reusing_pack_a_punch )
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
		}
		else
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		}
		level waittill( "powerup bonfire sale" );
		self.cost = 1000;
		self.attachment_cost = 1000;
		if ( isDefined( level.zombiemode_reusing_pack_a_punch ) && level.zombiemode_reusing_pack_a_punch )
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
		}
		else
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		}
		level waittill( "bonfire_sale_off" );
	}
}

wait_for_player_to_take( player, weapon, packa_timer, upgrade_as_attachment ) //changed 3/30/20 4:22 pm
{
	current_weapon = self.current_weapon;
	upgrade_name = self.upgrade_name;
	/*
/#
	assert( isDefined( current_weapon ), "wait_for_player_to_take: weapon does not exist" );
#/
/#
	assert( isDefined( upgrade_name ), "wait_for_player_to_take: upgrade_weapon does not exist" );
#/
	*/
	upgrade_weapon = upgrade_name;
	self endon( "pap_timeout" );
	level endon( "Pack_A_Punch_off" );
	while ( 1 )
	{
		packa_timer playloopsound( "zmb_perks_packa_ticktock" );
		self waittill( "trigger", trigger_player ); //working

		if ( isDefined( level.pap_grab_by_anyone ) && level.pap_grab_by_anyone )
		{
			player = trigger_player;
		}

		packa_timer stoploopsound( 0.05 );
		if ( trigger_player == player ) //working
		{
			player maps/mp/zombies/_zm_stats::increment_client_stat( "pap_weapon_grabbed" );
			player maps/mp/zombies/_zm_stats::increment_player_stat( "pap_weapon_grabbed" );
			current_weapon = player getcurrentweapon();
			/*
/#
			if ( current_weapon == "none" )
			{
				iprintlnbold( "WEAPON IS NONE, PACKAPUNCH RETRIEVAL DENIED" );
#/
			}
			*/
			if ( is_player_valid( player ) && !player.is_drinking > 0 && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && level.revive_tool != current_weapon && current_weapon != "none" && !player hacker_active() )
			{
				maps/mp/_demo::bookmark( "zm_player_grabbed_packapunch", getTime(), player );
				self notify( "pap_taken" );
				player notify( "pap_taken" );
				player.pap_used = 1;
				if ( isDefined( upgrade_as_attachment ) && !upgrade_as_attachment )
				{
					player thread do_player_general_vox( "general", "pap_arm", 15, 100 );
				}
				else
				{
					player thread do_player_general_vox( "general", "pap_arm2", 15, 100 );
				}
				weapon_limit = get_player_weapon_limit( player );
				player maps/mp/zombies/_zm_weapons::take_fallback_weapon();
				primaries = player getweaponslistprimaries();
				if ( isDefined( primaries ) && primaries.size >= weapon_limit )
				{
					player maps/mp/zombies/_zm_weapons::weapon_give( upgrade_weapon );
				}
				else
				{
					player giveweapon( upgrade_weapon, 0, player maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( upgrade_weapon ) );
					player givestartammo( upgrade_weapon );
				}
				player switchtoweapon( upgrade_weapon );
				if ( isDefined( player.restore_ammo ) && player.restore_ammo )
				{
					new_clip = player.restore_clip + ( weaponclipsize( upgrade_weapon ) - player.restore_clip_size );
					new_stock = player.restore_stock + ( weaponmaxammo( upgrade_weapon ) - player.restore_max );
					player setweaponammostock( upgrade_weapon, new_stock );
					player setweaponammoclip( upgrade_weapon, new_clip );
				}
				player.restore_ammo = undefined;
				player.restore_clip = undefined;
				player.restore_stock = undefined;
				player.restore_max = undefined;
				player.restore_clip_size = undefined;
				player maps/mp/zombies/_zm_weapons::play_weapon_vo( upgrade_weapon );
				return;
			}
		}
		wait 0.05;
	}
}

wait_for_timeout( weapon, packa_timer, player ) //checked
{
	self endon( "pap_taken" );
	self endon( "pap_player_disconnected" );
	self thread wait_for_disconnect( player );
	wait level.packapunch_timeout;
	self notify( "pap_timeout" );
	packa_timer stoploopsound( 0.05 );
	packa_timer playsound( "zmb_perks_packa_deny" );
	maps/mp/zombies/_zm_weapons::unacquire_weapon_toggle( weapon );
	if ( isDefined( player ) )
	{
		player maps/mp/zombies/_zm_stats::increment_client_stat( "pap_weapon_not_grabbed" );
		player maps/mp/zombies/_zm_stats::increment_player_stat( "pap_weapon_not_grabbed" );
	}
}

wait_for_disconnect( player ) //checked
{
	self endon( "pap_taken" );
	self endon( "pap_timeout" );
	while ( isDefined( player ) )
	{
		wait 0.1;
	}
	/*
/#
	println( "*** PAP : User disconnected." );
#/
	*/
	self notify( "pap_player_disconnected" );
}

destroy_weapon_on_disconnect( player ) //checked
{
	self endon( "pap_timeout" );
	self endon( "pap_taken" );
	level endon( "Pack_A_Punch_off" );
	player waittill( "disconnect" );
	if ( isDefined( self.worldgun ) )
	{
		if ( isDefined( self.worldgun.worldgundw ) )
		{
			self.worldgun.worldgundw delete();
		}
		self.worldgun delete();
	}
}

destroy_weapon_in_blackout( player ) //checked
{
	self endon( "pap_timeout" );
	self endon( "pap_taken" );
	self endon( "pap_player_disconnected" );
	level waittill( "Pack_A_Punch_off" );
	if ( isDefined( self.worldgun ) )
	{
		self.worldgun rotateto( self.worldgun.angles + ( randomint( 90 ) - 45, 0, randomint( 360 ) - 180 ), 1.5, 0, 0 );
		player playlocalsound( level.zmb_laugh_alias );
		wait 1.5;
		if ( isDefined( self.worldgun.worldgundw ) )
		{
			self.worldgun.worldgundw delete();
		}
		self.worldgun delete();
	}
}

do_knuckle_crack() //checked
{
	self endon( "disconnect" );
	gun = self upgrade_knuckle_crack_begin();
	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );
	self upgrade_knuckle_crack_end( gun );
}

upgrade_knuckle_crack_begin()
{
	self increment_is_drinking();
	self disable_player_move_states( 1 );
	primaries = self getweaponslistprimaries();
	gun = self getcurrentweapon();
	weapon = level.machine_assets[ "packapunch" ].weapon;
	if ( gun != "none" && !is_placeable_mine( gun ) && !is_equipment( gun ) )
	{
		self notify( "zmb_lost_knife" );
		self takeweapon( gun );
	}
	else
	{
		return;
	}
	self giveweapon( weapon );
	self switchtoweapon( weapon );
	return gun;
}

upgrade_knuckle_crack_end( gun ) //changed
{
/*
/#
	assert( !is_zombie_perk_bottle( gun ) );
#/
/#
	assert( gun != level.revive_tool );
#/
*/
	self enable_player_move_states();
	weapon = level.machine_assets[ "packapunch" ].weapon;
	if ( self maps/mp/zombies/_zm_laststand::player_is_in_laststand() || isDefined( self.intermission ) && self.intermission )
	{
		self takeweapon( weapon );
		return;
	}
	self decrement_is_drinking();
	self takeweapon( weapon );
	primaries = self getweaponslistprimaries();
	if ( self.is_drinking > 0 )
	{
		return;
	}
	else if ( isDefined( primaries ) && primaries.size > 0 )
	{
		self switchtoweapon( primaries[ 0 ] );
	}
	else if ( self hasweapon( level.laststandpistol ) )
	{
		self switchtoweapon( level.laststandpistol );
	}
	else
	{
		self maps/mp/zombies/_zm_weapons::give_fallback_weapon();
	}
}

turn_packapunch_on()
{
	vending_weapon_upgrade_trigger = getentarray( "specialty_weapupgrade", "script_noteworthy" );
	level.pap_triggers = vending_weapon_upgrade_trigger;
	i = 0;
	while ( i < vending_weapon_upgrade_trigger.size )
	{
		perk = getent( vending_weapon_upgrade_trigger[ i ].target, "targetname" );
		if ( isDefined( perk ) )
		{
			perk setmodel( level.machine_assets[ "packapunch" ].off_model );
		}
		i++;
	}
	for ( ;; )
	{
		level waittill( "Pack_A_Punch_on" );
		i = 0;
		while ( i < vending_weapon_upgrade_trigger.size )
		{
			perk = getent( vending_weapon_upgrade_trigger[ i ].target, "targetname" );
			if ( isDefined( perk ) )
			{
				perk thread activate_packapunch();
			}
			i++;
		}
		level waittill( "Pack_A_Punch_off" );
		i = 0;
		while ( i < vending_weapon_upgrade_trigger.size )
		{
			perk = getent( vending_weapon_upgrade_trigger[ i ].target, "targetname" );
			if ( isDefined( perk ) )
			{
				perk thread deactivate_packapunch();
			}
			i++;
		}
	}
}

activate_packapunch()
{
	self setmodel( level.machine_assets[ "packapunch" ].on_model );
	self playsound( "zmb_perks_power_on" );
	self vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
	timer = 0;
	duration = 0.05;
}

deactivate_packapunch()
{
	self setmodel( level.machine_assets[ "packapunch" ].off_model );
}

do_initial_power_off_callback( machine_array, perkname )
{
	if ( !isDefined( level.machine_assets[ perkname ] ) )
	{
	/*
/#
		println( "Error: doing setup for a machine with no level.machine_assets! Check your perk initialization!" );
#/
	*/
		return;
	}
	if ( !isDefined( level.machine_assets[ perkname ].power_off_callback ) )
	{
		return;
	}
	wait 0.05;
	array_thread( machine_array, level.machine_assets[ perkname ].power_off_callback );
}

turn_sleight_on()
{
	while ( 1 )
	{
		machine = getentarray( "vending_sleight", "targetname" );
		machine_triggers = getentarray( "vending_sleight", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "speedcola" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "speedcola" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "sleight_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "speedcola" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "sleight_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "speedcola" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "speedcola" ].power_on_callback );
		}
		level notify( "specialty_fastreload_power_on" );
		level waittill( "sleight_off" );
		array_thread( machine, ::turn_perk_off );
		if ( isDefined( level.machine_assets[ "speedcola" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "speedcola" ].power_off_callback );
		}
	}
}

use_solo_revive()
{
	if ( isDefined( level.using_solo_revive ) )
	{
		return level.using_solo_revive;
	}
	players = get_players();
	solo_mode = 0;
	if ( players.size == 1 || isDefined( level.force_solo_quick_revive ) && level.force_solo_quick_revive )
	{
		solo_mode = 1;
	}
	level.using_solo_revive = solo_mode;
	return solo_mode;
}

turn_revive_on()
{
	level endon( "stop_quickrevive_logic" );
	machine = getentarray( "vending_revive", "targetname" );
	machine_triggers = getentarray( "vending_revive", "target" );
	machine_model = undefined;
	machine_clip = undefined;
	if ( isDefined( level.zombiemode_using_revive_perk ) && !level.zombiemode_using_revive_perk )
	{
		return;
	}
	flag_wait( "start_zombie_round_logic" );
	players = get_players();
	solo_mode = 0;
	if ( use_solo_revive() )
	{
		solo_mode = 1;
	}
	start_state = 0;
	start_state = solo_mode;
	while ( 1 )
	{
		machine = getentarray( "vending_revive", "targetname" );
		machine_triggers = getentarray( "vending_revive", "target" );
		i = 0;
		while ( i < machine.size )
		{
			if ( flag_exists( "solo_game" ) && flag_exists( "solo_revive" ) && flag( "solo_game" ) && flag( "solo_revive" ) )
			{
				machine[ i ] hide();
			}
			machine[ i ] setmodel( level.machine_assets[ "revive" ].off_model );
			if ( isDefined( level.quick_revive_final_pos ) )
			{
				level.quick_revive_default_origin = level.quick_revive_final_pos;
			}
			if ( !isDefined( level.quick_revive_default_origin ) )
			{
				level.quick_revive_default_origin = machine[ i ].origin;
				level.quick_revive_default_angles = machine[ i ].angles;
			}
			level.quick_revive_machine = machine[ i ];
			i++;
		}
		array_thread( machine_triggers, ::set_power_on, 0 );
		if ( isDefined( start_state ) && !start_state )
		{
			level waittill( "revive_on" );
		}
		start_state = 0;
		i = 0;
		while ( i < machine.size )
		{
			if ( isDefined( machine[ i ].classname ) && machine[ i ].classname == "script_model" )
			{
				if ( isDefined( machine[ i ].script_noteworthy ) && machine[ i ].script_noteworthy == "clip" )
				{
					machine_clip = machine[ i ];
					i++;
					continue;
				}
				else
				{
					machine[ i ] setmodel( level.machine_assets[ "revive" ].on_model );
					machine[ i ] playsound( "zmb_perks_power_on" );
					machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
					machine_model = machine[ i ];
					machine[ i ] thread perk_fx( "revive_light" );
					machine[ i ] notify( "stop_loopsound" );
					machine[ i ] thread play_loop_on_machine();
					if ( isDefined( machine_triggers[ i ] ) )
					{
						machine_clip = machine_triggers[ i ].clip;
					}
					if ( isDefined( machine_triggers[ i ] ) )
					{
						blocker_model = machine_triggers[ i ].blocker_model;
					}
				}
			}
			i++;
		}
		wait_network_frame();
		if ( solo_mode && isDefined( machine_model ) && !is_true( machine_model.ishidden ) )
		{
			machine_model thread revive_solo_fx( machine_clip, blocker_model );
		}
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "revive" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "revive" ].power_on_callback );
		}
		level notify( "specialty_quickrevive_power_on" );
		if ( isDefined( machine_model ) )
		{
			machine_model.ishidden = 0;
		}
		notify_str = level waittill_any_return( "revive_off", "revive_hide" );
		should_hide = 0;
		if ( notify_str == "revive_hide" )
		{
			should_hide = 1;
		}
		if ( isDefined( level.machine_assets[ "revive" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "revive" ].power_off_callback );
		}
		i = 0;
		while ( i < machine.size )
		{
			if ( isDefined( machine[ i ].classname ) && machine[ i ].classname == "script_model" )
			{
				machine[ i ] turn_perk_off( should_hide );
			}
			i++;
		}
	}
}

revive_solo_fx( machine_clip, blocker_model )
{
	if ( level flag_exists( "solo_revive" ) && flag( "solo_revive" ) && !flag( "solo_game" ) )
	{
		return;
	}
	if ( isDefined( machine_clip ) )
	{
		level.quick_revive_machine_clip = machine_clip;
	}
	if ( !isDefined( level.solo_revive_init ) )
	{
		level.solo_revive_init = 1;
		flag_init( "solo_revive" );
	}
	level notify( "revive_solo_fx" );
	level endon( "revive_solo_fx" );
	self endon( "death" );
	flag_wait( "solo_revive" );
	if ( isDefined( level.revive_solo_fx_func ) )
	{
		level thread [[ level.revive_solo_fx_func ]]();
	}
	wait 2;
	self playsound( "zmb_box_move" );
	playsoundatposition( "zmb_whoosh", self.origin );
	if ( isDefined( self._linked_ent ) )
	{
		self unlink();
	}
	self moveto( self.origin + vectorScale( ( 0, 0, 1 ), 40 ), 3 );
	if ( isDefined( level.custom_vibrate_func ) )
	{
		[[ level.custom_vibrate_func ]]( self );
	}
	else
	{
		direction = self.origin;
		direction = ( direction[ 1 ], direction[ 0 ], 0 );
		if ( direction[ 1 ] < 0 || direction[ 0 ] > 0 && direction[ 1 ] > 0 )
		{
			direction = ( direction[ 0 ], direction[ 1 ] * -1, 0 );
		}
		else
		{
			if ( direction[ 0 ] < 0 )
			{
				direction = ( direction[ 0 ] * -1, direction[ 1 ], 0 );
			}
		}
		self vibrate( direction, 10, 0.5, 5 );
	}
	self waittill( "movedone" );
	playfx( level._effect[ "poltergeist" ], self.origin );
	playsoundatposition( "zmb_box_poof", self.origin );
	level clientnotify( "drb" );
	if ( isDefined( self.fx ) )
	{
		self.fx unlink();
		self.fx delete();
	}
	if ( isDefined( machine_clip ) )
	{
		machine_clip trigger_off();
		machine_clip connectpaths();
	}
	if ( isDefined( blocker_model ) )
	{
		blocker_model show();
	}
	level notify( "revive_hide" );
}

turn_jugger_on()
{
	while ( 1 )
	{
		machine = getentarray( "vending_jugg", "targetname" );
		machine_triggers = getentarray( "vending_jugg", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "juggernog" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "juggernog" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "juggernog_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "juggernog" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "jugger_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_armorvest_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "juggernog" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "juggernog" ].power_on_callback );
		}
		level waittill( "juggernog_off" );
		if ( isDefined( level.machine_assets[ "juggernog" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "juggernog" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
	}
}

turn_doubletap_on()
{
	while ( 1 )
	{
		machine = getentarray( "vending_doubletap", "targetname" );
		machine_triggers = getentarray( "vending_doubletap", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "doubletap" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "doubletap" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "doubletap_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "doubletap" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "doubletap_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_rof_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "doubletap" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "doubletap" ].power_on_callback );
		}
		level waittill( "doubletap_off" );
		if ( isDefined( level.machine_assets[ "doubletap" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "doubletap" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
	}
}

turn_marathon_on()
{
	while ( 1 )
	{
		machine = getentarray( "vending_marathon", "targetname" );
		machine_triggers = getentarray( "vending_marathon", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "marathon" ].off_model );
			i++;
		}
		array_thread( machine_triggers, ::set_power_on, 0 );
		level thread do_initial_power_off_callback( machine, "marathon" );
		level waittill( "marathon_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "marathon" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "marathon_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_longersprint_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "marathon" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "marathon" ].power_on_callback );
		}
		level waittill( "marathon_off" );
		if ( isDefined( level.machine_assets[ "marathon" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "marathon" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
	}
}

turn_deadshot_on()
{
	while ( 1 )
	{
		machine = getentarray( "vending_deadshot_model", "targetname" );
		machine_triggers = getentarray( "vending_deadshot", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "deadshot" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "deadshot" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "deadshot_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "deadshot" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "deadshot_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_deadshot_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "deadshot" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "deadshot" ].power_on_callback );
		}
		level waittill( "deadshot_off" );
		if ( isDefined( level.machine_assets[ "deadshot" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "deadshot" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
	}
}

turn_tombstone_on()
{
	level endon( "tombstone_removed" );
	while ( 1 )
	{
		machine = getentarray( "vending_tombstone", "targetname" );
		machine_triggers = getentarray( "vending_tombstone", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "tombstone" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "tombstone" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "tombstone_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "tombstone" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "tombstone_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_scavenger_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "tombstone" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "tombstone" ].power_on_callback );
		}
		level waittill( "tombstone_off" );
		if ( isDefined( level.machine_assets[ "tombstone" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "tombstone" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
		players = get_players();
		_a1718 = players;
		_k1718 = getFirstArrayKey( _a1718 );
		while ( isDefined( _k1718 ) )
		{
			player = _a1718[ _k1718 ];
			player.hasperkspecialtytombstone = undefined;
			_k1718 = getNextArrayKey( _a1718, _k1718 );
		}
	}
}

turn_additionalprimaryweapon_on()
{
	while ( 1 )
	{
		machine = getentarray( "vending_additionalprimaryweapon", "targetname" );
		machine_triggers = getentarray( "vending_additionalprimaryweapon", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "additionalprimaryweapon" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "additionalprimaryweapon" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "additionalprimaryweapon_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "additionalprimaryweapon" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "additionalprimaryweapon_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_additionalprimaryweapon_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "additionalprimaryweapon" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "additionalprimaryweapon" ].power_on_callback );
		}
		level waittill( "additionalprimaryweapon_off" );
		if ( isDefined( level.machine_assets[ "additionalprimaryweapon" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "additionalprimaryweapon" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
	}
}

turn_chugabud_on()
{
	maps/mp/zombies/_zm_chugabud::init();
	if ( isDefined( level.vsmgr_prio_visionset_zm_whos_who ) )
	{
		maps/mp/_visionset_mgr::vsmgr_register_info( "visionset", "zm_whos_who", 5000, level.vsmgr_prio_visionset_zm_whos_who, 1, 1 );
	}
	while ( 1 )
	{
		machine = getentarray( "vending_chugabud", "targetname" );
		machine_triggers = getentarray( "vending_chugabud", "target" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "whoswho" ].off_model );
			i++;
		}
		level thread do_initial_power_off_callback( machine, "whoswho" );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( "chugabud_on" );
		i = 0;
		while ( i < machine.size )
		{
			machine[ i ] setmodel( level.machine_assets[ "whoswho" ].on_model );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "tombstone_light" );
			machine[ i ] thread play_loop_on_machine();
			i++;
		}
		level notify( "specialty_finalstand_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "whoswho" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "whoswho" ].power_on_callback );
		}
		level waittill( "chugabud_off" );
		if ( isDefined( level.machine_assets[ "whoswho" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "whoswho" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
		players = get_players();
		_a1819 = players;
		_k1819 = getFirstArrayKey( _a1819 );
		while ( isDefined( _k1819 ) )
		{
			player = _a1819[ _k1819 ];
			player.hasperkspecialtychugabud = undefined;
			_k1819 = getNextArrayKey( _a1819, _k1819 );
		}
	}
}

set_power_on( state )
{
	self.power_on = state;
}

turn_perk_off( ishidden )
{
	self notify( "stop_loopsound" );
	newmachine = spawn( "script_model", self.origin );
	newmachine.angles = self.angles;
	newmachine.targetname = self.targetname;
	if ( is_true( ishidden ) )
	{
		newmachine.ishidden = 1;
		newmachine hide();
	}
	self delete();
}

play_loop_on_machine()
{
	if ( isDefined( level.sndperksacolaloopoverride ) )
	{
		return;
	}
	sound_ent = spawn( "script_origin", self.origin );
	sound_ent playloopsound( "zmb_perks_machine_loop" );
	sound_ent linkto( self );
	self waittill( "stop_loopsound" );
	sound_ent unlink();
	sound_ent delete();
}

perk_fx( fx, turnofffx )
{
	if ( isDefined( turnofffx ) )
	{
		self.perk_fx = 0;
	}
	else
	{
		wait 3;
		if ( isDefined( self ) && !is_true( self.perk_fx ) )
		{
			playfxontag( level._effect[ fx ], self, "tag_origin" );
			self.perk_fx = 1;
		}
	}
}

electric_perks_dialog()
{
	self endon( "death" );
	wait 0.01;
	flag_wait( "start_zombie_round_logic" );
	players = get_players();
	if ( players.size == 1 )
	{
		return;
	}
	self endon( "warning_dialog" );
	level endon( "switch_flipped" );
	timer = 0;
	while ( 1 )
	{
		wait 0.5;
		players = get_players();
		i = 0;
		while ( i < players.size )
		{
			if ( !isDefined( players[ i ] ) )
			{
				i++;
				continue;
			}
			else dist = distancesquared( players[ i ].origin, self.origin );
			if ( dist > 4900 )
			{
				timer = 0;
				i++;
				continue;
			}
			else if ( dist < 4900 && timer < 3 )
			{
				wait 0.5;
				timer++;
			}
			if ( dist < 4900 && timer == 3 )
			{
				if ( !isDefined( players[ i ] ) )
				{
					i++;
					continue;
				}
				else
				{
					players[ i ] thread do_player_vo( "vox_start", 5 );
					wait 3;
					self notify( "warning_dialog" );
					/*
/#
					iprintlnbold( "warning_given" );
#/
					*/
				}
			}
			i++;
		}
	}
}

reset_vending_hint_string()
{
	perk = self.script_noteworthy;
	solo = maps/mp/zombies/_zm_perks::use_solo_revive();
	switch( perk )
	{
		case "specialty_armorvest":
		case "specialty_armorvest_upgrade":
			self sethintstring( &"ZOMBIE_PERK_JUGGERNAUT", self.cost );
			break;
		case "specialty_quickrevive":
		case "specialty_quickrevive_upgrade":
			if ( solo )
			{
				self sethintstring( &"ZOMBIE_PERK_QUICKREVIVE_SOLO", self.cost );
			}
			else
			{
				self sethintstring( &"ZOMBIE_PERK_QUICKREVIVE", self.cost );
			}
			break;
		case "specialty_fastreload":
		case "specialty_fastreload_upgrade":
			self sethintstring( &"ZOMBIE_PERK_FASTRELOAD", self.cost );
			break;
		case "specialty_rof":
		case "specialty_rof_upgrade":
			self sethintstring( &"ZOMBIE_PERK_DOUBLETAP", self.cost );
			break;
		case "specialty_longersprint":
		case "specialty_longersprint_upgrade":
			self sethintstring( &"ZOMBIE_PERK_MARATHON", self.cost );
			break;
		case "specialty_deadshot":
		case "specialty_deadshot_upgrade":
			self sethintstring( &"ZOMBIE_PERK_DEADSHOT", self.cost );
			break;
		case "specialty_additionalprimaryweapon":
		case "specialty_additionalprimaryweapon_upgrade":
			self sethintstring( &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON", self.cost );
			break;
		case "specialty_scavenger":
		case "specialty_scavenger_upgrade":
			self sethintstring( &"ZOMBIE_PERK_TOMBSTONE", self.cost );
			break;
		case "specialty_finalstand":
		case "specialty_finalstand_upgrade":
			self sethintstring( &"ZOMBIE_PERK_CHUGABUD", self.cost );
			break;
		default:
			self sethintstring( ( perk + " Cost: " ) + level.zombie_vars[ "zombie_perk_cost" ] );
	}
	if ( isDefined( level._custom_perks ) )
	{
		if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].cost ) && isDefined( level._custom_perks[ perk ].hint_string ) )
		{
			self sethintstring( level._custom_perks[ perk ].hint_string, level._custom_perks[ perk ].cost );
		}
	}
}

vending_trigger_think() //checked to a degree
{
	self endon( "death" );
	wait 0.01;
	perk = self.script_noteworthy;
	solo = 0;
	start_on = 0;
	level.revive_machine_is_solo = 0;
	
	//fixed
	if( isdefined( perk ) && perk == "specialty_quickrevive" )
	{
		flag_wait("start_zombie_round_logic");
		solo = use_solo_revive();
		self endon("stop_quickrevive_logic");
		level.quick_revive_trigger = self;
		if( solo )
		{
			if(!is_true(level.revive_machine_is_solo))
			{
				start_on = 1;
				players = get_players();
				foreach(player in players)
				{
					if(!isdefined(player.lives))
					{
						player.lives = 0;
					}
				}
				level maps/mp/zombies/_zm::set_default_laststand_pistol(1);
			}
			level.revive_machine_is_solo = 1;
		}
	}
	self sethintstring( &"ZOMBIE_NEED_POWER" );
	self setcursorhint( "HINT_NOICON" );
	self usetriggerrequirelookat();
	cost = level.zombie_vars[ "zombie_perk_cost" ];
	switch( perk )
	{
		case "specialty_armorvest":
		case "specialty_armorvest_upgrade":
			cost = 2500;
			break;
		case "specialty_quickrevive":
		case "specialty_quickrevive_upgrade":
			if ( solo )
			{
				cost = 500;
			}
			else
			{
				cost = 1500;
			}
			break;
		case "specialty_fastreload":
		case "specialty_fastreload_upgrade":
			cost = 3000;
			break;
		case "specialty_rof":
		case "specialty_rof_upgrade":
			cost = 2000;
			break;
		case "specialty_longersprint":
		case "specialty_longersprint_upgrade":
			cost = 2000;
			break;
		case "specialty_deadshot":
		case "specialty_deadshot_upgrade":
			cost = 1500;
			break;
		case "specialty_additionalprimaryweapon":
		case "specialty_additionalprimaryweapon_upgrade":
			cost = 4000;
			break;
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].cost ) )
	{
		cost = level._custom_perks[ perk ].cost;
	}
	self.cost = cost;
	if ( !start_on )
	{
		notify_name = perk + "_power_on";
		level waittill( notify_name );
	}
	start_on = 0;
	if ( !isDefined( level._perkmachinenetworkchoke ) )
	{
		level._perkmachinenetworkchoke = 0;
	}
	else
	{
		level._perkmachinenetworkchoke++;
	}
	i = 0;
	while ( i < level._perkmachinenetworkchoke )
	{
		wait_network_frame();
		i++;
	}
	self thread maps/mp/zombies/_zm_audio::perks_a_cola_jingle_timer();
	self thread check_player_has_perk( perk );
	switch( perk )
	{
		case "specialty_armorvest":
		case "specialty_armorvest_upgrade":
			self sethintstring( &"ZOMBIE_PERK_JUGGERNAUT", cost );
			break;
		case "specialty_quickrevive":
		case "specialty_quickrevive_upgrade":
			if ( solo )
			{
				self sethintstring( &"ZOMBIE_PERK_QUICKREVIVE_SOLO", cost );
			}
			else
			{
				self sethintstring( &"ZOMBIE_PERK_QUICKREVIVE", cost );
			}
			break;
		case "specialty_fastreload":
		case "specialty_fastreload_upgrade":
			self sethintstring( &"ZOMBIE_PERK_FASTRELOAD", cost );
			break;
		case "specialty_rof":
		case "specialty_rof_upgrade":
			self sethintstring( &"ZOMBIE_PERK_DOUBLETAP", cost );
			break;
		case "specialty_longersprint":
		case "specialty_longersprint_upgrade":
			self sethintstring( &"ZOMBIE_PERK_MARATHON", cost );
			break;
		case "specialty_deadshot":
		case "specialty_deadshot_upgrade":
			self sethintstring( &"ZOMBIE_PERK_DEADSHOT", cost );
			break;
		case "specialty_additionalprimaryweapon":
		case "specialty_additionalprimaryweapon_upgrade":
			self sethintstring( &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON", cost );
			break;
		case "specialty_scavenger":
		case "specialty_scavenger_upgrade":
			self sethintstring( &"ZOMBIE_PERK_TOMBSTONE", cost );
			break;
		case "specialty_finalstand":
		case "specialty_finalstand_upgrade":
			self sethintstring( &"ZOMBIE_PERK_CHUGABUD", cost );
			break;
		default:
			self sethintstring( ( perk + " Cost: " ) + level.zombie_vars[ "zombie_perk_cost" ] );
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].hint_string ) )
	{
		self sethintstring( level._custom_perks[ perk ].hint_string, cost );
	}
	for ( ;; )
	{
		self waittill( "trigger", player );
		index = maps/mp/zombies/_zm_weapons::get_player_index( player );
		if ( player maps/mp/zombies/_zm_laststand::player_is_in_laststand() || isDefined( player.intermission ) && player.intermission )
		{
			wait 0.1;
			continue;
		}

		if ( player in_revive_trigger() )
		{
			wait 0.1;
			continue;
		}
		if ( !player maps/mp/zombies/_zm_magicbox::can_buy_weapon() )
		{
			wait 0.1;
			continue;
		}
		if ( player isthrowinggrenade() )
		{
			wait 0.1;
			continue;
		}
		if ( player isswitchingweapons() )
		{
			wait 0.1;
			continue;
		}
		if ( player.is_drinking > 0 )
		{
			wait 0.1;
			continue;
		}
		if ( player hasperk( perk ) || player has_perk_paused( perk ) )
		{
			cheat = 0;
			/*
/#
			if ( getDvarInt( "zombie_cheat" ) >= 5 )
			{
				cheat = 1;
#/
			}
			*/
			if ( cheat != 1 )
			{
				self playsound( "deny" );
				player maps/mp/zombies/_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 1 );
				continue;
			}
		}
		if ( isDefined( level.custom_perk_validation ) )
		{
			valid = self [[ level.custom_perk_validation ]]( player );
			if ( !valid )
			{
				continue;
			}
		}
		current_cost = cost;
		if ( player maps/mp/zombies/_zm_pers_upgrades_functions::is_pers_double_points_active() )
		{
			current_cost = player maps/mp/zombies/_zm_pers_upgrades_functions::pers_upgrade_double_points_cost( current_cost );
		}
		if ( player.score < current_cost )
		{
			self playsound( "evt_perk_deny" );
			player maps/mp/zombies/_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
			continue;
		}
		
		if ( player.num_perks >= player get_player_perk_purchase_limit() )
		{
			self playsound( "evt_perk_deny" );
			player maps/mp/zombies/_zm_audio::create_and_play_dialog( "general", "sigh" );
			continue;
		}
		sound = "evt_bottle_dispense";
		playsoundatposition( sound, self.origin );
		player maps/mp/zombies/_zm_score::minus_to_player_score( current_cost, 1 );
		player.perk_purchased = perk;
		self thread maps/mp/zombies/_zm_audio::play_jingle_or_stinger( self.script_label );
		self thread vending_trigger_post_think( player, perk );
	}
}

vending_trigger_post_think( player, perk ) //something is broken here
{
	player endon( "disconnect" );
	player endon( "end_game" );
	player endon( "perk_abort_drinking" );
	gun = player perk_give_bottle_begin( perk );
	evt = player waittill_any_return( "fake_death", "death", "player_downed", "weapon_change_complete" );
	if ( evt == "weapon_change_complete" )
	{
		player thread wait_give_perk( perk, 1 );
	}
	player perk_give_bottle_end( gun, perk );
	if ( player maps/mp/zombies/_zm_laststand::player_is_in_laststand() || isDefined( player.intermission ) && player.intermission )
	{
		return;
	}
	player notify( "burp" );
	if ( isDefined( level.pers_upgrade_cash_back ) && level.pers_upgrade_cash_back )
	{
		player maps/mp/zombies/_zm_pers_upgrades_functions::cash_back_player_drinks_perk();
	}
	if ( isDefined( level.pers_upgrade_perk_lose ) && level.pers_upgrade_perk_lose )
	{
		player thread maps/mp/zombies/_zm_pers_upgrades_functions::pers_upgrade_perk_lose_bought();
	}
	if ( isDefined( level.perk_bought_func ) )
	{
		player [[ level.perk_bought_func ]]( perk );
	}
	player.perk_purchased = undefined;
	if ( is_false( self.power_on ) )
	{
		wait 1;
		perk_pause( self.script_noteworthy );
	}
	bbprint( "zombie_uses", "playername %s playerscore %d round %d name %s x %f y %f z %f type %s", player.name, player.score, level.round_number, perk, self.origin, "perk" );
}

solo_revive_buy_trigger_move( revive_trigger_noteworthy )
{
	self endon( "death" );
	revive_perk_triggers = getentarray( revive_trigger_noteworthy, "script_noteworthy" );
	_a2384 = revive_perk_triggers;
	_k2384 = getFirstArrayKey( _a2384 );
	while ( isDefined( _k2384 ) )
	{
		revive_perk_trigger = _a2384[ _k2384 ];
		self thread solo_revive_buy_trigger_move_trigger( revive_perk_trigger );
		_k2384 = getNextArrayKey( _a2384, _k2384 );
	}
}

solo_revive_buy_trigger_move_trigger( revive_perk_trigger )
{
	self endon( "death" );
	revive_perk_trigger setinvisibletoplayer( self );
	if ( level.solo_lives_given >= 3 )
	{
		revive_perk_trigger trigger_off();
		if ( isDefined( level._solo_revive_machine_expire_func ) )
		{
			revive_perk_trigger [[ level._solo_revive_machine_expire_func ]]();
		}
		return;
	}
	while ( self.lives > 0 )
	{
		wait 0.1;
	}
	revive_perk_trigger setvisibletoplayer( self );
}

wait_give_perk( perk, bought )
{
	self endon( "player_downed" );
	self endon( "disconnect" );
	self endon( "end_game" );
	self endon( "perk_abort_drinking" );
	self waittill_notify_or_timeout( "burp", 0.5 );
	self give_perk( perk, bought );
}

return_retained_perks()
{
	while ( isDefined( self._retain_perks_array ) )
	{
		keys = getarraykeys( self._retain_perks_array );
		_a2445 = keys;
		_k2445 = getFirstArrayKey( _a2445 );
		while ( isDefined( _k2445 ) )
		{
			perk = _a2445[ _k2445 ];
			if ( isDefined( self._retain_perks_array[ perk ] ) && self._retain_perks_array[ perk ] )
			{
				self give_perk( perk, 0 );
			}
			_k2445 = getNextArrayKey( _a2445, _k2445 );
		}
	}
}

give_perk( perk, bought )
{
	self setperk( perk );
	self.num_perks++;
	if ( isDefined( bought ) && bought )
	{
		self maps/mp/zombies/_zm_audio::playerexert( "burp" );
		if ( isDefined( level.remove_perk_vo_delay ) && level.remove_perk_vo_delay )
		{
			self maps/mp/zombies/_zm_audio::perk_vox( perk );
		}
		else
		{
			self delay_thread( 1.5, ::perk_vox, perk );
		}
		self setblur( 4, 0.1 );
		wait 0.1;
		self setblur( 0, 0.1 );
		self notify( "perk_bought" );
	}
	self perk_set_max_health_if_jugg( perk, 1, 0 );
	if ( isDefined( level.disable_deadshot_clientfield ) && !level.disable_deadshot_clientfield )
	{
		if ( perk == "specialty_deadshot" )
		{
			self setclientfieldtoplayer( "deadshot_perk", 1 );
		}
		else
		{
			if ( perk == "specialty_deadshot_upgrade" )
			{
				self setclientfieldtoplayer( "deadshot_perk", 1 );
			}
		}
	}
	if ( perk == "specialty_scavenger" )
	{
		self.hasperkspecialtytombstone = 1;
	}
	players = get_players();
	if ( use_solo_revive() && perk == "specialty_quickrevive" )
	{
		self.lives = 1;
		if ( !isDefined( level.solo_lives_given ) )
		{
			level.solo_lives_given = 0;
		}
		if ( isDefined( level.solo_game_free_player_quickrevive ) )
		{
			level.solo_game_free_player_quickrevive = undefined;
		}
		else
		{
			level.solo_lives_given++;
		}
		if ( level.solo_lives_given >= 3 )
		{
			flag_set( "solo_revive" );
		}
		self thread solo_revive_buy_trigger_move( perk );
	}
	if ( perk == "specialty_finalstand" )
	{
		self.lives = 1;
		self.hasperkspecialtychugabud = 1;
		self notify( "perk_chugabud_activated" );
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].player_thread_give ) )
	{
		self thread [[ level._custom_perks[ perk ].player_thread_give ]]();
	}
	self set_perk_clientfield( perk, 1 );
	maps/mp/_demo::bookmark( "zm_player_perk", getTime(), self );
	self maps/mp/zombies/_zm_stats::increment_client_stat( "perks_drank" );
	self maps/mp/zombies/_zm_stats::increment_client_stat( perk + "_drank" );
	self maps/mp/zombies/_zm_stats::increment_player_stat( perk + "_drank" );
	self maps/mp/zombies/_zm_stats::increment_player_stat( "perks_drank" );
	if ( !isDefined( self.perk_history ) )
	{
		self.perk_history = [];
	}
	self.perk_history = add_to_array( self.perk_history, perk, 0 );
	if ( !isDefined( self.perks_active ) )
	{
		self.perks_active = [];
	}
	self.perks_active[ self.perks_active.size ] = perk;
	self notify( "perk_acquired" );
	self thread perk_think( perk );
}

perk_set_max_health_if_jugg( perk, set_premaxhealth, clamp_health_to_max_health )
{
	max_total_health = undefined;
	if ( perk == "specialty_armorvest" )
	{
		if ( set_premaxhealth )
		{
			self.premaxhealth = self.maxhealth;
		}
		max_total_health = level.zombie_vars[ "zombie_perk_juggernaut_health" ];
	}
	else if ( perk == "specialty_armorvest_upgrade" )
	{
		if ( set_premaxhealth )
		{
			self.premaxhealth = self.maxhealth;
		}
		max_total_health = level.zombie_vars[ "zombie_perk_juggernaut_health_upgrade" ];
	}
	else if ( perk == "jugg_upgrade" )
	{
		if ( set_premaxhealth )
		{
			self.premaxhealth = self.maxhealth;
		}
		if ( self hasperk( "specialty_armorvest" ) )
		{
			max_total_health = level.zombie_vars[ "zombie_perk_juggernaut_health" ];
		}
		else
		{
			max_total_health = 100;
		}
	}
	else
	{
		if ( perk == "health_reboot" )
		{
			max_total_health = 100;
		}
	}
	if ( isDefined( max_total_health ) )
	{
		if ( self maps/mp/zombies/_zm_pers_upgrades_functions::pers_jugg_active() )
		{
			max_total_health += level.pers_jugg_upgrade_health_bonus;
		}
		self setmaxhealth( max_total_health );
		if ( isDefined( clamp_health_to_max_health ) && clamp_health_to_max_health == 1 )
		{
			if ( self.health > self.maxhealth )
			{
				self.health = self.maxhealth;
			}
		}
	}
}

check_player_has_perk( perk )
{
	self endon( "death" );
	/*
/#
	if ( getDvarInt( "zombie_cheat" ) >= 5 )
	{
		return;
#/
	}
	*/
	dist = 16384;
	while ( 1 )
	{
		players = get_players();
		i = 0;
		while ( i < players.size )
		{
			if ( distancesquared( players[ i ].origin, self.origin ) < dist )
			{
				if ( !players[ i ] hasperk( perk ) && !players[ i ] has_perk_paused( perk ) && !players[ i ] in_revive_trigger() && !is_equipment_that_blocks_purchase( players[ i ] getcurrentweapon() ) && !players[ i ] hacker_active() )
				{
					self setinvisibletoplayer( players[ i ], 0 );
					i++;
					continue;
				}
				else
				{
					self setinvisibletoplayer( players[ i ], 1 );
				}
			}
			i++;
		}
		wait 0.1;
	}
}

vending_set_hintstring( perk )
{
	switch( perk )
	{
		case "specialty_armorvest":
		case "specialty_armorvest_upgrade":
			break;
	}
}

perk_think( perk )
{
/*
/#
	if ( getDvarInt( "zombie_cheat" ) >= 5 )
	{
		if ( isDefined( self.perk_hud[ perk ] ) )
		{
			return;
#/
		}
	}
*/
	perk_str = perk + "_stop";
	result = self waittill_any_return( "fake_death", "death", "player_downed", perk_str );
	do_retain = 1;
	if ( use_solo_revive() && perk == "specialty_quickrevive" )
	{
		do_retain = 0;
	}
	if ( do_retain )
	{
		if ( isDefined( self._retain_perks ) && self._retain_perks )
		{
			return;
		}
		else
		{
			if ( isDefined( self._retain_perks_array ) && isDefined( self._retain_perks_array[ perk ] ) && self._retain_perks_array[ perk ] )
			{
				return;
			}
		}
	}
	self unsetperk( perk );
	self.num_perks--;

	switch( perk )
	{
		case "specialty_armorvest":
			self setmaxhealth( 100 );
			break;
		case "specialty_additionalprimaryweapon":
			if ( result == perk_str )
			{
				self maps/mp/zombies/_zm::take_additionalprimaryweapon();
			}
			break;
		case "specialty_deadshot":
			if ( isDefined( level.disable_deadshot_clientfield ) && !level.disable_deadshot_clientfield )
			{
				self setclientfieldtoplayer( "deadshot_perk", 0 );
			}
			break;
		case "specialty_deadshot_upgrade":
			if ( isDefined( level.disable_deadshot_clientfield ) && !level.disable_deadshot_clientfield )
			{
				self setclientfieldtoplayer( "deadshot_perk", 0 );
			}
			break;
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].player_thread_take ) )
	{
		self thread [[ level._custom_perks[ perk ].player_thread_take ]]();
	}
	self set_perk_clientfield( perk, 0 );
	self.perk_purchased = undefined;
	if ( isDefined( level.perk_lost_func ) )
	{
		self [[ level.perk_lost_func ]]( perk );
	}
	if ( isDefined( self.perks_active ) && isinarray( self.perks_active, perk ) )
	{
		arrayremovevalue( self.perks_active, perk, 0 );
	}
	self notify( "perk_lost" );
}

set_perk_clientfield( perk, state )
{
	switch( perk )
	{
		case "specialty_additionalprimaryweapon":
			self setclientfieldtoplayer( "perk_additional_primary_weapon", state );
			break;
		case "specialty_deadshot":
			self setclientfieldtoplayer( "perk_dead_shot", state );
			break;
		case "specialty_flakjacket":
			self setclientfieldtoplayer( "perk_dive_to_nuke", state );
			break;
		case "specialty_rof":
			self setclientfieldtoplayer( "perk_double_tap", state );
			break;
		case "specialty_armorvest":
			self setclientfieldtoplayer( "perk_juggernaut", state );
			break;
		case "specialty_longersprint":
			self setclientfieldtoplayer( "perk_marathon", state );
			break;
		case "specialty_quickrevive":
			self setclientfieldtoplayer( "perk_quick_revive", state );
			break;
		case "specialty_fastreload":
			self setclientfieldtoplayer( "perk_sleight_of_hand", state );
			break;
		case "specialty_scavenger":
			self setclientfieldtoplayer( "perk_tombstone", state );
			break;
		case "specialty_finalstand":
			self setclientfieldtoplayer( "perk_chugabud", state );
			break;
		case default:
		if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].clientfield_set ) )
		{
			self [[ level._custom_perks[ perk ].clientfield_set ]]( state );
		}
	}
}

perk_hud_destroy( perk )
{
	self.perk_hud[ perk ] destroy_hud();
}

perk_hud_grey( perk, grey_on_off )
{
	if ( grey_on_off )
	{
		self.perk_hud[ perk ].alpha = 0.3;
	}
	else
	{
		self.perk_hud[ perk ].alpha = 1;
	}
}

perk_hud_flash()
{
	self endon( "death" );
	self.flash = 1;
	self scaleovertime( 0.05, 32, 32 );
	wait 0.3;
	self scaleovertime( 0.05, 24, 24 );
	wait 0.3;
	self.flash = 0;
}

perk_flash_audio( perk )
{
	alias = undefined;
	switch( perk )
	{
		case "specialty_armorvest":
			alias = "zmb_hud_flash_jugga";
			break;
		case "specialty_quickrevive":
			alias = "zmb_hud_flash_revive";
			break;
		case "specialty_fastreload":
			alias = "zmb_hud_flash_speed";
			break;
		case "specialty_longersprint":
			alias = "zmb_hud_flash_stamina";
			break;
		case "specialty_flakjacket":
			alias = "zmb_hud_flash_phd";
			break;
		case "specialty_deadshot":
			alias = "zmb_hud_flash_deadshot";
			break;
		case "specialty_additionalprimaryweapon":
			alias = "zmb_hud_flash_additionalprimaryweapon";
			break;
	}
	if ( isDefined( alias ) )
	{
		self playlocalsound( alias );
	}
}

perk_hud_start_flash( perk )
{
	if ( self hasperk( perk ) && isDefined( self.perk_hud ) )
	{
		hud = self.perk_hud[ perk ];
		if ( isDefined( hud ) )
		{
			if ( isDefined( hud.flash ) && !hud.flash )
			{
				hud thread perk_hud_flash();
				self thread perk_flash_audio( perk );
			}
		}
	}
}

perk_hud_stop_flash( perk, taken )
{
	if ( self hasperk( perk ) && isDefined( self.perk_hud ) )
	{
		hud = self.perk_hud[ perk ];
		if ( isDefined( hud ) )
		{
			hud.flash = undefined;
			if ( isDefined( taken ) )
			{
				hud notify( "stop_flash_perk" );
			}
		}
	}
}

perk_give_bottle_begin( perk )
{
	self increment_is_drinking();
	self disable_player_move_states( 1 );
	gun = self getcurrentweapon();
	weapon = "";
	switch( perk )
	{
		case " _upgrade":
		case "specialty_armorvest":
			weapon = level.machine_assets[ "juggernog" ].weapon;
			break;
		case "specialty_quickrevive":
		case "specialty_quickrevive_upgrade":
			weapon = level.machine_assets[ "revive" ].weapon;
			break;
		case "specialty_fastreload":
		case "specialty_fastreload_upgrade":
			weapon = level.machine_assets[ "speedcola" ].weapon;
			break;
		case "specialty_rof":
		case "specialty_rof_upgrade":
			weapon = level.machine_assets[ "doubletap" ].weapon;
			break;
		case "specialty_longersprint":
		case "specialty_longersprint_upgrade":
			weapon = level.machine_assets[ "marathon" ].weapon;
			break;
		case "specialty_flakjacket":
		case "specialty_flakjacket_upgrade":
			weapon = level.machine_assets[ "divetonuke" ].weapon;
			break;
		case "specialty_deadshot":
		case "specialty_deadshot_upgrade":
			weapon = level.machine_assets[ "deadshot" ].weapon;
			break;
		case "specialty_additionalprimaryweapon":
		case "specialty_additionalprimaryweapon_upgrade":
			weapon = level.machine_assets[ "additionalprimaryweapon" ].weapon;
			break;
		case "specialty_scavenger":
		case "specialty_scavenger_upgrade":
			weapon = level.machine_assets[ "tombstone" ].weapon;
			break;
		case "specialty_finalstand":
		case "specialty_finalstand_upgrade":
			weapon = level.machine_assets[ "whoswho" ].weapon;
			break;
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].perk_bottle ) )
	{
		weapon = level._custom_perks[ perk ].perk_bottle;
	}
	self giveweapon( weapon );
	self switchtoweapon( weapon );
	return gun;
}

perk_give_bottle_end( gun, perk ) //changed
{
	self endon( "perk_abort_drinking" );
	/*
/#
	assert( !is_zombie_perk_bottle( gun ) );
#/
/#
	assert( gun != level.revive_tool );
#/
	*/
	self enable_player_move_states();
	weapon = "";
	switch( perk )
	{
		case "specialty_rof":
		case "specialty_rof_upgrade":
			weapon = level.machine_assets[ "doubletap" ].weapon;
			break;
		case "specialty_longersprint":
		case "specialty_longersprint_upgrade":
			weapon = level.machine_assets[ "marathon" ].weapon;
			break;
		case "specialty_flakjacket":
		case "specialty_flakjacket_upgrade":
			weapon = level.machine_assets[ "divetonuke" ].weapon;
			break;
		case "specialty_armorvest":
		case "specialty_armorvest_upgrade":
			weapon = level.machine_assets[ "juggernog" ].weapon;
			self.jugg_used = 1;
			break;
		case "specialty_quickrevive":
		case "specialty_quickrevive_upgrade":
			weapon = level.machine_assets[ "revive" ].weapon;
			break;
		case "specialty_fastreload":
		case "specialty_fastreload_upgrade":
			weapon = level.machine_assets[ "speedcola" ].weapon;
			self.speed_used = 1;
			break;
		case "specialty_deadshot":
		case "specialty_deadshot_upgrade":
			weapon = level.machine_assets[ "deadshot" ].weapon;
			break;
		case "specialty_additionalprimaryweapon":
		case "specialty_additionalprimaryweapon_upgrade":
			weapon = level.machine_assets[ "additionalprimaryweapon" ].weapon;
			break;
		case "specialty_scavenger":
		case "specialty_scavenger_upgrade":
			weapon = level.machine_assets[ "tombstone" ].weapon;
			break;
		case "specialty_finalstand":
		case "specialty_finalstand_upgrade":
			weapon = level.machine_assets[ "whoswho" ].weapon;
			break;
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].perk_bottle ) )
	{
		weapon = level._custom_perks[ perk ].perk_bottle;
	}
	if ( self maps/mp/zombies/_zm_laststand::player_is_in_laststand() || isDefined( self.intermission ) && self.intermission )
	{
		self takeweapon( weapon );
		return;
	}
	self takeweapon( weapon );
	if ( self is_multiple_drinking() )
	{
		self decrement_is_drinking();
		return;
	}
	else if ( gun != "none" && !is_placeable_mine( gun ) && !is_equipment_that_blocks_purchase( gun ) )
	{
		self switchtoweapon( gun );
		if ( is_melee_weapon( gun ) )
		{
			self decrement_is_drinking();
			return;
		}
	}
	else
	{
		primaryweapons = self getweaponslistprimaries();
		if ( isDefined( primaryweapons ) && primaryweapons.size > 0 )
		{
			self switchtoweapon( primaryweapons[ 0 ] );
		}
	}
	self waittill( "weapon_change_complete" ); //event doesn't occur because there is no notifier bug
	self decrement_is_drinking();
	if ( !self maps/mp/zombies/_zm_laststand::player_is_in_laststand() && isDefined( self.intermission ) && !self.intermission )
	{
		self decrement_is_drinking();
	}
}

perk_abort_drinking( post_delay )
{
	if ( self.is_drinking )
	{
		self notify( "perk_abort_drinking" );
		self decrement_is_drinking();
		self enable_player_move_states();
		if ( isDefined( post_delay ) )
		{
			wait post_delay;
		}
	}
}

give_random_perk()
{
	random_perk = undefined;
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	perks = [];
	i = 0;
	while ( i < vending_triggers.size )
	{
		perk = vending_triggers[ i ].script_noteworthy;
		if ( isDefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
			i++;
			continue;
		}
		else
		{
			if ( perk == "specialty_weapupgrade" )
			{
				i++;
				continue;
			}
			else
			{
				if ( !self hasperk( perk ) && !self has_perk_paused( perk ) )
				{
					perks[ perks.size ] = perk;
				}
			}
		}
		i++;
	}
	if ( perks.size > 0 )
	{
		perks = array_randomize( perks );
		random_perk = perks[ 0 ];
		self give_perk( random_perk );
	}
	else
	{
		self playsoundtoplayer( level.zmb_laugh_alias, self );
	}
	return random_perk;
}

lose_random_perk()
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	perks = [];
	i = 0;
	while ( i < vending_triggers.size )
	{
		perk = vending_triggers[ i ].script_noteworthy;
		if ( isDefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
			i++;
			continue;
		}
		else
		{
			if ( self hasperk( perk ) || self has_perk_paused( perk ) )
			{
				perks[ perks.size ] = perk;
			}
		}
		i++;
	}
	if ( perks.size > 0 )
	{
		perks = array_randomize( perks );
		perk = perks[ 0 ];
		perk_str = perk + "_stop";
		self notify( perk_str );
		if ( use_solo_revive() && perk == "specialty_quickrevive" )
		{
			self.lives--;

		}
	}
}

update_perk_hud()
{
	while ( isDefined( self.perk_hud ) )
	{
		keys = getarraykeys( self.perk_hud );
		i = 0;
		while ( i < self.perk_hud.size )
		{
			self.perk_hud[ keys[ i ] ].x = i * 30;
			i++;
		}
	}
}

quantum_bomb_give_nearest_perk_validation( position )
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	range_squared = 32400;
	i = 0;
	while ( i < vending_triggers.size )
	{
		if ( distancesquared( vending_triggers[ i ].origin, position ) < range_squared )
		{
			return 1;
		}
		i++;
	}
	return 0;
}

quantum_bomb_give_nearest_perk_result( position )
{
	[[ level.quantum_bomb_play_mystery_effect_func ]]( position );
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	nearest = 0;
	i = 1;
	while ( i < vending_triggers.size )
	{
		if ( distancesquared( vending_triggers[ i ].origin, position ) < distancesquared( vending_triggers[ nearest ].origin, position ) )
		{
			nearest = i;
		}
		i++;
	}
	players = get_players();
	perk = vending_triggers[ nearest ].script_noteworthy;
	i = 0;
	while ( i < players.size )
	{
		player = players[ i ];
		if ( player.sessionstate == "spectator" || player maps/mp/zombies/_zm_laststand::player_is_in_laststand() )
		{
			i++;
			continue;
		}
		else
		{
			if ( !player hasperk( perk ) && isDefined( player.perk_purchased ) && player.perk_purchased != perk && randomint( 5 ) )
			{
				if ( player == self )
				{
					self thread maps/mp/zombies/_zm_audio::create_and_play_dialog( "kill", "quant_good" );
				}
				player give_perk( perk );
				player [[ level.quantum_bomb_play_player_effect_func ]]();
			}
		}
		i++;
	}
}

perk_pause( perk )
{
	if ( perk == "Pack_A_Punch" || perk == "specialty_weapupgrade" )
	{
		return;
	}
	j = 0;
	while ( j < get_players().size )
	{
		player = get_players()[ j ];
		if ( !isDefined( player.disabled_perks ) )
		{
			player.disabled_perks = [];
		}
		if ( isDefined( player.disabled_perks[ perk ] ) && !player.disabled_perks[ perk ] )
		{
			player.disabled_perks[ perk ] = player hasperk( perk );
		}
		if ( player.disabled_perks[ perk ] )
		{
			player unsetperk( perk );
			player set_perk_clientfield( perk, 2 );
			if ( perk == "specialty_armorvest" || perk == "specialty_armorvest_upgrade" )
			{
				player setmaxhealth( player.premaxhealth );
				if ( player.health > player.maxhealth )
				{
					player.health = player.maxhealth;
				}
			}
			if ( perk == "specialty_additionalprimaryweapon" || perk == "specialty_additionalprimaryweapon_upgrade" )
			{
				player maps/mp/zombies/_zm::take_additionalprimaryweapon();
			}
			if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].player_thread_take ) )
			{
				player thread [[ level._custom_perks[ perk ].player_thread_take ]]();
			}
			/*
/#
			println( " ZM PERKS " + player.name + " paused perk " + perk + "\n" );
#/
			*/
		}
		j++;
	}
}

perk_unpause( perk )
{
	if ( !isDefined( perk ) )
	{
		return;
	}
	if ( perk == "Pack_A_Punch" )
	{
		return;
	}
	j = 0;
	while ( j < get_players().size )
	{
		player = get_players()[ j ];
		if ( isDefined( player.disabled_perks ) && isDefined( player.disabled_perks[ perk ] ) && player.disabled_perks[ perk ] )
		{
			player.disabled_perks[ perk ] = 0;
			player set_perk_clientfield( perk, 1 );
			player setperk( perk );
			/*
/#
			println( " ZM PERKS " + player.name + " unpaused perk " + perk + "\n" );
#/
			*/
			if ( issubstr( perk, "specialty_scavenger" ) )
			{
				player.hasperkspecialtytombstone = 1;
			}
			player perk_set_max_health_if_jugg( perk, 0, 0 );
			if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].player_thread_give ) )
			{
				player thread [[ level._custom_perks[ perk ].player_thread_give ]]();
			}
		}
		j++;
	}
}

perk_pause_all_perks()
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	_a3378 = vending_triggers;
	_k3378 = getFirstArrayKey( _a3378 );
	while ( isDefined( _k3378 ) )
	{
		trigger = _a3378[ _k3378 ];
		maps/mp/zombies/_zm_perks::perk_pause( trigger.script_noteworthy );
		_k3378 = getNextArrayKey( _a3378, _k3378 );
	}
}

perk_unpause_all_perks()
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	_a3388 = vending_triggers;
	_k3388 = getFirstArrayKey( _a3388 );
	while ( isDefined( _k3388 ) )
	{
		trigger = _a3388[ _k3388 ];
		maps/mp/zombies/_zm_perks::perk_unpause( trigger.script_noteworthy );
		_k3388 = getNextArrayKey( _a3388, _k3388 );
	}
}

has_perk_paused( perk )
{
	if ( isDefined( self.disabled_perks ) && isDefined( self.disabled_perks[ perk ] ) && self.disabled_perks[ perk ] )
	{
		return 1;
	}
	return 0;
}

getvendingmachinenotify()
{
	if ( !isDefined( self ) )
	{
		return "";
	}
	switch( self.script_noteworthy )
	{
		case "specialty_armorvest":
		case "specialty_armorvest_upgrade":
			return "juggernog";
		case "specialty_quickrevive":
		case "specialty_quickrevive_upgrade":
			return "revive";
		case "specialty_fastreload":
		case "specialty_fastreload_upgrade":
			return "sleight";
		case "specialty_rof":
		case "specialty_rof_upgrade":
			return "doubletap";
		case "specialty_longersprint":
		case "specialty_longersprint_upgrade":
			return "marathon";
		case "specialty_flakjacket":
		case "specialty_flakjacket_upgrade":
			return "divetonuke";
		case "specialty_deadshot":
		case "specialty_deadshot_upgrade":
			return "deadshot";
		case "specialty_additionalprimaryweapon":
		case "specialty_additionalprimaryweapon_upgrade":
			return "additionalprimaryweapon";
		case "specialty_scavenger":
		case "specialty_scavenger_upgrade":
			return "tombstone";
		case "specialty_finalstand":
		case "specialty_finalstand_upgrade":
			return "chugabud";
		case "specialty_weapupgrade":
			return "Pack_A_Punch";
	}									
	str_perk = undefined;
	if ( isDefined( level._custom_perks[ self.script_noteworthy ] ) && isDefined( isDefined( level._custom_perks[ self.script_noteworthy ].alias ) ) )
	{
		str_perk = level._custom_perks[ self.script_noteworthy ].alias;
	}
	return str_perk;
}

perk_machine_removal( machine, replacement_model )
{
	if ( !isDefined( machine ) )
	{
		return;
	}
	trig = getent( machine, "script_noteworthy" );
	machine_model = undefined;
	if ( isDefined( trig ) )
	{
		trig notify( "warning_dialog" );
		while ( isDefined( trig.target ) )
		{
			parts = getentarray( trig.target, "targetname" );
			i = 0;
			while ( i < parts.size )
			{
				if ( isDefined( parts[ i ].classname ) && parts[ i ].classname == "script_model" )
				{
					machine_model = parts[ i ];
					i++;
					continue;
				}
				else
				{
					if ( parts[ i ].script_noteworthy )
					{
						if ( isDefined( parts[ i ].script_noteworthy == "clip" ) )
						{
							model_clip = parts[ i ];
						}
						i++;
						continue;
					}
					else
					{
						parts[ i ] delete();
					}
				}
				i++;
			}
		}
		if ( isDefined( replacement_model ) && isDefined( machine_model ) )
		{
			machine_model setmodel( replacement_model );
		}
		else
		{
			if ( !isDefined( replacement_model ) && isDefined( machine_model ) )
			{
				machine_model delete();
				if ( isDefined( model_clip ) )
				{
					model_clip delete();
				}
				if ( isDefined( trig.clip ) )
				{
					trig.clip delete();
				}
			}
		}
		if ( isDefined( trig.bump ) )
		{
			trig.bump delete();
		}
		trig delete();
	}
}

perk_machine_spawn_init()
{
	match_string = "";

	location = level.scr_zm_map_start_location;
	if ((location == "default" || location == "" ) && IsDefined(level.default_start_location))
	{
		location = level.default_start_location;
	}		

	match_string = level.scr_zm_ui_gametype + "_perks_" + location;
	pos = [];
	structs = getstructarray("zm_perk_machine", "targetname");
	_a3578 = structs;
	_k3578 = getFirstArrayKey( _a3578 );
	while ( isDefined( _k3578 ) )
	{
		struct = _a3578[ _k3578 ];
		if ( isDefined( struct.script_string ) )
		{
			tokens = strtok( struct.script_string, " " );
			_a3583 = tokens;
			_k3583 = getFirstArrayKey( _a3583 );
			while ( isDefined( _k3583 ) )
			{
				token = _a3583[ _k3583 ];
				if ( token == match_string )
				{
					pos[ pos.size ] = struct;
				}
				_k3583 = getNextArrayKey( _a3583, _k3583 );
			}
		}
		else
		{
			pos[ pos.size ] = struct;
		}
		_k3578 = getNextArrayKey( _a3578, _k3578 );
	}
	
	if(!IsDefined(pos) || pos.size == 0)
	{
		return;
	}
	if ( level.script == "zm_prison" && is_classic() )
	{
		posSizeOffset = pos.size - 4;
	}
	PreCacheModel("zm_collision_perks1");
	//everything above the for loop works
	//broken

	for ( i = 0; i < posSizeOffset; i++ )
	{
		perk = pos[i].script_noteworthy;
		if(IsDefined(perk) && IsDefined(pos[i].model))
		{
			use_trigger = Spawn( "trigger_radius_use", pos[i].origin + (0, 0, 30), 0, 40, 70 );
			use_trigger.targetname = "zombie_vending";			
			use_trigger.script_noteworthy = perk;
			use_trigger TriggerIgnoreTeam();
			//use_trigger thread debug_spot();
	
			perk_machine = Spawn("script_model", pos[i].origin);
			perk_machine.angles = pos[i].angles;
			perk_machine SetModel(pos[i].model);
				
			bump_trigger = Spawn( "trigger_radius", pos[i].origin, 0, 35, 64);
			bump_trigger.script_activated = 1;
			bump_trigger.script_sound = "zmb_perks_bump_bottle";
			bump_trigger.targetname = "audio_bump_trigger";
			
			if( perk != "specialty_weapupgrade" )
			{
				bump_trigger thread thread_bump_trigger();
			}
				
			collision = Spawn("script_model", pos[i].origin, 1);
			collision.angles = pos[i].angles;
			collision SetModel("zm_collision_perks1");
			collision.script_noteworthy = "clip";
			collision DisconnectPaths();
			
			// Connect all of the pieces for easy access.
			use_trigger.clip = collision;
			use_trigger.machine = perk_machine;
			use_trigger.bump = bump_trigger;

			switch( perk )
			{
				case "specialty_quickrevive":
				case "specialty_quickrevive_upgrade":
					use_trigger.script_sound = "mus_perks_revive_jingle";
					use_trigger.script_string = "revive_perk";
					use_trigger.script_label = "mus_perks_revive_sting";
					use_trigger.target = "vending_revive";
					perk_machine.script_string = "revive_perk";
					perk_machine.targetname = "vending_revive";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "revive_perk";
					}
					break;
				case "specialty_fastreload":
				case "specialty_fastreload_upgrade":
					use_trigger.script_sound = "mus_perks_speed_jingle";
					use_trigger.script_string = "speedcola_perk";
					use_trigger.script_label = "mus_perks_speed_sting";
					use_trigger.target = "vending_sleight";
					perk_machine.script_string = "speedcola_perk";
					perk_machine.targetname = "vending_sleight";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "speedcola_perk";
					}
					break;
				case "specialty_longersprint":
				case "specialty_longersprint_upgrade":
					use_trigger.script_sound = "mus_perks_stamin_jingle";
					use_trigger.script_string = "marathon_perk";
					use_trigger.script_label = "mus_perks_stamin_sting";
					use_trigger.target = "vending_marathon";
					perk_machine.script_string = "marathon_perk";
					perk_machine.targetname = "vending_marathon";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "marathon_perk";
					}
					break;
				case "specialty_armorvest":
				case "specialty_armorvest_upgrade":
					use_trigger.script_sound = "mus_perks_jugganog_jingle";
					use_trigger.script_string = "jugg_perk";
					use_trigger.script_label = "mus_perks_jugganog_sting";
					use_trigger.longjinglewait = 1;
					use_trigger.target = "vending_jugg";
					perk_machine.script_string = "jugg_perk";
					perk_machine.targetname = "vending_jugg";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "jugg_perk";
					}
					break;
				case "specialty_scavenger":
				case "specialty_scavenger_upgrade":
					use_trigger.script_sound = "mus_perks_tombstone_jingle";
					use_trigger.script_string = "tombstone_perk";
					use_trigger.script_label = "mus_perks_tombstone_sting";
					use_trigger.target = "vending_tombstone";
					perk_machine.script_string = "tombstone_perk";
					perk_machine.targetname = "vending_tombstone";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "tombstone_perk";
					}
					break;
				case "specialty_rof":
				case "specialty_rof_upgrade":
					use_trigger.script_sound = "mus_perks_doubletap_jingle";
					use_trigger.script_string = "tap_perk";
					use_trigger.script_label = "mus_perks_doubletap_sting";
					use_trigger.target = "vending_doubletap";
					perk_machine.script_string = "tap_perk";
					perk_machine.targetname = "vending_doubletap";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "tap_perk";
					}
					break;
				case "specialty_finalstand":
				case "specialty_finalstand_upgrade":
					use_trigger.script_sound = "mus_perks_whoswho_jingle";
					use_trigger.script_string = "tap_perk";
					use_trigger.script_label = "mus_perks_whoswho_sting";
					use_trigger.target = "vending_chugabud";
					perk_machine.script_string = "tap_perk";
					perk_machine.targetname = "vending_chugabud";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "tap_perk";
					}
					break;
				case "specialty_additionalprimaryweapon":
				case "specialty_additionalprimaryweapon_upgrade":
					use_trigger.script_sound = "mus_perks_mulekick_jingle";
					use_trigger.script_string = "tap_perk";
					use_trigger.script_label = "mus_perks_mulekick_sting";
					use_trigger.target = "vending_additionalprimaryweapon";
					perk_machine.script_string = "tap_perk";
					perk_machine.targetname = "vending_additionalprimaryweapon";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "tap_perk";
					}
					break;
				case "specialty_weapupgrade":
					use_trigger.target = "vending_packapunch";
					use_trigger.script_sound = "mus_perks_packa_jingle";
					use_trigger.script_label = "mus_perks_packa_sting";
					use_trigger.longjinglewait = 1;
					perk_machine.targetname = "vending_packapunch";
					flag_pos = getstruct( pos[ i ].target, "targetname" );
					if ( isDefined( flag_pos ) )
					{
						perk_machine_flag = spawn( "script_model", flag_pos.origin );
						perk_machine_flag.angles = flag_pos.angles;
						perk_machine_flag setmodel( flag_pos.model );
						perk_machine_flag.targetname = "pack_flag";
						perk_machine.target = "pack_flag";
					}
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "perks_rattle";
					}
					break;
				case "specialty_deadshot":
				case "specialty_deadshot_upgrade":
					use_trigger.script_sound = "mus_perks_deadshot_jingle";
					use_trigger.script_string = "deadshot_perk";
					use_trigger.script_label = "mus_perks_deadshot_sting";
					use_trigger.target = "vending_deadshot";
					perk_machine.script_string = "deadshot_vending";
					perk_machine.targetname = "vending_deadshot_model";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "deadshot_vending";
					}
					break;
				case default:
					use_trigger.script_sound = "mus_perks_speed_jingle";
					use_trigger.script_string = "speedcola_perk";
					use_trigger.script_label = "mus_perks_speed_sting";
					use_trigger.target = "vending_sleight";
					perk_machine.script_string = "speedcola_perk";
					perk_machine.targetname = "vending_sleight";
					if ( isDefined( bump_trigger ) )
					{
						bump_trigger.script_string = "speedcola_perk";
					}
					break;
			}
		}
		if(isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].perk_machine_set_kvps))
		{
			[[level._custom_perks[perk].perk_machine_set_kvps]](use_trigger, perk_machine, bump_trigger, collision);
		}
	}	
}	

get_perk_machine_start_state( perk )
{
	if ( isDefined( level.vending_machines_powered_on_at_start ) && level.vending_machines_powered_on_at_start )
	{
		return 1;
	}
	if ( perk == "specialty_quickrevive" || perk == "specialty_quickrevive_upgrade" )
	{
	/*
/#
		assert( isDefined( level.revive_machine_is_solo ) );
#/
	*/
		return level.revive_machine_is_solo;
	}
	return 0;
}

perks_register_clientfield()
{
	if ( isDefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
	{
		registerclientfield( "toplayer", "perk_additional_primary_weapon", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
	{
		registerclientfield( "toplayer", "perk_dead_shot", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
	{
		registerclientfield( "toplayer", "perk_double_tap", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
	{
		registerclientfield( "toplayer", "perk_juggernaut", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
	{
		registerclientfield( "toplayer", "perk_marathon", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
	{
		registerclientfield( "toplayer", "perk_quick_revive", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
	{
		registerclientfield( "toplayer", "perk_sleight_of_hand", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
	{
		registerclientfield( "toplayer", "perk_tombstone", 1, 2, "int" );
	}
	if ( isDefined( level.zombiemode_using_perk_intro_fx ) && level.zombiemode_using_perk_intro_fx )
	{
		registerclientfield( "scriptmover", "clientfield_perk_intro_fx", 1000, 1, "int" );
	}
	if ( isDefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
	{
		registerclientfield( "toplayer", "perk_chugabud", 1000, 1, "int" );
	}
	if(isdefined(level._custom_perks))
	{
		a_keys = getarraykeys(level._custom_perks);
		for(i = 0; i < a_keys.size; i++)
		{
			if(isdefined(level._custom_perks[ a_keys[ i ] ].clientfield_register))
			{
				level [[level._custom_perks[ a_keys[ i ] ].clientfield_register]]();
			}
		}
	}
}

thread_bump_trigger()
{
	for ( ;; )
	{
		self waittill( "trigger", trigplayer );
		trigplayer playsound( self.script_sound );
		while ( is_player_valid( trigplayer ) && trigplayer istouching( self ) )
		{
			wait 0.5;
		}
	}
}

reenable_quickrevive( machine_clip, solo_mode )
{
	if ( isDefined( level.revive_machine_spawned ) && !is_true( level.revive_machine_spawned ) )
	{
		return;
	}
	wait 0.1;
	power_state = 0;
	if ( is_true( solo_mode ) )
	{
		power_state = 1;
		should_pause = 1;
		players = get_players();
		_a3918 = players;
		_k3918 = getFirstArrayKey( _a3918 );
		while ( isDefined( _k3918 ) )
		{
			player = _a3918[ _k3918 ];
			if ( isDefined( player.lives ) && player.lives > 0 && power_state )
			{
				should_pause = 0;
			}
			else
			{
				if ( isDefined( player.lives ) && player.lives < 1 )
				{
					should_pause = 1;
				}
			}
			_k3918 = getNextArrayKey( _a3918, _k3918 );
		}
		if ( should_pause )
		{
			perk_pause( "specialty_quickrevive" );
		}
		else
		{
			perk_unpause( "specialty_quickrevive" );
		}
		if ( isDefined( level.solo_revive_init ) && level.solo_revive_init && flag( "solo_revive" ) )
		{
			disable_quickrevive( machine_clip );
			return;
		}
		update_quickrevive_power_state( 1 );
		unhide_quickrevive();
		restart_quickrevive();
		level notify( "revive_off" );
		wait 0.1;
		level notify( "stop_quickrevive_logic" );
	}
	else
	{
		if ( isDefined( level._dont_unhide_quickervive_on_hotjoin ) && !level._dont_unhide_quickervive_on_hotjoin )
		{
			unhide_quickrevive();
			level notify( "revive_off" );
			wait 0.1;
		}
		level notify( "revive_hide" );
		level notify( "stop_quickrevive_logic" );
		restart_quickrevive();
		if ( flag( "power_on" ) )
		{
			power_state = 1;
		}
		update_quickrevive_power_state( power_state );
	}
	level thread turn_revive_on();
	if ( power_state )
	{
		perk_unpause( "specialty_quickrevive" );
		level notify( "revive_on" );
		wait 0.1;
		level notify( "specialty_quickrevive_power_on" );
	}
	else
	{
		perk_pause( "specialty_quickrevive" );
	}
	if ( !is_true( solo_mode ) )
	{
		return;
	}
	should_pause = 1;
	players = get_players();
	_a3996 = players;
	_k3996 = getFirstArrayKey( _a3996 );
	while ( isDefined( _k3996 ) )
	{
		player = _a3996[ _k3996 ];
		if ( !is_player_valid( player ) )
		{
		}
		else if ( player hasperk( "specialty_quickrevive" ) )
		{
			if ( !isDefined( player.lives ) )
			{
				player.lives = 0;
			}
			if ( !isDefined( level.solo_lives_given ) )
			{
				level.solo_lives_given = 0;
			}
			level.solo_lives_given++;
			player.lives++;
			if ( isDefined( player.lives ) && player.lives > 0 && power_state )
			{
				should_pause = 0;
				break;
			}
			else
			{
				should_pause = 1;
			}
		}
		_k3996 = getNextArrayKey( _a3996, _k3996 );
	}
	if ( should_pause )
	{
		perk_pause( "specialty_quickrevive" );
	}
	else
	{
		perk_unpause( "specialty_quickrevive" );
	}
}

update_quickrevive_power_state( poweron )
{
	_a4034 = level.powered_items;
	_k4034 = getFirstArrayKey( _a4034 );
	while ( isDefined( _k4034 ) )
	{
		item = _a4034[ _k4034 ];
		if ( isDefined( item.target ) && isDefined( item.target.script_noteworthy ) && item.target.script_noteworthy == "specialty_quickrevive" )
		{
			if ( item.power && !poweron )
			{
				if ( !isDefined( item.powered_count ) )
				{
					item.powered_count = 0;
				}
				else
				{
					if ( item.powered_count > 0 )
					{
						item.powered_count--;

					}
				}
			}
			else
			{
				if ( !item.power && poweron )
				{
					if ( !isDefined( item.powered_count ) )
					{
						item.powered_count = 0;
					}
					item.powered_count++;
				}
			}
			if ( !isDefined( item.depowered_count ) )
			{
				item.depowered_count = 0;
			}
			item.power = poweron;
		}
		_k4034 = getNextArrayKey( _a4034, _k4034 );
	}
}

restart_quickrevive()
{
	triggers = getentarray( "zombie_vending", "targetname" );
	_a4074 = triggers;
	_k4074 = getFirstArrayKey( _a4074 );
	while ( isDefined( _k4074 ) )
	{
		trigger = _a4074[ _k4074 ];
		if ( !isDefined( trigger.script_noteworthy ) )
		{
		}
		else
		{
			if ( trigger.script_noteworthy == "specialty_quickrevive" || trigger.script_noteworthy == "specialty_quickrevive_upgrade" )
			{
				trigger notify( "stop_quickrevive_logic" );
				trigger thread vending_trigger_think();
				trigger trigger_on();
			}
		}
		_k4074 = getNextArrayKey( _a4074, _k4074 );
	}
}

disable_quickrevive( machine_clip )
{
	if ( is_true( level.solo_revive_init ) && flag( "solo_revive" ) && isDefined( level.quick_revive_machine ) )
	{
		triggers = getentarray( "zombie_vending", "targetname" );
		_a4096 = triggers;
		_k4096 = getFirstArrayKey( _a4096 );
		while ( isDefined( _k4096 ) )
		{
			trigger = _a4096[ _k4096 ];
			if ( !isDefined( trigger.script_noteworthy ) )
			{
			}
			else
			{
				if ( trigger.script_noteworthy == "specialty_quickrevive" || trigger.script_noteworthy == "specialty_quickrevive_upgrade" )
				{
					trigger trigger_off();
				}
			}
			_k4096 = getNextArrayKey( _a4096, _k4096 );
		}
		_a4108 = level.powered_items;
		_k4108 = getFirstArrayKey( _a4108 );
		while ( isDefined( _k4108 ) )
		{
			item = _a4108[ _k4108 ];
			if ( isDefined( item.target ) && isDefined( item.target.script_noteworthy ) && item.target.script_noteworthy == "specialty_quickrevive" )
			{
				item.power = 1;
				item.self_powered = 1;
			}
			_k4108 = getNextArrayKey( _a4108, _k4108 );
		}
		if ( isDefined( level.quick_revive_machine.original_pos ) )
		{
			level.quick_revive_default_origin = level.quick_revive_machine.original_pos;
			level.quick_revive_default_angles = level.quick_revive_machine.original_angles;
		}
		move_org = level.quick_revive_default_origin;
		if ( isDefined( level.quick_revive_linked_ent ) )
		{
			move_org = level.quick_revive_linked_ent.origin;
			if ( isDefined( level.quick_revive_linked_ent_offset ) )
			{
				move_org += level.quick_revive_linked_ent_offset;
			}
			level.quick_revive_machine unlink();
		}
		level.quick_revive_machine moveto( move_org + vectorScale( ( 0, 0, 1 ), 40 ), 3 );
		direction = level.quick_revive_machine.origin;
		direction = ( direction[ 1 ], direction[ 0 ], 0 );
		if ( direction[ 1 ] < 0 || direction[ 0 ] > 0 && direction[ 1 ] > 0 )
		{
			direction = ( direction[ 0 ], direction[ 1 ] * -1, 0 );
		}
		else
		{
			if ( direction[ 0 ] < 0 )
			{
				direction = ( direction[ 0 ] * -1, direction[ 1 ], 0 );
			}
		}
		level.quick_revive_machine vibrate( direction, 10, 0.5, 4 );
		level.quick_revive_machine waittill( "movedone" );
		level.quick_revive_machine hide();
		level.quick_revive_machine.ishidden = 1;
		if ( isDefined( level.quick_revive_machine_clip ) )
		{
			level.quick_revive_machine_clip connectpaths();
			level.quick_revive_machine_clip trigger_off();
		}
		playfx( level._effect[ "poltergeist" ], level.quick_revive_machine.origin );
		if ( isDefined( level.quick_revive_trigger ) && isDefined( level.quick_revive_trigger.blocker_model ) )
		{
			level.quick_revive_trigger.blocker_model show();
		}
		level notify( "revive_hide" );
	}
}

unhide_quickrevive()
{
	while ( players_are_in_perk_area( level.quick_revive_machine ) )
	{
		wait 0.1;
	}
	if ( isDefined( level.quick_revive_machine_clip ) )
	{
		level.quick_revive_machine_clip trigger_on();
		level.quick_revive_machine_clip disconnectpaths();
	}
	if ( isDefined( level.quick_revive_final_pos ) )
	{
		level.quick_revive_machine.origin = level.quick_revive_final_pos;
	}
	playfx( level._effect[ "poltergeist" ], level.quick_revive_machine.origin );
	if ( isDefined( level.quick_revive_trigger ) && isDefined( level.quick_revive_trigger.blocker_model ) )
	{
		level.quick_revive_trigger.blocker_model hide();
	}
	level.quick_revive_machine show();
	if ( isDefined( level.quick_revive_machine.original_pos ) )
	{
		level.quick_revive_default_origin = level.quick_revive_machine.original_pos;
		level.quick_revive_default_angles = level.quick_revive_machine.original_angles;
	}
	direction = level.quick_revive_machine.origin;
	direction = ( direction[ 1 ], direction[ 0 ], 0 );
	if ( direction[ 1 ] < 0 || direction[ 0 ] > 0 && direction[ 1 ] > 0 )
	{
		direction = ( direction[ 0 ], direction[ 1 ] * -1, 0 );
	}
	else
	{
		if ( direction[ 0 ] < 0 )
		{
			direction = ( direction[ 0 ] * -1, direction[ 1 ], 0 );
		}
	}
	org = level.quick_revive_default_origin;
	if ( isDefined( level.quick_revive_linked_ent ) )
	{
		org = level.quick_revive_linked_ent.origin;
		if ( isDefined( level.quick_revive_linked_ent_offset ) )
		{
			org += level.quick_revive_linked_ent_offset;
		}
	}
	if ( isDefined( level.quick_revive_linked_ent_moves ) && !level.quick_revive_linked_ent_moves && level.quick_revive_machine.origin != org )
	{
		level.quick_revive_machine moveto( org, 3 );
		level.quick_revive_machine vibrate( direction, 10, 0.5, 2.9 );
		level.quick_revive_machine waittill( "movedone" );
		level.quick_revive_machine.angles = level.quick_revive_default_angles;
	}
	else
	{
		if ( isDefined( level.quick_revive_linked_ent ) )
		{
			org = level.quick_revive_linked_ent.origin;
			if ( isDefined( level.quick_revive_linked_ent_offset ) )
			{
				org += level.quick_revive_linked_ent_offset;
			}
			level.quick_revive_machine.origin = org;
		}
		level.quick_revive_machine vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
	}
	if ( isDefined( level.quick_revive_linked_ent ) )
	{
		level.quick_revive_machine linkto( level.quick_revive_linked_ent );
	}
	level.quick_revive_machine.ishidden = 0;
}

players_are_in_perk_area( perk_machine )
{
	perk_area_origin = level.quick_revive_default_origin;
	if ( isDefined( perk_machine._linked_ent ) )
	{
		perk_area_origin = perk_machine._linked_ent.origin;
		if ( isDefined( perk_machine._linked_ent_offset ) )
		{
			perk_area_origin += perk_machine._linked_ent_offset;
		}
	}
	in_area = 0;
	players = get_players();
	dist_check = 9216;
	_a4286 = players;
	_k4286 = getFirstArrayKey( _a4286 );
	while ( isDefined( _k4286 ) )
	{
		player = _a4286[ _k4286 ];
		if ( distancesquared( player.origin, perk_area_origin ) < dist_check )
		{
			return 1;
		}
		_k4286 = getNextArrayKey( _a4286, _k4286 );
	}
	return 0;
}

perk_hostmigration() //changed level._custom_perks
{
	level endon( "end_game" );
	level notify( "perk_hostmigration" );
	level endon( "perk_hostmigration" );
	while ( 1 )
	{
		level waittill( "host_migration_end" );
		jug = getentarray( "vending_jugg", "targetname" );
		tap = getentarray( "vending_doubletap", "targetname" );
		mar = getentarray( "vending_marathon", "targetname" );
		deadshot = getentarray( "vending_deadshot", "targetname" );
		tomb = getentarray( "vending_tombstone", "targetname" );
		extraweap = getentarray( "vending_additionalprimaryweapon", "targetname" );
		sleight = getentarray( "vending_sleight", "targetname" );
		revive = getentarray( "vending_revive", "targetname" );
		chugabud = getentarray( "vending_chugabud", "targetname" );
		_a4321 = jug;
		_k4321 = getFirstArrayKey( _a4321 );
		while ( isDefined( _k4321 ) )
		{
			perk = _a4321[ _k4321 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "juggernog" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "jugger_light" );
			}
			_k4321 = getNextArrayKey( _a4321, _k4321 );
		}
		_a4330 = tap;
		_k4330 = getFirstArrayKey( _a4330 );
		while ( isDefined( _k4330 ) )
		{
			perk = _a4330[ _k4330 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "doubletap" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "doubletap_light" );
			}
			_k4330 = getNextArrayKey( _a4330, _k4330 );
		}
		_a4339 = mar;
		_k4339 = getFirstArrayKey( _a4339 );
		while ( isDefined( _k4339 ) )
		{
			perk = _a4339[ _k4339 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "marathon" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "marathon_light" );
			}
			_k4339 = getNextArrayKey( _a4339, _k4339 );
		}
		_a4348 = deadshot;
		_k4348 = getFirstArrayKey( _a4348 );
		while ( isDefined( _k4348 ) )
		{
			perk = _a4348[ _k4348 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "deadshot" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "deadshot_light" );
			}
			_k4348 = getNextArrayKey( _a4348, _k4348 );
		}
		_a4357 = tomb;
		_k4357 = getFirstArrayKey( _a4357 );
		while ( isDefined( _k4357 ) )
		{
			perk = _a4357[ _k4357 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "tombstone" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "tombstone_light" );
			}
			_k4357 = getNextArrayKey( _a4357, _k4357 );
		}
		_a4366 = extraweap;
		_k4366 = getFirstArrayKey( _a4366 );
		while ( isDefined( _k4366 ) )
		{
			perk = _a4366[ _k4366 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "additionalprimaryweapon" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "additionalprimaryweapon_light" );
			}
			_k4366 = getNextArrayKey( _a4366, _k4366 );
		}
		_a4375 = sleight;
		_k4375 = getFirstArrayKey( _a4375 );
		while ( isDefined( _k4375 ) )
		{
			perk = _a4375[ _k4375 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "speedcola" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "sleight_light" );
			}
			_k4375 = getNextArrayKey( _a4375, _k4375 );
		}
		_a4384 = revive;
		_k4384 = getFirstArrayKey( _a4384 );
		while ( isDefined( _k4384 ) )
		{
			perk = _a4384[ _k4384 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "revive" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "revive_light" );
			}
			_k4384 = getNextArrayKey( _a4384, _k4384 );
		}
		_a4393 = chugabud;
		_k4393 = getFirstArrayKey( _a4393 );
		while ( isDefined( _k4393 ) )
		{
			perk = _a4393[ _k4393 ];
			if ( isDefined( perk.model ) && perk.model == level.machine_assets[ "revive" ].on_model )
			{
				perk perk_fx( undefined, 1 );
				perk thread perk_fx( "tombstone_light" );
			}
			_k4393 = getNextArrayKey( _a4393, _k4393 );
		}
		if(level._custom_perks.size > 0)
		{
			a_keys = getarraykeys(level._custom_perks);
			for(i = 0; i < a_keys.size; i++)
			{
				if(isdefined(level._custom_perks[ a_keys[ i ] ].host_migration_func))
				{
					level thread [[level._custom_perks[ a_keys[ i ] ].host_migration_func]]();
				}
			}
		}
	}
}

get_perk_array( ignore_chugabud ) //changed code relating to level._custom_perks
{
	perk_array = [];
	if ( self hasperk( "specialty_armorvest" ) )
	{
		perk_array[ perk_array.size ] = "specialty_armorvest";
	}
	if ( self hasperk( "specialty_deadshot" ) )
	{
		perk_array[ perk_array.size ] = "specialty_deadshot";
	}
	if ( self hasperk( "specialty_fastreload" ) )
	{
		perk_array[ perk_array.size ] = "specialty_fastreload";
	}
	if ( self hasperk( "specialty_flakjacket" ) )
	{
		perk_array[ perk_array.size ] = "specialty_flakjacket";
	}
	if ( self hasperk( "specialty_longersprint" ) )
	{
		perk_array[ perk_array.size ] = "specialty_longersprint";
	}
	if ( self hasperk( "specialty_quickrevive" ) )
	{
		perk_array[ perk_array.size ] = "specialty_quickrevive";
	}
	if ( self hasperk( "specialty_rof" ) )
	{
		perk_array[ perk_array.size ] = "specialty_rof";
	}
	if ( self hasperk( "specialty_additionalprimaryweapon" ) )
	{
		perk_array[ perk_array.size ] = "specialty_additionalprimaryweapon";
	}
	if ( !isDefined( ignore_chugabud ) || ignore_chugabud == 0 )
	{
		if ( self hasperk( "specialty_finalstand" ) )
		{
			perk_array[ perk_array.size ] = "specialty_finalstand";
		}
	}
	if(level._custom_perks.size > 0)
	{
		a_keys = getarraykeys(level._custom_perks);
		for(i = 0; i < a_keys.size; i++)
		{
			if(self hasperk(a_keys[i]))
			{
				perk_array[perk_array.size] = a_keys[i];
			}
		}
	}
	return perk_array;
}

initialize_custom_perk_arrays()
{
	if ( !isDefined( level._custom_perks ) )
	{
		level._custom_perks = [];
	}
}

register_perk_basic_info( str_perk, str_alias, n_perk_cost, str_hint_string, str_perk_bottle_weapon )
{
/*
/#
	assert( isDefined( str_perk ), "str_perk is a required argument for register_perk_basic_info!" );
#/
/#
	assert( isDefined( str_alias ), "str_alias is a required argument for register_perk_basic_info!" );
#/
/#
	assert( isDefined( n_perk_cost ), "n_perk_cost is a required argument for register_perk_basic_info!" );
#/
/#
	assert( isDefined( str_hint_string ), "str_hint_string is a required argument for register_perk_basic_info!" );
#/
/#
	assert( isDefined( str_perk_bottle_weapon ), "str_perk_bottle_weapon is a required argument for register_perk_basic_info!" );
#/
*/
	_register_undefined_perk( str_perk );
	level._custom_perks[ str_perk ].alias = str_perk;
	level._custom_perks[ str_perk ].cost = n_perk_cost;
	level._custom_perks[ str_perk ].hint_string = str_hint_string;
	level._custom_perks[ str_perk ].perk_bottle = str_perk_bottle_weapon;
}

register_perk_machine( str_perk, func_perk_machine_setup, func_perk_machine_thread )
{
/*
/#
	assert( isDefined( str_perk ), "str_perk is a required argument for register_perk_machine!" );
#/
/#
	assert( isDefined( func_perk_machine_setup ), "func_perk_machine_setup is a required argument for register_perk_machine!" );
#/
/#
	assert( isDefined( func_perk_machine_thread ), "func_perk_machine_thread is a required argument for register_perk_machine!" );
#/
*/
	_register_undefined_perk( str_perk );
	if ( !isDefined( level._custom_perks[ str_perk ].perk_machine_set_kvps ) )
	{
		level._custom_perks[ str_perk ].perk_machine_set_kvps = func_perk_machine_setup;
	}
	if ( !isDefined( level._custom_perks[ str_perk ].perk_machine_thread ) )
	{
		level._custom_perks[ str_perk ].perk_machine_thread = func_perk_machine_thread;
	}
}

register_perk_precache_func( str_perk, func_precache )
{
/*
/#
	assert( isDefined( str_perk ), "str_perk is a required argument for register_perk_precache_func!" );
#/
/#
	assert( isDefined( func_precache ), "func_precache is a required argument for register_perk_precache_func!" );
#/
*/
	_register_undefined_perk( str_perk );
	if ( !isDefined( level._custom_perks[ str_perk ].precache_func ) )
	{
		level._custom_perks[ str_perk ].precache_func = func_precache;
	}
}

register_perk_threads( str_perk, func_give_player_perk, func_take_player_perk )
{
/*
/#
	assert( isDefined( str_perk ), "str_perk is a required argument for register_perk_threads!" );
#/
/#
	assert( isDefined( func_give_player_perk ), "func_give_player_perk is a required argument for register_perk_threads!" );
#/
*/
	_register_undefined_perk( str_perk );
	if ( !isDefined( level._custom_perks[ str_perk ].player_thread_give ) )
	{
		level._custom_perks[ str_perk ].player_thread_give = func_give_player_perk;
	}
	if ( isDefined( func_take_player_perk ) )
	{
		if ( !isDefined( level._custom_perks[ str_perk ].player_thread_take ) )
		{
			level._custom_perks[ str_perk ].player_thread_take = func_take_player_perk;
		}
	}
}

register_perk_clientfields( str_perk, func_clientfield_register, func_clientfield_set )
{
/*
/#
	assert( isDefined( str_perk ), "str_perk is a required argument for register_perk_clientfields!" );
#/
/#
	assert( isDefined( func_clientfield_register ), "func_clientfield_register is a required argument for register_perk_clientfields!" );
#/
/#
	assert( isDefined( func_clientfield_set ), "func_clientfield_set is a required argument for register_perk_clientfields!" );
#/
*/
	_register_undefined_perk( str_perk );
	if ( !isDefined( level._custom_perks[ str_perk ].clientfield_register ) )
	{
		level._custom_perks[ str_perk ].clientfield_register = func_clientfield_register;
	}
	if ( !isDefined( level._custom_perks[ str_perk ].clientfield_set ) )
	{
		level._custom_perks[ str_perk ].clientfield_set = func_clientfield_set;
	}
}

register_perk_host_migration_func( str_perk, func_host_migration )
{
/*
/#
	assert( isDefined( str_perk ), "str_perk is a required argument for register_perk_host_migration_func!" );
#/
/#
	assert( isDefined( func_host_migration ), "func_host_migration is a required argument for register_perk_host_migration_func!" );
#/
*/
	_register_undefined_perk( str_perk );
	if ( !isDefined( level._custom_perks[ str_perk ].host_migration_func ) )
	{
		level._custom_perks[ str_perk ].host_migration_func = func_host_migration;
	}
}

_register_undefined_perk( str_perk )
{
	if ( !isDefined( level._custom_perks ) )
	{
		level._custom_perks = [];
	}
	if ( !isDefined( level._custom_perks[ str_perk ] ) )
	{
		level._custom_perks[ str_perk ] = spawnstruct();
	}
}







