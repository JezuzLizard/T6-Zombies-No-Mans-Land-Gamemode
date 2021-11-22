#include maps/mp/zombies/_zm_stats;
#include common_scripts/utility;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/_utility;
#include maps/mp/gametypes_zm/_zm_gametype;
#include maps/mp/zombies/_zm_stats;

main()
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
		level.onprecachegametype = ::onprecachegametype_classic;
		level.onstartgametype = ::onstartgametype_classic;
	}
	level._game_module_custom_spawn_init_func = ::custom_spawn_init_func;
	level._game_module_stat_update_func = ::survival_classic_custom_stat_update;
	maps/mp/gametypes_zm/_zm_gametype::post_gametype_main( "zclassic" );
}

onprecachegametype_classic()
{
	level.playersuicideallowed = 1;
	level.canplayersuicide = ::canplayersuicide;
	level.suicide_weapon = "death_self_zm";
	precacheitem( "death_self_zm" );
	maps/mp/gametypes_zm/_zm_gametype::rungametypeprecache( "zclassic" );
}

onstartgametype_classic()
{
	maps/mp/gametypes_zm/_zm_gametype::rungametypemain( "zclassic", ::zclassic_main );
}