@document.meta
    title: TODO
    description: 
    authors: dagle
    categories: 
    created: 2022-03-28
    version: 0.0.11
@end

Maybe load the message again before we send it to templates, because templates
are destructive atm

- Being able to reuse bindings from different views?

- make Galoremailto safe?

- mixminion support?

- keybase

- What is the semantics for folds in (n)vim? A fold is local to a buffer and window
-- With an api we could:
--- define folds on buffers and make it possible to make window-local folds
--- vim.api.nvim_buf_create_fold(buf, start, stop)
---- we can update a buffer in the background etc
--- Syntax highlighting in folds
--- Being able to run code on open

Maybe use a sliding reader that loads messages when you scroll instead of loading all messages

.ics support (then hand it off to provider?)
- Being able to view an ics
-- Parse an ics in lua
-- Use calendar-vim to display?
--- How to display multiple dates in different months/years etc?
--- How to display the clocks?
- Being able to import an ics (whole/partial)
-- A generalized interface to 

- [ ] Create a body-builder that can build a message from a template
-- [ ] Then make compose create such a template to create messages

* 0.0.1
  - [ ] Cleanup code
  - [ ] Clunky stuff, setup etc

* 0.0.2
Todo: Tests, (hooks, templates, compose), documentation, logging

- [x] being able to read different versions of a message

- [ ] Missing decrypt and verify for message part
- [ ] Parts could be keys, are they attachments?

- [ ] tag undo
-- [ ] Should it be local to browser or global? Lets assume local
-- [ ] Save a history of {ids, "changes"}
- [ ] excluded tags when showing a thread and in tmb
- [ ] resend?
- [ ] Refresh all buffers
- [ ] Fold long headers

- Logging 
- [ ] Todo, log more stuff?

- Make the test framework actually work
- [ ] Test all util functions
- [ ] Test sign/crypt in builder
- [ ] Templates
- [ ] Add test for (integration tests):
-- [ ] Autocrypt tests
-- [ ] Buffer specific tests: saved, tmb, mb, tb, mv, tv, compose
--- [ ] Saved create a view with all generators and make sure the output and state is correct
--- [ ] Test sending email to a dummy inbox (with an attachment), checkoutput
--- [ ] Test draft
--- [ ] Testing that sending is async and doesn't use more mem then the pipe.
(--- [ ] Create a browser and make sure it creates the correct folds)
-- [ ] Buffer generic
--- [ ] Push all default keybindings making sure that it doesn't crash
- [ ] Profiling, cpu and memory

- Wrap functions? Config is a bit long atm 

(
-- [ ] Can we add/delete dias the future?
-- [ ] Being able to select the whole line instead of 100 atm.
)

- [ ] Callbacks for checking signatures: Can we do this in another thread or something
- [ ] add options for buffer-stuff: buffer should be listed, hidden etc?
-- Mostly for floating terms?
-- Should this be configuerable?

- [ ] documentation
-- [ ] Read the Emmy page!
-- use @alias for enums
-- [ ] Write types for everything
-- [ ] Use the correct types in documentation

- [ ] A nicer way to do buffer commands? How do we avoid adding 100 commands?
-- [ ] Can we collect the arguments?

(
- [ ] Decouple notmuch.lua
- [ ] ref-pointers and if we are using dangling pointers/leaking memory

-- [ ] Notmuch
--- [x] Finish OO bindings
--- [ ] Tests
)

- Async handling
- [ ] Register all async runners (so we can cancel them)
- [ ] Create a register function
-- [ ] What info do we neeed on the runners? Just a name and a handle
- [ ] Make a ui to be able to cancel jobs / timers

- [ ] Cleanup
-- [ ] Cleanup util, it's horrible
-- [ ] cleanup all (compose, util, template etc)
-- [ ] Move mime-preview and mime-view etc
-- [ ] FIXME and XXX
-- Iterators in util
-- Fix and test builder, and secure
-- Do we still get an extra line into body?

- [ ] Being able to recreate the mutt UI
-- [ ] A window can have a child?
-- [ ] Make a general way to make movements from message_view

- [ ] Templates 
-- [x] How to deal with the body of a message
-- [x] How to add the -- Forward Message --- part? Or not?
-- [ ] Being able to send a template without doing a compose
-- [ ] Clean up and test (then done)
-- [ ] A way to interact with the templates and set values (through opts)


- [ ] Builder
-- [ ] Cleanup (esp encryption and signing), better failing
-- [ ] Testing
-- [ ] Document what should/could be in each variable

- Make the builder more like template/render?
-- Being able to change builder at runtime?
-- builders should be composable

- [ ] Compose
-- [ ] Make compose work on table in and tables out and then for builder to use that table
--- Makes it easier to chain composes and should have the same interface as builder
-- [ ] Headers should be able to do multiline fields
--- [ ] Can we make cmp modules work correctly with multiline?
-- [ ] Concat multiple Adresses instead of overwriting them

Compose mode:
- [ ] Custom headers, add to builder (add to config or should we just do it in init?)

========================
* 0.0.3

- optional dsn support! off by default and very optional
-- Alternate-Recipient

-- Batch-mode

- later!
Use fs_poll from vim.loop to update wins?

- Functions to do add the selected email address to an addressbook.

- Being able to respond to html emails, with correct qouting etc

- Mime-type config (/etc/mime.types)?
- Make a neo-view tool/function/module? Or just use xdg-open?
-- xdg-open seems better
-- save tmpfiles and register them until deleted? Is this safe?

-- autoview
-- Being able to add autoviews
-- [ ] Support more than just html

- [ ] User defined templates

- [ ] Attaching a directory could automatcally create a tar.gz of the directory

-- [ ] Compose to sender

- [ ] Progressbar for async stuff?

- [ ] header_diagnostics 
-- [ ] A function to parse an adresses, return a iterator that returns an email
 and (position and end), so we can do diagnostics for addresses
-- [ ] A way to add diagnostics for failed email addresses
-- [ ] A way to add diagnostics for failed gpg keys (connected to email addresses)

- [ ] Mark as read-delay 
-- You have to have a mail open for at least 5 seconds before we count it as read
-- This is only an example, a good api should make this easy to implement this correctly.

- [ ] Partial renders

- [ ] Change colors for attachments, filter attachments etc depending on rules

- [ ] From shouldn't search address book but only our addresses.

- [ ] A send-buffer command

- [ ] Spell detection? Learn how spell works in vim first

- [ ] Treesitter syntax, for better control, for embeded syntax and navigation
- [ ] A way to close the window if it's the last one

- [ ] Finish AU
--- almost done, take a break from this ----
  - [ ] Autocrypt headers support
  --- When to add key? When we open an email, when we reply, never?
  -- [ ] If we reply to an email with an autocrypt
  --- Add to keyring for the future?
  --- Encrypt the response
  -- [ ] Add autocrypt header to our messages
  -- [ ] History so we can uncrypt old messages?
  use g_mime_crypto_context_register

-- libmagic?

- [ ] setopts instead of config
- [ ] Something like nvim-treesitter-context? For headers, maybe 

-- Mailinglist functions
-- ListArchive, ListHelp, ListId, ListOwner, ListPost, ListSubscribe, ListUnsubscribe,

- [ ] select action, change on thread, change on select etc
- [ ] Thread view / entire-thread
-- [ ] Opening a thread in thread view should scroll it to the current unread email
-- [ ] When replying in a thread view, we should reply to the correct message

-- [ ] Delete draft when sent

- [ ] Error handling in notmuch/Make a status handler for notmuch
- [ ] Multiselect?
- [ ] Revise diagnostics
- [ ] Use an opt based system instead of a static config
-- [ ] Fix diagnostics for update 

- [ ] Being able to reindex message (esp for decrypted messages)
-- How should this be done? Do we need to edit the file? 
-- If we need to decrypt this forever, we can just let notmuch do this?

- [ ] add an opt for show_presearch that moves presearch into default_text
-- [ ] add an "and" by default? Maybe a setting?

- [ ] Support "raw actions" etc?
-- [ ] Buffer and global?
-- [ ] Actions: Tags
-- [ ] Incremental support?

- [ ] Slowdowns and ui
-- [ ] Render the message/tmb async?
--- [ ] Being able to cancel and limit searches
-- [ ] Render everything async? (Does that even make sense?)
-- [ ] Can we reuse the filters (or at least most parts)?

- [ ] Managed windows, a way to update windows and 
-- [ ] Re-implement the mutt-ui.

- [ ] Rewrite notmuch-rs, the state of the lib is meh, maybe

- [ ] Don't assume utf8 but convert from and to the charset in vim?

- [ ] Doing GaloreNew should be able to update UI?


- [ ] Make different tiers, so it's easier to lazy load more of the code etc
- [ ] Different kind of builder modes
- [ ] A way to format markdown, neorg etc and get html

- [ ] Fcc outside of notmuch, not in 0.1
-- [ ] Make fcc automatically detect if it should insert or not, abs path vs relative

- [ ] Add limit and offset to searches.
- [ ] Make Gmime iterator stateless

- [ ] Add support other encryption methoods
- [ ] Add support for sq to gmime?

- [ ] Modular design: 
-- [ ] cmp
-- [ ] autocrypt
-- [ ] telescope
-- [ ] ...

- [ ] Telescope
-- [ ] Make it an plugin for searching with a telescope extension
-- [ ] When the terminal gets media support
--- [ ] Make preview telescope with media view?
--- [ ] Make a picker that can display both images and text
-- [ ] Use telescope for select_attachment, so we can preview the attachment
--- Set a limit for attachments over x-mb

  - [ ] Non-standard headers: ‘Mail-Reply-To’, ‘Mail-Followup-To’
  - [ ] Template system
  -- [ ] Responds to mailing list
  -- [ ] Forwarding a message and add the passed tag the message

  -- Easy to use
  -- Easy to write rules
  -- Reply, reply-all, compose to sender, compose, forward, unsubsribe

  - [ ] Is it worth doing your own gpg functions instead of adding the keys into a autocrypt keyring?

lsp for emails?!
-- hover?
-- completion?
-- symbols?
-- references? (I think not)
-- formating? rangef?

- 0.4 
- LSP/LATER
- [x] A way to see if all our to, cc, bcc are in the keyring
- [ ] make it easier to extend, so you can use virtual_text to display verified keys
	(works but not for autocrypt, todo)
- [ ] Solves the problem of callback hell

- RIIR?
-- The whole plugin?
-- Without making the config less powerful?
-- Without making anything less powerful/configable/dynamic
-- What does it solve?
-- Only make producers in rust? (Or C?)
--- Speed ups? Can't we just rewrite stuff in C?
--- No callback problems?


- Go through https://www.rfc-editor.org/rfc/rfc4021.html#section-2.1 once more
- Easy ways to generate these headers
-- Comments?
-- Keywords support?

gmime stuff:
Mail-Reply-To support?
Add support for sq to gmime?
Fix the password thing for gpg

-- unprotected error in call to Lua API (bad callback), REMOVE ALL CALLBACKS from ffi
Remove callbacks from parsing methods, because callbacks are bad-mkay

((
- [ ] Different parser options
- [ ] This is bad! This is all callbacks!
-- [ ] render_parser_options (the current one, mark as done when logging is done)
-- [ ] build_parser_options
-- [ ] diagnostic_parser_options
))

-- [ ] A sister plugin for outlook support
