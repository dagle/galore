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
  - [x] Guard against untagged messages: No tags => +archive?
  - [-] Render multipart messages
  -- [ ] Not tested

  - [ ] After a send, we should mark it as written
  -- [ ] Why is the buffer edited, how do we fix this
  --- Create a tmp file? That way, if we don't do anything, we don't need to save etj
  --- On save it should create a draft, make sure that the draft code overwrites
  --- On send, do hooks like:
  ---- Unset modified
  ---- Hooks, close buffer on send?


  - [-] Searching
  -- [-] Highlight messages matching description
  -- [x] Movement between matches

  - [ ] Missing headers in sending?

  - [ ] Hooks, where and why? (init, send, sent ...)

  - [ ] Being able to render trees in reverse
  - [ ] FIXME and XXX
  - [ ] Why does tab before enter in save make searches fail?

  - [ ] AutoEncrypt headers support
---- 
  - [ ] Fix Subject names, can we convert these to unicode, we still need to sub newline.


  - [x] Commands / Finding the class from a bufnum?
  - [x] Remove everything in global
  - [x] https://efail.de/ secure, only render html in non-encrypted emails
  - [x] Pipes, pipe keys, git am etc.
  -- [ ] Test it, do we actually need all of that?

  - [ ] Do we unref messages etc?
  - [ ] Can we make it so that we don't have to decrypt the message twice, should we really need to decrypt a message after we press reply?



  - [ ] Telescope
  -- [ ] Make it less clunky to use, costumize 
  -- [ ] Split everything up, thing that isn't telescope should be moved

  -- [ ] Can we make it into a telescope extension?
  -- [ ] Remove presearch and just use default_text?
  --- [ ] add an "and" by default? Maybe a setting?

  - [-] Notmuch saved queries 
  -- [x] Being able to save queries and write them to notmuch config
  -- [x] Easy way to create new queries or should we rely on telescope?
  -- [x] How easy is it to build on an old search, can we help?
  --- Toy around with ideas to do this in a good way

  - [ ] Autocmd and UI
  -- Parts
  -- Closing a window with q or :q should be the same?
  -- Should we list buffers etc
  -- What about compose? How do we not lose data? (:wq to send?)

  - [ ] Email groups, maybe this is vcard?
  -- [ ] Being able to add vcards, groups etc
  --- [x] Write an example using khards
  --- [ ] Write an example using pipe and mates

  - [x] Subfilters
  - [ ] Maybe filter the whole message?


  - [ ] Update so we get the index of the mail in, XXX no clue what this means

  - [ ] Add opts to config so simple customizations doesn't require you to rewrite code

  - [ ] Add tests to the project that actually work
  - [ ] Benchmark, dunno if galore is that slow but we need to benchmark

  - [x] Highlights etc, explore options <- Make a proof of concept
  -- [x] Being able to control what is highlighted
  -- [x] For matches messages in tmb
  -- [x] Being able to move between matched.
  -- [x] match-face, underline the match?

  - [ ] Slowdowns:
  -- [ ] Render the buffers async?
  -- [ ] Render everything async? (Does that even make sense?)
  -- [ ] Can we reuse the filters (or at least most parts)?
  -- [ ] Can we reuse the same crypto ctx?
  -- [x] Verify async

* 0.3 
  - [ ] Don't assume utf8 but convert from and to the charset in vim?
  - [ ] Managed windows
  - [ ] Doing GaloreNew should update the UI
  - [ ] Rewrite notmuch-rs, the state of the lib is meh
  - [ ] Decouple notmuch.lua and gmime.lua to their own projects
  - [ ] Make different tiers, so it's easier to lazy load more of the code etc
  - [ ] Different kind of builder modes
  - [ ] Fcc outside of notmuch, not in 0.1
  -- [ ] Make fcc automatically detect if it should insert or not, abs path vs relative
  - [ ] A way to format markdown, neorg etc and get html
  - [ ] Add limit and offset to searches.
  - [ ] Gmime iterator stateless
  - [ ] Add support other encryption methoods
  - [ ] Add support for sq to gmime?

  - [ ] Non-standard headers: ‘Mail-Reply-To’, ‘Mail-Followup-To’
  - [ ] Multiple builders
  - [ ] Template system
  -- [ ] Responds to mailing list
  -- [ ] Forwarding a message and add the passed tag the message
  -- Easy to use
  -- Easy to write rules
  -- Reply, reply-all, compose to sender, compose, forward, unsubsribe
