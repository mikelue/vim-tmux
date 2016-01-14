if exists("g:plugin_tmux") && !exists("g:reload_plugin_tmux")
	finish
endif

if exists('g:reload_plugin_tmux')
endif

let g:plugin_tmux = 1

let g:tmux_use_buffer_pane = 1

command! -complete=customlist,s:listCommands -nargs=+ Tmux call tmux#run(<q-args>)
command! -nargs=+ TmuxSendKeys call s:sendKeys(<q-args>)
command! -complete=shellcmd -nargs=+ TmuxExec call s:exec(<q-args>)

let s:ALL_TMUX_COMMANDS = [
	\ "append-selection", "attach-session",
	\ "bind-key", "break-pane",
	\ "capture-pane", "choose-buffer", "choose-client", "choose-session", "choose-tree", "choose-window", "clear-history", "clock-mode", "command-prompt", "confirm-before", "copy-mode",
	\ "delete-buffer", "detach-client", "display-message", "display-panes",
	\ "emacs-edit", "even-horizontal", "even-vertical",
	\ "find-window", "has-session", "history-limit", "if-shell", "join-pane",
	\ "kill-pane", "kill-server", "kill-session", "kill-window",
	\ "last-pane", "last-window",
	\ "link-window", "list-buffers", "list-clients", "list-commands", "list-keys", "list-panes", "list-sessions", "list-windows",
	\ "load-buffer", "lock-client", "lock-server", "lock-session",
	\ "main-horizontal", "main-vertical", "move-pane", "move-window", "new-session", "new-window", "next-layout", "next-window", "paste-buffer",
	\ "pipe-pane", "previous-layout", "previous-window", "refresh-client", "rename-session", "rename-window", "resize-pane", "respawn-pane", "respawn-window", "rotate-window", "run-shell",
	\ "save-buffer", "select-layout", "select-layout", "select-pane", "select-pane", "select-window", "send-keys", "send-prefix",
	\ "set-buffer", "set-environment", "set-option", "set-titles", "set-window-option",
	\ "show-buffer", "show-environment", "show-messages", "show-options", "show-window-options",
	\ "source-file", "split-window", "start-server", "suspend-client", "swap-pane", "swap-window", "switch-client",
	\ "unbind-key", "unlink-window", "vi-choice", "wait-for", "window-status-current-format"
\ ]

function! s:listCommands(ArgLead, CmdLine, CursorPos)
	let l:commandCount = len(split(a:CmdLine, '\s\+'))

	if commandCount <= 2
		if a:ArgLead == ""
			return s:ALL_TMUX_COMMANDS
		endif

		return filter(copy(s:ALL_TMUX_COMMANDS), 'v:val =~ "' . a:ArgLead . '"')
	endif

	return []
endfunction

function! s:sendKeys(args)
	call tmux#sendKeys(s:processArgs(a:args))
endfunction

function! s:exec(args)
	call tmux#exec(s:processArgs(a:args))
endfunction

function! s:processArgs(args)
	let resultArgs = a:args

	if g:tmux_use_buffer_pane == 1 && exists("b:tmux_pane")
		let resultArgs = printf("-t %s %s", b:tmux_pane, resultArgs)
	endif

	return resultArgs
endfunction
