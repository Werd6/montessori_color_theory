-- LOVE2D Configuration File

function love.conf(t)
    t.title = "Montessori Color Theory"        -- The title of the window the game is in
    t.author = "Your Name"                      -- The author of the game
    t.version = "11.5"                          -- The LOVE version this game was made for
    
    t.window.width = 1000                       -- Window width
    t.window.height = 700                       -- Window height
    t.window.borderless = false                 -- Remove all border visuals from the window
    t.window.resizable = false                  -- Let the window be user-resizable
    t.window.minwidth = 1                       -- Minimum window width if resizable
    t.window.minheight = 1                      -- Minimum window height if resizable
    t.window.fullscreen = false                 -- Enable fullscreen
    t.window.fullscreentype = "desktop"         -- Standard fullscreen or desktop fullscreen
    t.window.vsync = 1                          -- Enable vertical sync
    t.window.msaa = 0                           -- Number of samples to use for multi-sampled antialiasing
    t.window.highdpi = false                    -- Enable high-dpi mode for the window on a Retina display
    t.window.x = nil                            -- The x-coordinate of the window's position in the specified display
    t.window.y = nil                            -- The y-coordinate of the window's position in the specified display
    
    t.modules.audio = true                      -- Enable the audio module
    t.modules.event = true                      -- Enable the event module
    t.modules.graphics = true                   -- Enable the graphics module
    t.modules.image = true                      -- Enable the image module
    t.modules.joystick = true                   -- Enable the joystick module
    t.modules.keyboard = true                   -- Enable the keyboard module
    t.modules.math = true                       -- Enable the math module
    t.modules.mouse = true                      -- Enable the mouse module
    t.modules.physics = true                    -- Enable the physics module
    t.modules.sound = true                      -- Enable the sound module
    t.modules.system = true                     -- Enable the system module
    t.modules.timer = true                      -- Enable the timer module
    t.modules.touch = true                      -- Enable the touch module
    t.modules.video = true                      -- Enable the video module
    t.modules.window = true                     -- Enable the window module
    t.modules.thread = true                     -- Enable the thread module
end

