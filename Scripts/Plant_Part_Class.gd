extends Node
class_name Plant_Part

@export var part_type: String
var RNG: RandomNumberGenerator = RandomNumberGenerator.new()
var plant_id: int = -1
@export var growth_cost: float
@export var energy_cost_per_tick: float
@export var energy_production_type: Dictionary = {"Soil":0, "Light":0, "Heat":0}
@export var stability: float
@export var ideal_heat: float
@export var reproduction_cost: float
@export var reproduction_range: float
var heat: float
var energy_per_tick: float = 0
var actual_energy_per_tick: float
var variant_number: int = 1
var shade: Color
var connector_locations: Array = []
var intersecting_bodies: int = 0
var height: float = 0

func _ready():
	$Part_Sprite.modulate = self.shade
	
	var children_nodes: Array = get_children()
	for i in range(len(children_nodes)):
		if "Connector" in children_nodes[i].name:
			connector_locations.append( children_nodes[i].get_global_position() )
			
	var temp_energy_production_type = energy_production_type.duplicate(true)
	
	var temp_tile = Global.get_tile($Part_Sprite.get_global_position())
	
	if temp_tile not in Global.World_Dict:
		pass
	else:
		var local_tile: Global.tile_data = Global.World_Dict[ temp_tile ]
	
	
		#energy_per_tick
		temp_energy_production_type['Light'] = min(temp_energy_production_type['Light'], local_tile.light) / max(1,Global.compare_colors(shade,Global.ideal_photosynthesis_color))
		temp_energy_production_type['Heat'] = min(temp_energy_production_type['Heat'], local_tile.heat )
		temp_energy_production_type['Soil'] =min(temp_energy_production_type['Soil'], local_tile.use_fertility )
		
		var unmodified_stability: float = stability
		
		#if part_type == "Leaf":
		#	print($Part_Sprite.get_global_position().y + local_tile.height)
		var distance_from_ground = -1 * ($Part_Sprite.get_global_position().y + local_tile.height) 
		#print(distance_from_ground)
		if distance_from_ground < -1:
			energy_cost_per_tick += temp_energy_production_type['Light']
			temp_energy_production_type['Light'] = 0
			
		elif distance_from_ground > 1:
			temp_energy_production_type['Soil'] = 0
			stability /= distance_from_ground
			#print(stability)
			#print(gravity)
			height = distance_from_ground
		else:
			temp_energy_production_type['Soil'] = 0
			temp_energy_production_type['Light'] = 0
			temp_energy_production_type['Heat'] = 0
		
		if distance_from_ground > 1:
			if (unmodified_stability * distance_from_ground * local_tile.gravity)/1000 > Global.Plant_Dict[plant_id].Stability:
				
				#print("grav")
				temp_energy_production_type['Soil'] = 0
				temp_energy_production_type['Light'] = 0
				temp_energy_production_type['Heat'] = 0
				$Part_Sprite.hide()
				return null
				
		#print(temp_energy_production_type)
		

		for entry in temp_energy_production_type:
			energy_per_tick += temp_energy_production_type[entry]

		energy_per_tick -= temp_energy_production_type['Light']

		
		energy_production_type['Light'] = temp_energy_production_type['Light']
		#if part_type in ["Leaf","Root"]:
		#	print(energy_per_tick)
		#	print(energy_cost_per_tick)
		
		heat += local_tile.heat
		
		#if part_type != "Leaf":
		energy_cost_per_tick *= max(1,Global.compare_colors(shade,Global.ideal_energy_loss_color))
		#print(energy_cost_per_tick)
		energy_cost_per_tick *= Global.energy_cost_balancer

func update_parent(unique_id: int) -> void:
	
	var parent_plant = Global.Plant_Dict[unique_id]
	
	var temp_tile = Global.get_tile(parent_plant.Location)
	var local_tile: Global.tile_data = Global.World_Dict[ temp_tile ]
	
	
	parent_plant.Energy_Per_Tick += energy_per_tick
	parent_plant.Light_Energy_Per_Tick += energy_production_type['Light']
	parent_plant.Energy_Cost_Per_Tick += energy_cost_per_tick
	parent_plant.Energy -= growth_cost
	parent_plant.Available_Connectors += connector_locations
	parent_plant.Max_Stored_Energy += growth_cost
	parent_plant.Stability += stability
	parent_plant.Heat += heat
	parent_plant.Ideal_Heat.append(ideal_heat)
	
	if height > parent_plant.Height and part_type == "Leaf":
		
		local_tile.plant_heights.erase(parent_plant.Height)

		parent_plant.Height = height
		local_tile.plant_heights.append(height)
	
	
	if part_type == "Flower":
	
		RNG.randomize()
		
		#print("===")
		#print(reproduction_range)
		reproduction_range *= min(10,max(1,height / local_tile.gravity))
		#print(reproduction_range)
		#print("===")
		if len(parent_plant.Flowers) == 1:
			parent_plant.Flowers["-1"] = [reproduction_cost,reproduction_range]
		else:
			parent_plant.Flowers[str(RNG.randi_range(0,1000))] = [reproduction_cost,reproduction_range]

func check_overlap() -> void:
	
	var all_intersecting: Array = $Area2D.get_overlapping_areas() 
	
	if len(all_intersecting) > 0:
		for i in range(len(all_intersecting)):
			if all_intersecting[i].get_parent().plant_id != plant_id:
				if all_intersecting[i].get_parent().plant_id in Global.Plant_Dict:
					
					get_parent().die( Global.Plant_Dict[ all_intersecting[i].get_parent().plant_id ] )
	
	intersecting_bodies = len( $Area2D.get_overlapping_areas() )
	
	if intersecting_bodies > Global.intersection_floor:
		actual_energy_per_tick = energy_per_tick / (intersecting_bodies * Global.intersection_energy_falloff) - energy_cost_per_tick
	else:
		actual_energy_per_tick = energy_per_tick - energy_cost_per_tick
