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
	level.no_board_repair = true;
	level.playersuicideallowed = false;
	level.canplayersuicide = ::canplayersuicide;
	level.suicide_weapon = "death_self_zm";
	precacheitem( "death_self_zm" );
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

znml_main()
{
	flag_wait( "initial_blackscreen_passed" );
	flag_clear( "zombie_drop_powerups" );
	start_chest = getent( "start_chest", "script_noteworthy" );
	start_chest maps\mp\zombies\_zm_magicbox::hide_chest();
	doors = GetEntArray( "zombie_door", "targetname" );
	foreach ( door in doors )
	{
		door SetInvisibleToAll();
	}
	level thread maps\mp\zombies\_zm_blockers::open_all_zbarriers();
	level thread nml_ramp_up_zombies();
	level thread nml_round_manager();
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

onSpawnPlayer( predictedSpawn )
{
	getSpawnPoints();

	players = GET_PLAYERS();
	foreach ( index, player in players )
	{
		// Give Grenades
		//--------------
		lethal_grenade = player get_player_lethal_grenade();
		if( !player HasWeapon( lethal_grenade ) )
		{
			player GiveWeapon( lethal_grenade );
			player SetWeaponAmmoClip( lethal_grenade, 0 );
		}

		if ( player GetFractionMaxAmmo( lethal_grenade ) < .25 )
		{
			player SetWeaponAmmoClip( lethal_grenade, 2 );
		}
		else if ( player GetFractionMaxAmmo( lethal_grenade ) < .5 )
		{
			player SetWeaponAmmoClip( lethal_grenade, 3 );
		}
		else
		{
			player SetWeaponAmmoClip( lethal_grenade, 4 );
		}
	}
}