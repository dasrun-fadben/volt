::
/-  volt
/+  server, default-agent, dbug, libvolt=volt
|%
+$  versioned-state
  $%  [%0 state-zero]
  ==
::
+$  state-zero
  $:  =config:provider:volt
  ==
::
+$  card  card:agent:gall
::
++  default-config
  :*  uri='http://localhost:8080'
      macaroon=''
  ==
--
::
%-  agent:dbug
=|  state=versioned-state
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  =.  state  [%0 config=default-config]
  :_  this
  :~  [%pass /bind %arvo %e %connect [~ /'~volt-channels'] %volt-provider]
      [%pass /bind %arvo %e %connect [~ /'~volt-htlcs'] %volt-provider]
  ==
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  `this(state !<(versioned-state old-state))
::
++  on-poke
  |=  [=mark =vase]
  |^  ^-  (quip card _this)
  =^  cards  state
  ?+    mark  (on-poke:def mark vase)
      %volt-action
    (handle-action !<(action:provider:volt vase))
  ::
      %volt-command
    (handle-command !<(command:provider:volt vase))
  ::
      %handle-http-request
    (handle-request !<([id=@ta =inbound-request:eyre] vase))
  ==
  [cards this]
  ::
  ++  start-rpc-thread
    |=  =action:rpc:volt
    ^-  (list card)
    =/  tid     `@ta`(cat 3 'thread_' (scot %uv (sham eny.bowl)))
    =/  ta-now  `@ta`(scot %da now.bowl)
    =/  args     [~ `tid %lnd-rpc !>([~ config.state action])]
    :~  [%pass /thread/[ta-now] %agent [our.bowl %spider] %watch /thread-result/[tid]]
        [%pass /thread/[ta-now] %agent [our.bowl %spider] %poke %spider-start !>(args)]
    ==
  ::
  ++  handle-action
    |=  =action:provider:volt
    ^-  (quip card _state)
    ?-    -.action
        %open-channel   `state
        %close-channel  `state
    ==
  ::
  ++  handle-command
    |=  =command:provider:volt
    ^-  (quip card _state)
    ?-    -.command
        %set-configuration
      =.  config.state  config.command
      `state
    ::
        %ping
      :_  state
      (start-rpc-thread [%get-info ~])
    ::
        %open-channel
      :_  state
      (start-rpc-thread [%open-channel +.command])
    ::
        %close-channel
      :_  state
      (start-rpc-thread [%close-channel +.command])
    ==
  ::
  ++  no-content
    |=  id=@ta
    ^-  (list card)
    :~  [%give %fact ~[/http-response/[id]] [%http-response-header !>([201 ~])]]
        [%give %kick ~[/http-response/[id]] ~]
    ==
  ::
  ++  request-json
    |=  =request:http
    ^-  (unit json)
    %+  biff  body.request
      |=  =octs
      =/  body=@t  +.octs
      (de-json:html body)
  ::
  ++  handle-request
    |=  [id=@ta =inbound-request:eyre]
    ^-  (quip card _state)
    %+  fall
      %+  bind  (request-json request.inbound-request)
      |=  =json
      ?:  =(url.request.inbound-request '/~volt-channels')
        =/  =channel-update:rpc:volt
          (channel-update:dejs:rpc:libvolt json)
        (update-channel id channel-update)
      ::
      ?>  =(url.request.inbound-request '/~volt-htlcs')
        =/  htlc=forward-htlc-intercept-request:rpc:volt
          (forward-htlc-intercept-request:dejs:rpc:libvolt json)
        (handle-htlc id htlc)
    [(no-content id) state]
  ::
  ++  update-channel
    |=  [id=@ta =channel-update:rpc:volt]
    ^-  (quip card _state)
    ?-    -.channel-update
        %open-channel
      [(no-content id) state]
    ::
        %closed-channel
      [(no-content id) state]
    ::
        %active-channel
      [(no-content id) state]
    ::
        %inactive-channel
      [(no-content id) state]
    ::
        %pending-channel
      [(no-content id) state]
    ==
  ::
  ++  handle-htlc
    |=  [id=@ta htlc=forward-htlc-intercept-request:rpc:volt]
    ^-  (quip card _state)
    [(no-content id) state]
  --
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=(%eyre -.sign-arvo)
    `this
  (on-arvo:def wire sign-arvo)
::
++  on-watch
  |=  =path
  ?:  ?=([%http-response *] path)
    `this
  (on-watch:def path)
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  |^  ^-  (quip card _this)
  ?+    -.wire  (on-agent:def wire sign)
      %thread
    ?+    -.sign  (on-agent:def wire sign)
        %poke-ack
      ?~  p.sign
        %-  (slog leaf+"Thread started!" ~)
        `this
      %-  (slog leaf+"Thread failed!" u.p.sign)
      `this
    ::
        %fact
      ?+    p.cage.sign  (on-agent:def wire sign)
          %thread-fail
        =/  err  !<  (pair term tang)  q.cage.sign
        %-  (slog leaf+"Thread failed: {(trip p.err)}" q.err)
        `this
          %thread-done
        (handle-rpc-response !<(response:rpc:volt q.cage.sign))
      ==
    ==
  ==
  ++  handle-rpc-response
    |=  =response:rpc:volt
    ^-  (quip card _this)
    ?-    -.response
        %&
      =/  =result:rpc:volt  +.response
      %-  (slog leaf+"RPC ok!" ~)
      `this
    ::
        %|
      =/  =error:rpc:volt  +.response
      %-  (slog leaf+"RPC Error: {(trip message.error)}" ~)
      `this
    ==
  --
::
++  on-peek   on-peek:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
::
--
