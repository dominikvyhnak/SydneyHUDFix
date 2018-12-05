local create_assets_original = AssetsItem.create_assets
local unlock_asset_by_id_original = AssetsItem.unlock_asset_by_id
local move_up_original = AssetsItem.move_up
local move_down_original = AssetsItem.move_down
local move_left_original = AssetsItem.move_left
local move_right_original = AssetsItem.move_right
local confirm_pressed_original = AssetsItem.confirm_pressed
local mouse_moved_original = AssetsItem.mouse_moved
local mouse_pressed_original = AssetsItem.mouse_pressed

function AssetsItem:create_assets(...)
    create_assets_original(self, ...)

    self._buy_all_btn = self._panel:text({
        name = "buy_all_btn",
        text = "",
        h = tweak_data.menu.pd2_medium_font_size * 0.95,
        font_size = tweak_data.menu.pd2_medium_font_size * 0.9,
        font = tweak_data.menu.pd2_medium_font,
        color = tweak_data.screen_colors.button_stage_3,
        align = "right",
        blend_mode = "add",
        visible = managers.assets:has_locked_assets(),
    })

    self:update_buy_all_btn()
end

function AssetsItem:unlock_asset_by_id(...)
    unlock_asset_by_id_original(self, ...)

    self:update_buy_all_btn()
end

function AssetsItem:move_up(...)
    if self._asset_selected and (self._asset_selected % 2 > 0) and managers.assets:has_buyable_assets() and self:can_afford_all_assets() then
        self._buy_all_highlighted = true
        self._last_selected_asset = self._asset_selected
        self:check_deselect_item()
        self:update_buy_all_btn(true)
        managers.menu_component:post_event("highlight")
    else
        move_up_original(self, ...)
    end
end

function AssetsItem:move_down(...)
    if self._buy_all_highlighted then
        self._buy_all_highlighted = nil
        self:select_asset(self._last_selected_asset)
        self:update_buy_all_btn(true)
        self._last_selected_asset = nil
    else
        move_down_original(self, ...)
    end
end

function AssetsItem:move_left(...)
    if not self._buy_all_highlighted then
        move_left_original(self, ...)
    end
end

function AssetsItem:move_right(...)
    if not self._buy_all_highlighted then
        move_right_original(self, ...)
    end
end

function AssetsItem:confirm_pressed(...)
    if self._buy_all_highlighted then
        if self:can_afford_all_assets() then
            managers.assets:unlock_all_buyable_assets()
            self:update_buy_all_btn()
            self:move_down()
        end
    else
        return confirm_pressed_original(self, ...)
    end
end

function AssetsItem:mouse_moved(x, y, ...)
    if alive(self._buy_all_btn) and managers.assets:has_buyable_assets() then
        if self._buy_all_btn:inside(x, y) then
            if not self._buy_all_highlighted then
                self._buy_all_highlighted = true
                self:update_buy_all_btn(true)
                self:check_deselect_item()
                if self:can_afford_all_assets() then
                    managers.menu_component:post_event("highlight")
                end
            end
            return true, "link"
        elseif self._buy_all_highlighted then
            self._buy_all_highlighted = nil
            self:update_buy_all_btn(true)
        end
    end

    return mouse_moved_original(self, x, y, ...)
end

function AssetsItem:mouse_pressed(button, x, y, ...)
    if alive(self._buy_all_btn) and self:can_afford_all_assets() and button == Idstring("0") and self._buy_all_btn:inside(x, y) then
        managers.assets:unlock_all_buyable_assets()
        self:update_buy_all_btn()
    end

    return mouse_pressed_original(self, button, x, y, ...)
end

function AssetsItem:update_buy_all_btn(colors_only)
    if alive(self._buy_all_btn) then
        local asset_costs = managers.assets:get_total_assets_costs()
        if managers.assets:has_buyable_assets() then
            if self:can_afford_all_assets() then
                self._buy_all_btn:set_color(self._buy_all_highlighted and tweak_data.screen_colors.button_stage_2 or tweak_data.screen_colors.button_stage_3)
            else
                self._buy_all_btn:set_color(tweak_data.screen_colors.pro_color)
            end
        else
            self._buy_all_btn:set_color(tweak_data.screen_color_grey)
        end
        if not colors_only then
            local text = string.format("%s (%s)", managers.localization:to_upper_text("buy_all_assets"), managers.experience:cash_string(asset_costs))
            self._buy_all_btn:set_text(text)
            local _, _, w, _ = self._buy_all_btn:text_rect()
            self._buy_all_btn:set_w(math.ceil(w))
            self._buy_all_btn:set_top(15)
            if managers.menu:is_pc_controller() then
                self._buy_all_btn:set_right(self._panel:w() - 5)
            else
                self._buy_all_btn:set_left(5)
            end
        end
    end
end

function AssetsItem:can_afford_all_assets()
    return (managers.assets:get_total_assets_costs() <= managers.money:total())
end