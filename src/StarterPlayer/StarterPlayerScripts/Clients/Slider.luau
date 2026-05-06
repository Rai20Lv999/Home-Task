--[[
        
                 Authored by: ImYourRai
        ]]

        --// Variables //--

        local Slider       = {};
        local Systems      = {};

        local Modules      = require(game.ReplicatedStorage.Install);

        local UserInputService  = Modules.RBLXServices['UserInputService'];
        local Mouse        = game.Players.LocalPlayer:GetMouse();

        local DEFAULT_VALUE = Modules.RuntimeData['MIN Interval'];
        local CurrentValue = DEFAULT_VALUE;
        local Dragging = false;

        local IntervalChanged = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.IntervalChanged :: RemoteEvent;
        local Controller = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.Controller :: RemoteEvent;
        local BagClicked = Modules.RBLXServices['ReplicatedStorage'].Signals.Remotes.Bagclick :: RemoteEvent;

        local ScreenGui     = game.Players.LocalPlayer.PlayerGui:WaitForChild('SliderGui');
        if not (ScreenGui) then warn('Slidergui is not valid member')
            return;
        end
        local MainFrame     = ScreenGui.MainFrame;
        local Title         = ScreenGui.MainFrame.Title;
        local SliderBack    = ScreenGui.MainFrame.SliderBack;
        local SliderFill    = SliderBack.SliderFill;
        local SliderButton  = SliderBack.SliderButton;

        --// Codes //--

        local function ValueToPercent(value)
            return (value - Modules.RuntimeData['MIN Interval']) / (Modules.RuntimeData['MAX Interval'] - Modules.RuntimeData['MIN Interval']);
        end

        local function PercentToValue(percent)
            local rawValue = Modules.RuntimeData['MIN Interval'] + ((Modules.RuntimeData['MAX Interval'] - Modules.RuntimeData['MIN Interval']) * percent)
        
            -- Makes it whole number: 1, 2, 3, 4, 5
            return math.clamp(math.round(rawValue), Modules.RuntimeData['MIN Interval'], Modules.RuntimeData['MAX Interval'])
        end

        local function UpdateSlider(value)
            CurrentValue = math.clamp(value, Modules.RuntimeData['MIN Interval'], Modules.RuntimeData['MAX Interval'])
        
            local percent = ValueToPercent(CurrentValue)
        
            SliderFill.Size = UDim2.fromScale(percent, 1)
            SliderButton.Position = UDim2.fromScale(percent, 0.5)
        
            IntervalChanged:FireServer(CurrentValue);
            Title.Text = "Interval Value: " .. CurrentValue;
        
         --   print("Current Slider Value:", CurrentValue)
        end

        local function UpdateFromInput(input)
            local sliderPosition = SliderBack.AbsolutePosition.X
            local sliderSize = SliderBack.AbsoluteSize.X
        
            local mouseX = input.Position.X
            local percent = math.clamp((mouseX - sliderPosition) / sliderSize, 0, 1)
        
            local newValue = PercentToValue(percent)
            UpdateSlider(newValue)
        end

        SliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
        
                Dragging = true
                UpdateFromInput(input)
            end
        end)

        SliderBack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
        
                Dragging = true
                UpdateFromInput(input)

            end
        end)

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then
                return
            end
        
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
        
            local target = Mouse.Target:FindFirstAncestorOfClass('Model');
            if target and target:IsDescendantOf(game.Workspace.Baggage) then
                local bagId = target:GetAttribute("ID")
        
                if bagId then
                    print("[Client] Clicked bag ID:", bagId)
                    BagClicked:FireServer(bagId)
                end
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if Dragging then
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    UpdateFromInput(input)
                end
            end
        end)

        function Slider:Install(OtherSystem)
            Systems = OtherSystem; UpdateSlider(DEFAULT_VALUE);

            Controller.OnClientEvent:Connect(function()
                 ScreenGui.Enabled = true;
            end)

        end

        return Slider;