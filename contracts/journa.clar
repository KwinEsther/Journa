;; Define the list of fruits
(define-data-var fruits (list 10 (string-ascii 20)) (list "apple" "banana" "cherry" "date" "elderberry"))

;; Define a map to store votes for each fruit
(define-map fruit-votes {fruit: (string-ascii 20)} {votes: uint})

;; Define a constant for the maximum allowed votes per user
(define-constant MAX_VOTES_PER_USER u5)

;; Define a map to track votes per user
(define-map user-votes {user: principal} {vote-count: uint})

;; Function to vote for a fruit
(define-public (vote-for-fruit (fruit (string-ascii 20)))
    (let (
        (fruit-list (var-get fruits))
        (user-vote-count (default-to u0 (get vote-count (map-get? user-votes {user: tx-sender}))))
    )
        (if (and 
            (is-some (index-of fruit-list fruit))
            (< user-vote-count MAX_VOTES_PER_USER)
        )
            (begin
                (map-set user-votes {user: tx-sender} {vote-count: (+ user-vote-count u1)})
                (match (map-get? fruit-votes {fruit: fruit})
                    prev-votes (ok (map-set fruit-votes {fruit: fruit} {votes: (+ (get votes prev-votes) u1)}))
                    (ok (map-set fruit-votes {fruit: fruit} {votes: u1}))
                )
            )
            (err u0) ;; Return an error if the fruit is not in the list or user has reached max votes
        )
    )
)

;; Read-only function to get votes for a specific fruit
(define-read-only (get-fruit-votes (fruit (string-ascii 20)))
    (default-to u0 (get votes (map-get? fruit-votes {fruit: fruit})))
)

;; Read-only function to get the list of fruits
(define-read-only (get-fruits)
    (var-get fruits)
)

;; Read-only function to get the number of votes cast by a user
(define-read-only (get-user-vote-count (user principal))
    (default-to u0 (get vote-count (map-get? user-votes {user: user})))
)

;; Read-only function to get the current leading fruit
(define-read-only (get-leading-fruit)
    (fold check-max-votes (var-get fruits) {fruit: "", votes: u0})
)

;; Helper function for get-leading-fruit
(define-private (check-max-votes (fruit (string-ascii 20)) (current-max {fruit: (string-ascii 20), votes: uint}))
    (let ((fruit-vote-count (get-fruit-votes fruit)))
        (if (> fruit-vote-count (get votes current-max))
            {fruit: fruit, votes: fruit-vote-count}
            current-max
        )
    )
