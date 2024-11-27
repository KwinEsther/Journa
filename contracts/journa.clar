;; Journa - A decentralized collaborative productivity journal

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))

;; Data vars
(define-data-var next-goal-id uint u0)
(define-data-var next-habit-id uint u0)

;; Maps
(define-map goals
  uint
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    target: uint,
    deadline: uint,
    progress: uint
  }
)

(define-map habits
  uint
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    streak: uint,
    last-check-in: uint
  }
)

;; Helper function to check if a string is empty
(define-private (is-empty (str (string-ascii 100)))
  (is-eq str "")
)

;; Create a goal function
(define-public (create-goal (title-input (string-ascii 100)) 
                            (description-input (string-utf8 500)) 
                            (target-input uint) 
                            (deadline-input uint))
  (let
    (
      (goal-id (var-get next-goal-id))
    )
    (asserts! (and (not (is-empty title-input))
                   (not (is-empty description-input))
                   (> target-input u0)
                   (> deadline-input u0)) err-invalid-input)
    (map-set goals goal-id {
      owner: tx-sender,
      title: title-input,
      description: description-input,
      target: target-input,
      deadline: deadline-input,
      progress: u0
    })
    (var-set next-goal-id (+ goal-id u1))
    (ok goal-id)
  )
)

;; Update goal progress function
(define-public (update-goal-progress (goal-id uint) (new-progress uint))
  (match (map-get? goals goal-id)
    goal (begin
      (asserts! (is-eq (get owner goal) tx-sender) err-unauthorized)
      (ok (map-set goals goal-id (merge goal {progress: new-progress})))
    )
    err-not-found
  )
)

;; Create a habit function
(define-public (create-habit (title-input (string-ascii 100)) 
                             (description-input (string-utf8 500)))
  (let
    (
      (habit-id (var-get next-habit-id))
    )
    (asserts! (and (not (is-empty title-input))
                   (not (is-empty description-input))) err-invalid-input)
    (map-set habits habit-id {
      owner: tx-sender,
      title: title-input,
      description: description-input,
      streak: u0,
      last-check-in: u0
    })
    (var-set next-habit-id (+ habit-id u1))
    (ok habit-id)
  )
)

;; Check-in habit function
(define-public (check-in-habit (habit-id uint))
  (match (map-get? habits habit-id)
    habit (begin
      (asserts! (is-eq (get owner habit) tx-sender) err-unauthorized)
      (let
        (
          (new-streak (+ (get streak habit) u1))
        )
        (ok (map-set habits habit-id (merge habit {
          streak: new-streak,
          last-check-in: burn-block-height
        })))
      )
    )
    err-not-found
  )
)

;; Retrieve the goal by ID
(define-read-only (get-goal (goal-id uint))
  (match (map-get? goals goal-id)
    goal (if (is-eq (get owner goal) tx-sender)
      (ok goal)
      err-unauthorized
    )
    err-not-found
  )
)

;; Retrieve the habit by ID
(define-read-only (get-habit (habit-id uint))
  (match (map-get? habits habit-id)
    habit (if (is-eq (get owner habit) tx-sender)
      (ok habit)
      err-unauthorized
    )
    err-not-found
  )
)

;; Initialize contract
(begin
  (var-set next-goal-id u0)
  (var-set next-habit-id u0)
)

