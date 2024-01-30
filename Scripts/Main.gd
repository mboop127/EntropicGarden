extends Node2D

var RNG = RandomNumberGenerator.new()

var current_plant_id: int = 0

class Gene:
	var type: String
	var variant: int = 1
	var rotation: int
	var shade: Color
	var connector: int

class Plant:
	var Age: int = 0
	var Energy_Per_Tick: float = 0
	var Light_Energy_Per_Tick: float = 0
	var Energy_Cost_Per_Tick: float = 0
	var Parts: Array
	var DNA: Array
	var Location: Vector2
	var Available_Connectors: Array = []
	var Current_Instruction: int = 0
	var Energy: float = 0
	var Unique_ID: int
	var Max_Stored_Energy: float = 10
	var Stability: float = 0
	var Heat: float = 0
	var Ideal_Heat: Array = []
	var Height: float = 0
	var Flowers: Dictionary = {"-1":[20,1]} #id: [energy,range]

func average(array: Array) -> float:
	var output = 0
	for i in range(len(array)):
		output += array[i]
	
	if len(array) != 0:
		return output/len(array)
	else:
		return 1

func generate_random_dna(DNA_Length: int) -> Array:
	
	var DNA_output: Array = []
	for i in range(DNA_Length):
		var new_gene = Gene.new()
		new_gene.connector = RNG.randi_range(-5,5)
		new_gene.shade = Color( RNG.randf_range(0,1), RNG.randf_range(0,1), RNG.randf_range(0,1) )
		new_gene.type = Global.available_instructions[RNG.randi_range(0,len(Global.available_instructions)-1)]
		new_gene.variant = RNG.randi_range(1,3)
		new_gene.rotation = RNG.randi_range(0,360)
		
		DNA_output.append(new_gene)
	
	DNA_output[0].type = "Stem"
	return DNA_output

func generate_custom_dna() -> Array:
	var DNA_output: Array = []

	var new_gene = Gene.new()
	new_gene.type = "Stem"
	new_gene.connector = -1
	new_gene.shade = Color( RNG.randf_range(0,1), RNG.randf_range(0,1), RNG.randf_range(0,1) )
	new_gene.variant = 1
	new_gene.rotation = 0
	
	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Leaf"
	new_gene.connector = -1
	new_gene.shade = Global.ideal_photosynthesis_color
	new_gene.variant = 1
	new_gene.rotation = 0
	
	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Root"
	new_gene.connector = 0
	new_gene.shade = Color( RNG.randf_range(0,1), RNG.randf_range(0,1), RNG.randf_range(0,1) )
	new_gene.variant = 1
	new_gene.rotation = 0
	
	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Stem"
	new_gene.connector = -1
	new_gene.shade = Color( RNG.randf_range(0,1), RNG.randf_range(0,1), RNG.randf_range(0,1) )
	new_gene.variant = 1
	new_gene.rotation = 0

	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Leaf"
	new_gene.connector = -1
	new_gene.shade = Global.ideal_photosynthesis_color
	new_gene.variant = 1
	new_gene.rotation = 0
	
	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Flower"
	new_gene.connector = -1
	new_gene.variant = 1
	new_gene.rotation = 0
	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Skip"
	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Skip"
	DNA_output.append(new_gene)

	new_gene = Gene.new()
	new_gene.type = "Reproduce"
	new_gene.connector = 0
	new_gene.shade = Color( RNG.randf_range(0,1), RNG.randf_range(0,1), RNG.randf_range(0,1) )
	new_gene.variant = 1
	new_gene.rotation = 0
	
	DNA_output.append(new_gene)
	
	for i in range(10):
		new_gene = Gene.new()
		new_gene.type = "Reproduce"
		DNA_output.append(new_gene)

	return DNA_output

func mutate_Gene(gene: Gene) -> Gene:
	
	var output_gene = Gene.new()
	output_gene.type = gene.type
	output_gene.variant = gene.variant
	output_gene.connector = gene.connector
	output_gene.shade = gene.shade
	output_gene.rotation = gene.rotation
	
	if RNG.randf_range(0,1) < Global.mutation_chance:
		output_gene.connector = RNG.randi_range(-5,5)
	if RNG.randf_range(0,1) < Global.mutation_chance:
		output_gene.shade = Color( RNG.randf_range(0,1), RNG.randf_range(0,1), RNG.randf_range(0,1) )
	if RNG.randf_range(0,1) < Global.mutation_chance:
		output_gene.type = Global.available_instructions[RNG.randi_range(0,len(Global.available_instructions)-1)]
	if RNG.randf_range(0,1) < Global.mutation_chance:
		output_gene.variant = 1
	if RNG.randf_range(0,1) < Global.mutation_chance:
		output_gene.rotation = RNG.randi_range(0,360)	
	
	return output_gene
	
func mutate_DNA(DNA: Array) -> Array:
	
	var output_DNA = DNA.duplicate(true)
	
	RNG.randomize()
	for i in range(len(output_DNA)):
		output_DNA[i] = mutate_Gene(DNA[i])
		
	
		
	while RNG.randf_range(0,1) < Global.mutation_chance:
		var new_gene = Gene.new()
		new_gene.connector = RNG.randi_range(-5,5)
		new_gene.shade = Color( RNG.randf_range(0,1), RNG.randf_range(0,1), RNG.randf_range(0,1) )
		new_gene.type = Global.available_instructions[RNG.randi_range(0,3)]
		new_gene.variant = RNG.randf_range(1,3)
		new_gene.rotation = RNG.randi_range(0,360)
		  
		var location = RNG.randi_range(0,len(DNA)-1)
		
		output_DNA.insert(location, new_gene)
	
	if RNG.randf_range(0,1) < Global.mutation_chance:
		output_DNA.shuffle()

	while RNG.randf_range(0,1) < Global.mutation_chance and len(output_DNA) > 1:
		output_DNA.remove_at( RNG.randi_range(0, len(output_DNA) - 1) )
	
	
	output_DNA[0].type = "Stem"
	return output_DNA
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var b = Global.world_generation_parameters.new()
	b.fertility_frequency = 0.001
	b.gravity_frequency = 0.001
	b.heat_frequency = 0.005
	b.height_variation = 5
	b.light_frequency = 0.002
	
	Global.World_Dict = Global.generate_world_dict(b)
	
	draw_ground()
	draw_overlays()
	
func spawn_plant(DNA: Array, x_location: float, starting_energy: float) -> void:
	var new_plant = Plant.new()
	new_plant.Unique_ID = current_plant_id
	current_plant_id += 1
	
	new_plant.DNA = DNA
	
	RNG.randomize()
	new_plant.Energy = starting_energy
	new_plant.Max_Stored_Energy = starting_energy
	new_plant.Location.x = x_location
	new_plant.Location.y = -1 * Global.World_Dict[str( int( (new_plant.Location.x - Global.world_resolution/2 ) / Global.world_resolution) ) + ",0"].height
	new_plant.Available_Connectors.append(new_plant.Location)
	Global.Plant_Dict[new_plant.Unique_ID] = new_plant
	Global.World_Dict[ Global.get_tile( Vector2(x_location, 0) ) ].plant_count += 1
	#$Camera2D.set_position(new_plant.Location)

func die(plant: Plant) -> void:
	for i in range(len(plant.Parts)):
		plant.Parts[i].queue_free()

	Global.World_Dict[ Global.get_tile( Vector2(plant.Location.x, 0) ) ].plant_count -= 1
	Global.World_Dict[ Global.get_tile( Vector2(plant.Location.x, 0) ) ].use_fertility += max(0,plant.Energy)
	Global.World_Dict[ Global.get_tile( Vector2(plant.Location.x, 0) ) ].plant_heights.erase(plant.Height)

	#print(Global.World_Dict[ Global.get_tile( Vector2(plant.Location.x, 0) ) ].plant_count )

	Global.Plant_Dict.erase( plant.Unique_ID )

func life_tick(plant: Plant) -> Array:
	
	var die_list: Array = []
	
	plant.Age += 1
	
	var temp_tile = Global.get_tile(plant.Location)
	var local_tile: Global.tile_data = Global.World_Dict[ temp_tile ]
	
	var tick_energy: float = plant.Energy_Per_Tick
	var avg_ideal_heat = average(plant.Ideal_Heat)
	tick_energy *= max(.3,(1 - abs(avg_ideal_heat - plant.Heat)/plant.Heat))
	tick_energy *= (1-Global.age_efficiency_loss) ** plant.Age

	#print(local_tile.plant_heights))
	if plant.Height != local_tile.plant_heights.max():
		plant.Light_Energy_Per_Tick *= .5
	
	elif local_tile.plant_heights.count(plant.Height) > 1:
		plant.Light_Energy_Per_Tick *= .8
	

	tick_energy += plant.Light_Energy_Per_Tick


	#print(min(20,max(1,1000/len(Global.Plant_Dict))))
	tick_energy *= min(30,max(2,1000/len(Global.Plant_Dict)))

	
	#print("====")
	#print(tick_energy)
	#print(plant.Energy_Cost_Per_Tick)
	#print(plant.Energy)
	plant.Energy += max(0,tick_energy)
	
	plant.Energy = min(plant.Energy, plant.Max_Stored_Energy)
	plant.Energy -= plant.Energy_Cost_Per_Tick

	if plant.Energy < 0 or plant.Age > Global.max_age:
		#print("====")
		#print(plant.Energy)
		#print(plant.Age)
		die_list.append(plant)
	
	elif plant.Current_Instruction < len(plant.DNA) - 1:
		var expressed_gene = plant.DNA[plant.Current_Instruction]
		
		
		if expressed_gene.type in ['Leaf','Stem','Flower','Root']:
			#print("res://Plant_Parts/" + expressed_gene.type + "_" + str(expressed_gene.variant) + ".tscn")
			var loaded_part = load("res://Plant_Parts/" + expressed_gene.type + "_" + str(expressed_gene.variant) + ".tscn")
			var new_part = loaded_part.instantiate()
			
			if new_part.growth_cost < plant.Energy and len(plant.Available_Connectors) > 0:
				#print(expressed_gene.type)
				var connector_to_use = expressed_gene.connector
				
				while abs( connector_to_use ) > len(plant.Available_Connectors) -1:
					if connector_to_use > 0:
						connector_to_use -= 1
					elif connector_to_use < 0:
						connector_to_use += 1
				
				new_part.position = plant.Available_Connectors[connector_to_use]
				
				#print("===")
				#print(plant.Available_Connectors)
				#print(new_part.position)

				plant.Available_Connectors.erase(new_part.position)

				#print(plant.Available_Connectors)
				
				new_part.rotation = expressed_gene.rotation
				new_part.shade = expressed_gene.shade
				new_part.plant_id = plant.Unique_ID
				plant.Parts.append(new_part)
				
				add_child(new_part)
				new_part.update_parent(plant.Unique_ID)
				new_part.check_overlap()
				
				#print(new_part.part_type)
				
				plant.Current_Instruction += 1
			
			elif len(plant.Available_Connectors) < 1:
				new_part.queue_free()
				plant.Current_Instruction += 1
			
			else:
				new_part.queue_free()
		
		elif expressed_gene.type == 'Reproduce':
			#print("try")
			if reproduce(plant):
				plant.Current_Instruction += 1
		
		elif expressed_gene.type == 'Skip':
			plant.Current_Instruction += 1

	else:
		plant.Current_Instruction = 0
		
	return die_list

func reproduce(plant: Plant) -> bool:
	
	var success = false
	for flower in plant.Flowers:
	
		var reproduction_cost = plant.Flowers[flower][0]
		var reproduction_range = plant.Flowers[flower][1]
	
		if plant.Energy > reproduction_cost:
		
			var new_spawn_location: int = max(0, min( plant.Location.x + RNG.randi_range(-Global.world_resolution * reproduction_range/2,Global.world_resolution * reproduction_range/2), Global.godot_world_size - Global.world_resolution/2 ) )
			
			if Global.World_Dict[ Global.get_tile( Vector2(new_spawn_location, 0) ) ].plant_count < Global.max_plants_per_tile:
				
				plant.Energy -= reproduction_cost
				
				RNG.randomize()
				
				if RNG.randi_range(0,100) <= reproduction_cost:
					spawn_plant( mutate_DNA( plant.DNA ), new_spawn_location, reproduction_cost)
				
				success = true
		
		else:
			break
			
	return success

func _on_world_timer_timeout():
	
	print( len(Global.Plant_Dict) )
	
	Global.max_age = 100
	Global.age_efficiency_loss = .005
	
	refresh_fertility()
	
	var die_list: Array = []
	
	for plant_entry in Global.Plant_Dict:
		
		Global.Plant_Dict[plant_entry].Energy_Per_Tick = 0
		for i in range(len(Global.Plant_Dict[plant_entry].Parts)):
			Global.Plant_Dict[plant_entry].Parts[i].check_overlap()
			Global.Plant_Dict[plant_entry].Energy_Per_Tick += Global.Plant_Dict[plant_entry].Parts[i].actual_energy_per_tick
		
		die_list += life_tick(Global.Plant_Dict[plant_entry])
	
	for i in range(len(die_list)):
		die(die_list[i])
	
	
	if len(Global.Plant_Dict) == 0:
		print("extinction")
		for _i in range(100):
			spawn_plant( generate_random_dna(10), RNG.randi_range(0, Global.godot_world_size - Global.world_resolution/2), 20 )
			#spawn_plant( generate_custom_dna(), RNG.randi_range(0, Global.godot_world_size - Global.world_resolution/2), 20 )

	RNG.randomize()
	if RNG.randf_range(0,1) < .01:
		spawn_plant( generate_random_dna(10), RNG.randi_range(0, Global.godot_world_size - Global.world_resolution/2), 20 )

	$World_Timer.start()

func draw_ground() -> void:
	
	var ground_line = Line2D.new()
	ground_line.default_color = Color(0,1,0)
	for tile in Global.World_Dict:
		
		if tile.split(",")[1] == "0":

			ground_line.add_point(Vector2( int(tile.split(",")[0]) * Global.world_resolution + .5 *Global.world_resolution, -Global.World_Dict[tile].height))
			ground_line.add_point(Vector2( int(tile.split(",")[0]) * Global.world_resolution + 1.5 *Global.world_resolution, -Global.World_Dict[tile].height ))
		
			$Camera2D.set_position( Vector2( int(tile.split(",")[0]) * Global.world_resolution , -Global.World_Dict[tile].height ) )

	add_child(ground_line)

func draw_overlays() -> void:
	
	for tile in Global.World_Dict:
		var tile_data: Global.tile_data = Global.World_Dict[tile]
		var rect_position: Vector2 = Vector2( int( tile.split(",")[0] ) * Global.world_resolution + .5 * Global.world_resolution, -int( tile.split(",")[1] ) * Global.world_resolution + .5 *Global.world_resolution)
		var rect_size: Vector2 = Vector2(Global.world_resolution, Global.world_resolution)
		
		var new_label = Label.new()
		var new_rect = ColorRect.new()
		new_rect.color = Color(tile_data.heat/Global.max_heat,0,0, .3)
		new_rect.set_position(rect_position)
		new_rect.size = rect_size
		$Heat_Container.add_child(new_rect)
		new_label.text = str(snappedf(tile_data.heat,.01))
		new_label.set_position(rect_position)
		$Heat_Container.add_child(new_label)

		new_rect = ColorRect.new()
		new_rect.color = Color(tile_data.light/Global.max_light,0,0, .3)
		new_rect.set_position(rect_position)
		new_rect.size = rect_size
		$Light_Container.add_child(new_rect)
		new_label = Label.new()
		new_label.text = str(snappedf(tile_data.light,.01))
		new_label.set_position(rect_position)
		$Light_Container.add_child(new_label)
		
		
		new_rect = ColorRect.new()
		new_rect.color = Color(tile_data.gravity/Global.max_gravity,0,0, .3)
		new_rect.set_position(rect_position)
		new_rect.size = rect_size
		$Gravity_Container.add_child(new_rect)
		new_label = Label.new()
		new_label.text = str(snappedf(tile_data.gravity,.01))
		new_label.set_position(rect_position)
		$Gravity_Container.add_child(new_label)


		new_rect = ColorRect.new()
		new_rect.color = Color(tile_data.fertility/Global.max_fertility,0,0, .3)
		new_rect.set_position(rect_position)
		new_rect.size = rect_size
		$Fertility_Container.add_child(new_rect)
		new_label = Label.new()
		new_label.text = str(snappedf(tile_data.fertility,.01))
		new_label.set_position(rect_position)
		$Fertility_Container.add_child(new_label)

func refresh_fertility() -> void:
	
	for tile in Global.World_Dict:
		Global.World_Dict[tile].use_fertility += Global.World_Dict[tile].fertility_regen
		Global.World_Dict[tile].use_fertility = min(Global.World_Dict[tile].fertility, Global.World_Dict[tile].use_fertility )

var is_panning: bool = true
@export var cam_spd = 100

func _process(delta):
	move_editor()
	is_panning = Input.is_action_pressed("mb_middle")
	
func move_editor():
	if Input.is_action_pressed("ui_up"):
		$Camera2D.global_position.y -= cam_spd
	if Input.is_action_pressed("ui_left"):
		$Camera2D.global_position.x -= cam_spd
	if Input.is_action_pressed("ui_down"):
		$Camera2D.global_position.y += cam_spd
	if Input.is_action_pressed("ui_right"):
		$Camera2D.global_position.x += cam_spd
	pass

func _unhandled_input(event):
	if(event is InputEventMouseButton):
		if(event.is_pressed()):
			if(event.button_index == 5): #mouse button wheel up
				$Camera2D.zoom -= Vector2(0.1,0.1)
			if(event.button_index == 4): #mouse button wheel down
				$Camera2D.zoom += Vector2(0.1,0.1)
	if(event is InputEventMouseMotion):
		if(is_panning):
			$Camera2D.global_position -= event.relative * $Camera2D.zoom
	
	if event.is_action_pressed("ui_accept"):
		
		if $World_Timer.paused:
			$World_Timer.paused = false
		else:
			$World_Timer.paused = true
			
	if event.is_action_pressed("ui_end"):
		$World_Timer.paused = true
		
		print("extinction button!")
		
		for plant_entry in Global.Plant_Dict:
			Global.Plant_Dict[plant_entry].Energy -= 10
			
		$World_Timer.paused = false
		
