Config = {
    Items = {"nanskip.red_voxel"}
}

Client.OnStart = function()
    multi = require("multi")
	Player:SetParent(World)
	Map.Palette[3].Color = Color(255, 255, 255, 1)

	Player.Position = Number3(50, 20, 50)
    Player.isPlayer = true

    generateWheat()
end

onPlayerJoinListener = LocalEvent:Listen(LocalEvent.Name.OnPlayerJoin, function(p)
	p.isPlayer = true
end)

function generateWheat()
    wheats = {}

    for i=1, 44 do -- 44
        local row = {}
        for j=1, 31 do -- 31
            local wheat = Object()
            wheat.Position = Number3(55+(i*5), 5, 120+(j*5))
            wheat:SetParent(World)
            wheat.pos = {i, j}

            wheat.gather = function(self, other)
                if self == nil then
                    error("Call wheat.gather() with ':'!")

                    return
                end

                self.IsHidden = true
                self.collider.Physics = PhysicsMode.Disabled
                
                if other == Player then
                    e = Event()
                    e.pos1 = self.pos[1]
                    e.pos2 = self.pos[2]
                    e:SendTo(Server)
                end
            end

            for i=1, math.random(1, 2) do
                local q = Quad()
                q.Color = Color(247, 227, 67)
                q.Scale.Y = 7+math.random(0, 40)*0.1
                q:SetParent(wheat)
                q.Position = wheat.Position + Number3(math.random(5, 45)*0.1, 0, math.random(5, 45)*0.1)
                q.Rotation.Y = math.random(-314, 314)*0.01
                q.Shadow = true
                q.IsUnlit = true
            end

            wheat.collider = Shape(Items.nanskip.red_voxel)
            wheat.collider.Scale = Number3(4.5, 10, 4.5)
            wheat.collider.Pivot = Number3(2.5, 0, 2.5)
            wheat.collider:SetParent(wheat)
            wheat.collider.Physics = PhysicsMode.Trigger
            wheat.collider.Palette[1].Color.A = 0
            wheat.collider:RefreshModel()
            wheat.collider.Position = wheat.Position + Number3(12.5, 1, 12.5)

            wheat.collider.OnCollisionBegin= function(self, other)
                if other.isPlayer then
                    local p = self:GetParent()
                    p:gather(other)
                end
            end

            row[j] = wheat
        end
        wheats[i] = row
    end
end

Client.DidReceiveEvent = function(e)
    if e.wheats ~= nil then
        local wheat_table = JSON:Decode(e.wheats)
        print("Wheat loading event.")

        for i=1, 44 do -- 44
            for j=1, 31 do -- 31
                if wheat_table[i][j] then
                    wheats[i][j].IsHidden = false
                else
                    wheats[i][j].IsHidden = true
                end
            end
        end
        print("Wheat loaded.")
    end
end

Server.DidReceiveEvent = function(e)
    if e.pos1 ~= nil then
        wheats[e.pos1][e.pos2] = false
    end
end

Server.OnPlayerJoin = function(player)
    e = Event()

    e.wheats = JSON:Encode(wheats)
    e:SendTo(player)
end

Server.OnStart = function()
    syncTimer = 0
    wheats = {}
    for i=1, 44 do -- 44
        local row = {}
        for j=1, 31 do -- 31
            local obj = true
            row[j] = obj
        end
        wheats[i] = row
    end
end

Server.Tick = function()
    syncTimer = syncTimer + 1

    if syncTimer >= 900 then
        Server.syncWheat()
        syncTimer = 0
    end
end

Server.syncWheat = function()
    e = Event()

    e.wheats = JSON:Encode(wheats)
    e:SendTo(Players)
end
