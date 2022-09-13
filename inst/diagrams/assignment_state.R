library(nomnoml)

assignment_state <- "
#.state: fill=#8f8
[<start> start] -> [<state> Submitted]
[<state> Submitted] --> [<transceiver> get_assignment_status()]
[<transceiver> get_assignment_status()] --> [<sender> review_assignment()]
[<sender> review_assignment()] -> [<choice> Successful?]
[<choice> Successful?] Yes -> [<state> Approved]
[<choice> Successful?] No -> [<state> Rejected]
[<state> Approved] -> [<end> end]
[<state> Rejected] -> [<end> end]
"

diagram <- nomnoml(assignment_state)
diagram
