-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_CommunityProto.lua
-- ============================================================================
-- COMMUNITY: WHAT BOTH SIDES AGREE ON (ZeDUI/MP_ADMIN_SCOPE.md, Phase 5). The module, the two capabilities, the
-- questions kept to one switch, every limit, the checks on typed words, and what a player is asked. Pure Lua, ASCII,
-- nothing client-only at load: this file also runs on a dedicated server.
-- ============================================================================

require "ZeD/ZeD_TicketProto"

ZeD = ZeD or {}
ZeD.Cm = ZeD.Cm or {}
local Cm = ZeD.Cm

Cm.MOD = "ZeDM"

-- THE DIRECTOR'S QUESTIONS, answered the careful way, each kept to one switch (MP_SERVER_PART_DESIGN.md, the last section)
-- Who writes the message of the day, the rules, the appeal line and the two ticks. The game has no capability for this: this
-- is the one that changes the server's options, the welcome message among them. Moderators do not hold it.
Cm.CAP_RULES = "ChangeAndReloadServerOptions"
-- Who posts, pins and deletes news. The capability that sends a server message; moderators hold it, as the drawing's
-- post by Rosa has it.
Cm.CAP_NEWS = "DisplayServerMessage"
-- A rule taken away with nothing added: nobody has anything new to agree to. false: players are not asked again for
-- that. true: they are, with nothing marked NEW.
Cm.ASK_ON_REMOVE = false
-- Deleting a news post asks first in the card's foot. The drawing deletes at once; Delete sits beside Pin, and a post is
-- public. false: as drawn.
Cm.DELETE_ASKS = true
-- How many chat lines go with a report, each side of the picked line.
Cm.REPORT_AROUND = 5

-- every limit in one place, so they can become server settings later
Cm.L = {
    MOTD_MAX = 600,
    RULE_MAX = 200,
    RULES_MAX = 30,
    APPEAL_MAX = 120,
    POST_MAX = 500,
    NEWS_MAX = 50,                  -- posts kept; past it the oldest that is not pinned goes
    AGREED_MAX = 5000,              -- who agreed; past it the oldest agreement goes, and that player is asked again
    SAVE_MS = 3000,
    POST_MS = 5000,
    PIN_MS = 500,
    AGREE_MS = 2000,
    GET_MS = 1000,
}

-- typed words, several lines, trimmed: nil if they are not words or are too long. Empty is allowed: the caller says.
function Cm.text(s, max)
    local c = ZeD.Tk.clean(s)
    if not c or #c > max then return nil end
    return c
end

-- one line: a rule, the appeal line
function Cm.line(s, max)
    local c = ZeD.Tk.clean(s)
    if not c then return nil end
    c = string.gsub(c, "\n", " ")
    if #c > max then return nil end
    return c
end

-- the rule numbers marked NEW for the player a view was built for, in order. A first agreement marks nothing
function Cm.newRules(view)
    local out = {}
    if not (view and view.rules and view.since) then return out end
    for i = 1, view.rules.n or 0 do
        local r = view.rules[i]
        if r and (r.rev or 0) > view.since then out[#out + 1] = i end
    end
    return out
end

return Cm
