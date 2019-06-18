

fn isValidPath aname = (
		-- Add no �, accents, etc.
		local ok = true
		ok = ok and findString aname " " == undefined

		if not ok then (
			throw ("Developers say: Name has a space. Please remove spaces from name:\n" + aname)
		)

		ok = ok and findString aname "á" == undefined
		ok = ok and findString aname "é" == undefined
		ok = ok and findString aname "í" == undefined
		ok = ok and findString aname "ó" == undefined
		ok = ok and findString aname "ú" == undefined
		ok = ok and findString aname "Á" == undefined
		ok = ok and findString aname "É" == undefined
		ok = ok and findString aname "Í" == undefined
		ok = ok and findString aname "Ó" == undefined
		ok = ok and findString aname "Ú" == undefined
		
		ok = ok and findString aname "ñ" == undefined
		ok = ok and findString aname "Ñ" == undefined

		if not ok then (
			throw ("Developers say: Name has an accent. Please remove accents from name:\n" + aname)
		)

		ok = ok and findString aname "%" == undefined
		ok = ok and findString aname "$" == undefined
		ok = ok and findString aname "\"" == undefined
		ok = ok and findString aname "!" == undefined
		ok = ok and findString aname "\'" == undefined

		if not ok then (
			format "NOT OK: %\n" aname
			throw ("Developers say: Name has a symbol. Please remove symbols from name:\n" + aname )
		)

		return ok
	)

	fn isValidName aname = (
		local ok = true;
		ok = isValidPath(aname)
		ok = ok and findString aname ":" == undefined
		if not ok then (
			format "NOT OK: %\n" aname
			throw ("Developers say: Name has a ':'. Please remove ':' from name:\n" + aname )
		)
	)


-- ----------------------------------------------------------
-- ----------------------------------------------------------
-- ----------------------------------------------------------
struct TMaterialExporter (
	
	fs = TJsonFormatter(), 
	export_path,                 -- Asigned in the ctor 
	base_path,                 -- Asigned in the ctor
	mats_dir,
	mats_export_path,
	textures_dir,
	textures_export_path,

	
	




	fn exportMap map alias default_value = (
		
		if map == undefined then (
			local json_filename = "data/textures/" + default_value + ".dds" --default textures inside data/textures/...
			fs.writeKeyValue alias json_filename
			return false
		)
		
		-- "C:\users\pep\desktop\download\bricks.dds"
		local map_filename = map.filename
		
		-- bricks
		local base_name = getFilenameFile map_filename
		
		-- "C:\usrs\...\MyScene\textures\"
		local outputDir = export_path + textures_export_path

		local texconv_path = getDir #userStartupScripts
		texconv_path += "/../../tools/"


		local extraParams = ""
		if alias == "albedo" then (
			extraParams = "-f R8G8B8A8_UNORM_SRGB"
		)
		else (
			extraParams = "-f R8G8B8A8_UNORM"
		)

		-- check all paths are free from spaces and other symbols!
		isValidPath(texconv_path)
		isValidPath(outputDir)
		isValidPath(map_filename)


		local texconv_command = texconv_path + "texconv -o " + outputDir + " " + extraParams + " " + map_filename
		format "running command:\n %\n" texconv_command		

		DOSCommand(texconv_command)
		
		-- textures\bricks.dds"
		local json_filename = textures_dir + base_name + ".dds"
		fs.writeKeyValue alias json_filename
	),
	
	-- exports minion.material, to be used as a default mat with no textures
	fn exportDefaultMaterial = (
		local fullExportPath = export_path + mats_export_path

		fs.begin (fullExportPath + "minion.material" )
		fs.beginObj()
			fs.writeKeyValue "technique" "objs.tech" 
			fs.writeComma()
			fs.writeKeyValue "shadows" true 
			fs.writeComma()
			fs.writeKey "textures" 
			fs.beginObj()
				fs.writeKeyValue "albedo" "data/textures/white.dds"
			fs.endObj()
		fs.endObj()
		fs.end()
	),
	
	-- Exports a single std material to a json format
	fn exportStdMaterial mat mat_name = (
		format "Exporting material % % %\n" mat_name mat (classof mat as string)
		
		--print( "CHECKING IF NAME " + mat_name + " IS VALID" )
		isValidName( mat_name )
		
		local fullMatExportPath = export_path + mats_export_path + mat_name + ".material"

		fs.begin (fullMatExportPath )
		fs.beginObj()
		  --Will use the defaults set in the parser. Needs to be a full data/techniques/textured.tech"
			--fs.writeKeyValue "technique" "textured.tech"
			--fs.writeComma()
			--fs.writeKeyValue "shadows" true
			--fs.writeComma()
			fs.writeKey "textures" 
			fs.beginObj()
			
			--link to material description page : https://help.autodesk.com/view/3DSMAX/2016/ENU/?guid=__files_GUID_57F5EBBA_5F54_4CD4_8993_0B07A3571293_htm
			if classof mat == Standardmaterial then (
				exportMap mat.diffusemap "albedo" "defaults/null_albedo"
					fs.writeComma()
				exportMap mat.specularLevelMap "roughness" "defaults/white"
					fs.writeComma()
				exportMap mat.glossinessMap "metallic" "defaults/metal004"
			    fs.writeComma()
				exportMap mat.bumpMap "normal" "defaults/null_normal"
					fs.writeComma()
				exportMap mat.selfIllumMap "emissive" "defaults/black"
					fs.writeComma()
				exportMap mat.ambientMap "ao" "defaults/white"
					--fs.writeComma()
				-- ... other maps..
			)
		
			fs.endObj()
		fs.endObj()
		fs.end()
	),
	
	-- Will return an array of all the materials names used by obj and exported by us
	fn exportMaterial mat obj = (
		
		local exported_materials = #()
		local mats_JSON_path = mats_dir 

		if classof mat == StandardMaterial then (
			local mat_JSON_name = mats_JSON_path + mat.name + ".material"
			if mat.name == "minion" then mat_JSON_name = "data/materials/minion.material" --change to engine path if using minion material
			append exported_materials mat_JSON_name
			
			exportStdMaterial mat mat.name
			
		) else if classof mat == MultiMaterial then (
			local multi_mat = mat
			
			local materials_of_mesh = getMaterialsUsedByMesh obj
			for mat_idx = 1 to materials_of_mesh.count do (
				if materials_of_mesh[ mat_idx ] == undefined then continue
				local mat_of_mesh = multi_mat[ mat_idx ]
				
				if mat_of_mesh == undefined then throw ("Mesh " + obj.name + " is using a multimaterial in slot " + (mat_idx as string)+ " but the multimat does not have this submat")
				if classof mat_of_mesh != StandardMaterial then throw ("Mesh " + obj.name + " is using a multimaterial in slot " + (mat_idx as string) + " but the multimat in this slot is not a stdMaterial")
				
				local mat_JSON_name = mats_JSON_path + mat_of_mesh.name + ".material"
				if mat_of_mesh.name == "minion" then mat_JSON_name = "data/materials/minion.material" --change to engine path if using minion material
				append exported_materials mat_JSON_name

				exportStdMaterial mat_of_mesh mat_of_mesh.name
			)
		-- when using DummyMats, generate 'minion' material on the run
		) else if mat == undefined then(
			append exported_materials "data/materials/minion.material"
		)
		
		return exported_materials -- to be written into JSON
	)

	
)

--gc()
--me = TMaterialExporter project_path:"c:/code/engine/bin/" base_path:"data/"
--me.exportMaterial $.mat "data/materials/" $
