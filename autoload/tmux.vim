if exists("g:autoload_tmux") && !exists("g:reload_autoload_tmux")
	finish
endif

let g:autoload_tmux = 1

function! tmux#execute(context, ...)
	call call(function("tmux#sendKeys"), [a:context] + a:000 + ["Enter"])
endfunction

function! tmux#sendKeys(context, ...)
	call call(function("tmux#run"), ["send-keys", a:context] + a:000)
endfunction

function! tmux#run(command, context, ...)
	let fullCommand = ["tmux"]

	" ==================================================
	" Inserts the options of tmux
	" ==================================================
	let allOptions = get(a:context, "options")
	if type(allOptions) == v:t_list && !empty(allOptions)
		let fullCommand += allOptions
	endif
	" //:~)

	let fullCommand += [a:command]

	" ==================================================
	" Inserts the flags of sub-command of tmux
	" ==================================================
	let allFlags = get(a:context, "flags")
	if type(allFlags) == v:t_list && !empty(allFlags)
		let fullCommand += allFlags
	endif
	" //:~)

	let fullCommand += a:000

	let result = system(join(fullCommand, " "))
	if v:shell_error != 0
		echoerr "TMux Error"
		throw result
	endif

	return trim(result)
endfunction

function! tmux#getContext(buf)
	return {
	\	"options": tmux#getOptions(a:buf),
	\	"flags": tmux#getFlags(a:buf)
	\ }
endfunction
function! tmux#getOptions(buf)
	if !exists("g:tmux_options")
		let g:tmux_options = []
	endif

	let allOptions = g:tmux_options[:]

	let bufOptions = getbufvar(a:buf, "tmux_options")
	if !empty(bufOptions)
		let allOptions += bufOptions
	endif

	return allOptions
endfunction
function! tmux#getFlags(buf)
	if !exists("g:tmux_flags")
		let g:tmux_flags = []
	endif

	let allFlags = g:tmux_flags[:]

	let bufFlags = getbufvar(a:buf, "tmux_flags")
	if !empty(bufFlags)
		let allFlags += bufFlags
	endif

	return allFlags
endfunction
