-- // Службы Roblox // --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- // Локальные переменные // --
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart") -- HumanoidRootPart

local originalGravity = Workspace.Gravity -- Сохраняем исходную гравитацию

-- // Настройки полета // --
local isFlying = false           -- Состояние: летит игрок или нет
local flightSpeed = 75           -- Скорость полета
local toggleKey = Enum.KeyCode.F   -- Клавиша для включения/выключения полета

-- // Переменные для физики полета // --
local flyVelocity = nil
local flyGyro = nil
local heartbeatConnection = nil -- Для хранения соединения с Heartbeat

-- // Функция: Начать полет // --
local function startFlying()
	if isFlying then return end -- Если уже летим, ничего не делаем
	isFlying = true
	print("Полет активирован!")

	-- Отключаем стандартную гравитацию
	Workspace.Gravity = 0
	-- Предотвращаем стандартное поведение на земле
	humanoid.PlatformStand = true

	-- Создаем BodyVelocity для управления скоростью
	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.Name = "FlyVelocity"
	flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge) -- Бесконечная сила, чтобы переопределить физику
	flyVelocity.Velocity = Vector3.new(0, 0, 0) -- Начальная скорость
	flyVelocity.Parent = hrp

	-- Создаем BodyGyro для управления ориентацией (чтобы не падал)
	flyGyro = Instance.new("BodyGyro")
	flyGyro.Name = "FlyGyro"
	flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) -- Бесконечная сила вращения
	flyGyro.P = 5000 -- Коэффициент жесткости (насколько быстро он поворачивается)
	flyGyro.CFrame = hrp.CFrame -- Начальная ориентация
	flyGyro.Parent = hrp

	-- Подключаем функцию обновления полета к каждому кадру
	heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not isFlying or not flyVelocity or not flyGyro then return end -- Проверка на всякий случай

		local camera = Workspace.CurrentCamera
		if not camera then return end

		local moveDirection = Vector3.new(0, 0, 0)

		-- Проверяем нажатые клавиши для движения
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDirection = moveDirection + camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDirection = moveDirection - camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDirection = moveDirection + camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDirection = moveDirection - camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDirection = moveDirection + Vector3.new(0, 1, 0) -- Вверх
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveDirection = moveDirection + Vector3.new(0, -1, 0) -- Вниз
		end

		-- Нормализуем вектор, если есть движение (чтобы по диагонали не летать быстрее)
		if moveDirection.Magnitude > 0 then
			moveDirection = moveDirection.Unit
		end

		-- Устанавливаем желаемую скорость
		flyVelocity.Velocity = moveDirection * flightSpeed

		-- Обновляем ориентацию BodyGyro, чтобы персонаж смотрел по камере (но без наклона)
		flyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + camera.CFrame.LookVector)
	end)
end

-- // Функция: Прекратить полет // --
local function stopFlying()
	if not isFlying then return end -- Если не летим, ничего не делаем
	isFlying = false
	print("Полет деактивирован.")

	-- Возвращаем гравитацию
	Workspace.Gravity = originalGravity
	-- Возвращаем стандартное поведение
	humanoid.PlatformStand = false

	-- Уничтожаем объекты физики полета
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end

	-- Отключаем обновление полета
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	-- Сбрасываем скорость Humanoid, чтобы он не продолжал скользить
	humanoid:ChangeState(Enum.HumanoidStateType.Running) -- Сброс состояния может помочь
	hrp.Velocity = Vector3.new(0,0,0) -- Явно обнуляем скорость
end

-- // Функция: Обработка нажатий клавиш (для включения/выключения) // --
local function onInputBegan(input, gameProcessedEvent)
	-- Игнорируем ввод, если он обработан игрой (например, ввод в чат)
	if gameProcessedEvent then return end

	-- Проверяем, нажата ли наша клавиша
	if input.KeyCode == toggleKey then
		if isFlying then
			stopFlying()
		else
			startFlying()
		end
	end
end

-- // Обработка смерти и возрождения персонажа // --
player.CharacterAdded:Connect(function(newCharacter)
	-- Обновляем ссылки на нового персонажа
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	hrp = character:WaitForChild("HumanoidRootPart")

	-- Если игрок летел во время смерти, останавливаем полет при возрождении
	if isFlying then
		stopFlying()
	end
end)

-- // Подключаем обработчик нажатий // --
UserInputService.InputBegan:Connect(onInputBegan)

-- // Дополнительно: останавливаем полет, если игрок покидает игру // --
player.CharacterRemoving:Connect(function()
    if isFlying then
        stopFlying()
    end
    -- Отключаем основной слушатель ввода, чтобы избежать ошибок
    -- (Хотя LocalScript и так уничтожится)
end)

print("Скрипт простого полета загружен. Нажмите F для активации.")
