hit_state <- "
    [<start> start] --> [<sender> new_hit()]
    [<sender> new_hit()] -> [<state> Assignable]
    [<state> Assignable] --> [<actor> MTurk Worker]
    [<agent> MTurk Worker] -> [<state> Unassignable]
    [<state> Unassignable] -> [<choice> Submits?]
    [<choice> Submits?] No -> [<state> Assignable]
    [<choice> Submits?] Yes -> [<state> Reviewable]
    [<state> Reviewable] --> [<transceiver> check_hit_status()]
    [<transceiver> check_hit_status()] --> [<receiver> review_hit()]
    [<receiver> review_hit()] -> [<state> Reviewing]
    [<state> Reviewing] -> [<choice> Successful?]
    [<choice> Successful?] Yes -> [<state> Disposed]
    [<choice> Successful?] No -> [<state> Reviewable]
    [<state> Disposed] -> [<end> end]
"

diagram <- nomnoml(hit_state)
