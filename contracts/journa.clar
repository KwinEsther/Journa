;; Define the journals map
(define-map journals
  principal
  (list 100 (tuple (entry (string-ascii 100)) (mood (string-ascii 10)) (tags (list 10 (string-ascii 30)))))
)

;; Define the tags map
(define-map tags
  (string-ascii 30)
  (list 100 principal)
)

;; Store a new journal entry for a user
(define-public (add-entry (entry (string-ascii 100)) (mood (string-ascii 10)) (entry-tags (list 10 (string-ascii 30))))
  (let
    (
      (user tx-sender)
      (new-entry (tuple (entry entry) (mood mood) (tags entry-tags)))
      (current-entries (default-to (list) (map-get? journals user)))
    )
    (ok (map-set journals user (append current-entries new-entry)))
  )
)

;; Get all journal entries for a user
(define-read-only (get-entries (user principal))
  (ok (default-to (list) (map-get? journals user)))
)

;; Add a tag to the global tags list
(define-public (add-tag (tag (string-ascii 30)))
  (let
    (
      (user tx-sender)
      (current-users (default-to (list) (map-get? tags tag)))
    )
    (ok (map-set tags tag (append current-users user)))
  )
)

;; Get all users associated with a tag
(define-read-only (get-users-by-tag (tag (string-ascii 30)))
  (ok (default-to (list) (map-get? tags tag)))
)

;; Helper function to parse the mood and return a numerical score
(define-private (parse-mood (mood (string-ascii 10)))
  (match mood
    "happy" 1
    "neutral" 0
    "sad" -1
    "stressed" -2
    -3
  )
)

;; Calculate the average mood score
(define-private (calculate-average-mood (mood-scores (list 100 int)))
  (let
    (
      (sum (fold + 0 mood-scores))
      (count (len mood-scores))
    )
    (if (is-eq count u0)
      0
      (/ sum count)
    )
  )
)

;; Mood tracking: Get the average mood for a user
(define-read-only (get-average-mood (user principal))
  (let
    (
      (entries (default-to (list) (map-get? journals user)))
      (mood-scores (map parse-mood (map get mood entries)))
    )
    (ok (calculate-average-mood mood-scores))
  )
)

;; Get the number of entries for a user
(define-read-only (get-entry-count (user principal))
  (ok (len (default-to (list) (map-get? journals user))))
)

;; Get all journal entries for a user with pagination (limit)
(define-read-only (get-entries-limited (user principal) (limit uint))
  (let
    (
      (entries (default-to (list) (map-get? journals user)))
      (entries-count (len entries))
      (actual-limit (if (> limit entries-count) entries-count limit))
    )
    (ok (slice entries u0 actual-limit))
  )
)

