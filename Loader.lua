-- ====================================================================
-- MASENSDEV HUB - KEY SYSTEM & LOADER
-- Red & Black Theme (0.4 Transparency) + Fixed 12 Hours Multi-Device System
-- ====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- KONFIGURASI REPOSITORY & SAVING
local KEY_LIST_URL = "https://raw.githubusercontent.com/ens9555/MasensDevHub/main/keys.json"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/ens9555/MasensDevHub/main/Main.lua"
local SAVE_FILE = "MD_MasensDevHub_KeySave.json"
local KEY_EXPIRE_TIME = 12 * 3600 -- 12 Jam dalam detik (43.200 detik)

-- LINK GET KEY
local GET_KEY_LINK = "https://link-hub.net/9347872/OeHjUSdeYOef" 

-- Helper Simpan Data Key + Timestamp (Hanya dipanggil saat PERTAMA KALI LOGIN)
local function createNewSaveData(key)
    if writefile then
        local saveData = {
            key = key,
            timestamp = os.time() -- Mencatat waktu pertama kali login
        }
        writefile(SAVE_FILE, HttpService:JSONEncode(saveData))
    end
end

-- Helper Hapus Data Key
local function clearSavedKey()
    if isfile and isfile(SAVE_FILE) and delfile then
        delfile(SAVE_FILE)
    end
end

-- Fungsi Validasi Key Online (Bisa untuk semua device)
local function checkKey(userKey, isNewLogin)
    local success, response = pcall(function()
        return game:HttpGet(KEY_LIST_URL)
    end)
    
    if not success or not response then
        return false, "Gagal terhubung ke database key!"
    end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodeSuccess or not data or not data.KEYS then
        return false, "Format database key salah!"
    end

    local keyData = data.KEYS[userKey]
    if keyData then
        -- Multi-device: Pengecekan HWID dilewati agar 1 key bisa dipakai bersama
        if isNewLogin then
            createNewSaveData(userKey)
        end
        return true, "Valid"
    end

    return false, "Key tidak valid / tidak ditemukan!"
end

local function executeMainScript()
    print("[MasensDev Hub] Memuat Main.lua...")
    local success, err = pcall(function()
        loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
    end)
    if not success then
        warn("[MasensDev Hub] Gagal memuat Main.lua:", err)
    end
end

-- 1. CEK AUTO-LOGIN & BATAS WAKTU 12 JAM REAL-TIME
if isfile and isfile(SAVE_FILE) then
    local readSuccess, fileContent = pcall(function()
        return readfile(SAVE_FILE)
    end)
    
    if readSuccess and fileContent then
        local decodeSuccess, parsedData = pcall(function()
            return HttpService:JSONDecode(fileContent)
        end)
        
        if decodeSuccess and parsedData and parsedData.key and parsedData.timestamp then
            local currentTime = os.time()
            local timeElapsed = currentTime - parsedData.timestamp
            
            if timeElapsed < KEY_EXPIRE_TIME then
                -- Key masih berlaku, validasi ke database online (isNewLogin = false agar timestamp tidak ter-reset)
                local isValid, _ = checkKey(parsedData.key, false)
                if isValid then
                    local timeRemaining = KEY_EXPIRE_TIME - timeElapsed
                    local hoursRemaining = math.floor(timeRemaining / 3600)
                    local minsRemaining = math.floor((timeRemaining % 3600) / 60)
                    
                    print(string.format("[MasensDev Hub] Key Terverifikasi! Sisa waktu aktif: %d Jam %d Menit", hoursRemaining, minsRemaining))
                    executeMainScript()
                    return
                else
                    clearSavedKey()
                end
            else
                -- Sudah lewat dari 12 Jam sejak login pertama
                print("[MasensDev Hub] Key sudah kedaluwarsa (lebih dari 12 Jam).")
                clearSavedKey()
            end
        else
            clearSavedKey()
        end
    end
end

-- Clean Up GUI Lama jika ada
local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("MD_KeySystemUI")
if oldGui then oldGui:Destroy() end

-- 2. GUI MASUKKAN KEY (THEME RED & BLACK - 0.4 TRANSPARENCY)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MD_KeySystemUI"
ScreenGui.ResetOnSpawn = false

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

-- Frame Utama
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 330, 0, 195)
Frame.Position = UDim2.new(0.5, -165, 0.4, -97)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BackgroundTransparency = 0.4
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local mainCorner = Instance.new("UICorner", Frame)
mainCorner.CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", Frame)
mainStroke.Color = Color3.fromRGB(200, 0, 0)
mainStroke.Thickness = 1.5

-- Title Bar
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 38)
Title.Text = "MasensDev Hub - Key System"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
Title.BackgroundTransparency = 0.4
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15

local titleCorner = Instance.new("UICorner", Title)
titleCorner.CornerRadius = UDim.new(0, 10)

-- Input Box
local InputBox = Instance.new("TextBox", Frame)
InputBox.Size = UDim2.new(0.9, 0, 0, 36)
InputBox.Position = UDim2.new(0.05, 0, 0.30, 0)
InputBox.PlaceholderText = "Masukkan Key (Berlaku 12 Jam)..."
InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
InputBox.Text = ""
InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InputBox.BackgroundTransparency = 0.4
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.Font = Enum.Font.SourceSans
InputBox.TextSize = 13

local inputCorner = Instance.new("UICorner", InputBox)
inputCorner.CornerRadius = UDim.new(0, 6)

-- TOMBOL LOGIN
local SubmitBtn = Instance.new("TextButton", Frame)
SubmitBtn.Size = UDim2.new(0.43, 0, 0, 36)
SubmitBtn.Position = UDim2.new(0.05, 0, 0.60, 0)
SubmitBtn.Text = "LOGIN"
SubmitBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
SubmitBtn.BackgroundTransparency = 0.4
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.Font = Enum.Font.SourceSansBold
SubmitBtn.TextSize = 14

local submitCorner = Instance.new("UICorner", SubmitBtn)
submitCorner.CornerRadius = UDim.new(0, 6)

-- TOMBOL GET KEY
local GetKeyBtn = Instance.new("TextButton", Frame)
GetKeyBtn.Size = UDim2.new(0.43, 0, 0, 36)
GetKeyBtn.Position = UDim2.new(0.52, 0, 0.60, 0)
GetKeyBtn.Text = "GET KEY"
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
GetKeyBtn.BackgroundTransparency = 0.4
GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyBtn.Font = Enum.Font.SourceSansBold
GetKeyBtn.TextSize = 14

local getKeyCorner = Instance.new("UICorner", GetKeyBtn)
getKeyCorner.CornerRadius = UDim.new(0, 6)

-- LOGIKA BUTTON
SubmitBtn.MouseButton1Click:Connect(function()
    local userKey = InputBox.Text
    SubmitBtn.Text = "Memeriksa..."
    
    -- Pass 'true' karena ini login pertama via GUI
    local success, msg = checkKey(userKey, true)
    if success then
        SubmitBtn.Text = "BERHASIL!"
        task.wait(0.5)
        ScreenGui:Destroy()
        executeMainScript()
    else
        SubmitBtn.Text = "LOGIN"
        InputBox.Text = ""
        InputBox.PlaceholderText = msg
    end
end)

GetKeyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(GET_KEY_LINK)
        GetKeyBtn.Text = "COPIED!"
        task.wait(1.5)
        GetKeyBtn.Text = "GET KEY"
    else
        GetKeyBtn.Text = "FAILED"
    end
end)
