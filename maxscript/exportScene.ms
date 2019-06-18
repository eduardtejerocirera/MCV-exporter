clearListener()
gc()

fn exportSceneObjs objs baseName export_path base_path is_prefab:false   = () -- forward declaration

fn isCollider obj = (
	return obj != undefined and (findString obj.name "collider" != undefined ) and obj.parent != undefined
)

fn isTrigger obj = (
	if obj != undefined then (
		local is_trigger = getUserProp obj "trigger"
		if is_trigger == undefined then return false
		return is_trigger
	)
	return false
)

fn isCheckPoint obj = (
	return obj != undefined and (findString obj.name "trigger_checkpoint_" != undefined)
)

fn isWayPoint obj = (
	if obj != undefined then(
		local wp = getUserProp obj "waypoint"
		if wp == undefined then return false
		return wp
	)
	return false
)

fn objHasChildWaypoint obj = (
	if obj != undefined and obj.children != undefined and obj.children.count != 0 then(
		for child in obj.children do (
			if isWayPoint child then return true 
		)
	)
	return false
)

fn isTriggerLava obj = (
	return obj != undefined and (findString obj.name "trigger_lava" != undefined)
)

fn isXRefObj obj = (
	return classof obj == XRefObject and not obj.unresolved
)

fn isNameWeird aname = (
	local ok = true
	ok = ok and findString aname "×" == undefined
	ok = ok and findString aname "þ" == undefined
	ok = ok and findString aname "ü" == undefined
	ok = ok and findString aname "¡" == undefined
	ok = ok and findString aname "ý" == undefined
	ok = ok and findString aname "û" == undefined

	return ok
)



fn isSpecialPrefab obj = (
	if obj != undefined then (
		local sPrefab = getUserProp obj "special_prefab"
		return sPrefab != undefined 
	)
	return false
)

----------------------------------------------------------
struct TSceneExporter (

	fs = TJsonFormatter(), 
	baseName = "", -- escena_biblioteca57
	export_path = getDir #export + "\\", -- C:/Users/.../exportDir/
	base_path = "", -- escena_biblioteca57/
	
	scenes_dir = "", -- where .json scenes are stored
	scenes_export_path = base_path  + scenes_dir, -- escena_biblioteca57/

	
	mesh_dir = "meshes/", -- where .mesh meshes are stored
	mesh_export_path = base_path + mesh_dir, -- escena_biblioteca57/meshes/


	mats_dir = "materials/", -- where .material files are stored
	mats_export_path = base_path + mats_dir, -- escena_biblioteca57/materials/


	textures_dir = "textures/", --where .dds textures are stored
	textures_export_path = base_path + textures_dir, -- escena_biblioteca57/textures/

	exportPrefabs = false,
	useDummyMats = false,

	
	fn exportCompName obj = (
		fs.writeKeyValue "name" obj.name
	),
	
	fn isNameWithoutSpaces aname = (
		return findString aname " " == undefined 
	),

	----------------------------------------------------------
	fn extractPosRotFromTransform transform &pos &rot= (
		--directly stolen from exportTransform
		local max2mcv = rotateXMatrix -90
		local mcv2max = rotateXMatrix 90
		local mcv_position = transform.translation * max2mcv
		local mcv_transform = mcv2max * transform * max2mcv

		-- Take just the rotation as quaterion
		local mcv_quat = mcv_transform.rotationPart as quat
		pos = mcv_position
		rot = mcv_quat
	),

	----------------------------------------------------------
	fn exportTransform obj = (
		fs.writeComma()
		fs.writeKey "transform" 
		
		local max2mcv = rotateXMatrix -90
		local mcv2max = rotateXMatrix 90
		local mcv_position = obj.transform.translation * max2mcv
		
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

		local index = ((substring obj.name 20 1) as Integer) -- get checkpoint index from name
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

	fn exportPrefabEntry obj = (
		local filename = getFilenameFile obj.filename
		local prefabPath = "prefabs/" + filename + ".json" -- prebabs/MyPrefab.json
		fs.writeKeyValue "prefab" prefabPath
	),
	---------------------------------------------------------

	fn exportEditableMesh obj = (
		
		fs.writeComma()
		fs.writeKey "render" 
		fs.beginObj()
		local mesh_name = baseName + "_" + obj.name + ".mesh" -- MyScene_mesh001.mesh || MyPrefab_mesh001.mesh
		local mesh_JSON_path = mesh_dir + mesh_name -- entities/meshes/MyScene_mesh001.mesh || MyPrefab_mesh001.mesh
		local full_mesh_path = export_path + mesh_export_path + mesh_name -- C:/Usrs/.../MyScene/entities/meshes/MyScene_mesh001.mesh 
		format "full_mesh_filename is %\n" full_mesh_path

		--local texture_name = mats_path + obj.name
		fs.writeKeyValue "mesh" mesh_JSON_path
		fs.writeComma()
		

		-- for this to work obj needs to be editable mesh. Wer create a copy of the object and convert it into editable Mesh
		local edMesh = obj
		if classof obj != Editable_mesh then (
			edMesh = copy obj
			convertToMesh edMesh
		)

		local mat = edMesh.material

		-- if object does NOt have a mat...
		if mat == undefined then(
			if useDummyMats == true then (
				--If using DummyMats make sure all mat ids are set to the same value so that all faces are visible!
				format "forcing all faces to mat id\n"
				forceAllFacesToMatID edMesh

				local num_faces = getNumFaces edMesh
				for face_id = 1 to num_faces do (
					local mat_id = getFaceMatID edMesh face_id
					format "face % has matID %\n" face_id mat_id
				)
			)else(
				-- If NOT using dummy mats, throw error
				throw ("Obj " + obj.name + " does NOT have a material")
			)
		)

		-- Export the real mesh
		exportMesh edMesh full_mesh_path undefined
		
		--Export materials
		local me = TMaterialExporter export_path:export_path base_path:base_path \
		 mats_dir:mats_dir mats_export_path:mats_export_path \
		 textures_dir:textures_dir textures_export_path:textures_export_path

		local exported_materials = me.exportMaterial mat edMesh

		-- in case we created a copy, delete it
		if obj != edMesh then delete edMesh
		
		fs.writeKey "materials"
		fs.arrayOfStrings exported_materials
		
		--only add wirecolor if object does not have a texture
		if classof mat == StandardMaterial and mat.diffusemap == undefined then (
			fs.writeComma()
			fs.writeKeyValue "color" obj.wireColor
		)


			
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
				local pos
				local rot
				extractPosRotFromTransform obj.transform &pos &rot
				fs.writeKeyValue "pos" [pos.x, pos.y+half_size.y, pos.z]

			fs.endObj()
		
			convexmes
			
		) else if classof obj == Editable_Mesh or classof obj == Editable_Poly or classof obj == PolyMeshObject then (
			fs.writeKeyValue "shape" "trimesh"
			fs.writeComma()
			-- Warning, order might be incorrect!!!
			local mesh_name = baseName + "_" + obj.parent.name + ".col_mesh"
			local full_mesh_filename = export_path + mesh_export_path + mesh_name
			exportMesh obj full_mesh_filename "Pos"
			
			local mesh_JSON_path = mesh_dir + mesh_name
			fs.writeKeyValue "collision_mesh" mesh_JSON_path
		)
		else (
			throw ("collider with name: " + obj.name + " and parent named: " + obj.parent.name + " is not sphere, box or trimesh!")
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
			fs.writeKeyValue "kinematic" is_kinematic
		)
		
		if isTrigger obj then (
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
		
		
		
		local is_kinematic = getUserProp obj "kinematic"
		if is_kinematic != undefined then (
			-- an object CANNOT be kinematic without being dynamic, so set it to dynamic anyways
			fs.writeComma()
			fs.writeKeyValue "dynamic" is_kinematic
			fs.writeComma()
			fs.writeKeyValue "kinematic" is_kinematic
		)else (
			-- check only if dynamic
			local is_dynamic = getUserProp obj "dynamic"
			if is_dynamic != undefined then (
				fs.writeComma()
				fs.writeKeyValue "dynamic" is_dynamic
			)
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

	fn exportChildrenWaypoints obj = (
		fs.writeComma()
		fs.writeKey "waypoints" 


		local waypoints = #()

		local n = 0
		for child in obj.children do (
			if isWayPoint child then(
				local max2mcv = rotateXMatrix -90
				local pos = child.transform.translation * max2mcv
				append waypoints pos
			)
		)

		fs.beginArray()
		local n = 0
		for p in waypoints do (
			if n > 0 then fs.writeComma()
			fs.writeValue p
			n = n + 1
		)
		fs.endArray()

	),
	
	----------------------------------------------------------
	fn exportEntity obj = (
		fs.beginObj()
		fs.writeKey "entity"
			fs.beginObj()

			if isXRefObj obj then (
				exportPrefabEntry obj
				fs.writeComma()
				exportCompName obj
				exportTransform obj
				if objHasChildWaypoint obj then (
					exportChildrenWaypoints obj
				)
				fs.endObj()
				fs.endObj()
				return true
			)
			
			exportCompName obj
			exportTransform obj
		
			local nCA = custAttributes.count obj
			for idx = 1 to nCA do (
				local ca_data = custAttributes.get obj idx
				ca_data.exportAsComponent fs
			)

			--adds checkpoint component
			if isCheckPoint obj then (
				exportCheckPoint obj
			)

			--adds damage_on_contact component
			if isTriggerLava obj then (
				exportTriggerLava obj
			)

			if objHasChildWaypoint obj then (
				exportChildrenWaypoints obj
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
	
	fn existsFilenameInSet setNames filename = (
		local exists = false
		for n in setNames do (
			if filename == n then (
				return true
			)
		)
		return false
	),

	fn exportXrefObjects xrefNames = (
		for xrName in xrefNames do(
			local objects = #()

			local fullxrName = xrefPaths.getFullFilePath xrName
			format "fullxrName : %\n" fullxrName
			mergeMaxFile fullxrName #noredraw #autoRenameDups #useMergedMtlDups mergedNodes:&objects
			local new_export_path = export_path + base_path -- C:/usrs/.../escena_biblioteca57/
			local prefabBaseName = getFileNameFile xrName
			local prefabBasePath = baseName + "/" -- myPrefab/
			format "exporting prefab: %\n" prefabBasePath
			format "objs: %\n" objects.count
			format "basname: %, new_export_path: %, prefabBasePath: %\n" prefabBaseName new_export_path prefabBasePath
			local deleted = false
			try(
				--exportSceneObjs objects baseName new_export_path prefabBasePath true useDummyMats is_prefab:true 
				exporter = TSceneExporter exportPrefabs:true baseName:prefabBaseName export_path:new_export_path base_path:"prefabs/"\
		 			scenes_dir:"" mesh_dir: "../meshes/" mats_dir: "../materials/" textures_dir: "../textures/" useDummyMats:useDummyMats 

		 		exporter.exportObjects(objects)
			)catch(
				delete objects -- in case of error delete merged objects
				deleted = true
				throw()
			)

			if not deleted then delete objects
		)
	),

	fn exportSpecialPrefab obj = (
		fs.beginObj()
		fs.writeKey "entity"
			fs.beginObj()
			local sPrefab = getUserProp obj "special_prefab"
			local prefabPath = "data/prefabs/" + sPrefab + ".json"
			fs.writeKeyValue "prefab" prefabPath
			fs.writeComma()
			exportCompName obj
			exportTransform obj

			if objHasChildWaypoint obj then (
				exportChildrenWaypoints obj
			) 

			fs.endObj()
		fs.endObj()
	),

	fn exportObjects objs = (

		local full_scenes_path = export_path + base_path + scenes_dir
		local full_mesh_path = export_path + base_path + mesh_dir
		local full_mats_path = export_path + base_path + mats_dir
		local full_textures_path = export_path + base_path + textures_dir

		print ("CHECKING Scenes path: " + full_scenes_path)
		print ("CHECKING mesh path: " + full_mesh_path)
		print ("CHECKING mats path: " + full_mats_path)
		print ("CHECKING textures path: " + full_textures_path)

		if not doesDirectoryExist(full_scenes_path) then makeDir (full_scenes_path)
		if not doesDirectoryExist(full_mesh_path) then makeDir (full_mesh_path)
		if not doesDirectoryExist(full_mats_path) then makeDir (full_mats_path)
		if not doesDirectoryExist(full_textures_path) then makeDir (full_textures_path)

		local jsonPath = full_scenes_path + baseName + ".json"
		format "Exporting to % --> %\n" jsonPath  baseName

		fs.begin jsonPath
		fs.beginArray()
		
		local xrefNames = #()

		local nitems = 0
		for obj in objs do (
			
			if not isNameWeird(obj.name) do continue --quietly skip weird objects

			if isXRefObj obj then (
				if not existsFilenameInSet xrefNames obj.filename then append xrefNames obj.filename
			)

			if isCollider obj or isWayPoint obj then continue

			if nitems > 0 then  fs.writeComma()
			nitems = nitems + 1

			if isSpecialPrefab obj then (
				format "Exporting special prefab: % \n" obj.name
				exportSpecialPrefab obj
			) else (
				format "Exporting entity: % \n" obj.name
				exportEntity obj
			)

		)
		
		fs.endArray()
		fs.end()

		if exportPrefabs then(
			print xrefNames
			exportXrefObjects xrefNames
		)

		--export minion.material
		local me = TMaterialExporter export_path: export_path base_path:base_path
		me.exportDefaultMaterial
		
	)
	
	
)



--------------------------------------------------------------------------------------

fn exportSceneObjs objs baseName export_path base_path export_prefabs useDummyMats is_prefab:false   = (

	local exporter
	if is_prefab == true then(
		-- it's prefab, all exported to same directory
		--exporter = TSceneExporter exportPrefabs:export_prefabs baseName:baseName export_path:export_path base_path:base_path\
		 --scenes_dir:"" mesh_dir:"" mats_dir:"" textures_dir:"" useDummyMats:useDummyMats 

		 export_path = export_path + baseName + "/" --C:/Usrs/.../MyPrefab/
		 exporter = TSceneExporter exportPrefabs:export_prefabs baseName:baseName export_path:export_path base_path:"prefabs/"\
		 	scenes_dir:"" mesh_dir: "../meshes/" mats_dir: "../materials/" textures_dir: "../textures/" useDummyMats:useDummyMats
	)else(
		-- not a prefab, export in folder
		exporter = TSceneExporter exportPrefabs:export_prefabs baseName:baseName export_path: export_path base_path:base_path\
		 useDummyMats:useDummyMats
	)

	exporter.exportObjects(objs)

)
	
--exporter = TSceneExporter()
--exporter.exportAll()
