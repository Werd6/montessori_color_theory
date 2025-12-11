-- LOVE2D Main Entry Point - Montessori Color Theory

-- Load color name dictionary
local colorNames = require("color_names")

-- Constants
local SIDEBAR_WIDTH = 200
local CIRCLE_RADIUS = 80
local SOURCE_CIRCLE_RADIUS = 25
local COLUMNS = 3
local CIRCLE_SPACING = 50
local SIDEBAR_SCROLL_SPEED = 10
local COLOR_TOLERANCE = 0.01 -- Tolerance for color matching

-- Colors
local RED = {1, 0, 0}
local GREEN = {0, 1, 0}
local BLUE = {0, 0, 1}
local BLACK = {0, 0, 0}
local CYAN = {0, 1, 1}
local YELLOW = {1, 1, 0}
local MAGENTA = {1, 0, 1}
local WHITE = {1, 1, 1}
local GRAY = {0.3, 0.3, 0.3}
local LIGHT_GRAY = {0.9, 0.9, 0.9}
local DARK_GRAY = {0.2, 0.2, 0.2}

-- Game state
local gameState = "additive" -- "additive", "subtractive", or "paint"
local sourceCircles = {}
local canvasCircles = {}
local dragging = nil
local dragOffset = {x = 0, y = 0}
local isNewCircle = false -- Track if we're dragging a new circle from sidebar
local renderCanvas = nil -- Canvas for rendering circles with blending
local unlockedColorsAdditive = {} -- Track unlocked colors for additive mode
local unlockedColorsSubtractive = {} -- Track unlocked colors for subtractive mode
local unlockedColorsPaint = {} -- Track unlocked colors for paint mode
local popup = {
    visible = false,
    color = nil,
    colorName = nil,
    x = 0,
    y = 0,
    width = 300,
    height = 150
}
local colorUnlockQueue = {} -- Queue for multiple color unlocks
local circlesToClear = {} -- Track circles to clear after all notifications are closed

local sidebarScrollY = 0 -- Scroll offset for sidebar
local scrollbar = {
    x = SIDEBAR_WIDTH - 15, -- Right edge of sidebar
    width = 10,
    dragging = false,
    dragStartY = 0,
    dragStartScrollY = 0
}
local clearButton = {
    x = 0, -- Will be set in draw
    y = 10,
    width = 100,
    height = 30
}
local dropdown = {
    x = 0, -- Will be set in draw
    y = 10,
    width = 120,
    itemHeight = 30,
    isOpen = false,
    options = {
        {state = "additive", label = "RGB"},
        {state = "subtractive", label = "CYM"},
        {state = "paint", label = "Paint"}
    }
}

function love.load()
    love.graphics.setBackgroundColor(0.95, 0.95, 0.95) -- Light gray background
    
    -- Create render canvas for circle blending
    local width, height = love.graphics.getDimensions()
    renderCanvas = love.graphics.newCanvas(width - SIDEBAR_WIDTH, height)
    
    -- Initialize source circles for current game state
    initializeSourceCircles()
end

-- Initialize source circles based on current game state
function initializeSourceCircles()
    sourceCircles = {}
    
    local colors, colorNames
    if gameState == "additive" then
        colors = {RED, GREEN, BLUE, BLACK}
        colorNames = {"Red", "Green", "Blue", "Black"}
    elseif gameState == "subtractive" then
        colors = {CYAN, YELLOW, MAGENTA, WHITE}
        colorNames = {"Cyan", "Yellow", "Magenta", "White"}
    else -- paint
        colors = {RED, YELLOW, BLUE, WHITE}
        colorNames = {"Red", "Yellow", "Blue", "White"}
    end
    
    for i, color in ipairs(colors) do
        -- Check if color is black (for additive) or white (for subtractive)
        local isBlack = (color[1] == 0 and color[2] == 0 and color[3] == 0)
        local isWhite = (color[1] == 1 and color[2] == 1 and color[3] == 1)
        -- Calculate position in 3-column grid
        local col = (i - 1) % COLUMNS
        local row = math.floor((i - 1) / COLUMNS)
        local circleSpacing = SOURCE_CIRCLE_RADIUS * 2 + 10
        local startX = SIDEBAR_WIDTH / (COLUMNS + 1)
        local startY = 100
        
        table.insert(sourceCircles, {
            x = startX * (col + 1),
            y = startY + row * circleSpacing,
            radius = SOURCE_CIRCLE_RADIUS,
            color = color,
            name = colorNames[i],
            isSource = true,
            isBlack = isBlack, -- Mark black circles for special handling
            isWhite = isWhite -- Mark white circles for special handling
        })
        
        -- Mark initial colors as unlocked for current state
        markColorUnlocked(color[1], color[2], color[3])
    end
end

-- Switch game state
function switchGameState(newState)
    gameState = newState
    
    -- Clear canvas
    canvasCircles = {}
    dragging = nil
    
    -- Close popup
    popup.visible = false
    
    -- Reset sidebar scroll
    sidebarScrollY = 0
    
    -- Reinitialize source circles for new state
    initializeSourceCircles()
end

function love.update(dt)
    -- Update dragging position if dragging
    if dragging then
        local mx, my = love.mouse.getPosition()
        dragging.x = mx - dragOffset.x
        dragging.y = my - dragOffset.y
    end
    
    -- Update scrollbar dragging
    if scrollbar.dragging then
        local _, my = love.mouse.getPosition()
        local width, height = love.graphics.getDimensions()
        local sidebarContentTop = 80
        local sidebarContentHeight = height - sidebarContentTop
        
        -- Calculate total content height
        local totalContentHeight = 0
        if #sourceCircles > 0 then
            local lastCircle = sourceCircles[#sourceCircles]
            local circleSpacing = SOURCE_CIRCLE_RADIUS * 2 + 10
            totalContentHeight = lastCircle.y + SOURCE_CIRCLE_RADIUS + 20 - 100
        end
        
        local maxScroll = math.min(0, sidebarContentHeight - totalContentHeight)
        local scrollbarTrackHeight = sidebarContentHeight
        local scrollbarThumbHeight = math.max(20, (sidebarContentHeight / totalContentHeight) * scrollbarTrackHeight)
        local scrollableHeight = scrollbarTrackHeight - scrollbarThumbHeight
        
        if scrollableHeight > 0 then
            local dragDelta = my - scrollbar.dragStartY
            local scrollDelta = (dragDelta / scrollableHeight) * maxScroll
            sidebarScrollY = scrollbar.dragStartScrollY + scrollDelta
            sidebarScrollY = math.max(maxScroll, math.min(0, sidebarScrollY))
        end
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
    
    -- Calculate sidebar content area
    local sidebarContentTop = 80
    local sidebarContentHeight = height - sidebarContentTop
    
    -- Calculate total content height
    local totalContentHeight = 0
    if #sourceCircles > 0 then
        local lastCircle = sourceCircles[#sourceCircles]
        local circleSpacing = SOURCE_CIRCLE_RADIUS * 2 + 10
        totalContentHeight = lastCircle.y + SOURCE_CIRCLE_RADIUS + 20 - 100 -- 100 is startY
    end
    
    -- Calculate max scroll (negative value)
    local maxScroll = math.min(0, sidebarContentHeight - totalContentHeight)
    
    -- Clamp scroll position
    sidebarScrollY = math.max(maxScroll, math.min(0, sidebarScrollY))
    
    -- Set up scissor for scrollable sidebar content
    love.graphics.setScissor(0, sidebarContentTop, SIDEBAR_WIDTH, sidebarContentHeight)
    
    -- Draw source circles in sidebar with scroll offset
    for i, circle in ipairs(sourceCircles) do
        if circle ~= dragging then
            -- Apply scroll offset
            local originalY = circle.y
            circle.y = circle.y + sidebarScrollY
            drawCircle(circle)
            circle.y = originalY -- Restore original position
        end
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw scrollbar if content exceeds visible area
    if totalContentHeight > sidebarContentHeight then
        drawScrollbar(sidebarContentTop, sidebarContentHeight, totalContentHeight, maxScroll)
    end
    
    -- Draw canvas background
    local canvasX = SIDEBAR_WIDTH
    local canvasY = 0
    local canvasWidth = width - SIDEBAR_WIDTH
    local canvasHeight = height
    
    -- Use white background for all modes (background doesn't affect blending)
    if gameState == "additive" then
        love.graphics.setColor(WHITE)
    elseif gameState == "paint" then
        love.graphics.setColor(WHITE)
    else -- subtractive
        love.graphics.setColor(LIGHT_GRAY)
    end
    love.graphics.rectangle("fill", canvasX, canvasY, canvasWidth, canvasHeight)
    
    -- Draw canvas border
    love.graphics.setColor(GRAY)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", canvasX, canvasY, canvasWidth, canvasHeight)
    
    -- Draw canvas title with current mode
    -- Black text for all modes (white/light gray backgrounds)
    if gameState == "additive" then
        love.graphics.setColor(0, 0, 0) -- Black text
    else
        love.graphics.setColor(0, 0, 0) -- Black text
    end
    local canvasTitle
    if gameState == "additive" then
        canvasTitle = "Canvas (RGB)"
    elseif gameState == "paint" then
        canvasTitle = "Canvas (Paint)"
    else
        canvasTitle = "Canvas (CYM)"
    end
    love.graphics.print(canvasTitle, canvasX + 10, 20, 0, 1.2, 1.2)
    
    -- Draw clear button in top right
    clearButton.x = width - clearButton.width - 10
    drawClearButton(clearButton)
    
    -- Draw canvas circles with color blending for overlaps
    if gameState == "additive" then
        drawCanvasCircles()
    elseif gameState == "paint" then
        drawCanvasCirclesPaint()
    else
        drawCanvasCirclesSubtractive()
    end
    
    -- Draw dragging circle on top
    if dragging then
        drawCircle(dragging)
    end
    
    -- Draw dropdown menu in top right (above clear button)
    dropdown.x = width - dropdown.width - 10
    drawDropdown(dropdown)
    
    -- Draw popup on top of everything
    if popup.visible then
        drawPopup(popup)
    end
end

-- Helper function to draw circle text label
function drawCircleText(circle, offsetX, offsetY)
    if not circle.name then
        return
    end
    
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    
    local circleX = circle.x + offsetX
    local circleY = circle.y + offsetY
    
    -- Calculate luminance using standard formula (perceived brightness)
    -- Weights: Red 0.299, Green 0.587, Blue 0.114 (human eye sensitivity)
    local r, g, b = circle.color[1], circle.color[2], circle.color[3]
    local luminance = 0.299 * r + 0.587 * g + 0.114 * b
    
    -- Choose black text for light colors, white text for dark colors
    if luminance > 0.5 then
        love.graphics.setColor(0, 0, 0) -- Black text for light backgrounds
    else
        love.graphics.setColor(1, 1, 1) -- White text for dark backgrounds
    end
    
    -- Get font and calculate text dimensions
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(circle.name)
    local textHeight = font:getHeight()
    
    -- Calculate scale to fit text within circle (with padding)
    local maxTextWidth = circle.radius * 1.6 -- Allow text to be slightly wider than radius
    local scale = math.min(1, maxTextWidth / textWidth)
    
    -- Center text on circle
    local textX = circleX - (textWidth * scale) / 2
    local textY = circleY - (textHeight * scale) / 2
    
    -- Draw text with scaling
    love.graphics.print(circle.name, textX, textY, 0, scale, scale)
end

function drawCircle(circle)
    love.graphics.setColor(circle.color)
    love.graphics.circle("fill", circle.x, circle.y, circle.radius)
    -- Use white border for black circles, black border for white circles and others
    if isCircleBlack(circle) then
        love.graphics.setColor(1, 1, 1) -- White border for black
    elseif isCircleWhite(circle) then
        love.graphics.setColor(0, 0, 0) -- Black border for white
    else
        love.graphics.setColor(0, 0, 0) -- Black border for others
    end
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", circle.x, circle.y, circle.radius)
    
    -- Draw color name with inverse color for visibility
    drawCircleText(circle)
end

function drawPopup(popup)
    if not popup.visible or not popup.color then
        return
    end
    
    local width, height = love.graphics.getDimensions()
    local x = (width - popup.width) / 2
    local y = (height - popup.height) / 2
    popup.x = x
    popup.y = y
    
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, popup.width, popup.height, 10, 10)
    
    -- Draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, popup.width, popup.height, 10, 10)
    
    -- Draw text
    local text = "You unlocked " .. (popup.colorName or "a new color")
    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    love.graphics.print(text, x + (popup.width - textWidth) / 2, y + 30)
    
    -- Draw color circle
    local circleX = x + popup.width / 2
    local circleY = y + 80
    local circleRadius = 25
    love.graphics.setColor(popup.color[1], popup.color[2], popup.color[3])
    love.graphics.circle("fill", circleX, circleY, circleRadius)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", circleX, circleY, circleRadius)
    
    -- Draw X button
    local buttonSize = 25
    local buttonX = x + popup.width - buttonSize - 10
    local buttonY = y + 10
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonSize, buttonSize, 3, 3)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, buttonY, buttonSize, buttonSize, 3, 3)
    -- Draw X
    love.graphics.setLineWidth(2)
    love.graphics.line(buttonX + 5, buttonY + 5, buttonX + buttonSize - 5, buttonY + buttonSize - 5)
    love.graphics.line(buttonX + buttonSize - 5, buttonY + 5, buttonX + 5, buttonY + buttonSize - 5)
end

function drawDropdown(dropdown)
    local currentLabel = ""
    for _, option in ipairs(dropdown.options) do
        if option.state == gameState then
            currentLabel = option.label
            break
        end
    end
    
    -- Draw main button
    love.graphics.setColor(0.2, 0.5, 0.8) -- Blue
    love.graphics.rectangle("fill", dropdown.x, dropdown.y, dropdown.width, dropdown.itemHeight, 5, 5)
    
    -- Draw button border
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dropdown.x, dropdown.y, dropdown.width, dropdown.itemHeight, 5, 5)
    
    -- Draw current selection text
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(currentLabel)
    local textHeight = font:getHeight()
    love.graphics.print(currentLabel, dropdown.x + 10, dropdown.y + (dropdown.itemHeight - textHeight) / 2)
    
    -- Draw dropdown arrow
    local arrowX = dropdown.x + dropdown.width - 20
    local arrowY = dropdown.y + dropdown.itemHeight / 2
    love.graphics.setColor(1, 1, 1)
    if dropdown.isOpen then
        -- Up arrow
        love.graphics.polygon("fill", arrowX, arrowY - 3, arrowX - 5, arrowY + 3, arrowX + 5, arrowY + 3)
    else
        -- Down arrow
        love.graphics.polygon("fill", arrowX, arrowY + 3, arrowX - 5, arrowY - 3, arrowX + 5, arrowY - 3)
    end
    
    -- Draw dropdown menu if open
    if dropdown.isOpen then
        local menuY = dropdown.y + dropdown.itemHeight
        local menuHeight = #dropdown.options * dropdown.itemHeight
        
        -- Draw menu background
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("fill", dropdown.x, menuY, dropdown.width, menuHeight, 5, 5)
        
        -- Draw menu border
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", dropdown.x, menuY, dropdown.width, menuHeight, 5, 5)
        
        -- Draw menu items
        for i, option in ipairs(dropdown.options) do
            local itemY = menuY + (i - 1) * dropdown.itemHeight
            
            -- Highlight current selection
            if option.state == gameState then
                love.graphics.setColor(0.7, 0.8, 0.9)
                love.graphics.rectangle("fill", dropdown.x + 2, itemY + 2, dropdown.width - 4, dropdown.itemHeight - 4)
            end
            
            -- Draw item text
            love.graphics.setColor(0, 0, 0)
            local textHeight = font:getHeight()
            love.graphics.print(option.label, dropdown.x + 10, itemY + (dropdown.itemHeight - textHeight) / 2)
        end
    end
end

function drawClearButton(button)
    -- Draw button background
    love.graphics.setColor(0.7, 0.2, 0.2) -- Dark red
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 5, 5)
    
    -- Draw button border
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 5, 5)
    
    -- Draw button text
    love.graphics.setColor(1, 1, 1)
    local text = "Clear"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, button.x + (button.width - textWidth) / 2, button.y + (button.height - textHeight) / 2)
end

function drawScrollbar(contentTop, contentHeight, totalHeight, maxScroll)
    -- Calculate scrollbar dimensions
    local scrollbarTrackHeight = contentHeight
    local scrollbarThumbHeight = math.max(20, (contentHeight / totalHeight) * scrollbarTrackHeight)
    local scrollRatio = -sidebarScrollY / maxScroll -- 0 to 1
    local scrollbarThumbY = contentTop + (scrollbarTrackHeight - scrollbarThumbHeight) * scrollRatio
    
    -- Draw scrollbar track (background)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", scrollbar.x, contentTop, scrollbar.width, scrollbarTrackHeight)
    
    -- Draw scrollbar thumb
    if scrollbar.dragging then
        love.graphics.setColor(0.6, 0.6, 0.6) -- Lighter when dragging
    else
        love.graphics.setColor(0.5, 0.5, 0.5) -- Normal color
    end
    love.graphics.rectangle("fill", scrollbar.x, scrollbarThumbY, scrollbar.width, scrollbarThumbHeight)
    
    -- Draw scrollbar border
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", scrollbar.x, contentTop, scrollbar.width, scrollbarTrackHeight)
    love.graphics.rectangle("line", scrollbar.x, scrollbarThumbY, scrollbar.width, scrollbarThumbHeight)
end

-- Draw canvas circles with Venn diagram color blending
function drawCanvasCircles()
    local width, height = love.graphics.getDimensions()
    local canvasX = SIDEBAR_WIDTH
    local canvasY = 0
    local canvasWidth = width - SIDEBAR_WIDTH
    local canvasHeight = height
    
    -- Update canvas size if window was resized or doesn't exist
    if not renderCanvas or renderCanvas:getWidth() ~= canvasWidth or renderCanvas:getHeight() ~= canvasHeight then
        renderCanvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
    end
    
    local circlesToDraw = {}
    local blackCircles = {}
    for i, circle in ipairs(canvasCircles) do
        if circle ~= dragging then
            -- Separate black circles from colored circles
            if isCircleBlack(circle) then
                table.insert(blackCircles, circle)
            else
                table.insert(circlesToDraw, circle)
            end
        end
    end
    
    -- Render circles to canvas with black background for additive blending
    -- Additive blending works correctly on black (transparent acts as black)
    love.graphics.setCanvas(renderCanvas)
    love.graphics.clear(0, 0, 0, 1) -- Clear to black for additive blending
    
    if #circlesToDraw == 0 and #blackCircles == 0 then
        -- No circles, just clear and return
        love.graphics.setCanvas()
        return
    end
    
    -- Draw colored circles with additive blending first
    if #circlesToDraw > 0 then
        -- Use additive blending to create Venn diagram effect
        -- Additive blending: Red+Green=Yellow, Red+Blue=Magenta, Green+Blue=Cyan, All=White
        love.graphics.setBlendMode("add")
        
        -- Draw each colored circle with full intensity colors
        for i, circle in ipairs(circlesToDraw) do
            local relX = circle.x - canvasX
            local relY = circle.y - canvasY
            love.graphics.setColor(circle.color[1], circle.color[2], circle.color[3], 1)
            love.graphics.circle("fill", relX, relY, circle.radius)
        end
    end
    
    -- Don't draw black circles on canvas - we'll draw them on screen with proper blending
    
    -- Stop rendering to canvas (don't draw outlines on canvas - we'll draw them separately)
    love.graphics.setCanvas()
    
    -- Process the ImageData to make black background transparent and preserve colors
    -- Black circles are drawn separately on screen, so we don't need to preserve them here
    local imageData = renderCanvas:newImageData()
    imageData:mapPixel(function(x, y, r, g, b, a)
        -- Check if this pixel has any color content (not pure black)
        -- Lower threshold to preserve darkened colors from black circles
        if r > 0.005 or g > 0.005 or b > 0.005 then
            -- Keep the color as-is, but ensure full opacity
            return r, g, b, 1
        else
            -- Pure black pixels (background) become transparent
            return 0, 0, 0, 0
        end
    end)
    
    -- Create new image from processed ImageData
    local displayImage = love.graphics.newImage(imageData)
    
    -- Draw with normal alpha blending - transparent areas show white background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha")
    love.graphics.draw(displayImage, canvasX, canvasY)
    
    -- Draw black circles with multiply blend to darken underlying colors
    if #blackCircles > 0 then
        -- Use multiply blend mode to darken colors and make circle appear black
        love.graphics.setBlendMode("multiply", "premultiplied")
        for i, circle in ipairs(blackCircles) do
            -- Use very dark gray (0.15) to darken colors significantly
            -- This makes overlapping colors darker while making the circle appear black
            love.graphics.setColor(0.15, 0.15, 0.15, 1)
            love.graphics.circle("fill", circle.x, circle.y, circle.radius)
        end
    end
    
    -- Draw outlines directly on screen (not on canvas) so they show correctly on white
    love.graphics.setBlendMode("alpha")
    -- Colored circles get black outlines
    for i, circle in ipairs(circlesToDraw) do
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", circle.x, circle.y, circle.radius)
        -- Draw text label
        drawCircleText(circle)
    end
    
    -- Black circles get black outlines (visible on white background)
    for i, circle in ipairs(blackCircles) do
        love.graphics.setColor(0, 0, 0) -- Black outline for black circles
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", circle.x, circle.y, circle.radius)
        -- Draw text label (will be white text on black background)
        drawCircleText(circle)
    end
end

-- Draw canvas circles with subtractive color blending (CYM)
function drawCanvasCirclesSubtractive()
    local width, height = love.graphics.getDimensions()
    local canvasX = SIDEBAR_WIDTH
    local canvasY = 0
    local canvasWidth = width - SIDEBAR_WIDTH
    local canvasHeight = height
    
    -- Update canvas size if window was resized or doesn't exist
    if not renderCanvas or renderCanvas:getWidth() ~= canvasWidth or renderCanvas:getHeight() ~= canvasHeight then
        renderCanvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
    end
    
    local circlesToDraw = {}
    local whiteCircles = {}
    for i, circle in ipairs(canvasCircles) do
        if circle ~= dragging then
            -- Separate white circles from colored circles in subtractive mode
            if isCircleWhite(circle) then
                table.insert(whiteCircles, circle)
            else
                table.insert(circlesToDraw, circle)
            end
        end
    end
    
    -- Render circles to canvas with transparent background (no background in blending)
    love.graphics.setCanvas(renderCanvas)
    love.graphics.clear(0, 0, 0, 0) -- Clear to transparent
    
    if #circlesToDraw == 0 and #whiteCircles == 0 then
        -- No circles, just clear and return
        love.graphics.setCanvas()
        return
    end
    
    -- Draw colored circles with multiply blend mode for subtractive mixing
    -- Start with white base for multiply blending to work correctly
    if #circlesToDraw > 0 then
        -- First, fill with white so multiply blend works
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
        
        -- Use multiply blend mode to create subtractive color mixing
        -- Multiply: Cyan+Yellow=Green, Cyan+Magenta=Blue, Yellow+Magenta=Red, All=Black
        love.graphics.setBlendMode("multiply", "premultiplied")
        
        -- Draw each colored circle
        for i, circle in ipairs(circlesToDraw) do
            local relX = circle.x - canvasX
            local relY = circle.y - canvasY
            love.graphics.setColor(circle.color[1], circle.color[2], circle.color[3], 1)
            love.graphics.circle("fill", relX, relY, circle.radius)
        end
    end
    
    -- Draw white circles with additive blend mode to lighten colors
    if #whiteCircles > 0 then
        -- Use additive blend mode to lighten underlying colors
        love.graphics.setBlendMode("add")
        
        for i, circle in ipairs(whiteCircles) do
            local relX = circle.x - canvasX
            local relY = circle.y - canvasY
            -- Use a lighter shade to add brightness without going to pure white
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.circle("fill", relX, relY, circle.radius)
        end
    end
    
    -- Reset blend mode to normal for outlines
    love.graphics.setBlendMode("alpha")
    
    -- Draw outlines on top for definition
    -- Colored circles get black outlines
    for i, circle in ipairs(circlesToDraw) do
        local relX = circle.x - canvasX
        local relY = circle.y - canvasY
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", relX, relY, circle.radius)
        -- Draw text label
        drawCircleText(circle, -canvasX, -canvasY)
    end
    
    -- White circles get black outlines
    for i, circle in ipairs(whiteCircles) do
        local relX = circle.x - canvasX
        local relY = circle.y - canvasY
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", relX, relY, circle.radius)
        -- Draw text label
        drawCircleText(circle, -canvasX, -canvasY)
    end
    
    -- Stop rendering to canvas
    love.graphics.setCanvas()
    
    -- Draw the canvas onto the screen with alpha blending
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha")
    love.graphics.draw(renderCanvas, canvasX, canvasY)
end

-- Mix RYB colors properly for paint mode
function mixRybColors(colors)
    if #colors == 0 then
        return {1, 1, 1} -- White
    end
    
    if #colors == 1 then
        return {colors[1][1], colors[1][2], colors[1][3]}
    end
    
    -- Check for specific RYB mixing combinations
    local hasRed = false
    local hasYellow = false
    local hasBlue = false
    
    for _, color in ipairs(colors) do
        local r, g, b = color[1], color[2], color[3]
        -- Check if it's close to Red (1,0,0)
        if r > 0.9 and g < 0.1 and b < 0.1 then
            hasRed = true
        end
        -- Check if it's close to Yellow (1,1,0)
        if r > 0.9 and g > 0.9 and b < 0.1 then
            hasYellow = true
        end
        -- Check if it's close to Blue (0,0,1)
        if r < 0.1 and g < 0.1 and b > 0.9 then
            hasBlue = true
        end
    end
    
    -- Apply RYB mixing rules
    if hasRed and hasYellow and hasBlue then
        -- All three primaries = Brown/Dark
        return {0.4, 0.2, 0.1} -- Brown
    elseif hasRed and hasYellow then
        -- Red + Yellow = Orange
        return {1, 0.5, 0} -- Orange
    elseif hasYellow and hasBlue then
        -- Yellow + Blue = Green (this is the key fix!)
        return {0, 0.8, 0} -- Green
    elseif hasRed and hasBlue then
        -- Red + Blue = Purple
        return {0.5, 0, 0.5} -- Purple
    else
        -- For other combinations, use weighted average
        -- But weight towards the dominant color
        local totalR, totalG, totalB = 0, 0, 0
        local count = #colors
        for _, color in ipairs(colors) do
            totalR = totalR + color[1]
            totalG = totalG + color[2]
            totalB = totalB + color[3]
        end
        return {totalR / count, totalG / count, totalB / count}
    end
end

-- Draw canvas circles with paint mode RYB color averaging
function drawCanvasCirclesPaint()
    local width, height = love.graphics.getDimensions()
    local canvasX = SIDEBAR_WIDTH
    local canvasY = 0
    local canvasWidth = width - SIDEBAR_WIDTH
    local canvasHeight = height
    
    -- Update canvas size if window was resized or doesn't exist
    if not renderCanvas or renderCanvas:getWidth() ~= canvasWidth or renderCanvas:getHeight() ~= canvasHeight then
        renderCanvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
    end
    
    local circlesToDraw = {}
    local whiteCircles = {}
    for i, circle in ipairs(canvasCircles) do
        if circle ~= dragging then
            -- Separate white circles from colored circles in paint mode
            if isCircleWhite(circle) then
                table.insert(whiteCircles, circle)
            else
                table.insert(circlesToDraw, circle)
            end
        end
    end
    
    if #circlesToDraw == 0 and #whiteCircles == 0 then
        -- No circles, just clear and return
        love.graphics.setCanvas(renderCanvas)
        love.graphics.clear(1, 1, 1, 1)
        love.graphics.setCanvas()
        return
    end
    
    -- For paint mode, use optimized rendering - only process pixels within circle bounds
    -- Create ImageData initialized to transparent (background is separate layer)
    local imageData = love.image.newImageData(canvasWidth, canvasHeight)
    imageData:mapPixel(function(x, y, r, g, b, a)
        return 0, 0, 0, 0 -- Transparent background
    end)
    
    -- Calculate bounding box of all circles to limit processing area
    if #circlesToDraw > 0 or #whiteCircles > 0 then
        local minX, maxX = math.huge, -math.huge
        local minY, maxY = math.huge, -math.huge
        
        for _, circle in ipairs(circlesToDraw) do
            local relX = circle.x - canvasX
            local relY = circle.y - canvasY
            minX = math.min(minX, relX - circle.radius)
            maxX = math.max(maxX, relX + circle.radius)
            minY = math.min(minY, relY - circle.radius)
            maxY = math.max(maxY, relY + circle.radius)
        end
        
        for _, circle in ipairs(whiteCircles) do
            local relX = circle.x - canvasX
            local relY = circle.y - canvasY
            minX = math.min(minX, relX - circle.radius)
            maxX = math.max(maxX, relX + circle.radius)
            minY = math.min(minY, relY - circle.radius)
            maxY = math.max(maxY, relY + circle.radius)
        end
        
        -- Clamp to canvas bounds
        minX = math.max(0, math.floor(minX))
        maxX = math.min(canvasWidth - 1, math.ceil(maxX))
        minY = math.max(0, math.floor(minY))
        maxY = math.min(canvasHeight - 1, math.ceil(maxY))
        
        -- Only process pixels within the bounding box
        for y = minY, maxY do
            for x = minX, maxX do
                local screenX = x + canvasX
                local screenY = y + canvasY
                
                local colors = {}
                
                -- Check all colored circles
                for _, circle in ipairs(circlesToDraw) do
                    local dx = screenX - circle.x
                    local dy = screenY - circle.y
                    local distSq = dx * dx + dy * dy
                    if distSq <= circle.radius * circle.radius then
                        table.insert(colors, circle.color)
                    end
                end
                
                -- Check white circles
                local whiteCount = 0
                for _, circle in ipairs(whiteCircles) do
                    local dx = screenX - circle.x
                    local dy = screenY - circle.y
                    local distSq = dx * dx + dy * dy
                    if distSq <= circle.radius * circle.radius then
                        whiteCount = whiteCount + 1
                    end
                end
                
                    if #colors > 0 then
                        -- Mix colors using RYB color space
                        local mixedColor = mixRybColors(colors)
                        local r, g, b = mixedColor[1], mixedColor[2], mixedColor[3]
                        
                        -- Apply white lightening
                        if whiteCount > 0 then
                            local lightenAmount = math.min(whiteCount * 0.15, 0.5)
                            r = math.min(1, r + lightenAmount)
                            g = math.min(1, g + lightenAmount)
                            b = math.min(1, b + lightenAmount)
                        end
                        
                        imageData:setPixel(x, y, r, g, b, 1)
                    elseif whiteCount > 0 then
                        -- White circles on transparent background create light gray
                        local lightenAmount = math.min(whiteCount * 0.1, 0.3)
                        imageData:setPixel(x, y, 1 - lightenAmount, 1 - lightenAmount, 1 - lightenAmount, 1)
                    end
                    -- If no colors and no white, pixel stays transparent
            end
        end
    end
    
    -- Create image from ImageData and draw to canvas
    local image = love.graphics.newImage(imageData)
    love.graphics.setCanvas(renderCanvas)
    love.graphics.clear(0, 0, 0, 0) -- Transparent background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, 0, 0)
    
    -- Draw outlines on top for definition
    love.graphics.setBlendMode("alpha")
    for i, circle in ipairs(circlesToDraw) do
        local relX = circle.x - canvasX
        local relY = circle.y - canvasY
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", relX, relY, circle.radius)
        -- Draw text label
        drawCircleText(circle, -canvasX, -canvasY)
    end
    
    for i, circle in ipairs(whiteCircles) do
        local relX = circle.x - canvasX
        local relY = circle.y - canvasY
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", relX, relY, circle.radius)
        -- Draw text label
        drawCircleText(circle, -canvasX, -canvasY)
    end
    
    love.graphics.setCanvas()
    
    -- Draw the canvas onto the screen
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha")
    love.graphics.draw(renderCanvas, canvasX, canvasY)
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        -- Check if clicking on scrollbar
        local width, height = love.graphics.getDimensions()
        local sidebarContentTop = 80
        local sidebarContentHeight = height - sidebarContentTop
        
        -- Calculate total content height
        local totalContentHeight = 0
        if #sourceCircles > 0 then
            local lastCircle = sourceCircles[#sourceCircles]
            local circleSpacing = SOURCE_CIRCLE_RADIUS * 2 + 10
            totalContentHeight = lastCircle.y + SOURCE_CIRCLE_RADIUS + 20 - 100
        end
        
        if totalContentHeight > sidebarContentHeight and x >= scrollbar.x and x <= scrollbar.x + scrollbar.width then
            if y >= sidebarContentTop and y <= sidebarContentTop + sidebarContentHeight then
                -- Calculate scrollbar thumb position
                local maxScroll = math.min(0, sidebarContentHeight - totalContentHeight)
                local scrollbarTrackHeight = sidebarContentHeight
                local scrollbarThumbHeight = math.max(20, (sidebarContentHeight / totalContentHeight) * scrollbarTrackHeight)
                local scrollRatio = -sidebarScrollY / maxScroll
                local scrollbarThumbY = sidebarContentTop + (scrollbarTrackHeight - scrollbarThumbHeight) * scrollRatio
                
                -- Check if clicking on thumb or track
                if y >= scrollbarThumbY and y <= scrollbarThumbY + scrollbarThumbHeight then
                    -- Start dragging thumb
                    scrollbar.dragging = true
                    scrollbar.dragStartY = y
                    scrollbar.dragStartScrollY = sidebarScrollY
                else
                    -- Click on track - jump to that position
                    local clickRatio = (y - sidebarContentTop) / scrollbarTrackHeight
                    local maxScroll = math.min(0, sidebarContentHeight - totalContentHeight)
                    sidebarScrollY = -clickRatio * maxScroll
                    sidebarScrollY = math.max(maxScroll, math.min(0, sidebarScrollY))
                end
                return
            end
        end
        
        -- Check if clicking on popup X button
        if popup.visible then
            local buttonSize = 25
            local buttonX = popup.x + popup.width - buttonSize - 10
            local buttonY = popup.y + 10
            if x >= buttonX and x <= buttonX + buttonSize and
               y >= buttonY and y <= buttonY + buttonSize then
                -- Show next color in queue, or hide popup if queue is empty
                showNextColorInQueue()
                return
            end
        end
        
        -- Check if clicking on dropdown
        if x >= dropdown.x and x <= dropdown.x + dropdown.width then
            -- Check if clicking on main button
            if y >= dropdown.y and y <= dropdown.y + dropdown.itemHeight then
                dropdown.isOpen = not dropdown.isOpen
                return
            end
            
            -- Check if clicking on dropdown menu items
            if dropdown.isOpen then
                local menuY = dropdown.y + dropdown.itemHeight
                local menuHeight = #dropdown.options * dropdown.itemHeight
                if y >= menuY and y <= menuY + menuHeight then
                    local itemIndex = math.floor((y - menuY) / dropdown.itemHeight) + 1
                    if itemIndex >= 1 and itemIndex <= #dropdown.options then
                        local selectedOption = dropdown.options[itemIndex]
                        if selectedOption.state ~= gameState then
                            switchGameState(selectedOption.state)
                        end
                        dropdown.isOpen = false
                        return
                    end
                end
            end
        end
        
        -- Close dropdown if clicking outside
        if dropdown.isOpen then
            dropdown.isOpen = false
        end
        
        -- Check if clicking on clear button
        if x >= clearButton.x and x <= clearButton.x + clearButton.width and
           y >= clearButton.y and y <= clearButton.y + clearButton.height then
            canvasCircles = {}
            return
        end
        
        -- Check if clicking on a source circle (account for scroll)
        for i, circle in ipairs(sourceCircles) do
            -- Check with scroll offset applied
            local checkY = circle.y + sidebarScrollY
            if pointInCircle(x, y, {x = circle.x, y = checkY, radius = circle.radius}) then
                -- Create a new circle to drag
                dragging = {
                    x = x,
                    y = y,
                    radius = CIRCLE_RADIUS,
                    color = {circle.color[1], circle.color[2], circle.color[3]},
                    name = circle.name,
                    isBlack = circle.isBlack, -- Preserve black flag
                    isWhite = circle.isWhite -- Preserve white flag
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
    if button == 1 then
        -- Stop scrollbar dragging
        if scrollbar.dragging then
            scrollbar.dragging = false
        end
        
        -- Handle circle dragging
        if dragging then
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
                
                -- Detect new colors after placing/moving circle
                detectNewColors()
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
end

-- Get color name from RGB values using color dictionary
function getColorName(r, g, b)
    -- Round to 3 decimals for lookup
    local key = string.format("%.3f_%.3f_%.3f", r, g, b)
    local name = colorNames[key]
    
    if name then
        return name
    end
    
    -- If no exact match, find closest color
    local minDist = math.huge
    local closestName = nil
    
    for lookupKey, lookupName in pairs(colorNames) do
        -- Parse the key
        local parts = {}
        for part in lookupKey:gmatch("[^_]+") do
            table.insert(parts, tonumber(part))
        end
        
        if #parts == 3 then
            local dist = math.sqrt((r - parts[1])^2 + (g - parts[2])^2 + (b - parts[3])^2)
            if dist < minDist then
                minDist = dist
                closestName = lookupName
            end
        end
    end
    
    return closestName or "Unknown Color"
end

-- Check if a color is already unlocked or in sidebar
function isColorUnlocked(r, g, b)
    local key = string.format("%.3f_%.3f_%.3f", r, g, b)
    local unlockedColors
    if gameState == "additive" then
        unlockedColors = unlockedColorsAdditive
    elseif gameState == "subtractive" then
        unlockedColors = unlockedColorsSubtractive
    else -- paint
        unlockedColors = unlockedColorsPaint
    end
    
    if unlockedColors[key] then
        return true
    end
    
    -- Also check if color already exists in sidebar
    for _, circle in ipairs(sourceCircles) do
        local dr = math.abs(circle.color[1] - r)
        local dg = math.abs(circle.color[2] - g)
        local db = math.abs(circle.color[3] - b)
        if dr < COLOR_TOLERANCE and dg < COLOR_TOLERANCE and db < COLOR_TOLERANCE then
            return true
        end
    end
    
    return false
end

-- Mark a color as unlocked
function markColorUnlocked(r, g, b)
    local key = string.format("%.3f_%.3f_%.3f", r, g, b)
    if gameState == "additive" then
        unlockedColorsAdditive[key] = true
    elseif gameState == "subtractive" then
        unlockedColorsSubtractive[key] = true
    else -- paint
        unlockedColorsPaint[key] = true
    end
end

-- Show popup for unlocked color
function showColorUnlockedPopup(color, name, involvedCircles)
    -- If popup is already visible, queue this color
    if popup.visible then
        table.insert(colorUnlockQueue, {color = color, name = name, circles = involvedCircles})
    else
        popup.visible = true
        popup.color = color
        popup.colorName = name
        -- Store circles to clear when this popup is closed
        if involvedCircles then
            circlesToClear = involvedCircles
        end
    end
end

-- Show next color in queue
function showNextColorInQueue()
    if #colorUnlockQueue > 0 then
        local nextColor = table.remove(colorUnlockQueue, 1)
        popup.visible = true
        popup.color = nextColor.color
        popup.colorName = nextColor.name
        -- Update circles to clear with this color's circles
        if nextColor.circles then
            circlesToClear = nextColor.circles
        end
    else
        popup.visible = false
        -- All notifications are closed, clear the circles that created the colors
        if #circlesToClear > 0 then
            -- Remove circles from canvasCircles
            for _, circleToRemove in ipairs(circlesToClear) do
                for i = #canvasCircles, 1, -1 do
                    if canvasCircles[i] == circleToRemove then
                        table.remove(canvasCircles, i)
                        break
                    end
                end
            end
            circlesToClear = {} -- Clear the list
        end
    end
end

-- Detect new colors from overlapping circles
function detectNewColors()
    if not renderCanvas then
        return
    end
    
    -- Ensure canvas is rendered with current state
    -- We need to render it now to get the latest blended colors
    local width, height = love.graphics.getDimensions()
    local canvasX = SIDEBAR_WIDTH
    local canvasY = 0
    local canvasWidth = width - SIDEBAR_WIDTH
    local canvasHeight = height
    
    -- Update canvas size if needed
    if renderCanvas:getWidth() ~= canvasWidth or renderCanvas:getHeight() ~= canvasHeight then
        renderCanvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
    end
    
    -- Temporarily render canvas to get current state
    local circlesToDraw = {}
    local blackCircles = {}
    local whiteCircles = {}
    for i, circle in ipairs(canvasCircles) do
        if isCircleBlack(circle) then
            table.insert(blackCircles, circle)
        elseif isCircleWhite(circle) then
            table.insert(whiteCircles, circle)
        else
            table.insert(circlesToDraw, circle)
        end
    end
    
    love.graphics.setCanvas(renderCanvas)
    love.graphics.clear(0, 0, 0, 1) -- Clear to black for additive blending (same as rendering)
    
    -- Use appropriate blending based on game state
    if gameState == "additive" then
        if #circlesToDraw > 0 then
            love.graphics.setBlendMode("add")
            for i, circle in ipairs(circlesToDraw) do
                local relX = circle.x - canvasX
                local relY = circle.y - canvasY
                love.graphics.setColor(circle.color[1], circle.color[2], circle.color[3], 1)
                love.graphics.circle("fill", relX, relY, circle.radius)
            end
        end
        
        if #blackCircles > 0 then
            love.graphics.setBlendMode("multiply", "premultiplied")
            for i, circle in ipairs(blackCircles) do
                local relX = circle.x - canvasX
                local relY = circle.y - canvasY
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
                love.graphics.circle("fill", relX, relY, circle.radius)
            end
        end
    elseif gameState == "paint" then
        -- For paint mode, use the same RYB mixing approach as drawCanvasCirclesPaint
        -- Create ImageData to calculate pixel-by-pixel RYB mixing
        local imageData = love.image.newImageData(canvasWidth, canvasHeight)
        
        -- Initialize to transparent
        imageData:mapPixel(function(x, y, r, g, b, a)
            return 0, 0, 0, 0 -- Transparent background
        end)
        
        if #circlesToDraw > 0 or #whiteCircles > 0 then
            -- Calculate bounding box of all circles to limit processing area
            local minX, maxX = math.huge, -math.huge
            local minY, maxY = math.huge, -math.huge
            
            for _, circle in ipairs(circlesToDraw) do
                local relX = circle.x - canvasX
                local relY = circle.y - canvasY
                minX = math.min(minX, relX - circle.radius)
                maxX = math.max(maxX, relX + circle.radius)
                minY = math.min(minY, relY - circle.radius)
                maxY = math.max(maxY, relY + circle.radius)
            end
            
            for _, circle in ipairs(whiteCircles) do
                local relX = circle.x - canvasX
                local relY = circle.y - canvasY
                minX = math.min(minX, relX - circle.radius)
                maxX = math.max(maxX, relX + circle.radius)
                minY = math.min(minY, relY - circle.radius)
                maxY = math.max(maxY, relY + circle.radius)
            end
            
            -- Clamp to canvas bounds
            minX = math.max(0, math.floor(minX))
            maxX = math.min(canvasWidth - 1, math.ceil(maxX))
            minY = math.max(0, math.floor(minY))
            maxY = math.min(canvasHeight - 1, math.ceil(maxY))
            
            -- Process pixels within the bounding box
            for y = minY, maxY do
                for x = minX, maxX do
                    local screenX = x + canvasX
                    local screenY = y + canvasY
                    
                    local colors = {}
                    
                    -- Check all colored circles
                    for _, circle in ipairs(circlesToDraw) do
                        local dx = screenX - circle.x
                        local dy = screenY - circle.y
                        local distSq = dx * dx + dy * dy
                        if distSq <= circle.radius * circle.radius then
                            table.insert(colors, circle.color)
                        end
                    end
                    
                    -- Check white circles
                    local whiteCount = 0
                    for _, circle in ipairs(whiteCircles) do
                        local dx = screenX - circle.x
                        local dy = screenY - circle.y
                        local distSq = dx * dx + dy * dy
                        if distSq <= circle.radius * circle.radius then
                            whiteCount = whiteCount + 1
                        end
                    end
                    
                    if #colors > 0 then
                        -- Mix colors using RYB color space
                        local mixedColor = mixRybColors(colors)
                        local r, g, b = mixedColor[1], mixedColor[2], mixedColor[3]
                        
                        -- Apply white lightening
                        if whiteCount > 0 then
                            local lightenAmount = math.min(whiteCount * 0.15, 0.5)
                            r = math.min(1, r + lightenAmount)
                            g = math.min(1, g + lightenAmount)
                            b = math.min(1, b + lightenAmount)
                        end
                        
                        imageData:setPixel(x, y, r, g, b, 1)
                    elseif whiteCount > 0 then
                        -- White circles on transparent background create light gray
                        local lightenAmount = math.min(whiteCount * 0.1, 0.3)
                        imageData:setPixel(x, y, 1 - lightenAmount, 1 - lightenAmount, 1 - lightenAmount, 1)
                    end
                    -- If no colors and no white, pixel stays transparent
                end
            end
        end
        
        -- Draw ImageData to renderCanvas
        local image = love.graphics.newImage(imageData)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setBlendMode("alpha")
        love.graphics.draw(image, 0, 0)
    else -- subtractive
        -- For subtractive, start with white base for multiply to work
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
        
        if #circlesToDraw > 0 then
            love.graphics.setBlendMode("multiply", "premultiplied")
            for i, circle in ipairs(circlesToDraw) do
                local relX = circle.x - canvasX
                local relY = circle.y - canvasY
                love.graphics.setColor(circle.color[1], circle.color[2], circle.color[3], 1)
                love.graphics.circle("fill", relX, relY, circle.radius)
            end
        end
        
        if #whiteCircles > 0 then
            love.graphics.setBlendMode("add")
            for i, circle in ipairs(whiteCircles) do
                local relX = circle.x - canvasX
                local relY = circle.y - canvasY
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
                love.graphics.circle("fill", relX, relY, circle.radius)
            end
        end
    end
    
    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
    
    -- Sample colors from overlap regions
    local samplePoints = {}
    
    -- Sample points where circles overlap
    -- Include overlaps between colored circles, and between black circles and colored circles
    for i, circle1 in ipairs(canvasCircles) do
        for j, circle2 in ipairs(canvasCircles) do
            if i < j then
                -- Skip if both are black (black+black doesn't create new colors)
                local bothBlack = isCircleBlack(circle1) and isCircleBlack(circle2)
                -- Skip if both are white (for subtractive mode)
                local bothWhite = isCircleWhite(circle1) and isCircleWhite(circle2)
                
                if not bothBlack and not bothWhite then
                    -- Check if circles overlap
                    local dx = circle2.x - circle1.x
                    local dy = circle2.y - circle1.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < (circle1.radius + circle2.radius) and distance > 0 then
                        -- Calculate overlap intersection center
                        local r1 = circle1.radius
                        local r2 = circle2.radius
                        local d = distance
                        local a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
                        local h = math.sqrt(r1 * r1 - a * a)
                        
                        -- Center point of intersection
                        local px = circle1.x + a * (dx / d)
                        local py = circle1.y + a * (dy / d)
                        
                        -- Sample at intersection center and a few points around it
                        for offsetX = -h/2, h/2, h/3 do
                            for offsetY = -h/2, h/2, h/3 do
                                local sampleX = px + offsetX
                                local sampleY = py + offsetY
                                
                                if sampleX >= canvasX and sampleX <= canvasX + canvasWidth and
                                   sampleY >= canvasY and sampleY <= canvasY + canvasHeight then
                                    table.insert(samplePoints, {x = sampleX, y = sampleY})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sample three-way overlaps
    -- Include overlaps that involve black circles (but not all three black)
    for i, circle1 in ipairs(canvasCircles) do
        for j, circle2 in ipairs(canvasCircles) do
            for k, circle3 in ipairs(canvasCircles) do
                if i < j and j < k then
                    -- Skip if all three are black (black+black+black doesn't create new colors)
                    local allBlack = isCircleBlack(circle1) and isCircleBlack(circle2) and isCircleBlack(circle3)
                    -- Skip if all three are white (for subtractive mode)
                    local allWhite = isCircleWhite(circle1) and isCircleWhite(circle2) and isCircleWhite(circle3)
                    
                    if not allBlack and not allWhite then
                        -- Check if all three overlap
                        local dx12 = circle2.x - circle1.x
                        local dy12 = circle2.y - circle1.y
                        local dist12 = math.sqrt(dx12 * dx12 + dy12 * dy12)
                        
                        local dx13 = circle3.x - circle1.x
                        local dy13 = circle3.y - circle1.y
                        local dist13 = math.sqrt(dx13 * dx13 + dy13 * dy13)
                        
                        local dx23 = circle3.x - circle2.x
                        local dy23 = circle3.y - circle2.y
                        local dist23 = math.sqrt(dx23 * dx23 + dy23 * dy23)
                        
                        if dist12 < (circle1.radius + circle2.radius) and
                           dist13 < (circle1.radius + circle3.radius) and
                           dist23 < (circle2.radius + circle3.radius) then
                            -- Sample at center of three-way overlap and nearby points
                            local overlapX = (circle1.x + circle2.x + circle3.x) / 3
                            local overlapY = (circle1.y + circle2.y + circle3.y) / 3
                            local minRadius = math.min(circle1.radius, circle2.radius, circle3.radius)
                            
                            -- Sample multiple points in the overlap region
                            for offsetX = -minRadius/3, minRadius/3, minRadius/3 do
                                for offsetY = -minRadius/3, minRadius/3, minRadius/3 do
                                    local sampleX = overlapX + offsetX
                                    local sampleY = overlapY + offsetY
                                    
                                    if sampleX >= canvasX and sampleX <= canvasX + canvasWidth and
                                       sampleY >= canvasY and sampleY <= canvasY + canvasHeight then
                                        table.insert(samplePoints, {x = sampleX, y = sampleY})
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sample colors from render canvas
    local imageData = renderCanvas:newImageData()
    local foundNewColor = false
    
    for _, point in ipairs(samplePoints) do
        local canvasRelX = point.x - canvasX
        local canvasRelY = point.y - canvasY
        
        if canvasRelX >= 0 and canvasRelX < canvasWidth and
           canvasRelY >= 0 and canvasRelY < canvasHeight then
            local r, g, b, a = imageData:getPixel(math.floor(canvasRelX), math.floor(canvasRelY))
            
            -- Check if it's a valid color
            -- Background is now separate, so we only check for actual color content
            -- Valid colors have some color value and opacity
            local isValidColor = (r > 0.01 or g > 0.01 or b > 0.01) and a > 0.1
            
            -- For paint mode, also exclude colors that are too close to white (background color)
            if gameState == "paint" then
                local isWhite = (r > 0.95 and g > 0.95 and b > 0.95)
                isValidColor = isValidColor and not isWhite
            end
            
            if isValidColor then
                -- Check if this color is already unlocked
                if not isColorUnlocked(r, g, b) then
                    -- Mark as unlocked
                    markColorUnlocked(r, g, b)
                    
                    -- Get color name
                    local colorName = getColorName(r, g, b)
                    
                    -- Track all circles currently on canvas (these created the new color)
                    local involvedCircles = {}
                    for _, circle in ipairs(canvasCircles) do
                        table.insert(involvedCircles, circle)
                    end
                    
                    -- Queue popup (will show if no popup is visible, or queue it)
                    showColorUnlockedPopup({r, g, b}, colorName, involvedCircles)
                    
                    -- Auto-add to sidebar
                    local index = #sourceCircles + 1
                    local col = (index - 1) % COLUMNS
                    local row = math.floor((index - 1) / COLUMNS)
                    local circleSpacing = SOURCE_CIRCLE_RADIUS * 2 + 10
                    local startX = SIDEBAR_WIDTH / (COLUMNS + 1)
                    local startY = 100
                    
                    local isBlack = (r == 0 and g == 0 and b == 0)
                    local isWhite = (r == 1 and g == 1 and b == 1)
                    
                    table.insert(sourceCircles, {
                        x = startX * (col + 1),
                        y = startY + row * circleSpacing,
                        radius = SOURCE_CIRCLE_RADIUS,
                        color = {r, g, b},
                        name = colorName,
                        isSource = true,
                        isBlack = isBlack,
                        isWhite = isWhite
                    })
                    
                    foundNewColor = true
                    -- Don't break - continue to find all new colors and queue them
                end
            end
        end
    end
end

function pointInCircle(px, py, circle)
    local dx = px - circle.x
    local dy = py - circle.y
    return (dx * dx + dy * dy) <= (circle.radius * circle.radius)
end

-- Check if a circle is black (for darkening effect)
function isCircleBlack(circle)
    if circle.isBlack then
        return true
    end
    -- Also check color values as fallback
    if circle.color and circle.color[1] == 0 and circle.color[2] == 0 and circle.color[3] == 0 then
        return true
    end
    return false
end

-- Check if a circle is white (for subtractive mode)
function isCircleWhite(circle)
    if circle.isWhite then
        return true
    end
    -- Also check color values as fallback
    if circle.color and circle.color[1] == 1 and circle.color[2] == 1 and circle.color[3] == 1 then
        return true
    end
    return false
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "c" then
        -- Clear canvas
        canvasCircles = {}
    end
end

function love.wheelmoved(x, y)
    -- Handle mouse wheel scrolling in sidebar
    local mx, my = love.mouse.getPosition()
    if mx >= 0 and mx <= SIDEBAR_WIDTH then
        local width, height = love.graphics.getDimensions()
        local sidebarContentTop = 80
        local sidebarContentHeight = height - sidebarContentTop
        
        -- Calculate total content height
        local totalContentHeight = 0
        if #sourceCircles > 0 then
            local lastCircle = sourceCircles[#sourceCircles]
            local circleSpacing = SOURCE_CIRCLE_RADIUS * 2 + 10
            totalContentHeight = lastCircle.y + SOURCE_CIRCLE_RADIUS + 20 - 100
        end
        
        -- Only scroll if content exceeds visible area
        if totalContentHeight > sidebarContentHeight then
            local maxScroll = math.min(0, sidebarContentHeight - totalContentHeight)
            sidebarScrollY = sidebarScrollY + y * SIDEBAR_SCROLL_SPEED
            sidebarScrollY = math.max(maxScroll, math.min(0, sidebarScrollY))
        end
    end
end

