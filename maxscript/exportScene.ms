clearListener()
gc()

fn isCollider obj = (
	return obj != undefined and (findString obj.name "collider" != undefined ) and obj.parent != null
)

fn isTrigger obj = (
	return obj != undefined and obj.layer.name == "triggers"
)

fn isCheckPoint obj = (
	return obj != undefined and (findString obj.name "trigger_checkpoint_" != undefined)
)

fn isTriggerLava obj = (
	return obj != undefined and (findString obj.name "trigger_lava" != undefined)
)

----------------------------------------------------------
struct TSceneExporter (

	fs = TJsonFormatter(), 
	-- export_path = "c:/code/engine/bin/",
	export_path = getDir #export + "\\",
	base_path = "data/",
	current_scene_name,
	scenes_path = base_path + "scenes/",
	mesh_path = base_path + "meshes/",
	mats_path = base_path + "materials/",
	textures_path = base_path + "textures/",
	
	fn exportCompName obj = (
		fs.writeKeyValue "name" obj.name
	),
	
	fn isValidName aname = (
		return findString aname " " == undefined 
	),

	----------------------------------------------------------
	fn exportTransform obj = (
		fs.writeComma()
		fs.writeKey "transform" 
		
		local max2mcv = rotateXMatrix -90
		local mcv2max = rotateXMatrix 90
		local mcv_position = obj.position * max2mcv
		
		-- From mcv, we will go to max, apply the max transform and go back to mcv coord system
		local mcv_transform = mcv2max * obj.transform * max2mcv

		-- Take just the rotation as quaterion
		local mcv_quat = mcv_transform.rotationPart as quat
		
		fs.beginObj()
			fs.writeKeyValue "pos" mcv_position
			fs.writeComma()
			fs.writeKeyValue "rotation" mcv_quat
		fs.endObj()
	),

	----------------------------------------------------------

	fn exportCheckPoint obj = (
		fs.writeComma()
		fs.writeKey "checkpoint"

		local index = ((substring obj.name 20 1) as Integer)
		fs.beginObj()
			fs.writeKeyValue "index" index
		fs.endObj()
	),

	fn exportTriggerLava obj = (
		fs.writeComma()
		fs.writeKey "damage_on_contact"

		fs.beginObj()
			fs.writeKeyValue "damage" 1000
		fs.endObj()
	),
	
	----------------------------------------------------------
	fn exportEditableMesh obj = (
		
		fs.writeComma()
		fs.writeKey "render" 
		fs.beginObj()
		local mesh_name = mesh_path + current_scene_name + "_" + obj.name + ".mesh"

		--local texture_name = mats_path + obj.name
		fs.writeKeyValue "mesh" mesh_name
		fs.writeComma()
		fs.writeKeyValue "color" obj.wireColor
		
		-- Export the real mesh
		local full_mesh_filename = export_path + mesh_name
		format "full_mesh_filename is %\n" full_mesh_filename
		exportMesh obj full_mesh_filename undefined
		
		-- Export material(s)
		local mat = obj.material
		if mat == undefined then (
			throw ("Obj " + obj.name + " does NOT have a material")
		)
		local me = TMaterialExporter export_path: export_path base_path:base_path
		local exported_materials = me.exportMaterial mat mats_path obj
		
		fs.writeComma()
		fs.writeKey "materials"
		fs.arrayOfStrings exported_materials
			
		fs.endObj()
	),
	
	-- ----------------------------------------------------------
	fn exportCompShape obj = (
		
		fs.beginObj()
		
		if classof obj == Sphere or classof obj == GeoSphere then (
			fs.writeKeyValue "shape" "sphere"
			fs.writeComma()
			fs.writeKeyValue "radius" obj.radius
			
		) else if classof obj == Box then (
			fs.writeKeyValue "shape" "box"
			fs.writeComma()
			local half_size =  ( [abs obj.width, abs obj.height, abs obj.length] * 0.5)
			-- Warning, order might be incorrect!!!
			fs.writeKeyValue "half_size" half_size
			fs.writeComma()
			fs.writeKey "offset"
			fs.beginObj()
				fs.writeKeyValue "pos" [0, half_size.y, 0]
			fs.endObj()
		
			convexmes
			
		) else if classof obj == Editable_Mesh then (
			fs.writeKeyValue "shape" "trimesh"
			fs.writeComma()
			-- Warning, order might be incorrect!!!
			local mesh_name = mesh_path + current_scene_name + "_" + obj.parent.name + ".col_mesh"
			local full_mesh_filename = export_path + mesh_name
			exportMesh obj full_mesh_filename "Pos"
			
			fs.writeKeyValue "collision_mesh" mesh_name
		)
		local px_group = getUserProp obj "group"
		if px_group != undefined then (
			fs.writeComma()
			fs.writeKeyValue "group" px_group
		)
		
		local px_mask = getUserProp obj "mask"
		if px_mask != undefined then (
			fs.writeComma()
			fs.writeKeyValue "mask" px_mask
		)
		
		local is_kinematic = getUserProp obj "kinematic"
		if is_kinematic != undefined then (
			fs.writeComma()
			fs.writeKeyValue "kinematic" true
		)
		
		if obj.layer.name == "triggers" then (
			fs.writeComma()
			fs.writeKeyValue "trigger" true
		)
		
		fs.endObj()
	
	),
	
	fn exportCompCollider obj candidates = (
		
		fs.writeComma()
		fs.writeKey "collider" 
		fs.beginObj()
		
		fs.writeKey "shapes"
		fs.beginArray()
			local n = 0
			for child in candidates do (
				if n > 0 then fs.writeComma()
				exportCompShape child
				n = n + 1
			)
		fs.endArray()

		
		-- Add it in the user properties panel of max:     density = 10
		local density = getUserProp obj "density"
		if density != undefined then (
			fs.writeComma()
			fs.writeKeyValue "density" density
		)
		
		local is_dynamic = getUserProp obj "dynamic"
		if is_dynamic != undefined then (
			fs.writeComma()
			fs.writeKeyValue "dynamic" is_dynamic
		)
		
		local is_kinematic = getUserProp obj "kinematic"
		if is_kinematic != undefined then (
			fs.writeComma()
			fs.writeKeyValue "kinematic" true
		)
		
		fs.endObj()
	),
	
	
	fn exportChildrenColliders obj = (
		
		local candidates = #()
		for child in obj.children do (
			if isCollider child or isTrigger child then append candidates child
		)
		
		if isTrigger obj then candidates = #(obj)
		
		if candidates.count == 0 then return undefined
		
		format "Candidates are %\n" candidates
		--return true
		
		exportCompCollider obj candidates
	),
	
	----------------------------------------------------------
	fn exportEntity obj = (
		fs.beginObj()
		fs.writeKey "entity"
			fs.beginObj()
			exportCompName obj
			exportTransform obj
		
			local nCA = custAttributes.count obj
			for idx = 1 to nCA do (
				local ca_data = custAttributes.get obj idx
				ca_data.exportAsComponent fs
			)

			if isCheckPoint obj then (
				exportCheckPoint obj
			)

			if isTriggerLava obj then (
				exportTriggerLava obj
			)
			
			exportChildrenColliders obj
		
			if not isTrigger obj then (
			--if classof obj == Camera then exportCamera obj
				if canConvertTo obj Editable_mesh then exportEditableMesh obj
			--else (
			--	format "Warning. Don't kwow how to export obj % of class %\n" obj.name ((classof obj) as string)
			)
			fs.endObj()
		fs.endObj()
	),
	
	fn exportAll = (
		print ("CHECKING " + export_path + scenes_path)
		print ("CHECKING " + export_path + mesh_path)
		print ("CHECKING " + export_path + mats_path)
		makeDir (export_path + scenes_path)
		makeDir (export_path + mesh_path)
		makeDir (export_path + mats_path)
		makeDir (export_path + textures_path)

		-- Decide output filename based on .max filename
		current_scene_name = getFilenameFile maxFileName
		local full_path = export_path + scenes_path + current_scene_name + ".json"
		format "Exporting to % %\n" full_path  current_scene_name
		fs.begin full_path
		fs.beginArray()
		
		local nitems = 0
		for obj in $* do (
			if isCollider obj then continue
			if nitems > 0 then  fs.writeComma()
			format "Exporting entity: % \n" obj.name
			exportEntity obj
			nitems = nitems + 1
		)
		
		fs.endArray()
		fs.end()

		local me = TMaterialExporter export_path: export_path base_path:base_path
		local matPath = export_path + mats_path
		me.exportDefaultMaterial matPath
		
	)
	
	
)
	
--exporter = TSceneExporter()
--exporter.exportAll()
