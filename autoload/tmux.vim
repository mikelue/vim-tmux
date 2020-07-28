if exists("g:autoload_tmux") && !exists("g:reload_autoload_tmux")
	finish
endif

let g:autoload_tmux = 1

" Context supported:
" ========================================
" attributes supported of Tmux context:
" "os_subsystem": - (optional)subsystem prefix of tmux command(like WSL)
" 	$os_subsystem tmux ...
" "options": - (optional) Options for tmux program
" 	tmux $options ...
" "flags": - (optional) Arguments for executing Tmux command
" 	tmux <command> $flags
"
" functions supported of Tmux context:
" "getFlags()" - gets flags(as list)
" ========================================
function! tmux#sendKeys(context, ...) abort
	let SendKeysFunc = function("tmux#run", ["send-keys", a:context] + a:000)
	call SendKeysFunc()
endfunction

function! tmux#sendToCopyMode(context, ...) abort
	let context = a:context.addFlagByDeepCopy("-X")
	let SendCmd = function("tmux#run", ["send-keys", context] + a:000)
	call SendCmd()
endfunction

function! tmux#chdirOfCurrentPane(context, path) abort
	let checkExpr = [ printf('[ "#{pane_current_path}" != "%s" ]', a:path) ]
	let chdirCmd = printf('"cd %s"', a:path)

	let trueCmd = a:context.buildCmdWithFlags("send-keys") + [ chdirCmd, "Enter" ]

	call tmux#ifShell(a:context, checkExpr, trueCmd)
endfunction

function! tmux#ifShell(context, shellCmd, trueCmd, falseCmd=[]) abort
	let shellCmd = printf('bash -c "%s"', escape(join(a:shellCmd, " "), '"'))
	let trueCmd = join(a:trueCmd, " ")
	let falseCmd = join(a:falseCmd, " ")

	let ifShellArgs = [shellCmd, trueCmd]
	if falseCmd != ""
		call add(ifShellArgs, falseCmd)
	endif

	let IfShell = function("tmux#run", ["if-shell", a:context] + ifShellArgs)
	return IfShell()
endfunction

" Clean current bash line and execute command
function! tmux#executeShellLine(context, ...) abort
	" ==================================================
	" Cancel copy mode if the pane is under the mode
	" ==================================================
	call tmux#cancelCopyMode(a:context)
	" //:~)

	" ==================================================
	" Clean text of current command line
	" ==================================================
	let escapedCmd = s:escapeArgs(a:000)
	call tmux#sendKeys(a:context, "^[", "^cc", join(escapedCmd, " "), 'Enter')
	" //:~)
endfunction

function! tmux#cancelCopyMode(context) abort
	let compareExpr = ['[ "#{pane_mode}" == "copy-mode" ]']
	let trueCmd = a:context.buildCmdWithFlags("send-keys") + [ "-X", "cancel" ]

	call tmux#ifShell(a:context, compareExpr, trueCmd)
endfunction

function! tmux#getVar(context, varName) abort
	let context = a:context.addFlagByDeepCopy("-p")
	return tmux#run("display-message", context, printf("#{%s}", a:varName))
endfunction
function! tmux#getFormat(context, format) abort
	let context = a:context.addFlagByDeepCopy("-p")
	return tmux#run("display-message", context, a:format)
endfunction

function! tmux#run(command, context, ...) abort
	let fullCommand = a:context.buildTmuxCmd()
	let fullCommand += a:context.buildCmdWithFlags(a:command)
	let fullCommand += a:000
	let fullCommand = s:escapeArgs(fullCommand)

	call s:log("Run: %s", join(fullCommand, " "))
	return s:executeSystem(join(fullCommand, " "))
endfunction

" Run command sequence, which connect multiple Tmux command with '; '
" See help of Tmux
"
" Every a:000 is an array of comand and arguments
"
" For example:
" call tmux#runSequence(context, ['send-keys', 'aa'], ['send-keys', 'bb'])
function! tmux#runSequence(context, ...)
	let applyContextCmds = []
	for cmd in deepcopy(a:000)
		let cmdWithContext = a:context.buildCmdWithFlags(cmd[0])
		if len(cmd) >= 1
			let cmdWithContext += cmd[1:]
		endif

		call add(applyContextCmds, cmdWithContext)
	endfor

	let expandedCmds = []
	for cmd in applyContextCmds
		let cmd = s:escapeArgs(cmd)
		call extend(expandedCmds, cmd)
		call add(expandedCmds, '\; ')
	endfor
	call remove(expandedCmds, len(expandedCmds) - 1)

	let fullCommand = a:context.buildTmuxCmd() + expandedCmds

	return s:executeSystem(join(fullCommand, " "))
endfunction

function! tmux#getOsSubsystem(buf) abort
	if !exists("g:tmux_os_subsystem")
		let g:tmux_os_subsystem = ""
	endif

	let osSubsystem = g:tmux_os_subsystem

	let bufOsSubsystem = getbufvar(a:buf, "tmux_os_subsystem")
	if !empty(bufOsSubsystem)
		let osSubsystem = bufOsSubsystem
	endif

	return osSubsystem
endfunction
function! tmux#getOptions(buf) abort
	if !exists("g:tmux_options")
		let g:tmux_options = []
	endif

	let allOptions = deepcopy(g:tmux_options)

	let bufOptions = deepcopy(getbufvar(a:buf, "tmux_options"))
	if !empty(bufOptions)
		let allOptions += bufOptions
	endif

	return allOptions
endfunction
function! tmux#getFlags(buf) abort
	if !exists("g:tmux_flags")
		let g:tmux_flags = []
	endif

	let allFlags = deepcopy(g:tmux_flags)

	let bufFlags = deepcopy(getbufvar(a:buf, "tmux_flags"))
	if !empty(bufFlags)
		let allFlags += bufFlags
	endif

	return allFlags
endfunction

function! tmux#getContext(buf) abort
	return {
	\	"os_subsystem": tmux#getOsSubsystem(a:buf),
	\	"options": tmux#getOptions(a:buf),
	\	"flags": tmux#getFlags(a:buf),
	\	"addFlagByDeepCopy": function("s:context_AddFlagByDeepCopy"),
	\	"addOptionByDeepCopy": function("s:context_AddOptionByDeepCopy"),
	\	"buildCmdWithFlags": function("s:context_BuildCmdWithFlags"),
	\	"buildTmuxCmd": function("s:context_BuildTmuxCmd"),
	\ }
endfunction
function! <SID>context_AddFlagByDeepCopy(...) dict abort
	let newDict = deepcopy(self)

	let newDict.flags += a:000
	return newDict
endfunction
function! <SID>context_AddOptionByDeepCopy(...) dict abort
	let newDict = deepcopy(self)

	let newDict.options += a:000
	return newDict
endfunction
function! <SID>context_BuildCmdWithFlags(cmd) dict abort
	return [a:cmd] + self.flags
endfunction
function! <SID>context_BuildTmuxCmd() dict abort
	let cmd = ["tmux"] + self.options

	if self["os_subsystem"] != ""
		call insert(cmd, self["os_subsystem"])
	endif

	return cmd
endfunction

function! <SID>executeSystem(cmd) abort
	let result = system(a:cmd)

	if v:shell_error != 0
		echoerr printf("[TMux Error] %s:", result)
		echoerr a:cmd
		throw "Tmux error"
	endif

	return trim(result)
endfunction
function! <SID>escapeArgs(cmd) abort
	let command = a:cmd[0:0]
	let cmdArgs = map(a:cmd[1:], { _, val -> val =~ '\%\([''"#$]\|\s\)' ? shellescape(val) : val })

	return command + cmdArgs
endfunction
function! <SID>log(format, ...) abort
	if !exists("g:tmux_debug") || g:tmux_debug == 0
		return
	endif

	let PLog = function("printf", [a:format] + a:000)
	echo PLog()
endfunction
