utility MyMCVExporter "MCV Exporter"
(
	
	rollout exporter "The Exporter"
	(
		
		button btn_scene "Export Scene"
		button btn_mesh "Export Mesh"
		button btn_prefab_atts "Add Prefab Attributes"
		button btn_skeleton "Export Skeleton & Meshes"
		button btn_skel_anims "Export Animation" tooltip:"Uses max animation range and frame rate to specify the range to export"
		button btn_reset "Reset Model" tooltip:"Attaches model to sphere to reset it and then deletes sphere"
		
		on btn_scene pressed do
		(
			try (
				gc()
				local p = getDir #export + "\\"
				local export_path = getSavePath caption:"Export Scene to path:"\
					historyCategory: "ExportScene"
				
				-- Check again if inserted savepath is valid
				if export_path == undefined then (
					export_path = p
				) else (
						export_path = export_path + "\\"
				)

				local exporter = TSceneExporter export_path: export_path
				exporter.exportAll()
				MessageBox "All exported OK"
			) catch (
				MessageBox ("Error Exporting:\n" + getCurrentException() + "\n --- Stuff for devs:\n " + getCurrentExceptionStackTrace())
			)
		)
		
		-- Exports the current selection mesh to file
		on btn_mesh pressed do
		(
			try (
				gc()
				local ofilename = undefined  -- to be defined by you.
				exportMesh $ ofilename undefined
				MessageBox "Single mesh exported OK"
			) catch (
				MessageBox ("Error Exporting Single Mesh:\n" + getCurrentException())
			)
		)
		
		-- Exports the current selection mesh to file
		on btn_prefab_atts pressed do
		(
			if $ == undefined then return undefined
			custAttributes.add $ classPrefabData
		)

		-- Exports the current selection mesh to file
		on btn_skeleton pressed do
		(
			
			try (
				gc()
				local se = TSkeletonsExporter()
				se.exportSkelAndMeshes()
				MessageBox "Skeleton And Meshes exported OK"
			) catch (
				MessageBox ("Error Exporting Skeleton:\n" + getCurrentException())
			)
		)
		
		-- Exports the current selection mesh to file
		on btn_skel_anims pressed do
		(
			
			try (
				gc()
				local se = TSkeletonsExporter()
				se.exportAnim()
				MessageBox "Skeleton Animation exported OK"
			) catch (
				MessageBox ("Error Exporting Skeleton Animation:\n" + getCurrentException())
			)
		)

		on btn_reset pressed do(
			try (
				--gc() --don't apply gc because it erases all Undo commands!!
				resetModel $
				MessageBox "Reset Model OK"
			) catch (
				MessageBox ("Error Reseting Model:\n" + getCurrentException())
			)
		)
		
	) -- end rollout creator
		
	-- ...
	on MyMCVExporter open do
	(
		addRollout exporter
	) 
	on MyMCVExporter close do
	(
		removeRollout exporter
	) 
) -- end utility MyUtil 