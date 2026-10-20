-- ZeD-UI/42/media/lua/client/ZeD/Overrides/WriteNote.lua
-- ============================================================================
-- NOTEBOOK HOOK (HOOK_MAP row 24) — vanilla's Write / Read note on a notebook,
-- journal or diary is ISWriteSomething: a timed action whose start() builds an
-- ISUIWriteJournal window and runs until that window closes. For the length of
-- that one start(), ISUIWriteJournal.new hands back ZeD's reader on the
-- notebook's page instead (ZeD_Reader, notebook mode). Everything else is
-- vanilla's: the action, its light and pencil rules, the animation and sounds,
-- the modal's addToUIManager and controller focus, its stop and perform
-- closing the window. Vanilla's window is used only if the reader cannot open,
-- or while ZeD's safe mode is on.
-- ============================================================================

require "TimedActions/ISWriteSomething"
require "ISUI/ISUIWriteJournal"
require "ZeD/ZeD_Reader"
require "ZeD/SafeMode"

if not (ISWriteSomething and ISWriteSomething.start and ISUIWriteJournal) then return end

local _start = ISWriteSomething._zedOrigStart or ISWriteSomething.start
ISWriteSomething._zedOrigStart = _start

function ISWriteSomething:start()
    if ZeD.Safe.on() then return _start(self) end   -- safe mode: vanilla's journal window
    local action = self
    local origNew = ISUIWriteJournal.new
    ISUIWriteJournal.new = function(cls, x, y, w, h, target, onclick, character, notebook, defaultEntryText, title, lineNumber, editable, numberOfPages)
        local ok, win = pcall(ZeD.Reader.openNotebook, character, notebook, action, editable)
        if ok and win then return win end
        if not ok then print("[ZeD] notebook: " .. tostring(win)) end
        return origNew(cls, x, y, w, h, target, onclick, character, notebook, defaultEntryText, title, lineNumber, editable, numberOfPages)
    end
    local ok, err = pcall(_start, self)
    ISUIWriteJournal.new = origNew
    if not ok then error(err) end
end
