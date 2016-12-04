![vim-sayonara](https://github.com/mhinz/vim-sayonara/blob/master/image/sayonara.png)

This plugin provides a single command that deletes the current buffer and
handles the current window in a smart way.

Basically you don't have to think in terms of `:bdelete`, `:close`, `:quit` etc.
anymore. The plugin does that for you.

It reduces cognitive load and lets you focus on the main task: editing text.

    :Sayonara

This deletes the current buffer and closes the current window.

    :Sayonara!

This deletes the current buffer and preserves the current window.

## Installation and Documentation

Use your [favorite plugin
manager](https://github.com/mhinz/vim-galore#managing-plugins), e.g.
[vim-plug](https://github.com/junegunn/vim-plug):

    Plug 'mhinz/vim-sayonara', { 'on': 'Sayonara' }

Read `:h sayonara` for more information about this plugin.

## Details

First of all, `:Sayonara` or `:Sayonara!` will only delete the buffer, if it
isn't shown in any other window. Otherwise `:bdelete` would close these windows
as well. Therefore both commands always only affect the current window. This is
what the user expects and is easy reason about.

If the buffer contains unsaved changes, you'll be prompted on what to do.

#### :Sayonara

    * mark current buffer
    * current window is the only window in current tabpage?
      true  => is there only one tabpage?
               true  => are there any other active buffers?
                        true  => switch to most recently used active buffer
                        false => Is g:sayonara_confirm_quit set?
                                 true  => confirm whether to quit Vim
                                 false => quit Vim
               false => close tabpage
      false => close window
    * delete marked buffer unless it is shown in any other window

#### :Sayonara!

    * mark current buffer
    * are there any other active buffers?
      true  => switch to most recently used active buffer
      false => create an empty scratch buffer
    * delete marked buffer unless it is shown in any other window

If a window with an associated location-list is closed, the location list will
be closed as well.

## Isn't this the same as bufkill?

No.

The biggest difference is that bufkill doesn't handle other windows and
tabpages at all, so if you try to delete a buffer that is also shown in another
window, multiple windows will be closed. Sayonara is more predictable in this
regard, and, if at all, only closes the current window.

Bufkill also doesn't handle associated location lists.

Sayonara simply handles more corner cases and tries to make one command always
Do The Right Thing whereas bufkill provides multiple commands so you always
have to think about what you're trying to do.

## Feedback

If you like this plugin, star it! It's a great way of getting feedback. The same
goes for reporting issues or feature requests.

Contact: [Twitter](https://twitter.com/_mhinz_)
