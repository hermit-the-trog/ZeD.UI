-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_CommunityProto.lua
-- ============================================================================
-- COMMUNITY: WHAT BOTH SIDES AGREE ON, for the community board (the message of the day, the rules, the appeal line, the
-- news). The module name, the two capabilities, the choices kept to one switch each, every limit, the checks on typed
-- words, and which rules show as NEW to a player. Shared: this file loads on the client and on a dedicated server
-- alike, so nothing client-only at file scope. Pure Lua, pure ASCII.
-- ============================================================================

-- for ZeD.Tk.clean: the board's words go through the ticket protocol's scrubber
require "ZeD/ZeD_TicketProto"

-- Reload-safe: loading this file twice reuses the tables instead of wiping them
ZeD = ZeD or {}
ZeD.Cm = ZeD.Cm or {}
local Cm = ZeD.Cm

Cm.MOD = "ZeDM"             -- the module on every community command

-- DESIGN CHOICES that could go either way, answered the careful way, each kept to one switch
-- Who writes the message of the day, the rules, the appeal line and the two ticks (ask players to agree when they join;
-- ask again when a rule is added or changed). The game has no capability for this, so ZeD uses the one that changes
-- the server's options, the welcome message among them. Moderators do not hold it.
Cm.CAP_RULES = "ChangeAndReloadServerOptions"
-- Who posts, pins and deletes news. The capability that sends a server message; moderators hold it, so they can post
-- without holding the rules.
Cm.CAP_NEWS = "DisplayServerMessage"
-- A rule taken away with nothing added: nobody has anything new to agree to. false: players are not asked again for
-- that. true: they are, with nothing marked NEW.
Cm.ASK_ON_REMOVE = false
-- Deleting a news post asks first in the card's foot: Delete sits beside Pin, and a post is public, so a slip would
-- show to everyone. false: delete at once, no question.
Cm.DELETE_ASKS = true

-- every limit in one place, so they can become server settings later
Cm.L = {
    MOTD_MAX = 600,
    RULE_MAX = 200,
    RULES_MAX = 30,
    APPEAL_MAX = 120,
    POST_MAX = 500,
    NEWS_MAX = 50,                  -- posts kept; past it the oldest that is not pinned goes
    AGREED_MAX = 5000,              -- who agreed; past it the oldest agreement goes, and that player is asked again
    SAVE_MS = 3000,                 -- between two saves of the board's words, from one player
    POST_MS = 5000,                 -- between two news posts
    PIN_MS = 500,                   -- between two pins, and between two deletes
    AGREE_MS = 2000,                -- between two agreements
    GET_MS = 1000,                  -- between two asks for the board
    PUSH_MS = 5000,                 -- the board goes to everyone at most this often; whoever pressed gets it at once
    ASKED_MS = 300000,              -- asked and no answer for this long: one line in the log, and a Kick is owed
    ASKED_LOOK_MS = 5000,           -- how often the server looks
}

--- typed words of several lines (the message of the day, a news post), trimmed: nil if not given a string or longer
--- than max. Empty is allowed: the caller decides whether empty will do.
function Cm.text(s, max)
    local c = ZeD.Tk.clean(s)
    if not c or #c > max then return nil end
    return c
end

--- one line: a rule, the appeal line. Line breaks become spaces; nil if not given a string or longer than max
function Cm.line(s, max)
    local c = ZeD.Tk.clean(s)
    if not c then return nil end
    c = string.gsub(c, "\n", " ")
    if #c > max then return nil end
    return c
end

--- the rule numbers marked NEW for the player a view was built for, in order: rules added or changed after the
--- revision they last agreed at (view.since). A player who has never agreed gets an empty list: there is nothing to compare against
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
