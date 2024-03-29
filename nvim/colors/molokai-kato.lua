--
-- Built with,
--
--        ,gggg,
--       d8" "8I                         ,dPYb,
--       88  ,dP                         IP'`Yb
--    8888888P"                          I8  8I
--       88                              I8  8'
--       88        gg      gg    ,g,     I8 dPgg,
--  ,aa,_88        I8      8I   ,8'8,    I8dP" "8I
-- dP" "88P        I8,    ,8I  ,8'  Yb   I8P    I8
-- Yb,_,d88b,,_   ,d8b,  ,d8b,,8'_   8) ,d8     I8,
--  "Y8P"  "Y888888P'"Y88P"`Y8P' "YY8P8P88P     `Y8
--

local lush = require('lush')
local hsl = lush.hsl
local hsluv = lush.hsluv

local normal_fg = hsl(0, 0, 100)
local normal_bg = hsl(0, 0, 0)
local constant = hsl(270, 100, 68)
local string = hsl(45, 100, 75)
local identifier = hsl(30, 100, 64)
local function_name = hsl(90, 100, 64)
local statement = hsl(340, 100, 80)
local type = hsl(190, 100, 68)
local special = hsl(190, 100, 68)
local comment = hsl(195, 5, 55)
local todo = hsl(0, 0, 100)
local directory = hsl(90, 100, 64)
local search = hsl(45, 100, 75)
local error = hsl(0, 100, 80)
local warning = hsl(45, 100, 75)
local line_number = hsl(195, 5, 55)
local cursor_line = hsl(0, 0, 11)
local cursor_column = hsl(0, 0, 11)
local visual = hsl(0, 0, 24)
local folded = hsl(195, 5, 27)
local fold_column = hsl(195, 5, 27)
local non_text = hsl(195, 5, 14)
local special_key = hsl(195, 5, 14)
local tab_line_fill = hsl(0, 0, 50)
local tab_line = hsl(0, 0, 50)
local tab_line_sel = hsl(0, 0, 38)
local line_nr = hsl(195, 5, 27)
local cursor_line_nr = hsl(30, 100, 64)
local sign_column = hsl(0, 0, 14)
local vert_split = hsl(0, 0, 50)
local color_column = hsl(0, 0, 14)
local pmenu = hsl(190, 100, 68)
local pmenu_sel = hsl(0, 0, 50)
local pmenu_sbar = hsl(0, 0, 3)
local pmenu_thumb = hsl(190, 100, 68)
local wild_menu = hsl(190, 100, 68)
local mode_msg = hsl(45, 100, 65)
local more_msg = hsl(45, 100, 65)
local status_line = hsl(0, 0, 85)
local status_line_nc = hsl(0, 0, 50)
local error_msg = hsl(340, 100, 80)
local warning_msg = hsl(45, 100, 75)
local question = hsl(190, 100, 68)
local title = hsl(30, 100, 64)
local diff_added = hsl(100, 100, 60)
local diff_deleted = hsl(340, 100, 80)
local diff_change = hsl(0, 0, 15)
local diff_text = hsl(190, 100, 68)
local spell_bad = hsl(340, 100, 80)
local spell_cap = hsl(45, 100, 75)
local spell_local = hsl(45, 100, 75)
local spell_rare = hsl(45, 100, 75)
local syntastic_error_sign = hsl(340, 100, 80)
local syntastic_warning_sign = hsl(45, 100, 75)
local diff_added_fg = hsl(100, 100, 60)  -- Corresponds to #A6E22E in Vimscript
local diff_added_bg = hsl(0, 0, 15)      -- Corresponds to #272822 in Vimscript

-- Diff Deleted
local diff_deleted_fg = hsl(340, 100, 80)  -- Corresponds to #F92672 in Vimscript
local diff_deleted_bg = hsl(0, 0, 15)      -- Corresponds to #272822 in Vimscript

-- Diff Change
local diff_change_fg = hsl(0, 0, 0)        -- No fg defined in Vimscript
local diff_change_bg = hsl(0, 0, 15)       -- Corresponds to #272822 in Vimscript

-- Diff Text
local diff_text_fg = hsl(190, 100, 68)     -- Corresponds to #66D9EF in Vimscript
local diff_text_bg = hsl(0, 0, 22)
local cursearch_fg = hsl(0, 0, 0)  -- Background color is used for fg in Vimscript
local cursearch_bg = hsl(47, 50, 53)  -- Corresponds to #C4BE89 in Vimscript
local conditional_fg = hsl(338, 95, 56)  -- Corresponds to #F92672 in Vimscript



-- LSP/Linters mistakenly show `undefined global` errors in the spec, they may
-- support an annotation like the following. Consult your server documentation.
---@diagnostic disable: undefined-global
local theme = lush(function(injected_functions)
    local sym = injected_functions.sym
    return {
        Normal { bg = normal_bg, fg = normal_fg, }, -- Normal text
        NormalNC { Normal },                  -- normal text in non-current windows
        ColorColumn { bg = color_column },         -- Columns set with 'colorcolumn'
        -- Conceal {},                           -- Placeholder characters substituted for concealed text (see 'conceallevel')
        -- Cursor {},                                -- Character under the cursor
        CurSearch { fg = cursearch_bg, bg = cursearch_fg, gui = "bold", }, -- Highlighting a search pattern under the cursor (see 'hlsearch')
        -- lCursor        { }, -- Character under the cursor when |language-mapping| is used (see 'guicursor')
        -- CursorIM       { }, -- Like Cursor, but used when in IME mode |CursorIM|
        CursorColumn { bg = cursor_column },                                     -- Screen-column at the cursor, when 'cursorcolumn' is set.
        CursorLine { bg = cursor_line },                                       -- Screen-line at the cursor, when 'cursorline' is set. Low-priority if foreground (ctermfg OR guifg) is not set.
        Directory { fg = directory },                                         -- Directory names (and other special names in listings)
        DiffAdd { bg = diff_added_bg, fg = diff_added_fg }, -- Diff mode: Added line |diff.txt|
        DiffChange { bg = diff_change_bg, fg = diff_change_fg },    -- Diff mode: Changed line |diff.txt|
        DiffDelete { bg = diff_deleted_bg, fg = diff_deleted_fg, },      -- Diff mode: Deleted line |diff.txt|
        DiffText { bg = diff_text_bg, fg = diff_text_fg },               -- Diff mode: Changed text within a changed line |diff.txt|
        -- EndOfBuffer    { }, -- Filler lines (~) after the end of the buffer. By default, this is highlighted like |hl-NonText|.
        -- TermCursor     { }, -- Cursor in a focused terminal
        -- TermCursorNC   { }, -- Cursor in an unfocused terminal
        -- ErrorMsg       { }, -- Error messages on the command line
        -- VertSplit      { }, -- Column separating vertically split windows
        Folded { bg = yellow4, fg = yellow },              -- Line used for closed folds
        -- FoldColumn     { }, -- 'foldcolumn'
        SignColumn {},                                     -- Column where |signs| are displayed
        IncSearch { CurSearch, },                          -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
        Substitute { CurSearch, },                         -- |:substitute| replacement text highlighting
        LineNr { fg = line_nr, },                          -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
        LineNrAbove { LineNr },                            -- Line number for when the 'relativenumber' option is set, above the cursor line
        LineNrBelow { LineNr },                            -- Line number for when the 'relativenumber' option is set, below the cursor line
        CursorLineNr { fg = cursor_line_nr, bg = CursorLine.bg, }, -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
        -- CursorLineFold { }, -- Like FoldColumn when 'cursorline' is set for the cursor line
        CursorLineSign { bg = CursorLine.bg },             -- Like SignColumn when 'cursorline' is set for the cursor line
        MatchParen { fg = nil, gui = "underline, bold" },       -- Character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
        Title { fg = title, gui = "bold", },              -- Titles for output from ":set all", ":autocmd" etc.
        -- ModeMsg        { }, -- 'showmode' message (e.g., "-- INSERT -- ")
        MsgArea { Normal, },                               -- Area for messages and cmdline
        -- MsgSeparator   { }, -- Separator for scrolled messages, `msgsep` flag of 'display'
        -- MoreMsg        { }, -- |more-prompt|
        NonText { fg = non_text },                             -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
        NormalFloat { Normal, bg = hsl(0, 0, 0), },                   -- Normal text in floating windows.
        FloatBorder { NormalFloat, },                         -- Border of floating windows.
        FloatTitle { Title },                                 -- Title of floating windows.
        Pmenu { bg = hsl(0, 0, 0) },                                  -- Popup menu: Normal item.
        PmenuSel { bg = yellow5, fg = white, gui = "bold", }, -- Popup menu: Selected item.
        -- PmenuKind {},                                      -- Popup menu: Normal item "kind"
        -- PmenuKindSel   { }, -- Popup menu: Selected item "kind"
        -- PmenuExtra     { }, -- Popup menu: Normal item "extra text"
        -- PmenuExtraSel  { }, -- Popup menu: Selected item "extra text"
        -- PmenuSbar      { }, -- Popup menu: Scrollbar.
        -- PmenuThumb     { }, -- Popup menu: Thumb of the scrollbar.
        -- Question       { }, -- |hit-enter| prompt and yes/no questions
        -- QuickFixLine   { }, -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
        Search { bg = orange3, fg = black },          -- Last search pattern highlighting (see 'hlsearch'). Also used for similar items that need to stand out.
        -- SpecialKey     { }, -- Unprintable characters: text displayed differently from what it really is. But not 'listchars' whitespace. |hl-Whitespace|
        SpellBad { fg = red2 },                       -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
        SpellCap { SpellBad },                        -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
        SpellLocal { SpellBad },                      -- Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
        SpellRare { SpellBad },                       -- Word that is recognized by the spellchecker as one that is hardly ever used. |spell| Combined with the highlighting used otherwise.
        StatusLine { bg = yellow4, fg = Normal.fg, }, -- Status line of current window
        StatusLineNC { NormalNC, fg = yellow5 },      -- Status lines of not-current windows. Note: If this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
        TabLine { StatusLine, fg = yellow5, },        -- Tab pages line, not active tab page label
        TabLineFill { bg = TabLine.bg },              -- Tab pages line, where there are no labels
        TabLineSel { Normal },                        -- Tab pages line, active tab page label
        Visual { bg = visual },                         -- Visual mode selection
        -- VisualNOS      { }, -- Visual mode selection when vim is "Not Owning the Selection".
        -- WarningMsg     { }, -- Warning messages
        -- Whitespace     { }, -- "nbsp", "space", "tab" and "trail" in 'listchars'
        Winseparator { Normal, fg = black, }, -- Separator between window splits. Inherts from |hl-VertSplit| by default, which it will replace eventually.
        -- WildMenu       { }, -- Current match in 'wildmenu' completion
        -- WinBar         { }, -- Window bar of current window
        -- WinBarNC       { }, -- Window bar of not-current windows

        -- Common vim syntax groups used for all kinds of code and markup.
        -- Commented-out groups should chain up to their preferred (*) group
        -- by default.
        --
        -- See :h group-name
        --
        -- Uncomment and edit if you want more specific syntax highlighting.

        Comment { fg = comment, }, -- Any comment

        Constant { fg = constant },  -- (*) Any constant
        String { fg = string },    --   A string constant: "this is a string"
        -- Character      { }, --   A character constant: 'c', '\n'
        -- Number { fg = purple },   --   A number constant: 234, 0xff
        -- Boolean        { }, --   A boolean constant: TRUE, false
        -- Float          { }, --   A floating point constant: 2.3e10

        Identifier { fg = identifier }, -- (*) Any variable name
        Function { fg = function_name },  --   Function name (also: methods for classes)

        Statement { fg = statement },    -- (*) Any statement
        Conditional { fg = conditional_fg },  --   if, then, else, endif, switch, etc.
        -- Repeat { fg = blue },         --   for, do, while, etc.
        -- Label { fg = blue },          --   case, default, etc.
        -- Operator { fg = blue },       --   "sizeof", "+", "*", etc.
        Keyword { fg = identifier }, --   any other keyword
        -- Exception { fg = blue },                --   try, catch, throw

        PreProc { fg = blue, gui = "italic", },  -- (*) Generic Preprocessor
        Include { PreProc },                     --   Preprocessor #include
        Define { PreProc },                      --   Preprocessor #define
        Macro { PreProc },                       --   Same as Define
        PreCondit { PreProc },                   --   Preprocessor #if, #else, #endif, etc.

        Type { fg = blue, gui = "italic", },     -- (*) int, long, char, etc.
        StorageClass { Type },                   --   static, register, volatile, etc.
        Structure { Type },                      --   struct, union, enum, etc.
        Typedef { fg = yellow2, gui = "NONE", }, --   A typedef

        Special { fg = white3 },                 -- (*) Any special symbol
        -- SpecialChar    { }, --   Special character in a constant
        Tag { fg = red2, },                      --   You can use CTRL-] on this
        -- Delimiter      { }, --   Character that needs attention
        -- SpecialComment { }, --   Special things inside a comment (e.g. '\n')
        -- Debug          { }, --   Debugging statements

        Underlined { gui = "underline" }, -- Text that stands out, HTML links
        -- Ignore         { }, -- Left blank, hidden |hl-Ignore| (NOTE: May be invisible here in template)
        -- Error          { }, -- Any erroneous construct
        -- Todo           { }, -- Anything that needs extra attention; mostly the keywords TODO FIXME and XXX

        -- These groups are for the native LSP client and diagnostic system. Some
        -- other LSP clients may use these groups, or use their own. Consult your
        -- LSP client's documentation.
        -- See :h lsp-highlight, some groups may not be listed, submit a PR fix to lush-template!
        --
        -- LspReferenceText            { } , -- Used for highlighting "text" references
        -- LspReferenceRead            { } , -- Used for highlighting "read" references
        -- LspReferenceWrite           { } , -- Used for highlighting "write" references
        -- LspCodeLens                 { } , -- Used to color the virtual text of the codelens. See |nvim_buf_set_extmark()|.
        -- LspCodeLensSeparator        { } , -- Used to color the seperator between two or more code lens.
        LspSignatureActiveParameter { Search, }, -- Used to highlight the active parameter in the signature help. See |vim.lsp.handlers.signature_help()|.

        --
        -- See :h diagnostic-highlights, some groups may not be listed, submit a PR fix to lush-template!
        --
        DiagnosticError { fg = red.li(10), bg = red.mix(Normal.bg, 90) },      -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
        DiagnosticWarn { fg = orange.li(10), bg = orange.mix(Normal.bg, 90) }, -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
        DiagnosticInfo { fg = blue.li(10), bg = blue.mix(Normal.bg, 90) },     -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
        DiagnosticHint { fg = blue.li(10), bg = blue.mix(Normal.bg, 90) },     -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
        DiagnosticOk { fg = yellow2.li(10), bg = yellow2.mix(Normal.bg, 90) }, -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
        -- DiagnosticVirtualTextError { } , -- Used for "Error" diagnostic virtual text.
        -- DiagnosticVirtualTextWarn  { } , -- Used for "Warn" diagnostic virtual text.
        -- DiagnosticVirtualTextInfo  { } , -- Used for "Info" diagnostic virtual text.
        -- DiagnosticVirtualTextHint  { } , -- Used for "Hint" diagnostic virtual text.
        -- DiagnosticVirtualTextOk    { } , -- Used for "Ok" diagnostic virtual text.
        -- DiagnosticUnderlineError   { } , -- Used to underline "Error" diagnostics.
        -- DiagnosticUnderlineWarn    { } , -- Used to underline "Warn" diagnostics.
        -- DiagnosticUnderlineInfo    { } , -- Used to underline "Info" diagnostics.
        -- DiagnosticUnderlineHint    { } , -- Used to underline "Hint" diagnostics.
        -- DiagnosticUnderlineOk      { } , -- Used to underline "Ok" diagnostics.
        -- DiagnosticFloatingError    { } , -- Used to color "Error" diagnostic messages in diagnostics float. See |vim.diagnostic.open_float()|
        -- DiagnosticFloatingWarn     { } , -- Used to color "Warn" diagnostic messages in diagnostics float.
        -- DiagnosticFloatingInfo     { } , -- Used to color "Info" diagnostic messages in diagnostics float.
        -- DiagnosticFloatingHint     { } , -- Used to color "Hint" diagnostic messages in diagnostics float.
        -- DiagnosticFloatingOk       { } , -- Used to color "Ok" diagnostic messages in diagnostics float.
        -- DiagnosticSignError        { } , -- Used for "Error" signs in sign column.
        -- DiagnosticSignWarn         { } , -- Used for "Warn" signs in sign column.
        -- DiagnosticSignInfo         { } , -- Used for "Info" signs in sign column.
        -- DiagnosticSignHint         { } , -- Used for "Hint" signs in sign column.
        -- DiagnosticSignOk           { } , -- Used for "Ok" signs in sign column.

        --
        -- Tree-Sitter syntax groups.
        --
        -- See :h treesitter-highlight-groups, some groups may not be listed,
        -- submit a PR fix to lush-template!
        --
        -- Tree-Sitter groups are defined with an "@" symbol, which must be
        -- specially handled to be valid lua code, we do this via the special
        -- sym function. The following are all valid ways to call the sym function,
        -- for more details see https://www.lua.org/pil/5.html
        --
        -- For more information see https://github.com/rktjmp/lush.nvim/issues/109

        -- sym("@text.literal")      { }, -- Comment
        -- sym("@text.reference")    { }, -- Identifier
        -- sym("@text.title")        { }, -- Title
        -- sym("@text.uri")          { }, -- Underlined
        -- sym("@text.underline")    { }, -- Underlined
        -- sym("@text.todo")         { }, -- Todo
        sym("@comment") { Comment }, -- Comment
        -- sym("@punctuation")       { }, -- Delimiter
        sym("@punctuation.delimiter.yaml") { fg = red2, },
        sym("@punctuation.special.yaml") { fg = red2 },
        sym("@constant") { Constant },            -- Constant
        sym("@constant.builtin") { fg = purple }, -- Special
        -- sym("@constant.macro")    { }, -- Define
        -- sym("@define")            { }, -- Define
        -- sym("@macro")             { }, -- Macro
        -- sym("@string")            { }, -- String
        -- sym("@string.escape")     { }, -- SpecialChar
        -- sym("@string.special")    { }, -- SpecialChar
        -- sym("@character")         { }, -- Character
        -- sym("@character.special") { }, -- SpecialChar
        -- sym("@number")            { }, -- Number
        -- sym("@boolean")           { }, -- Boolean
        -- sym("@float")             { }, -- Float
        sym("@function") { fg = yellow2 },                 -- Function
        sym("@function.call") { fg = blue },               -- Function
        sym("@function.builtin") { fg = blue },            -- Special
        -- sym("@function.macro")    { }, -- Macro
        sym("@parameter") { fg = orange, gui = "italic" }, -- Identifier
        sym("@method") { fg = yellow2 },                   -- Function
        sym("@method.call") { fg = blue },                 -- Function
        -- sym("@field")             { }, -- Identifier
        -- sym("@property")          { }, -- Identifier
        -- sym("@constructor")       { }, -- Special
        -- sym("@conditional")       { }, -- Conditional
        -- sym("@repeat")            { }, -- Repeat
        -- sym("@label")             { }, -- Label
        -- sym("@operator")          { }, -- Operator
        sym("@keyword") { Keyword },
        sym("@keyword.function") { fg = blue },
        sym("@keyword.return") { fg = red2 },
        sym("@keyword.sql") { fg = red2 },
        sym("@keyword.dockerfile") { gui = "bold" },
        -- sym("@exception")         { }, -- Exception
        -- sym("@variable")          { }, -- Identifier
        -- sym("@type")              { }, -- Type
        sym("@type.definition") { Typedef }, -- Typedef
        -- sym("@storageclass")      { }, -- StorageClass
        -- sym("@structure")         { }, -- Structure
        -- sym("@namespace")         { }, -- Identifier
        -- sym("@include")           { }, -- Include
        -- sym("@preproc")           { }, -- PreProc
        -- sym("@debug")             { }, -- Debug
        sym("@tag") { Tag },
        sym("@tag.delimiter") { Identifier },
        sym("@tag.attribute") { Identifier },
        sym("@lsp.type.enumMember") { Constant },                                   -- @lsp.type.enumMember xxx links to Constant
        sym("@lsp.type.enumNumber") { Constant },                                   -- @lsp.type.enumNumber xxx links to Constant
        sym("@lsp.type.decorator") { Function },                                    -- @lsp.type.decorator xxx links to Function
        sym("@lsp.type.function") { Function },                                     -- @lsp.type.function xxx links to Function
        sym("@lsp.type.method") { Function },                                       -- @lsp.type.method xxx links to Function
        sym("@lsp.type.namespace") { Identifier },                                  -- @lsp.type.namespace xxx links to Identifier
        sym("@lsp.type.property") { fg = red2 },                                    -- @lsp.type.property xxx links to Identifier
        sym("@lsp.type.variable") { Identifier },                                   -- @lsp.type.variable xxx links to Identifier
        sym("@lsp.type.macro") { Macro },                                           -- @lsp.type.macro xxx links to Macro
        sym("@lsp.type.class") { Structure },                                       -- @lsp.type.class xxx links to Structure
        sym("@lsp.type.enum") { Structure },                                        -- @lsp.type.enum xxx links to Structure
        sym("@lsp.type.interface") { Structure },                                   -- @lsp.type.interface xxx links to Structure
        sym("@lsp.type.struct") { Structure },                                      -- @lsp.type.struct xxx links to Structure
        sym("@lsp.type.typeParameter") { Typedef },                                 -- @lsp.type.typeParameter xxx links to Typedef
        sym("@lsp.type.comment") { Comment },                                       -- @lsp.type.comment xxx links to Comment
        sym("@lsp.type.parameter") { gui = "italic", fg = orange, },                -- @lsp.type.parameter xxx cterm=italic gui=italic guifg=#fd971f
        sym("@lsp.type.type") { fg = blue, },                                       -- @lsp.type.type xxx guifg=#66d9ef
        sym("@lsp.typemod.function.defaultLibrary") { fg = orange, },               -- @lsp.typemod.function.defaultLibrary xxx guifg=#fd971f
        sym("@lsp.typemod.keyword.documentation") { gui = "italic", fg = blue, },   -- @lsp.typemod.keyword.documentation xxx cterm=italic gui=italic guifg=#66d9ef
        sym("@lsp.typemod.parameter.declaration") { gui = "italic", fg = orange, }, -- @lsp.typemod.parameter.declaration xxx cterm=italic gui=italic guifg=#fd971f
        sym("@lsp.typemod.variable.global.lua") { fg = orange, },                   -- @lsp.typemod.variable.global.lua xxx guifg=#fd971f
        sym("@lsp.typemod.function.declaration") { fg = yellow2, },                 -- @lsp.typemod.function.declaration xxx guifg=#a6e22e
        sym("@lsp.typemod.class.defaultLibrary") { fg = white, },                   -- @lsp.typemod.class.defaultLibrary xxx guifg=#fdfff1
        sym("@lsp.mod.deprecated") { gui = "strikethrough", },                      -- @lsp.mod.deprecated xxx cterm=strikethrough gui=strikethrough
        sym("@lsp.typemod.variable.defaultLibrary") { fg = orange, },               -- @lsp.typemod.variable.defaultLibrary xxx guifg=#fd971f
        sym("@lsp.typemod.variable.readonly") { fg = purple, },                     -- @lsp.typemod.variable.readonly xxx guifg=#ae81ff
        sym("@lsp.type.class.dockerfile") { fg = blue, },                           -- @lsp.type.class.dockerfile xxx guifg=#66d9ef



        --
        -- fugitive
        --
        diffAdded { DiffAdd }, -- fugitive
        diffNoEOL { DiffChange },
        diffLine { DiffChange },
        diffRemoved { DiffDelete }, -- Diff mode: Deleted line |diff.txt|

        --
        -- gitsigns
        --
        SignDelete { fg = red, },      -- SignDelete
        GitSignsDelete { SignDelete }, -- GitSignsDelete
        SignChange { fg = blue, },     -- SignChange
        GitSignsChange { SignChange }, -- GitSignsChange
        SignAdd { fg = yellow2 },      -- SignAdd
        GitSignsAdd { SignAdd },       -- GitSignsAdd
        GitSignsAddPreview { DiffAdd },
        GitSignsDeletePreview { DiffDelete },
        GitSignsCurrentLineBlame { fg = yellow5 },
        GitSignsAddInline { bg = DiffAdd.fg, fg = DiffAdd.bg },
        GitSignsDeleteInline { bg = DiffDelete.fg, fg = DiffDelete.bg },
        GitSignsChangeInline { DiffText },
        -- GitSignsAddLnInline {},
        -- GitSignsChangeLnInline {},
        -- GitSignsDeleteLnInline {},

        --
        -- diffview
        --
        -- DiffviewFilePanelFileName {},
        -- DiffviewFilePanelCounter {},
        -- DiffviewFilePanelTitle {},
        -- DiffviewSecondary {},
        -- DiffviewPrimary {},
        -- DiffviewDim1 {},
        DiffviewDiffText { DiffText },     -- links to DiffText
        DiffviewDiffDelete { DiffDelete }, -- links to DiffDelete
        -- DiffviewDiffAdd {}, -- links to DiffAdd
        -- DiffviewEndOfBuffer {}, -- links to EndOfBuffer
        -- DiffviewCursorLine {}, -- links to CursorLine
        -- DiffviewReference {}, -- links to Function
        -- DiffviewSignColumn {}, -- links to Normal
        -- DiffviewFolderName {}, -- links to Directory
        -- DiffviewNormal {}, -- links to Normal
        -- DiffviewStatusLineNC {}, -- links to StatusLineNC
        -- DiffviewStatusLine {}, -- links to StatusLine
        -- DiffviewStatusUnmerged {}, -- links to diffChanged
        DiffviewDiffChange { DiffChange }, -- links to DiffChange
        -- DiffviewNonText {}, -- links to NonText
        -- DiffviewStatusUnknown {}, -- links to diffRemoved
        -- DiffviewStatusRenamed {}, -- links to diffChanged
        -- DiffviewStatusIgnored {}, -- links to Comment
        -- DiffviewStatusBroken {}, -- links to diffRemoved
        -- DiffviewStatusDeleted {}, -- links to diffRemoved
        -- DiffviewWinSeparator {}, -- links to WinSeparator
        -- DiffviewStatusTypeChange {}, -- links to diffChanged
        -- DiffviewStatusCopied {}, -- links to diffChanged
        -- DiffviewStatusModified {}, -- links to diffChanged
        -- DiffviewStatusUntracked {}, -- links to diffAdded
        -- DiffviewStatusAdded {}, -- links to diffAdded
        -- DiffviewFolderSign {}, -- links to PreProc
        -- DiffviewFilePanelConflicts {}, -- links to DiagnosticSignWarn
        -- DiffviewFilePanelDeletions {}, -- links to diffRemoved
        -- DiffviewFilePanelInsertions {}, -- links to diffAdded
        -- DiffviewFilePanelPath {}, -- links to Comment
        -- DiffviewFilePanelSelected {}, -- links to Type
        -- DiffviewFilePanelRootPath {}, -- links to DiffviewFilePanelTitle
        -- DiffviewDiffAddAsDelete xxx guifg=#f95353 guibg=#392e22
        -- DiffviewDiffDeleteDim {}, -- links to Comment

        --
        -- Neogit
        --
        -- STATUS BUFFER
        -- NeogitBranch {},
        -- NeogitRemote {},
        -- NeogitObjectId {},
        -- NeogitStash {},
        -- NeogitFold {},
        -- NeogitRebaseDone {},
        --
        -- STATUS BUFFER SECTION HEADERS
        NeogitSectionHeader { fg = red2, gui = "bold" },
        -- NeogitUnpushedTo {},
        -- NeogitUnmergedInto {},
        -- NeogitUnpulledFrom {},
        -- NeogitUntrackedfiles {},
        -- NeogitUnstagedchanges {},
        -- NeogitUnmergedchanges {},
        -- NeogitUnpulledchanges {},
        -- NeogitRecentcommits {},
        -- NeogitStagedchanges {},
        -- NeogitStashes {},
        -- NeogitRebasing {},
        -- NeogitReverting {},
        -- NeogitPicking {},
        --
        -- STATUS BUFFER FILE
        -- Applied to the label on the left of filenames.
        NeogitChangeModified { fg = blue, gui = "bold" },
        NeogitChangeAdded { fg = yellow2, gui = "bold" },
        NeogitChangeDeleted { fg = red, gui = "bold" },
        NeogitChangeRenamed { fg = orange, gui = "bold" },
        NeogitChangeUpdated { fg = blue, gui = "bold" },
        NeogitChangeCopied { fg = orange, gui = "bold" },
        NeogitChangeBothModified { fg = blue, gui = "bold" },
        NeogitChangeNewFile { fg = yellow2, gui = "bold" },
        --
        -- SIGNS FOR LINE HIGHLIGHTING
        -- Used to highlight different sections of the status buffer or commit buffer.
        NeogitHunkHeader { bg = DiffChange.bg, fg = DiffChange.fg.mix(Normal.bg, 70) },
        NeogitDiffContext { bg = Normal.bg, fg = Normal.fg.mix(Normal.bg, 70) },
        NeogitDiffAdd { bg = DiffAdd.bg, fg = DiffAdd.fg.mix(Normal.bg, 70) },
        NeogitDiffDelete { bg = DiffDelete.bg, fg = DiffDelete.fg.mix(Normal.bg, 70) },
        NeogitDiffHeader { bg = DiffChange.bg, fg = DiffChange.fg.mix(Normal.bg, 70) },
        --
        -- SIGNS FOR LINE HIGHLIGHTING CURRENT CONTEXT
        -- These are essentially an accented version of the above highlight groups. Only
        -- applies to the current context the cursor is within.
        NeogitHunkHeaderHighlight { DiffChange },
        NeogitDiffContextHighlight { bg = Normal.bg, },
        NeogitDiffAddHighlight { DiffAdd },
        NeogitDiffDeleteHighlight { DiffDelete },
        -- NeogitDiffHeaderHighlight { DiffChange },
        NeogitCursorLine { CursorLine },
        --
        -- COMMIT BUFFER
        -- NeogitFilePath {},
        -- NeogitCommitViewHeader {},
        --
        -- LOG VIEW BUFFER
        -- NeogitGraphRed {},
        -- NeogitGraphOrange {},
        -- NeogitGraphYellow {},
        -- NeogitGraphGreen {},
        -- NeogitGraphBlue {},
        -- NeogitGraphPurple {},
        -- NeogitGraphRedBold {},
        -- NeogitGraphOrangeBold {},
        -- NeogitGraphYellowBold {},
        -- NeogitGraphGreenBold {},
        -- NeogitGraphBlueBold {},
        -- NeogitGraphPurpleBold {},
        --
        -- POPUPS
        -- NeogitPopupSectionTitle {},
        -- NeogitPopupBranchName {},
        -- NeogitPopupBold {},
        -- NeogitPopupSwitchKey {},
        -- NeogitPopupSwitchEnabled {},
        -- NeogitPopupSwitchDisabled {},
        -- NeogitPopupOptionKey {},
        -- NeogitPopupOptionEnabled {},
        -- NeogitPopupOptionDisabled {},
        -- NeogitPopupConfigKey {},
        -- NeogitPopupConfigEnabled {},
        -- NeogitPopupConfigDisabled {},
        -- NeogitPopupActionKey {},
        -- NeogitPopupActionDisabled {},
        --
        -- NOTIFICATIONS
        -- NeogitNotificationInfo {},
        -- NeogitNotificationWarning {},
        -- NeogitNotificationError {},
        --
        -- COMMAND HISTORY BUFFER
        -- NeogitCommandText {},
        -- NeogitCommandTime {},
        -- NeogitCommandCodeNormal {},
        -- NeogitCommandCodeError {},

        -- which-key
        --
        WhichKey { fg = yellow, gui = "bold", },
        -- WhichKeyGroup { gui="italic", },
        -- WhichKeySeparator { },
        -- WhichKeyDesc { fg=yellow, },
        -- WhichKeyFloat { },
        -- WhichKeyBorder { },
        -- WhichKeyValue { },


        -- cmp
        --
        CmpItemAbbr { fg = yellow3, },
        CmpItemAbbrDefault { fg = orange, },
        CmpItemAbbrDeprecated { fg = yellow3, gui = "strikethrough", },
        CmpItemAbbrDeprecatedDefault { fg = yellow5, },
        CmpItemAbbrMatch { fg = white3, gui = "bold", },
        CmpItemAbbrMatchFuzzy { CmpItemAbbrMatch },
        CmpItemAbbrMatchDefault { CmpItemAbbrMatch },
        CmpItemAbbrMatchFuzzyDefault { CmpItemAbbrMatch },
        CmpItemKindDefault { fg = white3, },
        CmpItemKind { CmpItemKindDefault },
        CmpItemMenu { fg = yellow3, },
        CmpItemMenuDefault { fg = orange, },
        CmpItemKindFile { fg = yellow3, },
        CmpItemKindProperty { fg = orange, },
        CmpItemKindModule { fg = blue, },
        CmpItemKindInterface { fg = blue, },
        CmpItemKindClass { fg = blue, },
        CmpItemKindVariable { fg = blue, },
        CmpItemKindField { fg = orange, },
        CmpItemKindConstructor { fg = yellow2, },
        CmpItemKindFunction { fg = yellow2, },
        CmpItemKindText { fg = yellow, },
        CmpItemKindFolder { fg = orange, },
        CmpItemKindReference { fg = purple, },
        CmpItemKindColor { fg = purple, },
        CmpItemKindKeyword { fg = red2, },
        CmpItemKindUnit { fg = purple, },
        CmpItemKindEnum { fg = orange, },
        CmpItemKindSnippet { fg = yellow2, },
        CmpItemKindMethod { fg = yellow2, },
        CmpItemKindEvent { fg = orange, },
        CmpItemKindTypeParameter { fg = orange, },
        CmpItemKindOperator { fg = red2, },
        CmpItemKindStruct { fg = red2, },
        CmpItemKindConstant { fg = purple, },
        CmpItemKindEnumMember { fg = orange, },
        CmpItemKindPackage { fg = purple, },
        CmpItemKindNumber { fg = purple, },
        CmpItemKindNull { fg = purple, },
        CmpItemKindNamespace { fg = blue, },
        CmpItemKindKey { fg = orange, },
        CmpItemKindArray { fg = red2, },
        CmpItemKindObject { fg = blue, },
        CmpItemKindString { fg = yellow, },
        CmpItemKindBoolean { fg = red2, },

        -- fzf-lua
        --
        -- FzfLuaNormal {},
        -- FzfLuaBorder {},
        -- FzfLuaTitle {},
        -- FzfLuaPreviewNormal {},
        -- FzfLuaPreviewBorder {},
        -- FzfLuaPreviewTitle {},
        -- FzfLuaCursor {},
        -- FzfLuaCursorLine {},
        -- FzfLuaCursorLineNr {},
        -- FzfLuaSearch {},
        -- FzfLuaScrollBorderEmpty {},
        -- FzfLuaBorder {},
        -- FzfLuaScrollBorderFull {},
        -- FzfLuaScrollFloatEmpty {},
        -- FzfLuaScrollFloatFull {},
        -- FzfLuaHelpNormal {},
        -- FzfLuaHelpBorder {},
        -- FzfLuaHeaderBind {},
        -- FzfLuaHeaderText {},
        -- FzfLuaBufName {},
        -- FzfLuaBufNr {},
        -- FzfLuaBufLineNr {},
        -- FzfLuaBufFlagCur {},
        -- FzfLuaBufFlagAlt {},
        -- FzfLuaTabTitle {},
        -- FzfLuaTabMarker {},

        -- oil.nvim
        --
        OilDir { Directory },                -- Directories in an oil buffer
        OilDirIcon { Directory },            -- Icon for directories
        OilSocket { Keyword },               -- Socket files in an oil buffer
        OilLink { Underlined, fg = yellow }, -- Soft links in an oil buffer
        OilFile { fg = Normal.fg },          -- Normal files in an oil buffer
        OilCreate { DiffAdd },               -- Create action in the oil preview window
        OilDelete { DiffDelete },            -- Delete action in the oil preview window
        OilMove { DiagnosticWarn },          -- Move action in the oil preview window
        OilCopy { DiagnosticWarn },          -- Copy action in the oil preview window
        OilChange { DiffChange },            -- Change action in the oil preview window

        -- nvim-bqf
        --
        BqfPreviewFloat { NormalFloat },
        BqfPreviewBorder { FloatBorder },
        BqfPreviewTitle { Title },
        -- BqfPreviewThumb { PmenuThumb },
        -- BqfPreviewSbar { PmenuSbar },
        -- BqfPreviewCursor { Cursor },
        BqfPreviewCursorLine { CursorLine },
        BqfPreviewRange { IncSearch },
        BqfPreviewBufLabel { BqfPreviewRange },
        BqfSign { fg = blue, },

        -- todo-comments.nvim
        --
        TodoBgTODO { bg = blue, fg = black, gui = "bold" },
        TodoFgTODO { fg = blue, gui = "italic" },
        TodoBgFIX { bg = red, fg = black, gui = "bold" },
        TodoFgFIX { fg = red, gui = "italic" },
        TodoBgWARN { bg = orange, fg = black, gui = "bold" },
        TodoFgWARN { fg = orange, gui = "italic" },
        TodoBgHACK { bg = orange, fg = black, gui = "bold" },
        TodoFgHACK { fg = orange, gui = "italic" },
        TodoBgPERF { bg = purple, fg = black, gui = "bold" },
        TodoFgPERF { fg = purple, gui = "italic" },
        TodoBgNOTE { bg = yellow2, fg = black, gui = "bold" },
        TodoFgNOTE { fg = yellow2, gui = "italic" },
        TodoBgTEST { bg = yellow3, fg = black, gui = "bold" },
        TodoFgTEST { fg = yellow3, gui = "italic" },
    }
end)

-- Return our parsed theme for extension or use elsewhere.
return theme
