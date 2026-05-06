--[[
        
                 Authored by: ImYourRai
        ]]

        --// Variables //--

        local Conveyor     = {};
        local Systems      = {};

        local Modules      = require(game.ReplicatedStorage.Install);

        local BaggageSpawn  = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.BaggageSpawn :: RemoteEvent;
        local BaggageRemove = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.BaggageRemove :: RemoteEvent;

        local GetBaggageSnapshot = Modules.RBLXServices['ReplicatedStorage'].Signals.Functions.GetBaggageSnapshot :: RemoteFunction;

        --// Codes //--

        type BagPacket = {
            id: string,
            t: number,
            s: number,
            c: Color3,
            m: Enum.Material,
        };

        type ClientBag = {
            Model: Model,
            Packet: BagPacket,
        };

        local Clientbags : {[string]: ClientBag} = {};

        local function getServerTime(): number
            return Modules.RBLXServices['Workspace']:GetServerTimeNow()
        end
        
        local function getDirection(StartUnit : BasePart, EndUnit : BasePart): Vector3
            local difference = EndUnit.Position - StartUnit.Position
            if difference.Magnitude <= 0 then
                return Vector3.zero
            end
            return difference.Unit
        end

        local function getLength(StartUnit : BasePart, EndUnit : BasePart): number
            return (EndUnit.Position - StartUnit.Position).Magnitude
        end
        
        local function getAlpha(packet: BagPacket): number

            local StartUnit = game.Workspace:WaitForChild("StartUnit") :: BasePart
            local EndUnit = game.Workspace:WaitForChild("EndUnit") :: BasePart

            local elapsed = getServerTime() - packet.t
            local distance = elapsed * packet.s
            local length = getLength(StartUnit, EndUnit)
            if length <= 0 then
                return 1
            end
            return math.clamp(distance / length, 0, 1)
        end

        local function getBaggageCFrame(packet : BagPacket) : CFrame
            
            local StartUnit = game.Workspace:WaitForChild("StartUnit") :: BasePart
            local EndUnit = game.Workspace:WaitForChild("EndUnit") :: BasePart

            local Elapsed = getServerTime() - packet.t;
            local distance = Elapsed * packet.s;

            local POS    = StartUnit.Position + getDirection(StartUnit, EndUnit) * distance;
            local Rot    = StartUnit.CFrame - StartUnit.Position;

            return CFrame.new(POS) * Rot;

        end

        local function Visualbag(Model : Model, packet : BagPacket)
            local Color, Material = packet.c, packet.m;

            local base      = Model:FindFirstChild('Base');
            if (base) then
                for i, v in base:GetChildren() do
                    v.Color = Color; v.Material = Material;
                end
            end
        end

        local function removeBag(id: string)
            local data = Clientbags[id]
        
            local Connection : RBXScriptConnection;

            if not data then
                return
            end

            local ScaleToValue = Instance.new('NumberValue'); ScaleToValue.Value = 1;

            local tween = Modules.RBLXServices['TweenService']:Create(
	            ScaleToValue, TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
	            { Value = .1 }
            );

            Connection = Modules.RBLXServices['RunService'].RenderStepped:Connect(function()
                data.Model:ScaleTo(ScaleToValue.Value);
            end)
            tween:Play();

            tween.Completed:Connect(function()
                Connection:Disconnect()
                ScaleToValue:Destroy()
                data.Model:Destroy()
            end)
        
            if data.Model then
              --  data.Model:Destroy()
            end
        
            Clientbags[id] = nil
        end

        local function createBag(packet: BagPacket)

            local Connection : RBXScriptConnection;
            if Clientbags[packet.id] then
                return
            end
            if getAlpha(packet) >= 1 then
                return
            end

            local templatebag       = Modules.RBLXServices['ReplicatedStorage'].Storage:FindFirstChild('Bag');
            if not (templatebag) then warn('Theres no bag')
                return;
            end

            local mdl = templatebag:Clone(); mdl.Name = 'Bag_'..packet.id; mdl.Parent = game.Workspace.Baggage;
            mdl:SetAttribute('ID', packet.id);

            Visualbag(mdl, packet); mdl:PivotTo(getBaggageCFrame(packet));

            local ScaleToValue = Instance.new('NumberValue');

            local tween = Modules.RBLXServices['TweenService']:Create(
	            ScaleToValue, TweenInfo.new(.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
	            { Value = 1 }
            );

            Connection = Modules.RBLXServices['RunService'].RenderStepped:Connect(function()
                mdl:ScaleTo(ScaleToValue.Value);
            end)
            tween:Play();

            tween.Completed:Connect(function()
                Connection:Disconnect()
                ScaleToValue:Destroy()
            end)

            Clientbags[packet.id] = {
                Model = mdl;
                Packet = packet;
            }

        end

        local function loadLateJoinSnapshot()
            local success, snapshot = pcall(function()
                return GetBaggageSnapshot:InvokeServer()
            end)
        
            if not success then
              --  warn("[ConveyorClient] Failed to load baggage snapshot:", snapshot)
             --   return
            end
        
            if typeof(snapshot) ~= "table" then
                return
            end
        
            for _, packet in pairs(snapshot) do
                createBag(packet)
            end
        end

        BaggageSpawn.OnClientEvent:Connect(function(packet: BagPacket)
            createBag(packet)
        end)
        
        BaggageRemove.OnClientEvent:Connect(function(id: string)
            removeBag(id)
        end)

        Modules.RBLXServices['RunService'].RenderStepped:Connect(function()
            for id, data in pairs(Clientbags) do
                local model = data.Model
                local packet = data.Packet
        
                if not model or not model.Parent then
                    Clientbags[id] = nil
                    continue
                end
        
                if getAlpha(packet) >= 1 then
                    removeBag(id)
                    continue
                end
        
                model:PivotTo(getBaggageCFrame(packet))
            end
        end)

        function Conveyor:Install(OtherSystem)
            Systems = OtherSystem; loadLateJoinSnapshot();
        end

        return Conveyor;