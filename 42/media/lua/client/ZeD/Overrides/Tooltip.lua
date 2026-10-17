-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Tooltip.lua
-- ============================================================================
-- TOOLTIP OVERRIDE
-- Replaces ISToolTip and ISToolTipInv rendering with ZeD design system
-- styling. All positioning logic is preserved exactly from vanilla.
-- Deferred to OnGameBoot so vanilla files are fully loaded first.
-- ============================================================================

require "ZeD/Tokens"

-- ============================================================================
-- Apply overrides AFTER all vanilla files are loaded
-- ============================================================================
local function applyTooltipOverrides()
    if not ISToolTip or not ISToolTipInv then return end

    -- Cache vanilla methods for fallback
    local _vanilla_prerender     = ISToolTip.prerender
    local _vanilla_render        = ISToolTip.render
    local _vanilla_new           = ISToolTip.new
    local _vanilla_inv_prerender = ISToolTipInv.prerender
    local _vanilla_inv_render    = ISToolTipInv.render
    local _vanilla_inv_new       = ISToolTipInv.new
    local _vanilla_doLayout      = ISToolTip.doLayout
    local _vanilla_getFont       = ISToolTip.GetFont
    local _vanilla_renderContents = ISToolTip.renderContents

    -- ========================================================================
    -- Layout in design units (S124). Mirrors vanilla doLayout with the ZeD role
    -- fonts (F2 title / description, F1 footnote) and T.px for every offset, so
    -- the frame fits the zoomed text at any root scale.
    -- ========================================================================
    function ISToolTip.GetFont()
        local T = ZeD.T
        if T and T.fontF2 then return T.fontF2 end
        return _vanilla_getFont()
    end

    function ISToolTip:doLayout()
        local T = ZeD.T
        if not T or not T.px then return _vanilla_doLayout(self) end
        local TMx = ZeD.TM
        local textX, textY, textWidth, textHeight = T.px(10), 0, 0, 0
        local textureX, textureY, textureWidth, textureHeight = T.px(8), T.px(5), 0, 0
        if self.texture then
            textureWidth  = T.px(self.texture:getWidth())
            textureHeight = T.px(self.texture:getHeight()) + T.px(5)
            textX = textureX + textureWidth + T.px(10)
        end
        local nameWidth, nameHeight = 0, 0
        if self.name then
            nameWidth  = TMx:MeasureStringX(T.fontF2, self.name) + T.px(self.nameMarginX or 50)
            nameHeight = TMx:getFontHeight(T.fontF2)
            textureY = T.px(35)
            textY    = T.px(25)
        end
        local defaultW = T.px(self.defaultMyWidth or 220)
        textWidth, textHeight = self:layoutContents(textX, textY, math.max(defaultW, nameWidth))
        local myWidth  = defaultW
        local myHeight = math.max(nameHeight, math.max(textureY + textureHeight, textY + textHeight))
        if myWidth < textX + textWidth then myWidth = textX + textWidth end
        if myWidth < nameWidth then myWidth = nameWidth end
        if self.footNote then
            local noteWidth = TMx:MeasureStringX(T.fontF1, self.footNote)
            if myWidth < noteWidth then myWidth = noteWidth end
            myHeight = myHeight + TMx:getFontHeight(T.fontF1) + T.px(4)
        end
        if self.name then
            myHeight = myHeight + math.max(0, TMx:getFontHeight(T.fontF2) - TMx:getFontHeight(T.fontF1)) + T.px(4)
        end
        self:setWidth(myWidth + T.px(20))
        self:setHeight(myHeight)
    end

    function ISToolTip:renderContents()
        local T = ZeD.T
        if not T or not T.px then return _vanilla_renderContents(self) end
        if self.description ~= "" then
            if self.texture then
                self.descriptionPanel:setX(self:getAbsoluteX() + T.px(8) + T.px(self.texture:getWidth()) + T.px(10))
            else
                self.descriptionPanel:setX(self:getAbsoluteX() + T.px(10))
            end
            local y = 0
            if self.name then y = ZeD.TM:getFontHeight(T.fontF2) end
            self.descriptionPanel:setY(self:getAbsoluteY() + y)
            self.descriptionPanel:prerender()
            self.descriptionPanel:render()
        end
    end

    -- ========================================================================
    -- ISToolTip:prerender()
    -- ========================================================================
    function ISToolTip:prerender()
        local T = ZeD.T
        if not T or not T.surf1 then
            return _vanilla_prerender(self)
        end

        if self.owner and not self.owner:isReallyVisible() then
            self:removeFromUIManager()
            self:setVisible(false)
            return
        end

        -- pcall doLayout because vanilla's replaceKeyNames can crash
        -- with string.find(nil) if tooltip content isn't fully set up yet
        local ok, err = pcall(self.doLayout, self)
        if not ok then return end

        local bg = T.surf1
        self:drawRect(0, 0, self.width, self.height, T.surf2.a, bg.r, bg.g, bg.b)
    end

    -- ========================================================================
    -- ISToolTip:render()
    -- ========================================================================
    function ISToolTip:render()
        local T = ZeD.T
        if not T or not T.base then
            return _vanilla_render(self)
        end


        -- Positioning (identical to vanilla; S124 scale: cursor / screen offsets stay vanilla px)
        local mx = getMouseX() + 32
        local my = getMouseY() + 10
        if not self.followMouse then
            mx = self:getX()
            my = self:getY()
        end
        if self.desiredX and self.desiredY then
            mx = self.desiredX
            my = self.desiredY
        end
        self:setX(mx)
        self:setY(my)

        if self.contextMenu and self.contextMenu.joyfocus then
            local playerNum = self.contextMenu.player
            self:setX(getPlayerScreenLeft(playerNum) + 60)
            self:setY(getPlayerScreenTop(playerNum) + 60)
        elseif self.contextMenu and self.contextMenu.currentOptionRect then
            if self.contextMenu.currentOptionRect.height > 32 then
                self:setY(my + self.contextMenu.currentOptionRect.height)
            end
            self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
        elseif self.owner and self.owner.isButton then
            local ownerRect = { x = self.owner:getAbsoluteX(), y = self.owner:getAbsoluteY(), width = self.owner.width, height = self.owner.height }
            self:adjustPositionToAvoidOverlap(ownerRect)
        elseif self.owner and self.owner.Type == "ISSkillProgressBar" then
            local ownerRect = { x = self.owner:getAbsoluteX(), y = self.owner:getAbsoluteY(), width = self.owner.width, height = self.owner.height }
            self:adjustPositionToAvoidOverlap(ownerRect)
        end

        -- Background + border with ZeD tokens
        local bg = T.base
        self:drawRect(0, 0, self.width, self.height, T.surf2.a, bg.r, bg.g, bg.b)
        local bc = T.borderS
        self:drawRectBorder(0, 0, self.width, self.height, bc.a, bc.r, bc.g, bc.b)

        -- Texture (design units, matches doLayout above)
        if self.texture then
            local textureY = self.name and T.px(35) or T.px(5)
            self:drawTextureScaledAspect(self.texture, T.px(8), textureY,
                T.px(self.texture:getWidth()), T.px(self.texture:getHeight()), 1, 1, 1, 1)
        end

        -- Title: accent color, body font
        if self.name then
            local ac = T.accent
            self:drawText(self.name, T.px(8), T.px(5), ac.r, ac.g, ac.b, ac.a, T.fontF2)
        end

        -- Description (ISRichTextPanel)
        self:renderContents()

        -- Footer
        if self.footNote then
            local fontHgt = ZeD.TM:getFontHeight(T.fontF1)
            local fc = T.textSec
            self:drawTextCentre(self.footNote, self:getWidth() / 2,
                self:getHeight() - fontHgt - T.px(4), fc.r, fc.g, fc.b, fc.a, T.fontF1)
        end
    end

    -- ========================================================================
    -- ISToolTipInv:prerender()
    -- ========================================================================
    function ISToolTipInv:prerender()
        local T = ZeD.T
        if not T or not T.surf1 then
            return _vanilla_inv_prerender(self)
        end
        if self.owner and not self.owner:isReallyVisible() then
            self:removeFromUIManager()
            self:setVisible(false)
            return
        end
    end

    -- ========================================================================
    -- ISToolTipInv:render()
    -- ========================================================================
    function ISToolTipInv:render()
        local T = ZeD.T
        if not T or not T.base then
            return _vanilla_inv_render(self)
        end

        -- Vanilla behavior: skip inventory tooltip rendering while a context menu
        -- is actively drawing (visibleCheck is set true during ISContextMenu:render).
        -- The entire positioning + drawing block is inside this guard; the matching
        -- `end` is at the bottom of the function, tagged "context menu guard".
        if not ISContextMenu.instance or not ISContextMenu.instance.visibleCheck then

        -- S124 scale: vanilla positioning of the Java-drawn item tooltip (DoTooltip is unscaled); offsets stay vanilla px
        local mx = getMouseX() + 24
        local my = getMouseY() + 24
        if not self.followMouse then
            mx = self:getX()
            my = self:getY()
            if self.anchorBottomLeft then
                mx = self.anchorBottomLeft.x
                my = self.anchorBottomLeft.y
            end
        end

        local PADX = 0
        self.tooltip:setX(mx + PADX)
        self.tooltip:setY(my)

        self.tooltip:setWidth(50)
        self.tooltip:setMeasureOnly(true)
        if self.item then self.item:DoTooltip(self.tooltip) end
        self.tooltip:setMeasureOnly(false)

        local myCore = getCore()
        local maxX = myCore:getScreenWidth()
        local maxY = myCore:getScreenHeight()
        local tw = self.tooltip:getWidth()
        local th = self.tooltip:getHeight()

        self.tooltip:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)))
        if not self.followMouse and self.anchorBottomLeft then
            self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)))
        else
            self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)))
        end

        if self.contextMenu and self.contextMenu.joyfocus then
            local playerNum = self.contextMenu.player
            self.tooltip:setX(getPlayerScreenLeft(playerNum) + 60)
            self.tooltip:setY(getPlayerScreenTop(playerNum) + 60)
        elseif self.contextMenu and self.contextMenu.currentOptionRect then
            if self.contextMenu.currentOptionRect.height > 32 then
                self:setY(my + self.contextMenu.currentOptionRect.height)
            end
            self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
        end

        self:setX(self.tooltip:getX() - PADX)
        self:setY(self.tooltip:getY())
        self:setWidth(tw + PADX)
        self:setHeight(th)

        if self.followMouse and (self.contextMenu == nil) then
            self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
        end

        -- Background + border with ZeD tokens
        local bg = T.base
        self:drawRect(0, 0, self.width, self.height, T.surf2.a, bg.r, bg.g, bg.b)
        local bc = T.borderS
        self:drawRectBorder(0, 0, self.width, self.height, bc.a, bc.r, bc.g, bc.b)

        if self.item then self.item:DoTooltip(self.tooltip) end

        end -- context menu guard
    end

    -- ========================================================================
    -- ISToolTip:new() hook
    -- ========================================================================
    function ISToolTip:new()
        local o = _vanilla_new(self)
        local T = ZeD.T
        if T and T.base and T.borderS then
            o.backgroundColor = { r = T.base.r, g = T.base.g, b = T.base.b, a = T.surf2.a }
            o.borderColor     = { r = T.borderS.r, g = T.borderS.g, b = T.borderS.b, a = T.borderS.a }
            if o.descriptionPanel then
                o.descriptionPanel.backgroundColor = { r = T.surf1.r, g = T.surf1.g, b = T.surf1.b, a = 0.4 }
                o.descriptionPanel.borderColor     = { r = T.borderS.r, g = T.borderS.g, b = T.borderS.b, a = 0.15 }
            end
        end
        return o
    end

    -- ========================================================================
    -- ISToolTipInv:new() hook
    -- ========================================================================
    function ISToolTipInv:new(item)
        local o = _vanilla_inv_new(self, item)
        local T = ZeD.T
        if T and T.base and T.borderS then
            o.backgroundColor = { r = T.base.r, g = T.base.g, b = T.base.b, a = T.surf2.a }
            o.borderColor     = { r = T.borderS.r, g = T.borderS.g, b = T.borderS.b, a = T.borderS.a }
        end
        return o
    end
end

-- Defer until all vanilla files are loaded
Events.OnGameBoot.Add(applyTooltipOverrides)
