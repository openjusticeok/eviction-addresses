library(nomnoml)

mturk_activity <- "
#direction: down
[<start> start] -> [<frame> Initialization |
  [<start> start] -> [<input> config.yml]
  [<input> config.yml] -> [<transceiver> mturk_auth()]
  [<transceiver> mturk_auth()] -> [<choice> Successful?]
  [<choice> Successful?] No -> [<end> end]
  [<choice> Successful?] Yes -> [<transceiver> create_hit_type()]
  [<transceiver> create_hit_type()] -> [<end> end]
]
[<frame> Runtime |
  [<start> start] -> [<sender> /mturk/batch]
  [<start> start] -> [<sender> /mturk/review]
  [<sender> /mturk/batch] -> [<transceiver> new_mturk_batch()]
  [<transceiver> new_mturk_batch()] -> [<choice> Cases Ready?]
  [<choice> Cases Ready?] Yes -> [<frame> batch_case() |
    [<start> start] -> [<transceiver> new_case_from_queue()]
    [<transceiver> new_case_from_queue()] -> [<transceiver> new_hit_from_case()]
    [<transceiver> new_hit_from_case()] -> [<end> end]
  ]
  [<choice> Cases Ready?] No -> [<end> end]
  [<frame> batch_case()] -> [<end> end]
  [<sender> /mturk/review] -> [<transceiver> get_reviewable_hits()]
  [<transceiver> get_reviewable_hits()] -> [<choice> HITs Ready?]
  [<choice> HITs Ready?] Yes -> [<frame> review_hit() |
      [<start> start] -> [<transceiver> set_hit_status('reviewing')]
      [<transceiver> set_hit_status('reviewing')] -> [<transceiver> get_hit_assignments()]
      [<transceiver> get_hit_assignments()] -> [<frame> review_assignments() |
        [<start> start] -> [<transceiver> get_assignment_status()]
        [<transceiver> get_assignment_status()] -> [<choice> Status == Reviewable]
        [<choice> Status == Reviewable] Yes -> [<transceiver> review_assignment()]
        [<choice> Status == Reviewable] No -> [<end> end]
        [<transceiver> review_assignment()] -> [<choice> Successful?]
        [<choice> Successful?] Yes -> [<transceiver> set_assignment_status('approved')]
        [<transceiver> set_assignment_status('approved')] -> [<end> end]
        [<choice> Successful?] No -> [<transceiver> set_assignment_status('rejected')]
        [<transceiver> set_assignment_status('rejected')] -> [<end> end]
      ]
      [<frame> review_assignments()] -> [<choice> Successful?]
      [<choice> Successful?] Yes -> [<transceiver> compare_hit_assignments()]
      [<transceiver> compare_hit_assignments()] -> [<choice> Comparison Successful?]
      [<choice> Comparison Successful?] Yes -> [<end> False]
      [<choice> Comparison Successful?] No -> [???]
    ]
  [<frame> review_hit()] -> [<choice> Review Successful?]
  [<transceiver> dispose_hit()] -> [<end> end]
  [<choice> Review Successful?] Yes -> [<transceiver> dispose_hit()]
  [<choice> Review Successful?] No -> [<transceiver> set_hit_status('reviewable')]
  [<transceiver> set_hit_status('reviewable')] -> [<end> end]
  [<choice> HITs Ready?] No -> [<end> end]
]
[<frame> Initialization] -> [<frame> Runtime]
[<frame> Runtime] -> [<end> end]
"

mturk_activity_diagram <- nomnoml(mturk_activity, png = "./inst/diagrams/mturk_activity_diagram.png", height = 2400, width = 1500)
mturk_activity_diagram
# htmlwidgets::saveWidget(mturk_activity_diagram, "./inst/diagrams/mturk_activity_diagram.html")
# webshot::webshot("./inst/diagrams/mturk_activity_diagram.html", file = "inst/diagrams/mturk_activity_diagram.png")
