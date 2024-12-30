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

;; Data Variables
(define-data-var admin principal tx-sender)

;; Maps
(define-map Topics 
  { topic-id: uint } 
  { 
    name: (string-ascii 50), 
    options: (list 10 (string-ascii 20)),
    end-block: uint,
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
  (is-eq tx-sender (var-get admin))
)

(define-private (check-topic-exists (topic-id uint))
  (match (map-get? Topics { topic-id: topic-id })
    topic true
    false
  )
)

(define-private (check-voting-active (topic-id uint))
  (match (map-get? Topics { topic-id: topic-id })
    topic (< block-height (get end-block topic))
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
            (merge topic { total-votes: (+ (get total-votes topic) weight) }))
    false
  )
)

;; Public Functions
(define-public (create-topic (name (string-ascii 50)) (options (list 10 (string-ascii 20))) (duration uint))
  (let ((topic-id (+ u1 (default-to u0 (get total-votes (map-get? Topics { topic-id: u0 }))))))
    (if (is-admin)
      (if (check-topic-exists topic-id)
        ERR_TOPIC_EXISTS
        (begin
          (map-set Topics 
            { topic-id: topic-id }
            { 
              name: name, 
              options: options,
              end-block: (+ block-height duration),
              total-votes: u0
            })
          (ok topic-id)))
      ERR_UNAUTHORIZED))
)

(define-public (cast-vote (topic-id uint) (option (string-ascii 20)))
  (let ((user-power (get-voting-power tx-sender)))
    (if (and (check-topic-exists topic-id) (check-voting-active topic-id))
      (match (map-get? Votes { topic-id: topic-id, user: tx-sender })
        prev-vote ERR_ALREADY_VOTED
        (begin
          (map-set Votes 
            { topic-id: topic-id, user: tx-sender }
            { option: option, weight: user-power })
          (update-vote-count topic-id user-power)
          (ok true)))
      ERR_INVALID_VOTE))
)

(define-public (delegate-vote (delegate principal))
  (if (is-eq tx-sender delegate)
    ERR_SELF_DELEGATION
    (if (is-some (map-get? Delegations { delegator: delegate }))
      ERR_DELEGATION_CYCLE
      (begin
        (map-set Delegations { delegator: tx-sender } { delegate: delegate })
        (map-set UserVotingPower 
          { user: delegate }
          { power: (+ (get-voting-power delegate) (get-voting-power tx-sender)) })
        (map-delete UserVotingPower { user: tx-sender })
        (ok true))))
)

(define-public (end-voting (topic-id uint))
  (if (is-admin)
    (match (map-get? Topics { topic-id: topic-id })
      topic (begin
              (map-set Topics 
                { topic-id: topic-id }
                (merge topic { end-block: block-height }))
              (ok true))
      ERR_TOPIC_NOT_FOUND)
    ERR_UNAUTHORIZED)
)

;; Read-Only Functions
(define-read-only (get-topic-votes (topic-id uint))
  (match (map-get? Topics { topic-id: topic-id })
    topic (ok (get total-votes topic))
    (err ERR_TOPIC_NOT_FOUND))
)

(define-read-only (get-user-voting-power (user principal))
  (ok (get-voting-power user))
)

(define-read-only (get-topic-status (topic-id uint))
  (match (map-get? Topics { topic-id: topic-id })
    topic (ok (< block-height (get end-block topic)))
    (err ERR_TOPIC_NOT_FOUND))
)

(define-read-only (get-leading-option (topic-id uint))
  (match (map-get? Topics { topic-id: topic-id })
    topic (ok (fold check-max-votes (get options topic) { option: "", votes: u0 }))
    (err ERR_TOPIC_NOT_FOUND))
)

(define-private (check-max-votes (option (string-ascii 20)) (current-max { option: (string-ascii 20), votes: uint }))
  (let ((option-votes (default-to u0 (get weight (map-get? Votes { topic-id: topic-id, user: tx-sender })))))
    (if (> option-votes (get votes current-max))
      { option: option, votes: option-votes }
      current-max))
)