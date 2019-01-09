data:extend(
  {
    {
      type = "font",
      name = "fatcontroller_small",
      from = "default",
      size = 13
    },
  })


data.raw["gui-style"].default["fatcontroller_thin_flow"] =
  {
    type = "vertical_flow_style",
    horizontal_spacing = 0,
    vertical_spacing = 0,
    max_on_row = 0,
    resize_row_to_width = true,
  }


data.raw["gui-style"].default["fatcontroller_thin_frame"] =
  {
    type = "frame_style",
    parent="frame",
    top_padding  = 4,
    bottom_padding = 2,
  }

data.raw["gui-style"].default["fatcontroller_main_flow_vertical"] =
  {
    type = "vertical_flow_style",
    top_padding  = 0,
    bottom_padding = 0,
    left_padding = 5,
    right_padding = 5,
    horizontal_spacing = 0,
    vertical_spacing = 0,
    max_on_row = 0,
    resize_row_to_width = true,
  }
data.raw["gui-style"].default["fatcontroller_main_flow_horizontal"] =
  {
    type = "horizontal_flow_style",
    top_padding  = 0,
    bottom_padding = 0,
    left_padding = 5,
    right_padding = 5,
    horizontal_spacing = 0,
    vertical_spacing = 0,
    max_on_row = 0,
    resize_row_to_width = true,
  }


data.raw["gui-style"].default["fatcontroller_top_flow"] =
  {
    type = "horizontal_flow_style",
    parent = "fatcontroller_main_flow_horizontal",
    top_padding  = 0,
    left_padding = 0
  }

data.raw["gui-style"].default["fatcontroller_button_flow_horizontal"] =
  {
    type = "horizontal_flow_style",
    parent="horizontal_flow",
    horizontal_spacing=1,
  }

data.raw["gui-style"].default["fatcontroller_traininfo_button_flow_horizontal"] =
  {
    type = "horizontal_flow_style",
    parent="fatcontroller_button_flow_horizontal",
    top_padding  = 4,
  }

data.raw["gui-style"].default["fatcontroller_button_style"] =
  {
    type = "button_style",
    parent = "button",
    top_padding = 1,
    right_padding = 5,
    bottom_padding = 1,
    left_padding = 5,
    left_click_sound =
    {
      {
        filename = "__core__/sound/gui-click.ogg",
        volume = 1
      }
    }
  }
data.raw["gui-style"].default["fatcontroller_sprite_button_style"] =
  {
    type = "button_style",
    parent = "fatcontroller_button_style",
    width=32,
    height=35
  }

data.raw["gui-style"].default["fatcontroller_main_button_style"] =
  {
    type = "button_style",
    parent = "fatcontroller_button_style",
    type = "button_style",
    parent = "button",
    width = 33,
    height = 33,
    top_padding = 6,
    right_padding = 5,
    bottom_padding = 0,
    left_padding = 0,
    default_graphical_set =
    {
      type = "monolith",
      monolith_image =
      {
        filename = "__TheFatController_0-16_Fix__/graphics/gui.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        x = 64
      }
    },
    hovered_graphical_set =
    {
      type = "monolith",
      monolith_image =
      {
        filename = "__TheFatController_0-16_Fix__/graphics/gui.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        x = 96
      }
    },
    clicked_graphical_set =
    {
      type = "monolith",
      monolith_image =
      {
        filename = "__TheFatController_0-16_Fix__/graphics/gui.png",
        width = 32,
        height = 32,
        x = 96
      }
    }
  }

data.raw["gui-style"].default["fatcontroller_player_button"] =
  {
    type = "button_style",
    parent = "fatcontroller_button_style",
    type = "button_style",
    parent = "button",
    width = 33,
    height = 33,
    top_padding = 6,
    right_padding = 5,
    bottom_padding = 0,
    left_padding = 0,
    default_graphical_set =
    {
      type = "monolith",
      monolith_image =
      {
        filename = "__TheFatController_0-16_Fix__/graphics/guiPlayer.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        x = 96
      }
    },
    hovered_graphical_set =
    {
      type = "monolith",
      monolith_image =
      {
        filename = "__TheFatController_0-16_Fix__/graphics/guiPlayer.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        x = 64
      }
    },
    clicked_graphical_set =
    {
      type = "monolith",
      monolith_image =
      {
        filename = "__TheFatController_0-16_Fix__/graphics/guiPlayer.png",
        width = 32,
        height = 32,
        x = 64
      }
    }
  }

data.raw["gui-style"].default["fatcontroller_disabled_button"] =
  {
    type = "button_style",
    parent = "fatcontroller_button_style",

    default_font_color={r=0.34, g=0.34, b=0.34},

    hovered_font_color={r=0.34, g=0.34, b=0.38},
    hovered_graphical_set =
    {
      type = "composition",
      filename = "__core__/graphics/gui.png",
      corner_size = {3, 3},
      position = {0, 0}
    },

    clicked_font_color={r=0.34, g=0.34, b=0.38},
    clicked_graphical_set =
    {
      type = "composition",
      filename = "__core__/graphics/gui.png",
      corner_size = {3, 3},
      position = {0, 0}
    },
  }


data.raw["gui-style"].default["fatcontroller_selected_button"] =
  {
    type = "button_style",
    parent = "fatcontroller_button_style",

    default_font_color={r=0, g=0, b=0},
    default_graphical_set =
    {
      type = "composition",
      filename = "__core__/graphics/gui.png",
      corner_size = {3, 3},
      position = {0, 8}
    },



    hovered_font_color={r=1, g=1, b=1},
    hovered_graphical_set =
    {
      type = "composition",
      filename = "__core__/graphics/gui.png",
      corner_size = {3, 3},
      position = {0, 16}
    },

    clicked_font_color={r=0, g=0, b=0},
    clicked_graphical_set =
    {
      type = "composition",
      filename = "__core__/graphics/gui.png",
      corner_size = {3, 3},
      position = {0, 0}
    },
  }

data.raw["gui-style"].default["fatcontroller_label_style"] =
  {
    type = "label_style",
    font = "default",
    font_color = {r=1, g=1, b=1},
    top_padding = 0,
    bottom_padding = 0,
  }

data.raw["gui-style"].default["fatcontroller_label_style_small"] =
  {
    type = "label_style",
    parent = "fatcontroller_label_style",
    font = "fatcontroller_small",
  }

data.raw["gui-style"].default["fatcontroller_textfield_small"] =
  {
    type = "textfield_style",
    left_padding = 3,
    right_padding = 2,
    minimal_width = 30,
  }

data.raw["gui-style"].default["fatcontroller_icon_style"] =
  {
    type = "checkbox_style",
    parent = "checkbox",
    width = 32,
    height = 32,
    bottom_padding = 10,
    default_background =
    {
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      width = 32,
      height = 32,
      x = 111
    },
    hovered_background =
    {
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      width = 32,
      height = 32,
      x = 111
    },
    clicked_background =
    {
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      width = 32,
      height = 32,
      x = 111
    },
    checked =
    {
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      width = 32,
      height = 32,
      x = 111
    }
  }
local alarms = {"noFuel", "noPath", "timeAtSignal", "timeToStation"}
for _, icon in pairs(alarms) do
  data:extend({
    {
      type="sprite",
      name="fat_" .. icon,
      filename = "__TheFatController_0-16_Fix__/graphics/icons/"..icon..".png",
      priority = "extra-high-no-scale",
      width = 32,
      height = 32,
    }})
end
