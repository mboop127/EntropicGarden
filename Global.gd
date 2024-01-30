extends Node

var RNG = RandomNumberGenerator.new()

var World_Dict: Dictionary = {}
var Plant_Dict: Dictionary = {}
var intersection_energy_falloff: float = .5
var intersection_floor: int = 4
var mutation_chance: float = 0.01
var max_age: int = 100
var min_reproduction_cost: float = 5 #should be set higher than min DNA
var available_instructions: Array = ["Stem","Leaf","Root","Skip","Reproduce","Flower"]
var max_plants: int = 10000
var max_plants_per_tile: int = 3
var age_efficiency_loss: float = .01

var energy_cost_balancer: float = 1 #multiple of energy cost, adjust to balance cost with production

var ideal_energy_loss_color: Color = Color(1,1,1)
var ideal_photosynthesis_color: Color = Color(0,1,0)

var world_size: float = 2000 #controls number of dictionary tiles
var world_resolution: float = 100 #controls size of each tile in godot units
var world_height: float = 10 #vertical tiles

var godot_world_size: float = world_size * world_resolution
var max_fertility: float = 10
var max_heat: float = 3
var max_light: float = 5
var max_gravity: float = 10

class world_generation_parameters:
	var light_frequency: float = 0 #if set to 0, only source of light is sky downwards
	var heat_frequency: float = 0 #if set to 0, only source of light is x = 0 outwards
	var fertility_frequency: float = 0 #if set to 0, only source of light is ground upwards
	var gravity_frequency: float = 0 #controls spawn rate of gravity, if set to 0 scales linearly with height
	var height_variation: float = 0 #controlls marching vectors of ground height; if set to 0 no variation

class tile_data:
	var light: float = 0
	var heat: float = 0
	var fertility: float = 0
	var height: float = 0
	var gravity: float = 0
	var plant_count: int = 0
	var fertility_regen : float = 0.01
	var use_fertility: float = 0
	var plant_heights: Array = []

class energy_source:
	var falloff: float
	var intensity: float
	var location: Vector2

func compare_colors(Color1: Color, Color2: Color) -> float:
	var difference = 0
	difference += abs(Color1.r - Color2.r)
	difference += abs(Color1.g - Color2.g)
	difference += abs(Color1.b - Color2.b)
	
	return difference/3

func generate_world_dict(params: world_generation_parameters) -> Dictionary:
	
	var world_dict: Dictionary = {}
	
	var light_sources: Array = []
	var heat_sources: Array = []
	var fertility_sources: Array = []
	var gravity_sources: Array = []
	
	RNG.randomize()
	for i in range(world_size * world_height):
		if RNG.randf_range(0,1) < params.light_frequency:
			var new_light: energy_source = energy_source.new()
			new_light.falloff = RNG.randf_range(0,Global.world_resolution/3)/Global.world_resolution
			new_light.intensity = RNG.randf_range(0,max_light)
			new_light.location = Vector2( RNG.randi_range(0,godot_world_size), RNG.randi_range( int(world_height*world_resolution/2), world_height*world_resolution) )
			light_sources.append(new_light)
		
	for i in range(world_size * world_height):
		if RNG.randf_range(0,1) < params.heat_frequency:
			var new_heat: energy_source = energy_source.new()
			new_heat.falloff = RNG.randf_range(0,Global.world_resolution/3)/Global.world_resolution
			new_heat.intensity = RNG.randf_range(0,max_heat)
			new_heat.location = Vector2( RNG.randi_range(0,godot_world_size), RNG.randi_range( 0, world_height*world_resolution) )
			
			heat_sources.append(new_heat)

	for i in range(world_size * world_height):
		if RNG.randf_range(0,1) < params.fertility_frequency:
			var new_fertility: energy_source = energy_source.new()
			new_fertility.falloff = RNG.randf_range(0,Global.world_resolution/3)/Global.world_resolution
			new_fertility.intensity = RNG.randf_range(0,max_fertility)
			new_fertility.location = Vector2( RNG.randi_range(0,godot_world_size), RNG.randi_range( 0, int(world_height*world_resolution/2) ) )
			
			fertility_sources.append(new_fertility)
	
	for i in range(world_size * world_height):
		if RNG.randf_range(0,1) < params.fertility_frequency:
			var new_gravity: energy_source = energy_source.new()
			new_gravity.falloff = RNG.randf_range(0,Global.world_resolution/3)/Global.world_resolution
			new_gravity.intensity = RNG.randf_range(0,max_gravity)
			new_gravity.location = Vector2( RNG.randi_range(0, godot_world_size), RNG.randi_range( 0, world_height*world_resolution ) )
			gravity_sources.append(new_gravity)
	
	var x_height = world_height * world_resolution / 2 - world_resolution
	for x in range(world_size):
		
		x_height += RNG.randf_range(-params.height_variation, params.height_variation)
		
		for y in range(world_height):
			var new_tile = tile_data.new()
			
			var tile_center = Vector2(x * world_resolution + world_resolution/2, y * world_resolution + world_resolution/2)
			
			new_tile.height = x_height
			
			if len(light_sources) == 0:
				new_tile.light = (y / world_height) * max_light
			else:
				new_tile.light = 0
				for i in range(len(light_sources)):
					if tile_center == light_sources[i].location:
						new_tile.light += light_sources[i].intensity
					else:
						new_tile.light += 100 * light_sources[i].intensity/ ( tile_center.distance_to( light_sources[i].location) * light_sources[i].falloff )
			
			if len(fertility_sources) == 0:
				new_tile.fertility = ((world_height-y) / world_height) * max_fertility
			else:
				new_tile.fertility = 0
				for i in range(len(fertility_sources)):
					if Vector2(x,y) == fertility_sources[i].location:
						new_tile.fertility += fertility_sources[i].intensity
					else:
						new_tile.fertility += 100 * fertility_sources[i].intensity/ (tile_center.distance_to( fertility_sources[i].location) * fertility_sources[i].falloff)  
			
			if len(heat_sources) == 0:
				new_tile.heat = abs(x)
			else:
				new_tile.heat = 0

				for i in range(len(heat_sources)):
					
					if Vector2(x,y) == heat_sources[i].location:
						new_tile.heat += heat_sources[i].intensity
					else:
						new_tile.heat += 100 * heat_sources[i].intensity / (tile_center.distance_to( heat_sources[i].location) * heat_sources[i].falloff)
			
			if len(gravity_sources) == 0:
				new_tile.gravity = (y / world_height) * max_gravity
			else:
				new_tile.gravity = 0
				for i in range(len(gravity_sources)):
					
					if Vector2(x,y) == gravity_sources[i].location:
						new_tile.gravity += gravity_sources[i].intensity
					else:
						new_tile.gravity += 100 * gravity_sources[i].intensity / (tile_center.distance_to( gravity_sources[i].location) * gravity_sources[i].falloff)
			


			world_dict[ str(x) + "," + str(y) ] = new_tile
	
	return world_dict
	
func get_tile(location: Vector2) -> String:
	var x_location = 0
	var y_location = 0
	
	x_location = int( (location.x - world_resolution/2) / world_resolution )
	y_location = - int( (location.y - world_resolution/2) / world_resolution )
	
	return(str(x_location) + "," + str(y_location))
	
