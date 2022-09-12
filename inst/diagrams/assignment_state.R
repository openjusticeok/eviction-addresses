assignment_state <- r"(
    [<start> start] -> [<state> Submitted]
    [<state> Submitted] --> [<transceiver> get_assignment_status()]
    [<transceiver> get_assignment_status()] --> [<sender> review_assignment()]
    [<sender> review_assignment()] -> [<choice> Success?]
    [<choice> Successful?] Yes -> [<state> Approved]
    [<choice> Successful?] No -> [<state> Rejected]
    [<state> Approved] -> [<end> end]
    [<state> Rejected] -> [<end> end]
)"

diagram <- nomnoml(assignment_state)
