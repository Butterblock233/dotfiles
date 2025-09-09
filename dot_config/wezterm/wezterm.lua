local wezterm = require("wezterm")

return {
	color_scheme = "OneHalfDark",
	font = wezterm.font_with_fallback({
		"JetBrainsMono NF",
		-- "JetBrains Mono",
		"Cascadia Code",
		"Microsoft YaHei UI",
	}),
	font_size = 16.0,

	-- window_background_opacity = 0.95,
	-- text_background_opacity = 0.95,

	enable_tab_bar = true,
	hide_tab_bar_if_only_one_tab = true,

	default_prog = { "nu" },

	keys = {
		{
			key = "w",
			mods = "CTRL|SHIFT",
			action = wezterm.action.CloseCurrentPane({ confirm = true }),
		},
		{
			key = "t",
			mods = "CTRL|SHIFT",
			action = wezterm.action.SpawnTab("CurrentPaneDomain"),
		},
	},

	window_padding = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	},
}

