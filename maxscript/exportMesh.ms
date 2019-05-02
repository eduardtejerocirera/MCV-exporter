clearListener()

struct TMeshSubGroup (
	first_idx,
	num_indices,
	material_index,
	user_material_id
)

function getMaterialsUsedByMesh obj = (
	-- Get faces by material id
	local num_faces = getNumFaces obj
	local faces_by_mat = #()
	for face_id = 1 to num_faces do (
		local mat_id = getFaceMatID obj face_id
		if faces_by_mat[ mat_id ] == undefined then (
			faces_by_mat[ mat_id ] = #()
		)			
		append faces_by_mat[ mat_id ] face_id
	)
	return faces_by_mat
)


function writeChunk fs id nbytes = (
	WriteLong fs id #unsigned
	WriteLong fs nbytes #unsigned
)

function writeMeshToFile outfilename verts idxs vtxType subgroups = (
	
	local magicHeader = 0x44444444
	local magicVtxs = 0x55554433
	local magicIdxs = 0x55556677
	local magicSubGroups = 0x55556688
	local magicEof = 0x55009988
	
	-- Create File
	local fs = fopen outfilename "wb"
	if fs == undefined then throw ( "Can't create file " + outfilename )
	
	local numFaces = idxs.count
	local bytes_per_float = 4
	local num_floats = verts[1].count
	local primitive_triangles = 4
	local bytes_per_vertex = num_floats * bytes_per_float
	-- 16 bits (2 bytes) allow 65536 indices
	local bytes_per_index = 2
	if verts.count > 65535 then bytes_per_index = 4
	format "Saving % %\n" outfilename bytes_per_index
	
	-- Write Header
	local headerSize = 16 + 16 + 32
	writeChunk fs magicHeader headerSize	-- 8 bytes
	
	WriteLong fs numFaces
	WriteLong fs verts.count
	WriteLong fs idxs.count
	WriteLong fs primitive_triangles
	
	WriteLong fs bytes_per_index
	WriteLong fs bytes_per_vertex
	WriteLong fs subgroups.count   -- Num SubGroups
	WriteLong fs 0
	
	-- Write the vertex type as 32 bytes string with zero paddings
	WriteString fs vtxType
	for i = vtxType.count+1 to 31 do WriteByte fs 0
	
	-- Write Verts
	local vertexsSize = verts.count * bytes_per_vertex
	writeChunk fs magicVtxs vertexsSize	-- 8 bytes
	for vtx in verts do (		-- For each vertex
		for c in vtx do (		-- For each component of the vertex
			writeFloat fs c		-- Write the value
		)
	)
	
	-- Write Idxs
	local idxsSize = idxs.count * bytes_per_index
	writeChunk fs magicIdxs idxsSize	
	if bytes_per_index == 2 then (
		for idx in idxs do (
			writeShort fs (idx-1) #unsigned		-- Write 2 bytes
		)
	) else if bytes_per_index == 4 then (
		for idx in idxs do (
			writeLong fs (idx-1) #unsigned		-- Write 4 bytes
		)
	)
	-- Save subgroups
	local bytes_per_subgroup = 4 * 4			-- 4 ints
	local bytes_subgroups = subgroups.count * bytes_per_subgroup
	writeChunk fs magicSubGroups bytes_subgroups
	for sg in subgroups do (	-- Each subgroup
		writeLong fs sg.first_idx #unsigned
		writeLong fs sg.num_indices #unsigned
		writeLong fs sg.material_index #unsigned
		writeLong fs sg.user_material_id #unsigned
	)
	
	writeChunk fs magicEof 0	
	
	-- Close file
	fclose fs
	
)


----------------------------------------------------------
-- Based on the code at
-- http://www.terathon.com/code/tangent.html
function computeTangentSpace vertexs idxs = (
	local tan1 = #()
	local tan2 = #()
	
	local vertexCount = vertexs.count
	
	-- Init the array with zeros
	for i = 1 to vertexCount do (
		tan1[ i ] = [0,0,0]
		tan2[ i ] = [0,0,0]
	)
	
	
	local triangleCount = idxs.count / 3
	local a = 0
	while a < triangleCount do (
		local index_base = a * 3 + 1		-- +1 because max scripts starts at 1
		
		local i1 = idxs[index_base+0]
		local i2 = idxs[index_base+1]
		local i3 = idxs[index_base+2]

		-- Our vertexs are arrays of floats... ( position.xyz, normal.xyz, uv.xy, .. )
		local vtx1 = vertexs[i1]
		local vtx2 = vertexs[i2]
		local vtx3 = vertexs[i3]

		-- Extract positions. Pos are in the position 1,2,3 of the array of floats
		local v1 = [ vtx1[1], vtx1[2], vtx1[3] ]
		local v2 = [ vtx2[1], vtx2[2], vtx2[3] ]
		local v3 = [ vtx3[1], vtx3[2], vtx3[3] ]

		-- Extract uv. UV's are in the positions 7 & 8  (posx3, Nx3, <Uv>)
		local w1 =  [ vtx1[7], vtx1[8] ]
		local w2 =  [ vtx2[7], vtx2[8] ]
		local w3 =  [ vtx3[7], vtx3[8] ]

		local x1 = v2.x - v1.x
		local x2 = v3.x - v1.x
		local y1 = v2.y - v1.y
		local y2 = v3.y - v1.y
		local z1 = v2.z - v1.z
		local z2 = v3.z - v1.z

		local s1 = w2.x - w1.x
		local s2 = w3.x - w1.x
		local t1 = w2.y - w1.y
		local t2 = w3.y - w1.y

		local r = 1.0 / (s1 * t2 - s2 * t1)
		local sdir = [(t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r]
		local tdir = [(s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r,(s1 * z2 - s2 * z1) * r]

		tan1[i1] = tan1[i1] + sdir
		tan1[i2] = tan1[i2] + sdir
		tan1[i3] = tan1[i3] + sdir

		tan2[i1] = tan2[i1] + tdir
		tan2[i2] = tan2[i2] + tdir
		tan2[i3] = tan2[i3] + tdir
		
		a = a + 1
	)

	for a = 1 to vertexCount do (
		
		-- Extract normal
		local n = [ vertexs[a][4], vertexs[a][5], vertexs[a][6] ]
		local t = tan1[a];
		
		-- Gram-Schmidt orthogonalize
		local dot_nt = dot n t
		local new_tangent = t - n * dot_nt
		new_tangent = normalize new_tangent		-- xyz

		-- Calculate handedness
		local cross_nt = Cross n t
		local dot_cross_tan2 = dot cross_nt tan2[a]
		local new_w = 1.
		if dot_cross_tan2 < 0.0 then new_w = -1.0
		
		-- Append to the end of our 'fat vertex' the new four 'float' components: 
		join vertexs[a] #(new_tangent.x, new_tangent.y, new_tangent.z, new_w)
		
	)

)




function findIndexOrRegister ht vtxs new_vtx = (

	-- Key is a string representation of all floats in new_vtx
	local key = with printAllElements off new_vtx as string

	-- Find the string in the hash map
	local idx = ht.Item key
	if idx == undefined then (
		-- Register it
		idx = ht.count + 1
		ht.add key idx			-- Bind "vertex_as_string" to 1
		append vtxs new_vtx	
	)
	return idx
)


function resetModel obj = (

	--thehold controls redo/undo in 3dsMax
	if not thehold.holding() do thehold.Begin()

	if obj == undefined then throw "Nothing selected to reset!"

	-- get name and children before reseting 
	local objName = obj.name
	local objChildren = #()
	for child in obj.children do (
		append objChildren child
	)
	local backFaceCull = obj.backfaceCull 
	local wasIsolated = IsolateSelection.IsolateSelectionModeActive()

	-- create sphere in 0,0,0
	local sph = Sphere radius:1.0 pos:[0,0,0] isSelected:on
	convertToMesh sph
	local numFacesSphere_before = getNumFaces sph

	-- attach object to sphere to reset it
	meshop.attach sph obj

	for i in numFacesSphere_before to 1 by -1 do (
		deleteFace sph i
	)

	-- restore name and children
	sph.name = objName

	for child in objChildren do (
		child.parent = sph
	)

	sph.backfaceCull = backFaceCull 

	if wasIsolated == true then (
		IsolateSelection.ExitIsolateSelectionMode()
		select sph
		IsolateSelection.EnterIsolateSelectionMode()
	)

	--adding an entry to undo stack
	theHold.Accept "ResetModel"


)

function exportMesh the_obj out_filename vtx_fmt = (
	
	format "Exporting mesh: % \n" the_obj.name
	
	if the_obj == undefined then throw "Need an object to export"
	
	if vtx_fmt == undefined then vtx_fmt = "PosNUv"
		
	local order = #(1,3,2)
	
	
	
	local obj = the_obj
	if classof obj != Editable_mesh then (
		obj = copy the_obj
		convertToMesh obj
	)
	
	
	
	-- obj is a mesh...
	local channelA = 1
	local numFaces = getNumFaces obj
	local numVerts = getNumVerts obj
	local verts = #()
	local idxs = #()
	local subgroups = #()
	
	
	-- An array of arrays, each containing the list of faces using the material nth
	local faces_by_material_used = getMaterialsUsedByMesh obj
	
	
	-- To quickly find if a vertex is new
	local HT = dotNetObject "System.Collections.Hashtable"
	
	--ensure object has map support for channelA before processing
	local mapSupport = meshop.getMapSupport obj channelA		
	if mapSupport==false then (
		format "WARNING: Had to manually set Map Support to object: %\n" obj.name
		meshop.setMapSupport obj channelA true
	)
	
	local max2mcv = rotateXMatrix -90
	local world2local = inverse obj.transform
	local world2mcv = world2local * max2mcv
	
	
	for mat_idx = 1 to faces_by_material_used.count do (
		
		local faces = faces_by_material_used[mat_idx]
		if faces == undefined then continue
		
		
		-- We are starting a new group. 
		local new_subgroup = TMeshSubGroup()
		new_subgroup.first_idx = idxs.count
		-- Each face uses 3 indices..
		new_subgroup.num_indices = faces.count * 3
		new_subgroup.material_index = subgroups.count
		new_subgroup.user_material_id = mat_idx
		
		-- For each face using that material
		for face_id in faces do (

			local face = getFace obj face_id
			


			local faceA = meshop.getMapFace obj channelA face_id 
			
			-- Returns an array of 3 normals, one per vertex of the face
			local face_normals = meshop.getFaceRNormals obj face_id
			
			for vtx_id = 1 to 3 do (
				local vtx_idx = order[vtx_id]
				
				-- Geometric position
				local posAbs = getVert obj face[vtx_idx] 
				local posLocal = posAbs * world2mcv 
				--format " Vert %\n" posLocal
				
				-- Normal
				local Nworld = face_normals[vtx_idx]
				local N = Nworld * world2mcv.rotationpart
				
				
				-- UV coords of set A
				local uvA = meshop.getMapVert obj channelA faceA[vtx_idx]
				
				-- The final vertex layout
				local new_vert;
				if vtx_fmt == "PosNUv" then new_vert = #(posLocal.x, posLocal.y, posLocal.z, N.x, N.y, N.z, uvA.x, 1.0 - uvA.y )
				else if vtx_fmt == "Pos" then new_vert = #(posLocal.x, posLocal.y, posLocal.z )
				
				-- Check if the vtx is unique
				local new_idx = findIndexOrRegister ht verts new_vert
				append idxs new_idx
				
			)
			
		)
		
		append subgroups new_subgroup
		
	)

	-- restoring map support to false after processing
	if mapSupport==false then (
		meshop.setMapSupport obj channelA false
	)

	if vtx_fmt != "Pos" then (
		computeTangentSpace verts idxs 
		vtx_fmt += "T";
	)


	-- Complete. Report
	--for v in verts do format "V: %\n" v
	--for i in idxs do format "I: %\n" i
	--local export_path = "D:/Documents/Programming/c++/MCV/h3r/bin/data/meshes/"
	--local outfilename = export_path + the_obj.name + ".mesh"
	--writeMeshToFile outfilename verts idxs "PosNUv"
	
	-- If no custom name is given, use the default
	if out_filename == undefined then (
		local export_path = getDir #export + "/data/meshes/"

		out_filename = getSaveFileName caption:"Save Mesh as:"\
			historyCategory: "ExportMesh.ms"
		
		-- Check again if inserted filename is valid
		if out_filename == undefined then (
			out_filename = export_path + obj.name + ".mesh"\
		)
	)
	writeMeshToFile out_filename verts idxs vtx_fmt subgroups
	
	-- If I created a local copy to convert to editable mesh
	-- it's time to remove it from the scene
	if obj != the_obj then delete obj
	
)

--exportMesh $ "C:/Code/engine/bin/data/meshes/UnitSolidCube.mesh" undefined
