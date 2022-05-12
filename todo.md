@document.meta
    title: TODO
    description: 
    authors: dagle
    categories: 
    created: 2022-03-28
    version: 0.0.11
@end

Ideas: 
  - [ ] Select multiple messages for cb
  -- No, this isn't vim-ish
  -- Can we search/match, can we add our own match() search mode? 
  -- Can we do object matching?
  -- Can we do movement?

  - Note: Use folds in the future?
  -- Currently the fold api is not what we want, maybe in the future
  -- Pros: Searches will work, selecting will work, goto works, nested folds, builtin movement,
  -- Don't write more code that depends on the current fold method


* 0.0.1
  - [ ] Cleanup code
  - [x] sort saved
  - [x] Unify the attachments api
  -- Cycles in requires, use "uml" to get it correct?
  - [ ] Clunky stuff, setup etc
  - [x] Init
  - [ ] Don't loose a compose, set better name etc
  -- How to make this not annoying:
  -- Shouldn't warn if the buffer have been saved to draft or sent etc

  - [x] Fix builder
  -- [x] Rename to builder
  -- [x] Generate a correct email
  - [x] Set headers? Or is that up to sendmail? 
  -- [x] Message id? Makes both send and save draft easier
  -- [x] Have an opts to set return-path etc, maybe move ref to this?
  -- [x] Return-Path
  -- [x] Reply-To
  -- [x] Registering to saved

* 0.0.2
today: 
-- A way to see if all our to, cc, bcc are in the keyring
-- Use nvim_buf_create_user_command 
-- Finish autocrypt
-- Make callbacks into categories? require("galore.callback").browser?

  - [x] Guard against untagged messages: No tags => +archive?
  - [-] Render multipart messages
  -- [ ] Not tested

  - [x] Commands / Finding the class from a bufnum?
  - [x] Remove everything in global
  - [x] https://efail.de/ secure, only render html in non-encrypted emails
  - [x] Pipes, pipe keys, git am etc.
  -- [ ] Test it, do we actually need all of that?

  - [-] Searching
  -- [-] Highlight messages matching description
  -- [x] Movement between matches
  - [x] Highlights etc, explore options <- Make a proof of concept
  -- [x] Being able to control what is highlighted
  -- [x] For matches messages in tmb
  -- [x] Being able to move between matched.
  -- [x] match-face, underline the match?

  - [-] Notmuch saved queries 
  -- [x] Being able to save queries and write them to notmuch config
  -- [x] Easy way to create new queries or should we rely on telescope?
  -- [x] How easy is it to build on an old search, can we help?
  --- Toy around with ideas to do this in a good way

  - [x] Make a directory for all of files etc and don't polute the data directory.

--- almost done, take a break from this ----
  - [ ] Autocrypt headers support
  --- When to add key? When we open an email, when we reply, never?
  -- [ ] If we reply to an email with an autocrypt
  --- Add to keyring for the future?
  --- Encrypt the response
  -- [ ] Add autocrypt header to our messages
  -- [ ] History so we can uncrypt old messages?
  use g_mime_crypto_context_register

--------
Compose mode:
  https://www.gnu.org/software/emacs/manual/html_mono/message.html
  - [ ] Missing headers in sending?
  -- [x] Why is the buffer edited, how do we fix this

  -- Create a tmp file? That way, if we don't do anything, we don't need to save etc
  - [x] After a send, we should mark it as written
  - [ ] Don't double decrypt
  - [ ] Don't qoute an decrypt that we can't encrypt

  - [ ] Have a way to indicate that we are sending an encrypted email?
  - [ ] Custom headers

  -- [ ] When we create a compose, we don't take the original message 
	but we generate a new one from the buffer, apply hooks on that, generate a file
	and then send that to compose? That way we get the power of vim and gmime?
	We need the headers from the original message though.

 -- Content-builder system:
 --- the builder should do the healy lifting but you should be able to use different
 --- content-builders, that way we can have html-mode etc

 - Things in opts:
 -- Reply

  -- On send, do hooks like:
  --- [x] Unset modified
  ---- Hooks, close buffer on send?
  --- make message stand-alone
  --- mailing lists (MFT support)
  --- All the config options

  - Annoying:
  - [ ] Hooks, where and why? (init, send, sent ...)
  - [ ] FIXME and XXX
  - [ ] Why does tab before enter in save make searches fail?
   -- seems to be because of m being bound
  - [ ] Fix Subject names, can we convert these to unicode, we still need to sub newline.

  - [ ] Telescope
  -- [ ] Make it less clunky to use/costumize
  -- [ ] Split everything up, thing that isn't telescope should be moved

  -- [ ] Can we make it into a telescope extension?
  -- [ ] Remove presearch and just use default_text?
  --- [ ] add an "and" by default? Maybe a setting?

  - [ ] Autocmd and UI
  -- Parts

  - [ ] Use a window for attachments
  -- Doesn't scroll correctly, maybe a bad idea?

  - [ ] Remove all commands and use vim.api.nvim_buf_create_user_command

  - [x] Do snippets for aliases

  - [x] Closing a window with q or :q should be the same?
  -- And it doesn't do that now? Be specific.

  -- Should we list buffers etc
  -- What about compose? How do we not lose data? (:wq to send?)

  - [x] Email groups, maybe this is vcard?
  --- How the fuck do I use groups?
  - [x] Write an example using khards
  - [x] Write an example using pipe and mates
  
  - [ ] Add opts to config so simple customizations doesn't require you to rewrite code
  - [ ] Use telescope when selecting parts and attachments
  -- [ ] Make preview telescope with media view?

  - [ ] A way to close the window if it's the last one

  - [ ] Add tests to the project that actually work
  - [ ] Benchmark, dunno if galore is that slow but we need to benchmark

  - [ ] Being able to reindex message (esp for decrypted messages)
  -- How should this be done? Do we need to edit the file? 
  -- If we need to decrypt this forever, we can just let notmuch do this?

  -- Mailinglist functions
  -- ListArchive, ListHelp, ListId, ListOwner, ListPost, ListSubscribe, ListUnsubscribe,

  - [ ] Slowdowns:
  -- [ ] Render the buffers async?
  -- [ ] Render everything async? (Does that even make sense?)
  -- [ ] Can we reuse the filters (or at least most parts)?
  -- [ ] Can we reuse the same crypto ctx?
  -- [x] Verify async

* 0.0.3 
  - Out of scope:
	  - [ ] Managed windows
	  - [ ] Rewrite notmuch-rs, the state of the lib is meh, maybe

  - [ ] Don't assume utf8 but convert from and to the charset in vim?

  - [ ] Doing GaloreNew should be able to update UI?

  - [ ] Decouple notmuch.lua and gmime.lua to their own projects

  - [ ] Make different tiers, so it's easier to lazy load more of the code etc
  - [ ] Different kind of builder modes
	- [ ] A way to format markdown, neorg etc and get html

  - [ ] Fcc outside of notmuch, not in 0.1
  -- [ ] Make fcc automatically detect if it should insert or not, abs path vs relative

  - [ ] Add limit and offset to searches.
  - [ ] Make Gmime iterator stateless

  - [ ] Add support other encryption methoods
	- [ ] Add support for sq to gmime?

  - [ ] Move tmb to folds
  - [ ] Make the buffer class into buffer variable

  - [ ] Modular design: 
  -- [ ] cmp
  -- [ ] autocrypt
  -- [ ] telescope
  -- [ ] ...

  - [ ] Non-standard headers: ‘Mail-Reply-To’, ‘Mail-Followup-To’
  - [ ] Template system
  -- [ ] Responds to mailing list
  -- [ ] Forwarding a message and add the passed tag the message

  -- Easy to use
  -- Easy to write rules
  -- Reply, reply-all, compose to sender, compose, forward, unsubsribe

  - [ ] Is it worth doing your own gpg functions instead of adding the keys into a autocrypt keyring?
