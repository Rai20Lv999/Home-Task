        --[[
        
                 Authored by: ImYourRai
        ]]

        --// Variables //--

        local Install              = {};

        --// Codebase //--

        for i, systems in script.Parent.Server:GetDescendants() do
            if (systems:IsA('ModuleScript')) then
                Install[systems.Name] = require(systems)
            end
        end

        for i , InitializeInstallment in pairs(Install) do
            if InitializeInstallment.Install or (getmetatable(InitializeInstallment) and getmetatable(InitializeInstallment).Install) then
                local Systems  = {}
                for othernames, otherfunctions in pairs(Install) do
                    if othernames ~= i then
                        Systems[othernames] = otherfunctions
                    end
                end
                InitializeInstallment:Install(Systems);
            end
        end

        return Install;