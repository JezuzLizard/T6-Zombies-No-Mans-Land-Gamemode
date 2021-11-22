#include maps/mp/_utility;
#include maps/mp/gametypes_zm/_hud_util;
#include common_scripts/utility;
#include maps/mp/zombies/_zm_utility;

onprecachegametype_nml() //checked matches cerberus output
{
	if ( !isDefined( level.script ) )
	{
		level.script = getDvar( "mapname" );
	}
	if ( !isDefined( level.gametype ) )
	{
		level.gametype = getDvar( "g_gametype" );
	}
	if ( !isDefined( level.zm_location ) )
	{
		level.zm_location = getDvar( "ui_zm_mapstartlocation" );
	}
	level._supress_survived_screen = true;
	level.custom_end_screen = ::nml_end_screen;
	level.no_board_repair = true;
	level.nml_dog_health = 100;
	level.playersuicideallowed = false;
	level.canplayersuicide = ::canplayersuicide;
	level.suicide_weapon = "death_self_zm";
	precacheitem( "death_self_zm" );
	level.can_spawn_dogs = false;
	switch ( level.zm_location )
	{
		case "town":
		case "farm":
		case "transit":
			level.can_spawn_dogs = true;
			break;
		default:
			break;
	}
	if ( level.can_spawn_dogs )
	{
		maps/mp/zombies/_zm_ai_dogs::init();
	}
	maps/mp/gametypes_zm/_zm_gametype::rungametypeprecache( level.gametype );
}

onstartgametype_nml() //checked matches cerberus output
{
	flag_init( "start_supersprint", 0 );
	level.initial_spawn = true;
	level.zombie_health = level.zombie_vars[ "zombie_health_start" ];
	maps/mp/gametypes_zm/_zm_gametype::setup_classic_gametype();
	maps/mp/gametypes_zm/_zm_gametype::rungametypemain( level.gametype, ::znml_main );
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
	start_chest = getent( "start_chest", "script_noteworthy" );
	start_chest maps/mp/zombies/_zm_magicbox::hide_chest();
	level thread maps/mp/zombies/_zm_blockers::open_all_zbarriers();
	level thread delete_trigs();
	flag_wait( "initial_blackscreen_passed" );
	flag_wait( "start_zombie_round_logic" );
	flag_clear( "zombie_drop_powerups" );
	level thread nml_ramp_up_zombies();
	level thread nml_round_manager();
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
		player thread on_player_spawned();
	}
}

on_player_spawned()
{
	while ( true )
	{
		self waittill( "spawned_player" );
		lethal_grenade = self get_player_lethal_grenade();
		if ( !self hasweapon( lethal_grenade ) )
		{
			self giveweapon( lethal_grenade );
			self setweaponammoclip( lethal_grenade, 2 );
		}
	}
}

on_end_game()
{
	level waittill( "end_game" );
	level.nml_best_time = GetTime() - level.nml_start_time;
}

nml_end_screen()
{
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