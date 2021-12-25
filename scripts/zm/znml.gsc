#include maps/mp/_utility;
#include maps/mp/gametypes_zm/_hud_util;
#include common_scripts/utility;
#include maps/mp/zombies/_zm_utility;
#include scripts/zm/znml_round_manager;
#include maps/mp/zombies/_zm_spawner;
#include maps/mp/zombies/_zm_magicbox;
#include maps/mp/zombies/_zm_zonemgr;

main()
{
	scr_gametype = getDvar( "scr_gametype" );
	if ( scr_gametype != "" && scr_gametype == "znml" )
	{
		level.ctsm_disable_custom_perk_locations = true;
		replaceFunc( maps/mp/zombies/_zm_utility::init_zombie_run_cycle, ::init_zombie_run_cycle_override );
		//replaceFunc( maps/mp/zombies/_zm_spawner::do_zombie_spawn, ::do_zombie_spawn_override );
		//replaceFunc( maps/mp/zombies/_zm_zonemgr::create_spawner_list, ::create_spawner_list_override );
		//replaceFunc( maps/mp/zombies/_zm_zonemgr::manage_zones, ::manage_zones_override );
		level thread on_player_connect();
		scripts/zm/_gametype_setup::add_struct_location_gamemode_func( "zstandard", "cornfield", ::override_cornfield_perk_locations );
		scripts/zm/_gametype_setup::add_struct_location_gamemode_func( "zstandard", "town", ::override_town_perk_locations );
	}
}

zombie_init_done() //checked matches cerberus output
{
	self.allowpain = 0;
	self.electrified = 1;
}

init_zombie_run_cycle_override()
{
	self set_zombie_run_cycle();
}

set_zombie_run_cycle( new_move_speed ) //checked matches cerberus output
{
	self.zombie_move_speed_original = self.zombie_move_speed;
	self.zombie_move_speed = new_move_speed;
	self maps/mp/animscripts/zm_run::needsupdate();
	self.deathanim = self maps/mp/animscripts/zm_utility::append_missing_legs_suffix( "zm_death" );
}

init() //checked matches cerberus output
{
	scr_gametype = getDvar( "scr_gametype" );
	if ( scr_gametype != "" && scr_gametype == "znml" )
	{
		level.zombie_init_done = ::zombie_init_done;
		level.round_spawn_func = scripts/zm/znml_round_manager::nml_round_manager;
		level.round_wait_func = scripts/zm/znml_round_manager::round_wait;
		zm_location = getDvar( "ui_zm_mapstartlocation" );
		level._supress_survived_screen = true;
		level.custom_end_screen = ::nml_end_screen;
		level.no_board_repair = true;
		level.nml_dog_health = 100;
		switch ( zm_location )
		{
			case "town":
			case "farm":
			case "transit":
				level.can_spawn_dogs = true;
				break;
			default:
				level.can_spawn_dogs = false;
				break;
		}
		print( "start()" );
		flag_init( "start_supersprint", 0 );
		level.initial_spawn = true;
		level.zombie_health = level.zombie_vars[ "zombie_health_start" ];
		level thread znml_main();
	}
}

delete_trigs()
{
	debris_trigs = getentarray( "zombie_debris", "targetname" );
	if ( isDefined( debris_trigs ) )
	{
		foreach ( trig in debris_trigs )
		{
			trig delete();
			wait 0.05;
		}
	}
	zombie_doors = getentarray( "zombie_door", "targetname" );
	if ( isDefined( zombie_doors ) )
	{
		foreach ( door in zombie_doors )
		{
			door delete();
			wait 0.05;
		}
	}
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" );
	for ( i = 0; i < weapon_spawns.size; i++ )
	{
		weapon_spawns[ i ] trigger_off();
	}
}

znml_main()
{
	//Remove every perk except jugg, speedcola, and packapunch
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_quickrevive");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_rof");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_longersprint");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_deadshot");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_additionalprimaryweapon");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_finalstand");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_scavenger");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_flakjacket");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_grenadepulldeath");
	maps\mp\zombies\_zm_perks::perk_machine_removal("specialty_nomotionsensor");
	foreach( chest in level.chests )
	{
		chest hide_chest();
	}
	level thread maps/mp/zombies/_zm_blockers::open_all_zbarriers();
	level thread delete_trigs();
	flag_wait( "initial_blackscreen_passed" );
	flag_wait( "start_zombie_round_logic" );
	level.playersuicideallowed = false;
	flag_clear( "zombie_drop_powerups" );
	level thread nml_ramp_up_zombies();
	if ( level.can_spawn_dogs )
	{
		level thread nml_dogs_init();
	}
	level thread on_end_game();
}

on_player_connect()
{
	while ( true )
	{
		level waittill( "connected", player );
		player.hunted_by = false;
	}
}

on_end_game()
{
	level waittill( "end_game" );
	level.nml_best_time = GetTime() - level.nml_start_time;
}

nml_end_screen()
{
	players = getPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		game_over[ i ] = newclienthudelem( players[ i ] );
		game_over[ i ].alignx = "center";
		game_over[ i ].aligny = "middle";
		game_over[ i ].horzalign = "center";
		game_over[ i ].vertalign = "middle";
		game_over[ i ].y -= 130;
		game_over[ i ].foreground = 1;
		game_over[ i ].fontscale = 3;
		game_over[ i ].alpha = 0;
		game_over[ i ].color = ( 1, 1, 1 );
		game_over[ i ].hidewheninmenu = 1;
		game_over[ i ] settext( &"ZOMBIE_GAME_OVER" );
		game_over[ i ] fadeovertime( 1 );
		game_over[ i ].alpha = 1;
		survived[ i ] = newclienthudelem( players[ i ] );
		survived[ i ].alignx = "center";
		survived[ i ].aligny = "middle";
		survived[ i ].horzalign = "center";
		survived[ i ].vertalign = "middle";
		survived[ i ].y -= 100;
		survived[ i ].foreground = 1;
		survived[ i ].fontscale = 2;
		survived[ i ].alpha = 0;
		survived[ i ].color = ( 1, 1, 1 );
		survived[ i ].hidewheninmenu = 1;
		nomanslandtime = level.nml_best_time;
		player_survival_time = int( nomanslandtime / 1000 );
		player_survival_time_in_mins = maps/mp/zombies/_zm::to_mins( player_survival_time );
		survived[ i ] settext( "You survived for ", player_survival_time_in_mins );
		survived[ i ] fadeovertime( 1 );
		survived[ i ].alpha = 1;
	}
}

override_cornfield_perk_locations()
{
	scripts/zm/_gametype_setup::register_perk_struct( "specialty_armorvest", "zombie_vending_jugg", ( 0, 260.2, 0 ), ( 10355.1, -1507.9, -213.3 ) );
	scripts/zm/_gametype_setup::register_perk_struct( "specialty_fastreload", "zombie_vending_sleight", ( 0, 21.8, 0 ), ( 9944.8, -121.7, -211 ) );
	scripts/zm/_gametype_setup::register_perk_struct( "specialty_weapupgrade", "p6_anim_zm_buildable_pap_on", ( 0, 270, 0), ( 12221.1, -719, -131.5 ) );
}

override_town_perk_locations()
{
	// scripts/zm/_gametype_setup::register_perk_struct( "specialty_armorvest", "zombie_vending_jugg", ( 0, 2.5, 0 ), ( 1967 -1297.8, -54.2 ) );
	// scripts/zm/_gametype_setup::register_perk_struct( "specialty_fastreload", "zombie_vending_sleight", ( 0, 270, 0 ), ( 2098, -1428.5, -56 ) );
	structs = getstructarray( "zm_perk_machine", "targetname" );
	foreach ( struct in structs )
	{
		if ( struct.script_string == "zstandard_perks_town" )
		{
			struct.script_string = "zremove_perks_town";
		}
		else if ( struct.script_string == "znml_perks_town" )
		{
			struct.script_string = "zstandard_perks_town";
		}
	}
}
