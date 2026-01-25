local bufferSerial = require("@BufferSerializer")

type Fruit = {
	seed_count: number,
	is_ripe: boolean,
	species: string,
}

-- the keys will take 1 byte each
-- after the first store
bufferSerial.pair(1, "seed_count")
bufferSerial.pair(2, "is_ripe")
bufferSerial.pair(3, "species")

local function GenerateFruit()
	local seed_count = math.random(10, 25)
	local is_ripe = math.random(0, 1) == 1
	local species = `{string.char(math.random(64, 86))}{math.random(100, 999)}`

	return {
		seed_count = seed_count,
		is_ripe = is_ripe,
		species = species,
	}
end

local data = {}

for i = 0, 30 do
	table.insert(data, GenerateFruit())
end

local serData = bufferSerial.serialize(data)

-- ...

local deserData = bufferSerial.deserialize(serData)

for _, fruit in deserData do
	print(`{fruit.species} has {fruit.seed_count} seeds`)
end
