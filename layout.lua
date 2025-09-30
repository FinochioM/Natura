local layout = {}

function layout.create()
    return {
        mode = "single",
        split_position = 0.5,
        active_side = "left"
    }
end

function layout.get_editor_bounds(ly, window_width, window_height)
    if ly.mode == "single" then
        return {
            left = { x = 0, y = 0, width = window_width, height = window_height, active = true }
        }
    else
        local split_x = math.floor(window_width * ly.split_position)
        return {
            left = {
                x = 0,
                y = 0,
                width = split_x - 1,
                height = window_height,
                active = ly.active_side == "left"
            },
            right = {
                x = split_x + 1,
                y = 0,
                width = window_width - split_x - 1,
                height = window_height,
                active = ly.active_side == "right"
            }
        }
    end
end

function layout.draw_divider(ly, window_width, window_height)
    if ly.mode == "double" then
        local split_x = math.floor(window_width * ly.split_position)
        local colors = require("colors")
        colors.set_color("text_dim")
        love.graphics.rectangle("fill", split_x, 0, 1, window_height)
    end
end

return layout