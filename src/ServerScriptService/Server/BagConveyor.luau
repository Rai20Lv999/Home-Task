local Players = game:GetService("Players")
--[[
        
                 Authored by: ImYourRai
        ]]

        --// Variables //--

        local Conveyor     = {};
        local Systems      = {};

        local Modules      = require(game.ReplicatedStorage.Install);

        --[[
            Events and functions signals
        ]]
        local BaggageSpawn  = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.BaggageSpawn :: RemoteEvent;
        local BaggageRemove = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.BaggageRemove :: RemoteEvent;
        local IntervalChanged = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.IntervalChanged :: RemoteEvent;
        local Controller = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.Controller :: RemoteEvent;
        local BagClicked = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.Bagclick :: RemoteEvent;
        
        local GetBaggageSnapshot = Modules.RBLXServices['ReplicatedStorage'].Signals.Functions.GetBaggageSnapshot :: RemoteFunction;

        type BagPacket = {
            id: string,
            t: number,
            s: number,
            c: Color3,
            m: Enum.Material,
        }

        --// Codes //--

        local function getServerTime(): number
            return game.Workspace:GetServerTimeNow()
        end        

        local function getConveyorLength(StartUnit : BasePart, EndUnit : BasePart): number
            return (EndUnit.Position - StartUnit.Position).Magnitude
        end

        local function getTravelTime(StartUnit : BasePart, EndUnit : BasePart): number
            local length = getConveyorLength(StartUnit, EndUnit)
        
            if Modules.RuntimeData['Speed'] <= 0 then
                return math.huge
            end
        
            return length / Modules.RuntimeData['Speed']
        end

        local function createPacket(): BagPacket
            local packet: BagPacket = {
                id = Modules.RBLXServices['HTTPs']:GenerateGUID(false),
                -- All clients use this to calculate the same baggage position.
                t = getServerTime(),
                s = Modules.RuntimeData['Speed'],
                c = Modules.Baggage['Colors'][math.random(1, #Modules.Baggage['Colors'])],
                m = Modules.Baggage['Materials'][math.random(1, #Modules.Baggage['Materials'])],
            }
            return packet
        end

        local function spawnBag()

            local StartUnit = game.Workspace:WaitForChild("StartUnit") :: BasePart
            local EndUnit = game.Workspace:WaitForChild("EndUnit") :: BasePart

            local packet = createPacket()
        
            Modules.RuntimeData['Bags'][packet.id] = packet;
        
            BaggageSpawn:FireAllClients(packet)
        
            task.delay(getTravelTime(StartUnit, EndUnit) + 0.5, function()
                if not Modules.RuntimeData['Bags'][packet.id] then
                    return
                end
                Modules.RuntimeData['Bags'][packet.id] = nil
                BaggageRemove:FireAllClients(packet.id);
            end)
        end
        
        local function cleanupOldBags()

            local StartUnit = game.Workspace:WaitForChild("StartUnit") :: BasePart
            local EndUnit = game.Workspace:WaitForChild("EndUnit") :: BasePart

            local now = getServerTime()
            local travelTime = getTravelTime(StartUnit, EndUnit)
        
            for id, packet in pairs(Modules.RuntimeData['Bags']) do
                if now - packet.t >= travelTime + 1 then
                    Modules.RuntimeData['Bags'][id] = nil
                    BaggageRemove:FireAllClients(id);
                end
            end
        end

        function Conveyor:Start()
            GetBaggageSnapshot.OnServerInvoke = function()
                -- Late joiners call this once.
                return Modules.RuntimeData['Bags']
            end

            IntervalChanged.OnServerEvent:Connect(function(USER : Player, Value : number)
                 Modules.RuntimeData['DEFAULT Interval'] = Value;
            end)

            BagClicked.OnServerEvent:Connect(function(USER : Player, ID : string)
                print('The Bag ID: ', ID)
            end)
        
            task.spawn(function()
                while true do
                    spawnBag();
                    cleanupOldBags();
                    task.wait(Modules.RuntimeData['DEFAULT Interval'])
                end
            end)
        end

        function Conveyor:Install(OtherSystem)
            Systems = OtherSystem; Conveyor:Start();
        end

        game.Players.PlayerAdded:Connect(function(player)
            local GetPlayers       = game.Players:GetPlayers();
            local ChosenPlayer     = GetPlayers[1];

            Controller:FireClient(ChosenPlayer);
        end)

        return Conveyor;