" ============================================================================
" File:        sweetscope.vim
" Description: Run cscope query and manage quickfix lists with results
" Author:      Kirill Bugaev <kirill.bugaev87@gmail.com>
" Licence:     Vim licence
" Website:     https://github.com/Kirill-Bugaev/sweetscope
" Version:     0.1
"
" Copyright notice:
"              Permission is hereby granted to use and distribute this code,
"              with or without modifications, provided that this copyright
"              notice is copied with it. Like anything else that's free,
"              plugin is provided *as is* and comes with no warranty of
"              any kind, either expressed or implied. In no event will the
"              copyright holder be liable for any damamges resulting from the
"              use of this software.
" ============================================================================

" Predefined settings
if has('cscope')
	set cscopeverbose	" enable messages from cscope
	" use both ctag and cscope for tags
	set cscopetag
	" use ctags before cscope
	set csto=1

	" populate quickfix list
	if has('quickfix')
		set cscopequickfix=s-,c-,d-,i-,t-,e-,a-,g-,f-
	endif

	" List of buffers for which cscope db is loaded
	let s:loaded_db_buffers = []

	" Query mapped buffers list
	let s:querymapped_buffers = []

	" Search mapped buffers list
	let s:searchmapped_buffers = []
	
	" Select mapped buffers list
	let s:selectmapped_buffers = []

	" History mapped buffers list
	let s:historymapped_buffers = []
	
	" Last query mapped quickfix buffer number
	let s:last_querymapped_qf_bufnr = 0
	
	" Last history mapped quickfix buffer number
	let s:last_historymapped_qf_bufnr = 0

	" Last search mapped quickfix buffer number
	let s:last_searchmapped_qf_bufnr = 0
	
	" Last select mapped quickfix buffer number
	let s:last_selectmapped_qf_bufnr = 0

	" Last highlighted quickfix buffer namber
	let s:last_hl_qf_bufnr = 0
	
	" Define interactive request commands
	command -bar -nargs=+ -complete=tag SweetScopeInteractive
				\ call s:InteractiveRequest(<f-args>)

	" Define wrappers for cscope commands
	command -nargs=* -complete=tag SweetScopeS call s:Run_cscope('s', <q-args>)
	command -nargs=* -complete=tag SweetScopeG call s:Run_cscope('g', <q-args>)
	command -nargs=* -complete=tag SweetScopeD call s:Run_cscope('d', <q-args>)
	command -nargs=* -complete=tag SweetScopeC call s:Run_cscope('c', <q-args>)
	command -nargs=* -complete=tag SweetScopeT call s:Run_cscope('t', <q-args>)
	command -nargs=* -complete=tag SweetScopeE call s:Run_cscope('e', <q-args>)
	command -nargs=* -complete=tag SweetScopeF call s:Run_cscope('f', <q-args>)
	command -nargs=* -complete=tag SweetScopeI call s:Run_cscope('i', <q-args>)
	command -nargs=* -complete=tag SweetScopeA call s:Run_cscope('a', <q-args>)
	" Define abbreviations
	cabbrev SweetScopes SweetScopeS
	cabbrev SweetScope0 SweetScopeS
	cabbrev SweetScopeg SweetScopeG
	cabbrev SweetScope1 SweetScopeG
	cabbrev SweetScoped SweetScopeD
	cabbrev SweetScope2 SweetScopeD
	cabbrev SweetScopec SweetScopeC
	cabbrev SweetScope3 SweetScopeC
	cabbrev SweetScopet SweetScopeT
	cabbrev SweetScope4 SweetScopeT
	cabbrev SweetScopee SweetScopeE
	cabbrev SweetScope6 SweetScopeE
	cabbrev SweetScopef SweetScopeF
	cabbrev SweetScope7 SweetScopeF
	cabbrev SweetScopei SweetScopeI
	cabbrev SweetScope8 SweetScopeI
	cabbrev SweetScopea SweetScopeA
	cabbrev SweetScope9 SweetScopeA
	
	" Define commands for cscope dbs
	command -bar -nargs=* -complete=file SweetScopeLoadDB
				\ call s:LoadDB_OnCommand(<f-args>)
	command -bar -nargs=0 SweetScopeLoadDBsForOpened
				\ call s:LoadDBsForAllOpenedBuffers()
	command -bar -nargs=0 SweetScopeReloadAllDBs
				\ call s:ReloadAllDBs()

	" Set user defined and default config
	" Run method
	if exists('g:sweetscope_runmethod')
		let s:sweetscope_runmethod = g:sweetscope_runmethod
	else
		let s:sweetscope_runmethod = 1
	endif
	" File types
	if exists('g:sweetscope_filetypes')
		let s:sweetscope_filetypes = deepcopy(g:sweetscope_filetypes)
	else
		let s:sweetscope_filetypes = ['c', 'cpp', 'h']
	endif
	" Read user defined db file name or set default
	if exists('g:sweetscope_db_filename')
		let s:sweetscope_db_filename = g:sweetscope_db_filename
	else
		let s:sweetscope_db_filename = 'cscope.out'
	endif
	" Autoloading db
	if exists('g:sweetscope_autoload_db')
		let s:sweetscope_autoload_db = g:sweetscope_autoload_db
	else
		let s:sweetscope_autoload_db = 1
	endif
	" Mapping ft buffers for query
	if exists('g:sweetscope_query_maps')
		let s:sweetscope_query_maps = g:sweetscope_query_maps
	else
		let s:sweetscope_query_maps = 1
	endif
	" Mapping quickfix like ft buffers for query
	if exists('g:sweetscope_map_quickfix')
		let s:sweetscope_map_quickfix = g:sweetscope_map_quickfix
	else
		let s:sweetscope_map_quickfix = 1
	endif
	" Mapping ft buffers for history
	" Open quickfix buffer in the same window where normal buffers opened 
	" when moving on history
	if exists('g:sweetscope_qf_samewin')
		let s:sweetscope_qf_samewin = g:sweetscope_qf_samewin
	else
		let s:sweetscope_qf_samewin = 0
	endif
	" Save history
	if exists('g:sweetscope_savehistory')
		let s:sweetscope_savehistory = g:sweetscope_savehistory
	else
		let s:sweetscope_savehistory = 1
	endif
	" History length
	if exists('g:sweetscope_historylength') && s:sweetscope_savehistory
		let s:sweetscope_historylength = g:sweetscope_historylength
	elseif s:sweetscope_savehistory
		let s:sweetscope_historylength = 50
	else
		let s:sweetscope_historylength = 0
	endif
	if exists('g:sweetscope_history_maps') && s:sweetscope_savehistory
		let s:sweetscope_history_maps = g:sweetscope_history_maps
	else
		let s:sweetscope_history_maps = 0
	endif
	" Map Enter key in quickfix window for save current quickfix list
	if exists('g:sweetscope_map_qf_enter') && s:sweetscope_savehistory
		let s:sweetscope_map_qf_enter = g:sweetscope_map_qf_enter
	else
		let s:sweetscope_map_qf_enter = 0
	endif
	" Open new quickfix list after current
	if exists('g:sweetscope_open_after_current') && s:sweetscope_savehistory
		let s:sweetscope_open_after_current = g:sweetscope_open_after_current
	else
		let s:sweetscope_open_after_current = 1
	endif
	" Search already opened quickfix lists
	if exists('g:sweetscope_searchopened') && s:sweetscope_savehistory
		let s:sweetscope_searchopened = g:sweetscope_searchopened
	elseif s:sweetscope_savehistory
		let s:sweetscope_searchopened = 1
	else
		let s:sweetscope_searchopened = 0
	endif
	" No duplicate quickfix lists
	if exists('g:sweetscope_noduplicate_qf') && s:sweetscope_savehistory
		let s:sweetscope_noduplicate_qf = g:sweetscope_noduplicate_qf
	else
		let s:sweetscope_noduplicate_qf = 1
	endif
	" No duplicate quickfix list items inside quickfix list
	if exists('g:sweetscope_noduplicate_items') && s:sweetscope_savehistory
		let s:sweetscope_noduplicate_items = g:sweetscope_noduplicate_items
	else
		let s:sweetscope_noduplicate_items = 1
	endif
	" Save changes of quickfix buffer
	if exists('g:sweetscope_save_qf_changes') && s:sweetscope_savehistory
		let s:sweetscope_save_qf_changes = g:sweetscope_save_qf_changes
	elseif s:sweetscope_savehistory
		let s:sweetscope_save_qf_changes = 1
	else
		let s:sweetscope_save_qf_changes = 0
	endif
	" Save quickfix stack before cscope run and restore after
	if exists('g:sweetscope_save_qf_stack')
		let s:sweetscope_save_qf_stack = g:sweetscope_save_qf_stack
	else
		let s:sweetscope_save_qf_stack = 1
	endif
	" Clear quickfix stack from excess cscope lists
	if exists('g:sweetscope_clear_qf_stack')
		let s:sweetscope_clear_qf_stack = g:sweetscope_clear_qf_stack
	else
		let s:sweetscope_clear_qf_stack = 1
	endif
	" SweetScope history file
	if exists('g:sweetscope_history_file') && s:sweetscope_savehistory
		let s:sweetscope_history_file = g:sweetscope_history_file
	else
		let s:sweetscope_history_file = 'sweetscope_history'
	endif
	" Search in history maps
	if exists('g:sweetscope_searchmaps') && s:sweetscope_savehistory
		let s:sweetscope_searchmaps = g:sweetscope_searchmaps
	elseif s:sweetscope_savehistory
		let s:sweetscope_searchmaps = 1
	else
		let s:sweetscope_searchmaps = 0
	endif
	" Search in history highlighting
	if exists('g:sweetscope_search_hl') && s:sweetscope_savehistory
		let s:sweetscope_search_hl = g:sweetscope_search_hl
	elseif s:sweetscope_savehistory
		let s:sweetscope_search_hl = 1
	else
		let s:sweetscope_search_hl = 0
	endif
	" Search in history highlighting attribute
	if exists('g:sweetscope_search_hl_attr') && s:sweetscope_savehistory
		let s:sweetscope_search_hl_attr = g:sweetscope_search_hl_attr
	else
		let s:sweetscope_search_hl_attr = 'none'
	endif
	" Search in history messages highlighting background
	if exists('g:sweetscope_search_hl_bg') && s:sweetscope_savehistory
		let s:sweetscope_search_hl_bg = g:sweetscope_search_hl_bg
	elseif s:sweetscope_savehistory
		let s:sweetscope_search_hl_bg = 'green'
	else
		let s:sweetscope_search_hl_bg = 'NONE'
	endif
	" Search in history messages highlighting foreground
	if exists('g:sweetscope_search_hl_fg') && s:sweetscope_savehistory
		let s:sweetscope_search_hl_fg = g:sweetscope_search_hl_fg
	elseif s:sweetscope_savehistory
		let s:sweetscope_search_hl_fg = 'black'
	else
		let s:sweetscope_search_hl_fg = 'NONE'
	endif
	" Echo highlighting attribute
	if exists('g:sweetscope_echo_hl_attr')
		let s:sweetscope_echo_hl_attr = g:sweetscope_echo_hl_attr
	else
		let s:sweetscope_echo_hl_attr = 'bold'
	endif
	" Echo message highlighting background
	if exists('g:sweetscope_echo_hl_bg')
		let s:sweetscope_echo_hl_bg = g:sweetscope_echo_hl_bg
	else
		let s:sweetscope_echo_hl_bg = 'NONE'
	endif
	" Echo message highlighting foreground
	if exists('g:sweetscope_echo_hl_fg')
		let s:sweetscope_echo_hl_fg = g:sweetscope_echo_hl_fg
	else
		let s:sweetscope_echo_hl_fg = 'green'
	endif
	" Select in quickfix list maps
	if exists('g:sweetscope_selectmaps')
		let s:sweetscope_selectmaps = g:sweetscope_selectmaps
	else
		let s:sweetscope_selectmaps = 1
	endif
	" Sort selected items in quickfix list
	if exists('g:sweetscope_sortselected')
		let s:sweetscope_sortselected = g:sweetscope_sortselected
	else
		let s:sweetscope_sortselected = 1
	endif
	" Omit select quickfix list when selecting
	if exists('g:sweetscope_noselect_in_selected') && s:sweetscope_savehistory
		let s:sweetscope_noselect_in_selected = g:sweetscope_noselect_in_selected
	elseif s:sweetscope_savehistory
		let s:sweetscope_noselect_in_selected = 1
	else
		let s:sweetscope_noselect_in_selected = 0
	endif
	" User defined maps toggle
	if exists('g:sweetscope_usermaps')
		let s:sweetscope_usermaps = g:sweetscope_usermaps
	else
		let s:sweetscope_usermaps = 0
	endif
	" User defined maps
	" cscope find interactive query
	if exists('g:sweetscope_find_interactive_map') && s:sweetscope_usermaps
		let s:sweetscope_find_interactive_map = g:sweetscope_find_interactive_map
	else
		let s:sweetscope_find_interactive_map = '<C-\>\'
	endif
	" cscope find s query
	if exists('g:sweetscope_find_s_map') && s:sweetscope_usermaps
		let s:sweetscope_find_s_map = g:sweetscope_find_s_map
	else
		let s:sweetscope_find_s_map = '<C-\>s'
	endif
	" cscope find g query
	if exists('g:sweetscope_find_g_map') && s:sweetscope_usermaps
		let s:sweetscope_find_g_map = g:sweetscope_find_g_map
	else
		let s:sweetscope_find_g_map = '<C-\>g'
	endif
	" cscope find d query
	if exists('g:sweetscope_find_d_map') && s:sweetscope_usermaps
		let s:sweetscope_find_d_map = g:sweetscope_find_d_map
	else
		let s:sweetscope_find_d_map = '<C-\>d'
	endif
	" cscope find c query
	if exists('g:sweetscope_find_c_map') && s:sweetscope_usermaps
		let s:sweetscope_find_c_map = g:sweetscope_find_c_map
	else
		let s:sweetscope_find_c_map = '<C-\>c'
	endif
	" cscope find t query
	if exists('g:sweetscope_find_t_map') && s:sweetscope_usermaps
		let s:sweetscope_find_t_map = g:sweetscope_find_t_map
	else
		let s:sweetscope_find_t_map = '<C-\>t'
	endif
	" cscope find e query
	if exists('g:sweetscope_find_e_map') && s:sweetscope_usermaps
		let s:sweetscope_find_e_map = g:sweetscope_find_e_map
	else
		let s:sweetscope_find_e_map = '<C-\>e'
	endif
	" cscope find f query
	if exists('g:sweetscope_find_f_map') && s:sweetscope_usermaps
		let s:sweetscope_find_f_map = g:sweetscope_find_f_map
	else
		let s:sweetscope_find_f_map = '<C-\>f'
	endif
	" cscope find i query
	if exists('g:sweetscope_find_i_map') && s:sweetscope_usermaps
		let s:sweetscope_find_i_map = g:sweetscope_find_i_map
	else
		let s:sweetscope_find_i_map = '<C-\>i'
	endif
	" cscope find a query
	if exists('g:sweetscope_find_a_map') && s:sweetscope_usermaps
		let s:sweetscope_find_a_map = g:sweetscope_find_a_map
	else
		let s:sweetscope_find_a_map = '<C-\>a'
	endif
	" Choose history list map
	if exists('g:sweetscope_choose_history_list_map') && s:sweetscope_usermaps
		let s:sweetscope_choose_history_list_map =
					\ g:sweetscope_choose_history_list_map
	else
		let s:sweetscope_choose_history_list_map = '<C-\>l'
	endif
	" Search in history forward map
	if exists('g:sweetscope_search_forward_map') && s:sweetscope_usermaps
		let s:sweetscope_search_forward_map = 
					\ g:sweetscope_search_forward_map
	else
		let s:sweetscope_search_forward_map = '<C-\>h'
	endif
	" Search in history backward map
	if exists('g:sweetscope_search_backward_map') && s:sweetscope_usermaps
		let s:sweetscope_search_backward_map =
					\ g:sweetscope_search_backward_map
	else
		let s:sweetscope_search_backward_map = '<C-\>H'
	endif
	" Toggle search highlighting map
	if exists('g:sweetscope_toggle_search_hl_map') && s:sweetscope_usermaps
		let s:sweetscope_toggle_search_hl_map =
					\ g:sweetscope_toggle_search_hl_map
	else
		let s:sweetscope_toggle_search_hl_map = '<S-H>'
	endif
	" Search next match in history map
	if exists('g:sweetscope_search_next_map') && s:sweetscope_usermaps
		let s:sweetscope_search_next_map = g:sweetscope_search_next_map
	else
		let s:sweetscope_search_next_map = '<S-J>'
	endif
	" Search previous match in history map
	if exists('g:sweetscope_search_previous_map') && s:sweetscope_usermaps
		let s:sweetscope_search_previous_map =
					\ g:sweetscope_search_previous_map
	else
		let s:sweetscope_search_previous_map = '<S-K>'
	endif
	" Select match in all history map
	if exists('g:sweetscope_select_in_all_history_map') && s:sweetscope_usermaps
		let s:sweetscope_select_in_all_history_map =
					\ g:sweetscope_select_in_all_history_map
	else
		let s:sweetscope_select_in_all_history_map = '<C-\>q'
	endif
	" Select match in current quickfix list map
	if exists('g:sweetscope_select_in_current_list_map') && s:sweetscope_usermaps
		let s:sweetscope_select_in_current_list_map =
					\ g:sweetscope_select_in_current_list_map
	else
		let s:sweetscope_select_in_current_list_map = '<C-\>Q'
	endif
	" Goto numbered quickfix list map
	if exists('g:sweetscope_goto_list_map') && s:sweetscope_usermaps
		let s:sweetscope_goto_list_map = g:sweetscope_goto_list_map
	else
		let s:sweetscope_goto_list_map = 'gl'
	endif
	" Goto next quickfix list map
	if exists('g:sweetscope_history_next_map') && s:sweetscope_usermaps
		let s:sweetscope_history_next_map = g:sweetscope_history_next_map
	else
		let s:sweetscope_history_next_map = '<C-N>'
	endif
	" Goto previous quickfix list map
	if exists('g:sweetscope_history_previous_map') && s:sweetscope_usermaps
		let s:sweetscope_history_previous_map =
					\ g:sweetscope_history_previous_map
	else
		let s:sweetscope_history_previous_map = '<C-P>'
	endif
	" Delete current quickfix list from history
	if exists('g:sweetscope_history_delete_map') && s:sweetscope_usermaps
		let s:sweetscope_history_delete_map = g:sweetscope_history_delete_map
	else
		let s:sweetscope_history_delete_map = '<C-D>'
	endif

	" Define history list, history index and quickfix save items
	if exists('s:sweetscope_savehistory') && s:sweetscope_savehistory
		" We add extra keys to quickfix list dictionary
		" type	= 0 for cscope quickfix list
		" 		= 1 for search quickfix list
		" lnum - line number of cursor position in quickfix buffer
		let s:history_list = []
		let s:history_index = -1
		let s:qf_saveitems = {'id': 0, 'idx': 0, 'items': 1, 'title': 1}
		" Not save quickfix buffer changes flag.
		" Setted when moving on history. 
		" Reseted in s:SaveQuickfixChanges function.
		" Prevent saving quickfix changes on history move.
		let s:nsqfc_flag = 0
		" Define command for choose from history list
		command -bar -nargs=* SweetScopeChooseList call s:ChooseHistoryList(<f-args>)
		" Define commands for write and load history file
		command -bar -nargs=* -complete=file -bang SweetScopeSaveHistory
					\ call s:SaveHistoryToFile(<bang>0, <f-args>)
		command -bar -nargs=* -complete=file -bang SweetScopeLoadHistory
					\ call s:LoadHistoryFromFile(<bang>0, <f-args>)
	endif
	
	" Set autocmd for user defined or default file types
	if len(s:sweetscope_filetypes) > 0
		let ft_line = ''
		for ft in s:sweetscope_filetypes
			let ft_line = ft_line . '*.' . ft . ','
		endfor
	else
		let ft_line = '*'
	endif
	" Autoloading db autocmd
	if exists('s:sweetscope_autoload_db') && s:sweetscope_autoload_db
		exe 'autocmd VimEnter * call s:LoadDB_OnVimEnter()'
		exe 'autocmd BufAdd ' . ft_line . ' call s:LoadDB_OnBufAdd()'
		exe 'autocmd BufWritePost ' . ft_line . ' call s:LoadDB_OnBufWrite()'
	endif
	" Query maps for filetype buffers autocmd
	if exists('s:sweetscope_query_maps') && s:sweetscope_query_maps
		exe 'autocmd BufReadPost,BufWritePost,BufEnter ' . ft_line
					\ . ' call s:SetQueryMapsForBuffer_OnBufEvent()'
	endif
	" Search maps for filetype buffers autocmd
	if exists('s:sweetscope_searchmaps') && s:sweetscope_searchmaps
		exe 'autocmd BufReadPost,BufWritePost,BufEnter ' . ft_line
					\ . ' call s:SetSearchMapsForBuffer_OnBufEvent()'
	endif
	" Select maps for filetype buffers autocmd
	if exists('s:sweetscope_selectmaps') && s:sweetscope_selectmaps
		exe 'autocmd BufReadPost,BufWritePost,BufEnter ' . ft_line
					\ . ' call s:SetSelectMapsForBuffer_OnBufEvent()'
	endif
	" History maps for filetype buffers autocmd
	if exists('s:sweetscope_history_maps') && s:sweetscope_history_maps
		exe 'autocmd BufReadPost,BufWritePost,BufEnter ' . ft_line
					\ . ' call s:SetHistoryMapsForBuffer_OnBufEvent()'
	endif
	
	" Set autocmd for quickfix
	" Query maps for quickfix autocmd
	if exists('s:sweetscope_map_quickfix') && s:sweetscope_map_quickfix
		autocmd BufWinEnter quickfix call s:SetQueryMapsForQuickfix_OnBufWinEnter()
	endif
	" History, search and select maps for quickfix autocmd
	if exists('s:sweetscope_savehistory') && s:sweetscope_savehistory
		autocmd BufWinEnter quickfix
					\ call s:SetHistoryMapsForQuickfix_OnBufWinEnter()
		autocmd BufWinEnter quickfix
					\ call s:SetSearchMapsForQuickfix_OnBufWinEnter()
		autocmd BufWinEnter quickfix
					\ call s:SetSelectMapsForQuickfix_OnBufWinEnter()
	endif
	" Save quickfix changes autocmd
	if exists('s:sweetscope_save_qf_changes') && s:sweetscope_save_qf_changes
		autocmd BufWinEnter quickfix setlocal modifiable
		autocmd InsertLeave,TextChanged * call s:SaveQuickfixChanges()
	endif

	" History search engine
	if exists('s:sweetscope_savehistory') && s:sweetscope_savehistory
		" Highlighting groups
		exe 'highlight SweetScopeSearchHL'
					\ . ' cterm=' . s:sweetscope_search_hl_attr
					\ . ' ctermbg=' . s:sweetscope_search_hl_bg
					\ . ' ctermfg=' . s:sweetscope_search_hl_fg
					\ . ' gui=' . s:sweetscope_search_hl_attr
					\ . ' guibg=' . s:sweetscope_search_hl_bg
					\ . ' guifg=' . s:sweetscope_search_hl_fg
		exe 'highlight SweetScopeEchoHL'
					\ . ' cterm=' . s:sweetscope_echo_hl_attr
					\ . ' ctermbg=' . s:sweetscope_echo_hl_bg
					\ . ' ctermfg=' . s:sweetscope_echo_hl_fg
					\ . ' gui=' . s:sweetscope_echo_hl_attr
					\ . ' guibg=' . s:sweetscope_echo_hl_bg
					\ . ' guifg=' . s:sweetscope_echo_hl_fg
		" Highlighting match id getted by matchadd() function
		let s:hl_match_id = -1
		" Search highlighting toggle
		if exists('s:sweetscope_search_hl') && !s:sweetscope_search_hl
			let s:search_hl = 0
		else
			let s:search_hl = 1
		endif
		" Highlighting autocmd
		autocmd BufWinEnter quickfix call s:SetHLForQuickfix_OnBufWinEnter()
		autocmd BufDelete * call s:Reset_hl_match_id_OnBufDelete()
		" Search expression
		let s:search_expr = ''
		" Search commands. Don't use -bar attribute, because Vim will remove
		" backslashes before escape characters when they are occurred in <q-args>.
		" Otherwise should type double backslash before each essential backslash
		" in command line argument.
		command -nargs=* -complete=tag -bang SweetScopeSearch
						\ call s:SearchInHistory(<bang>0, 1, <q-args>)
		command -nargs=* -complete=tag -bang SweetScopeSearchBack
						\ call s:SearchInHistory(<bang>0, -1, <q-args>)
		command -bar -bang SweetScopeSearchHLToggle
						\ call s:ToggleSearchHL(<bang>0)
	endif

	" Selection in history engine
	command -nargs=1 -complete=tag -bang SweetScopeSelect
				\ call s:SelectInHistory(<bang>0, <q-args>)

"	" Override BufAdd autocmd event
"	let s:been_there = {}
"	autocmd BufEnter quickfix
"				\   if !get(s:been_there, bufnr('%'), 0)
"				\ | 	let s:been_there[bufnr('%')] = 1
"				\ | 	call s:BufAdd()
"				\ | endif
"	func s:BufAdd()
"	endfunc

endif

func s:get_qf_bufnr()
	for buf_i in getbufinfo()
		if getbufvar(buf_i.bufnr, '&buftype') ==# 'quickfix'
			return buf_i.bufnr
		endif
	endfor
	return -1
endfunc

" This function is modified version of written by xolox and published on
" StackOverflow.
" Link: https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
function! s:get_visual_selection()
    if mode()==#"v" || mode()==#"V" || mode()==?"CTRL-V"
        let [line_start, column_start] = getpos("v")[1:2]
        let [line_end, column_end] = getpos(".")[1:2]
    else
        let [line_start, column_start] = getpos("'<")[1:2]
        let [line_end, column_end] = getpos("'>")[1:2]
    end
    if (line2byte(line_start)+column_start) > (line2byte(line_end)+column_end)
        let [line_start, column_start, line_end, column_end] =
        \   [line_end, column_end, line_start, column_start]
    end
    let lines = getline(line_start, line_end)
    if len(lines) == 0
            return ''
    endif
    let lines[-1] = lines[-1][: column_end - 1]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

" Load cscope databbase for every buffer opened on Vim start
func s:LoadDB_OnVimEnter()
	for buf_i in getbufinfo()
		" Check if cscope db already loaded for buffer
		let loaddb = 1
		for buf_j in s:loaded_db_buffers
			if buf_i.bufnr == buf_j
				let loaddb = 0
				break
			endif
		endfor
		if loaddb
			" Check file type matches
			let loaddb = 0
			if len(s:sweetscope_filetypes) == 0
				let loaddb = 1
			else
				for ft in s:sweetscope_filetypes
					if ft == fnamemodify(buf_i.name, ':e')
						let loaddb = 1
						break
					endif
				endfor
			endif		
			if loaddb 
				let prepath = fnamemodify(buf_i.name, ':p:h') 
				call s:LoadDB_OnAutocmd(fnameescape(prepath . '/'
							\ . s:sweetscope_db_filename), fnameescape(prepath))
				call add(s:loaded_db_buffers, buf_i.bufnr)
			endif
		endif
	endfor
endfunc

" Load cscope db for buffer on BufAdd autocmd event
func s:LoadDB_OnBufAdd()
	" Check if cscope db already loaded for buffer
	let loaddb = 1
	for buf_i in s:loaded_db_buffers
		if expand("<abuf>") == buf_i
			let loaddb = 0
			break
		endif
	endfor
	" Load db
	if loaddb
		call s:LoadDB_OnAutocmd(fnameescape(expand("<afile>:p:h") . "/"
					\ . s:sweetscope_db_filename),
					\ fnameescape(expand("<afile>:p:h")))
		call add(s:loaded_db_buffers, expand("<abuf>"))
	endif
endfunc

" Load cscope db for buffer on BufWrite autocmd event
func s:LoadDB_OnBufWrite()
	call s:LoadDB_OnAutocmd(fnameescape(expand("%:p:h") . "/"
				\ . s:sweetscope_db_filename), fnameescape(expand("%:p:h")))
	let noadd = 0
	for buf_i in s:loaded_db_buffers
		if bufnr('%') == buf_i
			let noadd = 1
		endif
	endfor
	if !noadd
		call add(s:loaded_db_buffers, bufnr('%'))
	endif
endfunc

" Load cscope db
" !!! Path to cscope db and prepath should not include escaped characters
"     ' \t\n*?[{`$\\%#'\"|!<'
func s:LoadDB_OnAutocmd(db_path, prepath)
	" load cscope db	
	set nocscopeverbose	" disable messages from cscope
	if filereadable(a:db_path)
		exe 'cscope add ' . a:db_path . ' ' . a:prepath
	elseif file_readable($CSCOPE_DB)
		exe 'cscope add ' . $CSCOPE_DB
	endif	
	set cscopeverbose	" enable messages from cscope
endfunc

" Load cscope db on Vim cmd SweetScopeLoadDB
" a000[0] if exists is path to cscope db
" a000[1] if exists is prepath (is the pathname used with the -P command to cscope)
" !!! Path to cscope db and prepath should not include escaped characters
"     ' \t\n*?[{`$\\%#'\"|!<'
func s:LoadDB_OnCommand(...)
	" Get path to db
	if exists('a:000[0]')
		let db_path = fnamemodify(a:000[0], ':p')
	else
		let db_path = expand('%:p:h') . '/' . s:sweetscope_db_filename
	endif

	" Get prepath
	if exists('a:000[1]')
		let prepath = fnamemodify(a:000[1], ':p')
	else 
		let prepath = fnamemodify(db_path, ':p:h')
	endif

	" Unload db if it is already loaded
	call s:UnloadDB(db_path)
	
	" Clear current command line messages before search
"	echon "\r\r"
"	echon ''
"	" Redraw the screen
"	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" Load db
	exe 'cscope add ' . db_path . ' ' . prepath
	if s:CheckDBLoaded(db_path)
		echom 'sweetscope: cscope db "' . db_path . '" loaded successfully.'
	else
		echom 'sweetscope: cscope db "' . db_path . '" has not been loaded.'
	endif

	" Disable echo message highlighting
	echohl None
endfunc

" Load cscope dbs for all opened buffer which filetypes was defined
" in g:sweetscope_filetypes
func s:LoadDBsForAllOpenedBuffers()
	let loaded_dbs = []
	" Scan all listed buffers
	for buf_item in getbufinfo({'buflisted':1})
		let loaddb = 0
		" Check if buffer file type matches defined in s:sweetscope_filetypes
		for ft in s:sweetscope_filetypes
			if ft == fnamemodify(buf_item.name, ':e')
				let loaddb = 1
				break
			endif
		endfor
		" Load db
		if loaddb
			let db_path = fnamemodify(buf_item.name, ':p:h') . '/'
						\ . s:sweetscope_db_filename
			" If db was not loaded before in this function
			if !(index(loaded_dbs, db_path) >= 0)
				call add(loaded_dbs, db_path)
				call  s:LoadDB_OnCommand(db_path)
			endif
		endif
	endfor
endfunc

" Reload all loaded cscope dbs
func s:ReloadAllDBs()
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" Get already loaded dbs
	let cs_show_items = split(execute('cs show'))
	" If no db loaded yet
	if len(cs_show_items) == 3
		" Redraw the screen
		redraw
		" Echo message
		echo 'sweetscope: No one cscope db loaded yet.'
		return
	endif
	
	" Reload dbs
	let css_i = 6
	while css_i < len(cs_show_items)
		exe 'cscope kill ' . cs_show_items[css_i]
		exe 'cscope add ' . cs_show_items[css_i + 2]
					\ . ' ' . cs_show_items[css_i + 3]
		let css_i += 4
	endwhile

	" Disable echo message highlighting
	echohl None
endfunc

" Check if cscope db is loaded
" Returns:	1 if loaded
" 			0 if not
func s:CheckDBLoaded(db_path)
	let retv = 0
	let cs_show_items = split(execute('cs show'))
	if len(cs_show_items) > 3
		let css_i = 6
		while css_i < len(cs_show_items)
			if cs_show_items[css_i + 2] ==# a:db_path
				let retv = 1
				break
			endif
			let css_i += 4
		endwhile
	endif
	return retv
endfunc

" Unload cscope db
" Returns:	1 if db was loaded before
" 			0 if not
func s:UnloadDB(db_path)
	let retv = 0
	" Unload db if it is loaded
	let cs_show_items = split(execute('cs show'))
	if len(cs_show_items) > 3
		let css_i = 6
		while css_i < len(cs_show_items)
			if cs_show_items[css_i + 2] ==# a:db_path
				let retv = 1
				set nocscopeverbose	" disable messages from cscope
				exe 'cscope kill ' . cs_show_items[css_i]
				set cscopeverbose	" enable messages from cscope
			endif
			let css_i += 4
		endwhile
	endif
	return retv
endfunc

" Set query maps for buffer
func s:SetQueryMapsForBuffer_OnBufEvent()
	" Check if buffer already mapped
	let mapbuf = 1
	for buf_i in s:querymapped_buffers
		if bufnr('%') == buf_i
			let mapbuf = 0
			break
		endif
	endfor
	" Set maps
	if mapbuf
		call s:MapCurrentBufferForQuery()
		if exists('s:sweetscope_savehistory') && s:sweetscope_savehistory
			call s:MapCurrentBufferForChooseHistoryList()
		endif
		call add(s:querymapped_buffers, bufnr('%'))
	endif
endfunc

" Set search maps for buffer
func s:SetSearchMapsForBuffer_OnBufEvent()
	" Check if buffer already mapped
	let mapbuf = 1
	for buf_i in s:searchmapped_buffers
		if bufnr('%') == buf_i
			let mapbuf = 0
			break
		endif
	endfor
	" Set maps
	if mapbuf
		call s:MapCurrentBufferForSearch()
		call add(s:searchmapped_buffers, bufnr('%'))
	endif
endfunc

" Set select maps for buffer
func s:SetSelectMapsForBuffer_OnBufEvent()
	" Check if buffer already mapped
	let mapbuf = 1
	for buf_i in s:selectmapped_buffers
		if bufnr('%') == buf_i
			let mapbuf = 0
			break
		endif
	endfor
	" Set maps
	if mapbuf
		call s:MapCurrentBufferForSelect()
		call add(s:selectmapped_buffers, bufnr('%'))
	endif
endfunc

" Set history maps for buffer
func s:SetHistoryMapsForBuffer_OnBufEvent()
	" Check if buffer already mapped
	let mapbuf = 1
	for buf_i in s:historymapped_buffers
		if bufnr('%') == buf_i
			let mapbuf = 0
			break
		endif
	endfor
	" Set maps
	if mapbuf
		call s:MapCurrentBufferForHistory()
		call add(s:historymapped_buffers, bufnr('%'))
	endif
endfunc

" Set query maps for quickfix
func s:SetQueryMapsForQuickfix_OnBufWinEnter()
	if s:last_querymapped_qf_bufnr != bufnr('%')
		call s:MapCurrentBufferForQuery()
		let s:last_querymapped_qf_bufnr = bufnr('%')
	endif	
endfunc

" Set history maps for quickfix
func s:SetHistoryMapsForQuickfix_OnBufWinEnter()
	if s:last_historymapped_qf_bufnr != bufnr('%')
		if exists('s:sweetscope_map_qf_enter') && s:sweetscope_map_qf_enter
			noremap <silent> <buffer> <ENTER> :call <SID>QuickfixOnEnterMap()<CR>
			inoremap <silent> <buffer> <ENTER> <ESC>:call <SID>QuickfixOnEnterMap()<CR>
		endif
		call s:MapCurrentBufferForHistory()
		call s:MapCurrentBufferForChooseHistoryList()
		let s:last_historymapped_qf_bufnr = bufnr('%')
	endif
endfunc

" Set search maps for quickfix
func s:SetSearchMapsForQuickfix_OnBufWinEnter()
	if s:last_searchmapped_qf_bufnr != bufnr('%')
		call s:MapCurrentBufferForSearch()
		call s:QuickfixOnlySearchMaps()
		let s:last_searchmapped_qf_bufnr = bufnr('%')
	endif
endfunc

" Set select maps for quickfix
func s:SetSelectMapsForQuickfix_OnBufWinEnter()
	if s:last_selectmapped_qf_bufnr != bufnr('%')
		call s:MapCurrentBufferForSelect()
		let s:last_selectmapped_qf_bufnr = bufnr('%')
	endif
endfunc

func s:MapCurrentBufferForQuery()
	if s:sweetscope_find_interactive_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_interactive_map
					\ . ' :call <SID>InteractiveRequest(expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_interactive_map
					\ . ' :call <SID>InteractiveRequest(<SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_s_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_s_map
					\ . ' :call <SID>Run_cscope("s", expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_s_map
					\ . ' :call <SID>Run_cscope("s", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_g_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_g_map
					\ . ' :call <SID>Run_cscope("g", expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_g_map
					\ . ' :call <SID>Run_cscope("g", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_d_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_d_map
					\ . ' :call <SID>Run_cscope("d", expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_d_map
					\ . ' :call <SID>Run_cscope("d", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_c_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_c_map
					\ . ' :call <SID>Run_cscope("c", expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_c_map
					\ . ' :call <SID>Run_cscope("c", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_t_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_t_map
					\ . ' :call <SID>Run_cscope("t", expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_t_map
					\ . ' :call <SID>Run_cscope("t", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_e_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_e_map
					\ . ' :call <SID>Run_cscope("e", expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_e_map
					\ . ' :call <SID>Run_cscope("e", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_f_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_f_map
					\ . ' :call <SID>Run_cscope("f", expand("<cfile>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_f_map
					\ . ' :call <SID>Run_cscope("f", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_i_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_i_map
					\ . ' :call <SID>Run_cscope("i", expand("<cfile>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_i_map
					\ . ' :call <SID>Run_cscope("i", <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_find_a_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_find_a_map
					\ . ' :call <SID>Run_cscope("a", expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_find_a_map
					\ . ' :call <SID>Run_cscope("a", <SID>get_visual_selection())<CR>'
	endif
endfunc

func s:MapCurrentBufferForSearch()
	if s:sweetscope_search_forward_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_search_forward_map
					\ . ' :call <SID>SearchInHistoryNext(expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_search_forward_map
					\ . ' :call <SID>SearchInHistoryNext(<SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_search_backward_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_search_backward_map
					\ . ' :call <SID>SearchInHistoryPrev(expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_search_backward_map
					\ . ' :call <SID>SearchInHistoryPrev(<SID>get_visual_selection())<CR>'
	endif
endfunc

func s:QuickfixOnlySearchMaps()
	if s:sweetscope_toggle_search_hl_map != ''
		exe 'noremap <silent> <buffer> ' . s:sweetscope_toggle_search_hl_map
					\ . ' :call <SID>ToggleSearchHL(0)<CR>'
	endif
	if s:sweetscope_search_next_map != ''
		exe 'noremap <silent> <buffer> ' . s:sweetscope_search_next_map
					\ . ' :call <SID>SearchInHistoryNext("")<CR>'
	endif
	if s:sweetscope_search_previous_map != ''
		exe 'noremap <silent> <buffer> ' . s:sweetscope_search_previous_map
					\ . ' :call <SID>SearchInHistoryPrev("")<CR>'
	endif
endfunc

func s:MapCurrentBufferForSelect()
	if s:sweetscope_select_in_all_history_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_select_in_all_history_map
					\ . ' :call <SID>SelectInHistory(0, expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_select_in_all_history_map
					\ . ' :call <SID>SelectInHistory(0, <SID>get_visual_selection())<CR>'
	endif
	if s:sweetscope_select_in_current_list_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_select_in_current_list_map
					\ . ' :call <SID>SelectInHistory(1, expand("<cword>"))<CR>'
		exe 'vnoremap <silent> <buffer> ' . s:sweetscope_select_in_current_list_map
					\ . ' :call <SID>SelectInHistory(1, <SID>get_visual_selection())<CR>'
	endif
endfunc

func s:MapCurrentBufferForHistory()
	if s:sweetscope_goto_list_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_goto_list_map . ' :<C-U>exe'
					\ . '"call <SID>GoToNumberedQuickfixList(v:count)"<CR>'
	endif
	if s:sweetscope_history_next_map != ''
		exe 'noremap <silent> <buffer> ' . s:sweetscope_history_next_map
					\ . ' :call <SID>HistoryNext()<CR>'
	endif
	if s:sweetscope_history_previous_map != ''
		exe 'noremap <silent> <buffer> ' . s:sweetscope_history_previous_map
					\ . ' :call <SID>HistoryPrev()<CR>'
	endif
	if s:sweetscope_history_delete_map != ''
		exe 'noremap <silent> <buffer> ' . s:sweetscope_history_delete_map
					\ . ' :call <SID>RemoveCurrentQuickfixListFromHistory()<CR>'
	endif
endfunc

func s:MapCurrentBufferForChooseHistoryList()
	if s:sweetscope_choose_history_list_map != ''
		exe 'nnoremap <silent> <buffer> ' . s:sweetscope_choose_history_list_map
					\ . ' :call <SID>ChooseHistoryList()<CR>'
	endif
endfunc

func s:QuickfixOnEnterMap()
	silent! exe "normal! \<CR>"
	call s:SaveCurrentQuickfixList()
endfunc

" Choose quickfix list from history
func s:ChooseHistoryList(...)
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" If history is empty
	if s:history_index == -1
		echom 'sweetscope: Nothing to choose. History is empty.'
		" Disable echo message highlighting
		echohl None
		return
	endif

	" If user define quickfix list number in argument
	if exists('a:000[0]')
		let chosen_qfl = a:000[0]
	else
		" Echo quickfix lists from history
		echo 'sweetscope history list:'
		let qfl_i = 0
		while qfl_i <= len(s:history_list) - 1
			echo (qfl_i + 1) . '. ' . s:history_list[qfl_i].title
			let qfl_i += 1
		endwhile
		let chosen_qfl = input('Type number or press ENTER to continue: ')
	endif
		
	" Jump to chosen quickfix list
	if chosen_qfl != ''
		if chosen_qfl > 0 && chosen_qfl <= len(s:history_list)
			call s:OpenQuickfixAndLoadList()
			call s:LoadQuickfixListFromHistory(chosen_qfl - 1)
		else
			echon "\n"
			echom 'Incorrect list number. 1-' . len(s:history_list)
						\ . ' are available.'
		endif
	endif

	" Disable echo message highlighting
	echohl None
endfunc

" Go to quickfix list numbered in argument
func s:GoToNumberedQuickfixList(num)
	if s:history_index != -1
		if a:num == 0
			call s:HistoryNext()
		else
			call s:HistoryMove(a:num - 1, 1)
		endif
	endif
endfunc

func s:HistoryNext()
	call s:HistoryMove(1, 0)
endfunc

func s:HistoryPrev()
	call s:HistoryMove(-1, 0)
endfunc

" Remove current quickfix list from history list
func s:RemoveCurrentQuickfixListFromHistory()
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" If history is empty
	if s:history_index == -1
		echom "Can't delete current quickfix list. History is empty."
		" Disable echo message highlighting
		echohl None
		return
	endif

	let nodel = 0

	" If quickfix window was not opened before
	if s:OpenQuickfixWindow()
		let nodel = 1
	endif

	" Switch to already used quickfix list
	let switch_res = s:SwitchToUsedQuickfixList()
	" If not switched
	if switch_res == 0
		" Create new quickfix list at the end of the stack
		call setqflist([], ' ', {'nr': '$'})
	endif
	if switch_res == 0 || switch_res == 2
		let nodel = 1
	endif
	
	" Remove current quickfix list
	if !nodel
		" If user defined clear quickfix stack and removed quickfix lists is
		" the last
		if exists('s:sweetscope_clear_qf_stack') && s:sweetscope_clear_qf_stack
					\ && len(s:history_list) == 1
			call s:ClearQuickfixStack(0)
		endif
		call remove(s:history_list, s:history_index)
		if s:history_index > len(s:history_list) - 1
			let s:history_index -= 1
		endif
	endif

	if s:history_index != -1
		" Update numbers in titles of quickfix lists in history
		call s:UpdateNumbersInTitlesOfQuickfixListsInHistory()
		" If user defined not clear quickfix stack
		if !(exists('s:sweetscope_clear_qf_stack') && s:sweetscope_clear_qf_stack)
			" Update titles of quickfix lists in stack
			if exists('s:sweetscope_searchopened') && s:sweetscope_searchopened
				call s:UpdateNumbersInTitlesOfQuickfixListsInStack()
			endif
		endif
		" Update quickfix list
		call s:LoadQuickfixListFromHistory(s:history_index)
	else
		" Disable highlighting if it is enabled
		if s:hl_match_id != -1
			call matchdelete(s:hl_match_id)
			let s:hl_match_id = -1
		endif
		" Close quickfix window if no lists in stack
		if getqflist({'nr': '$'}).nr == 0
			cclose
		endif
	endif

	" Disable echo message highlighting
	echohl None
endfunc

" Search in history
" bang = 1 toggle highlighting only for this search
" dir = -1 - backward search
" dir = 1 - forward search
func s:SearchInHistory(bang, dir, ...)
	" If search argument is not empty replace script defined search expression
	if a:000[0] != ''
		let s:search_expr = a:000[0]
	endif

	" Try to open quickfix window and load current quickfix list
	if !s:OpenQuickfixAndLoadList()
		return
	endif

	" If bang toggle highlighting only for this search
	if a:bang
		" If highlighting flag is setted disable highlighting
		if s:search_hl
			if s:hl_match_id != -1
				call matchdelete(s:hl_match_id)
				let s:hl_match_id = -1
			endif
		" If highlighting flag is not setted enable highlighting
		else
			" Disable previous highlighting
			if s:hl_match_id != -1
				call matchdelete(s:hl_match_id)
				let s:hl_match_id = -1
			endif
			" Enable new
			if s:search_expr != ''
				let s:hl_match_id = matchadd('SweetScopeSearchHL', s:search_expr)
			endif
		endif
	" If not bang set highlighting usual way
	else
		if s:search_hl
			" Disable previous highlighting
			if s:hl_match_id != -1
				call matchdelete(s:hl_match_id)
				let s:hl_match_id = -1
			endif
			" Enable new
			if s:search_expr != ''
				let s:hl_match_id = matchadd('SweetScopeSearchHL', s:search_expr)
			endif
		else
			" Disable highlighting
			if s:hl_match_id != -1
				call matchdelete(s:hl_match_id)
				let s:hl_match_id = -1
			endif
		endif
	endif

	" If search nothing
	if s:search_expr == ''
		return
	endif

	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" Determine position in current quickfix list
	let start_item = line('.') - 1
	" If it is search for next or previous match
	if a:000[0] == ''
		let start_item += a:dir
	endif
	" Search loop
	let found = 0
	let cur_index = s:history_index
	let cur_item = start_item
	let start_flag = 1
	while !found
		" If the end of current list is reached
		if a:dir > 0 && cur_item > len(s:history_list[cur_index].items) - 1
			" If the end of history list is reached
			if cur_index == len(s:history_list) - 1
				echo 'sweetscope: search hit BOTTOM, continuing at TOP'
				" Jump to first list
				let cur_index = 0
			else
				" Jump to next list
				let cur_index += 1
			endif
			let cur_item = 0
		" If the beginnig of current list is reached
		elseif a:dir < 0 && cur_item < 0
			" If the beginnig of history list is reached
			if cur_index == 0
				echo 'sweetscope: search hit TOP, continuing at BOTTOM'
				" Jump to last list
				let cur_index = len(s:history_list) - 1
			else
				" Jump to previous list
				let cur_index -= 1
			endif
			let cur_item = len(s:history_list[cur_index].items) - 1
		endif
		" If have returned to the beginnig of search
		if cur_index == s:history_index && cur_item == start_item && !start_flag
			break
		endif
		" Reset start flag
		if start_flag
			let start_flag = 0
		endif
		" Comparison
		if len(s:history_list[cur_index].items) > 0
			let item_expr = bufname(s:history_list[cur_index].items[cur_item].bufnr)
						\ . '|' . s:history_list[cur_index].items[cur_item].lnum . '|'
						\ . ' ' . s:history_list[cur_index].items[cur_item].text
			if item_expr =~# s:search_expr
				let found = 1
				break
			endif
		endif
		" Jump to next item
		let cur_item += a:dir
	endwhile
	
	" Result
	if found
		call s:LoadQuickfixListFromHistory(cur_index)
		call cursor(cur_item + 1, 1)
	else
		" Clear current command line messages before search
		echon "\r\r"
		echon ''
		" Redraw the screen
		redraw
		" Echo message
		echom 'sweetscope: Pattern not found: ' . s:search_expr
	endif
	
	" Disable echo message highlighting
	echohl None
endfunc

" Toggle search highlighting
" Disable if bang = 1
func s:ToggleSearchHL(bang)
	" Disable highlighting if bang
	if a:bang
		let s:search_hl = 0
		if s:hl_match_id != -1
			call matchdelete(s:hl_match_id)
			let s:hl_match_id = -1
		endif
		return
	endif

	" Try to open quickfix window and load current quickfix list
	if !s:OpenQuickfixAndLoadList()
		" Toggle highlighting flag
		let s:search_hl = !s:search_hl
		return
	endif

	" Toggle highlighting
	if s:hl_match_id != -1
		call matchdelete(s:hl_match_id)
		let s:hl_match_id = -1
		let s:search_hl = 0
	else
		if s:search_expr != ''
			let s:hl_match_id = matchadd('SweetScopeSearchHL', s:search_expr)
		endif
		let s:search_hl = 1
	endif
endfunc

" Search next match in history
func s:SearchInHistoryNext(search_expr)
	call s:SearchInHistory(0, 1, a:search_expr)
endfunc

" Search previous match in history
func s:SearchInHistoryPrev(search_expr)
	call s:SearchInHistory(0, -1, a:search_expr)
endfunc

" Make new quickfix list with pattern selection in history.
" With bang = 1 make selection in current quickfix list.
func s:SelectInHistory(bang, pattern)
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL
	
	" Define selected items list
	let sel_items = []

	" If bang = 1 make selection only in current quickfix list
	if a:bang
		let sel_items = s:SelectInQuickfixList(getqflist({'items': 1}), a:pattern)
	" If bang = 0 make selection in all history
	else
		" Scan all history
		for qfl in s:history_list
			" If user defined not select in select quickfix lists
			if exists('s:sweetscope_noselect_in_selected')
						\ && s:sweetscope_noselect_in_selected
						\ && qfl.type == 1
				let qfl_si = []
			else
				" Select items in current quickfix list
				let qfl_si = s:SelectInQuickfixList(qfl, a:pattern)
			endif
			" Add selected items in list
			call extend(sel_items, qfl_si)
		endfor
		" Exclude duplicates
		" if no duplicate quickfix list items option is setted
		if exists('s:sweetscope_noduplicate_items') && s:sweetscope_noduplicate_items
			let sel_items = s:NoDuplicate_qf_items(sel_items)
		endif
		" If user defined sort selected items
		if exists('s:sweetscope_sortselected') && s:sweetscope_sortselected
			let sel_items = s:SortQuickfixListItems(sel_items)
		endif
	endif

	" Result
	if !empty(sel_items)
		" Open quickfix window
		call s:OpenQuickfixWindow()
		" Make selection quickfix list dictionary
		let qfl = {}
		let qfl.items = sel_items
		" If save history defined
		if exists('s:sweetscope_savehistory') && s:sweetscope_savehistory
			" Save current quickfix list
			call s:SaveCurrentQuickfixList()
			" Switch to already used quickfix list if it is possible
			let switch_res = s:SwitchToUsedQuickfixList()
			" If not switched
			if switch_res == 0
				" Create new quickfix list at the end of the stack
				call setqflist([], ' ', {'nr': '$'})
			endif
			" Add extra parameters to quickfix list dictionary
			let qfl.type = 1
			let qfl.lnum = 1
			" Make initial quickfix list title
			let qfl.title = 'select (0 of 0) ' . a:pattern
			" Set no save quickfix buffer changes flag
			let s:nsqfc_flag = 1
			" Replace current quickfix list
			call setqflist([], 'r', qfl)
			" Update quickfix list parameters
			let qfl.id = getqflist({'id': 0}).id
			let qfl.idx = getqflist({'idx': 0}).idx
			" Add quickfix list to history
			call s:AddQuickfixListToHistory(qfl)
			" Update title of visiable quickfix list
			call setqflist([], 'a',
						\ {'title': s:history_list[s:history_index].title})
			" If user defined not clear quickfix stack
			if !(exists('s:sweetscope_clear_qf_stack')
						\ && s:sweetscope_clear_qf_stack)
				" Update titles of quickfix lists in stack
				if exists('s:sweetscope_searchopened') && s:sweetscope_searchopened
					call s:UpdateNumbersInTitlesOfQuickfixListsInStack()
				endif
			endif
		" If no save history
		else
			let qfl.title = 'select ' . a:pattern
			" Create new quickfix list at the end of the stack
			call setqflist([], ' ', {'nr': '$'})
			" Replace quickfix list by new
			call setqflist([], 'r', qfl)
		endif
	else
		" Clear current command line messages before search
		echon "\r\r"
		echon ''
		" Redraw the screen
		redraw
		" Echo message
		echom 'sweetscope: Pattern not found: ' . a:pattern
	endif

	" Disable echo message highlighting
	echohl None
endfunc

" Make selection in quickfix list
func s:SelectInQuickfixList(qfl, pattern)
	let ret_items = []
	for cur_item in a:qfl.items
		let item_expr = bufname(cur_item.bufnr)
					\ . '|' . cur_item.lnum . '|'
					\ . ' ' . cur_item.text
		if item_expr =~# a:pattern
			call add(ret_items, cur_item)
		endif
	endfor
	return ret_items
endfunc

" Sort quickfix list items first by buffer name, last by line number into increasing
" order
func s:SortQuickfixListItems(qfl_items)
	let l:qfl_items = s:SortQuickfixListItemsByBufname(a:qfl_items)
	return s:SortQuickfixListItemsByLinenum(qfl_items)
endfunc

" Sort quickfix list items by buffer name into increasing order
func s:SortQuickfixListItemsByBufname(qfl_items)
	return s:qfl_items_qsort(a:qfl_items, 0, len(a:qfl_items) - 1, 0)
endfunc

" Sort quickfix list items by line number into increasing order
" Supposed that items already sorted by buffer name
func s:SortQuickfixListItemsByLinenum(qfl_items)
	" If nothing to sort
	if empty(a:qfl_items)
		return []
	endif
	
	" Make argument changeable
	let l:qfl_items = deepcopy(a:qfl_items)

	" Select items with identical buffer number
	let cur_i = 1
	let start_i = 0
	let cur_bufnr = qfl_items[0].bufnr
	" Scan all items 
	while cur_i <= len(qfl_items) - 1
		" If jump to the edge of buffer or item is last
		if qfl_items[cur_i].bufnr != cur_bufnr
			let qfl_items = s:qfl_items_qsort(qfl_items, start_i, cur_i - 1, 1)
			let start_i = cur_i
			let cur_bufnr = qfl_items[cur_i].bufnr
		endif
		let cur_i += 1
	endwhile
	" Sort items of the last buffer
	let qfl_items = s:qfl_items_qsort(qfl_items, start_i, cur_i - 1, 1)
	return qfl_items
endfunc

" Sort quickfix list items by sort column into increasing order.
" If sort_col = 0 sort by buffer name.
" If sort_col = 1 sort by line number
func s:qfl_items_qsort(qfl_items, left, right, sort_col)
	" Do nothing if list contains fewer then two items
	if (a:left >= a:right)
		return a:qfl_items
	endif
	" Move partition item to to qfl_items[a:left]
	let l:qfl_items = s:qfl_items_swap(a:qfl_items, a:left, (a:left + a:right) / 2)
	" Sort cycle
	let last = a:left
	" If sort by buffer name
	if a:sort_col == 0
		let comp_col_left = bufname(qfl_items[a:left].bufnr)
	" If sort by line number
	elseif a:sort_col == 1
		let comp_col_left = qfl_items[a:left].lnum
	endif
	let cur_i = a:left + 1
	while cur_i <= a:right
		" If sort by buffer name
		if a:sort_col == 0
			let comp_col_i = bufname(qfl_items[cur_i].bufnr)
		" If sort by line number
		elseif a:sort_col == 1
			let comp_col_i = qfl_items[cur_i].lnum
		endif
		if comp_col_i < comp_col_left
			let last += 1
			if last != cur_i
				let qfl_items = s:qfl_items_swap(qfl_items, last, cur_i)
			endif
		endif
		let cur_i += 1
	endwhile
	" Restore partition item
	let qfl_items = s:qfl_items_swap(qfl_items, a:left, last)
	" Run sort for two parts of qfl_items list
	let qfl_items = s:qfl_items_qsort(qfl_items, a:left, last - 1, a:sort_col)
	let qfl_items = s:qfl_items_qsort(qfl_items, last + 1, a:right, a:sort_col)
	return qfl_items
endfunc

" Interchange qfl_items[el_i] and qfl_items[el_j]
func s:qfl_items_swap(qfl_items, el_i, el_j)
	" Make argument changeable
	let l:qfl_items = deepcopy(a:qfl_items)
	
	let temp = deepcopy(qfl_items[a:el_i])
	let qfl_items[a:el_i] = deepcopy(qfl_items[a:el_j])
	let qfl_items[a:el_j] = temp

	return qfl_items
endfunc

" Add quickfix list to history list
func s:AddQuickfixListToHistory(qfl)
	" If not save double option is setted
	if exists('s:sweetscope_noduplicate_qf') && s:sweetscope_noduplicate_qf
		call s:NoDuplicate_qf(a:qfl)
	endif
	" Add quickfix list to history list
	if exists('s:sweetscope_open_after_current')
				\ && s:sweetscope_open_after_current
				\ && s:history_index != -1
		let s:history_index += 1
		call insert(s:history_list, a:qfl, s:history_index)
	else
		call add(s:history_list, a:qfl)
		let s:history_index = len(s:history_list) - 1	
	endif
	" Remove first quickfix list item if history limit is reached
	if exists('s:sweetscope_historylength')
				\ && len(s:history_list) > s:sweetscope_historylength
		call remove(s:history_list, 0)
		let s:history_index -= 1
	endif
	" Update numbers in titles of quickfix lists in history
	call s:UpdateNumbersInTitlesOfQuickfixListsInHistory()
endfunc

" steps = -n - move n steps back
" steps = 0 - don't move
" steps = n - move n steps forward
" goto_flag = 0 for previous and next moves
" goto_flag = 1 for goto move
func s:HistoryMove(steps, goto_flag)
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" If history not empty
	if s:history_index != -1
		
		" Make steps variable modifiable
		let l:steps = a:steps
		
		" If quickfix wasn't opened before or was opened on other screen
		" and goto_flag not setted
		if s:OpenQuickfixWindow() && !a:goto_flag
			" not move on history
			let l:steps = 0
		endif

		" Switch to already used quickfix list if it is possible
		let switch_res = s:SwitchToUsedQuickfixList()
		" If not switched
		if switch_res == 0
			" Create new quickfix list at the end of the stack
			call setqflist([], ' ', {'nr': '$'})
		else
			call s:SaveCurrentQuickfixList()
		endif
		" Not move on history if goto flag is not setted and switched or not
		" switched
		if !a:goto_flag && (switch_res == 0 || switch_res == 2)	
			let steps = 0
		endif

		" Define new history index
		if a:goto_flag
			let new_index = steps
		else
			let new_index = s:history_index + steps
		endif
		if new_index < 0
			let new_index = 0
			echo 'sweetscope: History beginnig is reached.'
		elseif new_index > len(s:history_list) - 1
			echo 'sweetscope: History end is reached.'
			let new_index = len(s:history_list) - 1
		endif

		" Update quickfix list
		call s:LoadQuickfixListFromHistory(new_index)

	else
		echo "sweetscope: Can't move on. History is empty."
	endif

	" Disable echo message highlighting
	echohl None
endfunc

" Open quickfix window and load current quickfix list from history
" Returns: 	1 if quickfix list have been loaded
" 			0 if not
func s:OpenQuickfixAndLoadList()
	" If history is empty
	if s:history_index == -1
		return 0
	endif
	
	" Open quickfix window if it is not opened yet
	call s:OpenQuickfixWindow()

	" Try to switch to used quickfix list
	let switch_res = s:SwitchToUsedQuickfixList()
	if switch_res == 0
		" Create new quickfix list at the end of the stack
		call setqflist([], ' ', {'nr': '$'})
		" Load current in history quickfix list
		call s:LoadQuickfixListFromHistory(s:history_index)
	endif
	
	return 1
endfunc

" Open quickfix window
" Returns: 	0 - if quickfix was already opened
" 			1 - if quickfix wasn't opened before or was opened on other screen
func s:OpenQuickfixWindow()
	let l:ret = 0

	" Get quickfix bufnr
	let qf_bufnr = s:get_qf_bufnr()

	" If quickfix not opened yet
	if qf_bufnr == -1

		let l:ret = 1
		
		" If user define open quickfix buffer in same window
		if exists('s:sweetscope_qf_samewin') && s:sweetscope_qf_samewin
			copen
			let qf_bufnr = bufnr('%')
			wincmd p
			exe 'buffer ' . qf_bufnr
			wincmd p
			cclose
		else
			silent! botright copen
		endif

	else

		" Check if quickfix buffer opened on current screen
		" If so switch to it
		let qf_found = 0
		let last_winnr = winnr('$')
		let winnr_i = 1
		while winnr_i <= last_winnr
			if winbufnr(winnr_i) == qf_bufnr
				let qf_found = 1
				call win_gotoid(win_getid(winnr_i))
				break
			endif
			let winnr_i += 1
		endwhile

		" If quickfix opened on another screen
		if !qf_found
			let l:ret = 1

			" If user define open quickfix buffer in same window
			if exists('s:sweetscope_qf_samewin') && s:sweetscope_qf_samewin
				exe 'buffer ' . qf_bufnr
			else
				silent! botright copen
			endif
		endif

	endif

	return l:ret
endfunc

" Switch to already used quickfix list
" Returns:	0 if switch to used quickfix list is not possible (used quickfix
" 			list is absent or user defined not search opened quickfix lists)
" 			1 if current quickfix list is appropriate
" 			2 if switched
func s:SwitchToUsedQuickfixList()
	" If history is empty
	if s:history_index == -1
		return 0
	endif

	" Get current quickfix list id
	let cur_qfl_id = getqflist({'id': 0}).id

	" If current quickfix list id equals id of current item in history
	" then current quickfix list is appropriate
	if cur_qfl_id == s:history_list[s:history_index].id
		" Return appropriate
		return 1
	endif

	" If user defined not search already used quickfix lists
	if !(exists('s:sweetscope_searchopened') && s:sweetscope_searchopened)
		" Return not switched
		return 0
	endif

	" Check if current quickfix list contained in history list
	let found_index = 
				\ s:FindQuickfixListInHistory(getqflist(s:qf_saveitems))
	" Move history index to found quickfix list
	if found_index != -1
		let s:history_index = found_index
		let s:history_list[s:history_index].id = cur_qfl_id
		" Return appropriate
		return 1
	endif

	" If following is running it means that current quickfix list not in history
	" list. Find last nr (in stack) of quickfix list which contained in history.
	let found = s:FindLast_qf_List_nr_InHistory()
	" If found
	if !empty(found)
		" Commented leaves found quickfix list opened.
		" Without it current in history quickfix list will be
		" opened instead of found. I don't know which variant
		" is better.
		"let s:history_index = found.history_index
		"let s:history_list[s:history_index].id
		"			\ = getqflist({'id': 0, 'nr': found.qfl_nr}).id
		" Jump to found quickfix list
		let cur_qfl_nr = getqflist({'nr': 0}).nr
		if found.qfl_nr > cur_qfl_nr
			" Set no save quickfix buffer changes flag
			let s:nsqfc_flag = 1
			exe 'cnewer ' . (found.qfl_nr - cur_qfl_nr)
		elseif found.qfl_nr < cur_qfl_nr
			" Set no save quickfix buffer changes flag
			let s:nsqfc_flag = 1
			exe 'colder ' . (cur_qfl_nr - found.qfl_nr)
		endif
		" Move history index to found quickfix list
		let s:history_index = found.history_index
		let s:history_list[s:history_index].id = getqflist({'id': 0}).id
		" Restore cursor
		call cursor(s:history_list[s:history_index].lnum, 1)
		" Return switched
		return 2
	endif
	
	" Return not switched
	return 0
endfunc

" Load quickfix list from history to quickfix buffer
func s:LoadQuickfixListFromHistory(qfl_hi)
	" Erase quickfix list id before replacing
	unlet s:history_list[a:qfl_hi].id
	" Set no save quickfix buffer changes flag
	let s:nsqfc_flag = 1
	" Replace quickfix list
	call setqflist([], 'r', s:history_list[a:qfl_hi])
	" Set cursor
	call cursor(s:history_list[a:qfl_hi].lnum, 1)
"	" If quickfix buffer can be changed
"	if exists('s:sweetscope_save_qf_changes') && s:sweetscope_save_qf_changes
"		setlocal modifiable
"	endif
	" Save new quickfix list id
	let s:history_list[a:qfl_hi].id = getqflist({'id': 0}).id
	" Set new history_index
	let s:history_index = a:qfl_hi
endfunc

" Remove duplicate quickfix list from history
func s:NoDuplicate_qf(qfl)
	" Check if current quickfix list is duplicate
	let dup_i = s:FindQuickfixListInHistory(a:qfl)
	if dup_i != -1
		" Remove duplicate (previous list)
		call remove(s:history_list, dup_i)
		" Move history index
		if s:history_index >= dup_i
			let s:history_index -= 1
		endif
	endif
endfunc

" Remove duplicate items from quickfix list items.
" Returns quickfix list items without duplicates.
func s:NoDuplicate_qf_items(qfl_items)
	" Make argument modifiable
	let qfl_items = deepcopy(a:qfl_items)
	" Scan all items of quickfix list
	let qfl_item_i = 0
	while qfl_item_i < len(qfl_items) - 1
		" Make expression of item i
		let qfl_item_i_expr = bufname(qfl_items[qfl_item_i].bufnr)
					\ . '|' . qfl_items[qfl_item_i].lnum . '|'
					\ . ' ' . qfl_items[qfl_item_i].text
		" Scan rest items
		let qfl_item_j = qfl_item_i + 1
		while qfl_item_j <= len(qfl_items) - 1
			" Make expression of item j
			let qfl_item_j_expr = bufname(qfl_items[qfl_item_j].bufnr)
						\ . '|' . qfl_items[qfl_item_j].lnum . '|'
						\ . ' ' . qfl_items[qfl_item_j].text
			" If expressions are equal remove item j
			if qfl_item_i_expr == qfl_item_j_expr
				call remove(qfl_items, qfl_item_j)
			else
				let qfl_item_j += 1
			endif
		endwhile
		let qfl_item_i += 1
	endwhile
	return qfl_items
endfunc

" Find quickfix list in history list 
" Returns:	history index if found 
" 			-1 if not
func s:FindQuickfixListInHistory(qfl)
	" Scan history list
	let hl_i = 0
	while hl_i <= len(s:history_list) - 1
		" If desired quickfix list equals quickfix list from history
		" then found
		if s:CompareQuickfixLists(a:qfl, s:history_list[hl_i])
			return hl_i
		endif
		let hl_i += 1
	endwhile
	" If nothing found
	return -1
endfunc

" Compare two quickfix lists. Quickfix lists titles are compared first. May be
" it is faster then direct lists comparison.
" Returns:	0 if lists not equal
" 			1 if equal
func s:CompareQuickfixLists(qfl1, qfl2)
	" Make arguments changeable
	let l:qfl1 = deepcopy(a:qfl1)
	let l:qfl2 = deepcopy(a:qfl2)

	" Compare types if they exist
	if exists('qfl1.type') && exists('qfl2.type') && qfl1.type != qfl2.type
		return 0
	endif

	" Remove numbers from titles
	" If selection quickfix list
	if (exists('qfl1.type') && qfl1.type == 1) || qfl1.title[:5] ==# 'select'
		let qfl1.title = qfl1.title[0:5] . ' '
					\ . qfl1.title[stridx(qfl1.title, ')') + 2:]
	" If not selection quickfix list
	else
		let qfl1.title = qfl1.title[0:6] . ' '
					\ . qfl1.title[stridx(qfl1.title, ')') + 2:]
	endif
	" If selection quickfix list
	if (exists('qfl2.type') && qfl2.type == 1) || qfl2.title ==# 'select'
		let qfl2.title = qfl2.title[0:5] . ' '
					\ . qfl2.title[stridx(qfl2.title, ')') + 2:]
	" If not selection quickfix list
	else
		let qfl2.title = qfl2.title[0:6] . ' '
					\ . qfl2.title[stridx(qfl2.title, ')') + 2:]
	endif

	" Compare titles
	if qfl1.title == qfl2.title
		" Compare items
		if qfl1.items == qfl2.items
			return 1
		endif
	endif
	return 0
endfunc

" Find last quickfix list nr in stack that contained in history list
" Returns:	dictionary {'qfl_nr', 'history_index'} if found
" 			{} if not
func s:FindLast_qf_List_nr_InHistory()
	let qf_getitems = deepcopy(s:qf_saveitems)
	"Scan quickfix list stack
	let qfl_nr = getqflist({'nr': '$'}).nr
	while qfl_nr >= 1
		" Check if quickfix list in stack contained in history list
		let qf_getitems.nr = qfl_nr
		let qfl = getqflist(qf_getitems)
		let found_index = s:FindQuickfixListInHistory(qfl)
		if found_index != -1
			let ret_dict = {}
			let ret_dict.qfl_nr = qfl_nr
			let ret_dict.history_index = found_index
			return ret_dict
		endif	
		let qfl_nr -= 1
	endwhile
	" If nothing found
	return {}
endfunc

func s:SaveCurrentQuickfixList()
	if s:history_index != -1
		" If user defined search already used quickfix list
		if exists('s:sweetscope_searchopened') && s:sweetscope_searchopened
			let qfl = getqflist(s:qf_saveitems)
			let qfl_hi = s:FindQuickfixListInHistory(qfl)
			if qfl_hi != -1
				let s:history_list[qfl_hi].id = qfl.id
				let s:history_list[qfl_hi].idx = qfl.idx
				let qf_bufnr = s:get_qf_bufnr()
				if qf_bufnr != -1
					let s:history_list[qfl_hi].lnum = getbufinfo(qf_bufnr)[0].lnum
				endif
			endif
		endif
	endif
endfunc

" Save quickfix buffer changes in history list
func s:SaveQuickfixChanges()
	" If not save quickfix buffer changes flag is setted then don't save
	if s:nsqfc_flag	
		" Reset history move flag
		let s:nsqfc_flag = 0
		return
	endif
	
	" Check if changes were made in quickfix buffer
	if bufnr('%') == s:get_qf_bufnr()
		" Find current quickfix list in history list
		let qfl_hi = s:FindQuickfixListInHistory(getqflist(s:qf_saveitems))
		" If list have been found in history list
		if qfl_hi != -1
			" Will search every quickfix list item in quickfix buffer
			for qfl_item in s:history_list[qfl_hi].items
				" Make search expression for current quickfix list item
				let se = bufname(qfl_item.bufnr)
							\ . '|' . qfl_item.lnum . '|'
							\ . ' ' . qfl_item.text
				" Find search expression in quickfix buffer
				let found = 0
				let cl = 1
				while cl <= line('$')
					if se == getline(cl)
						let found = 1
						break
					endif
					let cl += 1
				endwhile
				if !found
					" Remove current item from quickfix list
					call remove(s:history_list[qfl_hi].items,
								\ index(s:history_list[qfl_hi].items, qfl_item))
				endif
			endfor

			" In general we should set not save quickfix buffer changes flag
			" (s:nsqfc_flag) because update of quickfix invoke TextChanged autocmd
			" event and this function again. But Vim apparently catches that changes
			" were made from autocmd event and doesn't invoke it. So we should not
			" set flag here. 


			" Save cursor position
			let cur_cursor = getpos('.')

			" Reload quickfix list
			" Can't use s:LoadQuickfixListFromHistory function here because it
			" sets s:nsqfc_flag = 1 which will not be reseted because TextChanged
			" autocmd event will not be invoked repeatedly.
			" Erase quickfix list id before replacing
			unlet s:history_list[qfl_hi].id
			" Replace quickfix list
			call setqflist([], 'r', s:history_list[qfl_hi])
			" Save new quickfix list id
			let s:history_list[qfl_hi].id = getqflist({'id': 0}).id
			" Set new history_index
			let s:history_index = qfl_hi

			" Restore cursor
			call cursor(cur_cursor[1], cur_cursor[2])
			" If quickfix list can be changed
			if exists('s:sweetscope_save_qf_changes')
						\ && s:sweetscope_save_qf_changes
				setlocal modifiable
			endif
		endif
	endif
endfunc

" Set highlighting for quickfix buffer on BufWinEnter autocmd event
func s:SetHLForQuickfix_OnBufWinEnter()
	if s:last_hl_qf_bufnr != bufnr('%')
		" Enable highlighting if it is not enabled yet
		if s:history_index != -1 && s:search_hl && s:hl_match_id == -1
					\ && s:search_expr != ''
			let s:hl_match_id = matchadd('SweetScopeSearchHL', s:search_expr)
		endif
		" Save quickfix buffer nr
		let s:last_hl_qf_bufnr = bufnr('%')
	endif	
endfunc

" Reset hl_match_id value on BufDelete autocmd event
func s:Reset_hl_match_id_OnBufDelete()
	if expand('<abuf>') == s:last_hl_qf_bufnr
"		if s:hl_match_id != -1
"			call matchdelete(s:hl_match_id)
"		endif
		let s:hl_match_id = -1
	endif
endfunc

" Return relative to 'dpath' path of 'fpath' with dots.
" fpath is full path to file.
" dpath is directory path.
" 'fpath' and 'dpath' should be absolute paths.
func s:get_relative_path(fpath, dpath)
	" Make arguments changeable
	let fpath = a:fpath
	let dpath = a:dpath
	
	" Stupid check of arguments
	if fpath == '' || dpath == '' || fpath[0] != '/' || dpath[0] != '/'
		return fpath
	endif

	" Add trailing `/` to dpath
	if dpath[len(dpath) - 1] != '/'
		let dpath = dpath . '/'
	endif
	
	" Find fpath and rpath matches
	let slash_count = 1
	let fpath_slash_i = 0
	let dpath_slash_i = 0
	let match_pos = 0
	while fpath_slash_i != -1 && dpath_slash_i != -1
				\ && fpath_slash_i == dpath_slash_i
				\ && fpath[match_pos:fpath_slash_i] == dpath[match_pos:dpath_slash_i]
		let match_pos = fpath_slash_i
		let fpath_slash_i = match(fpath, '/', fpath_slash_i + 1)
		let dpath_slash_i = match(dpath, '/', dpath_slash_i + 1)
	endwhile
	
	" Remove equal part from fpath and dpath
	let fpath = fpath[match_pos + 1:]
	let dpath = dpath[match_pos + 1:]
	
	" Replace dictionaries that is absent in fpath by '../'
	let dpath_slash_i = match(dpath, '/')
	while dpath_slash_i != -1
		let fpath = '../' . fpath
		let dpath_slash_i = match(dpath, '/', dpath_slash_i + 1)
	endwhile

	return fpath
endfunc

" Save quickfix history to file
" If bang = 1 rewrite file
" First argument is 'c' or 'a' that means save current or all quickfix lists
func s:SaveHistoryToFile(bang, ...)
	" Save current quickfix list
	call s:SaveCurrentQuickfixList()

	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" If history is empty
	if s:history_index == -1
		echom 'sweetscope: History is empty. Nothing to save.'
		" Disable echo message highlighting
		echohl None
		return
	endif

	" Determine target of saving
	if len(a:000) > 0 && a:000[0] !=? 'c' && a:000[0] !=? 'a'
		echom 'sweetscope: Wrong first argument. Usage: '
					\ . 'SweetScopeSaveHistory[!] [{c/a} [filename]]'
		" Disable echo message highlighting
		echohl None
		return
	endif
	let target = 'all'
	if len(a:000) > 0 && a:000[0] ==? 'c'
		let target = 'current'
	endif
	" Determine file name
	let fname = s:sweetscope_history_file
	if len(a:000) > 1
		let fname = a:000[1]
	endif

	" If file already exists
	if !a:bang && !empty(glob(fname))
		if input('File "' . fnamemodify(fname, ':p')
					\ . '" already exists. Overwrite? (y/n)') !=? 'y'
			" Clear current command line messages before search
			echon "\r\r"
			echon ''
			" Redraw the screen
			redraw
			" Disable echo message highlighting
			echohl None
			return
		endif
	endif

	" Define list which will saved
	let save_list = []

	" Get current working directory
	let cwd = getcwd()
	" Get history file directory
	if fname[0] != '/'
		let history_file_dir = fnamemodify(cwd . '/' . fname, ':p:h')
	else
		let history_file_dir = fnamemodify(fname, ':p:h')
	endif
	" Define dictionary with relative paths (history_file_dir) to buffers files.
	" index = bufnr, value = relative path
	let rel_fnames = {}
	" Define dictionary with 'absolute' paths (cwd + bufname() = absolute path)
	" to buffers files: index = bufnr, value = bufname()
	let abs_fnames = {}

	" Fill rel_fnames and abs_fnames dictionaries
	if target ==# 'all'
		" Scan all history list
		for qfl in s:history_list
			for qfl_item in qfl.items
				" If buffer is absent in dictionary and its name is not absolute path 
				if !has_key(rel_fnames, qfl_item.bufnr)
							\ && bufname(qfl_item.bufnr)[0] != '/'
					" Save buffer relative paths
					let rel_fnames[qfl_item.bufnr] = s:get_relative_path(
								\ cwd . '/' . bufname(qfl_item.bufnr),
								\ history_file_dir)
				endif
				if !has_key(abs_fnames, qfl_item.bufnr)
					" Save buffer 'absolute' (cwd + bufname() = absolute path) path
					let abs_fnames[qfl_item.bufnr] = bufname(qfl_item.bufnr)
				endif
			endfor
		endfor
	elseif target ==# 'current'
		" If user define search opened quickfix lists
		if exists('s:sweetscope_searchopened') && s:sweetscope_searchopened
			" Try to find current quickfix list in history
			let found_index = s:FindQuickfixListInHistory(getqflist(s:qf_saveitems))
			if found_index != -1
				let s:history_index = found_index
			else
				" Redraw the screen
				redraw
				" Echo message
				echom "sweetscope: History not saved."
							\ . " Can't find current quickfix list in history."
				" Disable echo message highlighting
				echohl None
				return
			endif
		endif
		" Scan only current history list
		for qfl_item in s:history_list[s:history_index].items
			if !has_key(rel_fnames, qfl_item.bufnr)
						\ && bufname(qfl_item.bufnr)[0] != '/'
				" Save buffer relative paths
				let rel_fnames[qfl_item.bufnr] = s:get_relative_path(
							\ cwd . '/' . bufname(qfl_item.bufnr),
							\ history_file_dir)
			endif
			if !has_key(abs_fnames, qfl_item.bufnr)
				" Save buffer 'absolute' (cwd + bufname() = absolute path) path
				let abs_fnames[qfl_item.bufnr] = bufname(qfl_item.bufnr)
			endif
		endfor
	endif

	" Add dictionary with relative paths to save_list
	call add(save_list, string(rel_fnames))
	
	" Add current working directory to save list
	call add(save_list, cwd)

	" Add dictionary with 'absolute' paths to save list
	call add(save_list, string(abs_fnames))
	
	" Add history list length to save list
	if target ==# 'all'
		call add(save_list, len(s:history_list))
	elseif target ==# 'current'
		call add(save_list, 1)
	endif

	" Add history index to save list
	if target ==# 'all'
		call add(save_list, s:history_index)
	elseif target ==# 'current'
		call add(save_list, 0)
	endif

	" Add quickfix lists from history to save list
	if target ==# 'all'
		" Scan all history
		for qfl in s:history_list
			" Add current quickfix list title to save list
			call add(save_list, qfl.title)
			" Add index of current entry in the quickfix list to save list
			call add(save_list, qfl.idx)
			" Add quickfix list type to save list
			call add(save_list, qfl.type)
			" Add line of cursor position in the quickfix list to save list
			call add(save_list, qfl.lnum)
			" Add number of items in quickfix list to save list
			call add(save_list, len(qfl.items))
			" Add each quickfix list item to save list
			for qfl_item in qfl.items
				call add(save_list, string(qfl_item))
			endfor
		endfor
	elseif target ==# 'current'
		" Add current quickfix list title to save list
		call add(save_list, s:history_list[s:history_index].title)
		" Add index of current entry in the quickfix list to save list
		call add(save_list, s:history_list[s:history_index].idx)
		" Add quickfix list type to save list
		call add(save_list, s:history_list[s:history_index].type)
		" Add line of cursor position in the quickfix list to save list
		call add(save_list, s:history_list[s:history_index].lnum)
		" Add number of items in quickfix list to save list
		call add(save_list, len(s:history_list[s:history_index].items))
		" Add each quickfix list item to save list
		for qfl_item in s:history_list[s:history_index].items
			call add(save_list, string(qfl_item))
		endfor
	endif

	" Redraw the screen
	redraw
	" Write history to file
	if writefile(save_list, fname) == 0
		echom 'sweetscope: History saved successfully to ' . fname
	else
		echom 'sweetscope: History not saved.'
	endif

	" Disable echo message highlighting
	echohl None
endfunc

" Load quickfix history from file
" If bang = 1 replace already existing history
func s:LoadHistoryFromFile(bang, ...)
	" Save current quickfix list
	call s:SaveCurrentQuickfixList()

	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" Determine file name
	let fname = s:sweetscope_history_file
	if len(a:000) > 0
		let fname = a:000[0]
	endif

	" Check if file readable
	if !filereadable(fname)
		echom "sweetscope: Can't load history from " . fname . ". File not readable."
		" Disable echo message highlighting
		echohl None
		return
	endif

	" Read file load list
	let load_list = readfile(fname)
	if empty(load_list)
		echom "sweetscope: Can't load history from " . fname . ". File is empty?"
		" Disable echo message highlighting
		echohl None
		return
	endif

	try
		" Get history file directory
		if fname[0] != '/'
			let history_file_dir = fnamemodify(getcwd() . '/' . fname, ':p:h')
		else
			let history_file_dir = fnamemodify(fname, ':p:h')
		endif
	
		" Define buffers correspondence dictionary
		let buf_cor = {}
		
		" Get dictionary of files with relative paths
		exe 'let rel_fnames = ' . load_list[0]
		" Load linked files with relative paths
		for key in keys(rel_fnames)
			let buf_name = history_file_dir . '/' . rel_fnames[key]
			" If file readable add buffer to correspondence dictionary.
			" If not will try to load same file again with absolute path further.
			if filereadable(buf_name)
				let buf_nr = bufnr(buf_name)
				" If buffer was not opened before
				if buf_nr == -1
					exe 'edit ' . buf_name
					let buf_nr = bufnr('%')
					" Delete opened buffer
					exe 'bdelete'
				endif
				" Add buffer number to correspondence dictionary
				let buf_cor[key] = buf_nr
			endif
		endfor

		" Get linked files pwd
		let buf_pwd = load_list[1]
		" Get dictionary of files with absolute paths
		" (buf_pwd + abs_fnames = absolute path)
		exe 'let abs_fnames = ' . load_list[2]
		" Load linked files with absolute paths
		for key in keys(abs_fnames)
			" If buffer has not been added yet
			if !has_key(buf_cor, key)
				" If path already absolute
				if abs_fnames[key][0] == '/'
					let buf_name = abs_fnames[key]
				else
					let buf_name = buf_pwd . '/' . abs_fnames[key]
				endif
				" If file readable add buffer to correspondence dictionary.
				if filereadable(buf_name)
					let buf_nr = bufnr(buf_name)
					" If buffer was not opened before
					if buf_nr == -1
						exe 'edit ' . buf_name
						let buf_nr = bufnr('%')
						" Delete opened buffer
						exe 'bdelete'
					endif
				" If file isn't readable just add stub to correspondence
				" dictionary
				else
					let buf_nr = 0
				endif
				" Add buffer number to correspondence dictionary
				let buf_cor[key] = buf_nr
			endif
		endfor

	" Get history list length
	let hist_len = eval(load_list[3])
	" Get history index
	let hist_idx = eval(load_list[4])

	" Define new history list
	let new_history_list = []
	" Get quickfix lists
	let list_i = 0
	let ll_i = 4
	while list_i <= hist_len - 1
		let qfl = {}
		" Get quickfix list title
		let qfl.title = load_list[ll_i + 1]
		" Get index of current entry in the quickfix list
		let qfl.idx = eval(load_list[ll_i + 2])
		" Get quickfix list type
		let qfl.type = eval(load_list[ll_i + 3])
		" Get line of cursor position in the quickfix list
		let qfl.lnum = eval(load_list[ll_i + 4])
		" Get number of items in quickfix list
		let items_num = eval(load_list[ll_i + 5])
		let qfl.items = []
		" Get quickfix list items
		let items_i = 0
		while items_i <= items_num - 1
			exe 'let item_dict = ' . load_list[ll_i + 6 + items_i]
			call add(qfl.items, item_dict)
			let items_i += 1
		endwhile
		call add(new_history_list, qfl)
		let list_i += 1
		let ll_i += 5 + items_num
	endwhile

	" Add stub quickfix list ids and correct buffer numbers in new history list
	let qfl_i = 0
	while qfl_i <= len(new_history_list) - 1
		let new_history_list[qfl_i].id = -1
		let qfl_items_i = 0
		while qfl_items_i <= len(new_history_list[qfl_i].items) - 1
			let new_history_list[qfl_i].items[qfl_items_i].bufnr =
						\ buf_cor[new_history_list[qfl_i].items[qfl_items_i].bufnr]
			let qfl_items_i += 1
		endwhile
		let qfl_i += 1
	endwhile

	if a:bang
		" Replace already existing history
		let s:history_list = deepcopy(new_history_list)
		let s:history_index = hist_idx
	else
		" Add new history to already existing
		" If user defined not duplicate quickfix lists
		if exists('s:sweetscope_noduplicate_qf') && s:sweetscope_noduplicate_qf
			for qfl in new_history_list
				call s:NoDuplicate_qf(qfl)
			endfor
		endif
		" Save previous history length and index
		let prev_hist_len = len(s:history_list)
		let prev_hist_idx = s:history_index
		" Add quickfix lists
		for qfl in new_history_list
			" If user defined open new quickfix lists after current one
			if exists('s:sweetscope_open_after_current')
						\ && s:sweetscope_open_after_current
						\ && s:history_index != -1
				let s:history_index += 1
				call insert(s:history_list, qfl, s:history_index)
			else
				call add(s:history_list, qfl)
				let s:history_index = len(s:history_list) - 1	
			endif
		endfor
		" Calculate new history index
		if exists('s:sweetscope_open_after_current')
					\ && s:sweetscope_open_after_current
			let s:history_index = prev_hist_idx + 1 + hist_idx
		else
			let s:history_index = prev_hist_len + hist_idx
		endif
		" Remove first quickfix lists if history limit is reached
		if exists('s:sweetscope_historylength')
			" Calculate lost quickfix lists
			let lost_qfls = len(s:history_list) - s:sweetscope_historylength
						\ - (s:history_index - hist_idx)
			" Remove excess quickfix lists
			while len(s:history_list) > s:sweetscope_historylength
				call remove(s:history_list, 0)
				let s:history_index -= 1
			endwhile
			" Report about lost quickfix lists
			if lost_qfls > 0
				echom 'sweetscope: ' . lost_qfls . ' quickfix lists are lost.'
							\ . ' Try to increase s:sweetscope_historylength value.'
			endif
		endif
		" Update numbers in titles of quickfix lists in history
		call s:UpdateNumbersInTitlesOfQuickfixListsInHistory()
	endif
	" Load current quickfix list
	let prev_hist_idx = s:history_index
	call s:OpenQuickfixAndLoadList()
	" Need to load quickfix list again because s:OpenQuickfixAndLoadList
	" function switch to already used quickfix and it is not alway that is
	" current in new_history_list.
	call s:LoadQuickfixListFromHistory(prev_hist_idx)

	catch 
		echoerr v:exception
		echom "sweetscope: Can't load history. Wrong file format?"
	finally
		" Disable echo message highlighting
		echohl None
	endtry
endfunc

" Interactive request to cscope db
" a:000[0] is pattern
" a:000[1] is query
func s:InteractiveRequest(...)
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" If query defined in command line
	if exists('a:000[1]')
		let chosen_query = a:000[1]
	" Request query interactively
	else
		echom 'cscope pattern: ' . a:000[0]
		echom '0 or s: Find this C symbol'
		echom '1 or g: Find this definition'
		echom '2 or d: Find functions called by this function'
		echom '3 or c: Find functions calling this function'
		echom '4 or t: Find this text string'
		echom '6 or e: Find this egrep pattern'
		echom '7 or f: Find this file'
		echom '8 or i: Find files #including this file'
		echom '9 or a: Find places where this symbol is assigned a value'
		let chosen_query = input('Type command or press ENTER to continue: ')
	endif

	" Check query
	if chosen_query ==# 's' || chosen_query ==# 'g' || chosen_query ==# 'd'
				\ || chosen_query ==# 'c' || chosen_query ==# 't'
				\ || chosen_query ==# 'e' || chosen_query ==# 'f'
				\ || chosen_query ==# 'i' || chosen_query ==# 'a'
				\ || chosen_query == '0' || chosen_query == '1'
				\ || chosen_query == '2' || chosen_query == '3'
				\ || chosen_query == '4' || chosen_query == '6'
				\ || chosen_query == '7' || chosen_query == '8'
				\ || chosen_query == '9'
		call s:Run_cscope(chosen_query, a:000[0])
	elseif chosen_query != ''
		echon "\r\r"
		echom ''
		echom 'Unknown cscope search type: ' . chosen_query
	endif

	" Disable echo message highlighting
	echohl None
endfunc

" Can populate quickfix with
" cex system("cscope -L -1 " . expand("<cword>"))<CR>
" but fills with trash too

" Run cscope by preferred method 
func s:Run_cscope(query, pattern)
	" Translate query to symbolic
	let query = s:NumToSymQuery(a:query)
	if exists('s:sweetscope_savehistory') && s:sweetscope_savehistory
		call s:SaveCurrentQuickfixList()
	endif
	if exists('s:sweetscope_runmethod') && s:sweetscope_runmethod
		call s:Run_cscopeWithCloseBuffer(query, a:pattern)
	else
		call s:Run_cscopeWithSell(query, a:pattern)
	endif
endfunc

" Translate numeric cscope query to symbolic
func s:NumToSymQuery(query)
	if a:query == '0' || a:query ==# 's'
		let query = 's'
	elseif a:query == '1' || a:query ==# 'g'
		let query = 'g'
	elseif a:query == '2' || a:query ==# 'd'
		let query = 'd'
	elseif a:query == '3' || a:query ==# 'c'
		let query = 'c'
	elseif a:query == '4' || a:query ==# 't'
		let query = 't'
	elseif a:query == '6' || a:query ==# 'e'
		let query = 'e'
	elseif a:query == '7' || a:query ==# 'f'
		let query = 'f'
	elseif a:query == '8' || a:query ==# 'i'
		let query = 'i'
	elseif a:query == '9' || a:query ==# 'a'
		let query = 'a'
	endif
	return query
endfunc

" Exec external command cscope with shell, treat output,
" close buffer opened by quickfix
func s:Run_cscopeWithSell(query, pattern)
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" Save current quickfix list
	call s:SaveCurrentQuickfixList()

	" Decode query
	let queryerr = 0
	if a:query == '0' || a:query == 's'
	   let querynum = '0'
  	elseif a:query == '1' || a:query ==# 'g'
	   let querynum = '1'
  	elseif a:query == '2' || a:query ==# 'd'
	   let querynum = '2'
  	elseif a:query == '3' || a:query ==# 'c'
	   let querynum = '3'
  	elseif a:query == '4' || a:query ==# 't'
	   let querynum = '4'
  	elseif a:query == '6' || a:query ==# 'e'
	   let querynum = '6'
  	elseif a:query == '7' || a:query ==# 'f'
	   let querynum = '7'
  	elseif a:query == '8' || a:query ==# 'i'
	   let querynum = '8'
  	elseif a:query == '9' || a:query ==# 'a'
	   let querynum = '9'
	else
		echoerr 'Query ' . a:query . ' not found.'
		let queryerr = 1
	endif
	let cmd = 'cscope -L -' . querynum . ' ' . a:pattern
	
	" Get cscope output
	let cmd_output = system(cmd)
	if cmd_output == ""
		echom 'sweetscope: No matches found for cscope query ' . a:query
					\ . ' ' . a:pattern
		echohl None
		return
	endif

	let tmpfile = tempname()
	let curfile = expand("%")

	exe "redir! > " . tmpfile
	if curfile != ""
		silent echon curfile . " dummy " . line(".") . " " . getline(".") . "\n"
	endif
	silent echon cmd_output
	redir END

	let old_efm = &efm
	set efm=%f\ %*[^\ ]\ %l\ %m

	" Save info about opened buffers
	let bufinfo = getbufinfo({'buflisted':1})
	" Save quickfix stack
	if exists('s:sweetscope_save_qf_stack') && s:sweetscope_save_qf_stack
		let qf_stack = s:SaveQuickfixStack()
	endif
	" Set no save quickfix buffer changes flag
	let s:nsqfc_flag = 1

	exe "silent! cfile " . tmpfile
	let &efm = old_efm

	" Restore quickfix stack
	if exists('s:sweetscope_save_qf_stack') && s:sweetscope_save_qf_stack
		call s:RestoreQuickfixStack(qf_stack)
	endif
	" save opened buffer number
	let opened_bufnr = bufnr('%')
	" open quickfix window, switch to previous buffer 
	" and go back to quickfix (order of commands is important)
	silent! cclose
	silent! botright copen
	exe 'wincmd p'
	exe "normal! \<C-O>"
	exe 'wincmd p'
	" check if atomatically opened buffer was opened before
	let noclose = 0
	for buf_i in bufinfo
		if opened_bufnr == buf_i.bufnr
			let noclose = 1
			break
		endif
	endfor
	" Close atomatically opened buffer
	if !noclose
		exe 'bdelete ' . opened_bufnr
	endif

	call delete(tmpfile)
		
	" Set initial quickfix list title
	call setqflist([], 'r', {'title': 'cs find ' . a:query . ' ' . a:pattern})

	" Make necessary manipulations with quickfix list and history after
	" cscope request
	call s:After_cscopeRequest()

	" Reset no save quickfix buffer changes flag
	let s:nsqfc_flag = 0

	" Disable echo message highlighting
	echohl None
endfunc

" Run native cscope and close automatically opened buffer
func s:Run_cscopeWithCloseBuffer(query, pattern)	
	" Clear current command line messages before search
	echon "\r\r"
	echon ''
	" Redraw the screen
	redraw
	" Enable echo message highlighting
	echohl SweetScopeEchoHL

	" Save current quickfix list
	call s:SaveCurrentQuickfixList()

	" Save info about opened buffers
	let bufinfo = getbufinfo({'buflisted':1})

	try
		" Save quickfix stack
		if exists('s:sweetscope_save_qf_stack') && s:sweetscope_save_qf_stack
			let qf_stack = s:SaveQuickfixStack()
		endif
		" Set no save quickfix buffer changes flag
		let s:nsqfc_flag = 1
		" run cscope
		exe 'cs find ' . a:query . ' ' . a:pattern
		" Restore quickfix stack
		if exists('s:sweetscope_save_qf_stack') && s:sweetscope_save_qf_stack
			call s:RestoreQuickfixStack(qf_stack)
		endif
		" save opened buffer number
		let opened_bufnr = bufnr('%')
		" open quickfix window, switch to previous buffer 
		" and go back to quickfix (order of commands is important)
    	silent! cclose
		silent! botright copen
		exe 'wincmd p'
		exe "normal! \<C-O>"
		exe 'wincmd p'
		" check if atomatically opened buffer was opened before
		let noclose = 0
		for buf_i in bufinfo
			if opened_bufnr == buf_i.bufnr
				let noclose = 1
				break
			endif
		endfor
		" Close atomatically opened buffer
		if !noclose
			exe 'bdelete ' . opened_bufnr
		endif
		
		" Make necessary manipulations with quickfix list and history after
		" cscope request
		call s:After_cscopeRequest()

	" If cscope has not found any matches
	catch /^Vim(cscope):E259:/
		echom 'sweetscope: No matches found for cscope query ' . a:query
					\ . ' ' . a:pattern
	catch 
		echoerr v:exception
	finally
		" Reset no save quickfix buffer changes flag
		let s:nsqfc_flag = 0
		" Disable echo message highlighting
		echohl None
	endtry
endfunc

" Make some manipulations with quickfix list and history after cscope request
func s:After_cscopeRequest()
	" Delete duplicate quickfix list items
	" if no duplicate quickfix list item option is setted
	if exists('s:sweetscope_noduplicate_items') && s:sweetscope_noduplicate_items
		" Get current quickfix list
		let qfl = getqflist(s:qf_saveitems)
		" Delete duplicates
		let qfl.items = s:NoDuplicate_qf_items(qfl.items)
		" Replace visiable quickfix list
		call setqflist([], 'r', qfl)
	endif

	" Save history
	if exists('s:sweetscope_savehistory') && s:sweetscope_savehistory
		" Add number to titles of visiable quickfix list
		call s:AddNumberToVisiableQuickfixListTitle(len(s:history_list) + 1,
					\ len(s:history_list) + 1)
		" Get current quickfix list
		let qfl = getqflist(s:qf_saveitems)
		" Add extra parameters to quickfix list dictionary
		let qfl.type = 0
		let qfl.lnum = 1
		" Add quickfix list to history
		call s:AddQuickfixListToHistory(qfl)
		" Update title of visiable quickfix list
		call setqflist([], 'a',
					\ {'title': s:history_list[s:history_index].title})
		" If user defined not clear quickfix stack
		if !(exists('s:sweetscope_clear_qf_stack')
					\ && s:sweetscope_clear_qf_stack)
			" Update titles of quickfix lists in stack
			if exists('s:sweetscope_searchopened') && s:sweetscope_searchopened
				call s:UpdateNumbersInTitlesOfQuickfixListsInStack()
			endif
		else
			" Clear quickfix stack
			call s:ClearQuickfixStack(1)
		endif
		" Set highlightings if required and not setted yet
		if s:search_hl && s:hl_match_id == -1 && s:search_expr != ''
			let s:hl_match_id = matchadd('SweetScopeSearchHL', s:search_expr)
		endif
	endif
	
"	" If quickfix list can be changed
"	if exists('s:sweetscope_save_qf_changes') && s:sweetscope_save_qf_changes
"		setlocal modifiable
"	endif
endfunc

" Save quickfix stack
func s:SaveQuickfixStack()
	let qf_stack = []
	let qfl_nr = 1
	" Scan all quickfix stack
	while qfl_nr <= getqflist({'nr': '$'}).nr
		call add(qf_stack, getqflist({'nr': qfl_nr, 'all': 1}))
		let qfl_nr += 1
	endwhile
	return qf_stack
endfunc

" Restore quickfix stack and add current quickfix list to it
func s:RestoreQuickfixStack(qf_stack)
	" Save current quickfix list
	let cur_qfl = getqflist({'all': 1})
	" Save cursor position
	let cur_cursor = getpos('.')
	
	" Free quickfix stack
	call setqflist([], 'f')
	
	" Restore quickfix stack
	for qfl in a:qf_stack
		" Create new quickfix list at the end of the stack
		call setqflist([], ' ', {'nr': '$'})
		" Replace quickfix list
		unlet qfl.id
		unlet qfl.nr
		" Set no save quickfix buffer changes flag
		let s:nsqfc_flag = 1
		call setqflist([], 'r', qfl)
	endfor

	" Add current quickfix list to stack
	call setqflist([], ' ', {'nr': '$'})
	unlet cur_qfl.id
	unlet cur_qfl.nr
	" Set no save quickfix buffer changes flag
	let s:nsqfc_flag = 1
	call setqflist([], 'r', cur_qfl)
	" Restore cursor
	call cursor(cur_cursor[1], cur_cursor[2])
endfunc

" Set number to title of current quickfix list
func s:AddNumberToVisiableQuickfixListTitle(num, all)
	let old_title = getqflist({'title':''}).title
	let new_title = old_title[0:6] . ' (' . a:num . ' of ' . a:all . ') '
				\ . old_title[8:]
	call setqflist([], 'a', {'title': new_title})
endfunc

" Update numbers in titles of quickfix lists in history list
func s:UpdateNumbersInTitlesOfQuickfixListsInHistory()
	let hl_i = 0
	while hl_i <= len(s:history_list) - 1 
		let old_title = s:history_list[hl_i].title
		let paren_i = stridx(old_title, ')')
		" If selection quickfix list
		if s:history_list[hl_i].type == 1
			let new_title = old_title[0:5] . ' ('. (hl_i + 1) . ' of '
						\. len(s:history_list) . ') ' . old_title[paren_i + 2:] 
		" If not selection quickfix list
		else
			let new_title = old_title[0:6] . ' ('. (hl_i + 1) . ' of '
						\. len(s:history_list) . ') ' . old_title[paren_i + 2:] 
		endif
		let s:history_list[hl_i].title = new_title
		let hl_i += 1
	endwhile
endfunc

" Update numbers in titles of quickfix in stack
func s:UpdateNumbersInTitlesOfQuickfixListsInStack()
	let qfl_items = deepcopy(s:qf_saveitems)
	let qfl_nr = 1
	while qfl_nr <= getqflist({'nr': '$'}).nr
		" Add quickfix list nr to getting quickfix list items
		let qfl_items.nr = qfl_nr
		" Find quickfix list with current nr in history
		let qfl = getqflist(qfl_items)
		unlet qfl.nr
		let qfl_hi = s:FindQuickfixListInHistory(qfl)
		if qfl_hi != -1
			call setqflist([], 'a', {
						\ 'nr': qfl_nr,
						\ 'title': s:history_list[qfl_hi].title})
		endif
		let qfl_nr += 1
	endwhile
endfunc

" Delete all cscope quickfix lists that contained in history from stack except
" last one if save_one_cscope_list = 1
func s:ClearQuickfixStack(save_one_cscope_list)
	" Save not listed in history and one cscope quickfix lists
	let saved_qfls = []
	let qfl_items = deepcopy(s:qf_saveitems)
	if a:save_one_cscope_list
		let cscope_qfl_i = -1
	endif
	let qfl_nr = getqflist({'nr': '$'}).nr
	" Scan all quickfix stack
	while qfl_nr >= 1
		" Get quickfix list with current nr
		let qfl_items.nr = qfl_nr
		let qfl = getqflist(qfl_items)
		unlet qfl.nr
		" If quickfix list is not contained in history
		if s:FindQuickfixListInHistory(qfl) == -1
			" Save quickfix list
			let qfl.context = getqflist({'nr': qfl_nr, 'context': 1}).context
			call add(saved_qfls, qfl)
		" If first cscope quickfix list not found yet
		elseif a:save_one_cscope_list && cscope_qfl_i == -1
			" Save empty dictionary instead of cscope quickfix list
			call add(saved_qfls, {})
			let cscope_qfl_i = len(saved_qfls) - 1
		endif
		let qfl_nr -= 1
	endwhile

	" Free quickfix stack
	call setqflist([], 'f')

	" Restore quickfix lists
	let qfl_i = len(saved_qfls) - 1
	while qfl_i >= 0 
		" Create new quickfix list at the end of the stack
		call setqflist([], ' ', {'nr': '$'})
		" If current quickfix list is cscope list
		if a:save_one_cscope_list && qfl_i == cscope_qfl_i
			" Replace quickfix list by current in history list
			let cscope_qfl = copy(s:history_list[s:history_index])
			unlet cscope_qfl.id
			" Set no save quickfix buffer changes flag
			let s:nsqfc_flag = 1
			call setqflist([], 'r', cscope_qfl)
		else
			" Replace quickfix list by current one
			unlet saved_qfls[qfl_i].id
			" Set no save quickfix buffer changes flag
			let s:nsqfc_flag = 1
			call setqflist([], 'r', saved_qfls[qfl_i])
		endif
		let qfl_i -= 1
	endwhile

	" Go to cscope quickfix list
	if a:save_one_cscope_list 
		let offset = cscope_qfl_i
		if offset > 0
			" Set no save quickfix buffer changes flag
			let s:nsqfc_flag = 1
			silent exe 'col ' . offset
		endif
	endif
endfunc
