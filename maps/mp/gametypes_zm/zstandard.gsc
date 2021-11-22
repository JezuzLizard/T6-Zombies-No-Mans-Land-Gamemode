//checked includes match cerberus output
#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_ai_dogs;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/gametypes_zm/_zm_gametype;
#include common_scripts/utility;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/_utility;

main() //checked matches cerberus output
{
	maps/mp/gametypes_zm/_zm_gametype::main();
	scr_gametype = getDvar( "scr_gametype" );
	if ( scr_gametype != "" && scr_gametype == "znml" )
	{
		level.onprecachegametype = scripts/zm/znml::onprecachegametype_nml;
		level.onstartgametype = scripts/zm/znml::onstartgametype_nml;
	}
	else 
	{
		level.onprecachegametype = ::onprecachegametype_standard;
		level.onstartgametype = ::onstartgametype_standard;
	}
	level._game_module_custom_spawn_init_func = maps/mp/gametypes_zm/_zm_gametype::custom_spawn_init_func;
	level._game_module_stat_update_func = maps/mp/zombies/_zm_stats::survival_classic_custom_stat_update;
	maps/mp/gametypes_zm/_zm_gametype::post_gametype_main( "zstandard" );
}

onprecachegametype_standard() //checked matches cerberus output
{
	level.playersuicideallowed = 1;
	level.canplayersuicide = ::canplayersuicide;
	level.suicide_weapon = "death_self_zm";
	precacheitem( "death_self_zm" );
	maps/mp/zombies/_zm_ai_dogs::init();
	maps/mp/gametypes_zm/_zm_gametype::rungametypeprecache( "zstandard" );
}

onstartgametype_standard() //checked matches cerberus output
{
	maps/mp/gametypes_zm/_zm_gametype::setup_classic_gametype();
	maps/mp/gametypes_zm/_zm_gametype::rungametypemain( "zstandard", ::zstandard_main );
}

zstandard_main() //checked matches cerberus output
{
	level.dog_rounds_allowed = getgametypesetting( "allowdogs" );
	if ( level.dog_rounds_allowed )
	{
		maps/mp/zombies/_zm_ai_dogs::enable_dog_rounds();
	}
	level thread maps/mp/zombies/_zm::round_start();
	level thread maps/mp/gametypes_zm/_zm_gametype::kill_all_zombies();
}
