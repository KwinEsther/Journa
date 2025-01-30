;; Journa - Advanced Blockchain Voting System

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_TOPIC_EXISTS (err u101))
(define-constant ERR_TOPIC_NOT_FOUND (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_INVALID_VOTE (err u105))
(define-constant ERR_SELF_DELEGATION (err u106))
(define-constant ERR_DELEGATION_CYCLE (err u107))
(define-constant ERR_INVALID_INPUT (err u108))
(define-constant ERR_NOT_ENOUGH_TOKENS (err u109))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u110))

;; Data Variables
(define-data-var admin (map principal bool) ())
(define-data-var time-counter uint u0)

;; Maps
(define-map Topics 
  { topic-id: uint } 
  { 
    name: (string-ascii 50), 
    options: (list 10 (string-ascii 20)),
    end-time: uint,
    total-votes: uint
  }
)

(define-map Votes 
  { topic-id: uint, user: principal } 
  { option: (string-ascii 20), weight: uint }
)

(define-map UserVotingPower 
  { user: principal } 
  { power: uint }
)

(define-map Delegations
  { delegator: principal }
  { delegate: principal }
)

;; Private Functions
(define-private (is-admin)
  (is-some (map-get? admin tx-sender))
)

(define-private (check-topic-exists (topic-id uint))
  (is-some (map-get? Topics { topic-id: topic-id }))
)

(define-private (check-voting-active (topic-id uint))
  (match (map-get? Topics { topic-id: topic-id })
    topic (< (var-get time-counter) (get end-time topic))
    false
  )
)

(define-private (get-voting-power (user principal))
  (default-to u1 (get power (map-get? UserVotingPower { user: user })))
)

(define-private (update-vote-count (topic-id uint) (weight uint))
  (match (map-get? Topics { topic-id: topic-id })
    topic (map-set Topics 
            { topic-id: topic-id }
            (merge topic { total-votes: (+ (get total-votes topic) weight) })))
)

(define-private (validate-string (input (string-ascii 50)))
  (and (>= (len input) u1) (<= (len input) u50))
)

(define-private (validate-options (options (list 10 (string-ascii 20)))))
  (and 
    (>= (len options) u2)
    (<= (len options) u10)
    (fold and (map validate-string options) true)
  )
)

(define-private (validate-token-based-voting (user principal))
  (let ((user-power (get-voting-power user)))
    (asserts! (> user-power u0) ERR_NOT_ENOUGH_TOKENS)
    (ok true)
  )
)

;; Public Functions
(define-public (create-topic (name (string-ascii 50)) (options (list 10 (string-ascii 20))) (duration uint))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (validate-string name) ERR_INVALID_INPUT)
    (asserts! (validate-options options) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (let 
      (
        (topic-id (+ u1 (default-to u0 (get total-votes (map-get? Topics { topic-id: u0 })))) )
        (current-time (var-get time-counter))
      )
      (asserts! (not (check-topic-exists topic-id)) ERR_TOPIC_EXISTS)
      (ok (map-set Topics 
            { topic-id: topic-id }
            { 
              name: name, 
              options: options,
              end-time: (+ current-time duration),
              total-votes: u0
            }))))
)

(define-public (cast-vote (topic-id uint) (option (string-ascii 20)))
  (let 
    (
      (user-power (get-voting-power tx-sender))
      (topic (unwrap! (map-get? Topics { topic-id: topic-id }) ERR_TOPIC_NOT_FOUND))
    )
    (asserts! (check-voting-active topic-id) ERR_VOTING_ENDED)
    (asserts! (is-some (index-of (get options topic) option)) ERR_INVALID_VOTE)
    (asserts! (is-none (map-get? Votes { topic-id: topic-id, user: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (validate-token-based-voting tx-sender) ERR_NOT_ENOUGH_TOKENS)
    (map-set Votes 
      { topic-id: topic-id, user: tx-sender }
      { option: option, weight: user-power })
    (update-vote-count topic-id user-power)
    (ok true)
  )
)

(define-public (delegate-vote (delegate principal))
  (begin
    (asserts! (not (is-eq tx-sender delegate)) ERR_SELF_DELEGATION)
    (asserts! (is-none (map-get? Delegations { delegator: delegate })) ERR_DELEGATION_CYCLE)
    (map-set Delegations { delegator: tx-sender } { delegate: delegate })
    (map-set UserVotingPower 
      { user: delegate }
      { power: (+ (get-voting-power delegate) (get-voting-power tx-sender)) })
    (map-delete UserVotingPower { user: tx-sender })
    (ok true)
  )
)

(define-public (end-voting (topic-id uint))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (check-topic-exists topic-id) ERR_TOPIC_NOT_FOUND)
    (let ((topic (unwrap! (map-get? Topics { topic-id: topic-id }) ERR_TOPIC_NOT_FOUND)))
      (ok (map-set Topics 
            { topic-id: topic-id }
            (merge topic { end-time: (var-get time-counter) })))
    )
  )
)

(define-public (increment-time)
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (ok (var-set time-counter (+ (var-get time-counter) u1)))
  )
)

;; Read-Only Functions
(define-read-only (get-topic-votes (topic-id uint))
  (ok (get total-votes (unwrap! (map-get? Topics { topic-id: topic-id }) ERR_TOPIC_NOT_FOUND)))
)

(define-read-only (get-user-voting-power (user principal))
  (ok (get-voting-power user))
)

(define-read-only (get-topic-status (topic-id uint))
  (let ((topic (unwrap! (map-get? Topics { topic-id: topic-id }) ERR_TOPIC_NOT_FOUND)))
    (ok (< (var-get time-counter) (get end-time topic)))
  )
)

(define-read-only (get-current-time)
  (ok (var-get time-counter))
)
