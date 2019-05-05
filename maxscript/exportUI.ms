
callbacks.removeScripts #selectionSetChanged id:#myCallbackID

utility MyMCVExporter "MCV Exporter"
(
	
	rollout currSelection "Current Selection"(

		label selectedTitle "current Object:"
		label selected ""

		checkbox collider_check "collider" checked:false enabled:false
		checkbox trigger_check "trigger" checked:false enabled:true

		dropdownlist filterGroup "Filter Group:" items:#("floor", "wall", "none")
		checkbox kinematic_check "kinematic" checked:false enabled:true





		fn GetSelectedObject = (
			if selection.count == 0 then (
				selected.text = "No objects selected"
				return undefined
			)
			else if selection.count > 1 then (
				selected.text =  "Too many objects selected"
				return undefined
			)
			else(
				selected.text = selection[1].name
				return selection[1]
			)
		)

		--filter group ------------------------------------------------
		
		fn disaplayFilterGroup obj = (
			if obj == undefined then (
				filterGroup.visible = false
			)else(
				filterGroup.visible = true
				local fgroup = getUserProp obj "group"
				if fgroup == "floor" then(
					filterGroup.selection = 1
				) else if fgroup == "wall" then (
					filterGroup.selection = 2
				) else (
					filterGroup.selection = 3
				)

			)
		)

		on filterGroup selected i do (

			local obj = selection[1]
			if obj != undefined then (
				setUserProp obj "group" filterGroup.items[i]
			)

		)
		--end filtergroup -------------------------------------------------

		--kinematic check ----------------------------------------------------
		fn displayKinematicCheck obj = (
			kinematic_check.visible = true
			local kinematic = getUserProp obj "kinematic"
			if kinematic != undefined and kinematic == true then(
				kinematic_check.checked = true
			)else(
				kinematic_check.checked = false
			)


		)

		on kinematic_check changed state do (

			local obj = selection[1]
			--if it's a collider with parent, get parent
			if obj.parent != undefined then obj = obj.parent
			
			setUserProp obj "dynamic" state
			setUserProp obj "kinematic" state
		)

		--end kinematic check -----------------------------------------------

		--trigger check ----------------------------------------------------
		fn displayTriggerCheck obj = (
			if obj == undefined then (
				trigger_check.visible = false
			)else(
				trigger_check.visible = true
				if isTrigger(obj) then (
					trigger_check.checked = true
				)else(
					trigger_check.checked = false
				)
			)
		)

		
		on trigger_check changed state do (
			local obj = selection[1]
			if classof obj == Sphere or classof obj == GeoSphere or classof obj == Box then (
				setUserProp obj "trigger" state
			)else(
				MessageBox ("Object needs to be box or sphere to be collider!\n")
				trigger_check.checked = false
			)

			
		)
		--end trigger check

		--collider check----------------------------------------------------

		fn displayColliderCheck obj = (
			if obj == undefined then (
				collider_check.visible = false
			)else(
				collider_check.visible = true	
			)

			--display/hide collider-related stuff
			if isCollider(obj) then (
				collider_check.checked = true
				local parent = obj.parent
				disaplayFilterGroup(obj)
				displayKinematicCheck(parent)
			)
			else(
				collider_check.checked = false
				filterGroup.visible = false
				kinematic_check.visible = false
			)

		)

		--end collider_check ------------------------------------------------- 

		fn disaplayValues obj = (
			displayColliderCheck(obj)

			-- object can be trigger without being collider
			displayTriggerCheck(obj)

		)

		fn printSelName = (
			local obj = GetSelectedObject()
			disaplayValues(obj)
		)


    		

	) --end rollout currSelection

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
		addRollout currSelection
		addRollout exporter
	) 
	on MyMCVExporter close do
	(
		removeRollout currSelection
		removeRollout exporter
	) 
) -- end utility MyUtil 

callbacks.addScript #selectionSetChanged "MyMCVExporter.currSelection.printSelName()" id:#myCallbackID