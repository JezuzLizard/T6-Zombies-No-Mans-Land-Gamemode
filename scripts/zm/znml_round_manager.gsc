#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

onStartGameType( name )
{
	//disable chalk
	level.noChalk = true;
	level._supress_survived_screen = 1;
	level.nml_dog_health = 100;

	level thread nml_dogs_init();
}

nml_ramp_up_zombies()
{
	self endon( "stop_ramp" );
	wait 30;
	// start at round level entered no mans land
	level.nml_timer = 1;
	while( true )
	{
		level thread attack_wave_screen_shake();
		//Check for health bump.
		level.nml_timer++;
		// DCS: ramping up zombies, play round change sound ( # 88706 )
		play_sound_2d( "evt_nomans_warning" );
		zombies = GetAISpeciesArray( "axis", "zombie" );
		z = 0;
		while ( isdefined( zombies ) && zombies.size > 0 && z < zombies.size )
		{
			zombie = zombies[z];
			//remove zombies from this array that have already taken damage or had thier head gibbed
			if ( ( zombie.health != level.zombie_health ) || is_true( zombie.gibbed ) || is_true( zombie.head_gibbed ) )
			{
				ArrayRemoveValue( zombies, zombie );
				z = 0;
			}
			else
			{
				z++;
			}
		}
		maps\mp\zombies\_zm::ai_calculate_health( level.nml_timer );
		foreach ( zombie in zombies )
		{
			if ( is_true( zombie.gibbed ) || is_true( zombie.head_gibbed ) )
			{
				continue;
			}
			zombie.health = level.zombie_health;
		}
		level thread nml_dog_health_increase();
		zombie_dogs = GetAISpeciesArray("axis","zombie_dog");
		if ( IsDefined( zombie_dogs ) )
		{
			for( i = 0; i < zombie_dogs.size; i++ )
			{
				zombie_dogs[ i ].maxhealth = int( level.nml_dog_health);
				zombie_dogs[ i ].health = int( level.nml_dog_health );
			}	
		}
		if ( level.nml_timer == 6 )
		{
			flag_set( "start_supersprint" );
		}
		wait 20;
	}
}

nml_dog_health_increase()
{
	if( level.nml_timer < 4) 
	{
		level.nml_dog_health = 100;
	}	
	else if( level.nml_timer >= 4 && level.nml_timer < 6) //80 seconds.
	{
		level.nml_dog_health = 400;
	}
	else if( level.nml_timer >= 6 && level.nml_timer < 15 ) //2 minutes
	{
		level.nml_dog_health = 800;
	}
	else if( level.nml_timer >= 15 && level.nml_timer < 30 ) // 5 minutes
	{
		level.nml_dog_health = 1200;
	}
	else if(level.nml_timer >= 30)//10 minutes or more
	{
		level.nml_dog_health = 1600;
	}
}	

nml_dogs_init()
{
	level.nml_dogs_enabled = false;
	wait 5;
	level.nml_dogs_enabled = true;
}

nml_round_manager()
{
	level.nml_start_time = GetTime();
	// Time when dog spawns start in NML
	dog_round_start_time = 100;
	dog_can_spawn_time = -1000*10;
	dog_difficulty_min_time = 3000;
	dog_difficulty_max_time = 9500;
	// Attack Waves setup
	wave_1st_attack_time = (1000 * 25);//(1000 * 40);
	prepare_attack_time = (1000 * 2.1);
	wave_attack_time = (1000 * 35);		// 40
	cooldown_time = (1000 * 16);		// 25
	next_attack_time = (1000 * 26);		// 32
	max_zombies = 20;
	next_round_time = level.nml_start_time + wave_1st_attack_time;
	mode = "normal_spawning";
	area = 1;
	while ( true )
	{
		current_time = GetTime();
		wait_override = 0.0;
		/**************************************************************/
		/* There is a limit of 24 AI entities, wait to hit this limit */
		/**************************************************************/
		zombies = GetAiSpeciesArray( "axis", "all" );
		while( zombies.size >= max_zombies )
		{
			zombies = GetAiSpeciesArray( "axis", "all" );
			wait 0.5;
		}
		/***************************/
		/* Update the Spawner Mode */
		/***************************/
		switch( mode )
		{
			// Default Ambient Zombies
			case "normal_spawning":
				
				if ( level.initial_spawn == true )
				{
					spawn_a_zombie( 10, 0.01 );
				}
				else
				{	
					ai = spawn_a_zombie( max_zombies, 0.01 );
					if ( isdefined ( ai ) )
					{
						move_speed = "sprint";

						if ( flag( "start_supersprint" ) )
						{
							move_speed  = "super_sprint";
						}

						ai set_zombie_run_cycle( move_speed );
					}
				}
				// Check for Spawner Wave to Start
				if( current_time > next_round_time )
				{
					next_round_time = current_time + prepare_attack_time;
					mode = "preparing_spawn_wave";
					level thread screen_shake_manager( next_round_time );
				}
			break;
			// Shake screen, start existing zombies running, then start a wave
			case "preparing_spawn_wave":
				zombies = GetAiSpeciesArray( "axis" );
				for( i = 0; i < zombies.size; i++ )
				{
					if( zombies[ i ].has_legs && zombies[ i ].animname == "zombie") // make sure not a dog.
					{
						move_speed = "sprint";

						if ( flag( "start_supersprint" ) )
						{
							move_speed  = "super_sprint";
						}
						zombies[ i ] set_zombie_run_cycle( move_speed );
						level.initial_spawn = false;
						level notify( "start_nml_ramp" );
					}
				}
				if( current_time > next_round_time )
				{
					level notify( "nml_attack_wave" );
					mode = "spawn_wave_active";
					
					if( area == 1 )
					{
						area = 2;
						level thread nml_wave_attack( max_zombies );
					}
					else
					{
						area = 1;
						level thread nml_wave_attack( max_zombies );
					}
									
					next_round_time = current_time + wave_attack_time;
				}
				wait_override = 0.1;
			break;
			// Attack wave in progress
			// Occasionally spawn a zombie
			case "spawn_wave_active":
				if ( current_time < next_round_time )
				{
					if( randomfloatrange(0, 1) < 0.05 )
					{
						ai = spawn_a_zombie( max_zombies, 0.01 );
						if ( isdefined( ai ) )
						{
							move_speed = "sprint";
							if ( flag( "start_supersprint" ) )
							{
								move_speed  = "super_sprint";
							}
							ai set_zombie_run_cycle( move_speed );
						}			
					}
				}
				else
				{
					level notify("wave_attack_finished");
					mode = "wave_finished_cooldown";
					next_round_time = current_time + cooldown_time;
				}
			break;
			// Round over, cooldown period
			case "wave_finished_cooldown":
				if( current_time > next_round_time )
				{
					next_round_time = current_time + next_attack_time;
					mode = "normal_spawning";
				}
				wait_override = 0.01;
			break;
		}
		/***************************************************************************************/
		/* If there are any dog targets (players running about in NML (away from the platform) */
		/* Send dogs after them																   */
		/***************************************************************************************/
		num_dog_targets = 0;
		if( (current_time - level.nml_start_time) > dog_round_start_time )
		{
			skip_dogs = 0;
			// *** DIFFICULTY FOR 1 Player ***
			players = getPlayers();
			if( players.size <= 1 )
			{
				dt = current_time - dog_can_spawn_time;
				if( dt < 0 )
				{
					//iPrintLn( "DOG SKIP" );
					skip_dogs = 1;
				}
				else
				{
					dog_can_spawn_time = current_time + randomfloatrange(dog_difficulty_min_time, dog_difficulty_max_time);
				}
			}
			if ( mode == "preparing_spawn_wave" )
			{
				skip_dogs = 1;
			}
			if ( !skip_dogs && level.nml_dogs_enabled )
			{
				num_dog_targets =  players.size;
				//iPrintLn( "Num Dog Targets: " + num_dog_targets );
				if( num_dog_targets )
				{
					// Send 2 dogs after each player
					dogs = getaispeciesarray( "axis", "dog" );
					num_dog_targets *= 2;
						
					if( dogs.size < num_dog_targets )
					{
						ai = maps\mp\zombies\_zm_ai_dogs::special_dog_spawn();
						//set their health to current level immediately.
						zombie_dogs = GetAISpeciesArray("axis","zombie_dog");
						if ( IsDefined( zombie_dogs ) )
						{
							for( i = 0; i < zombie_dogs.size; i++ )
							{
								zombie_dogs[ i ].maxhealth = int( level.nml_dog_health);
								zombie_dogs[ i ].health = int( level.nml_dog_health );
							}	
						}
					}
				}
			}
		}
		if ( wait_override != 0.0 )
		{
			wait wait_override;
		}
		else
		{
			wait randomfloatrange( 0.1, 0.8 );
		}
	}
}

nml_wave_attack( num_in_wave )
{
	level endon("wave_attack_finished");
	while( true )
	{
		zombies = GetAiSpeciesArray( "axis", "all" );
		if( zombies.size < num_in_wave )
		{
			ai = spawn_a_zombie( num_in_wave, 0.01 );
			if ( isdefined( ai ) )
			{
				move_speed = "sprint";
				if ( flag( "start_supersprint" ) )
				{
					move_speed  = "super_sprint";
				}
				ai set_zombie_run_cycle( move_speed );
			}
		}
		wait randomfloatrange( 0.3, 1.0 );
	}
}

spawn_a_zombie( max_zombies, spawner_zone_name, wait_delay )
{
	// Don't spawn a new zombie if we are at the limit
	zombies = getaispeciesarray( "axis" );
	if( zombies.size >= max_zombies )
	{
		return undefined;
	}
	spawn_point = level.zombie_spawners[ RandomInt( level.zombie_spawners.size ) ]; 
	ai = spawn_zombie( spawn_point ); 
	if( IsDefined( ai ) )
	{	
		ai thread maps\mp\zombies\_zm::round_spawn_failsafe();
	}
	wait wait_delay ;
	wait_network_frame();
	return ai;
}

screen_shake_manager( next_round_time )
{
	level endon( "nml_attack_wave" );
	time = 0;
	while ( time < next_round_time )
	{
		level thread attack_wave_screen_shake();
		wait_time = randomfloatrange( 0.25, 0.35 );
		wait wait_time ;
		time = gettime();
	}
}

attack_wave_screen_shake()
{
	/**********************************************************/
	/* Get a position that averages all the players positions */
	/**********************************************************/
	num_valid = 0;
	players = GET_PLAYERS();
	pos = ( 0, 0, 0 );
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		if ( is_player_valid( player ) )
		{
			pos += player.origin;
			num_valid++;
		}
	}
	if( !num_valid )
	{
		return;
	}
	shake_position = ( ( pos[ 0 ] / num_valid), ( pos[ 1 ] / num_valid ), ( pos[ 2 ] / num_valid ) );
	thread rumble_all_players( "damage_heavy" );
	scale = 0.4;
	duration = 1.0;
	radius = 42 * 400;
	//earthquake( scale, duration, shake_position, radius );
}

rumble_all_players(high_rumble_string, low_rumble_string, rumble_org, high_rumble_range, low_rumble_range)
{
	players = getPlayers();
	
	for ( i = 0; i < players.size; i++ )
	{
		if ( isdefined( high_rumble_range ) && isdefined( low_rumble_range ) && isdefined( rumble_org ) )
		{
			if ( distance( players[ i ].origin, rumble_org ) < high_rumble_range )
			{
				players[ i ] playrumbleonentity( high_rumble_string );
			}
			else if ( distance( players[ i ].origin, rumble_org ) < low_rumble_range )
			{
				players[ i ] playrumbleonentity( low_rumble_string );
			}
		}
		else
		{
			players[ i ] playrumbleonentity( high_rumble_string );
		}
	}
}