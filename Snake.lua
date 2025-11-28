-- Гра "Змійка" для EdgeTX (RadioMaster)
-- Виправлена версія: Рекорд зберігається тільки в RAM (щоб уникнути помилок файлової системи)
-- Керування: Правий стік (Елерони/Елеватор)

local snake = {}
local dir = {x = 1, y = 0} 
local food = {x = 0, y = 0}
local cellSize = 10 
local width = LCD_W / cellSize
local height = LCD_H / cellSize
local score = 0
local maxScore = 0 -- Рекорд (зберігається до виходу)
local gameOver = false
local lastMoveTime = 0

-- Налаштування швидкості
local startSpeed = 20 
local currentSpeed = startSpeed
local speedStep = 2 
local maxSpeed = 4 

-- НОВІ ЗМІННІ 
local lossTime = 0 
local restartDelay = 100 -- 100 тіків * 10мс = 1 секунда затримки
local hapticPlayed = false -- Прапор, щоб вібрація спрацювала лише раз

-- Функція ініціалізації
local function init()
    -- Скидання змійки в центр
    snake = {
        {x = math.floor(width / 2), y = math.floor(height / 2)},
        {x = math.floor(width / 2) - 1, y = math.floor(height / 2)},
        {x = math.floor(width / 2) - 2, y = math.floor(height / 2)}
    }
    dir = {x = 1, y = 0} 
    score = 0
    gameOver = false
    currentSpeed = startSpeed
    lossTime = 0           -- НОВЕ: Скидання часу програшу
    hapticPlayed = false   -- НОВЕ: Скидання прапора вібрації
    spawnFood()
end

-- Функція створення їжі
function spawnFood()
    local valid = false
    while not valid do
        food.x = math.random(0, width - 1)
        food.y = math.random(0, height - 1)
        valid = true
        for _, segment in ipairs(snake) do
            if segment.x == food.x and segment.y == food.y then
                valid = false
                break
            end
        end
    end
end

-- Головний цикл
local function run(event)
    lcd.clear()

    if event == EVT_EXIT_BREAK then
        return 2 
    end

    -- Відображення рахунку
    lcd.drawText(5, 5, "Score: " .. score, 0)
    lcd.drawText(LCD_W - 100, 5, "MAX: " .. maxScore, 0)
    
    local ail = getValue('ail')
    local ele = getValue('ele')
    local threshold = 500 
    
    -- ЛОГІКА КІНЦЯ ГРИ
    if gameOver then
	
        -- НОВЕ: Вібрація (спрацює лише один раз)
        if not hapticPlayed then
            playHaptic(2,0) -- 2 - сильний імпульс
            hapticPlayed = true
        end
        -- Оновлюємо рекорд у пам'яті
        if score > maxScore then
            maxScore = score
        end
		
        -- НОВЕ: Перевірка затримки (1 секунда)
        if getTime() - lossTime < restartDelay then
            -- Ігноруємо стіки, поки триває затримка
        else
            -- Якщо затримка минула, дозволяємо рестарт
            if math.abs(ail) > threshold or math.abs(ele) > threshold or event == EVT_KEY_LONG then
                init()
                return 0
            end
        end

        -- === КРАСИВИЙ GAME OVER ===
        
        -- 1. Малюємо напівпрозору підкладку (сірий прямокутник по центру)
        -- Відступи: зліва 40, зверху 30, ширина W-80, висота H-60
        lcd.drawFilledRectangle(40, 30, LCD_W - 80, LCD_H - 60, GREY)
        
        -- 2. Малюємо рамку навколо
        lcd.drawRectangle(40, 30, LCD_W - 80, LCD_H - 60, WHITE, 2) -- 2 це товщина лінії

        -- 3. Заголовок (Величезний, Червоний, Миготливий)
        -- XXLSIZE - дуже великий шрифт
        lcd.drawText(LCD_W / 2 - 180, 50, "GAME OVER", XXLSIZE + RED + BLINK)

        -- 4. Рахунок (Великий, Жовтий)
        lcd.drawText(LCD_W / 2 - 60, 100, "Score: " .. score, DBLSIZE + YELLOW)
        
        -- 5. Інструкція (Маленький, Білий на чорному тлі - INVERS)
        lcd.drawText(LCD_W / 2 - 115, 150, " Move Stick to Restart ", MIDSIZE + INVERS)
        lcd.drawText(LCD_W / 2 - 60, LCD_H - 20, "Press RTN to Exit", SMLSIZE)
        
        return 0
    end

    -- УПРАВЛІННЯ
    if ail > threshold and dir.x == 0 then dir = {x = 1, y = 0}
    elseif ail < -threshold and dir.x == 0 then dir = {x = -1, y = 0}
    elseif ele > threshold and dir.y == 0 then dir = {x = 0, y = -1}
    elseif ele < -threshold and dir.y == 0 then dir = {x = 0, y = 1}
    end

    -- РУХ
    local now = getTime()
    if now - lastMoveTime > currentSpeed then
        lastMoveTime = now
        
        local newHead = {x = snake[1].x + dir.x, y = snake[1].y + dir.y}

        -- Зіткнення зі стінами
        if newHead.x < 0 or newHead.x >= width or newHead.y < 0 or newHead.y >= height then
            gameOver = true
            playTone(300, 500, 0, PLAY_NOW)
			lossTime = getTime()           -- НОВЕ: Фіксуємо час програшу
        end

        -- Зіткнення з хвостом
        for _, segment in ipairs(snake) do
            if newHead.x == segment.x and newHead.y == segment.y then
                gameOver = true
                playTone(300, 500, 0, PLAY_NOW)
                lossTime = getTime()
            end
        end
        
        if not gameOver then
            table.insert(snake, 1, newHead)

            if newHead.x == food.x and newHead.y == food.y then
                score = score + 1
                spawnFood()
                
                -- Прискорення
                if score % 10 == 0 then
                    playTone(2000, 300, 0, PLAY_NOW)
                    if currentSpeed > maxSpeed then
                        currentSpeed = currentSpeed - speedStep
                    end
                else
                    playTone(1000, 100, 0, PLAY_NOW)
                end
            else
                table.remove(snake)
            end
        end
    end

    -- МАЛЮВАННЯ
    lcd.drawFilledRectangle(food.x * cellSize, food.y * cellSize, cellSize - 1, cellSize - 1, RED)
    
    for i, segment in ipairs(snake) do
        local color = GREEN
        if i == 1 then color = YELLOW end 
        lcd.drawFilledRectangle(segment.x * cellSize, segment.y * cellSize, cellSize - 1, cellSize - 1, color)
    end

    return 0
end

return { init=init, run=run }
