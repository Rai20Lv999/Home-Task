--// Variables //--

local Install                        = {};

--// Voids //-- 

for i, DevModuleInstaller in pairs(script.Parent.Modulescripts:GetDescendants()) do
    if DevModuleInstaller:IsA('ModuleScript') then
        if Install[DevModuleInstaller.Name] then
            error('[Dev Install] Nahanap namin ang Duplicated Script. Gumawa ulit ng magkaibang pangalan upang ito ay mag process');
        end
        Install[DevModuleInstaller.Name]         = require(DevModuleInstaller);
     --   print('[Dev ReplicatedStorage Install] Installed Successfully!')
    end
end
return Install;