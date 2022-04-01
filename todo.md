@document.meta
    title: TODO
    description: 
    authors: dagle
    categories: 
    created: 2022-03-28
    version: 0.0.11
@end

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
  - [ ] Missing headers in sending?
  - [ ] Can we make it so that we don't have to decrypt the message twice?
  - [ ] Maybe filter the whole message?
  - [ ] Highlights, maybe don't link?
  - [ ] Responds to mailing list
  - [ ] Hooks, where and why? (init, send, sent ...)
  - [ ] Template system
  -- Easy to use
  -- Easy to write rules
  -- Reply, reply-all, compose to sender, compose, forward, unsubsribe
  - [-] Notmuch saved queries 
  -- [x] Being able to save queries and write them to notmuch config
  -- [x] Easy way to create new queries or should we rely on telescope?
  -- [ ] How easy is it to build on an old search, can we help?
  - [ ] Commands / Finding the class from a bufnum?
  - [ ] Autocmd and UI
  -- Parts
  -- Closing a window with q or :q should be the same?
  -- Should we list buffers etc
  -- What about compose? How do we not lose data? (:wq to send?)
  - [ ] AutoEncrypt headers support
  - [ ] Email groups, maybe this is vcard?
  -- [ ] Being able to add vcards, groups etc
  - [ ] https://efail.de/ secure, only render html in non-encrypted emails
  - [ ] Benchmark, dunno if galore is that slow but we need to benchmark
  - [ ] Generalized movement
  - [ ] Make standard functions
  - [ ] Guard against untagged messages: No tags => +archive?
  - [ ] Add tests to the 
  - [ ] Subfilters
  - [ ] Update so we get the index of the mail in
  - [ ] match-face, underline the match?
  - [ ] More global functions: Quit
  - [ ] Pipes, pipe keys, git am etc.
  - [ ] Add opts to config so simple customizations doesn't require you to rewrite code
  - [ ] Forwarding a message and add the passed tag the message
  - [ ] Being able to render trees in reverse
  - [ ] Diagnostics
  -- [ ] For matches messages in tmb
  -- [ ] Being able to move between Diagnostics: Next matched, next unread, etc
  - [ ] Fix Subject names, can we convert these to unicode, we still need to sub newline.

  - [ ] Slowdowns:
  -- [ ] Render the buffers async?
  -- [ ] Render everything async? (Does that even make sense?)
  -- [ ] Can we reuse the filters (or at least most parts)?
  -- [ ] Can we reuse the same crypto ctx?
  -- [ ] Verify async

* 0.3 
  - [ ] Don't assume utf8 but convert from and to the charset in vim?
  - [ ] Managed windows
  - [ ] Doing GaloreNew should update the UI
  - [ ] Rewrite notmuch-rs, the state of the lib is quite horrible
  - [ ] Decouple notmuch.lua and gmime.lua to their own projects
  - [ ] Make different tiers, so it's easier to lazy load more of the code etc
  - [ ] A mml mode?
  - [ ] Fcc outside of notmuch, not in 0.1
  -- [ ] Make fcc automatically detect if it should insert or not, abs path vs relative
  - [ ] A way to format markdown, neorg etc and get html
  - [ ] Add limit and offset to searches.
  - [ ] Gmime iterator stateless
  - [ ] Add support other encryption methoods
  - [ ] Add support for sq to gmime?

  - [ ] Non-standard headers: ‘Mail-Reply-To’, ‘Mail-Followup-To’
