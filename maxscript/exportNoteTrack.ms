clearListener()

struct  TNotesExporter (
	
	fn exportNotes = (
		local export_path = getSavePath caption:"Export Notes to path:"\
		historyCategory: "Export Notes"
		if export_path == undefined then return false
		export_path = export_path + "\\"
		local baseName = getFilenameFile(maxfilename)
		if baseName == "" then (
			MessageBox "Save MaxFile First, this function uses the max filename."
			return false
		)
		local fullPath = export_path + baseName + ".note"

		nt = numNoteTracks rootScene
		if nt == 0 then (
			MessageBox "There's no notetrack in the rootScene."
			return false
		)

		nt = getNoteTrack rootScene 1
		if nt.keys.count == 0 then(
			MessageBox "Nothing to export."
			return false
		)

		fs = TJsonFormatter()
		fs.begin fullPath
		fs.beginArray()
		key_num = 0
		for key_idx = 1 to nt.keys.count do (
			if nt.keys[key_idx].value == "" then continue	
			if(key_idx != 1) then fs.writeComma()
			fs.beginObj()
			fs.writeKeyValue "time" ((getNoteKeyTime nt key_idx)as integer / 4800.0) --Juan Magic Number: converts frame number to time.
			fs.writeComma()
			fs.writeKeyValue "note" nt.keys[key_idx].value
			fs.endObj()
		)
		fs.endArray()
		fs.end()
		fs = undefined
		return true
	)
	
)

--gc()
--se = TSkeletonsExporter()
--se.exportSkelAndMeshes()
--se.exportAnim()