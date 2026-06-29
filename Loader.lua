local Loader = {}

function Loader.LoadFlex()
    local success, FlexUICode = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/UndefinedClear/FlexUI/refs/heads/main/FlexUI.luau")
    end)

    if not success or not FlexUICode or FlexUICode == "" then
        error("[Ошибка] Не удалось скачать интерфейс FlexUI. Проверь ссылку или интернет!")
    end

    local FlexUIFunc, compileError = loadstring(FlexUICode)
    if not FlexUIFunc then
        error("[Ошибка компиляции UI]: " .. tostring(compileError))
    else
        return FlexUIFunc
    end
end


return Loader