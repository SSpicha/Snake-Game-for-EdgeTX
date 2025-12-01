-- "Snake" game for EdgeTX (RadioMaster)
-- Fixed version: High score is stored in RAM only (to avoid file system errors)
-- Controls: Right Stick (Aileron/Elevator)

local snake = {}
local dir = {x = 1, y = 0} 
local food = {x = 0, y = 0}
local cellSize = 10 
local width = LCD_W / cellSize
local height = LCD_H / cellSize
local score = 0
local maxScore = 0 -- High score (stored until exit)
local gameOver = false
local lastMoveTime = 0

-- Speed settings
local startSpeed = 20 
local currentSpeed = startSpeed
local speedStep = 2 
local maxSpeed = 4 

-- NEW VARIABLES 
local lossTime = 0 
local restartDelay = 100 -- 100 ticks * 10ms = 1 second delay
local hapticPlayed = false -- Flag to ensure haptic plays only once

-- Initialization function
local function init()
    -- Reset snake to the center
    snake = {
        {x = math.floor(width / 2), y = math.floor(height / 2)},
        {x = math.floor(width / 2) - 1, y = math.floor(height / 2)},
        {x = math.floor(width / 2) - 2, y = math.floor(height / 2)}
    }
    dir = {x = 1, y = 0} 
    score = 0
    gameOver = false
    currentSpeed = startSpeed
    lossTime = 0           -- NEW: Reset loss time
    hapticPlayed = false   -- NEW: Reset haptic flag
    spawnFood()
end

-- Food spawning function
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

-- Main loop
local function run(event)
    lcd.clear()

    if event == EVT_EXIT_BREAK then
        return 2 
    end

    -- Display score
    lcd.drawText(5, 5, "Score: " .. score, 0)
    lcd.drawText(LCD_W - 100, 5, "MAX: " .. maxScore, 0)
    
    local ail = getValue('ail')
    local ele = getValue('ele')
    local threshold = 500 
    
    -- GAME OVER LOGIC
    if gameOver then
    
        -- NEW: Haptic (triggers only once)
        if not hapticPlayed then
            playHaptic(2,0) -- 2 - strong pulse
            hapticPlayed = true
        end
        -- Update high score in memory
        if score > maxScore then
            maxScore = score
        end
        
        -- NEW: Delay check (1 second)
        if getTime() - lossTime < restartDelay then
            -- Ignore sticks while delay is active
        else
            -- If delay has passed, allow restart
            if math.abs(ail) > threshold or math.abs(ele) > threshold or event == EVT_KEY_LONG then
                init()
                return 0
            end
        end

        -- === FANCY GAME OVER ===
        
        -- 1. Draw semi-transparent background (grey rectangle in the center)
        -- Margins: left 40, top 30, width W-80, height H-60
        lcd.drawFilledRectangle(40, 30, LCD_W - 80, LCD_H - 60, GREY)
        
        -- 2. Draw border around
        lcd.drawRectangle(40, 30, LCD_W - 80, LCD_H - 60, WHITE, 2) -- 2 is line thickness

        -- 3. Title (Huge, Red, Blinking)
        -- XXLSIZE - very large font
        lcd.drawText(LCD_W / 2 - 180, 50, "GAME OVER", XXLSIZE + RED + BLINK)

        -- 4. Score (Large, Yellow)
        lcd.drawText(LCD_W / 2 - 60, 100, "Score: " .. score, DBLSIZE + YELLOW)
        
        -- 5. Instruction (Small, White on black background - INVERS)
        lcd.drawText(LCD_W / 2 - 115, 150, " Move Stick to Restart ", MIDSIZE + INVERS)
        lcd.drawText(LCD_W / 2 - 60, LCD_H - 20, "Press RTN to Exit", SMLSIZE)
        
        return 0
    end

    -- CONTROLS
    if ail > threshold and dir.x == 0 then dir = {x = 1, y = 0}
    elseif ail < -threshold and dir.x == 0 then dir = {x = -1, y = 0}
    elseif ele > threshold and dir.y == 0 then dir = {x = 0, y = -1}
    elseif ele < -threshold and dir.y == 0 then dir = {x = 0, y = 1}
    end

    -- MOVEMENT
    local now = getTime()
    if now - lastMoveTime > currentSpeed then
        lastMoveTime = now
        
        local newHead = {x = snake[1].x + dir.x, y = snake[1].y + dir.y}

        -- Collision with walls
        if newHead.x < 0 or newHead.x >= width or newHead.y < 0 or newHead.y >= height then
            gameOver = true
            playTone(300, 500, 0, PLAY_NOW)
            lossTime = getTime()           -- NEW: Record loss time
        end

        -- Collision with tail
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
                
                -- Acceleration
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

    -- DRAWING
    lcd.drawFilledRectangle(food.x * cellSize, food.y * cellSize, cellSize - 1, cellSize - 1, RED)
    
    for i, segment in ipairs(snake) do
        local color = GREEN
        if i == 1 then color = YELLOW end 
        lcd.drawFilledRectangle(segment.x * cellSize, segment.y * cellSize, cellSize - 1, cellSize - 1, color)
    end

    return 0
end

return { init=init, run=run }
