local bufferSerial = require("./BufferSerializer/BufferSerializer")

local data = {
	Foo = "Baz",
	Fruit = "Apple"
}

-- We don't know if Baz or Apple are constant, but we can assume
-- that Foo and Fruit are
bufferSerial.pair(1, "Foo")
bufferSerial.pair(2, "Fruit")

local serData = bufferSerial.serialize(data)

-- ...

local deserData = bufferSerial.deserialize(serData)
print(deserData.Foo, deserData.Fruit) -- Baz	Apple