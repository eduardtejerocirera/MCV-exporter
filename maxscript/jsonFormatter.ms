
struct TJsonFormatter (
	
	ofilename,		-- Name of output file
	fs, 				-- File stream
	depth_level = 0,	-- To format json tabs	
	
	-- --------------------
	fn begin new_ofilename = (
		ofilename = new_ofilename
		--fs = listener
		fs = createFile  ofilename
	),
	
	-- --------------------
	fn end = (
		if fs != undefined and fs != listener then close fs
		fs = undefined
	),
	
	-- --------------------
	fn indent = (
		for i = 1 to depth_level do format "  " to:fs
	),
	
		-- --------------------
	fn beginArray = (
		indent()
		format "[\n" to:fs
		depth_level = depth_level + 1
	),
	
	fn endArray = (
		depth_level = depth_level - 1
		indent()
		format "]\n" to:fs
	),
	
		-- --------------------
	fn beginObj = (
		indent()
		format "{\n" to:fs
		depth_level = depth_level + 1
	),
	
	fn endObj = (
		depth_level = depth_level - 1
		indent()
		format "}\n" to:fs
	),
	
	fn writeComma = (
		indent()
		format ",\n" to:fs
	),
	
	-- --------------------
	fn writeKey key_str = (
		indent()
		format "\"%\":\n" key_str to:fs
	),
	
	-- --------------------
	fn writeKeyValue key_str val = (
		indent()
		if classof val == string then (
			format "\"%\": \"%\"\n" key_str val to:fs
		) else if classof val == Point3 then (
			format "\"%\": \"% % %\"\n" key_str val.x val.y val.z to:fs
		) else if classof val == Color then (
			format "\"%\": \"% % % %\"\n" key_str (val.red / 255.0) (val.green / 255.0) (val.blue / 255.0)  (val.alpha / 255.0)to:fs
		) else if classof val == quat then (
			-- Quats rotate in the opposite direction
			format "\"%\": \"% % % %\"\n" key_str val.x val.y val.z -val.w to:fs
		) else (
			format "\"%\": %\n" key_str val to:fs
		)
	),

	fn writeValue val = (
		indent()
		if classof val == string then (
			format "\"%\"\n" val to:fs
		) else if classof val == Point3 then (
			format "\"% % %\"\n" val.x val.y val.z to:fs
		) else if classof val == Color then (
			format "\"% % % %\"\n" (val.red / 255.0) (val.green / 255.0) (val.blue / 255.0)  (val.alpha / 255.0)to:fs
		) else if classof val == quat then (
			-- Quats rotate in the opposite direction
			format "\"% % % %\"\n" val.x val.y val.z -val.w to:fs
		) else (
			format "%\n" val to:fs
		)
	),
	
	-- --------------------
	fn writeName name = (
		indent()
		format "\"%\"\n" name to:fs
	),
	
	fn arrayOfStrings arr = (
		beginArray()
		for idx = 1 to arr.count do (
			if idx != 1 then writeComma()
			writeName arr[idx]
		)
		endArray()
	)
	
)
