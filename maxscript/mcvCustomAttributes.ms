clearListener()

classPrefabData = attributes prefabData
(
	parameters main rollout:params
	(
		prefab type: #integer ui:ddlPrefab default:1
	)
	rollout params "Weapon Parameters" width:163 height:168
	(
		dropDownList 'ddlPrefab' "DropDownList" pos:[10,10] width:151 height:40 items:#("Enemy", "Spawn", "LifeBox") align:#left
	)
	fn exportAsComponent fs = (
		local src = "";
		if prefab == 1 then src = "data/scenes/enemy.json"
		else if prefab == 2 then src = "data/scenes/spawn.json"
		else if prefab == 3 then src = "data/scenes/lifebox.json"
		else return undefined
		fs.writeComma()
		fs.writeKeyValue "prefab"  src
	)
)

fn createEmtyPrefab = (
	local newDummy = Dummy()
	custAttributes.add newDummy classPrefabData
	select newDummy
)
