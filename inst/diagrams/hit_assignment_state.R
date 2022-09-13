library(nomnoml)

state <- "
#.state: fill=#8f8
[<frame> HIT|
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
[<state> Reviewing] -> [<frame> Assignment|
[<start> start] -> [<state> Submitted]
[<state> Submitted] --> [<transceiver> get_assignment_status()]
[<transceiver> get_assignment_status()] --> [<sender> review_assignment()]
[<sender> review_assignment()] -> [<choice> Successful?]
[<choice> Successful?] Yes -> [<state> Approved]
[<choice> Successful?] No -> [<state> Rejected]
[<state> Approved] -> [<end> end]
[<state> Rejected] -> [<end> end]
]
[<frame> Assignment] -> [<choice> Successful?]
[<choice> Successful?] Yes -> [<state> Disposed]
[<choice> Successful?] No -> [<state> Reviewable]
[<state> Disposed] -> [<end> end]
]
"

diagram <- nomnoml(state)
diagram
