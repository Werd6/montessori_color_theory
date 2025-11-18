-- LOVE2D Main Entry Point - Montessori Color Theory

-- Constants
local SIDEBAR_WIDTH = 150
local CIRCLE_RADIUS = 30
local SOURCE_CIRCLE_RADIUS = 25

-- Colors
local RED = {1, 0, 0}
local GREEN = {0, 1, 0}
local BLUE = {0, 0, 1}
local GRAY = {0.3, 0.3, 0.3}
local LIGHT_GRAY = {0.9, 0.9, 0.9}
local DARK_GRAY = {0.2, 0.2, 0.2}

-- Game state
local sourceCircles = {}
local canvasCircles = {}
local dragging = nil
local dragOffset = {x = 0, y = 0}
local isNewCircle = false -- Track if we're dragging a new circle from sidebar

function love.load()
    love.graphics.setBackgroundColor(0.95, 0.95, 0.95) -- Light gray background
    
    -- Create source circles in sidebar
    local colors = {RED, GREEN, BLUE}
    local colorNames = {"Red", "Green", "Blue"}
    
    for i, color in ipairs(colors) do
        table.insert(sourceCircles, {
            x = SIDEBAR_WIDTH / 2,
            y = 100 + (i - 1) * 100,
            radius = SOURCE_CIRCLE_RADIUS,
            color = color,
            name = colorNames[i],
            isSource = true
        })
    end
end

function love.update(dt)
    -- Update dragging position if dragging
    if dragging then
        local mx, my = love.mouse.getPosition()
        dragging.x = mx - dragOffset.x
        dragging.y = my - dragOffset.y
    end
end

function love.draw()
    local width, height = love.graphics.getDimensions()
    
    -- Draw sidebar background
    love.graphics.setColor(DARK_GRAY)
    love.graphics.rectangle("fill", 0, 0, SIDEBAR_WIDTH, height)
    
    -- Draw sidebar border
    love.graphics.setColor(GRAY)
    love.graphics.setLineWidth(2)
    love.graphics.line(SIDEBAR_WIDTH, 0, SIDEBAR_WIDTH, height)
    
    -- Draw sidebar title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Colors", 10, 20, 0, 1.2, 1.2)
    
    -- Draw source circles in sidebar
    for i, circle in ipairs(sourceCircles) do
        if circle ~= dragging then
            drawCircle(circle)
        end
    end
    
    -- Draw canvas background
    local canvasX = SIDEBAR_WIDTH
    local canvasY = 0
    local canvasWidth = width - SIDEBAR_WIDTH
    local canvasHeight = height
    
    love.graphics.setColor(LIGHT_GRAY)
    love.graphics.rectangle("fill", canvasX, canvasY, canvasWidth, canvasHeight)
    
    -- Draw canvas border
    love.graphics.setColor(GRAY)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", canvasX, canvasY, canvasWidth, canvasHeight)
    
    -- Draw canvas title
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Canvas", canvasX + 10, 20, 0, 1.2, 1.2)
    
    -- Draw canvas circles with color blending for overlaps
    drawCanvasCircles()
    
    -- Draw dragging circle on top
    if dragging then
        drawCircle(dragging)
    end
end

function drawCircle(circle)
    love.graphics.setColor(circle.color)
    love.graphics.circle("fill", circle.x, circle.y, circle.radius)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", circle.x, circle.y, circle.radius)
end

-- Draw canvas circles with Venn diagram color blending
function drawCanvasCircles()
    local circlesToDraw = {}
    for i, circle in ipairs(canvasCircles) do
        if circle ~= dragging then
            table.insert(circlesToDraw, circle)
        end
    end
    
    if #circlesToDraw == 0 then
        return
    end
    
    -- Use additive blending to create Venn diagram effect
    -- Additive blending: Red+Green=Yellow, Red+Blue=Magenta, Green+Blue=Cyan, All=White
    love.graphics.setBlendMode("add")
    
    -- Draw each circle with colors that will blend additively
    -- Using 0.5 intensity so overlaps don't get too bright
    for i, circle in ipairs(circlesToDraw) do
        love.graphics.setColor(circle.color[1] * 0.5, circle.color[2] * 0.5, circle.color[3] * 0.5, 1)
        love.graphics.circle("fill", circle.x, circle.y, circle.radius)
    end
    
    -- Reset blend mode to normal
    love.graphics.setBlendMode("alpha")
    
    -- Draw black outlines on top for definition
    for i, circle in ipairs(circlesToDraw) do
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", circle.x, circle.y, circle.radius)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        -- Check if clicking on a source circle
        for i, circle in ipairs(sourceCircles) do
            if pointInCircle(x, y, circle) then
                -- Create a new circle to drag
                dragging = {
                    x = x,
                    y = y,
                    radius = CIRCLE_RADIUS,
                    color = {circle.color[1], circle.color[2], circle.color[3]},
                    name = circle.name
                }
                dragOffset.x = 0
                dragOffset.y = 0
                isNewCircle = true
                return
            end
        end
        
        -- Check if clicking on a canvas circle to move it
        for i, circle in ipairs(canvasCircles) do
            if pointInCircle(x, y, circle) then
                dragging = circle
                dragOffset.x = x - circle.x
                dragOffset.y = y - circle.y
                isNewCircle = false
                return
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and dragging then
        local width, height = love.graphics.getDimensions()
        local canvasX = SIDEBAR_WIDTH
        local canvasY = 0
        local canvasWidth = width - SIDEBAR_WIDTH
        local canvasHeight = height
        
        -- Check if dropped on canvas
        if x >= canvasX and x <= canvasX + canvasWidth and
           y >= canvasY and y <= canvasY + canvasHeight then
            -- Place on canvas
            if isNewCircle then
                -- New circle from sidebar - add to canvas
                table.insert(canvasCircles, dragging)
                isNewCircle = false
            end
            -- Existing canvas circle being moved - already in canvasCircles, position updated in update()
        else
            -- Dropped outside canvas
            if isNewCircle then
                -- Cancel new circle creation
                isNewCircle = false
            else
                -- Remove existing circle if moved outside canvas
                for i, circle in ipairs(canvasCircles) do
                    if circle == dragging then
                        table.remove(canvasCircles, i)
                        break
                    end
                end
            end
        end
        
        dragging = nil
        
    end
end

function pointInCircle(px, py, circle)
    local dx = px - circle.x
    local dy = py - circle.y
    return (dx * dx + dy * dy) <= (circle.radius * circle.radius)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "c" then
        -- Clear canvas
        canvasCircles = {}
    end
end

