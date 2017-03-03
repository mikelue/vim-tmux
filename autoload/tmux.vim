if exists("g:autoload_tmux") && !exists("g:reload_autoload_tmux")
	finish
endif

let g:autoload_tmux = 1

" Use tmux send-key <a:cmd> Enter to execute a command
function! tmux#exec(cmd)
	call tmux#sendKeys('C-[', 'cc')
	call tmux#sendKeys(printf("-l %s", shellescape(a:cmd)))
	call tmux#sendKeys('Enter')
endfunction
function! tmux#sendKeys(...)
	call tmux#run(printf("send-keys %s", join(a:000, ' ')))
endfunction

function! tmux#run(content)
	let result = system(printf("tmux %s", a:content))
	if v:shell_error != 0
		echoerr "TMux Error"
		throw result
	endif

	return result
endfunction
