# sweetscope
Vim plugin for cscope with improved quickfix list management

## Introduction

This plugin was written for use cscope tool in Vim easy and comfortable.

### Features
* Interactive query to cscope db
* Run cscope query for words under cursor or visually selected
* Two run methods of cscope query: Vim native and external
* Auto load cscope db for predefined file types
* Map predefined file types and quickfix buffer for cscope query
* Save history of cscope queries
* Save and load history of cscope queries to\from file 
* Search and select in history of cscope queries
* Restore quickfix stack after Vim native cscope query, prepend quickfix flooding

### Default key maps
Just move cursor on interesting word or select it visually and use some of key maps below.

`Ctrl-\` + `\` - Interactive cscope query

`Ctrl-\` + `s` - Find this C symbol

`Ctrl-\` + `g` - Find this definition

`Ctrl-\` + `d` - Find functions called by this function

`Ctrl-\` + `c` - Find functions calling this function

`Ctrl-\` + `t` - Find this text string

`Ctrl-\` + `e` - Find this egrep pattern

`Ctrl-\` + `f` - Find this file

`Ctrl-\` + `i` - Find files #including this file

`Ctrl-\` + `a` - Find places where this symbol is assigned a value

`Ctrl-\` + `l` - Choose quickfix list in history interactively

`Ctrl-\` + `h` - Search forward in history

`Ctrl-\` + `H` - Search backward in history

`Shift-J` - Jump to next search result in quickfix window (for quickfix buffer only)

`Shift-K` - Jump to previous search result in quickfix window (for quickfix buffer only)

`Shift-H` - Toggle search highlighting in quickfix window

`Ctrl-\` + `q` - Select in all history

`Ctrl-\` + `Q` - Select in current quickfix list

`[n]gl` - Go to [n] quickfix list in history

`Ctrl-N` - Jump to next in history quickfix list

`Ctrl-P` - Jump to previous in history quickfix list

`Ctrl-D` - Remove current quickfix list from history

## Options

### sweetscope_runmethod
Choose run method of cscope query. When `1` is setted Vim native query run will be used. For `0` external cscope program will be executed (by `system()` Vim function) for each query. Each method has slightly different output.
```vim
let g:sweetscope_runmethod = 1
```
(numeric, default `1`)

### sweetscope_filetypes
File types of Vim buffers for which plugin will automatically load cscope db and map keys for cscope query run. To apply plugin configuration for all Vim buffers set this list empty.
```vim
let g:sweetscope_filetypes = []
```
(list, default `['c', 'cpp', 'h']`)

### sweetscope_db_filename
File name of cscope db which plugin will search in working directory of each buffer  and load automatically if `g:sweetscope_autoload_db = 1`.
```vim
let g:sweetscope_db_filename = 'cscope.out'
```
(string, default `'cscope.out'`)

### sweetscope_autoload_db
Auto load cscope db toggle. If it is `1` cscope db defined in `g:sweetscope_db_filename` will be loaded automatically for each buffer which file type defined in `g:sweetscope_filetypes`.
```vim
let g:sweetscope_autoload_db = 1
```
(boolean, default `1`)

### sweetscope_query_maps
Switch on cscope query key maps for buffers which file types defined in `g:sweetscope_filetypes`. These key maps is used to run cscope query for word under cursor or visually selected.
```vim
let g:sweetscope_query_maps = 1
```
(boolean, default `1`)

### sweetscope_map_quickfix
Switch on cscope query key maps for quickfix buffer. These key maps is used to run cscope query for word under cursor or visually selected in quickfix buffer.
```vim
let g:sweetscope_map_quickfix = 1
```
(boolean, default `1`)

### sweetscope_qf_samewin
If `1` open quickfix buffer in the same window where current buffer opened when moving on history. If `0` new quickfix window will be opened (if it has not been opened yet).
```vim
let g:sweetscope_qf_samewin = 1
```
(boolean, default `0`)

### sweetscope_savehistory
Save history of cscope queries.
```vim
let g:sweetscope_savehistory = 1
```
(boolean, default `1`)

### sweetscope_historylength
Maximum length of history list.
```vim
let g:sweetscope_historylength = 100
```
(numeric, default `50`)

### sweetscope_history_maps
If `1` buffers which defined in `g:sweetscope_filetypes` will be mapped for history moving. This means that you can use the same as in quickfix keys in normal buffer for browse trough history lists. For most cases it is not necessary because history always displayed in quickfix window and quickfix buffer is always mapped. 
```vim
let g:sweetscope_history_maps = 1
```
(boolean, default `0`)

### sweetscope_map_qf_enter
If `1` plugin will update quickfix list in history every time you type Enter in quickfix window. I used with option when only start to write plugin. It seems that we don't need it anymore. Stayed as legacy.
```vim
let g:sweetscope_map_qf_enter = 1
```
(boolean, default `0`)

### sweetscope_open_after_current
If `1` new quickfix list generated by cscope query will be placed after current in history list. If `0` every new quickfix list will be appended to the end of history list.
```vim
let g:sweetscope_open_after_current = 1
```
(boolean, default `1`)

### sweetscope_searchopened
If `1` plugin will search already opened cscope quickfix list in quickfix stack and switch to it  when moving on history or running cscope query. It may make sence when current quickfix list doesn't belong to plugin, but may slow down history moving. If `0` new quickfix list in quickfix stack will be created each time you try to move on history and run cscope query if current quickfix list doesn't belong to plugin.
```vim
let g:sweetscope_searchopened = 1
```
(boolean, default `1`)

### sweetscope_noduplicate_qf
If `1` plugin will remove duplicate quickfix list from history on cscope query running. It is used to avoid cscope query lists with the same content.  If `0` duplicate list will be added to history. If this option is enabled it also may slow down new list opening on cscope query running.
```vim
let g:sweetscope_noduplicate_qf = 1
```
(boolean, default `1`)

### sweetscope_noduplicate_items
If `1` plugin will check quickfix list generated by cscope query and remove duplicate items. If this option is enabled it also may slow down new list opening on cscope query running.
```vim
let g:sweetscope_noduplicate_items = 1
```
(boolean, default `1`)

### sweetscope_save_qf_changes
If `1` plugin will save changes which has been made in quickfix buffer. This works only for deleting quickfix list items and not for changing text in quickfix buffer. So, no matter delete item or change its text, plugin will delete this item from corresponding list in history anyway. If this option is enabled it also makes quickfix buffer modifiable all time.
```vim
let g:sweetscope_save_qf_changes = 1
```
(boolean, default `1`)

### sweetscope_save_qf_stack
Vim native cscope query clears quickfix stack after request (but I don't remember in which cases exactly). If this option is enabled plugin will save quickfix stack before cscope query run and restore after.
```vim
let g:sweetscope_save_qf_stack = 1
```
(boolean, default `1`)

### sweetscope_clear_qf_stack
Each cscope query creates new quickfix list in quickfix stack. If this option is enabled plugin will save only one cscope list in quickfix stack, other cscope lists will be saved in history and it is possible to switch to it by history movement.
```vim
let g:sweetscope_clear_qf_stack = 1
```
(boolean, default `1`)

### sweetscope_history_file
It is file name where\from plugin will save\load history by default.
```vim
let g:sweetscope_history_file = 'sweetscope_history'
```
(string, default `'sweetscope_history'`)

### sweetscope_searchmaps
If `1` buffers which file types defined in `g:sweetscope_filetypes` will be mapped for history search engine. It means you can search in history word under cursor or visually selected. If this option disabled such key maps will work only in quickfix buffer and not in normal.
```vim
let g:sweetscope_searchmaps = 1
```
(boolean, default `1`)

### sweetscope_search_hl
If `1` search pattern will be highlighted in quickfix window. Search highlighting also can be toggled on run time by `SweetScopeSearchHLToggle` command.
```vim
let g:sweetscope_search_hl = 1
```
(boolean, default `1`)

### sweetscope_search_hl_attr
`cterm=` and `gui=` attribute for Vim `highlight` command used for history search highlighting (`SweetScopeSearchHL` group).
```vim
let g:sweetscope_search_hl_attr = 'none'
```
(string, default `'none'`)

### sweetscope_search_hl_bg
`ctermbg=` and `guibg=` color for Vim `highlight` command used for history search highlighting (`SweetScopeSearchHL` group).
```vim
let g:sweetscope_search_hl_bg = 'green'
```
(string, default `'green'`)

### sweetscope_search_hl_fg
`ctermfg=` and `guifg=` color for Vim `highlight` command used for history search highlighting (`SweetScopeSearchHL` group).
```vim
let g:sweetscope_search_hl_fg = 'black'
```
(string, default `'black'`)

### sweetscope_echo_hl_attr
`cterm=` and `gui=` attribute for Vim `highlight` command used for echoing messages highlighting (`SweetScopeEchoHL` group).
```vim
let g:sweetscope_echo_hl_attr = 'bold'
```
(string, default `'bold'`)

### sweetscope_echo_hl_bg
`ctermbg=` and `guibg=` color for Vim `highlight` command used for echoing messages highlighting (`SweetScopeEchoHL` group).
```vim
let g:sweetscope_echo_hl_bg = 'NONE'
```
(string, default `'NONE'`

### sweetscope_echo_hl_fg
`ctermfg=` and `guifg=` color for Vim `highlight` command used for echoing messages highlighting (`SweetScopeEchoHL` group).
```vim
let g:sweetscope_echo_hl_fg = 'green'
```
(string, default `'green'`)

### sweetscope_selectmaps
If `1` buffers which file types defined in `g:sweetscope_filetypes` will be mapped for select in history engine. It means you can select in history word under cursor or visually selected. If this option disabled such key maps will work only in quickfix buffer and not in normal.
```vim
let g:sweetscope_selectmaps = 1
```
(boolean, default `1`)

### sweetscope_sortselected
If `1` items in list made from history selection will be sorted. If this option is enabled it may slow down selection in history procedure.
```vim
let g:sweetscope_sortselected = 1
```
(boolean, default `1`)

### sweetscope_noselect_in_selected
If `1` plugin will not make selection in 'select' type lists. It means that if you have already made selection in history and placed results in list this list will be ignored if you will make selection again. It should make selection procedure faster. If `0` all history lists will be considered during selection no matter of them types.
```vim
let g:sweetscope_noselect_in_selected = 1
```
(boolean, default `1`)

### sweetscope_usermaps
```vim
let g:sweetscope_usermaps = 1
```
If `1` set user defined key maps instead of default. If you want to set some key map by default just not define appropriate global variable. Example:
```vim
" Set default key map for interactive cscope query
unlet g:sweetscope_find_interactive_map
```
If you want to switch off some key map define appropriate global variable with empty string value. Example:
```vim
" Switch off key map for interactive cscope query
let g:sweetscope_find_interactive_map = ''
```
(boolean, default `0`)

## Key maps
Query, search and select maps can be invoked both for word under cursor and for visually selected text. If you are going to change plugin default maps don't forget to set `g:sweetscope_usermaps = 1`

### sweetscope_find_interactive_map
Key map for interactive cscope query.
```vim
let g:sweetscope_find_interactive_map = '<C-\>\'
```
(string, default `'<C-\>\'`)

### sweetscope_find_s_map
Key map for 'Find this C symbol' cscope query.
```vim
let g:sweetscope_find_s_map = '<C-\>s'
```
(string, default `'<C-\>s'`)

### sweetscope_find_g_map
Key map for 'Find this definition' cscope query.
```vim
let g:sweetscope_find_g_map = '<C-\>g'
```
(string, default `'<C-\>g'`)

### sweetscope_find_d_map
Key map for 'Find functions called by this function' cscope query.
```vim
let g:sweetscope_find_d_map = '<C-\>d'
```
(string, default `'<C-\>d'`)

### sweetscope_find_c_map
Key map for 'Find functions calling this function' cscope query.
```vim
let g:sweetscope_find_c_map = '<C-\>c'
```
(string, default `'<C-\>c'`)

### sweetscope_find_t_map
Key map for 'Find this text string' cscope query.
```vim
let g:sweetscope_find_t_map = '<C-\>t'
```
(string, default `'<C-\>t'`)

### sweetscope_find_e_map
Key map for 'Find this egrep pattern' cscope query.
```vim
let g:sweetscope_find_e_map = '<C-\>e'
```
(string, default `'<C-\>e'`)

### sweetscope_find_f_map
Key map for 'Find this file' cscope query.
```vim
let g:sweetscope_find_f_map = '<C-\>f'
```
(string, default `'<C-\>f'`)

### sweetscope_find_i_map
Key map for 'Find files #including this file' cscope query.
```vim
let g:sweetscope_find_i_map = '<C-\>i'
```
(string, default `'<C-\>i'`)

### sweetscope_find_a_map
Key map for 'Find places where this symbol is assigned a value' cscope query.
```vim
let g:sweetscope_find_a_map = '<C-\>a'
```
(string, default `'<C-\>a'`)

### sweetscope_choose_history_list_map
Key map for choose concrete history list.
```vim
let g:sweetscope_choose_history_list_map = '<C-\>l'
```
(string, default `'<C-\>l'`)

### sweetscope_search_forward_map
Key map for forward search in history.
```vim
let g:sweetscope_search_forward_map = '<C-\>h'
```
(string, default `'<C-\>h'`)

### sweetscope_search_backward_map
Key map for backward search in history.
```vim
let g:sweetscope_search_backward_map = '<C-\>H'
```
(string, default `'<C-\>H'`)

### sweetscope_toggle_search_hl_map
Key map for toggle search highlighting in quickfix window.
```vim
let g:sweetscope_toggle_search_hl_map = '<S-H>'
```
(string, default `'<S-H>'`)

### sweetscope_search_next_map
Key map for jump to next search result in quickfix window.
```vim
let g:sweetscope_search_next_map = '<S-J>'
```
(string, default `'<S-J>'`)

### sweetscope_search_previous_map
Key map for jump to previous search result in quickfix window.
```vim
let g:sweetscope_search_previous_map = '<S-K>'
```
(string, default `'<S-K>'`)

### sweetscope_select_in_all_history_map
Key map for select by pattern in all history.
```vim
let g:sweetscope_select_in_all_history_map = '<C-\>q'
```
(string, default `'<C-\>q'`)

### sweetscope_select_in_current_list_map
Key map for select by pattern in current quickfix list.
```vim
let g:sweetscope_select_in_current_list_map = '<C-\>Q'
```
(string, default `'<C-\>Q'`)

### sweetscope_goto_list_map
Key map for jump to numbered quickfix list in history. This works similar to Vim `gt` map. Number of list can precede map invoke like `2ql` will jump to second in history quickfix list.
```vim
let g:sweetscope_goto_list_map = 'gl'
```
(string, default `'gl'`)

### sweetscope_history_next_map
Key map for jump to next in history quickfix list.
```vim
let g:sweetscope_history_next_map = '<C-N>'
```
(string, default `'<C-N>'`)

### sweetscope_history_previous_map
Key map for jump to previous in history quickfix list.
```vim
let g:sweetscope_history_previous_map = '<C-P>'
```
(string, default `'<C-P>'`)

### sweetscope_history_delete_map
Key map for delete current quickfix list from history.
```vim
let g:sweetscope_history_delete_map = '<C-D>'
```
(string, default `'<C-D>'`)

## Commands

### cscope query commands
You will may be want to define short abbreviations for cscope query commands like this:
```vim
cabbrev sss SweetScopeS
cabbrev ssg SweetScopeG
cabbrev ssd SweetScopeD
cabbrev ssc SweetScopeC
cabbrev sst SweetScopeT
cabbrev sse SweetScopeE
cabbrev ssf SweetScopeF
cabbrev ssi SweetScopeI
cabbrev ssa SweetScopeA
```

#### SweetScopeInteractive {pattern} [query]
Invoke interactive cscope query for {pattern} if [query] is omitted. If [query] is present invokes speified cscope query.

#### SweetScopeS {pattern}
Invoke s (Find this C symbol) cscope query for {pattern}.
abbreviations: SweetScopes, SweetScope0

#### SweetScopeG {pattern}
Invoke g (Find this definition) cscope query for {pattern}.
abbreviations: SweetScopeg, SweetScope1

#### SweetScopeD {pattern}
Invoke d (Find functions called by this function) cscope query for {pattern}.
abbreviations: SweetScoped, SweetScope2

#### SweetScopeC {pattern}
Invoke c (Find functions calling this function) cscope query for {pattern}.
abbreviations: SweetScopec, SweetScope3

#### SweetScopeT {pattern}
Invoke t (Find this text string) cscope query for {pattern}.
abbreviations: SweetScopet, SweetScope4

#### SweetScopeE {pattern}
Invoke e (Find this egrep pattern) cscope query for {pattern}.
abbreviations: SweetScopee, SweetScope6

#### SweetScopeF {pattern}
Invoke f (Find this file) cscope query for {pattern}.
abbreviations: SweetScopef, SweetScope7

#### SweetScopeI {pattern}
Invoke i (Find files #including this file) cscope query for {pattern}.
abbreviations: SweetScopei, SweetScope8

#### SweetScopeA {pattern}
Invoke a (Find places where this symbol is assigned a value) cscope query for {pattern}.
abbreviations: SweetScopea, SweetScope9

### cscope db commands

#### SweetScopeLoadDB [db_path] [prepath]
Load cscope db file defined in [db_path] with [prepath]. If only [db_path] argument is specified directory contains db file will used as prepath. In no arguments are specified current buffer directory will used as prepath and name defined in `g:sweetscope_db_filename` as db file name.

#### SweetScopeLoadDBsForOpened
Load cscope databases for all opened buffers which types are defined in `g:sweetscope_filetypes`. Value of `g:sweetscope_db_filename` is used as db file name in buffer file directory.

#### SweetScopeReloadAllDBs
Reload all connected cscope databases.

### History commands

#### SweetScopeChooseList [number]
Choose quickfix list by [number] defined in argument in history. If no argument defined run interactive choice.

#### SweetScopeSaveHistory[!] [[{c/a} [filename]]
Save current (with first argument is 'c') history list or all history (with first argument is 'a') to file defined in [filename] argument. If [filename] argument is not specified save history to file defined in `g:sweetscope_history_file`. If no arguments specified save all history. With [!] overwrite history file.

#### SweetScopeLoadHistory[!] [filename]
Load plugin history from [filename] and append it to existing history. If [filename] argument is not specified load history from file defined in `g:sweetscope_history_file`. With [!] overwrite existing history.

### Search and select commands

#### SweetScopeSearch[!] {pattern}
Search {pattern} forward in history. Without arguments search next match of previous search request. With [!] toggle highlighting only for this search request.

#### SweetScopeSearchBack[!] {pattern}
Search {pattern} backward in history. Without arguments search next match of previous search request. With [!] toggle highlighting only for this search request.

#### SweetScopeSearchHLToggle[!]
Toggle search highlighting. With [!] disable highlighting.

#### SweetScopeSelect[!] {pattern}
Select items in history lists which match {pattern} and make new quickfix list with results. With [!] select only in current quickfix list.
